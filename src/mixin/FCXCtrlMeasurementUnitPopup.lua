--  Author: Edward Koltun
--  Date: April 5, 2022
--[[
$module FCXCtrlMeasurementUnitPopup

*Extends `FCMCtrlPopup`*

This mixin defines a popup that can be used to change the window's measurement unit (eg like the one at the bottom of the settings dialog). It is largely internal, and other than setting the position and size, it runs automatically.
Programmatic changes of measurement unit should be handled at the parent window, not the control.

## Disabled Methods
The following inherited methods have been disabled:
- `Clear`
- `AddString`
- `AddStrings`
- `SetStrings`
- `GetSelectedItem`
- `SetSelectedItem`
- `SetSelectedLast`
- `ItemExists`
- `InsertString`
- `DeleteItem`
- `GetItemText`
- `SetItemText`
- `AddHandleSelectionChange`
- `RemoveHandleSelectionChange`

Event listeners for changes of measurement unit should be added to the parent window.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local measurement = require("library.measurement")

local class = {Parent = "FCMCtrlPopup", Methods = {}}
local methods = class.Methods
local private = setmetatable({}, {__mode = "k"})

local unit_order = {
    finale.MEASUREMENTUNIT_EVPUS, finale.MEASUREMENTUNIT_INCHES, finale.MEASUREMENTUNIT_CENTIMETERS,
    finale.MEASUREMENTUNIT_POINTS, finale.MEASUREMENTUNIT_PICAS, finale.MEASUREMENTUNIT_SPACES,
}
local flipped_unit_order = {}

for k, v in ipairs(unit_order) do
    flipped_unit_order[v] = k
end

-- Disabled methods
class.Disabled = {"Clear", "AddString", "AddStrings", "SetStrings", "GetSelectedItem", "SetSelectedItem", "SetSelectedLast",
    "ItemExists", "InsertString", "DeleteItem", "GetItemText", "SetItemText", "AddHandleSelectionChange", "RemoveHandleSelectionChange"}

--[[
% Init

**[Internal]**

@ self (FCXCtrlMeasurementUnitPopup)
]]
function class:Init()
    if private[self] then
        return
    end

    mixin_helper.assert(function() return mixin_helper.is_instance_of(self:GetParent(), "FCMCustomLuaWindow") end, "FCXCtrlMeasurementUnitPopup must have a parent window that is an instance of FCMCustomLuaWindow")

    for _, v in ipairs(unit_order) do
        mixin.FCMCtrlPopup.AddString(self, measurement.get_unit_name(v))
    end

    self:UpdateMeasurementUnit()

    mixin.FCMCtrlPopup.AddHandleSelectionChange(self, function(control)
        control:GetParent():SetMeasurementUnit(unit_order[mixin.FCMCtrlPopup.GetSelectedItem(control) + 1])
    end)

    private[self] = true
end

--[[
% UpdateMeasurementUnit

**[Fluid] [Internal]**

Checks the parent window's measurement unit and updates the selection if necessary.

@ self (FCXCtrlMeasurementUnitPopup)
]]
function methods:UpdateMeasurementUnit()
    local unit = self:GetParent():GetMeasurementUnit()

    if unit == unit_order[mixin.FCMCtrlPopup.GetSelectedItem(self) + 1] then
        return
    end

    mixin.FCMCtrlPopup.SetSelectedItem(self, flipped_unit_order[unit] - 1)
end

return class

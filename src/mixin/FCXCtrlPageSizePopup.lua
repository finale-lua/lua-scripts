--  Author: Edward Koltun
--  Date: April 13, 2021
--[[
$module FCXCtrlPageSizePopup

*Extends `FCMCtrlPopup`*

A popup for selecting a defined page size. The dimensions in the current unit are displayed along side each page size in the same way as the Page Format dialog.

Summary of modifications:
- `SelectionChange` has been overridden to match the specialised functionality.
- Setting and getting is now only done base on page size.

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
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local measurement = require("library.measurement")
local page_size = require("library.page_size")

local private = setmetatable({}, {__mode = "k"})
local props = {MixinParent = "FCMCtrlPopup"}

local trigger_page_size_change
local each_last_page_size_change

local temp_str = finale.FCString()

-- Disabled methods
mixin_helper.disable_methods(props, "Clear", "AddString", "AddStrings", "SetStrings", "GetSelectedItem", "SetSelectedItem", "SetSelectedLast",
    "ItemExists", "InsertString", "DeleteItem", "GetItemText", "SetItemText", "AddHandleSelectionChange", "RemoveHandleSelectionChange")

local function repopulate(control)
    local unit = mixin.is_instance_of(control:GetParent(), "FCXCustomLuaWindow") and control:GetParent():GetMeasurementUnit() or measurement.get_real_default_unit()

    if private[control].LastUnit == unit then
        return
    end

    local suffix = measurement.get_unit_abbreviation(unit)
    local selection = mixin.FCMCtrlPopup.GetSelectedItem(control)

    -- Use FCMCtrlPopup methods because `GetSelectedString` is needed in `GetSelectedPageSize`
    mixin.FCMCtrlPopup.Clear(control)

    for size, dimensions in page_size.pairs() do
        local str = size .. " ("
        temp_str:SetMeasurement(dimensions.width, unit)
        str = str .. temp_str.LuaString .. suffix .. " x "
        temp_str:SetMeasurement(dimensions.height, unit)
        str = str .. temp_str.LuaString .. suffix .. ")"

        mixin.FCMCtrlPopup.AddString(control, str)
    end

    mixin.FCMCtrlPopup.SetSelectedItem(control, selection)
    private[control].LastUnit = unit
end

--[[
% Init

**[Internal]**

@ self (FCXCtrlPageSizePopup)
]]
function props:Init()
    private[self] = private[self] or {}

    repopulate(self)
end

--[[
% GetSelectedPageSize

Returns the selected page size.

@ self (FCXCtrlPageSizePopup)
: (string|nil) The page size or `nil` if nothing is selected.
]]
function props:GetSelectedPageSize()
    local str = mixin.FCMCtrlPopup.GetSelectedString(self)
    if not str then
        return nil
    end

    return str:match("(.+) %(")
end

--[[
% SetSelectedPageSize

**[Fluid]**
Sets the selected page size. Must be a valid page size.

@ self (FCXCtrlPageSizePopup)
@ size (FCString|string)
]]
function props:SetSelectedPageSize(size)
    mixin.assert_argument(size, {"string", "FCString"}, 2)
    size = type(size) == "userdata" and size.LuaString or tostring(size)
    mixin.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")

    local index = 0
    for s in page_size.pairs() do
        if size == s then
            if index ~= self:GetSelectedItem_() then
                mixin.FCMCtrlPopup.SetSelectedItem(self, index)
                trigger_page_size_change(self)
            end

            return
        end

        index = index + 1
    end
end

--[[
% UpdateMeasurementUnit

**[Fluid] [Internal]**
Checks the parent window's measurement and updates the displayed page dimensions if necessary.

@ self (FCXCtrlPageSizePopup)
]]
function props:UpdateMeasurementUnit()
    repopulate(self)
end

--[[
% HandlePageSizeChange

**[Callback Template]**

@ control (FCXCtrlPageSizePopup)
@ last_page_size (string) The last page size that was selected. If no page size was previously selected, will be `false`.
]]

--[[
% AddHandlePageSizeChange

**[Fluid]**
Adds a handler for PageSizeChange events.
If the selected item is changed by a handler, that same handler will not be called again for that change.

The event will fire in the following cases:
- When the window is created (if an item is selected)
- Change in selected item by user or programatically (inserting an item before or after will not trigger the event)

@ self (FCXCtrlPageSizePopup)
@ callback (function) See `HandlePageSizeChange` for callback signature.
]]

--[[
% RemoveHandlePageSizeChange

**[Fluid]**
Removes a handler added with `AddHandlePageSizeChange`.

@ self (FCXCtrlPageSizePopup)
@ callback (function) Handler to remove.
]]
props.AddHandlePageSizeChange, props.RemoveHandlePageSizeChange, trigger_page_size_change, each_last_page_size_change = mixin_helper.create_custom_control_change_event(
    {
        name = "last_page_size",
        get = function(ctrl)
            return mixin.FCXCtrlPageSizePopup.GetSelectedPageSize(ctrl)
        end,
        initial = false,
    }
)

return props

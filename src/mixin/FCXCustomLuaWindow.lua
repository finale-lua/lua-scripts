--  Author: Edward Koltun
--  Date: April 10, 2022
--[[
$module FCXCustomLuaWindow

*Extends `FCMCustomLuaWindow`*

Summary of modifications:
- Measurement unit can be set on the window or changed by the user through a `FCXCtrlMeasurementUnitPopup`.
- Windows also have the option of inheriting the parent window's measurement unit when opening.
- Introduced a `MeasurementUnitChange` event.
- All controls with an `UpdateMeasurementUnit` method will have that method called upon a measurement unit change to allow them to immediately update their displayed values without needing to wait for a `MeasurementUnitChange` event.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local measurement = require("library.measurement")

local private = setmetatable({}, {__mode = "k"})
local props = {MixinParent = "FCMCustomLuaWindow"}

local trigger_measurement_unit_change
local each_last_measurement_unit_change

--[[
% Init

**[Internal]**

@ self (FCXCustomLuaWindow)
]]
function props:Init()
    private[self] = private[self] or
                        {
            MeasurementEdits = {},
            MeasurementUnit = measurement.get_real_default_unit(),
            UseParentMeasurementUnit = true,
        }
end

--[[
% GetMeasurementUnit

Returns the window's current measurement unit.

@ self (FCXCustomLuaWindow)
: (number) The value of one of the finale MEASUREMENTUNIT constants.
]]
function props:GetMeasurementUnit()
    return private[self].MeasurementUnit
end

--[[
% SetMeasurementUnit

**[Fluid]**
Sets the window's current measurement unit. Millimeters are not supported.

All controls that have an `UpdateMeasurementUnit` method will have that method called to allow them to immediately update their displayed measurement unit without needing to wait for a `MeasurementUnitChange` event.

@ self (FCXCustomLuaWindow)
@ unit (number) One of the finale MEASUREMENTUNIT constants.
]]
function props:SetMeasurementUnit(unit)
    mixin.assert_argument(unit, "number", 2)

    if unit == private[self].MeasurementUnit then
        return
    end

    if unit == finale.MEASUREMENTUNIT_DEFAULT then
        unit = measurement.get_real_default_unit()
    end

    mixin.force_assert(measurement.is_valid_unit(unit), "Measurement unit is not valid.")

    private[self].MeasurementUnit = unit

    -- Update all measurement controls
    for ctrl in each(self) do
        local func = ctrl.UpdateMeasurementUnit
        if func then
            func(ctrl)
        end
    end

    trigger_measurement_unit_change(self)
end

--[[
% GetMeasurementUnitName

Returns the name of the window's current measurement unit.

@ self (FCXCustomLuaWindow)
: (string)
]]
function props:GetMeasurementUnitName()
    return measurement.get_unit_name(private[self].MeasurementUnit)
end

--[[
% UseParentMeasurementUnit

**[Fluid]**
Sets whether to use the parent window's measurement unit when opening this window. Defaults to `true`.

@ self (FCXCustomLuaWindow)
@ on (boolean)
]]
function props:UseParentMeasurementUnit(on)
    mixin.assert_argument(on, "boolean", 2)

    private[self].UseParentMeasurementUnit = on
end

--[[
% CreateMeasurementEdit

Creates a `FCXCtrlMeasurementEdit` control.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlMeasurementEdit)
]]
function props:CreateMeasurementEdit(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local edit = mixin.FCMCustomWindow.CreateEdit(self, x, y, control_name)
    return mixin.subclass(edit, "FCXCtrlMeasurementEdit")
end

--[[
% CreateMeasurementUnitPopup

Creates a popup which allows the user to change the window's measurement unit.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlMeasurementUnitPopup)
]]
function props:CreateMeasurementUnitPopup(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
    return mixin.subclass(popup, "FCXCtrlMeasurementUnitPopup")
end

--[[
% CreatePageSizePopup

Creates a popup which allows the user to select a page size.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlPageSizePopup)
]]
function props:CreatePageSizePopup(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
    return mixin.subclass(popup, "FCXCtrlPageSizePopup")
end

--[[
% CreateStatic

**[Override]**
Creates an `FCXCtrlStatic` control.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlStatic)
]]
function props:CreateStatic(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local popup = mixin.FCMCustomWindow.CreateStatic(self, x, y, control_name)
    return mixin.subclass(popup, "FCXCtrlStatic")
end

--[[
% CreateUpDown

**[Override]**
Creates an `FCXCtrlUpDown` control.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlUpDown)
]]
function props:CreateUpDown(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local updown = mixin.FCMCustomWindow.CreateUpDown(self, x, y, control_name)
    return mixin.subclass(updown, "FCXCtrlUpDown")
end

--[[
% ExecuteModal

**[Override]**
If a parent window is passed and the `UseParentMeasurementUnit` setting is on, the measurement unit is automatically changed to match the parent.

@ self (FCXCustomLuaWindow)
@ parent (FCCustomWindow|FCMCustomWindow|nil)
: (number)
]]
function props:ExecuteModal(parent)
    if mixin.is_instance_of(parent, "FCXCustomLuaWindow") and private[self].UseParentMeasurementUnit then
        self:SetMeasurementUnit(parent:GetMeasurementUnit())
    end

    return mixin.FCMCustomWindow.ExecuteModal(self, parent)
end

--[[
% HandleMeasurementUnitChange

**[Callback Template]**
Template for MeasurementUnitChange handlers.

@ window (FCXCustomLuaWindow) The window that triggered the event.
@ last_unit (number) The window's previous measurement unit.
]]

--[[
% AddHandleMeasurementUnitChange

**[Fluid]**
Adds a handler for a change in the window's measurement unit.
The even will fire when:
- The window is created (if the measurement unit is not `finale.MEASUREMENTUNIT_DEFAULT`)
- The measurement unit is changed by the user via a `FCXCtrlMeasurementUnitPopup`
- The measurement unit is changed programmatically (if the measurement unit is changed within a handler, that *same* handler will not be called again for that change.)

@ self (FCXCustomLuaWindow)
@ callback (function) See `HandleMeasurementUnitChange` for callback signature.
]]

--[[
% RemoveHandleMeasurementUnitChange

**[Fluid]**
Removes a handler added with `AddHandleMeasurementUnitChange`.

@ self (FCXCustomLuaWindow)
@ callback (function)
]]
props.AddHandleMeasurementUnitChange, props.RemoveHandleMeasurementUnitChange, trigger_measurement_unit_change, each_last_measurement_unit_change =
    mixin_helper.create_custom_window_change_event(
        {
            name = "last_unit",
            get = function(win)
                return mixin.FCXCustomLuaWindow.GetMeasurementUnit(win)
            end,
            initial = measurement.get_real_default_unit(),
        })

return props

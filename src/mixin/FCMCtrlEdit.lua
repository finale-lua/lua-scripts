--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlEdit

Summary of modifications:
- Added `Change` custom control event.
- Added hooks for restoring control state
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local utils = require("library.utils")

local props = {}

local trigger_change
local each_last_change
local temp_str = mixin.FCMString()

--[[
% SetText

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

@ self (FCMCtrlEdit)
@ str (FCString|string|number)
]]
function props:SetText(str)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    mixin.FCMControl.SetText(self, str)
    trigger_change(self)
end

--[[
% GetInteger

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlEdit)
: (number)
]]

--[[
% SetInteger

**[Fluid] [Override]**
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

@ self (FCMCtrlEdit)
@ anint (number)
]]

--[[
% GetFloat

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlEdit)
: (number)
]]

--[[
% SetFloat

**[Fluid] [Override]**
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

@ self (FCMCtrlEdit)
@ value (number)
]]
for method, valid_types in pairs({
    Integer = "number",
    Float = "number",
}) do
    props["Get" .. method] = function(self)
        -- This is the long way around, but it ensures that the correct control value is used
        mixin.FCMControl.GetText(self, temp_str)
        return temp_str["Get" .. method](temp_str)
    end

    props["Set" .. method] = function(self, value)
        mixin.assert_argument(value, valid_types, 2)

        temp_str["Set" .. method](temp_str, value)
        mixin.FCMControl.SetText(self, temp_str)
        trigger_change(self)
    end
end

--[[
% GetMeasurement

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
: (number)
]]

--[[
% SetMeasurement

**[Fluid] [Override]**
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]

--[[
% GetMeasurementEfix

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
: (number)
]]

--[[
% SetMeasurementEfix

**[Fluid] [Override]**
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]

--[[
% GetMeasurementInteger

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
: (number)
]]

--[[
% SetMeasurementInteger

**[Fluid] [Override]**
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]
for method, valid_types in pairs({
    Measurement = "number",
    MeasurementEfix = "number",
    MeasurementInteger = "number",
}) do
    props["Get" .. method] = function(self, measurementunit)
        mixin.assert_argument(measurementunit, "number", 2)

        mixin.FCMControl.GetText(self, temp_str)
        return temp_str["Get" .. method](temp_str, measurementunit)
    end

    props["Set" .. method] = function(self, value, measurementunit)
        mixin.assert_argument(value, valid_types, 2)
        mixin.assert_argument(measurementunit, "number", 3)

        temp_str["Set" .. method](temp_str, value, measurementunit)
        mixin.FCMControl.SetText(self, temp_str)
        trigger_change(self)
    end
end

--[[
% GetRangeInteger

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlEdit)
@ minimum (number)
@ maximum (number)
: (number)
]]
function props:GetRangeInteger(minimum, maximum)
    mixin.assert_argument(minimum, "number", 2)
    mixin.assert_argument(maximum, "number", 3)

    return utils.clamp(mixin.FCMCtrlEdit.GetInteger(self), math.floor(minimum), math.floor(maximum))
end

--[[
% GetRangeMeasurement

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
@ minimum (number)
@ maximum (number)
: (number)
]]
function props:GetRangeMeasurement(measurementunit, minimum, maximum)
    mixin.assert_argument(measurementunit, "number", 2)
    mixin.assert_argument(minimum, "number", 3)
    mixin.assert_argument(maximum, "number", 4)

    return utils.clamp(mixin.FCMCtrlEdit.GetMeasurement(self, measurementunit), minimum, maximum)
end

--[[
% GetRangeMeasurementEfix

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
@ minimum (number)
@ maximum (number)
: (number)
]]
function props:GetRangeMeasurementEfix(measurementunit, minimum, maximum)
    mixin.assert_argument(measurementunit, "number", 2)
    mixin.assert_argument(minimum, "number", 3)
    mixin.assert_argument(maximum, "number", 4)

    return utils.clamp(mixin.FCMCtrlEdit.GetMeasurementEfix(self, measurementunit), minimum, maximum)
end

--[[
% GetRangeMeasurementInteger

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
@ minimum (number)
@ maximum (number)
: (number)
]]
function props:GetRangeMeasurementInteger(measurementunit, minimum, maximum)
    mixin.assert_argument(measurementunit, "number", 2)
    mixin.assert_argument(minimum, "number", 3)
    mixin.assert_argument(maximum, "number", 4)

    return utils.clamp(mixin.FCMCtrlEdit.GetMeasurementInteger(self, measurementunit), math.floor(minimum), math.floor(maximum))
end

--[[
% HandleChange

**[Callback Template]**

@ control (FCMCtrlEdit) The control that was changed.
@ last_value (string) The previous value of the control.
]]

--[[
% AddHandleChange

**[Fluid]**
Adds a handler for when the value of the control changes.
The even will fire when:
- The window is created (if the value of the control is not an empty string)
- The value of the control is changed by the user
- The value of the control is changed programmatically (if the value of the control is changed within a handler, that *same* handler will not be called again for that change.)

@ self (FCMCtrlEdit)
@ callback (function) See `HandleChange` for callback signature.
]]

--[[
% RemoveHandleChange

**[Fluid]**
Removes a handler added with `AddHandleChange`.

@ self (FCMCtrlEdit)
@ callback (function)
]]
props.AddHandleChange, props.RemoveHandleChange, trigger_change, each_last_change = mixin_helper.create_custom_control_change_event(
    {
        name = "last_value",
        get = mixin.FCMControl.GetText,
        initial = ""
    }
)

return props

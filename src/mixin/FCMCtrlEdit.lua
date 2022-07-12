--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlEdit

Summary of modifications:
- Added `Change` custom control event.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local props = {}

local trigger_change
local each_last_change

--[[
% SetInteger

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

@ self (FCMCtrlEdit)
@ anint (number)
]]
function props:SetInteger(anint)
    mixin.assert_argument(anint, "number", 2)

    self:SetInteger_(anint)
    trigger_change(self)
end

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
% SetMeasurement

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]
function props:SetMeasurement(value, measurementunit)
    mixin.assert_argument(value, "number", 2)
    mixin.assert_argument(measurementunit, "number", 3)

    self:SetMeasurement_(value, measurementunit)
    trigger_change(self)
end

--[[
% SetMeasurementEfix

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]
function props:SetMeasurementEfix(value, measurementunit)
    mixin.assert_argument(value, "number", 2)
    mixin.assert_argument(measurementunit, "number", 3)

    self:SetMeasurementEfix_(value, measurementunit)
    trigger_change(self)
end

--[[
% SetMeasurementInteger

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]
function props:SetMeasurementInteger(value, measurementunit)
    mixin.assert_argument(value, "number", 2)
    mixin.assert_argument(measurementunit, "number", 3)

    self:SetMeasurementInteger_(value, measurementunit)
    trigger_change(self)
end

--[[
% SetFloat

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

@ self (FCMCtrlEdit)
@ value (number)
]]
function props:SetFloat(value)
    mixin.assert_argument(value, "number", 2)

    self:SetFloat_(value)
    trigger_change(self)
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
props.AddHandleChange, props.RemoveHandleChange, trigger_change, each_last_change =
    mixin_helper.create_custom_control_change_event(
        {name = "last_value", get = mixin.FCMControl.GetText, initial = ""})

return props

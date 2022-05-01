--  Author: Edward Koltun
--  Date: March 3, 2022

--[[
$module FCMCtrlEdit

Summary of modifications:
- Added `Change` custom control event.
]]

local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local props = {}

local trigger_change
local each_last_change


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
    {name = 'last_value', get = mixin.FCMControl.GetText, initial = ""}
)


return props

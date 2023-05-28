--  Author: Edward Koltun
--  Date: April 2, 2022
--[[
$module FCMCtrlCheckbox

## Summary of Modifications
- Added `CheckChange` custom control event.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local class = {Methods = {}}
local methods = class.Methods

local trigger_check_change
local each_last_check_change

--[[
% SetCheck

**[Fluid] [Override]**

Override Changes:
- Ensures that `CheckChange` event is triggered.

@ self (FCMCtrlCheckbox)
@ checked (number)
]]
function methods:SetCheck(checked)
    mixin_helper.assert_argument_type(2, checked, "number")

    self:SetCheck__(checked)

    trigger_check_change(self)
end

--[[
% HandleCheckChange

**[Callback Template]**

@ control (FCMCtrlCheckbox) The control that was changed.
@ last_check (string) The previous value of the control's check state..
]]

--[[
% AddHandleCheckChange

**[Fluid]**

Adds a handler for when the value of the control's check state changes.
The event will fire when:
- The window is created (if the check state is not `0`)
- The control is checked/unchecked by the user
- The control's check state is changed programmatically (if the check state is changed within a handler, that *same* handler will not be called again for that change.)

@ self (FCMCtrlCheckbox)
@ callback (function) See `HandleCheckChange` for callback signature.
]]

--[[
% RemoveHandleCheckChange

**[Fluid]**

Removes a handler added with `AddHandleCheckChange`.

@ self (FCMCtrlCheckbox)
@ callback (function)
]]
methods.AddHandleCheckChange, methods.RemoveHandleCheckChange, trigger_check_change, each_last_check_change = mixin_helper.create_custom_control_change_event(
    -- initial could be set to -1 to force the event to fire on InitWindow, but unlike other controls, -1 is not a valid checkstate.
    -- If it becomes necessary to force this event to fire when the window is created, change to -1
    {
        name = "last_check",
        get = "GetCheck__",
        initial = 0,
    }
)

return class

--  Author: Edward Koltun
--  Date: April 3, 2022
--[[
$module FCMCtrlSlider

## Summary of Modifications
- Added `ThumbPositionChange` custom control event *(see note)*.

## Note on `ThumbPositionChange` and `Command` Events
Command events do not fire for `FCCtrlSlider` controls before RGPLua 0.64, so a workaround is used to make the `ThumbPositionChange` events fire.
- If using JW/RGPLua version 0.55 or lower, then the event dispatcher will run with the next Command event for a different control. In these versions the event is unreliable as the user will need to interact with another control for the change in thumb position to be registered.
- If using version 0.56 or later, then the dispatcher will run every 1 second. This is more reliable than in earlier versions but it still will not fire immediately.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local meta = {}
local public = {}
local windows = setmetatable({}, {__mode = "k"})

local trigger_thumb_position_change
local each_last_thumb_position_change

local using_timer_fix = false

local function bootstrap_command()
    -- Since we're piggybacking off a handler, we don't need to trigger immediately
    trigger_thumb_position_change(true)
end

local function bootstrap_timer(timerid, window)
    -- We're in the root of an event handler, so it is safe to trigger immediately
    trigger_thumb_position_change(true, true)
end

local bootstrap_timer_first

-- Timers may not work, so only remove the command handler once the timer has fired once
bootstrap_timer_first = function(timerid, window)
    window:RemoveHandleCommand(bootstrap_command)
    window:RemoveHandleTimer(timerid, bootstrap_timer_first)
    window:AddHandleTimer(timerid, bootstrap_timer)

    bootstrap_timer(timerid, window)
end

--[[
% RegisterParent

**[Internal] [Override]**

Override Changes:
- Bootstrap workaround for command events not firing on `FCCtrlSlider` controls

@ self (FCMCtrlSlider)
@ window (FCMCustomWindow)
]]
function public:RegisterParent(window)
    mixin.FCMControl.RegisterParent(self, window)

    if finenv.MajorVersion == 0 and finenv.MinorVersion < 64 and not windows[window] and mixin_helper.is_instance_of(window, "FCMCustomLuaWindow") then
        -- Bootstrap to command events for every other control
        window:AddHandleCommand(bootstrap_command)

        if window.SetTimer_ then
            -- Trigger dispatches every second
            window:AddHandleTimer(window:SetNextTimer(1000), bootstrap_timer_first)
        end

        windows[window] = true
    end
end

--[[
% SetThumbPosition

**[Fluid] [Override]**

Override Changes:
- Ensure that `ThumbPositionChange` event is triggered.

@ self (FCMCtrlSlider)
@ position (number)
]]
function public:SetThumbPosition(position)
    mixin_helper.assert_argument_type(2, position, "number")

    self:SetThumbPosition_(position)

    trigger_thumb_position_change(self)
end

--[[
% SetMinValue

**[Fluid] [Override]**

Override Changes:
- Ensure that `ThumbPositionChange` is triggered.

@ self (FCMCtrlSlider)
@ minvalue (number)
]]
function public:SetMinValue(minvalue)
    mixin_helper.assert_argument_type(2, minvalue, "number")

    self:SetMinValue_(minvalue)

    trigger_thumb_position_change(self)
end

--[[
% SetMaxValue

**[Fluid] [Override]**

Override Changes:
- Ensure that `ThumbPositionChange` event is triggered.

@ self (FCMCtrlSlider)
@ maxvalue (number)
]]
function public:SetMaxValue(maxvalue)
    mixin_helper.assert_argument_type(2, maxvalue, "number")

    self:SetMaxValue_(maxvalue)

    trigger_thumb_position_change(self)
end

--[[
% HandleThumbPositionChange

**[Callback Template]**

@ control (FCMCtrlSlider) The slider that was moved.
@ last_position (string) The previous value of the control's thumb position.
]]

--[[
% AddHandleChange

**[Fluid]**

Adds a handler for when the slider's thumb position changes.
The even will fire when:
- The window is created
- The slider is moved by the user (see note regarding command events)
- The slider's postion is changed programmatically (if the thumb position is changed within a handler, that *same* handler will not be called again for that change.)

@ self (FCMCtrlSlider)
@ callback (function) See `HandleThumbPositionChange` for callback signature.
]]

--[[
% RemoveHandleThumbPositionChange

**[Fluid]**

Removes a handler added with `AddHandleThumbPositionChange`.

@ self (FCMCtrlSlider)
@ callback (function)
]]
public.AddHandleThumbPositionChange, public.RemoveHandleThumbPositionChange, trigger_thumb_position_change, each_last_thumb_position_change = mixin_helper.create_custom_control_change_event(
    {
        name = "last_position",
        get = "GetThumbPosition_",
        initial = -1,
    }
)

return {meta, public}

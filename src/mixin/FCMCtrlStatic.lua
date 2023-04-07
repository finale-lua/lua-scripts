--  Author: Edward Koltun
--  Date: September 18, 2022
--[[
$module FCMCtrlStatic

## Summary of Modifications
- Added hooks for control state preservation.
- SetTextColor updates visible color immediately if window is showing.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local utils = require("library.utils")

local meta = {}
local public = {}
local private = setmetatable({}, {__mode = "k"})

local temp_str = finale.FCString()

--[[
% Init

**[Internal]**

@ self (FCMCtrlStatic)
]]
function meta:Init()
    if private[self] then
        return
    end

    private[self] = {}
end

--[[
% SetTextColor

**[Fluid] [Override]**

Override Changes:
- Displays the new text color immediately.
- Hooks into control state preservation.

@ self (FCMCtrlStatic)
@ red (number)
@ green (number)
@ blue (number)
]]
function public:SetTextColor(red, green, blue)
    mixin_helper.assert_argument_type(2, red, "number")
    mixin_helper.assert_argument_type(3, green, "number")
    mixin_helper.assert_argument_type(4, blue, "number")

    private[self].TextColor = {red, green, blue}

    if not mixin.FCMControl.UseStoredState(self) then
        self:SetTextColor_(red, green, blue)

        -- If a new text color is set after the window has been shown, the visible color will not change until new text is set
        -- Getting and setting the text makes the new text color visible immediately
        mixin.FCMControl.SetText(self, mixin.FCMControl.GetText(self))
    end
end

--[[
% RestoreState

**[Fluid] [Internal] [Override]**

Override Changes:
- Restores `FCMCtrlStatic`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

@ self (FCMCtrlStatic)
]]
function public:RestoreState()
    mixin.FCMControl.RestoreState(self)

    -- Only need to restore color if it has been changed from the default
    if private[self].TextColor then
        mixin.FCMCtrlStatic.SetTextColor(self, private[self].TextColor[1], private[self].TextColor[2], private[self].TextColor[3])
    end
end

return {meta, public}

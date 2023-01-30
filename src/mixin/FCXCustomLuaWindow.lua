--  Author: Edward Koltun
--  Date: April 10, 2022
--[[
$module FCXCustomLuaWindow

*Extends `FCMCustomLuaWindow`*

Summary of modifications:
- DebugClose is enabled by default
]] --
local mixin = require("library.mixin")
local utils = require("library.utils")
local mixin_helper = require("library.mixin_helper")
local measurement = require("library.measurement")

local props = {MixinParent = "FCMCustomLuaWindow"}

local trigger_measurement_unit_change
local each_last_measurement_unit_change

--[[
% Init

**[Internal]**

@ self (FCXCustomLuaWindow)
]]
function props:Init()
    self:SetEnableDebugClose(true)
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

return props

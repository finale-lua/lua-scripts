--  Author: Edward Koltun
--  Date: April 10, 2022
--[[
$module FCXCustomLuaWindow

*Extends `FCMCustomLuaWindow`*

## Summary of Modifications
- DebugClose is enabled by default
]] --
local mixin = require("library.mixin")
local utils = require("library.utils")
local mixin_helper = require("library.mixin_helper")
local measurement = require("library.measurement")

local meta = {Parent = "FCMCustomLuaWindow"}
local public = {}

local trigger_measurement_unit_change
local each_last_measurement_unit_change

--[[
% Init

**[Internal]**

@ self (FCXCustomLuaWindow)
]]
function meta:Init()
    self:SetEnableDebugClose(true)
end

--[[
% CreateUpDown

**[Override]**

Override Changes:
- Creates an `FCXCtrlUpDown` control.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlUpDown)
]]
function public:CreateUpDown(x, y, control_name)
    mixin_helper.assert_argument_type(2, x, "number")
    mixin_helper.assert_argument_type(3, y, "number")
    mixin_helper.assert_argument_type(4, control_name, "string", "nil")

    local updown = mixin.FCMCustomWindow.CreateUpDown(self, x, y, control_name)
    return mixin.subclass(updown, "FCXCtrlUpDown")
end

return {meta, public}

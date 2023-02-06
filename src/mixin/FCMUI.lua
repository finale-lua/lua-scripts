--  Author: Edward Koltun
--  Date: April 13, 2021
--[[
$module FCMUI

Summary of modifications:
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local props = {}

local temp_str = finale.FCString()

--[[
% GetDecimalSeparator

**[Override]**
Returns a Lua `string` and makes passing an `FCString` optional.

@ self (FCMUI)
@ [str] (FCString)
: (string)
]]
function props:GetDecimalSeparator(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    if not str then
        str = temp_str
    end

    self:GetDecimalSeparator_(str)

    return str.LuaString
end

return props

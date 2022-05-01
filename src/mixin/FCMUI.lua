--  Author: Edward Koltun
--  Date: April 13, 2021
--[[
$module FCMUI

Summary of modifications:
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
]] --
local mixin = require("library.mixin")

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
    mixin.assert_argument(str, {"nil", "FCString"}, 2)

    if not str then
        str = temp_str
    end

    self:GetDecimalSeparator_(str)

    return str.LuaString
end

return props

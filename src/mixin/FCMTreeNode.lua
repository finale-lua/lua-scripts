--  Author: Edward Koltun
--  Date: April 6, 2022
--[[
$module FCMTreeNode

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local props = {}

local temp_str = finale.FCString()

--[[
% GetText

**[Override]**
Returns a Lua `string` and makes passing an `FCString` optional.

@ self (FCMTreeNode)
@ [str] (FCString)
: (string)
]]
function props:GetText(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    if not str then
        str = temp_str
    end

    self:GetText_(str)

    return str.LuaString
end

--[[
% SetText

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMTreeNode)
@ str (FCString|string|number)
]]
function props:SetText(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    self:SetText_(str)
end

return props

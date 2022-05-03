--  Author: Edward Koltun
--  Date: April 6, 2022
--[[
$module FCMTreeNode

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
]] --
local mixin = require("library.mixin")

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
    mixin.assert_argument(str, {"nil", "FCString"}, 2)

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
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    self:SetText_(str)
end

return props

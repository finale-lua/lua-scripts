--  Author: Edward Koltun
--  Date: April 6, 2022
--[[
$module FCMTreeNode

## Summary of Modifications
- Setters that accept `FCString` also accept a Lua `string` or `number`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local class = {Methods = {}}
local methods = class.Methods

local temp_str = finale.FCString()

--[[
% GetText

**[?Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

@ self (FCMTreeNode)
@ [str] (FCString)
: (string) Returned if `str` is omitted.
]]
function methods:GetText(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    local do_return = false
    if not str then
        str = temp_str
        do_return = true
    end

    self:GetText__(str)

    if do_return then
        return str.LuaString
    end
end

--[[
% SetText

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

@ self (FCMTreeNode)
@ str (FCString | string | number)
]]
function methods:SetText(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    self:SetText__(mixin_helper.to_fcstring(str, temp_str))
end

return class

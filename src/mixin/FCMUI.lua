--  Author: Edward Koltun
--  Date: April 13, 2021
--[[
$module FCMUI

## Summary of Modifications
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local meta = {}
local public = {}

local temp_str = finale.FCString()

--[[
% GetDecimalSeparator

**[?Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

@ self (FCMUI)
@ [str] (FCString)
: (string)
]]
function public:GetDecimalSeparator(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    local do_return = false
    if not str then
        str = temp_str
        do_return = true
    end

    self:GetDecimalSeparator_(str)

    if do_return then
        return str.LuaString
    end
end

return {meta, public}

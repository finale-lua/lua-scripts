--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module __FCMUserWindow

## Summary of Modifications
- Setters that accept `FCString` will also accept a Lua `string`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local meta = {}
local public = {}

local temp_str = finale.FCString()

--[[
% GetTitle

**[?Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

@ self (__FCMUserWindow)
@ [title] (FCString)
: (string) Returned if `title` is omitted.
]]
function public:GetTitle(title)
    mixin_helper.assert_argument_type(2, title, "nil", "FCString")

    local do_return = false
    if not title then
        title = temp_str
        do_return = true
    end

    self:GetTitle_(title)

    if do_return then
        return title.LuaString
    end
end

--[[
% SetTitle

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

@ self (__FCMUserWindow)
@ title (FCString | string | number)
]]
function public:SetTitle(title)
    mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")

    self:SetTitle_(mixin_helper.to_fcstring(title, temp_str))
end

return {meta, public}

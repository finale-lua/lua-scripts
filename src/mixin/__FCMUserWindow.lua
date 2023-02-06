--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module __FCMUserWindow

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local props = {}

local temp_str = finale.FCString()

--[[
% GetTitle

**[Override]**
Returns a Lua `string` and makes passing an `FCString` optional.

@ self (__FCMUserWindow)
@ [title] (FCString)
: (string)
]]
function props:GetTitle(title)
    mixin_helper.assert_argument_type(2, title, "nil", "FCString")

    if not title then
        title = temp_str
    end

    self:GetTitle_(title)

    return title.LuaString
end

--[[
% SetTitle

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (__FCMUserWindow)
@ title (FCString|string|number)
]]
function props:SetTitle(title)
    mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")

    if type(title) ~= "userdata" then
        temp_str.LuaString = tostring(title)
        title = temp_str
    end

    self:SetTitle_(title)
end

return props

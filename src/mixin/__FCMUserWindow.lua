--  Author: Edward Koltun
--  Date: March 3, 2022

--[[
$module __FCMUserWindow

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
]]

local mixin = require("library.mixin")

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
    mixin.assert_argument(title, {"nil", "FCString"}, 2)

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
    mixin.assert_argument(title, {"string", "number", "FCString"}, 2)

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(title)
        title = temp_str
    end

    self:SetTitle_(title)
end


return props

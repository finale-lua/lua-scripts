--  Author: Edward Koltun
--  Date: April 13, 2021
--[[
$module FCMUI

## Summary of Modifications
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
]] --
local mixin = require("library.mixin") -- luacheck: ignore
local mixin_helper = require("library.mixin_helper")
local localization = require("library.localization")

local class = {Methods = {}}
local methods = class.Methods

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
function methods:GetDecimalSeparator(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    local do_return = false
    if not str then
        str = temp_str
        do_return = true
    end

    self:GetDecimalSeparator__(str)

    if do_return then
        return str.LuaString
    end
end

--[[
% AlertLocalizedError

**[Fluid]**

Displays a localized error message. 

@ self (FCMControl)
@ message_key (string) The key into the localization table. If there is no entry in the appropriate localization table, the key is the message.
@ title_key (string) The key into the localization table. If there is no entry in the appropriate localization table, the key is the title.
]]
function methods:AlertLocalizedError(message_key, title_key)
    mixin_helper.assert_argument_type(2, message_key, "string")
    mixin_helper.assert_argument_type(3, title_key, "string")

    self:AlertError(localization.localize(message_key), localization.localize(title_key))
end

return class

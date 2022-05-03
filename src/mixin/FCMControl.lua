--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMControl

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
- Ported `GetParent` from PDK to allow the parent window to be accessed from a control.
- Handlers for the `Command` event can now be set on a control.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

-- So as not to prevent the window (and by extension the controls) from being garbage collected in the normal way, use weak keys and values for storing the parent window
local parent = setmetatable({}, {__mode = "kv"})
local props = {}

local temp_str = finale.FCString()

--[[
% GetParent

**[PDK Port]**
Returns the control's parent window.
Do not override or disable this method.

@ self (FCMControl)
: (FCMCustomWindow)
]]
function props:GetParent()
    return parent[self]
end

--[[
% RegisterParent

**[Fluid] [Internal]**
Used to register the parent window when the control is created.
Do not disable this method.

@ self (FCMControl)
@ window (FCMCustomWindow)
]]
function props:RegisterParent(window)
    mixin.assert_argument(window, {"FCMCustomWindow", "FCMCustomLuaWindow"}, 2)

    if parent[self] then
        error("This method is for internal use only.", 2)
    end

    parent[self] = window
end

--[[
% GetText

**[Override]**
Returns a Lua `string` and makes passing an `FCString` optional.

@ self (FCMControl)
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

@ self (FCMControl)
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

--[[
% AddHandleCommand

**[Fluid]**
Adds a handler for command events.

@ self (FCMControl)
@ callback (function) See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature.
]]

--[[
% RemoveHandleCommand

**[Fluid]**
Removes a handler added with `AddHandleCommand`.

@ self (FCMControl)
@ callback (function)
]]
props.AddHandleCommand, props.RemoveHandleCommand = mixin_helper.create_standard_control_event("HandleCommand")

return props

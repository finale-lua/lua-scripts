--[[
$module FCMControl
]]

local mixin = require("library.mixin")

-- So as not to prevent the window (and by extension the controls) from being garbage collected in the normal way, use weak keys and values for storing the parent window
local parent = setmetatable({}, {__mode = "kv"})
local private = setmetatable({}, {__mode = "k"})
local props = {}

local temp_str = finale.FCString()
local handle_command_windows = {}

local function init_handle_command(window)
    if handle_command_windows[window] then
        return
    end

    window:AddHandleCommand(function(control)
        if not private[control] then
            return
        end

        for _, v in ipairs(private[control].HandleCommand) do
            v(control)
        end
    end)

    handle_command_windows[window] = true
end


--[[
% Init

**[Internal]**

@ self (FCMControl)
]]
function props:Init()
    private[self] = private[self] or {HandleCommand = {}}
end

--[[
% GetParent

**[PDK Port]**
Returns the control's parent window.

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

@ self (FCMControl)
@ window (FCMCustomWindow)
]]
function props:RegisterParent(window)
    mixin.assert_argument(window, {"FCMCustomWindow", "FCMCustomLuaWindow"}, 2)

    if parent[self] then
        error("This function is for internal use only.", 2)
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
@ func (function) Handler with the signature `func(control)`
]]
function props:AddHandleCommand(func)
    mixin.assert_argument(func, "function", 2)
    mixin.assert(parent[self], "Cannot add handler to control with no parent window.")
    mixin.assert((parent[self].MixinBase or parent[self].MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")

    init_handle_command(parent[self])
    table.insert(private[self].HandleCommand, func)
end

--[[
% RemoveHandleCommand

**[Fluid]**
Removes a handler added with `AddHandleCommand`.

@ self (FCMControl)
@ func (function)
]]
function props:RemoveHandleCommand(func)
    mixin.assert_argument(func, "function", 2)

    utils.table_remove_first(private[self].HandleCommand, func)
end


return props

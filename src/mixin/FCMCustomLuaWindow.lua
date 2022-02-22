--[[
$module FCMCustomLuaWindow
]]

local mixin = require("library.mixin")
local utils = require("library.utils")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local handle_functions = {"HandleCommand", "HandleDataListCheck", "HandleDataListSelect", "HandleUpDownPressed"}

local function execute_handlers(window, event, control, ...)
    local handlers = private[window][event]

    -- Call registered handler
    if handlers.Registered then
        handlers.Registered(control, ...)
    end

    -- Call added handlers
    for _, v in ipairs(handlers.Added) do
        v(control, ...)
    end
end

--[[
% Init

**[Internal]**

@ self (FCMCustomLuaWindow)
]]
function props:Init()
    private[self] = private[self] or {}

    -- Registers proxy functions up front to ensure that the handlers are passed the original object along with its mixin data
    for _, f in ipairs(handle_functions) do
        private[self][f] = {Added = {}, EventQueue = {}}

        if self["Register" .. f .. "_"] then
            self["Register" .. f .. "_"](self, function(control, ...)
                local handlers = private[self][f]

                -- Flush only old triggers first
                -- If any are added while flushing, they will be flushed later
                if #handlers.EventQueue > 0 then
                    local num = #handlers.EventQueue
                    for i = 1, num do
                        local c = handlers.EventQueue[1]
                        table.remove(handlers.EventQueue, 1)
                        execute_handlers(self, f, c)
                    end
                end

                -- Execute handlers for main control
                local temp = self:FindControl(control:GetControlID())

                if not temp then
                    error("Control with ID #" .. tostring(control:GetControlID()) .. " not found in '" .. f .. "'")
                end

                control = temp
                execute_handlers(self, f, control)

                -- Flush queue until empty
                while #handlers.EventQueue > 0 do
                    local c = handlers.EventQueue[1]
                    table.remove(handlers.EventQueue, 1)
                    execute_handlers(self, f, c)
                end
            end)
        end
    end
end


--[[
% RegisterHandleCommand

**[Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ func (function)
: (boolean) `true` on success
]]

--[[
% RegisterHandleDataListCheck

**[Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ func (function)
: (boolean) `true` on success
]]

--[[
% RegisterHandleDataListSelect

**[Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ func (function)
: (boolean) `true` on success
]]

--[[
% RegisterHandleUpDownPressed

**[Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ func (function)
: (boolean) `true` on success
]]

for _, f in ipairs(handle_functions) do
    props["Register" .. f] = function(self, func)
        mixin.assert_argument(func, "function", 2)

        private[self][f].Registered = func
        return true
    end
end


--[[
% AddHandleCommand

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleCommand` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ func (function)
]]

--[[
% AddHandleDataListCheck

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleDataListCheck` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ func (function)
]]

--[[
% AddHandleDataListSelect

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleDataListSelect` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ func (function)
]]

--[[
% AddHandleUpDownPressed

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleUpDownPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ func (function)
]]

for _, f in ipairs(handle_functions) do
    props["Add" .. f] = function(self, func)
        mixin.assert_argument(func, "function", 2)
        
        table.insert(private[self][f].Added, func)
    end
end


--[[
% RemoveHandleCommand

**[Fluid]**
Removes a handler added by `AddHandleCommand`.

@ self (FCMCustomLuaWindow)
@ func (function)
]]

--[[
% RemoveHandleDataListCheck

**[Fluid]**
Removes a handler added by `AddHandleDataListCheck`.

@ self (FCMCustomLuaWindow)
@ func (function)
]]

--[[
% RemoveHandleDataListSelect

**[Fluid]**
Removes a handler added by `AddHandleDataListSelect`.

@ self (FCMCustomLuaWindow)
@ func (function)
]]

--[[
% RemoveHandleUpDownPressed

**[Fluid]**
Removes a handler added by `AddHandleUpDownPressed`.

@ self (FCMCustomLuaWindow)
@ func (function)
]]

for _, f in ipairs(handle_functions) do
    props["Remove" .. f] = function(self, func)
        mixin.assert_argument(func, "function", 2)

        utils.table_remove_first(private[self][f].Added, func)
    end
end

--[[
% TriggerHandleCommand

**[Fluid]**
Triggers a HandleCommand event for a control.
It doesn't *actually* trigger the event, but adds it to a queue so the next time the event occurs for any control, event handlers will first be called with this control.

@ self (FCMCustomLuaWindow)
@ control (FCMControl)
]]
function props:TriggerHandleCommand(control)
    mixin.assert(control and self:FindControl(control:GetControlID()), "The control does not belong to this window.")

    for _, v in ipairs(private[self].HandleCommand.EventQueue) do
        if v == control then
            return
        end
    end

    table.insert(private[self].HandleCommand.EventQueue, control)
end

--[[
% RegisterHandleControlEvent

**[>= v0.56] [Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ control (FCMControl)
@ func (function)
: (boolean) `true` on success
]]
if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then
    -- Ensures that the original object along with its mixin data will be sent to the callback
    function props.RegisterHandleControlEvent(self, control, func)
        return self:RegisterHandleControlEvent_(ctrl, function(ctrl)
            func(self.FindControl(control:GetControlID()))
        end)
    end
end


return props
--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCustomLuaWindow

Summary of modifications:
- All `Register*` methods (apart from `RegisterHandleControlEvent`) have accompanying `Add*` and `Remove*` methods to enable multiple handlers to be added per event.
- Handlers for non-control events can receive the window object as an optional additional parameter.
- Control handlers are passed original object to preserve mixin data.
- Added custom callback queue which can be used by custom events to add dispatchers that will run with the next control event.
- Added `HasBeenShown` method for checking if the window has been shown
- Added methods for the automatic restoration of previous window position when showing (RGPLua > 0.60) for use with `finenv.RetainLuaState` and modeless windows.
]] --
local mixin = require("library.mixin")
local utils = require("library.utils")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local control_handlers = {"HandleCommand", "HandleDataListCheck", "HandleDataListSelect", "HandleUpDownPressed"}
local other_handlers = {"HandleCancelButtonPressed", "HandleOkButtonPressed", "InitWindow", "CloseWindow"}

local function flush_custom_queue(self)
    local queue = private[self].HandleCustomQueue
    private[self].HandleCustomQueue = {}

    for _, cb in ipairs(queue) do
        cb()
    end
end

local function restore_position(window)
    if private[window].HasBeenShown and private[window].AutoRestorePosition and window.StorePosition then
        window:StorePosition(false)
        window:SetRestorePositionOnlyData_(private[window].StoredX, private[window].StoredY)
        window:RestorePosition()
    end
end

--[[
% Init

**[Internal]**

@ self (FCMCustomLuaWindow)
]]
function props:Init()
    private[self] = private[self] or {
        NextTimerID = 1,
        HandleTimer = {},
        HandleCustomQueue = {},
        HasBeenShown = false,
        AutoRestorePosition = false,
        AutoRestoreSize = false,
        StoredX = nil,
        StoredY = nil,
    }

    -- Registers proxy functions up front to ensure that the handlers are passed the original object along with its mixin data
    for _, f in ipairs(control_handlers) do
        private[self][f] = {Added = {}}

        -- Handlers sometimes run twice, the second while the first is still running, so this flag prevents race conditions and concurrency issues.
        local is_running = false
        if self["Register" .. f .. "_"] then
            self["Register" .. f .. "_"](
                self, function(control, ...)
                    if is_running then
                        return
                    end

                    is_running = true
                    local handlers = private[self][f]

                    -- Flush custom queue once
                    flush_custom_queue(self)

                    -- Execute handlers for main control
                    local temp = self:FindControl(control:GetControlID())

                    if not temp then
                        error("Control with ID #" .. tostring(control:GetControlID()) .. " not found in '" .. f .. "'")
                    end

                    control = temp

                    -- Call registered handler
                    if handlers.Registered then
                        handlers.Registered(control, ...)
                    end

                    -- Call added handlers
                    for _, cb in ipairs(handlers.Added) do
                        cb(control, ...)
                    end

                    -- Flush custom queue until empty
                    while #private[self].HandleCustomQueue > 0 do
                        flush_custom_queue(self)
                    end

                    is_running = false
                end)
        end
    end

    -- Register proxies for other handlers
    for _, f in ipairs(other_handlers) do
        private[self][f] = {Added = {}}

        if self["Register" .. f .. "_"] then
            local function cb()
                local handlers = private[self][f]
                if handlers.Registered then
                    handlers.Registered()
                end

                for _, v in ipairs(handlers.Added) do
                    v(self)
                end
            end

            if f == "CloseWindow" then
                self["Register" .. f .. "_"](
                    self, function()
                        cb()

                        if self.StorePosition then
                            self:StorePosition(false)
                            private[self].StoredX = self.StoredX
                            private[self].StoredY = self.StoredY
                        end
                    end)
            else
                self["Register" .. f .. "_"](self, cb)
            end
        end
    end

    -- Register proxy for HandlerTimer if it's available in this RGPLua version.
    if self.RegisterHandleTimer_ then
        self:RegisterHandleTimer_(
            function(timerid)
                -- Call registered handler if there is one
                if private[self].HandleTimer.Registered then
                    -- Pass window as additional parameter
                    private[self].HandleTimer.Registered(timerid, self)
                end

                -- Call any added handlers for this timer
                if private[self].HandleTimer[timerid] then
                    for _, cb in ipairs(private[self].HandleTimer[timerid]) do
                        -- Pass window as additional parameter
                        cb(timerid, self)
                    end
                end
            end)
    end
end

--[[
% RegisterHandleCommand

**[Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature.
: (boolean) `true` on success
]]

--[[
% RegisterHandleDataListCheck

**[Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleDataListCheck` in the PDK for callback signature.
: (boolean) `true` on success
]]

--[[
% RegisterHandleDataListSelect

**[Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature.
: (boolean) `true` on success
]]

--[[
% RegisterHandleUpDownPressed

**[Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature.
: (boolean) `true` on success
]]
for _, f in ipairs(control_handlers) do
    props["Register" .. f] = function(self, callback)
        mixin.assert_argument(callback, "function", 2)

        private[self][f].Registered = callback
        return true
    end
end

--[[
% CancelButtonPressed

**[Callback Template] [Override]**
Can optionally receive the window object.

@ [window] (FCMCustomLuaWindow)
]]

--[[
% RegisterHandleCancelButtonPressed

**[Override]**

@ self (FCMCustomLuaWindow)
@ callback (function) See `CancelButtonPressed` for callback signature.
: (boolean) `true` on success
]]

--[[
% OkButtonPressed

**[Callback Template] [Override]**
Can optionally receive the window object.

@ [window] (FCMCustomLuaWindow)
]]

--[[
% RegisterHandleOkButtonPressed

**[Override]**

@ self (FCMCustomLuaWindow)
@ callback (function)  See `OkButtonPressed` for callback signature.
: (boolean) `true` on success
]]

--[[
% InitWindow

**[Callback Template] [Override]**
Can optionally receive the window object.

@ [window] (FCMCustomLuaWindow)
]]

--[[
% RegisterInitWindow

**[Override]**

@ self (FCMCustomLuaWindow)
@ callback (function) See `InitWindow` for callback signature.
: (boolean) `true` on success
]]

--[[
% CloseWindow

**[Callback Template] [Override]**
Can optionally receive the window object.

@ [window] (FCMCustomLuaWindow)
]]

--[[
% RegisterCloseWindow

**[Override]**

@ self (FCMCustomLuaWindow)
@ callback (function) See `CloseWindow` for callback signature.
: (boolean) `true` on success
]]
for _, f in ipairs(other_handlers) do
    props["Register" .. f] = function(self, callback)
        mixin.assert_argument(callback, "function", 2)

        private[self][f].Registered = callback
        return true
    end
end

--[[
% AddHandleCommand

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleCommand` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature.
]]

--[[
% AddHandleDataListCheck

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleDataListCheck` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleDataListCheck` in the PDK for callback signature.
]]

--[[
% AddHandleDataListSelect

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleDataListSelect` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature.
]]

--[[
% AddHandleUpDownPressed

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleUpDownPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature.
]]
for _, f in ipairs(control_handlers) do
    props["Add" .. f] = function(self, callback)
        mixin.assert_argument(callback, "function", 2)

        table.insert(private[self][f].Added, callback)
    end
end

--[[
% AddHandleCancelButtonPressed

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterCancelButtonPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `CancelButtonPressed` for callback signature.
]]

--[[
% AddHandleOkButtonPressed

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterOkButtonPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `OkButtonPressed` for callback signature.
]]

--[[
% AddInitWindow

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterInitWindow` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `InitWindow` for callback signature.
]]

--[[
% AddCloseWindow

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterCloseWindow` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `CloseWindow` for callback signature.
]]
for _, f in ipairs(other_handlers) do
    props["Add" .. f] = function(self, callback)
        mixin.assert_argument(callback, "function", 2)

        table.insert(private[self][f].Added, callback)
    end
end

--[[
% RemoveHandleCommand

**[Fluid]**
Removes a handler added by `AddHandleCommand`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% RemoveHandleDataListCheck

**[Fluid]**
Removes a handler added by `AddHandleDataListCheck`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% RemoveHandleDataListSelect

**[Fluid]**
Removes a handler added by `AddHandleDataListSelect`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% RemoveHandleUpDownPressed

**[Fluid]**
Removes a handler added by `AddHandleUpDownPressed`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]
for _, f in ipairs(control_handlers) do
    props["Remove" .. f] = function(self, callback)
        mixin.assert_argument(callback, "function", 2)

        utils.table_remove_first(private[self][f].Added, callback)
    end
end

--[[
% RemoveHandleCancelButtonPressed

**[Fluid]**
Removes a handler added by `AddHandleCancelButtonPressed`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% RemoveHandleOkButtonPressed

**[Fluid]**
Removes a handler added by `AddHandleOkButtonPressed`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% RemoveInitWindow

**[Fluid]**
Removes a handler added by `AddInitWindow`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% RemoveCloseWindow

**[Fluid]**
Removes a handler added by `AddCloseWindow`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]
for _, f in ipairs(other_handlers) do
    props["Remove" .. f] = function(self, callback)
        mixin.assert_argument(callback, "function", 2)

        utils.table_remove_first(private[self][f].Added, callback)
    end
end

--[[
% QueueHandleCustom

**[Fluid] [Internal]**
Adds a function to the queue which will be executed in the same context as an event handler at the next available opportunity.
Once called, the callback will be removed from tbe queue (i.e. it will only be called once). For multiple calls, the callback will need to be added to the queue again.
The callback will not be passed any arguments.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]
function props:QueueHandleCustom(callback)
    mixin.assert_argument(callback, "function", 2)

    table.insert(private[self].HandleCustomQueue, callback)
end

if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then

    --[[
% RegisterHandleControlEvent

**[>= v0.56] [Override]**
Ensures that the handler is passed the original control object.

@ self (FCMCustomLuaWindow)
@ control (FCMControl)
@ callback (function) See `FCCustomLuaWindow.HandleControlEvent` in the PDK for callback signature.
: (boolean) `true` on success
]]
    function props:RegisterHandleControlEvent(control, callback)
        mixin.assert_argument(callback, "function", 3)

        return self:RegisterHandleControlEvent_(
                   control, function(ctrl)
                callback(self.FindControl(ctrl:GetControlID()))
            end)
    end

    --[[
% SetTimer

**[>= v0.56] [Fluid] [Override]**

@ self (FCCustomLuaWindow)
@ timerid (number)
@ msinterval (number)
]]
    function props:SetTimer(timerid, msinterval)
        mixin.assert_argument(timerid, "number", 2)
        mixin.assert_argument(msinterval, "number", 3)

        self:SetTimer_(timerid, msinterval)

        private[self].HandleTimer[timerid] = private[self].HandleTimer[timerid] or {}
    end

    --[[
% GetNextTimerID

**[>= v0.56]**
Returns the next available timer ID.

@ self (FCMCustomLuaWindow)
: (number)
]]
    function props:GetNextTimerID()
        while private[self].HandleTimer[private[self].NextTimerID] do
            private[self].NextTimerID = private[self].NextTimerID + 1
        end

        return private[self].NextTimerID
    end

    --[[
% SetNextTimer

**[>= v0.56]**
Sets a timer using the next available ID (according to `GetNextTimerID`) and returns the ID.

@ self (FCMCustomLuaWindow)
@ msinterval (number)
: (number) The ID of the newly created timer.
]]
    function props:SetNextTimer(msinterval)
        mixin.assert_argument(msinterval, "number", 2)

        local timerid = self:GetNextTimerID()
        self:SetTimer(timerid, msinterval)

        return timerid
    end

    --[[
% HandleTimer

**[Callback Template] [Override]**
Can optionally receive the window object.

@ timerid (number)
@ [window] (FCMCustomLuaWindow)
]]

    --[[
% RegisterHandleTimer

**[>= v0.56] [Override]**

@ self (FCMCustomLuaWindow)
@ callback (function) See `HandleTimer` for callback signature.
: (boolean) `true` on success
]]
    function props:RegisterHandleTimer(callback)
        mixin.assert_argument(callback, "function", 2)

        private[self].HandleTimer.Registered = callback
        return true
    end

    --[[
% AddHandleTimer

**[>= v0.56] [Fluid]**
Adds a handler for a timer. Handlers added by this method will be called after the registered handler, if there is one.
If a handler is added for a timer that hasn't been set, the timer ID will be no longer be available to `GetNextTimerID` and `SetNextTimer`.

@ self (FCMCustomLuaWindow)
@ timerid (number)
@ callback (function) See `CancelButtonPressed` for callback signature.
]]
    function props:AddHandleTimer(timerid, callback)
        mixin.assert_argument(timerid, "number", 2)
        mixin.assert_argument(callback, "function", 3)

        private[self].HandleTimer[timerid] = private[self].HandleTimer[timerid] or {}

        table.insert(private[self].HandleTimer[timerid], callback)
    end

    --[[
% RemoveHandleTimer

**[>= v0.56] [Fluid]**
Removes a handler added with `AddHandleTimer`.

@ self (FCMCustomLuaWindow)
@ timerid (number)
@ callback (function)
]]
    function props:RemoveHandleTimer(timerid, callback)
        mixin.assert_argument(timerid, "number", 2)
        mixin.assert_argument(callback, "function", 3)

        if not private[self].HandleTimer[timerid] then
            return
        end

        utils.table_remove_first(private[self].HandleTimer[timerid], callback)
    end
end

--[[
% HasBeenShown

Checks if the window has been shown, either as a modal or modeless.

@ self (FCMCustomLuaWindow)
: (boolean) `true` if it has been shown, `false` if not
]]
function props:HasBeenShown()
    return private[self].HasBeenShown
end

if finenv.MajorVersion > 0 or finenv.MinorVersion >= 60 then
    --[[
% SetAutoRestorePosition

**[>= v0.60] [Fluid]**
Enables/disables automatic restoration of the window's position on subsequent openings.
This is disabled by default.

@ self (FCMCustomLuaWindow)
@ enabled (boolean)
]]
    function props:SetAutoRestorePosition(enabled)
        mixin.assert_argument(enabled, "boolean", 2)

        private[self].AutoRestorePosition = enabled
    end

    --[[
% GetAutoRestorePosition

**[>= v0.60]**
Returns whether automatic restoration of window position is enabled.

@ self (FCMCustomLuaWindow)
: (boolean) `true` if enabled, `false` if disabled.
]]
    function props:GetAutoRestorePosition()
        return private[self].AutoRestorePosition
    end

    --[[
% SetRestorePositionData

**[>= v0.60] [Fluid] [Override]**
If the position is changed while window is closed, ensures that the new position data will be used in auto restoration when window is shown.

@ self (FCMCustomLuaWindow)
@ x (number)
@ y (number)
@ width (number)
@ height (number)
]]
    function props:SetRestorePositionData(x, y, width, height)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)
        mixin.assert_argument(width, "number", 4)
        mixin.assert_argument(height, "number", 5)

        self:SetRestorePositionOnlyData_(x, y, width, height)

        if self:HasBeenShown() and not self:WindowExists() then
            private[self].StoredX = x
            private[self].StoredY = y
        end
    end

    --[[
% SetRestorePositionOnlyData

**[>= v0.60] [Fluid] [Override]**
If the position is changed while window is closed, ensures that the new position data will be used in auto restoration when window is shown.

@ self (FCMCustomLuaWindow)
@ x (number)
@ y (number)
]]
    function props:SetRestorePositionOnlyData(x, y)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)

        self:SetRestorePositionOnlyData_(x, y)

        if self:HasBeenShown() and not self:WindowExists() then
            private[self].StoredX = x
            private[self].StoredY = y
        end
    end
end

--[[
% ExecuteModal

**[Override]**
Sets the `HasBeenShown` flag and restores the previous position if auto restore is on.

@ self (FCMCustomLuaWindow)
: (number)
]]
function props:ExecuteModal(parent)
    restore_position(self)
    private[self].HasBeenShown = true
    return mixin.FCMCustomWindow.ExecuteModal(self, parent)
end

--[[
% ShowModeless

**[Override]**
Sets the `HasBeenShown` flag and restores the previous position if auto restore is on.

@ self (FCMCustomLuaWindow)
: (boolean)
]]
function props:ShowModeless()
    restore_position(self)
    private[self].HasBeenShown = true
    return self:ShowModeless_()
end

return props

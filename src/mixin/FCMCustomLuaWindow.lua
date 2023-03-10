--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCustomLuaWindow

## Summary of Modifications
- Window is automatically registered with `finenv.RegisterModelessDialog` when `ShowModeless` is called.
- All `Register*` methods (apart from `RegisterHandleControlEvent`) have accompanying `Add*` and `Remove*` methods to enable multiple handlers to be added per event.
- Handlers for all window events (ie not control events) recieve the window object as the first argument.
- Control handlers are passed original object to preserve mixin data.
- Added custom callback queue which can be used by custom events to add dispatchers that will run with the next control event.
- Added `HasBeenShown` method for checking if the window has been previously shown.
- Added methods for the automatic restoration of previous window position when showing (RGPLua > 0.60) for use with `finenv.RetainLuaState` and modeless windows.
- Added `DebugClose` option to assist with debugging (if ALT or SHIFT key is pressed when window is closed and debug mode is enabled, finenv.RetainLuaState will be set to false).
- Measurement unit can be set on the window or changed by the user through a `FCXCtrlMeasurementUnitPopup`.
- Windows also have the option of inheriting the parent window's measurement unit when opening.
- Introduced a `MeasurementUnitChange` event.
- All controls with an `UpdateMeasurementUnit` method will have that method called upon a measurement unit change to allow them to immediately update their displayed values without needing to wait for a `MeasurementUnitChange` event.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local utils = require("library.utils")
local measurement = require("library.measurement")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local trigger_measurement_unit_change
local each_last_measurement_unit_change

-- HandleTimer is omitted from this list because it is handled separately
local window_events = {"HandleCancelButtonPressed", "HandleOkButtonPressed", "InitWindow", "CloseWindow"}
local control_events = {"HandleCommand", "HandleDataListCheck", "HandleDataListSelect", "HandleUpDownPressed"}

local function flush_custom_queue(self)
    local queue = private[self].HandleCustomQueue
    private[self].HandleCustomQueue = {}

    for _, callback in ipairs(queue) do
        callback()
    end
end

local function restore_position(self)
    if private[self].HasBeenShown and private[self].EnableAutoRestorePosition and self.StorePosition then
        self:StorePosition(false)
        self:SetRestorePositionOnlyData_(private[self].StoredX, private[self].StoredY)
        self:RestorePosition()
    end
end

-- A generic event dispatcher
local function dispatch_event_handlers(self, event, context, ...)
    local handlers = private[self][event]
    if handlers.Registered then
        handlers.Registered(context, ...)
    end

    for _, handler in ipairs(handlers.Added) do
        handler(context, ...)
    end
end

local function create_handle_methods(event)
    -- Check if methods are available
    props["Register" .. event] = function(self, callback)
        mixin_helper.assert_argument_type(2, callback, "function")

        private[self][event].Registered = callback
    end

    props["Add" .. event] = function(self, callback)
        mixin_helper.assert_argument_type(2, callback, "function")

        table.insert(private[self][event].Added, callback)
    end

    props["Remove" .. event] = function(self, callback)
        mixin_helper.assert_argument_type(2, callback, "function")

        utils.table_remove_first(private[self][event].Added, callback)
    end
end

--[[
% Init

**[Internal]**

@ self (FCMCustomLuaWindow)
]]
function props:Init()
    private[self] = private[self] or {
        HandleTimer = {},
        HandleCustomQueue = {},
        HasBeenShown = false,
        EnableDebugClose = false,
        RestoreControlState = true,
        EnableAutoRestorePosition = true,
        StoredX = nil,
        StoredY = nil,
        MeasurementUnit = measurement.get_real_default_unit(),
        UseParentMeasurementUnit = true,
    }


    -- Registers proxy functions up front to ensure that the handlers are passed the original object along with its mixin data
    for _, event in ipairs(control_events) do
        private[self][event] = {Added = {}}

        if self["Register" .. event .. "_"] then
            -- Handlers sometimes run twice, the second while the first is still running, so this flag prevents race conditions and concurrency issues.
            local is_running = false

            self["Register" .. event .. "_"](self, function(control, ...)
                if is_running then
                    return
                end

                is_running = true

                -- Flush custom queue once
                flush_custom_queue(self)

                -- Execute handlers for main control
                local real_control = self:FindControl(control:GetControlID())

                if not real_control then
                    error("Control with ID #" .. tostring(control:GetControlID()) .. " not found in '" .. f .. "'")
                end

                dispatch_event_handlers(self, event, real_control, ...)

                -- Flush custom queue until empty
                while #private[self].HandleCustomQueue > 0 do
                    flush_custom_queue(self)
                end

                is_running = false
            end)
        end
    end


    -- Register proxies for window handlers
    for _, event in ipairs(window_events) do
        private[self][event] = {Added = {}}

        if not self["Register" .. event .. "_"] then
            goto continue
        end

        if event == "InitWindow" then
            self["Register" .. event .. "_"](self, function(...)
                if private[self].HasBeenShown and private[self].RestoreControlState then
                    for control in each(self) do
                        control:RestoreState()
                    end
                end

                dispatch_event_handlers(self, event, self, ...)
            end)
        elseif event == "CloseWindow" then
            self["Register" .. event .. "_"](self, function(...)
                if private[self].EnableDebugClose and finenv.RetainLuaState ~= nil then
                    if finenv.DebugEnabled and (self:QueryLastCommandModifierKeys(finale.CMDMODKEY_ALT) or self:QueryLastCommandModifierKeys(finale.CMDMODKEY_SHIFT)) then
                        finenv.RetainLuaState = false
                    end
                end

                -- Catch any errors so they don't disrupt storing window position and control state
                local success, error_msg = pcall(dispatch_event_handlers, self, event, self, ...)

                if self.StorePosition then
                    self:StorePosition(false)
                    private[self].StoredX = self.StoredX
                    private[self].StoredY = self.StoredY
                end

                if private[self].RestoreControlState then
                    for control in each(self) do
                        control:StoreState()
                    end
                end

                private[self].HasBeenShown = true

                if not success then
                    error(error_msg, 0)
                end
            end)
        else
            self["Register" .. event .. "_"](self, function(...)
                dispatch_event_handlers(self, event, self, ...)
            end)
        end

        :: continue ::
    end

    -- Register proxy for HandlerTimer if it's available in this RGPLua version.
    if self.RegisterHandleTimer_ then
        self:RegisterHandleTimer_(function(timerid)
            -- Call registered handler if there is one
            if private[self].HandleTimer.Registered then
                -- Pass window as first parameter
                private[self].HandleTimer.Registered(self, timerid)
            end

            -- Call any added handlers for this timer
            if private[self].HandleTimer[timerid] then
                for _, callback in ipairs(private[self].HandleTimer[timerid]) do
                    -- Pass window as first parameter
                    callback(self, timerid)
                end
            end
        end)
    end
end

--[[
% RegisterHandleCommand

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature.
]]

--[[
% AddHandleCommand

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterHandleCommand` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature.
]]

--[[
% RemoveHandleCommand

**[Fluid]**

Removes a handler added by `AddHandleCommand`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% RegisterHandleDataListCheck

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleDataListCheck` in the PDK for callback signature.
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
% RemoveHandleDataListCheck

**[Fluid]**

Removes a handler added by `AddHandleDataListCheck`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% RegisterHandleDataListSelect

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature.
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
% RemoveHandleDataListSelect

**[Fluid]**

Removes a handler added by `AddHandleDataListSelect`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% RegisterHandleUpDownPressed

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature.
]]

--[[
% AddHandleUpDownPressed

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterHandleUpDownPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature.
]]

--[[
% RemoveHandleUpDownPressed

**[Fluid]**

Removes a handler added by `AddHandleUpDownPressed`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]
for _, event in ipairs(control_events) do
    create_handle_methods(event)
end

--[[
% CancelButtonPressed

**[Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

@ self (FCMCustomLuaWindow)
]]

--[[
% RegisterHandleCancelButtonPressed

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ callback (function) See `CancelButtonPressed` for callback signature.
]]

--[[
% AddHandleCancelButtonPressed

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterCancelButtonPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `CancelButtonPressed` for callback signature.
]]

--[[
% RemoveHandleCancelButtonPressed

**[Fluid]**

Removes a handler added by `AddHandleCancelButtonPressed`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% OkButtonPressed

**[Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

@ self (FCMCustomLuaWindow)
]]

--[[
% RegisterHandleOkButtonPressed

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ callback (function)  See `OkButtonPressed` for callback signature.
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
% RemoveHandleOkButtonPressed

**[Fluid]**

Removes a handler added by `AddHandleOkButtonPressed`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% InitWindow

**[Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

@ self (FCMCustomLuaWindow)
]]

--[[
% RegisterInitWindow

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ callback (function) See `InitWindow` for callback signature.
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
% RemoveInitWindow

**[Fluid]**

Removes a handler added by `AddInitWindow`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]

--[[
% CloseWindow

**[Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

@ self (FCMCustomLuaWindow)
]]

--[[
% RegisterCloseWindow

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ callback (function) See `CloseWindow` for callback signature.
]]

--[[
% AddCloseWindow

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterCloseWindow` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

@ self (FCMCustomLuaWindow)
@ callback (function) See `CloseWindow` for callback signature.
]]

--[[
% RemoveCloseWindow

**[Fluid]**

Removes a handler added by `AddCloseWindow`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]
for _, event in ipairs(window_events) do
    create_handle_methods(event)
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
    mixin_helper.assert_argument_type(2, callback, "function")

    table.insert(private[self].HandleCustomQueue, callback)
end

if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then

--[[
% RegisterHandleControlEvent

**[>= v0.56] [Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ control (FCMControl)
@ callback (function) See `FCCustomLuaWindow.HandleControlEvent` in the PDK for callback signature.
]]
    function props:RegisterHandleControlEvent(control, callback)
        mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
        mixin_helper.assert_argument_type(3, callback, "function")

        if not self:RegisterHandleControlEvent_(control, function(ctrl)
            callback(self:FindControl(ctrl:GetControlID()))
        end) then
            error("'FCMCustomLuaWindow.RegisterHandleControlEvent' has encountered an error.", 2)
        end
    end
end

if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then
--[[
% HandleTimer

**[Breaking Change] [Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

@ self (FCMCustomLuaWindow)
@ timerid (number)
]]

--[[
% RegisterHandleTimer

**[>= v0.56] [Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCustomLuaWindow)
@ callback (function) See `HandleTimer` for callback signature (note the change in arguments).
]]
    function props:RegisterHandleTimer(callback)
        mixin_helper.assert_argument_type(2, callback, "function")

        private[self].HandleTimer.Registered = callback
    end

--[[
% AddHandleTimer

**[>= v0.56] [Fluid]**

Adds a handler for a timer. Handlers added by this method will be called after the registered handler, if there is one.
If a handler is added for a timer that hasn't been set, the timer ID will no longer be available to `GetNextTimerID` and `SetNextTimer`.

@ self (FCMCustomLuaWindow)
@ timerid (number)
@ callback (function) See `HandleTimer` for callback signature.
]]
    function props:AddHandleTimer(timerid, callback)
        mixin_helper.assert_argument_type(2, timerid, "number")
        mixin_helper.assert_argument_type(3, callback, "function")

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
        mixin_helper.assert_argument_type(2, timerid, "number")
        mixin_helper.assert_argument_type(3, callback, "function")

        if not private[self].HandleTimer[timerid] then
            return
        end

        utils.table_remove_first(private[self].HandleTimer[timerid], callback)
    end

--[[
% SetTimer

**[>= v0.56] [Fluid] [Override]**

Override Changes:
- Add setup to allow multiple handlers to be added for a timer.

@ self (FCCustomLuaWindow)
@ timerid (number)
@ msinterval (number)
]]
    function props:SetTimer(timerid, msinterval)
        mixin_helper.assert_argument_type(2, timerid, "number")
        mixin_helper.assert_argument_type(3, msinterval, "number")

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
        mixin_helper.assert_argument_type(2, msinterval, "number")

        local timerid = mixin.FCMCustomLuaWindow.GetNextTimerID(self)
        mixin.FCMCustomLuaWindow.SetTimer(self, timerid, msinterval)

        return timerid
    end
end

if finenv.MajorVersion > 0 or finenv.MinorVersion >= 60 then

--[[
% SetEnableAutoRestorePosition

**[>= v0.60] [Fluid]**

Enables/disables automatic restoration of the window's position on subsequent openings.
This is disabled by default.

@ self (FCMCustomLuaWindow)
@ enabled (boolean)
]]
    function props:SetEnableAutoRestorePosition(enabled)
        mixin_helper.assert_argument_type(2, enabled, "boolean")

        private[self].EnableAutoRestorePosition = enabled
    end

--[[
% GetEnableAutoRestorePosition

**[>= v0.60]**

Returns whether automatic restoration of window position is enabled.

@ self (FCMCustomLuaWindow)
: (boolean) `true` if enabled, `false` if disabled.
]]
    function props:GetEnableAutoRestorePosition()
        return private[self].EnableAutoRestorePosition
    end

--[[
% SetRestorePositionData

**[>= v0.60] [Fluid] [Override]**

Override Changes:
- If this method is called while the window is closed, the new position data will be used in automatic position restoration when window is next shown.

@ self (FCMCustomLuaWindow)
@ x (number)
@ y (number)
@ width (number)
@ height (number)
]]
    function props:SetRestorePositionData(x, y, width, height)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, width, "number")
        mixin_helper.assert_argument_type(5, height, "number")

        self:SetRestorePositionOnlyData_(x, y, width, height)

        if private[self].HasBeenShown and not self:WindowExists() then
            private[self].StoredX = x
            private[self].StoredY = y
        end
    end

--[[
% SetRestorePositionOnlyData

**[>= v0.60] [Fluid] [Override]**

Override Changes:
- If this method is called while the window is closed, the new position data will be used in automatic position restoration when window is next shown.

@ self (FCMCustomLuaWindow)
@ x (number)
@ y (number)
]]
    function props:SetRestorePositionOnlyData(x, y)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")

        self:SetRestorePositionOnlyData_(x, y)

        if private[self].HasBeenShown and not self:WindowExists() then
            private[self].StoredX = x
            private[self].StoredY = y
        end
    end
end

--[[
% SetEnableDebugClose

**[Fluid]**

If enabled and in debug mode, when the window is closed with either ALT or SHIFT key pressed, `finenv.RetainLuaState` will be set to `false`.
This is done before CloseWindow handlers are called.
This is disabled by default.

@ self (FCMCustomLuaWindow)
@ enabled (boolean)
]]
function props:SetEnableDebugClose(enabled)
    mixin_helper.assert_argument_type(2, enabled, "boolean")

    private[self].EnableDebugClose = enabled and true or false
end

--[[
% GetEnableDebugClose

Returns the enabled state of the `DebugClose` option.

@ self (FCMCustomLuaWindow)
: (boolean) `true` if enabled, `false` if disabled.
]]
function props:GetEnableDebugClose()
    return private[self].EnableDebugClose
end

--[[
% SetRestoreControlState

**[Fluid]**

Enables or disables the automatic restoration of control state on subsequent showings of the window.
This is disabled by default.

@ self (FCMCustomLuaWindow)
@ enabled (boolean) `true` to enable, `false` to disable.
]]
function props:SetRestoreControlState(enabled)
    mixin_helper.assert_argument_type(2, enabled, "boolean")

    private[self].RestoreControlState = enabled and true or false
end

--[[
% GetRestoreControlState

Checks if control state restoration is enabled.

@ self (FCMCustomLuaWindow)
: (boolean) `true` if enabled, `false` if disabled.
]]
function props:GetRestoreControlState()
    return private[self].RestoreControlState
end

--[[
% HasBeenShown

Checks if the window has been shown at least once prior, either as a modal or modeless.

@ self (FCMCustomLuaWindow)
: (boolean) `true` if it has been shown, `false` if not
]]
function props:HasBeenShown()
    return private[self].HasBeenShown
end

--[[
% ExecuteModal

**[Override]**

Override Changes:
- If a parent window is passed and the `UseParentMeasurementUnit` setting is enabled, this window's measurement unit is automatically changed to match the parent window.
- Restores the previous position if `AutoRestorePosition` is enabled.

@ self (FCMCustomLuaWindow)
@ parent (FCCustomWindow | FCMCustomWindow | nil)
: (number)
]]
function props:ExecuteModal(parent)
    if mixin_helper.is_instance_of(parent, "FCMCustomLuaWindow") and private[self].UseParentMeasurementUnit then
        self:SetMeasurementUnit(parent:GetMeasurementUnit())
    end

    restore_position(self)
    return mixin.FCMCustomWindow.ExecuteModal(self, parent)
end

--[[
% ShowModeless

**[Override]**

Override Changes:
- Automatically registers the dialog with `finenv.RegisterModelessDialog`.
- Restores the previous position if `AutoRestorePosition` is enabled.

@ self (FCMCustomLuaWindow)
: (boolean)
]]
function props:ShowModeless()
    finenv.RegisterModelessDialog(self)
    restore_position(self)
    return self:ShowModeless_()
end

--[[
% RunModeless

**[Fluid]**

Runs the window as a self-contained modeless plugin, performing the following steps:
- The first time the plugin is run, if ALT or SHIFT keys are pressed, sets `OkButtonCanClose` to true
- On subsequent runnings, if ALT or SHIFT keys are pressed the default action will be called without showing the window
- The default action defaults to the function registered with `RegisterHandleOkButtonPressed`
- If in JWLua, the window will be shown as a modal and it will check that a music region is currently selected

@ self (FCMCustomLuaWindow)
@ [selection_not_required] (boolean) If `true` and showing as a modal, will skip checking if a region is selected.
@ [default_action_override] (boolean | function) If `false`, there will be no default action. If a `function`, overrides the registered `OkButtonPressed` handler as the default action.
]]
function props:RunModeless(selection_not_required, default_action_override)
    local modifier_keys_on_invoke = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    local default_action = default_action_override == nil and private[self].HandleOkButtonPressed.Registered or default_action_override

    if modifier_keys_on_invoke and self:HasBeenShown() and default_action then
        default_action(self)
        return
    end

    if finenv.IsRGPLua then
        -- OkButtonCanClose will be nil before RGPLua v0.56 and true (the default) after
        if self.OkButtonCanClose then
            self.OkButtonCanClose = modifier_keys_on_invoke
        end

        if self:ShowModeless() then
            finenv.RetainLuaState = true
        end
    else
        if not selection_not_required and finenv.Region():IsEmpty() then
            finenv.UI():AlertInfo("Please select a music region before running this script.", "Selection Required")
            return
        end

        self:ExecuteModal(nil)
    end
end

--[[
% GetMeasurementUnit

Returns the window's current measurement unit.

@ self (FCMCustomLuaWindow)
: (number) The value of one of the finale MEASUREMENTUNIT constants.
]]
function props:GetMeasurementUnit()
    return private[self].MeasurementUnit
end

--[[
% SetMeasurementUnit

**[Fluid]**

Sets the window's current measurement unit. Millimeters are not supported.

All controls that have an `UpdateMeasurementUnit` method will have that method called to allow them to immediately update their displayed measurement unit immediately without needing to wait for a `MeasurementUnitChange` event.

@ self (FCMCustomLuaWindow)
@ unit (number) One of the finale MEASUREMENTUNIT constants.
]]
function props:SetMeasurementUnit(unit)
    mixin_helper.assert_argument_type(2, unit, "number")

    if unit == private[self].MeasurementUnit then
        return
    end

    if unit == finale.MEASUREMENTUNIT_DEFAULT then
        unit = measurement.get_real_default_unit()
    end

    mixin.force_assert(measurement.is_valid_unit(unit), "Measurement unit is not valid.")

    private[self].MeasurementUnit = unit

    -- Update all measurement controls
    for ctrl in each(self) do
        local func = ctrl.UpdateMeasurementUnit
        if func then
            func(ctrl)
        end
    end

    trigger_measurement_unit_change(self)
end

--[[
% GetMeasurementUnitName

Returns the name of the window's current measurement unit.

@ self (FCMCustomLuaWindow)
: (string)
]]
function props:GetMeasurementUnitName()
    return measurement.get_unit_name(private[self].MeasurementUnit)
end

--[[
% GetUseParentMeasurementUnit

Returns a boolean indicating whether this window will use the measurement unit of its parent window when opened.

@ self (FCMCustomLuaWindow)
: (boolean)
]]
function props:GetUseParentMeasurementUnit(enabled)
    return private[self].UseParentMeasurementUnit
end

--[[
% SetUseParentMeasurementUnit

**[Fluid]**

Sets whether to use the parent window's measurement unit when opening this window. Default is enabled.

@ self (FCMCustomLuaWindow)
@ enabled (boolean)
]]
function props:SetUseParentMeasurementUnit(enabled)
    mixin_helper.assert_argument_type(2, enabled, "boolean")

    private[self].UseParentMeasurementUnit = enabled and true or false
end

--[[
% HandleMeasurementUnitChange

**[Callback Template]**

Template for MeasurementUnitChange handlers.

@ self (FCMCustomLuaWindow)
@ last_unit (number) The window's previous measurement unit.
]]

--[[
% AddHandleMeasurementUnitChange

**[Fluid]**

Adds a handler for a change in the window's measurement unit.
The even will fire when:
- The window is created (if the measurement unit is not `finale.MEASUREMENTUNIT_DEFAULT`)
- The measurement unit is changed by the user via a `FCXCtrlMeasurementUnitPopup`
- The measurement unit is changed programmatically (if the measurement unit is changed within a handler, that *same* handler will not be called again for that change.)

@ self (FCMCustomLuaWindow)
@ callback (function) See `HandleMeasurementUnitChange` for callback signature.
]]

--[[
% RemoveHandleMeasurementUnitChange

**[Fluid]**

Removes a handler added with `AddHandleMeasurementUnitChange`.

@ self (FCMCustomLuaWindow)
@ callback (function)
]]
props.AddHandleMeasurementUnitChange, props.RemoveHandleMeasurementUnitChange, trigger_measurement_unit_change, each_last_measurement_unit_change = mixin_helper.create_custom_window_change_event(
    {
        name = "last_unit",
        get = function(window)
            return mixin.FCMCustomLuaWindow.GetMeasurementUnit(window)
        end,
        initial = measurement.get_real_default_unit(),
    }
)

--[[
% CreateMeasurementEdit

Creates an `FCXCtrlMeasurementEdit` control.

@ self (FCMCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlMeasurementEdit)
]]
function props:CreateMeasurementEdit(x, y, control_name)
    mixin_helper.assert_argument_type(2, x, "number")
    mixin_helper.assert_argument_type(3, y, "number")
    mixin_helper.assert_argument_type(4, control_name, "string", "nil")

    local edit = mixin.FCMCustomWindow.CreateEdit(self, x, y, control_name)
    return mixin.subclass(edit, "FCXCtrlMeasurementEdit")
end

--[[
% CreateMeasurementUnitPopup

Creates a popup which allows the user to change the window's measurement unit.

@ self (FCMCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlMeasurementUnitPopup)
]]
function props:CreateMeasurementUnitPopup(x, y, control_name)
    mixin_helper.assert_argument_type(2, x, "number")
    mixin_helper.assert_argument_type(3, y, "number")
    mixin_helper.assert_argument_type(4, control_name, "string", "nil")

    local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
    return mixin.subclass(popup, "FCXCtrlMeasurementUnitPopup")
end

--[[
% CreatePageSizePopup

Creates a popup which allows the user to select a page size.

@ self (FCMCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlPageSizePopup)
]]
function props:CreatePageSizePopup(x, y, control_name)
    mixin_helper.assert_argument_type(2, x, "number")
    mixin_helper.assert_argument_type(3, y, "number")
    mixin_helper.assert_argument_type(4, control_name, "string", "nil")

    local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
    return mixin.subclass(popup, "FCXCtrlPageSizePopup")
end

return props

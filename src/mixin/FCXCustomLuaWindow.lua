--  Author: Edward Koltun
--  Date: April 10, 2022
--[[
$module FCXCustomLuaWindow

*Extends `FCMCustomLuaWindow`*

Summary of modifications:
- Changed argument order for timer handlers so that window is passed first, before `timerid` (enables handlers to be method of window).
- Added `Add*` and `Remove*` handler methods for timers
- Measurement unit can be set on the window or changed by the user through a `FCXCtrlMeasurementUnitPopup`.
- Windows also have the option of inheriting the parent window's measurement unit when opening.
- Introduced a `MeasurementUnitChange` event.
- All controls with an `UpdateMeasurementUnit` method will have that method called upon a measurement unit change to allow them to immediately update their displayed values without needing to wait for a `MeasurementUnitChange` event.
- Changed the default auto restoration behaviour for window position to enabled
- finenv.RegisterModelessDialog is called automatically when ShowModeless is called
- DebugClose is enabled by default
]] --
local mixin = require("library.mixin")
local utils = require("library.utils")
local mixin_helper = require("library.mixin_helper")
local measurement = require("library.measurement")

local private = setmetatable({}, {__mode = "k"})
local props = {MixinParent = "FCMCustomLuaWindow"}

local trigger_measurement_unit_change
local each_last_measurement_unit_change

--[[
% Init

**[Internal]**

@ self (FCXCustomLuaWindow)
]]
function props:Init()
    private[self] = private[self] or {
        MeasurementUnit = measurement.get_real_default_unit(),
        UseParentMeasurementUnit = true,
        HandleTimer = {},
        RunModelessDefaultAction = nil,
    }

    if self.SetAutoRestorePosition then
        self:SetAutoRestorePosition(true)
    end

    self:SetRestoreControlState(true)
    self:SetEnableDebugClose(true)

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
                for _, cb in ipairs(private[self].HandleTimer[timerid]) do
                    -- Pass window as first parameter
                    cb(self, timerid)
                end
            end
        end)
    end
end

--[[
% GetMeasurementUnit

Returns the window's current measurement unit.

@ self (FCXCustomLuaWindow)
: (number) The value of one of the finale MEASUREMENTUNIT constants.
]]
function props:GetMeasurementUnit()
    return private[self].MeasurementUnit
end

--[[
% SetMeasurementUnit

**[Fluid]**
Sets the window's current measurement unit. Millimeters are not supported.

All controls that have an `UpdateMeasurementUnit` method will have that method called to allow them to immediately update their displayed measurement unit without needing to wait for a `MeasurementUnitChange` event.

@ self (FCXCustomLuaWindow)
@ unit (number) One of the finale MEASUREMENTUNIT constants.
]]
function props:SetMeasurementUnit(unit)
    mixin.assert_argument(unit, "number", 2)

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

@ self (FCXCustomLuaWindow)
: (string)
]]
function props:GetMeasurementUnitName()
    return measurement.get_unit_name(private[self].MeasurementUnit)
end

--[[
% UseParentMeasurementUnit

**[Fluid]**
Sets whether to use the parent window's measurement unit when opening this window. Defaults to `true`.

@ self (FCXCustomLuaWindow)
@ on (boolean)
]]
function props:UseParentMeasurementUnit(on)
    mixin.assert_argument(on, "boolean", 2)

    private[self].UseParentMeasurementUnit = on
end

--[[
% CreateMeasurementEdit

Creates a `FCXCtrlMeasurementEdit` control.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlMeasurementEdit)
]]
function props:CreateMeasurementEdit(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local edit = mixin.FCMCustomWindow.CreateEdit(self, x, y, control_name)
    return mixin.subclass(edit, "FCXCtrlMeasurementEdit")
end

--[[
% CreateMeasurementUnitPopup

Creates a popup which allows the user to change the window's measurement unit.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlMeasurementUnitPopup)
]]
function props:CreateMeasurementUnitPopup(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
    return mixin.subclass(popup, "FCXCtrlMeasurementUnitPopup")
end

--[[
% CreatePageSizePopup

Creates a popup which allows the user to select a page size.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlPageSizePopup)
]]
function props:CreatePageSizePopup(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
    return mixin.subclass(popup, "FCXCtrlPageSizePopup")
end

--[[
% CreateStatic

**[Override]**
Creates an `FCXCtrlStatic` control.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlStatic)
]]
function props:CreateStatic(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local popup = mixin.FCMCustomWindow.CreateStatic(self, x, y, control_name)
    return mixin.subclass(popup, "FCXCtrlStatic")
end

--[[
% CreateUpDown

**[Override]**
Creates an `FCXCtrlUpDown` control.

@ self (FCXCustomLuaWindow)
@ x (number)
@ y (number)
@ [control_name] (string)
: (FCXCtrlUpDown)
]]
function props:CreateUpDown(x, y, control_name)
    mixin.assert_argument(x, "number", 2)
    mixin.assert_argument(y, "number", 3)
    mixin.assert_argument(control_name, {"string", "nil"}, 4)

    local updown = mixin.FCMCustomWindow.CreateUpDown(self, x, y, control_name)
    return mixin.subclass(updown, "FCXCtrlUpDown")
end


if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then
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
Insert window object as first argument to handler.

@ window (FCXCustomLuaWindow)
@ timerid (number)
]]

    --[[
% RegisterHandleTimer

**[>= v0.56] [Override]**

@ self (FCMCustomLuaWindow)
@ callback (function) See `HandleTimer` for callback signature (note the change of arguments).
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
% RegisterHandleOkButtonPressed

**[Fluid] [Override]**
Stores callback as default action for `RunModeless`.

@ self (FCXCustomLuaWindow)
@ callback (function) See documentation for `FCMCustomLuaWindow.OkButtonPressed` for callback signature.
]]
function props:RegisterHandleOkButtonPressed(callback)
    mixin.assert_argument(callback, "function", 2)

    private[self].RunModelessDefaultAction = callback
    mixin.FCMCustomLuaWindow.RegisterHandleOkButtonPressed(self, callback)
end

--[[
% ExecuteModal

**[Override]**
If a parent window is passed and the `UseParentMeasurementUnit` setting is on, the measurement unit is automatically changed to match the parent.

@ self (FCXCustomLuaWindow)
@ parent (FCCustomWindow|FCMCustomWindow|nil)
: (number)
]]
function props:ExecuteModal(parent)
    if mixin.is_instance_of(parent, "FCXCustomLuaWindow") and private[self].UseParentMeasurementUnit then
        self:SetMeasurementUnit(parent:GetMeasurementUnit())
    end

    return mixin.FCMCustomLuaWindow.ExecuteModal(self, parent)
end

--[[
% ShowModeless

**[Override]**
Automatically registers the dialog with `finenv.RegisterModelessDialog`.

@ self (FCXCustomLuaWindow)
: (boolean)
]]
function props:ShowModeless()
    finenv.RegisterModelessDialog(self)
    return mixin.FCMCustomLuaWindow.ShowModeless(self)
end

--[[
% RunModeless

**[Fluid]**
Runs the window as a self-contained modeless plugin, performing the following steps:
- The first time the plugin is run, if ALT or SHIFT keys are pressed, sets `OkButtonCanClose` to true
- On subsequent runnings, if ALT or SHIFT keys are pressed the default action will be called without showing the window
- The default action defaults to the function registered with `RegisterHandleOkButtonPressed`
- If in JWLua, the window will be shown as a modal and it will check that a music region is currently selected

@ self (FCXCustomLuaWindow)
@ [no_selection_required] (boolean) If `true` and showing as a modal, will skip checking if a region is selected.
@ [default_action_override] (boolean|function) If `false`, there will be no default action. If a `function`, overrides the registered `OkButtonPressed` handler as the default action.
]]
function props:RunModeless(no_selection_required, default_action_override)
    local modifier_keys_on_invoke = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    local default_action = default_action_override == nil and private[self].RunModelessDefaultAction or default_action_override

    if modifier_keys_on_invoke and self:HasBeenShown() and default_action then
        default_action(self)
        return
    end

    if finenv.IsRGPLua then
        -- OkButtonCanClose will be nil before 0.56 and true (the default) after
        if self.OkButtonCanClose then
            self.OkButtonCanClose = modifier_keys_on_invoke
        end

        if self:ShowModeless() then
            finenv.RetainLuaState = true
        end
    else
        if not no_selection_required and finenv.Region():IsEmpty() then
            finenv.UI():AlertInfo("Please select a music region before running this script.", "Selection Required")
            return
        end

        self:ExecuteModal(nil)
    end
end

--[[
% HandleMeasurementUnitChange

**[Callback Template]**
Template for MeasurementUnitChange handlers.

@ window (FCXCustomLuaWindow) The window that triggered the event.
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

@ self (FCXCustomLuaWindow)
@ callback (function) See `HandleMeasurementUnitChange` for callback signature.
]]

--[[
% RemoveHandleMeasurementUnitChange

**[Fluid]**
Removes a handler added with `AddHandleMeasurementUnitChange`.

@ self (FCXCustomLuaWindow)
@ callback (function)
]]
props.AddHandleMeasurementUnitChange, props.RemoveHandleMeasurementUnitChange, trigger_measurement_unit_change, each_last_measurement_unit_change =
    mixin_helper.create_custom_window_change_event(
        {
            name = "last_unit",
            get = function(win)
                return mixin.FCXCustomLuaWindow.GetMeasurementUnit(win)
            end,
            initial = measurement.get_real_default_unit(),
        })

return props

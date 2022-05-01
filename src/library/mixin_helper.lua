--  Author: Edward Koltun
--  Date: April 3, 2022

--[[
$module Mixin Helper

A library of helper functions to improve code reuse in mixins.
]]
local utils = require("library.utils")
local mixin = require("library.mixin")

local mixin_helper = {}

local disabled_method = function()
    error("Attempt to call disabled method 'tryfunczzz'", 2)
end

--[[
% disable_methods

Disables mixin methods by setting an empty function that throws an error.

@ props (table) The mixin's props table.
@ ... (string) The names of the methods to replace
]]
function mixin_helper.disable_methods(props, ...)
    for i = 1, select("#", ...) do
        props[select(i, ...)] = disabled_method
    end
end

--[[
% create_standard_control_event

A helper function for creating a standard control event. standard refers to the `Handle*` methods from `FCCustomLuaWindow` (not including `HandleControlEvent`).
For example usage, refer to the source for the `FCMControl` mixin.

@ name (string) The full event name (eg. `HandleCommand`, `HandleUpDownPressed`, etc)
: (function) Returns two functions: a function for adding handlers and a function for removing handlers.
]]
function mixin_helper.create_standard_control_event(name)
    local callbacks = setmetatable({}, {__mode = "k"})
    local windows = setmetatable({}, {__mode = "k"})

    local handler = function(control, ...)
        if not callbacks[control] then
            return
        end

        for _, cb in ipairs(callbacks[control]) do
            cb(control, ...)
        end
    end

    local function init_window(window)
        if windows[window] then
            return
        end

        window["Add" .. name](window, handler)

        windows[window] = true
    end

    local function add_func(control, callback)
        mixin.assert_argument(callback, "function", 2)
        local window = control:GetParent()
        mixin.assert(window, "Cannot add handler to control with no parent window.")
        mixin.assert((window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")

        init_window(window)
        callbacks[control] = callbacks[control] or {}
        table.insert(callbacks[control], callback)
    end

    local function remove_func(control, callback)
        mixin.assert_argument(callback, "function", 2)

        utils.table_remove_first(private[self].HandleCommand, callback)
    end

    return add_func, remove_func
end

-- Helper for create_custom_control_event
local function unpack_arguments(values, ...)
    local args = {}
    for i = 1, select("#", ...) do
        table.insert(args, values[select(i, ...).name])
    end

    return table.unpack(args)
end

--[[
% create_custom_control_change_event

Helper function for creating a custom change event for a control.
Custom events are bootstrapped to InitWindow and HandleCommand, in addition be being able to be triggered manually.
For example usage, refer to the source for the `FCMCtrlPopup` mixin.

Parameters:
This function accepts as multiple arguments, a table for each parameter that will be passed to event handlers. Each table should have the following properties:
- `name`: The name of the parameter.
- `get`: The function or the string name of a control method to get the current value of the parameter. It should accept one argument which is the control itself. (eg `mixin.FCMControl.GetText` or `"GetSelectedItem_"`)
- `initial`: The initial value of the parameter (ie before the window has been created)

This function returns 4 values which are all functions:
1. Public method for adding a handler.
2. Public method for removing a handler.
3. Private static function for triggering the event on a control. Accepts one argument which is the control.
4. Private static function for iterating over the sets of last values to enable modification if needed. Each iteration returns a table with event handler paramater names and values.
]]
function mixin_helper.create_custom_control_change_event(...)
    local callbacks = setmetatable({}, {__mode = "k"})
    local windows = setmetatable({}, {__mode = "k"})
    local params = {...} -- Store varargs in table so that it's accessible by inner functions

    -- Bootstraps the custom event to InitWindow and HandleCommand events on the window object
    local handler = function(control)
        if not callbacks[control] then
            return
        end

        -- Get current values for event handler parameters
        local current = {}
        for _, p in ipairs(params) do
            if type(p.get) == "string" then
                current[p.name] = control[p.get](control)
            else
                current[p.name] = p.get(control)
            end
        end

        for _, cb in ipairs(callbacks[control].order) do
            -- If any of the last values are not equal to the current ones, call the handler
            for k, v in pairs(current) do
                if current[k] ~= callbacks[control].history[cb][k] then
                    cb(control, unpack_arguments(callbacks[control].history[cb], table.unpack(params)))

                    -- Update current values in case they have changed
                    for _, p in ipairs(params) do
                        if type(p.get) == "string" then
                            current[p.name] = control[p.get](control)
                        else
                            current[p.name] = p.get(control)
                        end
                    end

                    -- Update the stored last value
                    -- Doing this after the values are updated prevents the same handler being triggered for any changes within the handler, which also reduces the possibility of infinite handler loops
                    callbacks[control].history[cb] = utils.copy_table(current)

                    goto continue
                end
            end

            ::continue::
        end
    end

    local function init_window(window)
        if windows[window] then
            return
        end

        window:AddInitWindow(function()
            -- This will go through the controls in random order but unless it becomes an issue, it's not worth doing anything about
            for control in pairs(callbacks) do
                handler(control)
            end
        end)

        window:AddHandleCommand(handler)
    end

    -- Method for adding event handlers
    local function add_func(self, callback)
        mixin.assert_argument(callback, "function", 2)
        local window = self:GetParent()
        mixin.assert(window, "Cannot add handler to self with no parent window.")
        mixin.assert((window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
        mixin.force_assert(not callbacks[self] or callbacks[self].history[callback] == nil, "The callback has already been added as a change handler.")

        init_window(window)

        local history = {}
        for _, p in ipairs(params) do
            history[p.name] = window:WindowExists_() and p.get(self) or p.initial
        end

        callbacks[self] = callbacks[self] or {order = {}, history = {}}
        callbacks[self].history[callback] = history
        table.insert(callbacks[self].order, callback)
    end

    -- Method for removing event handlers
    local function remove_func(self, callback)
        mixin.assert_argument(callback, "function", 2)

        if not callbacks[self] then
            return
        end

        utils.table_remove_first(callbacks[self].order, callback)
        callbacks[self].history[callback] = nil
    end

    local function trigger_helper(control)
        if not callbacks[control] or callbacks[control].is_queued then
            return
        end

        local window = control:GetParent()

        if window:WindowExists_() then
            window:QueueHandleCustom(function()
                callbacks[control].is_queued = false
                handler(control)
            end)

            callbacks[control].is_queued = true
        end
    end

    -- Function for triggering the custom event on a control
    -- If control is boolean true, then will trigger dispatcher for all controls.
    -- If immediate is true, will trigger dispatchers immediately. This can have unintended consequences, so use with caution.
    local function trigger_func(control, immediate)
        if type(control) == 'boolean' and control then
            for ctrl in pairs(callbacks) do
                if immediate then
                    handler(ctrl)
                else
                    trigger_helper(ctrl)
                end
            end
        else
            if immediate then
                handler(control)
            else
                trigger_helper(control)
            end
        end
    end

    -- Function for iterating over history
    local function history_iterator(control)
        local cb = callbacks[control]
        if not cb then
            return function() return nil end
        end

        local i = 0
        local iterator = function()
            i = i + 1

            if not cb.order[i] then
                return nil
            end

            return cb.history[cb.order[i]]
        end

        return iterator
    end

    return add_func, remove_func, trigger_func, history_iterator
end


return mixin_helper

--  Author: Edward Koltun
--  Date: 2023/02/07
--  version 0.2
--[[
$module Mixin Helper

A library of helper functions to improve code reuse in mixins.
]] local utils = require("library.utils")
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

    local dispatcher = function(control, ...)
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

        window["Add" .. name](window, dispatcher)

        windows[window] = true
    end

    local function add_func(control, callback)
        mixin.assert_argument(callback, "function", 3)
        local window = control:GetParent()
        mixin.assert(window, "Cannot add handler to control with no parent window.")
        mixin.assert(
            (window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow",
            "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")

        init_window(window)
        callbacks[control] = callbacks[control] or {}
        table.insert(callbacks[control], callback)
    end

    local function remove_func(control, callback)
        mixin.assert_argument(callback, "function", 3)

        utils.table_remove_first(callbacks[control], callback)
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

local function get_event_value(target, func)
    if type(func) == "string" then
        return target[func](target)
    else
        return func(target)
    end
end

local function create_change_event(...)
    local callbacks = setmetatable({}, {__mode = "k"})
    local params = {...} -- Store varargs in table so that it's accessible by inner functions

    local event = {}
    function event.dispatcher(target)
        if not callbacks[target] then
            return
        end

        -- Get current values for event handler parameters
        local current = {}
        for _, p in ipairs(params) do
            current[p.name] = get_event_value(target, p.get)
        end

        for _, cb in ipairs(callbacks[target].order) do
            -- If any of the last values are not equal to the current ones, call the handler
            local called = false
            for k, v in pairs(current) do
                if current[k] ~= callbacks[target].history[cb][k] then
                    cb(target, unpack_arguments(callbacks[target].history[cb], table.unpack(params)))
                    called = true
                    goto continue
                end
            end
            ::continue::

            -- Update current values in case they have changed
            for _, p in ipairs(params) do
                current[p.name] = get_event_value(target, p.get)
            end

            -- Update the stored last value
            -- Doing this after the values are updated prevents the same handler being triggered for any changes within the handler, which also reduces the possibility of infinite handler loops
            if called then
                callbacks[target].history[cb] = utils.copy_table(current)
            end
        end
    end

    function event.add(target, callback, initial)
        callbacks[target] = callbacks[target] or {order = {}, history = {}}

        local history = {}
        for _, p in ipairs(params) do
            if initial then
                if type(p.initial) == "function" then
                    history[p.name] = p.initial(target)
                else
                    history[p.name] = p.initial
                end
            else
                history[p.name] = get_event_value(target, p.get)
            end
        end

        callbacks[target].history[callback] = history
        table.insert(callbacks[target].order, callback)
    end

    function event.remove(target, callback)
        if not callbacks[target] then
            return
        end

        callbacks[target].history[callback] = nil
        table.insert(callbacks[target].order, callback)
    end

    function event.callback_exists(target, callback)
        return callbacks[target] and callbacks[target].history[callback] and true or false
    end

    function event.has_callbacks(target)
        return callbacks[target] and #callbacks[target].order > 0 or false
    end

    -- Function for iterating over history
    function event.history_iterator(control)
        local cb = callbacks[control]
        if not cb or #cb.order == 0 then
            return function()
                return nil
            end
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

    function event.target_iterator()
        return utils.iterate_keys(callbacks)
    end

    return event
end

--[[
% create_custom_control_change_event

Helper function for creating a custom event for a control.
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

@ ... (table)
]]
function mixin_helper.create_custom_control_change_event(...)
    local event = create_change_event(...)
    local windows = setmetatable({}, {__mode = "k"})
    local queued = setmetatable({}, {__mode = "k"})

    local function init_window(window)
        if windows[window] then
            return
        end

        window:AddInitWindow(
            function()
                -- This will go through the controls in random order but unless it becomes an issue, it's not worth doing anything about
                for control in event.target_iterator() do
                    event.dispatcher(control)
                end
            end)

        window:AddHandleCommand(event.dispatcher)
    end

    local function add_func(self, callback)
        mixin.assert_argument(callback, "function", 2)
        local window = self:GetParent()
        mixin.assert(window, "Cannot add handler to self with no parent window.")
        mixin.assert(
            (window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow",
            "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
        mixin.force_assert(
            not event.callback_exists(self, callback), "The callback has already been added as a handler.")

        init_window(window)
        event.add(self, callback, not window:WindowExists_())
    end

    local function remove_func(self, callback)
        mixin.assert_argument(callback, "function", 2)

        event.remove(self, callback)
    end

    local function trigger_helper(control)
        if not event.has_callbacks(control) or queued[control] then
            return
        end

        local window = control:GetParent()

        if window:WindowExists_() then
            window:QueueHandleCustom(
                function()
                    queued[control] = nil
                    event.dispatcher(control)
                end)

            queued[control] = true
        end
    end

    -- Function for triggering the custom event on a control
    -- If control is boolean true, then will trigger dispatcher for all controls.
    -- If immediate is true, will trigger dispatchers immediately. This can have unintended consequences, so use with caution.
    local function trigger_func(control, immediate)
        if type(control) == "boolean" and control then
            for ctrl in event.target_iterator() do
                if immediate then
                    event.dispatcher(ctrl)
                else
                    trigger_helper(ctrl)
                end
            end
        else
            if immediate then
                event.dispatcher(control)
            else
                trigger_helper(control)
            end
        end
    end

    return add_func, remove_func, trigger_func, event.history_iterator
end

--[[
% create_custom_window_change_event

Creates a custom change event for a window class. For details, see the documentation for `create_custom_control_change_event`, which works in exactly the same way as this function except for controls.

@ ... (table)
]]
function mixin_helper.create_custom_window_change_event(...)
    local event = create_change_event(...)
    local queued = setmetatable({}, {__mode = "k"})

    local function add_func(self, callback)
        mixin.assert_argument(self, "FCMCustomLuaWindow", 1)
        mixin.assert_argument(callback, "function", 2)
        mixin.force_assert(
            not event.callback_exists(self, callback), "The callback has already been added as a handler.")

        event.add(self, callback)
    end

    local function remove_func(self, callback)
        mixin.assert_argument(callback, "function", 2)

        event.remove(self, callback)
    end

    local function trigger_helper(window)
        if not event.has_callbacks(window) or queued[window] or not window:WindowExists_() then
            return
        end

        window:QueueHandleCustom(
            function()
                queued[window] = nil
                event.dispatcher(window)
            end)

        queued[window] = true
    end

    local function trigger_func(window, immediate)
        if type(window) == "boolean" and window then
            for win in event.target_iterator() do
                if immediate then
                    event.dispatcher(window)
                else
                    trigger_helper(window)
                end
            end
        else
            if immediate then
                event.dispatcher(window)
            else
                trigger_helper(window)
            end
        end
    end

    return add_func, remove_func, trigger_func, event.history_iterator
end


--[[
% to_fcstring

Casts a value to an `FCString` object. If the value is already an `FCString`, it will be returned.

@ value (any)
@ [fcstr] (FCString) An optional `FCString` object to populate to skip creating a new object.
: (FCString)
]]

function mixin_helper.to_fcstring(value, fcstr)
    if mixin.is_instance_of(value, "FCString") then
        return value
    end

    fcstr = fcstr or finale.FCString()
    fcstr.LuaString = tostring(value)
    return fcstr
end

--[[
% boolean_to_error

There are many PDK methods that return a boolean value to indicate success / failure instead of throwing an error.
This function captures that result and throws an error in case of failure.

@ object (__FCMBase) Any `FCM` or `FCX` object.
@ method (string) The name of the method to call (no trailing underscore, it will be added automatically).
@ [...] (any) Any arguments to pass to the method.
]]

function mixin_helper.boolean_to_error(object, method, ...)
    if not object[method .. "_"](object, ...) then
        error("'" .. object.MixinClass .. "." .. method .. "' has encountered an error.", 3)
    end
end

return mixin_helper

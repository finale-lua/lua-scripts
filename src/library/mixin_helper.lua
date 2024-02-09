--  Author: Edward Koltun
--  Date: 2023/02/07
--  version 0.2
--[[
$module Mixin Helper

A library of helper functions to improve code reuse in mixins.
]] --
require("library.lua_compatibility")
local utils = require("library.utils")
local mixin = require("library.mixin")
local library = require("library.general_library")
local localization = require("library.localization")

local mixin_helper = {}

local debug_enabled = finenv.DebugEnabled

--[[
% is_instance_of

Checks if a Finale object is an instance of a class or classes. This function examines the full class hierarchy, so parent classes are also supported.

Table of Matching Conditions:
```
|            | FC  Class | FCM Class | FCX Class |
--------------------------------------------------
| FC  Object |     O     |     X     |     X     |
| FCM Object |     O     |     O     |     X     |
| FCX Object |     X     |     O     |     O     |
```
*Key: `O` = match, `X` = no match*

Summary:
- Parent cannot be instance of child class.
- `FC` object cannot be an instance of an `FCM` or `FCX` class.
- `FCM` object can be an instance of an `FC` class but cannot be an instance of an `FCX` class.
- `FCX` object can be an instance of an `FCM` class but cannot be an instance of an `FC` class.

*NOTE: The break points are due to differences in backwards compatibility between `FCM` and `FCX` mixins.*

@ object (__FCBase) Any finale object, including mixin enabled objects.
@ ... (string) Class names (as many as needed). Can be an `FC`, `FCM`, or `FCX` class name. Can also be the name of a parent class.
: (boolean)
]]
function mixin_helper.is_instance_of(object, ...)
    if not library.is_finale_object(object) then
        return false
    end

    -- 0 = FC
    -- 1 = FCM
    -- 2 = FCX
    local class_names = {[0] = {}, [1] = {}, [2] = {}}
    for i = 1, select("#", ...) do
        local class_name = select(i, ...)
        -- Skip over anything that isn't a class name (for easy integration with `assert_argument_type`)
        local class_type = (mixin.is_fcx_class_name(class_name) and 2) or (mixin.is_fcm_class_name(class_name) and 1) or (mixin.is_fc_class_name(class_name) and 0) or false
        if class_type then
            -- Convert FCM to FC for easier checking later
            class_names[class_type][class_type == 1 and mixin.fcm_to_fc_class_name(class_name) or class_name] = true
        end
    end

    local object_type = (mixin.is_fcx_class_name(object.MixinClass) and 2) or (mixin.is_fcm_class_name(object.MixinClass) and 1) or 0
    local parent = object_type == 0 and library.get_class_name(object) or object.MixinClass

    -- Traverse FCX hierarchy until we get to an FCM base
    if object_type == 2 then
        repeat
            if class_names[2][parent] then
                return true
            end

            -- We can assume that since we have an object, all parent classes have been loaded
            parent = object.MixinParent
        until mixin.is_fcm_class_name(parent)
    end

    -- Since FCM classes follow the same hierarchy as FC classes, convert to FC
    if object_type > 0 then
        parent = mixin.fcm_to_fc_class_name(parent)
    end

    -- Traverse FC hierarchy
    repeat
        if (object_type < 2 and class_names[0][parent]) or (object_type > 0 and class_names[1][parent]) then
            return true
        end

        parent = library.get_parent_class(parent)
    until not parent

    -- Nothing found
    return false
end

local function assert_argument_type(levels, argument_number, value, ...)
    local primary_type = type(value)
    local secondary_type
    if primary_type == "number" then
        secondary_type = math.type(value)
    end

    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if t == primary_type or (secondary_type and t == secondary_type) then
            return
        end
    end

    if mixin_helper.is_instance_of(value, ...) then
        return
    end

    -- Determine type for error message
    if library.is_finale_object(value) then
        secondary_type = value.MixinClass or value.ClassName
    end

    error(
        "bad argument #" .. tostring(argument_number) .. " to 'tryfunczzz' (" .. table.concat(table.pack(...), " or ") .. " expected, got " .. (secondary_type or primary_type) ..
            ")", levels)
end

--[[
% assert_argument_type

Asserts that an argument to a mixin method is the expected type(s). This should only be used within mixin methods as the function name will be inserted automatically.

If not a valid type, will throw a bad argument error at the level above where this function is called.

The followimg types can be specified:
- Standard Lua types (`string`, `number`, `boolean`, `table`, `function`, `nil`, etc),
- Number types (`integer` or `float`).
- Finale classes, including parent classes (eg `FCString`, `FCMeasure`, etc).
- Mixin classes, including parent classes (eg `FCMString`, `FCMMeasure`, etc).
*For details about what types a Finale object will satisfy, see `mixin_helper.is_instance_of`.*

*NOTE: This function will only assert if in debug mode (ie `finenv.DebugEnabled == true`). If assertions are always required, use `force_assert_argument_type` instead.*

@ argument_number (number) The REAL argument number for the error message (self counts as argument #1).
@ value (any) The value to test.
@ ... (string) Valid types (as many as needed). Can be standard Lua types, Finale class names, or mixin class names.
]]
function mixin_helper.assert_argument_type(argument_number, value, ...)
    if debug_enabled then
        assert_argument_type(4, argument_number, value, ...)
    end
end

--[[
% force_assert_argument_type

The same as `assert_argument_type` except this function always asserts, regardless of whether debug mode is enabled.

@ argument_number (number) The REAL argument number for the error message (self counts as argument #1).
@ value (any) The value to test.
@ ... (string) Valid types (as many as needed). Can be standard Lua types, Finale class names, or mixin class names.
]]
function mixin_helper.force_assert_argument_type(argument_number, value, ...)
    assert_argument_type(4, argument_number, value, ...)
end

local function assert_func(condition, message, level)
    if type(condition) == "function" then
        condition = condition()
    end

    if not condition then
        error(message, level)
    end
end

--[[
% assert

Asserts a condition in a mixin method. If the condition is false, an error is thrown one level above where this function is called.

*NOTE: This function will only assert if in debug mode (ie `finenv.DebugEnabled == true`). If assertions are always required, use `force_assert` instead.*

@ condition (any) Can be any value or expression. If a function, it will be called (with zero arguments) and the result will be tested.
@ message (string) The error message.
@ [level] (number) Optional level to throw the error message at (default is 2).
]]
function mixin_helper.assert(condition, message, level)
    if debug_enabled then
        assert_func(condition, message, level == 0 and 0 or 2 + (level or 2))
    end
end

--[[
% force_assert

The same as `assert` except this function always asserts, regardless of whether debug mode is enabled.

@ condition (any) Can be any value or expression.
@ message (string) The error message.
@ [level] (number) Optional level to throw the error message at (default is 2).
]]
function mixin_helper.force_assert(condition, message, level)
    assert_func(condition, message, level == 0 and 0 or 2 + (level or 2))
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
        mixin_helper.assert_argument_type(3, callback, "function")
        local window = control:GetParent()
        mixin_helper.assert(window, "Cannot add handler to control with no parent window.")
        mixin_helper.assert((window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")

        init_window(window)
        callbacks[control] = callbacks[control] or {}
        table.insert(callbacks[control], callback)
    end

    local function remove_func(control, callback)
        mixin_helper.assert_argument_type(3, callback, "function")

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
            for k, _ in pairs(current) do
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
        mixin_helper.assert_argument_type(2, callback, "function")
        local window = self:GetParent()
        mixin_helper.assert(window, "Cannot add handler to self with no parent window.")
        mixin_helper.assert((window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
        mixin_helper.force_assert(not event.callback_exists(self, callback), "The callback has already been added as a handler.")

        init_window(window)
        event.add(self, callback, not window:WindowExists__())
    end

    local function remove_func(self, callback)
        mixin_helper.assert_argument_type(2, callback, "function")

        event.remove(self, callback)
    end

    local function trigger_helper(control)
        if not event.has_callbacks(control) or queued[control] then
            return
        end

        local window = control:GetParent()

        if window:WindowExists__() then
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
        mixin_helper.assert_argument_type(1, self, "FCMCustomLuaWindow")
        mixin_helper.assert_argument_type(2, callback, "function")
        mixin_helper.force_assert(not event.callback_exists(self, callback), "The callback has already been added as a handler.")

        event.add(self, callback)
    end

    local function remove_func(self, callback)
        mixin_helper.assert_argument_type(2, callback, "function")

        event.remove(self, callback)
    end

    local function trigger_helper(window)
        if not event.has_callbacks(window) or queued[window] or not window:WindowExists__() then
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
                    event.dispatcher(win)
                else
                    trigger_helper(win)
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
    if mixin_helper.is_instance_of(value, "FCString") then
        return value
    end

    fcstr = fcstr or finale.FCString()
    fcstr.LuaString = value == nil and "" or tostring(value)
    return fcstr
end

--[[
% to_string

Casts a value to a Lua string. If the value is an `FCString`, it returns `LuaString`, otherwise it calls `tostring`.

@ value (any)
: (string)
]]

function mixin_helper.to_string(value)
    if mixin_helper.is_instance_of(value, "FCString") then
        return value.LuaString
    end

    return value == nil and "" or tostring(value)
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
    if not object[method .. "__"](object, ...) then
        error("'" .. object.MixinClass .. "." .. method .. "' has encountered an error.", 3)
    end
end

--[[
% create_localized_proxy

Creates a proxy method that takes localization keys instead of raw strings.

@ method_name (string)
@ class_name (string|nil) If `nil`, the resulting call will be on the `self` object. If a `string` is passed, it will be forwarded to a static call on that class in the `mixin` namespace.
@ only_localize_args (table|nil) If `nil`, all values passed to the method will be localized. If only certain arguments need localizing, pass a `table` of argument `number`s (note that `self` is argument #1).
: (function)
]]
function mixin_helper.create_localized_proxy(method_name, class_name, only_localize_args)
    local args_to_localize
    if only_localize_args == nil then
        args_to_localize = setmetatable({}, { __index = function() return true end })
    else
        args_to_localize = utils.create_lookup_table(only_localize_args)
    end

    return function(self, ...)
        local args = table.pack(...)

        for arg_num = 1, args.n do
            if args_to_localize[arg_num] then
                mixin_helper.assert_argument_type(arg_num, args[arg_num], "string", "FCString")
                args[arg_num] = localization.localize(mixin_helper.to_string(args[arg_num]))
            end
        end

        --Tail call. Errors will pass through to the correct level
        return (class_name and mixin[class_name] or self)[method_name](self, table.unpack(args, 1, args.n))
    end
end

--[[
% create_multi_string_proxy

Creates a proxy method that takes multiple string arguments.

@ method_name (string) An instance method on the class that accepts a single Lua `string`, `FCString`, or `number`
: (function)
]]
function mixin_helper.create_multi_string_proxy(method_name)
    local function to_key_string(value)
        if type(value) == "string" then
            value = "\"" .. value .. "\""
        end

        return "[" .. tostring(value) .. "]"
    end
    return function(self, ...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString", "FCStrings", "table")

            if type(v) == "userdata" and v:ClassName() == "FCStrings" then
                for str in each(v) do
                    self[method_name](self, str)
                end
            elseif type(v) == "table" then
                for k2, v2 in pairsbykeys(v) do
                    require('mobdebug').start()
                    mixin_helper.assert_argument_type(tostring(i + 1) .. to_key_string(k2), v2, "string", "number", "FCString")
                    self[method_name](self, v2)
                end
            else
                self[method_name](self, v)
            end
        end
    end
end


return mixin_helper

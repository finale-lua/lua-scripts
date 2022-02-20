--  Author: Edward Koltun
--  Date: November 3, 2021

--[[
$module Fluid Mixins

The Fluid Mixins library simplifies the process of writing plugins and improves code maintainability.

This library does 2 things:
- Allows mixins to be added to any `FC*` objects
- Adds a fluid interface for any methods that return zero values.


By default, it is not possible to override or extend any of the `FC*` objects in Finale Lua because objects that are tied to their underlying C++ implementation are userdata, not tables.
So through a little bit of magic with proxying, this library enables new methods and properties to be added, while maintaining access to the original methods and properties.


**Adding New Methods and Properties**
Including the mixin library instantly enables the addition of new methods and properties. The example below demonstrates adding a new property and a new method which accesses that property.
```
local mixin = require('library.mixin')
local dialog = finale.FCCustomLuaWindow()

dialog.my_custom_property = 'foo'

dialog.my_custom_method = function(t) print(t.my_custom_property) end
```
*Note: methods and properties cannot end in an underscore. For more info, see 'Accessing Original Methods'*


**Overriding Existing Method and Properties**
In the same way, it is also possible to override existing methods of `FC*` objects.
```
local mixin = require('library.mixin')
local dialog = finale.FCCustomLuaWindow()

dialog.ExecuteModal = function(t, ...)
    print('Showing modal dialog window')
    return t.ExecuteModal_(...)
end
```
*Note: Only one copy of a mixin method is stored at a time. This means that overriding either an already overridden method or a new method will result in the first method being replaced, rendering it inaccessible.*


To minimise conflicts, existing properties continue to follow their original behaviour and this behaviour cannot be modified. This essentially means that existing methods cannot be overridden.
In other words:
- Existing read-only properties will remain read-only
- Existing writable properties remain writable

```
local mixin = require('mixin')

local cell = finale.FCCell(m, s)
cell.Measure = 2 -- Fails with an error as it is still a read-only property
```


**Accessing Original Methods**
For various reasons, it may be desirable to access the original method once overridden. This can be done by appending a trailing underscore to the method name.

```
local mixin = require('library.mixin')
local dialog = finale.FCCustomLuaWindow()

dialog.ExecuteModal = function(t, ...)
    print('Showing modal dialog window')
    return t.ExecuteModal_(...) -- This references the original method.
end
```
For this reason, mixin methods and properties cannot have a trailing underscore and attempting to do so will result in an error being thrown.

If needed, (eg for performance reasons), the original `finale` global object can also be accessed by appending a trailing underscore.
```
local mixin = require('library.mixin')

-- Refers to the original finale object, without mixins.
local dialog = finale_.FCCustomLuaWindow()
```


**Global Mixins**
In addition to being able to add methods and properties on the fly, there are also two ways of defining mixins. The first of these are global mixins. Global mixins are applied at the class level and can be defined at any level in the class heirarchy. Once registered, global mixins are applied retroactively to every instance of the class. Global mixins are primarily intended to be used for fixing bugs or for introducing convenience functions and should retain compatibility with the original method signature to avoid conflicts.

```
local mixin = require('library.mixin')

-- A table of methods and/or properties
local props = {
    my_custom_property = 'foo',
    my_custom_method = function(t) print(t.my_custom_property) end
} 

mixin.register_global_mixin('FCCustomLuaWindow', props)
```

Global mixins can be registered automatically. To take advantage of this, they should be defined in the `mixin.global` namespace in a file with the same name as the class name. E.g. the snippet above would be located in src/mixin/global/FCCustomLuaWindow.lua`.


**Named Mixins**
The other type of defined mixin is a named mixin. Named mixins are intended for defining more customised functionality and are only applied on request to an instance. These should be stored in the `mixin.named` namespace and need to be included in order to be available for use.

`src/mixin/named/my_custom_window.lua`
```
local mixin = require('library.mixin')

-- A table of methods and/or properties
local props = {
    my_custom_property = 'foo',
    my_custom_method = function(t) print(t.my_custom_property) end
} 

mixin.register_named_mixin('FCCustomLuaWindow', 'my_custom_window', props)
```

Plugin:
```
local mixin = require('library.mixin')
require('mixin.named.my_custom_window')

local dialog = finale.FCCustomLuaWindow()
dialog.apply_mixin('my_custom_window')

print(dialog.has_mixin('my_custom_window')) -- true
```

You can check if an object has a named mixin applied by calling `has_mixin`. Named mixins can only be applied once per object. Applying a named mixin multiple times on the same instance will result in an error being thrown.



**Fluid Interface**
As an additional convenience, this library also makes available a fluid interface for all `FC*` object methods that return zero values. Methods that return `nil` are not affected by this since that is technically a value.

```
local mixin = require('library.mixin')
local window = finale.FCCustomLuaWindow()

window:CreateStatic(10, 10):SetText(finale.FCString():SetLuaString('this is some text'))

window:ExecuteModal(nil)
```


Functions available in the mixin library are:
]]

local utils = require("library.utils")

-- For compatibility with Lua <= 5.1
local unpack = unpack or table.unpack

local mixin, global_mixins, named_mixins = {}, {}, {}

local base_mixins = {
    is_mixin = true,

--[[
% has_mixin(name)

Object Method: Checks if the object it is called on has a mixin applied.

Example:
```
print(dialog.has_mixin('my_custom_dialog')) -- false

dialog.apply_mixin('my_custom_dialog');

print(dialog.has_mixin('my_custom_dialog')) -- true
```

@ name (string) Mixin name.
: (boolean)
]]
    has_mixin = function(t, mixin_list, _, name)
        return mixin_list[t][name] and true or false
    end,

--[[
% has_mixin(name)

Object Method: Applies a mixin to the object it is called on.

Example:
```
local mixin = require('library.mixin')
require('mixin.named.my_custom_dialog')

local dialog = finale.FCCustomLuaWindow()
dialog.apply_mixin('my_custom_dialog');
```

@ name (string) Mixin name.
]]
    apply_mixin = function(t, mixin_list, mixin_props, name)
        if mixin_list[t][name] then
            error('Mixin \'' .. name .. '\' has already been applied to this object.');
        end

        local m = mixin.get_mixin(mixin.get_class_name(t), name)
        for p, v in pairs(m) do
            -- Take advantage of error checking
            t[p] = v
        end

        if m.init then
            t:init()
            mixin_props[t].init = nil
        end

        mixin_list[t][name] = true
    end,
}

-- Loads a global mixin, if it hasn't been loaded yet
local function load_global_mixin(class_name)
    if type(global_mixins[class_name]) ~= 'nil' then return end

    success, result = pcall(function(c) return require(c) end, 'mixin.global.' .. class_name)

    if not success then
        -- If the reason it failed to load was anything other than module not found, display the error
        if not result:match("module '[^']-' not found") then
            error(result, 0)
        end

        -- Keep track of failed attempts to prevent calling require more than once per class
        global_mixins[class_name] = false
    end
end

-- Catches an error and throws it at the specified level (relative to where this function was called)
-- First argument is called tryfunczzz for uniqueness
local pcall_line = debug.getinfo(1, "l").currentline + 2 -- This MUST refer to the pcall 2 lines below
local function catch_and_rethrow(tryfunczzz, func_name, levels, ...)
    local success, result = pcall(function(...) return {tryfunczzz(...)} end, ...)

    if not success then
        file, line, msg = result:match('([a-zA-Z]-:?[^:]+):([0-9]+): (.+)')
        msg = msg or result

        -- Conditions for rethrowing at a higher level:
        -- Ignore errors thrown with no level info (ie. level = 0), as we can't make any assumptions
        -- Both the file and line number indicate that it was thrown at this level
        if file and line and file:sub(-9) == 'mixin.lua' and tonumber(line) == pcall_line then

            -- Replace the method name with the correct one, for bad argument errors etc
            if func_name then
                msg = msg:gsub('\'tryfunczzz\'', '\'' .. func_name .. '\'')
            end

            error(msg, levels + 1)

        -- Otherwise, it's either an internal function error or we couldn't be certain that it isn't
        -- So, rethrow with original file and line number to be 'safe'
        else
            error(result, 0)
        end
    end

    return unpack(result)
end

-- Returns the name of the parent class
-- This function should only be called for classnames that start with "FC" or "__FC"
local get_parent_class = function(classname)
    local class = finale_[classname]
    if type(class) ~= "table" then return nil end
    if not finenv.IsRGPLua then -- old jw lua
        classt = class.__class
        if classt and classname ~= "__FCBase" then
            classtp = classt.__parent -- this line crashes Finale (in jw lua 0.54) if "__parent" doesn't exist, so we excluded "__FCBase" above, the only class without a parent
            if classtp and type(classtp) == "table" then
                for k, v in pairs(finale_) do
                    if type(v) == "table" then
                        if v.__class and v.__class == classtp then
                            return tostring(k)
                        end
                    end
                end
            end
        end
    else
        for k, _ in pairs(class.__parent) do
            return tostring(k)  -- in RGP Lua the v is just a dummy value, and the key is the classname of the parent
        end
    end
    return nil
end

-- Gets the real class name of a Finale object
-- Some classes have incorrect class names, so this function attempts to resolve them with ducktyping
function mixin.get_class_name(object)
    if not object or not object.ClassName then return end
    if object:ClassName() == '__FCCollection' and object.ExecuteModal then
        return object.RegisterHandleCommand and 'FCCustomLuaWindow' or 'FCCustomWindow'
    end

    return object:ClassName()
end

-- Attempts to determine if an object is a Finale object through ducktyping
local function is_finale_object(object)
    -- All finale objects implement __FCBase, so just check for the existence of __FCBase methods
    return object and type(object) == 'userdata' and object.ClassName and object.GetClassID and true or false
end

-- Returns a function that handles the fluid interface
function mixin.create_fluid_proxy(t, func, func_name)
    local function proxy(...)
        local n = select('#', ...)
        -- If no return values, then apply the fluid interface
        if n == 0 then
            return t
        end

        -- Apply mixin foundation to all returned finale objects
        for i = 1, n do
            mixin.apply_mixin_foundation(select(i, ...))
        end
        return ...
    end

    return function(...)
        return proxy(catch_and_rethrow(func, func_name, 2, ...))
    end
end

-- Modifies an FC* class to allow adding mixins to any instance of that class.
function mixin.apply_mixin_foundation(object)
    if not object or not is_finale_object(object) then return end
    if object.is_mixin then return object end

    local class_name = mixin.get_class_name(object)

    -- Storage for mixin methods and properties
    local mixin_props, mixin_list = {}, {}

    -- Use weak keys to enable garbage collection and prevent memory leaks
    setmetatable(mixin_props, {__mode = 'k'})
    setmetatable(mixin_list, {__mode = 'k'})

    local meta = getmetatable(object)

    -- We need to retain a reference to the originals for later
    local original_index = meta.__index 
    local original_newindex = meta.__newindex

    meta.__index = function(t, k)
        local prop
        local real_k = k
        mixin_props[t] = mixin_props[t] or {}

        -- First, check if it's one of the base mixin methods (these can't be overridden)
        if base_mixins[k] ~= nil then
            if type(base_mixins[k]) == 'function' then
                prop = function(tt, ...) return base_mixins[k](tt, mixin_list, mixin_props, ...) end
            else
                prop = utils.copy_table(base_mixins[k])
            end

        -- If there's a trailing underscore in the key, then return the original property, whether it exists or not
        elseif type(k) == 'string' and k:sub(-1) == '_' then
            -- Strip trailing underscore
            real_k = k:sub(1, -2)
            prop = original_index(t, real_k)

        -- Check if it's a mixin that's been directly applied
        elseif mixin_props[t][k] ~= nil then
            prop = mixin_props[t][k]

        -- Otherwise, assume we're looking for a global mixin
        else
            -- Try and find the mixin somewhere in the inheritance tree
            local parent = class_name
            while parent do
                load_global_mixin(parent)
                if global_mixins[parent] and global_mixins[parent][k] ~= nil then
                    -- Only copy over tables, in order to make them writable.
                    if type(global_mixins[parent][k]) == 'table' then
                        mixin_props[t][k] = utils.copy_table(global_mixins[parent][k])
                        prop = mixin_props[t][k]
                    else
                        prop = global_mixins[parent][k]
                    end

                    break
                end

                parent = get_parent_class(parent)
            end

            -- As a last resort, use original property, whether it exists or not
            if not parent then
                prop = original_index(t, real_k)
            end
        end

       if type(prop) == 'function' then
            return mixin.create_fluid_proxy(t, prop, real_k)
        else
            return prop
        end
    end

    -- This will cause certain things (eg misspelling a property) to fail silently as the misspelled property will be stored on the mixin instead of triggering an error
    -- Using methods instead of properties will avoid this
    meta.__newindex = function(t, k, v)
        -- Trailing underscores are reserved for accessing original methods
        if (type(k) == 'string' and k:sub(-1) == '_') then
            error('Mixin methods and properties cannot end in an underscore.', 2)
        end

        local type_v_original = type(original_index(t, k))
        mixin_props[t] = mixin_props[t] or {}

        -- If it's a method, or a property that doesn't exist on the original object, store it
        if type_v_original == 'nil' then
            local type_v_mixin = type(mixin_props[t][k])
            local type_v = type(v)

            -- Technically, a property could still be erased by setting it to nil and then replacing it with a method afterwards
            -- But handling that case would mean either storing a list of all properties ever created, or preventing properties from being set to nil.
            if type_v_mixin ~= 'nil' then
                if type_v == 'function' and type_v_mixin ~= 'function' then
                    error('A mixin method cannot be overridden with a property.', 2)
                elseif type_v_mixin == 'function' and type_v ~= 'function' then
                    error('A mixin property cannot be overridden with a method.', 2)
                end
            end

            mixin_props[t][k] = v

        -- If it's a method, we can override it but only with another method
        elseif type_v_original == 'function' then
            if type(v) ~= 'function' then
                error('A mixin method cannot be overridden with a property.', 2)
            end

            mixin_props[t][k] = v

        -- Otherwise, try and store it on the original property. If it's read-only, it will fail and we show the error
        else
            catch_and_rethrow(original_newindex, nil, 2, t, k, v)
        end
    end

    return object
end

--[[
% register_global_mixin(class, prop[, value])

Library Method: Register a mixin for a finale class that will be applied globally (ie to all instances of the specified classes, including existing instances). Properties and methods cannot end in an underscore.

@ class (string|array) The target class (or an array of classes).
@ prop (string|table) Either the property name, or a table with pairs of (string) = (mixed)
@ value [mixed] OPTIONAL: Method or property value. Will be ignored if prop is a table.
]]
function mixin.register_global_mixin(class, prop, value)
    class = type(class) == 'table' and class or {class}
    prop = type(prop) == 'table' and prop or {[prop] = value}

    for _, c in ipairs(class) do
        for p, v in pairs(prop) do
            if type(p) == 'string' and p:sub(-1) ~= '_' then
                global_mixins[c] = global_mixins[c] or {}
                global_mixins[c][p] = utils.copy_table(v)
            end
        end
    end
end

--[[
% register_named_mixin(class, mixin_name, prop[, value])

Library Method: Register a named mixin which can then be applied by calling the target object's apply_mixin method. If a named mixin requires a 'constructor', include a method called 'init' that accepts zero arguments. It will be called when the mixin is applied. Properties and methods cannot end in an underscore.

@ class (string|array) The class (or an array of classes) to apply the mixin to.
@ mixin_name (string|array) Mixin name, or an array of names.
@ prop (string|table) Either the property name, or a table with pairs of (string) = (mixed)
@ value [mixed] OPTIONAL: Method or property value. Will be ignored if prop is a table.
]]
function mixin.register_named_mixin(class, mixin_name, prop, value)
    mixin_name = type(mixin_name) == 'table' and mixin_name or {mixin_name}
    class = type(class) == 'table' and class or {class}
    prop = type(prop) == 'table' and prop or {[prop] = value}

    for _, n in ipairs(mixin_name) do
        if n == 'global' then
            error('A mixin cannot be named \'global\'.', 2)
        end

        for _, c in ipairs(class) do
            named_mixins[c] = named_mixins[c] or {}

            if named_mixins[c][n] then
                error('Named mixins can only be registered once per class.', 2)
            else
                named_mixins[c][n] = {}
            end

            for p, v in pairs(prop) do
                if type(p) == 'string' and p:sub(-1) ~= '_' then named_mixins[c][n][p] = utils.copy_table(v) end
            end
        end
    end
end

--[[
% get_global_mixin(class, prop)

Library Method: Returns a copy of all methods and properties of a global mixin.

@ class (string) The finale class name.
: (table|nil)
]]
function mixin.get_global_mixin(class)
    load_global_mixin(class)

    return global_mixins[class] and utils.copy_table(global_mixins[class]) or nil
end

--[[
% get_named_mixin(class, mixin_name)

Library Method: Retrieves a copy of all the methods and properties of a named mixin.

@ class (string) Finale class.
@ mixin_name (string) Name of mixin.
: (table|nil)
]]
function mixin.get_named_mixin(class, mixin_name)
    return named_mixins[class] and named_mixins[class][mixin_name] and utils.copy_table(named_mixins[class][mixin_name]) or nil
end

-- Keep a copy of the original finale namespace. Available globally, if needed for performance reasons.
finale_ = finale

-- Turn the finale namespace into a proxy
finale = setmetatable({}, {
    __newindex = function(t, k, v) end,
    __index = function(t, k)
        if (type(k) == 'string' and k:sub(-1) == '_') then
            return finale_[k:sub(1, -2)]
        end

        local val = finale_[k]

        if type(val) == 'table' then
            return setmetatable({}, {
                __index = function(t, k) return finale_[k] end,
                __call = function(...)
                    return mixin.apply_mixin_foundation(finale_[k](...))
                end
            })
        end

        return val
    end
})

return {
    register_global_mixin = mixin.register_global_mixin,
    register_named_mixin = mixin.register_named_mixin,
    get_global_mixin = mixin.get_global_mixin,
    get_named_mixin = mixin.get_named_mixin,
}

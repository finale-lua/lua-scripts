--[[
$module Fluid Mixins
]]
local mixin, default_mixins, named_mixins = {}, {}, {}

-- Recursively copies a table, or just returns the value if not a table
local function copy_table(t)
    if type(t) == 'table' then
        local new = {}
        for k, v in pairs(t) do
            new[copy_table(k)] = copy_table(v)
        end
        setmetatable(new, copy_table(getmetatable(t)))
        return new
    else
        return t
    end
end

-- Gets the real class name of a Finale object
-- Some classes have incorrect class names, so this function attempts to resolve them with ducktyping
local function get_class_name(object)
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
function mixin.create_fluid_proxy(t, func)
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
        return proxy(func(...))
    end
end

-- Modifies an existing instance of an FC* object to allow adding mixins and adds primary mixins.
function mixin.apply_mixin_foundation(object)
    if not object or not is_finale_object(object) or object.is_mixin then return end
    local class_name = get_class_name(object)
    local mixin_store = {}
    local meta = getmetatable(object)

    -- We need to retain a reference to the originals for later
    local original_index = meta.__index 
    local original_newindex = meta.__newindex

    meta.__index = function(t, k)
        local prop

        if k == 'is_mixin' then
            return true
        elseif mixin_store[k] then
            prop = mixin_store[k]
        elseif default_mixins[class_name] and default_mixins[class_name][k] then
        	prop = default_mixins[class_name][k]
        else
            -- Strip trailing underscore if there is one
            if type(k) == 'string' and k:sub(-1) == '_' then k = k:sub(1, -2) end
            prop = original_index(t, k)
        end

       if type(prop) == 'function' then
            return mixin.create_fluid_proxy(t, prop)
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

        local v_type = type(original_index(t, k))

        -- If it's a method, or a property that doesn't exist on the original object, store it
        if (v_type == 'nil' or v_type == 'function') then
            mixin_store[k] = v
        -- Otherwise, try and store it on the original property. If it's read-only, it will fail show the error
        elseif not pcall(function() original_newindex(t, k, v) end) then
            -- In the absence of the ability to throw exceptions, replicate the original error
            error('no member named \'' .. k .. '\'', 2)
        end
    end

    -- Add default mixin properties
    for k, v in pairs(default_mixins[class_name] or {}) do
        if type(v) ~= 'function' then
            -- Applying to object instead of mixin allows us to utilise the existing error handling 
            object[k] = copy_table(v)
        end
    end

    return object
end

--[[
% register_default(class, prop[, value])

Register a mixin for a Finale class that will be applied globally. Note that methods are applied retroactively but properties will only be applied to new instances.

@ class (string|array) The class (or an array of classes) to apply the mixin to.
@ prop (string|table) Either the property name, or a table with pairs of (string) = (mixed)
@ value (mixed) OPTIONAL: Method or property value. Will be ignored if prop is a table.
]]
function mixin.register_default(class, prop, value)
    class = type(class) ~= 'table' and {class} or class
    prop = type(prop) ~= 'table' and {[prop] = value} or prop

    for _, c in ipairs(class) do
        for p, v in pairs(prop) do
            if type(p) == 'string' and p:sub(-1) ~= '_' then default_mixins[c][p] = copy_table(v) end
        end
    end
end

--[[
% register_named(class, mixin_name, prop[, value])

Register a named mixin which can then be applied by calling apply_named. If a named mixin requires setup, include a method called `init` that accepts zero arguments. It will be called when the mixin is applied.

@ class (string|array) The class (or an array of classes) to apply the mixin to.
@ mixin_name (string|array) Mixin name, or an array of names.
@ prop (string|table) Either the property name, or a table with pairs of (string) = (mixed)
@ value (mixed) OPTIONAL: Method or property value. Will be ignored if prop is a table.
]]
function mixin.register_named(class, mixin_name, method, func)
    mixin_name = type(mixin_name) ~= 'table' and {mixin_name} or mixin_name
    class = type(class) ~= 'table' and {class} or class
    prop = type(prop) ~= 'table' and {[prop] = value} or prop

    for _, n in ipairs(mixin_name) do
        for _, c in ipairs(class) do
            named_mixins[c] = named_mixins[c] or {}
            named_mixins[c][n] = named_mixins[c][n] or {}
            for p, v in pairs(prop) do
                if type(p) == 'string' and m:sub(-1) ~= '_' then named_mixins[c][n][p] = copy_table(v) end
            end
        end
    end
end

--[[
% get_default(class, prop)

Retrieves the value of a default mixin.

@ class (string) The Finale class name.
@ prop (string) The name of the property or method.
: (mixed|nil) If the value is a table, a copy will be returned.
]]
function mixin.get_default(class, prop)
    return default_mixins[class] and default_mixins[class][prop] and copy_table(default_mixins[class][prop]) or nil
end

--[[
% get_named(class, mixin_name)

Retrieves all the methods / properties of a named mixin.

@ class (string) Finale class.
@ mixin_name (string) Name of mixin.
: (table|nil)
]]
function mixin.get_named(class, mixin_name)
    return named_mixins[class] and named_mixins[class][mixin_name] and copy_table(named_mixins[class][mixin_name]) or nil
end

--[[
% apply_named(object, mixin_name)

Applies a named mixin to an object. See apply_table for more details.

@ object (__FCBase) The object to apply the mixin to.
@ mixin_name (string) The name of the mixin to apply.
: (__FCBase) The object that was passed.
]]
function mixin.apply_named(object, mixin_name)
    local class = mixin.get_class_name(object)
    return mixin.apply_table(object, class and named_mixins[class] and named_mixins[class][mixin_name] or {})
end

--[[
% apply_table(object, table)

Takes all pairs in the table and copies them over to the target object. If there is an `init` method, it will be called and then removed. This method does not check for conflicts sonit may result in another mixin's method / property being overwritten.

@ object (__FCBase) The target object.
@ mixin_table (table) Table of properties to apply_table
: (__FCBase) The object that was passed.
]]
function mixin.apply_table(object, mixin_table)
    for prop, val in pairs(mixin_table) do
        if type(prop) == 'string' then
            object[prop] = copy_table(val)
            object[prop] = copy_table(val)
        end
    end

    if mixin_table.init then
        object:init()
        object.init = nil
    end

    return object
end

-- Keep a copy of the original finale namespace
local original_finale = finale

-- Turn the finale namespace into a proxy
finale = setmetatable({}, {
    __newindex = function(t,k,v) end,
    __index = function(t, k)
        if (type(k) == 'string' and k:sub(-1) == '_') then
            return original_finale[k:sub(1, -2)]
        end

        local val = original_finale[k]

        if (type(val) == 'table') then
            return setmetatable({}, {
                __index = function(t, k) return original_finale[k] end,
                __call = function(...)
                    return mixin.apply_mixin_foundation(original_finale[k](...))
                end
            })
        end

        return val
    end
})

return {
    register_default = mixin.register_default,
    register_named = mixin.register_named,
    get_default = mixin.get_default,
    get_named = mixin.get_named,
    apply_named = mixin.apply_named,
    apply_table = mixin.apply_table,
}

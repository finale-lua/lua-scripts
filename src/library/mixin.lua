--[[
$module Fluid Mixins
]]

-- For compatibility with Lua <= 5.1
local unpack = unpack or table.unpack

local mixin, global_mixins, named_mixins = {}, {}, {}

local base_mixins = {
    is_mixin = true,

--[[
% has_mixin(name)

Object Method: Checks if the object it is called on has a mixin applied.

@ name (string) Mixin name.
: (boolean)
]]
    has_mixin = function(t, mixin_list, _, name)
        if name == 'global' then
            return global_mixins[mixin.get_class_name(t)] and true or false
        end

        return mixin_list[name] and true or false
    end,

--[[
% has_mixin(name)

Object Method: Applies a mixin to the object it is called on.

@ name (string) Mixin name.
]]
    apply_mixin = function(t, mixin_list, mixin_props, name)
        if mixin_list[name] then
            error('Mixin \'' .. name .. '\' has already been applied to this object.');
        end

        local m = mixin.get_mixin(mixin.get_class_name(t), name)
        for p, v in pairs(m) do
            -- Take advantage of error checking
            t[p] = v
        end

        if m.init then
            t:init()
            mixin_props.init = nil
        end

        mixin_list[name] = true
    end,
}

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

-- Catches an error and rethrows it at the specified level
local function catch_and_rethrow(func, func_name, levels, ...)
    local success, result = pcall(function(...) return {func(...)} end, ...)

    if not success then
        -- Strip the original line number
        _, _, result = result:match('([^:]+):([^:]+): (.+)')

        -- Replace the method name with the correct one
        if func_name then
            result = result:gsub('\'func\'', '\'' .. func_name .. '\'')
        end

        error(result, levels + 1)
    end

    return unpack(result)
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

-- Modifies an existing instance of an FC* object to allow adding mixins and adds primary mixins.
function mixin.apply_mixin_foundation(object)
    if not object or not is_finale_object(object) or object.is_mixin then return end
    local class_name = mixin.get_class_name(object)
    local mixin_props, mixin_list = {}, {}
    local meta = getmetatable(object)

    -- We need to retain a reference to the originals for later
    local original_index = meta.__index 
    local original_newindex = meta.__newindex

    meta.__index = function(t, k)
        local prop
        local real_k = k

        if base_mixins[k] then
            if type(base_mixins[k]) == 'function' then
                -- This will couple the method to the current instance but this shouldn't be an issue
                -- because calls to foo.has_mixin(bar, 'baz_mix') instead of bar:has_mixin('baz_mix') shouldn't be happening...
                prop = function(_, ...) return base_mixins[k](t, mixin_list, mixin_props, ...) end
            else
                prop = copy_table(base_mixins[k])
            end
        elseif mixin_props[k] then
            prop = mixin_props[k]
        elseif global_mixins[class_name] and global_mixins[class_name][k] then
            -- Only copy over properties, not methods.
            if type(global_mixins[k]) == 'function' then
                prop = global_mixins[class_name][k]
            else
                mixin_props[k] = copy_table(global_mixins[class_name][k])
                prop = mixin_props[k]
            end
        else
            -- Strip trailing underscore if there is one
            if type(k) == 'string' and k:sub(-1) == '_' then real_k = k:sub(1, -2) end
            prop = original_index(t, real_k)
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

        -- If it's a method, or a property that doesn't exist on the original object, store it
        if type_v_original == 'nil' then
            local type_v_mixin = type(mixin_props[k])
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

            mixin_props[k] = v

        -- If it's a method, we can override it but only with another method
        elseif type_v_original == 'function' then
            if type(v) ~= 'function' then
                error('A mixin method cannot be overridden with a property.', 2)
            end

            mixin_props[k] = v

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
                global_mixins[c][p] = copy_table(v)
            end
        end
    end
end

--[[
% register_mixin(class, mixin_name, prop[, value])

Library Method: Register a named mixin which can then be applied by calling the target object's apply_mixin method. If a named mixin requires a 'constructor', include a method called 'init' that accepts zero arguments. It will be called when the mixin is applied. Properties and methods cannot end in an underscore.

@ class (string|array) The class (or an array of classes) to apply the mixin to.
@ mixin_name (string|array) Mixin name, or an array of names.
@ prop (string|table) Either the property name, or a table with pairs of (string) = (mixed)
@ value [mixed] OPTIONAL: Method or property value. Will be ignored if prop is a table.
]]
function mixin.register_mixin(class, mixin_name, prop, value)
    mixin_name = type(mixin_name) == 'table' and mixin_name or {mixin_name}
    class = type(class) == 'table' and class or {class}
    prop = type(prop) == 'table' and prop or {[prop] = value}

    for _, n in ipairs(mixin_name) do
        if n == 'global' then
            error('A mixin cannot be named \'global\'.',  2)
        end

        for _, c in ipairs(class) do
            named_mixins[c] = named_mixins[c] or {}

            if named_mixins[c][n] then
                error('Named mixins can only be registered once per class.', 2)
            else
                named_mixins[c][n] = {}
            end

            for p, v in pairs(prop) do
                if type(p) == 'string' and p:sub(-1) ~= '_' then named_mixins[c][n][p] = copy_table(v) end
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
    return global_mixins[class] and copy_table(global_mixins[class]) or nil
end

--[[
% get_mixin(class, mixin_name)

Library Method: Retrieves a copy of all the methods and properties of mixin.

@ class (string) Finale class.
@ mixin_name (string) Name of mixin.
: (table|nil)
]]
function mixin.get_mixin(class, mixin_name)
    return named_mixins[class] and named_mixins[class][mixin_name] and copy_table(named_mixins[class][mixin_name]) or nil
end

-- Keep a copy of the original finale namespace
local original_finale = finale

-- Turn the finale namespace into a proxy
finale = setmetatable({}, {
    __newindex = function(t, k, v) end,
    __index = function(t, k)
        if (type(k) == 'string' and k:sub(-1) == '_') then
            return original_finale[k:sub(1, -2)]
        end

        local val = original_finale[k]

        if type(val) == 'table' then
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
    register_global_mixin = mixin.register_global_mixin,
    register_mixin = mixin.register_mixin,
    get_global_mixin = mixin.get_global_mixin,
    get_mixin = mixin.get_mixin,
}

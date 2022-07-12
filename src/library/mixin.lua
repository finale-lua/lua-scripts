--  Author: Edward Koltun
--  Date: November 3, 2021

--[[
$module Fluid Mixins

The Fluid Mixins library does the following:
- Modifies Finale objects to allow methods to be overridden and new methods or properties to be added. In other words, the modified Finale objects function more like regular Lua tables.
- Mixins can be used to address bugs, to introduce time-savers, or to provide custom functionality.
- Introduces a new namespace for accessing the mixin-enabled Finale objects.
- Also introduces two types of formally defined mixin: `FCM` and `FCX` classes
- As an added convenience, all methods that return zero values have a fluid interface enabled (aka method chaining)


## finalemix Namespace
To utilise the new namespace, simply include the library, which also gives access to he helper functions:
```lua
local finalemix = require("library.mixin")
```

All defined mixins can be accessed through the `finalemix` namespace in the same way as the `finale` namespace. All constructors have the same signature as their `FC` originals.

```lua
local fcstr = finale.FCString()

-- Base mixin-enabled FCString object
local fcmstr = finalemix.FCMString()

-- Customised mixin that extends FCMString
local fcxstr = finalemix.FCXString()

-- Customised mixin that extends FCXString. Still has the same constructor signature as FCString
local fcxcstr = finalemix.FCXMyCustomString()
```
For more information about naming conventions and the different types of mixins, see the 'FCM Mixins' and 'FCX Mixins' sections.


Static copies of `FCM` and `FCX` methods and properties can also be accessed through the namespace like so:
```lua
local func = finalemix.FCXMyMixin.MyMethod
```
Note that static access includes inherited methods and properties.


## Rules of the Game
- New methods can be added or existing methods can be overridden.
- New properties can be added but existing properties retain their original behaviour (ie if they are writable or read-only, and what types they can be)
- The original method can always be accessed by appending a trailing underscore to the method name
- In keeping with the above, method and property names cannot end in an underscore. Setting a method or property ending with an underscore will result in an error.
- Returned `FC` objects from all mixin methods are automatically upgraded to a mixin-enabled `FCM` object.
- All methods that return no values (returning `nil` counts as returning a value) will instead return `self`, enabling a fluid interface

There are also some additional global mixin properties and methods that have special meaning:
| Name | Description | FCM Accessible | FCM Definable | FCX Accessible | FCX Definable |
| :--- | :---------- | :------------- | :------------ | :------------- | :------------ |
| string `MixinClass` | The class name (FCM or FCX) of the mixin. | Yes | No | Yes | No |
| string|nil `MixinParent` | The name of the mixin parent | Yes | No | Yes | Yes (required) |
| string|nil `MixinBase` | The class name of the FCM base of an FCX class | No | No | Yes | No |
| function `Init(self`) | An initialising function. This is not a constructor as it will be called after the object has been constructed. | Yes | Yes (optional) | Yes | Yes (optional) |


## FCM Mixins

`FCM` classes are the base mixin-enabled Finale objects. These are modified Finale classes which, by default (that is, without any additional modifications), retain full backward compatibility with their original counterparts.

The name of an `FCM` class corresponds to its underlying 'FC' class, with the addition of an 'M' after the 'FC'.
For example, the following will create a mixin-enabled `FCCustomLuaWindow` object:
```lua
local finalemix = require("library.mixin")

local dialog = finalemix.FCMCustomLuaWindow()
```

In addition to creating a mixin-enabled finale object, `FCM` objects also automatically load any `FCM` mixins that apply to the class or its parents. These may contain additional methods or overrides for existing methods (eg allowing a method that expects an `FCString` object to accept a regular Lua string as an alternative). The usual principles of inheritance apply (children override parents, etc).

To see if any additional methods are available, or which methods have been modified, look for a file named after the class (eg `FCMCtrlStatic.lua`) in the `mixin` directory. Also check for parent classes, as `FCM` mixins are inherited and can be set at any level in the class hierarchy.


## Defining an FCM Mixin
The following is an example of how to define an `FCM` mixin for `FCMControl`.
`src/mixin/FCMControl.lua`
```lua
-- Include the mixin namespace and helper functions
local library = require("library.general_library")
local finalemix = require("library.mixin")

local props = {

    -- An optional initialising method
    Init = function(self)
        print("Initialising...")
    end,

    -- This method is an override for the SetText method 
    -- It allows the method to accept a regular Lua string, which means that plugin authors don't need to worry anout creating an FCString objectq
    SetText = function(self, str)
        finalemix.assert_argument(str, {"string", "number", "FCString"}, 2)

        -- Check if the argument is a finale object. If not, turn it into an FCString
        if not library.is_finale_object(str)
            local tmp = str

            -- Use a mixin object so that we can take advantage of the fluid interface
            str = finalemix.FCMString():SetLuaString(tostring(str))
        end

        -- Use a trailing underscore to reference the original method from FCControl
        self:SetText_(str)

        -- By maintaining the original method's behaviour and not returning anything, the fluid interface can be applied.
    end
}

return props
```
Since the underlying class `FCControl` has a number of child classes, the `FCMControl` mixin will also be inherited by all child classes, unless overridden.


An example of utilizing the above mixin:
```lua
local finalemix = require("library.mixin")

local dialog = finalemix.FCMCustomLuaWindow()

-- Fluid interface means that self is returned from SetText instead of nothing
local label = dialog:CreateStatic(10, 10):SetText("Hello World")

dialog:ExecuteModal(nil)
```



## FCX Mixins
`FCX` mixins are extensions of `FCM` mixins. They are intended for defining extended functionality with no requirement for backwards compatability with the underlying `FC` object.

While `FCM` class names are directly tied to their underlying `FC` object, their is no such requirement for an `FCX` mixin. As long as it the class name is prefixed with `FCX` and is immediately followed with another uppercase letter, they can be named anything. If an `FCX` mixin is not defined, the namespace will return `nil`.

When constructing an `FCX` mixin (eg `local dialog = finalemix.FCXMyDialog()`, the library first creates the underlying `FCM` object and then adds each parent (if any) `FCX` mixin until arriving at the requested class.


Here is an example `FCX` mixin definition:

`src/mixin/FCXMyStaticCounter.lua`
```lua
-- Include the mixin namespace and helper functions
local finalemix = require("library.mixin")

-- Since mixins can't have private properties, we can store them in a table
local private = {}
setmetatable(private, {__mode = "k"}) -- Use weak keys so that properties are automatically garbage collected along with the objects they are tied to

local props = {

    -- All FCX mixins must declare their parent. It can be an FCM class or another FCX class
    MixinParent = "FCMCtrlStatic",

    -- Initialiser
    Init = function(self)
        -- Set up private storage for the counter value
        if not private[self] then
            private[self] = 0
            finalemix.FCMControl.SetText(self, tostring(private[self]))
        end
    end,

    -- This custom control doesn't allow manual setting of text, so we override it with an empty function
    SetText = function()
    end,

    -- Incrementing counter method
    Increment = function(self)
        private[self] = private[self] + 1

        -- We need the SetText method, but we've already overridden it! Fortunately we can take a static copy from the finalemix namespace
        finalemix.FCMControl.SetText(self, tostring(private[self]))
    end
}

return props
```

`src/mixin/FCXMyCustomDialog.lua`
```lua
-- Include the mixin namespace and helper functions
local finalemix = require("library.mixin")

local props = {
    MixinParent = "FCMCustomLuaWindow",

    CreateStaticCounter = function(self, x, y)
        -- Create an FCMCtrlStatic and then use the subclass function to apply the FCX mixin
        return finalemix.subclass(self:CreateStatic(x, y), "FCXMyStaticCounter")
    end
}

return props
```


Example usage:
```lua
local finalemix = require("library.mixin")

local dialog = finalemix.FCXMyCustomDialog()

local counter = dialog:CreateStaticCounter(10, 10)

counter:Increment():Increment()

-- Counter should display 2
dialog:ExecuteModal(nil)
```
]]

local utils = require("library.utils")
local library = require("library.general_library")

local mixin, mixin_props, mixin_classes = {}, {}, {}

-- Weak table for mixin properties / methods
setmetatable(mixin_props, {__mode = "k"})

-- Reserved properties (cannot be set on an object)
-- 0 = cannot be set in the mixin definition
-- 1 = can be set in the mixin definition
local reserved_props = {
    IsMixinReady = 0,
    MixinClass = 0,
    MixinParent = 1,
    MixinBase = 0,
    Init = 1,
}


local function is_fcm_class_name(class_name)
    return type(class_name) == "string" and (class_name:match("^FCM%u") or class_name:match("^__FCM%u")) and true or false
end

local function is_fcx_class_name(class_name)
    return type(class_name) == "string" and class_name:match("^FCX%u") and true or false
end

local function fcm_to_fc_class_name(class_name)
    return string.gsub(class_name, "FCM", "FC", 1)
end

local function fc_to_fcm_class_name(class_name)
    return string.gsub(class_name, "FC", "FCM", 1)
end

-- Gets the real class name of a Finale object
-- Some classes have incorrect class names, so this function attempts to resolve them with ducktyping
-- Does not check if the object is a Finale object
local function get_class_name(object)
    -- If we're dealing with mixin objects, methods may have been added, so we need the originals
    local suffix = object.MixinClass and "_" or ""
    local class_name = object["ClassName" .. suffix](object)

    if class_name == "__FCCollection" and object["ExecuteModal" ..suffix] then
        return object["RegisterHandleCommand" .. suffix] and "FCCustomLuaWindow" or "FCCustomWindow"
    elseif class_name == "FCControl" then
        if object["GetCheck" .. suffix] then
            return "FCCtrlCheckbox"
        elseif object["GetThumbPosition" .. suffix] then
            return "FCCtrlSlider"
        elseif object["AddPage" .. suffix] then
            return "FCCtrlSwitcher"
        else
            return "FCCtrlButton"
        end
    elseif class_name == "FCCtrlButton" and object["GetThumbPosition" .. suffix] then
        return "FCCtrlSlider"
    end

    return class_name
end

-- Returns the name of the parent class
-- This function should only be called for classnames that start with "FC" or "__FC"
local function get_parent_class(classname)
    local class = finale[classname]
    if type(class) ~= "table" then return nil end
    if not finenv.IsRGPLua then -- old jw lua
        classt = class.__class
        if classt and classname ~= "__FCBase" then
            classtp = classt.__parent -- this line crashes Finale (in jw lua 0.54) if "__parent" doesn't exist, so we excluded "__FCBase" above, the only class without a parent
            if classtp and type(classtp) == "table" then
                for k, v in pairs(finale) do
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

local function try_load_module(name)
    local success, result = pcall(function(c) return require(c) end, name)

    -- If the reason it failed to load was anything other than module not found, display the error
    if not success and not result:match("module '[^']-' not found") then
        error(result, 0)
    end

    return success, result
end

function mixin.load_mixin_class(class_name)
    if mixin_classes[class_name] then return end

    local is_fcm = is_fcm_class_name(class_name)
    local is_fcx = is_fcx_class_name(class_name)

    local success, result = try_load_module("mixin." .. class_name)

    if not success then
        success, result = try_load_module("personal_mixin." .. class_name)
    end

    if not success then
        -- FCM classes are optional, so if it's valid and not found, start with a blank slate
        if is_fcm and finale[fcm_to_fc_class_name(class_name)] then
            result = {}
        else
            return
        end
    end

    -- Mixins must be a table
    if type(result) ~= "table" then
        error("Mixin '" .. class_name .. "' is not a table.", 0)
    end

    local class = {props = result}

    -- Check for trailing underscores
    for k, _ in pairs(class.props) do
        if type(k) == "string" and k:sub(-1) == "_" then
            error("Mixin methods and properties cannot end in an underscore (" .. class_name .. "." .. k .. ")", 0)
        end
    end

    -- Check for reserved properties
    for k, v in pairs(reserved_props) do
        if v == 0 and type(class.props[k]) ~= "nil" then
            error("Mixin '" .. class_name .. "' contains reserved property '" .. k .. "'", 0)
        end
    end

    -- Ensure that Init is a function
    if class.props.Init and type(class.props.Init) ~= "function" then
        error("Mixin '" .. class_name .. "' method 'Init' must be a function.", 0)
    end

    -- FCM specific
    if is_fcm then
        class.props.MixinParent = get_parent_class(fcm_to_fc_class_name(class_name))

        if class.props.MixinParent then
            class.props.MixinParent = fc_to_fcm_class_name(class.props.MixinParent)

            mixin.load_mixin_class(class.props.MixinParent)

            -- Collect init functions
            class.init = mixin_classes[class.props.MixinParent].init and utils.copy_table(mixin_classes[class.props.MixinParent].init) or {}

            if class.props.Init then
                table.insert(class.init, class.props.Init)
            end

            -- Collect parent methods/properties if not overridden
            -- This prevents having to traverse the whole tree every time a method or property is accessed
            for k, v in pairs(mixin_classes[class.props.MixinParent].props) do
                if type(class.props[k]) == "nil" then
                    class.props[k] = utils.copy_table(v)
                end
            end
        end

    -- FCX specific
    else
        -- FCX classes must specify a parent
        if not class.props.MixinParent then
            error("Mixin '" .. class_name .. "' does not have a 'MixinParent' property defined.", 0)
        end

        mixin.load_mixin_class(class.props.MixinParent)

        -- Check if FCX parent is missing
        if not mixin_classes[class.props.MixinParent] then
            error("Unable to load mixin '" .. class.props.MixinParent .. "' as parent of '" .. class_name .. "'", 0)
        end

        -- Get the base FCM class (all FCX classes must eventually arrive at an FCM parent)
        class.props.MixinBase = is_fcm_class_name(class.props.MixinParent) and class.props.MixinParent or mixin_classes[class.props.MixinParent].props.MixinBase
    end

    -- Add class info to properties
    class.props.MixinClass = class_name

    mixin_classes[class_name] = class
end

-- Catches an error and throws it at the specified level (relative to where this function was called)
-- First argument is called tryfunczzz for uniqueness
local pcall_line = debug.getinfo(1, "l").currentline + 2 -- This MUST refer to the pcall 2 lines below
local function catch_and_rethrow(tryfunczzz, levels, ...)
    return mixin.pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))
end

function mixin.pcall_wrapper(levels, success, result, ...)
    if not success then
        file, line, msg = result:match("([a-zA-Z]-:?[^:]+):([0-9]+): (.+)")
        msg = msg or result

        -- Conditions for rethrowing at a higher level:
        -- Ignore errors thrown with no level info (ie. level = 0), as we can't make any assumptions
        -- Both the file and line number indicate that it was thrown at this level
        if file and line and file:sub(-9) == "mixin.lua" and tonumber(line) == pcall_line then
            local d = debug.getinfo(levels, "n")

            -- Replace the method name with the correct one, for bad argument errors etc
            msg = msg:gsub("'tryfunczzz'", "'" .. (d.name or "") .. "'")

            -- Shift argument numbers down by one for colon function calls
            if d.namewhat == "method" then
                local arg = msg:match("^bad argument #(%d+)")

                if arg then
                    msg = msg:gsub("#" .. arg, "#" .. tostring(tonumber(arg) - 1), 1)
                end
            end

            error(msg, levels + 1)

        -- Otherwise, it's either an internal function error or we couldn't be certain that it isn't
        -- So, rethrow with original file and line number to be 'safe'
        else
            error(result, 0)
        end
    end

    return ...
end

local function proxy(t, ...)
    local n = select("#", ...)
    -- If no return values, then apply the fluid interface
    if n == 0 then
        return t
    end

    -- Apply mixin foundation to all returned finale objects
    for i = 1, n do
        mixin.enable_mixin(select(i, ...))
    end
    return ...
end

-- Returns a function that handles the fluid interface
function mixin.create_fluid_proxy(func, func_name)
    return function(t, ...)
        return proxy(t, catch_and_rethrow(func, 2, t, ...))
    end
end

-- Takes an FC object and enables the mixin
function mixin.enable_mixin(object, fcm_class_name)
    if not library.is_finale_object(object) or mixin_props[object] then return object end

    mixin.apply_mixin_foundation(object)
    fcm_class_name = fcm_class_name or fc_to_fcm_class_name(get_class_name(object))
    mixin_props[object] = {}

    mixin.load_mixin_class(fcm_class_name)

    if mixin_classes[fcm_class_name].init then
        for _, v in pairs(mixin_classes[fcm_class_name].init) do
            v(object)
        end
    end

    return object
end

-- Modifies an FC class to allow adding mixins to any instance of that class.
-- Needs an instance in order to gain access to the metatable
function mixin.apply_mixin_foundation(object)
    if not object or not library.is_finale_object(object) or object.IsMixinReady then return end

    -- Metatables are shared across all instances, so this only needs to be done once per class
    local meta = getmetatable(object)

    -- We need to retain a reference to the originals for later
    local original_index = meta.__index 
    local original_newindex = meta.__newindex

    local fcm_class_name = fc_to_fcm_class_name(get_class_name(object))

    meta.__index = function(t, k)
        -- Return a flag that this class has been modified
        -- Adding a property to the metatable would be preferable, but that would entail going down the rabbit hole of modifying metatables of metatables
        if k == "IsMixinReady" then return true end

        -- If the object doesn't have an associated mixin (ie from finale namespace), let's pretend that nothing has changed and return early
        if not mixin_props[t] then return original_index(t, k) end

        local prop

        -- If there's a trailing underscore in the key, then return the original property, whether it exists or not
        if type(k) == "string" and k:sub(-1) == "_" then
            -- Strip trailing underscore
            prop = original_index(t, k:sub(1, -2))

        -- Check if it's a custom or FCX property/method
        elseif type(mixin_props[t][k]) ~= "nil" then
            prop = mixin_props[t][k]
        
        -- Check if it's an FCM property/method
        elseif type(mixin_classes[fcm_class_name].props[k]) ~= "nil" then
            prop = mixin_classes[fcm_class_name].props[k]

            -- If it's a table, copy it to allow instance-level editing
            if type(prop) == "table" then
                mixin_props[t][k] = utils.copy_table(prop)
                prop = mixin[t][k]
            end

        -- Otherwise, use the underlying object
        else
            prop = original_index(t, k)
        end

        if type(prop) == "function" then
            return mixin.create_fluid_proxy(prop, k)
        else
            return prop
        end
    end

    -- This will cause certain things (eg misspelling a property) to fail silently as the misspelled property will be stored on the mixin instead of triggering an error
    -- Using methods instead of properties will avoid this
    meta.__newindex = function(t, k, v)
        -- Return early if this is not mixin-enabled
        if not mixin_props[t] then return catch_and_rethrow(original_newindex, 2, t, k, v) end

        -- Trailing underscores are reserved for accessing original methods
        if type(k) == "string" and k:sub(-1) == "_" then
            error("Mixin methods and properties cannot end in an underscore.", 2)
        end

        -- Setting a reserved property is not allowed
        if reserved_props[k] then
            error("Cannot set reserved property '" .. k .. "'", 2)
        end

        local type_v_original = type(original_index(t, k))

        -- If it's a method, or a property that doesn't exist on the original object, store it
        if type_v_original == "nil" then
            local type_v_mixin = type(mixin_props[t][k])
            local type_v = type(v)

            -- Technically, a property could still be erased by setting it to nil and then replacing it with a method afterwards
            -- But handling that case would mean either storing a list of all properties ever created, or preventing properties from being set to nil.
            if type_v_mixin ~= "nil" then
                if type_v == "function" and type_v_mixin ~= "function" then
                    error("A mixin method cannot be overridden with a property.", 2)
                elseif type_v_mixin == "function" and type_v ~= "function" then
                    error("A mixin property cannot be overridden with a method.", 2)
                end
            end

            mixin_props[t][k] = v

        -- If it's a method, we can override it but only with another method
        elseif type_v_original == "function" then
            if type(v) ~= "function" then
                error("A mixin method cannot be overridden with a property.", 2)
            end

            mixin_props[t][k] = v

        -- Otherwise, try and store it on the original property. If it's read-only, it will fail and we show the error
        else
            catch_and_rethrow(original_newindex, 2, t, k, v)
        end
    end
end

--[[
% subclass

Takes a mixin-enabled finale object and migrates it to an `FCX` subclass. Any conflicting property or method names will be overwritten.

If the object is not mixin-enabled or the current `MixinClass` is not a parent of `class_name`, then an error will be thrown.
If the current `MixinClass` is the same as `class_name`, this function will do nothing.

@ object (__FCMBase)
@ class_name (string) FCX class name.
: (__FCMBase|nil) The object that was passed with mixin applied.
]]
function mixin.subclass(object, class_name)
    if not library.is_finale_object(object) then
        error("Object is not a finale object.", 2)
    end

    if not catch_and_rethrow(mixin.subclass_helper, 2, object, class_name) then
        error(class_name .. " is not a subclass of " .. object.MixinClass, 2)
    end

    return object
end

-- Returns true on success, false if class_name is not a subclass of the object, and throws errors for everything else
-- Returns false because we only want the originally requested class name for the error message, which is then handled by mixin.subclass
function mixin.subclass_helper(object, class_name, suppress_errors)
    if not object.MixinClass then
        if suppress_errors then
            return false
        end

        error("Object is not mixin-enabled.", 2)
    end

    if not is_fcx_class_name(class_name) then
        if suppress_errors then
            return false
        end

        error("Mixins can only be subclassed with an FCX class.", 2)
    end

    if object.MixinClass == class_name then return true end

    mixin.load_mixin_class(class_name)

    if not mixin_classes[class_name] then
        if suppress_errors then
            return false
        end

        error("Mixin '" .. class_name .. "' not found.", 2)
    end

    -- If we've reached the top of the FCX inheritance tree and the class names don't match, then class_name is not a subclass
    if is_fcm_class_name(mixin_classes[class_name].props.MixinParent) and mixin_classes[class_name].props.MixinParent ~= object.MixinClass then
        return false
    end

    -- If loading the parent of class_name fails, then it's not a subclass of the object
    if mixin_classes[class_name].props.MixinParent ~= object.MixinClass then
        if not catch_and_rethrow(mixin.subclass_helper, 2, object, mixin_classes[class_name].props.MixinParent) then
            return false
        end
    end

    -- Copy the methods and properties over
    local props = mixin_props[object]
    for k, v in pairs(mixin_classes[class_name].props) do
        props[k] = utils.copy_table(v)
    end

    -- Run initialiser, if there is one
    if mixin_classes[class_name].props.Init then
        catch_and_rethrow(object.Init, 2, object)
    end

    return true
end

-- Silently returns nil on failure
function mixin.create_fcm(class_name, ...)
    mixin.load_mixin_class(class_name)
    if not mixin_classes[class_name] then return nil end

    return mixin.enable_mixin(catch_and_rethrow(finale[fcm_to_fc_class_name(class_name)], 2, ...))
end

-- Silently returns nil on failure
function mixin.create_fcx(class_name, ...)
    mixin.load_mixin_class(class_name)
    if not mixin_classes[class_name] then return nil end

    local object = mixin.create_fcm(mixin_classes[class_name].props.MixinBase, ...)

    if not object then return nil end

    if not catch_and_rethrow(mixin.subclass_helper, 2, object, class_name, false) then
        return nil
    end

    return object
end


local mixin_public = {subclass = mixin.subclass}

--[[
% is_instance_of

Checks if an object is an instance of a class.
Conditions:
- Parent cannot be instance of child.
- `FC` object cannot be an instance of an `FCM` or `FCX` class
- `FCM` object cannot be an instance of an `FCX` class
- `FCX` object cannot be an instance of an `FC` class

@ object (__FCBase) Any finale object, including mixin enabled objects.
@ class_name (string) An `FC`, `FCM`, or `FCX` class name. Can be the name of a parent class.
: (boolean)
]]
function mixin_public.is_instance_of(object, class_name)
    if not library.is_finale_object(object) then
        return false
    end

    -- 0 = FC
    -- 1 = FCM
    -- 2 = FCX
    local object_type = (is_fcx_class_name(object.MixinClass) and 2) or (is_fcm_class_name(object.MixinClass) and 1) or 0
    local class_type = (is_fcx_class_name(class_name) and 2) or (is_fcm_class_name(class_name) and 1) or 0

    -- See doc block for explanation of conditions
    if (object_type == 0 and class_type == 1) or (object_type == 0 and class_type == 2) or (object_type == 1 and class_type == 2) or (object_type == 2 and class_type == 0) then
        return false
    end

    local parent = object_type == 0 and get_class_name(object) or object.MixinClass

    -- Traverse FCX hierarchy until we get to an FCM base
    if object_type == 2 then
        repeat
            if parent == class_name then
                return true
            end

            -- We can assume that since we have an object, all parent classes have been loaded
            parent = mixin_classes[parent].props.MixinParent
        until is_fcm_class_name(parent)
    end

    -- Since FCM classes follow the same hierarchy as FC classes, convert to FC
    if object_type > 0 then
        parent = fcm_to_fc_class_name(parent)
    end

    if class_type > 0 then
        class_name = fcm_to_fc_class_name(class_name)
    end

    -- Traverse FC hierarchy
    repeat
        if parent == class_name then
            return true
        end

        parent = get_parent_class(parent)
    until not parent

    -- Nothing found
    return false
end

--[[
% assert_argument

Asserts that an argument to a mixin method is the expected type(s). This should only be used within mixin methods as the function name will be inserted automatically.

NOTE: For performance reasons, this function will only assert if in debug mode (ie `finenv.DebugEnabled == true`). If assertions are always required, use `force_assert_argument` instead.

If not a valid type, will throw a bad argument error at the level above where this function is called.
Types can be Lua types (eg `string`, `number`, `bool`, etc), finale class (eg `FCString`, `FCMeasure`, etc), or mixin class (eg `FCMString`, `FCMMeasure`, etc)
Parent classes cannot be specified as this function does not examine the class hierarchy.

Note that mixin classes may satisfy the condition for the underlying `FC` class.
For example, if the expected type is `FCString`, an `FCMString` object will pass the test, but an `FCXString` object will not.
If the expected type is `FCMString`, an `FCXString` object will pass the test but an `FCString` object will not.

@ value (mixed) The value to test.
@ expected_type (string|table) If there are multiple valid types, pass a table of strings.
@ argument_number (number) The REAL argument number for the error message (self counts as #1).
]]
function mixin_public.assert_argument(value, expected_type, argument_number)
    local t, tt

    if library.is_finale_object(value) then
        t = value.MixinClass
        tt = is_fcx_class_name(t) and value.MixinBase or get_class_name(value)
    else
        t = type(value)
    end

    if type(expected_type) == "table" then
        for _, v in ipairs(expected_type) do
            if t == v or tt == v then
                return
            end
        end

        expected_type = table.concat(expected_type, " or ")
    else
        if t == expected_type or tt == expected_type then
            return
        end
    end

    error("bad argument #" .. tostring(argument_number) .. " to 'tryfunczzz' (" .. expected_type .. " expected, got " .. (t or tt) .. ")", 3)
end

--[[
% force_assert_argument

The same as `assert_argument` except this function always asserts, regardless of whether debug mode is enabled.

@ value (mixed) The value to test.
@ expected_type (string|table) If there are multiple valid types, pass a table of strings.
@ argument_number (number) The REAL argument number for the error message (self counts as #1).
]]
mixin_public.force_assert_argument = mixin_public.assert_argument

--[[
% assert

Asserts a condition in a mixin method. If the condition is false, an error is thrown one level above where this function is called.
Only asserts when in debug mode. If assertion is required on all executions, use `force_assert` instead

@ condition (any) Can be any value or expression.
@ message (string) The error message.
@ [no_level] (boolean) If true, error will be thrown with no level (ie level 0)
]]
function mixin_public.assert(condition, message, no_level)
    if not condition then
        error(message, no_level and 0 or 3)
    end
end

--[[
% force_assert

The same as `assert` except this function always asserts, regardless of whether debug mode is enabled.

@ condition (any) Can be any value or expression.
@ message (string) The error message.
@ [no_level] (boolean) If true, error will be thrown with no level (ie level 0)
]]
mixin_public.force_assert = mixin_public.assert


-- Replace assert functions with dummy function when not in debug mode
if finenv.IsRGPLua and not finenv.DebugEnabled then
    mixin_public.assert_argument = function() end
    mixin_public.assert = mixin_public.assert_argument
end

--[[
% UI

Returns a mixin enabled UI object from `finenv.UI`

: (FCMUI)
]]
function mixin_public.UI()
    return mixin.enable_mixin(finenv.UI(), "FCMUI")
end

-- Create a new namespace for mixins
return setmetatable({}, {
    __newindex = function(t, k, v) end,
    __index = function(t, k)
        if mixin_public[k] then return mixin_public[k] end

        mixin.load_mixin_class(k)
        if not mixin_classes[k] then return nil end

        -- Cache the class tables
        mixin_public[k] = setmetatable({}, {
            __newindex = function(tt, kk, vv) end,
            __index = function(tt, kk)
                local val = utils.copy_table(mixin_classes[k].props[kk])
                if type(val) == "function" then
                    val = mixin.create_fluid_proxy(val, kk)
                end
                return val
            end,
            __call = function(_, ...)
                if is_fcm_class_name(k) then
                    return mixin.create_fcm(k, ...)
                else
                    return mixin.create_fcx(k, ...)
                end
            end
        })

        return mixin_public[k]
    end
})

--  Author: Edward Koltun
--  Date: November 3, 2021

--[[
$module Mixin

The Mixin library enables Finale objects to be modified with additional methods and properties to simplify the process of writing plugins. It provides two methods of formally defining mixins: `FCM` and `FCX` mixins. As an added convenience, the library also automatically applies a fluid interface to mixin methods where possible.

## The `mixin` Namespace
Mixin-enabled objects can be created from the `mixin` namespace, which functions in the same way as the `finale` namespace. To create a mixin-enabled version of a Finale object, simply add an `M` to the class name after the `FC` and call it from the `mixin` namespace.
```lua
-- Include the mixin namespace as well as any helper functions
local mixin = require("library.mixin")

-- Create mixin-enabled FCString
local str = mixin.FCMString()

-- Create mixin-enabled FCCustomLuaWindow
local dialog = mixin.FCMCustomLuaWindow()
```

## Adding Methods or Properties to Finale Objects
The mixin library allows methods and properties to be added to Finale objects in two ways:

1) Predefined `FCM` or `FCX` mixins which can be accessed from the `mixin` namespace or returned from other mixin methods. For example:
```lua
local mixin = require("library.mixin")

-- Loads a mixin-enabled FCCustomLuaWindow object and applies any methods or properties from the FCMCustomLuaWindow mixin and its parents
local dialog = mixin.FCMCustomLuaWindow()

-- Creates an FCMCustomLuaWindow object and applies the FCXMyCustomDialog mixin, along with any parent mixins
local mycustomdialog = mixin.FCXMyCustomDialog()
```
*For more information about `FCM` and `FCX` mixins, see the next section and the mixin templates further down the page*

2) Setting them on an object in the same way as a table. For example:

```lua
local mixin = require("library.mixin")
local str = mixin.FCMString()

-- Add a new property
str.MyCustomProperty = "Hello World"

-- Add a new method
function str:AlertMyCustomProperty()
    finenv.UI():AlertInfo(self.MyCustomProperty, "My Custom Property")
end

-- Execute the new method
str:AlertMyCustomProperty()
```

Regardless of which approach is used, the following principles apply:
- New methods can be added or existing methods can be overridden.
- New properties can be added but existing properties from the underlying `FC` object retain their original behaviour (ie if they are writable or read-only, and what types they can be).
- The original `FC` method can always be accessed by appending a trailing underscore to the method name (eg `control:GetWidth_()`).
- In keeping with the above, method and property names cannot end in an underscore. Setting a method or property name ending with an underscore will trigger an error.
- Methods or properties beginning with `Mixin` are reserved for internal use and cannot be set.
- The constructor cannot be overridden or changed in any way.


## `FCM` and `FCX` Mixins & Class Hierarchy

### `FCM` Mixins
`FCM` mixins are modified `FC` classes. The name of each `FCM` mixin corresponds to the `FC` class that it extends. For example `__FCBase` -> `__FCMBase`, `FCControl` -> `FCMControl`, `FCCustomLuaWindow` -> `FCMCustomLuaWindow`, etc etc

`FCM` mixins are mainly intended to enhance core functionality, by fixing bugs, expanding method signatures (eg allowing a method to accept a regular Lua string instead of an `FCString`) and providing additional convenience methods to simplify the process of writing plugins.

To maximise compatibility and to simplify migration, `FCM` mixins retain as much backwards compatibility as possible with standard code using `FC` classes, but there may be a very small number of breaking changes. These will be marked in the documentation.

*Note that `FCM` mixins are optional. If an `FCM` mixin does not exist in the `mixin` folder, a mixin-enabled Finale object will still be created (ie able to be modified and with a fluid interface). It just won't have any new or overridden methods.*

### `FCX` Mixins
`FCX` mixins are customised `FC` objects. With no restrictions and no requirement for backwards compatibility, `FCX` mixins are intended to create highly specialised functionality that is built off an existing `FCM` object.

The name of an `FCX` mixin can be anythng, as long as it begins with `FCX` followed by an uppercase letter.

### Mixin Class Hierarchy
With mixins, the new inheritance tree looks like this:

```
              ________
             /        \
 __FCBase    |    __FCMBase
     |       |        |
     V       |        V
 FCControl   |    FCMControl
     |       |        |
     V       |        V
FCCtrlEdit   |   FCMCtrlEdit
     |       |        |
     \_______/       ---
                      |
                      V
             FCXCtrlMeasurementEdit
```

`FCM` mixins share a parellel heirarchy with the `FC` classes, but as they are applied on top of an existing `FC` object, they come afterwards in the tree. `FCX` mixins are applied on top of `FCM` classes and any subsequent `FCX` mixins continue the tree in a linear a fashion downwards.

### Special Properties
The `mixin` library adds several read-only properties to mixin-enabled Finale objects. These are:
- **`MixinClass`** *`[string]`* - The mixin class name.
- **`MixinParent`** *`[?string]`* - The name of the parent mixin (for `__FCMBase` this will be `nil`).
- **`MixinBase`** *`[?string]`* - *FCX only.* The class name of the underlying `FCM` object on which it is based.
- **`Init`** *`[?function]`* - *Optional.* The mixin's `Init` meta-method or `nil` if it doesn't have one. As this is intended to be called internally, it is only available statically via the `mixin` namespace.
- **`MixinReady`** *`[true]`* - *Internal.* A flag for determining which `FC` classes have had their metatatables modified.


## Automatic Mixin Enabling
All `FC` objects that are returned from mixin methods are automatically upgraded to a mixin-enabled `FCM` object. This includes objects returned from methods inherited from the underlying `FC` object.


## Accessing Mixin Methods Statically
All methods from `FCM` and `FCX` mixins can be accessed statically through the `mixin` namespace.
```lua
local mixin = require("library.mixin")
local str = mixin.FCXString()

-- Standard instance method call
str:SetLuaString("hello world")

-- Accessing an instance method statically
mixin.FCXString.PrintString(str, "goodbye world")

-- Accessing a static method
mixin.FCXString.PrintHelloWorld()
```


## Fluid Interface (aka Method Chaining)
Any method on a mixin-enabled Finale object that returns zero values (returning `nil` still counts as a value) will have a fluid interface automatically applied by the library. This means that instead of returning nothing, the method will return `self`.

For example, this was the previous way of creating an edit control:
```lua
local dialog = finale.FCCustomLuaWindow()
dialog:SetWidth(100)
dialog:SetHeight(100)
local edit = dialog:CreateEdit(0, 0)
edit:SetWidth(25)
edit:SetMeasurement(12, finale.MEASUREMENTUNIT_DEFAULT)
```

With the fluid interface, the code above can be shortened to this:
```lua
local mixin = require("library.mixin")
local dialog = mixin.FCMCustomLuaWindow():SetWidth(100):SetHeight(100)

local edit = dialog:CreateEdit(0, 0):SetWidth(25):SetMeasurementInteger(12, finale.MEASUREMENTUNIT_DEFAULT)
```

Alternatively, the example above can be respaced in the following way:

```lua
local mixin = require("library.mixin")
local dialog = mixin.FCMCustomLuaWindow()
    :SetWidth(100)
    :SetHeight(100)
local edit = dialog:CreateEdit(0, 0)
    :SetWidth(25)
    :SetMeasurementInteger(12, finale.MEASUREMENTUNIT_DEFAULT)
```

## Creating Mixins
General points for creating mixins:
- Place mixins in a Lua file named after the mixin in the `mixin` or `personal_mixin` folder (eg `__FCMBase.lua`, `FCXMyCustomDialog.lua`, etc). There can only be one mixin per file.
- All mixins must return a table with two values (see the templates below for examples):
- - A `meta` table of information about the `mixin` and meta-methods.
- - A `public` table with public properties and methods
- The `Init` meta-method is called after the object has been constructed, so all public methods will be available.
- If you need to guarantee that a method call won't refer to an overridden method, use a static call (eg `mixin.FCMControl.GetText(self)`).

### `meta` Properties
The `meta` table can contain the following properties and methods:
- **Init** *(optional)* - An initializing method which should accept one argument, `self`.
- **Parent** *(FCX only, required)* - The name of the parent of an `FCX` mixin. If not set or the parent cannot be loaded, an error will be thrown.

### Creating `FCM` Mixins
Points to remember when creating `FCM` mixins:
- The filename of an `FCM` mixin must correspond exactly to the `FC` class that it extends (ie `__FCBase` -> `__FCMBase.lua`, `FCNote` -> `FCMNote.lua`). Since `FCM` mixins are optional, a misspelled filename will simply result in the mixin not being loaded, without any errors.
- `FCM` mixins can be defined for any class in the PDK, including parent classes that can't be directly accessed (eg `__FCMBase`, `FCControl`). Use these clases if you need to add functionality that will be inherited by all child classes.

Below is a basic template for creating an `FCM` mixin. Replace the example methods with 
```lua
-- Include the mixin namespace and helper methods (include any additional libraries below)
local mixin = require("library.mixin")

-- Table for storing private data for this mixin
local private = setmetatable({}, {__mode = "k"})

-- Meta information and public methods and properties
local meta = {}
local public = {}

-- Example initializer (remove this if not needed).
function meta:Init()
    -- Create private mixin storage and initialise private properties
    private[self] = private[self] or {
        ExamplePrivateProperty = "hello world",
    }
end

-- Define all methods here (remove/replace examples as needed)

-- Example public instance method (use a colon)
function public:SetExample(value)
    -- Ensure argument is the correct type for testing
    -- The argument number is 2 because when using a colon in the method signature, it will automatically be passed `self` as the first argument.
    mixin.assert_argument(value, "string", 2)

    private[self].ExamplePrivateProperty = value
end

-- Example public static method (note the use of a dot instead of a colon)
function public.GetMagicNumber()
    return 7
end

-- Return meta information and public methods/properties back to the mixin library
return {meta, public}
```

### Creating `FCX` Mixins
Points to remember when creating `FCX` mixins:
- The name of an `FCX` mixin must be in Pascal case (just like the `FC` classes), beginning with `FCX`. For example `FCXMyCustomDialog`, `FCXCtrlMeasurementEdit`, `FCXCtrlPageSizePopup`, etc
- The parent class must be declared, which can be either an `FCM` or `FCX` class. If it is an `FCM` class, it must be a concrete class (ie one that can be instantiated, like `FCMCtrlEdit`) and not an abstract parent class (ie not `FCMControl`).


Below is a template for creating an `FCX` mixin. It is almost identical to defining an `FCM` mixin but there are a couple of important differences.
```lua
-- Include the mixin namespace and helper methods (include any additional libraries below)
local mixin = require("library.mixin")

-- Table for storing private data for this mixin
local private = setmetatable({}, {__mode = "k"})

-- Meta information and public methods and properties
local meta = {}
local public = {}

-- FCX mixins must declare their parent class (change as needed)
meta.Parent = "FCMString"

-- Example initializer (remove this if not needed).
function meta:Init()
    -- Create private mixin storage and initialise private properties
    private[self] = private[self] or {
        Counter = 0,
    }
end

---
-- Define all methods here (remove/replace examples as needed)
---

-- Example public instance method (use a colon)
function public:IncrementCounter()
    private[self].Counter = private[self].Counter + 1
end


-- Example public static method (use a dot)
function public.GetHighestCounter()
    local highest = 0

    for _, v in pairs(private) do
        if v.Counter < highest then
            highest = v.Counter
        end
    end

    return highest
end

-- Return meta information and public methods/properties back to the mixin library
return {meta, public}
```

## Personal Mixins
If you've written mixins for your personal use and don't want to submit them to the Finale Lua repository, you can place them in a folder called `personal_mixin`, next to the `mixin` folder.

Personal mixins take precedence over public mixins, so if a mixin with the same name exists in both  folders, the one in the `personal_mixin` folder will be used.
]]

local utils = require("library.utils")
local library = require("library.general_library")

-- Public methods and mixin constructors, stored separately to keep the mixin namespace read-only.
local mixin_public = {}
-- Private methods
local mixin_private = {}
-- Fully resolved FCM and FCX mixin class definitions
local mixin_classes = {}
-- Weak table for mixin instance properties / methods
local mixin_props = setmetatable({}, {__mode = "k"})

-- Reserved properties (cannot be set on an object)
local reserved_props = {
    MixinReady = function(class) return true end,
    MixinClass = function(class) return class end,
    MixinParent = function(class) return mixin_classes[class].meta.Parent end,
    MixinBase = function(class) return mixin_classes[class].meta.Base end,
    Init = function(class) return mixin_classes[class].meta.Init end,
}

-- Create a new namespace for mixins
local mixin = setmetatable({}, {
    __newindex = function(t, k, v) end,
    __index = function(t, k)
        if mixin_public[k] then return mixin_public[k] end

        mixin_private.load_mixin_class(k)
        if not mixin_classes[k] then return nil end

        -- Cache the class tables
        mixin_public[k] = setmetatable({}, {
            __newindex = function(tt, kk, vv) end,
            __index = function(tt, kk)
                local val = reserved_props[kk] and utils.copy_table(reserved_props[kk](k)) or utils.copy_table(mixin_classes[k].public[kk])
                if type(val) == "function" then
                    val = mixin_private.create_fluid_proxy(val, kk)
                end
                return val
            end,
            __call = function(_, ...)
                if mixin_private.is_fcm_class_name(k) then
                    return mixin_private.create_fcm(k, ...)
                else
                    return mixin_private.create_fcx(k, ...)
                end
            end
        })

        return mixin_public[k]
    end
})

function mixin_private.is_fcm_class_name(class_name)
    return type(class_name) == "string" and (class_name:match("^FCM%u") or class_name:match("^__FCM%u")) and true or false
end

function mixin_private.is_fcx_class_name(class_name)
    return type(class_name) == "string" and class_name:match("^FCX%u") and true or false
end

function mixin_private.fcm_to_fc_class_name(class_name)
    return string.gsub(class_name, "FCM", "FC", 1)
end

function mixin_private.fc_to_fcm_class_name(class_name)
    return string.gsub(class_name, "FC", "FCM", 1)
end

function mixin_private.assert_valid_property_name(name, error_level, suffix)
    if type(name) ~= "string" then
        return
    end

    suffix = suffix or ""

    if name:sub(-1) == "_" then
        error("Mixin methods and properties cannot end in an underscore" .. suffix, error_level)
    elseif name:sub(1, 5):lower() == "mixin" then
        error("Mixin methods and properties beginning with 'Mixin' are reserved" .. suffix, error_level)
    elseif reserved_props[name] then
        error("'" .. name .. "' is a reserved name and cannot be used for propertiea or methods" .. suffix, error_level)
    end
end

-- Gets the real class name of a Finale object
-- Some classes have incorrect class names, so this function attempts to resolve them with ducktyping
-- Does not check if the object is a Finale object
function mixin_private.get_class_name(object)
    -- If we're dealing with mixin objects, methods may have been added so we need the originals
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
function mixin_private.get_parent_class(classname)
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

-- Attempts to load a module
function mixin_private.try_load_module(name)
    local success, result = pcall(function(c) return require(c) end, name)

    -- If the reason it failed to load was anything other than module not found, display the error
    if not success and not result:match("module '[^']-' not found") then
        error(result, 0)
    end

    return success, result
end

-- Loads an FCM or FCX mixin class
function mixin_private.load_mixin_class(class_name)
    if mixin_classes[class_name] then return end

    local is_fcm = mixin_private.is_fcm_class_name(class_name)
    local is_fcx = mixin_private.is_fcx_class_name(class_name)

    -- Try personal mixins first (allows the library's mixin to be overridden if desired)
    local success, result = mixin_private.try_load_module("personal_mixin." .. class_name)

    if not success then
        success, result = mixin_private.try_load_module("mixin." .. class_name)
    end

    if not success then
        -- FCM classes are optional, so if it's valid and not found, start with a blank slate
        if is_fcm and finale[mixin_private.fcm_to_fc_class_name(class_name)] then
            result = {{}, {}}
        else
            return
        end
    end

    -- Mixins must be a table
    if type(result) ~= "table" then
        error("Mixin '" .. class_name .. "' is not a table.", 0)
    end

    local class = {}
    if #result > 1 then
        class.meta = result[1]
        class.public = result[2]
    else
        -- Legacy compatibility
        class.public = result
        class.meta = {}
        class.meta.Parent = class.public.MixinParent
        class.meta.Init = class.public.Init
        class.public.MixinParent = nil
        class.public.Init = nil
    end

    -- Check that property names are valid
    for k, _ in pairs(class.public) do
        mixin_private.assert_valid_property_name(k, 0, " (" .. class_name .. "." .. k .. ")")
    end

    -- Ensure that Init is a function
    if class.meta.Init and type(class.meta.Init) ~= "function" then
        error("Mixin meta-method 'Init' must be a function (" .. class_name .. ")", 0)
    end

    -- FCM specific
    if is_fcm then
        -- Temporarily store the FC class name
        class.meta.Parent = mixin_private.get_parent_class(mixin_private.fcm_to_fc_class_name(class_name))

        if class.meta.Parent then
            -- Turn it back into an FCM class name
            class.meta.Parent = mixin_private.fc_to_fcm_class_name(class.meta.Parent)

            mixin_private.load_mixin_class(class.meta.Parent)

            -- Collect init functions
            class.init = mixin_classes[class.meta.Parent].init and utils.copy_table(mixin_classes[class.meta.Parent].init) or {}

            if class.meta.Init then
                table.insert(class.init, class.meta.Init)
            end

            -- Collect parent methods/properties if not overridden
            -- This prevents having to traverse the whole tree every time a method or property is accessed
            for k, v in pairs(mixin_classes[class.meta.Parent].public) do
                if type(class.public[k]) == "nil" then
                    class.public[k] = utils.copy_table(v)
                end
            end
        end

    -- FCX specific
    else
        -- FCX classes must specify a parent
        if not class.meta.Parent then
            error("Mixin '" .. class_name .. "' does not have a parent class defined.", 0)
        end

        mixin_private.load_mixin_class(class.meta.Parent)

        -- Check if FCX parent is missing
        if not mixin_classes[class.meta.Parent] then
            error("Unable to load mixin '" .. class.meta.Parent .. "' as parent of '" .. class_name .. "'", 0)
        end

        -- Get the base FCM class (all FCX classes must eventually arrive at an FCM parent)
        class.meta.Base = mixin_private.is_fcm_class_name(class.meta.Parent) and class.meta.Parent or mixin_classes[class.meta.Parent].meta.Base
    end

    -- Add class info to properties
    class.meta.Class = class_name

    mixin_classes[class_name] = class
end

-- Catches an error and throws it at the specified level (relative to where this function was called)
-- First argument is called tryfunczzz for uniqueness
-- Tail calls aren't counted as levels in the call stack. Adding an additional return value (in this case, 1) forces this level to be included, which enables the error to be accurately captured
local pcall_line = debug.getinfo(1, "l").currentline + 2 -- This MUST refer to the pcall 2 lines below
local function catch_and_rethrow(tryfunczzz, levels, ...)
    return mixin_private.pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))
end

-- Get the name of this file.
local mixin_file_name = debug.getinfo(1, "S").source
mixin_file_name = mixin_file_name:sub(1, 1) == "@" and mixin_file_name:sub(2) or nil

-- Processes the results from the pcall in catch_and_rethrow
function mixin_private.pcall_wrapper(levels, success, result, ...)
    if not success then
        local file
        local line
        local msg
        file, line, msg = result:match("([a-zA-Z]-:?[^:]+):([0-9]+): (.+)")
        msg = msg or result

        local file_is_truncated = file and file:sub(1, 3) == "..."
        file = file_is_truncated and file:sub(4) or file

        -- Conditions for rethrowing at a higher level:
        -- Ignore errors thrown with no level info (ie. level = 0), as we can't make any assumptions
        -- Both the file and line number indicate that it was thrown at this level
        if file
            and line
            and mixin_file_name
            and (file_is_truncated and mixin_file_name:sub(-1 * file:len()) == file or file == mixin_file_name)
            and tonumber(line) == pcall_line
        then
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

-- Proxy function for all mixin method calls
-- Handles the fluid interface and automatic promotion of all returned Finale objects to mixin objects
local function proxy(t, ...)
    local n = select("#", ...)
    -- If no return values, then apply the fluid interface
    if n == 0 then
        return t
    end

    -- Apply mixin foundation to all returned finale objects
    for i = 1, n do
        mixin_private.enable_mixin(select(i, ...))
    end
    return ...
end

-- Returns a function that handles the fluid interface, mixin enabling, and error re-throwing
function mixin_private.create_fluid_proxy(func, func_name)
    return function(t, ...)
        return proxy(t, catch_and_rethrow(func, 2, t, ...))
    end
end

-- Takes an FC object and enables the mixin
function mixin_private.enable_mixin(object, fcm_class_name)
    if mixin_props[object] or not library.is_finale_object(object) then
        return object
    end

    mixin_private.apply_mixin_foundation(object)
    fcm_class_name = fcm_class_name or mixin_private.fc_to_fcm_class_name(mixin_private.get_class_name(object))

    mixin_private.load_mixin_class(fcm_class_name)
    mixin_props[object] = {MixinClass = fcm_class_name}

    for _, v in pairs(mixin_classes[fcm_class_name].init) do
        v(object)
    end

    return object
end

-- Modifies an FC class to allow adding mixins to any instance of that class.
-- Needs an instance in order to gain access to the metatable
function mixin_private.apply_mixin_foundation(object)
    if not object or not library.is_finale_object(object) or object.MixinReady then return end

    -- Metatables are shared across all instances, so this only needs to be done once per class
    local meta = getmetatable(object)

    -- We need to retain a reference to the originals for later
    local original_index = meta.__index 
    local original_newindex = meta.__newindex

    local fcm_class_name = mixin_private.fc_to_fcm_class_name(mixin_private.get_class_name(object))

    meta.__index = function(t, k)
        -- Return a flag that this class has been modified
        -- Adding a property to the metatable would be preferable, but that would entail going down the rabbit hole of modifying metatables of metatables
        if k == "MixinReady" then return true end

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
        elseif type(mixin_classes[fcm_class_name].public[k]) ~= "nil" then
            prop = mixin_classes[fcm_class_name].public[k]

            -- If it's a table, copy it to allow instance-level editing
            if type(prop) == "table" then
                mixin_props[t][k] = utils.copy_table(prop)
                prop = mixin[t][k]
            end

        -- Check if it's a reserved property
        elseif reserved_props[k] then
            prop = reserved_props[k](mixin_props[t].MixinClass)

        -- Otherwise, use the underlying object
        else
            prop = original_index(t, k)
        end

        if type(prop) == "function" then
            return mixin_private.create_fluid_proxy(prop, k)
        else
            return prop
        end
    end

    -- This will cause certain things (eg misspelling a property) to fail silently as the misspelled property will be stored on the mixin instead of triggering an error
    -- Using methods instead of properties will avoid this
    meta.__newindex = function(t, k, v)
        -- Return early if this is not mixin-enabled
        if not mixin_props[t] then return catch_and_rethrow(original_newindex, 2, t, k, v) end

        mixin_private.assert_valid_property_name(k, 3)

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

-- See the doc block for mixin_public.subclass for information
function mixin_private.subclass(object, class_name)
    if not library.is_finale_object(object) then
        error("Object is not a finale object.", 2)
    end

    if not catch_and_rethrow(mixin_private.subclass_helper, 2, object, class_name) then
        error(class_name .. " is not a subclass of " .. object.MixinClass, 2)
    end

    return object
end

-- Returns true on success, false if class_name is not a subclass of the object, and throws errors for everything else
-- Returns false because we only want the originally requested class name for the error message, which is then handled by mixin_private.subclass
function mixin_private.subclass_helper(object, class_name, suppress_errors)
    if not object.MixinClass then
        if suppress_errors then
            return false
        end

        error("Object is not mixin-enabled.", 2)
    end

    if not mixin_private.is_fcx_class_name(class_name) then
        if suppress_errors then
            return false
        end

        error("Mixins can only be subclassed with an FCX class.", 2)
    end

    if object.MixinClass == class_name then return true end

    mixin_private.load_mixin_class(class_name)

    if not mixin_classes[class_name] then
        if suppress_errors then
            return false
        end

        error("Mixin '" .. class_name .. "' not found.", 2)
    end

    -- If we've reached the top of the FCX inheritance tree and the class names don't match, then class_name is not a subclass
    if mixin_private.is_fcm_class_name(mixin_classes[class_name].meta.Parent) and mixin_classes[class_name].meta.Parent ~= object.MixinClass then
        return false
    end

    -- If loading the parent of class_name fails, then it's not a subclass of the object
    if mixin_classes[class_name].meta.Parent ~= object.MixinClass then
        if not catch_and_rethrow(mixin_private.subclass_helper, 2, object, mixin_classes[class_name].meta.Parent) then
            return false
        end
    end

    -- Copy the methods and properties over
    local props = mixin_props[object]
    props.MixinClass = class_name

    for k, v in pairs(mixin_classes[class_name].public) do
        props[k] = utils.copy_table(v)
    end

    -- Run initialiser, if there is one
    if mixin_classes[class_name].meta.Init then
        catch_and_rethrow(mixin_classes[class_name].meta.Init, 2, object)
    end

    return true
end

-- Silently returns nil on failure
function mixin_private.create_fcm(class_name, ...)
    mixin_private.load_mixin_class(class_name)
    if not mixin_classes[class_name] then return nil end

    return mixin_private.enable_mixin(catch_and_rethrow(finale[mixin_private.fcm_to_fc_class_name(class_name)], 2, ...))
end

-- Silently returns nil on failure
function mixin_private.create_fcx(class_name, ...)
    mixin_private.load_mixin_class(class_name)
    if not mixin_classes[class_name] then return nil end

    local object = mixin_private.create_fcm(mixin_classes[class_name].meta.Base, ...)

    if not object then return nil end

    if not catch_and_rethrow(mixin_private.subclass_helper, 2, object, class_name, false) then
        return nil
    end

    return object
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
mixin_public.subclass = mixin_private.subclass

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
    local object_type = (mixin_private.is_fcx_class_name(object.MixinClass) and 2) or (mixin_private.is_fcm_class_name(object.MixinClass) and 1) or 0
    local class_type = (mixin_private.is_fcx_class_name(class_name) and 2) or (mixin_private.is_fcm_class_name(class_name) and 1) or 0

    -- See doc block for explanation of conditions
    if (object_type == 0 and class_type == 1) or (object_type == 0 and class_type == 2) or (object_type == 1 and class_type == 2) or (object_type == 2 and class_type == 0) then
        return false
    end

    local parent = object_type == 0 and mixin_private.get_class_name(object) or object.MixinClass

    -- Traverse FCX hierarchy until we get to an FCM base
    if object_type == 2 then
        repeat
            if parent == class_name then
                return true
            end

            -- We can assume that since we have an object, all parent classes have been loaded
            parent = mixin_classes[parent].meta.Parent
        until mixin_private.is_fcm_class_name(parent)
    end

    -- Since FCM classes follow the same hierarchy as FC classes, convert to FC
    if object_type > 0 then
        parent = mixin_private.fcm_to_fc_class_name(parent)
    end

    if class_type > 0 then
        class_name = mixin_private.fcm_to_fc_class_name(class_name)
    end

    -- Traverse FC hierarchy
    repeat
        if parent == class_name then
            return true
        end

        parent = mixin_private.get_parent_class(parent)
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
        tt = mixin_private.is_fcx_class_name(t) and value.MixinBase or mixin_private.get_class_name(value)
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

@ condition (any) Can be any value or expression. If a function, it will be called (with zero arguments) and the result will be tested.
@ message (string) The error message.
@ [no_level] (boolean) If true, error will be thrown with no level (ie level 0)
]]
function mixin_public.assert(condition, message, no_level)
    if type(condition) == 'function' then
        condition = condition()
    end

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
    return mixin_private.enable_mixin(finenv.UI(), "FCMUI")
end

--[[
% eachentry

A modified version of the JW/RGPLua `eachentry` function that allows items to be stored and used outside of a loop.

@ region (FCMusicRegion)
@ [layer] (number)
: (function) A generator which returns `FCMNoteEntry`s
]]
function mixin_public.eachentry(region, layer)
    local measure = region.StartMeasure
    local slotno = region:GetStartSlot()
    local i = 0
    local layertouse = 0
    if layer ~= nil then layertouse = layer end
    local c = mixin.FCMNoteEntryCell(measure, region:CalcStaffNumber(slotno))
    c:SetLoadLayerMode(layertouse)
    c:Load()
    return function ()
        while true do
            i = i + 1;
            local returnvalue = c:GetItemAt(i - 1)
            if returnvalue ~= nil then
                if (region:IsEntryPosWithin(returnvalue)) then return returnvalue end
            else
                measure = measure + 1
                if measure > region.EndMeasure then
                    measure = region.StartMeasure
                    slotno = slotno + 1
                    if (slotno > region:GetEndSlot()) then return nil end
                    c = mixin.FCMNoteEntryCell(measure, region:CalcStaffNumber(slotno))
                    c:SetLoadLayerMode(layertouse)
                    c:Load()
                    i = 0
                else
                    c = mixin.FCMNoteEntryCell(measure, region:CalcStaffNumber(slotno))
                    c:SetLoadLayerMode(layertouse)
                    c:Load()
                    i = 0
                end
            end
        end
    end
end

return mixin

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
local mixin_helper = require("library.mixin_helper")

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
    mixin_helper.assert_argument_type(2, value, "string")

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
local mixin_helper = require("library.mixin_helper")

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
-- FCM and FCX mixin class definitions
local mixin_classes = {}
-- Flattened class definitions for optimised runtime lookup
local mixin_lookup = {}
-- Weak table for mixin instance properties / methods
local mixin_props = setmetatable({}, {__mode = "k"})

-- Reserved properties, all accessible statically (cannot be set on an object)
local reserved_props = {
    MixinReady = function(class_name) return true end,
    MixinClass = function(class_name) return class_name end,
    MixinParent = function(class_name) return mixin_classes[class_name].Parent end,
    MixinBase = function(class_name) return mixin_classes[class_name].Base end,
    Init = function(class_name) return mixin_classes[class_name].Init end,
    __class = function(class_name) return mixin_private.create_method_reflection(class_name, "Methods") end,
    __static = function(class_name) return mixin_private.create_method_reflection(class_name, "StaticMethods") end,
    __propget = function(class_name) return mixin_private.create_property_reflection(class_name, "Get") end,
    __propset = function(class_name) return mixin_private.create_property_reflection(class_name, "Set") end,
    __disabled = function(class_name) return mixin_classes[class_name].Disabled and utils.copy_table(mixin_classes[class_name].Disabled) or {} end,
}

-- Reserved properties that are accessible from an object instance
local instance_reserved_props = {
    MixinReady = true,
    MixinClass = true,
    MixinParent = true,
    MixinBase = true,
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
                local value

                if mixin_lookup[k].Methods[kk] then
                    value = mixin_private.create_fluid_proxy(mixin_lookup[k].Methods[kk])
                elseif mixin_classes[k].StaticMethods and mixin_classes[k].StaticMethods[kk] then
                    value = mixin_private.create_proxy(mixin_classes[k].StaticMethods[kk])
                elseif mixin_lookup[k].Properties[kk] then
                    -- Use non-fluid proxy
                    value = {}
                    for kkkk, vvvv in pairs(mixin_lookup[k].Properties[kk]) do
                        value[kkkk] = mixin_private.create_proxy(vvvv)
                    end
                elseif reserved_props[kk] then
                    value = reserved_props[kk](k) -- reserved_props handles calls to copy_table itself if needed
                end

                return value
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

function mixin_private.is_fc_class_name(class_name)
    return type(class_name) == "string" and not mixin_private.is_fcm_class_name(class_name) and not mixin_private.is_fcx_class_name(class_name) and (class_name:match("^FC%u") or class_name:match("^__FC%u")) and true or false
end

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
        error("Mixin method and property names must be strings" .. suffix, error_level)
    end

    suffix = suffix or ""

    if name:sub(-2) == "__" then
        error("Mixin methods and properties cannot end in a double underscore" .. suffix, error_level)
    elseif name:sub(1, 5):lower() == "mixin" then
        error("Mixin methods and properties beginning with 'Mixin' are reserved" .. suffix, error_level)
    elseif reserved_props[name] then
        error("'" .. name .. "' is a reserved name and cannot be used for propertiea or methods" .. suffix, error_level)
    end
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

local find_ancestor_with_prop
find_ancestor_with_prop = function(class, attr, prop)
    if class[attr] and class[attr][prop] then
        return class.Class
    end
    if not class.Parent then
        return nil
    end
    return find_ancestor_with_prop(mixin_classes[class.Parent], attr, prop)
end

-- Loads an FCM or FCX mixin class
function mixin_private.load_mixin_class(class_name, create_lookup)
    if mixin_classes[class_name] then return end

    local is_fcm = mixin_private.is_fcm_class_name(class_name)

    -- Only load FCM and FCX mixins
    if not is_fcm and not mixin_private.is_fcx_class_name(class_name) then
        return
    end

    local is_personal_mixin = false
    local success
    local result

    -- Try personal mixins first (allows the library's mixin to be overridden if desired)
    -- But only if this is a user-trusted script
    if finenv.TrustedMode == nil or finenv.TrustedMode == finenv.TrustedModeType.USER_TRUSTED then
        success, result = mixin_private.try_load_module("personal_mixin." .. class_name)
    end

    if success then
        is_personal_mixin = true
    else
        success, result = mixin_private.try_load_module("mixin." .. class_name)
    end

    if not success then
        -- FCM classes are optional, so if it's valid and not found, start with a blank slate
        if is_fcm and finale[mixin_private.fcm_to_fc_class_name(class_name)] then
            result = {}
        else
            return
        end
    end

    local error_prefix = (is_personal_mixin and "personal_" or "") .. "mixin." .. class_name

    -- Mixins must be a table
    if type(result) ~= "table" then
        error("Mixin '" .. error_prefix .. "' is not a table.", 0)
    end

    local class = {Class = class_name}

    local function has_attr(attr, attr_type)
        if result[attr] == nil then
            return false
        end
        if type(result[attr]) ~= attr_type then
            error("Mixin '" .. attr .. "' must be a " .. attr_type .. ", " .. type(result[attr]) .. " given (" .. error_prefix .. "." .. attr .. ")", 0)
        end
        return true
    end

    -- Check and assign or copy parent
    has_attr("Parent", "string")

    -- FCM specific
    if is_fcm then
        -- Temporarily store the parent FC class name
        class.Parent = library.get_parent_class(mixin_private.fcm_to_fc_class_name(class_name))

        if class.Parent then
            -- Turn it back into an FCM class name
            class.Parent = mixin_private.fc_to_fcm_class_name(class.Parent)

            mixin_private.load_mixin_class(class.Parent)
        end

    -- FCX specific
    else
        -- FCX classes must specify a parent
        if not result.Parent then
            error("Mixin '" .. error_prefix .. "' does not have a parent class defined.", 0)
        end

        if not mixin_private.is_fcm_class_name(result.Parent) and not mixin_private.is_fcx_class_name(result.Parent) then
            error("Mixin parent must be an FCM or FCX class name, '" .. result.Parent .. "' given (" .. error_prefix .. ".Parent)", 0)
        end

        mixin_private.load_mixin_class(result.Parent)

        -- Check if FCX parent is missing
        if not mixin_classes[result.Parent] then
            error("Unable to load mixin '" .. result.Parent .. "' as parent of '" .. error_prefix .. "'", 0)
        end

        class.Parent = result.Parent

        -- Get the base FCM class (all FCX classes must eventually arrive at an FCM parent)
        class.Base = mixin_classes[result.Parent].Base or result.Parent
    end

    -- Now that we have the parent, create a lookup base before we continue
    local lookup = class.Parent and utils.copy_table(mixin_lookup[class.Parent]) or {Methods = {}, Properties = {}, Disabled = {}, FCMInits = {}}

    -- Check and copy the remaining attributes
    if has_attr("Init", "function") and is_fcm then
        table.insert(lookup.FCMInits, result.Init)
    end
    class.Init = result.Init
    if not is_fcm then
        lookup.FCMInits = nil
    end

    -- Process Disabled before methods and properties because we need these for later checks
    if has_attr("Disabled", "table") then
        class.Disabled = {}
        for _, v in pairs(result.Disabled) do
            mixin_private.assert_valid_property_name(v, 0, " (" .. error_prefix .. ".Disabled." .. tostring(v) .. ")")
            class.Disabled[v] = true
            lookup.Disabled[v] = true
            lookup.Methods[v] = nil
            lookup.Properties[v] = nil
        end
    end

    local function find_property_name_clash(name, attr_to_check)
        for _, attr in pairs(attr_to_check) do
            if attr == "StaticMethods" or (lookup[attr] and lookup[attr][nane]) then
                local cl = find_ancestor_with_prop(class, attr, name)
                return cl and (cl .. "." .. attr .. "." .. name) or nil
            end
        end
    end

    if has_attr("Methods", "table") then
        class.Methods = {}
        for k, v in pairs(result.Methods) do
            mixin_private.assert_valid_property_name(k, 0, " (" .. error_prefix .. ".Methods." .. tostring(k) .. ")")
            if type(v) ~= "function" then
                error("A mixin method must be a function, " .. type(v) .. " given (" .. error_prefix .. ".Methods." .. k .. ")", 0)
            end
            if lookup.Disabled[k] then
                error("Mixin methods cannot be defined for disabled names (" .. error_prefix .. ".Methods." .. k .. ")", 0)
            end
            local clash = find_property_name_clash(k, {"StaticMethods", "Properties"})
            if clash then
                error("A method, static method or property cannot share the same name (" .. error_prefix .. ".Methods." .. k .. " & " .. clash .. ")", 0)
            end
            class.Methods[k] = v
            lookup.Methods[k] = v
        end
    end

    if has_attr("StaticMethods", "table") then
        class.StaticMethods = {}
        for k, v in pairs(result.StaticMethods) do
            mixin_private.assert_valid_property_name(k, 0, " (" .. error_prefix .. ".StaticMethods." .. tostring(k) .. ")")
            if type(v) ~= "function" then
                error("A mixin method must be a function, " .. type(v) .. " given (" .. error_prefix .. ".StaticMethods." .. k .. ")", 0)
            end
            if lookup.Disabled[k] then
                error("Mixin methods cannot be defined for disabled names (" .. error_prefix .. ".StaticMethods." .. k .. ")", 0)
            end
            local clash = find_property_name_clash(k, {"Methods", "Properties"})
            if clash then
                error("A method, static method or property cannot share the same name (" .. error_prefix .. ".StaticMethods." .. k .. " & " .. clash .. ")", 0)
            end
            class.Methods[k] = v
        end
    end

    if has_attr("Properties", "table") then
        class.Properties = {}
        for k, v in pairs(result.Properties) do
            mixin_private.assert_valid_property_name(k, 0, " (" .. error_prefix .. ".Properties." .. tostring(k) .. ")")
            if lookup.Disabled[k] then
                error("Mixin properties cannot be defined for disabled names (" .. error_prefix .. ".Properties." .. k .. ")", 0)
            end
            local clash = find_property_name_clash(k, {"Methods", "StaticMethods"})
            if clash then
                error("A method, static method or property cannot share the same name (" .. error_prefix .. ".Properties." .. k .. " & " .. clash .. ")", 0)
            end
            if type(v) ~= "table" then
                error("A mixin property descriptor must be a table, " .. type(v) .. " given (" .. error_prefix .. ".Properties." .. k .. ")", 0)
            end
            if not v.Get and not v.Set then
                error("A mixin property descriptor must have at least a 'Get' or 'Set' attribute (" .. error_prefix .. ".Properties." .. k .. ")", 0)
            end

            class.Properties[k] = {}
            lookup.Properties[k] = lookup.Properties[k] or {}

            for kk, vv in pairs(v) do
                if kk ~= "Get" and kk ~= "Set" then
                    error("A mixin property descriptor can only have 'Get' and 'Set' attributes (" .. error_prefix .. ".Properties." .. k .. ")", 0)
                end
                if type(vv) ~= "function" then
                    error("A mixin property descriptor attribute must be a function, " .. type(vv) .. " given (" .. error_prefix .. ".Properties." .. k .. "." .. kk .. ")", 0)
                end
                class.Properties[k][kk] = vv
                lookup.Properties[k][kk] = vv
            end
        end
    end

    mixin_lookup[class_name] = lookup
    mixin_classes[class_name] = class
end

function mixin_private.create_method_reflection(class_name, attr)
    local t = {}
    if mixin_classes[class_name][attr] then
        for k, v in pairs(mixin_classes[class_name][attr]) do
            t[k] = mixin_private.create_proxy(v)
        end
    end
    return t
end

function mixin_private.create_property_reflection(class_name, attr)
    local t = {}
    if mixin_classes[class_name].Properties then
        for k, v in pairs(mixin_classes[class_name].Properties) do
            if v[attr] then
                t[k] = mixin_private.create_proxy(v[attr])
            end
        end
    end
    return t
end

-- Proxy function for all mixin method calls
-- Handles the fluid interface and automatic promotion of all returned Finale objects to mixin objects
local function fluid_proxy(t, ...)
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

local function proxy(t, ...)
    local n = select("#", ...)
    -- Apply mixin foundation to all returned finale objects
    for i = 1, n do
        mixin_private.enable_mixin(select(i, ...))
    end
    return ...
end

-- Returns a function that handles the fluid interface, mixin enabling, and error re-throwing
function mixin_private.create_fluid_proxy(func)
    return function(t, ...)
        return fluid_proxy(t, utils.call_and_rethrow(2, func, t, ...))
    end
end

function mixin_private.create_proxy(func)
    return function(t, ...)
        return proxy(t, utils.call_and_rethrow(2, func, t, ...))
    end
end


-- Takes an FC object and enables the mixin
function mixin_private.enable_mixin(object, fcm_class_name)
    if mixin_props[object] or not library.is_finale_object(object) then
        return object
    end

    mixin_private.apply_mixin_foundation(object)
    fcm_class_name = fcm_class_name or mixin_private.fc_to_fcm_class_name(library.get_class_name(object))

    mixin_private.load_mixin_class(fcm_class_name)
    mixin_props[object] = {MixinClass = fcm_class_name}

    for _, v in ipairs(mixin_lookup[fcm_class_name].FCMInits) do
        v(object)
    end

    return object
end

-- Modifies an FC class to allow adding mixins to any instance of that class.
-- Needs an instance in order to gain access to the metatable
-- Does not check if object is a Finale object
function mixin_private.apply_mixin_foundation(object)
    if object.MixinReady then return end

    -- Metatables are shared across all instances, so this only needs to be done once per class
    local meta = getmetatable(object)

    -- We need to retain a reference to the originals for later
    local original_index = meta.__index 
    local original_newindex = meta.__newindex

    meta.__index = function(t, k)
        -- Return a flag that this class has been modified
        -- Adding a property to the metatable would be preferable, but that would entail going down the rabbit hole of modifying metatables of metatables
        if k == "MixinReady" then return true end

        -- If the object doesn't have an associated mixin (ie from finale namespace), let's pretend that nothing has changed and return early
        if not mixin_props[t] then return original_index(t, k) end

        local class = mixin_props[t].MixinClass
        local prop

        -- If there's a trailing double underscore in the key, then return the original property, whether it exists or not
        if type(k) == "string" and k:sub(-2) == "__" then
            -- Strip trailing underscore
            prop = original_index(t, k:sub(1, -3))

        -- Check defined properties
        elseif mixin_lookup[class].Properties[k] and mixin_lookup[class].Properties[k].Get then
            prop = utils.call_and_rethrow(2, mixin_lookup[class].Properties[k].Get, t)

        -- Check if it's a custom property/method
        elseif mixin_props[t][k] ~= nil then
            prop = utils.copy_table(mixin_props[t][k])

        -- Check if it's an FCM or FCX method
        elseif mixin_lookup[class].Methods[k] then
            prop = mixin_lookup[class].Methods[k]

        -- Check if it's a reserved property
        elseif instance_reserved_props[k] then
            prop = reserved_props[k](class)

        -- Otherwise, use the underlying object
        else
            prop = original_index(t, k)
        end

        if type(prop) == "function" then
            return mixin_private.create_fluid_proxy(prop)
        end

        return prop
    end

    -- This will cause certain things (eg misspelling a property) to fail silently as the misspelled property will be stored on the mixin instead of triggering an error
    -- Using methods instead of properties will avoid this
    meta.__newindex = function(t, k, v)
        -- Return original if this is not mixin-enabled
        if not mixin_props[t] then
            return original_newindex(t, k, v)
        end

        local class = mixin_props[t].MixinClass

        -- If it's disabled or reserved, throw an error
        if mixin_lookup[class].Disabled[k] or reserved_props[k] then
            error("No writable member '" .. tostring(k) .. "'", 2)
        end

        -- If a property descriptor exists, use the setter if it has one
        -- Otherwise, use the original property (this prevents a read-only property from being overwritten by a custom property)
        if mixin_lookup[class].Properties[k] then
            if mixin_lookup[class].Properties[k].Set then
                return mixin_lookup[class].Properties[k].Set(t, v)
            else
                return original_newindex(t, k, v)
            end
        end

        -- If it's not a string key, it has to be a custom property
        if type(k) ~= "string" then
            mixin_props[t][k] = v
            return
        end

        -- For a trailing double underscore, set original property
        if k:sub(-2) == "__" then
            k = k:sub(1, -3)
            return original_newindex(t, k, v)
        end

        mixin_private.assert_valid_property_name(k, 3)

        local type_v_original = type(original_index(t, k))
        local type_v = type(v)
        local is_mixin_method = mixin_lookup[class].Methods[k] and true or false

        -- If it's a method or property that doesn't exist on the original object, store it
        if type_v_original == "nil" then

            if is_mixin_method and not (type_v == "function" or type_v == "nil") then
                error("A mixin method cannot be overridden with a property.", 2)
            end

            mixin_props[t][k] = v
            return

        -- If it's a method, we can override it but only with another method
        elseif type_v_original == "function" then
            if not (type_v == "function" or type_v == "nil") then
                error("A Finale PDK method cannot be overridden with a property.", 2)
            end

            mixin_props[t][k] = v
            return
        end

        -- Otherwise, try and store it on the original property. If it's read-only, it will fail and we show the error
        return original_newindex(t, k, v)
    end
end

-- See the doc block for mixin_public.subclass for information
function mixin_private.subclass(object, class_name)
    if not library.is_finale_object(object) then
        error("Object is not a finale object.", 2)
    end

    if not utils.call_and_rethrow(2, mixin_private.subclass_helper, object, class_name) then
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
    if mixin_private.is_fcm_class_name(mixin_classes[class_name].Parent) and mixin_classes[class_name].Parent ~= object.MixinClass then
        return false
    end

    -- If loading the parent of class_name fails, then it's not a subclass of the object
    if mixin_classes[class_name].Parent ~= object.MixinClass then
        if not utils.call_and_rethrow(2, mixin_private.subclass_helper, object, mixin_classes[class_name].Parent) then
            return false
        end
    end

    -- Change class name
    mixin_props[object].MixinClass = class_name

    -- Remove any newly disabled methods or properties
    if mixin_classes[class_name].Disabled then
        for k, _ in pairs(mixin_classes[class_name].Disabled) do
            mixin_props[object][k] = nil
        end
    end

    -- Run initialiser, if there is one
    if mixin_classes[class_name].Init then
        utils.call_and_rethrow(2, mixin_classes[class_name].Init, object)
    end

    return true
end

-- Silently returns nil on failure
function mixin_private.create_fcm(class_name, ...)
    mixin_private.load_mixin_class(class_name)
    if not mixin_classes[class_name] then return nil end

    return mixin_private.enable_mixin(utils.call_and_rethrow(2, finale[mixin_private.fcm_to_fc_class_name(class_name)], ...))
end

-- Silently returns nil on failure
function mixin_private.create_fcx(class_name, ...)
    mixin_private.load_mixin_class(class_name)
    if not mixin_classes[class_name] then return nil end

    local object = mixin_private.create_fcm(mixin_classes[class_name].Base, ...)

    if not object then return nil end

    if not utils.call_and_rethrow(2, mixin_private.subclass_helper, object, class_name, false) then
        return nil
    end

    return object
end

--[[
% is_fc_class_name

Checks if a class name is an `FC` class name.

@ class_name (string)
: (boolean)
]]
mixin_public.is_fc_class_name = mixin_private.is_fc_class_name

--[[
% is_fcm_class_name

Checks if a class name is an `FCM` class name.

@ class_name (string)
: (boolean)
]]
mixin_public.is_fcm_class_name = mixin_private.is_fcm_class_name

--[[
% is_fcx_class_name

Checks if a class name is an `FCX` class name.

@ class_name (string)
: (boolean)
]]
mixin_public.is_fcx_class_name = mixin_private.is_fcx_class_name

--[[
% fc_to_fcm_class_name

Converts an `FC` class name to an `FCM` class name.

@ class_name (string)
: (string)
]]
mixin_public.fc_to_fcm_class_name = mixin_private.fc_to_fcm_class_name

--[[
% fcm_to_fc_class_name

Converts an `FCM` class name to an `FC` class name.

@ class_name (string)
: (string)
]]
mixin_public.fcm_to_fc_class_name = mixin_private.fcm_to_fc_class_name

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

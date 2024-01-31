# Mixin

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

## Functions

- [is_fc_class_name(class_name)](#is_fc_class_name)
- [is_fcm_class_name(class_name)](#is_fcm_class_name)
- [is_fcx_class_name(class_name)](#is_fcx_class_name)
- [fc_to_fcm_class_name(class_name)](#fc_to_fcm_class_name)
- [fcm_to_fc_class_name(class_name)](#fcm_to_fc_class_name)
- [subclass(object, class_name)](#subclass)
- [UI()](#ui)
- [eachentry(region, layer)](#eachentry)

### is_fc_class_name

```lua
mixin.is_fc_class_name(class_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin.lua#L942)

Checks if a class name is an `FC` class name.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `class_name` | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### is_fcm_class_name

```lua
mixin.is_fcm_class_name(class_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin.lua#L952)

Checks if a class name is an `FCM` class name.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `class_name` | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### is_fcx_class_name

```lua
mixin.is_fcx_class_name(class_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin.lua#L962)

Checks if a class name is an `FCX` class name.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `class_name` | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### fc_to_fcm_class_name

```lua
mixin.fc_to_fcm_class_name(class_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin.lua#L972)

Converts an `FC` class name to an `FCM` class name.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `class_name` | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### fcm_to_fc_class_name

```lua
mixin.fcm_to_fc_class_name(class_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin.lua#L982)

Converts an `FCM` class name to an `FC` class name.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `class_name` | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### subclass

```lua
mixin.subclass(object, class_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin.lua#L996)

Takes a mixin-enabled finale object and migrates it to an `FCX` subclass. Any conflicting property or method names will be overwritten.

If the object is not mixin-enabled or the current `MixinClass` is not a parent of `class_name`, then an error will be thrown.
If the current `MixinClass` is the same as `class_name`, this function will do nothing.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `object` | `__FCMBase` |  |
| `class_name` | `string` | FCX class name. |

| Return type | Description |
| ----------- | ----------- |
| `__FCMBase\\|nil` | The object that was passed with mixin applied. |

### UI

```lua
mixin.UI()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin.lua#L1005)

Returns a mixin enabled UI object from `finenv.UI`

| Return type | Description |
| ----------- | ----------- |
| `FCMUI` |  |

### eachentry

```lua
mixin.eachentry(region, layer)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin.lua#L1018)

A modified version of the JW/RGPLua `eachentry` function that allows items to be stored and used outside of a loop.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `region` | `FCMusicRegion` |  |
| `layer` (optional) | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `function` | A generator which returns `FCMNoteEntry`s |

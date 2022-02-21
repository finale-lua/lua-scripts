# Fluid Mixins

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

- [has_mixin](#has_mixin)
- [has_mixin](#has_mixin)
- [register_global_mixin](#register_global_mixin)
- [register_named_mixin](#register_named_mixin)
- [get_global_mixin](#get_global_mixin)
- [get_named_mixin](#get_named_mixin)

## has_mixin

```lua
fluid_mixins.has_mixin(name)
```

Object Method: Checks if the object it is called on has a mixin applied.

Example:
```
print(dialog.has_mixin('my_custom_dialog')) -- false

dialog.apply_mixin('my_custom_dialog');

print(dialog.has_mixin('my_custom_dialog')) -- true
```


| Input | Type | Description |
| --- | --- | --- |
| `name` | `string` | Mixin name. |

| Output type | Description |
| --- | --- |
| `boolean` |  |

## has_mixin

```lua
fluid_mixins.has_mixin(name)
```

Object Method: Applies a mixin to the object it is called on.

Example:
```
local mixin = require('library.mixin')
require('mixin.named.my_custom_dialog')

local dialog = finale.FCCustomLuaWindow()
dialog.apply_mixin('my_custom_dialog');
```


| Input | Type | Description |
| --- | --- | --- |
| `name` | `string` | Mixin name. |

## register_global_mixin

```lua
fluid_mixins.register_global_mixin(class, prop[, value])
```

Library Method: Register a mixin for a finale class that will be applied globally (ie to all instances of the specified classes, including existing instances). Properties and methods cannot end in an underscore.


| Input | Type | Description |
| --- | --- | --- |
| `class` | `string\|array` | The target class (or an array of classes). |
| `prop` | `string\|table` | Either the property name, or a table with pairs of (string) = (mixed) |
@ value [mixed] OPTIONAL: Method or property value. Will be ignored if prop is a table.

## register_named_mixin

```lua
fluid_mixins.register_named_mixin(class, mixin_name, prop[, value])
```

Library Method: Register a named mixin which can then be applied by calling the target object's apply_mixin method. If a named mixin requires a 'constructor', include a method called 'init' that accepts zero arguments. It will be called when the mixin is applied. Properties and methods cannot end in an underscore.


| Input | Type | Description |
| --- | --- | --- |
| `class` | `string\|array` | The class (or an array of classes) to apply the mixin to. |
| `mixin_name` | `string\|array` | Mixin name, or an array of names. |
| `prop` | `string\|table` | Either the property name, or a table with pairs of (string) = (mixed) |
@ value [mixed] OPTIONAL: Method or property value. Will be ignored if prop is a table.

## get_global_mixin

```lua
fluid_mixins.get_global_mixin(class, prop)
```

Library Method: Returns a copy of all methods and properties of a global mixin.


| Input | Type | Description |
| --- | --- | --- |
| `class` | `string` | The finale class name. |

| Output type | Description |
| --- | --- |
| `table\|nil` |  |

## get_named_mixin

```lua
fluid_mixins.get_named_mixin(class, mixin_name)
```

Library Method: Retrieves a copy of all the methods and properties of a named mixin.


| Input | Type | Description |
| --- | --- | --- |
| `class` | `string` | Finale class. |
| `mixin_name` | `string` | Name of mixin. |

| Output type | Description |
| --- | --- |
| `table\|nil` |  |
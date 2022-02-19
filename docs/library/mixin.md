# Fluid Mixins

Fluid mixins simplify the process of writing plugins and improve code maintainability.

This library does 2 things:
- Allows mixins to be added to any `FC*` objects
- Adds a fluid interface for any methods that don't return anything.

By default, it is not possible to override or extend any of the FC* objects in Finale Lua
because objects that are tied to their underlying C++ implementation are not tables.
So through a little bit of magic with proxying, this PR enables new methods and properties to be added.
If needed, the original functionality can always be accessed.

In short:
- Existing methods can be overridden
- New methods can be added
- New properties can be added
- Existing properties follow original behaviour (eg whether read-only or writable)
- Original method is always accessible by appending a trailing underscore to the method name, e.g. `SetText_(foo)`

The fluid interface strives to reduce the necessity of duplicate code when writing plugins.
It works by returning the `this` value from any method that would otherwise return nothing.
Methods that return nil or false are not affected by this. Only methods that return no values
have the fluid interface applied.

Here's an example of creating a window with some static text the standard way:
```
local window = finale.FCCustomLuaWindow()

local str = finale.FCString()
str.LuaString = 'this is some text'
window:CreateStatic(10, 10):SetText(str)

window:ExecuteModal(nil)
```

Now, if we include the Fluid Mixin library, immediately we have some improvements:
```
local window = finale.FCCustomLuaWindow()

window:CreateStatic(10, 10):SetText(finale.FCString():SetLuaString('this is some text'))

window:ExecuteModal(nil)
```

If we were to then override the `SetText` method so that it accepts plain strings like so:
```
mixin.register_default('FCCtrlStatic', 'SetText', function(this, str)
	if type(str) == 'string' then
		local temp = str
		str = finale.FCString():SetLuaString(temp) -- This works because of the fluid interface
	end

	-- Trailing underscore is used to refer to the original method
	this:SetText_(str)

	-- By not returning a value (copying the behaviour of the original method), the fluid interface is maintained
end)
```

The code could be reduced even further to this:
```
local window = finale.FCCustomLuaWindow()

window:CreateStatic(10, 10):SetText('this is some text')

window:ExecuteModal(nil)
```
In the example above, the same mixin could also be applied on mass by passing an array of classes and or method names.


There are other ways in which this could be used including:
- Fix methods that have bugs.
- Where possible, allow methods to accept Lua types (e.g., `string` instead of `FCString`, array of strings instead of `FCStrings`, etc.)
- Add additional high level functionality. (I have written some of these for dialogs, which was especially useful in reducing boilerplating.)
- In the absence of the ability to inherit from `FC*` objects, named mixins can be used to create subclasses.

Functions available in the mixin library are:

- [has_mixin](#has_mixin)
- [has_mixin](#has_mixin)
- [register_global_mixin](#register_global_mixin)
- [register_mixin](#register_mixin)
- [get_global_mixin](#get_global_mixin)
- [get_mixin](#get_mixin)

## has_mixin

```lua
fluid_mixins.has_mixin(name)
```

Object Method: Checks if the object it is called on has a mixin applied.


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

## register_mixin

```lua
fluid_mixins.register_mixin(class, mixin_name, prop[, value])
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

## get_mixin

```lua
fluid_mixins.get_mixin(class, mixin_name)
```

Library Method: Retrieves a copy of all the methods and properties of mixin.


| Input | Type | Description |
| --- | --- | --- |
| `class` | `string` | Finale class. |
| `mixin_name` | `string` | Name of mixin. |

| Output type | Description |
| --- | --- |
| `table\|nil` |  |
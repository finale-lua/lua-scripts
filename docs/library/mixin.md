# Fluid Mixins

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
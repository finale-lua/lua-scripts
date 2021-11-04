# Fluid Mixins

- [register_default](#register_default)
- [register_named](#register_named)
- [get_default](#get_default)
- [get_named](#get_named)
- [apply_named](#apply_named)
- [apply_table](#apply_table)

## register_default

```lua
fluid_mixins.register_default(class, prop[, value])
```

Register a mixin for a Finale class that will be applied globally. Note that methods are applied retroactively but properties will only be applied to new instances.


| Input | Type | Description |
| --- | --- | --- |
| `class` | `string\|array` | The class (or an array of classes) to apply the mixin to. |
| `prop` | `string\|table` | Either the property name, or a table with pairs of (string) = (mixed) |
@ value [mixed] OPTIONAL: Method or property value. Will be ignored if prop is a table.

## register_named

```lua
fluid_mixins.register_named(class, mixin_name, prop[, value])
```

Register a named mixin which can then be applied by calling apply_named. If a named mixin requires setup, include a method called `init` that accepts zero arguments. It will be called when the mixin is applied.


| Input | Type | Description |
| --- | --- | --- |
| `class` | `string\|array` | The class (or an array of classes) to apply the mixin to. |
| `mixin_name` | `string\|array` | Mixin name, or an array of names. |
| `prop` | `string\|table` | Either the property name, or a table with pairs of (string) = (mixed) |
@ value [mixed] OPTIONAL: Method or property value. Will be ignored if prop is a table.

## get_default

```lua
fluid_mixins.get_default(class, prop)
```

Retrieves the value of a default mixin.


| Input | Type | Description |
| --- | --- | --- |
| `class` | `string` | The Finale class name. |
| `prop` | `string` | The name of the property or method. |

| Output type | Description |
| --- | --- |
| `mixed\|nil` | If the value is a table, a copy will be returned. |

## get_named

```lua
fluid_mixins.get_named(class, mixin_name)
```

Retrieves all the methods / properties of a named mixin.


| Input | Type | Description |
| --- | --- | --- |
| `class` | `string` | Finale class. |
| `mixin_name` | `string` | Name of mixin. |

| Output type | Description |
| --- | --- |
| `table\|nil` |  |

## apply_named

```lua
fluid_mixins.apply_named(object, mixin_name)
```

Applies a named mixin to an object. See apply_table for more details.


| Input | Type | Description |
| --- | --- | --- |
| `object` | `__FCBase` | The object to apply the mixin to. |
| `mixin_name` | `string` | The name of the mixin to apply. |

| Output type | Description |
| --- | --- |
| `__FCBase` | The object that was passed. |

## apply_table

```lua
fluid_mixins.apply_table(object, table)
```

Takes all pairs in the table and copies them over to the target object. If there is an `init` method, it will be called and then removed. This method does not check for conflicts sonit may result in another mixin's method / property being overwritten.


| Input | Type | Description |
| --- | --- | --- |
| `object` | `__FCBase` | The target object. |
| `mixin_table` | `table` | Table of properties to apply_table |

| Output type | Description |
| --- | --- |
| `__FCBase` | The object that was passed. |
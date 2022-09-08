# Utility Functions

A library of general Lua utility functions.

## Functions

- [copy_table(t)](#copy_table)
- [table_remove_first(t, value)](#table_remove_first)
- [iterate_keys(t)](#iterate_keys)
- [round(num)](#round)
- [calc_roman_numeral(num)](#calc_roman_numeral)
- [calc_ordinal(num)](#calc_ordinal)
- [calc_alphabet(num)](#calc_alphabet)
- [clamp(num, minimum, maximum)](#clamp)

### copy_table

```lua
utility_functions.copy_table(t)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/utils.lua#L16)

If a table is passed, returns a copy, otherwise returns the passed value.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `t` | `mixed` |  |

| Return type | Description |
| ----------- | ----------- |
| `mixed` |  |

### table_remove_first

```lua
utility_functions.table_remove_first(t, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/utils.lua#L37)

Removes the first occurrence of a value from an array table.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `t` | `table` |  |
| `value` | `mixed` |  |

### iterate_keys

```lua
utility_functions.iterate_keys(t)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/utils.lua#L54)

Returns an unordered iterator for the keys in a table.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `t` | `table` |  |

| Return type | Description |
| ----------- | ----------- |
| `function` |  |

### round

```lua
utility_functions.round(num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/utils.lua#L71)

Rounds a number to the nearest whole integer.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### calc_roman_numeral

```lua
utility_functions.calc_roman_numeral(num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/utils.lua#L83)

Calculates the roman numeral for the input number. Adapted from https://exercism.org/tracks/lua/exercises/roman-numerals/solutions/Nia11 on 2022-08-13

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### calc_ordinal

```lua
utility_functions.calc_ordinal(num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/utils.lua#L104)

Calculates the ordinal for the input number (e.g. 1st, 2nd, 3rd).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### calc_alphabet

```lua
utility_functions.calc_alphabet(num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/utils.lua#L128)

This returns one of the ways that Finale handles numbering things alphabetically, such as rehearsal marks or measure numbers.

This function was written to emulate the way Finale numbers saves when Autonumber is set to A, B, C... When the end of the alphabet is reached it goes to A1, B1, C1, then presumably to A2, B2, C2. 

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### clamp

```lua
utility_functions.clamp(num, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/utils.lua#L145)

Clamps a number between two values.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` | The number to clamp. |
| `minimum` | `number` | The minimum value. |
| `maximum` | `number` | The maximum value. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

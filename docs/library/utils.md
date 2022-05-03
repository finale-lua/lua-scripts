# Utility Functions

A library of general Lua utility functions.

- [copy_table](#copy_table)
- [table_remove_first](#table_remove_first)
- [iterate_keys](#iterate_keys)
- [round](#round)

## copy_table

```lua
utility_functions.copy_table(t)
```

If a table is passed, returns a copy, otherwise returns the passed value.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `t` | `mixed` |  |

| Return type | Description |
| ----------- | ----------- |
| `mixed` |  |

## table_remove_first

```lua
utility_functions.table_remove_first(t, value)
```

Removes the first occurrence of a value from an array table.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `t` | `table` |  |
| `value` | `mixed` |  |

## iterate_keys

```lua
utility_functions.iterate_keys(t)
```

Returns an unordered iterator for the keys in a table.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `t` | `table` |  |

| Return type | Description |
| ----------- | ----------- |
| `function` |  |

## round

```lua
utility_functions.round(num)
```

Rounds a number to the nearest whole integer.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `num` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

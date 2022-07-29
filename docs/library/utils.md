# Utility Functions

A library of general Lua utility functions.

## Functions

- [copy_table(t)](#copy_table)
- [table_remove_first(t, value)](#table_remove_first)
- [iterate_keys(t)](#iterate_keys)
- [round(num)](#round)

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

# Utility Functions

A library of general Lua utility functions.

- [copy_table](#copy_table)
- [unpack](#unpack)

## copy_table

```lua
utility_functions.copy_table(t)
```

If a table is passed, returns a copy, otherwise returns the passed value.

| Input | Type | Description |
| --- | --- | --- |
| `t` | `mixed` |  |

| Output type | Description |
| --- | --- |
| `mixed` |  |

## unpack

```lua
utility_functions.unpack(t)
```

Unpacks a table into separate values (for compatibility with Lua <= 5.1).

| Input | Type | Description |
| --- | --- | --- |
| `t` | `table` |  |

| Output type | Description |
| --- | --- |
| `mixed` |  |
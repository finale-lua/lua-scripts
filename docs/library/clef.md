# Clef

A library of general clef utility functions.

## Functions

- [get_cell_clef(measure, staff_number)](#get_cell_clef)
- [get_default_clef(first_measure, last_measure, staff_number)](#get_default_clef)
- [restore_default_clef(first_measure, last_measure, staff_number)](#restore_default_clef)
- [clef_change(clef)](#clef_change)

### get_cell_clef

```lua
clef.get_cell_clef(measure, staff_number)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/clef.lua#L46)

Gets the clef for any cell.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `measure` | `number` | The measure number for the cell |
| `staff_number` | `number` | The staff number for the cell |

| Return type | Description |
| ----------- | ----------- |
| `number` | The clef for the cell |

### get_default_clef

```lua
clef.get_default_clef(first_measure, last_measure, staff_number)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/clef.lua#L72)

Gets the default clef for any staff for a specific region.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `first_measure` | `number` | The first measure of the region |
| `last_measure` | `number` | The last measure of the region |
| `staff_number` | `number` | The staff number for the cell |

| Return type | Description |
| ----------- | ----------- |
| `number` | The default clef for the staff |

### restore_default_clef

```lua
clef.restore_default_clef(first_measure, last_measure, staff_number)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/clef.lua#L93)

Restores the default clef for any staff for a specific region.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `first_measure` | `number` | The first measure of the region |
| `last_measure` | `number` | The last measure of the region |
| `staff_number` | `number` | The staff number for the cell |

### clef_change

```lua
clef.clef_change(clef)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/clef.lua#L118)

Inserts a clef change in the selected region.

@ region FCMusicRegion The region to change.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `clef` | `string` | The clef to change to. |

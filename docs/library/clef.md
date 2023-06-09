# Clef

A library of general clef utility functions.

## Functions

- [get_cell_clef(measure, staff_number)](#get_cell_clef)
- [get_default_clef(first_measure, last_measure, staff_number)](#get_default_clef)
- [set_measure_clef(first_measure, last_measure, staff_number, clef_index)](#set_measure_clef)
- [restore_default_clef(first_measure, last_measure, staff_number)](#restore_default_clef)
- [process_clefs(mid_clefs)](#process_clefs)
- [clef_change(clef)](#clef_change)

### get_cell_clef

```lua
clef.get_cell_clef(measure, staff_number)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/clef.lua#L46)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/clef.lua#L73)

Gets the default clef for any staff for a specific region.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `first_measure` | `number` | The first measure of the region |
| `last_measure` | `number` | The last measure of the region |
| `staff_number` | `number` | The staff number for the cell |

| Return type | Description |
| ----------- | ----------- |
| `number` | The default clef for the staff |

### set_measure_clef

```lua
clef.set_measure_clef(first_measure, last_measure, staff_number, clef_index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/clef.lua#L95)

Sets the clefs of of a range measures.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `first_measure` | `number` | The first measure of the region |
| `last_measure` | `number` | The last measure of the region |
| `staff_number` | `number` | The staff number for the cell |
| `clef_index` | `number` | The clef to set |

### restore_default_clef

```lua
clef.restore_default_clef(first_measure, last_measure, staff_number)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/clef.lua#L125)

Restores the default clef for any staff for a specific region.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `first_measure` | `number` | The first measure of the region |
| `last_measure` | `number` | The last measure of the region |
| `staff_number` | `number` | The staff number for the cell |

### process_clefs

```lua
clef.process_clefs(mid_clefs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/clef.lua#L159)

Processes a table of clef changes and returns them in order, without duplicates.

:(FCCellClefChanges) 

| Input | Type | Description |
| ----- | ---- | ----------- |
| `mid_clefs` | `FCCellClefChanges` |  |

### clef_change

```lua
clef.clef_change(clef)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/clef.lua#L199)

Inserts a clef change in the selected region.

@ region FCMusicRegion The region to change.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `clef` | `string` | The clef to change to. |

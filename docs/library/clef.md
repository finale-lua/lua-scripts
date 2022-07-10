# Clef

A library of general clef utility functions.

## Functions

[get_cell_clef(measure, staff_number)](#get_cell_clef)
[get_default_clef(first_measure, last_measure, staff_number)](#get_default_clef)
[can_change_clef()](#can_change_clef)
[restore_default_clef(first_measure, last_measure, staff_number)](#restore_default_clef)

### get_cell_clef

```lua
clef.get_cell_clef(measure, staff_number)
```

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

Gets the default clef for any staff for a specific region.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `first_measure` | `number` | The first measure of the region |
| `last_measure` | `number` | The last measure of the region |
| `staff_number` | `number` | The staff number for the cell |

| Return type | Description |
| ----------- | ----------- |
| `number` | The default clef for the staff |

### can_change_clef

```lua
clef.can_change_clef()
```

Determine if the current version of the plugin can change clefs.

| Return type | Description |
| ----------- | ----------- |
| `boolean` | Whether or not the plugin can change clefs |

### restore_default_clef

```lua
clef.restore_default_clef(first_measure, last_measure, staff_number)
```

Restores the default clef for any staff for a specific region.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `first_measure` | `number` | The first measure of the region |
| `last_measure` | `number` | The last measure of the region |
| `staff_number` | `number` | The staff number for the cell |

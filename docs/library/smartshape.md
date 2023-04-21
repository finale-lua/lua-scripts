# SmartShape

## Functions

- [add_entry_based_smartshape(start_note, end_note, shape_type)](#add_entry_based_smartshape)
- [delete_entry_based_smartshape(music_region, shape_type)](#delete_entry_based_smartshape)
- [delete_all_slurs()](#delete_all_slurs)

### add_entry_based_smartshape

```lua
smartshape.add_entry_based_smartshape(start_note, end_note, shape_type)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/smartshape.lua#L48)

Creates an entry based SmartShape based on two input notes. If a type is not specified, creates a slur.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `start_note` | `FCNoteEntry` | Starting note for SmartShape. |
| `end_note` | `FCNoteEntry` | Ending note for SmartShape. |
| `shape_type` | `string` | or (number) The type of shape to add, pulled from table, or finale.SMARTSHAPE_TYPES number |

### delete_entry_based_smartshape

```lua
smartshape.delete_entry_based_smartshape(music_region, shape_type)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/smartshape.lua#L126)

Creates an entry based SmartShape based on two input notes. If a type is not specified, creates a slur.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `music_region` | `FCMusicregion` | The region to process. |
| `shape_type` | `string` | or (number) The type of shape to add, pulled from table, or finale.SMARTSHAPE_TYPES number |

### delete_all_slurs

```lua
smartshape.delete_all_slurs()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/smartshape.lua#L155)

Deletes all slurs, dashed slurs, and dashed curves.

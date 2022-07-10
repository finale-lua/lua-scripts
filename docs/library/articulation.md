# Articulation

## Functions

[delete_from_entry_by_char_num(entry, char_num)](#delete_from_entry_by_char_num)
[is_note_side(artic, curr_pos)](#is_note_side)
[calc_main_character_dimensions(artic_def)](#calc_main_character_dimensions)

### delete_from_entry_by_char_num

```lua
articulation.delete_from_entry_by_char_num(entry, char_num)
```

Removes any articulation assignment that has the specified character as its above-character.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` |  |
| `char_num` | `number` | UTF-32 code of character (which is the same as ASCII for ASCII characters) |

### is_note_side

```lua
articulation.is_note_side(artic, curr_pos)
```

Uses `FCArticulation.CalcMetricPos` to determine if the input articulation is on the note-side.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `artic` | `FCArticulation` |  |
| `curr_pos` (optional) | `FCPoint` | current position of articulation that will be calculated if not supplied |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | true if on note-side, otherwise false |

### calc_main_character_dimensions

```lua
articulation.calc_main_character_dimensions(artic_def)
```

Uses `FCTextMetrics:LoadArticulation` to determine the dimensions of the main character

| Input | Type | Description |
| ----- | ---- | ----------- |
| `artic_def` | `FCArticulationDef` |  |

| Return type | Description |
| ----------- | ----------- |
| `number, number` | the width and height of the main articulation character in (possibly fractional) evpus, or 0, 0 if it failed to load metrics |

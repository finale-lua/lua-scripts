# Note Entry

## Functions

- [get_music_region(entry)](#get_music_region)
- [get_evpu_notehead_height(entry)](#get_evpu_notehead_height)
- [get_top_note_position(entry, entry_metrics)](#get_top_note_position)
- [get_bottom_note_position(entry, entry_metrics)](#get_bottom_note_position)
- [calc_widths(entry)](#calc_widths)
- [calc_left_of_all_noteheads(entry)](#calc_left_of_all_noteheads)
- [calc_left_of_primary_notehead(entry)](#calc_left_of_primary_notehead)
- [calc_center_of_all_noteheads(entry)](#calc_center_of_all_noteheads)
- [calc_center_of_primary_notehead(entry)](#calc_center_of_primary_notehead)
- [calc_stem_offset(entry)](#calc_stem_offset)
- [calc_right_of_all_noteheads(entry)](#calc_right_of_all_noteheads)
- [calc_note_at_index(entry, note_index)](#calc_note_at_index)
- [stem_sign(entry)](#stem_sign)
- [duplicate_note(note)](#duplicate_note)
- [delete_note(note)](#delete_note)
- [make_rest(entry)](#make_rest)
- [calc_pitch_string(note)](#calc_pitch_string)
- [calc_spans_number_of_octaves(entry)](#calc_spans_number_of_octaves)
- [add_augmentation_dot(entry)](#add_augmentation_dot)
- [get_next_same_v(entry)](#get_next_same_v)
- [hide_stem(entry)](#hide_stem)
- [rest_offset(entry, offset)](#rest_offset)

### get_music_region

```lua
note_entry.get_music_region(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L14)

Returns an intance of `FCMusicRegion` that corresponds to the metric location of the input note entry.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMusicRegion` |  |

### get_evpu_notehead_height

```lua
note_entry.get_evpu_notehead_height(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L48)

Returns the calculated height of the notehead rectangle.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` | the EVPU height |

### get_top_note_position

```lua
note_entry.get_top_note_position(entry, entry_metrics)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L64)

Returns the vertical page coordinate of the top of the notehead rectangle, not including the stem.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` |  |
| `entry_metrics` (optional) | `FCEntryMetrics` | entry metrics may be supplied by the caller if they are already available |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### get_bottom_note_position

```lua
note_entry.get_bottom_note_position(entry, entry_metrics)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L97)

Returns the vertical page coordinate of the bottom of the notehead rectangle, not including the stem.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` |  |
| `entry_metrics` (optional) | `FCEntryMetrics` | entry metrics may be supplied by the caller if they are already available |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### calc_widths

```lua
note_entry.calc_widths(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L129)

Get the widest left-side notehead width and widest right-side notehead width.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` |  |

| Return type | Description |
| ----------- | ----------- |
| `number, number` | widest left-side notehead width and widest right-side notehead width |

### calc_left_of_all_noteheads

```lua
note_entry.calc_left_of_all_noteheads(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L161)

Calculates the handle offset for an expression with "Left of All Noteheads" horizontal positioning.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to calculate from |

| Return type | Description |
| ----------- | ----------- |
| `number` | offset from left side of primary notehead rectangle |

### calc_left_of_primary_notehead

```lua
note_entry.calc_left_of_primary_notehead(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L177)

Calculates the handle offset for an expression with "Left of Primary Notehead" horizontal positioning.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to calculate from |

| Return type | Description |
| ----------- | ----------- |
| `number` | offset from left side of primary notehead rectangle |

### calc_center_of_all_noteheads

```lua
note_entry.calc_center_of_all_noteheads(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L189)

Calculates the handle offset for an expression with "Center of All Noteheads" horizontal positioning.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to calculate from |

| Return type | Description |
| ----------- | ----------- |
| `number` | offset from left side of primary notehead rectangle |

### calc_center_of_primary_notehead

```lua
note_entry.calc_center_of_primary_notehead(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L206)

Calculates the handle offset for an expression with "Center of Primary Notehead" horizontal positioning.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to calculate from |

| Return type | Description |
| ----------- | ----------- |
| `number` | offset from left side of primary notehead rectangle |

### calc_stem_offset

```lua
note_entry.calc_stem_offset(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L222)

Calculates the offset of the stem from the left edge of the notehead rectangle. Eventually the PDK Framework may be able to provide this instead.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to calculate from |

| Return type | Description |
| ----------- | ----------- |
| `number` | offset of stem from the left edge of the notehead rectangle. |

### calc_right_of_all_noteheads

```lua
note_entry.calc_right_of_all_noteheads(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L238)

Calculates the handle offset for an expression with "Right of All Noteheads" horizontal positioning.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to calculate from |

| Return type | Description |
| ----------- | ----------- |
| `number` | offset from left side of primary notehead rectangle |

### calc_note_at_index

```lua
note_entry.calc_note_at_index(entry, note_index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L256)

This function assumes `for note in each(note_entry)` always iterates in the same direction.
(Knowing how the Finale PDK works, it probably iterates from bottom to top note.)
Currently the PDK Framework does not seem to offer a better option.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` |  |
| `note_index` | `number` | the zero-based index |

### stem_sign

```lua
note_entry.stem_sign(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L276)

This is useful for many x,y positioning fields in Finale that mirror +/-
based on stem direction.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` | 1 if upstem, -1 otherwise |

### duplicate_note

```lua
note_entry.duplicate_note(note)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L289)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCNote \\| nil` | reference to added FCNote or `nil` if not success |

### delete_note

```lua
note_entry.delete_note(note)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L308)

Removes the specified FCNote from its associated FCNoteEntry.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | true if success |

### make_rest

```lua
note_entry.make_rest(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L340)

Deletes all notes and turns the note_entry into a floating rest. This function also
deletes any attached entry details such as articulations and special tools edits.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | success |

### calc_pitch_string

```lua
note_entry.calc_pitch_string(note)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L363)

Calculates the pitch string of a note for display purposes.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` | display string for note |

### calc_spans_number_of_octaves

```lua
note_entry.calc_spans_number_of_octaves(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L379)

Calculates the numer of octaves spanned by a chord (considering only staff positions, not accidentals).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to calculate from |

| Return type | Description |
| ----------- | ----------- |
| `number` | of octaves spanned |

### add_augmentation_dot

```lua
note_entry.add_augmentation_dot(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L394)

Adds an augentation dot to the entry. This works even if the entry already has one or more augmentation dots.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to which to add the augmentation dot |

### get_next_same_v

```lua
note_entry.get_next_same_v(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L409)

Returns the next entry in the same V1 or V2 as the input entry.
If the input entry is V2, only the current V2 launch is searched.
If the input entry is V1, only the current measure and layer is searched.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to process |

| Return type | Description |
| ----------- | ----------- |
| `FCNoteEntry` | the next entry or `nil` in none |

### hide_stem

```lua
note_entry.hide_stem(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L432)

Hides the stem of the entry by replacing it with Shape 0.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to process |

### rest_offset

```lua
note_entry.rest_offset(entry, offset)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/note_entry.lua#L454)

Confirms the entry is a rest then offsets it from the staff rest "center" position. 

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | the entry to process |
| `offset` | `number` | offset in half spaces |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | true if success |

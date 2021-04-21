# Articulation

- [delete_from_entry_by_char_num](#delete_from_entry_by_char_num)
- [is_note_side](#is_note_side)

## delete_from_entry_by_char_num

```lua
articulation.delete_from_entry_by_char_num(entry, char_num)
```

Removes any articulation assignment that has the specified character as its above-character.

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` |  |
| `char_num` | `number` | UTF-32 code of character (which is the same as ASCII for ASCII characters) |

## is_note_side

```lua
articulation.is_note_side(artic, curr_pos)
```

Uses metrics to determine if the input articulation is on the note-side.

| Input | Type | Description |
| --- | --- | --- |
| `artic` | `FCArticulation` |  |
| `curr_pos` (optional) | `FCPoint` | will be calculated if not supplied |

| Output type | Description |
| --- | --- |
| `boolean` | true if on note-side, otherwise false |
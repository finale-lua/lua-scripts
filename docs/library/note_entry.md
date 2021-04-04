# Note Entry

- [get_music_region](#get_music_region)
- [get_evpu_notehead_height](#get_evpu_notehead_height)
- [get_top_note_position](#get_top_note_position)
- [get_bottom_note_position](#get_bottom_note_position)
- [calc_widths](#calc_widths)
- [calc_note_at_index](#calc_note_at_index)
- [stem_sign](#stem_sign)
- [duplicate_note](#duplicate_note)
- [calc_spans_number_of_octaves](#calc_spans_number_of_octaves)

## get_music_region

```lua
note_entry.get_music_region(entry)
```

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` |  |

| Output type | Description |
| --- | --- |
| `FCMusicRegion` |  |

## get_evpu_notehead_height

```lua
note_entry.get_evpu_notehead_height(entry)
```

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` |  |

| Output type | Description |
| --- | --- |
| `number` | the EVPU height |

## get_top_note_position

```lua
note_entry.get_top_note_position(entry, entry_metrics)
```

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` |  |
| `entry_metrics` (optional) | `FCEntryMetrics` |  |

## get_bottom_note_position

```lua
note_entry.get_bottom_note_position(entry, entry_metrics)
```

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` |  |
| `entry_metrics` (optional) | `FCEntryMetrics` |  |

## calc_widths

```lua
note_entry.calc_widths(entry)
```

Get the widest left-side notehead width and widest right-side notehead width.

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` |  |

| Output type | Description |
| --- | --- |
| `number, number` | widest left-side notehead width and widest right-side notehead width |

## calc_note_at_index

```lua
note_entry.calc_note_at_index(entry, note_index)
```

this function assumes for note in each(note_entry) always iterates in the same direction
(Knowing how the Finale PDK works, it probably iterates from bottom to top note.)
currently the PDK Framework does not seem to offer a better option

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` |  |
| `note_index` | `number` | the zero-based index |

## stem_sign

```lua
note_entry.stem_sign(entry)
```

This is useful for many x,y positioning fields in Finale that mirror +/-
based on stem direction.

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` |  |

| Output type | Description |
| --- | --- |
| `number` | 1 if upstem, -1 otherwise |

## duplicate_note

```lua
note_entry.duplicate_note(note)
```

| Input | Type | Description |
| --- | --- | --- |
| `note` | `FCNote` |  |

| Output type | Description |
| --- | --- |
| `FCNote | nil` | reference to added FCNote or nil if not success |

## calc_spans_number_of_octaves

```lua
note_entry.calc_spans_number_of_octaves(entry)
```

Calculates the numer of octaves spanned by a chord (considering only staff positions, not accidentals)

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` | the entry to calculate from |

| Output type | Description |
| --- | --- |
| `number` | of octaves spanned |
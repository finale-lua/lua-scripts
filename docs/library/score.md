# Score

- [delete_all_staves](#delete_all_staves)
- [set_show_staff_time_signature](#set_show_staff_time_signature)
- [set_staff_transposition](#set_staff_transposition)
- [set_staff_allow_hiding](#set_staff_allow_hiding)
- [set_staff_keyless](#set_staff_keyless)
- [add_space_above_staff](#add_space_above_staff)
- [set_staff_full_name](#set_staff_full_name)
- [set_staff_short_name](#set_staff_short_name)
- [create_staff](#create_staff)
- [create_staff_spaced](#create_staff_spaced)
- [create_staff_percussion](#create_staff_percussion)
- [create_group](#create_group)
- [create_group_primary](#create_group_primary)
- [create_group_secondary](#create_group_secondary)
- [set_global_system_scaling](#set_global_system_scaling)
- [set_global_system_scaling](#set_global_system_scaling)
- [use_large_time_signatures](#use_large_time_signatures)
- [use_large_measure_numbers](#use_large_measure_numbers)
- [set_minimum_measure_width](#set_minimum_measure_width)

## delete_all_staves

```lua
score.delete_all_staves()
```

Deletes all staves in the current document.

## set_show_staff_time_signature

```lua
score.set_show_staff_time_signature(staff_id, show_time_signature)
```

Sets whether or not to show the time signature on the staff.

| Input | Type | Description |
| --- | --- | --- |
| `staff_id` | `number` | the staff_id for the staff |
| `show_time_signature` (optional) | `boolean` | whether or not to show the time signature, true if not specified |

| Output type | Description |
| --- | --- |
| `number` | the staff_id for the staff |

## set_staff_transposition

```lua
score.set_staff_transposition(staff_id, key, interval, clef)
```

Sets the transposition for a staff. Used for instruments that are not concert pitch (e.g., Bb Clarinet or F Horn)

| Input | Type | Description |
| --- | --- | --- |
| `staff_id` | `number` | the staff_id for the staff |
| `key` | `number` | the key signature to set following the circle of fifths (C is 0, F is -1, G is 1) |
| `interval` | `number` | the interval number of steps to transpose the notes by |
| `clef` (optional) | `string` | the clef to set, "treble", "alto", "tenor", or "bass" |

| Output type | Description |
| --- | --- |
| `number` | the staff_id for the staff |

## set_staff_allow_hiding

```lua
score.set_staff_allow_hiding(staff_id, allow_hiding)
```

Sets whether the staff is allowed to hide when it is empty.

| Input | Type | Description |
| --- | --- | --- |
| `staff_id` | `number` | the staff_id for the staff |
| `allow_hiding` (optional) | `boolean` | whether or not to allow the staff to hide, true if not specified |

| Output type | Description |
| --- | --- |
| `number` | the staff_id for the staff |

## set_staff_keyless

```lua
score.set_staff_keyless(staff_id, is_keyless)
```

Sets whether or not the staff is keyless.

| Input | Type | Description |
| --- | --- | --- |
| `staff_id` | `number` | the staff_id for the staff |
| `is_keyless` (optional) | `boolean` | whether the staff is keyless, true if not specified |

| Output type | Description |
| --- | --- |
| `number` | the staff_id for the staff |

## add_space_above_staff

```lua
score.add_space_above_staff(staff_id)
```

This is the equivalent of "Add Vertical Space" in the Setup Wizard. It adds space above the staff as well as adds the staff to Staff List 1, which allows it to show tempo markings.

| Input | Type | Description |
| --- | --- | --- |
| `staff_id` | `number` | the staff_id for the staff |

| Output type | Description |
| --- | --- |
| `number` | the staff_id for the staff |

## set_staff_full_name

```lua
score.set_staff_full_name(staff, full_name, double)
```

Sets the full name for the staff.

If two instruments are on the same staff, this will also add the related numbers. For instance, if horn one and 2 are on the same staff, this will show Horn 1/2. `double` sets the first number. In this example, `double` should be `1` to show Horn 1/2. If the staff is for horn three and four, `double` should be `3`.

| Input | Type | Description |
| --- | --- | --- |
| `staff` | `FCStaff` | the staff |
| `full_name` | `string` | the full name to set |
| `double` (optional) | `number` | the number of the first instrument if two instruments share the staff |

## set_staff_short_name

```lua
score.set_staff_short_name(staff, short_name, double)
```

Sets the abbreviated name for the staff.

If two instruments are on the same staff, this will also add the related numbers. For instance, if horn one and 2 are on the same staff, this will show Horn 1/2. `double` sets the first number. In this example, `double` should be `1` to show Horn 1/2. If the staff is for horn three and four, `double` should be `3`.

| Input | Type | Description |
| --- | --- | --- |
| `staff` | `FCStaff` | the staff |
| `short_name` | `string` | the abbreviated name to set |
| `double` (optional) | `number` | the number of the first instrument if two instruments share the staff |

## create_staff

```lua
score.create_staff(full_name, short_name, type, clef, double)
```

Creates a staff at the end of the score.

| Input | Type | Description |
| --- | --- | --- |
| `full_name` | `string` | the abbreviated name |
| `short_name` | `string` | the abbreviated name |
| `type` | `string` | the `__FCStaffBase` type (e.g., finale.FFUUID_TRUMPETC) |
| `clef` | `string` | the clef for the staff (e.g., "treble", "bass", "tenor") |
| `double` (optional) | `number` | the number of the first instrument if two instruments share the staff |

| Output type | Description |
| --- | --- |
| `number` | the staff_id for the new staff |

## create_staff_spaced

```lua
score.create_staff_spaced(full_name, short_name, type, clef, double)
```

Creates a staff at the end of the score with a space above it. This is equivalent to using `score.create_staff` then `score.add_space_above_staff`.

| Input | Type | Description |
| --- | --- | --- |
| `full_name` | `string` | the abbreviated name |
| `short_name` | `string` | the abbreviated name |
| `type` | `string` | the `__FCStaffBase` type (e.g., finale.FFUUID_TRUMPETC) |
| `clef` | `string` | the clef for the staff (e.g., "treble", "bass", "tenor") |
| `double` (optional) | `number` | the number of the first instrument if two instruments share the staff |

| Output type | Description |
| --- | --- |
| `number` | the staff_id for the new staff |

## create_staff_percussion

```lua
score.create_staff_percussion(full_name, short_name, type, clef)
```

Creates a percussion staff at the end of the score.

| Input | Type | Description |
| --- | --- | --- |
| `full_name` | `string` | the abbreviated name |
| `short_name` | `string` | the abbreviated name |

| Output type | Description |
| --- | --- |
| `number` | the staff_id for the new staff |

## create_group

```lua
score.create_group(start_staff, end_staff, brace_name, has_barline, level, full_name, short_name)
```

Creates a percussion staff at the end of the score.

| Input | Type | Description |
| --- | --- | --- |
| `start_staff` | `number` | the staff_id for the first staff |
| `end_staff` | `number` | the staff_id for the last staff |
| `brace_name` | `string` | the name for the brace (e.g., "none", "plain", "piano") |
| `has_barline` | `boolean` | whether or not barlines should continue through all staves in the group |
| `level` | `number` | the indentation level for the group bracket |
| `full_name` (optional) | `string` | the full name for the group |
| `short_name` (optional) | `string` | the abbreviated name for the group |

## create_group_primary

```lua
score.create_group_primary(start_staff, end_staff, full_name, short_name)
```

Creates a primary group with the "curved_chorus" bracket.

| Input | Type | Description |
| --- | --- | --- |
| `start_staff` | `number` | the staff_id for the first staff |
| `end_staff` | `number` | the staff_id for the last staff |
| `full_name` (optional) | `string` | the full name for the group |
| `short_name` (optional) | `string` | the abbreviated name for the group |

## create_group_secondary

```lua
score.create_group_secondary(start_staff, end_staff, full_name, short_name)
```

Creates a primary group with the "desk" bracket.

| Input | Type | Description |
| --- | --- | --- |
| `start_staff` | `number` | the staff_id for the first staff |
| `end_staff` | `number` | the staff_id for the last staff |
| `full_name` (optional) | `string` | the full name for the group |
| `short_name` (optional) | `string` | the abbreviated name for the group |

## set_global_system_scaling

```lua
score.set_global_system_scaling(scaling)
```

Sets the system scaling for every system in the score.

| Input | Type | Description |
| --- | --- | --- |
| `scaling` | `number` | the scaling factor |

## set_global_system_scaling

```lua
score.set_global_system_scaling(scaling)
```

Sets the system scaling for a specific system in the score.

| Input | Type | Description |
| --- | --- | --- |
| `system_number` | `number` | the system number to set the scaling for |
| `scaling` | `number` | the scaling factor |

## use_large_time_signatures

```lua
score.use_large_time_signatures()
```

Creates large time signatures in the score.

## use_large_measure_numbers

```lua
score.use_large_measure_numbers(distance)
```

Adds large measure numbers below every measure in the score.

| Input | Type | Description |
| --- | --- | --- |
| `distance` | `string` | the distance between the bottom staff and the measure numbers (e.g., "12s" for 12 spaces) |

## set_minimum_measure_width

```lua
score.set_minimum_measure_width(width)
```

Sets the minimum measure width.

| Input | Type | Description |
| --- | --- | --- |
| `width` | `string` | the minimum measure width (e.g., "24s" for 24 spaces) |
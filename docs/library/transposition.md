# Transposition

A collection of helpful JW Lua transposition scripts.

This library allows configuration of custom key signatures by means
of a configuration file called "custom_key_sig.config.txt" in the
"script_settings" subdirectory. However, RGP Lua (starting with version 0.58)
can read the correct custom key signature information directly from
Finale. Therefore, when you run this script with RGP Lua 0.58+, the configuration file
is ignored.

## Functions

- [diatonic_transpose(note, interval)](#diatonic_transpose)
- [change_octave(note, number_of_octaves)](#change_octave)
- [enharmonic_transpose(note, direction, ignore_error)](#enharmonic_transpose)
- [enharmonic_transpose_default(note, direction)](#enharmonic_transpose_default)
- [simplify_spelling(note, min_abs_alteration)](#simplify_spelling)
- [chromatic_transpose(note, interval, alteration, simplify)](#chromatic_transpose)
- [stepwise_transpose(note, number_of_steps)](#stepwise_transpose)
- [chromatic_major_third_down(note)](#chromatic_major_third_down)
- [chromatic_perfect_fourth_up(note)](#chromatic_perfect_fourth_up)
- [chromatic_perfect_fifth_down(note)](#chromatic_perfect_fifth_down)
- [each_to_transpose(entry, preserve_originals)](#each_to_transpose)
- [entry_diatonic_transpose(entry)](#entry_diatonic_transpose)
- [entry_chromatic_transpose(entry, interval, alteration, simplify, plus_octaves, preserve_originals)](#entry_chromatic_transpose)
- [entry_stepwise_transpose(entry, number_of_steps, preserve_originals)](#entry_stepwise_transpose)
- [entry_enharmonic_transpose(entry, direction)](#entry_enharmonic_transpose)

### diatonic_transpose

```lua
transposition.diatonic_transpose(note, interval)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L133)

Transpose the note diatonically by the given interval displacement.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |
| `interval` | `number` | 0 = unison, 1 = up a diatonic second, -2 = down a diatonic third, etc. |

### change_octave

```lua
transposition.change_octave(note, number_of_octaves)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L149)

Transpose the note by the given number of octaves.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |
| `number_of_octaves` | `number` | 0 = no change, 1 = up an octave, -2 = down 2 octaves, etc. |

### enharmonic_transpose

```lua
transposition.enharmonic_transpose(note, direction, ignore_error)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L172)

Transpose the note enharmonically in the given direction. In some microtone systems this yields a different result than transposing by a diminished 2nd.
Failure occurs if the note's `RaiseLower` value exceeds an absolute value of 7. This is a hard-coded limit in Finale.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |
| `direction` | `number` | positive = up, negative = down (normally 1 or -1, but any positive or negative numbers work) |
| `ignore_error` (optional) | `boolean` | default false. If true, always return success. External callers should omit this parameter. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | success or failure |

### enharmonic_transpose_default

```lua
transposition.enharmonic_transpose_default(note, direction)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L206)

Transpose the note enharmonically in Finale's default direction. This function should be used when performing an
unlinked enharmonic flip in a part. Only a default enharmonic flip unlinks. Any other enharmonic flip appears in the
score as well. This code is based on observed Finale behavior in Finale 27.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |
| `direction` | `number` | positive = up, negative = down (normally 1 or -1, but any positive or negative numbers work) |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | success or failure |

### simplify_spelling

```lua
transposition.simplify_spelling(note, min_abs_alteration)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L248)

Simplifies the spelling of a note. See FCTransposer::SimplifySpelling at https://pdk.finalelua.com/ for more information
about why it can fail. External calls to this function should never fail, provided they omit the `min_abs_alteration` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note to transpose |
| `min_abs_alteration` (optional) | `number` | a value used internally. External calls should omit this parameter. |

### chromatic_transpose

```lua
transposition.chromatic_transpose(note, interval, alteration, simplify)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L291)

Transposes a note chromatically by the input chromatic interval. Supports custom key signatures
and microtone systems by means of a `custom_key_sig.config.txt` file. In Finale, chromatic intervals
are defined by a diatonic displacement (0 = unison, 1 = second, 2 = third, etc.) and a chromatic alteration.
Major and perfect intervals have a chromatic alteration of 0. So for example, `{2, -1}` is up a minor third, `{3, 0}`
is up a perfect fourth, `{5, 1}` is up an augmented sixth, etc. Reversing the signs of both values in the pair
allows for downwards transposition.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note to transpose |
| `interval` | `number` | the diatonic displacement (negative for transposing down) |
| `alteration` | `number` | the chromatic alteration that defines the chromatic interval (reverse sign for transposing down) |
| `simplify` (optional) | `boolean` | if present and true causes the spelling of the transposed note to be simplified |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | success or failure (see `enharmonic_transpose` for what causes failure) |

### stepwise_transpose

```lua
transposition.stepwise_transpose(note, number_of_steps)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L333)

Transposes the note by the input number of steps and simplifies the spelling.

For predefined key signatures, each step is a half-step.
For microtone systems defined with custom key signatures, the number of steps is determined by the key signature.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |
| `number_of_steps` | `number` | positive = up, negative = down |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | success or failure (see `enharmonic_transpose` for what causes failure) |

### chromatic_major_third_down

```lua
transposition.chromatic_major_third_down(note)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L355)

Transpose the note down by a major third.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |

### chromatic_perfect_fourth_up

```lua
transposition.chromatic_perfect_fourth_up(note)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L366)

Transpose the note up by a perfect fourth.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |

### chromatic_perfect_fifth_down

```lua
transposition.chromatic_perfect_fifth_down(note)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L377)

Transpose the note down by a perfect fifth.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |

### each_to_transpose

```lua
transposition.each_to_transpose(entry, preserve_originals)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L389)

Feeds a for loop with notes to transpose. Nothing happens if the entry is a rest.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | input and modified output |
| `preserve_originals` (optional) | `boolean` | if true, creates new notes to be transposed rather than feeding the original notes (defaults to false) |

### entry_diatonic_transpose

```lua
transposition.entry_diatonic_transpose(entry)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L418)

Transpose all the notes in an entry diatonically by the specified interval

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | input and modified output |

### entry_chromatic_transpose

```lua
transposition.entry_chromatic_transpose(entry, interval, alteration, simplify, plus_octaves, preserve_originals)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L439)

Transpose all the notes in an entry diatonically by the specified interval. If any note in the entry
fails to transpose, the return value is false. However, only the failed notes are reverted to their
original state. (See `enharmonic_transpose` for what causes failure.)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | input and modified output |
| `interval` | `number` | the diatonic displacement (negative for transposing down) |
| `alteration` | `number` | the chromatic alteration that defines the chromatic interval (reverse sign for transposing down) |
| `simplify` (optional) | `boolean` | if present and true causes the spelling of the transposed note to be simplified |
| `plus_octaves` (optional) | `number` | if present and non-zero, specifies the number of octaves to further transpose the result |
| `preserve_originals` (optional) | `boolean` | if present and true create duplicates of the original notes and transposes them, |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | success or failure (see `enharmonic_transpose` for what causes failure) |

### entry_stepwise_transpose

```lua
transposition.entry_stepwise_transpose(entry, number_of_steps, preserve_originals)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L466)

Transposes the note by the input number of steps and simplifies the spelling. If any note in the entry
fails to transpose, the return value is false. However, only the failed notes are reverted to their
original state. (See `enharmonic_transpose` for what causes failure.)

For predefined key signatures, each step is a half-step.
For microtone systems defined with custom key signatures, the number of steps is determined by the key signature.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | input and modified output |
| `number_of_steps` | `number` | positive = up, negative = down |
| `preserve_originals` (optional) | `boolean` | if present and true create duplicates of the original notes and transposes them, |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | success or failure |

### entry_enharmonic_transpose

```lua
transposition.entry_enharmonic_transpose(entry, direction)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/transposition.lua#L487)

Transpose all the notes enharmonically in the given direction. In some microtone systems this yields a different result than transposing by a diminished 2nd.
Failure occurs if any note's `RaiseLower` value exceeds an absolute value of 7. This is a hard-coded limit in Finale.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `entry` | `FCNoteEntry` | input and modified output |
| `direction` | `number` | positive = up, negative = down (normally 1 or -1, but any positive or negative numbers work) |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | success or failure |

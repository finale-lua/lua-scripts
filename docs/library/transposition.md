# Transposition

A collection of helpful JW Lua transposition scripts.

This library allows configuration of custom key signatures by means
of a configuration file called "custom_key_sig.config.txt" in the
"script_settings" subdirectory. However, RGP Lua (starting with version 0.58)
can read the correct custom key signature information directly from
Finale. Therefore, when you run this script with RGP Lua 0.58+, the configuration file
is ignored.

- [diatonic_transpose](#diatonic_transpose)
- [change_octave](#change_octave)
- [enharmonic_transpose](#enharmonic_transpose)
- [chromatic_transpose](#chromatic_transpose)
- [stepwise_transpose](#stepwise_transpose)
- [chromatic_major_third_down](#chromatic_major_third_down)
- [chromatic_perfect_fourth_up](#chromatic_perfect_fourth_up)
- [chromatic_perfect_fifth_down](#chromatic_perfect_fifth_down)

## diatonic_transpose

```lua
transposition.diatonic_transpose(note, interval)
```

Transpose the note diatonically by the given interval displacement.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |
| `interval` | `number` | 0 = unison, 1 = up a diatonic second, -2 = down a diatonic third, etc. |

## change_octave

```lua
transposition.change_octave(note, number_of_octaves)
```

Transpose the note by the given number of octaves.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |
| `number_of_octaves` | `number` | 0 = no change, 1 = up an octave, -2 = down 2 octaves, etc. |

## enharmonic_transpose

```lua
transposition.enharmonic_transpose(note, direction, ignore_error)
```

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

## chromatic_transpose

```lua
transposition.chromatic_transpose(note, interval, alteration, simplify)
```

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

## stepwise_transpose

```lua
transposition.stepwise_transpose(note, number_of_steps)
```

Transposes the note by the input number of steps and simplifies the spelling.
For predefined key signatures, each step is a half-step.
For microtone systems defined with custom key signatures and matching options in the `custom_key_sig.config.txt` file,
each step is the smallest division of the octave defined by the custom key signature.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |
| `number_of_steps` | `number` | positive = up, negative = down |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | success or failure (see `enharmonic_transpose` for what causes failure) |

## chromatic_major_third_down

```lua
transposition.chromatic_major_third_down(note)
```

Transpose the note down by a major third.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |

## chromatic_perfect_fourth_up

```lua
transposition.chromatic_perfect_fourth_up(note)
```

Transpose the note up by a perfect fourth.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |

## chromatic_perfect_fifth_down

```lua
transposition.chromatic_perfect_fifth_down(note)
```

Transpose the note down by a perfect fifth.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | input and modified output |

# Tie

This library encapsulates Finale's behavior for initializing FCTieMod endpoints,
as well as providing other useful information about ties.

## Functions

- [calc_tied_to(note)](#calc_tied_to)
- [calc_tied_from(note)](#calc_tied_from)
- [calc_tie_span(note, for_tied_to, tie_must_exist)](#calc_tie_span)
- [calc_default_direction(note, for_tieend, tie_prefs)](#calc_default_direction)
- [calc_direction(note, tie_mod, tie_prefs)](#calc_direction)
- [calc_connection_code(note, placement, direction, for_endpoint, for_tieend, for_pageview, tie_prefs)](#calc_connection_code)
- [calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)](#calc_placement)
- [activate_endpoints(note, tie_mod, for_pageview, tie_prefs)](#activate_endpoints)
- [calc_contour_index(note, tie_mod, for_pageview, direction, tie_prefs)](#calc_contour_index)
- [activate_contour(note, tie_mod, for_pageview, tie_prefs)](#activate_contour)

### calc_tied_to

```lua
tie.calc_tied_to(note)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L41)

Calculates the note that the input note could be (or is) tied to.
For this function to work correctly across barlines, the input note
must be from an instance of FCNoteEntryLayer that contains both the
input note and the tied-to note.

@ [tie_must_exist] if true, only returns a note if the tie already exists.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to return the tied-to note |

| Return type | Description |
| ----------- | ----------- |
| `FCNote` | Returns the tied-to note or nil if none |

### calc_tied_from

```lua
tie.calc_tied_from(note)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L81)

Calculates the note that the input note could be (or is) tied from.
For this function to work correctly across barlines, the input note
must be from an instance of FCNoteEntryLayer that contains both the
input note and the tied-from note.

@ [tie_must_exist] if true, only returns a note if the tie already exists.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to return the tied-from note |

| Return type | Description |
| ----------- | ----------- |
| `FCNote` | Returns the tied-from note or nil if none |

### calc_tie_span

```lua
tie.calc_tie_span(note, for_tied_to, tie_must_exist)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L122)

Calculates the (potential) start and end notes for a tie, given an input note. The
input note can be from anywhere, including from the `eachentry()` iterator functions.
The function returns 3 values:

- A FCNoteLayerEntry containing both the start and and notes (if they exist).
You must maintain the lifetime of this variable as long as you are referencing either
of the other two values.
- The potential or actual start note of the tie (taken from the FCNoteLayerEntry above).
- The potential or actual end note of the tie (taken from the FCNoteLayerEntry above).

Be very careful about modifying the return values from this function. If you do it within
an iterator loop from `eachentry()` or `eachentrysaved()` you could end up overwriting your changes
with stale data from the iterator loop. You may discover that this function is more useful
for gathering information than for modifying the values it returns.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to calculated the tie span |
| `for_tied_to` (optional) | `boolean` | if true, searches for a note tying to the input note. Otherwise, searches for a note tying from the input note. |
| `tie_must_exist` (optional) | `boolean` | if true, only returns notes for ties that already exist. |

| Return type | Description |
| ----------- | ----------- |
| `FCNoteLayerEntry` | A new FCNoteEntryLayer instance that contains both the following two return values. |
| `FCNote` | The start note of the tie. |
| `FCNote` | The end note of the tie. |

### calc_default_direction

```lua
tie.calc_default_direction(note, for_tieend, tie_prefs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L155)

Calculates the default direction of a tie based on context and FCTiePrefs but ignoring multi-voice
and multi-layer overrides. It also does not take into account the direction being overridden in
FCTieMods. Use tie.calc_direction to calculate the actual current tie direction.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to return the tie direction. |
| `for_tieend` | `boolean` | specifies that this request is for a tie_end. |
| `tie_prefs` (optional) | `FCTiePrefs` | use these tie prefs if supplied |

| Return type | Description |
| ----------- | ----------- |
| `number` | Returns either TIEMODDIR_UNDER or TIEMODDIR_OVER. If the input note has no applicable tie, it returns 0. |

### calc_direction

```lua
tie.calc_direction(note, tie_mod, tie_prefs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L342)

Calculates the current direction of a tie based on context and FCTiePrefs, taking into account multi-voice
and multi-layer overrides. It also takes into account if the direction has been overridden in
FCTieMods.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to return the tie direction. |
| `tie_mod` | `FCTieMod` | the tie mods for the note, if any. |
| `tie_prefs` (optional) | `FCTiePrefs` | use these tie prefs if supplied |

| Return type | Description |
| ----------- | ----------- |
| `number` | Returns either TIEMODDIR_UNDER or TIEMODDIR_OVER. If the input note has no applicable tie, it returns 0. |

### calc_connection_code

```lua
tie.calc_connection_code(note, placement, direction, for_endpoint, for_tieend, for_pageview, tie_prefs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L410)

Calculates the correct connection code for activating a Tie Placement Start Point or End Point
in FCTieMod.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to return the code |
| `placement` | `number` | one of the TIEPLACEMENT_INDEXES values |
| `direction` | `number` | one of the TIEMOD_DIRECTION values |
| `for_endpoint` | `boolean` | if true, calculate the end point code, otherwise the start point code |
| `for_tieend` | `boolean` | if true, calculate the code for a tie end |
| `for_pageview` | `boolean` | if true, calculate the code for page view, otherwise for scroll/studio view |
| `tie_prefs` (optional) | `FCTiePrefs` | use these tie prefs if supplied |

| Return type | Description |
| ----------- | ----------- |
| `number` | Returns one of TIEMOD_CONNECTION_CODES. If the input note has no applicable tie, it returns TIEMODCNCT_NONE. |

### calc_placement

```lua
tie.calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L518)

Calculates the current placement of a tie based on context and FCTiePrefs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to return the tie direction. |
| `tie_mod` | `FCTieMod` | the tie mods for the note, if any. |
| `for_pageview` | `bool` | true if calculating for Page View, false for Scroll/Studio View |
| `direction` | `number` | one of the TIEMOD_DIRECTION values or nil (if you don't know it yet) |
| `tie_prefs` (optional) | `FCTiePrefs` | use these tie prefs if supplied |

| Return type | Description |
| ----------- | ----------- |
| `number` | TIEPLACEMENT_INDEXES value for start point |
| `number` | TIEPLACEMENT_INDEXES value for end point |

### activate_endpoints

```lua
tie.activate_endpoints(note, tie_mod, for_pageview, tie_prefs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L641)

Activates the placement endpoints of the input tie_mod and initializes them with their
default values. If an endpoint is already activated, that endpoint is not touched.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to return the tie direction. |
| `tie_mod` | `FCTieMod` | the tie mods for the note, if any. |
| `for_pageview` | `bool` | true if calculating for Page View, false for Scroll/Studio View |
| `tie_prefs` (optional) | `FCTiePrefs` | use these tie prefs if supplied |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | returns true if anything changed |

### calc_contour_index

```lua
tie.calc_contour_index(note, tie_mod, for_pageview, direction, tie_prefs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L755)

Calculates the current contour index of a tie based on context and FCTiePrefs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to return the tie direction. |
| `tie_mod` | `FCTieMod` | the tie mods for the note, if any. |
| `for_pageview` | `bool` | true if calculating for Page View, false for Scroll/Studio View |
| `direction` | `number` | one of the TIEMOD_DIRECTION values or nil (if you don't know it yet) |
| `tie_prefs` (optional) | `FCTiePrefs` | use these tie prefs if supplied |

| Return type | Description |
| ----------- | ----------- |
| `number` | CONTOUR_INDEXES value for tie |
| `number` | calculated length of tie in EVPU |

### activate_contour

```lua
tie.activate_contour(note, tie_mod, for_pageview, tie_prefs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/tie.lua#L821)

Activates the contour fields of the input tie_mod and initializes them with their
default values. If the contour fields are already activated, nothing is changed. Note
that for interpolated Medium span types, the interpolated values may not be identical
to those calculated by Finale, but they should be close enough to make no appreciable
visible difference.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` | the note for which to return the tie direction. |
| `tie_mod` | `FCTieMod` | the tie mods for the note, if any. |
| `for_pageview` | `bool` | true if calculating for Page View, false for Scroll/Studio View |
| `tie_prefs` (optional) | `FCTiePrefs` | use these tie prefs if supplied |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | returns true if anything changed |

# Tie

This library encapsulates Finale's behavior for initializing FCTieMod endpoints,
as well as providing other useful information about ties.

- [calc_default_direction](#calc_default_direction)
- [calc_direction](#calc_direction)
- [calc_connection_code](#calc_connection_code)
- [calc_placement](#calc_placement)
- [activate_endpoints](#activate_endpoints)
- [calc_contour_index](#calc_contour_index)
- [activate_contour](#activate_contour)

## calc_default_direction

```lua
tie.calc_default_direction(note, for_tieend, tie_prefs)
```


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

## calc_direction

```lua
tie.calc_direction(note, tie_mod, tie_prefs)
```


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

## calc_connection_code

```lua
tie.calc_connection_code(note, placement, direction, for_endpoint, for_tieend, for_pageview, tie_prefs)
```


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

## calc_placement

```lua
tie.calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)
```


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
| `number` | TIEPLACEMENT_INDEXES value for end point |

## activate_endpoints

```lua
tie.activate_endpoints(note, tie_mod, for_pageview, tie_prefs)
```


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

## calc_contour_index

```lua
tie.calc_contour_index(note, tie_mod, for_pageview, direction, tie_prefs)
```


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
| `number` | calculated length of tie in EVPU |

## activate_contour

```lua
tie.activate_contour(note, tie_mod, for_pageview, tie_prefs)
```


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

# measurement

## Functions

- [convert_to_EVPUs(text)](#convert_to_evpus)
- [get_unit_name(unit)](#get_unit_name)
- [get_unit_suffix(unit)](#get_unit_suffix)
- [get_unit_abbreviation(unit)](#get_unit_abbreviation)
- [is_valid_unit(unit)](#is_valid_unit)
- [get_real_default_unit()](#get_real_default_unit)

### convert_to_EVPUs

```lua
measurement.convert_to_EVPUs(text)
```

Converts the specified string into EVPUs. Like text boxes in Finale, this supports
the usage of units at the end of the string. The following are a few examples:

- `12s` => 288 (12 spaces is 288 EVPUs)
- `8.5i` => 2448 (8.5 inches is 2448 EVPUs)
- `10cm` => 1133 (10 centimeters is 1133 EVPUs)
- `10mm` => 113 (10 millimeters is 113 EVPUs)
- `1pt` => 4 (1 point is 4 EVPUs)
- `2.5p` => 120 (2.5 picas is 120 EVPUs)

Read the [Finale User Manual](https://usermanuals.finalemusic.com/FinaleMac/Content/Finale/def-equivalents.htm#overriding-global-measurement-units)
for more details about measurement units in Finale.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `text` | `string` | the string to convert |

| Return type | Description |
| ----------- | ----------- |
| `number` | the converted number of EVPUs |

### get_unit_name

```lua
measurement.get_unit_name(unit)
```

Returns the name of a measurement unit.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `unit` | `number` | A finale MEASUREMENTUNIT constant. |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### get_unit_suffix

```lua
measurement.get_unit_suffix(unit)
```

Returns the measurement unit's suffix. Suffixes can be used to force the text value (eg in `FCString` or `FCCtrlEdit`) to be treated as being from a particular measurement unit
Note that although this method returns a "p" for Picas, the fractional part goes after the "p" (eg `1p6`), so in practice it may be that no suffix is needed.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `unit` | `number` | A finale MEASUREMENTUNIT constant. |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### get_unit_abbreviation

```lua
measurement.get_unit_abbreviation(unit)
```

Returns measurement unit abbreviations that are more human-readable than Finale's internal suffixes.
Abbreviations are also compatible with the internal ones because Finale discards everything after the first letter that isn't part of the suffix.

For example:
```lua
local str_internal = finale.FCString()
str.LuaString = "2i"

local str_display = finale.FCString()
str.LuaString = "2in"

print(str_internal:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT) == str_display:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)) -- true
```

| Input | Type | Description |
| ----- | ---- | ----------- |
| `unit` | `number` | A finale MEASUREMENTUNIT constant. |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### is_valid_unit

```lua
measurement.is_valid_unit(unit)
```

Checks if a number is equal to one of the finale MEASUREMENTUNIT constants.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `unit` | `number` | The unit to check. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if valid, `false` if not. |

### get_real_default_unit

```lua
measurement.get_real_default_unit()
```

Resolves `finale.MEASUREMENTUNIT_DEFAULT` to the value of one of the other `MEASUREMENTUNIT` constants.

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

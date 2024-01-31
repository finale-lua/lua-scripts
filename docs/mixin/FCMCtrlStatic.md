# FCMCtrlStatic

## Summary of Modifications
- Added hooks for control state preservation.
- SetTextColor updates visible color immediately if window is showing.
- Added methods for setting and displaying measurements.

## Functions

- [Init(self)](#init)
- [RegisterParent(self, window)](#registerparent)
- [SetTextColor(self, red, green, blue)](#settextcolor)
- [RestoreState(self)](#restorestate)
- [SetText(self, str)](#settext)
- [SetMeasurement(self, value, measurementunit)](#setmeasurement)
- [SetMeasurementInteger(self, value, measurementunit)](#setmeasurementinteger)
- [SetMeasurementEfix(self, value, measurementunit)](#setmeasurementefix)
- [SetMeasurement10000th(self, value, measurementunit)](#setmeasurement10000th)
- [SetShowMeasurementSuffix(self, enabled)](#setshowmeasurementsuffix)
- [SetMeasurementSuffixShort(self)](#setmeasurementsuffixshort)
- [SetMeasurementSuffixAbbreviated(self)](#setmeasurementsuffixabbreviated)
- [SetMeasurementSuffixFull(self)](#setmeasurementsuffixfull)
- [UpdateMeasurementUnit(self)](#updatemeasurementunit)

### Init

```lua
fcmctrlstatic.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L52)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

### RegisterParent

```lua
fcmctrlstatic.RegisterParent(self, window)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L77)

**[Fluid] [Internal] [Override]**

Override Changes:
- Set `MeasurementEnabled` flag.

*Do not disable this method.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |
| `window` | `FCMCustomWindow` |  |

### SetTextColor

```lua
fcmctrlstatic.SetTextColor(self, red, green, blue)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L97)

**[Fluid] [Override]**

Override Changes:
- Displays the new text color immediately.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |
| `red` | `number` |  |
| `green` | `number` |  |
| `blue` | `number` |  |

### RestoreState

```lua
fcmctrlstatic.RestoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L125)

**[Fluid] [Internal] [Override]**

Override Changes:
- Restores `FCMCtrlStatic`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

### SetText

```lua
fcmctrlstatic.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L145)

**[Fluid] [Override]**

Override Changes:
- Switches the control's measurement status off.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |
| `str` | `FCString \| string\|  number` |  |

### SetMeasurement

```lua
fcmctrlstatic.SetMeasurement(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L166)

**[Fluid]**

Sets a measurement in fractional EVPUs which will be displayed in either the specified measurement unit or the parent window's current measurement unit.
If using the parent window's measurement unit, it will be automatically updated if the parent window's measurement unit changes.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |
| `value` | `number` | Value in EVPUs |
| `measurementunit` (optional) | `number \| nil` | Forces the value to be displayed in this measurement unit. Can only be omitted if parent window is `FCMCustomLuaWindow`. |

### SetMeasurementInteger

```lua
fcmctrlstatic.SetMeasurementInteger(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L185)

**[Fluid]**

Sets a measurement in whole EVPUs which will be displayed in either the specified measurement unit or the parent window's current measurement unit.
If using the parent window's measurement unit, it will be automatically updated if the parent window's measurement unit changes.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |
| `value` | `number` | Value in whole EVPUs |
| `measurementunit` (optional) | `number \| nil` | Forces the value to be displayed in this measurement unit. Can only be omitted if parent window is `FCMCustomLuaWindow`. |

### SetMeasurementEfix

```lua
fcmctrlstatic.SetMeasurementEfix(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L204)

**[Fluid]**

Sets a measurement in EFIXes which will be displayed in either the specified measurement unit or the parent window's current measurement unit.
If using the parent window's measurement unit, it will be automatically updated if the parent window's measurement unit changes.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |
| `value` | `number` | Value in EFIXes |
| `measurementunit` (optional) | `number \| nil` | Forces the value to be displayed in this measurement unit. Can only be omitted if parent window is `FCMCustomLuaWindow`. |

### SetMeasurement10000th

```lua
fcmctrlstatic.SetMeasurement10000th(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L-1)

**[Fluid]**

Sets a measurement in 10000ths of an EVPU which will be displayed in either the specified measurement unit or the parent window's current measurement unit.
If using the parent window's measurement unit, it will be automatically updated if the parent window's measurement unit changes.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |
| `value` | `number` | Value in 10000ths of an EVPU |
| `measurementunit` (optional) | `number \| nil` | Forces the value to be displayed in this measurement unit. Can only be omitted if parent window is `FCMCustomLuaWindow`. |

### SetShowMeasurementSuffix

```lua
fcmctrlstatic.SetShowMeasurementSuffix(self, enabled)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L240)

**[Fluid]**

Sets whether to show a suffix at the end of a measurement (eg `cm` in `2.54cm`). This is enabled by default.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |
| `enabled` | `boolean` |  |

### SetMeasurementSuffixShort

```lua
fcmctrlstatic.SetMeasurementSuffixShort(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L256)

**[Fluid]**

Sets the measurement suffix to the shortest form used by Finale's measurement overrides (eg `e`, `i`, `c`, etc)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

### SetMeasurementSuffixAbbreviated

```lua
fcmctrlstatic.SetMeasurementSuffixAbbreviated(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L272)

**[Fluid]**

Sets the measurement suffix to commonly known abbrevations (eg `in`, `cm`, `pt`, etc).

*This is the default style.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

### SetMeasurementSuffixFull

```lua
fcmctrlstatic.SetMeasurementSuffixFull(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L286)

**[Fluid]**

Sets the measurement suffix to the full unit name. (eg `inches`, `centimeters`, etc).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

### UpdateMeasurementUnit

```lua
fcmctrlstatic.UpdateMeasurementUnit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlStatic.lua#L300)

**[Fluid] [Internal]**

Updates the displayed measurement unit in line with the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

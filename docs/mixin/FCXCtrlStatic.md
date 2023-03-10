# FCXCtrlStatic

*Extends `FCMCtrlStatic`*

Summary of changes:
- Parent window must be `FCXCustomLuaWindow`
- Added methods for setting and displaying measurements

## Functions

- [Init(self)](#init)
- [SetText(self, str)](#settext)
- [SetMeasurement(self, value)](#setmeasurement)
- [SetMeasurementInteger(self, value)](#setmeasurementinteger)
- [SetMeasurementEfix(self, value)](#setmeasurementefix)
- [SetShowMeasurementSuffix(self, enabled)](#setshowmeasurementsuffix)
- [SetMeasurementSuffixShort(self)](#setmeasurementsuffixshort)
- [SetMeasurementSuffixAbbreviated(self)](#setmeasurementsuffixabbreviated)
- [SetMeasurementSuffixFull(self)](#setmeasurementsuffixfull)
- [UpdateMeasurementUnit(self)](#updatemeasurementunit)

### Init

```lua
fcxctrlstatic.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L39)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |

### SetText

```lua
fcxctrlstatic.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L57)

**[Fluid] [Override]**
Switches the control's measurement status off.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |
| `str` | `FCString\|string\|number` |  |

### SetMeasurement

```lua
fcxctrlstatic.SetMeasurement(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L75)

**[Fluid]**
Sets a measurement in EVPUs which will be displayed in the parent window's current measurement unit. This will be automatically updated if the parent window's measurement unit changes.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |
| `value` | `number` | Value in EVPUs |

### SetMeasurementInteger

```lua
fcxctrlstatic.SetMeasurementInteger(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L97)

**[Fluid]**
Sets a measurement in whole EVPUs which will be displayed in the parent window's current measurement unit. This will be automatically updated if the parent window's measurement unit changes.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |
| `value` | `number` | Value in whole EVPUs (fractional part will be rounded to nearest integer) |

### SetMeasurementEfix

```lua
fcxctrlstatic.SetMeasurementEfix(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L120)

**[Fluid]**
Sets a measurement in EFIXes which will be displayed in the parent window's current measurement unit. This will be automatically updated if the parent window's measurement unit changes.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |
| `value` | `number` | Value in EFIXes |

### SetShowMeasurementSuffix

```lua
fcxctrlstatic.SetShowMeasurementSuffix(self, enabled)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L143)

**[Fluid]**
Sets whether to show a suffix at the end of a measurement (eg `cm` in `2.54cm`). This is on by default.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |
| `enabled` | `boolean` |  |

### SetMeasurementSuffixShort

```lua
fcxctrlstatic.SetMeasurementSuffixShort(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L158)

**[Fluid]**
Sets the measurement suffix to the short style used by Finale's internals (eg `e`, `i`, `c`, etc)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |

### SetMeasurementSuffixAbbreviated

```lua
fcxctrlstatic.SetMeasurementSuffixAbbreviated(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L172)

**[Fluid]**
Sets the measurement suffix to commonly known abbrevations (eg `in`, `cm`, `pt`, etc).
This is the default style.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |

### SetMeasurementSuffixFull

```lua
fcxctrlstatic.SetMeasurementSuffixFull(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L185)

**[Fluid]**
Sets the measurement suffix to the full unit name. (eg `inches`, `centimeters`, etc).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |

### UpdateMeasurementUnit

```lua
fcxctrlstatic.UpdateMeasurementUnit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlStatic.lua#L198)

**[Fluid] [Internal]**
Updates the displayed measurement unit in line with the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlStatic` |  |

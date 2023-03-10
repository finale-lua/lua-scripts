# FCXCtrlUpDown

*Extends `FCMCtrlUpDown`*
An up down control that is created by `FCXCustomLuaWindow`.

Summary of modifications:
- The ability to set the step size on a per-measurement unit basis.
- Step size for integers can also be changed.
- Added a setting for forcing alignment to the next step when moving up or down.
- Connected edit must be an instance of `FCXCtrlEdit`
- Measurement edits can be connected in two additional ways which affect the underlying methods used in `GetValue` and `SetValue`
- Measurement EFIX edits have a different set of default step sizes.

## Functions

- [Init(self)](#init)
- [GetConnectedEdit(self)](#getconnectededit)
- [ConnectIntegerEdit(self, control, minimum, maximum)](#connectintegeredit)
- [ConnectMeasurementEdit(self, control, minimum, maximum)](#connectmeasurementedit)
- [SetIntegerStepSize(self, value)](#setintegerstepsize)
- [SetEVPUsStepSize(self, value)](#setevpusstepsize)
- [SetInchesStepSize(self, value, is_evpus)](#setinchesstepsize)
- [SetCentimetersStepSize(self, value, is_evpus)](#setcentimetersstepsize)
- [SetPointsStepSize(self, value, is_evpus)](#setpointsstepsize)
- [SetPicasStepSize(self, value, is_evpus)](#setpicasstepsize)
- [SetSpacesStepSize(self, value, is_evpus)](#setspacesstepsize)
- [AlignWSetAlignWhenMovinghenMoving(self, on)](#alignwsetalignwhenmovinghenmoving)
- [GetValue(self)](#getvalue)
- [SetValue(self, value)](#setvalue)
- [GetMinimum(self)](#getminimum)
- [GetMaximum(self)](#getmaximum)
- [SetRange(self, minimum, maximum)](#setrange)

### Init

```lua
fcxctrlupdown.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L65)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |

### GetConnectedEdit

```lua
fcxctrlupdown.GetConnectedEdit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L153)

**[Override]**
Ensures that original edit control is returned.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlEdit\\|nil` | `nil` if there is no edit connected. |

### ConnectIntegerEdit

```lua
fcxctrlupdown.ConnectIntegerEdit(self, control, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L169)

**[Fluid] [Override]**
Connects an integer edit.
The underlying methods used in `GetValue` and `SetValue` will be `GetRangeInteger` and `SetInteger` respectively.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `control` | `FCMCtrlEdit` |  |
| `minimum` | `number` |  |
| `maximum` | `maximum` |  |

### ConnectMeasurementEdit

```lua
fcxctrlupdown.ConnectMeasurementEdit(self, control, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L193)

**[Fluid] [Override]**
Connects a measurement edit. The control will be automatically registered as a measurement edit if it isn't already.
The underlying methods used in `GetValue` and `SetValue` will depend on the measurement edit's type.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `control` | `FCXCtrlMeasurementEdit` |  |
| `minimum` | `number` |  |
| `maximum` | `maximum` |  |

### SetIntegerStepSize

```lua
fcxctrlupdown.SetIntegerStepSize(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L213)

**[Fluid]**
Sets the step size for integer edits.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `value` | `number` |  |

### SetEVPUsStepSize

```lua
fcxctrlupdown.SetEVPUsStepSize(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L228)

**[Fluid]**
Sets the step size for measurement edits that are currently displaying in EVPUs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `value` | `number` |  |

### SetInchesStepSize

```lua
fcxctrlupdown.SetInchesStepSize(self, value, is_evpus)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L244)

**[Fluid]**
Sets the step size for measurement edits that are currently displaying in Inches.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `value` | `number` |  |
| `is_evpus` (optional) | `boolean` | If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Inches. |

### SetCentimetersStepSize

```lua
fcxctrlupdown.SetCentimetersStepSize(self, value, is_evpus)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L264)

**[Fluid]**
Sets the step size for measurement edits that are currently displaying in Centimeters.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `value` | `number` |  |
| `is_evpus` (optional) | `boolean` | If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Centimeters. |

### SetPointsStepSize

```lua
fcxctrlupdown.SetPointsStepSize(self, value, is_evpus)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L284)

**[Fluid]**
Sets the step size for measurement edits that are currently displaying in Points.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `value` | `number` |  |
| `is_evpus` (optional) | `boolean` | If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Points. |

### SetPicasStepSize

```lua
fcxctrlupdown.SetPicasStepSize(self, value, is_evpus)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L304)

**[Fluid]**
Sets the step size for measurement edits that are currently displaying in Picas.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `value` | `number\|string` |  |
| `is_evpus` (optional) | `boolean` | If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Picas. |

### SetSpacesStepSize

```lua
fcxctrlupdown.SetSpacesStepSize(self, value, is_evpus)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L325)

**[Fluid]**
Sets the step size for measurement edits that are currently displaying in Spaces.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `value` | `number` |  |
| `is_evpus` (optional) | `boolean` | If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Spaces. |

### AlignWSetAlignWhenMovinghenMoving

```lua
fcxctrlupdown.AlignWSetAlignWhenMovinghenMoving(self, on)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L-1)

**[Fluid]**
Sets whether to align to the next multiple of a step when moving.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `on` | `boolean` |  |

### GetValue

```lua
fcxctrlupdown.GetValue(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L365)

**[Override]**
Returns the value of the connected edit, clamped according to the set minimum and maximum.

Different types of connected edits will return different types and use different methods to access the value of the edit. The methods are:
- Integer edit => `GetRangeInteger`
- Measurement edit ("Measurement") => `GetRangeMeasurement`
- Measurement edit ("MeasurementInteger") => `GetRangeMeasurementInteger`
- Measurement edit ("MeasurementEfix") => `GetRangeMeasurementEfix`

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` | An integer for an integer edit, EVPUs for a measurement edit, whole EVPUs for a measurement integer edit, or EFIXes for a measurement EFIX edit. |

### SetValue

```lua
fcxctrlupdown.SetValue(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L394)

**[Fluid] [Override]**
Sets the value of the attached control, clamped according to the set minimum and maximum.

Different types of connected edits will accept different types and use different methods to set the value of the edit. The methods are:
- Integer edit => `SetRangeInteger`
- Measurement edit ("Measurement") => `SetRangeMeasurement`
- Measurement edit ("MeasurementInteger") => `SetRangeMeasurementInteger`
- Measurement edit ("MeasurementEfix") => `SetRangeMeasurementEfix`

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlUpDown` |  |
| `value` | `number` | An integer for an integer edit, EVPUs for a measurement edit, whole EVPUs for a measurement integer edit, or EFIXes for a measurement EFIX edit. |

### GetMinimum

```lua
fcxctrlupdown.GetMinimum(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L419)

**[Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` | An integer for integer edits or EVPUs for measurement edits. |

### GetMaximum

```lua
fcxctrlupdown.GetMaximum(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L432)

**[Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` | An integer for integer edits or EVPUs for measurement edits. |

### SetRange

```lua
fcxctrlupdown.SetRange(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlUpDown.lua#L445)

**[Fluid] [Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |
| `minimum` | `number` | An integer for integer edits or EVPUs for measurement edits. |
| `maximum` | `number` | An integer for integer edits or EVPUs for measurement edits. |

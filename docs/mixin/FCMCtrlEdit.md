# FCMCtrlEdit

## Summary of Modifications
- Added `Change` custom control event.
- Added hooks into control state preservation.
- `GetMeasurement*` and `SetMeasurement*` methods have been overridden to use the `FCMString` versions of those methods internally. For more details on any changes, see the documentation for `FCMString`.

## Functions

- [SetText(self, str)](#settext)
- [GetInteger(self)](#getinteger)
- [SetInteger(self, anint)](#setinteger)
- [GetFloat(self)](#getfloat)
- [SetFloat(self, value)](#setfloat)
- [GetMeasurement(self, measurementunit)](#getmeasurement)
- [GetRangeMeasurement(self, measurementunit, minimum, maximum)](#getrangemeasurement)
- [SetMeasurement(self, value, measurementunit)](#setmeasurement)
- [GetMeasurementEfix(self, measurementunit)](#getmeasurementefix)
- [GetRangeMeasurementEfix(self, measurementunit, minimum, maximum)](#getrangemeasurementefix)
- [SetMeasurementEfix(self, value, measurementunit)](#setmeasurementefix)
- [GetMeasurementInteger(self, measurementunit)](#getmeasurementinteger)
- [GetRangeMeasurementInteger(self, measurementunit, minimum, maximum)](#getrangemeasurementinteger)
- [SetMeasurementInteger(self, value, measurementunit)](#setmeasurementinteger)
- [GetMeasurement10000th(self, measurementunit)](#getmeasurement10000th)
- [GetRangeMeasurement10000th(self, measurementunit, minimum, maximum)](#getrangemeasurement10000th)
- [SetMeasurement10000th(self, value, measurementunit)](#setmeasurement10000th)
- [GetRangeInteger(self, minimum, maximum)](#getrangeinteger)
- [HandleChange(control, last_value)](#handlechange)
- [AddHandleChange(self, callback)](#addhandlechange)
- [RemoveHandleChange(self, callback)](#removehandlechange)

### SetText

```lua
fcmctrledit.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L33)

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `str` | `FCString \| string \| number` |  |

### GetInteger

```lua
fcmctrledit.GetInteger(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L316)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetInteger

```lua
fcmctrledit.SetInteger(self, anint)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `anint` | `number` |  |

### GetFloat

```lua
fcmctrledit.GetFloat(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetFloat

```lua
fcmctrledit.SetFloat(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |

### GetMeasurement

```lua
fcmctrledit.GetMeasurement(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L150)

**[Override]**

- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurement

```lua
fcmctrledit.GetRangeMeasurement(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L163)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurement

```lua
fcmctrledit.SetMeasurement(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L178)

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### GetMeasurementEfix

```lua
fcmctrledit.GetMeasurementEfix(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementEfix

```lua
fcmctrledit.GetRangeMeasurementEfix(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurementEfix

```lua
fcmctrledit.SetMeasurementEfix(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### GetMeasurementInteger

```lua
fcmctrledit.GetMeasurementInteger(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementInteger

```lua
fcmctrledit.GetRangeMeasurementInteger(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Override]**

Override Changes:
- Hooks into control state preservation.
- Fixes issue with decimal places in `minimum` being discarded instead of being correctly taken into account (see `FCMString.GetRangeMeasurementInteger`).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurementInteger

```lua
fcmctrledit.SetMeasurementInteger(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### GetMeasurement10000th

```lua
fcmctrledit.GetMeasurement10000th(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

Returns the measurement in 10000ths of an EVPU.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurement10000th

```lua
fcmctrledit.GetRangeMeasurement10000th(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

Returns the measurement in 10000ths of an EVPU, clamped between two values.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurement10000th

```lua
fcmctrledit.SetMeasurement10000th(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Fluid]**
Sets a measurement in 10000ths of an EVPU.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### GetRangeInteger

```lua
fcmctrledit.GetRangeInteger(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L312)

**[Override]**

Override Changes:
- Hooks into control state preservation.
- Fixes issue with decimal places in `minimum` being discarded instead of being correctly taken into account.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### HandleChange

```lua
fcmctrledit.HandleChange(control, last_value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L329)

**[Callback Template]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCMCtrlEdit` | The control that was changed. |
| `last_value` | `string` | The previous value of the control. |

### AddHandleChange

```lua
fcmctrledit.AddHandleChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L348)

**[Fluid]**

Adds a handler for when the value of the control changes.
The even will fire when:
- The window is created (if the value of the control is not an empty string)
- The value of the control is changed by the user
- The value of the control is changed programmatically (if the value of the control is changed within a handler, that *same* handler will not be called again for that change.)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `callback` | `function` | See `HandleChange` for callback signature. |

### RemoveHandleChange

```lua
fcmctrledit.RemoveHandleChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L353)

**[Fluid]**

Removes a handler added with `AddHandleChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `callback` | `function` |  |

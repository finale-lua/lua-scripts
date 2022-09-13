# FCMCtrlEdit

Summary of modifications:
- Added `Change` custom control event.
- Added hooks for restoring control state

## Functions

- [SetText(self, str)](#settext)
- [GetInteger(self)](#getinteger)
- [SetInteger(self, anint)](#setinteger)
- [GetFloat(self)](#getfloat)
- [SetFloat(self, value)](#setfloat)
- [GetMeasurement(self, measurementunit)](#getmeasurement)
- [SetMeasurement(self, value, measurementunit)](#setmeasurement)
- [GetMeasurementEfix(self, measurementunit)](#getmeasurementefix)
- [SetMeasurementEfix(self, value, measurementunit)](#setmeasurementefix)
- [GetMeasurementInteger(self, measurementunit)](#getmeasurementinteger)
- [SetMeasurementInteger(self, value, measurementunit)](#setmeasurementinteger)
- [GetRangeInteger(self, minimum, maximum)](#getrangeinteger)
- [GetRangeMeasurement(self, measurementunit, minimum, maximum)](#getrangemeasurement)
- [GetRangeMeasurementEfix(self, measurementunit, minimum, maximum)](#getrangemeasurementefix)
- [GetRangeMeasurementInteger(self, measurementunit, minimum, maximum)](#getrangemeasurementinteger)
- [HandleChange(control, last_value)](#handlechange)
- [AddHandleChange(self, callback)](#addhandlechange)
- [RemoveHandleChange(self, callback)](#removehandlechange)

### SetText

```lua
fcmctrledit.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L29)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `str` | `FCString\|string\|number` |  |

### GetInteger

```lua
fcmctrledit.GetInteger(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L201)

**[Override]**
Hooks into control state restoration.

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
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

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
Hooks into control state restoration.

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
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |

### GetMeasurement

```lua
fcmctrledit.GetMeasurement(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L120)

**[Override]**
Hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurement

```lua
fcmctrledit.SetMeasurement(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L131)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### GetMeasurementEfix

```lua
fcmctrledit.GetMeasurementEfix(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L241)

**[Override]**
Hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurementEfix

```lua
fcmctrledit.SetMeasurementEfix(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### GetMeasurementInteger

```lua
fcmctrledit.GetMeasurementInteger(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L261)

**[Override]**
Hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurementInteger

```lua
fcmctrledit.SetMeasurementInteger(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L-1)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.
Also hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### GetRangeInteger

```lua
fcmctrledit.GetRangeInteger(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L197)

**[Override]**
Hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurement

```lua
fcmctrledit.GetRangeMeasurement(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L216)

**[Override]**
Hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementEfix

```lua
fcmctrledit.GetRangeMeasurementEfix(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L236)

**[Override]**
Hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementInteger

```lua
fcmctrledit.GetRangeMeasurementInteger(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L256)

**[Override]**
Hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `measurementunit` | `number` | Any of the finale.MEASUREMENTUNIT_* constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### HandleChange

```lua
fcmctrledit.HandleChange(control, last_value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L274)

**[Callback Template]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCMCtrlEdit` | The control that was changed. |
| `last_value` | `string` | The previous value of the control. |

### AddHandleChange

```lua
fcmctrledit.AddHandleChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L291)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua#L296)

**[Fluid]**
Removes a handler added with `AddHandleChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `callback` | `function` |  |

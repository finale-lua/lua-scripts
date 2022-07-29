# FCMCtrlEdit

Summary of modifications:
- Added `Change` custom control event.

## Functions

- [SetInteger(self, anint)](#setinteger)
- [SetText(self, str)](#settext)
- [SetMeasurement(self, value, measurementunit)](#setmeasurement)
- [SetMeasurementEfix(self, value, measurementunit)](#setmeasurementefix)
- [SetMeasurementInteger(self, value, measurementunit)](#setmeasurementinteger)
- [SetFloat(self, value)](#setfloat)
- [HandleChange(control, last_value)](#handlechange)
- [AddHandleChange(self, callback)](#addhandlechange)
- [RemoveHandleChange(self, callback)](#removehandlechange)

### SetInteger

```lua
fcmctrledit.SetInteger(self, anint)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua.lua#L26)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `anint` | `number` |  |

### SetText

```lua
fcmctrledit.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua.lua#L42)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `str` | `FCString\|string\|number` |  |

### SetMeasurement

```lua
fcmctrledit.SetMeasurement(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua.lua#L59)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### SetMeasurementEfix

```lua
fcmctrledit.SetMeasurementEfix(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua.lua#L77)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### SetMeasurementInteger

```lua
fcmctrledit.SetMeasurementInteger(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua.lua#L95)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |
| `measurementunit` | `number` |  |

### SetFloat

```lua
fcmctrledit.SetFloat(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua.lua#L112)

**[Fluid] [Override]**
Ensures that `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `value` | `number` |  |

### HandleChange

```lua
fcmctrledit.HandleChange(control, last_value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua.lua#L129)

**[Callback Template]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCMCtrlEdit` | The control that was changed. |
| `last_value` | `string` | The previous value of the control. |

### AddHandleChange

```lua
fcmctrledit.AddHandleChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua.lua#L146)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlEdit.lua.lua#L151)

**[Fluid]**
Removes a handler added with `AddHandleChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlEdit` |  |
| `callback` | `function` |  |

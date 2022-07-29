# FCXCtrlMeasurementEdit

*Extends `FCMCtrlEdit`*

Summary of modifications:
- Parent window must be an instance of `FCXCustomLuaWindow`
- Displayed measurement unit will be automatically updated with the parent window
- Measurement edits can be set to one of three types which correspond to the `GetMeasurement*`, `SetMeasurement*` and *GetRangeMeasurement*` methods. The type affects which methods are used for changing measurement units, for events, and for interacting with an `FCXCtrlUpDown` control.
- All measurement get and set methods no longer accept a measurement unit as this is taken from the parent window.
- `Change` event has been overridden to pass a measurement.

## Functions

- [Init(self)](#init)
- [SetText(self, str)](#settext)
- [SetInteger(self, anint)](#setinteger)
- [SetFloat(self, value)](#setfloat)
- [GetMeasurement(self)](#getmeasurement)
- [SetMeasurement(self, value)](#setmeasurement)
- [GetMeasurementInteger(self)](#getmeasurementinteger)
- [SetMeasurementInteger(self, value)](#setmeasurementinteger)
- [GetMeasurementEfix(self)](#getmeasurementefix)
- [SetMeasurementEfix(self, value)](#setmeasurementefix)
- [GetRangeMeasurement(self, minimum, maximum)](#getrangemeasurement)
- [GetRangeMeasurementInteger(self, minimum, maximum)](#getrangemeasurementinteger)
- [GetRangeMeasurementEfix(self, minimum, maximum)](#getrangemeasurementefix)
- [SetTypeMeasurement(self)](#settypemeasurement)
- [SetTypeMeasurementInteger(self)](#settypemeasurementinteger)
- [SetTypeMeasurementEfix(self)](#settypemeasurementefix)
- [IsTypeMeasurement(self)](#istypemeasurement)
- [IsTypeMeasurementInteger(self)](#istypemeasurementinteger)
- [IsTypeMeasurementEfix(self)](#istypemeasurementefix)
- [UpdateMeasurementUnit(self)](#updatemeasurementunit)
- [HandleChange(control, last_value)](#handlechange)
- [AddHandleChange(self, callback)](#addhandlechange)
- [RemoveHandleChange(self, callback)](#removehandlechange)

### Init

```lua
fcxctrlmeasurementedit.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L32)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### SetText

```lua
fcxctrlmeasurementedit.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L51)

**[Fluid] [Override]**
Ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `str` | `FCString\|string\|number` |  |

### SetInteger

```lua
fcxctrlmeasurementedit.SetInteger(self, anint)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L67)

**[Fluid] [Override]**
Ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `anint` | `number` |  |

### SetFloat

```lua
fcxctrlmeasurementedit.SetFloat(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L83)

**[Fluid] [Override]**
Ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `value` | `number` |  |

### GetMeasurement

```lua
fcxctrlmeasurementedit.GetMeasurement(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L99)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurement

```lua
fcxctrlmeasurementedit.SetMeasurement(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L114)

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

Also ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `value` | `number` |  |

### GetMeasurementInteger

```lua
fcxctrlmeasurementedit.GetMeasurementInteger(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L130)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurementInteger

```lua
fcxctrlmeasurementedit.SetMeasurementInteger(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L145)

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

Also ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `value` | `number` |  |

### GetMeasurementEfix

```lua
fcxctrlmeasurementedit.GetMeasurementEfix(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L161)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurementEfix

```lua
fcxctrlmeasurementedit.SetMeasurementEfix(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L176)

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

Also ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `value` | `number` |  |

### GetRangeMeasurement

```lua
fcxctrlmeasurementedit.GetRangeMeasurement(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L194)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementInteger

```lua
fcxctrlmeasurementedit.GetRangeMeasurementInteger(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L212)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementEfix

```lua
fcxctrlmeasurementedit.GetRangeMeasurementEfix(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L230)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetTypeMeasurement

```lua
fcxctrlmeasurementedit.SetTypeMeasurement(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L246)

**[Fluid]**
Sets the type to `"Measurement"`.
This means that the setters & getters used in events, measurement unit changes, and up down controls are `GetMeasurement`, `GetRangeMeasurement`, and `SetMeasurement`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### SetTypeMeasurementInteger

```lua
fcxctrlmeasurementedit.SetTypeMeasurementInteger(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L269)

**[Fluid]**
Sets the type to `"MeasurementInteger"`. This is the default type.
This means that the setters & getters used in events, measurement unit changes, and up down controls are `GetMeasurementInteger`, `GetRangeMeasurementInteger`, and `SetMeasurementInteger`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### SetTypeMeasurementEfix

```lua
fcxctrlmeasurementedit.SetTypeMeasurementEfix(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L296)

**[Fluid]**
Sets the type to `"MeasurementEfix"`.
This means that the setters & getters used in events, measurement unit changes, and up down controls are `GetMeasurementEfix`, `GetRangeMeasurementEfix`, and `SetMeasurementEfix`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### IsTypeMeasurement

```lua
fcxctrlmeasurementedit.IsTypeMeasurement(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L326)

Checks if the type is `"Measurement"`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### IsTypeMeasurementInteger

```lua
fcxctrlmeasurementedit.IsTypeMeasurementInteger(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L338)

Checks if the type is `"MeasurementInteger"`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### IsTypeMeasurementEfix

```lua
fcxctrlmeasurementedit.IsTypeMeasurementEfix(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L350)

Checks if the type is `"MeasurementEfix"`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### UpdateMeasurementUnit

```lua
fcxctrlmeasurementedit.UpdateMeasurementUnit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L362)

**[Fluid] [Internal]**
Checks the parent window for a change in measurement unit and updates the control if needed.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### HandleChange

```lua
fcxctrlmeasurementedit.HandleChange(control, last_value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L386)

**[Callback Template] [Override]**
The type and unit of `last_value` will change depending on the measurement edit's type. The possibilities are:
- `"Measurement"` => EVPUs (with fractional part)
- `"MeasurementInteger"` => whole EVPUs (without fractional part)
- `"MeasurementEfix"` => EFIXes (1 EFIX is 1/64th of an EVPU)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCXCtrlMeasurementEdit` | The control that was changed. |
| `last_value` | `number` | The previous measurement value of the control. |

### AddHandleChange

```lua
fcxctrlmeasurementedit.AddHandleChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L404)

**[Fluid] [Override]**
Adds a handler for when the value of the control changes.
The even will fire when:
- The window is created (if the value of the control is not an empty string)
- The value of the control is changed by the user
- The value of the control is changed programmatically (if the value of the control is changed within a handler, that *same* handler will not be called again for that change.)
- A measurement unit change will only trigger the event if the underlying measurement value has changed.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `callback` | `function` | See `HandleChange` for callback signature. |

### RemoveHandleChange

```lua
fcxctrlmeasurementedit.RemoveHandleChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua.lua#L409)

**[Fluid] [Override]**
Removes a handler added with `AddHandleChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `callback` | `function` |  |

# FCXCtrlMeasurementEdit

*Extends `FCMCtrlEdit`*

_Note that the type should be set **before** setting any values._

Summary of modifications:
- Parent window must be an instance of `FCXCustomLuaWindow`.
- Displayed measurement unit will be automatically updated with the parent window.
- Measurement edits can be set to one of four types which correspond to the `GetMeasurement*`, `SetMeasurement*` and *GetRangeMeasurement*` methods. The type affects which methods are used for changing measurement units, for events, and for interacting with an `FCXCtrlUpDown` control.
- All measurement get and set methods no longer accept a measurement unit as this is taken from the parent window.
- Added measures to prevent underlying value from changing when the measurement unit is changed.
- `Change` event has been overridden to pass a measurement.
- Added hooks into control state restoration

## Functions

- [Init(self)](#init)
- [SetText(self, str)](#settext)
- [SetInteger(self, anint)](#setinteger)
- [SetFloat(self, value)](#setfloat)
- [GetType(self)](#gettype)
- [GetMeasurement(self)](#getmeasurement)
- [GetRangeMeasurement(self, minimum, maximum)](#getrangemeasurement)
- [SetMeasurement(self, value)](#setmeasurement)
- [IsTypeMeasurement(self)](#istypemeasurement)
- [SetTypeMeasurement(self)](#settypemeasurement)
- [GetMeasurementInteger(self)](#getmeasurementinteger)
- [GetRangeMeasurementInteger(self, minimum, maximum)](#getrangemeasurementinteger)
- [SetMeasurementInteger(self, value)](#setmeasurementinteger)
- [IsTypeMeasurementInteger(self)](#istypemeasurementinteger)
- [SetTypeMeasurementInteger(self)](#settypemeasurementinteger)
- [GetMeasurementEfix(self)](#getmeasurementefix)
- [GetRangeMeasurementEfix(self, minimum, maximum)](#getrangemeasurementefix)
- [SetMeasurementEfix(self, value)](#setmeasurementefix)
- [IsTypeMeasurementEfix(self)](#istypemeasurementefix)
- [SetTypeMeasurementEfix(self)](#settypemeasurementefix)
- [GetMeasurement10000th(self)](#getmeasurement10000th)
- [GetRangeMeasurement10000th(self, minimum, maximum)](#getrangemeasurement10000th)
- [SetMeasurement10000th(self, value)](#setmeasurement10000th)
- [IsTypeMeasurement10000th(self)](#istypemeasurement10000th)
- [SetTypeMeasurement10000th(self)](#settypemeasurement10000th)
- [UpdateMeasurementUnit(self)](#updatemeasurementunit)
- [HandleChange(control, last_value)](#handlechange)
- [AddHandleChange(self, callback)](#addhandlechange)
- [RemoveHandleChange(self, callback)](#removehandlechange)

### Init

```lua
fcxctrlmeasurementedit.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L66)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### SetText

```lua
fcxctrlmeasurementedit.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L-1)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L-1)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L-1)

**[Fluid] [Override]**
Ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `value` | `number` |  |

### GetType

```lua
fcxctrlmeasurementedit.GetType(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L130)

Returns the measurement edit's type. The result can also be appended to `"Get"`, `"GetRange"`, or `"Set"` to use type-specific methods.
The default type is `"MeasurementInteger"`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` | `"Measurement"`, `"MeasurementInteger"`, `"MeasurementEfix"`, or `"Measurement10000th"` |

### GetMeasurement

```lua
fcxctrlmeasurementedit.GetMeasurement(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L181)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurement

```lua
fcxctrlmeasurementedit.GetRangeMeasurement(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L181)

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

### SetMeasurement

```lua
fcxctrlmeasurementedit.SetMeasurement(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L181)

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.
Also ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `value` | `number` |  |

### IsTypeMeasurement

```lua
fcxctrlmeasurementedit.IsTypeMeasurement(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L220)

Checks if the type is `"Measurement"`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### SetTypeMeasurement

```lua
fcxctrlmeasurementedit.SetTypeMeasurement(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L229)

**[Fluid]**
Sets the type to `"Measurement"`.
This means that the getters & setters used in events, measurement unit changes, and up down controls are `GetMeasurement`, `GetRangeMeasurement`, and `SetMeasurement`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### GetMeasurementInteger

```lua
fcxctrlmeasurementedit.GetMeasurementInteger(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L233)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementInteger

```lua
fcxctrlmeasurementedit.GetRangeMeasurementInteger(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L233)

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

### SetMeasurementInteger

```lua
fcxctrlmeasurementedit.SetMeasurementInteger(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L233)

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.
Also ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `value` | `number` |  |

### IsTypeMeasurementInteger

```lua
fcxctrlmeasurementedit.IsTypeMeasurementInteger(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L-1)

Checks if the type is `"MeasurementInteger"`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### SetTypeMeasurementInteger

```lua
fcxctrlmeasurementedit.SetTypeMeasurementInteger(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L-1)

**[Fluid]**
Sets the type to `"MeasurementInteger"`. This is the default type.
This means that the getters & setters used in events, measurement unit changes, and up down controls are `GetMeasurementInteger`, `GetRangeMeasurementInteger`, and `SetMeasurementInteger`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### GetMeasurementEfix

```lua
fcxctrlmeasurementedit.GetMeasurementEfix(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L285)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementEfix

```lua
fcxctrlmeasurementedit.GetRangeMeasurementEfix(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L285)

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

### SetMeasurementEfix

```lua
fcxctrlmeasurementedit.SetMeasurementEfix(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L285)

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.
Also ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `value` | `number` |  |

### IsTypeMeasurementEfix

```lua
fcxctrlmeasurementedit.IsTypeMeasurementEfix(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L-1)

Checks if the type is `"MeasurementEfix"`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### SetTypeMeasurementEfix

```lua
fcxctrlmeasurementedit.SetTypeMeasurementEfix(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L-1)

**[Fluid]**
Sets the type to `"MeasurementEfix"`.
This means that the getters & setters used in events, measurement unit changes, and up down controls are `GetMeasurementEfix`, `GetRangeMeasurementEfix`, and `SetMeasurementEfix`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### GetMeasurement10000th

```lua
fcxctrlmeasurementedit.GetMeasurement10000th(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L337)

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurement10000th

```lua
fcxctrlmeasurementedit.GetRangeMeasurement10000th(self, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L337)

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

### SetMeasurement10000th

```lua
fcxctrlmeasurementedit.SetMeasurement10000th(self, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L337)

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.
Also ensures that the overridden `Change` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `value` | `number` |  |

### IsTypeMeasurement10000th

```lua
fcxctrlmeasurementedit.IsTypeMeasurement10000th(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L-1)

Checks if the type is `"Measurement10000th"`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### SetTypeMeasurement10000th

```lua
fcxctrlmeasurementedit.SetTypeMeasurement10000th(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L-1)

**[Fluid]**
Sets the type to `"Measurement10000th"`.
This means that the getters & setters used in events, measurement unit changes, and up down controls are `GetMeasurement10000th`, `GetRangeMeasurement10000th`, and `SetMeasurement10000th`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### UpdateMeasurementUnit

```lua
fcxctrlmeasurementedit.UpdateMeasurementUnit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L398)

**[Fluid] [Internal]**
Checks the parent window for a change in measurement unit and updates the control if needed.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |

### HandleChange

```lua
fcxctrlmeasurementedit.HandleChange(control, last_value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L422)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L440)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCtrlMeasurementEdit.lua#L445)

**[Fluid] [Override]**
Removes a handler added with `AddHandleChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementEdit` |  |
| `callback` | `function` |  |

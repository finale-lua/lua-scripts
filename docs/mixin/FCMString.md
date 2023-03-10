# FCMString

Summary of modifications:
- Fixed rounding bugs in `GetMeasurement` and adjusted override handling behaviour to match `FCCtrlEdit.GetMeasurement` on Windows
- Fixed bug in `SetMeasurement` where all displayed numbers were truncated at 2 decimal places.
- Added `GetMeasurementInteger`, `GetRangeMeasurementInteger` and `SetMeasurementInteger` methods for parity with `FCCtrlEdit`
- Added `GetMeasurementEfix`, `GetRangeMeasurementEfix` and `SetMeasurementEfix methods for parity with `FCCtrlEdit`
- Added `*Measurement10000th` methods for setting and retrieving values in 10,000ths of an EVPU (eg for piano brace settings, slur tip width, etc)

## Functions

- [GetMeasurement(self, measurementunit)](#getmeasurement)
- [GetRangeMeasurement(self, measurementunit, minimum, maximum)](#getrangemeasurement)
- [SetMeasurement(self, value, measurementunit)](#setmeasurement)
- [GetMeasurementInteger(self, measurementunit)](#getmeasurementinteger)
- [GetRangeMeasurementInteger(self, measurementunit, minimum, maximum)](#getrangemeasurementinteger)
- [SetMeasurementInteger(self, value, measurementunit)](#setmeasurementinteger)
- [GetMeasurementEfix(self, measurementunit)](#getmeasurementefix)
- [GetRangeMeasurementEfix(self, measurementunit, minimum, maximum)](#getrangemeasurementefix)
- [SetMeasurementEfix(self, value, measurementunit)](#setmeasurementefix)
- [GetMeasurement10000th(self, measurementunit)](#getmeasurement10000th)
- [GetRangeMeasurement10000th(self, measurementunit, minimum, maximum)](#getrangemeasurement10000th)
- [SetMeasurement10000th(self, value, measurementunit)](#setmeasurement10000th)

### GetMeasurement

```lua
fcmstring.GetMeasurement(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L56)

**[Override]**
Fixes issue with incorrect rounding of returned value.
Also changes handling of overrides to match the behaviour of `FCCtrlEdit` on Windows

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT_*` constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` | EVPUs with decimal part. |

### GetRangeMeasurement

```lua
fcmstring.GetRangeMeasurement(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L129)

**[Override]**
See `FCMString.GetMeasurement`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurement

```lua
fcmstring.SetMeasurement(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L148)

**[Override] [Fluid]**
Fixes issue with displayed numbers being truncated at 2 decimal places.
Emulates the behaviour of `FCCtrlEdit.SetMeasurement` on Windows while the window is showing.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `value` | `number` | The value to set in EVPUs. |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT_*` constants. |

### GetMeasurementInteger

```lua
fcmstring.GetMeasurementInteger(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L185)

Returns the measurement in whole EVPUs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementInteger

```lua
fcmstring.GetRangeMeasurementInteger(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L203)

Returns the measurement in whole EVPUs, clamped between two values.
Also ensures that any decimal places in `minimum` are correctly taken into account instead of being discarded.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurementInteger

```lua
fcmstring.SetMeasurementInteger(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L221)

**[Fluid]**
Sets a measurement in whole EVPUs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `value` | `number` | The value in whole EVPUs. |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |

### GetMeasurementEfix

```lua
fcmstring.GetMeasurementEfix(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L237)

Returns the measurement in whole EFIXes (1/64th of an EVPU)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurementEfix

```lua
fcmstring.GetRangeMeasurementEfix(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L254)

Returns the measurement in whole EFIXes (1/64th of an EVPU), clamped between two values.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurementEfix

```lua
fcmstring.SetMeasurementEfix(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L272)

**[Fluid]**
Sets a measurement in whole EFIXes.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `value` | `number` | The value in EFIXes (1/64th of an EVPU) |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |

### GetMeasurement10000th

```lua
fcmstring.GetMeasurement10000th(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L288)

Returns the measurement in 10,000ths of an EVPU.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetRangeMeasurement10000th

```lua
fcmstring.GetRangeMeasurement10000th(self, measurementunit, minimum, maximum)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L306)

Returns the measurement in 10,000ths of an EVPU, clamped between two values.
Also ensures that any decimal places in `minimum` are handled correctly instead of being discarded.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |
| `minimum` | `number` |  |
| `maximum` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurement10000th

```lua
fcmstring.SetMeasurement10000th(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L324)

**[Fluid]**
Sets a measurement in 10,000ths of an EVPU.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `value` | `number` | The value in 10,000ths of an EVPU. |
| `measurementunit` | `number` | One of the `finale.MEASUREMENTUNIT*_` constants. |

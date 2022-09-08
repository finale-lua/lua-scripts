# FCMString

Summary of modifications:
- Added `GetMeasurementInteger` and `SetMeasurementInteger` methods for parity with `FCCtrlEdit`

## Functions

- [GetMeasurementInteger(self, measurementunit)](#getmeasurementinteger)
- [SetMeasurementInteger(self, value, measurementunit)](#setmeasurementinteger)

### GetMeasurementInteger

```lua
fcmstring.GetMeasurementInteger(self, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L23)

Returns the measurement in whole EVPUs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `measurementunit` | `number` | Any of the `finale.MEASUREMENTUNIT*_` constants. |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetMeasurementInteger

```lua
fcmstring.SetMeasurementInteger(self, value, measurementunit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMString.lua#L39)

**[Fluid]**
Sets a measurement in whole EVPUs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMString` |  |
| `value` | `number` | The value in whole EVPUs. |
| `measurementunit` | `number` | Any of the `finale.MEASUREMENTUNIT*_` constants. |

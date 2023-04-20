# FCMCtrlUpDown

## Summary of Modifications
- Methods that returned a boolean to indicate success/failure now throw an error instead.
- `GetConnectedEdit` returns the original control object.
- Added methods to allow handlers for the `UpDownPressed` event to be set directly on the control.

## Functions

- [Init(self)](#init)
- [GetConnectedEdit(self)](#getconnectededit)
- [ConnectIntegerEdit(self, control, minvalue, maxvalue)](#connectintegeredit)
- [ConnectMeasurementEdit(self, control, minvalue, maxvalue)](#connectmeasurementedit)
- [AddHandlePress(self, callback)](#addhandlepress)
- [RemoveHandlePress(self, callback)](#removehandlepress)

### Init

```lua
fcmctrlupdown.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlUpDown.lua#L25)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |

### GetConnectedEdit

```lua
fcmctrlupdown.GetConnectedEdit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlUpDown.lua#L44)

**[Override]**

Override Changes:
- Ensures that original edit control is returned.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlEdit \\| nil` | `nil` if there is no edit connected. |

### ConnectIntegerEdit

```lua
fcmctrlupdown.ConnectIntegerEdit(self, control, minvalue, maxvalue)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlUpDown.lua#L62)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Stores original control object.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |
| `control` | `FCCtrlEdit` |  |
| `minvalue` | `number` |  |
| `maxvalue` | `number` |  |

### ConnectMeasurementEdit

```lua
fcmctrlupdown.ConnectMeasurementEdit(self, control, minvalue, maxvalue)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlUpDown.lua#L87)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Stores original control object.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |
| `control` | `FCCtrlEdit` |  |
| `minvalue` | `number` |  |
| `maxvalue` | `number` |  |

### AddHandlePress

```lua
fcmctrlupdown.AddHandlePress(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlUpDown.lua#L112)

**[Fluid]**
Adds a handler for UpDownPressed events.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature. |

### RemoveHandlePress

```lua
fcmctrlupdown.RemoveHandlePress(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlUpDown.lua#L117)

**[Fluid]**
Removes a handler added with `AddHandlePress`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |
| `callback` | `function` |  |

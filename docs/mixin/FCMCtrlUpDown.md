# FCMCtrlUpDown

Summary of modifications:
- `GetConnectedEdit` returns the original control object.
- Handlers for the `UpDownPressed` event can now be set on a control.

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

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |

### GetConnectedEdit

```lua
fcmctrlupdown.GetConnectedEdit(self)
```

**[Override]**
Ensures that original edit control is returned.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlEdit\\|nil` | `nil` if there is no edit connected. |

### ConnectIntegerEdit

```lua
fcmctrlupdown.ConnectIntegerEdit(self, control, minvalue, maxvalue)
```

**[Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |
| `control` | `FCCtrlEdit` |  |
| `minvalue` | `number` |  |
| `maxvalue` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### ConnectMeasurementEdit

```lua
fcmctrlupdown.ConnectMeasurementEdit(self, control, minvalue, maxvalue)
```

**[Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |
| `control` | `FCCtrlEdit` |  |
| `minvalue` | `number` |  |
| `maxvalue` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### AddHandlePress

```lua
fcmctrlupdown.AddHandlePress(self, callback)
```

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

**[Fluid]**
Removes a handler added with `AddHandlePress`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlUpDown` |  |
| `callback` | `function` |  |

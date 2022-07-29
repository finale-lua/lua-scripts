# FCMControl

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
- Ported `GetParent` from PDK to allow the parent window to be accessed from a control.
- Handlers for the `Command` event can now be set on a control.

## Functions

- [GetParent(self)](#getparent)
- [RegisterParent(self, window)](#registerparent)
- [GetText(self, str)](#gettext)
- [SetText(self, str)](#settext)
- [AddHandleCommand(self, callback)](#addhandlecommand)
- [RemoveHandleCommand(self, callback)](#removehandlecommand)

### GetParent

```lua
fcmcontrol.GetParent(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMControl.lua.lua#L31)

**[PDK Port]**
Returns the control's parent window.
Do not override or disable this method.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMCustomWindow` |  |

### RegisterParent

```lua
fcmcontrol.RegisterParent(self, window)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMControl.lua.lua#L45)

**[Fluid] [Internal]**
Used to register the parent window when the control is created.
Do not disable this method.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `window` | `FCMCustomWindow` |  |

### GetText

```lua
fcmcontrol.GetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMControl.lua.lua#L65)

**[Override]**
Returns a Lua `string` and makes passing an `FCString` optional.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `str` (optional) | `FCString` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### SetText

```lua
fcmcontrol.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMControl.lua.lua#L86)

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `str` | `FCString\|string\|number` |  |

### AddHandleCommand

```lua
fcmcontrol.AddHandleCommand(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMControl.lua.lua#L111)

**[Fluid]**
Adds a handler for command events.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature. |

### RemoveHandleCommand

```lua
fcmcontrol.RemoveHandleCommand(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMControl.lua.lua#L116)

**[Fluid]**
Removes a handler added with `AddHandleCommand`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `callback` | `function` |  |

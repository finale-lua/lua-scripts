# FCXCustomLuaWindow

*Extends `FCMCustomLuaWindow`*

Summary of modifications:
- DebugClose is enabled by default

## Functions

- [Init(self)](#init)
- [CreateStatic(self, x, y, control_name)](#createstatic)
- [CreateUpDown(self, x, y, control_name)](#createupdown)

### Init

```lua
fcxcustomluawindow.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L28)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |

### CreateStatic

```lua
fcxcustomluawindow.CreateStatic(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L44)

**[Override]**
Creates an `FCXCtrlStatic` control.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlStatic` |  |

### CreateUpDown

```lua
fcxcustomluawindow.CreateUpDown(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L65)

**[Override]**
Creates an `FCXCtrlUpDown` control.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlUpDown` |  |

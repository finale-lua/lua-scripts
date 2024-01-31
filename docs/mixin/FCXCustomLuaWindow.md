# FCXCustomLuaWindow

*Extends `FCMCustomLuaWindow`*

## Summary of Modifications
- DebugClose is enabled by default

## Functions

- [Init(self)](#init)
- [CreateUpDown(self, x, y, control_name)](#createupdown)

### Init

```lua
fcxcustomluawindow.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCustomLuaWindow.lua#L24)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |

### CreateUpDown

```lua
fcxcustomluawindow.CreateUpDown(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCustomLuaWindow.lua#L42)

**[Override]**

Override Changes:
- Creates an `FCXCtrlUpDown` control.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlUpDown` |  |

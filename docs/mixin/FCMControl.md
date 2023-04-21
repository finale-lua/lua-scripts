# FCMControl

## Summary of Modifications
- Setters that accept `FCString` also accept a Lua `string` or `number`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
- Ported `GetParent` from PDK to allow the parent window to be accessed from a control.
- Added methods to allow handlers for the `Command` event to be set directly on the control.
- Added methods for storing and restoring control state, allowing controls to preserve their values across multiple script executions.

## Functions

- [Init(self)](#init)
- [GetParent(self)](#getparent)
- [RegisterParent(self, window)](#registerparent)
- [GetEnable(self)](#getenable)
- [SetEnable(self, enable)](#setenable)
- [GetVisible(self)](#getvisible)
- [SetVisible(self, visible)](#setvisible)
- [GetLeft(self)](#getleft)
- [SetLeft(self, left)](#setleft)
- [GetTop(self)](#gettop)
- [SetTop(self, top)](#settop)
- [GetHeight(self)](#getheight)
- [SetHeight(self, height)](#setheight)
- [GetWidth(self)](#getwidth)
- [SetWidth(self, width)](#setwidth)
- [GetText(self, str)](#gettext)
- [SetText(self, str)](#settext)
- [UseStoredState(self)](#usestoredstate)
- [StoreState(self)](#storestate)
- [RestoreState(self)](#restorestate)
- [AddHandleCommand(self, callback)](#addhandlecommand)
- [RemoveHandleCommand(self, callback)](#removehandlecommand)

### Init

```lua
fcmcontrol.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L31)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

### GetParent

```lua
fcmcontrol.GetParent(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L51)

**[PDK Port]**

Returns the control's parent window.

*Do not override or disable this method.*

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L67)

**[Fluid] [Internal]**

Used to register the parent window when the control is created.

*Do not disable this method.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `window` | `FCMCustomWindow` |  |

### GetEnable

```lua
fcmcontrol.GetEnable(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L343)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### SetEnable

```lua
fcmcontrol.SetEnable(self, enable)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L363)

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `enable` | `boolean` |  |

### GetVisible

```lua
fcmcontrol.GetVisible(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L344)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### SetVisible

```lua
fcmcontrol.SetVisible(self, visible)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L364)

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `visible` | `boolean` |  |

### GetLeft

```lua
fcmcontrol.GetLeft(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L345)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetLeft

```lua
fcmcontrol.SetLeft(self, left)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L365)

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `left` | `number` |  |

### GetTop

```lua
fcmcontrol.GetTop(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L346)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetTop

```lua
fcmcontrol.SetTop(self, top)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L366)

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `top` | `number` |  |

### GetHeight

```lua
fcmcontrol.GetHeight(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L347)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetHeight

```lua
fcmcontrol.SetHeight(self, height)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L367)

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `height` | `number` |  |

### GetWidth

```lua
fcmcontrol.GetWidth(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L348)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetWidth

```lua
fcmcontrol.SetWidth(self, width)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L368)

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `width` | `number` |  |

### GetText

```lua
fcmcontrol.GetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L267)

**[?Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `str` (optional) | `FCString` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` | Returned if `str` is omitted. |

### SetText

```lua
fcmcontrol.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L300)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `str` | `FCString \| string \| number` |  |

### UseStoredState

```lua
fcmcontrol.UseStoredState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L324)

**[Internal]**

Checks if this control should use its stored state instead of the live state from the control.

*Do not override or disable this method.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### StoreState

```lua
fcmcontrol.StoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L340)

**[Fluid] [Internal]**

Stores the control's current state.

*Do not disable this method. Override as needed but call the parent first.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

### RestoreState

```lua
fcmcontrol.RestoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L362)

**[Fluid] [Internal]**

Restores the control's stored state.

*Do not disable this method. Override as needed but call the parent first.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |

### AddHandleCommand

```lua
fcmcontrol.AddHandleCommand(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L391)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMControl.lua#L396)

**[Fluid]**

Removes a handler added with `AddHandleCommand`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `callback` | `function` |  |

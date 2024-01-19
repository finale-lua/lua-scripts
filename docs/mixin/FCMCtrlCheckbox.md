# FCMCtrlCheckbox

## Summary of Modifications
- Added `CheckChange` custom control event.

## Functions

- [Init(self)](#init)
- [GetCheck(self)](#getcheck)
- [SetCheck(self, checked)](#setcheck)
- [HandleCheckChange(control, last_check)](#handlecheckchange)
- [AddHandleCheckChange(self, callback)](#addhandlecheckchange)
- [RemoveHandleCheckChange(self, callback)](#removehandlecheckchange)
- [StoreState(self)](#storestate)
- [RestoreState(self)](#restorestate)

### Init

```lua
fcmctrlcheckbox.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlCheckbox.lua#L26)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlCheckbox` |  |

### GetCheck

```lua
fcmctrlcheckbox.GetCheck(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlCheckbox.lua#L47)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlCheckbox` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetCheck

```lua
fcmctrlcheckbox.SetCheck(self, checked)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlCheckbox.lua#L66)

**[Fluid] [Override]**

Override Changes:
- Ensures that `CheckChange` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlCheckbox` |  |
| `checked` | `number` |  |

### HandleCheckChange

```lua
fcmctrlcheckbox.HandleCheckChange(control, last_check)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlCheckbox.lua#L88)

**[Callback Template]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCMCtrlCheckbox` | The control that was changed. |
| `last_check` | `string` | The previous value of the control's check state.. |

### AddHandleCheckChange

```lua
fcmctrlcheckbox.AddHandleCheckChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlCheckbox.lua#L107)

**[Fluid]**

Adds a handler for when the value of the control's check state changes.
The event will fire when:
- The window is created (if the check state is not `0`)
- The control is checked/unchecked by the user
- The control's check state is changed programmatically (if the check state is changed within a handler, that *same* handler will not be called again for that change.)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlCheckbox` |  |
| `callback` | `function` | See `HandleCheckChange` for callback signature. |

### RemoveHandleCheckChange

```lua
fcmctrlcheckbox.RemoveHandleCheckChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlCheckbox.lua#L112)

**[Fluid]**

Removes a handler added with `AddHandleCheckChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlCheckbox` |  |
| `callback` | `function` |  |

### StoreState

```lua
fcmctrlcheckbox.StoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlCheckbox.lua#L134)

**[Fluid] [Internal] [Override]**

Override Changes:
- Stores `FCMCtrlCheckbox`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlCheckbox` |  |

### RestoreState

```lua
fcmctrlcheckbox.RestoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlCheckbox.lua#L151)

**[Fluid] [Internal] [Override]**

Override Changes:
- Restores `FCMCtrlCheckbox`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlCheckbox` |  |

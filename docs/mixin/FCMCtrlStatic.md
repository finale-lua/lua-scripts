# FCMCtrlStatic

Summary of modifications:
- Added hooks for control state restoration
- SetTextColor updates visible color immediately if window is showing

## Functions

- [Init(self)](#init)
- [SetTextColor(self, red, green, blue)](#settextcolor)
- [RestoreState(self)](#restorestate)

### Init

```lua
fcmctrlstatic.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlStatic.lua#L25)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

### SetTextColor

```lua
fcmctrlstatic.SetTextColor(self, red, green, blue)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlStatic.lua#L41)

**[Fluid] [Override]**
Displays the new text color immediately.
Also hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |
| `red` | `number` |  |
| `green` | `number` |  |
| `blue` | `number` |  |

### RestoreState

```lua
fcmctrlstatic.RestoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlStatic.lua#L66)

**[Fluid] [Internal]**
Restores the control's stored state.
Do not disable this method. Override as needed but call the parent first.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

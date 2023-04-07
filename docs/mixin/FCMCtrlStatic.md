# FCMCtrlStatic

## Summary of Modifications
- Added hooks for control state preservation.
- SetTextColor updates visible color immediately if window is showing.

## Functions

- [Init(self)](#init)
- [SetTextColor(self, red, green, blue)](#settextcolor)
- [RestoreState(self)](#restorestate)

### Init

```lua
fcmctrlstatic.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlStatic.lua#L27)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

### SetTextColor

```lua
fcmctrlstatic.SetTextColor(self, red, green, blue)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlStatic.lua#L49)

**[Fluid] [Override]**

Override Changes:
- Displays the new text color immediately.
- Hooks into control state preservation.

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlStatic.lua#L77)

**[Fluid] [Internal] [Override]**

Override Changes:
- Restores `FCMCtrlStatic`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlStatic` |  |

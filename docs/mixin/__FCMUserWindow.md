# __FCMUserWindow

## Summary of Modifications
- Setters that accept `FCString` will also accept a Lua `string`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.

## Functions

- [GetTitle(self, title)](#gettitle)
- [SetTitle(self, title)](#settitle)
- [SetTitleLocalized(self, title)](#settitlelocalized)
- [CreateChildUI(self)](#createchildui)

### GetTitle

```lua
__fcmuserwindow.GetTitle(self, title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/__FCMUserWindow.lua#L30)

**[?Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `__FCMUserWindow` |  |
| `title` (optional) | `FCString` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` | Returned if `title` is omitted. |

### SetTitle

```lua
__fcmuserwindow.SetTitle(self, title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/__FCMUserWindow.lua#L57)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `__FCMUserWindow` |  |
| `title` | `FCString \| string \| number` |  |

### SetTitleLocalized

```lua
__fcmuserwindow.SetTitleLocalized(self, title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/__FCMUserWindow.lua#L73)

Localized version of `SetTitle`.

**[Fluid] [Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `__FCMUserWindow` |  |
| `title` | `FCString \| string \| number` |  |

### CreateChildUI

```lua
__fcmuserwindow.CreateChildUI(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/__FCMUserWindow.lua#L86)

**[Override]**

Override Changes:
- Returns original `CreateChildUI` if the method exists, otherwise it returns `mixin.UI()`

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `__FCMUserWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMUI` |  |

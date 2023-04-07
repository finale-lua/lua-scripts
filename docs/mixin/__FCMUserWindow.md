# __FCMUserWindow

## Summary of Modifications
- Setters that accept `FCString` will also accept a Lua `string`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.

## Functions

- [GetTitle(self, title)](#gettitle)
- [SetTitle(self, title)](#settitle)

### GetTitle

```lua
__fcmuserwindow.GetTitle(self, title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/__FCMUserWindow.lua#L30)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/__FCMUserWindow.lua#L57)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `__FCMUserWindow` |  |
| `title` | `FCString \| string \| number` |  |

# FCMTreeNode

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned.

## Functions

- [GetText(self, str)](#gettext)
- [SetText(self, str)](#settext)

### GetText

```lua
fcmtreenode.GetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMTreeNode.lua#L27)

**[Override]**
Returns a Lua `string` and makes passing an `FCString` optional.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTreeNode` |  |
| `str` (optional) | `FCString` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### SetText

```lua
fcmtreenode.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMTreeNode.lua#L48)

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTreeNode` |  |
| `str` | `FCString\|string\|number` |  |

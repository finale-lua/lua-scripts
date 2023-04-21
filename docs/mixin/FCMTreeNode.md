# FCMTreeNode

## Summary of Modifications
- Setters that accept `FCString` also accept a Lua `string` or `number`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.

## Functions

- [GetText(self, str)](#gettext)
- [SetText(self, str)](#settext)

### GetText

```lua
fcmtreenode.GetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTreeNode.lua#L30)

**[?Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTreeNode` |  |
| `str` (optional) | `FCString` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` | Returned if `str` is omitted. |

### SetText

```lua
fcmtreenode.SetText(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTreeNode.lua#L57)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTreeNode` |  |
| `str` | `FCString \| string \| number` |  |

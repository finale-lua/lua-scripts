# FCMCtrlTree

Summary of modifications:
- Methods that accept `FCString` now also accept Lua `string` and `number`.

## Functions

- [AddNode(self, parentnode, iscontainer, text)](#addnode)

### AddNode

```lua
fcmctrltree.AddNode(self, parentnode, iscontainer, text)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlTree.lua#L27)

**[Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlTree` |  |
| `parentnode` | `FCTreeNode\|nil` |  |
| `iscontainer` | `boolean` |  |
| `text` | `FCString\|string\|number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMTreeNode` |  |

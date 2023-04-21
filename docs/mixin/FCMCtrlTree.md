# FCMCtrlTree

## Summary of Modifications
- Methods that accept `FCString` will also accept Lua `string` or `number`.

## Functions

- [AddNode(self, parentnode, iscontainer, text)](#addnode)

### AddNode

```lua
fcmctrltree.AddNode(self, parentnode, iscontainer, text)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlTree.lua#L31)

**[Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlTree` |  |
| `parentnode` | `FCTreeNode \| nil` |  |
| `iscontainer` | `boolean` |  |
| `text` | `FCString \| string \| number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMTreeNode` |  |

# FCMCtrlTree

Summary of modifications:
- Methods that accept `FCString` now also accept Lua `string` and `number`.

## Functions

- [AddNode(self, parentnode, iscontainer, text)](#addnode)

### AddNode

```lua
fcmctrltree.AddNode(self, parentnode, iscontainer, text)
```

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

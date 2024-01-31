# FCMNoteEntryCell

Summary of modifications:
- Attach collection to child object before returning

## Functions

- [GetItemAt(self, index)](#getitemat)

### GetItemAt

```lua
fcmnoteentrycell.GetItemAt(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMNoteEntryCell.lua#L28)

**[Override]**

Override Changes:
- Registers this collection as the parent of the item before returning it.
This allows the item to be used outside of a `mixin.eachentry` loop.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMNoteEntryCell` |  |
| `index` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMNoteEntry \\| nil` |  |

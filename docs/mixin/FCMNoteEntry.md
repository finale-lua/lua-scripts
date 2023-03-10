# FCMNoteEntry

Summary of modifications:
- Added methods to keep parent collection in scope

## Functions

- [Init(self)](#init)
- [RegisterParent(self, parent)](#registerparent)
- [GetParent(self)](#getparent)

### Init

```lua
fcmnoteentry.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMNoteEntry.lua#L22)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMNoteEntry` |  |

### RegisterParent

```lua
fcmnoteentry.RegisterParent(self, parent)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMNoteEntry.lua#L35)

**[Fluid]**
Registers the collection to which this object belongs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMNoteEntry` |  |
| `parent` | `FCNoteEntryCell` |  |

### GetParent

```lua
fcmnoteentry.GetParent(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMNoteEntry.lua#L51)

Returns the collection to which this object belongs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMNoteEntry` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMNoteEntryCell\\|nil` |  |

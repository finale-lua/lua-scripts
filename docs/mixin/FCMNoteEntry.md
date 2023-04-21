# FCMNoteEntry

## Summary of Modifications
- Added methods to keep parent collection in scope.

## Functions

- [Init(self)](#init)
- [RegisterParent(self, parent)](#registerparent)
- [GetParent(self)](#getparent)

### Init

```lua
fcmnoteentry.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMNoteEntry.lua#L23)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMNoteEntry` |  |

### RegisterParent

```lua
fcmnoteentry.RegisterParent(self, parent)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMNoteEntry.lua#L41)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMNoteEntry.lua#L57)

Returns the collection to which this object belongs.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMNoteEntry` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMNoteEntryCell \\| nil` |  |

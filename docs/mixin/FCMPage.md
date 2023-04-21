# FCMPage

## Summary of Modifications
- Added methods for getting and setting the page size by its name according to the `page_size` library.
- Added `IsBlank` method.

## Functions

- [GetSize(self)](#getsize)
- [SetSize(self, size)](#setsize)
- [IsBlank(self)](#isblank)

### GetSize

```lua
fcmpage.GetSize(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMPage.lua#L25)

Returns the size of the page.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMPage` |  |

| Return type | Description |
| ----------- | ----------- |
| `string \\| nil` | The page size or `nil` if there is no defined size that matches the dimensions of this page. |

### SetSize

```lua
fcmpage.SetSize(self, size)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMPage.lua#L38)

**[Fluid]**
Sets the dimensions of this page to match the given size. Page orientation will be preserved.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMPage` |  |
| `size` | `string` | A defined page size. |

### IsBlank

```lua
fcmpage.IsBlank(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMPage.lua#L53)

Checks if this is a blank page (ie it contains no systems).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMPage` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if this page is blank |

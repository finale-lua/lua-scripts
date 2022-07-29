# FCMPage

Summary of modifications:
- Added methods for getting and setting the page size by its name according to the `page_size` library.
- Added method for checking if the page is blank.

## Functions

- [GetSize(self)](#getsize)
- [SetSize(self, size)](#setsize)
- [IsBlank(self)](#isblank)

### GetSize

```lua
fcmpage.GetSize(self)
```

Returns the size of the page.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMPage` |  |

| Return type | Description |
| ----------- | ----------- |
| `string\\|nil` | The page size or `nil` if there is no defined size that matches the dimensions of this page. |

### SetSize

```lua
fcmpage.SetSize(self, size)
```

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

Checks if this is a blank page (ie it contains no systems).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMPage` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if this is page is blank |

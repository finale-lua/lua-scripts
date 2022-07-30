# Page Size

A library for determining page sizes.

## Functions

- [get_dimensions(size)](#get_dimensions)
- [is_size(size)](#is_size)
- [get_size(width, height)](#get_size)
- [get_page_size(page)](#get_page_size)
- [set_page_size(page, size)](#set_page_size)
- [pairs()](#pairs)

### get_dimensions

```lua
page_size.get_dimensions(size)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/page_size.lua#L41)

Returns the dimensions of the requested page size. Dimensions are in portrait.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `size` | `string` | The page size. |

| Return type | Description |
| ----------- | ----------- |
| `table` | Has keys `width` and `height` which contain the dimensions in EVPUs. |

### is_size

```lua
page_size.is_size(size)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/page_size.lua#L53)

Checks if the given size is defined.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `size` | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if defined, `false` if not |

### get_size

```lua
page_size.get_size(width, height)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/page_size.lua#L66)

Determines the page size based on the given dimensions.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `width` | `number` | Page width in EVPUs. |
| `height` | `number` | Page height in EVPUs. |

| Return type | Description |
| ----------- | ----------- |
| `string\\|nil` | Page size, or `nil` if no match. |

### get_page_size

```lua
page_size.get_page_size(page)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/page_size.lua#L91)

Determines the page size of an `FCPage`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `page` | `FCPage` |  |

| Return type | Description |
| ----------- | ----------- |
| `string\\|nil` | Page size, or `nil` if no match. |

### set_page_size

```lua
page_size.set_page_size(page, size)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/page_size.lua#L103)

Sets the dimensions of an `FCPage` to the given size. The existing page orientation will be preserved.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `page` | `FCPage` |  |
| `size` | `string` |  |

### pairs

```lua
page_size.pairs()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/page_size.lua#L127)

Return an alphabetical order iterator that yields the following pairs:
`(string) size`
`(table) dimensions` => has keys `width` and `height` which contain the dimensions in EVPUs

| Return type | Description |
| ----------- | ----------- |
| `function` |  |

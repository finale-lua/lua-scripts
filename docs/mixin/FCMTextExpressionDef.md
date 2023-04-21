# FCMTextExpressionDef

## Summary of Modifications
- Setters that accept `FCString` also accept a Lua string.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
- Methods that returned a boolean to indicate success/failure now throw an error instead.

## Functions

- [SaveNewTextBlock(self, str)](#savenewtextblock)
- [AssignToCategory(self, cat_def)](#assigntocategory)
- [SetUseCategoryPos(self, enable)](#setusecategorypos)
- [SetUseCategoryFont(self, enable)](#setusecategoryfont)
- [MakeRehearsalMark(self, str, measure)](#makerehearsalmark)
- [SaveTextString(self, str)](#savetextstring)
- [DeleteTextBlock(self)](#deletetextblock)
- [SetDescription(self, str)](#setdescription)
- [GetDescription(self, str)](#getdescription)
- [DeepSaveAs(self, item_num)](#deepsaveas)
- [DeepDeleteData(self)](#deepdeletedata)

### SaveNewTextBlock

```lua
fcmtextexpressiondef.SaveNewTextBlock(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L36)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.
- Accepts Lua `string` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |
| `str` | `string \| FCString` | The initializing string |

### AssignToCategory

```lua
fcmtextexpressiondef.AssignToCategory(self, cat_def)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L55)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |
| `cat_def` | `FCCategoryDef` | the parent Category Definition |

### SetUseCategoryPos

```lua
fcmtextexpressiondef.SetUseCategoryPos(self, enable)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L73)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |
| `enable` | `boolean` |  |

### SetUseCategoryFont

```lua
fcmtextexpressiondef.SetUseCategoryFont(self, enable)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L91)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |
| `enable` | `boolean` |  |

### MakeRehearsalMark

```lua
fcmtextexpressiondef.MakeRehearsalMark(self, str, measure)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L112)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |
| `str` (optional) | `FCString` |  |
| `measure` | `integer` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` | If `FCString` is omitted. |

### SaveTextString

```lua
fcmtextexpressiondef.SaveTextString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L146)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.
- Accepts Lua `string` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |
| `str` | `string \| FCString` | The initializing string |

### DeleteTextBlock

```lua
fcmtextexpressiondef.DeleteTextBlock(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L165)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |

### SetDescription

```lua
fcmtextexpressiondef.SetDescription(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L182)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |
| `str` | `string \| FCString` | The initializing string |

### GetDescription

```lua
fcmtextexpressiondef.GetDescription(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L202)

**[?Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |
| `str` (optional) | `FCString` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` | Returned if `str` is omitted. |

### DeepSaveAs

```lua
fcmtextexpressiondef.DeepSaveAs(self, item_num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L226)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |
| `item_num` | `integer` |  |

### DeepDeleteData

```lua
fcmtextexpressiondef.DeepDeleteData(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMTextExpressionDef.lua#L243)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMTextExpressionDef` |  |

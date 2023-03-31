# Expression

## Functions

- [get_music_region(exp_assign)](#get_music_region)
- [get_associated_entry(exp_assign)](#get_associated_entry)
- [calc_handle_offset_for_smart_shape(exp_assign)](#calc_handle_offset_for_smart_shape)
- [calc_text_width(expression_def, expand_tags)](#calc_text_width)
- [is_for_current_part(exp_assign, current_part)](#is_for_current_part)
- [is_dynamic(exp)](#is_dynamic)
- [resync_expressions_for_category(category_id)](#resync_expressions_for_category)
- [resync_to_category(expression_def)](#resync_to_category)

### get_music_region

```lua
expression.get_music_region(exp_assign)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/expression.lua#L18)

Returns a music region corresponding to the input expression assignment.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `exp_assign` | `FCExpression` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMusicRegion` |  |

### get_associated_entry

```lua
expression.get_associated_entry(exp_assign)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/expression.lua#L41)

Returns the note entry associated with the input expression assignment, if any.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `exp_assign` | `FCExpression` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCNoteEntry` | associated entry or nil if none |

### calc_handle_offset_for_smart_shape

```lua
expression.calc_handle_offset_for_smart_shape(exp_assign)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/expression.lua#L64)

Returns the horizontal EVPU offset for a smart shape endpoint to align exactly with the handle of the input expression, given that they both have the same EDU position.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `exp_assign` | `FCExpression` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### calc_text_width

```lua
expression.calc_text_width(expression_def, expand_tags)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/expression.lua#L101)

Returns the text advance width of the input expression definition.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `expression_def` | `FCTextExpessionDef` |  |
| `expand_tags` (optional) | `boolean` | defaults to false, currently only supports `^value()` |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### is_for_current_part

```lua
expression.is_for_current_part(exp_assign, current_part)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/expression.lua#L120)

Returns true if the expression assignment is assigned to the current part or score.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `exp_assign` | `FCExpression` |  |
| `current_part` (optional) | `FCPart` | defaults to current part, but it can be supplied if the caller has already calculated it. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### is_dynamic

```lua
expression.is_dynamic(exp)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/expression.lua#L138)

Returns true if the expression appears to be a dynamic.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `exp` | `FCExpression` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### resync_expressions_for_category

```lua
expression.resync_expressions_for_category(category_id)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/expression.lua#L165)

Updates the fonts and positioning of all expression definitions linked to a category after making changes to the category.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `category_id` | `number` |  |

### resync_to_category

```lua
expression.resync_to_category(expression_def)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/expression.lua#L181)

Updates the fonts and positioning of an expression definition to match its category after making changes to the category.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `expression_def` | `FCTextExpessionDef` |  |

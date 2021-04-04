# Expression

- [calc_text_width](#calc_text_width)
- [is_for_current_part](#is_for_current_part)

## calc_text_width

```lua
expression.calc_text_width(expression_def, expand_tags)
```

| Input | Type | Description |
| --- | --- | --- |
| `expression_def` | `FCExpessionDef` |  |
| `expand_tags` (optional) | `boolean` | defaults to false, currently only suppoerts `^value()` |

## is_for_current_part

```lua
expression.is_for_current_part(exp_assign, current_part)
```

| Input | Type | Description |
| --- | --- | --- |
| `exp_assign` | `unknown` |  |
| `current_part` (optional) | `unknown` |  |
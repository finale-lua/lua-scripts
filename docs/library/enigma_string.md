# Enigma String

## Functions

- [trim_first_enigma_font_tags(string)](#trim_first_enigma_font_tags)
- [change_first_string_font(string, font_info)](#change_first_string_font)
- [change_first_text_block_font(text_block, font_info)](#change_first_text_block_font)
- [change_string_font(string, font_info)](#change_string_font)
- [change_text_block_font(text_block, font_info)](#change_text_block_font)
- [remove_inserts(fcstring, replace_with_generic)](#remove_inserts)
- [expand_value_tag(fcstring, value_num)](#expand_value_tag)
- [calc_text_advance_width(inp_string)](#calc_text_advance_width)

### trim_first_enigma_font_tags

```lua
enigma_string.trim_first_enigma_font_tags(string)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/enigma_string.lua.lua#L32)

Trims the first font tags and returns the result as an instance of FCFontInfo.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `string` | `FCString` | this is both the input and the trimmed output result |

| Return type | Description |
| ----------- | ----------- |
| `FCFontInfo \\| nil` | the first font info that was stripped or `nil` if none |

### change_first_string_font

```lua
enigma_string.change_first_string_font(string, font_info)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/enigma_string.lua.lua#L65)

Replaces the first enigma font tags of the input enigma string.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `string` | `FCString` | this is both the input and the modified output result |
| `font_info` | `FCFontInfo` | replacement font info |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | true if success |

### change_first_text_block_font

```lua
enigma_string.change_first_text_block_font(text_block, font_info)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/enigma_string.lua.lua#L85)

Replaces the first enigma font tags of input text block.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `text_block` | `FCTextBlock` | this is both the input and the modified output result |
| `font_info` | `FCFontInfo` | replacement font info |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | true if success |

### change_string_font

```lua
enigma_string.change_string_font(string, font_info)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/enigma_string.lua.lua#L105)

Changes the entire enigma string to have the input font info.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `string` | `FCString` | this is both the input and the modified output result |
| `font_info` | `FCFontInfo` | replacement font info |

### change_text_block_font

```lua
enigma_string.change_text_block_font(text_block, font_info)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/enigma_string.lua.lua#L120)

Changes the entire text block to have the input font info.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `text_block` | `FCTextBlock` | this is both the input and the modified output result |
| `font_info` | `FCFontInfo` | replacement font info |

### remove_inserts

```lua
enigma_string.remove_inserts(fcstring, replace_with_generic)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/enigma_string.lua.lua#L134)

Removes text inserts other than font commands and replaces them with

| Input | Type | Description |
| ----- | ---- | ----------- |
| `fcstring` | `FCString` | this is both the input and the modified output result |
| `replace_with_generic` | `boolean` | if true, replace the insert with the text of the enigma command |

### expand_value_tag

```lua
enigma_string.expand_value_tag(fcstring, value_num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/enigma_string.lua.lua#L171)

Expands the value tag to the input value_num.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `fcstring` | `FCString` | this is both the input and the modified output result |
| `value_num` | `number` | the value number to replace the tag with |

### calc_text_advance_width

```lua
enigma_string.calc_text_advance_width(inp_string)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/enigma_string.lua.lua#L184)

Calculates the advance width of the input string taking into account all font and style changes within the string.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `inp_string` | `FCString` | this is an input-only value and is not modified |

| Return type | Description |
| ----------- | ----------- |
| `number` | the width of the string |

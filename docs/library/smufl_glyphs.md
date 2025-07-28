# SMuFL Glyphs

Provides immediate Lua access to the glyph names in the SMuFL `glyphnames.json` and
`glyphnamesFinale.json files.
The `glyphs` and `by_codepoint` tables were programmatically generated from them.

## Functions

- [get_glyph_info(codepoint_or_name, font_info_or_name)](#get_glyph_info)
- [iterate_glyphs()](#iterate_glyphs)

### get_glyph_info

```lua
smufl_glyphs.get_glyph_info(codepoint_or_name, font_info_or_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/smufl_glyphs.lua#L7295)

Returns the SMuFL glyph name and a new table containing the `codepoint` and its `description`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `codepoint_or_name` | `string\|number` | the name or codepoint for a SMuFL glyph |
| `font_info_or_name` (optional) | `string` | or (font_info) the SMuFL font to search for optional glyphs |

| Return type | Description |
| ----------- | ----------- |
| `string` | The glyph name |
| `table` | The glyph information |

### iterate_glyphs

```lua
smufl_glyphs.iterate_glyphs()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/smufl_glyphs.lua#L7341)

Returns an iterator over the standard SMuFL glyphs as defined in glyphnames.json.

Each iteration returns:
1. The glyph name (string)
2. A new table with `codepoint` and `description`

| Return type | Description |
| ----------- | ----------- |
| `function` | An iterator over (string, table) |

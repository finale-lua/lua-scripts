# Enigma String

This implements a hypothetical FCString::TrimFirstEnigmaFontTags() function that would
preferably be in the PDK Framework. Trimming only first allows us to preserve
style changes within the rest of the string, such as changes from plain to
italic. Ultimately this seems more useful than trimming out all font tags.
If the PDK Framework is ever changed, it might be even better to create replace font
functions that can replace only font, only size, only style, or all three together.

- [trim_first_enigma_font_tags](#trim_first_enigma_font_tags)

## trim_first_enigma_font_tags

```lua
enigma_string.trim_first_enigma_font_tags(string)
```

| Input | Type | Description |
| --- | --- | --- |
| `string` | `string` |  |

| Output type | Description |
| --- | --- |
| `string \| nill` | the first font info that was stripped or nil if none |
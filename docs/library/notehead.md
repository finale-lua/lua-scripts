# Notehead

User-created config file "notehead.config.txt" will overwrite any of the values in this file.
Store the file in a folder called "script_settings" in the same location as the calling script.

To change the shape (glyph) of a note, add to the config file a line of the form:
    diamond.quarter.glyph = 0xea07 -- (SMuFL character)
        OR
    diamond.quarter.glyph = 173 -- (non-SMuFL character)

To change the size of a specific shape add the line:
    diamond.half.size = 120
And for offset (horizontal - left/right):
    diamond.whole.offset = -5 -- (offset 5 EVPU to the left)

Note that many of the shapes assumed in this file don't exist in Maestro but only in proper SMuFL fonts.

version cv0.57 2023/02/12

## Functions

- [change_shape(note, shape)](#change_shape)

### change_shape

```lua
notehead.change_shape(note, shape)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/notehead.lua#L215)

Changes the given notehead to a specified notehead descriptor string, or specified numeric character.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `note` | `FCNote` |  |
| `shape` | `lua string` | or (number) |

| Return type | Description |
| ----------- | ----------- |
| `FCNoteheadMod` | the new notehead mod record created |

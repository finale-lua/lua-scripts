# Library

This repository includes several pre-made Lua functions that you can use in your code. That way, you can write better scripts, faster.

```lua
-- use once at top of script file, tells JW Lua where the library modules are saved
-- These first few lines will eventually be phased out
local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"

-- load each library module you'll use
local library = require("library.file_name") -- no path, no ".lua"

-- run a library function
library.function_name()
```

Subsequent pages detail the exact details of the library. If you wish to contribute to the standard library, create a pull request.

## Documenting library functions

The docs for the individual functions are automatically created from the multiline comments you use in your code. For instance…

```lua
--[[
% stem_sign(entry)

This is useful for many x,y positioning fields in Finale that mirror +/-
based on stem direction.

@ entry (FCNoteEntry)
: (number) 1 if upstem, -1 otherwise
]]
```

…Produces the following documentation…

---

### stem_sign

```lua
note_entry.stem_sign(entry)
```

This is useful for many x,y positioning fields in Finale that mirror +/-
based on stem direction.

| Input | Type | Description |
| --- | --- | --- |
| `entry` | `FCNoteEntry` |  |

| Output type | Description |
| --- | --- |
| `number` | 1 if upstem, -1 otherwise |

---

As you can see, the comments are very easy to write and produce readable, searchable documentation. Clearly documenting any functions you write is almost as valuable as the code itself.

You can find a complete list of syntax you can use for documentation here: [https://github.com/Nick-Mazuk/lua-docs-generator/blob/main/documentation.md](https://github.com/Nick-Mazuk/lua-docs-generator/blob/main/documentation.md)

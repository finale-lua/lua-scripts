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
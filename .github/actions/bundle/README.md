# Lua bundler

This action bundles Lua scripts and their dependencies so a script can be distributed and downloaded as a single file.

## Dev setup

This action is written in TypeScript and uses pnpm to install 3rd-party dependencies. To get download pnpm, view the instructions on the [pnpm website](https://pnpm.io/installation).

```bash
pnpm i # installs dependencies
pnpm dev # runs the bundler locally
pnpm test # runs the unit tests
pnpm test:watch # reruns the unit tests whenever a file in this action changes
```

## How bundling works

To understand how this bundler bundles Lua files, we first need to understand how file importing works in Lua. In Lua, files are imported using the `require` function.

```lua
local my_library = require("my_library")
```

Normally, this function will then read the file system for `./my_library.lua` and get its contents. However, if we want to bundle a script into a single file, this won't work for us. However, since the `require` function is a function, we can overwrite it.

This means we can inline all the file dependencies, then overload the `require` function to point to the inlined version of each dependency.

Here's what the overwritten require function looks like:

```lua
local __imports = {}

function require(name)
    return __imports[name]()
end
```

> Note: each item in the `__imports` table must be a function. Why? We'll get to that.

Then, for each imported file, we can just wrap it into a function and store it in the __imports table.

```lua
-- my_library.lua

local library = {}

function library.hello()
    print("hello world")
end

return library

-- main.lua
_imports["my_library"] = function()
    local library = {}

    function library.hello(name)
        print("Hello " .. name)
    end

    return library
end
```

Since an imported file must return anyways to export a value, we can literally wrap the entire file inside the function and things still work. Plus, the function provides automatic variable scoping which eliminates any potential naming conflicts. This is why every item in the `__imports` table must be a function.

Finally, we can "import" files using the `require` function without changing any syntax:

```lua
local my_library = require("my_library")
my_library.hello("Finale users!") -- prints "Hello Finale users!"
```

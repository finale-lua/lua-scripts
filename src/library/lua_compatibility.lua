--  Author: Edward Koltun
--  Date: April 9, 2023
--[[
$module Lua Compatibility

This library assists in providing compatibility across Lua versions by polyfilling standard library functions in older Lua versions.

The following functions are polyfilled:
```
Function         | Lua Versions Polyfilled
-------------------------------------------
math.tointeger   | < 5.3
math.type        | < 5 3
```
]] --

if not math.type then
    math.type = function(value)
        if type(value) == "number" then
            local _, fractional = math.modf(value)
            return fractional == 0 and "integer" or "float"
        end

        return nil
    end
end

if not math.tointeger then
    math.tointeger = function(value)
        return type(value) == "number" and math.floor(value) or nil
    end
end

return true

# Lua Compatibility

This library assists in providing compatibility across Lua versions by polyfilling standard library functions in older Lua versions.

The following functions are polyfilled:
```
Function         | Lua Versions Polyfilled
-------------------------------------------
math.tointeger   | < 5.3
math.type        | < 5 3
```

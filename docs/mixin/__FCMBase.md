# __FCMBase

## Summary of Modifications
- Add method _FallbackCall to gracefully allow skipping missing methods in earlier Lua versions

## Functions

- [_FallbackCall(self, method_name, fallback_value)](#_fallbackcall)

### _FallbackCall

```lua
__fcmbase._FallbackCall(self, method_name, fallback_value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/__FCMBase.lua#L29)

Checks the existence of a class method before calling it. If the method exists, it returns
as expected. If the method does not exist, it returns the fallback_value. This function allows
a script to call a method that does not exist in earlier versions of Lua (specifically, in JW Lua)
and get a default return value in that case.

@ additional_parameters (...) The additional parameters of the method.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `userdata` | The class instance on which to call the method. |
| `method_name` | `string` | The name of the method to return. |
| `fallback_value` | `any` | The value that will be returned if the method does not exist. If this value is `nil`, the function returns `self`. |

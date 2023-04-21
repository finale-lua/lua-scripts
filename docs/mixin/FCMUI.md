# FCMUI

## Summary of Modifications
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.

## Functions

- [GetDecimalSeparator(self, str)](#getdecimalseparator)

### GetDecimalSeparator

```lua
fcmui.GetDecimalSeparator(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/RGP/add-hashes-to-deploy-yml/src/mixin/FCMUI.lua#L29)

**[?Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMUI` |  |
| `str` (optional) | `FCString` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

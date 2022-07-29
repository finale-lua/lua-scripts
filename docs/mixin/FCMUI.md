# FCMUI

Summary of modifications:
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned.

## Functions

- [GetDecimalSeparator(self, str)](#getdecimalseparator)

### GetDecimalSeparator

```lua
fcmui.GetDecimalSeparator(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMUI.lua#L25)

**[Override]**
Returns a Lua `string` and makes passing an `FCString` optional.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMUI` |  |
| `str` (optional) | `FCString` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

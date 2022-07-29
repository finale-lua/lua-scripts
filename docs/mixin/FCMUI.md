# FCMUI

Summary of modifications:
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned.

## Functions

- [GetDecimalSeparator(self, str)](#getdecimalseparator)

### GetDecimalSeparator

```lua
fcmui.GetDecimalSeparator(self, str)
```

**[Override]**
Returns a Lua `string` and makes passing an `FCString` optional.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMUI` |  |
| `str` (optional) | `FCString` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

# FCMUI

## Summary of Modifications
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.

## Functions

- [GetDecimalSeparator(self, str)](#getdecimalseparator)
- [GetUserLocaleName(self, str)](#getuserlocalename)
- [AlertErrorLocalized(self, message_key, title_key)](#alerterrorlocalized)

### GetDecimalSeparator

```lua
fcmui.GetDecimalSeparator(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMUI.lua#L29)

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

### GetUserLocaleName

```lua
fcmui.GetUserLocaleName(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMUI.lua#L57)

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

### AlertErrorLocalized

```lua
fcmui.AlertErrorLocalized(self, message_key, title_key)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMUI.lua#L84)

**[Fluid]**

Displays a localized error message.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `message_key` | `string` | The key into the localization table. If there is no entry in the appropriate localization table, the key is the message. |
| `title_key` | `string` | The key into the localization table. If there is no entry in the appropriate localization table, the key is the title. |

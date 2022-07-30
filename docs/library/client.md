# Client

Get information about the current client. For the purposes of Finale Lua, the client is
the Finale application that's running on someones machine. Therefore, the client has
details about the user's setup, such as their Finale version, plugin version, and
operating system.

One of the main uses of using client details is to check its capabilities. As such,
the bulk of this library is helper functions to determine what the client supports.
All functions to check a client's capabilities should start with `client.supports_`.
These functions don't accept any arguments, and should always return a boolean.

## Functions

- [get_raw_finale_version(major, minor, build)](#get_raw_finale_version)
- [supports_smufl_fonts()](#supports_smufl_fonts)
- [supports_category_save_with_new_type()](#supports_category_save_with_new_type)
- [supports_finenv_query_invoked_modifier_keys()](#supports_finenv_query_invoked_modifier_keys)
- [supports_retained_state()](#supports_retained_state)
- [supports_modeless_dialog()](#supports_modeless_dialog)
- [supports_clef_changes()](#supports_clef_changes)
- [supports_custom_key_signatures()](#supports_custom_key_signatures)

### get_raw_finale_version

```lua
client.get_raw_finale_version(major, minor, build)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L27)

Returns a raw Finale version from major, minor, and (optional) build parameters. For 32-bit Finale
this is the internal major Finale version, not the year.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `major` | `number` | Major Finale version |
| `minor` | `number` | Minor Finale version |
| `build` (optional) | `number` | zero if omitted |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### supports_smufl_fonts

```lua
client.supports_smufl_fonts()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L42)

Returns true if the current client supports SMuFL fonts.

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### supports_category_save_with_new_type

```lua
client.supports_category_save_with_new_type()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L53)

Returns true if the current client supports FCCategory::SaveWithNewType().

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### supports_finenv_query_invoked_modifier_keys

```lua
client.supports_finenv_query_invoked_modifier_keys()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L64)

Returns true if the current client supports finenv.QueryInvokedModifierKeys().

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### supports_retained_state

```lua
client.supports_retained_state()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L75)

Returns true if the current client supports retaining state between runs.

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### supports_modeless_dialog

```lua
client.supports_modeless_dialog()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L86)

Returns true if the current client supports modeless dialogs.

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### supports_clef_changes

```lua
client.supports_clef_changes()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L97)

Returns true if the current client supports changing clefs.

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### supports_custom_key_signatures

```lua
client.supports_custom_key_signatures()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L108)

Returns true if the current client supports changing clefs.

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

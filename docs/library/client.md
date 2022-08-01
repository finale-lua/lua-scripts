# Client

Get information about the current client. For the purposes of Finale Lua, the client is
the Finale application that's running on someones machine. Therefore, the client has
details about the user's setup, such as their Finale version, plugin version, and
operating system.

One of the main uses of using client details is to check its capabilities. As such,
the bulk of this library is helper functions to determine what the client supports.

## Functions

- [get_raw_finale_version(major, minor, build)](#get_raw_finale_version)
- [supports(feature)](#supports)
- [assert_supports(feature)](#assert_supports)

### get_raw_finale_version

```lua
client.get_raw_finale_version(major, minor, build)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L92)

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

### supports

```lua
client.supports(feature)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L113)

Checks the client supports a given feature. Returns true if the client
supports the feature, false otherwise.

To assert the client must support a feature, use `client.assert_supports`.

For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `feature` | `string` | The feature the client should support. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### assert_supports

```lua
client.assert_supports(feature)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/client.lua#L134)

Asserts that the client supports a given feature. If the client doesn't
support the feature, this function will throw an friendly error then
exit the program.

To simply check if a client supports a feature, use `client.supports`.

For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `feature` | `string` | The feature the client should support. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

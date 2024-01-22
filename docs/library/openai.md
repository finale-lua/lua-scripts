# OpenAI

Provides access to the OpenAI apis. To use them successfully, you need an
OpenAI account with an API Key. The safest and easiest place to put your API Key is
in the RGP Lua prefix for the script or the System Prefix in RGP Lua. Whichever
you choose, add this line to your script:

```
openai_api_key = "<your secure api key>"
```

This library assumes that there is a global string variable `openai_api_key` that contains
your API key.

This code sends an https post message to OpenAI, so your `plugindef()` function must include

```
finaleplugin.ExecuteHttpsCalls = true
```

The `callback_or_timeout` parameters in each function determine if the call is synchronous or
asynchronous. If it is a function, then this is the callback for an asynchronous call.
If it is a number, it is the timout in seconds for a synchronous call.
For synchronous calls, the function returns a session variable you should keep
as long as the call is running. The callback function should have the following signature

```
function my_callback(success, response)
```

- success (boolean) indicates if the function succeeded
- response (string) the table representing the json response from OpenAI on success or an error message on fail

For asynchronous calls, the function returns the same two values directly.

If you are calling this from a running dialog box, it is recommended to use async
calls for better user responsiveness. If there is no dialog box, synchronous calls are
okay as long as the timeout is reasonably short.

## Functions

- [create_completion(model, prompt, temperature, callback_or_timeout)](#create_completion)
- [create_chat(model, messages, temperature, callback_or_timeout)](#create_chat)

### create_completion

```lua
openai.create_completion(model, prompt, temperature, callback_or_timeout)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/openai.lua#L103)

Sends a request to the OpenAI API to generate a completion for a given prompt.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `model` | `string` | The model to use, e.g., "gpt-3.5-turbo" |
| `prompt` | `string` | The prompt to send |
| `temperature` | `number` | See the OpenAI documentation for information about this value. A reasonable value is between 0.0 and 1.0. |
| `callback_or_timeout` (optional) | `function or number` | Defaults to 5.0. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | if synchronous call. See above for asynchronous. |
| `string` | if synchronous call. See above for asynchronous. |

### create_chat

```lua
openai.create_chat(model, messages, temperature, callback_or_timeout)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/openai.lua#L148)

Sends a request to the OpenAI API to generate a chat session. If you start a new chat session, the
chat session value is returned in the reply sting. You can then use that value to continue the same
same chat session. (See the OpenAI documentation for details.)

The messages table is an array of tables with two elements, "role" and "content". To start a fresh chat,
the table should be initialized as follows:

```
local messages =
{
    {role = "system", content = "You are a helpful assistant"},
    {role = "user", content = <your initial prompt>}
}
```

Thereafter, accumulate all subsequent request and response messages into this table. The entire chat is
sent to the API each time. The LLM does not maintain context. The role value for inserting each subsequent
response message into this table is included in the response message. However, normally
it is "assistant". Messages for requests from the user always take the role of "user".

There is a much more detailed explanation at the OpenAI documentation site for the API.

# chat_session (string) The chat session to continue, or nil for a new chat session.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `model` | `string` | The model to use, e.g., "gpt-3.5-turbo" |
| `messages` | `table` | See the description of this table above. |
| `temperature` | `number` | See the OpenAI documentation for information about this value. A reasonable value is between 0.0 and 1.0. |
| `callback_or_timeout` (optional) | `function or number` | Defaults to 5.0. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | if synchronous call. See above for asynchronous. |
| `string` | if synchronous call. See above for asynchronous. |

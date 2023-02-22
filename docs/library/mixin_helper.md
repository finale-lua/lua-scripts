# Mixin Helper

A library of helper functions to improve code reuse in mixins.

## Functions

- [disable_methods(props)](#disable_methods)
- [create_standard_control_event(name)](#create_standard_control_event)
- [create_custom_control_change_event()](#create_custom_control_change_event)
- [create_custom_window_change_event()](#create_custom_window_change_event)
- [to_fcstring(value, fcstr)](#to_fcstring)
- [boolean_to_error(object, method)](#boolean_to_error)

### disable_methods

```lua
mixin_helper.disable_methods(props)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/mixin_helper.lua#L25)

Disables mixin methods by setting an empty function that throws an error.

@ ... (string) The names of the methods to replace

| Input | Type | Description |
| ----- | ---- | ----------- |
| `props` | `table` | The mixin's props table. |

### create_standard_control_event

```lua
mixin_helper.create_standard_control_event(name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/mixin_helper.lua#L40)

A helper function for creating a standard control event. standard refers to the `Handle*` methods from `FCCustomLuaWindow` (not including `HandleControlEvent`).
For example usage, refer to the source for the `FCMControl` mixin.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `name` | `string` | The full event name (eg. `HandleCommand`, `HandleUpDownPressed`, etc) |

| Return type | Description |
| ----------- | ----------- |
| `function` | Returns two functions: a function for adding handlers and a function for removing handlers. |

### create_custom_control_change_event

```lua
mixin_helper.create_custom_control_change_event()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/mixin_helper.lua#L233)

Helper function for creating a custom event for a control.
Custom events are bootstrapped to InitWindow and HandleCommand, in addition be being able to be triggered manually.
For example usage, refer to the source for the `FCMCtrlPopup` mixin.

Parameters:
This function accepts as multiple arguments, a table for each parameter that will be passed to event handlers. Each table should have the following properties:
- `name`: The name of the parameter.
- `get`: The function or the string name of a control method to get the current value of the parameter. It should accept one argument which is the control itself. (eg `mixin.FCMControl.GetText` or `"GetSelectedItem_"`)
- `initial`: The initial value of the parameter (ie before the window has been created)

This function returns 4 values which are all functions:
1. Public method for adding a handler.
2. Public method for removing a handler.
3. Private static function for triggering the event on a control. Accepts one argument which is the control.
4. Private static function for iterating over the sets of last values to enable modification if needed. Each iteration returns a table with event handler paramater names and values.

@ ... (table)

### create_custom_window_change_event

```lua
mixin_helper.create_custom_window_change_event()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/mixin_helper.lua#L323)

Creates a custom change event for a window class. For details, see the documentation for `create_custom_control_change_event`, which works in exactly the same way as this function except for controls.

@ ... (table)

### to_fcstring

```lua
mixin_helper.to_fcstring(value, fcstr)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/mixin_helper.lua#L388)

Casts a value to an `FCString` object. If the value is already an `FCString`, it will be returned.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `value` | `any` |  |
| `fcstr` (optional) | `FCString` | An optional `FCString` object to populate to skip creating a new object. |

| Return type | Description |
| ----------- | ----------- |
| `FCString` |  |

### boolean_to_error

```lua
mixin_helper.boolean_to_error(object, method)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/mixin_helper.lua#L409)

There are many PDK methods that return a boolean value to indicate success / failure instead of throwing an error.
This function captures that result and throws an error in case of failure.

@ [...] (any) Any arguments to pass to the method.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `object` | `__FCMBase` | Any `FCM` or `FCX` object. |
| `method` | `string` | The name of the method to call (no trailing underscore, it will be added automatically). |

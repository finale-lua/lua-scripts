# Mixin Helper

A library of helper functions to improve code reuse in mixins.

## Functions

- [is_instance_of(object)](#is_instance_of)
- [assert_argument_type(argument_number, value)](#assert_argument_type)
- [force_assert_argument_type(argument_number, value)](#force_assert_argument_type)
- [assert_table_argument_type(argument_number, table_value)](#assert_table_argument_type)
- [force_assert_table_argument_type(argument_number, table_value)](#force_assert_table_argument_type)
- [assert(condition, message, level)](#assert)
- [force_assert(condition, message, level)](#force_assert)
- [create_standard_control_event(name)](#create_standard_control_event)
- [create_custom_control_change_event()](#create_custom_control_change_event)
- [create_custom_window_change_event()](#create_custom_window_change_event)
- [to_fcstring(value, fcstr)](#to_fcstring)
- [to_string(value)](#to_string)
- [boolean_to_error(object, method)](#boolean_to_error)
- [create_localized_proxy(method_name, class_name, only_localize_args)](#create_localized_proxy)
- [create_multi_string_proxy(method_name)](#create_multi_string_proxy)

### is_instance_of

```lua
mixin_helper.is_instance_of(object)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L46)

Checks if a Finale object is an instance of a class or classes. This function examines the full class hierarchy, so parent classes are also supported.

Table of Matching Conditions:
```
|            | FC  Class | FCM Class | FCX Class |
--------------------------------------------------
| FC  Object |     O     |     X     |     X     |
| FCM Object |     O     |     O     |     X     |
| FCX Object |     X     |     O     |     O     |
```
*Key: `O` = match, `X` = no match*

Summary:
- Parent cannot be instance of child class.
- `FC` object cannot be an instance of an `FCM` or `FCX` class.
- `FCM` object can be an instance of an `FC` class but cannot be an instance of an `FCX` class.
- `FCX` object can be an instance of an `FCM` class but cannot be an instance of an `FC` class.

*NOTE: The break points are due to differences in backwards compatibility between `FCM` and `FCX` mixins.*

@ ... (string) Class names (as many as needed). Can be an `FC`, `FCM`, or `FCX` class name. Can also be the name of a parent class.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `object` | `__FCBase` | Any finale object, including mixin enabled objects. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### assert_argument_type

```lua
mixin_helper.assert_argument_type(argument_number, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L145)

Asserts that an argument to a mixin method is the expected type(s). This should only be used within mixin methods as the function name will be inserted automatically.

If not a valid type, will throw a bad argument error at the level above where this function is called.

The followimg types can be specified:
- Standard Lua types (`string`, `number`, `boolean`, `table`, `function`, `nil`, etc),
- Number types (`integer` or `float`).
- Finale classes, including parent classes (eg `FCString`, `FCMeasure`, etc).
- Mixin classes, including parent classes (eg `FCMString`, `FCMMeasure`, etc).
*For details about what types a Finale object will satisfy, see `mixin_helper.is_instance_of`.*

*NOTE: This function will only assert if in debug mode (ie `finenv.DebugEnabled == true`). If assertions are always required, use `force_assert_argument_type` instead.*

start with a number that is the real argument number.
@ ... (string) Valid types (as many as needed). Can be standard Lua types, Finale class names, or mixin class names.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `argument_number` | `number \| string` | The REAL argument number for the error message (self counts as argument #1). If the argument is a string, it should |
| `value` | `any` | The value to test. |

### force_assert_argument_type

```lua
mixin_helper.force_assert_argument_type(argument_number, value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L160)

The same as `assert_argument_type` except this function always asserts, regardless of whether debug mode is enabled.

@ ... (string) Valid types (as many as needed). Can be standard Lua types, Finale class names, or mixin class names.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `argument_number` | `number` | The REAL argument number for the error message (self counts as argument #1). |
| `value` | `any` | The value to test. |

### assert_table_argument_type

```lua
mixin_helper.assert_table_argument_type(argument_number, table_value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L198)

For mixin methods that accept a table of values as an argument, this function will validate the types of the values within the table.
It is assumed that the table itself has already been validated with `assert_argument_type`. If a table is not passed, an error will be thrown.

As the key `n` has special meaning in Lua, if it is present and a `number`, it will be ignored.

*NOTE: This function will only assert if in debug mode (ie `finenv.DebugEnabled == true`). If assertions are always required, use `force_assert_table_argument_type` instead.*

@ ... (string) Valid types (as many as needed). Can be standard Lua types, Finale class names, or mixin class names.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `argument_number` | `number` | The REAL argument number for the error message (self counts as argument #1). |
| `table_value` | `table` | A table of values to test. |

### force_assert_table_argument_type

```lua
mixin_helper.force_assert_table_argument_type(argument_number, table_value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L213)

The same as `assert_table_argument_type` except this function always asserts, regardless of whether debug mode is enabled.

@ ... (string) Valid types (as many as needed). Can be standard Lua types, Finale class names, or mixin class names.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `argument_number` | `number` | The REAL argument number for the error message (self counts as argument #1). |
| `table_value` | `table` | A table of values to test. |

### assert

```lua
mixin_helper.assert(condition, message, level)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L238)

Asserts a condition in a mixin method. If the condition is false, an error is thrown one level above where this function is called.

*NOTE: This function will only assert if in debug mode (ie `finenv.DebugEnabled == true`). If assertions are always required, use `force_assert` instead.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `condition` | `any` | Can be any value or expression. If a function, it will be called (with zero arguments) and the result will be tested. |
| `message` | `string` | The error message. |
| `level` (optional) | `number` | Optional level to throw the error message at (default is 2). |

### force_assert

```lua
mixin_helper.force_assert(condition, message, level)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L253)

The same as `assert` except this function always asserts, regardless of whether debug mode is enabled.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `condition` | `any` | Can be any value or expression. |
| `message` | `string` | The error message. |
| `level` (optional) | `number` | Optional level to throw the error message at (default is 2). |

### create_standard_control_event

```lua
mixin_helper.create_standard_control_event(name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L266)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L457)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L542)

Creates a custom change event for a window class. For details, see the documentation for `create_custom_control_change_event`, which works in exactly the same way as this function except for controls.

@ ... (table)

### to_fcstring

```lua
mixin_helper.to_fcstring(value, fcstr)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L604)

Casts a value to an `FCString` object. If the value is already an `FCString`, it will be returned.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `value` | `any` |  |
| `fcstr` (optional) | `FCString` | An optional `FCString` object to populate to skip creating a new object. |

| Return type | Description |
| ----------- | ----------- |
| `FCString` |  |

### to_string

```lua
mixin_helper.to_string(value)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L623)

Casts a value to a Lua string. If the value is an `FCString`, it returns `LuaString`, otherwise it calls `tostring`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `value` | `any` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### boolean_to_error

```lua
mixin_helper.boolean_to_error(object, method)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L642)

There are many PDK methods that return a boolean value to indicate success / failure instead of throwing an error.
This function captures that result and throws an error in case of failure.

@ [...] (any) Any arguments to pass to the method.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `object` | `__FCMBase` | Any `FCM` or `FCX` object. |
| `method` | `string` | The name of the method to call (no trailing underscore, it will be added automatically). |

### create_localized_proxy

```lua
mixin_helper.create_localized_proxy(method_name, class_name, only_localize_args)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L658)

Creates a proxy method that takes localization keys instead of raw strings.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `method_name` | `string` |  |
| `class_name` | `string\|nil` | If `nil`, the resulting call will be on the `self` object. If a `string` is passed, it will be forwarded to a static call on that class in the `mixin` namespace. |
| `only_localize_args` | `table\|nil` | If `nil`, all values passed to the method will be localized. If only certain arguments need localizing, pass a `table` of argument `number`s (note that `self` is argument #1). |

| Return type | Description |
| ----------- | ----------- |
| `function` |  |

### create_multi_string_proxy

```lua
mixin_helper.create_multi_string_proxy(method_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/mixin_helper.lua#L689)

Creates a proxy method that takes multiple string arguments.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `method_name` | `string` | An instance method on the class that accepts a single Lua `string`, `FCString`, or `number` |

| Return type | Description |
| ----------- | ----------- |
| `function` |  |

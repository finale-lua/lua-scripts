# Configuration

This library implements a UTF-8 text file scheme for configuration and user settings as follows:

- Comments start with `--`
- Leading, trailing, and extra whitespace is ignored
- Each parameter is named and delimited as follows:

```
<parameter-name> = <parameter-value>
```

Parameter values may be:

- Strings delimited with either single- or double-quotes.
- Tables delimited with `{}` that may contain any Lua syntax for defining tables, including nested tables. (Be careful of syntax errors.)
- Booleans (`true` or `false`).
- Numbers.

Note that parameter values, including nested tables, must fit on a single line of text with the parameter name.

Parameter names may specify nested tables using dot-syntax:

```lua
diamond.quarter.glyph = 226
```

or

```lua
diamond.quarter = { glyph = 0xe0e2, size = 100 }
```

A sample configuration file might be:

```lua
-- Configuration File for "Hairpin and Dynamic Adjustments" script
--
left_dynamic_cushion         = 12        --evpus
right_dynamic_cushion        = -6        --evpus
```

## Configuration Files

Configuration files provide a way for power users to modify script behavior without
having to modify the script itself. Some users track their changes to their configuration files,
so scripts should not create or modify them programmatically.

- The user creates each configuration file in a subfolder called `script_settings` within
the folder of the calling script.
- Each script that has a configuration file defines its own configuration file name.
- It is entirely appropriate over time for scripts to transition from configuration files to user settings,
but this requires implementing a user interface to modify the user settings from within the script.
(See below.)

## User Settings Files

User settings are written by the scripts themselves and reside in the user's preferences folder
in an appropriately-named location for the operating system. (The naming convention is a detail that the
configuration library handles for the caller.) If the user settings are to be changed from their defaults,
the script itself should provide a means to change them. This could be a (preferably optional) dialog box
or any other mechanism the script author chooses.

User settings are saved in the user's preferences folder (on Mac) or AppData folder (on Windows).

Limitations for User Settings Files are

- supported parameter types limited to numbers, strings, and booleans
- no nested tables

## Merge Process

Files are _merged_ into the passed-in list of default values. They do not _replace_ the list. Each calling script contains
a table of all the configurable parameters or settings it recognizes along with default values. An example:

`sample.lua:`

```lua
parameters = {
   x = 1,
   y = 2,
   z = 3
}

configuration.get_parameters(parameters, "script.config.txt")

for k, v in pairs(parameters) do
   print(k, v)
end
```

Suppose the `script.config.text` file is as follows:

```
y = 4
q = 6
```

The returned parameters list is:

```lua
parameters = {
   x = 1,       -- remains the default value passed in
   y = 4,       -- replaced value from the config file
   z = 3        -- remains the default value passed in
}
```

The `q` parameter in the config file is ignored because the input paramater list
had no `q` parameter.

This approach allows total flexibility for the script add to or modify its list of parameters
without having to worry about older configuration files or user settings affecting it.

## Functions

- [get_parameters(file_name, parameter_list)](#get_parameters)
- [save_user_settings(script_name, parameter_list)](#save_user_settings)
- [get_user_settings(script_name, parameter_list, create_automatically)](#get_user_settings)

### get_parameters

```lua
configuration.get_parameters(file_name, parameter_list)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/configuration.lua#L200)

Searches for a file with the input filename in the `script_settings` directory and replaces the default values in `parameter_list`
with any that are found in the config file.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `file_name` | `string` | the file name of the config file (which will be prepended with the `script_settings` directory) |
| `parameter_list` | `table` | a table with the parameter name as key and the default value as value |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | true if the file exists |

### save_user_settings

```lua
configuration.save_user_settings(script_name, parameter_list)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/configuration.lua#L243)

Saves the user's preferences for a script from the values provided in `parameter_list`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `script_name` | `string` | the name of the script (without an extension) |
| `parameter_list` | `table` | a table with the parameter name as key and the default value as value |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | true on success |

### get_user_settings

```lua
configuration.get_user_settings(script_name, parameter_list, create_automatically)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/configuration.lua#L284)

Find the user's settings for a script in the preferences directory and replaces the default values in `parameter_list`
with any that are found in the preferences file. The actual name and path of the preferences file is OS dependent, so
the input string should just be the script name (without an extension).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `script_name` | `string` | the name of the script (without an extension) |
| `parameter_list` | `table` | a table with the parameter name as key and the default value as value |
| `create_automatically` (optional) | `boolean` | if true, create the file automatically (default is `true`) |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if the file already existed, `false` if it did not or if it was created automatically |

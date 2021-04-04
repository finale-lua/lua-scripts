# Configuration

Author: Robert Patterson
Date: March 5, 2021

This library implements a text file scheme as follows:
Comments start with "--"
Leading and trailing whitespace is ignored
Each parameter is named and delimited by a colon as follows:

<parameter-name> = <parameter-value>

Parameter values may be:

- Strings delimited with either single- or double-quotes)
- Tables delimited with {}
- Booleans (true or false)
- Integers

Currently tables embedded within tables is not supported.

- [get_parameters](#get_parameters)

## get_parameters

```lua
configuration.get_parameters(file_name, parameter_list)
```

| Input | Type | Description |
| --- | --- | --- |
| `file_name` | `string` | the file name of the config file (which will be prepended with the script_settings_dir) |
| `parameter_list` | `table` | a table with the parameter name as key and the default value as value |
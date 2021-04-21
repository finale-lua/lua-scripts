# Configuration

Author: Robert Patterson
Date: March 5, 2021

This library implements a text file scheme as follows:
Comments start with "--"
Leading, trailing, and extra whitespace is ignored
Each parameter is named and delimited as follows:

<parameter-name> = <parameter-value>

Parameter values may be:

- Strings delimited with either single- or double-quotes
- Tables delimited with {} that may contain strings, booleans, or numbers
- Booleans (true or false)
- Numbers

Currently the following are not supported:
    Tables embedded within tables
    Tables containing strings that contain commas

- [get_parameters](#get_parameters)

## get_parameters

```lua
configuration.get_parameters(file_name, parameter_list)
```

Searches for a file with the input filename in the `script_settings` directory and replaces the default values in `parameter_list` with any that are found in the config file.

| Input | Type | Description |
| --- | --- | --- |
| `file_name` | `string` | the file name of the config file (which will be prepended with the `script_settings` directory) |
| `parameter_list` | `table` | a table with the parameter name as key and the default value as value |
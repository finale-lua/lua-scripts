--  Author: Robert Patterson
--  Date: March 5, 2021
--[[
$module Configuration

This library implements a UTF-8 text file scheme for configuration and user settings as follows:

- Comments start with `--`
- Leading, trailing, and extra whitespace is ignored
- Each parameter is named and delimited as follows:

```
<parameter-name> = <parameter-value>
```

Parameter values may be:

- Strings delimited with either single- or double-quotes
- Tables delimited with `{}` that may contain strings, booleans, or numbers
- Booleans (`true` or `false`)
- Numbers

Currently the following are not supported:

- Tables embedded within tables
- Tables containing strings that contain commas

A sample configuration file might be:

```lua
-- Configuration File for "Hairpin and Dynamic Adjustments" script
--
left_dynamic_cushion 		= 12		--evpus
right_dynamic_cushion		= -6		--evpus
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
]]

local configuration = {}

local script_settings_dir = "script_settings" -- the parent of this directory is the running lua path
local comment_marker = "--"
local parameter_delimiter = "="
local path_delimiter = "/"

local file_exists = function(file_path)
    local f = io.open(file_path, "r")
    if nil ~= f then
        io.close(f)
        return true
    end
    return false
end

local strip_leading_trailing_whitespace = function(str)
    return str:match("^%s*(.-)%s*$") -- lua pattern magic taken from the Internet
end

local parse_table = function(val_string)
    local ret_table = {}
    for element in val_string:gmatch("[^,%s]+") do -- lua pattern magic taken from the Internet
        local parsed_element = parse_parameter(element)
        table.insert(ret_table, parsed_element)
    end
    return ret_table
end

parse_parameter = function(val_string)
    if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then -- double-quote string
        return string.gsub(val_string, "\"(.+)\"", "%1") -- lua pattern magic: "(.+)" matches all characters between two double-quote marks (no escape chars)
    elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then -- single-quote string
        return string.gsub(val_string, "'(.+)'", "%1") -- lua pattern magic: '(.+)' matches all characters between two single-quote marks (no escape chars)
    elseif "{" == val_string:sub(1, 1) and "}" == val_string:sub(#val_string, #val_string) then
        return parse_table(string.gsub(val_string, "{(.+)}", "%1"))
    elseif "true" == val_string then
        return true
    elseif "false" == val_string then
        return false
    end
    return tonumber(val_string)
end

local get_parameters_from_file = function(file_path, parameter_list)
    local file_parameters = {}

    if not file_exists(file_path) then
        return false
    end

    for line in io.lines(file_path) do
        local comment_at = string.find(line, comment_marker, 1, true) -- true means find raw string rather than lua pattern
        if nil ~= comment_at then
            line = string.sub(line, 1, comment_at - 1)
        end
        local delimiter_at = string.find(line, parameter_delimiter, 1, true)
        if nil ~= delimiter_at then
            local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at - 1))
            local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at + 1))
            file_parameters[name] = parse_parameter(val_string)
        end
    end

    for param_name, _ in pairs(parameter_list) do
        local param_val = file_parameters[param_name]
        if nil ~= param_val then
            parameter_list[param_name] = param_val
        end
    end

    return true
end

--[[
% get_parameters

Searches for a file with the input filename in the `script_settings` directory and replaces the default values in `parameter_list`
with any that are found in the config file.

@ file_name (string) the file name of the config file (which will be prepended with the `script_settings` directory)
@ parameter_list (table) a table with the parameter name as key and the default value as value
: (boolean) true if the file exists
]]
function configuration.get_parameters(file_name, parameter_list)
    local path = ""
    if finenv.IsRGPLua then
        path = finenv.RunningLuaFolderPath()
    else
        local str = finale.FCString()
        str:SetRunningLuaFolderPath()
        path = str.LuaString
    end
    local file_path = path .. script_settings_dir .. path_delimiter .. file_name
    return get_parameters_from_file(file_path, parameter_list)
end

-- Calculates a filepath in the user's preferences folder using recommended naming conventions
--
local calc_preferences_filepath = function(script_name)
    local str = finale.FCString()
    str:SetUserOptionsPath()
    local folder_name = str.LuaString
    if not finenv.IsRGPLua and finenv.UI():IsOnMac() then
        -- works around bug in SetUserOptionsPath() in JW Lua
        folder_name = os.getenv("HOME") .. folder_name:sub(2) -- strip '~' and replace with actual folder
    end
    if finenv.UI():IsOnWindows() then
        folder_name = folder_name .. path_delimiter .. "FinaleLua"
    end
    local file_path = folder_name .. path_delimiter
    if finenv.UI():IsOnMac() then
        file_path = file_path .. "com.finalelua."
    end
    file_path = file_path .. script_name .. ".settings.txt"
    return file_path, folder_name
end

--[[
% save_user_settings

Saves the user's preferences for a script from the values provided in `parameter_list`.

@ script_name (string) the name of the script (without an extension)
@ parameter_list (table) a table with the parameter name as key and the default value as value
: (boolean) true on success
]]
function configuration.save_user_settings(script_name, parameter_list)
    local file_path, folder_path = calc_preferences_filepath(script_name)
    local file = io.open(file_path, "w")
    if not file and finenv.UI():IsOnWindows() then -- file not found
        os.execute('mkdir "' .. folder_path ..'"') -- so try to make a folder (windows only, since the folder is guaranteed to exist on mac)
        file = io.open(file_path, "w") -- try the file again
    end
    if not file then -- still couldn't find file
        return false -- so give up
    end
    file:write("-- User settings for " .. script_name .. ".lua\n\n")
    for k,v in pairs(parameter_list) do -- only number, boolean, or string values
        if type(v) == "string" then
            v = "\"" .. v .."\""
        else
            v = tostring(v)
        end
        file:write(k, " = ", v, "\n")
    end
    file:close()
    return true -- success
end

--[[
% get_user_settings

Find the user's settings for a script in the preferences directory and replaces the default values in `parameter_list`
with any that are found in the preferences file. The actual name and path of the preferences file is OS dependent, so
the input string should just be the script name (without an extension).

@ script_name (string) the name of the script (without an extension)
@ parameter_list (table) a table with the parameter name as key and the default value as value
@ [create_automatically] (boolean) if true, create the file automatically (default is `true`)
: (boolean) `true` if the file already existed, `false` if it did not or if it was created automatically
]]
function configuration.get_user_settings(script_name, parameter_list, create_automatically)
    if create_automatically == nil then create_automatically = true end
    local exists = get_parameters_from_file(calc_preferences_filepath(script_name), parameter_list)
    if not exists and create_automatically then
        configuration.save_user_settings(script_name, parameter_list)
    end
    return exists
end

return configuration

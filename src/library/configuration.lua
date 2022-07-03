--  Author: Robert Patterson
--  Date: March 5, 2021
--[[
$module Configuration

This library implements a UTF-8 text file scheme for configuration as follows:

- Comments start with `--`
- Leading, trailing, and extra whitespace is ignored
- Each parameter is named and delimited as follows:
`<parameter-name> = <parameter-value>`

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

Configuration files must be placed in a subfolder called `script_settings` within
the folder of the calling script. Each script that has a configuration file
defines its own configuration file name.
]] --
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

local parse_parameter -- forward function declaration

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

local get_parameters_from_file = function(file_name)
    local parameters = {}

    local path = finale.FCString()
    path:SetRunningLuaFolderPath()
    local file_path = path.LuaString .. path_delimiter .. file_name
    if not file_exists(file_path) then
        return parameters
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
            parameters[name] = parse_parameter(val_string)
        end
    end

    return parameters
end

--[[
% get_parameters

Searches for a file with the input filename in the `script_settings` directory and replaces the default values in `parameter_list` with any that are found in the config file.

@ file_name (string) the file name of the config file (which will be prepended with the `script_settings` directory)
@ parameter_list (table) a table with the parameter name as key and the default value as value
]]
function configuration.get_parameters(file_name, parameter_list)
    local file_parameters = get_parameters_from_file(script_settings_dir .. path_delimiter .. file_name)
    if nil ~= file_parameters then
        for param_name, def_val in pairs(parameter_list) do
            local param_val = file_parameters[param_name]
            if nil ~= param_val then
                parameter_list[param_name] = param_val
            end
        end
    end
end

--[[
% save_parameters

Saves a config file with the input filename in the `script_settings` directory using values provided in `parameter_list`.

@ file_name (string) the file name of the config file (which will be prepended with the `script_settings` directory)
@ parameter_list (table) a table with the parameter name as key and the default value as value
]]
function configuration.save_parameters(file_name, parameter_list)
    local folder_path = finenv:RunningLuaFolderPath() .. script_settings_dir
    local file_path = folder_path ..  path_delimiter .. file_name
    local file = io.open(file_path, "w")
    if file == nil then -- file not found
        os.execute('mkdir "' .. folder_path ..'"') -- so try to make a folder
        file = io.open(file_path, "w") -- try the file again
        if file == nil then -- still couldn't find file
            return false -- so give up
        end
    end
    for i,v in pairs(parameter_list) do -- only integer or string values
        if type(v) == "string" then
            v = "\"" .. v .."\""
        else
            v = tostring(v)
        end
        file:write(i, " = ", v, "\n")
    end
    file:close()
    return true -- success
end

return configuration

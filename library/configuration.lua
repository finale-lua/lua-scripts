-- A collection of helpful JW Lua scripts to retrieve parameters from a text file
-- Simply import this file to another Lua script to use any of these scripts
--
-- Author: Robert Patterson
-- Date: March 5, 2021
--
-- This library implements a text file scheme as follows:
-- Comments start with "--"
-- Leading and trailing whitespace is ignored
-- Each parameter is named and delimited by a colon as follows:
--
-- <parameter-name> = <parameter-value>
--
-- Parameter values must be numbers or booleans. (If we need strings, that can be an enhancement.)

local configuration = {}

local script_settings_dir = "script_settings" -- the parent of this directory is the running lua path
local comment_marker = "--"
local parameter_delimiter = "="
local path_delimiter = "/"

local file_exists = function(file_path)
    local f = io.open(file_path,"r")
    if nil ~= f then
        io.close(f)
        return true
    end
    return false
end

local strip_leading_trailing_whitespace = function (str)
    return str:match("^%s*(.-)%s*$") -- regular expression magic taken from the Internet
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
        local comment_at = string.find(line, comment_marker, 1, true) -- true means use raw string rather than reg. exp.
        if nil ~= comment_at then
            line = string.sub(line, 1, comment_at-1)
        end
        local delimiter_at = string.find(line, parameter_delimiter, 1, true)
        if nil ~= delimiter_at then
            local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at-1))
            local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at+1))
            if "true" == val_string then
                parameters[name] = true
            elseif "false" == val_string then
                parameters[name] = false
            else
                parameters[name] = tonumber(val_string)
            end
        end
    end
    
    return parameters
end

-- configuration.get_parameters
-- file_name: the file name of the config file (which will be prepended with the script_settings_dir)
-- parameter_list: a table with the parameter name as key and the default value as value
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

return configuration

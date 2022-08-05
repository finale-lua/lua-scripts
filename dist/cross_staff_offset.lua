local __imports = {}
local __import_results = {}

function require(item)
    if not __imports[item] then
        error("module '" .. item .. "' not found")
    end

    if __import_results[item] == nil then
        __import_results[item] = __imports[item]()
        if __import_results[item] == nil then
            __import_results[item] = true
        end
    end

    return __import_results[item]
end

__imports["library.configuration"] = function()
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

end

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.HandlesUndo = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Version = "v1.29"
    finaleplugin.Date = "2022/07/11"
	finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.AdditionalMenuOptions = [[  CrossStaff Offset No Dialog  ]]
    finaleplugin.AdditionalUndoText = [[     CrossStaff Offset No Dialog  ]]
    finaleplugin.AdditionalPrefixes = [[     no_user_dialog = true  ]]
    finaleplugin.AdditionalDescriptions = [[ Offset horizontal position of cross-staff note entries - NO DIALOG ]]
    finaleplugin.Notes = [[
        When creating cross-staff notes using the option-downarrow shortcut, the stems of 
        'crossed' notes are reversed (on the wrong side of the notehead) and appear too far 
        to the right (if shifting downwards) by the width of one notehead, typically 24EVPU. 
        This script lets you set a horizontal offset for all cross-staff notes in the 
        selected region, with a different offset for non-crossed notes.  
        For crossing to the staff below use (-24,0) or (-12,12).  
        For crossing to the staff above use (24,0) or (12,-12).  
        Also specify which layer number to act upon (1-4) or "all layers" (0). 
        (This also offers a simple way to reset the horizontal offset of all notes in the selection to zero).
    
        This script adds an extra `NO DIALOG` menu item to rapidly duplicate the last action
        without using a confirmation dialog.
]]
   return "CrossStaff Offset…", "CrossStaff Offset", "Offset horizontal position of cross-staff note entries"
end

no_user_dialog = no_user_dialog or false

-- other global variables for modeless operation
global_dialog = nil
global_dialog_options = { -- words, key value in config, edit control holder
    { "Cross-staff offset:", "cross_staff_offset", nil },
    { "Non-crossed offset:", "non_cross_offset", nil },
    { "Layer 1-4 (0 = all):", "layer_number", nil }
}
config = {
    cross_staff_offset  = 0,
    non_cross_offset = 0,
    layer_number = 0,
    window_pos_x = 700,
    window_pos_y = 200
}
local configuration = require("library.configuration")

function is_out_of_range(horiz_offset)
    return ( math.abs(horiz_offset) > 999 ) -- some unreasonable EVPU offset
end

function no_submission_errors()
    local error = ""
    if config.layer_number < 0 or config.layer_number > 4  then 
        error = "The layer number must\nbe between 0 and 4\n(not " .. config.layer_number .. ")"
    elseif is_out_of_range(config.cross_staff_offset) or is_out_of_range(config.non_cross_offset) then
        error = "Choose realistic offset\nvalues (say from -999 to 999)\n(not "
            .. config.cross_staff_offset .. " / " .. config.non_cross_offset .. ")"
    end
    if error ~= "" then  -- error dialog and exit
        finenv.UI():AlertNeutral("script: " .. plugindef(), error)
        return false
    end
    return true
end

function create_user_dialog() -- attempting MODELESS operation
    local current_vert = 10
    local vertical_step = 25
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local edit_box_horiz = 120

    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    function make_static(msg, horiz, vert, width, color)
        local static = dialog:CreateStatic(horiz, vert)
        str.LuaString = msg
        static:SetText(str)
        static:SetWidth(width)
        if color == "red" then
            static:SetTextColor(204, 51, 0)
        end
    end

    for i, v in ipairs(global_dialog_options) do
        make_static(v[1], 0, current_vert, edit_box_horiz, "")
        v[3] = dialog:CreateEdit(edit_box_horiz, current_vert - mac_offset)
        v[3]:SetInteger(config[v[2]]) -- display the saved config value
        v[3]:SetWidth(75)
        if i < 3 then
            make_static("EVPUs", edit_box_horiz + 80, current_vert, 75, "")
        end
        current_vert = current_vert + vertical_step
    end
    make_static("cross to staff below = [ -24, 0 ] or [ -12, 12 ]", 0, current_vert + 8, 290, "red")
    make_static("cross to staff above = [ 24, 0 ] or [ 12, -12 ]", 0, current_vert + vertical_step, 290, "red")
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return dialog
end

function change_the_offsets() -- change entry offsets in the chosen layer (0 = all layers)
    finenv.StartNewUndoBlock("CrossStaff Offset", false)
    for entry in eachentrysaved(finenv.Region(), config.layer_number) do
        if entry:IsNote() then
            entry.ManualPosition = entry.CrossStaff and config.cross_staff_offset or config.non_cross_offset
        end
    end
    if finenv.EndUndoBlock then
        finenv.EndUndoBlock(true)
        finenv.Region():Redraw()
    else
        finenv.StartNewUndoBlock("CrossStaff Offset", true)
    end
end

function on_ok()
    for i, v in ipairs(global_dialog_options) do -- save the 3 integer values
        config[v[2]] = v[3]:GetInteger()
    end
    if no_submission_errors() then
        change_the_offsets()
    end
end

function on_close()
    global_dialog:StorePosition()
    config.window_pos_x = global_dialog.StoredX
    config.window_pos_y = global_dialog.StoredY
    configuration.save_user_settings("cross_staff_offset", config)
end

function cross_staff_offset()
    configuration.get_user_settings("cross_staff_offset", config)
    if no_user_dialog then
        change_the_offsets()
        return
    end
    global_dialog = create_user_dialog()
    if config.window_pos_x ~= nil and config.window_pos_y ~= nil then
        global_dialog:StorePosition()
        global_dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        global_dialog:RestorePosition()
    end
    global_dialog:RegisterHandleOkButtonPressed(on_ok)
    if global_dialog.RegisterCloseWindow then
        global_dialog:RegisterCloseWindow(on_close)
    end
    finenv.RegisterModelessDialog(global_dialog)
    global_dialog:ShowModeless()
end

cross_staff_offset()

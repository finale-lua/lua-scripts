__imports = __imports or {}
__import_results = __import_results or {}

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

__imports["library.configuration"] = __imports["library.configuration"] or function()
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
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Jacob Winkler" 
    finaleplugin.Copyright = "©2022 Jacob Winkler"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "2022-07-02"
    return "Lyrics - Space Baselines", "Lyrics - Space Baselines", "Lyrics - Space Baselines"
end



local configuration = require("library.configuration")

config = {all_lyrics = "true"}

local script_name = "lyrics_baseline_spacing"

configuration.get_user_settings(script_name, config, true)

function lyrics_spacing(title)
    local independent_lyrics = false
    local baseline_verse = finale.FCBaseline()
    baseline_verse:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSVERSE,1)
    local verse1_start = -baseline_verse.VerticalOffset
    baseline_verse:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSVERSE,2)
    local verse_gap =  -baseline_verse.VerticalOffset - verse1_start
    --
    local baseline_chorus = finale.FCBaseline()
    baseline_chorus:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSCHORUS,1)
    local chorus1_start = -baseline_chorus.VerticalOffset
    baseline_chorus:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSCHORUS,2)
    local chorus_gap =  -baseline_chorus.VerticalOffset - chorus1_start
    --
    local baseline_section = finale.FCBaseline()
    baseline_section:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSSECTION,1)
    local section1_start = -baseline_section.VerticalOffset
    baseline_section:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSSECTION,2)
    local section_gap = -baseline_section.VerticalOffset - section1_start
    --
    local row_h = 20
    local col_w = 60
    local col_gap = 10
    local str = finale.FCString()
    str.LuaString = title
    local dialog = finale.FCCustomLuaWindow()
    dialog:SetTitle(str)

    local row = {}
    for i = 1, 100 do
        row[i] = (i -1) * row_h
    end
--
    local col = {}
    for i = 1, 20 do
        col[i] = (i - 1) * col_w
    end
--

    function add_ctrl(dialog, ctrl_type, text, x, y, h, w, min, max)
        str.LuaString = text
        local ctrl = ""
        if ctrl_type == "checkbox" then
            ctrl = dialog:CreateCheckbox(x, y)
        elseif ctrl_type == "edit" then
            ctrl = dialog:CreateEdit(x, y - 2)
        elseif ctrl_type == "static" then
            ctrl = dialog:CreateStatic(x, y)
        end
        if ctrl_type == "edit" then
            ctrl:SetHeight(h-2)
            ctrl:SetWidth(w - col_gap)
        else
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
        end
        ctrl:SetText(str)
        return ctrl
    end

--    local control = add_ctrl(dialog, "static", "TESTING!", col[1], row[2], row_h, col_w, 0, 0)
    local verse_static = add_ctrl(dialog, "static", "All Lyrics", col[3], row[1], row_h, col_w, 0, 0)
    local chorus_static = add_ctrl(dialog, "static", "", col[4], row[1], row_h, col_w, 0, 0)
    local section_static = add_ctrl(dialog, "static", "", col[5], row[1], row_h, col_w, 0, 0)
    --
    local lyric1_static = add_ctrl(dialog, "static", "Lyric 1 baseline:", col[1] + 31, row[2], row_h, col_w * 2, 0, 0)
    local verse1_edit = add_ctrl(dialog, "edit", verse1_start, col[3], row[2], row_h, col_w, 0, 0)  
    local chorus1_edit = add_ctrl(dialog, "edit", chorus1_start, col[4], row[2], row_h, col_w, 0, 0)  
    local section1_edit = add_ctrl(dialog, "edit", section1_start, col[5], row[2], row_h, col_w, 0, 0)
    --
    local gap_static = add_ctrl(dialog, "static", "Gap:", col[2] + 29, row[3], row_h, col_w, 0, 0)
    local verse_gap_edit = add_ctrl(dialog, "edit", verse_gap, col[3], row[3], row_h, col_w, 0, 0)  
    local chorus_gap_edit = add_ctrl(dialog, "edit", chorus_gap, col[4], row[3], row_h, col_w, 0, 0)  
    local section_gap_edit = add_ctrl(dialog, "edit", section_gap, col[5], row[3], row_h, col_w, 0, 0)  
    --
        local all_lyrics_static = add_ctrl(dialog, "static", "Edit all:", col[2] + 14, row[4], row_h, col_w, 0, 0)
    local all_lyrics_check = add_ctrl(dialog, "checkbox", "", col[3], row[4], row_h, col_w * 2, 0, 0) 

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    --
    function apply()
        if config.all_lyrics == true then
            verse1_edit:GetText(str)
            chorus1_edit:SetText(str)
            section1_edit:SetText(str)
            --
            verse_gap_edit:GetText(str)
            chorus_gap_edit:SetText(str)
            section_gap_edit:SetText(str)
        end

        verse1_edit:GetText(str)
        verse1_start = tonumber(str.LuaString)
        chorus1_edit:GetText(str)
        chorus1_start = tonumber(str.LuaString)
        section1_edit:GetText(str)
        section1_start = tonumber(str.LuaString)
--
        verse_gap_edit:GetText(str)
        verse_gap = tonumber(str.LuaString)
        chorus_gap_edit:GetText(str)
        chorus_gap = tonumber(str.LuaString)
        section_gap_edit:GetText(str)
        section_gap = tonumber(str.LuaString)
        --
        for i = 1, 100, 1 do
            baseline_verse:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSVERSE,i)
            baseline_verse.VerticalOffset = -verse1_start - (verse_gap * (i - 1))
            baseline_verse:Save()
            --
            baseline_chorus:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSCHORUS,i)
            baseline_chorus.VerticalOffset = -chorus1_start - (chorus_gap * (i - 1))
            baseline_chorus:Save()
            --
            baseline_section:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSSECTION,i)
            baseline_section.VerticalOffset = -section1_start - (section_gap * (i - 1))
            baseline_section:Save()
        end
    end

    function callback(ctrl)
        if ctrl:GetControlID() == all_lyrics_check:GetControlID()  then

            if all_lyrics_check:GetCheck() == 1 then
                config.all_lyrics = true
            else
                config.all_lyrics = false
            end
            update()
        end
    end -- callback
    --
    dialog:RegisterHandleCommand(callback)
    --
    function update()
        if not config.all_lyrics then
            independent_lyrics = true
            str.LuaString = "Verse"
            verse_static:SetText(str)
            str.LuaString = "Chorus"
            chorus_static:SetText(str)
            str.LuaString = "Section"
            section_static:SetText(str)
            all_lyrics_check:SetCheck(0)
        else
            independent_lyrics = false
            str.LuaString = "All Lyrics"
            verse_static:SetText(str)
            str.LuaString = ""
            chorus_static:SetText(str)
            section_static:SetText(str)
            all_lyrics_check:SetCheck(1)
        end
        chorus1_edit:SetEnable(independent_lyrics)
        section1_edit:SetEnable(independent_lyrics)
        chorus_gap_edit:SetEnable(independent_lyrics)
        section_gap_edit:SetEnable(independent_lyrics)
        --
    end

    update()
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        apply()
        configuration.save_user_settings(script_name, config)
    end
end -- lyrics_spacing()

lyrics_spacing("Lyrics - Space Baselines")
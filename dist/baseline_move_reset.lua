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



    local configuration = {}
    local script_settings_dir = "script_settings"
    local comment_marker = "
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
        return str:match("^%s*(.-)%s*$")
    end
    local parse_table = function(val_string)
        local ret_table = {}
        for element in val_string:gmatch("[^,%s]+") do
            local parsed_element = parse_parameter(element)
            table.insert(ret_table, parsed_element)
        end
        return ret_table
    end
    parse_parameter = function(val_string)
        if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "\"(.+)\"", "%1")
        elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "'(.+)'", "%1")
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
            local comment_at = string.find(line, comment_marker, 1, true)
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


    local calc_preferences_filepath = function(script_name)
        local str = finale.FCString()
        str:SetUserOptionsPath()
        local folder_name = str.LuaString
        if not finenv.IsRGPLua and finenv.UI():IsOnMac() then

            folder_name = os.getenv("HOME") .. folder_name:sub(2)
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

    function configuration.save_user_settings(script_name, parameter_list)
        local file_path, folder_path = calc_preferences_filepath(script_name)
        local file = io.open(file_path, "w")
        if not file and finenv.UI():IsOnWindows() then
            os.execute('mkdir "' .. folder_path ..'"')
            file = io.open(file_path, "w")
        end
        if not file then
            return false
        end
        file:write("
        for k,v in pairs(parameter_list) do
            if type(v) == "string" then
                v = "\"" .. v .."\""
            else
                v = tostring(v)
            end
            file:write(k, " = ", v, "\n")
        end
        file:close()
        return true
    end

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
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Version = "1.0"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Date = "May 15, 2022"
    finaleplugin.CategoryTags = "Baseline"
    finaleplugin.AuthorURL = "http://robertgpatterson.com"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        This script nudges system baselines up or down by a single staff-space (24 evpus). It introduces 10
        menu options to nudge each baseline type up or down. It also introduces 5 menu options to reset
        the baselines to their staff-level values.
        The possible prefix inputs to the script are
        ```
        direction
        baseline_types
        nudge_evpus
        ```
        You can also change the size of the nudge by creating a configuration file called `baseline_move.config.txt` and
        adding a single line with the size of the nudge in evpus.
        ```
        nudge_evpus = 36
        ```
        A value in a prefix overrides any setting in a configuration file.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Move Lyric Baselines Up
        Reset Lyric Baselines
        Move Expression Baseline Above Down
        Move Expression Baseline Above Up
        Reset Expression Baseline Above
        Move Expression Baseline Below Down
        Move Expression Baseline Below Up
        Reset Expression Baseline Below
        Move Chord Baseline Down
        Move Chord Baseline Up
        Reset Chord Baseline
        Move Fretboard Baseline Down
        Move Fretboard Baseline Up
        Reset Fretboard Baseline
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Moves all lyrics baselines up one space in the selected systems
        Resets all selected lyrics baselines to default
        Moves the selected expression above baseline down one space
        Moves the selected expression above baseline up one space
        Resets the selected expression above baselines
        Moves the selected expression below baseline down one space
        Moves the selected expression below baseline up one space
        Resets the selected expression below baselines
        Moves the selected chord baseline down one space
        Moves the selected chord baseline up one space
        Resets the selected chord baselines
        Moves the selected fretboard baseline down one space
        Moves the selected fretboard baseline up one space
        Resets the selected fretboard baselines
    ]]
    finaleplugin.AdditionalPrefixes = [[
        direction = 1
        direction = 0
        direction = -1 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = 1 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = 0 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = -1 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = 1 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = 0 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = -1 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = 1 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = 0 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = -1 baseline_types = {finale.BASELINEMODE_FRETBOARD}
        direction = 1 baseline_types = {finale.BASELINEMODE_FRETBOARD}
        direction = 0 baseline_types = {finale.BASELINEMODE_FRETBOARD}
    ]]
    return "Move Lyric Baselines Down", "Move Lyrics Baselines Down", "Moves all lyrics baselines down one space in the selected systems"
end
local configuration = require("library.configuration")
local config = {nudge_evpus = 24}
if nil ~= configuration then
    configuration.get_parameters("baseline_move.config.txt", config)
end
local lyric_baseline_types = {
    [finale.BASELINEMODE_LYRICSVERSE] = function()
        return finale.FCVerseLyricsText()
    end,
    [finale.BASELINEMODE_LYRICSCHORUS] = function()
        return finale.FCChorusLyricsText()
    end,
    [finale.BASELINEMODE_LYRICSSECTION] = function()
        return finale.FCSectionLyricsText()
    end,
}
local find_valid_lyric_nums = function(baseline_type)
    local lyrics_text_class_constructor = lyric_baseline_types[baseline_type]
    if lyrics_text_class_constructor then
        local valid_lyric_nums = {}
        local lyrics_text_class = lyrics_text_class_constructor()
        for i = 1, 32767, 1 do
            if lyrics_text_class:Load(i) then
                local str = finale.FCString()
                lyrics_text_class:GetText(str)
                if not str:IsEmpty() then
                    valid_lyric_nums[{baseline_type, i}] = 1
                end
            end
        end
        return valid_lyric_nums
    end
    return nil
end
function baseline_move()
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local lastSys_number = lastSys:GetItemNo()
    local start_slot = region:GetStartSlot()
    local end_slot = region:GetEndSlot()
    for _, baseline_type in pairs(baseline_types) do
        local valid_lyric_nums = find_valid_lyric_nums(baseline_type)
        for i = system_number, lastSys_number, 1 do
            local baselines = finale.FCBaselines()
            if direction ~= 0 then
                baselines:LoadAllForSystem(baseline_type, i)
                for j = start_slot, end_slot do
                    if valid_lyric_nums then
                        for lyric_info, _ in pairs(valid_lyric_nums) do
                            local _, lyric_number = table.unpack(lyric_info)
                            bl = baselines:AssureSavedLyricNumber(baseline_type, i, region:CalcStaffNumber(j), lyric_number)
                            bl.VerticalOffset = bl.VerticalOffset + direction * nudge_evpus
                            bl:Save()
                        end
                    else
                        bl = baselines:AssureSavedStaff(baseline_type, i, region:CalcStaffNumber(j))
                        bl.VerticalOffset = bl.VerticalOffset + direction * nudge_evpus
                        bl:Save()
                    end
                end
            else
                for j = start_slot, end_slot do
                    baselines:LoadAllForSystemStaff(baseline_type, i, region:CalcStaffNumber(j))

                    for baseline in eachbackwards(baselines) do
                        baseline:DeleteData()
                    end
                end
            end
        end
    end
end
baseline_types = baseline_types or {finale.BASELINEMODE_LYRICSVERSE, finale.BASELINEMODE_LYRICSCHORUS, finale.BASELINEMODE_LYRICSSECTION}
direction = direction or -1
nudge_evpus = nudge_evpus or config.nudge_evpus
baseline_move()

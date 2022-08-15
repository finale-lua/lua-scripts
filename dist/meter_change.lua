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
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "June 4, 2022"
    finaleplugin.CategoryTags = "Meter"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.RequireSelection = true
    finaleplugin.Notes = [[
        Changes the meter in a selected range.

        If a single measure is selected,
        the meter will be set for all measures until the next
        meter change, or until the next measure with Time Signature
        set to "Always Show", or for the remaining measures in the score.
        You can override stopping at "Always Show" measures with a configuration
        file script_settings/meter_change.config.txt that contains the following
        line:
        ```
        stop_at_always_show = false
        ```
        You can limit the meter change to one bar by holding down Shift or Option
        keys when invoking the script. Then the meter is changed only
        for the single measure you selected.
        If multiple measures are selected, the meter will be set
        exactly for the selected measures.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Meter - 1/2
        Meter - 2/2
        Meter - 3/2
        Meter - 4/2
        Meter - 5/2
        Meter - 6/2
        Meter - 1/4
        Meter - 2/4
        Meter - 3/4
        Meter - 5/4
        Meter - 6/4
        Meter - 7/4
        Meter - 3/8
        Meter - 5/8 (2+3)
        Meter - 5/8 (3+2)
        Meter - 6/8
        Meter - 7/8 (2+2+3)
        Meter - 7/8 (3+2+2)
        Meter - 9/8
        Meter - 12/8
        Meter - 15/8
    ]]
    finaleplugin.AdditionalPrefixes = [[
        numerator = 1 denominator = 2
        numerator = 2 denominator = 2
        numerator = 3 denominator = 2
        numerator = 4 denominator = 2
        numerator = 5 denominator = 2
        numerator = 6 denominator = 2
        numerator = 1 denominator = 4
        numerator = 2 denominator = 4
        numerator = 3 denominator = 4
        numerator = 5 denominator = 4
        numerator = 6 denominator = 4
        numerator = 7 denominator = 4
        numerator = 3 denominator = 8
        numerator = 5 denominator = 8 composite = {2, 3}
        numerator = 5 denominator = 8 composite = {3, 2}
        numerator = 6 denominator = 8
        numerator = 7 denominator = 8 composite = {2, 2, 3}
        numerator = 7 denominator = 8 composite = {3, 2, 2}
        numerator = 9 denominator = 8
        numerator = 12 denominator = 8
        numerator = 15 denominator = 8
    ]]
    return "Meter - 4/4", "Meter - 4/4", "Sets the meter as indicated in a selected range."
end
local configuration = require("library.configuration")
config =
{
    stop_at_always_show = true
}
configuration.get_parameters("meter_change.config.txt", config)
numerator = numerator or 4
denominator = denominator or 4
composite = composite or nil
if denominator == 8 and not composite then
    numerator = numerator / 3
end
num_composite = 0
if composite then
    for k, v in pairs(composite) do
        num_composite = num_composite + 1
    end
end
local denominators = {}
denominators[2] = 2048
denominators[4] = 1024
denominators[8] = composite and 512 or 1536
local do_single_bar = finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
function apply_new_time(measure, beat_num, beat_duration)
    local time_sig = measure:GetTimeSignature()
    if composite then
        local top_list = finale.FCCompositeTimeSigTop()
        top_list:AddGroup(num_composite)
        for k, v in ipairs(composite) do
            top_list:SetGroupElementBeats(0, k-1, v)
        end
        time_sig:SaveNewCompositeTop(top_list)
        measure.UseTimeSigForDisplay = true
        local abrv_time_sig = measure:GetTimeSignatureForDisplay()
        abrv_time_sig:RemoveCompositeTop(beat_num)
        abrv_time_sig:RemoveCompositeBottom(beat_duration)
    else
        if measure.UseTimeSigForDisplay then
            local abrv_time_sig = measure:GetTimeSignatureForDisplay()
            abrv_time_sig:RemoveCompositeTop(beat_num)
            abrv_time_sig:RemoveCompositeBottom(beat_duration)
            measure.UseTimeSigForDisplay = false
        end
        time_sig:RemoveCompositeTop(beat_num)
    end
    time_sig:RemoveCompositeBottom(beat_duration)
end
function set_time(beat_num, beat_duration)
    local measures = finale.FCMeasures()
    measures:LoadRegion(finenv.Region())
    if measures.Count > 1 or do_single_bar then
        for m in each(measures) do
            apply_new_time(m, beat_num, beat_duration)
            m:Save()
        end
    else
        local selected_measure = measures:GetItemAt(0)
        local selected_time_signature = selected_measure:GetTimeSignature()


        for m in loadall(finale.FCMeasures()) do
            if (m.ItemNo > selected_measure.ItemNo) then
                if config.stop_at_always_show and m.ShowTimeSignature == finale.SHOWSTATE_SHOW then
                    break
                end
                if not selected_time_signature:IsIdentical(m:GetTimeSignature()) then
                    break
                end
                apply_new_time(m, beat_num, beat_duration)
                m:Save()
            end
        end
        apply_new_time(selected_measure, beat_num, beat_duration)
        selected_measure:Save()
    end
end
set_time(numerator, denominators[denominator])

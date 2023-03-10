__imports = __imports or {}
__import_results = __import_results or {}
__aaa_original_require_for_deployment__ = __aaa_original_require_for_deployment__ or require
function require(item)
    if not __imports[item] then
        return __aaa_original_require_for_deployment__(item)
    end
    if __import_results[item] == nil then
        __import_results[item] = __imports[item]()
        if __import_results[item] == nil then
            __import_results[item] = true
        end
    end
    return __import_results[item]
end
__imports["library.utils"] = __imports["library.utils"] or function()

    local utils = {}

    function utils.copy_table(t)
        if type(t) == "table" then
            local new = {}
            for k, v in pairs(t) do
                new[utils.copy_table(k)] = utils.copy_table(v)
            end
            setmetatable(new, utils.copy_table(getmetatable(t)))
            return new
        else
            return t
        end
    end

    function utils.table_remove_first(t, value)
        for k = 1, #t do
            if t[k] == value then
                table.remove(t, k)
                return
            end
        end
    end

    function utils.iterate_keys(t)
        local a, b, c = pairs(t)
        return function()
            c = a(b, c)
            return c
        end
    end

    function utils.round(value, places)
        places = places or 0
        local multiplier = 10^places
        return math.floor(value * multiplier + 0.5) / multiplier
    end

    function utils.calc_roman_numeral(num)
        local thousands = {'M','MM','MMM'}
        local hundreds = {'C','CC','CCC','CD','D','DC','DCC','DCCC','CM'}
        local tens = {'X','XX','XXX','XL','L','LX','LXX','LXXX','XC'}	
        local ones = {'I','II','III','IV','V','VI','VII','VIII','IX'}
        local roman_numeral = ''
        if math.floor(num/1000)>0 then roman_numeral = roman_numeral..thousands[math.floor(num/1000)] end
        if math.floor((num%1000)/100)>0 then roman_numeral=roman_numeral..hundreds[math.floor((num%1000)/100)] end
        if math.floor((num%100)/10)>0 then roman_numeral=roman_numeral..tens[math.floor((num%100)/10)] end
        if num%10>0 then roman_numeral = roman_numeral..ones[num%10] end
        return roman_numeral
    end

    function utils.calc_ordinal(num)
        local units = num % 10
        local tens = num % 100
        if units == 1 and tens ~= 11 then
            return num .. "st"
        elseif units == 2 and tens ~= 12 then
            return num .. "nd"
        elseif units == 3 and tens ~= 13 then
            return num .. "rd"
        end
        return num .. "th"
    end

    function utils.calc_alphabet(num)
        local letter = ((num - 1) % 26) + 1
        local n = math.floor((num - 1) / 26)
        return string.char(64 + letter) .. (n > 0 and n or "")
    end

    function utils.clamp(num, minimum, maximum)
        return math.min(math.max(num, minimum), maximum)
    end

    function utils.ltrim(str)
        return string.match(str, "^%s*(.*)")
    end

    function utils.rtrim(str)
        return string.match(str, "(.-)%s*$")
    end

    function utils.lrtrim(str)
        return utils.ltrim(utils.rtrim(str))
    end
    return utils
end
__imports["library.configuration"] = __imports["library.configuration"] or function()



    local configuration = {}
    local utils = require("library.utils")
    local script_settings_dir = "script_settings"
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
    parse_parameter = function(val_string)
        if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "\"(.+)\"", "%1")
        elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "'(.+)'", "%1")
        elseif "{" == val_string:sub(1, 1) and "}" == val_string:sub(#val_string, #val_string) then
            return load("return " .. val_string)()
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
                local name = utils.lrtrim(string.sub(line, 1, delimiter_at - 1))
                local val_string = utils.lrtrim(string.sub(line, delimiter_at + 1))
                file_parameters[name] = parse_parameter(val_string)
            end
        end
        local function process_table(param_table, param_prefix)
            param_prefix = param_prefix and param_prefix.."." or ""
            for param_name, param_val in pairs(param_table) do
                local file_param_name = param_prefix .. param_name
                local file_param_val = file_parameters[file_param_name]
                if nil ~= file_param_val then
                    param_table[param_name] = file_param_val
                elseif type(param_val) == "table" then
                        process_table(param_val, param_prefix..param_name)
                end
            end
        end
        process_table(parameter_list)
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
        file:write("-- User settings for " .. script_name .. ".lua\n\n")
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
    finaleplugin.Version = "1.1.0"
    finaleplugin.Date = "February 6, 2023"
    finaleplugin.CategoryTags = "Meter"
    finaleplugin.MinJWLuaVersion = 0.63
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
local measures_processed = {}
function apply_new_time(measure_or_cell, beat_num, beat_duration)
    if measure_or_cell:ClassName() == "FCMeasure" then
        if measures_processed[measure_or_cell.ItemNo] then
            return
        end
        measures_processed[measure_or_cell.ItemNo] = true
    end
    local time_sig = measure_or_cell:GetTimeSignature()
    if composite then
        local top_list = finale.FCCompositeTimeSigTop()
        top_list:AddGroup(num_composite)
        for k, v in ipairs(composite) do
            top_list:SetGroupElementBeats(0, k-1, v)
        end
        time_sig:SaveNewCompositeTop(top_list)
        local abrv_time_sig = (function()
            if measure_or_cell.UseTimeSigForDisplay ~= nil then
                measure_or_cell.UseTimeSigForDisplay = true
                return measure_or_cell:GetTimeSignatureForDisplay()
            end
            return measure_or_cell:AssureSavedIndependentTimeSigForDisplay()
        end)()
        abrv_time_sig:RemoveCompositeTop(beat_num)
        abrv_time_sig:RemoveCompositeBottom(beat_duration)
    else
        if measure_or_cell.UseTimeSigForDisplay then
            local abrv_time_sig = measure_or_cell:GetTimeSignatureForDisplay()
            abrv_time_sig:RemoveCompositeTop(beat_num)
            abrv_time_sig:RemoveCompositeBottom(beat_duration)
            measure_or_cell.UseTimeSigForDisplay = false
        elseif measure_or_cell.RemoveIndependentTimeSigForDisplay then
            measure_or_cell:RemoveIndependentTimeSigForDisplay()
        end
        time_sig:RemoveCompositeTop(beat_num)
    end
    time_sig:RemoveCompositeBottom(beat_duration)
    measure_or_cell:Save()
end
function set_time(beat_num, beat_duration)
    local measures_selected = finale.FCMeasures()
    measures_selected:LoadRegion(finenv.Region())
    local all_measures = finale.FCMeasures()
    all_measures:LoadAll()
    for staff_num in eachstaff(finenv.Region()) do
        if measures_selected.Count > 1 or do_single_bar then
            for m in each(measures_selected) do
                local cell = finale.FCCell(m.ItemNo, staff_num)
                if cell:HasIndependentTimeSig() then
                    apply_new_time(cell, beat_num, beat_duration)
                else
                    apply_new_time(m, beat_num, beat_duration)
                end
            end
        else
            local selected_measure = measures_selected:GetItemAt(0)
            local is_measure_stack = true
            local selected_time_signature, selected_item = (function()
                local selected_cell = finale.FCCell(selected_measure.ItemNo, staff_num)
                if selected_cell:HasIndependentTimeSig() then
                    is_measure_stack = false
                    return selected_cell:GetTimeSignature(), selected_cell
                end
                return selected_measure:GetTimeSignature(), selected_measure
            end)()


            for m in each(all_measures) do
                if (m.ItemNo > selected_measure.ItemNo) then
                    if config.stop_at_always_show and m.ShowTimeSignature == finale.SHOWSTATE_SHOW then
                        break
                    end
                    local this_item = m
                    if not is_measure_stack then
                        local cell = finale.FCCell(m.ItemNo, staff_num)
                        if not cell:HasIndependentTimeSig() then
                            break
                        end
                        this_item = cell
                    end
                    if not selected_time_signature:IsIdentical(this_item:GetTimeSignature()) then
                        break
                    end
                    apply_new_time(this_item, beat_num, beat_duration)
                end
            end
            apply_new_time(selected_item, beat_num, beat_duration)
        end
    end
    for measure_number, _ in pairs(measures_processed) do
        local measure = finale.FCMeasure()
        measure:Load(measure_number)
        local beat_chart = measure:CreateBeatChartElements()
        if beat_chart.Count > 0 then
            if beat_chart:GetItemAt(0).MeasurePos ~= measure:GetDuration() then
                beat_chart:DeleteDataForItem(measure_number)
                if measure.PositioningNotesMode == finale.POSITIONING_BEATCHART then
                    measure.PositioningNotesMode = finale.POSITIONING_TIMESIG
                    measure:Save()
                end
            end
        end
    end
end
set_time(numerator, denominators[denominator])

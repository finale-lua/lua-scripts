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
    finaleplugin.MinFinaleVersion = "2012"
    finaleplugin.Author = "Jari Williamsson"
    finaleplugin.Version = "0.01"
    finaleplugin.Notes = [[
        This script will only process 7-tuplets that appears on staves that has been defined as "Harp" in the Score Manager.
    ]]
    finaleplugin.CategoryTags = "Idiomatic, Note, Plucked Strings, Region, Tuplet, Woodwinds"
    return "Harp gliss", "Harp gliss", "Transforms 7-tuplets to harp gliss notation."
end
local configuration = require("library.configuration")
local config = {
    stem_length = 84,
    small_note_size = 70,
}
configuration.get_parameters("harp_gliss.config.txt", config)
function change_beam_info(primary_beam, entry)
    local current_length = entry:CalcStemLength()
    primary_beam.Thickness = 0
    if entry:CalcStemUp() then
        primary_beam.LeftVerticalOffset = primary_beam.LeftVerticalOffset + config.stem_length - current_length
    else
        primary_beam.LeftVerticalOffset = primary_beam.LeftVerticalOffset - config.stem_length + current_length
    end
end
function change_primary_beam(entry)
    local primary_beams = finale.FCPrimaryBeamMods(entry)
    primary_beams:LoadAll()
    if primary_beams.Count > 0 then

        local primary_beam = primary_beams:GetItemAt(0)
        change_beam_info(primary_beam, entry)
        primary_beam:Save()
    else

        local primary_beam = finale.FCBeamMod(false)
        primary_beam:SetNoteEntry(entry)
        change_beam_info(primary_beam, entry)
        primary_beam:SaveNew()
    end
end
function verify_entries(entry, tuplet)
    local entry_staff_spec = finale.FCCurrentStaffSpec()
    entry_staff_spec:LoadForEntry(entry)
    if entry_staff_spec.InstrumentUUID ~= finale.FFUUID_HARP then
        return false
    end
    local symbolic_duration = 0
    local first_entry = entry
    for _ = 0, 6 do
        if entry == nil then
            return false
        end
        if entry:IsRest() then
            return false
        end
        if entry.Duration >= finale.QUARTER_NOTE then
            return false
        end
        if entry.Staff ~= first_entry.Staff then
            return false
        end
        if entry.Layer ~= first_entry.Layer then
            return false
        end
        if entry:CalcDots() > 0 then
            return false
        end
        symbolic_duration = symbolic_duration + entry.Duration
        entry = entry:Next()
    end
    return (symbolic_duration == tuplet:CalcFullSymbolicDuration())
end
function get_matching_tuplet(entry)
    local tuplets = entry:CreateTuplets()
    for tuplet in each(tuplets) do
        if tuplet.SymbolicNumber == 7 and verify_entries(entry, tuplet) then
            return tuplet
        end
    end
    return nil
end
function hide_tuplet(tuplet)
    tuplet.ShapeStyle = finale.TUPLETSHAPE_NONE
    tuplet.NumberStyle = finale.TUPLETNUMBER_NONE
    tuplet.Visible = false
    tuplet:Save()
end
function hide_stems(entry, tuplet)
    local hide_first_entry = (tuplet:CalcFullReferenceDuration() >= finale.WHOLE_NOTE)
    for i = 0, 6 do
        if i > 0 or hide_first_entry then
            local stem = finale.FCCustomStemMod()
            stem:SetNoteEntry(entry)
            stem:UseUpStemData(entry:CalcStemUp())
            if stem:LoadFirst() then
                stem.ShapeID = 0
                stem:Save()
            else
                stem.ShapeID = 0
                stem:SaveNew()
            end
        end
        entry = entry:Next()
    end
end
function set_noteheads(entry, tuplet)
    for i = 0, 6 do
        for chord_note in each(entry) do
            local notehead = finale.FCNoteheadMod()
            if i == 0 then
                local reference_duration = tuplet:CalcFullReferenceDuration()
                if reference_duration >= finale.WHOLE_NOTE then
                    notehead.CustomChar = 119
                elseif reference_duration >= finale.HALF_NOTE then
                    notehead.CustomChar = 250
                end
            else
                notehead.Resize = config.small_note_size
            end
            notehead:SaveAt(chord_note)
        end
        entry = entry:Next()
    end
end
function change_dotted_first_entry(entry, tuplet)
    local reference_duration = tuplet:CalcFullReferenceDuration()
    local tuplet_dots = finale.FCNoteEntry.CalcDotsForDuration(reference_duration)
    local entry_dots = entry:CalcDots()
    if tuplet_dots == 0 then
        return
    end
    if tuplet_dots > 3 then
        return
    end
    if entry_dots > 0 then
        return
    end

    local next_entry = entry:Next()
    local next_duration = next_entry.Duration / 2
    for _ = 1, tuplet_dots do
        entry.Duration = entry.Duration + next_duration
        next_entry.Duration = next_entry.Duration - next_duration
        next_duration = next_duration / 2
    end
end
function harp_gliss()

    local harp_tuplets_exist = false
    for entry in eachentrysaved(finenv.Region()) do
        local harp_tuplet = get_matching_tuplet(entry)
        if harp_tuplet then
            harp_tuplets_exist = true
            for i = 1, 6 do
                entry = entry:Next()
                entry.BeamBeat = false
            end
        end
    end
    if not harp_tuplets_exist then
        return
    end


    finale.FCNoteEntry.MarkEntryMetricsForUpdate()

    for entry in eachentrysaved(finenv.Region()) do
        local harp_tuplet = get_matching_tuplet(entry)
        if harp_tuplet then
            change_dotted_first_entry(entry, harp_tuplet)
            change_primary_beam(entry)
            hide_tuplet(harp_tuplet)
            hide_stems(entry, harp_tuplet)
            set_noteheads(entry, harp_tuplet)
        end
    end
end
harp_gliss()

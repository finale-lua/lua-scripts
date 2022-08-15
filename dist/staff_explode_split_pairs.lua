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
__imports["library.client"] = function()

    local client = {}
    local function to_human_string(feature)
        return string.gsub(feature, "_", " ")
    end
    local function requires_later_plugin_version(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. "which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
        end
        return "This script requires a later version of RGP Lua. Please update RGP Lua instead to use this script."
    end
    local function requires_rgp_lua(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which is not available on JW Lua. Please use RGP Lua instead to use this script."
        end
        return "This script requires RGP Lua, the successor of JW Lua. Please use RGP Lua instead to use this script."
    end
    local function requires_plugin_version(version, feature)
        if tonumber(version) <= 0.54 then
            if feature then
                return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua or JW Lua version " .. version ..
                           " or later. Please update your plugin to use this script."
            end
            return "This script requires RGP Lua or JW Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        return "This script requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    local function requires_finale_version(version, feature)
        return "This script uses " .. to_human_string(feature) .. ", which is only available on Finale " .. version .. " or later"
    end

    % get_raw_finale_version
    Returns a raw Finale version from major, minor, and (optional) build parameters. For 32-bit Finale
    this is the internal major Finale version, not the year.
    @ major (number) Major Finale version
    @ minor (number) Minor Finale version
    @ [build] (number) zero if omitted
    : (number)
    ]]
    function client.get_raw_finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

    function client.get_lua_plugin_version()
        local num_string = tostring(finenv.MajorVersion) .. "." .. tostring(finenv.MinorVersion)
        return tonumber(num_string)
    end
    local features = {
        clef_change = {
            test = client.get_lua_plugin_version() >= 0.60,
            error = requires_plugin_version("0.58", "a clef change"),
        },
        ["FCKeySignature::CalcTotalChromaticSteps"] = {
            test = finenv.IsRGPLua and finale.FCKeySignature.__class.CalcTotalChromaticSteps,
            error = requires_later_plugin_version("a custom key signature"),
        },
        ["FCCategory::SaveWithNewType"] = {
            test = client.get_lua_plugin_version() >= 0.58,
            error = requires_plugin_version("0.58"),
        },
        ["finenv.QueryInvokedModifierKeys"] = {
            test = finenv.IsRGPLua and finenv.QueryInvokedModifierKeys,
            error = requires_later_plugin_version(),
        },
        ["FCCustomLuaWindow::ShowModeless"] = {
            test = finenv.IsRGPLua,
            error = requires_rgp_lua("a modeless dialog")
        },
        ["finenv.RetainLuaState"] = {
            test = finenv.IsRGPLua and finenv.RetainLuaState ~= nil,
            error = requires_later_plugin_version(),
        },
        smufl = {
            test = finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1),
            error = requires_finale_version("27.1", "a SMUFL font"),
        },
    }

    % supports
    Checks the client supports a given feature. Returns true if the client
    supports the feature, false otherwise.
    To assert the client must support a feature, use `client.assert_supports`.
    For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).
    @ feature (string) The feature the client should support.
    : (boolean)
    ]]
    function client.supports(feature)
        if features[feature].test == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

    % assert_supports
    Asserts that the client supports a given feature. If the client doesn't
    support the feature, this function will throw an friendly error then
    exit the program.
    To simply check if a client supports a feature, use `client.supports`.
    For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).
    @ feature (string) The feature the client should support.
    : (boolean)
    ]]
    function client.assert_supports(feature)
        local error_level = finenv.DebugEnabled and 2 or 0
        if not client.supports(feature) then
            if features[feature].error then
                error(features[feature].error, error_level)
            end

            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end
    return client
end
__imports["library.clef"] = function()

    local clef = {}
    local client = require("library.client")

    function clef.get_cell_clef(measure, staff_number)
        local cell_clef = -1
        local cell = finale.FCCell(measure, staff_number)
        local cell_frame_hold = finale.FCCellFrameHold()
        cell_frame_hold:ConnectCell(cell)
        if cell_frame_hold:Load() then
            if cell_frame_hold.IsClefList then
                cell_clef = cell_frame_hold:CreateFirstCellClefChange().ClefIndex
            else
                cell_clef = cell_frame_hold.ClefIndex
            end
        end
        return cell_clef
    end

    function clef.get_default_clef(first_measure, last_measure, staff_number)
        local staff = finale.FCStaff()
        local cell_clef = clef.get_cell_clef(first_measure - 1, staff_number)
        if cell_clef < 0 then
            cell_clef = clef.get_cell_clef(last_measure + 1, staff_number)
            if cell_clef < 0 then
                cell_clef = staff:Load(staff_number) and staff.DefaultClef or 0
            end
        end
        return cell_clef
    end

    function clef.restore_default_clef(first_measure, last_measure, staff_number)
        client.assert_supports("clef_change")
        local default_clef = clef.get_default_clef(first_measure, last_measure, staff_number)
        for measure = first_measure, last_measure do
            local cell = finale.FCCell(measure, staff_number)
            local cell_frame_hold = finale.FCCellFrameHold()
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
                cell_frame_hold:MakeCellSingleClef(nil)
                cell_frame_hold:SetClefIndex(default_clef)
                cell_frame_hold:Save()
            end
        end
    end
    return clef
end
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.48"
    finaleplugin.Date = "2022/07/14"
    finaleplugin.Notes = [[
        This script explodes a set of chords from one staff into "split" pairs of notes,
        top to bottom, on subsequent staves (1-3/2-4; 1-4/2-5/3-6; etc).
        Chords may contain different numbers of notes, the number of pairs determined by the chord with the largest number of notes.
        It warns if pre-existing music will be erased and duplicates all markings from the original,
        resetting the current clef for each destination staff.
        By default this script doesn't respace the selected music after it completes.
        If you want automatic respacing, hold down the `shift` or `alt` (option) key when selecting the script's menu item.
        Alternatively, if you want the default behaviour to include spacing then create a `configuration` file:
        If it does not exist, create a subfolder called `script_settings` in the folder containing this script.
        In that folder create a plain text file  called `staff_explode_split_pairs.config.txt` containing the line:
        ```
        fix_note_spacing = true
        ```
        If you subsequently hold down the `shift` or `alt` (option) key, spacing will not be included.
    ]]
    return "Staff Explode Split Pairs", "Staff Explode Split Pairs", "Explode chords from one staff into split pairs of notes on consecutive single staves"
end
local configuration = require("library.configuration")
local clef = require("library.clef")
local config = { fix_note_spacing = false }
configuration.get_parameters("staff_explode_split_pairs.config.txt", config)
function show_error(error_code)
    local errors = {
        need_more_staves = "There are not enough empty\nstaves to explode onto",
        only_one_staff = "Please select only one source staff!",
        empty_region = "Please select a region\nwith some notes in it!",
        three_or_more = "Explode Pairs needs\nthree or more notes per chord",
    }
    finenv.UI():AlertNeutral("script: " .. plugindef(), errors[error_code])
    return -1
end
function should_overwrite_existing_music()
    local alert = finenv.UI():AlertOkCancel("script: " .. plugindef(), "Overwrite existing music?")
    local should_overwrite = (alert == 0)
    return should_overwrite
end
function get_max_note_count(source_staff_region)
    local max_note_count = 0
    for entry in eachentry(source_staff_region) do
        if entry.Count > 0 then
            if max_note_count < entry.Count then
                max_note_count = entry.Count
            end
        end
    end
    if max_note_count == 0 then
        return show_error("empty_region")
    elseif max_note_count < 3 then
        return show_error("three_or_more")
    end
    return max_note_count
end
function ensure_score_has_enough_staves(slot, max_note_count)
    local staves = finale.FCStaves()
    staves:LoadAll()
    if max_note_count > staves.Count - slot + 1 then
        return false
    end
    return true
end
function staff_explode()
    if finenv.QueryInvokedModifierKeys and
    (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
        then
        config.fix_note_spacing = not config.fix_note_spacing
    end
    local source_staff_region = finale.FCMusicRegion()
    source_staff_region:SetCurrentSelection()
    if source_staff_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    end
    local start_slot = source_staff_region.StartSlot
    local start_measure = source_staff_region.StartMeasure
    local end_measure = source_staff_region.EndMeasure
    local regions = {}
    regions[1] = source_staff_region
    local max_note_count = get_max_note_count(source_staff_region)
    if max_note_count <= 0 then
        return
    end
    local staff_count = math.floor((max_note_count / 2) + 0.5)
    if not ensure_score_has_enough_staves(start_slot, staff_count) then
        show_error("need_more_staves")
        return
    end

    local destination_is_empty = true
    for slot = 2, staff_count do
        regions[slot] = finale.FCMusicRegion()
        regions[slot]:SetRegion(regions[1])
        regions[slot]:CopyMusic()
        local this_slot = start_slot + slot - 1
        regions[slot].StartSlot = this_slot
        regions[slot].EndSlot = this_slot

        if destination_is_empty then
            for entry in eachentry(regions[slot]) do
                if entry.Count > 0 then
                    destination_is_empty = false
                    break
                end
            end
        end
    end
    if destination_is_empty or should_overwrite_existing_music() then


        local pitches_to_keep = {}
        local chord = 1
        for entry in eachentry(regions[1]) do
            if entry:IsNote() then
                pitches_to_keep[chord] = {}
                for note in each(entry) do
                    table.insert(pitches_to_keep[chord], note:CalcMIDIKey())
                end
                chord = chord + 1
            end
        end


        for slot = 1, staff_count do
            if slot > 1 then
                regions[slot]:PasteMusic()
                clef.restore_default_clef(start_measure, end_measure, regions[slot].StartStaff)
            end
            chord = 1
            for entry in eachentrysaved(regions[slot]) do
                if entry:IsNote() then

                    local hi_pitch = entry.Count + 1 - slot
                    local lo_pitch = hi_pitch - staff_count
                    local overflow = -1
                    while entry.Count > 0 and overflow < max_note_count do
                        overflow = overflow + 1
                        for note in each(entry) do
                            local pitch = note:CalcMIDIKey()
                            if pitch ~= pitches_to_keep[chord][hi_pitch] and pitch ~= pitches_to_keep[chord][lo_pitch] then
                                entry:DeleteNote(note)
                                break
                            end
                        end
                    end
                    chord = chord + 1
                end
            end
        end
        if config.fix_note_spacing then
            regions[1]:SetFullMeasureStack()
            regions[1]:SetInDocument()
            finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
            regions[1].StartSlot = start_slot
            regions[1].EndSlot = start_slot
            regions[1]:SetInDocument()
        end
    end

    for slot = 2, staff_count do
        regions[slot]:ReleaseMusic()
    end
    finenv:Region():SetInDocument()
end
staff_explode()

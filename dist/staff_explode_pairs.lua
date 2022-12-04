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



    local configuration = {}
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
__imports["library.client"] = __imports["library.client"] or function()

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

    function client.supports(feature)
        if features[feature].test == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

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
__imports["library.clef"] = __imports["library.clef"] or function()

    local clef = {}

    local client = require("library.client")

    local clef_map = {
        treble = 0,
        alto = 1,
        tenor = 2,
        bass = 3,
        perc_old = 4,
        treble_8ba = 5,
        treble_8vb = 5,
        tenor_voice = 5,
        bass_8ba = 6,
        bass_8vb = 6,
        baritone = 7,
        baritone_f = 7,
        french_violin_clef = 8,
        baritone_c = 9,
        mezzo_soprano = 10,
        soprano = 11,
        percussion = 12,
        perc_new = 12,
        treble_8va = 13,
        bass_8va = 14,
        blank = 15,
        tab_sans = 16,
        tab_serif = 17
    }



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


    function clef.set_measure_clef(first_measure, last_measure, staff_number, clef_index)
        client.assert_supports("clef_change")

        for measure = first_measure, last_measure do
            local cell = finale.FCCell(measure, staff_number)
            local cell_frame_hold = finale.FCCellFrameHold()
            local clef_change = cell_frame_hold:CreateFirstCellClefChange()
            clef_change:SetClefIndex(clef_index)
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
                cell_frame_hold:MakeCellSingleClef(clef_change)
                cell_frame_hold:SetClefIndex(clef_index)
                cell_frame_hold:Save()
            else
                cell_frame_hold:MakeCellSingleClef(clef_change)
                cell_frame_hold:SetClefIndex(clef_index)
                cell_frame_hold:SaveNew()
            end
        end
    end


    function clef.restore_default_clef(first_measure, last_measure, staff_number)
        client.assert_supports("clef_change")

        local default_clef = clef.get_default_clef(first_measure, last_measure, staff_number)

        clef.set_measure_clef(first_measure, last_measure, staff_number, default_clef)


    end


    function clef.process_clefs(mid_clefs)
        local clefs = {}
        local new_mid_clefs = finale.FCCellClefChanges()
        for mid_clef in each(mid_clefs) do
            table.insert(clefs, mid_clef)
        end
        table.sort(clefs, function (k1, k2) return k1.MeasurePos < k2.MeasurePos end)

        for k, mid_clef in ipairs(clefs) do
            new_mid_clefs:InsertCellClefChange(mid_clef)
            new_mid_clefs:SaveAllAsNew()
        end


        for i = new_mid_clefs.Count - 1, 1, -1 do
            local later_clef_change = new_mid_clefs:GetItemAt(i)
            local earlier_clef_change = new_mid_clefs:GetItemAt(i - 1)
            if later_clef_change.MeasurePos < 0 then
                new_mid_clefs:ClearItemAt(i)
                new_mid_clefs:SaveAll()
                goto continue
            end
            if earlier_clef_change.ClefIndex == later_clef_change.ClefIndex then
                new_mid_clefs:ClearItemAt(i)
                new_mid_clefs:SaveAll()
            end
            ::continue::
        end

        return new_mid_clefs
    end


    function clef.clef_change(clef_type, region)
        local clef_index = clef_map[clef_type]
        local cell_frame_hold = finale.FCCellFrameHold()
        local last_clef
        local last_staff = -1

        for cell_measure, cell_staff in eachcell(region) do
            local cell = finale.FCCell(region.EndMeasure, cell_staff)
            if cell_staff ~= last_staff then
                last_clef = cell:CalcClefIndexAt(region.EndMeasurePos)
                last_staff = cell_staff
            end
            cell = finale.FCCell(cell_measure, cell_staff)
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
            end

            if  region:IsFullMeasureIncluded(cell_measure) then
                clef.set_measure_clef(cell_measure, cell_measure, cell_staff, clef_index)
                if not region:IsLastEndMeasure() then
                    cell = finale.FCCell(cell_measure + 1, cell_staff)
                    cell_frame_hold:ConnectCell(cell)
                    if cell_frame_hold:Load() then
                        cell_frame_hold:SetClefIndex(last_clef)
                        cell_frame_hold:Save()
                    else
                        cell_frame_hold:SetClefIndex(last_clef)
                        cell_frame_hold:SaveNew()
                    end
                end


            else
                local mid_measure_clefs = cell_frame_hold:CreateCellClefChanges()
                local new_mid_measure_clefs = finale.FCCellClefChanges()
                local mid_measure_clef = finale.FCCellClefChange()

                if not mid_measure_clefs then
                    mid_measure_clefs = finale.FCCellClefChanges()
                    mid_measure_clef:SetClefIndex(cell_frame_hold.ClefIndex)
                    mid_measure_clef:SetMeasurePos(0)
                    mid_measure_clef:Save()
                    mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    mid_measure_clefs:SaveAllAsNew()
                end

                if cell_frame_hold.Measure == region.StartMeasure and region.StartMeasure ~= region.EndMeasure then

                    for mid_clef in each(mid_measure_clefs) do
                        if mid_clef.MeasurePos < region.StartMeasurePos then
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        end
                    end

                    mid_measure_clef:SetClefIndex(clef_index)
                    mid_measure_clef:SetMeasurePos(region.StartMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()
                end

                if cell_frame_hold.Measure == region.EndMeasure and region.StartMeasure ~= region.EndMeasure then


                    for mid_clef in each(mid_measure_clefs) do
                        if mid_clef.MeasurePos == 0 then
                            mid_clef:SetClefIndex(clef_index)
                            mid_clef:Save()
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        elseif mid_clef.MeasurePos > region.EndMeasurePos then
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        end
                    end


                    mid_measure_clef:SetClefIndex(last_clef)
                    mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()
                end

                if cell_frame_hold.Measure == region.StartMeasure and region.StartMeasure == region.EndMeasure then
                    local last_clef = cell:CalcClefIndexAt(region.EndMeasurePos)

                    for mid_clef in each(mid_measure_clefs) do
                        if mid_clef.MeasurePos == 0 then
                            if region.StartMeasurePos == 0 then
                                mid_clef:SetClefIndex(clef_index)
                                mid_clef:Save()
                            end
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        elseif mid_clef.MeasurePos < region.StartMeasurePos or
                        mid_clef.MeasurePos > region.EndMeasurePos then
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        end
                    end

                    mid_measure_clef:SetClefIndex(clef_index)
                    mid_measure_clef:SetMeasurePos(region.StartMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()

                    mid_measure_clef:SetClefIndex(last_clef)
                    mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()
                end

                new_mid_measure_clefs = clef.process_clefs(new_mid_measure_clefs)

                if cell_frame_hold:Load() then
                    cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                    cell_frame_hold:Save()
                else
                    cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                    cell_frame_hold:SaveNew()
                end
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
    finaleplugin.Version = "v1.50"
    finaleplugin.Date = "2022/09/24"
    finaleplugin.AdditionalMenuOptions = [[
        Staff Explode Pairs Up
    ]]
    finaleplugin.AdditionalUndoText = [[
        Staff Explode Pairs Up
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Explode chords from one staff into pairs of notes on consecutive single staves, favouring lowest staff"
    ]]
    finaleplugin.AdditionalPrefixes = [[
        split_type = "upwards"
    ]]
    finaleplugin.ScriptGroupName = "Staff Explode Pairs"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        This script explodes a set of chords from one staff into pairs of notes, top to bottom, on subsequent staves.
        Chords may contain different numbers of notes, the number of destination staves determined by the chord with the largest number of notes.
        It duplicates all markings from the original, resets the current clef for each destination staff
        and warns if pre-existing music in the destination will be erased.
        This script explodes "top-down" so that any uneven or missing notes in a chord are omitted from the bottom staff.
        A second menu item offers `Explode Pairs Up` for "bottom-up" action so that uneven or missing notes are instead omitted from the top staff.
        By default this script doesn't respace the selected music after it completes.
        If you want automatic respacing, hold down the `shift` or `alt` (option) key when selecting the script's menu item.
        Alternatively, if you want the default behaviour to include spacing then create a `configuration` file:
        If it does not exist, create a subfolder called `script_settings` in the folder containing this script.
        In that folder create a plain text file  called `staff_explode_pairs.config.txt` containing the line:
        ```
        fix_note_spacing = true
        ```
        If you subsequently hold down the `shift` or `alt` (option) key, spacing will not be included.
    ]]
    return "Staff Explode Pairs", "Staff Explode Pairs", "Explode chords from one staff into pairs of notes on consecutive single staves"
end
split_type = split_type or "downwards"
local configuration = require("library.configuration")
local clef = require("library.clef")
local config = { fix_note_spacing = false }
configuration.get_parameters("staff_explode_pairs.config.txt", config)
function show_error(error_code)
    local errors = {
        need_more_staves = "There are not enough empty\nstaves to explode onto",
        only_one_staff = "Please select only one staff!",
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
function get_note_count(source_staff_region)
    local note_count = 0
    for entry in eachentry(source_staff_region) do
        if entry.Count > 0 then
            if note_count < entry.Count then
                note_count = entry.Count
            end
        end
    end
    if note_count == 0 then
        return show_error("empty_region")
    elseif note_count < 3 then
        return show_error("three_or_more")
    end
    return note_count
end
function ensure_score_has_enough_staves(slot, staff_count)
    local staves = finale.FCStaves()
    staves:LoadAll()
    if staff_count > staves.Count - slot + 1 then
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
    local max_note_count = get_note_count(source_staff_region)
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

        for slot = 1, staff_count do
            if slot > 1 then
                regions[slot]:PasteMusic()
                clef.restore_default_clef(start_measure, end_measure, regions[slot].StartStaff)
            end
            for entry in eachentrysaved(regions[slot]) do
                if entry:IsNote() then
                    local from_top = (slot - 1) * 2
                    local from_bottom = entry.Count - (slot * 2)
                    if split_type == "upwards" then
                        from_bottom = (staff_count - slot) * 2
                        from_top = entry.Count - from_bottom - 2
                    end
                    if from_top > 0 then
                        for i = 1, from_top do
                            entry:DeleteNote(entry:CalcHighestNote(nil))
                        end
                    end
                    if from_bottom > 0 then
                        for i = 1, from_bottom do
                            entry:DeleteNote(entry:CalcLowestNote(nil))
                        end
                    end
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

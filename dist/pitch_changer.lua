package.preload["library.utils"] = package.preload["library.utils"] or function()

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
        local ret = math.floor(value * multiplier + 0.5)

        return places == 0 and ret or ret / multiplier
    end

    function utils.to_integer_if_whole(value)
        local int = math.floor(value)
        return value == int and int or value
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

    function utils.trim(str)
        return utils.ltrim(utils.rtrim(str))
    end

    local pcall_wrapper
    local rethrow_placeholder = "tryfunczzz"
    local pcall_line = debug.getinfo(1, "l").currentline + 2
    function utils.call_and_rethrow(levels, tryfunczzz, ...)
        return pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))

    end

    local source = debug.getinfo(1, "S").source
    local source_is_file = source:sub(1, 1) == "@"
    if source_is_file then
        source = source:sub(2)
    end

    pcall_wrapper = function(levels, success, result, ...)
        if not success then
            local file
            local line
            local msg
            file, line, msg = result:match("([a-zA-Z]-:?[^:]+):([0-9]+): (.+)")
            msg = msg or result
            local file_is_truncated = file and file:sub(1, 3) == "..."
            file = file_is_truncated and file:sub(4) or file



            if file
                and line
                and source_is_file
                and (file_is_truncated and source:sub(-1 * file:len()) == file or file == source)
                and tonumber(line) == pcall_line
            then
                local d = debug.getinfo(levels, "n")

                msg = msg:gsub("'" .. rethrow_placeholder .. "'", "'" .. (d.name or "") .. "'")

                if d.namewhat == "method" then
                    local arg = msg:match("^bad argument #(%d+)")
                    if arg then
                        msg = msg:gsub("#" .. arg, "#" .. tostring(tonumber(arg) - 1), 1)
                    end
                end
                error(msg, levels + 1)


            else
                error(result, 0)
            end
        end
        return ...
    end

    function utils.rethrow_placeholder()
        return "'" .. rethrow_placeholder .. "'"
    end

    function utils.require_embedded(library_name)
        return require(library_name)
    end
    return utils
end
package.preload["library.configuration"] = package.preload["library.configuration"] or function()



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
                local name = utils.trim(string.sub(line, 1, delimiter_at - 1))
                local val_string = utils.trim(string.sub(line, delimiter_at + 1))
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

            local osutils = finenv.EmbeddedLuaOSUtils and utils.require_embedded("luaosutils")
            if osutils then
                osutils.process.make_dir(folder_path)
            else
                os.execute('mkdir "' .. folder_path ..'"')
            end
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
package.preload["library.layer"] = package.preload["library.layer"] or function()

    local layer = {}

    function layer.copy(region, source_layer, destination_layer, clone_articulations)
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        source_layer = source_layer - 1
        destination_layer = destination_layer - 1
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local noteentry_source_layer = finale.FCNoteEntryLayer(source_layer, staffNum, start, stop)
            noteentry_source_layer:SetUseVisibleLayer(false)
            noteentry_source_layer:Load()
            local noteentry_destination_layer = noteentry_source_layer:CreateCloneEntries(
                destination_layer, staffNum, start)
            noteentry_destination_layer:Save()
            noteentry_destination_layer:CloneTuplets(noteentry_source_layer)

            if clone_articulations and noteentry_source_layer.Count == noteentry_destination_layer.Count then
                for index = 0, noteentry_destination_layer.Count - 1 do
                    local source_entry = noteentry_source_layer:GetItemAt(index)
                    local destination_entry = noteentry_destination_layer:GetItemAt(index)
                    local source_artics = source_entry:CreateArticulations()
                    for articulation in each (source_artics) do
                        articulation:SetNoteEntry(destination_entry)
                        articulation:SaveNew()
                    end
                end
            end
            noteentry_destination_layer:Save()
        end
    end

    function layer.clear(region, layer_to_clear)
        layer_to_clear = layer_to_clear - 1
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local  noteentry_layer = finale.FCNoteEntryLayer(layer_to_clear, staffNum, start, stop)
            noteentry_layer:SetUseVisibleLayer(false)
            noteentry_layer:Load()
            noteentry_layer:ClearAllEntries()
        end
    end

    function layer.swap(region, swap_a, swap_b)

        swap_a = swap_a - 1
        swap_b = swap_b - 1
        for measure, staff_number in eachcell(region) do
            local cell_frame_hold = finale.FCCellFrameHold()
            cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
            local loaded = cell_frame_hold:Load()
            local cell_clef_changes = loaded and cell_frame_hold.IsClefList and cell_frame_hold:CreateCellClefChanges() or nil
            local  noteentry_layer_one = finale.FCNoteEntryLayer(swap_a, staff_number, measure, measure)
            noteentry_layer_one:SetUseVisibleLayer(false)
            noteentry_layer_one:Load()
            noteentry_layer_one.LayerIndex = swap_b

            local  noteentry_layer_two = finale.FCNoteEntryLayer(swap_b, staff_number, measure, measure)
            noteentry_layer_two:SetUseVisibleLayer(false)
            noteentry_layer_two:Load()
            noteentry_layer_two.LayerIndex = swap_a
            noteentry_layer_one:Save()
            noteentry_layer_two:Save()
            if loaded then
                local new_cell_frame_hold = finale.FCCellFrameHold()
                new_cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
                if new_cell_frame_hold:Load() then
                    if cell_frame_hold.IsClefList then
                        if new_cell_frame_hold.SetCellClefChanges then
                            new_cell_frame_hold:SetCellClefChanges(cell_clef_changes)
                        end

                    else
                        new_cell_frame_hold.ClefIndex = cell_frame_hold.ClefIndex
                    end
                    new_cell_frame_hold:Save()
                end
            end
        end
    end

    function layer.max_layers()
        return finale.FCLayerPrefs.GetMaxLayers and finale.FCLayerPrefs.GetMaxLayers() or 4
    end
    return layer
end
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.15"
    finaleplugin.Date = "2023/10/13"
    finaleplugin.AdditionalMenuOptions = [[
        Pitch Changer Repeat
    ]]
    finaleplugin.AdditionalUndoText = [[
        Pitch Changer Repeat
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Repeat the last pitch change without confirmation dialog
    ]]
    finaleplugin.AdditionalPrefixes = [[
        repeat_change = true
    ]]
    finaleplugin.MinJWLuaVersion = 0.64
    finaleplugin.ScriptGroupName = "Pitch Changer"
    finaleplugin.ScriptGroupDescription = "Change all notes of one pitch in the region to another pitch"
    finaleplugin.Notes = [[
        This script was inspired by Jari Williamsson's "JW Change Pitches" plug-in (2017)
        revived to work on Macs with non-Intel processors.
        Identify pitches by note name (a-g or A-G) followed by accidental
        (#-###, b-bbb) as required.
        Matching pitches will be changed in every octave.
        To repeat the last pitch change without a confirmation dialog use
        the "Pitch Changer Repeat" menu or hold down the SHIFT key at startup.
        KEY REPLACEMENTS:
        Hit the "z", "x" or "v" keys to change the DIRECTION to "Closest",
        "Up" or "Down" respectively. The pitch names won't change.
        Hit "s" as an alternative to the "#" key.
        Hit "w" to swap the values in the "From:" and "To:" fields.
        Hit "q" to display this "Information" window.
	]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/pitch_changer.hash"
    return "Pitch Changer...", "Pitch Changer", "Change all notes of one pitch in the region to another pitch"
end
repeat_change = repeat_change or false
local directions = { "Closest", "Up", "Down" }
local config = {
    find_string = "F#",
    find_pitch = "F",
    find_offset = 1,
    new_string = "eb",
    new_pitch = "E",
    new_offset = -1,
    direction = 1,
    layer_num = 0,
    window_pos_x = false,
    window_pos_y = false,
}
local configuration = require("library.configuration")
local layer = require("library.layer")
local script_name = "pitch_changer"
function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end
function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end
function calc_pitch_string(note)
    local pitch_string = finale.FCString()
    local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
    local key_signature = cell:GetKeySignature()
    note:GetString(pitch_string, key_signature, false, false)
    return pitch_string.LuaString
end
function decode_note_string(str)
    local s = str:upper()
    local pitch = s:sub(1, 1)
    if s == "" or pitch < "A" or pitch > "G" then
        return "", 0, 0
    end
    local octave = tonumber(s:sub(-1)) or 4
    local raise_lower = 0
    s = s:sub(2)
    if s:find("[#B]") then
        for _ in s:gmatch("#") do raise_lower = raise_lower + 1 end
        for _ in s:gmatch("B") do raise_lower = raise_lower - 1 end
    end
    return pitch, raise_lower, octave
end
function user_selection()
    local max_layer = layer.max_layers()
    local x_pos = { 0, 47, 85, 140 }
    local notes = finaleplugin.Notes:gsub(" %s+", " "):gsub("\n ", "\n"):sub(2)
        local function show_info()
            finenv.UI():AlertInfo(notes, finaleplugin.ScriptGroupName .. " Information")
        end
    local dialog = finale.FCCustomLuaWindow()
        local function m_str(str)
            local s = finale.FCString()
            s.LuaString = tostring(str)
            return s
        end
        local function cstat(horiz, vert, wide, str)
            local stat = dialog:CreateStatic(horiz, vert)
            stat:SetWidth(wide)
            stat:SetText(m_str(str))
        end
        local function cedit(horiz, vert, wide, value)
            local m_offset = finenv.UI():IsOnMac() and 3 or 0
            local ctl = dialog:CreateEdit(horiz, vert - m_offset)
            ctl:SetWidth(wide)
            ctl:SetText(m_str(value))
            return ctl
        end
        local function get_string(control)
            local str = finale.FCString()
            control:GetText(str)
            return str.LuaString
        end
    dialog:SetTitle(m_str(plugindef()))
    local y = 0
    cstat(x_pos[1], y, 50, "From:")
    cstat(x_pos[3], y, 50, "To:")
    cstat(x_pos[4], y, 60, "Direction:")
    y = y + 20
    local find_pitch = cedit(x_pos[1], y, 40, config.find_string)
    local new_pitch = cedit(x_pos[3], y, 40, config.new_string)
    local save_text = { find = config.find_string, new = config.new_string }
    local swap = dialog:CreateButton(x_pos[2], y)
        swap:SetText(m_str("←→"))
        swap:SetWidth(30)
        local function value_swap()
            local str1, str2 = finale.FCString(), finale.FCString()
            str1.LuaString = save_text.find
            new_pitch:SetText(str1)
            str2.LuaString = save_text.new
            find_pitch:SetText(str2)
            save_text.find = str2.LuaString
            save_text.new = str1.LuaString
        end
    dialog:RegisterHandleControlEvent(swap, function() value_swap() end)
    local labels = finale.FCStrings()
    labels:CopyFromStringTable(directions)
    local group = dialog:CreateRadioButtonGroup(x_pos[4], y, 3)
        group:SetText(labels)
        group:SetWidth(55)
        group:SetSelectedItem(config.direction - 1)
        local function key_substitutions(ctl, kind)
            local str = finale.FCString()
            ctl:GetText(str)
            local test = str.LuaString:upper()
            if (kind == "layer" and test:find("[^0-4]"))
              or (kind ~= "layer" and test:find("[^A-G#]")) then
                local sub = 0

                for i, v in ipairs ({"Z", "X", "V", "[INQ]", "S", "W"}) do
                    if test:find(v) then sub = i break end
                end
                if sub > 0 then
                    if     sub == 6 then value_swap()
                    elseif sub == 5 and kind ~= "layer" then
                        save_text[kind] = save_text[kind] .. "#"
                    elseif sub == 4 then show_info()
                    elseif sub <= 3 then group:SetSelectedItem(sub - 1)
                    end
                end
                if sub < 6 or kind == "layer" then
                    str.LuaString = save_text[kind]
                    ctl:SetText(str)
                end
            else
                if kind == "layer" then
                    str.LuaString = str.LuaString:sub(-1)
                    ctl:SetText(str)
                end
                save_text[kind] = str.LuaString
            end
        end
    dialog:RegisterHandleControlEvent(find_pitch, function() key_substitutions(find_pitch, "find") end)
    dialog:RegisterHandleControlEvent(new_pitch,  function() key_substitutions(new_pitch,  "new" ) end)
    y = y + 25
    local info = dialog:CreateButton(x_pos[1], y)
        info:SetText(m_str("?"))
        info:SetWidth(20)
    dialog:RegisterHandleControlEvent(info, function() show_info() end)
    y = y + 25
    cstat(x_pos[3] - 58, y, 100, "Layer 1-" .. max_layer .. ":")
    save_text.layer = config.layer_num
    local layer_num = cedit(x_pos[3], y, 30, save_text.layer)
    cstat(x_pos[3] + 32, y, 90, "(0 = all layers)")
    dialog:RegisterHandleControlEvent(layer_num, function() key_substitutions(layer_num, "layer" ) end)
    local ok_button = dialog:CreateOkButton()
        ok_button:SetText(m_str("Change"))
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function() find_pitch:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function() dialog_save_position(dialog) end)
    dialog_set_position(dialog)
        local function encode_pitches(control, kind)
            local s = get_string(control)
            local pitch, raise_lower, _ = decode_note_string(s:upper())
            if pitch == "" or s:upper():sub(2):find("[AC-G]") then
                config.find_pitch = ""
                return false
            end
            config[kind .. "_pitch"] = pitch
            config[kind .. "_offset"] = raise_lower
            config[kind .. "_string"] = s
            return true
        end
    dialog:RegisterHandleOkButtonPressed(function()
            if encode_pitches(find_pitch, "find") and encode_pitches(new_pitch, "new") then
                config.layer_num = layer_num:GetInteger()
                config.direction = group:GetSelectedItem() + 1
                configuration.save_user_settings(script_name, config)
            end
        end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end
function displacement_direction(disp)
    local direction = config.direction
    if direction == 1 then
        if disp < -3 then disp = disp + 7
        elseif disp > 3 then disp = disp - 7
        end
    elseif direction == 2 then
        if disp < 0 or (disp == 0 and config.new_offset < config.find_offset) then
            disp = disp + 7
        end
    elseif direction == 3 then
        if disp > 0 or (disp == 0 and config.new_offset > config.find_offset) then
            disp = disp - 7
        end
    end
    return disp
end
function change_pitch()
    configuration.get_user_settings(script_name, config, true)
    local mod_key = finenv.QueryInvokedModifierKeys and
        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
            or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
        )
    if not (repeat_change or mod_key) then
        if not user_selection() then return end
        if config.find_pitch == "" then
            finenv.UI():AlertError(
                "Pitch names cannot be empty and must start with a single " ..
                "note name (a-g or A-G) followed by accidentals " ..
                "(#-###, b-bbb) if required.",
                "Error")
            return
        end
    end
    local displacement = string.byte(config.new_pitch) - string.byte(config.find_pitch)
    displacement = displacement_direction(displacement)

    for entry in eachentrysaved(finenv.Region(), config.layer_num) do
        if entry:IsNote() then
            for note in each(entry) do
                local pitch_string = calc_pitch_string(note)
                local pitch, raise_lower, _ = decode_note_string(pitch_string)
                if pitch == config.find_pitch and raise_lower == config.find_offset then
                    note.Displacement = note.Displacement + displacement
                    note.RaiseLower = config.new_offset
                end
            end
        end
    end
end
change_pitch()

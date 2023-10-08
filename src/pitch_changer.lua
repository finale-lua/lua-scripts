function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.14"
    finaleplugin.Date = "2023/10/08"
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
        Keys other than those six plus "a" to "g" and "#" will be ignored. 
	]]
    return "Pitch Changer...", "Pitch Changer", "Change all notes of one pitch in the region to another pitch"
end

repeat_change = repeat_change or false

local directions = { "Closest", "Up", "Down" }
local config = {
    find_string = "F#",
    find_pitch = "F",
    find_offset = 1, -- raise/lower value (to find)
    new_string = "eb",
    new_pitch = "E",
    new_offset = -1, -- raise/lower value (to replace)
    direction = 1, -- one-based index of "directions" choice
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
    s = s:sub(2) -- move past first char
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
        group:SetSelectedItem(config.direction - 1) -- (convert to 0-based index)

        local function key_substitutions(ctl, kind)
            local str = finale.FCString()
            ctl:GetText(str)
            local test = str.LuaString:upper()
            local sub = 0
            local do_layer = (kind == "layer" and test:find("[^0-4]"))
            if do_layer or (kind ~= "layer" and test:find("[^A-G#]")) then
            --  key substitutions:Closest| Up |Down |Info |SHARP| Swap
                for i, v in ipairs ({"Z", "X", "V", "[INQ]", "S", "W"}) do
                    if test:find(v) then sub = i break end
                end
                if sub > 0 then
                    if     sub == 6 then value_swap()
                    elseif sub == 5 and not do_layer then save_text[kind] = save_text[kind] .. "#"
                    elseif sub == 4 then show_info()
                    elseif sub <= 3 then group:SetSelectedItem(sub - 1)
                    end
                end
                if sub < 6 or do_layer then
                    str.LuaString = save_text[kind]
                    ctl:SetText(str)
                end
            else
                save_text[kind] = str.LuaString -- else keep new text
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
    save_text.layer = tostring(config.layer_num)
    local layer_num = cedit(x_pos[3], y, 30, tostring(save_text.layer))
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
                config.find_pitch = "" -- signal submission error
                return false
            end -- otherwise continue without error
            config[kind .. "_pitch"] = pitch
            config[kind .. "_offset"] = raise_lower
            config[kind .. "_string"] = s
            return true
        end
    dialog:RegisterHandleOkButtonPressed(function()
            if encode_pitches(find_pitch, "find") and encode_pitches(new_pitch, "new") then
                local n = tonumber(get_string(layer_num)) or 0
                config.layer_num = math.min(math.max(n, 0), max_layer)
                config.direction = group:GetSelectedItem() + 1 -- save as one-based index
                configuration.save_user_settings(script_name, config)
            end
        end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function displacement_direction(disp)
    local direction = config.direction
    if direction == 1 then -- "Closest"
        if disp < -3 then disp = disp + 7
        elseif disp > 3 then disp = disp - 7
        end
    elseif direction == 2 then -- "Up"
        if disp < 0 or (disp == 0 and config.new_offset < config.find_offset) then
            disp = disp + 7
        end
    elseif direction == 3 then -- "Down"
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
        if not user_selection() then return end -- user cancelled
        if config.find_pitch == "" then -- submission error
            finenv.UI():AlertError(
                "Pitch names cannot be empty and must start with a single " ..
                "note name (a-g or A-G) followed by accidentals " ..
                "(#-###, b-bbb) if required.",
                "Error")
            return
        end
    end
    local displacement = string.byte(config.new_pitch) - string.byte(config.find_pitch)
    displacement = displacement_direction(displacement) -- adjust for "direction" preference

    -- change the pitches ...
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

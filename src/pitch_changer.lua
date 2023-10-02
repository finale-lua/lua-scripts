function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.11"
    finaleplugin.Date = "2023/10/03"
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
        This script is inspired by Jari Williamsson's "JW Change Pitches" plug-in (2017) 
        revived to work on Macs with non-Intel processors.

        Identify pitches by note name (a-g or A-G) followed by accidental 
        (#-### or b-bbb) if required. 
        Matching pitches will be changed in every octave. 
        To repeat the last pitch change without a confirmation dialog use 
        the "Pitch Changer Repeat" menu or hold down the SHIFT key at startup.

        If the cursor is in the "From:" or "To:" fields, hit the "z", "x" or "v" keys 
        to change the DIRECTION to "Closest", "Up" or "Down" respectively. 
        (Pitch names won't change). 
        Hit "s" to swap the values in the "From:" and "To:" fields. 
        Hit "i" to display this "Information" window. 
        Keys other than those five plus "a" to "g" and "#" will be ignored. 
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
    new_pitch = "A",
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
            if type(value) == "number" then ctl:SetInteger(value)
            else ctl:SetText(m_str(value))
            end
            return ctl
        end

    dialog:SetTitle(m_str(plugindef()))
    local y = 0
    cstat(x_pos[1], y, 50, "From:")
    cstat(x_pos[3], y, 50, "To:")
    cstat(x_pos[4], y, 60, "Direction:")
    y = 20
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
        group:SetSelectedItem(config.direction - 1) -- (convert to 0-based)

        local function key_substitutions(ctl, kind)
            local str = finale.FCString()
            ctl:GetText(str)
            local test = str.LuaString:upper()
            if test ~= "" then
                local substitution = 0
            --  key substitutions:Closest| Up |Down|Info|Swap|illegal keys
                for i, v in ipairs ({"Z", "X", "V", "I", "S", "[^A-G#]"}) do
                    if test:find(v) then substitution = i break end
                end
                if substitution > 0 then
                    if substitution == 5 then value_swap()
                    elseif substitution == 4 then show_info()
                    elseif substitution <= 3 then group:SetSelectedItem(substitution - 1)
                    end
                    if substitution ~= 5 then -- restore previous text
                        str.LuaString = save_text[kind]
                        ctl:SetText(str)
                    end
                else
                    save_text[kind] = str.LuaString -- else keep new text
                end
            end
        end
    dialog:RegisterHandleControlEvent(find_pitch, function() key_substitutions(find_pitch, "find") end)
    dialog:RegisterHandleControlEvent(new_pitch,  function() key_substitutions(new_pitch,  "new" ) end)

    y = 45
    local info = dialog:CreateButton(x_pos[1], y)
        info:SetText(m_str("?"))
        info:SetWidth(20)
    dialog:RegisterHandleControlEvent(info, function() show_info() end)
    y = 70
    cstat(x_pos[3] - 58, y, 100, "Layer 1-" .. max_layer .. ":")
    local layer_num = cedit(x_pos[3], y, 20, config.layer_num)
    cstat(x_pos[3] + 22, y, 90, "(0 = all layers)")

    local ok_button = dialog:CreateOkButton()
        ok_button:SetText(m_str("Change"))
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function() find_pitch:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function() dialog_save_position(dialog) end)
    dialog_set_position(dialog)

        local function encode_pitches(control, kind)
            local str = finale.FCString()
            control:GetText(str)
            local s = str.LuaString:upper()
            local pitch, raise_lower, _ = decode_note_string(s)
            if pitch:find("[A-G]") and not s:sub(2):find("[AC-G]") then
                config[kind .. "_pitch"] = pitch
                config[kind .. "_string"] = s
                config[kind .. "_offset"] = raise_lower
                return true
            end
            config.find_pitch = "" -- signal submission error
            return false
        end
    dialog:RegisterHandleOkButtonPressed(function()
            if encode_pitches(find_pitch, "find") and encode_pitches(new_pitch, "new") then
                config.layer_num = math.min(math.max(layer_num:GetInteger(), 0), max_layer)
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

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.19"
    finaleplugin.Date = "2023/11/04"
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
        This script was inspired by Jari Williamsson's "JW Change Pitches" 
        plug-in (2017) revived to work on Macs with non-Intel processors.

        Identify "from" and "to" pitches by note name (a-g or A-G) 
        followed by accidental (#-###, b-bbb) as required. 
        Matching pitches will be changed in every octave. 
        To repeat the last pitch change without a confirmation dialog use 
        the "Pitch Changer Repeat" menu or hold down the SHIFT key at startup.

        KEY REPLACEMENTS:

        Type "z", "x" or "v" to change the DIRECTION to "Closest", 
        "Up" or "Down" respectively. 
        Type "s" as an alternative to "#". 
        Type "w" to swap the values in the "From:" and "To:" fields. 
        Type "q" to display this "Information" window. 
	]]
    return "Pitch Changer...", "Pitch Changer", "Change all notes of one pitch in the region to another pitch"
end

repeat_change = repeat_change or false

local directions = { {"Closest", "z"}, {"Up", "x"}, {"Down", "v" } }
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
local mixin = require("library.mixin")
local script_name = "pitch_changer"

local function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function calc_pitch_string(note)
    local pitch_string = finale.FCString()
    local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
    local key_signature = cell:GetKeySignature()
    note:GetString(pitch_string, key_signature, false, false)
    return pitch_string.LuaString
end

local function decode_note_string(str)
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

local function user_selection()
    local max_layer = layer.max_layers()
    local x_pos = { 0, 47, 85, 130 }
    local m_offset = finenv.UI():IsOnMac() and 3 or 0
    local notes = finaleplugin.Notes:gsub(" %s+", " "):gsub("\n ", "\n"):sub(2)
        local function show_info()
            finenv.UI():AlertInfo(notes, finaleplugin.ScriptGroupName .. " Information")
        end
    local pitch, save_text = {}, { find = config.find_string, new = config.new_string }
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    local y = 0
        local function cstat(horiz, vert, wide, str)
            dialog:CreateStatic(horiz, vert):SetWidth(wide):SetText(str)
        end
    cstat(x_pos[1], y, 50, "From:")
    cstat(x_pos[3], y, 50, "To:")
    cstat(x_pos[4], y, 60, "Direction:")

        local function value_swap()
            pitch.new:SetText(save_text.find)
            pitch.find:SetText(save_text.new)
            save_text.find = save_text.new
            save_text.new = pitch.new:GetText()
        end

        local function key_substitutions(kind)
            local t = pitch[kind]:GetText()
            local s = t:upper()
            if (kind == "layer" and s:find("[^0-4]"))
              or (kind ~= "layer" and s:find("[^A-G#]")) then
                local sub = 0
                -- substitutions:Closest| Up |Down |Info |SHARP| Swap
                for i, v in ipairs ({"Z", "X", "V", "[?Q]", "S", "W"}) do
                    if s:find(v) then sub = i break end
                end
                if sub > 0 then
                    if     sub == 6 then value_swap()
                    elseif sub == 5 and kind ~= "layer" then
                        save_text[kind] = save_text[kind] .. "#"
                    elseif sub == 4 then show_info()
                    elseif sub <= 3 then pitch.popup:SetSelectedItem(sub - 1)
                    end
                end
                if sub < 6 or kind == "layer" then
                    pitch[kind]:SetText(save_text[kind])
                end
            else
                if kind == "layer" then
                    t = t:sub(-1)
                    pitch[kind]:SetText(t)
                end
                save_text[kind] = t
            end
        end

    y = y + 20
    pitch.find = dialog:CreateEdit(x_pos[1], y - m_offset):SetWidth(40):SetText(config.find_string)
        :AddHandleCommand(function() key_substitutions("find") end)
    dialog:CreateButton(x_pos[2], y):SetText("←→"):SetWidth(30)
        :AddHandleCommand(function() value_swap() end)
    pitch.new  = dialog:CreateEdit(x_pos[3], y - m_offset):SetWidth(40):SetText(config.new_string)
        :AddHandleCommand(function() key_substitutions("new") end)
    pitch.popup = dialog:CreatePopup(x_pos[4], y):SetWidth(80)
    for _, v in ipairs(directions) do
        pitch.popup:AddString(v[1] .. " (" .. v[2] ..")")
    end
    pitch.popup:SetSelectedItem(config.direction - 1) -- 0-based index configure value

    y = y + 25
    dialog:CreateButton(x_pos[1], y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    cstat(x_pos[3] - 58, y, 60, "Layer 1-" .. max_layer .. ":")
    save_text.layer = tostring(config.layer_num)
    pitch.layer = dialog:CreateEdit(x_pos[3], y - m_offset):SetWidth(25):SetText(config.layer_num)
        :AddHandleCommand(function() key_substitutions("layer") end)

    cstat(x_pos[3] + 27, y, 90, "(0 = all layers)")
    dialog:CreateOkButton():SetText("Change")
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function() pitch.find:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function() dialog_save_position(dialog) end)
    dialog_set_position(dialog)

        local function encode_pitches(kind)
            local s = pitch[kind]:GetText()
            local p_pitch, raise_lower, _ = decode_note_string(s:upper())
            if p_pitch == "" or s:upper():sub(2):find("[AC-G]") then
                config.find_pitch = "" -- signal submission error
                return false
            end -- otherwise continue without error
            config[kind .. "_pitch"] = p_pitch
            config[kind .. "_offset"] = raise_lower
            config[kind .. "_string"] = s
            return true
        end
    dialog:RegisterHandleOkButtonPressed(function()
            if encode_pitches("find") and encode_pitches("new") then
                config.layer_num = pitch.layer:GetInteger()
                config.direction = pitch.popup:GetSelectedItem() + 1 -- save as one-based index
                configuration.save_user_settings(script_name, config)
            end
        end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function displacement_direction(disp)
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

local function change_pitch()
    configuration.get_user_settings(script_name, config, true)
    local mod_key = finenv.QueryInvokedModifierKeys and
        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
            or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
        )
    if not (repeat_change or mod_key) then
        if not user_selection() then return end -- user cancelled
        if config.find_pitch == "" then -- entry error
            finenv.UI():AlertError(
                "Pitch names cannot be empty and must start with a single " ..
                "note name (a-g or A-G) followed by accidentals " ..
                "(#-###, b-bbb) if required.", "Error"
            )
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

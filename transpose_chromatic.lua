function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 25, 2020"
    finaleplugin.CategoryTags = "Note"
    return "Transpose Chromatic...", "Transpose Chromatic",
           "Chromatic transposition of selected region (supports microtone systems)."
end

--[[
For this script to function correctly with custom key signatures, you must create a custom_key_sig.config.txt file in the
the script_settings folder with the following two options for the custom key signature you are using. Unfortunately,
the current version of JW Lua does allow scripts to read this information from the Finale document.

(This example is for 31-EDO.)

number_of_steps = 31
diatonic_steps = {0, 5, 10, 13, 18, 23, 28}
]]

local interval_names = {
    "Perfect Unison",
    "Augmented Unison",
    "Diminished Second",
    "Minor Second",
    "Major Second",
    "Augmented Second",
    "Diminished Third",
    "Minor Third",
    "Major Third",
    "Augmented Third",
    "Diminished Fourth",
    "Perfect Fourth",
    "Augmented Fourth",
    "Diminished Fifth",
    "Perfect Fifth",
    "Augmented Fifth",
    "Diminished Sixth",
    "Minor Sixth",
    "Major Sixth",
    "Augmented Sixth",
    "Diminished Seventh",
    "Minor Seventh",
    "Major Seventh",
    "Augmented Seventh",
    "Diminished Octave",
    "Perfect Octave"
}

local interval_disp_alts = {
    {0,0},  {0,1},                      -- unisons
    {1,-2}, {1,-1}, {1,0}, {1,1},       -- 2nds
    {2,-2}, {2,-1}, {2,0}, {2,1},       -- 3rds
    {3,-1}, {3,0},  {3,1},              -- 4ths
    {4,-1}, {4,0},  {4,1},              -- 5ths
    {5,-2}, {5,-1}, {5,0}, {5,1},       -- 6ths
    {6,-2}, {6,-1}, {6,0}, {6,1},       -- 7ths
    {7,-1}, {7,0}                       -- octaves
}

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local transposition = require("library.transposition")
local note_entry = require("Library.note_entry")

function add_strings_to_control(control, strings)
    local str = finale.FCString()
    for k, v in pairs(strings) do
        str.LuaString = v
        control:AddString(str)
    end
end

function do_dialog_box()
    local str = finale.FCString()
    local dialog = finale.FCCustomWindow()
    str.LuaString = "Transpose Chromatic"
    dialog:SetTitle(str)
    local current_y = 0
    local y_increment = 26
    local x_increment = 85
    -- direction
    local static = dialog:CreateStatic(0, current_y+2)
    str.LuaString = "Direction:"
    static:SetText(str)
    local direction_choice = dialog:CreatePopup(x_increment, current_y)
    add_strings_to_control(direction_choice, {"Up", "Down"})
    direction_choice:SetWidth(x_increment)
    current_y = current_y + y_increment
    -- interval
    static = dialog:CreateStatic(0, current_y+2)
    str.LuaString = "Interval:"
    static:SetText(str)
    local interval_choice = dialog:CreatePopup(x_increment, current_y)
    add_strings_to_control(interval_choice, interval_names)
    interval_choice:SetWidth(140)
    current_y = current_y + y_increment
    -- simplify checkbox
    local do_simplify = dialog:CreateCheckbox(0, current_y+2)
    str.LuaString = "Simplify Spelling"
    do_simplify:SetText(str)
    do_simplify:SetWidth(140)
    current_y = current_y + y_increment
    -- plus octaves
    static = dialog:CreateStatic(0, current_y+2)
    str.LuaString = "Plus Octaves:"
    static:SetText(str)
    local edit_x = x_increment
    if finenv.UI():IsOnMac() then
        edit_x = edit_x + 4
    end
    local plus_octaves = dialog:CreateEdit(edit_x, current_y)
    current_y = current_y + y_increment
    -- preserve existing notes
    local do_preserve = dialog:CreateCheckbox(0, current_y+2)
    str.LuaString = "Preserve Existing Notes"
    do_preserve:SetText(str)
    do_preserve:SetWidth(140)
    current_y = current_y + y_increment
    -- OK/Cxl
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    if 1 == dialog:ExecuteModal(nil) then
        local direction = 1 -- up
        if direction_choice:GetSelectedItem() > 0 then
            direction = -1 -- down
        end
        return true, direction, 1+interval_choice:GetSelectedItem(), (0 ~= do_simplify:GetCheck()),
                        plus_octaves:GetInteger(), (0 ~= do_preserve:GetCheck())
    end
    return false
end

function do_transpose_chromatic(interval, alteration, simplify, plus_octaves, preserve_originals)
    local success = true
    for entry in eachentrysaved(finenv.Region()) do
        local note_count = entry.Count
        local note_index = 0
        for note in each(entry) do
            if preserve_originals then
                note_index = note_index + 1
                if note_index > note_count then
                    break
                end
                local dup_note = note_entry.duplicate_note(note)
                if nil ~= dup_note then
                    note = dup_note
                end
            end
            if not transposition.chromatic_transpose(note, interval, alteration, simplify) then
                success = false
            end
            transposition.change_octave(note, plus_octaves)
        end
    end
    return success
end

function transpose_chromatic()
    local success, direction, interval_index, simplify, plus_octaves, preserve_originals = do_dialog_box()
    if success then
        local interval = interval_disp_alts[interval_index][1]
        local alteration = interval_disp_alts[interval_index][2]
        if not do_transpose_chromatic(direction*interval, direction*alteration, simplify, direction*plus_octaves, preserve_originals) then
            finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.", "Transposition Error")
        end
    end
end

transpose_chromatic()

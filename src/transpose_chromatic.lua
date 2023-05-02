function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true -- not recognized by JW Lua or RGP Lua v0.55
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "January 20, 2022"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.Notes = [[
        This script transposes the selected region by a chromatic interval. It works correctly even with
        microtone scales defined by custom key signatures.

        Normally the script opens a modeless window. However, if you invoke the plugin with a shift, option, or
        alt key pressed, it skips opening a window and uses the last settings you entered into the window.
        (This works with RGP Lua version 0.60 and higher.)

        If you are using custom key signatures with JW Lua or an early version of RGP Lua, you must create
        a custom_key_sig.config.txt file in a folder called `script_settings` within the same folder as the script.
        It should contains the following two lines that define the custom key signature you are using. Unfortunately,
        the JW Lua and early versions of RGP Lua do not allow scripts to read this information from the Finale document.

        (This example is for 31-EDO.)

        ```
        number_of_steps = 31
        diatonic_steps = {0, 5, 10, 13, 18, 23, 28}
        ```

        Later versions of RGP Lua (0.58 or higher) ignore this configuration file (if it exists) and read the correct
        information from the Finale document.
    ]]
    return "Transpose Chromatic...", "Transpose Chromatic", "Chromatic transposition of selected region (supports microtone systems)."
end

if not finenv.RetainLuaState then
    -- do initial setup once per Lua state
    interval_names = {
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

    interval_disp_alts = {
        {0,0},  {0,1},                      -- unisons
        {1,-2}, {1,-1}, {1,0}, {1,1},       -- 2nds
        {2,-2}, {2,-1}, {2,0}, {2,1},       -- 3rds
        {3,-1}, {3,0},  {3,1},              -- 4ths
        {4,-1}, {4,0},  {4,1},              -- 5ths
        {5,-2}, {5,-1}, {5,0}, {5,1},       -- 6ths
        {6,-2}, {6,-1}, {6,0}, {6,1},       -- 7ths
        {7,-1}, {7,0}                       -- octaves
    }
end

if not finenv.IsRGPLua then
    local path = finale.FCString()
    path:SetRunningLuaFolderPath()
    package.path = package.path .. ";" .. path.LuaString .. "?.lua"
end

local transposition = require("library.transposition")
local note_entry = require("library.note_entry")
local mixin = require("library.mixin")

local function chromatic_transpose(note, interval, alteration, simplify)
    if not note.GetTransposer then -- if our plugin does not have FCTransposer
        return transposition.chromatic_transpose(note, interval, alteration, simplify)
    end
    return note:GetTransposer():ChromaticTranspose(interval, alteration, simplify)
end

local function change_octave(note, plus_octaves)
    if not note.GetTransposer then -- if our plugin does not have FCTransposer
        return transposition.change_octave(note, plus_octaves)
    end
    return note:GetTransposer():OctaveTranspose(plus_octaves)
end

function do_transpose_chromatic(direction, interval_index, simplify, plus_octaves, preserve_originals)
    if finenv.Region():IsEmpty() then
        return
    end
    local interval = direction * interval_disp_alts[interval_index][1]
    local alteration = direction * interval_disp_alts[interval_index][2]
    plus_octaves = direction * plus_octaves
    local undostr = "Transpose Chromatic " .. tostring(finenv.Region().StartMeasure)
    if finenv.Region().StartMeasure ~= finenv.Region().EndMeasure then
        undostr = undostr .. " - " .. tostring(finenv.Region().EndMeasure)
    end
    finenv.StartNewUndoBlock(undostr, false) -- this works on both JW Lua and RGP Lua
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
            if not chromatic_transpose(note, interval, alteration, simplify) then
                success = false
            end
            change_octave(note, plus_octaves)
        end
    end
    if finenv.EndUndoBlock then -- EndUndoBlock only exists on RGP Lua 0.56 and higher
        finenv.EndUndoBlock(true)
        finenv.Region():Redraw()
    else
        finenv.StartNewUndoBlock(undostr, true) -- JW Lua automatically terminates the final undo block we start here
    end
    if not success then
        finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.", "Transposition Error")
    end
    return success
end

function create_dialog_box()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Transpose Chromatic")
    local current_y = 0
    local y_increment = 26
    local x_increment = 85
    -- direction
    dialog:CreateStatic(0, current_y + 2):SetText("Direction:")
    dialog:CreatePopup(x_increment, current_y, "direction_choice"):AddStrings("Up", "Down"):SetWidth(x_increment):SetSelectedItem(0)
    current_y = current_y + y_increment
    -- interval
    static = dialog:CreateStatic(0, current_y + 2):SetText("Interval:")
    dialog:CreatePopup(x_increment, current_y, "interval_choice"):AddStrings(table.unpack(interval_names)):SetWidth(140):SetSelectedItem(0)
    current_y = current_y + y_increment
    -- simplify checkbox
    dialog:CreateCheckbox(0, current_y + 2, "do_simplify"):SetText("Simplify Spelling"):SetWidth(140):SetCheck(0)
    current_y = current_y + y_increment
    -- plus octaves
    dialog:CreateStatic(0, current_y + 2):SetText("Plus Octaves:")
    local edit_x = x_increment + (finenv.UI():IsOnMac() and 4 or 0)
    dialog:CreateEdit(edit_x, current_y, "plus_octaves"):SetText("")
    current_y = current_y + y_increment
    -- preserve existing notes
    dialog:CreateCheckbox(0, current_y + 2, "do_preserve"):SetText("Preserve Existing Notes"):SetWidth(140):SetCheck(0)
    current_y = current_y + y_increment
    -- OK/Cxl
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
            local direction = 1 -- up
            if self:GetControl("direction_choice"):GetSelectedItem() > 0 then
                direction = -1 -- down
            end
            local interval_choice = 1 + self:GetControl("interval_choice"):GetSelectedItem()
            local do_simplify = (0 ~= self:GetControl("do_simplify"):GetCheck())
            local plus_octaves = self:GetControl("plus_octaves"):GetInteger()
            local preserve_originals = (0 ~= self:GetControl("do_preserve"):GetCheck())
            do_transpose_chromatic(direction, interval_choice, do_simplify, plus_octaves, preserve_originals)
        end
    )
    return dialog
end

function transpose_chromatic()
    global_dialog = global_dialog or create_dialog_box()
    global_dialog:RunModeless()
end

transpose_chromatic()

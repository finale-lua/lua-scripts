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

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local transposition = require("library.transposition")
local note_entry = require("Library.note_entry")

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
    local dialog = finenv.UserValueInput()
    dialog.Title = "Transpose Chromatic"
    dialog:SetTypes("NumberedList", "NumberedList", "Boolean", "Number")
    dialog:SetDescriptions("Direction", "Interval", "Simplify Spelling", "Plus Octaves")
    dialog:SetInitValues(0)
    local returnvalues = dialog:Execute()
    if nil ~= returnvalues then
        local number_of_steps = math.floor(returnvalues[1] + 0.5) -- in case user entered a decimal
        if not do_transpose_chromatic(2, -1, false, 0, true) then
            finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.", "Transposition Error")
        end
    end
end

transpose_chromatic()

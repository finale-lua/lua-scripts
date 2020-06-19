function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Octave Doubling Up", "Octave Doubling Up", "Doubles the current note an octave higher"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local transposition = require("library.transposition")

function pitch_entry_double_octave_up()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 1) then
            local note = entry:CalcLowestNote(nil)
            local new_note = entry:AddNewNote()
            transposition.set_notes_to_same_pitch(note, new_note)
            transposition.change_octave(new_note, 1)
            new_note.Tie = note.Tie
            new_note.TieBackwards = note.TieBackwards
        end
    end
end

pitch_entry_double_octave_up()

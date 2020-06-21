function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 15, 2020"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "String Harmonics 5th - Sounding Pitch", "String Harmonics 5th - Sounding Pitch",
           "Takes a sounding pitch, then creates the artificial harmonic that would produce that pitch"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local articulation = require("library.articulation")
local transposition = require("library.transposition")
local notehead = require("library.notehead")

function pitch_transform_harmonics_fifth()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 1) then
            articulation.delete_from_entry_by_char_num(entry, 111)
            local note = entry:CalcLowestNote(nil)
            transposition.change_octave(note, -2)

            local new_note = entry:AddNewNote()
            new_note.Tie = note.Tie

            transposition.set_notes_to_same_pitch(note, new_note)
            transposition.chromatic_perfect_fifth_down(new_note)

            notehead.change_shape(note, "diamond")
        end
    end
end

pitch_transform_harmonics_fifth()

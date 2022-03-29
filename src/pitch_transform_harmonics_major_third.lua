function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "March 30, 2021"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "String Harmonics M3rd - Sounding Pitch", "String Harmonics M3rd - Sounding Pitch",
           "Takes a sounding pitch, then creates the artificial harmonic that would produce that pitch"
end

local articulation = require("library.articulation")
local transposition = require("library.transposition")
local notehead = require("library.notehead")
local note_entry = require("library.note_entry")

function pitch_transform_harmonics_major_third()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 1) and (not entry:IsRest()) then
            articulation.delete_from_entry_by_char_num(entry, 111)
            local note = entry:CalcLowestNote(nil)
            transposition.change_octave(note, -2)
            local new_note = note_entry.duplicate_note(note)
            transposition.chromatic_major_third_down(new_note)
        end
    end
    -- we have to change the note shapes in a separate pass because we may need to get the stem direction
    -- after transposition, which means the entry has to be saved first
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 2) then
            local note = entry:CalcHighestNote(nil)
            notehead.change_shape(note, "diamond")
        end
    end
end

pitch_transform_harmonics_major_third()

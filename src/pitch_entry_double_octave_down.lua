function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.2"
    finaleplugin.Date = "March 31, 2021"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Octave Doubling Down", "Octave Doubling Down", "Doubles the current note an octave lower"
end

local transposition = require("library.transposition")
local note_entry = require("library.note_entry")

function pitch_entry_double_octave_down()
    for entry in eachentrysaved(finenv.Region()) do
        local note_count = entry.Count
        local note_index = 0
        for note in each(entry) do
            note_index = note_index + 1
            if note_index > note_count then
                break
            end
            local new_note = note_entry.duplicate_note(note)
            if nil ~= new_note then
                transposition.change_octave(new_note, -1)
            end
        end
    end
end

pitch_entry_double_octave_down()

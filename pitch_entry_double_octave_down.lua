function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Octave Doubling Down", "Octave Doubling Down", "Doubles the current note an octave lower"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local transposition = require("library.transposition")
local note_entry = require("Library.note_entry")

function pitch_entry_double_octave_down()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 1) then
            local note = entry:CalcLowestNote(nil)
            local new_note = note_entry.duplicate_note(note)
            transposition.change_octave(new_note, -1)
        end
    end
end

pitch_entry_double_octave_down()

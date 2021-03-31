function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "March 30, 2021"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Rotate Chord Down", "Rotate Chord Down",
           "Rotates the chord upwards, taking the top note and moving it below the rest of the chord"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local transposition = require("library.transposition")
local note_entry = require("library.note_entry")

function pitch_rotate_chord_up()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local num_octaves = note_entry.spans_number_of_octaves(entry)
            local top_note = entry:CalcHighestNote(nil)
            transposition.change_octave(top_note, -1*math.max(1,num_octaves))
        end
    end
end

pitch_rotate_chord_up()

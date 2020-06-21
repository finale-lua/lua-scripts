function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 20, 2020"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Rotate Chord Up", "Rotate Chord Up",
           "Rotates the chord upwards, taking the bottom note and moving it above the rest of the chord"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local transposition = require("library.transposition")

function pitch_rotate_chord_up()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local top_note = entry:CalcHighestNote(nil)
            local bottom_note = entry:CalcLowestNote(nil)

            while top_note:CalcMIDIKey() > bottom_note:CalcMIDIKey() do
                transposition.change_octave(bottom_note, 1)
            end
        end
    end
end

pitch_rotate_chord_up()

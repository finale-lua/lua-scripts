function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "March 30, 2021"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Rotate Chord Up", "Rotate Chord Up",
           "Rotates the chord upwards, taking the bottom note and moving it above the rest of the chord"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local transposition = require("library.transposition")
local note_entry = require("library.note_entry")

function pitch_rotate_chord_up()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local num_octaves = note_entry.calc_spans_number_of_octaves(entry)
            local top_note = entry:CalcHighestNote(nil)
            local bottom_note = entry:CalcLowestNote(nil)
            transposition.change_octave(bottom_note, math.max(1,num_octaves))
            --octave-spanning chords (such as common 4-note piano chords) need some special attention
            if top_note:IsIdenticalPitch(bottom_note) and (entry.Count > 2) then
                local new_bottom_note = entry:CalcLowestNote(nil)
                bottom_note.Displacement = new_bottom_note.Displacement
                bottom_note.RaiseLower = new_bottom_note.RaiseLower
                transposition.change_octave(bottom_note, math.max(1,num_octaves))
            end
        end
    end
end

pitch_rotate_chord_up()

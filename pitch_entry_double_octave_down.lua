function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 7, 2020"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Octave Doubling Down", "Octave Doubling Down", "Doubles the current note an octave lower"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library")

function pitch_entry_double_octave_down()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 1) then
            local note = entry:CalcLowestNote(nil)
            local pitch_string = finale.FCString()
            local measure = entry:GetMeasure()
            measure_object = finale.FCMeasure()
            measure_object:Load(measure)
            local keysig = measure_object:GetKeySignature()
            note:GetString(pitch_string, keysig, false, false)
            pitch_string = library.change_octave(pitch_string, -1)
            local new_note = entry:AddNewNote()
            new_note:SetString(pitch_string, keysig, false)
            new_note.Tie = note.Tie
            new_note.TieBackwards = note.TieBackwards
        end
    end
end

pitch_entry_double_octave_down()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 7, 2020"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Chord Line - Delete Bottom Note", "Chord Line - Delete Bottom Note",
           "Deletes the bottom note of every chord"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local note_entry = require("library.note_entry")

function pitch_entry_delete_bottom_note()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local bottom_note = entry:CalcLowestNote(nil)
            note_entry.delete_note(bottom_note)
        end
    end
end

pitch_entry_delete_bottom_note()

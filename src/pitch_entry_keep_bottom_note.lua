function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 7, 2020"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Chord Line - Keep Bottom Note", "Chord Line - Keep Bottom Note",
           "Keeps the bottom note of every chord and deletes the rest"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local note_entry = require("library.note_entry")

function pitch_entry_keep_bottom_note()
    for entry in eachentrysaved(finenv.Region()) do
        while (entry.Count >= 2) do
            local top_note = entry:CalcHighestNote(nil)
            note_entry.delete_note(top_note)
        end
    end
end

pitch_entry_keep_bottom_note()

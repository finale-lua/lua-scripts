function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 9, 2020"
    finaleplugin.CategoryTags = "Note"
    return "Add Augmentation Dots", "Add Augmentation Dots", "Add an augmentation dot to all notes and rests in selected region."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library")

function note_add_augmentation_dots()
    for entry in eachentrysaved(finenv.Region()) do
        library.add_augmentation_dot(entry)
    end
    finenv.Region():RebeamMusic()
end

note_add_augmentation_dots()

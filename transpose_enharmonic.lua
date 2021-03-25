function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 24, 2020"
    finaleplugin.CategoryTags = "Note"
    return "Transpose Enharmonic", "Transpose Enharmonic",
           "Transpose enharmonically all notes in selected regions."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local transposition = require("library.transposition")

local success = true
for entry in eachentrysaved(finenv.Region()) do
    for note in each(entry) do
        if not transposition.enharmonic_transpose(note, 1) then
            success = false
        end
    end
end
if not success then
    finenv.UI():AlertError("Some notes could not be transposed.", "Error")
end
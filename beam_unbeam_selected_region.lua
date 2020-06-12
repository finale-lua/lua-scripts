function plugindef()
   -- This function and the 'finaleplugin' namespace
   -- are both reserved for the plug-in definition.
   finaleplugin.RequireSelection = true
   finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
   finaleplugin.Version = "1.0"
   finaleplugin.Date = "June 8, 2020"
   finaleplugin.CategoryTags = "Note"
   return "Unbeam Selected Region", "Unbeam Selected Region", "Unbeam Selected Region"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library")

function unbeam_selected_region()
    for note_entry in eachentrysaved(finenv.Region()) do
        local isV2 = note_entry:GetVoice2()
        if note_entry:GetDuration() < 1024 then   -- less than quarter note duration
                note_entry:SetBeamBeat(true)
        end
        local next_entry = library.get_next_same_v (note_entry)
        if (nil ~= next_entry) and (next_entry:GetDuration() < 1024) and not finenv.Region():IsEntryPosWithin(next_entry) then
            next_entry:SetBeamBeat(true)
        end
    end
end

unbeam_selected_region()
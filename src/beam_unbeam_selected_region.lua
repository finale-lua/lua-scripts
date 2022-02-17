function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "Note"
    return "Unbeam Selected Region", "Unbeam Selected Region", "Unbeam Selected Region"
end

local note_entry = require("library.note_entry")

function unbeam_selected_region()
    for entry in eachentrysaved(finenv.Region()) do
        local isV2 = entry:GetVoice2()
        if entry:GetDuration() < 1024 then -- less than quarter note duration
            entry:SetBeamBeat(true)
        end
        local next_entry = note_entry.get_next_same_v(entry)
        if (nil ~= next_entry) and (next_entry:GetDuration() < 1024) and
            not finenv.Region():IsEntryPosWithin(next_entry) then
            next_entry:SetBeamBeat(true)
        end
    end
end

unbeam_selected_region()

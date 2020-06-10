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

function entry_get_next_same_v (entry)
    local next_entry = entry:Next()
    if entry:GetVoice2() then
        if (nil ~= next_entry) and next_entry:GetVoice2() then
            return next_entry
        end
        return nil
    end
    if entry:GetVoice2Launch() then
        while (nil ~= next_entry) and  next_entry:GetVoice2() do
            next_entry = next_entry:Next()
        end
    end
    return next_entry
end

function unbeam_selected_region()
    for note_entry in eachentrysaved(finenv.Region()) do
        local isV2 = note_entry:GetVoice2()
        if note_entry:GetDuration() < 1024 then   -- less than quarter note duration
                note_entry:SetBeamBeat(true)
        end
        local next_entry = entry_get_next_same_v (note_entry)
        if (nil ~= next_entry) and (next_entry:GetDuration() < 1024) and not finenv.Region():IsEntryPosWithin(next_entry) then
            next_entry:SetBeamBeat(true)
        end
    end
end

unbeam_selected_region()
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 9, 2020"
    finaleplugin.CategoryTags = "Note"
    return "Delete Hidden V2 Notes", "Delete Hidden V2 Notes", "Removes V2 notes if all are hidden and no rests. Useful when Finale adds unwanted playback notes, e.g., after Score Merge."
end

function note_delete_hidden_v2_notes()
    for entry in eachentrysaved(finenv.Region()) do
        if entry.Voice2Launch then
            local v2_count = 0
            local next_entry = entry:Next()
            while (nil ~= next_entry) and next_entry.Voice2 do
                if next_entry.Visible or next_entry:IsRest() then
                    v2_count = 0
                    break
                end
                v2_count = v2_count + 1
                next_entry = next_entry:Next()
            end
            if v2_count > 0 then
                next_entry = entry:Next() 
                while (nil ~= next_entry) and (v2_count > 0) do
                    next_entry.Duration = 0
                    v2_count = v2_count - 1
                    next_entry = next_entry:Next()
                 end
                 entry:SetVoice2Launch(false)
            end
        end
    end    
end

note_delete_hidden_v2_notes()
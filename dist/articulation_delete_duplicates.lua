function plugindef()
    finaleplugin.Author = "CJ Garcia"
    finaleplugin.Copyright = "© 2020 CJ Garcia Music"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "June 22, 2020"
    finaleplugin.CategoryTags = "Articulation"
    finaleplugin.RequireSelection = true
    return "Remove Duplicate Articulations", "Remove Duplicate Articulations", "Remove Duplicate Articulations"
end
function articulation_delete_duplicates()
    for note_entry in eachentrysaved(finenv.Region()) do
        local art_list = {}
        local arts = note_entry:CreateArticulations()
        for a in each(arts) do
            table.insert(art_list, a:GetID())
        end
        local sort_list = {}
        local unique_list = {}
        for k,v in ipairs(art_list) do
            if (not sort_list[v]) then
                unique_list[#unique_list + 1] = v
                sort_list[v] = true
            end
        end
        for key, value in pairs(art_list) do
            for a in each(arts) do
                a:DeleteData()
            end
        end
        for key, value in pairs(unique_list) do
            local art = finale.FCArticulation()
            art:SetNoteEntry(note_entry)
            art:SetID(value) art:SaveNew()
        end
    end
end
articulation_delete_duplicates()

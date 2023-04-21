function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 19, 2020"
    finaleplugin.CategoryTags = "Articulation"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/articulation_remove_from_rests.hash"
    return "Remove Articulations from Rests", "Remove Articulations from Rests",
           "If a rest has an articulation, it removes it (except breath marks, caesuras, or fermatas"
end
function articulation_remove_from_rests()
    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsRest() and entry:GetArticulationFlag() then
            local a = finale.FCArticulation()
            a:SetNoteEntry(entry)
            if a:LoadFirst() then
                local ad = finale.FCArticulationDef()
                if ad:Load(a:GetID()) then
                    local char = ad:GetAboveSymbolChar()
                    print(char)
                    if char ~= 85 and char ~= 34 and char ~= 44 then
                        entry:SetArticulationFlag(false)
                    end
                end
            end
        end
    end
end
articulation_remove_from_rests()

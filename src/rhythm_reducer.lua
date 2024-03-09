function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.12"
    finaleplugin.Date = "2024/03/10"
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.Notes = [[
        This script adjusts the rhythm of the selection to conform 
        to conventional notation rules and Finale's inbuilt quantization rules. 
        This may not always be exactly what you want but is 
        a great expedient for eliminating multiple (unwanted) rests 
        and as a quick check on the suitability of your rhyhthmic choices.
    ]]
    return "Rhythm Reducer", "Rhythm Reducer",
        "Adjust the rhythm of the selection to conform to conventional notation rules"
end

local function reduce_rhythms()
    for m, s in eachcell(finenv.Region()) do
        local c = finale.FCNoteEntryCell(m, s)
        c:Load()
        c:ReduceEntries()
        c:Save()
    end
end

reduce_rhythms()

function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 9, 2020"
    finaleplugin.CategoryTags = "Articulation"
    return "Autoposition Rolled Chord Articulations", "Autoposition Rolled Chord Articulations", "Autoposition Rolled Chord Articulations"
end

local config = {
    articulation_char = "g" -- Maestro rolled chord character
}

function articulation_autoposition_rolled_chords()
    local artic_defs = finale.FCArticulationDefs()
    artic_defs:LoadAll()
    for artic_def in each(artic_defs) do
        if artic_def.CopyMainSymbol and not artic_def.CopyMainSymbolHorizontally then
            finenv.UI():AlertInfo ("found artic def " .. tostring(artic_def.ItemNo), "info")
        end
    end
end

articulation_autoposition_rolled_chords()

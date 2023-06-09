function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "7/24/2022"
    finaleplugin.Notes = [[
Replaces the noteheads in a 'Finale Maestro' document with the 'Maestro Wide' glyphs included in the Alternates & Extras category.
    ]]
    return "Finale Maestro: Wide Notes", "Finale Maestro: Wide Notes", "Replaces noteheads in Finale Maestro with the wide variation."
end

local library = require("library.general_library")

function maestro_wide_noteheads()
    local default_music_font = library.get_default_music_font_name()
    if default_music_font == "Finale Maestro" or default_music_font == "FinaleMaestro" then
        local musiccharacterprefs = finale.FCMusicCharacterPrefs()
        musiccharacterprefs:Load(1)
        musiccharacterprefs.SymbolQuarterNotehead = tonumber("F604", 16)
        musiccharacterprefs.SymbolHalfNotehead = tonumber("F603", 16)
        musiccharacterprefs.SymbolWholeNotehead = tonumber("F602", 16)
        musiccharacterprefs.SymbolBrevisNotehead = tonumber("F600", 16)
        musiccharacterprefs:Save()
    end
end

maestro_wide_noteheads()
function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "4/18/2022"
    finaleplugin.Notes = [[
Replaces the noteheads in a 'Bravura' document with the larger glyphs included in the Stylistic Alternates category. These alternate glyphs (which are about 8% larger than the ones loaded by default) are the ones that the font is actually designed to use, and are the ones used by Dorico. For a discussion about these larger noteheads and why they are not used by default, see this thread in the MuseScore forum: https://musescore.org/en/node/68461
    ]]
    return "Bravura: Large Noteheads", "Bravura: Large Noteheads", "Replaces noteheads in Bravura with the intended larger size."
end

local library = require("library.general_library")

function bravura_large_noteheads()
    local default_music_font = library.get_default_music_font_name()
    if default_music_font == "Bravura" then
        local musiccharacterprefs = finale.FCMusicCharacterPrefs()
        musiccharacterprefs:Load(1)
        musiccharacterprefs.SymbolQuarterNotehead = tonumber("F4BE", 16)
        musiccharacterprefs.SymbolHalfNotehead = tonumber("F4BD", 16)
        musiccharacterprefs.SymbolWholeNotehead = tonumber("F4BC", 16)
        musiccharacterprefs.SymbolBrevisNotehead = tonumber("F4BA", 16)
        musiccharacterprefs:Save()
    end
end

bravura_large_noteheads()

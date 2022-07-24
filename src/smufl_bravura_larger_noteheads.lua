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

--JETSTREAM-- should add to library!
function getUsedFontName(standard_name)
    local font_name = standard_name
    if string.find(os.tmpname(), "/") then
        font_name = standard_name
    elseif string.find(os.tmpname(), "\\") then
        font_name = string.gsub(standard_name, "%s", "")
    end
    return font_name
end

function get_def_mus_font()
    local fontinfo = finale.FCFontInfo()
    if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
        return getUsedFontName(fontinfo:GetName())
    end
end
-------------
function bravura_notehead_update()
    local default_music_font = get_def_mus_font()
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


bravura_notehead_update()

function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "Lyric"
    return "Reset Lyrics Fonts", "Reset Lyrics Fonts", "Reset lyrics to document\'s default font settings."
end

local enigma_string = require("library.enigma_string")

-- lyrics_block: pass in one of finale.FCVerseLyricsText(), finale.FCChorusLyricsText(), finale.FCSectionLyricsText()
-- pref_id pass in the corresponding finale.FONTPREF_LYRICSVERSE, finale.FONTPREF_LYRICSCHORUS, finale.FONTPREF_LYRICSSECTION
function prefs_reset_lyrics_block_font(lyrics_block, pref_id)
    local font_info = finale.FCFontInfo()
    font_info:LoadFontPrefs(pref_id)
    if lyrics_block:LoadFirst() then
        -- The PDK Framework (inexplicably) does not implement LoadNext for lyric blocks, so
        -- we'll try up to 10000 non-sequentially and do as many as there are sequentially
        -- attempting to load non-existent items seems to cost very little in performance
        local next_id = lyrics_block.ItemNo
        local loaded_next = true
        while loaded_next do
            local lyric_text = lyrics_block:CreateString()
            -- enigma_string.change_first_string_font() changes the *initial* font, thus preserving subsequent style changes
            -- you could instead call enigma_string.change_string_font() to change the entire block's font and style
            if enigma_string.change_first_string_font(lyric_text, font_info) then
                lyrics_block:SetText(lyric_text)
                lyrics_block:Save()
            end
            next_id = next_id + 1
            while not lyrics_block:Load(next_id) do
                next_id = next_id + 1
                if (next_id > 10000) then -- we try the first 10000 sequentially, whether they exist or not
                    loaded_next = false
                    break
                end
            end
        end
    end
end

function prefs_reset_lyrics_fonts()
    prefs_reset_lyrics_block_font(finale.FCVerseLyricsText(), finale.FONTPREF_LYRICSVERSE)
    prefs_reset_lyrics_block_font(finale.FCChorusLyricsText(), finale.FONTPREF_LYRICSCHORUS)
    prefs_reset_lyrics_block_font(finale.FCSectionLyricsText(), finale.FONTPREF_LYRICSSECTION)
end

prefs_reset_lyrics_fonts()

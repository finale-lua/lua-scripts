function plugindef()
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.ExecuteHttpsCalls = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "September 13, 2023"
    finaleplugin.CategoryTags = "Lyrics"
    finaleplugin.Notes = [[
        Uses the OpenAI online api to add or correct lyrics hyphenation.
        You must have a OpenAI account and internet connection. You will
        need your API Key, which can be obtained as follows:
        
        - Login to your OpenAI account at openai.com.
        - Select API and then click on Personal
        - You will see an option to create an API Key.
        - You must keep your API Key secure. Do not share it online.
        
        To configure your OpenAI account, enter your API Key in the prefix
        when adding the script to RGP Lua. The prefix should include this line
        of code:
        
        ```
        openai_api_key = "<your secure api key>"
        ```
        
        It is important to enclose the API Key you got from OpenAI in quotes as shown
        above.
        
        The first time you use the script, RGP Lua will prompt you for permission
        to post data to the openai.com server. You can choose Allow Always to suppress
        that prompt in the future.
        
        The OpenAI service is not free, but each request for lyrics hyphenation is very
        light (using ChatGPT 3.5) and small jobs only cost a fraction of a cent.
        Check the pricing at the OpenAI site.
    ]]
    return "Lyrics Hyphenation", "Lyrics Hyphenation",
           "Add or correct lyrics hypenation using your OpenAI account."
end

--require("mobdebug").start()

--local mixin = require("library.mixin") -- mixins not working with FCCtrlEditText

local config =
{
    max_search = 500 -- the highest lyrics block to search for
}

local lyrics =
{ 
    {}, -- verses
    {}, -- choruses
    {}  -- sections
}

local function fstr(text)
    local retval = finale.FCString()
    retval.LuaString = text
    return retval
end


local function open_dialog()
    dlg = finale.FCCustomLuaWindow()
    dlg:SetTitle(fstr("Lyrics OpenAI Hyphenator"))
    local lyric_label = dlg:CreateStatic(10, 11)
    lyric_label:SetWidth(40)
    lyric_label:SetText(fstr("Lyric:"))
    local popup = dlg:CreatePopup(45, 10)
    popup:SetWidth(70)
    popup:AddString(fstr("Verse"))
    popup:AddString(fstr("Chorus"))
    popup:AddString(fstr("Section"))
    local lyric_num = dlg:CreateEdit(125, 9)
    lyric_num:SetWidth(25)
    local lyrics_box = dlg:CreateEditText(10, 35)
    lyrics_box:SetHeight(300)
    lyrics_box:SetWidth(400)
    for itemno = 1, config.max_search do
        lyric_num:SetInteger(itemno)
        local val = lyrics[1][itemno]
        if val then
            lyrics_box:SetFont(val.font)
            lyrics_box:SetText(fstr(val.text))
        else
            local font_prefs = finale.FCFontPrefs()
            if font_prefs:Load(finale.FONTPREF_LYRICSVERSE) then
                local font_info = finale:FCFontInfo()
                font_prefs:GetFontInfo(font_info)
                lyrics_box:SetFont(font_info)
            end
            lyrics_box:SetText(fstr(""))
        end
        break
    end
    dlg:CreateOkButton()
    dlg:ExecuteModal(nil)
end

local function openai_hyphenation()
    local function populate_lyrics(lyrics_text, lyrics_table)
        for itemno = 1, config.max_search do
            if lyrics_text:Load(itemno) then
                local fcstr = lyrics_text:CreateString()
                local font_info = fcstr:CreateLastFontInfo()
                fcstr:TrimEnigmaTags()
                lyrics_table[itemno] = { font = font_info, text = fcstr.LuaString }
            end
        end
    end
    for k, v in pairs({finale.FCVerseLyricsText(), finale.FCChorusLyricsText(), finale.FCSectionLyricsText() }) do
        populate_lyrics(v, lyrics[k])
    end
    open_dialog()
end

openai_hyphenation()
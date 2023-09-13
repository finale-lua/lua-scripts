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

local mixin = require("library.mixin")

local config =
{
    max_search = 500 -- the highest lyrics block to search for
}

local verses = {}
local choruses = {}
local sections = {}

local function open_dialog()
    local dlg = mixin.FCXCustomLuaWindow()
    dlg:SetTitle("Lyrics OpenAI Hyphenator")
    dlg:CreateStatic(10, 11):SetWidth(40):SetText("Lyric:")
    local popup = dlg:CreatePopup(45, 10):SetWidth(70)
            :AddString("Verse")
            :AddString("Chorus")
            :AddString("Section")
    local lyric_num = dlg:CreateEdit(125, 9):SetWidth(25)
    local lyrics_box = dlg:CreateEditText(10, 35):SetHeight(300):SetWidth(400)
    local got1 = false
    for itemno, val in pairs(verses) do
        lyric_num:SetInteger(itemno)
        lyrics_box:SetFont(val.font):SetText(val.text)
        got1 = true
        break
    end
    if not got1 then
        finenv:UI():AlertInfo("No lyrics found.", "")
        return
    end
    dlg:CreateOkButton()
    dlg:ExecuteModal()
end

local function openai_hyphenation()
    local function populate_lyrics(lyrics_text, lyrics_table)
        for itemno = 1, config.max_search do
            if lyrics_text:Load(itemno) then
                local fcstr = lyrics_text:CreateString()
                local font_info = fcstr:CreateLastFontInfo()
                fcstr:TrimEnigmaTags()
                lyrics_table[itemno] = {font = font_info, text = fcstr.LuaString}
            end
        end
    end
    populate_lyrics(finale.FCVerseLyricsText(), verses)
    populate_lyrics(finale.FCChorusLyricsText(), choruses)
    populate_lyrics(finale.FCSectionLyricsText(), sections)
    open_dialog()
end

openai_hyphenation()
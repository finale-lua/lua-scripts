function plugindef()
    finaleplugin.HandlesUndo = true
    finaleplugin.MinJWLuaVersion = 0.67
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
        when adding the script to RGP Lua. If you want OpenAI to be available in
        any script, you can add your key to the System Prefix instead.

        Your prefix should include this line of code:

        ```
        openai_api_key = "<your secure api key>"
        ```

        It is important to enclose the API Key you got from OpenAI in quotes as shown
        above.

        The first time you use the script, RGP Lua will prompt you for permission
        to post data to the openai.com server. You can choose Allow Always to suppress
        that prompt in the future.

        The OpenAI service is not free, but each request for lyrics hyphenation is very
        light (using ChatGPT 3.5) and small jobs only cost fractions of a cent.
        Check the pricing at the OpenAI site.
    ]]
    return "Lyrics Hyphenation", "Lyrics Hyphenation",
           "Add or correct lyrics hypenation using your OpenAI account."
end

require("mobdebug").start()

--local mixin = require("library.mixin") -- mixins not working with FCCtrlEditText
local openai = require("library.openai")

local config =
{
    api_model = "gpt-3.5-turbo",
    temperature = 0.8, -- the web ChatGPT default, apparently
    add_hyphens_prompt = [[
        Hyphenate the following text according the rules of musical text underlay. For languages that
        do not use spaces to separate words, nevertheless separate each word with a space and each
        pronounced syllable inside each word with a hyphen. If a single symbol represents more than
        one syllable, add the syllables with hyphens in parentheses in the most appropriate syllable
        representation for that language. Ignore any text that has the form
        ^font(...), ^size(...), or ^nfx(...), where  the ellipsis "..." is any text. Return only the
        hyphenated text without any additonal commentary. Here is the text to hyphenate:
    ]],
    remove_hyphens_prompt = [[
        Remove hyphens from the following text that has been used for musical text underlay. If a word
        should be hyphenated normally, leave those hyphens in place. For languages that do not use spaces
        to separate words, remove any spaces between words according to the rules of that language.
        If hyphenated syllables have been added in parentheses after a multi-syllable symbol,
        remove the paranthesized syllables entirely. Return only the de-hyphenated text without any
        additonal commentary. Here is the text from which to remove hyphens:
    ]]
}

local lyrics_classes =
{
    finale.FCVerseLyricsText,
    finale.FCChorusLyricsText,
    finale.FCSectionLyricsText
}

local lyrics_prefs =
{
    finale.FONTPREF_LYRICSVERSE,
    finale.FONTPREF_LYRICSCHORUS,
    finale.FONTPREF_LYRICSSECTION
}

local function fstr(text)
    local retval = finale.FCString()
    retval.LuaString = text
    return retval
end

local function update_dlg_text(lyrics_box, itemno, type)
    local lyrics_instance = lyrics_classes[type]()
    if lyrics_instance:Load(itemno) then
        local fcstr = lyrics_instance:CreateString()
        local font_info = fcstr:CreateLastFontInfo()
        fcstr:TrimEnigmaTags()
        lyrics_box:SetFont(font_info)
        lyrics_box:SetText(fcstr)
    else
        local font_prefs = finale.FCFontPrefs()
        if font_prefs:Load(lyrics_prefs[type]) then
            local font_info = finale:FCFontInfo()
            font_prefs:GetFontInfo(font_info)
            lyrics_box:SetFont(font_info)
        end
        lyrics_box:SetText(fstr(""))
    end
end

local function update_document(lyrics_box, itemno, type, name)
    finenv.StartNewUndoBlock("Update "..name.." "..itemno.." Lyrics", false)
    local lyrics_instance = lyrics_classes[type]()
    local loaded = lyrics_instance:Load(itemno)
    if not loaded and not lyrics_instance.SaveAs then
        finenv.UI():AlertError("This version of RGP Lua cannot create new lyrics blocks. Look for RGP Lua version 0.68 or higher.",
            "RGP Lua Version Error")
        finenv.EndUndoBlock(false)
        return
    end
    local font = lyrics_box:CreateFontInfo()
    local text = finale.FCString()
    lyrics_box:GetText(text)
    local new_lyrics = font:CreateEnigmaString(nil)
    new_lyrics:AppendString(text)
    lyrics_instance:SetText(new_lyrics)
    if loaded then
        lyrics_instance:Save()
    else
        lyrics_instance:SaveAs(itemno)
    end
    finenv.EndUndoBlock(true)
end

local function openai_hyphenation()
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
    lyric_num:SetInteger(1)
    local lyrics_box = dlg:CreateEdit(10, 35) --dlg:CreateEditText(10, 35)
    lyrics_box:SetHeight(300)
    lyrics_box:SetWidth(400)
    local hyphenate = dlg:CreateButton(10, 345)
    hyphenate:SetWidth(70)
    hyphenate:SetText(fstr("Hyphenate"))
    local update = dlg:CreateButton(90, 345)
    update:SetWidth(70)
    update:SetText(fstr("Update"))
    local ok = dlg:CreateOkButton()
    ok:SetText(fstr("Close"))
    dlg:RegisterHandleControlEvent(popup, function(control)
        update_dlg_text(lyrics_box, lyric_num:GetInteger(), popup:GetSelectedItem() + 1)
    end)
    dlg:RegisterHandleControlEvent(lyric_num, function(control)
        update_dlg_text(lyrics_box, lyric_num:GetInteger(), popup:GetSelectedItem() + 1)
    end)
    dlg:RegisterHandleControlEvent(update, function(control)
        local selected_text = finale.FCString()
        popup:GetText(selected_text)
        update_document(lyrics_box, lyric_num:GetInteger(), popup:GetSelectedItem() + 1, selected_text.LuaString)
    end)
    dlg:RegisterHandleControlEvent(hyphenate, function(control)
        local success, result = openai.create_completion(config.api_model, config.add_hyphens_prompt.." The very complicated hyphenation text.", config.temperature)
        if success then
            lyrics_box:SetText(fstr(result.choices[1].message.content))
        else
            finenv.UI():AlertError(result, "OpenAI")
        end
    end)
    update_dlg_text(lyrics_box, lyric_num:GetInteger(), popup:GetSelectedItem() + 1)
    dlg:ExecuteModal(nil)
end

openai_hyphenation()
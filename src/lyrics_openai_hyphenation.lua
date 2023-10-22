function plugindef()
    finaleplugin.HandlesUndo = true
    finaleplugin.MinJWLuaVersion = 0.67
    finaleplugin.ExecuteHttpsCalls = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "2.0"
    finaleplugin.Date = "September 22, 2023"
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
    return "DBG Lyrics Hyphenation...", "Lyrics Hyphenation",
           "Add or correct lyrics hypenation using your OpenAI account."
end

require('mobdebug').start()

local mixin = require("library.mixin")
local openai = require("library.openai")
local configuration = require("library.configuration")

local utils = require("library.utils")
local osutils = utils.require_embedded("luaosutils")
local https = osutils.internet

local config =
{
    use_edit_control = true,
    api_model = "gpt-4",
    temperature = 0.2, -- fairly deterministic
    add_hyphens_prompt = [[
Hyphenate the following text, delimiting words with spaces and syllables with hyphens.
If a word has multiple options for hyphenation, choose the one with the most syllables.
If words are already hyphenated, correct any mistakes found.

Do not modify text with the following patterns (where [TEXT_PLACEHOLDER] is any sequence of characters):
^font([TEXT_PLACEHOLDER])
^Font([TEXT_PLACEHOLDER])
^size([TEXT_PLACEHOLDER])
^nfx([TEXT_PLACEHOLDER])

Special Processing:
Do not modify line endings.
Identify the language. If it is a language that does not use spaces, nevertheless separate each word with a space and each pronounced syllable inside each word with a hyphen.

Input:
]],
    remove_hyphens_prompt = [[
Remove hyphens from the following text that has been used for musical text underlay.
If a word should be hyphenated according to non-musical usage, leave those hyphens in place.

Do not modify text with the following patterns (where [TEXT_PLACEHOLDER] is any sequence of characters):
^font([TEXT_PLACEHOLDER])
^Font([TEXT_PLACEHOLDER])
^size([TEXT_PLACEHOLDER])
^nfx([TEXT_PLACEHOLDER])

Special Processing:
Do not remove any punctuation other than hyphens.
Do not modify line endings.
Identify the language. If the language does not use spaces to separate words, remove any spaces between words according to the rules of that language.
If you do not recognize a word, leave it alone.

Input:
]]
}

configuration.get_parameters("lyrics_openai_hyphenation.config.txt", config)

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

config.use_edit_control = config.use_edit_control and (finenv.UI():IsOnMac() or finale.FCCtrlTextEditor)
local use_edit_text = finale.FCCtrlTextEditor ~= nil
local use_active_lyric = finale.FCActiveLyric ~= nil

-- These globals persist over multiple calls to the function
https_session = nil
update_automatically = true
global_timer_id = 1         -- per docs, we supply the timer id, starting at 1

local function update_document(lyrics_box, edit_type, popup)
    if https_session then
        return -- do not do anything if a request is in progress
    end
    local itemno = edit_type:GetInteger()
    local type = popup:GetSelectedItem() + 1
    local selected_text = finale.FCString()
    popup:GetText(selected_text)
    name = selected_text.LuaString
    finenv.StartNewUndoBlock("Update " .. name .. " " .. itemno .. " Lyrics", false)
    local lyrics_instance = lyrics_classes[type]()
    local loaded = lyrics_instance:Load(itemno)
    if not loaded and not lyrics_instance.SaveAs then
        finenv.UI():AlertError(
            "This version of RGP Lua cannot create new lyrics blocks. Look for RGP Lua version 0.68 or higher.",
            "RGP Lua Version Error")
        finenv.EndUndoBlock(false)
        return
    end
    local text_length = 0
    if config.use_edit_control then
        local new_lyrics = lyrics_box:CreateEnigmaString()
        text_length = new_lyrics.Length
        lyrics_instance:SetText(new_lyrics)
    else
        text_length = lyrics_box.Length
        lyrics_instance:SetText(lyrics_box)
    end
    if loaded then
        if text_length > 0 then
            lyrics_instance:Save()
        else
            lyrics_instance:DeleteData()
        end
    else
        if text_length > 0 then
            lyrics_instance:SaveAs(itemno)
        end
    end
    finenv.EndUndoBlock(true)
end

local function fixup_line_endings(input_str)
    local replacement = "\r"
    if finenv:UI():IsOnWindows() then
        replacement = "\r\n"
    end
    
    local result = ""
    local is_previous_carriage_return = false

    for i = 1, #input_str do
        local char = input_str:sub(i, i)

        if char == "\n" and not is_previous_carriage_return then
            result = result .. replacement
        else
            result = result .. char
            is_previous_carriage_return = (char == "\r")
        end
    end

    return result
end

local function update_to_active_lyric(lyrics_box, edit_type, popup)
    if not use_active_lyric then return end
    if edit_type:GetInteger() <= 0 then return end
    local selected_text = finale.FCString()
    popup:GetText(selected_text)
    name = selected_text.LuaString
    finenv.StartNewUndoBlock("Update Current Lyric to "..name.." "..edit_type:GetInteger(), false)
    local active_lyric = finale.FCActiveLyric()
    if active_lyric:Load() then
        if active_lyric.BlockType ~= popup:GetSelectedItem() + 1 or active_lyric.TextBlockID ~= edit_type:GetInteger() then
            active_lyric.BlockType = popup:GetSelectedItem() + 1
            active_lyric.TextBlockID = edit_type:GetInteger()
            active_lyric.Syllable = 1
            active_lyric:Save()
        end
    end
    finenv.EndUndoBlock(true)
end

local function update_dlg_text(lyrics_box, edit_type, popup)
    local itemno = edit_type:GetInteger()
    local type = popup:GetSelectedItem() + 1
    local lyrics_instance = lyrics_classes[type]()
    if lyrics_instance:Load(itemno) then
        local lyrics_string = lyrics_instance:CreateString()
        if config.use_edit_control then
            lyrics_box:SetEnigmaString(lyrics_string, lyrics_instance)
        else
            lyrics_box.LuaString = lyrics_string.LuaString
        end
    else
        local font_prefs = finale.FCFontPrefs()
        if font_prefs:Load(lyrics_prefs[type]) then
            local font_info = finale.FCFontInfo()
            font_prefs:GetFontInfo(font_info)
            if config.use_edit_control then
                lyrics_box:SetFont(font_info)
            else
                lyrics_box.LuaString = font_info:CreateEnigmaString(nil).LuaString
            end
        end
        if config.use_edit_control then
            lyrics_box:SetText("")
        end
    end
    update_to_active_lyric(lyrics_box, edit_type, popup)
end

local function hyphenate_dlg_text(lyrics_box, popup, edit_type, auto_update, dehyphenate)
    local function callback(success, result)
        if config.use_edit_control then
            lyrics_box:SetEnable(true)
        end
        popup:SetEnable(true)
        edit_type:SetEnable(true)
        https_session = nil
        if success then
            local fixed_text = fixup_line_endings(result.choices[1].message.content)
            if config.use_edit_control then
                local itemno = edit_type:GetInteger()
                local type = popup:GetSelectedItem() + 1
                local lyrics_instance = lyrics_classes[type]()
                lyrics_instance:Load(itemno) -- failure doesn't matter here
                lyrics_box:SetEnigmaString(finale.FCString(fixed_text), lyrics_instance)
            else
                lyrics_box.LuaString = fixed_text
            end
            if auto_update then
                local selected_text = finale.FCString()
                popup:GetText(selected_text)
                update_document(lyrics_box, edit_type, popup)
            end
        else
            finenv.UI():AlertError(result, "OpenAI")
        end
    end
    if https_session then
        return -- do not do anything if a request is in progress
    end
    local lyrics_text = finale.FCString()
    if config.use_edit_control then
        lyrics_text = lyrics_box:CreateEnigmaString()
    else
        update_dlg_text(lyrics_box, edit_type, popup)
        lyrics_text.LuaString = lyrics_box.LuaString
    end
    if lyrics_text.Length > 0 then
        if config.use_edit_control then
            lyrics_box:SetEnable(false)
        end
        popup:SetEnable(false)
        edit_type:SetEnable(false)
        local prompt = dehyphenate and config.remove_hyphens_prompt or config.add_hyphens_prompt
        prompt = prompt..lyrics_text.LuaString.."\nOutput:\n"
        https_session = openai.create_completion(config.api_model, prompt, config.temperature, callback)
    end
end

local function update_from_active_lyric(lyrics_box, edit_type, popup, force)
    if not use_active_lyric then return end
    local active_lyric = finale.FCActiveLyric()
    if active_lyric:Load() then
        if force or active_lyric.BlockType ~= popup:GetSelectedItem() + 1 or active_lyric.TextBlockID ~= edit_type:GetInteger() then
            if update_automatically and use_edit_text then
                local selected_text = finale.FCString()
                popup:GetText(selected_text)
                update_document(lyrics_box, edit_type, popup)
            end
            popup:SetSelectedItem(active_lyric.BlockType - 1)
            edit_type:SetInteger(active_lyric.TextBlockID)
            update_dlg_text(lyrics_box, edit_type, popup)
        end
    end
end

local function get_current_font(text_ctrl)
    local range = finale.FCRange()
    text_ctrl:GetSelection(range)                            
    local font = text_ctrl:CreateFontInfoAtIndex(range.Start)
    if not font then font = finale.FCFontInfo() end
    return font
end

local function create_dialog_box()
    dlg = mixin.FCXCustomLuaWindow()
                :SetTitle("Lyrics OpenAI Hyphenator")
    local lyric_label = dlg:CreateStatic(10, 11)
                :SetWidth(30)
                :SetText("Lyric:")
    local popup = dlg:CreatePopup(45, 10, "type")
                :SetWidth(70)
                :AddString("Verse")
                :AddString("Chorus")
                :AddString("Section")
    local lyric_num = dlg:CreateEdit(125, 9, "number")
                :SetWidth(25)
                :SetInteger(1)
    if use_edit_text then
        local ctrlfont = finale.FCFontInfo("Arial", 11)
        ctrlfont.Bold = true
        ctrlfont.Italic = false
        dlg:CreateButton(160, 10, "bold")
                :SetWidth(15)
                :SetText("B")
                :SetFont(ctrlfont)
                :AddHandleCommand(function()
                    local text_ctrl = dlg:GetControl("text")
                    local font = get_current_font(text_ctrl)
                    text_ctrl:SetFontBoldForSelection(not font:GetBold())
                end)
        ctrlfont.Bold = false
        ctrlfont.Italic = true
        dlg:CreateButton(185, 10, "italic")
                :SetWidth(15)
                :SetText("I")
                :SetFont(ctrlfont)
                :AddHandleCommand(function()
                    local text_ctrl = dlg:GetControl("text")
                    local font = get_current_font(text_ctrl)
                    text_ctrl:SetFontItalicForSelection(not font:GetItalic())
                end)
        dlg:CreateButton(210, 10, "fontsel")
                :SetWidth(60)
                :SetText("Font...")
                :AddHandleCommand(function()
                    local ui = dlg:CreateChildUI()
                    local text_ctrl = dlg:GetControl("text")
                    local font = get_current_font(text_ctrl)
                    local selector = finale.FCFontDialog(ui, font)
                    if selector:Execute() then
                        text_ctrl:SetFontForSelection(font)
                    end
                end)
        dlg:CreateStatic(280, 10, "showfont")
                :SetWidth(220)  -- 500 - accumulated width (280)  
    end
    local lyrics_box
    local yoff = 45
    if config.use_edit_control then
        if use_edit_text then
            lyrics_box = dlg:CreateTextEditor(10, yoff, "text")
        else
            lyrics_box = dlg:CreateEdit(10, yoff)
        end
        lyrics_box:SetHeight(300):SetWidth(500)
        yoff = yoff + 310
    else
        lyrics_box = finale.FCString()
    end
    local xoff = 10
    local hyphenate = dlg:CreateButton(xoff, yoff)
                :SetText("Hyphenate")
                :SetWidth(110)
    xoff = xoff + 120
    local dehyphenate = dlg:CreateButton(xoff, yoff)
                :SetText("Remove Hyphens")
                :SetWidth(110)
    if config.use_edit_control then
        xoff = xoff + 120
        local update = dlg:CreateButton(xoff, yoff)
                    :SetText("Update")
                    :SetWidth(110)
        xoff = xoff + 120
        local auto_update = dlg:CreateCheckbox(xoff, yoff)
                    :SetText("Update Automatically")
                    :SetWidth(150)
                    :SetCheck(update_automatically and 1 or 0)
        dlg:RegisterHandleControlEvent(update, function(control)
            local selected_text = finale.FCString()
            popup:GetText(selected_text)
            update_document(lyrics_box, lyric_num, popup)
        end)
        dlg:RegisterHandleControlEvent(auto_update, function(control)
            update_automatically = control:GetCheck() ~= 0
        end)
    end                    
    dlg:CreateOkButton():SetText("Close")
    dlg:RegisterInitWindow(function()
        -- RunModeless modifies it based on modifier keys, but we want it
        -- always true
        dlg.OkButtonCanClose = true
        if use_active_lyric then
            dlg:SetTimer(global_timer_id, 100) -- timer can't be set until window is created
        end
        local text_ctrl = dlg:GetControl("text")
        if text_ctrl then
            local range = finale.FCRange(0, 0)
            text_ctrl:SetSelection(range)
        end
    end)
    if use_active_lyric then
        dlg:RegisterHandleTimer(function(dialog, timer_id) -- FCXCustomLuaWindow passes the dialog as the first parameter to HandleTimer
            if timer_id ~= global_timer_id then return end
            update_from_active_lyric(lyrics_box, lyric_num, popup)
        end)
    end
    dlg:RegisterHandleControlEvent(popup, function(control)
        update_dlg_text(lyrics_box, lyric_num, popup)
    end)
    dlg:RegisterHandleControlEvent(lyric_num, function(control)
        update_dlg_text(lyrics_box, lyric_num, popup)
    end)
    dlg:RegisterHandleControlEvent(hyphenate, function(control)
        hyphenate_dlg_text(lyrics_box, popup, lyric_num, update_automatically, false)
    end)
    dlg:RegisterHandleControlEvent(dehyphenate, function(control)
        hyphenate_dlg_text(lyrics_box, popup, lyric_num, update_automatically, true)
    end)
    dlg:RegisterHandleTextSelectionChanged(function()
        local text_ctrl = dlg:GetControl("text")
        if text_ctrl then
            local selRange = finale.FCRange()
            text_ctrl:GetSelection(selRange)
            local fontInfo = text_ctrl:CreateFontInfoAtIndex(selRange.Start)
            if fontInfo then
                dlg:GetControl("showfont"):SetText(fontInfo:CreateDescription())
            end
        end
    end)
    dlg:RegisterCloseWindow(function()
        https_session = https.cancel_session(https_session)
    end)
    update_dlg_text(lyrics_box, lyric_num, popup)
    if use_active_lyric then
        update_from_active_lyric(lyrics_box, lyric_num, popup, true) -- true: force update
    end
    return dlg
end

local function openai_hyphenation()
    global_dialog = global_dialog or create_dialog_box()
    global_dialog:RunModeless()
end

openai_hyphenation()

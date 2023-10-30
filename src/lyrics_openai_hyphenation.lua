function plugindef()
    finaleplugin.HandlesUndo = true
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.ExecuteHttpsCalls = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "3.0"
    finaleplugin.Date = "October 29, 2023"
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
    api_model = "gpt-4",
    temperature = 0.2, -- fairly deterministic
    add_hyphens_prompt = [[
Hyphenate the following text, delimiting words with spaces and syllables with hyphens.
If a word has multiple options for hyphenation, choose the one with the most syllables.
If words are already hyphenated, correct any mistakes found.
If there is no text to process, return the input without modifying it.

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
If there is no text to process, return the input without modifying it.

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

-- These globals persist over multiple calls to the script
context = context or
{
    https_session = nil,
    global_timer_id = 1,
    in_prog_indicators = {"|", "/", "—", "\\"},
    in_prog_size = 4,
    in_prog_counter = nil,
    range_for_hyphenation = nil,
    current_lyric_type = 0,
    current_lyric_number = 0, 
    -- current_clean_text and current_lyric_text should only vary because of inconsequential encoding differences between Finale and FCCtrlTextEditor
    current_clean_text = nil,       -- FCString of the Enigma string the control contained the last time we synced with the document
    current_lyric_text = nil,       -- FCString of the Enigma string the document lyric block contained the last time we synced with the document
    current_editor_text = nil       -- FCString of the last contents of the control, for preserving state between executions of the script
}

local function is_current_in_editor(fcstr_lyrics)
    if not context.current_clean_text then
        local total_range = finale.FCRange()
        global_dialog:GetControl("text"):GetTotalTextRange(total_range)
        if total_range.Length <= 0 then
            return true
        end
    elseif fcstr_lyrics:Compare(context.current_clean_text) == 0 then
        return true
    end
    return false
end

local function update_document(options)
    if context.https_session then
        return -- do not do anything if a request is in progress
    end
    options = options or { update_active_lyric = true }
    assert(type(options) == "table", "options argument must be a table")
    local lyrics_box = global_dialog:GetControl("text")
    local new_lyrics = lyrics_box:CreateEnigmaString()
    local selected_text = finale.FCString()
    global_dialog:GetControl("type"):GetText(selected_text)
    finenv.StartNewUndoBlock("Update " .. selected_text.LuaString .. " " .. context.current_lyric_number .. " Lyrics", false)
    if not is_current_in_editor(new_lyrics) then
        local lyrics_instance = lyrics_classes[context.current_lyric_type]()
        local loaded = lyrics_instance:Load(context.current_lyric_number)
        local total_range = finale.FCRange()
        lyrics_box:GetTotalTextRange(total_range)
        local text_length = math.min(new_lyrics.Length, total_range.Length)
        lyrics_instance:SetText(new_lyrics)
        if loaded then
            if text_length > 0 then
                lyrics_instance:Save()
            else
                lyrics_instance:DeleteData()
            end
        else
            if text_length > 0 then
                lyrics_instance:SaveAs(context.current_lyric_number)
            end
        end
        -- reload for Finale-encoded Enigma string
        if lyrics_instance:Reload() then
            context.current_lyric_text = lyrics_instance:CreateString()
        else
            context.current_lyric_text = nil
        end
    end
    context.current_clean_text = new_lyrics
    if options.update_active_lyric then
        local active_lyric = finale.FCActiveLyric()
        if active_lyric:Load() then
            if active_lyric.BlockType ~= context.current_lyric_type or active_lyric.TextBlockID ~= context.current_lyric_number then
                active_lyric.BlockType = context.current_lyric_type
                active_lyric.TextBlockID = context.current_lyric_number
                active_lyric.Syllable = 1
                active_lyric:Save()
            end
        end
    end
    finenv.EndUndoBlock(true)
end

local function fixup_line_endings(input_str)
    local replacement = "\r"
    if finenv:UI():IsOnWindows() then
        replacement = "\r\n"
    end

    local result = {} -- a table is MUCH faster than string concatenation
    local is_previous_carriage_return = false

    for i = 1, #input_str do
        local char = input_str:sub(i, i)

        if char == "\n" and not is_previous_carriage_return then
            table.insert(result, replacement)
        else
            -- We only get here for "\n" if it is part of a CRLF pair.
            -- Therefore, omit it on Mac to avoid a double line break.
            if char ~= "\n" or finale.UI():IsOnWindows() then
                table.insert(result, char)
            end
            is_previous_carriage_return = (char == "\r")
        end
    end

    return table.concat(result)
end

local function update_dlg_text()
    local lyrics_box = global_dialog:GetControl("text")
    local lyrics_instance = lyrics_classes[context.current_lyric_type]()
    local selection_range = finale.FCRange()
    lyrics_box:GetSelection(selection_range)
    if lyrics_instance:Load(context.current_lyric_number) then
        local lyrics_string = lyrics_instance:CreateString()
        lyrics_box:SetEnigmaString(lyrics_string, lyrics_instance.BlockType)
        context.current_lyric_text = lyrics_string
    else
        local font_prefs = finale.FCFontPrefs()
        if font_prefs:Load(lyrics_prefs[context.current_lyric_type]) then
            local font_info = finale.FCFontInfo()
            font_prefs:GetFontInfo(font_info)
            lyrics_box:SetFont(font_info)
        end
        lyrics_box:SetText("")
        context.current_lyric_text = nil
    end
    context.current_clean_text = lyrics_box:CreateEnigmaString() -- always get the current clean text out of the edit control
    lyrics_box:ResetUndoState()
    lyrics_box:SetSelection(selection_range)
end

local function enable_disable()
    local enable = not context.https_session and true or false
    global_dialog:GetControl("text"):SetEnable(enable)
    global_dialog:GetControl("number"):SetEnable(enable)
    global_dialog:GetControl("type"):SetEnable(enable)
    global_dialog:GetControl("hyphenate"):SetEnable(enable)
    global_dialog:GetControl("dehyphenate"):SetEnable(enable)
end

local function get_hyphenation_text()
    local text_ctrl = global_dialog:GetControl("text")
    local selected_range = finale.FCRange()
    text_ctrl:GetSelection(selected_range)
    local fcstr = finale.FCString()
    if selected_range.Length > 0 then
        context.range_for_hyphenation = selected_range
        text_ctrl:GetTextInRange(fcstr, selected_range)
    else
        context.range_for_hyphenation = nil
        fcstr = text_ctrl:CreateEnigmaString()
    end
    return fcstr.LuaString
end

local function set_hyphenation_text(text)
    local text_ctrl = global_dialog:GetControl("text")
    if context.range_for_hyphenation then
        text_ctrl:ReplaceTextInRange(finale.FCString(text), context.range_for_hyphenation)
    else
        text_ctrl:SetEnigmaString(finale.FCString(text), context.current_lyric_type)
    end
end

local function hyphenate_dlg_text(dehyphenate)
    local function callback(success, result)
        context.https_session = nil
        enable_disable()
        global_dialog:GetControl("showprogress"):SetText("")
        if success then
            local fixed_text = fixup_line_endings(result.choices[1].message.content)
            set_hyphenation_text(fixed_text)
            if global_dialog:GetControl("auto_update"):GetCheck() ~= 0 then
                update_document()
            end
        else
            finenv.UI():AlertError(result, "OpenAI")
        end
        context.range_for_hyphenation = nil
    end
    if context.https_session then
        return -- do not do anything if a request is in progress
    end
    lyrics_text = finale.FCString(get_hyphenation_text())
    if lyrics_text.Length > 0 then
        local prompt = dehyphenate and config.remove_hyphens_prompt or config.add_hyphens_prompt
        prompt = prompt..lyrics_text.LuaString.."\nOutput:\n"
        context.https_session = openai.create_completion(config.api_model, prompt, config.temperature, callback)
        enable_disable()
    end
end

local function update_from_active_lyric(options)
    options = options or {}
    assert(type(options) == "table", "input parameter must be a table")
    local edit_type = global_dialog:GetControl("number")
    local popup = global_dialog:GetControl("type")
    local active_lyric = finale.FCActiveLyric()
    local updated = false
    if active_lyric:Load() then
        if options.force or (active_lyric.BlockType == context.current_lyric_type and active_lyric.TextBlockID == context.current_lyric_number) then
            popup:SetSelectedItem(active_lyric.BlockType - 1)
            context.current_lyric_type = active_lyric.BlockType
            edit_type:SetInteger(active_lyric.TextBlockID)
            context.current_lyric_number = active_lyric.TextBlockID
            if options.force or is_current_in_editor(global_dialog:GetControl("text"):CreateEnigmaString()) then
                update_dlg_text()
            end
            updated = true
        end
    end
    if not updated then
        local edit_text = global_dialog:GetControl("text")
        if is_current_in_editor(edit_text:CreateEnigmaString()) then
            local lyrics_instance = lyrics_classes[context.current_lyric_type]()
            if lyrics_instance:Load(context.current_lyric_number) then
                local curr_lyrics = lyrics_instance:CreateString()
                if curr_lyrics:Compare(context.current_lyric_text) ~= 0 then
                    print("updating control because document changed")
                    update_dlg_text()
                end
            else
                local total_range = finale.FCRange()
                edit_text:GetTotalTextRange(total_range)
                if total_range.Length > 0 then
                    update_dlg_text()
                end
            end
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

local function on_selection_changed(text_ctrl)
    local selRange = finale.FCRange()
    text_ctrl:GetSelection(selRange)
    local fontInfo = text_ctrl:CreateFontInfoAtIndex(selRange.Start)
    if fontInfo then
        global_dialog:GetControl("showfont"):SetText(fontInfo:CreateDescription())
    end
end

-- FCXCustomLuaWindow (mixin version) passes the dialog as the first parameter to HandleTimer
local function on_timer(dialog, timer_id)
    if timer_id ~= context.global_timer_id then return end
    update_from_active_lyric()
    if context.https_session then
        context.in_prog_counter = context.in_prog_counter and context.in_prog_counter + 1 or 1
        context.in_prog_counter = (context.in_prog_counter - 1) % context.in_prog_size + 1
        local prog_string = context.in_prog_indicators[context.in_prog_counter]
        global_dialog:GetControl("showprogress"):SetText(prog_string)
    end
end

local function on_init_window()
    -- RunModeless modifies it based on modifier keys, but we want it
    -- always true
    global_dialog.OkButtonCanClose = true
    global_dialog:SetTimer(context.global_timer_id, 100) -- timer can't be set until window is created
    context.current_lyric_type = global_dialog:GetControl("type"):GetSelectedItem() + 1
    context.current_lyric_number = global_dialog:GetControl("number"):GetInteger()
    if context.current_editor_text then
        global_dialog:GetControl("text"):SetEnigmaString(context.current_editor_text, context.current_lyric_type)
    else
        update_from_active_lyric({force = true})
    end
    local range = finale.FCRange(0, 0)
    global_dialog:GetControl("text"):SetSelection(range)
end

local function on_close_window()
    global_dialog:StopTimer(context.global_timer_id)
    context.https_session = https.cancel_session(context.https_session)
    context.range_for_hyphenation = nil
    enable_disable()
    global_dialog:GetControl("showprogress"):SetText("")
    if global_dialog:GetControl("auto_update"):GetCheck() ~= 0 then
        update_document()
    end
    context.current_editor_text = global_dialog:GetControl("text"):CreateEnigmaString()
end

local function create_dialog_box()
    -- size parameters
    local text_height = 300
    local text_width = 500
    dlg = mixin.FCXCustomLuaWindow()
            :SetTitle("Lyrics OpenAI Hyphenator")
    -- Lyrics type, number, and font selections
    dlg:CreateStatic(10, 11)
            :SetWidth(30)
            :SetText("Lyric:")
    context.current_lyric_type = finale.RAWTEXTTYPE_VERSELYRIC
    dlg:CreatePopup(45, 10, "type")
            :SetWidth(70)
            :AddString("Verse")
            :AddString("Chorus")
            :AddString("Section")
            :SetSelectedItem(context.current_lyric_type)
            :AddHandleCommand(function(popup)
                local ctrl_val = popup:GetSelectedItem() + 1
                if ctrl_val ~= context.current_lyric_type then
                    context.current_lyric_type = ctrl_val
                    update_dlg_text()
                end
            end)
    context.current_lyric_number = 1
    dlg:CreateEdit(125, 9, "number")
            :SetWidth(25)
            :SetInteger(context.current_lyric_number)
            :AddHandleCommand(function(edit_number)
                local ctrl_val = math.max(1, edit_number:GetInteger())
                if ctrl_val ~= context.current_lyric_number then
                    context.current_lyric_number = ctrl_val
                    update_dlg_text()
                end
                if ctrl_val ~= edit_number:GetInteger() then
                    edit_number:SetInteger(ctrl_val)
                end
            end)
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
            :SetWidth(text_width - 280 - 20)  -- accumulated width (280)
    dlg:CreateStatic(text_width - 15, 8, "showprogress")
            :SetWidth(15)
            :SetHeight(22)
            :SetText("")
            :SetFont(finale.FCFontInfo("Arial", 14, 0x01)) -- 0x01: bold
            :SetTextColor(0, 255, 0) -- green
    local yoff = 45
    -- text editor
    dlg:CreateTextEditor(10, yoff, "text")
            :SetHeight(text_height)
            :SetWidth(text_width)
            :SetUseRichText(true)
            :SetAutomaticEditing(true) -- affects mac only: double-dashes converted to em-dashees and quotes converted to curly quotes, among others
            :SetWordWrap(true)
    yoff = yoff + 310
    -- command buttons
    local xoff = 10
    dlg:CreateButton(xoff, yoff, "hyphenate")
            :SetText("Hyphenate")
            :SetWidth(110)
            :AddHandleCommand(function()
                hyphenate_dlg_text(false)
            end)
    xoff = xoff + 120
    dlg:CreateButton(xoff, yoff, "dehyphenate")
            :SetText("Remove Hyphens")
            :SetWidth(110)
            :AddHandleCommand(function()
                hyphenate_dlg_text(true)
            end)
    xoff = xoff + 120
    dlg:CreateButton(xoff, yoff, "update")
            :SetText("Update")
            :SetWidth(110)
            :AddHandleCommand(function(control) update_document() end)
    xoff = xoff + 120
    dlg:CreateCheckbox(xoff, yoff, "auto_update")
            :SetText("Update Automatically")
            :SetWidth(150)
            :SetCheck(1)
    yoff = yoff + 30
    dlg:CreateCloseButton(text_width - 80, yoff)
            :SetWidth(80)
    -- registrations
    dlg:RegisterInitWindow(on_init_window)
    dlg:RegisterCloseWindow(on_close_window)
    dlg:RegisterHandleTimer(on_timer)
    dlg:RegisterHandleTextSelectionChanged(on_selection_changed)
    return dlg
end

local function openai_hyphenation()
    global_dialog = global_dialog or create_dialog_box()
    require('mobdebug').start()
    global_dialog:RunModeless()
end

openai_hyphenation()

function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.NoStore = true
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "November 15, 2023"
    finaleplugin.CategoryTags = "Expressions"
    finaleplugin.Notes = [[
            Allows you to construct a string from SMuFL multi-segment "wiggle" characters
            that can be use for random/uneven vibrato expressions.
        ]]
    return "SMuFL Multi-Segment Vibrato...", "SMuFL Multi-Segment Vibrato", "Allows you to construct a string from SMuFL multi-segment \"wiggle\" characters"
end

local library = require('library.general_library')
local mixin = require('library.mixin')

local smufl_list = library.get_smufl_font_list()

local function win_mac(win_val, mac_val)
    if finenv.UI():IsOnWindows() then
        return win_val
    end
    return mac_val
end

local function on_font_changed(control)
    local fontlist = global_dialog:GetControl("fontlist")
    local selected_item = fontlist:GetSelectedItem()
    local fontsize = global_dialog:GetControl("editsize"):GetInteger()
    -- ToDo: skip if neither selected_item nor fontsize (to avoid churn)
    local font_name = finale.FCString()
    fontlist:GetItemText(selected_item, font_name)
    local font = finale.FCFontInfo(font_name, fontsize)
    global_dialog:GetControl("editor"):SetFont(font)
end

local function on_char_button_hit(control)
    local text = finale.FCString()
    control:GetText(text)
    global_dialog:GetControl("editor"):ReplaceSelectedText(text)
end

local function create_dialog_box()
    local text_height = 150
    local text_width = 700
    local y_off = 5
    local x_off = 0
    local y_sep = 10
    local x_sep = 10
    local button_height = 20
    local dlg = mixin.FCXCustomLuaWindow()
        :SetTitle("Multi-Segment Vibrato")
    -- SMuFL popup and size
    local popup = dlg:CreatePopup(x_off, y_off, "fontlist")
        :SetWidth(200)
        :AddHandleCommand(on_font_changed)
    local bravura_index
    local finale_index
    for fontname, _ in pairsbykeys(smufl_list) do
        if fontname == "Bravura" then
            bravura_index = popup:GetCount()
        elseif fontname == "Finale Maestro" then
            finale_index = popup:GetCount()
        end
        popup:AddString(fontname)
    end
    if popup:GetCount() <= 0 then
        finenv.UI():AlertInfo("No SMuFL fonts found on system.", "Not Found")
        finenv.RetainLuaState = false -- in case it was set somewhere
        return nil
    end
    if bravura_index then
        popup:SetSelectedItem(bravura_index)
    elseif finale_index then
        popup:SetSelectedItem(finale_index)
    else
        popup:SetSelectedItem(0)
    end
    x_off = x_off + 200 + x_sep
    dlg:CreateStatic(x_off, y_off)
        :SetText("Size:")
        :SetWidth(35)
    x_off = x_off + 35 + x_sep
    dlg:CreateEdit(x_off, y_off - win_mac(1, 5), "editsize")
        :SetInteger(24)
        :AddHandleCommand(on_font_changed)
    y_off = y_off + button_height + y_sep
    -- SMuFL display area
    x_off = 0
    local fontname_text = finale.FCString()
    popup:GetItemText(popup:GetSelectedItem(), fontname_text)
    local initial_font = finale.FCFontInfo(fontname_text, dlg:GetControl("editsize"):GetInteger())
    dlg:CreateTextEditor(x_off, y_off, "editor")
        :SetWidth(text_width)
        :SetHeight(text_height)
        :SetFont(initial_font)
        :SetWordWrap(false)
        :SetReadOnly(false)
        :SetUseRichText(true)
        :SetAutomaticEditing(false)
    y_off = y_off + text_height + y_sep
    -- squiggle buttons
    local function add_button(utf8char, fontsize)
        dlg:CreateButton(x_off, y_off)
            :SetWidth(30)
            :SetText(finale.FCString(utf8.char(utf8char)))
            :SetFont(finale.FCFontInfo(fontname_text, fontsize))
            :AddHandleCommand(on_char_button_hit)
        x_off = x_off + 30 + x_sep
    end
    local function add_button_row(label_text, utf8_first, utf8_last, fontsize)
        x_off = 0
        dlg:CreateStatic(x_off, y_off)
            :SetWidth(200)
            :SetText("-----------" .. label_text .. "-----------")
        y_off = y_off + button_height
        for utf8char = utf8_first, utf8_last do
            add_button(utf8char, fontsize)
        end
        y_off = y_off + button_height + 5
    end
    add_button_row("smallest", 0xeacd, 0xead3, win_mac(24, 24))
    add_button_row("small", 0xead4, 0xeada, win_mac(24, 24))
    add_button_row("medium", 0xeadb, 0xeae1, win_mac(20, 24))
    add_button_row("large", 0xeae2, 0xeae8, win_mac(18, 24))
    add_button_row("largest", 0xeae9, 0xeaef, win_mac(14, 18))
    add_button_row("random", 0xeaf0, 0xeaf3, win_mac(12, 16))
    y_off = y_off + y_sep
    -- copy and close buttons
    x_off = 0
    dlg:CreateButton(x_off, y_off, "copy2clip")
        :SetWidth(150)
        :SetText("Copy to Clipboard")
        :AddHandleCommand(function(control)
            dlg:GetControl("editor"):TextToClipboard()
            dlg:CreateChildUI():AlertInfo("Text copied to clipboard.", "Text Copied")
        end)
    x_off = x_off + 150 + x_sep
    dlg:CreateCloseButton(text_width - 70, y_off)
        :SetWidth(70)
    return dlg
end

local function smufl_multisegment_vibrato()
    global_dialog = global_dialog or create_dialog_box()
    if global_dialog then
        global_dialog:RunModeless()
    end
end

smufl_multisegment_vibrato()

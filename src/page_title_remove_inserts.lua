function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "February 21, 2021"
    finaleplugin.CategoryTags = "Page"
    finaleplugin.Notes = [[
        Finale makes it surprisingly difficult to remove text inserts from an existing Page Text.
        It requires extremely precise positioning of the cursor, and even then it frequently modifies
        the insert instead of the Page Text. This is especially true if the Page Text contains *only* 
        one or more inserts. This script allows you to select a Page Text and remove
        the inserts with no fuss.

        For version 0.68 and higher of RGP Lua, you can edit the text inserts directly.
    ]]
    return "Remove Inserts From Page Text...", "Remove Inserts From Page Text",
           "Removes text inserts from selected Page Text."
end

local mixin = require("library.mixin")
local enigma_string = require("library.enigma_string")

local editor_available = finale.FCCtrlTextEditor and true or false
local initial_replace_option = true
local clean_texts = {}
local page_texts_with_inserts = {}

function on_update_editor(dialog)
    local editor = dialog:GetControl("editor")
    if editor then -- editor with be nil if editor_available is false
        local selected_page_text = dialog:GetControl("pagetext"):GetSelectedItem() + 1
        local page_text = page_texts_with_inserts[selected_page_text]
        local text = page_text:CreateTextString()
        enigma_string.remove_inserts(text, dialog:GetControl("replace"):GetCheck() ~= 0, editor_available)
        editor:SetEnigmaString(text)
        local range = finale.FCRange(0, 0)
        dialog:GetControl("editor"):SetSelection(range)
    end
end

local function get_current_font(text_ctrl)
    local range = finale.FCRange()
    text_ctrl:GetSelection(range)
    local font = text_ctrl:CreateFontInfoAtIndex(range.Start)
    if not font then font = finale.FCFontInfo() end
    return font
end

function create_dialog()
    local current_y = 0
    local current_x = 0
    local y_increment = 10
    local x_increment = 10
    local label_width = 65
    local popup_width = 190
    local total_width = 500
    local editor_height = 150
    local button_height = 20

    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle("Select Page Text")

    -- page text
    dialog:CreateStatic(current_x, current_y+2)
        :SetText("Page Text:")
        :SetWidth(label_width)
    current_x = current_x + label_width + x_increment
    local page_text = dialog:CreatePopup(current_x, current_y, "pagetext")
        :SetWidth(popup_width)
        :AddHandleCommand(function(_)
            on_update_editor(dialog)
        end)
    for _, v in pairs(clean_texts) do
        page_text:AddString(v)
    end
    current_x = current_x + popup_width + x_increment
    if editor_available then
        dialog:CreateButton(current_x, current_y, "fontsel")
        :SetWidth(60)
        :SetText("Font...")
        :AddHandleCommand(function()
            local ui = dialog:CreateChildUI()
            local editor = dialog:GetControl("editor")
            local font = get_current_font(editor)
            local selector = finale.FCFontDialog(ui, font)
            if selector:Execute() then
                editor:SetFontForSelection(font)
            end
        end)
        current_x = current_x + 60 + x_increment
        dialog:CreateStatic(current_x, current_y, "showfont")
            :SetWidth(total_width - current_x)  -- accumulated width (280)
    end
    current_y = current_y + button_height + y_increment

    -- editor (if available)
    if editor_available then
        dialog:CreateTextEditor(0, current_y, "editor")
            :SetWidth(total_width)
            :SetHeight(editor_height)
            :SetUseRichText(true)
            :SetReadOnly(false)
            :SetAutomaticEditing(true)
            :SetWordWrap(false)
        current_y = current_y + editor_height + y_increment
    end

    -- Replace Checkbox
    dialog:CreateCheckbox(0, current_y+2, "replace")
        :SetText("Replace Inserts With Generic Text")
        :SetWidth(250)
        :SetCheck(initial_replace_option and 1 or 0)
        :AddHandleCommand(function(_)
            on_update_editor(dialog)
        end)
    
    -- OK/Cxl
    dialog:CreateOkButton()
    dialog:CreateCancelButton()

    -- Registrations
    dialog:RegisterInitWindow(function()
        on_update_editor(dialog)
    end)
    dialog:RegisterTextSelectionChanged(function(text_ctrl)
        local selRange = finale.FCRange()
        text_ctrl:GetSelection(selRange)
        local fontInfo = text_ctrl:CreateFontInfoAtIndex(selRange.Start)
        if fontInfo then
            dialog:GetControl("showfont"):SetText(fontInfo:CreateDescription())
        end
    end)

    return dialog
end

function page_title_remove_inserts()
    local page_texts = finale.FCPageTexts()
    page_texts:LoadAll()
    for page_text in each(page_texts) do
        local clean_text = page_text:CreateTextString()
        if clean_text:ContainsEnigmaTextInsert() then
            clean_text:TrimEnigmaFontTags()
            if nil ~= clean_text then
                local page_string
                if page_text.FirstPage == page_text.LastPage then
                    page_string = " [" .. page_text.FirstPage .. "]"
                elseif page_text.LastPage == 0 then
                    page_string = " [" .. page_text.FirstPage .. " - end]"
                else
                    page_string = " [" .. page_text.FirstPage .. " - " .. page_text.LastPage .. "]"
                end
                table.insert(clean_texts, clean_text.LuaString .. page_string)
                table.insert(page_texts_with_inserts, page_text)
            end
        end
    end
    local dialog = create_dialog()
    if dialog:ExecuteModal() == finale.EXECMODAL_OK then
        local selected_page_text = page_texts_with_inserts[1 + dialog:GetControl("pagetext"):GetSelectedItem()]
        local editor = dialog:GetControl("editor")
        if editor then
            local text = editor:CreateEnigmaString()
            text.LuaString = text.LuaString:gsub("%^%^", "^")
            selected_page_text:SaveTextString(text)
        else
            local selected_text_string = selected_page_text:CreateTextString()
            enigma_string.remove_inserts(selected_text_string, dialog:GetControl("replace"):GetCheck() ~= 0, editor_available)
            selected_page_text:SaveTextString(selected_text_string)
        end
        selected_page_text:Save()
        finenv.UI():RedrawDocument()
    end
end

page_title_remove_inserts()

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
    ]]
    return "Remove Inserts From Page Text...", "Remove Inserts From Page Text",
           "Removes text inserts from selected Page Text."
end

local enigma_string = require("library.enigma_string")

function do_dialog_box(clean_texts)
    local str = finale.FCString()
    local dialog = finale.FCCustomWindow()
    str.LuaString = "Select Page Text"
    dialog:SetTitle(str)
    local current_y = 0
    local y_increment = 26
    local x_increment = 65

    -- page text
    static = dialog:CreateStatic(0, current_y+2)
    str.LuaString = "Page Text:"
    static:SetText(str)
    local page_text = dialog:CreatePopup(x_increment, current_y)
    for k, v in pairs(clean_texts) do
        str.LuaString = v
        page_text:AddString(str)
    end
    page_text:SetWidth(250)
    current_y = current_y + y_increment

    -- Replace Checkbox
    local do_replace = dialog:CreateCheckbox(0, current_y+2)
    str.LuaString = "Replace Inserts With Generic Text"
    do_replace:SetText(str)
    do_replace:SetWidth(250)
    do_replace:SetCheck(1)
    current_y = current_y + y_increment

    -- OK/Cxl
    dialog:CreateOkButton()
    dialog:CreateCancelButton()

    if finale.EXECMODAL_OK == dialog:ExecuteModal(nil) then
        return true, 1+page_text:GetSelectedItem(), (0 ~= do_replace:GetCheck())
    end
    return false
end

function page_title_remove_inserts()
    local page_texts = finale.FCPageTexts()
    page_texts:LoadAll()
    local clean_texts = {}
    local page_texts_with_inserts = {}
    for page_text in each(page_texts) do
        local clean_text = page_text:CreateTextString()
        if clean_text:ContainsEnigmaTextInsert() then
            clean_text:TrimEnigmaFontTags()
            if nil ~= clean_text then
                table.insert(clean_texts, clean_text.LuaString)
                table.insert(page_texts_with_inserts, page_text)
            end
        end
    end
    local success, selected_text_index, do_replace = do_dialog_box(clean_texts)
    if success then
        local selected_page_text = page_texts_with_inserts[selected_text_index]
        local selected_text_string = selected_page_text:CreateTextString()
        enigma_string.remove_inserts(selected_text_string, do_replace)
        selected_page_text:SaveTextString(selected_text_string)
        selected_page_text:Save()
    end
end

page_title_remove_inserts()

function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "February 21, 2021"
    finaleplugin.CategoryTags = "Page"
    return "Remove Inserts From Page Text...", "Remove Inserts From Page Text",
           "Removes text inserts from selected Page Text."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local enigma_string = require("library.enigma_string")

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
    local dialog = finenv.UserValueInput()
    dialog.Title = "Select Page Text"
    dialog:SetTypes("NumberedList", "Boolean")
    dialog:SetDescriptions("Page Text", "Replace Inserts With Generic Text")
    dialog:SetInitValues("", true)
    dialog:SetLists(clean_texts, nil)
    local returnvalues = dialog:Execute()
    if nil ~= returnvalues then
        local selected_page_text = page_texts_with_inserts[returnvalues[1]]
        local selected_text_string = selected_page_text:CreateTextString()
        enigma_string.remove_inserts(selected_text_string, returnvalues[2])
        selected_page_text:SaveTextString(selected_text_string)
        selected_page_text:Save()
    end
end

page_title_remove_inserts()

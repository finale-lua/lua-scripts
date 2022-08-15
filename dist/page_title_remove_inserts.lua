local __imports = {}
local __import_results = {}
function require(item)
    if not __imports[item] then
        error("module '" .. item .. "' not found")
    end
    if __import_results[item] == nil then
        __import_results[item] = __imports[item]()
        if __import_results[item] == nil then
            __import_results[item] = true
        end
    end
    return __import_results[item]
end
__imports["library.enigma_string"] = function()

    local enigma_string = {}
    local starts_with_font_command = function(string)
        local text_cmds = {"^font", "^Font", "^fontMus", "^fontTxt", "^fontNum", "^size", "^nfx"}
        for i, text_cmd in ipairs(text_cmds) do
            if string:StartsWith(text_cmd) then
                return true
            end
        end
        return false
    end


    function enigma_string.trim_first_enigma_font_tags(string)
        local font_info = finale.FCFontInfo()
        local found_tag = false
        while true do
            if not starts_with_font_command(string) then
                break
            end
            local end_of_tag = string:FindFirst(")")
            if end_of_tag < 0 then
                break
            end
            local font_tag = finale.FCString()
            if string:SplitAt(end_of_tag, font_tag, nil, true) then
                font_info:ParseEnigmaCommand(font_tag)
            end
            string:DeleteCharactersAt(0, end_of_tag + 1)
            found_tag = true
        end
        if found_tag then
            return font_info
        end
        return nil
    end

    function enigma_string.change_first_string_font(string, font_info)
        local final_text = font_info:CreateEnigmaString(nil)
        local current_font_info = enigma_string.trim_first_enigma_font_tags(string)
        if (current_font_info == nil) or not font_info:IsIdenticalTo(current_font_info) then
            final_text:AppendString(string)
            string:SetString(final_text)
            return true
        end
        return false
    end

    function enigma_string.change_first_text_block_font(text_block, font_info)
        local new_text = text_block:CreateRawTextString()
        if enigma_string.change_first_string_font(new_text, font_info) then
            text_block:SaveRawTextString(new_text)
            return true
        end
        return false
    end



    function enigma_string.change_string_font(string, font_info)
        local final_text = font_info:CreateEnigmaString(nil)
        string:TrimEnigmaFontTags()
        final_text:AppendString(string)
        string:SetString(final_text)
    end

    function enigma_string.change_text_block_font(text_block, font_info)
        local new_text = text_block:CreateRawTextString()
        enigma_string.change_string_font(new_text, font_info)
        text_block:SaveRawTextString(new_text)
    end

    function enigma_string.remove_inserts(fcstring, replace_with_generic)


        local text_cmds = {
            "^arranger", "^composer", "^copyright", "^date", "^description", "^fdate", "^filename", "^lyricist", "^page",
            "^partname", "^perftime", "^subtitle", "^time", "^title", "^totpages",
        }
        local lua_string = fcstring.LuaString
        for i, text_cmd in ipairs(text_cmds) do
            local starts_at = string.find(lua_string, text_cmd, 1, true)
            while nil ~= starts_at do
                local replace_with = ""
                if replace_with_generic then
                    replace_with = string.sub(text_cmd, 2)
                end
                local after_text_at = starts_at + string.len(text_cmd)
                local next_at = string.find(lua_string, ")", after_text_at, true)
                if nil ~= next_at then
                    next_at = next_at + 1
                else
                    next_at = starts_at
                end
                lua_string = string.sub(lua_string, 1, starts_at - 1) .. replace_with .. string.sub(lua_string, next_at)
                starts_at = string.find(lua_string, text_cmd, 1, true)
            end
        end
        fcstring.LuaString = lua_string
    end

    function enigma_string.expand_value_tag(fcstring, value_num)
        value_num = math.floor(value_num + 0.5)
        fcstring.LuaString = fcstring.LuaString:gsub("%^value%(%)", tostring(value_num))
    end

    function enigma_string.calc_text_advance_width(inp_string)
        local accumulated_string = ""
        local accumulated_width = 0
        local enigma_strings = inp_string:CreateEnigmaStrings(true)
        for str in each(enigma_strings) do
            accumulated_string = accumulated_string .. str.LuaString
            if string.sub(str.LuaString, 1, 1) ~= "^" then
                local fcstring = finale.FCString()
                local text_met = finale.FCTextMetrics()
                fcstring.LuaString = accumulated_string
                local font_info = fcstring:CreateLastFontInfo()
                fcstring.LuaString = str.LuaString
                fcstring:TrimEnigmaTags()
                text_met:LoadString(fcstring, font_info, 100)
                accumulated_width = accumulated_width + text_met:GetAdvanceWidthEVPUs()
            end
        end
        return accumulated_width
    end
    return enigma_string
end
function plugindef()


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

    local do_replace = dialog:CreateCheckbox(0, current_y+2)
    str.LuaString = "Replace Inserts With Generic Text"
    do_replace:SetText(str)
    do_replace:SetWidth(250)
    do_replace:SetCheck(1)
    current_y = current_y + y_increment

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

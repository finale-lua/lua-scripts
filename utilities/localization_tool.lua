function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.ExecuteHttpsCalls = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "February 3, 2024"
    finaleplugin.MinJWLuaVersion = "0.71"
    finaleplugin.Notes = [[
        This script provides a set of localization services for developers of scripts to make localization
        as simple as possible. It uses calls to OpenAI to automatically translate words and phrases. However,
        such translations should always be checked with fluent speakers before presenting them to users.

        Functions include:

        - Automatically create a table of all quoted strings in the library. The user can then edit this
            down to the user-facing strings that need to be localized.
        - Given a table of strings, creates a localization file for a specified language.
        - Create a localized `plugindef` function for a script.
        
        Users of this script will get the best results if they use it in tandem with an indegrated development
        environment (IDE) such as Visual Studio Code or with a text editor. The script copies text to the clipboard
        which you can then paste into the IDE or editor.
    ]]
    return "Localization Tool...", "Localization Tool", "Automates the process of localizing scripts in the Finale Lua repository."
end

-- luacheck: ignore 11./global_dialog

local client = require("library.client")
local library = require("library.general_library")
local openai = require("library.openai")
local mixin = require("library.mixin")
local utils = require("library.utils")

local osutils = require("luaosutils")
local https = osutils.internet

local tab_str = "    "
local src_directory = (function()
    local curr_path = library.calc_script_filepath()
    local path_name = finale.FCString()
    finale.FCString(curr_path):SplitToPathAndFile(path_name, nil)
    return path_name.LuaString .. "../src/"
end)()

global_contents = global_contents or {}
local in_popup_handler = false
local popup_cur_sel = -1
local in_text_change_event = false
local https_session

local finale_supported_languages = {
    ["Dutch"] = "nl",
    ["English"] = "en",
    ["German"] = "de",
    ["French"] = "fr",
    ["Italian"] = "it",
    ["Japanese"] = "ja",
    ["Polish"] = "pl",
    ["Spanish"] = "es",
    ["Swedish"] = "sv"
}

--[[
% create_localized_base_table

Creates and returns a table of localizable strings by searching the top-level script for
quoted strings. While this may be useful at user-runtime, the primary use case it targets
is as a developer tool to aid in the creation of a table to be embedded in the script.

The returned table is in this form:

```
{
    ["<found string>"] = "found-string",
    ... -- for every string found in the script
}

Only the top-level script is searched. This is the script at the path specified by finenv.Running

: (table) a table containing the found strings
]]
local function create_localized_base_table(file_path)
    local retval = {}
    file_path = client.encode_with_client_codepage(file_path)
    local file <close> = io.open(file_path, "r")
    if file then
        local function extract_strings(file_content)
            local i = 1
            local length = #file_content
            return function()
                while i <= length do
                    local char = string.sub(file_content, i, i)
                    if char == "'" or char == '"' then
                        local quote = char
                        local str = quote
                        i = i + 1
                        while i <= length do
                            char = string.sub(file_content, i, i)
                            local escaped = false
                            if char == '\\' then
                                i = i + 1
                                char = string.sub(file_content, i, i)
                                if char == "n" then char = "\n" end
                                if char == "r" then char = "\r" end
                                if char == "t" then char = "\t" end
                                -- may need to add more escape codes here
                                escaped = true
                            end
                            str = str .. char
                            -- Check for the end of the quoted string
                            if not escaped and char == quote then
                                break
                            end
                            i = i + 1
                        end
                        i = i + 1
                        return str:sub(2, -2)
                    end
                    i = i + 1
                end
                -- End of file, return nil to terminate the loop
                return nil
            end
        end
        for line in file:lines() do
            if not string.match(line, "^%s*%-%-") then
                for found_string in extract_strings(line) do
                    retval[found_string] = found_string
                end
            end
        end
    end
    return retval
end

local function make_flat_table_string(file_path, lang, t)
    local file_name = finale.FCString()
    finale.FCString(file_path):SplitToPathAndFile(nil, file_name)
    local concat = {}
    table.insert(concat, "--\n")
    table.insert(concat, "-- Localization " .. lang .. ".lua for " .. file_name.LuaString .. "\n")
    table.insert(concat, "--\n")
    table.insert(concat, "loc = {\n")
    for k, v in pairsbykeys(t) do
        table.insert(concat, tab_str .. "[\"" .. tostring(k) .. "\"] = \"" .. tostring(v) .. "\",\n")
    end
    table.insert(concat, "}\n\nreturn loc\n")
    return table.concat(concat)
end

local function set_edit_text(edit_text)
    global_dialog:GetControl("editor"):SetText(edit_text)
end

local function get_sel_text()
    local popup = global_dialog:GetControl("file_list")
    local sel_item = popup:GetSelectedItem()
    if sel_item >= 0 and sel_item < popup:GetCount() then
        return popup:GetItemText(popup:GetSelectedItem())
    end
    return nil
end

--[[
% create_localized_base_table_string

Creates and displays a string representing a lua table of localizable strings by searching the specified script for
quoted strings. It then copies this string to the editor. The user can then edit it to include only user-facing
string and then create translations from that.

The base table is the table that defines the keys for all other languages. For each item in the base table, the
key is always equal to the value. The base table can be in any language. The base table does not need to be saved
as a localization.

@ file_path (string) the file_path to search for strings.
]]
local function create_localized_base_table_string(file_path)
    local t = create_localized_base_table(file_path)
    local locale = mixin.UI():GetUserLocaleName()
    local table_text = make_flat_table_string(file_path, locale:sub(1, 2), t)
    global_contents[file_path] = table_text
    set_edit_text(table_text)
    -- finenv.UI():AlertInfo("localization_base table copied to clipboard", "")
end

--[[
% extract_plugindef

Extracts the plugindef function from the input script file_path.
@ file_path (string) the file_path of the script to search for a plugindef function
: (table) the lines of the plugindef function in a table of strings
: (boolean) locale already exists
]]
local function extract_plugindef(file_path)
    local retval = {}
    local locale_exists = false
    file_path = client.encode_with_client_codepage(file_path)
    local file <close> = io.open(file_path, "r")
    if file then
        local found_first = false
        for line in file:lines() do
            if line:find("function plugindef") == 1 then
                found_first = true
                locale_exists = line:match("plugindef%s*%(%s*locale%s*%)")
            end
            if found_first then
                table.insert(retval, line)
            end
            if line:find("end") == 1 then
                break
            end
        end
    end
    return retval, locale_exists
end

--[[
% extract_plugindef_locale_table

Extracts the existing user-facing strings from a plugindef function into a string that contains
Lua code for a locale table. This can be inserted into a new plugindef function or sent to OpenAI
to be translated. It also modifies the plugindef lines to pull from the table.

For best results, certain conventions must be followed:

- The `plugindef` function and its `end` statment should have no whitespace at the beginning of the line.
- Additional menu options, undo strings, and descriptions should be entirely on separate lines from their
double-bracket delimiters.
- The return strings should be on a single line and use double-quotes.

If if you follow these conventions, you will likely have to edit the result somewhat.

@ table A table consisting of strings that are the lines of the plugindef function. This value is also modified
to pull the strings from a locale table `t`
: string A string containing Lua code that defines a table of keys and values
]]
local function extract_plugindef_locale_table(plugindef_function)
    local concat = {}
    table.insert(concat, "{\n")
    local index = 1
    while (plugindef_function[index]) do
        local line = plugindef_function[index]
        local function check_additional_strings(property, key)
            local pattern = "%s*finaleplugin%." .. property .. "%s*="
            if line:match("^" .. pattern .. "%s*%[%[") then
                plugindef_function[index] = line:gsub("^(" .. pattern .. ").-$", "%1" .. " t." .. key)
                table.insert(concat, tab_str)
                table.insert(concat, tab_str)
                table.insert(concat, key)
                table.insert(concat, " = [[\n")
                while (plugindef_function[index + 1]) do
                    local next_line = plugindef_function[index + 1]
                    table.insert(concat, tab_str)
                    table.insert(concat, next_line)
                    table.remove(plugindef_function, index + 1)
                    if next_line:find("]]") then
                        table.insert(concat, ",\n")
                        break
                    else
                        table.insert(concat, "\n")
                    end
                end
                return true
            end
            return false
        end
        if check_additional_strings("AdditionalMenuOptions", "addl_menus") then         -- luacheck: ignore
        elseif check_additional_strings("AdditionalUndoText", "addl_undos") then        -- luacheck: ignore
        elseif check_additional_strings("AdditionalDescriptions", "addl_descs") then    -- luacheck: ignore
        elseif line:match("^%s*return") then
            local new_return = line:gsub("^(%s*return).-$", "%1" .. " ")
            local got_menu, got_undo, got_desc
            for match, _ in line:gmatch('("([^"]*)")') do
                local function insert_retval(key, value)
                    table.insert(concat, tab_str)
                    table.insert(concat, tab_str)
                    table.insert(concat, key)
                    table.insert(concat, " = ")
                    table.insert(concat, value)
                    table.insert(concat, ",\n")
                end
                if not got_menu then
                    insert_retval("menu", match)
                    new_return = new_return .. " t.menu"
                    got_menu = true
                elseif not got_undo then
                    insert_retval("undo", match)
                    new_return = new_return .. ", t.undo"
                    got_undo = true
                elseif not got_desc then
                    insert_retval("desc", match)
                    new_return = new_return .. ", t.desc"
                    got_desc = true
                else
                    break
                end
            end
            plugindef_function[index] = new_return 
        end
        index = index + 1
    end
    table.insert(concat, tab_str .. "}")
    return table.concat(concat)
end

local function set_enable_all()
    local state = (https_session == nil) -- disable (send false) if https_session is not nil
    global_dialog:GetControl("file_list"):SetEnable(state)    
    global_dialog:GetControl("lang_list"):SetEnable(state)    
    global_dialog:GetControl("editor"):SetEnable(state)    
    global_dialog:GetControl("open"):SetEnable(state)    
    global_dialog:GetControl("generate"):SetEnable(state)    
    global_dialog:GetControl("translate"):SetEnable(state)    
    global_dialog:GetControl("plugindef"):SetEnable(state)
    -- The Close button is deliberately left enabled at all times
end

local function translate_localized_table_string(table_string, target_lang)
    local function callback(success, result)
        https_session = nil
        set_enable_all()
        if success then
            local retval = string.gsub(result.choices[1].message.content, "```", "")
            retval = retval:gsub("^%s+", "")            -- remove leading whitespace
            retval = retval:gsub("%s+$", "") .. "\n"    -- remove trailing whitespace and add line ending
            mixin.UI():TextToClipboard(retval)
            mixin.UI():AlertInfo("localization for " .. target_lang .. " table copied to clipboard", "")
        else
            mixin.UI():AlertError(result, "OpenAI Error")
        end
    end
    local prompt = [[
        I am working on localizing text for a program that prints and plays music. There may be musical
        terminology among the words and phrases that I would like you to translate, as follows.\n
    ]] .. "Here is Lua source code for a table of keys and values:\n\n```\n" .. table_string .. "\n```\n" ..
        [[
                    Provide a string that is Lua source code of a similar table definition that has the same keys
                    but with values that are translations of the keys for the locale specified by the code
                ]] .. target_lang .. [[. Return only the Lua code without any commentary. The output source code should
                    be identical to the input (including comments) except the values should be translated and any
                    locale code in the comment should be changed to match ]] .. target_lang .. "." ..
                    [[
                        There may or may not be musical terms in the provided text.
                        This information is provided for context if needed.
                    ]]
    https_session = openai.create_completion("gpt-4", prompt, 0.2, callback)
    set_enable_all()
end

local function on_text_change(control)
    assert(type(control) == "userdata" and control.ClassName, "argument 1 expected FCCtrlPopup, got " .. type(control))
    assert(control:ClassName() == "FCCtrlTextEditor", "argument 1 expected FCCtrlTextEditor, got " .. control:ClassName())
    if in_text_change_event then
        return
    end
    in_text_change_event = true
    local sel_text = get_sel_text()
    if sel_text then
        global_contents[sel_text] = control:GetText()
    end
    in_text_change_event = false
end

local function on_popup(control)
    assert(type(control) == "userdata" and control.ClassName, "argument 1 expected FCCtrlPopup, got " .. type(control))
    assert(control:ClassName() == "FCCtrlPopup", "argument 1 expected FCCtrlPopup, got " .. control:ClassName())
    if in_popup_handler then
        return
    end
    in_popup_handler = true
    local selected_item = control:GetSelectedItem()
    if popup_cur_sel ~= selected_item then -- avoid Windows churn
        popup_cur_sel = selected_item
        control:SetEnable(false)
        local sel_text = control:GetItemText(selected_item)
        local sel_content = global_contents[sel_text] or ""
        set_edit_text(sel_content)
        control:SetEnable(true)
        popup_cur_sel = control:GetSelectedItem()
    end
    in_popup_handler = false
    -- do not put edit_text in focus here, because it messes up Windows
end

local on_script_open
local function on_generate(control)
    local popup = global_dialog:GetControl("file_list")
    if popup:GetCount() <= 0 then
        on_script_open(control)
    end
    if popup:GetCount() > 0 then
        local sel_item = popup:GetSelectedItem()
        create_localized_base_table_string(popup:GetItemText(sel_item))
    end
    global_dialog:GetControl("editor"):SetKeyboardFocus()
end

on_script_open = function(control)
    local file_open_dlg = finale.FCFileOpenDialog(global_dialog:CreateChildUI())
    file_open_dlg:AddFilter(finale.FCString("*.lua"), finale.FCString("Lua source files"))
    file_open_dlg:SetInitFolder(finale.FCString(src_directory))
    file_open_dlg:SetWindowTitle(finale.FCString("Open Lua Source File"))
    if file_open_dlg:Execute() then
        local fc_name = finale.FCString()
        file_open_dlg:GetFileName(fc_name)
        local popup = global_dialog:GetControl("file_list")
        if global_contents[fc_name.LuaString] then
            for x = 0, popup:GetCount() - 1 do
                local x_text = popup:GetItemText(x)
                if x_text == fc_name.LuaString then
                    popup:SetSelectedItem(x)
                    on_popup(popup)
                    return
                end
            end
        end
        popup:AddString(fc_name.LuaString)
        popup:SetSelectedItem(popup:GetCount() - 1)
        on_generate(control)
    end
    global_dialog:GetControl("editor"):SetKeyboardFocus()
end

local function on_translate(_control)
    local sel_text = get_sel_text() or ""
    local content = global_contents[sel_text] or ""
    local lang_text = global_dialog:GetControl("lang_list"):GetText()
    lang_text = finale_supported_languages[lang_text] or lang_text
    if not lang_text:match("^[a-z][a-z]$") and not lang_text:match("^[a-z][a-z]_[A-Z][A-Z]$") then
        mixin.UI():AlertError(lang_text .. " is not a valid language or locale code.", "Invalid Entry")
        return
    end
    translate_localized_table_string(content, lang_text) -- ToDo: ask for language code somehow
    global_dialog:GetControl("editor"):SetKeyboardFocus()
end

local function on_plugindef(_control)
    local sel_text = get_sel_text()
    local text_copied = false
    if sel_text then
        local plugindef_function, locale_exists = extract_plugindef(sel_text)
        if #plugindef_function > 0 then
            local base_strings = extract_plugindef_locale_table(plugindef_function)
            if #base_strings > 0 then
                if not locale_exists then
                    plugindef_function[1] = "function plugindef(locale)"
                end
                local locale = mixin.UI():GetUserLocaleName()
                table.insert(plugindef_function, 2, tab_str .. "local loc = {}")
                table.insert(plugindef_function, 3, tab_str .. "loc." .. locale:sub(1, 2) .. " = " .. base_strings)
                table.insert(plugindef_function, 4,
                    tab_str .. "local t = locale and loc[locale:sub(1, 2)] or loc." .. locale:sub(1, 2))
            end
            mixin.UI():TextToClipboard(table.concat(plugindef_function, "\n") .. "\n")
            mixin.UI():AlertInfo("Localized plugindef function copied to clipboard.", "")
            text_copied = true
        end
    end
    if not text_copied then
        mixin.UI():AlertError("No plugindef function found.", "")
    end
    global_dialog:GetControl("editor"):SetKeyboardFocus()
end 

local function on_close()
    https_session = https.cancel_session(https_session)
    set_enable_all()
end

local function create_dialog()
    local dlg = mixin.FCXCustomLuaWindow()
        :SetTitle("Localization Helper")
    local editor_width = 700
    local editor_height = 300
    local y_separator = 10
    local x_separator = 7
    local button_height = 20
    --script selection
    local curr_y = 0
    dlg:CreateButton(0, curr_y, "open")
        :SetText("Open...")
        :DoAutoResizeWidth()
        :AddHandleCommand(on_script_open)
    dlg:CreatePopup(0, curr_y, "file_list")
        :SetWidth((2 * editor_width) / 3)
        :AssureNoHorizontalOverlap(dlg:GetControl("open"), x_separator)
        :AddHandleCommand(on_popup)
    dlg:CreateComboBox(0, curr_y, "lang_list")
        :SetWidth(0)
        :DoAutoResizeWidth()
        :AddStrings(utils.get_keys(finale_supported_languages))
        :SetText("Spanish")
    curr_y = curr_y + button_height
    --editor
    curr_y = curr_y + y_separator
    local font = finale.FCFontInfo(utils.win_mac("Consolas", "Menlo"), utils.win_mac(9, 11))
    local editor = dlg:CreateTextEditor(0, curr_y, "editor")
        :SetWidth(editor_width)
        :SetHeight(editor_height)
        :SetUseRichText(false)
        :SetAutomaticEditing(false)
        :SetWordWrap(false)
        :SetFont(font)
        :SetConvertTabsToSpaces(#tab_str)
        :SetAutomaticallyIndent(true)
        :AddHandleCommand(on_text_change)
        :HorizontallyAlignRightWith(dlg:GetControl("lang_list"), utils.win_mac(0, -3))
    curr_y = curr_y + editor_height
    -- command buttons
    curr_y = curr_y + y_separator
    dlg:CreateButton(0, curr_y, "generate")
        :SetText("Generate Table")
        :DoAutoResizeWidth()
        :AddHandleCommand(on_generate)
    dlg:CreateButton(0, curr_y, "translate")
        :SetText("Translate Table")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("generate"), x_separator)
        :AddHandleCommand(on_translate)
    dlg:CreateButton(0, curr_y, "plugindef")
        :SetText("Localize Plugindef")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("translate"), x_separator)
        :AddHandleCommand(on_plugindef)
    dlg:CreateCloseButton(0, curr_y)
        :HorizontallyAlignRightWith(editor)
    -- registrations
    dlg:RegisterCloseWindow(on_close)
    -- return
    return dlg
end

local function localization_tool()
    global_dialog = global_dialog or create_dialog()
    global_dialog:RunModeless()
end

localization_tool()

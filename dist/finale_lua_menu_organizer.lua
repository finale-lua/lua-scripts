package.preload["library.utils"] = package.preload["library.utils"] or function()

    local utils = {}




    function utils.copy_table(t, to_table, overwrite)
        overwrite = (overwrite == nil) and true or false
        if type(t) == "table" then
            local new = type(to_table) == "table" and to_table or {}
            for k, v in pairs(t) do
                local new_key = utils.copy_table(k)
                local new_value = utils.copy_table(v)
                if overwrite then
                    new[new_key] = new_value
                else
                    new[new_key] = new[new_key] == nil and new_value or new[new_key]
                end
            end
            setmetatable(new, utils.copy_table(getmetatable(t)))
            return new
        else
            return t
        end
    end

    function utils.table_remove_first(t, value)
        for k = 1, #t do
            if t[k] == value then
                table.remove(t, k)
                return
            end
        end
    end

    function utils.table_is_empty(t)
        if type(t) ~= "table" then
            return false
        end
        for _, _ in pairs(t) do
            return false
        end
        return true
    end

    function utils.iterate_keys(t)
        local a, b, c = pairs(t)
        return function()
            c = a(b, c)
            return c
        end
    end

    function utils.create_keys_table(t)
        local retval = {}
        for k, _ in pairsbykeys(t) do
            table.insert(retval, k)
        end
        return retval
    end

    function utils.create_lookup_table(t)
        local lookup = {}
        for _, v in pairs(t) do
            lookup[v] = true
        end
        return lookup
    end

    function utils.round(value, places)
        places = places or 0
        local multiplier = 10^places
        local ret = math.floor(value * multiplier + 0.5)

        return places == 0 and ret or ret / multiplier
    end

    function utils.to_integer_if_whole(value)
        local int = math.floor(value)
        return value == int and int or value
    end

    function utils.calc_roman_numeral(num)
        local thousands = {'M','MM','MMM'}
        local hundreds = {'C','CC','CCC','CD','D','DC','DCC','DCCC','CM'}
        local tens = {'X','XX','XXX','XL','L','LX','LXX','LXXX','XC'}	
        local ones = {'I','II','III','IV','V','VI','VII','VIII','IX'}
        local roman_numeral = ''
        if math.floor(num/1000)>0 then roman_numeral = roman_numeral..thousands[math.floor(num/1000)] end
        if math.floor((num%1000)/100)>0 then roman_numeral=roman_numeral..hundreds[math.floor((num%1000)/100)] end
        if math.floor((num%100)/10)>0 then roman_numeral=roman_numeral..tens[math.floor((num%100)/10)] end
        if num%10>0 then roman_numeral = roman_numeral..ones[num%10] end
        return roman_numeral
    end

    function utils.calc_ordinal(num)
        local units = num % 10
        local tens = num % 100
        if units == 1 and tens ~= 11 then
            return num .. "st"
        elseif units == 2 and tens ~= 12 then
            return num .. "nd"
        elseif units == 3 and tens ~= 13 then
            return num .. "rd"
        end
        return num .. "th"
    end

    function utils.calc_alphabet(num)
        local letter = ((num - 1) % 26) + 1
        local n = math.floor((num - 1) / 26)
        return string.char(64 + letter) .. (n > 0 and n or "")
    end

    function utils.clamp(num, minimum, maximum)
        return math.min(math.max(num, minimum), maximum)
    end

    function utils.ltrim(str)
        return string.match(str, "^%s*(.*)")
    end

    function utils.rtrim(str)
        return string.match(str, "(.-)%s*$")
    end

    function utils.trim(str)
        return utils.ltrim(utils.rtrim(str))
    end

    local pcall_wrapper
    local rethrow_placeholder = "tryfunczzz"
    local pcall_line = debug.getinfo(1, "l").currentline + 2
    function utils.call_and_rethrow(levels, tryfunczzz, ...)
        return pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))

    end

    local source = debug.getinfo(1, "S").source
    local source_is_file = source:sub(1, 1) == "@"
    if source_is_file then
        source = source:sub(2)
    end

    pcall_wrapper = function(levels, success, result, ...)
        if not success then
            local file
            local line
            local msg
            file, line, msg = result:match("([a-zA-Z]-:?[^:]+):([0-9]+): (.+)")
            msg = msg or result
            local file_is_truncated = file and file:sub(1, 3) == "..."
            file = file_is_truncated and file:sub(4) or file



            if file
                and line
                and source_is_file
                and (file_is_truncated and source:sub(-1 * file:len()) == file or file == source)
                and tonumber(line) == pcall_line
            then
                local d = debug.getinfo(levels, "n")

                msg = msg:gsub("'" .. rethrow_placeholder .. "'", "'" .. (d.name or "") .. "'")

                if d.namewhat == "method" then
                    local arg = msg:match("^bad argument #(%d+)")
                    if arg then
                        msg = msg:gsub("#" .. arg, "#" .. tostring(tonumber(arg) - 1), 1)
                    end
                end
                error(msg, levels + 1)


            else
                error(result, 0)
            end
        end
        return ...
    end

    function utils.rethrow_placeholder()
        return "'" .. rethrow_placeholder .. "'"
    end

    function utils.show_notes_dialog(parent, caption, width, height)
        if not finaleplugin.RTFNotes and not finaleplugin.Notes then
            return
        end
        if parent and (type(parent) ~= "userdata" or not parent.ExecuteModal) then
            error("argument 1 must be nil or an instance of FCResourceWindow", 2)
        end
        local function dedent(input)
            local first_line_indent = input:match("^(%s*)")
            local pattern = "\n" .. string.rep(" ", #first_line_indent)
            local result = input:gsub(pattern, "\n")
            result = result:gsub("^%s+", "")
            return result
        end
        local function replace_font_sizes(rtf)
            local font_sizes_json  = rtf:match("{\\info%s*{\\comment%s*(.-)%s*}}")
            if font_sizes_json then
                local cjson = require("cjson.safe")
                local font_sizes = cjson.decode('{' .. font_sizes_json .. '}')
                if font_sizes and font_sizes.os then
                    local this_os = finenv.UI():IsOnWindows() and 'win' or 'mac'
                    if (font_sizes.os == this_os) then
                        rtf = rtf:gsub("fs%d%d", font_sizes)
                    end
                end
            end
            return rtf
        end
        if not caption then
            caption = plugindef():gsub("%.%.%.", "")
            if finaleplugin.Version then
                local version = finaleplugin.Version
                if string.sub(version, 1, 1) ~= "v" then
                    version = "v" .. version
                end
                caption = string.format("%s %s", caption, version)
            end
        end
        if finenv.MajorVersion == 0 and finenv.MinorVersion < 68 and finaleplugin.Notes then
            finenv.UI():AlertInfo(dedent(finaleplugin.Notes), caption)
        else
            local notes = dedent(finaleplugin.RTFNotes or finaleplugin.Notes)
            if finaleplugin.RTFNotes then
                notes = replace_font_sizes(notes)
            end
            width = width or 500
            height = height or 350

            local dlg = finale.FCCustomLuaWindow()
            dlg:SetTitle(finale.FCString(caption))
            local edit_text = dlg:CreateTextEditor(10, 10)
            edit_text:SetWidth(width)
            edit_text:SetHeight(height)
            edit_text:SetUseRichText(finaleplugin.RTFNotes)
            edit_text:SetReadOnly(true)
            edit_text:SetWordWrap(true)
            local ok = dlg:CreateOkButton()
            dlg:RegisterInitWindow(
                function()
                    local notes_str = finale.FCString(notes)
                    if edit_text:GetUseRichText() then
                        edit_text:SetRTFString(notes_str)
                    else
                        local edit_font = finale.FCFontInfo()
                        edit_font.Name = "Arial"
                        edit_font.Size = finenv.UI():IsOnWindows() and 9 or 12
                        edit_text:SetFont(edit_font)
                        edit_text:SetText(notes_str)
                    end
                    edit_text:ResetColors()
                    ok:SetKeyboardFocus()
                end)
            dlg:ExecuteModal(parent)
        end
    end

    function utils.win_mac(windows_value, mac_value)
        if finenv.UI():IsOnWindows() then
            return windows_value
        end
        return mac_value
    end

    function utils.split_file_path(full_path)
        local path_name = finale.FCString()
        local file_name = finale.FCString()
        local file_path = finale.FCString(full_path)

        if file_path:FindFirst("/") >= 0 or (finenv.UI():IsOnWindows() and file_path:FindFirst("\\") >= 0) then
            file_path:SplitToPathAndFile(path_name, file_name)
        else
            file_name.LuaString = full_path
        end

        local extension = file_name.LuaString:match("^.+(%..+)$")
        extension = extension or ""
        if #extension > 0 then

            local truncate_pos = file_name.Length - finale.FCString(extension).Length
            if truncate_pos > 0 then
                file_name:TruncateAt(truncate_pos)
            else
                extension = ""
            end
        end
        path_name:AssureEndingPathDelimiter()
        return path_name.LuaString, file_name.LuaString, extension
    end

    function utils.eachfile(directory_path, recursive)
        if finenv.MajorVersion <= 0 and finenv.MinorVersion < 68 then
            error("utils.eachfile requires at least RGP Lua v0.68.", 2)
        end
        recursive = recursive or false
        local lfs = require('lfs')
        local text = require('luaosutils').text
        local fcstr = finale.FCString(directory_path)
        fcstr:AssureEndingPathDelimiter()
        directory_path = fcstr.LuaString

        local lfs_directory_path = text.convert_encoding(directory_path, text.get_utf8_codepage(), text.get_default_codepage())
        return coroutine.wrap(function()
            for lfs_file in lfs.dir(lfs_directory_path) do
                if lfs_file ~= "." and lfs_file ~= ".." then
                    local utf8_file = text.convert_encoding(lfs_file, text.get_default_codepage(), text.get_utf8_codepage())
                    local mode = lfs.attributes(lfs_directory_path .. lfs_file, "mode")
                    if mode == "directory" then
                        if recursive then
                            for subdir, subfile in utils.eachfile(directory_path .. utf8_file, recursive) do
                                coroutine.yield(subdir, subfile)
                            end
                        end
                    elseif (mode == "file" or mode == "link") and lfs_file:sub(1, 2) ~= "._" then
                        coroutine.yield(directory_path, utf8_file)
                    end
                end
            end
        end)
    end
    return utils
end
function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.ExecuteAtStartup = true
    finaleplugin.ModifyFinaleMenus = true
    finaleplugin.IncludeInPluginMenu = false
    finaleplugin.LoadLuaOSUtils = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "2023"
    finaleplugin.Version = "1.0.2"
    finaleplugin.Date = "2023-02-24"
    finaleplugin.MinJWLuaVersion = 0.66 -- https://robertgpatterson.com/-fininfo/-rgplua/rgplua.html
        --[[
    As of March 10, 2023, the documentation generator for the finale-lua/lua-scripts GitHub repository does not
    support Markdown tables, so I rewrote the Notes string not to use one. However, if it ever does support them,
    here is the original table.

    |Token|Description|
    |-----|-----------|
    |MENUNAME&nbsp;[text]|Identifies the source menu from which to take menu items. The plugin searches Finale's Plug-Ins menu and submenus for a menu item that starts with this text. The menu containing that item becomes the menu from which items are taken. If this value is omitted, it defaults to JW Lua.|
    |USEMAINMENU&nbsp;[text]|Specifies a new menu item to be created in Finale's main menu bar. If omitted, the menu items will be copied to the same menu as specified by MENUNAME. You can include an ampersand (&) for a Windows menu hotkey. This will be stripped out and ignored if the file is used with Mac Finale.|
    |>[text]|Starts a submenu with name [text].|
    |<|Ends the current submenu.|
    |=>|Changes the menu item text from the original text to new text.|
    |-|A single hyphen by itself inserts a divider into the menu.|
    |//|Delimits a comment. Everything after the comment delimiter is ignored.|

    ]]
    finaleplugin.Notes = [[
    This plug-in runs when Finale starts up and organizes the menus according to a configuration file called `finale_lua_menus.txt`.
    The plugin searches for the file in two locations:

    1. The running folder where this script resides.
    2. The Finale Plug-Ins main folder.

    If the file is not found, the script exits without doing anything. However, you can have it create a template with all the Lua menu items
    by changing the `create_template_if_not_found` variable to `true`. You may then edit the template to taste. It creates it in the script's running folder.

    The format of `finale_lua_menus.txt` is fully compatible with the format of the JWLuaMenu plugin, which this script is intended to replace.
    It supports the following keywords and tokens. Empty lines are skipped.

    **MENUNAME [text]**

    Identifies the source menu from which to take menu items. The plugin searches Finale's Plug-Ins menu and submenus for a menu item that starts with this text.
    The menu containing that item becomes the menu from which items are taken. If this value is omitted, it defaults to JW Lua.

    **USEMAINMENU [text]**

    Specifies a new menu item to be created in Finale's main menu bar. If omitted, the menu items will be copied to the same menu as specified by MENUNAME.
    You can include an ampersand (&) for a Windows menu hotkey. This will be stripped out and ignored if the file is used with Mac Finale.

    **>[text]** Starts a submenu with name [text].

    **<** Ends the current submenu.

    **=>** Changes the menu item text from the original text to new text.

    **-** A single hyphen by itself inserts a divider into the menu.

    **//** Delimits a comment. Everything after the comment delimiter is ignored.

    Tabs and other whitespace are ignored, but it may be useful to use tabs to show submenus.
    If any of the source menus are empty after the menu layout is complete, the script removes that submenu from Finale's plugin menu.

    Here is an example of a configuration file.

    ```
    MENUNAME    RGP Lua        // selects the subfolder containing the RGP Lua plugin.
    USEMAINMENU    &Lua        // creates a new menu called 'Lua' in Finale's main menu bar (optional)
    >Articulations
        Autoposition Rolled Chord Articulations
        Remove Duplicate Articulations
        Remove Articulations from Rests
        Reset Automatic Articulation Positions
        Reset Articulation Positions
        -
        Delete Articulations            => Delete All
    <
    >Barline
        Barline Set Dashed        => Dashed
        Barline Set Double        => Double
        Barline Set Final        => Final
        Barline Set None        => None
        Barline Set Normal        => Normal
    <
    ```
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This plug-in runs when Finale starts up and organizes the menus according to a configuration file called {\f1 finale_lua_menus.txt}. The plugin searches for the file in two locations:\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 1.\tx360\tab The running folder where this script resides.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 2.\tx360\tab The Finale Plug-Ins main folder.\sa180\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 If the file is not found, the script exits without doing anything. However, you can have it create a template with all the Lua menu items by changing the {\f1 create_template_if_not_found} variable to {\f1 true}. You may then edit the template to taste. It creates it in the script\u8217's running folder.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 The format of {\f1 finale_lua_menus.txt} is fully compatible with the format of the JWLuaMenu plugin, which this script is intended to replace. It supports the following keywords and tokens. Empty lines are skipped.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 {\b MENUNAME [text]}\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 Identifies the source menu from which to take menu items. The plugin searches Finale\u8217's Plug-Ins menu and submenus for a menu item that starts with this text. The menu containing that item becomes the menu from which items are taken. If this value is omitted, it defaults to JW Lua.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 {\b USEMAINMENU [text]}\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 Specifies a new menu item to be created in Finale\u8217's main menu bar. If omitted, the menu items will be copied to the same menu as specified by MENUNAME. You can include an ampersand (&) for a Windows menu hotkey. This will be stripped out and ignored if the file is used with Mac Finale.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 {\b >[text]} Starts a submenu with name [text].\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 {\b <} Ends the current submenu.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 {\b =>} Changes the menu item text from the original text to new text.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 {\b -} A single hyphen by itself inserts a divider into the menu.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 {\b //} Delimits a comment. Everything after the comment delimiter is ignored.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 Tabs and other whitespace are ignored, but it may be useful to use tabs to show submenus. If any of the source menus are empty after the menu layout is complete, the script removes that submenu from Finale\u8217's plugin menu.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 Here is an example of a configuration file.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 \f1 MENUNAME    RGP Lua        // selects the subfolder containing the RGP Lua plugin.\line
        USEMAINMENU    &Lua        // creates a new menu called 'Lua' in Finale's main menu bar (optional)\line
        >Articulations\line
            Autoposition Rolled Chord Articulations\line
            Remove Duplicate Articulations\line
            Remove Articulations from Rests\line
            Reset Automatic Articulation Positions\line
            Reset Articulation Positions\line
            -\line
            Delete Articulations            => Delete All\line
        <\line
        >Barline\line
            Barline Set Dashed        => Dashed\line
            Barline Set Double        => Double\line
            Barline Set Final        => Final\line
            Barline Set None        => None\line
            Barline Set Normal        => Normal\line
        <\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/finale_lua_menu_organizer.hash"
    return "Finale Lua Menu Organizer", "Finale Lua Menu Organizer",
        "Organizes the Lua menus in Finale's Plug-Ins menu as specified in a configuration file."
end
local create_template_if_not_found = false
local utils = require("library.utils")
local osutils = require("luaosutils")
local menu = osutils.menu
local layout_file_name = "finale_lua_menus.txt"
local comment_string = "//"
local menuname_keyword = "MENUNAME"
local usemainmenu_keyword = "USEMAINMENU"
local downsubmenu_indicator = ">"
local upsubmenu_indicator = "<"
local separator_indicator = "-"
local replacement_indicator = "=>"
local win_kbdshortcut = "&"
if finenv.UI():IsOnMac() then
    win_kbdshortcut = ""
end
local top_level_menu = menu.get_top_level_menu(finenv.GetFinaleMainWindow())
local min_index_for_plugin_menu = 6
local get_lua_menu = function()
    local lua_menu, lua_menu_index = menu.find_item(top_level_menu, "RGP Lua...", min_index_for_plugin_menu)
    if lua_menu then return lua_menu, lua_menu_index end

    lua_menu, lua_menu_index = menu.find_item(top_level_menu, "JW Lua...", min_index_for_plugin_menu)
    return lua_menu, lua_menu_index
end
local get_config_file = function()
    local try_file = function(file_path)
        local file = io.open(file_path, "r")
        if file then
            io.close(file)
            return true
        end
        return false
    end
    if try_file(finenv.RunningLuaFolderPath() .. layout_file_name) then
        return finenv.RunningLuaFolderPath() .. layout_file_name, true
    end
    local fcstr = finale.FCString()
    fcstr:SetPluginsFolderPath()
    fcstr:AppendLuaString("/")
    if try_file(fcstr.LuaString .. layout_file_name) then
        return fcstr.LuaString .. layout_file_name, true
    end
    return finenv.RunningLuaFolderPath() .. layout_file_name, false
end
local create_layout_template = function()
    local lua_menu, lua_menu_index = get_lua_menu()
    if not lua_menu then return false end
    local config_file = get_config_file()
    local file = io.open(config_file, "w")
    if not file then return false end
    file:write(comment_string .. " " .. plugindef() .. " " .. finaleplugin.Version .. "\n")
    file:write(comment_string .. " " .. "Use > to start a submenu and < to return to previous menu." .. "\n")
    file:write(comment_string .. " " .. "Use (original text) => (replacement text) to change the text of a menu." .. "\n")
    file:write(comment_string .. " " .. "Tabs and other whitespace are ignored." .. "\n")
    file:write("\n")
    file:write(menuname_keyword ..
    "    " ..
    "RGP Lua" ..
    " " .. comment_string .. "Optional keyword to choose any menu to organize. (Defaults to RGP Lua if omitted.)" .. "\n")
    file:write(usemainmenu_keyword ..
    " " .. win_kbdshortcut .. "Lua" .. " " .. comment_string ..
    "Remove this line to build the Lua menu in place." .. "\n")
    file:write("\n")
    local num_items = menu.get_item_count(lua_menu)
    local lua_menu_title = menu.get_item_text(lua_menu, lua_menu_index)
    local got1 = false
    for x = 0, num_items - 1 do
        local item_text = menu.get_item_text(lua_menu, x)
        if item_text ~= lua_menu_title then
            if not got1 then
                file:write(downsubmenu_indicator, "Scripts" .. "\n")
                got1 = true
            end
            file:write("\t" .. item_text .. "\n")
        end
    end
    if got1 then
        file:write(upsubmenu_indicator .. "\n")
        file:write(separator_indicator .. "\n")
    end
    file:write(lua_menu_title .. "\n")
    io.close(file)
    return true
end
local parse_layout_file_to_menu
parse_layout_file_to_menu = function(file, from_menu, to_menu)
    local menus_to_delete = {}
    local function function_exit()
        for k, _ in pairs(menus_to_delete) do
            menu.delete_submenu(k, finenv.GetFinaleMainWindow())
        end
        return true
    end
    local function extract_keyword_value(keyword, line)
        local result = utils.trim(line:sub(#keyword + 1))
        if not finenv.UI():IsOnWindows() then
            result = result:gsub("&", "")
        end
        return result
    end
    to_menu = to_menu or from_menu
    while true do
        local line = file:read("*line")
        if not line then break end
        local comment_start = line:find(comment_string, 1, true)
        if comment_start then
            line = line:sub(1, comment_start-1)
        end
        line = utils.trim(line)
        if #line > 0 then
            if line:find(menuname_keyword, 1, true) == 1 then
                line = extract_keyword_value(menuname_keyword, line)
                from_menu = menu.find_item(top_level_menu, line, min_index_for_plugin_menu)
                to_menu = to_menu or from_menu
            elseif line:find(usemainmenu_keyword, 1, true) == 1 then
                line = extract_keyword_value(usemainmenu_keyword, line)
                local top_menu = menu.get_top_level_menu(finenv.GetFinaleMainWindow())
                to_menu = menu.insert_submenu(line, top_menu)
                to_menu = to_menu or from_menu
            elseif from_menu and to_menu then
                if not finenv.UI():IsOnWindows() then
                    if not line:find(" & ", 1, true) then
                        line = line:gsub("&", "")
                    end
                end
                if line:find(downsubmenu_indicator, 1, true) == 1 then
                    local submenu = menu.insert_submenu(line:sub(2), to_menu)
                    parse_layout_file_to_menu(file, from_menu, submenu)
                elseif line:find(upsubmenu_indicator, 1, true) == 1 then
                    return function_exit()
                elseif line:find(separator_indicator, 1, true) == 1 then
                    menu.insert_separator(to_menu)
                else
                    local find_item = function(start_menu, str)
                        if finenv.UI():IsOnWindows() then
                            str = str:gsub("&", "")
                        end
                        return menu.find_item(start_menu, str)
                    end
                    local item_menu, item_index = find_item(from_menu, line)
                    if item_menu then
                        if menu.move_item(item_menu, item_index, to_menu) then
                            menus_to_delete[item_menu] = true
                            menus_to_delete[from_menu] = true
                        end
                    else
                        local found = line:find(replacement_indicator, -#line, true)
                        if found then
                            local original_text = utils.trim(line:sub(1, found - 1))
                            local replacement_text = utils.trim(line:sub(found + #replacement_indicator))
                            if #replacement_text > 0 then
                                item_menu, item_index = find_item(from_menu, original_text)
                                if item_menu then
                                    local success, index = menu.move_item(item_menu, item_index, to_menu)
                                    if success then
                                        menu.set_item_text(to_menu, index, replacement_text)
                                        menus_to_delete[item_menu] = true
                                        menus_to_delete[from_menu] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return function_exit()
end
local function organize_finale_lua_menus()
    local file_path, exists = get_config_file()
    if not exists then
        if not create_template_if_not_found then
            return
        end
        if not create_layout_template() then
            finenv.UI():AlertError(plugindef() .. " was unable to create a layout template.", "")
            return
        end
        file_path, exists = get_config_file()
        if not exists then
            finenv.UI():AlertError("An unexpected error occured in " .. plugindef() .. ".", "")
            return
        end
    end
    local file = io.open(file_path, "r")
    if not file then
        finenv.UI():AlertError("Unable to read " .. file_path .. ".", "")
        return
    end
    local lua_menu = get_lua_menu()
    parse_layout_file_to_menu(file, lua_menu)
    menu.redraw(finenv.GetFinaleMainWindow())
end
organize_finale_lua_menus()

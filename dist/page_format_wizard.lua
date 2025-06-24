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

    function utils.parse_codepoint(codepoint_string)
        return tonumber(codepoint_string:match("U%+(%x+)"), 16)
    end

    function utils.format_codepoint(codepoint)
        return string.format("U+%04X", codepoint)
    end
    return utils
end
package.preload["library.configuration"] = package.preload["library.configuration"] or function()



    local configuration = {}
    local utils = require("library.utils")
    local script_settings_dir = "script_settings"
    local comment_marker = "--"
    local parameter_delimiter = "="
    local path_delimiter = "/"
    local file_exists = function(file_path)
        local f = io.open(file_path, "r")
        if nil ~= f then
            io.close(f)
            return true
        end
        return false
    end
    parse_parameter = function(val_string)
        if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "\"(.+)\"", "%1")
        elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "'(.+)'", "%1")
        elseif "{" == val_string:sub(1, 1) and "}" == val_string:sub(#val_string, #val_string) then
            return load("return " .. val_string)()
        elseif "true" == val_string then
            return true
        elseif "false" == val_string then
            return false
        end
        return tonumber(val_string)
    end
    local get_parameters_from_file = function(file_path, parameter_list)
        local file_parameters = {}
        if not file_exists(file_path) then
            return false
        end
        for line in io.lines(file_path) do
            local comment_at = string.find(line, comment_marker, 1, true)
            if nil ~= comment_at then
                line = string.sub(line, 1, comment_at - 1)
            end
            local delimiter_at = string.find(line, parameter_delimiter, 1, true)
            if nil ~= delimiter_at then
                local name = utils.trim(string.sub(line, 1, delimiter_at - 1))
                local val_string = utils.trim(string.sub(line, delimiter_at + 1))
                file_parameters[name] = parse_parameter(val_string)
            end
        end
        local function process_table(param_table, param_prefix)
            param_prefix = param_prefix and param_prefix.."." or ""
            for param_name, param_val in pairs(param_table) do
                local file_param_name = param_prefix .. param_name
                local file_param_val = file_parameters[file_param_name]
                if nil ~= file_param_val then
                    param_table[param_name] = file_param_val
                elseif type(param_val) == "table" then
                        process_table(param_val, param_prefix..param_name)
                end
            end
        end
        process_table(parameter_list)
        return true
    end

    function configuration.get_parameters(file_name, parameter_list)
        local path
        if finenv.IsRGPLua then
            path = finenv.RunningLuaFolderPath()
        else
            local str = finale.FCString()
            str:SetRunningLuaFolderPath()
            path = str.LuaString
        end
        local file_path = path .. script_settings_dir .. path_delimiter .. file_name
        return get_parameters_from_file(file_path, parameter_list)
    end


    local calc_preferences_filepath = function(script_name)
        local str = finale.FCString()
        str:SetUserOptionsPath()
        local folder_name = str.LuaString
        if not finenv.IsRGPLua and finenv.UI():IsOnMac() then

            folder_name = os.getenv("HOME") .. folder_name:sub(2)
        end
        if finenv.UI():IsOnWindows() then
            folder_name = folder_name .. path_delimiter .. "FinaleLua"
        end
        local file_path = folder_name .. path_delimiter
        if finenv.UI():IsOnMac() then
            file_path = file_path .. "com.finalelua."
        end
        file_path = file_path .. script_name .. ".settings.txt"
        return file_path, folder_name
    end

    function configuration.save_user_settings(script_name, parameter_list)
        local file_path, folder_path = calc_preferences_filepath(script_name)
        local file = io.open(file_path, "w")
        if not file and finenv.UI():IsOnWindows() then

            local osutils = finenv.EmbeddedLuaOSUtils and require("luaosutils")
            if osutils then
                osutils.process.make_dir(folder_path)
            else
                os.execute('mkdir "' .. folder_path ..'"')
            end
            file = io.open(file_path, "w")
        end
        if not file then
            return false
        end
        file:write("-- User settings for " .. script_name .. ".lua\n\n")
        for k,v in pairs(parameter_list) do
            if type(v) == "string" then
                v = "\"" .. v .."\""
            else
                v = tostring(v)
            end
            file:write(k, " = ", v, "\n")
        end
        file:close()
        return true
    end

    function configuration.get_user_settings(script_name, parameter_list, create_automatically)
        if create_automatically == nil then create_automatically = true end
        local exists = get_parameters_from_file(calc_preferences_filepath(script_name), parameter_list)
        if not exists and create_automatically then
            configuration.save_user_settings(script_name, parameter_list)
        end
        return exists
    end
    return configuration
end
function plugindef()
  finaleplugin.RequireSelection = false
  finaleplugin.Author = "Jacob Winkler" 
  finaleplugin.Copyright = "©2024 Jacob Winkler"
  finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
  finaleplugin.Date = "2024/1/25"
  finaleplugin.Version = "1.2.2"
  finaleplugin.HandlesUndo = true
  finaleplugin.NoStore = false
  finaleplugin.MinJWLuaVersion = 0.70 -- https://robertgpatterson.com/-fininfo/-rgplua/rgplua.html
  finaleplugin.Notes = [[
        USING THE 'PAGE FORMAT WIZARD'
        
        The Page Format Wizard duplicates and extends the functionality of both the 'Page Format for Score' and 'Page Format for Parts' dialogs, and works instantly without needing to call 'Redefine Pages' from the Page Layout Tool menu.
        
        Staff height is entered using millimeters, rather than Finale's method of using "Resulting System Scaling" (a fixed value multiplied by a scaling factor). Presets for various raster sizes can be selected from the popup menu. A brief description of each raster size pops up when it is selected, paraphrased from the MOLA guidelines on parts and scores, Elaine Gould's "Behind Bars", and Steven Powell's "Music Engraving Today: The Art and Practice of Digital Notesetting."
        
        System margins can use different units than page units. The default unit for system related measurements are spaces, but the plug-in will remember what was last used.
        
        You can set or scale the staff spacing as you reformat, without the need to 'Respace Staves' using the Staff Tool. This can be useful for doing things like reformatting a tabloid sized score to A3 where slight adjustments to staff spacing might need to be made. Note that if you scale the staff spacing by a percentage, the dialog will be reset to 100% so that you don't keep applying the same transformation over and over. Systems can be locked or unlocked through the plug-in as needed before reformatting.
        
        In addition to formatting the score and parts, you can set up "special parts" to have alternate formatting. This makes it easy to do something like create something like a Piano/Vocal score that may have different requirements than both the full score and the regular instrumental parts. The "special parts" feature could also be used to reformat a subset of parts without touching the others simply by diabling the 'Score' and 'Default Parts' sections of the plug-in.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 USING THE \u8216'PAGE FORMAT WIZARD\u8217'\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 The Page Format Wizard duplicates and extends the functionality of both the \u8216'Page Format for Score\u8217' and \u8216'Page Format for Parts\u8217' dialogs, and works instantly without needing to call \u8216'Redefine Pages\u8217' from the Page Layout Tool menu.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 Staff height is entered using millimeters, rather than Finale\u8217's method of using \u8220"Resulting System Scaling\u8221" (a fixed value multiplied by a scaling factor). Presets for various raster sizes can be selected from the popup menu. A brief description of each raster size pops up when it is selected, paraphrased from the MOLA guidelines on parts and scores, Elaine Gould\u8217's \u8220"Behind Bars\u8221", and Steven Powell\u8217's \u8220"Music Engraving Today: The Art and Practice of Digital Notesetting.\u8221"\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 System margins can use different units than page units. The default unit for system related measurements are spaces, but the plug-in will remember what was last used.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 You can set or scale the staff spacing as you reformat, without the need to \u8216'Respace Staves\u8217' using the Staff Tool. This can be useful for doing things like reformatting a tabloid sized score to A3 where slight adjustments to staff spacing might need to be made. Note that if you scale the staff spacing by a percentage, the dialog will be reset to 100% so that you don\u8217't keep applying the same transformation over and over. Systems can be locked or unlocked through the plug-in as needed before reformatting.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 In addition to formatting the score and parts, you can set up \u8220"special parts\u8221" to have alternate formatting. This makes it easy to do something like create something like a Piano/Vocal score that may have different requirements than both the full score and the regular instrumental parts. The \u8220"special parts\u8221" feature could also be used to reformat a subset of parts without touching the others simply by diabling the \u8216'Score\u8217' and \u8216'Default Parts\u8217' sections of the plug-in.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/page_format_wizard.hash"
  return "Page Format Wizard", "Page Format Wizard", "Page Format Wizard"
end
local configuration = require("library.configuration")
local config_file = "Page_Format_Wizard"
local config = {
  score_enable = 1,
  parts_enable = 1,
  special_enable = 0,
  score_system_units = 6,
  parts_system_units = 6,
  special_system_units = 6,
  score_bypass_systems_bool = 1,
  parts_bypass_systems_bool = 1,
  special_bypass_sytems_bool = 1,
  score_staff_spacing = 0,
  parts_staff_spacing = 0,
  special_staff_spacing = 0,
  score_staff_spacing_first_page_bool = 0,
  parts_staff_spacing_first_page_bool = 0,
  special_staff_spacing_first_page_bool = 0,
  score_staff_spacing_set_first_page = 12 * 24,
  score_staff_spacing_set_other_pages = 12 * 24,
  score_staff_spacing_scale_first_page = 100,
  score_staff_spacing_scale_other_pages = 100,
  parts_staff_spacing_set_first_page = 12 * 24,
  parts_staff_spacing_set_other_pages = 12 * 24,
  parts_staff_spacing_scale_first_page = 100,
  parts_staff_spacing_scale_other_pages = 100,
  special_staff_spacing_set_first_page = 12 * 24,
  special_staff_spacing_set_other_pages = 12 * 24,
  special_staff_spacing_scale_first_page = 100,
  special_staff_spacing_scale_other_pages = 100,
  score_lock = 0,
  parts_lock = 0,
  special_lock = 0,
  score_reflect_bool = 0,
  parts_reflect_bool = 0,
  special_reflect_bool = 0
}
local special_config = "Page_Format_Wizard_Special_Part_Prefs"
local function win_mac(winval, macval)
  if finenv.UI():IsOnWindows() then return winval end
  return macval
end
local hold = true
local str = finale.FCString()
local function update_layout()
  local ui = finenv.UI()
  local update_layout_menu = win_mac(12110, 1433422945)
  ui:ExecuteOSMenuCommand(update_layout_menu)
end
function bold_control(control)
  local font = control:CreateFontInfo()
  font:SetBold(true)
  control:SetFont(font)
end
function math_sign(number)
  return (number >= 0 and 1) or -1
end
function math_round(number, round_to)
  number = number or 0
  round_to = round_to or 1
  return math.floor(math.abs(number)/round_to + 0.5) * round_to * math_sign(number)
end
local function mm_to_efix(mm)
  local efix = mm * (18432 / 25.4)
  return efix
end
local function efix_to_mm(efix)
  local mm = efix * (25.4 / 18432)
  return mm
end
local function absolute_height(staff_height, resize)
  local abs_h = staff_height / (resize/100)
  return abs_h
end
local function efix_to_mm_string(efix)
  str:SetMeasurement(efix/64*10, finale.MEASUREMENTUNIT_CENTIMETERS)
  local temp = str.LuaString
  temp = math_round(tonumber(temp), .1)
  str.LuaString = tostring(temp)
  return str
end
local function staff_h_prefs_to_staves(staff_h_prefs)

  local staff_h_staves = staff_h_prefs * (64/16)
  return staff_h_staves
end
local function staff_h_staves_to_prefs(staff_h_staves)

  local staff_h_prefs = staff_h_staves * (16/64)
  return staff_h_prefs
end
local temp = 0
local units = {
  {"EVPUs", "e", finale.MEASUREMENTUNIT_EVPUS},
  {"Inches", "in.", finale.MEASUREMENTUNIT_INCHES},
  {"Centimeters", "cm", finale.MEASUREMENTUNIT_CENTIMETERS},
  {"Points", "pt", finale.MEASUREMENTUNIT_POINTS},
  {"Picas", "p", finale.MEASUREMENTUNIT_PICAS},
  {"Spaces", "sp" , finale.MEASUREMENTUNIT_SPACES}
}
local page_sizes = {
  {"Letter (8.5×11\")", 2448, 3168, finale.MEASUREMENTUNIT_INCHES},
  {"Legal (8.5×14\")", 2448, 4032, finale.MEASUREMENTUNIT_INCHES},
  {"Tabloid (11×17\")", 3168, 4896, finale.MEASUREMENTUNIT_INCHES},
  {"A5 (148×210 mm)", 1672, 2373, finale.MEASUREMENTUNIT_CENTIMETERS},
  {"B5 (176×250 mm)", 1994, 2834, finale.MEASUREMENTUNIT_CENTIMETERS},
  {"A4 (210×297 mm)", 2381, 3368, finale.MEASUREMENTUNIT_CENTIMETERS},
  {"B4 (257×364 mm)", 2920, 4127, finale.MEASUREMENTUNIT_CENTIMETERS},
  {"A3 (297×420 mm)", 3366, 4761, finale.MEASUREMENTUNIT_CENTIMETERS},
  {"Statement (5.5×8.5\")", 1584, 2448, finale.MEASUREMENTUNIT_INCHES},
  {"Hymn (5.75×8.25\")", 1656, 2376, finale.MEASUREMENTUNIT_INCHES},
  {"Octavo (6.75×10.5\")", 1944, 3024, finale.MEASUREMENTUNIT_INCHES},
  {"Concert (9×12\")", 2592, 3456, finale.MEASUREMENTUNIT_INCHES},
  {"Part (9.5×12.5\")", 2736, 3600, finale.MEASUREMENTUNIT_INCHES},
  {"Part (10×13\")", 2880, 3744, finale.MEASUREMENTUNIT_INCHES},
  {"iPad 11\"", 2605, 1820, finale.MEASUREMENTUNIT_INCHES},
  {"iPad 12.9\"", 2980, 2234, finale.MEASUREMENTUNIT_INCHES},
  {"*CUSTOM*", 1, 1, finale.MEASUREMENTUNIT_INCHES}
}
local raster_sizes = {
  {"Size 0 (9.2 mm)", "Children's piano books", 92},
  {"Size 1 (7.9 mm)", "Early grades and bands", 79},
  {"Size 2 (7.4 mm)", "Instrumental parts, piano music, songs", 74},
  {"Size 3 (7.0 mm)", "Inst. Parts (small), sheet music, vocal scores", 70},
  {"Size 4 (6.5 mm)", "Choral music", 65},
  {"Size 5 (6.0 mm)", "Full scores", 60},
  {"Size 6 (5.5 mm)", "Full scores, miniature scores, cues", 55},
  {"Size 7 (4.8 mm)", "Full scores, miniature scores, cues", 48},
  {"Size 8 (3.7 mm)", "FULL scores, miniature scores", 37},
  {"* Custom *", "", 1}
}
local score_settings = {}
local score_enable_checkbox
local score_ctrls = {}
local score_ctrls_collection = {}
local parts_settings = {}
local parts_enable_checkbox
local parts_ctrls = {}
local parts_ctrls_collection = {}
local special_settings = {initialize = 1}
local special_enable_checkbox
local special_ctrls = {}
local special_ctrls_collection = {}
local function match_page(w, h)
  w = math_round(w, 1)
  h = math_round(h, 1)
  local matched = -1
  local landscape = 0
  for k, v in pairs(page_sizes) do
    if (w == v[2] and h == v[3]) or (h == v[2] and w == v[3]) then
      matched = k
    end
  end
  if matched < 0 then
    local count = 0
    for _ in pairs(page_sizes) do
      count = count + 1
    end
    matched = count
  end
  if w > h then
    landscape = 1
  end
  return matched, landscape
end
function add_ctrl(dialog, ctrl_type, text, x, y, w, h)
  str.LuaString = text
  local ctrl
  if ctrl_type == "button" then
    ctrl = dialog:CreateButton(x, y - win_mac(3, 3))
  elseif ctrl_type == "checkbox" then
    ctrl = dialog:CreateCheckbox(x,  y + win_mac(1,2))
    w = win_mac(12, 10)
    h = w
  elseif ctrl_type == "datalist" then
    ctrl = dialog:CreateDataList(x, y)
  elseif ctrl_type == "edit" then
    ctrl = dialog:CreateEdit(x - win_mac(0,0), y - win_mac(3,3))
  elseif ctrl_type == "horizontalline" then
    ctrl = dialog:CreateHorizontalLine(x, y, w)
    if h == 0 then h = 1 end
  elseif ctrl_type == "verticalline" then
    ctrl = dialog:CreateVerticalLine(x, y, h)
    if w == 0 then w = 1 end
  elseif ctrl_type == "popup" then
    ctrl = dialog:CreatePopup(x, y - win_mac(4,3))
  elseif ctrl_type == "static" then
    ctrl = dialog:CreateStatic(x, y)
    local font = finale.FCFontInfo()
    str.LuaString = win_mac("MS Shell Dlg", ".AppleSystemUIFont")
    font:SetNameString(str)
    local text_metrics = finale.FCTextMetrics()
    str.LuaString = text
    text_metrics:LoadString(str, font, 100)
    local string_width = text_metrics:CalcWidthPoints() * win_mac(1, 1.2)
    if w < string_width then w = string_width end
  elseif ctrl_type == "updown" then
    ctrl = dialog:CreateUpDown(x,y - win_mac(2,0))
    w = win_mac(11, 11)
    h = win_mac(20, 18)
  end
  ctrl:SetWidth(w)
  ctrl:SetHeight(h)
  ctrl:SetText(str)
  return ctrl
end
local function orientation_set(w, h, mode)
  if mode == 0 and h > w then
    return w, h
  else
    return h, w
  end
end
local function orientation_set_popup(w, h, popup)
  if not hold then
    if w > h then
      popup:SetSelectedItem(1)
    else
      popup:SetSelectedItem(0)
    end
  end
end
local function config_load()

  if special_settings.initialize == 1 then
    special_settings.initialize = 0
    for k,v in pairs(parts_settings) do
      special_settings[k] = v
    end
  end
  configuration.get_user_settings(special_config, special_settings)

  configuration.get_user_settings(config_file, config)
  score_settings.system_units = config.score_system_units
  parts_settings.system_units = config.parts_system_units
  special_settings.system_units = config.special_system_units
  score_settings.bypass_systems_bool = config.score_bypass_systems_bool
  parts_settings.bypass_systems_bool = config.parts_bypass_systems_bool
  special_settings.bypass_systems_bool = config.special_bypass_sytems_bool
  score_settings.staff_spacing = config.score_staff_spacing
  parts_settings.staff_spacing = config.parts_staff_spacing
  special_settings.staff_spacing = config.special_staff_spacing
  score_settings.staff_spacing_first_page_bool = config.score_staff_spacing_first_page_bool
  parts_settings.staff_spacing_first_page_bool = config.parts_staff_spacing_first_page_bool
  special_settings.staff_spacing_first_page_bool = config.special_staff_spacing_first_page_bool
  score_settings.staff_spacing_set_first_page = config.score_staff_spacing_set_first_page
  score_settings.staff_spacing_set_other_pages = config.score_staff_spacing_set_other_pages
  score_settings.staff_spacing_scale_first_page = config.score_staff_spacing_scale_first_page
  score_settings.staff_spacing_scale_other_pages = config.score_staff_spacing_scale_other_pages
  parts_settings.staff_spacing_set_first_page = config.parts_staff_spacing_set_first_page
  parts_settings.staff_spacing_set_other_pages = config.parts_staff_spacing_set_other_pages
  parts_settings.staff_spacing_scale_first_page = config.parts_staff_spacing_scale_first_page
  parts_settings.staff_spacing_scale_other_pages = config.parts_staff_spacing_scale_other_pages
  special_settings.staff_spacing_set_first_page = config.special_staff_spacing_set_first_page
  special_settings.staff_spacing_set_other_pages = config.special_staff_spacing_set_other_pages
  special_settings.staff_spacing_scale_first_page = config.special_staff_spacing_scale_first_page
  special_settings.staff_spacing_scale_other_pages = config.special_staff_spacing_scale_other_pages
  score_settings.lock = config.score_lock
  parts_settings.lock = config.parts_lock
  special_settings.lock = config.special_lock
  score_settings.reflect_bool = config.score_reflect_bool
  parts_settings.reflect_bool = config.parts_reflect_bool
  special_settings.reflect_bool = config.special_reflect_bool
end
local function config_save()
  config.score_system_units = score_settings.system_units
  config.parts_system_units = parts_settings.system_units
  config.special_system_units = special_settings.system_units
  config.score_bypass_systems_bool = score_settings.bypass_systems_bool
  config.parts_bypass_systems_bool =  parts_settings.bypass_systems_bool
  config.special_bypass_systems_bool = special_settings.bypass_systems_bool
  config.score_staff_spacing = score_settings.staff_spacing
  config.parts_staff_spacing = parts_settings.staff_spacing
  config.special_staff_spacing = special_settings.staff_spacing
  config.score_staff_spacing_first_page_bool = score_settings.staff_spacing_first_page_bool
  config.parts_staff_spacing_first_page_bool = parts_settings.staff_spacing_first_page_bool
  config.special_staff_spacing_first_page_bool = special_settings.staff_spacing_first_page_bool
  config.score_staff_spacing_set_first_page = score_settings.staff_spacing_set_first_page
  config.score_staff_spacing_set_other_pages = score_settings.staff_spacing_set_other_pages
  config.score_staff_spacing_scale_first_page = score_settings.staff_spacing_scale_first_page
  config.score_staff_spacing_scale_other_pages = score_settings.staff_spacing_scale_other_pages
  config.parts_staff_spacing_set_first_page = parts_settings.staff_spacing_set_first_page
  config.parts_staff_spacing_set_other_pages = parts_settings.staff_spacing_set_other_pages
  config.parts_staff_spacing_scale_first_page = parts_settings.staff_spacing_scale_first_page
  config.parts_staff_spacing_scale_other_pages = parts_settings.staff_spacing_scale_other_pages
  config.special_staff_spacing_set_first_page = special_settings.staff_spacing_set_first_page
  config.special_staff_spacing_set_other_pages = special_settings.staff_spacing_set_other_pages
  config.special_staff_spacing_scale_first_page = special_settings.staff_spacing_scale_first_page
  config.special_staff_spacing_scale_other_pages = special_settings.staff_spacing_scale_other_pages
  config.score_lock = score_settings.lock
  config.parts_lock = parts_settings.lock
  config.special_lock = special_settings.lock
  config.score_reflect_bool = score_settings.reflect_bool
  config.parts_reflect_bool = parts_settings.reflect_bool
  config.special_reflect_bool = special_settings.reflect_bool
  configuration.save_user_settings(config_file, config)

  configuration.save_user_settings(special_config, special_settings)
end
local function format_wizard()
  local dialog = finale.FCCustomLuaWindow()
  str.LuaString = "Page Format Wizard - v"..finaleplugin.Version
  dialog:SetTitle(str)

  local row_h = 20
  local row = 1
  local col_w = win_mac(38,40)
  local col = {}
  for i = 1, 20 do
    col[i] = (i - 1) * col_w
  end
  local section_w = col[8]
  local section_n = 0
  local x
  local y = 0

  local function match_preset(controls, page_settings)
    local match_preset_bool, landscape = match_page(page_settings.page_w, page_settings.page_h)
    if match_preset_bool then
      controls.page_size_popup:SetSelectedItem(match_preset_bool-1)
      controls.page_units_popup:SetSelectedItem(page_sizes[match_preset_bool][4]-1)
      page_settings.page_units = units[controls.page_units_popup:GetSelectedItem()+1][3]
    end
    if landscape then
      controls.orientation_popup:SetSelectedItem(landscape)
    end
  end
  local function page_size_preset(controls, page_settings)
    local selected_size = controls.page_size_popup:GetSelectedItem()+1
    controls.page_units_popup:SetSelectedItem(page_sizes[selected_size][4]-1)
    str.LuaString = units[controls.page_units_popup:GetSelectedItem()+1][2]
    controls.page_units:SetText(str)
    controls.first_page_top_units:SetText(str)
    controls.left_page_units_static:SetText(str)
    controls.right_page_units_static:SetText(str)
    page_settings.page_w = page_sizes[selected_size][2]
    page_settings.page_h = page_sizes[selected_size][3]
    page_settings.page_w, page_settings.page_h = orientation_set(page_settings.page_w, page_settings.page_h, controls.orientation_popup:GetSelectedItem())
    controls.page_width_edit:SetMeasurement(page_settings.page_w, page_sizes[selected_size][4])
    controls.page_height_edit:SetMeasurement(page_settings.page_h, page_sizes[selected_size][4])
  end
  local staff_space_first_page_enable
  local function page_size_update(controls, page_settings, ctrls_collection)
    page_settings.page_units = units[controls.page_units_popup:GetSelectedItem()+1][3]
    str.LuaString = units[controls.page_units_popup:GetSelectedItem()+1][2]
    controls.page_units:SetText(str)
    controls.first_page_top_units:SetText(str)
    controls.left_page_units_static:SetText(str)
    controls.right_page_units_static:SetText(str)
    controls.page_width_edit:SetMeasurement(page_settings.page_w, page_settings.page_units)
    controls.page_height_edit:SetMeasurement(page_settings.page_h, page_settings.page_units)
    if page_settings.first_page_bool == 1 then
      controls.first_page_top_edit:SetMeasurement(page_settings.first_page_top_margin, page_settings.page_units)
    end
    controls.left_page_top_edit:SetMeasurement(page_settings.left_page_top_margin, page_settings.page_units)
    controls.left_page_left_edit:SetMeasurement(page_settings.left_page_left_margin, page_settings.page_units)
    controls.left_page_right_edit:SetMeasurement(page_settings.left_page_right_margin, page_settings.page_units)
    controls.left_page_bottom_edit:SetMeasurement(page_settings.left_page_bottom_margin, page_settings.page_units)
    if page_settings.reflect_bool == 1 then
      page_settings.right_page_top_margin = page_settings.left_page_top_margin
      page_settings.right_page_left_margin = page_settings.left_page_right_margin
      page_settings.right_page_right_margin = page_settings.left_page_left_margin
      page_settings.right_page_bottom_margin = page_settings.left_page_bottom_margin
      for _,v in ipairs(ctrls_collection.right_page_ctrls_2) do
        v:SetEnable(false)
      end
    else
      for _,v in ipairs(ctrls_collection.right_page_ctrls_2) do
        v:SetEnable(true)
      end
    end
    controls.right_page_top_edit:SetMeasurement(page_settings.right_page_top_margin, page_settings.page_units)
    controls.right_page_left_edit:SetMeasurement(page_settings.right_page_left_margin, page_settings.page_units)
    controls.right_page_right_edit:SetMeasurement(page_settings.right_page_right_margin, page_settings.page_units)
    controls.right_page_bottom_edit:SetMeasurement(page_settings.right_page_bottom_margin, page_settings.page_units)
    match_preset(controls, page_settings)
    orientation_set_popup(page_settings.page_w, page_settings.page_h, controls.orientation_popup)
    controls.page_scale_edit:SetInteger(page_settings.page_scale)
    if page_settings.first_page_top_margin_bool then
      controls.first_page_top_checkbox:SetCheck(1)
      controls.first_page_top_edit:SetEnable(true)
      controls.first_page_top_units:SetVisible(true)
    else
      controls.first_page_top_checkbox:SetCheck(0)
      controls.first_page_top_edit:SetEnable(false)
      controls.first_page_top_units:SetVisible(false)
    end
    controls.first_page_top_edit:SetMeasurement(page_settings.first_page_top_margin, page_settings.page_units)
    if page_settings.facing_pages_bool then
      controls.facing_pages_checkbox:SetCheck(1)
      for _, v in ipairs(ctrls_collection.right_page_ctrls_1) do
        v:SetVisible(true)
      end
      for _, v in ipairs(ctrls_collection.right_page_ctrls_2) do
        v:SetVisible(true)
      end
    else
      controls.facing_pages_checkbox:SetCheck(0)
      for _, v in ipairs(ctrls_collection.right_page_ctrls_1) do
        v:SetVisible(false)
      end
      for _, v in ipairs(ctrls_collection.right_page_ctrls_2) do
        v:SetVisible(false)
      end
    end

    if page_settings.first_system_bool then
      controls.first_system_checkbox:SetCheck(1)
      for _, v in ipairs(ctrls_collection.first_sys_ctrls) do
        v:SetVisible(true)
      end
    else
      controls.first_system_checkbox:SetCheck(0)
      for _, v in ipairs(ctrls_collection.first_sys_ctrls) do
        v:SetVisible(false)
      end
    end

    if page_settings.bypass_systems_bool > 0 then
      controls.system_margins_check:SetCheck(1)
      for _, v in ipairs(ctrls_collection.system_margin_ctrls) do
        v:SetEnable(true)
      end
    else
      controls.system_margins_check:SetCheck(0)
      for _, v in ipairs(ctrls_collection.system_margin_ctrls) do
        v:SetEnable(false)
      end
    end

    page_settings.system_units = units[controls.system_units_popup:GetSelectedItem()+1][3]
    str.LuaString = units[controls.system_units_popup:GetSelectedItem()+1][2]
    controls.between_systems_units:SetText(str)
    controls.first_system_from_top_units:SetText(str)
    controls.system_units_static:SetText(str)
    controls.first_system_units_static:SetText(str)
    if page_settings.staff_spacing == 2 then
      controls.staff_spacing_first_page_units:SetText(str)
      controls.staff_spacing_other_pages_units:SetText(str)
    end
    controls.between_systems_edit:SetMeasurement(page_settings.system_distance_between*-1, page_settings.system_units)
    controls.first_system_from_top_edit:SetMeasurement(page_settings.first_system_distance, page_settings.system_units)
    controls.system_top_edit:SetMeasurement(page_settings.system_top_margin, page_settings.system_units)
    controls.first_system_top_edit:SetMeasurement(page_settings.first_system_top_margin, page_settings.system_units)
    controls.system_left_edit:SetMeasurement(page_settings.system_left_margin, page_settings.system_units)
    controls.system_right_edit:SetMeasurement(page_settings.system_right_margin*-1, page_settings.system_units)
    controls.first_system_left_edit:SetMeasurement(page_settings.first_system_left_margin, page_settings.system_units)
    controls.system_bottom_edit:SetMeasurement(page_settings.system_bottom_margin-96, page_settings.system_units)

    temp = math_round(efix_to_mm(page_settings.staff_h)*10, 1)
    controls.staff_h_invisible:SetInteger(temp)
    controls.staff_h_updown:SetValue(temp)
    controls.staff_h_edit:SetText(efix_to_mm_string(page_settings.staff_h))
    local raster_match_bool = false
    local count = 0
    for k in ipairs(raster_sizes) do
      if temp == raster_sizes[k][3] then
        controls.staff_size_popup:SetSelectedItem(k-1)
        str.LuaString = raster_sizes[k][2]
        controls.staff_settings_static:SetText(str)
        raster_match_bool = true
      end
      count = count + 1
    end
    if not raster_match_bool then
      controls.staff_size_popup:SetSelectedItem(count-1)
      str.LuaString = raster_sizes[count][2]
      controls.staff_settings_static:SetText(str)
    end

    controls.staff_spacing_popup:SetSelectedItem(page_settings.staff_spacing)
    controls.staff_spacing_first_page_checkbox:SetCheck(page_settings.staff_spacing_first_page_bool)
    if page_settings.staff_spacing == 0 then
      for _, v in pairs(ctrls_collection.staff_spacing_ctrls) do
        v:SetVisible(false)
      end
    elseif page_settings.staff_spacing == 1 then
      for _, v in pairs(ctrls_collection.staff_spacing_ctrls) do
        v:SetVisible(true)
      end
      str.LuaString = units[controls.system_units_popup:GetSelectedItem()+1][2]
      controls.staff_spacing_first_page_units:SetText(str)
      controls.staff_spacing_other_pages_units:SetText(str)
      controls.staff_spacing_first_page_edit:SetMeasurement(page_settings.staff_spacing_set_first_page, page_settings.system_units)
      controls.staff_spacing_other_pages_edit:SetMeasurement(page_settings.staff_spacing_set_other_pages, page_settings.system_units)
    elseif page_settings.staff_spacing == 2 then
      for _, v in pairs(ctrls_collection.staff_spacing_ctrls) do
        v:SetVisible(true)
      end
      str.LuaString = "%"
      controls.staff_spacing_first_page_units:SetText(str)
      controls.staff_spacing_other_pages_units:SetText(str)
      controls.staff_spacing_first_page_edit:SetInteger(page_settings.staff_spacing_scale_first_page)
      controls.staff_spacing_other_pages_edit:SetInteger(page_settings.staff_spacing_scale_other_pages)
    end
    staff_space_first_page_enable(controls, page_settings)
    controls.lock_popup:SetSelectedItem(page_settings.lock)
  end
  function staff_space_first_page_enable(controls, page_settings)
    if page_settings.staff_spacing_first_page_bool == 1 and page_settings.staff_spacing > 0 then
      str.LuaString = "First Page:"
      controls.staff_spacing_first_page_static:SetText(str)
      controls.staff_spacing_first_page_edit:SetVisible(true)
      controls.staff_spacing_first_page_units:SetVisible(true)
      str.LuaString = "Others:"
      controls.staff_spacing_other_pages_static:SetText(str)
    elseif page_settings.staff_spacing_first_page_bool == 0 then
      str.LuaString = "(First)"
      controls.staff_spacing_first_page_static:SetText(str)

      controls.staff_spacing_first_page_edit:SetVisible(false)
      controls.staff_spacing_first_page_units:SetVisible(false)
      str.LuaString = "       All:"
      controls.staff_spacing_other_pages_static:SetText(str)
    end
  end
  local function section_enable(check, controls, page_settings, ctrls_collection)
    page_size_update(controls, page_settings, ctrls_collection)
    if check:GetCheck() == 1 then
      for _, v in pairs(controls) do
        v:SetEnable(true)
      end
    else
      for _, v in pairs(controls) do
        v:SetEnable(false)
      end
    end
    if check:GetCheck() == 1 and controls.first_page_top_checkbox:GetCheck() == 1 then
      controls.first_page_top_edit:SetEnable(true)
    else
      controls.first_page_top_edit:SetEnable(false)
    end
    controls.auto_reflect_check:SetCheck(page_settings.reflect_bool)
    for _, v in pairs(ctrls_collection.right_page_ctrls_2) do
      if page_settings.reflect_bool == 1 then
        v:SetEnable(false)
      else
        if check:GetCheck() == 1 then
          v:SetEnable(true)
        end
      end
    end
    if page_settings.bypass_systems_bool < 1 then
      for _, v in pairs(ctrls_collection.system_margin_ctrls) do
        v:SetEnable(false)
      end
    end
  end
  local function format_pages_and_save()
    local controls = {}
    local page_settings
    local score_format_prefs = finale.FCPageFormatPrefs()
    local parts_format_prefs = finale.FCPageFormatPrefs()
    parts_format_prefs:LoadParts()
    local special_format_prefs = finale.FCPageFormatPrefs()
    local parts = finale.FCParts()
    parts:LoadAll()

    local function copy_format_prefs(page_settings, page_format_prefs)
      page_format_prefs:SetPageWidth(page_settings.page_w)
      page_format_prefs:SetPageHeight(page_settings.page_h)
      page_format_prefs:SetPageScaling(page_settings.page_scale)
      page_format_prefs:SetUseFirstPageTopMargin(page_settings.first_page_top_margin_bool)
      page_format_prefs:SetFirstPageTopMargin(page_settings.first_page_top_margin)
      page_format_prefs:SetUseFacingPages(page_settings.facing_pages_bool)
      page_format_prefs:SetLeftPageTopMargin(page_settings.left_page_top_margin)
      page_format_prefs:SetLeftPageLeftMargin(page_settings.left_page_left_margin)
      page_format_prefs:SetLeftPageRightMargin(page_settings.left_page_right_margin)
      page_format_prefs:SetLeftPageBottomMargin(page_settings.left_page_bottom_margin)
      page_format_prefs:SetRightPageTopMargin(page_settings.right_page_top_margin)
      page_format_prefs:SetRightPageLeftMargin(page_settings.right_page_left_margin)
      page_format_prefs:SetRightPageRightMargin(page_settings.right_page_right_margin)
      page_format_prefs:SetRightPageBottomMargin(page_settings.right_page_bottom_margin)
      page_format_prefs:SetUseFirstSystemMargins(page_settings.first_system_bool)

      page_format_prefs:SetUseFirstSystemMargins(page_settings.first_system_bool)
      page_format_prefs:SetFirstSystemDistance(page_settings.first_system_distance)
      page_format_prefs:SetFirstSystemTop(page_settings.first_system_top_margin)
      page_format_prefs:SetFirstSystemLeft(page_settings.first_system_left_margin)
      page_format_prefs:SetSystemTop(page_settings.system_top_margin)
      page_format_prefs:SetSystemLeft(page_settings.system_left_margin)
      page_format_prefs:SetSystemRight(page_settings.system_right_margin)
      page_format_prefs:SetSystemBottom(page_settings.system_bottom_margin)
      page_format_prefs:SetSystemDistanceBetween(page_settings.system_distance_between)
      page_format_prefs:SetSystemScaling(100)
      page_format_prefs.SystemStaffHeight = staff_h_staves_to_prefs(page_settings.staff_h)
    end
    if  score_enable_checkbox:GetCheck() == 1 then
      score_format_prefs:LoadScore()
      copy_format_prefs(score_settings, score_format_prefs)
      score_format_prefs:Save()
    end
    if parts_enable_checkbox:GetCheck() == 1 then
      parts_format_prefs:LoadParts()
      copy_format_prefs(parts_settings, parts_format_prefs)
      parts_format_prefs:Save()
    end
    if special_enable_checkbox:GetCheck() == 1 then
      special_format_prefs:LoadParts()
      copy_format_prefs(special_settings, special_format_prefs)
    end

    local function lock_set(lock_bool)
      local ui = finenv.UI()
      local select_all = win_mac(10515, 1935764588)
      ui:ExecuteOSMenuCommand(select_all)
      local locks
      if lock_bool then
        locks = win_mac(12104, 1296387179)
      else
        locks = win_mac(12105, 1296389484)
      end
      ui:ExecuteOSMenuCommand(locks)
    end
    local function check_for_special(part_num)
      for i = 0, special_ctrls.parts_datalist:GetCount()-1 do
        row = special_ctrls.parts_datalist:GetItemAt(i)
        str = row:GetItemAt(1)
        if part_num == tonumber(str.LuaString) then
          if row:GetCheck() then
            return true
          end
        end
      end
    end
    for part in each(parts) do
      if score_enable_checkbox:GetCheck() == 1 and part:IsScore() then
        page_settings = score_settings
        controls = score_ctrls
      elseif part:IsPart() then
        local is_special_part = false
        if special_enable_checkbox:GetCheck() == 1 then
          is_special_part = check_for_special(part.ItemNo)
          if is_special_part then
            page_settings = special_settings
            controls = special_ctrls
            special_format_prefs:Save()
          end
        end
        if parts_enable_checkbox:GetCheck() == 1 and not is_special_part then
          page_settings = parts_settings
          controls = parts_ctrls
          parts_format_prefs:Save()
        elseif parts_enable_checkbox:GetCheck() == 0 and not is_special_part then
          goto skip
        end
      else
        goto skip
      end
      part:SwitchTo()
      if page_settings.lock == 1 then
        lock_set(true)
      elseif page_settings.lock == 2 then
        lock_set(false)
      end

      local pages = finale.FCPages()
      pages:LoadAll()
      for page in each(pages) do
        page:SetWidth(page_settings.page_w)
        page:SetHeight(page_settings.page_h)
        page:SetPercent(page_settings.page_scale)
        local is_right_page = page:GetItemNo() % 2
        if is_right_page == 1 and page_settings.facing_pages_bool then
          page:SetTopMargin(page_settings.right_page_top_margin)
          page:SetLeftMargin(page_settings.right_page_left_margin)
          page:SetRightMargin(page_settings.right_page_right_margin)
          page:SetBottomMargin(page_settings.right_page_bottom_margin)
        else
          page:SetTopMargin(page_settings.left_page_top_margin)
          page:SetLeftMargin(page_settings.left_page_left_margin)
          page:SetRightMargin(page_settings.left_page_right_margin)
          page:SetBottomMargin(page_settings.left_page_bottom_margin)
        end
        if page:GetItemNo() == 1 and page_settings.first_page_top_margin_bool then
          page:SetTopMargin(page_settings.first_page_top_margin)
        end
        if page:Save() then
          page:Save()
        else
          page:SaveNew()
        end
      end

      local function staff_height_set(staffsys, height)
        staffsys.Resize = 100
        staffsys.StaffHeight = height
        staffsys:Save()
      end
      local systems = finale.FCStaffSystems()
      systems:LoadAll()
      for system in each(systems) do
        if page_settings.bypass_systems_bool > 0 then
          if system:GetItemNo() == 1 and page_settings.first_system_bool then
            system:SetTopMargin(page_settings.first_system_top_margin)
            system:SetLeftMargin(page_settings.first_system_left_margin)
            system:SetSpaceAbove(page_settings.first_system_distance)
          else
            system:SetTopMargin(page_settings.system_top_margin)
            system:SetLeftMargin(page_settings.system_left_margin)
            system:SetSpaceAbove(page_settings.system_distance_between*-1)
          end
          system:SetRightMargin(page_settings.system_right_margin)
          system:SetBottomMargin(page_settings.system_bottom_margin)
        end

        staff_height_set(system, page_settings.staff_h)
        if controls.staff_spacing_popup:GetSelectedItem() > 0 then
          local sysstaves = finale.FCSystemStaves()
          sysstaves:LoadAllForItem(system:GetItemNo())
          local last_staff_pos = 0
          local staff_starting_pos = 0
          local total_move = 0
          local count = 0
          for sysstaff in each(sysstaves) do
            if sysstaff:GetStaff() ~= system:CalcTopStaff() then
              if controls.staff_spacing_popup:GetSelectedItem() == 1 then
                if pages:FindSystemNumber(system.ItemNo).ItemNo == 1 and page_settings.staff_spacing_first_page_bool == 1 then
                  sysstaff:SetDistance(count * page_settings.staff_spacing_set_first_page)
                else
                  sysstaff:SetDistance(count * page_settings.staff_spacing_set_other_pages)
                end
              elseif controls.staff_spacing_popup:GetSelectedItem() == 2 then
                staff_starting_pos = sysstaff:GetDistance()
                local gap
                local move_staff_by
                if pages:FindSystemNumber(system.ItemNo).ItemNo == 1  and page_settings.staff_spacing_first_page_bool == 1 then
                  gap = sysstaff:GetDistance() - last_staff_pos
                  move_staff_by = (gap * page_settings.staff_spacing_scale_first_page/100) - gap
                  total_move = total_move + move_staff_by
                  sysstaff:SetDistance(sysstaff:GetDistance() + total_move)
                else
                  gap = sysstaff:GetDistance() - last_staff_pos
                  move_staff_by = (gap * page_settings.staff_spacing_scale_other_pages/100) - gap
                  total_move = total_move + move_staff_by
                  sysstaff:SetDistance(sysstaff:GetDistance() + total_move)
                end
              end
            end
            last_staff_pos = staff_starting_pos
            count = count + 1
            sysstaff:Save()
          end
        end
        if system:Save() then
          system:Save()
        else
          system:SaveNew()
        end
        if systems:NeedUpdateLayout() then
          finale.FCStaffSystems:UpdateFullLayout()
        end
      end
      part:Save()
      ::skip::
    end
    parts_format_prefs:Save()
    local function update_scaling()
      if score_enable_checkbox:GetCheck() == 1 then
        score_settings.staff_spacing_scale_first_page = 100
        score_settings.staff_spacing_scale_other_pages = 100
        page_size_update(score_ctrls, score_settings, score_ctrls_collection)
      end
      if parts_enable_checkbox:GetCheck() == 1 then
        parts_settings.staff_spacing_scale_first_page = 100
        parts_settings.staff_spacing_scale_other_pages = 100
        page_size_update(parts_ctrls, parts_settings, parts_ctrls_collection)
      end
      if special_enable_checkbox:GetCheck() == 1 then
        special_settings.staff_spacing_scale_first_page = 100
        special_settings.staff_spacing_scale_other_pages = 100
        page_size_update(special_ctrls, special_settings, special_ctrls_collection)
      end
    end
    update_scaling()
    config_save()
  end
  local function initialize_page_settings()
    for i = 1, 2 do
      local page_settings
      local page_format_prefs = finale.FCPageFormatPrefs()
      if i == 1 then
        page_format_prefs:LoadScore()
        page_settings = score_settings
      else
        page_format_prefs:LoadParts()
        page_settings = parts_settings
      end
      page_settings.page_units = finale.MEASUREMENTUNIT_DEFAULT
      page_settings.page_w = page_format_prefs.PageWidth
      page_settings.page_h = page_format_prefs.PageHeight
      page_settings.page_scale = page_format_prefs.PageScaling
      page_settings.first_page_top_margin_bool = page_format_prefs:GetUseFirstPageTopMargin()
      page_settings.first_page_top_margin = page_format_prefs:GetFirstPageTopMargin()
      page_settings.facing_pages_bool = page_format_prefs:GetUseFacingPages()
      page_settings.left_page_top_margin = page_format_prefs:GetLeftPageTopMargin()
      page_settings.left_page_left_margin = page_format_prefs:GetLeftPageLeftMargin()
      page_settings.left_page_right_margin = page_format_prefs:GetLeftPageRightMargin()
      page_settings.left_page_bottom_margin = page_format_prefs:GetLeftPageBottomMargin()
      page_settings.right_page_top_margin = page_format_prefs:GetRightPageTopMargin()
      page_settings.right_page_left_margin = page_format_prefs:GetRightPageLeftMargin()
      page_settings.right_page_right_margin = page_format_prefs:GetRightPageRightMargin()
      page_settings.right_page_bottom_margin = page_format_prefs:GetRightPageBottomMargin()
      page_settings.first_system_bool = page_format_prefs:GetUseFirstSystemMargins()
      page_settings.first_system_distance = page_format_prefs:GetFirstSystemDistance()
      page_settings.first_system_top_margin  = page_format_prefs:GetFirstSystemTop()
      page_settings.first_system_left_margin = page_format_prefs:GetFirstSystemLeft()
      page_settings.system_top_margin = page_format_prefs:GetSystemTop()
      page_settings.system_left_margin = page_format_prefs:GetSystemLeft()
      page_settings.system_right_margin = page_format_prefs:GetSystemRight()
      page_settings.system_bottom_margin = page_format_prefs:GetSystemBottom()
      page_settings.system_distance_between = page_format_prefs:GetSystemDistanceBetween()
      page_settings.staff_h = staff_h_prefs_to_staves(page_format_prefs.SystemStaffHeight)
      page_settings.staff_scaling = page_format_prefs.SystemScaling
      page_settings.staff_h  = absolute_height(page_settings.staff_h , page_settings.staff_scaling)
    end
  end
  local function copy_settings_to_special(page_settings)
    for k, v in pairs(page_settings) do
      special_settings[k] = v
    end
  end
  initialize_page_settings()
  config_load()
  x = section_n*section_w
  score_enable_checkbox = add_ctrl(dialog, "checkbox", "", x, 0, 10, 10)
  score_enable_checkbox:SetCheck(config.score_enable)
  local score_static = add_ctrl(dialog, "static", "SCORE", x + 12, 0, col_w, row_h)
  section_n = section_n + 1
  x = section_n*section_w
  add_ctrl(dialog, "verticalline", "", x-20, 0, 1, row_h*34)
  parts_enable_checkbox = add_ctrl(dialog, "checkbox", "", x, 0, 10, 10)
  parts_enable_checkbox:SetCheck(config.parts_enable)
  local parts_static = add_ctrl(dialog, "static", "DEFAULT PARTS", x + 12, 0, col_w, row_h)
  section_n = section_n + 1
  x = section_n*section_w
  add_ctrl(dialog, "verticalline", "", x-20, 0, 1, row_h*34)
  special_enable_checkbox = add_ctrl(dialog, "checkbox", "", x, 0, 10, 10)
  special_enable_checkbox:SetCheck(config.special_enable)
  local special_static = add_ctrl(dialog, "static", "SPECIAL PARTS", x + 12, 0, col_w, row_h)
  local function section_create(controls, page_settings, ctrls_collection)
    row = 1
    y = row*row_h
    x = section_n*section_w
    controls.page_section = add_ctrl(dialog, "static", "Page Settings:", x, y, col_w, row_h)
    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.page_units_static = add_ctrl(dialog, "static", "Page Units:", x, y, col_w, row_h)
    controls.page_units_popup = add_ctrl(dialog, "popup", "", x+col_w*2, y-1, col_w*3, row_h)
    for i in ipairs(units) do
      str.LuaString = units[i][1]
      controls.page_units_popup:AddString(str)
    end

    row = row + 1
    y = row*row_h
    controls.page_size_static = add_ctrl(dialog, "static", "Page Size:", x, y, col_w, row_h)
    controls.page_size_popup = add_ctrl(dialog, "popup", "", x+col_w*2, y-1, col_w*3, row_h)
    for i in ipairs(page_sizes) do
      str.LuaString = page_sizes[i][1]
      controls.page_size_popup:AddString(str)
    end

    row = row + 1
    y = row*row_h
    x = section_n*section_w + col[2] + 20
    controls.page_width = add_ctrl(dialog, "static", "W:", x, y, 10, row_h)
    controls.page_width_edit = add_ctrl(dialog, "edit", "", x+win_mac(18,20), y, col_w, row_h)
    x = x + col_w*2 - 14
    controls.page_height = add_ctrl(dialog, "static", "H:", x, y, 10, row_h)
    controls.page_height_edit = add_ctrl(dialog, "edit", "", x+win_mac(18,20), y, col_w, row_h)
    x = x + col_w + 20
    controls.page_units = add_ctrl(dialog, "static", "OI", x, y, 10, row_h-4)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.score_orientation_static = add_ctrl(dialog, "static", "Orientation:", x, y, col_w, row_h)
    controls.orientation_popup = add_ctrl(dialog, "popup", "", x+col_w*2, y, col_w*3, row_h)
    str.LuaString = "Portrait"
    controls.orientation_popup:AddString(str)
    str.LuaString = "Landscape"
    controls.orientation_popup:AddString(str)

    row = row + 1
    y = row*row_h
    controls.page_scale = add_ctrl(dialog, "static", "Page Scaling:", x, y, col_w, row_h)
    controls.page_scale_edit = add_ctrl(dialog, "edit", "", x+col_w*2, y, col_w, row_h)
    controls.page_scale_percent = add_ctrl(dialog, "static", "%", x+col_w*3, y, 10, row_h)

    row = row + 1
    y = row*row_h
    controls.page_margins_section = add_ctrl(dialog, "static", "Page Margins:", x, y, col_w, row_h)
    row = row + 1
    y = row*row_h
    controls.first_page_top_checkbox = add_ctrl(dialog, "checkbox", "", x, y, 10, 10)
    controls.first_page_top_static = add_ctrl(dialog, "static", "First Page Top:", x+12, y, col_w, row_h)
    x = section_n*section_w + col[4] - 12
    controls.first_page_top_edit = add_ctrl(dialog, "edit", "", x, y, col_w, row_h)
    x = section_n*section_w + col[5] - 12
    controls.first_page_top_units = add_ctrl(dialog, "static", "OI", x, y, col_w, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.facing_pages_checkbox = add_ctrl(dialog, "checkbox", "", x, y, 10, 10)
    controls.facing_pages_static = add_ctrl(dialog, "static", "Facing Pages (Left/Right)", x+12, y, col_w, row_h)

    row = row + 1
    y = row*row_h
    controls.left_page_static = add_ctrl(dialog, "static", "Left Pages:", x, y, col_w, row_h)
    x = section_n*section_w + col[4]
    controls.facing_pages_line = add_ctrl(dialog, "verticalline", "", x-win_mac(6,12), y, 1, row_h*6)
    controls.right_page_static = add_ctrl(dialog, "static", "Right Pages:", x, y, col_w, row_h)

    controls.auto_reflect_check = add_ctrl(dialog, "checkbox", "", x+col[3]-2, y, 10, 10)
    controls.auto_reflect_static = add_ctrl(dialog, "static", "Auto", x+col[3]+win_mac(12,10), y, 10, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w + col[2]
    controls.left_page_top_static = add_ctrl(dialog, "static", "Top", x-1, y+4, 10, row_h)
    x = section_n*section_w + col[5]
    controls.right_page_top_static = add_ctrl(dialog, "static", "Top", x-1, y+4, 10, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w + col[2]
    controls.left_page_top_edit = add_ctrl(dialog, "edit", "", x-8, y, col_w, row_h)
    x = section_n*section_w + col[3]
    controls.left_page_units_static = add_ctrl(dialog, "static", "OI", x-8, y, 10, row_h)
    x = section_n*section_w + col[5]
    controls.right_page_top_edit = add_ctrl(dialog, "edit", "", x-8, y, col_w, row_h)
    x = section_n*section_w + col[6]
    controls.right_page_units_static = add_ctrl(dialog, "static", "OI", x-8, y, 10, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.left_page_left_static = add_ctrl(dialog, "static", "L", x, y, 10, row_h)
    controls.left_page_left_edit = add_ctrl(dialog, "edit", "", x+10, y, col_w, row_h)
    x = x+col_w+12
    controls.left_page_right_edit = add_ctrl(dialog, "edit", "", x, y, col_w, row_h)
    controls.left_page_right_static = add_ctrl(dialog, "static", "R", x+col_w, y, 10, row_h)
    x = section_n*section_w + col_w*3
    controls.right_page_left_static = add_ctrl(dialog, "static", "L", x, y, 10, row_h)
    controls.right_page_left_edit = add_ctrl(dialog, "edit", "", x+10, y, col_w, row_h)
    x = x+col_w+12
    controls.right_page_right_edit = add_ctrl(dialog, "edit", "", x, y, col_w, row_h)
    controls.right_page_right_static = add_ctrl(dialog, "static", "R", x+col_w, y, 10, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w + col[2]
    controls.left_page_bottom_edit = add_ctrl(dialog, "edit", "", x-8, y, col_w, row_h)
    x = section_n*section_w + col[5]
    controls.right_page_bottom_edit = add_ctrl(dialog, "edit", "", x-8, y, col_w, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w + col[2]
    controls.left_page_bottom_static = add_ctrl(dialog, "static", "Bottom", x-9, y-4, col_w, row_h)
    x = section_n*section_w + col[5]
    controls.right_page_bottom_static = add_ctrl(dialog, "static", "Bottom", x-9, y-4, col_w, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.page_margin_separator = add_ctrl(dialog, "horizontalline", "", x, y+row_h/2, col[7], 1)

    row = row + 1
    y = row*row_h
    controls.system_margins_check = add_ctrl(dialog, "checkbox", "", x, y, 10, 10)
    controls.system_margins_section = add_ctrl(dialog, "static", "System Settings:", x + 12, y, col_w, row_h)
    row = row + 1
    y = row*row_h
    controls.system_units = add_ctrl(dialog, "static", "System Units:", x, y, col_w, row_h)
    controls.system_units_popup = add_ctrl(dialog, "popup", "", x+col_w*2, y, col_w*3, row_h)
    for i in ipairs(units) do
      str.LuaString = units[i][1]
      controls.system_units_popup:AddString(str)
    end
    controls.system_units_popup:SetSelectedItem(page_settings.system_units-1)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.margins_static = add_ctrl(dialog, "static", "Margins:", x, y, col_w, row_h)
    x = section_n*section_w + col[4]
    controls.first_system_checkbox = add_ctrl(dialog, "checkbox", "", x, y, 10, 10)
    controls.first_system_top = add_ctrl(dialog, "static", "Diff. First System", x+12, y, 10, row_h)
    controls.first_system_top:SetWidth(80)
    controls.first_system_line = add_ctrl(dialog, "verticalline", "", x-win_mac(6,12), y, 1, row_h*6.5)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.between_systems = add_ctrl(dialog, "static", "Between:", x, y, col_w, row_h)
    controls.between_systems_edit = add_ctrl(dialog, "edit", "", x+col_w+14, y, col_w-2, row_h)
    controls.between_systems_units = add_ctrl(dialog, "static", "IO", x+col_w*2+12, y, 10, row_h)
    x = section_n*section_w + col[4]
    controls.first_system_from_top = add_ctrl(dialog, "static", "From Top:", x, y, col_w, row_h)
    controls.first_system_from_top_edit = add_ctrl(dialog, "edit", "", x+col_w+16, y, col_w-2, row_h)
    controls.first_system_from_top_units = add_ctrl(dialog, "static", "OI", x+col_w*2+14, y, 10, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w + col[2]
    controls.system_top_static = add_ctrl(dialog, "static", "Top", x-1, y+4, col_w, row_h)
    x = section_n*section_w + col[5]
    controls.first_system_top_static = add_ctrl(dialog, "static", "Top", x-1, y+4, col_w, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w + col[2]
    controls.system_top_edit = add_ctrl(dialog, "edit", "", x-8, y, col_w, row_h)
    x = section_n*section_w + col[3]
    controls.system_units_static = add_ctrl(dialog, "static", "OI", x-8, y, 10, row_h)
    x = section_n*section_w + col[5]
    controls.first_system_top_edit = add_ctrl(dialog, "edit", "", x-8, y, col_w, row_h)
    x = section_n*section_w + col[6]
    controls.first_system_units_static = add_ctrl(dialog, "static", "OI", x-8, y, 10, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.system_left_static = add_ctrl(dialog, "static", "L", x, y, 10, row_h)
    controls.system_left_edit = add_ctrl(dialog, "edit", "", x+10, y, col_w, row_h)
    x = x+col_w+12
    controls.system_right_edit = add_ctrl(dialog, "edit", "", x, y, col_w, row_h)
    controls.system_right_static = add_ctrl(dialog, "static", "R", x+col_w, y, 10, row_h)
    x = section_n*section_w + col_w*3
    controls.first_system_left_static = add_ctrl(dialog, "static", "L", x, y, 10, row_h)
    controls.first_system_left_edit = add_ctrl(dialog, "edit", "", x+10, y, col_w, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w + col[2]
    controls.system_bottom_edit = add_ctrl(dialog, "edit", "", x-8, y, col_w, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w + col[2]
    controls.system_bottom_static = add_ctrl(dialog, "static", "Bottom", x-9, y-4, col_w, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.system_margin_separator = add_ctrl(dialog, "horizontalline", "", x, y, col[7], 1)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.staff_settings = add_ctrl(dialog, "static", "Staff Settings:", x, y, col_w, row_h)
    row = row + 1
    y = row*row_h
    controls.staff_size = add_ctrl(dialog, "static", "Rastral Size:", x, y, col_w, row_h)
    x = x + col[3]
    controls.staff_size_popup = add_ctrl(dialog, "popup", "", x, y, col_w*3, row_h)
    for k in ipairs(raster_sizes) do
      str.LuaString = raster_sizes[k][1]
      controls.staff_size_popup:AddString(str)
    end

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.staff_settings_static = add_ctrl(dialog, "static", "***Description***", x, y, col[7], row_h)
    row = row + 1
    y = row*row_h
    controls.staff_h_invisible = add_ctrl(dialog, "edit", "", x, y, 10, 10)
    controls.staff_h_invisible:SetVisible(false)
    controls.staff_h_static = add_ctrl(dialog, "static", "Staff Height:", x, y, col_w, row_h)
    controls.staff_h_edit = add_ctrl(dialog, "edit", "", x+col[3], y, col_w, row_h)
    controls.staff_h_updown = add_ctrl(dialog, "updown", "", x+col[4]-4, y, 20, row_h)
    controls.staff_h_updown:ConnectIntegerEdit(controls.staff_h_invisible, 30, 100)
    controls.staff_h_mm_static = add_ctrl(dialog, "static", "mm", x+col[4]+12, y, 20, row_h)

    temp = math_round(efix_to_mm(page_settings.staff_h)*10, .1)
    controls.staff_h_invisible:SetInteger(temp ,1)
    controls.staff_h_edit:SetText(efix_to_mm_string(page_settings.staff_h))
    controls.staff_h_updown:SetValue(controls.staff_h_invisible:GetInteger())

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.staff_spacing_static = add_ctrl(dialog, "static", "Staff Spacing:", x, y, col_w, row_h)
    controls.staff_spacing_popup = add_ctrl(dialog, "popup", "", x+col[3], y, col_w*3, row_h)
    str.LuaString = "(Don't Respace)"
    controls.staff_spacing_popup:AddString(str)
    str.LuaString = "Set To..."
    controls.staff_spacing_popup:AddString(str)
    str.LuaString = "Scale By..."
    controls.staff_spacing_popup:AddString(str)
    controls.staff_spacing_popup:SetSelectedItem(page_settings.staff_spacing)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.staff_spacing_first_page_checkbox = add_ctrl(dialog, "checkbox", "", x, y, 10, 10)
    controls.staff_spacing_first_page_checkbox:SetCheck(page_settings.staff_spacing_first_page_bool)
    controls.staff_spacing_first_page_static = add_ctrl(dialog, "static", "First Page:", x+12, y, col_w, row_h)
    controls.staff_spacing_first_page_edit = add_ctrl(dialog, "edit", "", x+col[3]-8, y, col_w, row_h)
    controls.staff_spacing_first_page_units = add_ctrl(dialog, "static", "OI", x+col[4]-8, y, 10, row_h)
    controls.staff_spacing_other_pages_static = add_ctrl(dialog, "static", "Others:", x+col[4]+16, y, col_w, row_h)
    controls.staff_spacing_other_pages_edit = add_ctrl(dialog, "edit", "", x+col[5]+20, y, col_w, row_h)
    controls.staff_spacing_other_pages_units = add_ctrl(dialog, "static", "OI", x+col[6]+20, y, 10, row_h)

    row = row + 1
    y = row*row_h
    x = section_n*section_w
    controls.lock_popup = add_ctrl(dialog, "popup", "", x+col[2], y, col_w*4, row_h)
    str.LuaString = "(Don't Lock/Unlock)"
    controls.lock_popup:AddString(str)
    str.LuaString = "Lock Systems"
    controls.lock_popup:AddString(str)
    str.LuaString = "Unlock Systems"
    controls.lock_popup:AddString(str)
    controls.lock_popup:SetSelectedItem(page_settings.lock)

    if section_n == 2 then
      row = 0
      y = row*row_h
      x = section_n*section_w + col[4] - 3
      controls.copy_from_static = add_ctrl(dialog, "static", "Copy From:", x+3, y, col_w, row_h)
      row = row + 1
      y = row*row_h
      controls.copy_parts_button = add_ctrl(dialog, "button", "Parts", x-2, y, col[2]+2, row_h-4)
      controls.copy_score_button = add_ctrl(dialog, "button", "Score", x+col[2]+2, y, col[2]+2, row_h-4)

      row = 1
      y = row*row_h
      x = (section_n + 1)*section_w - col_w
      controls.parts_datalist = add_ctrl(dialog, "datalist", "DATALIST!!!", x, y, col[6], row_h*33)
      if finenv.UI():IsOnMac() then
        controls.parts_datalist:UseAlternatingBackgroundRowColors()
      end
      str.LuaString = "Part Name:"
      controls.parts_datalist.UseCheckboxes = true
      controls.parts_datalist:AddColumn(str, col[6])
      str.LuaString = "Part Num:"
      controls.parts_datalist:AddColumn(str, 20)
      local parts = finale.FCParts()
      parts:LoadAll()
      for part in each(parts) do
        if part:IsPart() then
          part:GetName(str)
          row = controls.parts_datalist:CreateRow()
          row:GetItemAt(0).LuaString = str.LuaString
          row:GetItemAt(1).LuaString = part:GetItemNo()
        end
      end
      controls.clear_datalist_button = add_ctrl(dialog, "button", "Clear", x, 0, col[2]-4, row_h)
    end


    ctrls_collection.system_margin_ctrls = {
      controls.system_units,
      controls.system_units_popup,
      controls.margins_static,
      controls.first_system_checkbox,
      controls.first_system_top,
      controls.first_system_line,
      controls.between_systems,
      controls.between_systems_edit,
      controls.between_systems_units,
      controls.first_system_from_top,
      controls.first_system_from_top_edit,
      controls.first_system_from_top_units,
      controls.system_top_static,
      controls.first_system_top_static,
      controls.system_top_edit,
      controls.system_units_static,
      controls.first_system_top_edit,
      controls.first_system_units_static,
      controls.system_left_static,
      controls.system_left_edit,
      controls.system_right_edit,
      controls.system_right_static,
      controls.first_system_left_static,
      controls.first_system_left_edit,
      controls.system_bottom_edit,
      controls.system_bottom_static
    }
    ctrls_collection.staff_spacing_ctrls = {
      controls.staff_spacing_first_page_checkbox,
      controls.staff_spacing_first_page_static,
      controls.staff_spacing_first_page_edit,
      controls.staff_spacing_first_page_units,
      controls.staff_spacing_other_pages_static,
      controls.staff_spacing_other_pages_edit,
      controls.staff_spacing_other_pages_units
    }

    ctrls_collection.right_page_ctrls_1 = {
      controls.facing_pages_line,
      controls.left_page_static,
      controls.right_page_static,
      controls.auto_reflect_check,
      controls.auto_reflect_static
    }
    ctrls_collection.right_page_ctrls_2 = {
      controls.right_page_top_static,
      controls.right_page_top_edit,
      controls.right_page_left_static,
      controls.right_page_left_edit,
      controls.right_page_right_static,
      controls.right_page_right_edit,
      controls.right_page_bottom_static,
      controls.right_page_bottom_edit,
      controls.right_page_units_static
    }
    ctrls_collection.first_sys_ctrls = {
      controls.first_system_line,
      controls.first_system_from_top,
      controls.first_system_from_top_edit,
      controls.first_system_from_top_units,
      controls.first_system_top_static,
      controls.first_system_top_edit,
      controls.first_system_units_static,
      controls.first_system_left_static,
      controls.first_system_left_edit
    }
    match_preset(controls, page_settings)
    page_size_update(controls, page_settings, ctrls_collection)
    return controls, page_settings, ctrls_collection
  end
  section_n = 0
  score_ctrls, score_settings, score_ctrls_collection = section_create(score_ctrls, score_settings, score_ctrls_collection)
  section_n = 1

  parts_ctrls, parts_settings, parts_ctrls_collection = section_create(parts_ctrls, parts_settings, parts_ctrls_collection)
  section_n = 2

  special_ctrls, special_settings, special_ctrls_collection = section_create(special_ctrls, special_settings, special_ctrls_collection)

  section_enable(score_enable_checkbox, score_ctrls, score_settings, score_ctrls_collection)
  section_enable(parts_enable_checkbox, parts_ctrls, parts_settings, parts_ctrls_collection)
  section_enable(special_enable_checkbox, special_ctrls, special_settings, special_ctrls_collection)
  dialog:RegisterHandleControlEvent (score_enable_checkbox, function(_control)
      section_enable(score_enable_checkbox, score_ctrls, score_settings, score_ctrls_collection)
      config.score_enable = score_enable_checkbox:GetCheck()
    end)
  dialog:RegisterHandleControlEvent (parts_enable_checkbox, function(_control)
      section_enable(parts_enable_checkbox, parts_ctrls, parts_settings, parts_ctrls_collection)
      config.parts_enable = parts_enable_checkbox:GetCheck()
    end)
  dialog:RegisterHandleControlEvent (special_enable_checkbox, function(_control)
      section_enable(special_enable_checkbox, special_ctrls, special_settings, special_ctrls_collection)
      config.special_enable = special_enable_checkbox:GetCheck()
    end)
  local function register_controls(controls, page_settings, ctrls_collection)
    dialog:RegisterHandleControlEvent (controls.page_size_popup, function(_control)
        if not hold then
          hold = true
          page_size_preset(controls, page_settings)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.page_units_popup, function(_control)
        if not hold then
          hold = true
          local temp_units = controls.page_units_popup:GetSelectedItem()
          page_size_update(controls, page_settings, ctrls_collection)
          controls.page_units_popup:SetSelectedItem(temp_units)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.page_width_edit, function(_control)
        if not hold then
          hold = true
          page_settings.page_units = units[controls.page_units_popup:GetSelectedItem()+1][3]
          page_settings.page_w = controls.page_width_edit:GetMeasurement(page_settings.page_units)
          match_preset(controls, page_settings)
          orientation_set_popup(page_settings.page_w, page_settings.page_h, controls.orientation_popup)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.page_height_edit, function(_control)
        if not hold then
          hold = true
          page_settings.page_units = units[controls.page_units_popup:GetSelectedItem()+1][3]
          page_settings.page_h = controls.page_height_edit:GetMeasurement(page_settings.page_units)
          match_preset(controls, page_settings)
          orientation_set_popup(page_settings.page_w, page_settings.page_h, controls.orientation_popup)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.orientation_popup, function(control)
        if page_settings.page_w < page_settings.page_h and control:GetSelectedItem() == 1 or
        page_settings.page_w > page_settings.page_h and control:GetSelectedItem() == 0 then
          if not hold then
            hold = true
            page_settings.page_w, page_settings.page_h = orientation_set(page_settings.page_w, page_settings.page_h, controls.orientation_popup:GetSelectedItem())
            page_size_update(controls, page_settings, ctrls_collection)
            hold = false
          end
        end
      end)
    dialog:RegisterHandleControlEvent (controls.page_scale_edit, function(_control)
        page_settings.page_scale = controls.page_scale_edit:GetFloat(1, 500)
      end)
    dialog:RegisterHandleControlEvent (controls.first_page_top_checkbox, function(_control)
        if not hold then
          hold = true
          if controls.first_page_top_checkbox:GetCheck() == 1 then
            page_settings.first_page_top_margin_bool = true
          else
            page_settings.first_page_top_margin_bool = false
          end
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.facing_pages_checkbox, function(_control)
        if not hold then
          hold = true
          if controls.facing_pages_checkbox:GetCheck() == 1 then
            page_settings.facing_pages_bool = true
          else
            page_settings.facing_pages_bool = false
          end
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.first_page_top_edit, function(_control)
        if not hold then
          hold = true
          page_settings.first_page_top_margin = controls.first_page_top_edit:GetMeasurement(page_settings.page_units)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.left_page_top_edit, function(_control)
        if not hold then
          hold = true
          page_settings.left_page_top_margin = controls.left_page_top_edit:GetMeasurement(page_settings.page_units)
          if page_settings.reflect_bool == 1 then
            page_settings.right_page_top_margin = page_settings.left_page_top_margin
            controls.right_page_top_edit:SetMeasurement(page_settings.right_page_top_margin, page_settings.page_units)
          end
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.left_page_left_edit, function(_control)
        if not hold then
          hold = true
          page_settings.left_page_left_margin = controls.left_page_left_edit:GetMeasurement(page_settings.page_units)
          if page_settings.reflect_bool == 1 then
            page_settings.right_page_right_margin = page_settings.left_page_left_margin
            controls.right_page_right_edit:SetMeasurement(page_settings.right_page_right_margin, page_settings.page_units)
          end
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.left_page_right_edit, function(_control)
        if not hold then
          hold = true
          page_settings.left_page_right_margin = controls.left_page_right_edit:GetMeasurement(page_settings.page_units)
          if page_settings.reflect_bool == 1 then
            page_settings.right_page_left_margin = page_settings.left_page_right_margin
            controls.right_page_left_edit:SetMeasurement(page_settings.right_page_left_margin, page_settings.page_units)
          end
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.left_page_bottom_edit, function(_control)
        if not hold then
          hold = true
          page_settings.left_page_bottom_margin = controls.left_page_bottom_edit:GetMeasurement(page_settings.page_units)
          if page_settings.reflect_bool == 1 then
            page_settings.right_page_bottom_margin = page_settings.left_page_bottom_margin
            controls.right_page_bottom_edit:SetMeasurement(page_settings.right_page_bottom_margin, page_settings.page_units)
          end
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.right_page_top_edit, function(_control)
        if not hold then
          hold = true
          page_settings.right_page_top_margin = controls.right_page_top_edit:GetMeasurement(page_settings.page_units)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.right_page_left_edit, function(_control)
        if not hold then
          hold = true
          page_settings.right_page_left_margin = controls.right_page_left_edit:GetMeasurement(page_settings.page_units)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.right_page_right_edit, function(_control)
        if not hold then
          hold = true
          page_settings.right_page_right_margin = controls.right_page_right_edit:GetMeasurement(page_settings.page_units)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.right_page_bottom_edit, function(_control)
        if not hold then
          hold = true
          page_settings.right_page_bottom_margin = controls.right_page_bottom_edit:GetMeasurement(page_settings.page_units)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.auto_reflect_check, function(_control)
        if not hold then
          hold = true
          page_settings.reflect_bool = controls.auto_reflect_check:GetCheck()
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.system_margins_check, function(_control)
        if not hold then
          hold = true
          page_settings.bypass_systems_bool = controls.system_margins_check:GetCheck()
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.system_units_popup, function(_control)
        if not hold then
          hold = true
          page_settings.system_units = controls.system_units_popup:GetSelectedItem()
          page_size_update(controls, page_settings, ctrls_collection)
          controls.system_units_popup:SetSelectedItem(page_settings.system_units-1)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.first_system_checkbox, function(_control)
        if not hold then
          hold = true
          if controls.first_system_checkbox:GetCheck() == 1 then
            page_settings.first_system_bool = true
          else
            page_settings.first_system_bool = false
          end
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.between_systems_edit, function(_control)
        page_settings.system_distance_between = controls.between_systems_edit:GetMeasurement(page_settings.system_units) * -1
      end)
    dialog:RegisterHandleControlEvent (controls.first_system_from_top_edit, function(_control)
        page_settings.first_system_distance = controls.first_system_from_top_edit:GetMeasurement(page_settings.system_units)
      end)
    dialog:RegisterHandleControlEvent (controls.system_top_edit, function(_control)
        page_settings.system_top_margin = controls.system_top_edit:GetMeasurement(page_settings.system_units)
      end)
    dialog:RegisterHandleControlEvent (controls.first_system_top_edit, function(_control)
        page_settings.first_system_top_margin = controls.first_system_top_edit:GetMeasurement(page_settings.system_units)
      end)
    dialog:RegisterHandleControlEvent (controls.system_left_edit, function(_control)
        page_settings.system_left_margin = controls.system_left_edit:GetMeasurement(page_settings.system_units)
      end)
    dialog:RegisterHandleControlEvent (controls.system_right_edit, function(_control)
        page_settings.system_right_margin = controls.system_right_edit:GetMeasurement(page_settings.system_units) * -1
      end)
    dialog:RegisterHandleControlEvent (controls.first_system_left_edit, function(_control)
        if not hold then
          hold = true
          page_settings.first_system_left_margin = controls.first_system_left_edit:GetMeasurement(page_settings.system_units)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.system_bottom_edit, function(_control)
        page_settings.system_bottom_margin = controls.system_bottom_edit:GetMeasurement(page_settings.system_units)+96
      end)
    dialog:RegisterHandleControlEvent (controls.staff_h_edit, function(_control)
        if not hold then
          hold = true
          page_settings.staff_h = mm_to_efix(controls.staff_h_edit:GetMeasurement(finale.MEASUREMENTUNIT_MILLIMETERS))
          temp = math_round(controls.staff_h_edit:GetMeasurement(finale.MEASUREMENTUNIT_MILLIMETERS)*10, 1)
          controls.staff_h_invisible:SetInteger(temp)
          controls.staff_h_updown:SetValue(temp)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.staff_size_popup, function(_control)
        if not hold then
          hold = true
          temp = raster_sizes[controls.staff_size_popup:GetSelectedItem()+1][3]/100
          str.LuaString = (tostring(temp))
          page_settings.staff_h = str:GetMeasurement(finale.MEASUREMENTUNIT_CENTIMETERS)*64
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.staff_spacing_popup, function(_control)
        if not hold then
          hold = true
          page_settings.staff_spacing = controls.staff_spacing_popup:GetSelectedItem()
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.staff_spacing_first_page_checkbox, function(_control)
        if not hold then
          hold = true
          page_settings.staff_spacing_first_page_bool = controls.staff_spacing_first_page_checkbox:GetCheck()
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.staff_spacing_first_page_edit, function(_control)
        if not hold then
          hold = true
          if controls.staff_spacing_popup:GetSelectedItem() == 1 then
            page_settings.staff_spacing_set_first_page = controls.staff_spacing_first_page_edit:GetMeasurement(finale.MEASUREMENTUNIT_SPACES)
          elseif controls.staff_spacing_popup:GetSelectedItem() == 2 then
            page_settings.staff_spacing_scale_first_page = controls.staff_spacing_first_page_edit:GetFloat(0, 1024)
          end
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.staff_spacing_other_pages_edit, function(_control)
        if not hold then
          hold = true
          if controls.staff_spacing_popup:GetSelectedItem() == 1 then
            page_settings.staff_spacing_set_other_pages = controls.staff_spacing_other_pages_edit:GetMeasurement(finale.MEASUREMENTUNIT_SPACES)
          elseif controls.staff_spacing_popup:GetSelectedItem() == 2 then
            page_settings.staff_spacing_scale_other_pages = controls.staff_spacing_other_pages_edit:GetFloat(0, 1024)
          end
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.lock_popup, function(_control)
        if not hold then
          hold = true
          page_settings.lock = controls.lock_popup:GetSelectedItem()
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.copy_parts_button, function(_control)
        if not hold then
          hold = true
          copy_settings_to_special(parts_settings)
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.copy_score_button, function(_control)
        if not hold then
          hold = true
          copy_settings_to_special(score_settings)
          page_size_update(controls, page_settings, ctrls_collection)
          hold = false
        end
      end)
    dialog:RegisterHandleControlEvent (controls.clear_datalist_button, function(_control)
        for i = 0, controls.parts_datalist:GetCount()-1 do
          row = controls.parts_datalist:GetItemAt(i)
          row:SetCheck(false)
        end
      end)
  end
  register_controls(score_ctrls, score_settings, score_ctrls_collection)
  register_controls(parts_ctrls, parts_settings, parts_ctrls_collection)
  register_controls(special_ctrls, special_settings, special_ctrls_collection)
  local function updown_callback(ctrl, _delta)
    if not hold then
      hold = true
      if ctrl:GetControlID() == score_ctrls.staff_h_updown:GetControlID() then
        temp = score_ctrls.staff_h_invisible:GetInteger()/100
        str.LuaString = (tostring(temp))
        score_settings.staff_h = str:GetMeasurement(finale.MEASUREMENTUNIT_CENTIMETERS)*64
        page_size_update(score_ctrls, score_settings, score_ctrls_collection)
      elseif ctrl:GetControlID() == parts_ctrls.staff_h_updown:GetControlID() then
        temp = parts_ctrls.staff_h_invisible:GetInteger()/100
        str.LuaString = (tostring(temp))
        parts_settings.staff_h = str:GetMeasurement(finale.MEASUREMENTUNIT_CENTIMETERS)*64
        page_size_update(parts_ctrls, parts_settings, parts_ctrls_collection)
      elseif ctrl:GetControlID() == special_ctrls.staff_h_updown:GetControlID() then
        temp = special_ctrls.staff_h_invisible:GetInteger()/100
        str.LuaString = (tostring(temp))
        special_settings.staff_h = str:GetMeasurement(finale.MEASUREMENTUNIT_CENTIMETERS)*64
        page_size_update(special_ctrls, special_settings, special_ctrls_collection)
      end
      hold = false
    end
  end
  dialog:RegisterHandleUpDownPressed(updown_callback)
  local function execute_all()
    local orig_part = finale.FCPart(finale.PARTID_CURRENT)

    str.LuaString = "Format:"
    if score_enable_checkbox:GetCheck() == 1 then
      str.LuaString = str.LuaString.." Score"
      if parts_enable_checkbox:GetCheck() == 1 or special_enable_checkbox:GetCheck() == 1 then
        str.LuaString = str.LuaString..","
      end
    end
    if parts_enable_checkbox:GetCheck() == 1 then
      str.LuaString = str.LuaString.." Parts"
      if special_enable_checkbox:GetCheck() == 1 then
        str.LuaString = str.LuaString..","
      end
    end
    if special_enable_checkbox:GetCheck() == 1 then
      str.LuaString = str.LuaString.." Special Parts"
    end

    finenv.StartNewUndoBlock(str.LuaString, false)
    format_pages_and_save()
    orig_part:SwitchTo()
    update_layout()
    finenv.EndUndoBlock(true)
  end
  local button_ok = dialog:CreateOkButton()
  str.LuaString = "Apply"
  button_ok:SetText(str)
  local button_cancel = dialog:CreateCancelButton()
  str.LuaString = "Close"
  button_cancel:SetText(str)
  dialog:RegisterHandleOkButtonPressed (function(_control)
      execute_all()
    end)
  dialog:SetOkButtonCanClose(false)
  finenv.RegisterModelessDialog(dialog)
  dialog:ShowModeless()
  hold = false
  bold_control(score_static)
  bold_control(parts_static)
  bold_control(special_static)
  bold_control(score_ctrls.page_section)
  bold_control(parts_ctrls.page_section)
  bold_control(special_ctrls.page_section)
  bold_control(score_ctrls.system_margins_section)
  bold_control(parts_ctrls.system_margins_section)
  bold_control(special_ctrls.system_margins_section)
  bold_control(score_ctrls.staff_settings)
  bold_control(parts_ctrls.staff_settings)
  bold_control(special_ctrls.staff_settings)
end
format_wizard()
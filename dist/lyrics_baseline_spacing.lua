package.preload["library.utils"] = package.preload["library.utils"] or function()

    local utils = {}




    function utils.copy_table(t)
        if type(t) == "table" then
            local new = {}
            for k, v in pairs(t) do
                new[utils.copy_table(k)] = utils.copy_table(v)
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

    function utils.iterate_keys(t)
        local a, b, c = pairs(t)
        return function()
            c = a(b, c)
            return c
        end
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

    function utils.show_notes_dialog(caption, width, height)
        if not finaleplugin.RTFNotes and not finaleplugin.Notes then
            return
        end

        width = width or 500
        height = height or 350

        if not caption then
            caption = plugindef()
            if finaleplugin.Version then
                local version = finaleplugin.Version
                if string.sub(version, 1, 1) ~= "v" then
                    version = "v" .. version
                end
                caption = string.format("%s %s", caption, version)
            end
        end
        local dlg = finale.FCCustomLuaWindow()
        dlg:SetTitle(finale.FCString(caption))
        local edit_text = dlg:CreateTextEditor(10, 10)
        edit_text:SetWidth(width)
        edit_text:SetHeight(height)
        edit_text:SetUseRichText(finaleplugin.RTFNotes)
        edit_text:SetReadOnly(true)
        edit_text:SetWordWrap(true)
        local ok = dlg:CreateOkButton()
        local function dedent(input)
            local first_line_indent = input:match("^(%s*)")
            local pattern = "\n" .. string.rep(" ", #first_line_indent)
            local result = input:gsub(pattern, "\n")
            result = result:gsub("^%s+", "")
            return result
        end
        dlg:RegisterInitWindow(
            function()
                local notes = dedent(finaleplugin.RTFNotes or dedent(finaleplugin.Notes))
                local notes_str = finale.FCString(notes)
                if edit_text:GetUseRichText() then
                    edit_text:SetRTFString(notes_str)
                else
                    local edit_font = finale.FCFontInfo()
                    edit_font.Name = "Arial"
                    edit_font.Size = 10
                    edit_text:SetFont(edit_font)
                    edit_text:SetText(notes_str)
                end
                edit_text:ResetColors()
                ok:SetKeyboardFocus()
            end)
        dlg:ExecuteModal(nil)
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
    finaleplugin.Copyright = "©2022 Jacob Winkler"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "2022-07-02"
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/lyrics_baseline_spacing.hash"
    return "Lyrics - Space Baselines", "Lyrics - Space Baselines", "Lyrics - Space Baselines"
end
local configuration = require("library.configuration")
config = {all_lyrics = "true"}
local script_name = "lyrics_baseline_spacing"
configuration.get_user_settings(script_name, config, true)
function lyrics_spacing(title)
    local independent_lyrics = false
    local baseline_verse = finale.FCBaseline()
    baseline_verse:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSVERSE,1)
    local verse1_start = -baseline_verse.VerticalOffset
    baseline_verse:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSVERSE,2)
    local verse_gap =  -baseline_verse.VerticalOffset - verse1_start

    local baseline_chorus = finale.FCBaseline()
    baseline_chorus:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSCHORUS,1)
    local chorus1_start = -baseline_chorus.VerticalOffset
    baseline_chorus:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSCHORUS,2)
    local chorus_gap =  -baseline_chorus.VerticalOffset - chorus1_start

    local baseline_section = finale.FCBaseline()
    baseline_section:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSSECTION,1)
    local section1_start = -baseline_section.VerticalOffset
    baseline_section:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSSECTION,2)
    local section_gap = -baseline_section.VerticalOffset - section1_start

    local row_h = 20
    local col_w = 60
    local col_gap = 10
    local str = finale.FCString()
    str.LuaString = title
    local dialog = finale.FCCustomLuaWindow()
    dialog:SetTitle(str)
    local row = {}
    for i = 1, 100 do
        row[i] = (i -1) * row_h
    end
    local col = {}
    for i = 1, 20 do
        col[i] = (i - 1) * col_w
    end
    local function add_ctrl(dialog, ctrl_type, text, x, y, h, w)
        str.LuaString = tostring(text)
        local ctrl
        if ctrl_type == "checkbox" then
            ctrl = dialog:CreateCheckbox(x, y)
        elseif ctrl_type == "edit" then
            ctrl = dialog:CreateEdit(x, y - 2)
        elseif ctrl_type == "static" then
            ctrl = dialog:CreateStatic(x, y)
        end
        if ctrl_type == "edit" then
            ctrl:SetHeight(h - 2)
            ctrl:SetWidth(w - col_gap)
        else
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
        end
        ctrl:SetText(str)
        return ctrl
    end

    local verse_static = add_ctrl(dialog, "static", "All Lyrics", col[3], row[1], row_h, col_w)
    local chorus_static = add_ctrl(dialog, "static", "", col[4], row[1], row_h, col_w)
    local section_static = add_ctrl(dialog, "static", "", col[5], row[1], row_h, col_w)

    add_ctrl(dialog, "static", "Lyric 1 baseline:", col[1] + 31, row[2], row_h, col_w * 2)
    local verse1_edit = add_ctrl(dialog, "edit", verse1_start, col[3], row[2], row_h, col_w)
    local chorus1_edit = add_ctrl(dialog, "edit", chorus1_start, col[4], row[2], row_h, col_w)
    local section1_edit = add_ctrl(dialog, "edit", section1_start, col[5], row[2], row_h, col_w)

    add_ctrl(dialog, "static", "Gap:", col[2] + 29, row[3], row_h, col_w)
    local verse_gap_edit = add_ctrl(dialog, "edit", verse_gap, col[3], row[3], row_h, col_w)
    local chorus_gap_edit = add_ctrl(dialog, "edit", chorus_gap, col[4], row[3], row_h, col_w)
    local section_gap_edit = add_ctrl(dialog, "edit", section_gap, col[5], row[3], row_h, col_w)

    add_ctrl(dialog, "static", "Edit all:", col[2] + 14, row[4], row_h, col_w)
    local all_lyrics_check = add_ctrl(dialog, "checkbox", "", col[3], row[4], row_h, col_w * 2)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()

    local function apply()
        if config.all_lyrics == true then
            verse1_edit:GetText(str)
            chorus1_edit:SetText(str)
            section1_edit:SetText(str)

            verse_gap_edit:GetText(str)
            chorus_gap_edit:SetText(str)
            section_gap_edit:SetText(str)
        end
        verse1_edit:GetText(str)
        verse1_start = tonumber(str.LuaString) or 0
        chorus1_edit:GetText(str)
        chorus1_start = tonumber(str.LuaString) or 0
        section1_edit:GetText(str)
        section1_start = tonumber(str.LuaString) or 0
        verse_gap_edit:GetText(str)
        verse_gap = tonumber(str.LuaString) or 0
        chorus_gap_edit:GetText(str)
        chorus_gap = tonumber(str.LuaString) or 0
        section_gap_edit:GetText(str)
        section_gap = tonumber(str.LuaString) or 0

        for i = 1, 100, 1 do
            baseline_verse:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSVERSE,i)
            baseline_verse.VerticalOffset = -verse1_start - (verse_gap * (i - 1))
            baseline_verse:Save()

            baseline_chorus:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSCHORUS,i)
            baseline_chorus.VerticalOffset = -chorus1_start - (chorus_gap * (i - 1))
            baseline_chorus:Save()

            baseline_section:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSSECTION,i)
            baseline_section.VerticalOffset = -section1_start - (section_gap * (i - 1))
            baseline_section:Save()
        end
    end
    local function update()
        if not config.all_lyrics then
            independent_lyrics = true
            str.LuaString = "Verse"
            verse_static:SetText(str)
            str.LuaString = "Chorus"
            chorus_static:SetText(str)
            str.LuaString = "Section"
            section_static:SetText(str)
            all_lyrics_check:SetCheck(0)
        else
            independent_lyrics = false
            str.LuaString = "All Lyrics"
            verse_static:SetText(str)
            str.LuaString = ""
            chorus_static:SetText(str)
            section_static:SetText(str)
            all_lyrics_check:SetCheck(1)
        end
        chorus1_edit:SetEnable(independent_lyrics)
        section1_edit:SetEnable(independent_lyrics)
        chorus_gap_edit:SetEnable(independent_lyrics)
        section_gap_edit:SetEnable(independent_lyrics)

    end
    local function callback(ctrl)
        if ctrl:GetControlID() == all_lyrics_check:GetControlID()  then
            if all_lyrics_check:GetCheck() == 1 then
                config.all_lyrics = true
            else
                config.all_lyrics = false
            end
            update()
        end
    end

    dialog:RegisterHandleCommand(callback)

    update()
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        apply()
        configuration.save_user_settings(script_name, config)
    end
end
lyrics_spacing("Lyrics - Space Baselines")
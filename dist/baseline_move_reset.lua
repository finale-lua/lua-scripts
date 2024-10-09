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
function plugindef(locale)
--[[
-- This comment allows RGP Lua pre-0.71 to find the plugindef function
function plugindef()
--]]
    local loc = {}
    loc.en = {
        addl_menus = [[
            Move Lyric Baselines Up
            Reset Lyric Baselines
            Move Expression Baseline Above Down
            Move Expression Baseline Above Up
            Reset Expression Baseline Above
            Move Expression Baseline Below Down
            Move Expression Baseline Below Up
            Reset Expression Baseline Below
            Move Chord Baseline Down
            Move Chord Baseline Up
            Reset Chord Baseline
            Move Fretboard Baseline Down
            Move Fretboard Baseline Up
            Reset Fretboard Baseline
        ]],
        addl_descs = [[
            Moves all lyrics baselines up one space in the selected systems
            Resets all lyrics baselines to their defaults in the selected systems
            Moves the expression above baseline down one space in the selected systems
            Moves the expression above baseline up one space in the selected systems
            Resets the expression above baselines in the selected systems
            Moves the expression below baseline down one space in the selected systems
            Moves the expression below baseline up one space in the selected systems
            Resets the expression below baselines in the selected systems
            Moves the chord baseline down one space in the selected systems
            Moves the chord baseline up one space in the selected systems
            Resets the chord baselines in the selected systems
            Moves the fretboard baseline down one space in the selected systems
            Moves the fretboard baseline up one space in the selected systems
            Resets the fretboard baselines in the selected systems
        ]],
        menu = "Move Lyric Baselines Down",
        desc = "Moves all lyrics baselines down one space in the selected systems",
    }
    loc.es = {
        addl_menus = [[
            Mover las líneas de referencia de las letras hacia arriba
            Restablecer las líneas de referencia de las letras
            Mover la línea de referencia por encima de las expresiones hacia abajo
            Mover la línea de referencia por encima de las expresiones hacia arriba
            Restablecer la línea de referencia por encima de las expresiones
            Mover la línea de referencia por abajo de las expresiones hacia abajo
            Mover la línea de referencia por abajo de las expresiones hacia arriba
            Restablecer la línea de referencia por abajo de las expresiones
            Mover la línea de referencia de los acordes hacia abajo
            Mover la línea de referencia de los acordes hacia arriba
            Restablecer la línea de referencia de los acordes
            Mover la línea de referencia de los trastes hacia abajo
            Mover la línea de referencia de los trastes hacia arriba
            Restablecer la línea de referencia de los trastes
        ]],
        addl_descs = [[
            Mueve todas las líneas de referencia de las letras un espacio hacia arriba en los sistemas de pentagramas seleccionadas
            Restablece todas las líneas de referencia de las letras a su valor predeterminado en los sistemas de pentagramas seleccionadas
            Mueve la línea de referencia por encima de las expresiones hacia abajo un espacio en los sistemas de pentagramas seleccionadas
            Mueve la línea de referencia por encima de las expresiones hacia arriba un espacio en los sistemas de pentagramas seleccionadas
            Restablece la línea de referencia por encima de las expresiones superior en los sistemas de pentagramas seleccionadas
            Mueve la línea de referencia por abajo de las expresiones hacia abajo un espacio en los sistemas de pentagramas seleccionadas
            Mueve la línea de referencia por abajo de las expresiones hacia arriba un espacio en los sistemas de pentagramas seleccionadas
            Restablece la línea de referencia por abajo de las expresiones inferior en los sistemas de pentagramas seleccionadas
            Mueve la línea de referencia de los acordes hacia abajo un espacio en los sistemas de pentagramas seleccionadas
            Mueve la línea de referencia de los acordes hacia arriba un espacio en los sistemas de pentagramas seleccionadas
            Restablece las líneas de referencia de los acordes en los sistemas de pentagramas seleccionadas
            Mueve la línea de referencia de los trastes hacia abajo un espacio en los sistemas de pentagramas seleccionadas
            Mueve la línea de referencia de los trastes hacia arriba un espacio en los sistemas de pentagramas seleccionadas
            Restablece las líneas de referencia de los trastes en los sistemas de pentagramas seleccionadas
        ]],
        menu = "Mover las líneas de referencia de las letras hacia abajo",
        desc = "Mueve todas las líneas de referencia de las letras un espacio hacia abajo en los sistemas de pentagramas seleccionadas",
    }
    local t = locale and loc[locale:sub(1, 2)] or loc.en
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Version = "1.1"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Date = "February 4, 2024"
    finaleplugin.CategoryTags = "Baseline"
    finaleplugin.AuthorURL = "http://robertgpatterson.com"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        This script nudges system baselines up or down by a single staff-space (24 evpus). It introduces 10
        menu options to nudge each baseline type up or down. It also introduces 5 menu options to reset
        the baselines to their staff-level values.

        The possible prefix inputs to the script are

        ```
        direction -- 1 for up, -1 for down, 0 for reset
        baseline_types -- a table containing a list of the baseline types to process
        nudge_evpus -- a positive number indicating the size of the nudge
        ```

        You can also change the size of the nudge by creating a configuration file called `baseline_move.config.txt` and
        adding a single line with the size of the nudge in evpus.

        ```
        nudge_evpus = 36 -- or whatever size you wish
        ```

        A value in a prefix overrides any setting in a configuration file.
    ]]
    finaleplugin.ScriptGroupName = "Move or Reset System Baselines"
    finaleplugin.ScriptGroupDescription = "Move or reset baselines for systems in the selected region"
    finaleplugin.AdditionalMenuOptions = t.addl_menus
    finaleplugin.AdditionalDescriptions = t.addl_descs
    finaleplugin.AdditionalPrefixes = [[
        direction = 1 -- no baseline_types table, which picks up the default (lyrics)
        direction = 0 -- no baseline_types table, which picks up the default (lyrics)
        direction = -1 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = 1 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = 0 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = -1 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = 1 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = 0 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = -1 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = 1 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = 0 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = -1 baseline_types = {finale.BASELINEMODE_FRETBOARD}
        direction = 1 baseline_types = {finale.BASELINEMODE_FRETBOARD}
        direction = 0 baseline_types = {finale.BASELINEMODE_FRETBOARD}
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script nudges system baselines up or down by a single staff-space (24 evpus). It introduces 10 menu options to nudge each baseline type up or down. It also introduces 5 menu options to reset the baselines to their staff-level values.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 The possible prefix inputs to the script are\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 \f1 direction -- 1 for up, -1 for down, 0 for reset\line
        baseline_types -- a table containing a list of the baseline types to process\line
        nudge_evpus -- a positive number indicating the size of the nudge\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 You can also change the size of the nudge by creating a configuration file called {\f1 baseline_move.config.txt} and adding a single line with the size of the nudge in evpus.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 \f1 nudge_evpus = 36 -- or whatever size you wish\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 A value in a prefix overrides any setting in a configuration file.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/baseline_move_reset.hash"
    return  t.menu, t.menu, t.desc
end
local configuration = require("library.configuration")
local config = {nudge_evpus = 24}
if nil ~= configuration then
    configuration.get_parameters("baseline_move.config.txt", config)
end
local lyric_baseline_types = {
    [finale.BASELINEMODE_LYRICSVERSE] = function()
        return finale.FCVerseLyricsText()
    end,
    [finale.BASELINEMODE_LYRICSCHORUS] = function()
        return finale.FCChorusLyricsText()
    end,
    [finale.BASELINEMODE_LYRICSSECTION] = function()
        return finale.FCSectionLyricsText()
    end,
}
local find_valid_lyric_nums = function(baseline_type)
    local lyrics_text_class_constructor = lyric_baseline_types[baseline_type]
    if lyrics_text_class_constructor then
        local valid_lyric_nums = {}
        local lyrics_text_class = lyrics_text_class_constructor()
        for i = 1, 32767, 1 do
            if lyrics_text_class:Load(i) then
                local str = finale.FCString()
                lyrics_text_class:GetText(str)
                if not str:IsEmpty() then
                    valid_lyric_nums[{baseline_type, i}] = 1
                end
            end
        end
        return valid_lyric_nums
    end
    return nil
end
function baseline_move()
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local lastSys_number = lastSys:GetItemNo()
    local start_slot = region:GetStartSlot()
    local end_slot = region:GetEndSlot()
    for _, baseline_type in pairs(baseline_types) do
        local valid_lyric_nums = find_valid_lyric_nums(baseline_type)
        for i = system_number, lastSys_number, 1 do
            local baselines = finale.FCBaselines()
            if direction ~= 0 then
                baselines:LoadAllForSystem(baseline_type, i)
                for j = start_slot, end_slot do
                    local bl
                    if valid_lyric_nums then
                        for lyric_info, _ in pairs(valid_lyric_nums) do
                            local _, lyric_number = table.unpack(lyric_info)
                            bl = baselines:AssureSavedLyricNumber(baseline_type, i, region:CalcStaffNumber(j), lyric_number)
                            bl.VerticalOffset = bl.VerticalOffset + direction * nudge_evpus
                            bl:Save()
                        end
                    else
                        bl = baselines:AssureSavedStaff(baseline_type, i, region:CalcStaffNumber(j))
                        bl.VerticalOffset = bl.VerticalOffset + direction * nudge_evpus
                        bl:Save()
                    end
                end
            else
                for j = start_slot, end_slot do
                    baselines:LoadAllForSystemStaff(baseline_type, i, region:CalcStaffNumber(j))

                    for baseline in eachbackwards(baselines) do
                        baseline:DeleteData()
                    end
                end
            end
        end
    end
end
baseline_types = baseline_types or {finale.BASELINEMODE_LYRICSVERSE, finale.BASELINEMODE_LYRICSCHORUS, finale.BASELINEMODE_LYRICSSECTION}
direction = direction or -1
nudge_evpus = nudge_evpus or config.nudge_evpus
baseline_move()

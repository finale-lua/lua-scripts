--[[
$module Utility Functions

A library of general Lua utility functions.
]] --
local utils = {}

--[[
% copy_table

If a table is passed, returns a copy, otherwise returns the passed value.

@ t (mixed)
@ [to_table] (table) the existing top-level table to copy to if present. (Sub-tables are always copied to new tables.)
@ [overwrite] (boolean) if true, overwrites existing values; if false, does not copy over existing values. Default is true.
: (mixed)
]]
---@generic T
---@param t T
---@return T
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

--[[
% table_remove_first

Removes the first occurrence of a value from an array table.

@ t (table)
@ value (mixed)
]]
function utils.table_remove_first(t, value)
    for k = 1, #t do
        if t[k] == value then
            table.remove(t, k)
            return
        end
    end
end

--[[
% table_is_empty

Returns true if the table is an empty table. This works with both
array tables and keyed tables

@ t *table
: (boolean) true if the input table is empty; false if it is not empty or the input is not a table
]]
function utils.table_is_empty(t)
    if type(t) ~= "table" then
        return false
    end
    for _, _ in pairs(t) do -- luacheck: ignore
        return false
    end
    return true
end

--[[
% iterate_keys

Returns an unordered iterator for the keys in a table.

@ t (table)
: (function)
]]
function utils.iterate_keys(t)
    local a, b, c = pairs(t)

    return function()
        c = a(b, c)
        return c
    end
end

--[[
% get_keys

Returns a sorted array table of all the keys in a table.

@ t (table)
: (table) array table of the keys
]]
function utils.create_keys_table(t)
    local retval = {}

    for k, _ in pairsbykeys(t) do
        table.insert(retval, k)
    end
    return retval
end

--[[
% create_lookup_table

Creates a value lookup table from an existing table.

@ t (table)
: (table)
]]
function utils.create_lookup_table(t)
    local lookup = {}

    for _, v in pairs(t) do
        lookup[v] = true
    end

    return lookup
end

--[[
% round

Rounds a number to the nearest integer or the specified number of decimal places.

@ num (number)
@ [places] (number) If specified, the number of decimal places to round to. If omitted or 0, will round to the nearest integer.
: (number)
]]
function utils.round(value, places)
    places = places or 0
    local multiplier = 10^places
    local ret = math.floor(value * multiplier + 0.5)
    -- Ensures that a real integer type is returned as needed
    return places == 0 and ret or ret / multiplier
end

--[[
% to_integer_if_whole

Takes a number and if it is an integer or whole float (eg 12 or 12.0), returns an integer.
All other floats will be returned as passed.

@ value (number)
: (number)
]]
function utils.to_integer_if_whole(value)
    local int = math.floor(value)
    return value == int and int or value
end

--[[ 
% calc_roman_numeral

Calculates the roman numeral for the input number. Adapted from https://exercism.org/tracks/lua/exercises/roman-numerals/solutions/Nia11 on 2022-08-13

@ num (number)
: (string)
]]
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

--[[ 
% calc_ordinal

Calculates the ordinal for the input number (e.g. 1st, 2nd, 3rd).

@ num (number)
: (string)
]]
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

--[[ 
% calc_alphabet

This returns one of the ways that Finale handles numbering things alphabetically, such as rehearsal marks or measure numbers.

This function was written to emulate the way Finale numbers saves when Autonumber is set to A, B, C... When the end of the alphabet is reached it goes to A1, B1, C1, then presumably to A2, B2, C2. 

@ num (number)
: (string)
]]
function utils.calc_alphabet(num)
    local letter = ((num - 1) % 26) + 1
    local n = math.floor((num - 1) / 26)

    return string.char(64 + letter) .. (n > 0 and n or "")
end

--[[
% clamp

Clamps a number between two values.

@ num (number) The number to clamp.
@ minimum (number) The minimum value.
@ maximum (number) The maximum value.
: (number)
]]
function utils.clamp(num, minimum, maximum)
    return math.min(math.max(num, minimum), maximum)
end

--[[
% ltrim

Removes whitespace from the start of a string.

@ str (string)
: (string)
]]
function utils.ltrim(str)
    return string.match(str, "^%s*(.*)")
end

--[[
% rtrim

Removes whitespace from the end of a string.

@ str (string)
: (string)
]]
function utils.rtrim(str)
    return string.match(str, "(.-)%s*$")
end

--[[
% trim

Removes whitespace from the start and end of a string.

@ str (string)
: (string)
]]
function utils.trim(str)
    return utils.ltrim(utils.rtrim(str))
end

--[[
% call_and_rethrow

Calls a function and returns any returned values. If any errors are thrown at the level this function is called, they will be rethrown at the specified level with new level information.
If the error message contains the rethrow placeholder enclosed in single quotes (see `utils.rethrow_placeholder`), it will be replaced with the correct function name for the new level.

*The first argument must have the same name as the `rethrow_placeholder`, chosen for uniqueness.*

@ levels (number) Number of levels to rethrow.
@ tryfunczzz (function) The function to call.
@ ... (any) Any arguments to be passed to the function.
: (any) If no error is caught, returns the returned values from `tryfunczzz`
]]
local pcall_wrapper
local rethrow_placeholder = "tryfunczzz" -- If changing this, make sure to do a search and replace for all instances in this file, including the argument to `rethrow_error`
local pcall_line = debug.getinfo(1, "l").currentline + 2 -- This MUST refer to the pcall 2 lines below
function utils.call_and_rethrow(levels, tryfunczzz, ...)
    return pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))
    -- ^Tail calls aren't counted as levels in the call stack. Adding an additional return value (in this case, 1) forces this level to be included, which enables the error to be accurately captured
end

-- Get the name of this file.
local source = debug.getinfo(1, "S").source
local source_is_file = source:sub(1, 1) == "@"
if source_is_file then
    source = source:sub(2)
end

-- Processes the results from the pcall in catch_and_rethrow
pcall_wrapper = function(levels, success, result, ...)
    if not success then
        local file
        local line
        local msg
        file, line, msg = result:match("([a-zA-Z]-:?[^:]+):([0-9]+): (.+)")
        msg = msg or result

        local file_is_truncated = file and file:sub(1, 3) == "..."
        file = file_is_truncated and file:sub(4) or file

        -- Conditions for rethrowing at a higher level:
        -- Ignore errors thrown with no level info (ie. level = 0), as we can't make any assumptions
        -- Both the file and line number indicate that it was thrown at this level
        if file
            and line
            and source_is_file
            and (file_is_truncated and source:sub(-1 * file:len()) == file or file == source)
            and tonumber(line) == pcall_line
        then
            local d = debug.getinfo(levels, "n")

            -- Replace the method name with the correct one, for bad argument errors etc
            msg = msg:gsub("'" .. rethrow_placeholder .. "'", "'" .. (d.name or "") .. "'")

            -- Shift argument numbers down by one for colon function calls
            if d.namewhat == "method" then
                local arg = msg:match("^bad argument #(%d+)")

                if arg then
                    msg = msg:gsub("#" .. arg, "#" .. tostring(tonumber(arg) - 1), 1)
                end
            end

            error(msg, levels + 1)

        -- Otherwise, it's either an internal function error or we couldn't be certain that it isn't
        -- So, rethrow with original file and line number to be 'safe'
        else
            error(result, 0)
        end
    end

    return ...
end

--[[
% rethrow_placeholder

Returns the function name placeholder (enclosed in single quotes, the same as in Lua's internal errors) used in `call_and_rethrow`.

Use this in error messages where the function name is variable or unknown (eg because the error is thrown up multiple levels) and needs to be replaced with the correct one at runtime by `call_and_rethrow`.

: (string)
]]
function utils.rethrow_placeholder()
    return "'" .. rethrow_placeholder .. "'"
end

--[[
% show_notes_dialog

Displays a modal dialog with the contents of finaleplugin.RFTNotes (if present) or finaleplugin.Notes. If neither one is present, no dialog is shown.

@ parent (FCResourceWindow) The parent window (if any) that is opening this dialog
@ caption (string) The caption for the dialog. Defaults to plugin name and version.
@ width (number) The width in pixels of the edit control. Defaults to 500.
@ height (number) The height inpixels of the edit control. Defaults to 350.
]]
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

--[[
% win_mac

Returns the winval or the macval depending on which operating system the script is running on.

@ windows_value (any) The Windows value to return
@ mac_value (any) The macOS value to return
: (any) The windows_value or mac_value based on finenv.UI()IsOnWindows()
]]

function utils.win_mac(windows_value, mac_value)
    if finenv.UI():IsOnWindows() then
        return windows_value
    end
    return mac_value
end

--[[
% split_file_path

Splits a file path into folder, file name, and extension.

@ full_path (string) The full file path in a Lua string.
: (string) the folder path always including the final delimeter slash (macOS) or backslash (Windows). This may be an empty string.
: (string) the filename without its extension
: (string) the extension including its leading "." or an empty string if no extension.
]]
function utils.split_file_path(full_path)
    local path_name = finale.FCString()
    local file_name = finale.FCString()
    local file_path = finale.FCString(full_path)
    -- work around bug in SplitToPathAndFile when path is not specified
    if file_path:FindFirst("/") >= 0 or (finenv.UI():IsOnWindows() and file_path:FindFirst("\\") >= 0) then
        file_path:SplitToPathAndFile(path_name, file_name)
    else
        file_name.LuaString = full_path
    end
    -- do not use FCString.ExtractFileExtension() because it has a hard-coded limit of 7 characters (!)
    local extension = file_name.LuaString:match("^.+(%..+)$")
    extension = extension or ""
    if #extension > 0 then
        -- FCString.FindLast is unsafe if extension is not ASCII, so avoid using it
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

--[[
% eachfile

Iterates a file path using lfs and feeds each directory and file name to a function.
The directory names fed to the iterator function always contain path delimeters at the end.
The following are skipped.

- "." and ".."
- any file name starting withn "._" (These are macOS resource forks and can be seen on Windows as well when searching a macOS shared drive.)

Generates a runtime error for plugin versions before RGP Lua 0.68.

@ directory_path (string) the directory path to search, encoded utf8.
@ [recursive)] (boolean) true if subdirectories should always be searched. Defaults to false.
: (function) iterator function to be used in for loop.
]]
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

    -- direcly call text.convert_encoding to avoid dependency on library.utils
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
                elseif (mode == "file" or mode == "link") and lfs_file:sub(1, 2) ~= "._" then -- skip macOS resource files
                    coroutine.yield(directory_path, utf8_file)
                end
            end
        end
    end)
end

return utils

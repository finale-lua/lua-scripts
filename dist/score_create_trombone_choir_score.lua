function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "September 2, 2021"
    finaleplugin.CategoryTags = "Staff"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Create Trombone Choir Ensemble", "Create Trombone Choir Ensemble",
           "Creates the score setup correctly for trombone choir"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
--[[
$module Score
]] --
local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
-- A measurement of helpful JW Lua scripts
-- Simply import this file to another Lua script to use any of these scripts
local measurement = {}

function measurement.convert_to_EVPUs(text)
    local str = finale.FCString()
    str.LuaString = text
    return str:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)
end



--  Author: Robert Patterson
--  Date: March 5, 2021

--[[
$module Configuration

This library implements a UTF-8 text file scheme for configuration as follows:

- Comments start with `--`
- Leading, trailing, and extra whitespace is ignored
- Each parameter is named and delimited as follows:
`<parameter-name> = <parameter-value>`

Parameter values may be:

- Strings delimited with either single- or double-quotes
- Tables delimited with `{}` that may contain strings, booleans, or numbers
- Booleans (`true` or `false`)
- Numbers

Currently the following are not supported:

- Tables embedded within tables
- Tables containing strings that contain commas

A sample configuration file might be:

```lua
-- Configuration File for "Hairpin and Dynamic Adjustments" script
--
left_dynamic_cushion 		= 12		--evpus
right_dynamic_cushion		= -6		--evpus
```

Configuration files must be placed in a subfolder called `script_settings` within
the folder of the calling script. Each script that has a configuration file
defines its own configuration file name.
]]

local configuration = {}

local script_settings_dir = "script_settings" -- the parent of this directory is the running lua path
local comment_marker = "--"
local parameter_delimiter = "="
local path_delimiter = "/"

local file_exists = function(file_path)
    local f = io.open(file_path,"r")
    if nil ~= f then
        io.close(f)
        return true
    end
    return false
end

local strip_leading_trailing_whitespace = function (str)
    return str:match("^%s*(.-)%s*$") -- lua pattern magic taken from the Internet
end

local parse_parameter -- forward function declaration

local parse_table = function(val_string)
    local ret_table = {}
    for element in val_string:gmatch('[^,%s]+') do  -- lua pattern magic taken from the Internet
        local parsed_element = parse_parameter(element)
        table.insert(ret_table, parsed_element)
    end
    return ret_table
end

parse_parameter = function(val_string)
    if '"' == val_string:sub(1,1) and '"' == val_string:sub(#val_string,#val_string) then -- double-quote string
        return string.gsub(val_string, '"(.+)"', "%1") -- lua pattern magic: "(.+)" matches all characters between two double-quote marks (no escape chars)
    elseif "'" == val_string:sub(1,1) and "'" == val_string:sub(#val_string,#val_string) then -- single-quote string
        return string.gsub(val_string, "'(.+)'", "%1") -- lua pattern magic: '(.+)' matches all characters between two single-quote marks (no escape chars)
    elseif "{" == val_string:sub(1,1) and "}" == val_string:sub(#val_string,#val_string) then
        return parse_table(string.gsub(val_string, "{(.+)}", "%1"))
    elseif "true" == val_string then
        return true
    elseif "false" == val_string then
        return false
    end
    return tonumber(val_string)
end

local get_parameters_from_file = function(file_name)
    local parameters = {}

    local path = finale.FCString()
    path:SetRunningLuaFolderPath()
    local file_path = path.LuaString .. path_delimiter .. file_name
    if not file_exists(file_path) then
        return parameters
    end

    for line in io.lines(file_path) do
        local comment_at = string.find(line, comment_marker, 1, true) -- true means find raw string rather than lua pattern
        if nil ~= comment_at then
            line = string.sub(line, 1, comment_at-1)
        end
        local delimiter_at = string.find(line, parameter_delimiter, 1, true)
        if nil ~= delimiter_at then
            local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at-1))
            local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at+1))
            parameters[name] = parse_parameter(val_string)
        end
    end
    
    return parameters
end

--[[
% get_parameters(file_name, parameter_list)

Searches for a file with the input filename in the `script_settings` directory and replaces the default values in `parameter_list` with any that are found in the config file.

@ file_name (string) the file name of the config file (which will be prepended with the `script_settings` directory)
@ parameter_list (table) a table with the parameter name as key and the default value as value
]]
function configuration.get_parameters(file_name, parameter_list)
    local file_parameters = get_parameters_from_file(script_settings_dir .. path_delimiter .. file_name)
    if nil ~= file_parameters then
        for param_name, def_val in pairs(parameter_list) do
            local param_val = file_parameters[param_name]
            if nil ~= param_val then
                parameter_list[param_name] = param_val
            end
        end
    end
end




local config = {use_uppercase_staff_names = false, hide_default_whole_rests = false}

configuration.get_parameters("score.config.txt", config)

local score = {}

local CLEF_MAP = {treble = 0, alto = 1, tenor = 2, bass = 3, percussion = 12}
local BRACE_MAP = {
    none = finale.GRBRAC_NONE,
    plain = finale.GRBRAC_PLAIN,
    chorus = finale.GRBRAC_CHORUS,
    piano = finale.GRBRAC_PIANO,
    reverse_chorus = finale.GRBRAC_REVERSECHORUS,
    reverse_piano = finale.GRBRAC_REVERSEPIANO,
    curved_chorus = finale.GRBRAC_CURVEDCHORUS,
    reverse_curved_chorus = finale.GRBRAC_REVERSECURVEDCHORUS,
    desk = finale.GRBRAC_DESK,
    reverse_desk = finale.GRBRAC_REVERSEDESK,
}

--[[
% delete_all_staves()

Deletes all staves in the current document.
]]
function score.delete_all_staves()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        staff:DeleteData()
    end
    staves:SaveAll()
end

--[[
% set_show_staff_time_signature(staff_id, show_time_signature)

Sets whether or not to show the time signature on the staff.

@ staff_id (number) the staff_id for the staff
@ [show_time_signature] (boolean) whether or not to show the time signature, true if not specified

: (number) the staff_id for the staff
]]
function score.set_show_staff_time_signature(staff_id, show_time_signature)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    if show_time_signature == nil then
        staff.ShowScoreTimeSignatures = true
    else
        staff.ShowScoreTimeSignatures = show_time_signature
    end
    staff:Save()
    return staff_id
end

--[[
% set_staff_transposition(staff_id, key, interval, clef)

Sets the transposition for a staff. Used for instruments that are not concert pitch (e.g., Bb Clarinet or F Horn)

@ staff_id (number) the staff_id for the staff
@ key (number) the key signature to set following the circle of fifths (C is 0, F is -1, G is 1)
@ interval (number) the interval number of steps to transpose the notes by
@ [clef] (string) the clef to set, "treble", "alto", "tenor", or "bass"

: (number) the staff_id for the staff
]]
function score.set_staff_transposition(staff_id, key, interval, clef)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff.TransposeAlteration = key or 0
    staff.TransposeInterval = interval or 0
    if clef then
        staff.TransposeClefIndex = CLEF_MAP[clef]
        staff.TransposeUseClef = true
    end
    staff:Save()
    return staff_id
end

--[[
% set_staff_allow_hiding(staff_id, allow_hiding)

Sets whether the staff is allowed to hide when it is empty.

@ staff_id (number) the staff_id for the staff
@ [allow_hiding] (boolean) whether or not to allow the staff to hide, true if not specified

: (number) the staff_id for the staff
]]
function score.set_staff_allow_hiding(staff_id, allow_hiding)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff.AllowHiding = allow_hiding or true
    staff:Save()
    return staff_id
end

--[[
% set_staff_keyless(staff_id, is_keyless)

Sets whether or not the staff is keyless.

@ staff_id (number) the staff_id for the staff
@ [is_keyless] (boolean) whether the staff is keyless, true if not specified

: (number) the staff_id for the staff
]]
function score.set_staff_keyless(staff_id, is_keyless)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff.NoKeySigShowAccidentals = is_keyless or true
    staff:Save()
    return staff_id
end

--[[
% add_space_above_staff(staff_id)

This is the equivalent of "Add Vertical Space" in the Setup Wizard. It adds space above the staff as well as adds the staff to Staff List 1, which allows it to show tempo markings.

@ staff_id (number) the staff_id for the staff

: (number) the staff_id for the staff
]]
function score.add_space_above_staff(staff_id)
    local lists = finale.FCStaffLists()
    lists:SetMode(finale.SLMODE_CATEGORY_SCORE)
    lists:LoadAll()
    local list = lists:GetItemAt(0)
    list:AddStaff(staff_id)
    list:Save()

    -- could be faster
    local system_staves = finale.FCSystemStaves()
    system_staves:LoadAllForItem(1)
    for system_staff in each(system_staves) do
        if system_staff.Staff == staff_id then
            system_staff.Distance = system_staff.Distance + measurement.convert_to_EVPUs(tostring("6s"))
        end
        system_staff:Save()
    end
end

--[[
% set_staff_full_name(staff, full_name, double)

Sets the full name for the staff.

If two instruments are on the same staff, this will also add the related numbers. For instance, if horn one and 2 are on the same staff, this will show Horn 1/2. `double` sets the first number. In this example, `double` should be `1` to show Horn 1/2. If the staff is for horn three and four, `double` should be `3`.

@ staff (FCStaff) the staff
@ full_name (string) the full name to set
@ [double] (number) the number of the first instrument if two instruments share the staff
]]
function score.set_staff_full_name(staff, full_name, double)
    local str = finale.FCString()
    if config.use_uppercase_staff_names then
        str.LuaString = string.upper(full_name):gsub("%^FLAT%(%)", "^flat()")
    else
        str.LuaString = full_name
    end
    if (double ~= nil) then
        str.LuaString = str.LuaString .. "^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. double ..
                            "\r^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. (double + 1)
    end
    staff:SaveNewFullNameString(str)
end

--[[
% set_staff_short_name(staff, short_name, double)

Sets the abbreviated name for the staff.

If two instruments are on the same staff, this will also add the related numbers. For instance, if horn one and 2 are on the same staff, this will show Horn 1/2. `double` sets the first number. In this example, `double` should be `1` to show Horn 1/2. If the staff is for horn three and four, `double` should be `3`.

@ staff (FCStaff) the staff
@ short_name (string) the abbreviated name to set
@ [double] (number) the number of the first instrument if two instruments share the staff
]]
function score.set_staff_short_name(staff, short_name, double)
    local str = finale.FCString()
    if config.use_uppercase_staff_names then
        str.LuaString = string.upper(short_name):gsub("%^FLAT%(%)", "^flat()")
    else
        str.LuaString = short_name
    end
    if (double ~= nil) then
        str.LuaString = str.LuaString .. "^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. double ..
                            "\r^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. (double + 1)
    end
    staff:SaveNewAbbreviatedNameString(str)
end

--[[
% create_staff(full_name, short_name, type, clef, double)

Creates a staff at the end of the score.

@ full_name (string) the abbreviated name
@ short_name (string) the abbreviated name
@ type (string) the `__FCStaffBase` type (e.g., finale.FFUUID_TRUMPETC)
@ clef (string) the clef for the staff (e.g., "treble", "bass", "tenor")
@ [double] (number) the number of the first instrument if two instruments share the staff

: (number) the staff_id for the new staff
]]
function score.create_staff(full_name, short_name, type, clef, double)
    local staff_id = finale.FCStaves.Append()
    if staff_id then
        -- Load the created staff
        local staff = finale.FCStaff()
        staff:Load(staff_id)

        staff.InstrumentUUID = type
        staff:SetDefaultClef(CLEF_MAP[clef])

        if config.hide_default_whole_rests then
            staff:SetDisplayEmptyRests(false)
        end

        score.set_staff_full_name(staff, full_name, double)
        score.set_staff_short_name(staff, short_name, double)

        -- Save and return
        staff:Save()
        return staff:GetItemNo()
    end
    return -1
end

--[[
% create_staff_spaced(full_name, short_name, type, clef, double)

Creates a staff at the end of the score with a space above it. This is equivalent to using `score.create_staff` then `score.add_space_above_staff`.

@ full_name (string) the abbreviated name
@ short_name (string) the abbreviated name
@ type (string) the `__FCStaffBase` type (e.g., finale.FFUUID_TRUMPETC)
@ clef (string) the clef for the staff (e.g., "treble", "bass", "tenor")
@ [double] (number) the number of the first instrument if two instruments share the staff

: (number) the staff_id for the new staff
]]
function score.create_staff_spaced(full_name, short_name, type, clef)
    local staff_id = score.create_staff(full_name, short_name, type, clef)
    score.add_space_above_staff(staff_id)
    return staff_id
end

--[[
% create_staff_percussion(full_name, short_name, type, clef)

Creates a percussion staff at the end of the score.

@ full_name (string) the abbreviated name
@ short_name (string) the abbreviated name

: (number) the staff_id for the new staff
]]
function score.create_staff_percussion(full_name, short_name)
    local staff_id = score.create_staff(full_name, short_name, finale.FFUUID_PERCUSSIONGENERAL, "percussion")
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff:SetNotationStyle(finale.STAFFNOTATION_PERCUSSION)
    staff:SavePercussionLayout(1, 0)
    return staff_id
end

--[[
% create_group(start_staff, end_staff, brace_name, has_barline, level, full_name, short_name)

Creates a percussion staff at the end of the score.

@ start_staff (number) the staff_id for the first staff
@ end_staff (number) the staff_id for the last staff
@ brace_name (string) the name for the brace (e.g., "none", "plain", "piano")
@ has_barline (boolean) whether or not barlines should continue through all staves in the group
@ level (number) the indentation level for the group bracket
@ [full_name] (string) the full name for the group
@ [short_name] (string) the abbreviated name for the group
]]
function score.create_group(start_staff, end_staff, brace_name, has_barline, level, full_name, short_name)
    local sg_cmper = {}
    local sg = finale.FCGroup()
    local staff_groups = finale.FCGroups()
    staff_groups:LoadAll()
    for sg in each(staff_groups) do
        table.insert(sg_cmper, sg:GetItemID())
    end
    table.sort(sg_cmper)
    sg:SetStartStaff(start_staff)
    sg:SetEndStaff(end_staff)
    sg:SetStartMeasure(1)
    sg:SetEndMeasure(32767)
    sg:SetBracketStyle(BRACE_MAP[brace_name])
    if start_staff == end_staff then
        sg:SetBracketSingleStaff(true)
    end
    if (has_barline) then
        sg:SetDrawBarlineMode(finale.GROUPBARLINESTYLE_THROUGH)
    end
    sg:SetBracketHorizontalPos(-12 * level)

    -- names
    if full_name then
        local str = finale.FCString()
        str.LuaString = full_name
        sg:SaveNewFullNameBlock(str)
        sg:SetShowGroupName(true)
        sg:SetFullNameHorizontalOffset(measurement.convert_to_EVPUs("2s"))
    end
    if short_name then
        local str = finale.FCString()
        str.LuaString = short_name
        sg:SaveNewAbbreviatedNameBlock(str)
        sg:SetShowGroupName(true)
    end

    if sg_cmper[1] == nil then
        sg:SaveNew(1)
    else
        local save_num = sg_cmper[1] + 1
        sg:SaveNew(save_num)
    end
end

--[[
% create_group_primary(start_staff, end_staff, full_name, short_name)

Creates a primary group with the "curved_chorus" bracket.

@ start_staff (number) the staff_id for the first staff
@ end_staff (number) the staff_id for the last staff
@ [full_name] (string) the full name for the group
@ [short_name] (string) the abbreviated name for the group
]]
function score.create_group_primary(start_staff, end_staff, full_name, short_name)
    score.create_group(start_staff, end_staff, "curved_chorus", true, 1, full_name, short_name)
end

--[[
% create_group_secondary(start_staff, end_staff, full_name, short_name)

Creates a primary group with the "desk" bracket.

@ start_staff (number) the staff_id for the first staff
@ end_staff (number) the staff_id for the last staff
@ [full_name] (string) the full name for the group
@ [short_name] (string) the abbreviated name for the group
]]
function score.create_group_secondary(start_staff, end_staff, full_name, short_name)
    score.create_group(start_staff, end_staff, "desk", false, 2, full_name, short_name)
end

--[[
% set_global_system_scaling(scaling)

Sets the system scaling for every system in the score.

@ scaling (number) the scaling factor
]]
function score.set_global_system_scaling(scaling)
    local format = finale.FCPageFormatPrefs()
    format:LoadScore()
    format:SetSystemScaling(scaling)
    format:Save()
    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    for system in each(staff_systems) do
        system:SetResize(scaling)
        system:Save()
    end
    finale.FCStaffSystems.UpdateFullLayout()
end

--[[
% set_global_system_scaling(scaling)

Sets the system scaling for a specific system in the score.

@ system_number (number) the system number to set the scaling for
@ scaling (number) the scaling factor
]]
function score.set_single_system_scaling(system_number, scaling)
    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    local system = staff_systems:GetItemAt(system_number)
    if system then
        system:SetResize(scaling)
        system:Save()
    end
end

--[[
% use_large_time_signatures()

Creates large time signatures in the score.
]]
function score.use_large_time_signatures()
    local font_preferences = finale.FCFontPrefs()
    font_preferences:Load(finale.FONTPREF_TIMESIG)
    local font_info = font_preferences:CreateFontInfo()
    font_info:SetSize(40)
    font_info.Name = "EngraverTime"
    font_preferences:SetFontInfo(font_info)
    font_preferences:Save()
    local distance_preferences = finale.FCDistancePrefs()
    distance_preferences:Load(1)
    distance_preferences:SetTimeSigBottomVertical(-290)
    distance_preferences:Save()
end

--[[
% use_large_measure_numbers(distance)

Adds large measure numbers below every measure in the score.

@ distance (string) the distance between the bottom staff and the measure numbers (e.g., "12s" for 12 spaces)
]]
function score.use_large_measure_numbers(distance)
    local systems = finale.FCStaffSystem()
    systems:Load(1)

    for m in loadall(finale.FCMeasureNumberRegions()) do
        m:SetUseScoreInfoForParts(false)
        local font_preferences = finale.FCFontPrefs()
        font_preferences:Load(finale.FONTPREF_MEASURENUMBER)
        local font = font_preferences:CreateFontInfo()
        m:SetMultipleFontInfo(font, false)
        m:SetShowOnTopStaff(false, false)
        m:SetShowOnSystemStart(false, false)
        m:SetShowOnBottomStaff(true, false)
        m:SetExcludeOtherStaves(true, false)
        m:SetShowMultiples(true, false)
        m:SetHideFirstNumber(false, false)
        m:SetMultipleAlignment(finale.MNALIGN_CENTER, false)
        m:SetMultipleJustification(finale.MNJUSTIFY_CENTER, false)

        -- Sets the position in accordance to the system scaling
        local position = -1 * measurement.convert_to_EVPUs(distance)
        m:SetMultipleVerticalPosition(position, false)
        m:Save()
    end
end

--[[
% set_minimum_measure_width(width)

Sets the minimum measure width.

@ width (string) the minimum measure width (e.g., "24s" for 24 spaces)
]]
function score.set_minimum_measure_width(width)
    local music_spacing_preferences = finale.FCMusicSpacingPrefs()
    music_spacing_preferences:Load(1)
    music_spacing_preferences:SetMinMeasureWidth(measurement.convert_to_EVPUs(width))
    music_spacing_preferences:Save()
end



--  Author: Robert Patterson
--  Date: March 5, 2021

--[[
$module Configuration

This library implements a UTF-8 text file scheme for configuration as follows:

- Comments start with `--`
- Leading, trailing, and extra whitespace is ignored
- Each parameter is named and delimited as follows:
`<parameter-name> = <parameter-value>`

Parameter values may be:

- Strings delimited with either single- or double-quotes
- Tables delimited with `{}` that may contain strings, booleans, or numbers
- Booleans (`true` or `false`)
- Numbers

Currently the following are not supported:

- Tables embedded within tables
- Tables containing strings that contain commas

A sample configuration file might be:

```lua
-- Configuration File for "Hairpin and Dynamic Adjustments" script
--
left_dynamic_cushion 		= 12		--evpus
right_dynamic_cushion		= -6		--evpus
```

Configuration files must be placed in a subfolder called `script_settings` within
the folder of the calling script. Each script that has a configuration file
defines its own configuration file name.
]]

local configuration = {}

local script_settings_dir = "script_settings" -- the parent of this directory is the running lua path
local comment_marker = "--"
local parameter_delimiter = "="
local path_delimiter = "/"

local file_exists = function(file_path)
    local f = io.open(file_path,"r")
    if nil ~= f then
        io.close(f)
        return true
    end
    return false
end

local strip_leading_trailing_whitespace = function (str)
    return str:match("^%s*(.-)%s*$") -- lua pattern magic taken from the Internet
end

local parse_parameter -- forward function declaration

local parse_table = function(val_string)
    local ret_table = {}
    for element in val_string:gmatch('[^,%s]+') do  -- lua pattern magic taken from the Internet
        local parsed_element = parse_parameter(element)
        table.insert(ret_table, parsed_element)
    end
    return ret_table
end

parse_parameter = function(val_string)
    if '"' == val_string:sub(1,1) and '"' == val_string:sub(#val_string,#val_string) then -- double-quote string
        return string.gsub(val_string, '"(.+)"', "%1") -- lua pattern magic: "(.+)" matches all characters between two double-quote marks (no escape chars)
    elseif "'" == val_string:sub(1,1) and "'" == val_string:sub(#val_string,#val_string) then -- single-quote string
        return string.gsub(val_string, "'(.+)'", "%1") -- lua pattern magic: '(.+)' matches all characters between two single-quote marks (no escape chars)
    elseif "{" == val_string:sub(1,1) and "}" == val_string:sub(#val_string,#val_string) then
        return parse_table(string.gsub(val_string, "{(.+)}", "%1"))
    elseif "true" == val_string then
        return true
    elseif "false" == val_string then
        return false
    end
    return tonumber(val_string)
end

local get_parameters_from_file = function(file_name)
    local parameters = {}

    local path = finale.FCString()
    path:SetRunningLuaFolderPath()
    local file_path = path.LuaString .. path_delimiter .. file_name
    if not file_exists(file_path) then
        return parameters
    end

    for line in io.lines(file_path) do
        local comment_at = string.find(line, comment_marker, 1, true) -- true means find raw string rather than lua pattern
        if nil ~= comment_at then
            line = string.sub(line, 1, comment_at-1)
        end
        local delimiter_at = string.find(line, parameter_delimiter, 1, true)
        if nil ~= delimiter_at then
            local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at-1))
            local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at+1))
            parameters[name] = parse_parameter(val_string)
        end
    end
    
    return parameters
end

--[[
% get_parameters(file_name, parameter_list)

Searches for a file with the input filename in the `script_settings` directory and replaces the default values in `parameter_list` with any that are found in the config file.

@ file_name (string) the file name of the config file (which will be prepended with the `script_settings` directory)
@ parameter_list (table) a table with the parameter name as key and the default value as value
]]
function configuration.get_parameters(file_name, parameter_list)
    local file_parameters = get_parameters_from_file(script_settings_dir .. path_delimiter .. file_name)
    if nil ~= file_parameters then
        for param_name, def_val in pairs(parameter_list) do
            local param_val = file_parameters[param_name]
            if nil ~= param_val then
                parameter_list[param_name] = param_val
            end
        end
    end
end




local config = {use_large_time_signatures = false, use_large_measure_numbers = false}

configuration.get_parameters("score_create_trombone_choir_score.config.txt", config)

local function score_create_trombone_choir_score()
    score.delete_all_staves()
    local trombone_staves = {}
    for i = 1, 6, 1 do
        trombone_staves[i] = score.set_show_staff_time_signature(
                                 score.create_staff(
                                     "Trombone " .. i, "Tbn. " .. i, finale.FFUUID_TROMBONE,
                                     (i < 3) and "tenor" or "bass"),
                                 (not config.use_large_time_signatures) or i == 1 or i == 5)
    end

    local bass_trombone_staves = {}
    for i = 1, 2, 1 do
        bass_trombone_staves[i] = score.set_show_staff_time_signature(
                                      score.create_staff(
                                          "Bass Trombone " .. i, "B. Tbn. " .. i, finale.FFUUID_BASSTROMBONE, "bass"),
                                      not config.use_large_time_signatures)
    end

    score.create_group_primary(trombone_staves[1], bass_trombone_staves[#bass_trombone_staves])
    score.create_group_secondary(trombone_staves[1], trombone_staves[#trombone_staves])
    score.create_group_secondary(bass_trombone_staves[1], bass_trombone_staves[#bass_trombone_staves])

    score.set_global_system_scaling(63)
    score.set_single_system_scaling(0, 56)
    score.set_single_system_scaling(1, 56)

    if config.use_large_time_signatures then
        score.use_large_time_signatures()
    end
    if config.use_large_measure_numbers then
        score.use_large_measure_numbers("14s")
    end
    score.set_minimum_measure_width("25s")
end

score_create_trombone_choir_score()

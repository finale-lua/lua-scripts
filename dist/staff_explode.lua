function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.40"
    finaleplugin.Date = "2022/03/13"
    finaleplugin.Notes = [[
        This script explodes a set of chords from one staff onto single lines on subsequent staves. It warns if pre-existing music in the destination will be erased. It duplicates all markings from the original, and sets the copies in the current clef for each destination.

        This script allows for the following configuration:

        ```
        fix_note_spacing = true -- to respace music automatically when the script finishes
        ```
    ]]
    return "Staff Explode", "Staff Explode", "Staff Explode onto consecutive single staves"
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
]] --
local configuration = {}

local script_settings_dir = "script_settings" -- the parent of this directory is the running lua path
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

local strip_leading_trailing_whitespace = function(str)
    return str:match("^%s*(.-)%s*$") -- lua pattern magic taken from the Internet
end

local parse_parameter -- forward function declaration

local parse_table = function(val_string)
    local ret_table = {}
    for element in val_string:gmatch("[^,%s]+") do -- lua pattern magic taken from the Internet
        local parsed_element = parse_parameter(element)
        table.insert(ret_table, parsed_element)
    end
    return ret_table
end

parse_parameter = function(val_string)
    if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then -- double-quote string
        return string.gsub(val_string, "\"(.+)\"", "%1") -- lua pattern magic: "(.+)" matches all characters between two double-quote marks (no escape chars)
    elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then -- single-quote string
        return string.gsub(val_string, "'(.+)'", "%1") -- lua pattern magic: '(.+)' matches all characters between two single-quote marks (no escape chars)
    elseif "{" == val_string:sub(1, 1) and "}" == val_string:sub(#val_string, #val_string) then
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
            line = string.sub(line, 1, comment_at - 1)
        end
        local delimiter_at = string.find(line, parameter_delimiter, 1, true)
        if nil ~= delimiter_at then
            local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at - 1))
            local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at + 1))
            parameters[name] = parse_parameter(val_string)
        end
    end

    return parameters
end

--[[
% get_parameters

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



--[[
$module Clef

A library of general clef utility functions.
]] --
local clef = {}

--[[
% get_cell_clef

Gets the clef for any cell.

@ measure (number) The measure number for the cell
@ staff_number (number) The staff number for the cell
: (number) The clef for the cell
]]
function clef.get_cell_clef(measure, staff_number)
    local cell_clef = -1
    local cell = finale.FCCell(measure, staff_number)
    local cell_frame_hold = finale.FCCellFrameHold()

    cell_frame_hold:ConnectCell(cell)
    if cell_frame_hold:Load() then
        if cell_frame_hold.IsClefList then
            cell_clef = cell_frame_hold:CreateFirstCellClefChange().ClefIndex
        else
            cell_clef = cell_frame_hold.ClefIndex
        end
    end
    return cell_clef
end

--[[
% get_default_clef

Gets the default clef for any staff for a specific region.

@ first_measure (number) The first measure of the region
@ last_measure (number) The last measure of the region
@ staff_number (number) The staff number for the cell
: (number) The default clef for the staff
]]
function clef.get_default_clef(first_measure, last_measure, staff_number)
    local staff = finale.FCStaff()
    local cell_clef = clef.get_cell_clef(first_measure - 1, staff_number)
    if cell_clef < 0 then -- failed, so check clef AFTER insertion
        cell_clef = clef.get_cell_clef(last_measure + 1, staff_number)
        if cell_clef < 0 then -- resort to destination staff default clef
            cell_clef = staff:Load(staff_number) and staff.DefaultClef or 0 -- default treble
        end
    end
    return cell_clef
end

--[[
% can_change_clef

Determine if the current version of the plugin can change clefs.

: (boolean) Whether or not the plugin can change clefs
]]
function clef.can_change_clef()
    -- RGPLua 0.60 or later needed for clef changing
    return finenv.IsRGPLua or finenv.StringVersion >= "0.60"
end

--[[
% restore_default_clef

Restores the default clef for any staff for a specific region.

@ first_measure (number) The first measure of the region
@ last_measure (number) The last measure of the region
@ staff_number (number) The staff number for the cell
]]
function clef.restore_default_clef(first_measure, last_measure, staff_number)
    if not clef.can_change_clef() then
        return
    end

    local default_clef = clef.get_default_clef(first_measure, last_measure, staff_number)

    for measure = first_measure, last_measure do
        local cell = finale.FCCell(measure, staff_number)
        local cell_frame_hold = finale.FCCellFrameHold()
        cell_frame_hold:ConnectCell(cell)
        if cell_frame_hold:Load() then
            cell_frame_hold:MakeCellSingleClef(nil) -- RGPLua v0.60
            cell_frame_hold:SetClefIndex(default_clef)
            cell_frame_hold:Save()
        end
    end
end




local config = {fix_note_spacing = true}

configuration.get_parameters("staff_explode.config.txt", config)

function show_error(error_code)
    local errors = {
        need_more_staves = "There are not enough empty\nstaves to explode onto",
        only_one_staff = "Please select only one staff!",
        same_note_count = "Every chord must contain\nthe same number of pitches",
        empty_region = "Please select a region\nwith some notes in it!",
        require_chords = "Chords must contain\nat least two pitches",
    }
    finenv.UI():AlertNeutral("script: " .. plugindef(), errors[error_code])
    return -1
end

function should_overwrite_existing_music()
    local alert = finenv.UI():AlertOkCancel("script: " .. plugindef(), "Overwrite existing music?")
    local should_overwrite = alert == 0
    return should_overwrite
end

function get_note_count(source_staff_region)
    local note_count = 0
    local unique_counts = 0
    local seen_counts = {}
    for entry in eachentry(source_staff_region) do
        if entry.Count > 0 then
            if not seen_counts[entry.Count] then
                seen_counts[entry.Count] = true
                unique_counts = unique_counts + 1
            end
            if note_count < entry.Count then
                note_count = entry.Count
            end
        end
    end
    if unique_counts > 1 then
        return show_error("same_note_count")
    end
    if note_count == 0 then
        return show_error("empty_region")
    end
    if note_count < 2 then
        return show_error("require_chords")
    end
    return note_count
end

function ensure_score_has_enough_staves(staff, note_count)
    local staves = finale.FCStaves()
    staves:LoadAll()
    if note_count > staves.Count + 1 - staff then
        show_error("need_more_staves")
        return
    end
end

function staff_explode()
    local source_staff_region = finenv.Region()
    if source_staff_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    end
    local staff = source_staff_region.StartStaff
    local start_measure = source_staff_region.StartMeasure
    local end_measure = source_staff_region.EndMeasure
    local regions = {}
    regions[1] = source_staff_region

    local note_count = get_note_count(source_staff_region)
    if note_count <= 0 then
        return
    end

    ensure_score_has_enough_staves(staff, note_count)

    -- copy top staff to note_count lower staves (one-based index)
    local destination_has_content = false
    local staves = -1
    for i = 2, note_count do
        regions[i] = finale.FCMusicRegion()
        regions[i]:SetRegion(regions[1])
        regions[i]:CopyMusic()
        staves = staff + i - 1 -- "real" staff number, indexed[1]
        regions[i].StartStaff = staves
        regions[i].EndStaff = staves
        if not destination_has_content then
            for entry in eachentry(regions[i]) do
                if entry.Count > 0 then
                    destination_has_content = true
                    break
                end
            end
        end
    end

    if not destination_has_content or (destination_has_content and should_overwrite_existing_music()) then
        -- run through all staves deleting requisite notes in each entry
        for ss = 1, note_count do
            if ss > 1 then
                regions[ss]:PasteMusic()
                local real_staff_number = staff + ss - 1
                clef.restore_default_clef(start_measure, end_measure, real_staff_number)
            end

            local from_top = ss - 1 -- delete how many notes from top?
            local from_bottom = note_count - ss -- how many from bottom?
            -- run the ENTRIES loop for current selection on all staff copies
            for entry in eachentrysaved(regions[ss]) do
                if from_top > 0 then -- delete TOP notes
                    for _ = 1, from_top do
                        entry:DeleteNote(entry:CalcHighestNote(nil))
                    end
                end
                if from_bottom > 0 then -- delete BOTTOM notes
                    for i = 1, from_bottom do
                        entry:DeleteNote(entry:CalcLowestNote(nil))
                    end
                end
            end
        end

        if config.fix_note_spacing then
            regions[1].EndStaff = staff + note_count - 1 -- full staff range
            regions[1]:SetFullMeasureStack()
            regions[1]:SetInDocument()
            finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
            regions[1].StartStaff = staff
            regions[1].StartStaff = staff
            regions[1].EndStaff = staff
            regions[1]:SetInDocument()
        end
    end

    -- ALL DONE -- empty out the copied clip files
    for i = 2, note_count do
        regions[i]:ReleaseMusic()
    end
end

staff_explode()

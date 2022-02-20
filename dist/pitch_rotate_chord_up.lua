function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "March 30, 2021"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Rotate Chord Up", "Rotate Chord Up",
           "Rotates the chord upwards, taking the bottom note and moving it above the rest of the chord"
end

--[[
$module Transposition

A collection of helpful JW Lua transposition scripts.

This library allows configuration of custom key signatures by means
of a configuration file called "custom_key_sig.config.txt" in the
"script_settings" subdirectory. However, RGP Lua (starting with version 0.58)
can read the correct custom key signature information directly from
Finale. Therefore, when you run this script with RGP Lua 0.58+, the configuration file
is ignored.
]] -- 
-- Structure
-- 1. Helper functions
-- 2. Diatonic Transposition
-- 3. Enharmonic Transposition
-- 3. Chromatic Transposition
-- 
local transposition = {}

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




local standard_key_number_of_steps = 12
local standard_key_major_diatonic_steps = {0, 2, 4, 5, 7, 9, 11}
local standard_key_minor_diatonic_steps = {0, 2, 3, 5, 7, 8, 10}

local max_allowed_abs_alteration = 7 -- Finale cannot represent an alteration outside +/- 7

-- first number is plus_fifths
-- second number is minus_octaves
local diatonic_interval_adjustments = {{0, 0}, {2, -1}, {4, -2}, {-1, 1}, {1, 0}, {3, -1}, {5, -2}, {0, 1}}

local custom_key_sig_config = {
    number_of_steps = standard_key_number_of_steps,
    diatonic_steps = standard_key_major_diatonic_steps,
}

configuration.get_parameters("custom_key_sig.config.txt", custom_key_sig_config)

-- 
-- HELPER functions
-- 

local sign = function(n)
    if n < 0 then
        return -1
    end
    return 1
end

-- this is necessary because the % operator in lua appears always to return a positive value,
-- unlike the % operator in c++
local signed_modulus = function(n, d)
    return sign(n) * (math.abs(n) % d)
end

local get_key = function(note)
    local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
    return cell:GetKeySignature()
end

-- These local functions that take FCKeySignature (key) as their first argument should
-- perhaps move to a key_signature library someday.

-- return number of steps, diatonic steps map, and number of steps in fifth
local get_key_info = function(key)
    local number_of_steps = standard_key_number_of_steps
    local diatonic_steps = standard_key_major_diatonic_steps
    if finenv.IsRGPLua and key.CalcTotalChromaticSteps then -- if this version of RGP Lua supports custom key sigs
        number_of_steps = key:CalcTotalChromaticSteps()
        diatonic_steps = key:CalcDiatonicStepsMap()
    else
        if not key:IsPredefined() then
            number_of_steps = custom_key_sig_config.number_of_steps
            diatonic_steps = custom_key_sig_config.diatonic_steps
        elseif key:IsMinor() then
            diatonic_steps = standard_key_minor_diatonic_steps
        end
    end
    -- 0.5849625 is log(3/2)/log(2), which is how to calculate the 5th per Ere Lievonen.
    -- For basically any practical key sig this calculation comes out to the 5th scale degree,
    -- which is 7 chromatic steps for standard keys
    local fifth_steps = math.floor((number_of_steps * 0.5849625) + 0.5)
    return number_of_steps, diatonic_steps, fifth_steps
end

local calc_scale_degree = function(interval, number_of_diatonic_steps_in_key)
    local interval_normalized = signed_modulus(interval, number_of_diatonic_steps_in_key)
    if interval_normalized < 0 then
        interval_normalized = interval_normalized + number_of_diatonic_steps_in_key
    end
    return interval_normalized
end

local calc_steps_between_scale_degrees = function(key, first_disp, second_disp)
    local number_of_steps_in_key, diatonic_steps = get_key_info(key)
    local first_scale_degree = calc_scale_degree(first_disp, #diatonic_steps)
    local second_scale_degree = calc_scale_degree(second_disp, #diatonic_steps)
    local number_of_steps = sign(second_disp - first_disp) *
                                (diatonic_steps[second_scale_degree + 1] - diatonic_steps[first_scale_degree + 1])
    if number_of_steps < 0 then
        number_of_steps = number_of_steps + number_of_steps_in_key
    end
    return number_of_steps
end

local calc_steps_in_alteration = function(key, interval, alteration)
    local number_of_steps_in_key, _, fifth_steps = get_key_info(key)
    local plus_fifths = sign(interval) * alteration * 7 -- number of fifths to add for alteration
    local minus_octaves = sign(interval) * alteration * -4 -- number of octaves to subtract for alteration
    local new_alteration = sign(interval) * ((plus_fifths * fifth_steps) + (minus_octaves * number_of_steps_in_key)) -- new alteration for chromatic interval
    return new_alteration
end

local calc_steps_in_normalized_interval = function(key, interval_normalized)
    local number_of_steps_in_key, _, fifth_steps = get_key_info(key)
    local plus_fifths = diatonic_interval_adjustments[math.abs(interval_normalized) + 1][1] -- number of fifths to add for interval
    local minus_octaves = diatonic_interval_adjustments[math.abs(interval_normalized) + 1][2] -- number of octaves to subtract for alteration
    local number_of_steps_in_interval = sign(interval_normalized) *
                                            ((plus_fifths * fifth_steps) + (minus_octaves * number_of_steps_in_key))
    return number_of_steps_in_interval
end

local simplify_spelling = function(note, min_abs_alteration)
    while math.abs(note.RaiseLower) > min_abs_alteration do
        local curr_sign = sign(note.RaiseLower)
        local curr_abs_disp = math.abs(note.RaiseLower)
        local direction = curr_sign
        local success = transposition.enharmonic_transpose(note, direction, true) -- true: ignore errors (success is always true)
        if not success then
            return false
        end
        if math.abs(note.RaiseLower) >= curr_abs_disp then
            return transposition.enharmonic_transpose(note, -1 * direction)
        end
        if curr_sign ~= sign(note.RaiseLower) then
            break
        end
    end
    return true
end

-- 
-- DIATONIC transposition (affect only Displacement)
-- 

--[[
% diatonic_transpose(note, interval)

Transpose the note diatonically by the given interval displacement.

@ note (FCNote) input and modified output
@ interval (number) 0 = unison, 1 = up a diatonic second, -2 = down a diatonic third, etc.
]]
function transposition.diatonic_transpose(note, interval)
    note.Displacement = note.Displacement + interval
end

--[[
% change_octave(note, number_of_octaves)

Transpose the note by the given number of octaves.

@ note (FCNote) input and modified output
@ number_of_octaves (number) 0 = no change, 1 = up an octave, -2 = down 2 octaves, etc.
]]
function transposition.change_octave(note, number_of_octaves)
    transposition.diatonic_transpose(note, 7 * number_of_octaves)
end

--
-- ENHARMONIC transposition
--

--[[
% enharmonic_transpose(note, direction, ignore_error)

Transpose the note enharmonically in the given direction. In some microtone systems this yields a different result than transposing by a diminished 2nd.
Failure occurs if the note's `RaiseLower` value exceeds an absolute value of 7. This is a hard-coded limit in Finale.

@ note (FCNote) input and modified output
@ direction (number) positive = up, negative = down (normally 1 or -1, but any positive or negative numbers work)
@ [ignore_error] (boolean) default false. If true, always return success. External callers should omit this parameter.
: (boolean) success or failure
]]
function transposition.enharmonic_transpose(note, direction, ignore_error)
    ignore_error = ignore_error or false
    local curr_disp = note.Displacement
    local curr_alt = note.RaiseLower
    local key = get_key(note)
    local key_step_enharmonic = calc_steps_between_scale_degrees(
                                    key, note.Displacement, note.Displacement + sign(direction))
    transposition.diatonic_transpose(note, sign(direction))
    note.RaiseLower = note.RaiseLower - sign(direction) * key_step_enharmonic
    if ignore_error then
        return true
    end
    if math.abs(note.RaiseLower) > max_allowed_abs_alteration then
        note.Displacement = curr_disp
        note.RaiseLower = curr_alt
        return false
    end
    return true
end

-- 
-- CHROMATIC transposition (affect Displacement and RaiseLower)
-- 

--[[
% chromatic_transpose(note, interval, alteration, simplify)

Transposes a note chromatically by the input chromatic interval. Supports custom key signatures
and microtone systems by means of a `custom_key_sig.config.txt` file. In Finale, chromatic intervals
are defined by a diatonic displacement (0 = unison, 1 = second, 2 = third, etc.) and a chromatic alteration.
Major and perfect intervals have a chromatic alteration of 0. So for example, `{2, -1}` is up a minor third, `{3, 0}`
is up a perfect fourth, `{5, 1}` is up an augmented sixth, etc. Reversing the signs of both values in the pair
allows for downwards transposition.

@ note (FCNote) the note to transpose
@ interval (number) the diatonic displacement (negative for transposing down)
@ alteration (number) the chromatic alteration that defines the chromatic interval (reverse sign for transposing down)
@ [simplify] (boolean) if present and true causes the spelling of the transposed note to be simplified
: (boolean) success or failure (see `enharmonic_transpose` for what causes failure)
--]]
function transposition.chromatic_transpose(note, interval, alteration, simplify)
    simplify = simplify or false
    local curr_disp = note.Displacement
    local curr_alt = note.RaiseLower

    local key = get_key(note)
    local number_of_steps, diatonic_steps, fifth_steps = get_key_info(key)
    local interval_normalized = signed_modulus(interval, #diatonic_steps)
    local steps_in_alteration = calc_steps_in_alteration(key, interval, alteration)
    local steps_in_interval = calc_steps_in_normalized_interval(key, interval_normalized)
    local steps_in_diatonic_interval = calc_steps_between_scale_degrees(
                                           key, note.Displacement, note.Displacement + interval_normalized)
    local effective_alteration = steps_in_alteration + steps_in_interval - sign(interval) * steps_in_diatonic_interval
    transposition.diatonic_transpose(note, interval)
    note.RaiseLower = note.RaiseLower + effective_alteration

    local min_abs_alteration = max_allowed_abs_alteration
    if simplify then
        min_abs_alteration = 0
    end
    local success = simplify_spelling(note, min_abs_alteration)
    if not success then -- if Finale can't represent the transposition, revert it to original value
        note.Displacement = curr_disp
        note.RaiseLower = curr_alt
    end
    return success
end

--[[
% stepwise_transpose(note, number_of_steps)

Transposes the note by the input number of steps and simplifies the spelling.
For predefined key signatures, each step is a half-step.
For microtone systems defined with custom key signatures and matching options in the `custom_key_sig.config.txt` file,
each step is the smallest division of the octave defined by the custom key signature.

@ note (FCNote) input and modified output
@ number_of_steps (number) positive = up, negative = down
: (boolean) success or failure (see `enharmonic_transpose` for what causes failure)
]]
function transposition.stepwise_transpose(note, number_of_steps)
    local curr_disp = note.Displacement
    local curr_alt = note.RaiseLower
    note.RaiseLower = note.RaiseLower + number_of_steps
    local success = simplify_spelling(note, 0)
    if not success then -- if Finale can't represent the transposition, revert it to original value
        note.Displacement = curr_disp
        note.RaiseLower = curr_alt
    end
    return success
end

--[[
% chromatic_major_third_down(note)

Transpose the note down by a major third.

@ note (FCNote) input and modified output
]]
function transposition.chromatic_major_third_down(note)
    transposition.chromatic_transpose(note, -2, -0)
end

--[[
% chromatic_perfect_fourth_up(note)

Transpose the note up by a perfect fourth.

@ note (FCNote) input and modified output
]]
function transposition.chromatic_perfect_fourth_up(note)
    transposition.chromatic_transpose(note, 3, 0)
end

--[[
% chromatic_perfect_fifth_down(note)

Transpose the note down by a perfect fifth.

@ note (FCNote) input and modified output
]]
function transposition.chromatic_perfect_fifth_down(note)
    transposition.chromatic_transpose(note, -4, -0)
end



--[[
$module Note Entry
]]
local note_entry = {}

--[[
% get_music_region(entry)

Returns an intance of `FCMusicRegion` that corresponds to the metric location of the input note entry.

@ entry (FCNoteEntry)
: (FCMusicRegion)
]]
function note_entry.get_music_region(entry)
    local exp_region = finale.FCMusicRegion()
    exp_region:SetCurrentSelection() -- called to match the selected IU list (e.g., if using Staff Sets)
    exp_region.StartStaff = entry.Staff
    exp_region.EndStaff = entry.Staff
    exp_region.StartMeasure = entry.Measure
    exp_region.EndMeasure = entry.Measure
    exp_region.StartMeasurePos = entry.MeasurePos
    exp_region.EndMeasurePos = entry.MeasurePos
    return exp_region
end

--entry_metrics can be omitted, in which case they are constructed and released here
--return entry_metrics, loaded_here
local use_or_get_passed_in_entry_metrics = function(entry, entry_metrics)
    if nil ~= entry_metrics then
        return entry_metrics, false
    end
    entry_metrics = finale.FCEntryMetrics()
    if entry_metrics:Load(entry) then
        return entry_metrics, true
    end
    return nil, false
end

--[[
% get_evpu_notehead_height(entry)

Returns the calculated height of the notehead rectangle.

@ entry (FCNoteEntry)

: (number) the EVPU height
]]
function note_entry.get_evpu_notehead_height(entry)
    local highest_note = entry:CalcHighestNote(nil)
    local lowest_note = entry:CalcLowestNote(nil)
    local evpu_height = (2 + highest_note:CalcStaffPosition() - lowest_note:CalcStaffPosition()) * 12 -- 12 evpu per staff step; add 2 staff steps to accommodate for notehead height at top and bottom
    return evpu_height
end

--[[
% get_top_note_position(entry, entry_metrics)

Returns the vertical page coordinate of the top of the notehead rectangle, not including the stem.

@ entry (FCNoteEntry)
@ [entry_metrics] (FCEntryMetrics) entry metrics may be supplied by the caller if they are already available
: (number)
]]
function note_entry.get_top_note_position(entry, entry_metrics)
    local retval = -math.huge
    local loaded_here = false
    entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
    if nil == entry_metrics then
        return retval
    end
    if not entry:CalcStemUp() then
        retval = entry_metrics.TopPosition
    else
        local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
        if nil ~= cell_metrics then
            local evpu_height = note_entry.get_evpu_notehead_height(entry)
            local scaled_height = math.floor(((cell_metrics.StaffScaling*evpu_height)/10000) + 0.5)
            retval = entry_metrics.BottomPosition + scaled_height
            cell_metrics:FreeMetrics()
        end
    end
    if loaded_here then
        entry_metrics:FreeMetrics()
    end
    return retval
end

--[[
% get_bottom_note_position(entry, entry_metrics)

Returns the vertical page coordinate of the bottom of the notehead rectangle, not including the stem.

@ entry (FCNoteEntry)
@ [entry_metrics] (FCEntryMetrics) entry metrics may be supplied by the caller if they are already available
: (number)
]]
function note_entry.get_bottom_note_position(entry, entry_metrics)
    local retval = math.huge
    local loaded_here = false
    entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
    if nil == entry_metrics then
        return retval
    end
    if entry:CalcStemUp() then
        retval = entry_metrics.BottomPosition
    else
        local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
        if nil ~= cell_metrics then
            local evpu_height = note_entry.get_evpu_notehead_height(entry)
            local scaled_height = math.floor(((cell_metrics.StaffScaling*evpu_height)/10000) + 0.5)
            retval = entry_metrics.TopPosition - scaled_height
            cell_metrics:FreeMetrics()
        end
    end
    if loaded_here then
        entry_metrics:FreeMetrics()
    end
    return retval
end

--[[
% calc_widths(entry)

Get the widest left-side notehead width and widest right-side notehead width.

@ entry (FCNoteEntry)
: (number, number) widest left-side notehead width and widest right-side notehead width
]]
function note_entry.calc_widths(entry)
    local left_width = 0
    local right_width = 0
    for note in each(entry) do
        local note_width = note:CalcNoteheadWidth()
        if note_width > 0 then
            if note:CalcRightsidePlacement() then
                if note_width > right_width then
                    right_width = note_width
                end
            else
                if note_width > left_width then
                    left_width = note_width
                end
            end
        end
    end
    return left_width, right_width
end

-- These functions return the offset for an expression handle.
-- Expression handles are vertical when they are left-aligned
-- with the primary notehead rectangle.

--[[
% calc_left_of_all_noteheads(entry)

Calculates the handle offset for an expression with "Left of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_left_of_all_noteheads(entry)
    if entry:CalcStemUp() then
        return 0
    end
    local left, right = note_entry.calc_widths(entry)
    return -left
end

--[[
% calc_left_of_primary_notehead(entry)

Calculates the handle offset for an expression with "Left of Primary Notehead" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_left_of_primary_notehead(entry)
    return 0
end

--[[
% calc_center_of_all_noteheads(entry)

Calculates the handle offset for an expression with "Center of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_center_of_all_noteheads(entry)
    local left, right = note_entry.calc_widths(entry)
    local width_centered = (left + right) / 2
    if not entry:CalcStemUp() then
        width_centered = width_centered - left
    end
    return width_centered
end

--[[
% calc_center_of_primary_notehead(entry)

Calculates the handle offset for an expression with "Center of Primary Notehead" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_center_of_primary_notehead(entry)
    local left, right = note_entry.calc_widths(entry)
    if entry:CalcStemUp() then
        return left / 2
    end
    return right / 2
end

--[[
% calc_stem_offset(entry)

Calculates the offset of the stem from the left edge of the notehead rectangle. Eventually the PDK Framework may be able to provide this instead.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset of stem from the left edge of the notehead rectangle.
]]
function note_entry.calc_stem_offset(entry)
    if not entry:CalcStemUp() then
        return 0
    end
    local left, right = note_entry.calc_widths(entry)
    return left
end

--[[
% calc_right_of_all_noteheads(entry)

Calculates the handle offset for an expression with "Right of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_right_of_all_noteheads(entry)
    local left, right = note_entry.calc_widths(entry)
    if entry:CalcStemUp() then
        return left + right
    end
    return right
end

--[[
% calc_note_at_index(entry, note_index)

This function assumes `for note in each(note_entry)` always iterates in the same direction.
(Knowing how the Finale PDK works, it probably iterates from bottom to top note.)
Currently the PDK Framework does not seem to offer a better option.

@ entry (FCNoteEntry)
@ note_index (number) the zero-based index
]]
function note_entry.calc_note_at_index(entry, note_index)
    local x = 0
    for note in each(entry) do
        if x == note_index then
            return note
        end
        x = x + 1
    end
    return nil
end

--[[
% stem_sign(entry)

This is useful for many x,y positioning fields in Finale that mirror +/-
based on stem direction.

@ entry (FCNoteEntry)
: (number) 1 if upstem, -1 otherwise
]]
function note_entry.stem_sign(entry)
    if entry:CalcStemUp() then
        return 1
    end
    return -1
end

--[[
% duplicate_note(note)

@ note (FCNote)
: (FCNote | nil) reference to added FCNote or `nil` if not success
]]
function note_entry.duplicate_note(note)
    local new_note = note.Entry:AddNewNote()
    if nil ~= new_note then
        new_note.Displacement = note.Displacement
        new_note.RaiseLower = note.RaiseLower
        new_note.Tie = note.Tie
        new_note.TieBackwards = note.TieBackwards
    end
    return new_note
end

--[[
% delete_note(note)

Removes the specified FCNote from its associated FCNoteEntry.

@ note (FCNote)
: (boolean) true if success
]]
function note_entry.delete_note(note)
    local entry = note.Entry
    if nil == entry then
        return false
    end

    -- attempt to delete all associated entry-detail mods, but ignore any failures
    finale.FCAccidentalMod():EraseAt(note)
    finale.FCCrossStaffMod():EraseAt(note)
    finale.FCDotMod():EraseAt(note)
    finale.FCNoteheadMod():EraseAt(note)
    finale.FCPercussionNoteMod():EraseAt(note)
    finale.FCTablatureNoteMod():EraseAt(note)
    --finale.FCTieMod():EraseAt(note)  -- FCTieMod is not currently lua supported, but leave this here in case it ever is

    return entry:DeleteNote(note)
end

--[[
% calc_spans_number_of_octaves(entry)

Calculates the numer of octaves spanned by a chord (considering only staff positions, not accidentals).

@ entry (FCNoteEntry) the entry to calculate from
: (number) of octaves spanned
]]
function note_entry.calc_spans_number_of_octaves(entry)
    local top_note = entry:CalcHighestNote(nil)
    local bottom_note = entry:CalcLowestNote(nil)
    local displacement_diff = top_note.Displacement - bottom_note.Displacement
    local num_octaves = math.ceil(displacement_diff / 7)
    return num_octaves
end

--[[
% add_augmentation_dot(entry)

Adds an augentation dot to the entry. This works even if the entry already has one or more augmentation dots.

@ entry (FCNoteEntry) the entry to which to add the augmentation dot
]]
function note_entry.add_augmentation_dot(entry)
    -- entry.Duration = entry.Duration | (entry.Duration >> 1) -- For Lua 5.3 and higher
    entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
end

--[[
% get_next_same_v(entry)

Returns the next entry in the same V1 or V2 as the input entry.
If the input entry is V2, only the current V2 launch is searched.
If the input entry is V1, only the current measure and layer is searched.

@ entry (FCNoteEntry) the entry to process
: (FCNoteEntry) the next entry or `nil` in none
]]
function note_entry.get_next_same_v(entry)
    local next_entry = entry:Next()
    if entry.Voice2 then
        if (nil ~= next_entry) and next_entry.Voice2 then
            return next_entry
        end
        return nil
    end
    if entry.Voice2Launch then
        while (nil ~= next_entry) and next_entry.Voice2 do
            next_entry = next_entry:Next()
        end
    end
    return next_entry
end




function pitch_rotate_chord_up()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local num_octaves = note_entry.calc_spans_number_of_octaves(entry)
            local top_note = entry:CalcHighestNote(nil)
            local bottom_note = entry:CalcLowestNote(nil)
            transposition.change_octave(bottom_note, math.max(1,num_octaves))
            --octave-spanning chords (such as common 4-note piano chords) need some special attention
            if top_note:IsIdenticalPitch(bottom_note) and (entry.Count > 2) then
                local new_bottom_note = entry:CalcLowestNote(nil)
                bottom_note.Displacement = new_bottom_note.Displacement
                bottom_note.RaiseLower = new_bottom_note.RaiseLower
                transposition.change_octave(bottom_note, math.max(1,num_octaves))
            end
        end
    end
end

pitch_rotate_chord_up()

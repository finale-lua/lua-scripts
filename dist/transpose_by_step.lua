function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true     -- not recognized by JW Lua or RGP Lua v0.55
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "January 20, 2022"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.Notes = [[
        This script allows you to specify a number of chromatic steps by which to transpose and the script
        simplifies the spelling. Chromatic steps are half-steps in a standard 12-tone scale, but they are smaller
        if you are using a microtone sytem defined in a custom key signature.

        Normally the script opens a modeless window. However, if you invoke the plugin with a shift, option, or
        alt key pressed, it skips opening a window and uses the last settings you entered into the window.
        (This works with RGP Lua version 0.60 and higher.)
        
        If you are using custom key signatures with JW Lua or an early version of RGP Lua, you must create
        a custom_key_sig.config.txt file in a folder called `script_settings` within the same folder as the script.
        It should contains the following two lines that define the custom key signature you are using. Unfortunately,
        the JW Lua and early versions of RGP Lua do not allow scripts to read this information from the Finale document.
        
        (This example is for 31-EDO.)
        
        number_of_steps = 31  
        diatonic_steps = {0, 5, 10, 13, 18, 23, 28}

        Later versions of RGP Lua (0.58 or higher) ignore this config file (if it exists) and read the correct
        information from the Finale document.
    ]]
    return "Transpose By Steps...", "Transpose By Steps",
           "Transpose by the number of steps given, simplifying spelling as needed."
end

global_dialog = nil
global_number_of_steps_edit = nil

local modifier_keys_on_invoke = false

if not finenv.RetainLuaState then
    context =
    {
        number_of_steps = nil,
        window_pos_x = nil,
        window_pos_y = nil
    }
end

if not finenv.IsRGPLua then
    local path = finale.FCString()
    path:SetRunningLuaFolderPath()
    package.path = package.path .. ";" .. path.LuaString .. "?.lua"
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




function do_transpose_by_step(global_number_of_steps_edit)
    if finenv.Region():IsEmpty() then
        return
    end
    local undostr = "Transpose By Steps " .. tostring(finenv.Region().StartMeasure)
    if finenv.Region().StartMeasure ~= finenv.Region().EndMeasure then
        undostr = undostr .. " - " .. tostring(finenv.Region().EndMeasure)
    end
    local success = true
    finenv.StartNewUndoBlock(undostr, false) -- this works on both JW Lua and RGP Lua
    for entry in eachentrysaved(finenv.Region()) do
        for note in each(entry) do
            if not transposition.stepwise_transpose(note, global_number_of_steps_edit) then
                success = false
            end
        end
    end
    if finenv.EndUndoBlock then -- EndUndoBlock only exists on RGP Lua 0.56 and higher
        finenv.EndUndoBlock(true)
        finenv.Region():Redraw()
    else
        finenv.StartNewUndoBlock(undostr, true) -- JW Lua automatically terminates the final undo block we start here
    end
    if not success then
        finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.", "Transposition Error")
    end
    return success
end

function create_dialog_box()
    local str = finale.FCString()
    local dialog = finale.FCCustomLuaWindow()
    str.LuaString = "Transpose By Steps"
    dialog:SetTitle(str)
    local current_y = 0
    local x_increment = 105
    -- number of steps
    local static = dialog:CreateStatic(0, current_y+2)
    str.LuaString = "Number Of Steps:"
    static:SetText(str)
    local edit_x = x_increment
    if finenv.UI():IsOnMac() then
        edit_x = edit_x + 4
    end
    global_number_of_steps_edit = dialog:CreateEdit(edit_x, current_y)
    if context.number_of_steps and 0 ~= context.number_of_steps then
        local str = finale.FCString()
        str:AppendInteger(context.number_of_steps)
        global_number_of_steps_edit:SetText(str)
    end
-- ok/cancel
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    if dialog.OkButtonCanClose then -- OkButtonCanClose will be nil before 0.56 and true (the default) after
        dialog.OkButtonCanClose = modifier_keys_on_invoke
    end
    return dialog
end
    
function on_ok()
    do_transpose_by_step(global_number_of_steps_edit:GetInteger())
end

function on_close()
    if global_dialog:QueryLastCommandModifierKeys(finale.CMDMODKEY_ALT) or global_dialog:QueryLastCommandModifierKeys(finale.CMDMODKEY_SHIFT) then
        finenv.RetainLuaState = false
    else
        context.number_of_steps = global_number_of_steps_edit:GetInteger()
        global_dialog:StorePosition()
        context.window_pos_x = global_dialog.StoredX
        context.window_pos_y = global_dialog.StoredY
    end
end

function transpose_by_step()
    modifier_keys_on_invoke = finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
    if modifier_keys_on_invoke and context.number_of_steps then
        do_transpose_by_step(context.number_of_steps)
        return
    end
    global_dialog = create_dialog_box()
    if nil ~= context.window_pos_x and nil ~= context.window_pos_y then
        global_dialog:StorePosition()
        global_dialog:SetRestorePositionOnlyData(context.window_pos_x, context.window_pos_y)
        global_dialog:RestorePosition()
    end
    global_dialog:RegisterHandleOkButtonPressed(on_ok)
    if global_dialog.RegisterCloseWindow then
        global_dialog:RegisterCloseWindow(on_close)
    end
    if finenv.IsRGPLua then
        if nil ~= finenv.RetainLuaState then
            finenv.RetainLuaState = true
        end
        finenv.RegisterModelessDialog(global_dialog)
        global_dialog:ShowModeless()
    else
        if finenv.Region():IsEmpty() then
            finenv.UI():AlertInfo("Please select a music region before running this script.", "Selection Required")
            return
        end
        global_dialog:ExecuteModal(nil)
    end
end

transpose_by_step()

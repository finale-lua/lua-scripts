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

local client = require("library.client")
local configuration = require("library.configuration")
local note_entry = require("library.note_entry")

local standard_key_number_of_steps = 12
local standard_key_major_diatonic_steps = {0, 2, 4, 5, 7, 9, 11}
local standard_key_minor_diatonic_steps = {0, 2, 3, 5, 7, 8, 10}

local max_allowed_abs_alteration = 7 -- Finale cannot represent an alteration outside +/- 7

-- first number is plus_fifths
-- second number is minus_octaves
local diatonic_interval_adjustments = {{0, 0}, {2, -1}, {4, -2}, {-1, 1}, {1, 0}, {3, -1}, {5, -2}, {0, 1}}

local custom_key_sig_config = {number_of_steps = standard_key_number_of_steps, diatonic_steps = standard_key_major_diatonic_steps}

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
    if client.supports("FCKeySignature::CalcTotalChromaticSteps") then
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
    local number_of_steps = sign(second_disp - first_disp) * (diatonic_steps[second_scale_degree + 1] - diatonic_steps[first_scale_degree + 1])
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
    local number_of_steps_in_interval = sign(interval_normalized) * ((plus_fifths * fifth_steps) + (minus_octaves * number_of_steps_in_key))
    return number_of_steps_in_interval
end

--
-- DIATONIC transposition (affect only Displacement)
--

--[[
% diatonic_transpose

Transpose the note diatonically by the given interval displacement.

@ note (FCNote) input and modified output
@ interval (number) 0 = unison, 1 = up a diatonic second, -2 = down a diatonic third, etc.
]]
function transposition.diatonic_transpose(note, interval)
    if note.GetTransposer then
        note:GetTransposer():DiatonicTranspose(interval)
        return
    end
    note.Displacement = note.Displacement + interval
end

--[[
% change_octave

Transpose the note by the given number of octaves.

@ note (FCNote) input and modified output
@ number_of_octaves (number) 0 = no change, 1 = up an octave, -2 = down 2 octaves, etc.
]]
function transposition.change_octave(note, number_of_octaves)
    if note.GetTransposer then
        note:GetTransposer():OctaveTranspose(number_of_octaves)
        return
    end
    transposition.diatonic_transpose(note, 7 * number_of_octaves)
end

--
-- ENHARMONIC transposition
--

--[[
% enharmonic_transpose

Transpose the note enharmonically in the given direction. In some microtone systems this yields a different result than transposing by a diminished 2nd.
Failure occurs if the note's `RaiseLower` value exceeds an absolute value of 7. This is a hard-coded limit in Finale.

@ note (FCNote) input and modified output
@ direction (number) positive = up, negative = down (normally 1 or -1, but any positive or negative numbers work)
@ [ignore_error] (boolean) default false. If true, always return success. External callers should omit this parameter.
: (boolean) success or failure
]]
function transposition.enharmonic_transpose(note, direction, ignore_error)
    ignore_error = ignore_error or false
    if note.GetTransposer and not ignore_error then
        return note:GetTransposer():EnharmonicTranspose(direction)
    end
    local curr_disp = note.Displacement
    local curr_alt = note.RaiseLower
    local key = get_key(note)
    local key_step_enharmonic = calc_steps_between_scale_degrees(key, note.Displacement, note.Displacement + sign(direction))
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


--[[
% enharmonic_transpose_default

Transpose the note enharmonically in Finale's default direction. This function should be used when performing an
unlinked enharmonic flip in a part. Only a default enharmonic flip unlinks. Any other enharmonic flip appears in the
score as well. This code is based on observed Finale behavior in Finale 27.

@ note (FCNote) input and modified output
@ direction (number) positive = up, negative = down (normally 1 or -1, but any positive or negative numbers work)
: (boolean) success or failure
]]
function transposition.enharmonic_transpose_default(note)
    if note.GetTransposer then
        return note:GetTransposer():DefaultEnharmonicTranspose()
    end
    if note.RaiseLower ~= 0 then
        return transposition.enharmonic_transpose(note, sign(note.RaiseLower))
    end
    local original_displacement = note.Displacement
    local original_raiselower = note.RaiseLower
    if not transposition.enharmonic_transpose(note, 1) then
        return false
    end
    -- This is observed Finale behavior, relevant in the context of microtone custom key signatures.
    -- A possibly more correct version would omit this hard-coded comparison to the number 2, but it
    -- seems to be what Finale does.
    if math.abs(note.RaiseLower) ~= 2 then
        return true
    end
    local up_displacement = note.Displacement
    local up_raiselower = note.RaiseLower
    note.Displacement = original_displacement
    note.RaiseLower = original_raiselower
    if not transposition.enharmonic_transpose(note, -1) then
        return false
    end
    if math.abs(note.RaiseLower) < math.abs(up_raiselower) then
        return true
    end
    note.Displacement = up_displacement
    note.RaiseLower = up_raiselower
    return true
end

--[[
% simplify_spelling

Simplifies the spelling of a note. See FCTransposer::SimplifySpelling at https://pdk.finalelua.com/ for more information
about why it can fail. External calls to this function should never fail, provided they omit the `min_abs_alteration` parameter.

@ note (FCNote) the note to transpose
@ [min_abs_alteration] (number) a value used internally. External calls should omit this parameter.
]]
function transposition.simplify_spelling(note, min_abs_alteration)
    min_abs_alteration = min_abs_alteration or 0
    if note.GetTransposer and min_abs_alteration == 0 then
        return note:GetTransposer():SimplifySpelling()
    end
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
-- CHROMATIC transposition (affect Displacement and RaiseLower)
--

--[[
% chromatic_transpose

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
    if note.GetTransposer then
        return note:GetTransposer():ChromaticTranspose(interval, alteration, simplify)
    end
    simplify = simplify or false
    local curr_disp = note.Displacement
    local curr_alt = note.RaiseLower

    local key = get_key(note)
    local _, diatonic_steps, _ = get_key_info(key)
    local interval_normalized = signed_modulus(interval, #diatonic_steps)
    local steps_in_alteration = calc_steps_in_alteration(key, interval, alteration)
    local steps_in_interval = calc_steps_in_normalized_interval(key, interval_normalized)
    local steps_in_diatonic_interval = calc_steps_between_scale_degrees(key, note.Displacement, note.Displacement + interval_normalized)
    local effective_alteration = steps_in_alteration + steps_in_interval - sign(interval) * steps_in_diatonic_interval
    transposition.diatonic_transpose(note, interval)
    note.RaiseLower = note.RaiseLower + effective_alteration

    local min_abs_alteration = max_allowed_abs_alteration
    if simplify then
        min_abs_alteration = 0
    end
    local success = transposition.simplify_spelling(note, min_abs_alteration)
    if not success then -- if Finale can't represent the transposition, revert it to original value
        note.Displacement = curr_disp
        note.RaiseLower = curr_alt
    end
    return success
end

--[[
% stepwise_transpose

Transposes the note by the input number of steps and simplifies the spelling.

For predefined key signatures, each step is a half-step.
For microtone systems defined with custom key signatures, the number of steps is determined by the key signature.

@ note (FCNote) input and modified output
@ number_of_steps (number) positive = up, negative = down
: (boolean) success or failure (see `enharmonic_transpose` for what causes failure)
]]
function transposition.stepwise_transpose(note, number_of_steps)
    if note.GetTransposer then
        return note:GetTransposer():EDOStepTranspose(number_of_steps)
    end
    local curr_disp = note.Displacement
    local curr_alt = note.RaiseLower
    note.RaiseLower = note.RaiseLower + number_of_steps
    local success = transposition.simplify_spelling(note)
    if not success then -- if Finale can't represent the transposition, revert it to original value
        note.Displacement = curr_disp
        note.RaiseLower = curr_alt
    end
    return success
end

--[[
% chromatic_major_third_down

Transpose the note down by a major third.

@ note (FCNote) input and modified output
]]
function transposition.chromatic_major_third_down(note)
    transposition.chromatic_transpose(note, -2, -0)
end

--[[
% chromatic_perfect_fourth_up

Transpose the note up by a perfect fourth.

@ note (FCNote) input and modified output
]]
function transposition.chromatic_perfect_fourth_up(note)
    transposition.chromatic_transpose(note, 3, 0)
end

--[[
% chromatic_perfect_fifth_down

Transpose the note down by a perfect fifth.

@ note (FCNote) input and modified output
]]
function transposition.chromatic_perfect_fifth_down(note)
    transposition.chromatic_transpose(note, -4, -0)
end

--[[
% each_to_transpose

Feeds a for loop with notes to transpose. Nothing happens if the entry is a rest.

@ entry (FCNoteEntry) input and modified output
@ [preserve_originals] (boolean) if true, creates new notes to be transposed rather than feeding the original notes (defaults to false)
]]
function transposition.each_to_transpose(entry, preserve_originals)
    if not entry then return nil end
    assert(entry:ClassName() == "FCNoteEntry", "argument 1 must be FCNoteEntry")
    local note_count = entry.Count
    local note_index = -1
    return function()
        if entry:IsRest() then
            return nil
        end
        note_index = note_index + 1
        if note_index >= note_count then
            return nil
        end
        local note = entry:GetItemAt(note_index)
        assert(note, "invalid note found")
        if preserve_originals then
            return note_entry.duplicate_note(note)
        end
        return note
    end
end

--[[
% entry_diatonic_transpose

Transpose all the notes in an entry diatonically by the specified interval

@ entry (FCNoteEntry) input and modified output
]]
function transposition.entry_diatonic_transpose(entry, interval, preserve_originals)
    for note in transposition.each_to_transpose(entry, preserve_originals) do
        transposition.diatonic_transpose(note, interval)
    end
end

--[[
% entry_chromatic_transpose

Transpose all the notes in an entry diatonically by the specified interval. If any note in the entry
fails to transpose, the return value is false. However, only the failed notes are reverted to their
original state. (See `enharmonic_transpose` for what causes failure.)

@ entry (FCNoteEntry) input and modified output
@ interval (number) the diatonic displacement (negative for transposing down)
@ alteration (number) the chromatic alteration that defines the chromatic interval (reverse sign for transposing down)
@ [simplify] (boolean) if present and true causes the spelling of the transposed note to be simplified
@ [plus_octaves] (number) if present and non-zero, specifies the number of octaves to further transpose the result
@ [preserve_originals] (boolean) if present and true create duplicates of the original notes and transposes them,
: (boolean) success or failure (see `enharmonic_transpose` for what causes failure)
]]
function transposition.entry_chromatic_transpose(entry, interval, alteration, simplify, plus_octaves, preserve_originals)
    plus_octaves = plus_octaves or 0
    local success = true
    for note in transposition.each_to_transpose(entry, preserve_originals) do
        if not transposition.chromatic_transpose(note, interval, alteration, simplify) then
            success = false
        end
        transposition.change_octave(note, plus_octaves)
    end
    return success
end

--[[
% entry_stepwise_transpose

Transposes the note by the input number of steps and simplifies the spelling. If any note in the entry
fails to transpose, the return value is false. However, only the failed notes are reverted to their
original state. (See `enharmonic_transpose` for what causes failure.)

For predefined key signatures, each step is a half-step.
For microtone systems defined with custom key signatures, the number of steps is determined by the key signature.

@ entry (FCNoteEntry) input and modified output
@ number_of_steps (number) positive = up, negative = down
@ [preserve_originals] (boolean) if present and true create duplicates of the original notes and transposes them,
: (boolean) success or failure
]]
function transposition.entry_stepwise_transpose(entry, number_of_steps, preserve_originals)
    local success = true
    for note in transposition.each_to_transpose(entry, preserve_originals) do
        if not transposition.stepwise_transpose(note, number_of_steps) then
            success = false
        end
    end
    return success
end


--[[
% entry_enharmonic_transpose

Transpose all the notes enharmonically in the given direction. In some microtone systems this yields a different result than transposing by a diminished 2nd.
Failure occurs if any note's `RaiseLower` value exceeds an absolute value of 7. This is a hard-coded limit in Finale.

@ entry (FCNoteEntry) input and modified output
@ direction (number) positive = up, negative = down (normally 1 or -1, but any positive or negative numbers work)
: (boolean) success or failure
]]
function transposition.entry_enharmonic_transpose(entry, direction)
    local success = true
    for note in transposition.each_to_transpose(entry) do
        if not transposition.enharmonic_transpose(note, direction) then
            success = false
        end
    end
    return success
end

    
return transposition

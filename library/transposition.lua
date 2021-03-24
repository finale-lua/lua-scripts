-- A collection of helpful JW Lua transposition scripts
-- Simply import this file to another Lua script to use any of these scripts
-- 
-- THIS MODULE IS INCOMPLETE
-- 
-- Structure
-- 1. Helper functions
-- 2. Diatonic Transpositions (listed by interval - ascending)
-- 3. Chromatic Transpositions (listed by interval - ascending)
-- 
local transposition = {}

-- 
-- HELPER functions
-- 

function transposition.calc_pitch_string(note)
    local pitch_string = finale.FCString()
    local entry = note:GetEntry()
    local measure = entry:GetMeasure()
    measure_object = finale.FCMeasure()
    measure_object:Load(measure)
    local key_signature = measure_object:GetKeySignature()
    note:GetString(pitch_string, key_signature, false, false)
    return pitch_string
end

function transposition.set_pitch_string(note, pitch_string)
    local entry = note:GetEntry()
    local measure = entry:GetMeasure()
    measure_object = finale.FCMeasure()
    measure_object:Load(measure)
    local key_signature = measure_object:GetKeySignature()
    note:SetString(pitch_string, key_signature, false)
end

function transposition.pitch_string_change_octave(pitch_string, n)
    pitch_string.LuaString = pitch_string.LuaString:sub(1, -2) .. (tonumber(string.sub(pitch_string.LuaString, -1)) + n)
    return pitch_string
end

function transposition.change_octave(note, n)
    note.Displacement = note.Displacement + 7*n
end

function transposition.set_notes_to_same_pitch(note_a, note_b)
    note_b.Displacement = note_a.Displacement
    note_b.RaiseLower = note_a.RaiseLower
end


-- 
-- DIATONIC transposition
-- 

function transposition.diatonic_third_down(note)
    note.Displacement = note.Displacement - 2
end

function transposition.diatonic_fourth_up(note)
    note.Displacement = note.Displacement + 3
end

function transposition.diatonic_fifth_down(note)
    note.Displacement = note.Displacement + 4
end

-- 
-- CHROMATIC transposition
-- 

function transposition.chromatic_major_third_down(note)
    local original_midi_key = note:CalcMIDIKey()
    transposition.diatonic_third_down(note)

    -- fixes any errors from the diatonic transposition
    if (note:CalcMIDIKey() - original_midi_key ~= 4) then
        local error = note:CalcMIDIKey() - original_midi_key + 4
        print(note:CalcMIDIKey() - original_midi_key + 4)
        note.RaiseLower = note.RaiseLower - error
    end
end

function transposition.chromatic_perfect_fourth_up(note)
    local original_midi_key = note:CalcMIDIKey()
    transposition.diatonic_fourth_up(note)

    -- fixes any errors from the diatonic transposition
    if (note:CalcMIDIKey() - original_midi_key ~= 5) then
        local error = note:CalcMIDIKey() - original_midi_key - 5
        note.RaiseLower = note.RaiseLower + error
    end
end

function transposition.chromatic_perfect_fifth_down(note)
    local original_midi_key = note:CalcMIDIKey()
    transposition.diatonic_fifth_down(note)

    -- fixes any errors from the diatonic transposition
    if (note:CalcMIDIKey() - original_midi_key ~= 7) then
        local error = note:CalcMIDIKey() - original_midi_key + 7
        note.RaiseLower = note.RaiseLower - error
    end
end

return transposition

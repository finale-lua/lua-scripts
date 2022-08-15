function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.56"
    finaleplugin.Date = "2022/08/04"
    finaleplugin.AdditionalMenuOptions = [[
        Note Ends Eighths
    ]]
    finaleplugin.AdditionalUndoText = [[
        Note Ends Eighths
    ]]
    finaleplugin.AdditionalPrefixes = [[
        eighth_notes = true
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Change smaller notes followed by rests into eighth notes
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.ScriptGroupName = "Change note endings"
    finaleplugin.ScriptGroupDescription = "Align the ends of notes followed by a rest to selected duration boundaries"
    finaleplugin.Notes = [[
        This plug-in aligns the ends of notes followed by a rest to a specific "duration boundary". 
        It helps improve readability of music with lots of short notes and rests. 
        It creates two menu items, `Note Ends Eighths` and `Note Ends Quarters`.
]]
    return "Note Ends Quarters", "Note Ends Quarters", "Change smaller notes followed by rests into quarter notes"
end

-- default to quarter notes
eighth_notes = eighth_notes or false

function is_valid_entry(entry, boundary_value, beat_duration)
    -- (a) must be note followed by rest
    if entry:IsRest() or not entry:Next() or entry:Next():IsNote() then
        return false
    end
    local note_boundary = entry.MeasurePos % (boundary_value / 2)
    local is_compound_meter = (beat_duration % 3 == 0)
    local start_beat = math.floor(entry.MeasurePos / beat_duration)
    local position_in_beat = entry.MeasurePos % beat_duration

    -- (b) note too long, or not on half- or beat-boundary
    if (entry.Duration >= boundary_value) or (note_boundary ~= 0) or (entry.Duration + entry:Next().Duration < boundary_value) then
        return false
    end
    -- (c) room for expanded endpoint / special case quarter note on odd beat
    if (position_in_beat + boundary_value > beat_duration) and (is_compound_meter or eighth_notes or (start_beat % 2) ~= 0) then
        return false
    end
    return true
end

function expand_note_ends()
    local should_delete_next = false
    local boundary_value = eighth_notes and finale.NOTE_8TH or finale.NOTE_QUARTER -- [ 512 / 1024 ]
    local beat_duration = 0
    local measure_number = 0

    for entry in eachentrysaved(finenv.Region()) do
        if measure_number ~= entry.Measure then -- calculate beat duration for new measure
            measure_number = entry.Measure
            local measure = finale.FCMeasure()
            measure:Load(measure_number)
            local time_sig = measure:GetTimeSignature()
            beat_duration = time_sig:CalcLargestBeatDuration()
        end

        if should_delete_next then -- last note was expanded
            entry.Duration = 0 -- so delete this rest
            should_delete_next = false -- and start over
        elseif is_valid_entry(entry, boundary_value, beat_duration) then
            local duration_with_rest = entry.Duration + entry:Next().Duration
            entry.Duration = boundary_value	-- expand target note

            if duration_with_rest == boundary_value then
                should_delete_next = true -- just delete the following rest
            elseif duration_with_rest > boundary_value then -- some duration left over
                entry:Next().Duration = duration_with_rest - boundary_value -- make rest smaller
                should_delete_next = false -- and don't delete it
            end
        end
    end
end

expand_note_ends()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.54"
    finaleplugin.Date = "2022/08/02"
    finaleplugin.AdditionalMenuOptions = [[
        Note ends eighths
    ]]
    finaleplugin.AdditionalUndoText = [[
        Note ends eighths
    ]]
    finaleplugin.AdditionalPrefixes = [[
        eighth_notes = true
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Change smaller notes followed by rests into eighth notes
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.ScriptGroupName = "Change note endings"
    finaleplugin.ScriptGroupDescription = "Align the ends of notes followed by a rest to specific duration boundaries"
    finaleplugin.Notes = [[
        This plug-in aligns the ends of notes followed by a rest to a specific "duration boundary". 
        It helps improve readability of music with lots of short notes and rests. 
        It creates two menu items, `Note ends eighths` and `Note ends quarters`.
]]
    return "Note ends quarters", "Note ends quarters", "Change smaller notes followed by rests into quarter notes"
end

-- default to quarter notes for normal operation
eighth_notes = eighth_notes or false

function expand_note_ends()
    local should_delete_next = false
    local note_value = eighth_notes and finale.NOTE_8TH or finale.NOTE_QUARTER -- [ 512 / 1024 ]
    local beat_duration = note_value
    local measure_number = 0
    local measure = finale.FCMeasure()
    local is_compound_meter = false

    for entry in eachentrysaved(finenv.Region()) do
        if measure_number ~= entry.Measure then -- calculate beat duration for each new measure
            measure_number = entry.Measure
            measure:Load(measure_number)
            local time_sig = measure:GetTimeSignature()
            beat_duration = time_sig:CalcLargestBeatDuration()
            is_compound_meter = (beat_duration % 3 == 0)
        end
        local position_in_beat = entry.MeasurePos % beat_duration
        local note_boundary = entry.MeasurePos % (note_value / 2)
        local start_beat = math.floor(entry.MeasurePos / beat_duration)

        if should_delete_next then -- last note was expanded
            entry.Duration = 0 -- so delete this rest
            should_delete_next = false -- and start over
            -- OTHERWISE
        elseif entry:IsNote() -- is a note
            and entry:Next() -- with a following entry
            and entry:Next():IsRest() -- that is a rest
            and entry.Duration < note_value -- this note is too short
            and note_boundary == 0 -- on a beat or half-beat
            and entry.Duration + entry:Next().Duration >= note_value
            and
            (    (beat_duration >= position_in_beat + note_value) -- enough space for expanded endpoint
                or  (not is_compound_meter and not eighth_notes and start_beat % 2 == 0) -- special case quarter note on an odd beat
            )
            then
            local duration_with_rest = entry.Duration + entry:Next().Duration
            entry.Duration = note_value	-- expand target note
            if duration_with_rest == note_value then
                should_delete_next = true -- just delete the following rest
            elseif duration_with_rest > note_value then -- some duration left over
                entry:Next().Duration = duration_with_rest - note_value -- make rest smaller
                should_delete_next = false -- and don't delete it
            end
        end
    end
end

expand_note_ends()

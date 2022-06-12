function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "June 4, 2022"
    finaleplugin.CategoryTags = "Meter"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.RequireSelection = true
    finaleplugin.Notes = [[
        Changes the meter. If a single measure is selected,
        the meter will be set for remaining measures in the score.
        If multiple measures are selected, the meter will be set
        only for the selected measures.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Meter - 1/2
        Meter - 2/2
        Meter - 3/2
        Meter - 4/2
        Meter - 5/2
        Meter - 6/2
        Meter - 1/4
        Meter - 2/4
        Meter - 3/4
        Meter - 5/4
        Meter - 6/4
        Meter - 7/4
        Meter - 3/8
        Meter - 6/8
        Meter - 9/8
        Meter - 12/8
        Meter - 15/8
    ]]
    finaleplugin.AdditionalUndoText = [[
        Meter - 1/2
        Meter - 2/2
        Meter - 3/2
        Meter - 4/2
        Meter - 5/2
        Meter - 6/2
        Meter - 1/4
        Meter - 2/4
        Meter - 3/4
        Meter - 5/4
        Meter - 6/4
        Meter - 7/4
        Meter - 3/8
        Meter - 6/8
        Meter - 9/8
        Meter - 12/8
        Meter - 15/8
    ]]
    finaleplugin.AdditionalPrefixes = [[
        numerator = 1 denominator = 2
        numerator = 2 denominator = 2
        numerator = 3 denominator = 2
        numerator = 4 denominator = 2
        numerator = 5 denominator = 2
        numerator = 6 denominator = 2
        numerator = 1 denominator = 4
        numerator = 2 denominator = 4
        numerator = 3 denominator = 4
        numerator = 5 denominator = 4
        numerator = 6 denominator = 4
        numerator = 7 denominator = 4
        numerator = 3 denominator = 8
        numerator = 6 denominator = 8
        numerator = 9 denominator = 8
        numerator = 12 denominator = 8
        numerator = 15 denominator = 8
    ]]
    return "Meter - 4/4", "Meter - 4/4", "Sets the meter to 4/4"
end

numerator = numerator or 4
denominator = denominator or 4
if denominator == 8 then
    numerator = numerator / 3
end

local denominators = {}
denominators[2] = 2048
denominators[4] = 1024
denominators[8] = 1536 -- for compound meters

function set_time(beat_num, beat_duration)
    local measures = finale.FCMeasures()
    measures:LoadRegion(finenv.Region())
    if measures.Count > 1 then
        for m in each(measures) do
            local time_sig = m:GetTimeSignature()
            time_sig:SetBeats(beat_num)
            time_sig:SetBeatDuration(beat_duration)
            time_sig:Save()
            m:Save()
        end
    else
        local allMeasures = finale.FCMeasures()
        allMeasures:LoadAll()
        for m in each(allMeasures) do
            local selectedMeasure = measures:GetItemAt(0)
            if (m.ItemNo >= selectedMeasure.ItemNo) then
                local time_sig = m:GetTimeSignature()
                time_sig:SetBeats(beat_num)
                time_sig:SetBeatDuration(beat_duration)
                time_sig:Save()
                m:Save()
            end
        end
    end
end

set_time(numerator, denominators[denominator])

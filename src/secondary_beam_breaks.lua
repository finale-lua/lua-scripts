function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine after Jari Williamsson"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdobreak_beams/zero/1.0/"
    finaleplugin.Version = "v1.2"
    finaleplugin.Date = "2022/06/06"
    finaleplugin.AdditionalMenuOptions = [[ Clear secondary beam breaks ]]
    finaleplugin.AdditionalUndoText = [[ Clear secondary beam breaks ]]
    finaleplugin.AdditionalPrefixes = [[ clear_breaks = true ]]
    finaleplugin.AdditionalDescriptions = [[ Clear all secondary beam breaks in the selected region ]]
    finaleplugin.Notes = [[ 
    A string of small beamed notes (say 32nd note or shorter) are much easier to read if their secondary beam is broken in the middle of a beat. 
    This script is designed principally to break secondary beams in simple meters (2/4, 3/4, 4/4 etc) in the middle of each beat. 
    If the current meter is compound (6/8, 9/8 etc) then the beat is divided into three sections. 
    RGPLua (0.62 and above) creates a companion menu item, "Clear secondary beam breaks".
    ]]
    return "Break secondary beams", "Break secondary beams", "Break secondary beams with compound consideration"
end

-- default to break beams
clear_breaks = clear_breaks or false

function break_secondary_beams()
    local measure_number = 0
    local beamed_length = finale.NOTE_8TH -- default to 8ths
    local measure = finale.FCMeasure()

    for entry in eachentrysaved(finenv.Region()) do
        if measure_number ~= entry:GetMeasure() then -- started a new measure
            measure_number = entry:GetMeasure()
            measure:Load(measure_number)
            local time_sig = measure:GetTimeSignature()
            beamed_length = time_sig:CalcLargestBeatDuration()
            if (beamed_length % 3 == 0) then  -- compound time_sig, divide beat by 3
                beamed_length = beamed_length / 3
            else
                beamed_length = beamed_length / 2 -- "normal" time, divide beat by 2
            end
        end

        -- is this entry at a division point in a beamed group?
        if not (entry.BeamBeat or entry:IsRest() or entry:Previous():IsRest())
            and (entry.MeasurePos % beamed_length == 0) then

            local sbbm = finale.FCSecondaryBeamBreakMod()
            sbbm:SetNoteEntry(entry)
            local bm_loaded = sbbm:LoadFirst()
            sbbm:SetBreakAll(true) -- also "SetBreak128th" (true) etc
            if bm_loaded then
                sbbm:Save() -- save existing data
            else
                sbbm:SaveNew() -- create new data
            end
        end
    end
end

function clear_beam_breaks()
    local sbbm = finale.FCSecondaryBeamBreakMod()

    for entry in eachentrysaved(finenv.Region()) do
        sbbm:SetNoteEntry(entry)
        local loaded = sbbm:LoadFirst()
        if loaded then -- beam change already exists
            sbbm:SetBreakAll(false) -- remove all breaks
            sbbm:Save() -- save changed data
        end
    end
end

if clear_breaks then
    clear_beam_breaks()
else
    break_secondary_beams()
end

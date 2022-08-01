function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine after Jari Williamsson"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdobreak_beams/zero/1.0/"
    finaleplugin.Version = "v1.21"
    finaleplugin.Date = "2022/08/01"
    finaleplugin.AdditionalMenuOptions = [[
        Clear secondary beam breaks
    ]]
    finaleplugin.AdditionalUndoText = [[
        Clear secondary beam breaks
    ]]
    finaleplugin.AdditionalPrefixes = [[
        clear_breaks = true
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Clear all secondary beam breaks in the selected region
    ]]
    finaleplugin.ScriptGroupName = "Secondary beam breaks"
    finaleplugin.ScriptGroupDescription = "Create or remove secondary beam breaks"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[ 
        A stream of many short beamed notes (say 32nd notes) are easier to read 
        if the secondary beam is broken in the middle of a beat. 
        This script breaks secondary beams in simple meters (2/4, 3/4, 4/4 etc) 
        in the middle of each beat. 
        If the meter is compound (6/8, 9/8 etc) then the beat is divided into three sections. 
        Two menus are created, `Break secondary beams` and 
        `Clear secondary beam breaks`.
        ]]
    return "Break secondary beams", "Break secondary beams", "Break secondary beams with compound consideration"
end

-- default to break beams
clear_breaks = clear_breaks or false

function break_secondary_beams()
    local measure_number = 0
    local staff_number = 0
    local beamed_length = finale.NOTE_8TH -- default to 8ths

    for entry in eachentrysaved(finenv.Region()) do
        if measure_number ~= entry.Measure or staff_number ~= entry.Staff then -- started a new cell
            measure_number = entry.Measure
            staff_number = entry.Staff
            local cell = finale.FCCell(measure_number, staff_number)
            local time_sig = cell:GetTimeSignature()
            beamed_length = time_sig:CalcLargestBeatDuration()
            if (beamed_length % 3 == 0) then  -- compound time_sig, divide beat by 3
                beamed_length = beamed_length / 3
            else
                beamed_length = beamed_length / 2 -- "normal" time, divide beat by 2
            end
        end

        -- is this entry at a division point in a beamed group?
        if not (entry.BeamBeat or entry:IsRest() or (entry:Previous() and entry:Previous():IsRest()))
            and (entry.MeasurePos % beamed_length == 0) then

            local sbbm = finale.FCSecondaryBeamBreakMod()
            sbbm:SetNoteEntry(entry)
            local bm_loaded = sbbm:LoadFirst()
            for beam = 0, 8 do
                local beam_value = bit32.rshift(finale.NOTE_16TH, beam)
                if beam_value < beamed_length then
                    sbbm:SetBreak(beam, true)
                end
            end
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

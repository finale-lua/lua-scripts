function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine and Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.76"
    finaleplugin.Date = "2022/08/01"
    finaleplugin.AdditionalMenuOptions = [[
        Untie Notes
    ]]
    finaleplugin.AdditionalUndoText = [[
        Untie Notes
    ]]
    finaleplugin.AdditionalPrefixes = [[
        untie_notes = true
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Untie all notes in the selected region
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.ScriptGroupName = "Tie/untie notes"
    finaleplugin.ScriptGroupDescription = "Tie or untie suitable notes in the current selection"
    finaleplugin.Notes = [[ 
    Ties notes in adjacent entries if matching pitches are available. 
    A companion menu item is also created to `Untie` all notes in the selection.
    ]]
    return "Tie Notes", "Tie Notes", "Tie suitable notes in the selected region"
end

-- default to "tie" notes for normal operation
untie_notes = untie_notes or false

local tie = require('library.tie')

local function tie_notes_in_selection()
    local region = finenv.Region()

    for slot = region.StartSlot, region.EndSlot do
        local staff_number = region:CalcStaffNumber(slot)
        for layer_number = 0, 3 do  -- run through layers [0-based]
            local entry_layer = finale.FCNoteEntryLayer(layer_number, staff_number, region.StartMeasure, region.EndMeasure)
            entry_layer:Load()
            for entry in each(entry_layer) do
                if entry:IsNote() and region:IsEntryPosWithin(entry) then
                    for note in each(entry) do
                        if untie_notes then
                            if note.TieBackwards then
                                local tie_span_from, start_note = tie.calc_tie_span(note, true)
                                if not start_note or region:IsEntryPosWithin(start_note.Entry) or not start_note.Tie then
                                    note.TieBackwards = false
                                    finale.FCTieMod(finale.TIEMODTYPE_TIEEND):EraseAt(note)
                                end
                            end
                            if note.Tie then
                                local tie_span_to, _, end_note = tie.calc_tie_span(note, false)
                                if not end_note or region:IsEntryPosWithin(end_note.Entry) or not end_note.TieBackwards then
                                    note.Tie = false
                                    finale.FCTieMod(finale.TIEMODTYPE_TIESTART):EraseAt(note)
                                end
                            end
                        else
                            local tied_to_note = tie.calc_tied_to(note)
                            if tied_to_note and region:IsEntryPosWithin(tied_to_note.Entry) then
                                note.Tie = true
                                tied_to_note.TieBackwards = true
                            end
                        end
                    end
                end
            end
            entry_layer:Save()
        end
    end
end

tie_notes_in_selection()

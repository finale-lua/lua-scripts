function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine and Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.75"
    finaleplugin.Date = "2022/06/06"
    finaleplugin.AdditionalMenuOptions = [[ Untie Notes ]]
    finaleplugin.AdditionalUndoText = [[ Untie Notes ]]
    finaleplugin.AdditionalPrefixes = [[ untie_notes = true ]]
    finaleplugin.AdditionalDescriptions = [[ Untie all notes in the selected region ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[ 
    Ties notes in adjacent entries if matching pitches are available. 
    RGPLua (0.62 and above) creates a companion menu item, UNTIE Notes.
    ]]
    return "Tie Notes", "Tie Notes", "Tie suitable notes in the selected region, with matching Untie option"
end

-- default to "tie" notes for normal operation
untie_notes = untie_notes or false

local note_entry = require('library.note_entry')

local function tied_to(note)
    if not note then
        return nil
    end
    local next_entry = note.Entry
    if next_entry then
        if next_entry.Voice2Launch then
            next_entry = note_entry.get_next_same_v(next_entry)
        else
            next_entry = next_entry:Next()
        end
        if next_entry and next_entry:IsNote() and not next_entry.GraceNote then
            local tied_to_note = next_entry:FindPitch(note)
            if tied_to_note then
                return tied_to_note
            end
            if next_entry.Voice2Launch then
                local next_v2_entry = next_entry:Next()
                tied_to_note = next_v2_entry:FindPitch(note)
                if tied_to_note then
                    return tied_to_note
                end
            end
        end
    end
    return nil
end

local function tie_notes_in_selection()
    local region = finenv.Region()

    for staff_number = region.StartStaff, region.EndStaff do
        for layer_number = 0, 3 do  -- run through layers [0-based]
            local entry_layer = finale.FCNoteEntryLayer(layer_number, staff_number, region.StartMeasure, region.EndMeasure)
            entry_layer:Load()
            for entry in each(entry_layer) do
                if entry:IsNote() and region:IsEntryPosWithin(entry) then
                    for note in each(entry) do
                        local tied_to_note = tied_to(note)
                        if tied_to_note and region:IsEntryPosWithin(tied_to_note.Entry) then
                            note.Tie = not untie_notes
                            tied_to_note.TieBackwards = not untie_notes
                        end
                    end
                end
            end
            entry_layer:Save()
        end
    end
end


tie_notes_in_selection()

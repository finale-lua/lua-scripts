--[[
$module Tie

This library encapsulates Finale's behavior for initializing FCTieMod endpoints,
as well as providing other useful information about ties. 
]] --
local tie = {}

-- returns FCNoteEntryLayer, along with start and end FCNotes for the tie that
--      are contained within the FCNoteEntryLayer.
local tie_span = function(note, for_tieend)
    local start_measnum = (for_tieend and note.Entry.Measure > 1) and note.Entry.Measure - 1 or note.Entry.Measure
    local end_measnum = for_tieend and note.Entry.Measure or note.Entry.Measure + 1
    local note_entry_layer = finale.FCNoteEntryLayer(note.Entry.LayerNumber - 1, note.Entry.Staff, start_measnum, end_measnum)
    note_entry_layer:Load()
    local same_entry
    for entry in each(note_entry_layer) do
        if entry.EntryNumber == note.Entry.EntryNumber then
            same_entry = entry
            break
        end
    end
    if not same_entry then
        return note_entry_layer
    end

end

--[[
% default_direction

Returns one of the TIEMODDIR_ constants. If the input note has no applicable tie,
it returns 0.

@ note (FCNote) the note for which to return the tie direction.
@ for_tieend (boolen) specifies that this request is for a tie_end.
]]
function tie.default_direction(note, for_tieend)
    if for_tieend then
        if not note.TieBackwards then
            return 0
        end
    else
        if not note.Tie then
            return 0
        end
    end
    if note.Entry.Count > 1 then
    else

    end

end -- function tie.default_direction

return tie

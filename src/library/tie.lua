--[[
$module Tie

This library encapsulates Finale's behavior for initializing FCTieMod endpoints,
as well as providing other useful information about ties. 
]] --
local tie = {}

-- returns the equal note in the next closest entry or nil if none
local equal_note = function(entry, target_note, for_tieend)
    if entry:IsRest() then
        return nil
    end
    -- By using CalcStaffLine we can support a key change in the middle of a tie. But it is at the cost
    -- of not supporting a clef change in the middle of the tie. A calculation comparing normalized concert
    -- pitch is *much* more complicated code, and clef changes in the middle of ties seem like a very limited
    -- use case.
    local target_staffline = target_note:CalcStaffLine()
    for note in each(entry) do
        local this_staffline = note:CalcStaffLine()
        if this_staffline == target_staffline then
            if for_tieend then
                if note.TieBackwards then
                    return note
                end
            else
                if note.Tie then
                    return note
                end
            end
        end
    end
    return nil
end

-- returns the note that the input note is tied to.
-- for this function to work, note must be from a FCNoteEntryLayer
-- instance constructed by function tie_span.
local function tied_to(note)
    if not note then
        return nil
    end
    local next_entry = note.Entry
    if next_entry then
        next_entry = next_entry:Next()
        if next_entry and not next_entry.GraceNote then
            local tied_to_note = equal_note(next_entry, note, true)
            if tied_to_note then
                return tied_to_note
            end
            if next_entry.Voice2Launch then
                local next_v2_entry = next_entry:Next()
                tied_to_note = equal_note(next_v2_entry, note, true)
                if tied_to_note then
                    return tied_to_note
                end
            end
        end
    end
    return nil
end

-- returns the note that the input note is tied from.
-- for this function to work, note must be from a FCNoteEntryLayer
-- instance constructed by function tie_span.
local function tied_from(note)
    if not note then
        return nil
    end
    local entry = note.Entry
    while true do
        entry = entry:Previous()
        if not entry then
            break
        end
        tied_from_note = equal_note(entry, note, false)
        if tied_from_note then
            return tied_from_note
        end
    end
end

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
    local note_entry_layer_note = same_entry:GetItemAt(note.NoteIndex)
    local start_note = for_tieend and tied_from(note_entry_layer_note) or note_entry_layer_note
    local end_note = for_tieend and note_entry_layer_note or tied_to(note_entry_layer_note)
    return note_entry_layer, start_note, end_note
end

--[[
% default_direction

Returns either TIEMODDIR_UNDER or TIEMODDIR_OVER. If the input note has no applicable tie,
it returns 0.

@ note (FCNote) the note for which to return the tie direction.
@ for_tieend (boolean) specifies that this request is for a tie_end.
@ [tie_prefs] (FCTiePrefs) use these tie prefs if supplied
]]
function tie.default_direction(note, for_tieend, tie_prefs)
    if for_tieend then
        if not note.TieBackwards then
            return 0
        end
    else
        if not note.Tie then
            return 0
        end
    end
    if not tie_prefs then
        tie_prefs = finale.FCTiePrefs()
        tie_prefs:Load(0)
    end
    local stemdir = note.Entry.StemUp and 1 or -1
    if note.Entry.Count > 1 then
    else
        local adjacent_stemdir = 0
        local note_entry_layer, start_note, end_note = tie_span(note, for_tieend)
        if for_tieend then
            -- There seems to be a "bug" in how Finale determines mixed-stem values for Tie-Ends.
            -- It looks at the stem direction of the immediately preceding entry, even if that entry
            -- is not the entry that started the tie. Therefore, do not use tied_from_note to
            -- get the stem direction.
            if end_note then
                local start_entry = end_note.Entry:Previous()
                if start_entry then
                    adjacent_stemdir = start_entry.StemUp and 1 or -1
                end
            end
        else
            if end_note then
                adjacent_stemdir = end_note.Entry.StemUp and 1 or -1
            end
            if adjacent_stemdir == 0 and start_note then
                -- Finale (as of v2K) has the following Mickey Mouse behavior. When no Tie-To note exists,
                -- it determines the mixed stem value based on
                --		1. If the next entry is a rest, the adjStemDir is indeterminate so use stemDir (i.e., fall thru to bottom)
                --		2. If the next entry is a note with its stem frozen, use it
                --		3. If the next entry floats, but it has a V2Launch, then if EITHER the V1 or
                --				the V2 has a stem in the opposite direction, use it.
                local next_entry = start_note.Entry:Next()
                if next_entry and not next_entry:IsRest() then
                    adjacent_stemdir = next_entry.StemUp and 1 or -1
                    if not next_entry.FreezeStem and next_entry.Voice2Launch and adjacent_stemdir == stemdir then
                        next_entry = next_entry:Next()
                        if next_entry then
                            adjacent_stemdir = next_entry.StemUp and 1 or -1
                        end
                    end
                end
            end
            if adjacent_stemdir ~= 0 and adjacent_stemdir ~= stemdir then
                if tie_prefs.MixedStemDirectionType == finale.TIEMIXEDSTEM_OVER then
                    return finale.TIEMODDIR_OVER
                elseif tie_prefs.MixedStemDirectionType == finale.TIEMIXEDSTEM_UNDER then
                    return finale.TIEMODDIR_UNDER
                end
            end
        end
    end

    return (stemdir > 0) and finale.TIEMODDIR_UNDER or finale.TIEMODDIR_OVER

end -- function tie.default_direction

return tie

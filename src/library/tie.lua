--[[
$module Tie

This library encapsulates Finale's behavior for initializing FCTieMod endpoints,
as well as providing other useful information about ties. 
]] --
local tie = {}

local note_entry = require('library.note_entry')

-- returns the equal note in the next closest entry or nil if none
local equal_note = function(entry, target_note, for_tied_to, tie_must_exist)
    local found_note = entry:FindPitch(target_note)
    if not found_note or not tie_must_exist then
        return found_note
    end
    if for_tied_to then
        if found_note.TieBackwards then
            return found_note
        end
    else
        if found_note.Tie then
            return found_note
        end
    end
    return nil
end

--[[
% calc_tied_to

Calculates the note that the input note could be (or is) tied to.
For this function to work correctly across barlines, the input note
must be from an instance of FCNoteEntryLayer that contains both the
input note and the tied-to note.

@ note (FCNote) the note for which to return the tied-to note
@ [tie_must_exist] if true, only returns a note if the tie already exists.
: (FCNote) Returns the tied-to note or nil if none
]]
function tie.calc_tied_to(note, tie_must_exist)
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
        if next_entry and not next_entry.GraceNote then
            local tied_to_note = equal_note(next_entry, note, true, tie_must_exist)
            if tied_to_note then
                return tied_to_note
            end
            if next_entry.Voice2Launch then
                local next_v2_entry = next_entry:Next()
                tied_to_note = equal_note(next_v2_entry, note, true, tie_must_exist)
                if tied_to_note then
                    return tied_to_note
                end
            end
        end
    end
    return nil
end

--[[
% calc_tied_from

Calculates the note that the input note could be (or is) tied from.
For this function to work correctly across barlines, the input note
must be from an instance of FCNoteEntryLayer that contains both the
input note and the tied-from note.

@ note (FCNote) the note for which to return the tied-from note
@ [tie_must_exist] if true, only returns a note if the tie already exists.
: (FCNote) Returns the tied-from note or nil if none
]]
function tie.calc_tied_from(note, tie_must_exist)
    if not note then
        return nil
    end
    local entry = note.Entry
    while true do
        entry = entry:Previous()
        if not entry then
            break
        end
        tied_from_note = equal_note(entry, note, false, tie_must_exist)
        if tied_from_note then
            return tied_from_note
        end
    end
end

--[[
% calc_tie_span

Calculates the (potential) start and end notes for a tie, given an input note. The
input note can be from anywhere, including from the `eachentry()` iterator functions.
The function returns 3 values:

- A FCNoteLayerEntry containing both the start and and notes (if they exist).
You must maintain the lifetime of this variable as long as you are referencing either
of the other two values.
- The potential or actual start note of the tie (taken from the FCNoteLayerEntry above).
- The potential or actual end note of the tie (taken from the FCNoteLayerEntry above).

Be very careful about modifying the return values from this function. If you do it within
an iterator loop from `eachentry()` or `eachentrysaved()` you could end up overwriting your changes
with stale data from the iterator loop. You may discover that this function is more useful
for gathering information than for modifying the values it returns.

@ note (FCNote) the note for which to calculated the tie span
@ [for_tied_to] (boolean) if true, searches for a note tying to the input note. Otherwise, searches for a note tying from the input note.
@ [tie_must_exist] (boolean) if true, only returns notes for ties that already exist.
: (FCNoteLayerEntry) A new FCNoteEntryLayer instance that contains both the following two return values.
: (FCNote) The start note of the tie.
: (FCNote) The end note of the tie.
]]
function tie.calc_tie_span(note, for_tied_to, tie_must_exist)
    local start_measnum = (for_tied_to and note.Entry.Measure > 1) and note.Entry.Measure - 1 or note.Entry.Measure
    local end_measnum = for_tied_to and note.Entry.Measure or note.Entry.Measure + 1
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
    local start_note = for_tied_to and tie.calc_tied_from(note_entry_layer_note, tie_must_exist) or note_entry_layer_note
    local end_note = for_tied_to and note_entry_layer_note or tie.calc_tied_to(note_entry_layer_note, tie_must_exist)
    return note_entry_layer, start_note, end_note
end

--[[
% calc_default_direction

Calculates the default direction of a tie based on context and FCTiePrefs but ignoring multi-voice
and multi-layer overrides. It also does not take into account the direction being overridden in
FCTieMods. Use tie.calc_direction to calculate the actual current tie direction.

@ note (FCNote) the note for which to return the tie direction.
@ for_tieend (boolean) specifies that this request is for a tie_end.
@ [tie_prefs] (FCTiePrefs) use these tie prefs if supplied
: (number) Returns either TIEMODDIR_UNDER or TIEMODDIR_OVER. If the input note has no applicable tie, it returns 0.
]]
function tie.calc_default_direction(note, for_tieend, tie_prefs)
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
    local stemdir = note.Entry:CalcStemUp() and 1 or -1
    if note.Entry.Count > 1 then
        -- This code depends on observed Finale behavior that the notes are always sorted
        -- from lowest-to-highest inside the entry. If Finale's behavior ever changes, this
        -- code is screwed.

        -- If note is outer, tie-direction is unaffected by tie_prefs
        if note.NoteIndex == 0 then
            return finale.TIEMODDIR_UNDER
        end
        if note.NoteIndex == note.Entry.Count - 1 then
            return finale.TIEMODDIR_OVER
        end

        local inner_default = 0

        if tie_prefs.ChordDirectionType ~= finale.TIECHORDDIR_STEMREVERSAL then
            if note.NoteIndex < math.floor(note.Entry.Count / 2) then
                inner_default = finale.TIEMODDIR_UNDER
            end
            if note.NoteIndex >= math.floor((note.Entry.Count + 1) / 2) then
                inner_default = finale.TIEMODDIR_OVER
            end
            if tie_prefs.ChordDirectionType == finale.TIECHORDDIR_OUTSIDEINSIDE then
                inner_default = (stemdir > 0) and finale.TIEMODDIR_UNDER or finale.TIEMODDIR_OVER
            end
        end
        if inner_default == 0 or tie_prefs.ChordDirectionType == finale.TIECHORDDIR_STEMREVERSAL then
            local staff_position = note:CalcStaffPosition()
            local curr_staff = finale.FCCurrentStaffSpec()
            curr_staff:LoadForEntry(note.Entry)
            inner_default = staff_position < curr_staff.StemReversalPosition and finale.TIEMODDIR_UNDER or finale.TIEMODDIR_OVER
        end
        if inner_default ~= 0 then
            if tie_prefs.ChordDirectionOpposingSeconds then
                if inner_default == finale.TIEMODDIR_OVER and not note:IsUpper2nd() and note:IsLower2nd() then
                    return finale.TIEMODDIR_UNDER
                end
                if inner_default == finale.TIEMODDIR_UNDER and note:IsUpper2nd() and not note:IsLower2nd() then
                    return finale.TIEMODDIR_OVER
                end
            end
            return inner_default
        end
    else
        local adjacent_stemdir = 0
        local note_entry_layer, start_note, end_note = tie.calc_tie_span(note, for_tieend, true)
        if for_tieend then
            -- There seems to be a "bug" in how Finale determines mixed-stem values for Tie-Ends.
            -- It looks at the stem direction of the immediately preceding entry, even if that entry
            -- is not the entry that started the tie. Therefore, do not use tied_from_note to
            -- get the stem direction.
            if end_note then
                local start_entry = end_note.Entry:Previous()
                if start_entry then
                    adjacent_stemdir = start_entry:CalcStemUp() and 1 or -1
                end
            end
        else
            if end_note then
                adjacent_stemdir = end_note.Entry:CalcStemUp() and 1 or -1
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
                    adjacent_stemdir = next_entry:CalcStemUp() and 1 or -1
                    if not next_entry.FreezeStem and next_entry.Voice2Launch and adjacent_stemdir == stemdir then
                        next_entry = next_entry:Next()
                        if next_entry then
                            adjacent_stemdir = next_entry:CalcStemUp() and 1 or -1
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

local calc_layer_is_visible = function(staff, layer_number)
    local altnotation_layer = staff.AltNotationLayer
    if layer_number ~= altnotation_layer then
        return staff.AltShowOtherNotes
    end

    local hider_altnotation_types = {
        finale.ALTSTAFF_BLANKNOTATION, finale.ALTSTAFF_SLASHBEATS, finale.ALTSTAFF_ONEBARREPEAT, finale.ALTSTAFF_TWOBARREPEAT, finale.ALTSTAFF_BLANKNOTATIONRESTS,
    }
    local altnotation_type = staff.AltNotationStyle
    for _, v in pairs(hider_altnotation_types) do
        if v == altnotation_type then
            return false
        end
    end

    return true
end

local calc_other_layers_visible = function(entry)
    local staff = finale.FCCurrentStaffSpec()
    staff:LoadForEntry(entry)
    for layer = 1, finale.FCLayerPrefs.GetMaxLayers() do
        if layer ~= entry.LayerNumber and calc_layer_is_visible(staff, layer) then
            local layer_prefs = finale.FCLayerPrefs()
            if layer_prefs:Load(layer - 1) and not layer_prefs.HideWhenInactive then
                local layer_entries = finale.FCNoteEntryLayer(layer - 1, entry.Staff, entry.Measure, entry.Measure)
                if layer_entries:Load() then
                    for layer_entry in each(layer_entries) do
                        if layer_entry.Visible then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local layer_stem_direction = function(layer_prefs, entry)
    if layer_prefs.UseFreezeStemsTies then
        if layer_prefs.UseRestOffsetInMultiple then -- UseRestOffsetInMultiple controls a lot more than just rests
            if not entry:CalcMultiLayeredCell() then
                return 0
            end
            if layer_prefs.IgnoreHiddenNotes and not calc_other_layers_visible(entry) then
                return 0
            end
        end
        return layer_prefs.FreezeStemsUp and 1 or -1
    end
    return 0
end

local layer_tie_direction = function(entry)
    local layer_prefs = finale.FCLayerPrefs()
    if not layer_prefs:Load(entry.LayerNumber - 1) then
        return 0
    end
    local layer_stemdir = layer_stem_direction(layer_prefs, entry)
    if layer_stemdir ~= 0 and layer_prefs.FreezeTiesSameDirection then
        return layer_stemdir > 0 and finale.TIEMODDIR_OVER or finale.TIEMODDIR_UNDER
    end
    return 0
end

--[[
% calc_direction

Calculates the current direction of a tie based on context and FCTiePrefs, taking into account multi-voice
and multi-layer overrides. It also takes into account if the direction has been overridden in
FCTieMods.

@ note (FCNote) the note for which to return the tie direction.
@ tie_mod (FCTieMod) the tie mods for the note, if any.
@ [tie_prefs] (FCTiePrefs) use these tie prefs if supplied
: (number) Returns either TIEMODDIR_UNDER or TIEMODDIR_OVER. If the input note has no applicable tie, it returns 0.
]]
function tie.calc_direction(note, tie_mod, tie_prefs)
    -- much of this code works even if the note doesn't (yet) have a tie, so
    -- skip the check to see if we actually have a tie.
    if tie_mod.TieDirection ~= finale.TIEMODDIR_AUTOMATIC then
        return tie_mod.TieDirection
    end
    if note.Entry.SplitStem then
        return note.UpstemSplit and finale.TIEMODDIR_OVER or finale.TIEMODDIR_UNDER
    end
    local layer_tiedir = layer_tie_direction(note.Entry)
    if layer_tiedir ~= 0 then
        return layer_tiedir
    end
    if note.Entry.Voice2Launch or note.Entry.Voice2 then
        return note.Entry:CalcStemUp() and finale.TIEMODDIR_OVER or finale.TIEMODDIR_UNDER
    end
    if note.Entry.FlipTie then
        return note.Entry:CalcStemUp() and finale.TIEMODDIR_OVER or finale.TIEMODDIR_UNDER
    end

    return tie.calc_default_direction(note, not tie_mod:IsStartTie(), tie_prefs)
end -- function tie.calc_direction

local calc_is_end_of_system = function(note, for_pageview)
    if not note.Entry:Next() then
        local region = finale.FCMusicRegion()
        region:SetFullDocument()
        if note.Entry.Measure == region.EndMeasure then
            return true
        end
    end
    if for_pageview then
        local note_entry_layer, start_note, end_note = tie.calc_tie_span(note, false, true)
        if start_note and end_note then
            local systems = finale.FCStaffSystems()
            systems:LoadAll()
            local start_system = systems:FindMeasureNumber(start_note.Entry.Measure)
            local end_system = systems:FindMeasureNumber(end_note.Entry.Measure)
            return start_system.ItemNo ~= end_system.ItemNo
        end
    end
    return false
end

local has_nonaligned_2nd = function(entry)
    for note in each(entry) do
        if note:IsNonAligned2nd() then
            return true
        end
    end
    return false
end

--[[
% calc_connection_code

Calculates the correct connection code for activating a Tie Placement Start Point or End Point
in FCTieMod.

@ note (FCNote) the note for which to return the code
@ placement (number) one of the TIEPLACEMENT_INDEXES values
@ direction (number) one of the TIEMOD_DIRECTION values
@ for_endpoint (boolean) if true, calculate the end point code, otherwise the start point code
@ for_tieend (boolean) if true, calculate the code for a tie end
@ for_pageview (boolean) if true, calculate the code for page view, otherwise for scroll/studio view
@ [tie_prefs] (FCTiePrefs) use these tie prefs if supplied
: (number) Returns one of TIEMOD_CONNECTION_CODES. If the input note has no applicable tie, it returns TIEMODCNCT_NONE.
]]
function tie.calc_connection_code(note, placement, direction, for_endpoint, for_tieend, for_pageview, tie_prefs)
    -- As of now, I haven't found any use for the connection codes:
    --      TIEMODCNCT_ENTRYCENTER_NOTEBOTTOM
    --      TIEMODCNCT_ENTRYCENTER_NOTETOP
    -- The other 15 are accounted for here. RGP 5/11/2022
    if not tie_prefs then
        tie_prefs = finale.FCTiePrefs()
        tie_prefs:Load(0)
    end
    if not for_endpoint and for_tieend then
        return finale.TIEMODCNCT_SYSTEMSTART
    end
    if for_endpoint and not for_tieend and calc_is_end_of_system(note, for_pageview) then
        return finale.TIEMODCNCT_SYSTEMEND
    end
    if placement == finale.TIEPLACE_OVERINNER or placement == finale.TIEPLACE_UNDERINNER then
        local stemdir = note.Entry:CalcStemUp() and 1 or -1
        if for_endpoint then
            if tie_prefs.BeforeSingleAccidental and note.Entry.Count == 1 and note:CalcAccidental() then
                return finale.TIEMODCNCT_ACCILEFT_NOTECENTER
            end
            if has_nonaligned_2nd(note.Entry) then
                if (stemdir > 0 and direction ~= finale.TIEMODDIR_UNDER and note:IsNonAligned2nd()) or (stemdir < 0 and not note:IsNonAligned2nd()) then
                    return finale.TIEMODCNCT_NOTELEFT_NOTECENTER
                end
            end
            return finale.TIEMODCNCT_ENTRYLEFT_NOTECENTER
        else
            local num_dots = note.Entry:CalcDots()
            if (tie_prefs.AfterSingleDot and num_dots == 1) or (tie_prefs.AfterMultipleDots and num_dots > 1) then
                return finale.TIEMODCNCT_DOTRIGHT_NOTECENTER
            end
            if has_nonaligned_2nd(note.Entry) then
                if (stemdir > 0 and not note:IsNonAligned2nd()) or (stemdir < 0 and direction ~= finale.TIEMODDIR_OVER and note:IsNonAligned2nd()) then
                    return finale.TIEMODCNCT_NOTERIGHT_NOTECENTER
                end
            end
            return finale.TIEMODCNCT_ENTRYRIGHT_NOTECENTER
        end
    elseif placement == finale.TIEPLACE_OVEROUTERNOTE then
        return finale.TIEMODCNCT_NOTECENTER_NOTETOP
    elseif placement == finale.TIEPLACE_UNDEROUTERNOTE then
        return finale.TIEMODCNCT_NOTECENTER_NOTEBOTTOM
    elseif placement == finale.TIEPLACE_OVEROUTERSTEM then
        return for_endpoint and finale.TIEMODCNCT_NOTELEFT_NOTETOP or finale.TIEMODCNCT_NOTERIGHT_NOTETOP
    elseif placement == finale.TIEPLACE_UNDEROUTERSTEM then
        return for_endpoint and finale.TIEMODCNCT_NOTELEFT_NOTEBOTTOM or finale.TIEMODCNCT_NOTERIGHT_NOTEBOTTOM
    end
    return finale.TIEMODCNCT_NONE
end

local calc_placement_for_endpoint = function(note, tie_mod, tie_prefs, direction, stemdir, for_endpoint, end_note_slot, end_num_notes, end_upstem2nd, end_downstem2nd)
    local note_slot = end_note_slot and end_note_slot or note.NoteIndex
    local num_notes = end_num_notes and end_num_notes or note.Entry.Count
    local upstem2nd = end_upstem2nd ~= nil and end_upstem2nd or note.Upstem2nd
    local downstem2nd = end_downstem2nd ~= nil and end_downstem2nd or note.Downstem2nd
    if (note_slot == 0 and direction == finale.TIEMODDIR_UNDER) or (note_slot == num_notes - 1 and direction == finale.TIEMODDIR_OVER) then
        local use_outer = false
        local manual_override = false
        if tie_mod.OuterPlacement ~= finale.TIEMODSEL_DEFAULT then
            manual_override = true
            if tie_mod.OuterPlacement == finale.TIEMODSEL_ON then
                use_outer = true
            end
        end
        if not manual_override and tie_prefs.UseOuterPlacement then
            use_outer = true
        end
        if use_outer then
            if note.Entry.Duration < finale.WHOLE_NOTE then
                if for_endpoint then
                    -- A downstem 2nd is always treated as OuterNote
                    -- An upstem 2nd is always treated as OuterStem
                    if stemdir < 0 and direction == finale.TIEMODDIR_UNDER and not downstem2nd then
                        return finale.TIEPLACE_UNDEROUTERSTEM
                    end
                    if stemdir > 0 and direction == finale.TIEMODDIR_OVER and upstem2nd then
                        return finale.TIEPLACE_OVEROUTERSTEM
                    end
                else
                    -- see comments above and take their opposites
                    if stemdir > 0 and direction == finale.TIEMODDIR_OVER and not upstem2nd then
                        return finale.TIEPLACE_OVEROUTERSTEM
                    end
                    if stemdir < 0 and direction == finale.TIEMODDIR_UNDER and downstem2nd then
                        return finale.TIEPLACE_UNDEROUTERSTEM
                    end
                end
            end
            return direction == finale.TIEMODDIR_UNDER and finale.TIEPLACE_UNDEROUTERNOTE or finale.TIEPLACE_OVEROUTERNOTE
        end
    end
    return direction == finale.TIEMODDIR_UNDER and finale.TIEPLACE_UNDERINNER or finale.TIEPLACE_OVERINNER
end

--[[
% calc_placement

Calculates the current placement of a tie based on context and FCTiePrefs.

@ note (FCNote) the note for which to return the tie direction.
@ tie_mod (FCTieMod) the tie mods for the note, if any.
@ for_pageview (bool) true if calculating for Page View, false for Scroll/Studio View
@ direction (number) one of the TIEMOD_DIRECTION values or nil (if you don't know it yet)
@ [tie_prefs] (FCTiePrefs) use these tie prefs if supplied
: (number) TIEPLACEMENT_INDEXES value for start point
: (number) TIEPLACEMENT_INDEXES value for end point
]]
function tie.calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)
    if not tie_prefs then
        tie_prefs = finale.FCTiePrefs()
        tie_prefs:Load(0)
    end
    direction = direction and direction ~= finale.TIEMODDIR_AUTOMATIC and direction or tie.calc_direction(note, tie_mod, tie_prefs)
    local stemdir = note.Entry:CalcStemUp() and 1 or -1
    local start_placement, end_placement
    if not tie_mod:IsStartTie() then
        start_placement = calc_placement_for_endpoint(note, tie_mod, tie_prefs, direction, stemdir, false)
        end_placement = calc_placement_for_endpoint(note, tie_mod, tie_prefs, direction, stemdir, true)
    else
        start_placement = calc_placement_for_endpoint(note, tie_mod, tie_prefs, direction, stemdir, false)
        end_placement = start_placement -- initialize it with something
        local note_entry_layer, start_note, end_note = tie.calc_tie_span(note, false, true)
        if end_note then
            local next_stemdir = end_note.Entry:CalcStemUp() and 1 or -1
            end_placement = calc_placement_for_endpoint(end_note, tie_mod, tie_prefs, direction, next_stemdir, true)
        else
            -- more reverse-engineered logic. Here is the observed Finale behavior:
            -- 1. Ties to rests and nothing have StemOuter placement at their endpoint.
            -- 2. Ties to an adjacent empty bar have inner placement on both ends. (weird but true)
            -- 3. Ties to notes are Inner if the down-tied-to entry has a note that is lower or
            --			an up-tied-to entry has a note that is higher.
            --			The flakiest behavior is with with under-ties to downstem chords containing 2nds.
            --			In this case, we must pass in the UPSTEM 2nd bit or'ed from all notes in the chord.
            local next_entry = start_note.Entry:Next() -- start_note is from note_entry_layer, which includes the next bar
            if next_entry then
                if not next_entry:IsRest() and next_entry.Count > 0 then
                    if direction == finale.TIEMODDIR_UNDER then
                        local next_note = next_entry:GetItemAt(0)
                        if next_note.Displacment < note.Displacement then
                            end_placement = finale.TIEPLACE_UNDERINNER
                        else
                            local next_stemdir = next_entry:CalcStemUp() and 1 or -1
                            end_placement = calc_placement_for_endpoint(next_note, tie_mod, tie_prefs, direction, next_stemdir, true)
                        end
                    else
                        local next_note = next_entry:GetItemAt(next_entry.Count - 1)
                        if next_note.Displacment > note.Displacement then
                            end_placement = finale.TIEPLACE_OVERINNER
                        else
                            -- flaky behavior alert: this code might not work in a future release but
                            -- so far it it has held up. This is the Finale 2000 behavior.
                            -- If the entry is downstem, OR together all the Upstem 2nd bits.
                            -- Finale is so flaky that it does not do this for Scroll View at less than 130%.
                            -- However, it seems to do it consistently in Page View.
                            local upstem2nd = next_note.Upstem2nd
                            if next_entry:CalcStemUp() then
                                for check_note in each(next_entry) do
                                    if check_note.Upstem2nd then
                                        upstem2nd = true
                                    end
                                end
                                local next_stemdir = direction == finale.TIEMODDIR_UNDER and -1 or 1
                                end_placement = calc_placement_for_endpoint(
                                                    next_note, tie_mod, tie_prefs, direction, next_stemdir, true, next_note.NoteIndex, next_entry.Count, upstem2nd,
                                                    next_note.Downstem2nd)
                            end
                        end
                    end
                else
                    local next_stemdir = direction == finale.TIEMODDIR_UNDER and -1 or 1
                    end_placement = calc_placement_for_endpoint(note, tie_mod, tie_prefs, direction, next_stemdir, true, note.NoteIndex, note.Entry.Count, false, false)
                end
            else
                if calc_is_end_of_system(note, for_pageview) then
                    end_placement = direction == finale.TIEMODDIR_UNDER and finale.TIEPLACE_UNDEROUTERSTEM or finale.TIEPLACE_OVEROUTERSTEM
                else
                    end_placement = direction == finale.TIEMODDIR_UNDER and finale.TIEPLACE_UNDERINNER or finale.TIEPLACE_OVERINNER
                end
            end
        end
    end

    -- if either of the endpoints is inner, make both of them inner.
    if start_placement == finale.TIEPLACE_OVERINNER or start_placement == finale.TIEPLACE_UNDERINNER then
        end_placement = start_placement
    elseif end_placement == finale.TIEPLACE_OVERINNER or end_placement == finale.TIEPLACE_UNDERINNER then
        start_placement = end_placement
    end

    return start_placement, end_placement
end

local calc_prefs_offset_for_endpoint = function(note, tie_prefs, tie_placement_prefs, placement, for_endpoint, for_tieend, for_pageview)
    local tie_
    if for_endpoint then
        if calc_is_end_of_system(note, for_pageview) then
            return tie_prefs.SystemRightHorizontalOffset, tie_placement_prefs:GetVerticalEnd(placement)
        end
        return tie_placement_prefs:GetHorizontalEnd(placement), tie_placement_prefs:GetVerticalEnd(placement)
    end
    if for_tieend then
        return tie_prefs.SystemLeftHorizontalOffset, tie_placement_prefs:GetVerticalStart(placement)
    end
    return tie_placement_prefs:GetHorizontalStart(placement), tie_placement_prefs:GetVerticalStart(placement)
end

local activate_endpoint = function(note, tie_mod, placement, direction, for_endpoint, for_pageview, tie_prefs, tie_placement_prefs)
    local active_check_func = for_endpoint and tie_mod.IsEndPointActive or tie_mod.IsStartPointActive
    if active_check_func(tie_mod) then
        return false
    end
    local for_tieend = not tie_mod:IsStartTie()
    local connect = tie.calc_connection_code(note, placement, direction, for_endpoint, for_tieend, for_pageview, tie_prefs)
    local xoffset, yoffset = calc_prefs_offset_for_endpoint(note, tie_prefs, tie_placement_prefs, placement, for_endpoint, for_tieend, for_pageview)
    local activation_func = for_endpoint and tie_mod.ActivateEndPoint or tie_mod.ActivateStartPoint
    activation_func(tie_mod, direction == finale.TIEMODDIR_OVER, connect, xoffset, yoffset)
    return true
end

--[[
% activate_endpoints

Activates the placement endpoints of the input tie_mod and initializes them with their
default values. If an endpoint is already activated, that endpoint is not touched.

@ note (FCNote) the note for which to return the tie direction.
@ tie_mod (FCTieMod) the tie mods for the note, if any.
@ for_pageview (bool) true if calculating for Page View, false for Scroll/Studio View
@ [tie_prefs] (FCTiePrefs) use these tie prefs if supplied
: (boolean) returns true if anything changed
]]
function tie.activate_endpoints(note, tie_mod, for_pageview, tie_prefs)
    if not tie_prefs then
        tie_prefs = finale.FCTiePrefs()
        tie_prefs:Load(0)
    end
    local tie_placement_prefs = tie_prefs:CreateTiePlacementPrefs()
    local direction = tie.calc_direction(note, tie_mod, tie_prefs)
    local lplacement, rplacement = tie.calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)
    local lactivated = activate_endpoint(note, tie_mod, lplacement, direction, false, for_pageview, tie_prefs, tie_placement_prefs)
    local ractivated = activate_endpoint(note, tie_mod, rplacement, direction, true, for_pageview, tie_prefs, tie_placement_prefs)
    if lactivated and ractivated then
        tie_mod:LocalizeFromPreferences()
    end
    return lactivated or ractivated
end

local calc_tie_length = function(note, tie_mod, for_pageview, direction, tie_prefs, tie_placement_prefs)
    local cell_metrics_start = finale.FCCellMetrics()
    local entry_metrics_start = finale.FCEntryMetrics()
    cell_metrics_start:LoadAtEntry(note.Entry)
    entry_metrics_start:Load(note.Entry)

    local cell_metrics_end = finale.FCCellMetrics()
    local entry_metrics_end = finale.FCEntryMetrics()
    local note_entry_layer, start_note, end_note = tie.calc_tie_span(note, false, true)
    if tie_mod:IsStartTie() then
        if end_note then
            cell_metrics_end:LoadAtEntry(end_note.Entry)
            entry_metrics_end:Load(end_note.Entry)
        end
    end

    local lplacement, rplacement = tie.calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)
    local horz_start = 0
    local horz_end = 0
    local incr_start = 0
    local incr_end = 0

    -- the following default locations are empirically determined.
    local OUTER_NOTE_OFFSET_PCTG = 7.0 / 16.0
    local INNER_INCREMENT = 6

    local staff_scaling = cell_metrics_start.StaffScaling / 10000.0
    local horz_stretch = for_pageview and 1 or cell_metrics_start.HorizontalStretch / 10000.0

    if tie_mod:IsStartTie() then
        horz_start = entry_metrics_start:GetNoteLeftPosition(note.NoteIndex) / horz_stretch
        if lplacement == finale.TIEPLACE_OVERINNER or lplacement == finale.TIEPLACE_OVEROUTERSTEM or lplacement == finale.TIEPLACE_UNDERINNER then
            horz_start = horz_start + entry_metrics_start:GetNoteWidth(note.NoteIndex)
            incr_start = INNER_INCREMENT
        else
            horz_start = horz_start + (entry_metrics_start:GetNoteWidth(note.NoteIndex) * OUTER_NOTE_OFFSET_PCTG)
        end
    else
        horz_start = (cell_metrics_start.MusicStartPos * staff_scaling) / horz_stretch
    end

    if tie_mod:IsStartTie() and (not end_note or cell_metrics_start.StaffSystem ~= cell_metrics_end.StaffSystem) then
        local next_cell_metrics = finale.FCCellMetrics()
        local next_metrics_loaded = next_cell_metrics:LoadAtCell(finale.FCCell(note.Entry.Measure + 1, note.Entry.Staff))
        if not next_metrics_loaded or cell_metrics_start.StaffSystem ~= cell_metrics_end.StaffSystem then
            -- note: a tie to an empty measure on the same system will get here, but
            -- currently we do not correctly calculate its span. To do so we would have to
            -- read the measure separations from the prefs.
            horz_end = (cell_metrics_start.MusicStartPos + cell_metrics_start.Width) * staff_scaling
            incr_end = cell_metrics_start.RightBarlineWidth
        else
            horz_end = next_cell_metrics.MusicStartPos * staff_scaling
        end
        horz_end = horz_end / horz_stretch
    else
        local entry_metrics = tie_mod:IsStartTie() and entry_metrics_end or entry_metrics_start
        local note_index = start_note.NoteIndex
        if end_note then
            -- if tie_mod:IsStartTie() is true, then end_note will never be nil here (see top if statement),
            -- but the Lua delinter can't figure it out, so use an explicit if statement for end_note.
            note_index = tie_mod:IsStartTie() and end_note.NoteIndex or note_index
        end
        horz_end = entry_metrics:GetNoteLeftPosition(note_index) / horz_stretch
        if rplacement == finale.TIEPLACE_OVERINNER or rplacement == finale.TIEPLACE_UNDERINNER or rplacement == finale.TIEPLACE_UNDEROUTERSTEM then
            incr_end = -INNER_INCREMENT
        else
            horz_end = horz_end + (entry_metrics_start:GetNoteWidth(note.NoteIndex) * (1.0 - OUTER_NOTE_OFFSET_PCTG))
        end
    end

    local start_offset = tie_mod.StartHorizontalPos
    if not tie_mod:IsStartPointActive() then
        start_offset = calc_prefs_offset_for_endpoint(note, tie_prefs, tie_placement_prefs, lplacement, false, not tie_mod:IsStartTie(), for_pageview)
    end
    local end_offset = tie_mod.EndHorizontalPos
    if not tie_mod:IsEndPointActive() then
        end_offset = calc_prefs_offset_for_endpoint(note, tie_prefs, tie_placement_prefs, lplacement, true, not tie_mod:IsStartTie(), for_pageview)
    end

    local tie_length = horz_end - horz_start
    -- 'undo' page/sys/line % scaling to get absolute EVPUs.
    tie_length = tie_length / staff_scaling
    tie_length = tie_length + ((end_offset + incr_end) - (start_offset + incr_start))
    return math.floor(tie_length + 0.5)
end

--[[
% calc_contour_index

Calculates the current contour index of a tie based on context and FCTiePrefs.

@ note (FCNote) the note for which to return the tie direction.
@ tie_mod (FCTieMod) the tie mods for the note, if any.
@ for_pageview (bool) true if calculating for Page View, false for Scroll/Studio View
@ direction (number) one of the TIEMOD_DIRECTION values or nil (if you don't know it yet)
@ [tie_prefs] (FCTiePrefs) use these tie prefs if supplied
: (number) CONTOUR_INDEXES value for tie
: (number) calculated length of tie in EVPU
]]
function tie.calc_contour_index(note, tie_mod, for_pageview, direction, tie_prefs)
    if not tie_prefs then
        tie_prefs = finale.FCTiePrefs()
        tie_prefs:Load(0)
    end
    direction = direction and direction ~= finale.TIEMODDIR_AUTOMATIC and direction or tie.calc_direction(note, tie_mod, tie_prefs)
    local tie_placement_prefs = tie_prefs:CreateTiePlacementPrefs()
    if tie_prefs.UseTieEndStyle then
        return finale.TCONTOURIDX_TIEENDS
    end
    local tie_length = calc_tie_length(note, tie_mod, for_pageview, direction, tie_prefs, tie_placement_prefs)
    local tie_contour_prefs = tie_prefs:CreateTieContourPrefs()
    if tie_length >= tie_contour_prefs:GetSpan(finale.TCONTOURIDX_LONG) then
        return finale.TCONTOURIDX_LONG
    elseif tie_length <= tie_contour_prefs:GetSpan(finale.TCONTOURIDX_SHORT) then
        return finale.TCONTOURIDX_SHORT
    end
    return finale.TCONTOURIDX_MEDIUM, tie_length
end

local calc_inset_and_height = function(tie_prefs, tie_contour_prefs, length, contour_index, get_fixed_func, get_relative_func, get_height_func)
    -- This function is based on observed Finale behavior and may not precisely capture the exact same interpolated values.
    -- However, it appears that Finale interpolates from Short to Medium for lengths in that span and from Medium to Long
    -- for lengths in that span.
    local height = get_height_func(tie_contour_prefs, contour_index)
    local inset = tie_prefs.FixedInsetStyle and get_fixed_func(tie_contour_prefs, contour_index) or get_relative_func(tie_contour_prefs, contour_index)
    if tie_prefs.UseInterpolation and contour_index == finale.TCONTOURIDX_MEDIUM then
        local interpolation_length, interpolation_percent, interpolation_height_diff, interpolation_inset_diff
        if length < tie_contour_prefs:GetSpan(finale.TCONTOURIDX_MEDIUM) then
            interpolation_length = tie_contour_prefs:GetSpan(finale.TCONTOURIDX_MEDIUM) - tie_contour_prefs:GetSpan(finale.TCONTOURIDX_SHORT)
            interpolation_percent = (interpolation_length - tie_contour_prefs:GetSpan(finale.TCONTOURIDX_MEDIUM) + length) / interpolation_length
            interpolation_height_diff = get_height_func(tie_contour_prefs, finale.TCONTOURIDX_MEDIUM) - get_height_func(tie_contour_prefs, finale.TCONTOURIDX_SHORT)
            interpolation_inset_diff = get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_MEDIUM) - get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_SHORT)
            height = get_height_func(tie_contour_prefs, finale.TCONTOURIDX_SHORT)
            if not tie_prefs.FixedInsetStyle then
                inset = get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_SHORT)
            end
        else
            interpolation_length = tie_contour_prefs:GetSpan(finale.TCONTOURIDX_LONG) - tie_contour_prefs:GetSpan(finale.TCONTOURIDX_MEDIUM)
            interpolation_percent = (interpolation_length - tie_contour_prefs:GetSpan(finale.TCONTOURIDX_LONG) + length) / interpolation_length
            interpolation_height_diff = get_height_func(tie_contour_prefs, finale.TCONTOURIDX_LONG) - get_height_func(tie_contour_prefs, finale.TCONTOURIDX_MEDIUM)
            interpolation_inset_diff = get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_LONG) - get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_MEDIUM)
        end
        height = math.floor(0.5 + height + interpolation_height_diff * interpolation_percent)
        if not tie_prefs.FixedInsetStyle then
            inset = math.floor(0.5 + inset + interpolation_inset_diff * interpolation_percent)
        end
    end
    return inset, height
end

--[[
% activate_contour

Activates the contour fields of the input tie_mod and initializes them with their
default values. If the contour fields are already activated, nothing is changed. Note
that for interpolated Medium span types, the interpolated values may not be identical
to those calculated by Finale, but they should be close enough to make no appreciable
visible difference.

@ note (FCNote) the note for which to return the tie direction.
@ tie_mod (FCTieMod) the tie mods for the note, if any.
@ for_pageview (bool) true if calculating for Page View, false for Scroll/Studio View
@ [tie_prefs] (FCTiePrefs) use these tie prefs if supplied
: (boolean) returns true if anything changed
]]
function tie.activate_contour(note, tie_mod, for_pageview, tie_prefs)
    if tie_mod:IsContourActive() then
        return false
    end
    if not tie_prefs then
        tie_prefs = finale.FCTiePrefs()
        tie_prefs:Load(0)
    end
    local direction = tie.calc_direction(note, tie_mod, tie_prefs)
    local tie_contour_index, length = tie.calc_contour_index(note, tie_mod, for_pageview, direction, tie_prefs)
    local tie_contour_prefs = tie_prefs:CreateTieContourPrefs()
    local left_inset, left_height = calc_inset_and_height(
                                        tie_prefs, tie_contour_prefs, length, tie_contour_index, tie_contour_prefs.GetLeftFixedInset, tie_contour_prefs.GetLeftRawRelativeInset,
                                        tie_contour_prefs.GetLeftHeight)
    local right_inset, right_height = calc_inset_and_height(
                                          tie_prefs, tie_contour_prefs, length, tie_contour_index, tie_contour_prefs.GetRightFixedInset, tie_contour_prefs.GetRightRawRelativeInset,
                                          tie_contour_prefs.GetRightHeight)
    tie_mod:ActivateContour(left_inset, left_height, right_inset, right_height, tie_prefs.FixedInsetStyle)
    return true
end

return tie

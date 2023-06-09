package.preload["library.note_entry"] = package.preload["library.note_entry"] or function()

    local note_entry = {}

    function note_entry.get_music_region(entry)
        local exp_region = finale.FCMusicRegion()
        exp_region:SetCurrentSelection()
        exp_region.StartStaff = entry.Staff
        exp_region.EndStaff = entry.Staff
        exp_region.StartMeasure = entry.Measure
        exp_region.EndMeasure = entry.Measure
        exp_region.StartMeasurePos = entry.MeasurePos
        exp_region.EndMeasurePos = entry.MeasurePos
        return exp_region
    end


    local use_or_get_passed_in_entry_metrics = function(entry, entry_metrics)
        if entry_metrics then
            return entry_metrics, false
        end
        entry_metrics = finale.FCEntryMetrics()
        if entry_metrics:Load(entry) then
            return entry_metrics, true
        end
        return nil, false
    end

    function note_entry.get_evpu_notehead_height(entry)
        local highest_note = entry:CalcHighestNote(nil)
        local lowest_note = entry:CalcLowestNote(nil)
        local evpu_height = (2 + highest_note:CalcStaffPosition() - lowest_note:CalcStaffPosition()) * 12
        return evpu_height
    end

    function note_entry.get_top_note_position(entry, entry_metrics)
        local retval = -math.huge
        local loaded_here = false
        entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
        if nil == entry_metrics then
            return retval
        end
        if not entry:CalcStemUp() then
            retval = entry_metrics.TopPosition
        else
            local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
            if nil ~= cell_metrics then
                local evpu_height = note_entry.get_evpu_notehead_height(entry)
                local scaled_height = math.floor(((cell_metrics.StaffScaling * evpu_height) / 10000) + 0.5)
                retval = entry_metrics.BottomPosition + scaled_height
                cell_metrics:FreeMetrics()
            end
        end
        if loaded_here then
            entry_metrics:FreeMetrics()
        end
        return retval
    end

    function note_entry.get_bottom_note_position(entry, entry_metrics)
        local retval = math.huge
        local loaded_here = false
        entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
        if nil == entry_metrics then
            return retval
        end
        if entry:CalcStemUp() then
            retval = entry_metrics.BottomPosition
        else
            local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
            if nil ~= cell_metrics then
                local evpu_height = note_entry.get_evpu_notehead_height(entry)
                local scaled_height = math.floor(((cell_metrics.StaffScaling * evpu_height) / 10000) + 0.5)
                retval = entry_metrics.TopPosition - scaled_height
                cell_metrics:FreeMetrics()
            end
        end
        if loaded_here then
            entry_metrics:FreeMetrics()
        end
        return retval
    end

    function note_entry.calc_widths(entry)
        local left_width = 0
        local right_width = 0
        for note in each(entry) do
            local note_width = note:CalcNoteheadWidth()
            if note_width > 0 then
                if note:CalcRightsidePlacement() then
                    if note_width > right_width then
                        right_width = note_width
                    end
                else
                    if note_width > left_width then
                        left_width = note_width
                    end
                end
            end
        end
        return left_width, right_width
    end




    function note_entry.calc_left_of_all_noteheads(entry)
        if entry:CalcStemUp() then
            return 0
        end
        local left, right = note_entry.calc_widths(entry)
        return -left
    end

    function note_entry.calc_left_of_primary_notehead(entry)
        return 0
    end

    function note_entry.calc_center_of_all_noteheads(entry)
        local left, right = note_entry.calc_widths(entry)
        local width_centered = (left + right) / 2
        if not entry:CalcStemUp() then
            width_centered = width_centered - left
        end
        return width_centered
    end

    function note_entry.calc_center_of_primary_notehead(entry)
        local left, right = note_entry.calc_widths(entry)
        if entry:CalcStemUp() then
            return left / 2
        end
        return right / 2
    end

    function note_entry.calc_stem_offset(entry)
        if not entry:CalcStemUp() then
            return 0
        end
        local left, right = note_entry.calc_widths(entry)
        return left
    end

    function note_entry.calc_right_of_all_noteheads(entry)
        local left, right = note_entry.calc_widths(entry)
        if entry:CalcStemUp() then
            return left + right
        end
        return right
    end

    function note_entry.calc_note_at_index(entry, note_index)
        local x = 0
        for note in each(entry) do
            if x == note_index then
                return note
            end
            x = x + 1
        end
        return nil
    end

    function note_entry.stem_sign(entry)
        if entry:CalcStemUp() then
            return 1
        end
        return -1
    end

    function note_entry.duplicate_note(note)
        local new_note = note.Entry:AddNewNote()
        if nil ~= new_note then
            new_note.Displacement = note.Displacement
            new_note.RaiseLower = note.RaiseLower
            new_note.Tie = note.Tie
            new_note.TieBackwards = note.TieBackwards
        end
        return new_note
    end

    function note_entry.delete_note(note)
        local entry = note.Entry
        if nil == entry then
            return false
        end

        finale.FCAccidentalMod():EraseAt(note)
        finale.FCCrossStaffMod():EraseAt(note)
        finale.FCDotMod():EraseAt(note)
        finale.FCNoteheadMod():EraseAt(note)
        finale.FCPercussionNoteMod():EraseAt(note)
        finale.FCTablatureNoteMod():EraseAt(note)
        finale.FCPerformanceMod():EraseAt(note)
        if finale.FCTieMod then
            finale.FCTieMod(finale.TIEMODTYPE_TIESTART):EraseAt(note)
            finale.FCTieMod(finale.TIEMODTYPE_TIEEND):EraseAt(note)
        end
        return entry:DeleteNote(note)
    end

    function note_entry.make_rest(entry)
        local articulations = entry:CreateArticulations()
        for articulation in each(articulations) do
            articulation:DeleteData()
        end
        if entry:IsNote() then
            while entry.Count > 0 do
                note_entry.delete_note(entry:GetItemAt(0))
            end
        end
        entry:MakeRest()
        return true
    end

    function note_entry.calc_pitch_string(note)
        local pitch_string = finale.FCString()
        local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
        local key_signature = cell:GetKeySignature()
        note:GetString(pitch_string, key_signature, false, false)
        return pitch_string
    end

    function note_entry.calc_spans_number_of_octaves(entry)
        local top_note = entry:CalcHighestNote(nil)
        local bottom_note = entry:CalcLowestNote(nil)
        local displacement_diff = top_note.Displacement - bottom_note.Displacement
        local num_octaves = math.ceil(displacement_diff / 7)
        return num_octaves
    end

    function note_entry.add_augmentation_dot(entry)

        entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
    end

    function note_entry.remove_augmentation_dot(entry)
        if entry.Duration <= 0 then
            return false
        end
        local lowest_order_bit = 1
        if bit32.band(entry.Duration, lowest_order_bit) == 0 then

            lowest_order_bit = bit32.bxor(bit32.band(entry.Duration, entry.Duration - 1), entry.Duration)
        end

        local new_value = bit32.band(entry.Duration, bit32.bnot(lowest_order_bit))
        if new_value ~= 0 then
            entry.Duration = new_value
            return true
        end
        return false
    end

    function note_entry.get_next_same_v(entry)
        local next_entry = entry:Next()
        if entry.Voice2 then
            if (nil ~= next_entry) and next_entry.Voice2 then
                return next_entry
            end
            return nil
        end
        if entry.Voice2Launch then
            while (nil ~= next_entry) and next_entry.Voice2 do
                next_entry = next_entry:Next()
            end
        end
        return next_entry
    end

    function note_entry.hide_stem(entry)
        local stem = finale.FCCustomStemMod()
        stem:SetNoteEntry(entry)
        stem:UseUpStemData(entry:CalcStemUp())
        if stem:LoadFirst() then
            stem.ShapeID = 0
            stem:Save()
        else
            stem.ShapeID = 0
            stem:SaveNew()
        end
    end

    function note_entry.rest_offset(entry, offset)
        if entry:IsNote() then
            return false
        end
        local rest_prop = "OtherRestPosition"
        if entry.Duration >= finale.BREVE then
            rest_prop = "DoubleWholeRestPosition"
        elseif entry.Duration >= finale.WHOLE_NOTE then
            rest_prop = "WholeRestPosition"
        elseif entry.Duration >= finale.HALF_NOTE then
            rest_prop = "HalfRestPosition"
        end
        entry:MakeMovableRest()
        local rest = entry:GetItemAt(0)
        local curr_staffpos = rest:CalcStaffPosition()
        local staff_spec = finale.FCCurrentStaffSpec()
        staff_spec:LoadForEntry(entry)
        local total_offset = staff_spec[rest_prop] + offset - curr_staffpos
        entry:SetRestDisplacement(entry:GetRestDisplacement() + total_offset)
        return true
    end
    return note_entry
end
package.preload["library.tie"] = package.preload["library.tie"] or function()

    local tie = {}
    local note_entry = require('library.note_entry')

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
    end
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
            if layer_prefs.UseRestOffsetInMultiple then
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

    function tie.calc_direction(note, tie_mod, tie_prefs)


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
    end
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

    function tie.calc_connection_code(note, placement, direction, for_endpoint, for_tieend, for_pageview, tie_prefs)




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


                        if stemdir < 0 and direction == finale.TIEMODDIR_UNDER and not downstem2nd then
                            return finale.TIEPLACE_UNDEROUTERSTEM
                        end
                        if stemdir > 0 and direction == finale.TIEMODDIR_OVER and upstem2nd then
                            return finale.TIEPLACE_OVEROUTERSTEM
                        end
                    else

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
            end_placement = start_placement
            local note_entry_layer, start_note, end_note = tie.calc_tie_span(note, false, true)
            if end_note then
                local next_stemdir = end_note.Entry:CalcStemUp() and 1 or -1
                end_placement = calc_placement_for_endpoint(end_note, tie_mod, tie_prefs, direction, next_stemdir, true)
            else







                local next_entry = start_note.Entry:Next()
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

        tie_length = tie_length / staff_scaling
        tie_length = tie_length + ((end_offset + incr_end) - (start_offset + incr_start))
        return math.floor(tie_length + 0.5)
    end

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
end
function plugindef()


  finaleplugin.Author = "Jacob Winkler"
  finaleplugin.Copyright = "2022"
  finaleplugin.Version = "1.0.1"
  finaleplugin.Date = "2022-08-26"
  finaleplugin.RequireSelection = true
  finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/ties_remove_dangling.hash"
  return "Ties: Remove Dangling", "Ties: Remove Dangling", "Removes dangling ties (ties that go nowhere)."
end
local tie = require("library.tie")
local music_region = finale.FCMusicRegion()
music_region:SetCurrentSelection()
for working_staff = music_region:GetStartStaff(), music_region:GetEndStaff() do
  for layer_num = 0, 3, 1 do
    local current_note
    local note_entry_layer = finale.FCNoteEntryLayer(layer_num, working_staff, music_region.StartMeasure, music_region.EndMeasure)
    note_entry_layer:Load()
    for index = 0, note_entry_layer.Count-1, 1 do
      local entry = note_entry_layer:GetRegionItemAt(index, music_region)
      if entry and entry:IsTied() then
          for note in each(entry) do
              local tie_must_exist = true
              local tied_note = tie.calc_tied_to(note, tie_must_exist)
              if not tied_note then
                  note.Tie = false
              end
          end
      end
    end
    note_entry_layer:Save()
  end
end
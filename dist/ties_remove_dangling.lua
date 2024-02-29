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
        local loaded_here
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
        local loaded_here
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
        local left, _ = note_entry.calc_widths(entry)
        return -left
    end

    function note_entry.calc_left_of_primary_notehead(_entry)
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
        local left, _ = note_entry.calc_widths(entry)
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
            if equal_note(entry, note, false, tie_must_exist) then
                return true
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
            local _, start_note, end_note = tie.calc_tie_span(note, for_tieend, true)
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
            end
            if adjacent_stemdir ~= 0 and adjacent_stemdir ~= stemdir then
                if tie_prefs.MixedStemDirectionType == finale.TIEMIXEDSTEM_OVER then
                    return finale.TIEMODDIR_OVER
                elseif tie_prefs.MixedStemDirectionType == finale.TIEMIXEDSTEM_UNDER then
                    return finale.TIEMODDIR_UNDER
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
            local _, start_note, end_note = tie.calc_tie_span(note, false, true)
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
            local _, start_note, end_note = tie.calc_tie_span(note, false, true)
            if end_note then
                local next_stemdir = end_note.Entry:CalcStemUp() and 1 or -1
                end_placement = calc_placement_for_endpoint(end_note, tie_mod, tie_prefs, direction, next_stemdir, true)
            elseif start_note then







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
        local _, start_note, end_note = tie.calc_tie_span(note, false, true)
        if tie_mod:IsStartTie() then
            if end_note then
                cell_metrics_end:LoadAtEntry(end_note.Entry)
                entry_metrics_end:Load(end_note.Entry)
            end
        end
        local lplacement, rplacement = tie.calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)
        local horz_start, horz_end
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
        elseif start_note then
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
package.preload["library.smartshape"] = package.preload["library.smartshape"] or function()

    local smartshape = {}
    local smartshape_type = {
        ["slurauto"] = finale.SMARTSHAPE_SLURAUTO,
        ["slur_auto"] = finale.SMARTSHAPE_SLURAUTO,
        ["autoslur"] = finale.SMARTSHAPE_SLURAUTO,
        ["auto_slur"] = finale.SMARTSHAPE_SLURAUTO,
        ["slur"] = finale.SMARTSHAPE_SLURAUTO,
        ["slurdown"] = finale.SMARTSHAPE_SLURDOWN,
        ["slur_down"] = finale.SMARTSHAPE_SLURDOWN,
        ["slurup"] = finale.SMARTSHAPE_SLURUP,
        ["slur_up"] = finale.SMARTSHAPE_SLURUP,
        ["dashed"] = finale.SMARTSHAPE_DASHEDSLURAUTO,
        ["dashedslur"] = finale.SMARTSHAPE_DASHEDSLURAUTO,
        ["dashed_slur"] = finale.SMARTSHAPE_DASHEDSLURAUTO,
        ["dashedslurdown"] = finale.SMARTSHAPE_DASHEDSLURDOWN,
        ["dashedslurup"] = finale.SMARTSHAPE_DASHEDSLURDOWN,
        ["dashedcurve"] = finale.SMARTSHAPE_DASHCURVEAUTO,
        ["dashed_curve"] = finale.SMARTSHAPE_DASHCURVEAUTO,
        ["curve"] = finale.SMARTSHAPE_DASHCURVEAUTO,
        ["dashedcurvedown"] = finale.SMARTSHAPE_DASHCURVEDOWN,
        ["dashedcurveup"] = finale.SMARTSHAPE_DASHCURVEUP,
        ["tabslide"] = finale.SMARTSHAPE_TABSLIDE,
        ["tab"] = finale.SMARTSHAPE_TABSLIDE,
        ["slide"] = finale.SMARTSHAPE_TABSLIDE,
        ["glissando"] = finale.SMARTSHAPE_GLISSANDO,
        ["gliss"] = finale.SMARTSHAPE_GLISSANDO,
        ["bendhat"] = finale.SMARTSHAPE_BEND_HAT,
        ["bend_hat"] = finale.SMARTSHAPE_BEND_HAT,
        ["hat"] = finale.SMARTSHAPE_BEND_HAT,
        ["bend"] = finale.SMARTSHAPE_BEND_HAT,
        ["bendcurve"] = finale.SMARTSHAPE_BEND_CURVE,
        ["bend_curve"] = finale.SMARTSHAPE_BEND_CURVE
    }

    function smartshape.add_entry_based_smartshape(start_note, end_note, shape_type)
        local smartshape = finale.FCSmartShape()
        smartshape:SetEntryAttachedFlags(true)
        local shape
        if shape_type and type(shape_type) == "number" and shape_type <= finale.SMARTSHAPE_DASHEDSLURAUTO then
            shape = shape_type
        else
            shape_type = shape_type or "slur"
            shape = smartshape_type[string.lower(shape_type)]
        end
        smartshape:SetShapeType(shape)
        smartshape.PresetShape = true
        if smartshape:IsAutoSlur() then
            smartshape:SetSlurFlags(true)
            smartshape:SetEngraverSlur(finale.SS_AUTOSTATE)
        end

        local left_segment = smartshape:GetTerminateSegmentLeft()
        local right_segment = smartshape:GetTerminateSegmentRight()

        left_segment:SetEntry(start_note)
        left_segment:SetStaff(start_note.Staff)
        left_segment:SetMeasure(start_note.Measure)

        right_segment:SetEntry(end_note)
        right_segment:SetStaff(end_note.Staff)
        right_segment:SetMeasure(end_note.Measure)
        if (shape == finale.SMARTSHAPE_TABSLIDE) or (shape == finale.SMARTSHAPE_GLISSANDO) then
            if shape == finale.SMARTSHAPE_GLISSANDO then
                smartshape.LineID = 1
            elseif shape == finale.SMARTSHAPE_TABSLIDE then
                smartshape.LineID = 2
            end

            left_segment.NoteID = 1
            right_segment.NoteID = 1
            right_segment:SetCustomOffset(true)
            local accidentals = 0
            local start_note_staff_pos = 0
            local end_note_staff_pos = 0
            local offset_y_add = 4
            local offset_x_add = 12
            for note in each(start_note) do
                if note.NoteID == 1 then
                    start_note_staff_pos = note:CalcStaffPosition()
                end
            end

            for note in each(end_note) do
                if note:CalcAccidental() then
                    accidentals = accidentals + 1
                end
                if note.NoteID == 1 then
                    end_note_staff_pos = note:CalcStaffPosition()
                end
            end
            local staff_pos_difference = start_note_staff_pos - end_note_staff_pos
            if accidentals > 0 then
                offset_x_add = offset_x_add + 28
            end
            right_segment:SetEndpointOffsetX(right_segment.EndpointOffsetX - offset_x_add)
            right_segment:SetEndpointOffsetY(right_segment.EndpointOffsetY + offset_y_add + (staff_pos_difference/2))
        end
        smartshape:SaveNewEverything(start_note, end_note)
    end

    function smartshape.delete_entry_based_smartshape(music_region, shape_type)
        local shape
        if shape_type and type(shape_type) == "number" and shape_type <= finale.SMARTSHAPE_DASHEDSLURAUTO then
            shape = shape_type
        else
            shape_type = shape_type or "slur"
            shape = smartshape_type[string.lower(shape_type)]
        end
        for noteentry in eachentrysaved(music_region) do
            local smartshape_entry_marks = finale.FCSmartShapeEntryMarks(noteentry)
            smartshape_entry_marks:LoadAll(music_region)
            for ss_entry_mark in each(smartshape_entry_marks) do
                local smartshape = ss_entry_mark:CreateSmartShape()
                if smartshape ~= nil then
                    if ss_entry_mark:CalcLeftMark() or (ss_entry_mark:CalcRightMark()) then
                        if smartshape.ShapeType == shape then
                            smartshape:DeleteData()
                        end
                    end
                end
            end
        end
    end

    function smartshape.delete_all_slurs(music_region)
        local slurs = {
            "slurauto",
            "slurdown",
            "slurup",
            "dashed",
            "dashedslurdown",
            "dashedslurup",
            "dashedcurve",
            "dashedcurvedown",
            "dashedcurveup"
        }
        for _, val in pairs(slurs) do
            smartshape.delete_entry_based_smartshape(music_region, val)
        end
    end
    return smartshape
end
package.preload["library.client"] = package.preload["library.client"] or function()

    local client = {}
    local function to_human_string(feature)
        return string.gsub(feature, "_", " ")
    end
    local function requires_later_plugin_version(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
        end
        return "This script requires a later version of RGP Lua. Please update RGP Lua instead to use this script."
    end
    local function requires_rgp_lua(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which is not available on JW Lua. Please use RGP Lua instead to use this script."
        end
        return "This script requires RGP Lua, the successor of JW Lua. Please use RGP Lua instead to use this script."
    end
    local function requires_plugin_version(version, feature)
        if tonumber(version) <= 0.54 then
            if feature then
                return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua or JW Lua version " .. version ..
                           " or later. Please update your plugin to use this script."
            end
            return "This script requires RGP Lua or JW Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        return "This script requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    local function requires_finale_version(version, feature)
        return "This script uses " .. to_human_string(feature) .. ", which is only available on Finale " .. version .. " or later"
    end

    function client.get_raw_finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

    function client.get_lua_plugin_version()
        local num_string = tostring(finenv.MajorVersion) .. "." .. tostring(finenv.MinorVersion)
        return tonumber(num_string)
    end
    local features = {
        clef_change = {
            test = client.get_lua_plugin_version() >= 0.60,
            error = requires_plugin_version("0.58", "a clef change"),
        },
        ["FCKeySignature::CalcTotalChromaticSteps"] = {
            test = finenv.IsRGPLua and finale.FCKeySignature.__class.CalcTotalChromaticSteps,
            error = requires_later_plugin_version("a custom key signature"),
        },
        ["FCCategory::SaveWithNewType"] = {
            test = client.get_lua_plugin_version() >= 0.58,
            error = requires_plugin_version("0.58"),
        },
        ["finenv.QueryInvokedModifierKeys"] = {
            test = finenv.IsRGPLua and finenv.QueryInvokedModifierKeys,
            error = requires_later_plugin_version(),
        },
        ["FCCustomLuaWindow::ShowModeless"] = {
            test = finenv.IsRGPLua,
            error = requires_rgp_lua("a modeless dialog")
        },
        ["finenv.RetainLuaState"] = {
            test = finenv.IsRGPLua and finenv.RetainLuaState ~= nil,
            error = requires_later_plugin_version(),
        },
        smufl = {
            test = finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1),
            error = requires_finale_version("27.1", "a SMUFL font"),
        },
        luaosutils = {
            test = finenv.EmbeddedLuaOSUtils,
            error = requires_later_plugin_version("the embedded luaosutils library")
        }
    }

    function client.supports(feature)
        if features[feature] == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

    function client.assert_supports(feature)
        local error_level = finenv.DebugEnabled and 2 or 0
        if not client.supports(feature) then
            if features[feature].error then
                error(features[feature].error, error_level)
            end

            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end

    function client.encode_with_client_codepage(input_string)
        if client.supports("luaosutils") then
            local text = require("luaosutils").text
            if text and text.get_default_codepage() ~= text.get_utf8_codepage() then
                return text.convert_encoding(input_string, text.get_utf8_codepage(), text.get_default_codepage())
            end
        end
        return input_string
    end
    return client
end
package.preload["library.general_library"] = package.preload["library.general_library"] or function()

    local library = {}
    local client = require("library.client")

    function library.group_overlaps_region(staff_group, region)
        if region:IsFullDocumentSpan() then
            return true
        end
        local staff_exists = false
        local sys_staves = finale.FCSystemStaves()
        sys_staves:LoadAllForRegion(region)
        for sys_staff in each(sys_staves) do
            if staff_group:ContainsStaff(sys_staff:GetStaff()) then
                staff_exists = true
                break
            end
        end
        if not staff_exists then
            return false
        end
        if (staff_group.StartMeasure > region.EndMeasure) or (staff_group.EndMeasure < region.StartMeasure) then
            return false
        end
        return true
    end

    function library.group_is_contained_in_region(staff_group, region)
        if not region:IsStaffIncluded(staff_group.StartStaff) then
            return false
        end
        if not region:IsStaffIncluded(staff_group.EndStaff) then
            return false
        end
        return true
    end

    function library.staff_group_is_multistaff_instrument(staff_group)
        local multistaff_instruments = finale.FCMultiStaffInstruments()
        multistaff_instruments:LoadAll()
        for inst in each(multistaff_instruments) do
            if inst:ContainsStaff(staff_group.StartStaff) and (inst.GroupID == staff_group:GetItemID()) then
                return true
            end
        end
        return false
    end

    function library.get_selected_region_or_whole_doc()
        local sel_region = finenv.Region()
        if sel_region:IsEmpty() then
            sel_region:SetFullDocument()
        end
        return sel_region
    end

    function library.get_first_cell_on_or_after_page(page_num)
        local curr_page_num = page_num
        local curr_page = finale.FCPage()
        local got1 = false

        while curr_page:Load(curr_page_num) do
            if curr_page:GetFirstSystem() > 0 then
                got1 = true
                break
            end
            curr_page_num = curr_page_num + 1
        end
        if got1 then
            local staff_sys = finale.FCStaffSystem()
            staff_sys:Load(curr_page:GetFirstSystem())
            return finale.FCCell(staff_sys.FirstMeasure, staff_sys.TopStaff)
        end

        local end_region = finale.FCMusicRegion()
        end_region:SetFullDocument()
        return finale.FCCell(end_region.EndMeasure, end_region.EndStaff)
    end

    function library.get_top_left_visible_cell()
        if not finenv.UI():IsPageView() then
            local all_region = finale.FCMusicRegion()
            all_region:SetFullDocument()
            return finale.FCCell(finenv.UI():GetCurrentMeasure(), all_region.StartStaff)
        end
        return library.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())
    end

    function library.get_top_left_selected_or_visible_cell()
        local sel_region = finenv.Region()
        if not sel_region:IsEmpty() then
            return finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
        end
        return library.get_top_left_visible_cell()
    end

    function library.is_default_measure_number_visible_on_cell(meas_num_region, cell, staff_system, current_is_part)
        local staff = finale.FCCurrentStaffSpec()
        if not staff:LoadForCell(cell, 0) then
            return false
        end
        if meas_num_region:GetShowOnTopStaff() and (cell.Staff == staff_system.TopStaff) then
            return true
        end
        if meas_num_region:GetShowOnBottomStaff() and (cell.Staff == staff_system:CalcBottomStaff()) then
            return true
        end
        if staff.ShowMeasureNumbers then
            return not meas_num_region:GetExcludeOtherStaves(current_is_part)
        end
        return false
    end

    function library.calc_parts_boolean_for_measure_number_region(meas_num_region, for_part)
        if meas_num_region.UseScoreInfoForParts then
            return false
        end
        if nil == for_part then
            return finenv.UI():IsPartView()
        end
        return for_part
    end

    function library.is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)
        current_is_part = library.calc_parts_boolean_for_measure_number_region(meas_num_region, current_is_part)
        if is_for_multimeasure_rest and meas_num_region:GetShowOnMultiMeasureRests(current_is_part) then
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultiMeasureAlignment(current_is_part)) then
                return false
            end
        elseif (cell.Measure == system.FirstMeasure) then
            if not meas_num_region:GetShowOnSystemStart() then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetStartAlignment(current_is_part)) then
                return false
            end
        else
            if not meas_num_region:GetShowMultiples(current_is_part) then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultipleAlignment(current_is_part)) then
                return false
            end
        end
        return library.is_default_measure_number_visible_on_cell(meas_num_region, cell, system, current_is_part)
    end

    function library.update_layout(from_page, unfreeze_measures)
        from_page = from_page or 1
        unfreeze_measures = unfreeze_measures or false
        local page = finale.FCPage()
        if page:Load(from_page) then
            page:UpdateLayout(unfreeze_measures)
        end
    end

    function library.get_current_part()
        local part = finale.FCPart(finale.PARTID_CURRENT)
        part:Load(part.ID)
        return part
    end

    function library.get_score()
        local part = finale.FCPart(finale.PARTID_SCORE)
        part:Load(part.ID)
        return part
    end

    function library.get_page_format_prefs()
        local current_part = library.get_current_part()
        local page_format_prefs = finale.FCPageFormatPrefs()
        local success
        if current_part:IsScore() then
            success = page_format_prefs:LoadScore()
        else
            success = page_format_prefs:LoadParts()
        end
        return page_format_prefs, success
    end
    local calc_smufl_directory = function(for_user)
        local is_on_windows = finenv.UI():IsOnWindows()
        local do_getenv = function(win_var, mac_var)
            if finenv.UI():IsOnWindows() then
                return win_var and os.getenv(win_var) or ""
            else
                return mac_var and os.getenv(mac_var) or ""
            end
        end
        local smufl_directory = for_user and do_getenv("LOCALAPPDATA", "HOME") or do_getenv("COMMONPROGRAMFILES")
        if not is_on_windows then
            smufl_directory = smufl_directory .. "/Library/Application Support"
        end
        smufl_directory = smufl_directory .. "/SMuFL/Fonts/"
        return smufl_directory
    end

    function library.get_smufl_font_list()
        local osutils = finenv.EmbeddedLuaOSUtils and require("luaosutils")
        local font_names = {}
        local add_to_table = function(for_user)
            local smufl_directory = calc_smufl_directory(for_user)
            local get_dirs = function()
                local options = finenv.UI():IsOnWindows() and "/b /ad" or "-1"
                if osutils then
                    return osutils.process.list_dir(smufl_directory, options)
                end

                local cmd = finenv.UI():IsOnWindows() and "dir " or "ls "
                local handle = io.popen(cmd .. options .. " \"" .. smufl_directory .. "\"")
                if not handle then return "" end
                local retval = handle:read("*a")
                handle:close()
                return retval
            end
            local is_font_available = function(dir)
                local fc_dir = finale.FCString()
                fc_dir.LuaString = dir
                return finenv.UI():IsFontAvailable(fc_dir)
            end
            local dirs = get_dirs() or ""
            for dir in dirs:gmatch("([^\r\n]*)[\r\n]?") do
                if not dir:find("%.") then
                    dir = dir:gsub(" Bold", "")
                    dir = dir:gsub(" Italic", "")
                    local fc_dir = finale.FCString()
                    fc_dir.LuaString = dir
                    if font_names[dir] or is_font_available(dir) then
                        font_names[dir] = for_user and "user" or "system"
                    end
                end
            end
        end
        add_to_table(false)
        add_to_table(true)
        return font_names
    end

    function library.get_smufl_metadata_file(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        local try_prefix = function(prefix, font_info)
            local file_path = prefix .. font_info.Name .. "/" .. font_info.Name .. ".json"
            return io.open(file_path, "r")
        end
        local user_file = try_prefix(calc_smufl_directory(true), font_info)
        if user_file then
            return user_file
        end
        return try_prefix(calc_smufl_directory(false), font_info)
    end

    function library.is_font_smufl_font(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        if client.supports("smufl") then
            if nil ~= font_info.IsSMuFLFont then
                return font_info.IsSMuFLFont
            end
        end
        local smufl_metadata_file = library.get_smufl_metadata_file(font_info)
        if nil ~= smufl_metadata_file then
            io.close(smufl_metadata_file)
            return true
        end
        return false
    end

    function library.simple_input(title, text, default)
        local str = finale.FCString()
        local min_width = 160

        local function format_ctrl(ctrl, h, w, st)
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
            if st then
                str.LuaString = st
                ctrl:SetText(str)
            end
        end

        local title_width = string.len(title) * 6 + 54
        if title_width > min_width then
            min_width = title_width
        end
        local text_width = string.len(text) * 6
        if text_width > min_width then
            min_width = text_width
        end

        str.LuaString = title
        local dialog = finale.FCCustomLuaWindow()
        dialog:SetTitle(str)
        local descr = dialog:CreateStatic(0, 0)
        format_ctrl(descr, 16, min_width, text)
        local input = dialog:CreateEdit(0, 20)
        format_ctrl(input, 20, min_width, default)
        dialog:CreateOkButton()
        dialog:CreateCancelButton()
        if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
            input:GetText(str)
            return str.LuaString
        end
    end

    function library.is_finale_object(object)

        return object and type(object) == "userdata" and object.ClassName and object.GetClassID and true or false
    end

    function library.get_parent_class(classname)
        local class = finale[classname]
        if type(class) ~= "table" then return nil end
        if not finenv.IsRGPLua then
            local classt = class.__class
            if classt and classname ~= "__FCBase" then
                local classtp = classt.__parent
                if classtp and type(classtp) == "table" then
                    for k, v in pairs(finale) do
                        if type(v) == "table" then
                            if v.__class and v.__class == classtp then
                                return tostring(k)
                            end
                        end
                    end
                end
            end
        else
            if class.__parent then
                for k, _ in pairs(class.__parent) do
                    return tostring(k)
                end
            end
        end
        return nil
    end

    function library.get_class_name(object)
        local class_name = object:ClassName(object)
        if class_name == "__FCCollection" and object.ExecuteModal then
            return object.RegisterHandleCommand and "FCCustomLuaWindow" or "FCCustomWindow"
        elseif class_name == "FCControl" then
            if object.GetCheck then
                return "FCCtrlCheckbox"
            elseif object.GetThumbPosition then
                return "FCCtrlSlider"
            elseif object.AddPage then
                return "FCCtrlSwitcher"
            else
                return "FCCtrlButton"
            end
        elseif class_name == "FCCtrlButton" and object.GetThumbPosition then
            return "FCCtrlSlider"
        end
        return class_name
    end

    function library.system_indent_set_to_prefs(system, page_format_prefs)
        page_format_prefs = page_format_prefs or library.get_page_format_prefs()
        local first_meas = finale.FCMeasure()
        local is_first_system = (system.FirstMeasure == 1)
        if (not is_first_system) and first_meas:Load(system.FirstMeasure) then
            if first_meas.ShowFullNames then
                is_first_system = true
            end
        end
        if is_first_system and page_format_prefs.UseFirstSystemMargins then
            system.LeftMargin = page_format_prefs.FirstSystemLeft
        else
            system.LeftMargin = page_format_prefs.SystemLeft
        end
        return system:Save()
    end

    function library.calc_script_filepath()
        local fc_string = finale.FCString()
        if finenv.RunningLuaFilePath then

            fc_string.LuaString = finenv.RunningLuaFilePath()
        else


            fc_string:SetRunningLuaFilePath()
        end
        return fc_string.LuaString
    end

    function library.calc_script_name(include_extension)
        local fc_string = finale.FCString()
        fc_string.LuaString = library.calc_script_filepath()
        local filename_string = finale.FCString()
        fc_string:SplitToPathAndFile(nil, filename_string)
        local retval = filename_string.LuaString
        if not include_extension then
            retval = retval:match("(.+)%..+")
            if not retval or retval == "" then
                retval = filename_string.LuaString
            end
        end
        return retval
    end

    function library.get_default_music_font_name()
        local fontinfo = finale.FCFontInfo()
        local default_music_font_name = finale.FCString()
        if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
            fontinfo:GetNameString(default_music_font_name)
            return default_music_font_name.LuaString
        end
    end
    return library
end
function plugindef()
  finaleplugin.Author = "Jacob Winkler"
  finaleplugin.Copyright = "2024"
  finaleplugin.Version = "1.2"
  finaleplugin.Date = "2024-02-06"
  finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
  finaleplugin.AdditionalMenuOptions = [[
    Ties: Replace Dangling w/Slurs
    ]]
  finaleplugin.AdditionalUndoText = [[
    Ties: Replace Dangling w/Slurs
    ]]
  finaleplugin.AdditionalDescriptions = [[
    Removes dangling ties and replaces them with slurs
    ]]
  finaleplugin.AdditionalPrefixes = [[
    replace_with_slur = true
    ]]
  finaleplugin.Notes = [[
      TIES: REMOVE DANGLING
      
      This script will search for 'dangling ties' - ties that go to rests rather than other notes - and either remove them or replace them with slurs.
      ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 TIES: REMOVE DANGLING\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script will search for \u8216'dangling ties\u8217' - ties that go to rests rather than other notes - and either remove them or replace them with slurs.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/ties_remove_dangling.hash"
  return "Ties: Remove Dangling", "Ties: Remove Dangling", "Removes dangling ties (ties that go nowhere)."
end
replace_with_slur = replace_with_slur or false
local tie = require("library.tie")
local smartshape = require("library.smartshape")
local library = require("library.general_library")
local music_region = library.get_selected_region_or_whole_doc()
for working_staff = music_region:GetStartStaff(), music_region:GetEndStaff() do
  for layer_num = 0, 3, 1 do
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
            if replace_with_slur then
              local next_entry = note_entry_layer:GetRegionItemAt(index + 1, music_region)
              if next_entry then
                smartshape.add_entry_based_smartshape(entry, next_entry)
              end
            end
          end
        end
      end
    end
    note_entry_layer:Save()
  end
end
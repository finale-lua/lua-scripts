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
        if entry.NextSameVInFrame then
            return entry:NextSameVInFrame()
        end
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
package.preload["library.articulation"] = package.preload["library.articulation"] or function()

    local articulation = {}
    local note_entry = require("library.note_entry")

    function articulation.delete_from_entry_by_char_num(entry, char_num)
        local artics = entry:CreateArticulations()
        for a in eachbackwards(artics) do
            local defs = a:CreateArticulationDef()
            if defs:GetAboveSymbolChar() == char_num then
                a:DeleteData()
            end
        end
    end

    function articulation.is_note_side(artic, curr_pos)
        if nil == curr_pos then
            curr_pos = finale.FCPoint(0, 0)
            if not artic:CalcMetricPos(curr_pos) then
                return false
            end
        end
        local entry = artic:GetNoteEntry()
        local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
        if nil == cell_metrics then
            return false
        end
        if entry:CalcStemUp() then
            local bot_pos = note_entry.get_bottom_note_position(entry)
            bot_pos = math.floor(((10000 * bot_pos) / cell_metrics.StaffScaling) + 0.5)
            return curr_pos.Y <= bot_pos
        else
            local top_pos = note_entry.get_top_note_position(entry)
            top_pos = math.floor(((10000 * top_pos) / cell_metrics.StaffScaling) + 0.5)
            return curr_pos.Y >= top_pos
        end
    end

    function articulation.calc_main_character_dimensions(artic_def)
        local text_mets = finale.FCTextMetrics()
        if not text_mets:LoadArticulation(artic_def, false, 100) then
            return 0, 0
        end
        return text_mets:CalcWidthEVPUs(), text_mets:CalcHeightEVPUs()
    end

    function articulation.reset_to_default(artic, artic_def)
        artic_def = artic_def or artic:CreateArticulationDef()
        artic.StackingMode = finale.ARTICSTACKING_USEDEFINITION
        artic.PlacementMode = finale.ARTICPLACEMENT_AUTOMATIC
        artic:ResetPos(artic_def)
    end
    return articulation
end
function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "July 29, 2024"
    finaleplugin.CategoryTags = "Articulation"
    finaleplugin.MinFinaleVersionRaw = 0x1a000000
    finaleplugin.MinJWLuaVersion = 0.58
    finaleplugin.RequireSelection = true
    finaleplugin.Notes = [[
This script resets all selected articulations to their default positions but only if they are not manually positioned.
Due to complications arising from how Finale stored articulation positions before Finale 26, it requires Finale 26 or higher.
Due to issues around maintaining the context for automatic stacking, it must be run under RGP Lua. JW Lua does not have the necessary
logic to manage the stacking context.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script resets all selected articulations to their default positions but only if they are not manually positioned. Due to complications arising from how Finale stored articulation positions before Finale 26, it requires Finale 26 or higher. Due to issues around maintaining the context for automatic stacking, it must be run under RGP Lua. JW Lua does not have the necessary logic to manage the stacking context.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/articulation_reset_auto_positioning.hash"
    return "Reset Automatic Articulation Positions", "Reset Automatic Articulation Positions",
        "Resets the position of automatically positioned articulations while ignoring those with manual positioning."
end
local articulation = require("library.articulation")
function articulation_reset_auto_positioning()
    for note_entry in eachentry(finenv.Region()) do
        local articulations = note_entry:CreateArticulations()
        for artic_assign in each(articulations) do
            local articulation_def = finale.FCArticulationDef()
            if articulation_def:Load(artic_assign.ID) then
                local do_save = false
                if articulation_def.CenterHorizontally then
                    artic_assign.HorizontalPos = 0
                    do_save = true
                end
                if finale.ARTPOS_MANUAL_POSITIONING ~= articulation_def.AutoPosSide then
                    local save_horzpos = artic_assign.HorizontalPos
                    local save_flip = artic_assign.PlacementMode
                    articulation.reset_to_default(artic_assign, articulation_def)
                    artic_assign.HorizontalPos = save_horzpos
                    artic_assign.PlacementMode = save_flip
                    do_save = true
                end
                if do_save then
                    artic_assign:Save()
                end
            end
        end
    end
end
articulation_reset_auto_positioning()

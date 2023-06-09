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
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "©2019 Jacob Winkler"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "11/02/2019"
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/note_cluster_determinate.hash"
    return "Cluster - Determinate", "Cluster - Determinate", "Creates a determinate cluster."
end
local note_entry = require("library.note_entry")
local region = finenv.Region()
local layer = {}
local layer_one_note = {}
local layer_two_note = {}
local measure = {}
local horizontal_offset = -20
local function process_notes(music_region)
    local stem_dir = {}

    for entry in eachentrysaved(region) do
        entry.FreezeStem = false
        table.insert(stem_dir, entry:CalcStemUp())
    end
    layer.copy(1, 2)
    layer.copy(1, 3)
    local i = 1
    local j = 1
    for note_entry in eachentrysaved(music_region) do
        local span = note_entry:CalcDisplacementRange(nil)
        local stem_direction = stem_dir[i]
        if note_entry.LayerNumber == 1 then
            stem_direction = stem_dir[i]
            if note_entry:IsNote() then
                if span > 2 then
                    delete_bottom_notes(note_entry)
                else
                    delete_middle_notes(note_entry)
                    note_entry.FreezeStem = true
                    note_entry.StemUp = stem_direction
                end
            elseif note_entry:IsRest() then
                note_entry:SetRestDisplacement(6)
            end
            if stem_direction == false and span > 2 then
                hide_stems(note_entry, stem_direction)
            end
            i = i + 1
        elseif note_entry.LayerNumber == 2 then
            stem_direction = stem_dir[j]
            if note_entry:IsNote() and span > 2 then
                delete_top_notes(note_entry)
            else
                note_entry:MakeRest()
                note_entry.Visible = false
                note_entry:SetRestDisplacement(4)
            end
            if stem_direction == true then
                hide_stems(note_entry, stem_direction)
            end
            j = j + 1
        elseif note_entry.LayerNumber == 3 then
            if note_entry:IsNote() then
                for note in each(note_entry) do
                    note.AccidentalFreeze = true
                    note.Accidental = false
                end
                note_entry.FreezeStem = true
                note_entry.StemUp = true
                hide_stems(note_entry, true)
                delete_top_bottom_notes(note_entry)
            elseif note_entry:IsRest() then
                note_entry:SetRestDisplacement(2)
            end
            note_entry.Visible = false
        end
        note_entry.CheckAccidentals = true
        if note_entry:IsNote() then
            n = 1
            for note in each(note_entry) do
                note.NoteID = n
                n = n + 1
            end
        end
    end
end
function hide_stems(entry, stem_direction)
    local stem = finale.FCCustomStemMod()
    stem:SetNoteEntry(entry)
    if stem_direction then
        stem_direction = false
    else
        stem_direction = true
    end
    stem:UseUpStemData(stem_direction)
    if stem:LoadFirst() then
        stem.ShapeID = 0
        stem:Save()
    else
        stem.ShapeID = 0
        stem:SaveNew()
    end
    entry:SetBeamBeat(true)
end
function layer.copy(source, destination)
    local region = finenv.Region()
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local system_staves = finale.FCSystemStaves()
    system_staves:LoadAllForRegion(region)

    source = source - 1
    destination = destination - 1
    for system_staff in each(system_staves) do
        local staff_number = system_staff.Staff
        local note_entry_layer_source = finale.FCNoteEntryLayer(source, staff_number, start, stop)
        note_entry_layer_source:Load()
        local noteentrylayerDest = note_entry_layer_source:CreateCloneEntries(destination, staff_number, start)
        noteentrylayerDest:Save()
        noteentrylayerDest:CloneTuplets(note_entry_layer_source)
        noteentrylayerDest:Save()
    end
end
function delete_bottom_notes(entry)
    while entry.Count > 1 do
        local lowest_note = entry:CalcLowestNote(nil)
        note_entry.delete_note(lowest_note)
    end
end
function delete_top_notes(entry)
    while entry.Count > 1 do
        local highest_note = entry:CalcHighestNote(nil)
        note_entry.delete_note(highest_note)
    end
end
function delete_top_bottom_notes(entry)
    local highest_note = entry:CalcHighestNote(nil)
    note_entry.delete_note(highest_note)
    local lowest_note = entry:CalcLowestNote(nil)
    note_entry.delete_note(lowest_note)
end
function delete_middle_notes(entry)
    while entry.Count > 2 do
        local n = 1
        for note in each(entry) do
            note.NoteID = n
            n = n + 1
        end
        for note in each(entry) do
            if note.NoteID == 2 then
                note_entry.delete_note(note)
            end
        end
    end
end
local function create_cluster_line()

    local line_exists = false
    local my_line = 0
    local my_line_width = 64 * 24 * .5
    local custom_start_line_defs = finale.FCCustomSmartLineDefs()
    custom_start_line_defs:LoadAll()
    for csld in each(custom_start_line_defs) do
        if csld.LineStyle == finale.CUSTOMLINE_SOLID and csld.LineWidth == my_line_width then
            if csld.StartArrowheadStyle == finale.CLENDPOINT_NONE and csld.EndArrowheadStyle == finale.CLENDPOINT_NONE then
                if csld.Horizontal == false then
                    my_line = csld.ItemNo
                    line_exists = true
                end
            end
        end
    end

    if line_exists == false then
        local csld = finale.FCCustomSmartLineDef()
        csld.Horizontal = false
        csld.LineStyle = finale.CUSTOMLINE_SOLID
        csld.StartArrowheadStyle = finale.CLENDPOINT_NONE
        csld.EndArrowheadStyle = finale.CLENDPOINT_NONE
        csld.LineWidth = my_line_width
        csld:SaveNew()
        my_line = csld.ItemNo
    end
    return my_line
end
local function create_short_cluster_line()

    local line_exists = false
    local my_line = 0
    local my_line_width = 64 * 24 * .333
    local custom_smart_line_defs = finale.FCCustomSmartLineDefs()
    custom_smart_line_defs:LoadAll()
    for csld in each(custom_smart_line_defs) do
        if csld.LineStyle == finale.CUSTOMLINE_SOLID and csld.LineWidth == my_line_width then
            if csld.StartArrowheadStyle == finale.CLENDPOINT_NONE and csld.EndArrowheadStyle == finale.CLENDPOINT_NONE then
                if csld.Horizontal == false then
                    my_line = csld.ItemNo
                    line_exists = true
                end
            end
        end
    end

    if line_exists == false then
        local csld = finale.FCCustomSmartLineDef()
        csld.Horizontal = false
        csld.LineStyle = finale.CUSTOMLINE_SOLID
        csld.StartArrowheadStyle = finale.CLENDPOINT_NONE
        csld.EndArrowheadStyle = finale.CLENDPOINT_NONE
        csld.LineWidth = my_line_width
        csld:SaveNew()
        my_line = csld.ItemNo
    end
    return my_line
end
function add_cluster_line(left_note, right_note, line_id)
    if left_note:IsNote() and left_note.Count == 1 and right_note:IsNote() then
        local smartshape = finale.FCSmartShape()
        local layer_one_highest = left_note:CalcHighestNote(nil)
        local note_width = layer_one_highest:CalcNoteheadWidth()
        local layer_one_note_y = layer_one_highest:CalcStaffPosition()
        local layer_two_highest = right_note:CalcHighestNote(nil)
        local layer_two_note_y = layer_two_highest:CalcStaffPosition()
        local top_pad = 0
        local bottom_pad = 0
        if left_note.Duration >= 2048 and left_note.Duration < 4096 then
            top_pad = 9
            bottom_pad = top_pad
        elseif left_note.Duration >= 4096 then
            top_pad = 10
            bottom_pad = 11.5
        end
        layer_one_note_y = (layer_one_note_y * 12) - top_pad
        layer_two_note_y = (layer_two_note_y * 12) + bottom_pad
        smartshape.ShapeType = finale.SMARTSHAPE_CUSTOM
        smartshape.EntryBased = false
        smartshape.MakeHorizontal = false
        smartshape.BeatAttached = true
        smartshape.PresetShape = true
        smartshape.Visible = true
        smartshape.LineID = line_id
        local left_segment = smartshape:GetTerminateSegmentLeft()
        left_segment:SetMeasure(left_note.Measure)
        left_segment:SetStaff(left_note.Staff)
        left_segment:SetMeasurePos(left_note.MeasurePos)
        left_segment:SetEndpointOffsetX(note_width / 2)
        left_segment:SetEndpointOffsetY(layer_one_note_y)
        local right_segment = smartshape:GetTerminateSegmentRight()
        right_segment:SetMeasure(right_note.Measure)
        right_segment:SetStaff(right_note.Staff)
        right_segment:SetMeasurePos(right_note.MeasurePos)
        right_segment:SetEndpointOffsetX(note_width / 2)
        right_segment:SetEndpointOffsetY(layer_two_note_y)
        smartshape:SaveNewEverything(nil, nil)
    end
end
function add_short_cluster_line(entry, short_lineID)
    if entry:IsNote() and entry.Count > 1 then
        local smartshape = finale.FCSmartShape()
        local left_note = entry:CalcHighestNote(nil)
        local left_note_y = left_note:CalcStaffPosition() * 12 + 12
        local right_note = entry:CalcLowestNote(nil)
        local right_note_y = right_note:CalcStaffPosition() * 12 - 12
        smartshape.ShapeType = finale.SMARTSHAPE_CUSTOM
        smartshape.EntryBased = false
        smartshape.MakeHorizontal = false
        smartshape.PresetShape = true
        smartshape.Visible = true
        smartshape.BeatAttached = true
        smartshape.LineID = short_lineID
        local left_segment = smartshape:GetTerminateSegmentLeft()
        left_segment:SetMeasure(entry.Measure)
        left_segment:SetStaff(entry.Staff)
        left_segment:SetMeasurePos(entry.MeasurePos)
        left_segment:SetEndpointOffsetX(horizontal_offset)
        left_segment:SetEndpointOffsetY(left_note_y)
        local right_segment = smartshape:GetTerminateSegmentRight()
        right_segment:SetMeasure(entry.Measure)
        right_segment:SetStaff(entry.Staff)
        right_segment:SetMeasurePos(entry.MeasurePos)
        right_segment:SetEndpointOffsetX(horizontal_offset)
        right_segment:SetEndpointOffsetY(right_note_y)
        smartshape:SaveNewEverything(nil, nil)
    end
end
local line_id = create_cluster_line()
local short_lineID = create_short_cluster_line()
for add_staff = region:GetStartStaff(), region:GetEndStaff() do
    local count = 0
    for k in pairs(layer_one_note) do
        layer_one_note[k] = nil
    end
    for k in pairs(layer_two_note) do
        layer_two_note[k] = nil
    end
    for k in pairs(measure) do
        measure[k] = nil
    end
    region:SetStartStaff(add_staff)
    region:SetEndStaff(add_staff)
    local measures = finale.FCMeasures()
    measures:LoadRegion(region)
    process_notes(region)
    for entry in eachentrysaved(region) do
        if entry.LayerNumber == 1 then
            table.insert(layer_one_note, entry)
            table.insert(measure, entry.Measure)
            count = count + 1
        elseif entry.LayerNumber == 2 then
            table.insert(layer_two_note, entry)
        end
    end
    for i = 1, count do
        add_short_cluster_line(layer_one_note[i], short_lineID)
        add_cluster_line(layer_one_note[i], layer_two_note[i], line_id)
    end
end
for note_entry in eachentrysaved(finenv.Region()) do
    if note_entry:IsNote() and note_entry.Count > 1 then
        for note in each(note_entry) do
            if note.Accidental == true then
                local accidental_mod = finale.FCAccidentalMod()
                accidental_mod:SetNoteEntry(note_entry)
                accidental_mod:SetUseCustomVerticalPos(true)
                accidental_mod:SetHorizontalPos(horizontal_offset * 1.5)
                accidental_mod:SaveAt(note)
            end
        end
    end
end

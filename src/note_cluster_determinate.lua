function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Jacob Winkler" -- With help & advice from CJ Garcia, Nick Mazuk, and Jan Angermüller. Thanks guys!
    finaleplugin.Copyright = "©2019 Jacob Winkler"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "11/02/2019"
    return "Cluster - Determinate", "Cluster - Determinate", "Creates a determinate cluster."
end

local note_entry = require("library.note_entry")

local region = finenv.Region()

local layer = {}
local layer_one_note = {}
local layer_two_note = {}

local measure = {}

local horizontal_offset = -20

-- FUNCTION 1: Delete and Hide Notes
local function process_notes(music_region)
    local stem_dir = {}
    -- First build up a table of the initial stem direction information
    for entry in eachentrysaved(region) do
        entry.FreezeStem = false
        table.insert(stem_dir, entry:CalcStemUp())
    end

    layer.copy(1, 2)
    layer.copy(1, 3)

    local i = 1 -- To iterate stem direction table for Layer 1
    local j = 1 -- To iterate stem direction table for Layer 2

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

-- Function 2: Hide Stems (from JW's Harp Gliss script, modified)
function hide_stems(entry, stem_direction)
    local stem = finale.FCCustomStemMod()
    stem:SetNoteEntry(entry)
    if stem_direction then -- Reverse "stemDir"
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
    entry:SetBeamBeat(true) -- Since flags get hidden, use this instead of trying tro change beam width
end

-- Function 3 - Copy Layer "src" to Layer "dest"
function layer.copy(source, destination) -- source and destination layer numbers, 1 based
    local region = finenv.Region()
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local system_staves = finale.FCSystemStaves()
    system_staves:LoadAllForRegion(region)

    -- Set variables for 0-based layers
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

-- Function 4 - Delete the bottom notes, leaving only the top
function delete_bottom_notes(entry)
    while entry.Count > 1 do
        local lowest_note = entry:CalcLowestNote(nil)
        note_entry.delete_note(lowest_note)
    end
end

-- Function 5 - Delete the top notes, leaving only the bottom
function delete_top_notes(entry)
    while entry.Count > 1 do
        local highest_note = entry:CalcHighestNote(nil)
        note_entry.delete_note(highest_note)
    end
end

-- Function 6 - Delete the Top and Bottom Notes
function delete_top_bottom_notes(entry)
    local highest_note = entry:CalcHighestNote(nil)
    note_entry.delete_note(highest_note)
    local lowest_note = entry:CalcLowestNote(nil)
    note_entry.delete_note(lowest_note)
end

-- Function 6.1 - Delete the middle notes
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

-- Function 7: Create the custom line to use (or choose it if it already exists)
local function create_cluster_line()
    -- Check to see if the right line exists. If it does, get the line ID
    local line_exists = false
    local my_line = 0
    local my_line_width = 64 * 24 * .5 -- 64 EFIXes * 24EVPUs * .5 = 1/2 space
    local custom_start_line_defs = finale.FCCustomSmartLineDefs()
    custom_start_line_defs:LoadAll()
    for csld in each(custom_start_line_defs) do
        if csld.LineStyle == finale.CUSTOMLINE_SOLID and csld.LineWidth == my_line_width then -- 1st if: Solid line, 740
            if csld.StartArrowheadStyle == finale.CLENDPOINT_NONE and csld.EndArrowheadStyle == finale.CLENDPOINT_NONE then -- 2nd if (arrowhead styles)
                if csld.Horizontal == false then
                    my_line = csld.ItemNo
                    line_exists = true
                end
            end
        end
    end

    -- if the line does not exist, create it and get the line ID
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

-- Function 7.1: Create the short-span custom line to use (or choose it if it already exists)
local function create_short_cluster_line()
    -- Check to see if the right line exists. If it does, get the line ID
    local line_exists = false
    local my_line = 0
    local my_line_width = 64 * 24 * .333 -- 64 EFIXes * 24EVPUs * .333 = 1/3 space
    local custom_smart_line_defs = finale.FCCustomSmartLineDefs()
    custom_smart_line_defs:LoadAll()
    for csld in each(custom_smart_line_defs) do
        if csld.LineStyle == finale.CUSTOMLINE_SOLID and csld.LineWidth == my_line_width then -- 1st if: Solid line, 740
            if csld.StartArrowheadStyle == finale.CLENDPOINT_NONE and csld.EndArrowheadStyle == finale.CLENDPOINT_NONE then -- 2nd if (arrowhead styles)
                if csld.Horizontal == false then
                    my_line = csld.ItemNo
                    line_exists = true
                end
            end
        end
    end

    -- if the line does not exist, create it and get the line ID
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

-- Function 8: Attach the cluster line to the score
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
        if left_note.Duration >= 2048 and left_note.Duration < 4096 then -- for half notes...
            top_pad = 9
            bottom_pad = top_pad
        elseif left_note.Duration >= 4096 then -- for whole notes and greater...
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

-- Function 8.1: Attach the short cluster line to the score
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

-- separate move accidentals function for short clusters that encompass a 3rd
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

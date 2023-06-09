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
        for key, val in pairs(slurs) do
            smartshape.delete_entry_based_smartshape(music_region, val)
        end
    end
    return smartshape
end
package.preload["library.layer"] = package.preload["library.layer"] or function()

    local layer = {}

    function layer.copy(region, source_layer, destination_layer, clone_articulations)
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        source_layer = source_layer - 1
        destination_layer = destination_layer - 1
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local noteentry_source_layer = finale.FCNoteEntryLayer(source_layer, staffNum, start, stop)
            noteentry_source_layer:SetUseVisibleLayer(false)
            noteentry_source_layer:Load()
            local noteentry_destination_layer = noteentry_source_layer:CreateCloneEntries(
                destination_layer, staffNum, start)
            noteentry_destination_layer:Save()
            noteentry_destination_layer:CloneTuplets(noteentry_source_layer)

            if clone_articulations and noteentry_source_layer.Count == noteentry_destination_layer.Count then
                for index = 0, noteentry_destination_layer.Count - 1 do
                    local source_entry = noteentry_source_layer:GetItemAt(index)
                    local destination_entry = noteentry_destination_layer:GetItemAt(index)
                    local source_artics = source_entry:CreateArticulations()
                    for articulation in each (source_artics) do
                        articulation:SetNoteEntry(destination_entry)
                        articulation:SaveNew()
                    end
                end
            end
            noteentry_destination_layer:Save()
        end
    end

    function layer.clear(region, layer_to_clear)
        layer_to_clear = layer_to_clear - 1
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local  noteentry_layer = finale.FCNoteEntryLayer(layer_to_clear, staffNum, start, stop)
            noteentry_layer:SetUseVisibleLayer(false)
            noteentry_layer:Load()
            noteentry_layer:ClearAllEntries()
        end
    end

    function layer.swap(region, swap_a, swap_b)

        swap_a = swap_a - 1
        swap_b = swap_b - 1
        for measure, staff_number in eachcell(region) do
            local cell_frame_hold = finale.FCCellFrameHold()
            cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
            local loaded = cell_frame_hold:Load()
            local cell_clef_changes = loaded and cell_frame_hold.IsClefList and cell_frame_hold:CreateCellClefChanges() or nil
            local  noteentry_layer_one = finale.FCNoteEntryLayer(swap_a, staff_number, measure, measure)
            noteentry_layer_one:SetUseVisibleLayer(false)
            noteentry_layer_one:Load()
            noteentry_layer_one.LayerIndex = swap_b

            local  noteentry_layer_two = finale.FCNoteEntryLayer(swap_b, staff_number, measure, measure)
            noteentry_layer_two:SetUseVisibleLayer(false)
            noteentry_layer_two:Load()
            noteentry_layer_two.LayerIndex = swap_a
            noteentry_layer_one:Save()
            noteentry_layer_two:Save()
            if loaded then
                local new_cell_frame_hold = finale.FCCellFrameHold()
                new_cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
                if new_cell_frame_hold:Load() then
                    if cell_frame_hold.IsClefList then
                        if new_cell_frame_hold.SetCellClefChanges then
                            new_cell_frame_hold:SetCellClefChanges(cell_clef_changes)
                        end

                    else
                        new_cell_frame_hold.ClefIndex = cell_frame_hold.ClefIndex
                    end
                    new_cell_frame_hold:Save()
                end
            end
        end
    end

    function layer.max_layers()
        return finale.FCLayerPrefs.GetMaxLayers and finale.FCLayerPrefs.GetMaxLayers() or 4
    end
    return layer
end
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.53"
    finaleplugin.Date = "2022/11/14"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        A nice trick in Sibelius is hitting the 'S' key to create a slur joining the currently selected notes.
        Activate this script in Finale with a macro hotkey utility to do the same thing.
        Each layer will be slurred independently, and if there are
        multiple runs of notes separated by rests, each run will be slurred independently.
        If you want to automate slurs on specific note patterns then try
        JW Pattern (Performance Notation -> Slurs) or TGTools (Music -> Create Slurs...").
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/slur_selection.hash"
    return "Slur Selection", "Slur Selection", "Create slurs across the current selection"
end
local smartshape = require("library.smartshape")
local layer = require("library.layer")
function make_slurs()
    local region = finenv.Region()
    for staff_number = region.StartStaff, region.EndStaff do
        for layer_number = 1, layer.max_layers() do
            local entry_layer = finale.FCNoteEntryLayer(layer_number - 1, staff_number, region.StartMeasure, region.EndMeasure)
            entry_layer:Load()
            local start_slur = false
            for entry in each(entry_layer) do
                if region:IsEntryPosWithin(entry) then
                    if not start_slur then
                        if entry:IsNote() then
                            start_slur = entry
                        end
                    elseif entry:IsRest() then
                        start_slur = false
                    elseif not entry:Next() or entry:Next():IsRest() or not region:IsEntryPosWithin(entry:Next()) then
                        smartshape.add_entry_based_smartshape(start_slur, entry, "auto_slur")
                        start_slur = false
                    end
                end
            end
        end
    end
end
make_slurs()

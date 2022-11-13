__imports = __imports or {}
__import_results = __import_results or {}

function require(item)
    if not __imports[item] then
        error("module '" .. item .. "' not found")
    end

    if __import_results[item] == nil then
        __import_results[item] = __imports[item]()
        if __import_results[item] == nil then
            __import_results[item] = true
        end
    end

    return __import_results[item]
end

__imports["library.layer"] = __imports["library.layer"] or function()
    --[[
    $module Layer
    ]] --
    local layer = {}
    
    --[[
    % copy
    
    Duplicates the notes from the source layer to the destination. The source layer remains untouched.
    
    @ region (FCMusicRegion) the region to be copied
    @ source_layer (number) the number (1-4) of the layer to duplicate
    @ destination_layer (number) the number (1-4) of the layer to be copied to
    ]]
    function layer.copy(region, source_layer, destination_layer)
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
            noteentry_destination_layer:Save()
        end
    end -- function layer_copy
    
    --[[
    % clear
    
    Clears all entries from a given layer.
    
    @ region (FCMusicRegion) the region to be cleared
    @ layer_to_clear (number) the number (1-4) of the layer to clear
    ]]
    function layer.clear(region, layer_to_clear)
        layer_to_clear = layer_to_clear - 1 -- Turn 1 based layer to 0 based layer
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
    
    --[[
    % swap
    
    Swaps the entries from two different layers (e.g. 1-->2 and 2-->1).
    
    @ region (FCMusicRegion) the region to be swapped
    @ swap_a (number) the number (1-4) of the first layer to be swapped
    @ swap_b (number) the number (1-4) of the second layer to be swapped
    ]]
    function layer.swap(region, swap_a, swap_b)
        -- Set layers for 0 based
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
            --
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
                        -- No remedy here in JW Lua. The clef list can be changed by a layer swap.
                    else
                        new_cell_frame_hold.ClefIndex = cell_frame_hold.ClefIndex
                    end
                    new_cell_frame_hold:Save()
                end
            end
        end
    end
    
    
    --[[
    % max_layers
    
    Return the maximum number of layers available in the current document.
    
    : (number) maximum number of available layers
    ]]
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
    finaleplugin.Version = "v1.48"
    finaleplugin.Date = "2022/11/14"
    finaleplugin.Notes = [[
        Chords on layer 1 in the selected region are split into independent layers on the same staff. 
        Multiple measures and staves can be selected at once. 
        More than four notes in a chord are deposited on layer 4. 
        As a special case, if a staff contains only single-note entries, they are duplicated to layer 2. 
        Markings on the original are not copied to other layers.
    ]]
    return "Staff Explode To Layers", "Staff Explode To Layers", "Explode chords on layer 1 into independent layers"
end

local layer = require("library.layer")

function get_note_count(region)
    local note_count = 0
    for entry in eachentry(region) do
        if entry.Count > note_count then
            note_count = entry.Count
        end
    end
    return note_count
end

function explode_one_slot(slot)
    local region = finenv.Region()
    region.StartSlot = slot
    region.EndSlot = slot
    local max_note_count = get_note_count(region)
    if max_note_count == 0 then return end -- no notes in this slot

    local start_measure = region.StartMeasure
    local end_measure = region.EndMeasure
    local staff = region:CalcStaffNumber(slot)

    -- assume that user wants to double single layer 1 notes to layer 2
    local unison_doubling = (max_note_count == 1) and 1 or 0

    -- copy top staff to max_note_count layers
    local layers = {}
    layers[1] = finale.FCNoteEntryLayer(0, staff, start_measure, end_measure)
    layers[1]:Load()

    for i = 2, (max_note_count + unison_doubling) do  -- copy to the other layers
        if i > layer.max_layers() then break end -- observe maximum layers
        layer.copy(region, 1, i)
    end

    if unison_doubling == 1 then  -- special unison doubling, so don't delete layer 2
        return
    end

    -- run through all entries and split by layer
    for entry in eachentrysaved(region) do
        if entry:IsNote() then
            local this_layer = entry.LayerNumber
            local from_top = this_layer - 1   -- delete how many notes from top?
            local from_bottom = entry.Count - this_layer -- how many from bottom?

            if from_top > 0 then -- delete TOP notes
                for i = 1, from_top do
                    entry:DeleteNote(entry:CalcHighestNote(nil))
                end
            end
            if from_bottom > 0 and this_layer < layer.max_layers() then -- delete BOTTOM notes
                for i = 1, from_bottom do
                    entry:DeleteNote(entry:CalcLowestNote(nil))
                end
            end
        end
    end
end

function staff_layer_explode()
    local region = finenv.Region()
    local note_count = get_note_count(region)
    if note_count == 0 then -- nothing here ... go home
        finenv.UI():AlertNeutral("", "Please select a region\nwith some notes in it!")
        return
    end
    for slot = region.StartSlot, region.EndSlot do
        explode_one_slot(slot)
    end
end

staff_layer_explode()

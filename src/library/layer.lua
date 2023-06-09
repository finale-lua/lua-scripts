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
@ [clone_articulations] (boolean) if true, clone articulations (default is false)
]]
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
        -- ToDo: (possible) clone note-level items such as custom notehead alterations
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

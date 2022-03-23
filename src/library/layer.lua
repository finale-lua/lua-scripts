--[[
$module Layer
]]

layer = {}

--[[
% copy(source_layer, destination_layer)

Duplicates the notes from the source layer to the destination. The source layer remains untouched.

@ source_layer number the number (1-4) of the layer to duplicate
@ destination_layer number the number (1-4) of the layer to be copied to
]]
function layer.copy(source_layer, destination_layer)
    local region = finenv.Region()
    local start=region.StartMeasure
    local stop=region.EndMeasure
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(region)
    source_layer = source_layer - 1
    destination_layer = destination_layer - 1
    for sysstaff in each(sysstaves) do
        staffNum = sysstaff.Staff
        local noteentry_source_layer = finale.FCNoteEntryLayer(source_layer,staffNum,start,stop)
        noteentry_source_layer:Load()     
        local noteentry_destination_layer = noteentry_source_layer:CreateCloneEntries(destination_layer,staffNum,start)
        noteentry_destination_layer:Save()
        noteentry_destination_layer:CloneTuplets(noteentry_source_layer)
        noteentry_destination_layer:Save()
    end
end -- function layer_copy

--[[
% clear(layer_to_clear)

Clears all entries from a given layer.

@ layer_to_clear number the number (1-4) of the layer to clear
]]
function layer.clear(layer_to_clear)
    layer_to_clear = layer_to_clear - 1 -- Turn 1 based layer to 0 based layer
    local region = finenv.Region()
    local start=region.StartMeasure
    local stop=region.EndMeasure
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(region)
    for sysstaff in each(sysstaves) do
        staffNum = sysstaff.Staff
        local noteentrylayer = finale.FCNoteEntryLayer(layer_to_clear,staffNum,start,stop)
        noteentrylayer:Load()
        noteentrylayer:ClearAllEntries()
    end
end

--[[
% swap(swap_a, swap_b)

Swaps the entries from two different layers (e.g. 1-->2 and 2-->1).

@ swap_a number the number (1-4) of the first layer to be swapped
@ swap_b number the number (1-4) of the second layer to be swapped
]]
function layer.swap(swap_a, swap_b)
    local region = finenv.Region()
    local start=region.StartMeasure
    local stop=region.EndMeasure
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(region)
    -- Set layers for 0 based
    swap_a = swap_a - 1
    swap_b = swap_b - 1
    for sysstaff in each(sysstaves) do
        staffNum = sysstaff.Staff
        local noteentrylayer_1 = finale.FCNoteEntryLayer(swap_a,staffNum,start,stop)
        noteentrylayer_1:Load()
        noteentrylayer_1.LayerIndex=swap_b
        --
        local noteentrylayer_2 = finale.FCNoteEntryLayer(swap_b,staffNum,start,stop)
        noteentrylayer_2:Load()
        noteentrylayer_2.LayerIndex=swap_a
        noteentrylayer_1:Save()
        noteentrylayer_2:Save()
    end
end

return layer
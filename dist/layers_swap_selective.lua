function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.50"
    finaleplugin.Date = "2022/05/17"
    finaleplugin.Notes = [[
        Swaps notes in the selected region between two layers chosen by the user.
    ]]
    return "Swap layers selective", "Swap layers selective", "Swap layers selectively"
end

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
        local noteentrylayer = finale.FCNoteEntryLayer(layer_to_clear, staffNum, start, stop)
        noteentrylayer:Load()
        noteentrylayer:ClearAllEntries()
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
        local noteentrylayer_1 = finale.FCNoteEntryLayer(swap_a, staff_number, measure, measure)
        noteentrylayer_1:Load()
        noteentrylayer_1.LayerIndex = swap_b
        --
        local noteentrylayer_2 = finale.FCNoteEntryLayer(swap_b, staff_number, measure, measure)
        noteentrylayer_2:Load()
        noteentrylayer_2.LayerIndex = swap_a
        noteentrylayer_1:Save()
        noteentrylayer_2:Save()
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




function find_errors(layer_a, layer_b)
    local error_message = ""
    if layer_a < 1 or  layer_a > 4 or layer_b < 1 or layer_b > 4  then 
        error_message = "Layer numbers must be\nintegers between 1 and 4"
    elseif layer_a == layer_b  then 
        error_message = "Please nominate two DIFFERENT layers"
    end
    if (error_message ~= "") then  -- error dialog and exit
        finenv.UI():AlertNeutral("(script: " .. plugindef() .. ")", error_message)
        return true
    end
    return false
end

function choose_layers_to_swap()
    local current_vertical = 10 -- first vertical position
    local vertical_step = 25 -- vertical step for each line
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra horizontal offset for Mac edit box
    local horiz_offset = 110
    local edit_boxes = {} -- array of edit boxes for user data input
    local string = finale.FCString()
    local dialog = finale.FCCustomWindow()

    string.LuaString = plugindef()
    dialog:SetTitle(string)
    local texts = { -- words, default value
        { "swap layer# (1-4):", 1 },
        { "with layer# (1-4):", 2 }
    }
        
    for i,v in ipairs(texts) do
        string.LuaString = v[1]
        local static = dialog:CreateStatic(0, current_vertical)
        static:SetText(string)
        static:SetWidth(200)
        edit_boxes[i] = dialog:CreateEdit(horiz_offset, current_vertical - mac_offset)
        edit_boxes[i]:SetInteger(v[2])
        current_vertical = current_vertical + vertical_step
    end

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return dialog:ExecuteModal(nil), -- == 1 if Ok button pressed, else nil
        edit_boxes[1]:GetInteger(), edit_boxes[2]:GetInteger()
end

function layers_swap_selective()
    local ok, layer_a, layer_b = choose_layers_to_swap()
    if ok == finale.EXECMODAL_OK and not find_errors(layer_a, layer_b) then
        layer.swap(finenv.Region(), layer_a, layer_b)
    end
end

layers_swap_selective()

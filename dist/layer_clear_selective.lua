local __imports = {}
local __import_results = {}

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

__imports["library.layer"] = function()
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
    
    return layer

end

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.07"
    finaleplugin.Date = "2022/08/02"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.Notes = [[
        Clear all music from the chosen layer in the surrently selected region. 
        (The chosen layer will be cleared for the whole measure even if the measure is only partially selected).
    ]]
    return "Clear layer selective", "Clear layer selective", "Clear the chosen layer"
end

-- RetainLuaState retains global variable: config
local layer = require("library.layer")

function user_chooses_layer()
    local y_offset = 10
    local x_offset = 110
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box

    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    str.LuaString = "Clear Layer (1-4):"
    local static = dialog:CreateStatic(0, y_offset)
    static:SetText(str)
    static:SetWidth(x_offset)

    local layer_choice = dialog:CreateEdit(x_offset, y_offset - mac_offset)
    layer_choice:SetInteger(config.layer or 1)  -- default layer 1
    layer_choice:SetWidth(50)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        config.layer = layer_choice:GetInteger()
    end)
    dialog:RegisterCloseWindow(function()
        dialog:StorePosition()
        config.pos_x = dialog.StoredX
        config.pos_y = dialog.StoredY
    end)
    return dialog
end

function clear_layer()
    config = config or { layer = nil, pos_x = false, pos_y = false }
    local dialog = user_chooses_layer()

    if config.pos_x and config.pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
        dialog:RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK then
        return -- user cancelled
    end
    if not config.layer or config.layer < 1 or config.layer > 4 then
        finenv.UI():AlertNeutral("script: " .. plugindef(),
            "The layer number must be\nan integer between 1 and 4\n(not " .. config.layer .. ")")
        return
    end
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    layer.clear(finenv.Region(), config.layer)
end

clear_layer()

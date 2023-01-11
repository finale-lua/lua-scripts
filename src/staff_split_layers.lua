function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true -- not recognized by JW Lua or RGP Lua v0.55
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.AuthorURL = "https://www.robertgpatterson.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.0"
    finaleplugin.Date = "2023/1/11"
    finaleplugin.Notes = [[
        Chords from the source layers in the selected region are split into another layer on the same staff based on a split point. 
        Multiple measures and staves can be selected at once. 
        Articulations on the original are optionally copied to the other layer.
        
        The dialog box has the following options:
        
        - From Layer (1-4): the source layer to split from (defaults to 1)
        - To Layer (1-4): the target layer to split to (defaults to 2)
        - Split After (From Top): the number of chord tones to preserve in the source layer, counting from the top of each chord. All other notes are split to the target layer.
        - Copy Articulations: if checked, copies articulations from the source to the target.
        
    ]]
    return "Staff Split Layers...", "Staff Split Layers", "Split chords from one layer 1 into two independent layers, based on a split point."
end

local note_entry = require("library.note_entry")
local layer = require("library.layer")
local mixin = require("library.mixin")

function explode_one_slot(slot, split_from_top, source_layer, destination_layer, clone_artics)
    local region = finale.FCMusicRegion()
    region:SetCurrentSelection()
    region.StartSlot = slot
    region.EndSlot = slot
    region:SetStartMeasurePosLeft()
    region:SetEndMeasurePosRight()

    local start_measure = region.StartMeasure
    local end_measure = region.EndMeasure
    local staff = region:CalcStaffNumber(slot)

    layer.copy(region, source_layer, destination_layer, clone_artics)

    -- run through all entries and split by layer
    for entry in eachentrysaved(region) do
        if entry:IsNote() then
            local this_layer = entry.LayerNumber
            if this_layer == source_layer and entry.Count > split_from_top then
                for index = 0, entry.Count - split_from_top - 1 do
                    note_entry.delete_note(entry:GetItemAt(0))
                end
            end
            if this_layer == destination_layer then
                if entry.Count > split_from_top then
                    for index = 0, split_from_top - 1 do
                        note_entry.delete_note(entry:GetItemAt(entry.Count-1))
                    end
                else
                    note_entry.make_rest(entry)
                end
            end
        end
    end
end

function do_staff_split_layers()    
    local split_from_top = global_dialog:GetControl("split_after"):GetInteger()
    local source_layer = global_dialog:GetControl("from_layer"):GetInteger()
    local destination_layer = global_dialog:GetControl("to_layer"):GetInteger()
    local clone_artics = 0 ~= global_dialog:GetControl("clone_artics"):GetCheck()
    
    if source_layer < 1 or source_layer > layer.max_layers() then
        finenv.UI():AlertError("Invalid From Layer.", "Layer Number")
        return
    end
    if destination_layer < 1 or destination_layer > layer.max_layers() then
        finenv.UI():AlertError("Invalid To Layer.", "Layer Number")
        return
    end
    if source_layer == destination_layer then
        finenv.UI():AlertError("From and To layers must be different.", "Layer Number")
        return
    end
    if split_from_top <= 0 then
        finenv.UI():AlertError("Split After must be greater than zero.", "Split After")
        return
    end
    local region = finale.FCMusicRegion()
    if not region:SetCurrentSelection() then
        finenv.UI():AlertError("Please select music before executing this script.", "No Selection")
        return -- no selection
    end

    local undostr = "Split Layers " .. tostring(finenv.Region().StartMeasure)
    if finenv.Region().StartMeasure ~= finenv.Region().EndMeasure then
        undostr = undostr .. " - " .. tostring(finenv.Region().EndMeasure)
    end
    finenv.StartNewUndoBlock(undostr, false) -- this works on both JW Lua and RGP Lua
    for slot = region.StartSlot, region.EndSlot do
        explode_one_slot(slot, split_from_top, source_layer, destination_layer, clone_artics)
    end
    if finenv.EndUndoBlock then -- EndUndoBlock only exists on RGP Lua 0.56 and higher
        finenv.EndUndoBlock(true)
        finenv.Region():Redraw()
    else
        finenv.StartNewUndoBlock(undostr, true) -- JW Lua automatically terminates the final undo block we start here
    end
end

function create_dialog_box()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Split Layers")
    local current_y = 0
    local x_increment = 130
    local y_increment = 22
    local edit_width = 30
    -- from layer
    dialog:CreateStatic(0, current_y + 2)
        :SetWidth(x_increment - 5)
        :SetText("From Layer (1-4):")
    local edit_x = x_increment + (finenv.UI():IsOnMac() and 4 or 0)
    dialog:CreateEdit(edit_x, current_y, "from_layer")
        :SetWidth(edit_width)
        :SetInteger(1)
    current_y = current_y + y_increment
    -- to layer
    dialog:CreateStatic(0, current_y + 2)
        :SetWidth(x_increment - 5)
        :SetText("To Layer (1-4):")
    local edit_x = x_increment + (finenv.UI():IsOnMac() and 4 or 0)
    dialog:CreateEdit(edit_x, current_y, "to_layer")
        :SetWidth(edit_width)
        :SetInteger(2)
    current_y = current_y + y_increment
    -- notes to keep
    dialog:CreateStatic(0, current_y + 2)
        :SetWidth(x_increment - 5)
        :SetText("Split After (From Top):")
    local edit_x = x_increment + (finenv.UI():IsOnMac() and 4 or 0)
    dialog:CreateEdit(edit_x, current_y, "split_after")
        :SetWidth(edit_width)
        :SetInteger(1)
    current_y = current_y + y_increment
    -- clone articulations
    dialog:CreateCheckbox(0, current_y + 2, "clone_artics"):SetText("Copy Articulations")
        :SetWidth(x_increment)
        :SetCheck(1)
    -- ok/cancel
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
            do_staff_split_layers()
        end
    )
    return dialog
end

function staff_split_layers()
    global_dialog = global_dialog or create_dialog_box()
    global_dialog:RunModeless()
end

staff_split_layers()

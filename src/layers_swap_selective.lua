function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.56"
    finaleplugin.Date = "2022/08/07"
    finaleplugin.Notes = [[
        Swaps notes in the selected region between two chosen layers
    ]]
    return "Swap Layers Selective", "Swap Layers Selective", "Swaps notes in the selected region between two chosen layers"
end

-- RetainLuaState retains one global:
config = config or { layer_a = 1, layer_b = 2, pos_x = false, pos_y = false }
local layer = require("library.layer")
local mixin = require("library.mixin")

function any_errors()
    local error_message = ""
    if config.layer_a < 1 or  config.layer_a > 4 or config.layer_b < 1 or config.layer_b > 4  then 
        error_message = "Layer numbers must both\nbe integers between 1 and 4"
    elseif config.layer_a == config.layer_b  then 
        error_message = "Please choose two\ndifferent layer numbers"
    end
    if error_message ~= "" then  -- error dialog and exit
        finenv.UI():AlertNeutral("(script: " .. plugindef() .. ")", error_message)
        return true
    end
    return false
end

function swap_layers()
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    finenv.StartNewUndoBlock("Swap Layers Selective", false)
    layer.swap(finenv.Region(), config.layer_a, config.layer_b)
    if finenv.EndUndoBlock then
        finenv.EndUndoBlock(true)
        finenv.Region():Redraw()
    else
        finenv.StartNewUndoBlock("Swap Layers Selective", true)
    end
end

function create_dialog_box()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Swap Layers Selective")
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra horizontal offset for Mac edit box
    local offset_x = 105
    local offset_y = 22

    dialog:CreateStatic(0, mac_offset):SetText("swap layer# (1-4):"):SetWidth(offset_x)
    dialog:CreateEdit(offset_x, 0, "edit_a"):SetInteger(config.layer_a or 1)

    dialog:CreateStatic(5, offset_y + mac_offset):SetText("with layer# (1-4):"):SetWidth(offset_x)
    dialog:CreateEdit(offset_x, offset_y, "edit_b"):SetInteger(config.layer_b or 2)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.layer_a = self:GetControl("edit_a"):GetInteger()
        config.layer_b = self:GetControl("edit_b"):GetInteger()
    end)
    dialog:RegisterCloseWindow(function()
        dialog:StorePosition()
        config.pos_x = dialog.StoredX
        config.pos_y = dialog.StoredY
    end)

    return dialog
end

function layers_swap_selective()
    local dialog = create_dialog_box()
    if config.pos_x and config.pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
        dialog:RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK then
        return -- user cancelled
    end
    if any_errors() then
        return
    end
    swap_layers()
end

layers_swap_selective()

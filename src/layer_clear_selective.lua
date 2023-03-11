function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v1.12"
    finaleplugin.Date = "2023/02/28"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.Notes = [[
        Clear all music from the chosen layer in the currently selected region. 
        (The chosen layer will be cleared for a whole measure even if the measure is only partially selected).
    ]]
    return "Clear Layer Selective", "Clear Layer Selective", "Clear the chosen layer"
end

local layer = require("library.layer")
local mixin = require("library.mixin")

function is_error(max_layers)
    if config.layer < 1 or config.layer > max_layers then
        local message = "Layer number must be an\ninteger between 1 and ".. max_layers .. "\n(not " .. config.layer .. ")"
        finenv.UI():AlertInfo(message, "User Error")
        return true
    end
    return false
end

function user_dialog(region, max_layers)
    local y_offset = 3
    local x_offset = 140
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    local message = "Clear layer number (1-" .. max_layers .. "):"
    dialog:CreateStatic(0, y_offset)
        :SetText(message)
        :SetWidth(x_offset + 70)
    local layer_num = dialog:CreateEdit(x_offset, y_offset - mac_offset)
        :SetInteger(config.layer or 1)
        :SetWidth(50)
    local start = region.StartMeasure
    local stop = region.EndMeasure
    message = (start == stop) and ("measure " .. start) or ("measures " .. start .. " to " .. stop)
    dialog:CreateStatic(0, y_offset + 20)
        :SetText("from " .. message)
        :SetWidth(x_offset + 70)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        config.layer = layer_num:GetInteger()
        dialog:StorePosition()
        config.pos_x = dialog.StoredX
        config.pos_y = dialog.StoredY
    end)
    return dialog
end

function clear_layer()
    config = config or {} -- single global for ReatinLuaState
    local region = finenv.Region()
    local max_layers = layer.max_layers()
    local dialog = user_dialog(region, max_layers)

    if config.pos_x and config.pos_y then
        dialog:StorePosition()
            :SetRestorePositionOnlyData(config.pos_x, config.pos_y)
            :RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK or is_error(max_layers) then
        return -- user cancelled / entry error
    end
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    layer.clear(region, config.layer)
end

clear_layer()

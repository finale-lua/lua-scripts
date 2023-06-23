function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.11"
    finaleplugin.Date = "2023/06/23"
    finaleplugin.MinJWLuaVersion = 0.62
	finaleplugin.Notes = [[
        Set stems on a specific layer in the current selection to point up, down or in the "default" direction.
    ]]
    return "Stem Direction By Layer", "Stem Direction By Layer", "Change stem directions on a specific layer in the current selection"
end

local direction_choice = { "Up", "Down", "Default" }
local config = {
    direction = "Default",
    layer_num = 0,
    window_pos_x = false, -- saved dialog window position
    window_pos_y = false,
}
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local script_name = "stem_direction_by_layer"

function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

function user_choices()
    local max = layer.max_layers()
    local offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac EDIT box
    local edit_x = 110
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Choose Stem Direction:"):SetWidth(150)
    local y = 20
    local direction_list = dialog:CreateListBox(0, y):SetWidth(150):SetHeight(54)
    for i, v in ipairs(direction_choice) do
        direction_list:AddString(v)
        if v == config.direction then direction_list:SetSelectedItem(i - 1) end
    end
    y = y + 60
    dialog:CreateStatic(0, y + offset):SetText("Layer 1-" .. max .. " (0 = all):"):SetWidth(edit_x)
    local layer_num = dialog:CreateEdit(edit_x - 5, y):SetInteger(config.layer_num or 0):SetWidth(25)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        local n = layer_num:GetInteger()
        if n < 0 then n = 0
        elseif n > max then n = max
        end
        config.layer_num = n
        config.direction = direction_choice[direction_list:GetSelectedItem() + 1]
    end)
    dialog:RegisterInitWindow(function() direction_list:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function() dialog_save_position(dialog) end)
    dialog_set_position(dialog)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function stem_direction()
    configuration.get_user_settings(script_name, config, true)
    if user_choices() then -- otherwise user cancelled
        for entry in eachentrysaved(finenv.Region(), config.layer_num) do
            if entry:IsNote() then
                entry.FreezeStem = (config.direction ~= "Default")
                if config.direction ~= "Default" then
                    entry.StemUp = (config.direction == "Up")
                end
            end
        end
    end
end

stem_direction()

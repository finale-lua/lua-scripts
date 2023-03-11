function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Version = "v1.10"
    finaleplugin.Date = "2023/03/10"
    finaleplugin.AdditionalMenuOptions = [[
        Layer Unmute
    ]]
    finaleplugin.AdditionalUndoText = [[
        Layer Unmute
    ]]
    finaleplugin.AdditionalPrefixes = [[
        layer_playback = true
    ]]
    finaleplugin.AdditionalDescriptions = [[ 
        Unmute chosen layer in the current music selection
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.ScriptGroupName = "Layer Mute or Unmute"
    finaleplugin.ScriptGroupDescription = "Mute or unmute chosen layer in the current selection"
	finaleplugin.Notes = [[
		Change the playback state of the chosen layer or all layers in the current selection. 
		This script creates two menus, `Layer Mute` and `Layer Unmute`.
	]]
    return "Layer Mute", "Layer Mute", "Mute chosen layer(s) in the current selection"
end

-- default to "mute" layer for "normal" operation
layer_playback = layer_playback or false
-- RetainLuaState retains one global:
config = config or {}
local layer = require("library.layer")
local mixin = require("library.mixin")

function user_chooses_layer()
    local y_offset = 10
    local x_offset = 120
    local edit_width = 50
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box

    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle(layer_playback and "Layer Unmute" or "Layer Mute")
    dialog:CreateStatic(0, y_offset)
        :SetText("Layer# 1-" .. layer.max_layers() .. " (0 = all):")
        :SetWidth(x_offset)
    dialog:CreateEdit(x_offset, y_offset - mac_offset, "layer")
        :SetInteger(config.layer or 1)  -- default layer 1
        :SetWidth(edit_width)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.layer = self:GetControl("layer"):GetInteger()
    end)
    dialog:RegisterCloseWindow(function(self)
        self:StorePosition()
        config.pos_x = self.StoredX
        config.pos_y = self.StoredY
    end)
    return dialog
end

function change_state()
    local dialog = user_chooses_layer()

    if config.pos_x and config.pos_y then
        dialog:StorePosition()
            :SetRestorePositionOnlyData(config.pos_x, config.pos_y)
            :RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK then
        return -- user cancelled
    end
    local max = layer.max_layers()
    if not config.layer or config.layer < 0 or config.layer > max then
        finenv.UI():AlertInfo(
            "The layer number must be\nan integer between 0 and " .. max .. "\n(not " .. config.layer .. ")",
            "User Error"
        )
        return
    end
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    for entry in eachentrysaved(finenv.Region(), config.layer) do
        entry.Playback = layer_playback
    end
end

change_state()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Version = "v1.07"
    finaleplugin.Date = "2022/08/02"
    finaleplugin.AdditionalMenuOptions = [[
        Layer unhide
    ]]
    finaleplugin.AdditionalUndoText = [[
        Layer unhide
    ]]
    finaleplugin.AdditionalPrefixes = [[
        layer_visibility = true
    ]]
    finaleplugin.AdditionalDescriptions = [[ 
        Unhide selected layer in the current selection
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.ScriptGroupName = "Layers hide or unhide"
    finaleplugin.ScriptGroupDescription = "Hide or unhide chosen layers in the current selection"
	finaleplugin.Notes = [[
		Hide or unhide chosen layers in the current selection. 
		This script creates two menu item, `Layer hide` and `Layer unhide`. 
	]]
    return "Layer hide", "Layer hide", "Hide selected layer in the current selection"
end

-- default to "hide" layer for "normal" operation
layer_visibility = layer_visibility or false
-- RetainLuaState retains one global:
config = config or {}

function user_chooses_layer()
    local y_offset = 10
    local x_offset = 120
    local edit_width = 50
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box

    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = layer_visibility and "Layer unhide" or "Layer hide"
    dialog:SetTitle(str)

    str.LuaString = "Layer# 1-4 (0 = all):"
    local static = dialog:CreateStatic(0, y_offset)
    static:SetText(str)
    static:SetWidth(x_offset)

    local layer_choice = dialog:CreateEdit(x_offset, y_offset - mac_offset)
    layer_choice:SetInteger(config.layer or 1)  -- default layer 1
    layer_choice:SetWidth(edit_width)

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

function change_state()
    local dialog = user_chooses_layer()

    if config.pos_x and config.pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
        dialog:RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK then
        return -- user cancelled
    end
    if not config.layer or config.layer < 0 or config.layer > 4 then
        finenv.UI():AlertNeutral("script: " .. plugindef(),
            "The layer number must be\nan integer between 0 and 4\n(not " .. config.layer .. ")")
        return
    end
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    for entry in eachentrysaved(finenv.Region(), config.layer) do
        entry.Visible = layer_visibility
    end
end

change_state()
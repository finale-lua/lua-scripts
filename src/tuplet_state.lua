function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.53"
    finaleplugin.Date = "2023/04/22"
    finaleplugin.AdditionalMenuOptions = [[
        Tuplet State Visible
        Tuplet State Invisible
        Tuplet State Flat
        Tuplet State Not Flat
        Tuplet State Avoid Staff
        Tuplet State Don't Avoid Staff
        Tuplet State Set Active Layer...
    ]]
    finaleplugin.AdditionalUndoText = [[
        Tuplet State Visible
        Tuplet State Invisible
        Tuplet State Flat
        Tuplet State Not Flat
        Tuplet State Avoid Staff
        Tuplet State Don't Avoid Staff
        Tuplet State Set Active Layer
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Show tuplets in the current selection
        Hide tuplets in the current selection
        Make tuplets flat in the current selection
        Make tuplets not flat in the current selection
        Make tuplets avoid the staff
        Make tuplets not avoid the staff
        Set the active layer for Tuplet State
    ]]
    finaleplugin.AdditionalPrefixes = [[
        action = "show"
        action = "hide"
        action = "flat"
        action = "notflat"
        action = "avoid"
        action = "notavoid"
        action = "change_layer"
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.ScriptGroupName = "Tuplet State"
    finaleplugin.ScriptGroupDescription = "Change all tuplets in the selected region in seven ways"
    finaleplugin.Notes = [[
        Change the state of all tuplets in the selection via the menus provided:  

        - Tuplet State Visible
        - Tuplet State Invisible
        - Tuplet State Flat
        - Tuplet State Not Flat
        - Tuplet State Avoid Staff
        - Tuplet State Don't Avoid Staff
        - Tuplet State Reset (to Default Preferences)
        - Tuplet State Set Active Layer (for all actions)

        To change tuplets on a specific layer number choose the "Set Active Layer..." menu 
        or hold down the SHIFT or ALT (option) key when selecting a menu item. 
        The layer choice will persist until it is changed. 
	]]
    return "Tuplet State Reset", "Tuplet State Reset", "Reset tuplet state in the current selection to default preferences"
end

action = action or "reset"
local config = { layer_num = 0 }
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local script_name = "tuplet_state"
configuration.get_user_settings(script_name, config, true)

function change_active_layer()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Tuplet State")
    local max = layer.max_layers()
    dialog:CreateStatic(0, 0):SetWidth(180)
        :SetText("Set Layer Number 1-" .. max .. " (\"0\" = all):")
    dialog:CreateEdit(70, 20, "layer"):SetInteger(config.layer_num or 0):SetWidth(40)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
        local n = self:GetControl("layer"):GetInteger()
        if n < 0 then n = 0
        elseif n > max then n = max
        end
        config.layer_num = n
    end)
    return dialog
end

function tuplets_change()
    local mod_key = finenv.QueryInvokedModifierKeys and -- held modifier keys?
        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
            or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT) )
    if mod_key or action == "change_layer" then
        local dialog = change_active_layer()
        if (dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK) then return end -- User cancelled
        configuration.save_user_settings(script_name, config)
        if action == "change_layer" then return end -- no more action requested
    end

    for entry in eachentry(finenv.Region(), config.layer_num) do
        if entry:IsStartOfTuplet() then
            for tuplet in each(entry:CreateTuplets()) do
                if action == "hide" or action == "show" then
                    tuplet.Visible = (action == "show")
                elseif action == "flat" or action == "notflat" then
                    tuplet.AlwaysFlat = (action == "flat")
                elseif action == "avoid" or action == "notavoid" then
                    tuplet.AvoidStaff = (action == "avoid")
                elseif action == "reset" then
                    tuplet:PrefsReset(true)
                end
                tuplet:Save()
            end
        end
    end
end

tuplets_change()

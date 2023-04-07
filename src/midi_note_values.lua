function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.13"
    finaleplugin.Date = "2023/04/07"
    finaleplugin.CategoryTags = "MIDI"
    finaleplugin.MinJWLuaVersion = 0.63
    finaleplugin.AdditionalMenuOptions = [[
        MIDI Note Duration...
        MIDI Note Velocity...
    ]]
    finaleplugin.AdditionalUndoText = [[
        MIDI Note Duration
        MIDI Note Velocity
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Change the MIDI duration of notes by layer
        Change the MIDI velocity of notes by layer
    ]]
    finaleplugin.AdditionalPrefixes = [[
        action = 0
        action = 2
    ]]
    finaleplugin.ScriptGroupName = "MIDI Note Values"
    finaleplugin.ScriptGroupDescription = "Change the MIDI velocity and duration values of notes by layer"
    finaleplugin.Notes = [[
        Change the playback MIDI Velocity and Duration (Start/Stop times) 
        of every note in the currently selected music on one or all layers. 
        Choose the "MIDI Note Values" menu item to change both at once or set them independently with the  
        "MIDI Note Duration" and "MIDI Note Velocity" menu items.

        If Human Playback is active, "Velocity" and "Start/Stop Time" must be set to "HP Incorporate Data" at 
        [Finale -> Settings -> Human Playback -> MIDI Data] to affect playback. 
        Otherwise set "Key Velocities" and "Note Durations" to "Play Recorded" 
        under "Playback/Record Options" in the "Playback Controls" window. 
        Note that some playback samples don't respond to velocity settings. 

        Holding down the SHIFT or ALT (option) keys when invoking a menu item 
        will make the changes using your most recent values without showing any 
        confirmation dialog window (or any other visual confirmation!)
    ]]
    return "MIDI Note Values...", "MIDI Note Values", "Change the MIDI velocity and duration values of notes by layer"
end

action = action or 1 -- 0 = Duration only / 1 = Both / 2 = Velocity only
local config = {
    layer = 0,
    start_offset = 0,
    stop_offset = 0,
    velocity = 64,
    window_pos_x = false, -- saved dialog window position
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local script_name = "midi_note_values"

function user_error()
    local max = layer.max_layers()
    local msg = ""
    if config.layer < 0 or config.layer > max then
        msg = "Layer number must be an integer between zero and " .. max .. " (not " .. config.layer .. ").\n\n"
    end
    if (action <= 1) -- duration" or both
        and (math.abs(config.start_offset) > 9999 or math.abs(config.stop_offset) > 9999) then
        msg = msg .. "Offset levels must be reasonable, say -9999 to 9999 (not " ..
            config.start_offset .. " to " .. config.stop_offset .. "). \n\n"
    end
    if (action >= 1) -- "velocity" or both
        and (config.velocity < 0 or config.velocity > 127) then
        msg = msg .. "Velocity must be an integer between 0 and 127 (not " .. config.velocity .. "). "
    end
    if msg ~= "" then
        finenv.UI():AlertInfo(msg, "User Error")
        return true
    end
    return false
end

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
end

function user_choices(basekey)
    local offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac EDIT box
    local y, y_step = offset, 25
    local edit_x, e_wide = 120, 45

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    if (action <= 1) then -- "duration" or both
        dialog:CreateStatic(0, y):SetText("Start time (EDU):"):SetWidth(edit_x)
        dialog:CreateEdit(edit_x, y - offset, "start"):SetInteger(config.start_offset or 0):SetWidth(e_wide)
        y = y + y_step
        dialog:CreateStatic(0, y):SetText("Stop time (EDU):"):SetWidth(edit_x)
        dialog:CreateEdit(edit_x, y - offset, "stop"):SetInteger(config.stop_offset or 0):SetWidth(e_wide)
        y = y + y_step
    end
    if (action >= 1) then -- "velocity" or both
        dialog:CreateStatic(0, y):SetText("Key Velocity (0-127):"):SetWidth(edit_x)
        dialog:CreateEdit(edit_x, y - offset, "velocity"):SetInteger(config.velocity or basekey):SetWidth(e_wide)
        y = y + y_step
    end
    dialog:CreateStatic(0, y):SetText("Layer 1-4 (0 = all):"):SetWidth(edit_x)
    dialog:CreateEdit(edit_x, y - offset, "layer"):SetInteger(config.layer or 0):SetWidth(e_wide)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.layer = self:GetControl("layer"):GetInteger()
        if (action <= 1) then
            config.start_offset = self:GetControl("start"):GetInteger()
            config.stop_offset = self:GetControl("stop"):GetInteger()
        end
        if (action >= 1) then
            config.velocity = self:GetControl("velocity"):GetInteger()
        end
        dialog_save_position(self)
    end)
    dialog_set_position(dialog)
    return dialog
end

function change_values(basekey)
    for entry in eachentrysaved(finenv.Region(), config.layer) do
		if entry:IsNote() then
            local perf_mod = finale.FCPerformanceMod()
    		perf_mod:SetNoteEntry(entry)
    		for note in each(entry) do
    		    perf_mod:LoadAt(note)
                if action <= 1 then -- duration
                    if not note.Tie then -- don't change stop time of tied notes!
                        perf_mod.EndOffset = config.stop_offset
                    end
                    if not note.TieBackwards then
                        perf_mod.StartOffset = config.start_offset
                    end
                end
                if action >= 1 then -- velocity
                    perf_mod.VelocityDelta = config.velocity - basekey
                end
    		    perf_mod:SaveAt(note)
    		end
    	end
	end
end

function midi_note_values()
    configuration.get_user_settings(script_name, config, true)
    local basekey = 64
    if action >= 1 then -- velocity
        local prefs = finale.FCPlaybackPrefs()
        prefs:Load(1)
        basekey = prefs:GetBaseKeyVelocity()
    end

    local mod_down = finenv.QueryInvokedModifierKeys and
        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
         or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
        )
    if not mod_down then -- modifiers inhibit confirmation dialog
        local dialog = user_choices()
        if (dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK) or user_error() then
            return -- user cancelled or made a mistake
        end
        configuration.save_user_settings(script_name, config)
    end
    change_values(basekey)
end

midi_note_values()

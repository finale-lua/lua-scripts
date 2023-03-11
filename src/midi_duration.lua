function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.43"
    finaleplugin.Date = "2023/03/10"
    finaleplugin.CategoryTags = "MIDI, Playback"
    finaleplugin.Notes = [[
    Change the playback START and STOP times for every note in the selected area in one or all layers. 
    To affect playback "Note Durations" must be enabled under "Playback/Record Options".
    ]]
    return "MIDI Duration", "MIDI Duration", "Change MIDI note start and stop times"
end

-- RetainLuaState retains one global:
config = config or {}
local mixin = require("library.mixin")
local layer = require("library.layer")

function is_error()
    local max = layer.max_layers()
    local msg = ""
    if math.abs(config.start_offset) > 9999 or math.abs(config.stop_offset) > 9999 then
        msg = "Offset levels must be reasonable,\nsay -9999 to 9999\n(not " ..
            config.start_offset .. "/" .. config.stop_offset .. ")"
    elseif config.layer < 0 or config.layer > max then
        msg = "Layer number must be an\ninteger between zero and " .. max .. "\n(not " .. config.layer .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertInfo(msg, "User Error")
        return true
    end
    return false
end

function user_choices()
    local current_vert, vert_step = 10, 25
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local edit_horiz = 110

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    local edit_boxes = { -- static text, default value
        { "Start time (EDU):", config.start_offset or 0, "start_offset" },
        { "Stop time (EDU):", config.stop_offset or 0, "stop_offset" },
        { "Layer 1-4 (0 = all):", config.layer or 0, "layer" },
    }

    for _,v in ipairs(edit_boxes) do
        dialog:CreateStatic(0, current_vert):SetText(v[1]):SetWidth(edit_horiz)
        dialog:CreateEdit(edit_horiz, current_vert - mac_offset, v[3]):SetInteger(v[2])
        current_vert = current_vert + vert_step
    end

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
        for _,v in ipairs(edit_boxes) do
            config[v[3]] = self:GetControl(v[3]):GetInteger()
        end
        self:StorePosition()
        config.pos_x = self.StoredX
        config.pos_y = self.StoredY
    end)
    return dialog
end

function make_the_change()
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    for entry in eachentrysaved(finenv.Region(), config.layer) do
        local perf_mod = finale.FCPerformanceMod()
		if entry:IsNote() then
    		perf_mod:SetNoteEntry(entry)
    		for note in each(entry) do
    		    perf_mod:LoadAt(note)     -- don't change durations of tied notes!
    		    if not note.TieBackwards then
                    perf_mod.StartOffset = config.start_offset
                end
        		if not note.Tie then
                    perf_mod.EndOffset = config.stop_offset
                end
    		    perf_mod:SaveAt(note)
    		end
    	end
	end
end

function change_midi_duration()
    local dialog = user_choices()
    if config.pos_x and config.pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
        dialog:RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK or is_error() then
        return -- user cancelled or made a mistake
    end
    make_the_change()
end

change_midi_duration()

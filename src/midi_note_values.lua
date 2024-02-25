function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.22"
    finaleplugin.Date = "2024/02/03"
    finaleplugin.CategoryTags = "MIDI"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.AdditionalMenuOptions = [[
        MIDI Note Duration...
        MIDI Note Velocity...
    ]]
    finaleplugin.AdditionalUndoText = [[
        MIDI Note Duration
        MIDI Note Velocity
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Change the MIDI duration of notes on a chosen layer
        Change the MIDI velocity of notes on a chosen layer
    ]]
    finaleplugin.AdditionalPrefixes = [[
        action = 0
        action = 2
    ]]
    finaleplugin.ScriptGroupName = "MIDI Note Values"
    finaleplugin.ScriptGroupDescription = "Change the MIDI velocity and duration of notes on a chosen layer"
    finaleplugin.Notes = [[
        Change the playback __MIDI Velocity__ and __Duration__ (Start/Stop times) 
        of every note in the currently selected music on one or all layers. 
        Choose the _MIDI Note Values_ menu item to change both at once or set them 
        independently with _MIDI Note Duration_ and _MIDI Note Velocity_.  

        To affect playback when _Human Playback_ is active you must set 
        _Velocity_ and _Start/Stop Time_ to __HP Incorporate Data__ at 
        _Settings_ → _Human Playback_ → _MIDI Data_. 
        Otherwise set _Key Velocities_ and _Note Durations_ to __Play Recorded__ 
        under _Playback/Record Options_ in the _Playback Controls_ window. 
        Note that some playback samples don't respond to velocity settings. 

        Hold down [Shift] when opening the script to 
        repeat your last choices without a confirmation dialog. 
        Layer number is "clamped" to a single character so to change 
        layer just type a new number - delete key not needed.  
    ]]
    return "MIDI Note Values...",
        "MIDI Note Values",
        "Change the MIDI velocity and duration of notes on a chosen layer"
end

action = action or 1 -- 0 = Duration only / 1 = Both / 2 = Velocity only

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local focus_document = false -- set to true if utils.show_notes_dialog is used

local config = {
    layer = 0,
    start_offset = 0,
    stop_offset = 0,
    velocity = 64,
    window_pos_x = false, -- saved dialog window position
    window_pos_y = false,
}
local options = { -- key; text description
    start_offset = "Start time (EDU):",
    stop_offset  = "Stop time (EDU):",
    velocity     = "Key Velocity (0-127):",
    layer        = "Layer 1-" .. layer.max_layers() .. " (0 = all):"
}

local function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function user_choices()
    local offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac EDIT box
    local y, y_step = offset, 25
    local edit_x, e_wide = 120, 45
    local saved = {}
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(finaleplugin.ScriptGroupName)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. finaleplugin.ScriptGroupName, 400, 247)
            focus_document = true -- return focus to document
        end
        local function key_check(ctl, name) -- inhibit alphabetic keys and some negation
            local val = ctl:GetText()
            if      val:find("[^-0-9]")
                    or (name == "layer" and val:find("[^0-" .. layer.max_layers() .. "]"))
                    or (name == "velocity" and val:find("-"))
                    then
                if val:find("[?q]") then show_info() end
                ctl:SetText(saved[name]):SetKeyboardFocus()
            elseif val ~= "" then
                if name == "layer" then
                    val = val:sub(-1) -- one character only
                elseif name == "velocity" then
                    if tonumber(val) > 127 then val = "127" end
                else -- EDU offsets
                    local num_chars = (val:sub(1,1) == "-") and 5 or 4
                    val = val:sub(1, num_chars) -- 4/5 characters max
                end
                ctl:SetText(val)
                saved[name] = val
            end
        end
        local function create_value(name)
            saved[name] = config[name] -- restore config values
            dialog:CreateStatic(0, y):SetText(options[name]):SetWidth(edit_x)
            dialog:CreateEdit(edit_x, y - offset, name):SetText(saved[name])
                :SetWidth((name == "layer") and 20 or e_wide)
                :AddHandleCommand(function(self) key_check(self, name) end)
            y = y + y_step
        end

    if (action <= 1) then -- "duration" or both
        create_value("start_offset")
        create_value("stop_offset")
    end
    if (action >= 1) then -- "velocity" or both
        create_value("velocity")
    end
    create_value("layer") -- always
    dialog:CreateButton(edit_x + 26, y - y_step):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
        for k, _ in pairs(options) do
            local ctl = self:GetControl(k)
            if ctl then config[k] = ctl:GetInteger() end
        end
    end)
    dialog_set_position(dialog)
    dialog:RegisterCloseWindow(function() dialog_save_position(dialog) end)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK)
end

function change_values()
    local prefs = finale.FCPlaybackPrefs()
    prefs:Load(1)
    local basekey = prefs:GetBaseKeyVelocity()

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
    local qim = finenv.QueryInvokedModifierKeys
    local mod_down = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    if mod_down or user_choices() then
        change_values()
    end
    if focus_document then finenv.UI():ActivateDocumentWindow() end
end

midi_note_values()

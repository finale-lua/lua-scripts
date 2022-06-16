function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.2"
    finaleplugin.Date = "2022/06/14"
    finaleplugin.CategoryTags = "MIDI, Playback"
    finaleplugin.Notes = [[
    Change the playback Key Velocity for every note in the selected area in one or all layers. 
    "Key Velocities" must be enabled under "Playback/Record Options" to affect playback. 
    Note that key velocity will not affect every type of playback especially if Human Playback is active. 

    Side-note: selecting the MIDI tool, choosing "Velocity" then "Set to" is moderately convenient 
    but doesn't offer setting key velocity on a single chosen layer. 
    This script also remembers your choices between invocations.
]]
    return "MIDI Velocity", "MIDI Velocity", "Change MIDI Velocity"
end

-- RetainLuaState will return global variables:
-- key_velocity and layer_number

function show_error(error_type, actual_value)
    local errors = {
        bad_velocity = "Velocity must be an\ninteger between 0 and 127\n(not ",
        bad_layer_number = "Layer number must be an\ninteger between zero and 4\n(not ",
    }
    finenv.UI():AlertNeutral("script: " .. plugindef(), errors[error_type] .. actual_value .. ")")
end

function get_user_choices(basekey)
    local current_vert, vert_step = 10, 25
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local edit_horiz = 120

    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    local answer = {}
    local texts = { -- static text, default value
        { "Key Velocity (0-127):", key_velocity or basekey },
        { "Layer 1-4 (0 = all):", layer_number or 0 },
    }
    for i,v in ipairs(texts) do
        str.LuaString = v[1]
        local static = dialog:CreateStatic(0, current_vert)
        static:SetText(str)
        static:SetWidth(edit_horiz)
        answer[i] = dialog:CreateEdit(edit_horiz, current_vert - mac_offset)
        answer[i]:SetInteger(v[2])
        current_vert = current_vert + vert_step
    end

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK), answer[1]:GetInteger(), answer[2]:GetInteger()
end

function change_velocity()
    local prefs = finale.FCPlaybackPrefs()
    prefs:Load(1)
    local basekey = prefs:GetBaseKeyVelocity()

    local is_ok = false -- key_velocity and layer_number are globals
    is_ok, key_velocity, layer_number = get_user_choices(basekey)
    if not is_ok then -- user cancelled
        return
    end
    if key_velocity < 0 or key_velocity > 127 then
        show_error("bad_velocity", key_velocity)
        return
    end
    if layer_number < 0 or layer_number > 4 then 
        show_error("bad_layer_number", layer_number)
        return
    end
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end

    -- don't forget to offset velocity to playback "base" velocity
    for entry in eachentrysaved(finenv.Region(), layer_number) do
        local pm = finale.FCPerformanceMod()
		if entry:IsNote() then    
		    pm:SetNoteEntry(entry)
    		for note in each(entry) do
    		    pm:LoadAt(note)
    		    pm.VelocityDelta = key_velocity - basekey
    		    pm:SaveAt(note)
    		end
    	end
	end
end

change_velocity()

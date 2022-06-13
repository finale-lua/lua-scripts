function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.3"
    finaleplugin.Date = "2022/06/13"
    finaleplugin.CategoryTags = "MIDI"
    finaleplugin.Notes = [[
    Change the playback START and STOP times for every note in the selected area on one or all layers. 
    To affect playback "Note Durations" must be enabled under "Playback/Record Options".
]]
    return "MIDI Duration", "MIDI Duration", "Change MIDI note start and stop times"
end

-- RetainLuaState will return global variables:
-- start_offset, stop_offset and layer_number

function show_error(error_type, actual_value)
    local errors = {
        bad_offset = "Offset times must be reasonable,\nsay -9999 to 9999\n(not ",
        bad_layer_number = "Layer number must be an\ninteger between zero and 4\n(not ",
    }
    finenv.UI():AlertNeutral("script: " .. plugindef(), errors[error_type] .. actual_value .. ")")
end

function get_user_choices()
    local current_vert, vert_step = 10, 25
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local edit_horiz = 120
    
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    local answer = {}
    local texts = { -- static text, default value
        { "Start time:", start_offset or 0 },
        { "Stop time:", stop_offset or 0 },
        { "Layer# 1-4 (0 = all):", layer_number or 0 },
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
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK), 
        answer[1]:GetInteger(), answer[2]:GetInteger(), answer[3]:GetInteger()
end

function change_midi_duration()
    local ok = false
    is_ok, start_offset, stop_offset, layer_number = get_user_choices()
    if not is_ok then
        return
    end -- user cancelled
    
    if start_offset < -9999 or start_offset > 9999 or stop_offset < -9999 or stop_offset > 9999 then
        show_error("bad_offset", start_offset .. " / " .. stop_offset)
        return
    end
    if layer_number < 0 or layer_number > 4 then
        show_error("bad_layer_number", layer_number)
        return
    end
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end

    for entry in eachentrysaved(finenv.Region(), layer_number) do
        local perf_mod = finale.FCPerformanceMod()
		if entry:IsNote() then
    		perf_mod:SetNoteEntry(entry)
    		for note in each(entry) do
    		    perf_mod:LoadAt(note)     -- don't change durations of tied notes!
    		    if not note.TieBackwards then
                    perf_mod.StartOffset = start_offset
                end
        		if not note.Tie then
                    perf_mod.EndOffset = stop_offset
                end
    		    perf_mod:SaveAt(note)
    		end
    	end
	end
end

change_midi_duration()

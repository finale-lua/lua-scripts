function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.41"
    finaleplugin.Date = "2022/08/04"
    finaleplugin.CategoryTags = "MIDI, Playback"
    finaleplugin.Notes = [[
    Change the playback START and STOP times for every note in the selected area in one or all layers. 
    To affect playback "Note Durations" must be enabled under "Playback/Record Options".
    ]]
    return "MIDI Duration", "MIDI Duration", "Change MIDI note start and stop times"
end

-- RetainLuaState retains one global:
config = config or {}

function is_error()
    local msg = ""
    if math.abs(config.start_offset) > 9999 or math.abs(config.stop_offset) > 9999 then
        msg = "Offset levels must be reasonable,\nsay -9999 to 9999\n(not " .. 
            config.start_offset .. "/" .. config.stop_offset .. ")"
    elseif config.layer < 0 or config.layer > 4 then
        msg = "Layer number must be an\ninteger between zero and 4\n(not " .. config.layer .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertNeutral("script: " .. plugindef(), msg)
        return true
    end
    return false
end

function user_choices()
    local current_vert, vert_step = 10, 25
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local edit_horiz = 110
    
    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    local answer = {}
    local texts = { -- static text, default value
        { "Start time (EDU):", config.start_offset or 0 },
        { "Stop time (EDU):", config.stop_offset or 0 },
        { "Layer 1-4 (0 = all):", config.layer or 0 },
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
    dialog:RegisterHandleOkButtonPressed(function()
        config.start_offset = answer[1]:GetInteger()
        config.stop_offset = answer[2]:GetInteger()
        config.layer = answer[3]:GetInteger()
    end)
    dialog:RegisterCloseWindow(function()
        dialog:StorePosition()
        config.pos_x = dialog.StoredX
        config.pos_y = dialog.StoredY
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
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK then
        return -- user cancelled
    end
    if is_error() then
        return
    end
    make_the_change()
end

change_midi_duration()

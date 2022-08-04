function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.21"
    finaleplugin.Date = "2022/08/04"
    finaleplugin.CategoryTags = "MIDI, Playback"
    finaleplugin.Notes = [[
    Change the playback Key Velocity for every note in the selected area in one or all layers. 
    "Key Velocities" must be enabled under "Playback/Record Options" to affect playback. 
    Note that key velocity will not affect every type of playback especially if Human Playback is active. 

    Side-note: selecting the MIDI tool, choosing "Velocity" then "Set to" is moderately convenient 
    but doesn't allow setting key velocity on a single chosen layer. 
    This script also remembers your choices between invocations.
    ]]
    return "MIDI Velocity", "MIDI Velocity", "Change MIDI Velocity"
end

-- RetainLuaState retains one global:
config = config or {}

function is_error()
    local msg = ""
    if config.velocity < 0 or config.velocity > 127 then
        msg = "Velocity must be an\ninteger between 0 and 127\n(not " .. config.velocity .. ")"
    elseif config.layer < 0 or config.layer > 4 then
        msg = "Layer number must be an\ninteger between zero and 4\n(not " .. config.layer .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertNeutral("script: " .. plugindef(), msg)
        return true
    end
    return false
end

function user_choices(basekey)
    local current_vert, vert_step = 10, 25
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local edit_horiz = 110

    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    local answer = {}
    local texts = { -- static text, default value
        { "Key Velocity (0-127):", config.velocity or basekey },
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
        config.velocity = answer[1]:GetInteger()
        config.layer = answer[2]:GetInteger()
    end)
    dialog:RegisterCloseWindow(function()
        dialog:StorePosition()
        config.pos_x = dialog.StoredX
        config.pos_y = dialog.StoredY
    end)
    return dialog
end

function make_the_change(basekey)
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    for entry in eachentrysaved(finenv.Region(), config.layer) do
        local pm = finale.FCPerformanceMod()
        if entry:IsNote() then
            pm:SetNoteEntry(entry)
            for note in each(entry) do
                pm:LoadAt(note)
                pm.VelocityDelta = config.velocity - basekey
                pm:SaveAt(note)
            end
        end
    end
end

function change_velocity()
    local prefs = finale.FCPlaybackPrefs()
    prefs:Load(1)
    local basekey = prefs:GetBaseKeyVelocity()

    local dialog = user_choices(basekey)
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
    make_the_change(basekey)
end

change_velocity()

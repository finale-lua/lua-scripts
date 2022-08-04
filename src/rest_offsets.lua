function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Version = "v1.36"
    finaleplugin.Date = "2022/08/03"
    finaleplugin.Notes = [[
    Several situations including cross-staff notation (rests should be centred between the staves) 
    require adjusting the vertical position (offset) of rests. 
    This script duplicates the action of Finale's inbuilt "Move rests..." plug-in but needs no mouse activity. 
    It is also an easy way to reset rest offsets to zero in every layer, the default setting. 
    (An offest of zero centres on the middle staff line.)
]]
   return "Rest Offsets", "Rest Offsets", "Rest vertical offsets"
end

-- RetainLuaState retains one global:
config = config or {}

function is_error()
    local msg = ""
    if math.abs(config.offset) > 20 then
        msg = "Offset level must be reasonable,\nsay -20 to 20\n(not " .. config.offset .. ")"
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
    local horizontal = 110
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local answer = {}
    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    local texts = { -- text, default value, vertical_position
        { "Vertical offset:", config.offset or 0, 15 },
        { "Layer# 1-4 (0 = all):", config.layer or 0, 50  },
    }
    for i, v in ipairs(texts) do -- create labels and edit boxes
        str.LuaString = v[1]
        local static = dialog:CreateStatic(0, v[3])
        static:SetText(str)
        static:SetWidth(horizontal)
        answer[i] = dialog:CreateEdit(horizontal, v[3] - mac_offset)
        answer[i]:SetInteger(v[2])
        answer[i]:SetWidth(50)
    end

    texts = { -- offset number / horizontal offset / description /  vertical position
        {  "4", 5, "= top staff line", 0},
        {  "0", 5, "= middle staff line", 15 },
        { "-4", 0, "= bottom staff line", 30 },
        { "", 0, "(for 5-line staff)", 45 },
    }
    for _, v in ipairs(texts) do -- static text information lines
        str.LuaString = v[1]
        dialog:CreateStatic(horizontal + 60 + v[2], v[4]):SetText(str)
        local static = dialog:CreateStatic(horizontal + 75, v[4])
        str.LuaString = v[3]
        static:SetText(str)
        static:SetWidth(horizontal)
    end

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        config.offset = answer[1]:GetInteger()
        config.layer = answer[2]:GetInteger()
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
        if entry:IsRest() then
            if config.offset == 0 then
                entry:SetFloatingRest(true)
            else
                local rest_prop = "OtherRestPosition"
                local duration = entry.Duration
                if duration >= finale.BREVE then
                    rest_prop = "DoubleWholeRestPosition"
                elseif duration >= finale.WHOLE_NOTE then
                    rest_prop = "WholeRestPosition"
                elseif duration >= finale.HALF_NOTE then
                    rest_prop = "HalfRestPosition"
                end
                local staff_spec = finale.FCCurrentStaffSpec()
                staff_spec:LoadForEntry(entry)
                local total_offset = staff_spec[rest_prop] + config.offset
                entry:MakeMovableRest()
                local rest = entry:GetItemAt(0)
                local curr_staffpos = rest:CalcStaffPosition()
                entry:SetRestDisplacement(entry:GetRestDisplacement() + total_offset - curr_staffpos)
            end
        end
    end
end

function change_rest_offset()
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

change_rest_offset()

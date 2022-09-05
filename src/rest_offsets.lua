function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Version = "v1.40"
    finaleplugin.Date = "2022/09/05"
    finaleplugin.Notes = [[
        Several situations including cross-staff notation (rests should be centred between the staves) 
        require adjusting the vertical position (offset) of rests. 
        This script duplicates the action of Finale's inbuilt "Move rests..." plug-in but needs no mouse activity. 
        It is also an easy way to reset rest offsets to zero in every layer, the default setting. 

        Newly created rests are "floating" and will avoid entries in other layers (if present) 
        using the setting for "Adjust Floating Rests by..." in `Document Options...` -> `Layers`.  
        This script stops them "floating", instead "fixing" them to a specific offset from the middle staff line. 
        To return them to "floating", select the "Zero = Floating Rest" checkbox and set the offset to zero.
    ]]
   return "Rest Offsets", "Rest Offsets", "Rest vertical offsets"
end

local mixin = require("library.mixin")

-- ================= SCRIPT BEGINS =================================
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

function make_dialog()
    local horizontal = 110
    local y_level = {15, 45, 75}
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac Edit box
    local answer = {}
    local dialog = mixin.FCXCustomLuaWindow():SetTitle( plugindef() )

    local texts = { -- text, default value, vertical_position
        { "Vertical offset:", config.offset or 0, y_level[1] },
        { "Layer# 1-4 (0 = all):", config.layer or 0, y_level[2]  },
    }
    for i, v in ipairs(texts) do -- create labels and edit boxes
        dialog:CreateStatic(0, v[3]):SetText(v[1]):SetWidth(horizontal)
        answer[i] = dialog:CreateEdit(horizontal, v[3] - mac_offset):SetInteger(v[2]):SetWidth(50)
    end
    local checked = config.zero_floating and 1 or 0
    answer[3] = dialog:CreateCheckbox(0, texts[2][3] + 30):SetText("Zero = Floating Rest"):SetWidth(horizontal * 2):SetCheck(checked)

    texts = { -- offset number / horizontal offset / description /  vertical position
        {  "4", 5, "= top staff line", 0 },
        {  "0", 5, "= middle staff line", 15 },
        { "-4", 0, "= bottom staff line", 30 },
        { "", 0, "(for 5-line staff)", 45 },
    }
    for _, v in ipairs(texts) do -- static text information lines
        dialog:CreateStatic(horizontal + 60 + v[2], v[4]):SetText(v[1])
        dialog:CreateStatic(horizontal + 75, v[4]):SetText(v[3]):SetWidth(horizontal)
    end

    dialog:CreateButton(128, y_level[3]):SetText("?"):SetWidth(20):AddHandleCommand(function(self)
        local msg = "Newly created rests are \"floating\" and will avoid entries in other layers (if present) "
        .. "using the setting for \"Adjust Floating Rests by...\" in \"Document Options...\" -> \"Layers\". \n\n"
        .. "This script stops rests \"floating\", instead \"fixing\" them to a specific offset from the middle staff line. "
        .. "To return them to \"floating\", select the \"Zero = Floating Rest\" option and set the offset to zero."
        finenv.UI():AlertNeutral(msg, "Rest Offsets Info")
    end)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        config.offset = answer[1]:GetInteger()
        config.layer = answer[2]:GetInteger()
        config.zero_floating = (answer[3]:GetCheck() == 1)
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
            if config.offset == 0 and config.zero_floating then
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
    local dialog = make_dialog()
    if config.pos_x and config.pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
        dialog:RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK or is_error() then
        return -- user cancelled OR data error
    end
    make_the_change()
end

change_rest_offset()

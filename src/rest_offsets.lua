function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Version = "v1.45"
    finaleplugin.Date = "2023/03/10"
    finaleplugin.Notes = [[
        Several situations including cross-staff notation (rests should be centred between the staves) 
        require adjusting the vertical position of rests. 
        This script duplicates the action of Finale's inbuilt "Move rests..." plug-in but needs no mouse activity. 
        It is also an easy way to reset rest positions in every layer, the default setting. 

        Newly created rests are "floating" and will avoid entries in other layers (if present) 
        following the setting for "Adjust Floating Rests by..." in `Document Options...` -> `Layers`.  
        This script stops them "floating", instead "fixing" them to a specific offset from their default position. 
        To return them to "floating", select the "Zero = Floating Rest" checkbox and set the offset to zero.  

        The offset is measured in "steps" where there are 8 equal steps (4 "spaces") between the top and bottom staff lines. 
        If the default rest position is anchored to the middle staff line, 
        "4" anchors it to the top staff line and "-4" anchors it to the bottom one.
    ]]
   return "Rest Offsets", "Rest Offsets", "Change vertical offsets of rests by layer"
end

local mixin = require("library.mixin")
local layer = require("library.layer")

-- ================= SCRIPT BEGINS =================================
-- RetainLuaState retains one global:
config = config or {}

function is_error()
    local max = layer.max_layers()
    local msg = ""
    if math.abs(config.offset) > 20 then
        msg = "Offset level must be reasonable,\nsay between -20 and 20\n(not " .. config.offset .. ")"
    elseif config.layer < 0 or config.layer > max then
        msg = "Layer number must be an\ninteger between zero and " .. max .. "\n(not " .. config.layer .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertInfo(msg, "User Error")
        return true
    end
    return false
end

function make_dialog()
    local x_offset = 110
    local y_level = {15, 45, 75}
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac Edit box
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())

    local texts = { -- text, default value, vertical_position
        { "Vertical offset:", config.offset or 0, y_level[1], "offset" },
        { "Layer# 1-" .. layer.max_layers() .. " (0 = all):", config.layer or 0, y_level[2], "layer"  },
    }
    for _, v in ipairs(texts) do -- create labels and edit boxes
        dialog:CreateStatic(0, v[3]):SetText(v[1]):SetWidth(x_offset)
        dialog:CreateEdit(x_offset, v[3] - mac_offset, v[4]):SetInteger(v[2]):SetWidth(50)
    end
    local checked = config.zero_floating and 1 or 0
    dialog:CreateCheckbox(0, y_level[3], "zero"):SetText("Zero = Floating Rest"):SetWidth(x_offset * 2):SetCheck(checked)

    texts = { -- offset number / x_offset offset / description /  vertical position
        {  "4", 5, "= top staff line", 0 },
        {  "0", 5, "= middle staff line", 15 },
        { "-4", 0, "= bottom staff line", 30 },
        { "", 0, "(for 5-line staff)", 45 },
    }
    for _, v in ipairs(texts) do -- static text information lines
        dialog:CreateStatic(x_offset + 60 + v[2], v[4]):SetText(v[1])
        dialog:CreateStatic(x_offset + 75, v[4]):SetText(v[3]):SetWidth(x_offset)
    end

    dialog:CreateButton(128, y_level[3]):SetText("?"):SetWidth(20):AddHandleCommand(function(self)
        local msg = "Newly created rests are \"floating\" and will avoid entries in other layers (if present) "
        .. "using the setting for \"Adjust Floating Rests by...\" in \"Document Options...\" -> \"Layers\". \n\n"
        .. "This script stops rests \"floating\", instead \"fixing\" them to a specific offset from the middle staff line. "
        .. "To return them to \"floating\", select the \"Zero = Floating Rest\" option and set the offset to zero."
        finenv.UI():AlertInfo(msg, "Rest Offsets Info")
    end)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.offset = self:GetControl("offset"):GetInteger()
        config.layer = self:GetControl("layer"):GetInteger()
        config.zero_floating = (self:GetControl("zero"):GetCheck() == 1)
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
            :SetRestorePositionOnlyData(config.pos_x, config.pos_y)
            :RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK or is_error() then
        return -- user cancelled or data error
    end
    make_the_change()
end

change_rest_offset()

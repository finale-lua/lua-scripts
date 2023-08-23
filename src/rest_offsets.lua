function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v1.52"
    finaleplugin.Date = "2023/07/26"
    finaleplugin.Notes = [[ 
        This script alters the vertical position of rests. 
        It duplicates Finale's inbuilt "Move Rests..." plug-in but with less mouse activity. 
        It is also a quick way to reset rest positions in every layer, the default setting.

        New rests are "floating" and will avoid entries in other layers (if present) 
        using the setting for "Adjust Floating Rests by..." at Finale → Document → Document Options → Layers.  
        This script can stop rests "floating", instead "fixing" them to a specific offset from the default position. 
        On transposing staves such "fixed" rests will behave like actual notes and change position 
        if "Display in Concert Pitch" is selected. 
        Set the "Floating Rests" checkbox to return all rests on the chosen layer to "floating".

        A "space" is the vertical distance between staff lines, and a "step" is half a space. 
        The distance between the top and bottom lines of a 5-line staff is 4 spaces or 8 steps. 
        Rests usually "centre" on the middle staff line, 4 steps below the top line of a 5-line staff. 
        This script, like Finale, uses "step" offsets to shift rests relative to the default position. 
    ]]
    return "Rest Offsets...", "Rest Offsets", "Change the vertical offset of rests by layer"
end

-- RetainLuaState retains one global:
config = config or {
    offset = 0,
    layer = 0,
    make_floating = 0,
    pos_x = false,
    pos_y = false
}
local mixin = require("library.mixin")
local layer = require("library.layer")
local note_entry = require("library.note_entry")

function no_errors()
    local max = layer.max_layers()
    local msg = ""
    if math.abs(config.offset) > 20 then
        msg = "Offset level must be reasonable, say between -20 and 20 (not " .. config.offset .. ")\n\n"
    end
    if config.layer < 0 or config.layer > max then
        msg = msg .. "Layer number must be an integer\nbetween 0 and " .. max .. " (not " .. config.layer .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertInfo(msg, "User Error")
        return false
    end
    return true
end

function make_dialog()
    local x = 110
    local y_grid = { 15, 45, 70 }
    local x_off = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac Edit box
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())

    local stat = dialog:CreateStatic(0, y_grid[1]):SetText("Vertical offset:")
        :SetWidth(x):SetEnable(config.make_floating == 0)
    local offset = dialog:CreateEdit(x, y_grid[1] - x_off):SetInteger(config.offset)
        :SetWidth(50):SetEnable(config.make_floating == 0)
    dialog:CreateStatic(0, y_grid[2]):SetText("Layer 1-" .. layer.max_layers() .. " (0 = all)"):SetWidth(x)
    local layer_num = dialog:CreateEdit(x, y_grid[2] - x_off):SetInteger(config.layer):SetWidth(50)

    local float = dialog:CreateCheckbox(0, y_grid[3]):SetText("Floating Rests")
        :SetCheck(config.make_floating):SetWidth(x * 2)
        :AddHandleCommand(function(self)
            offset:SetEnable(self:GetCheck() == 0)
            stat:SetEnable(self:GetCheck() == 0)
        end)

    texts = { -- offset number / x offset / description /  vertical position
        {  "4", 5, "= top staff line",    0 },
        {  "0", 5, "= middle staff line", 15 },
        { "-4", 0, "= bottom staff line", 30 },
        { "",   0, "(for 5-line staff)",  45 },
    }
    for _, v in ipairs(texts) do -- static text information lines
        dialog:CreateStatic(x + 60 + v[2], v[4]):SetText(v[1])
        dialog:CreateStatic(x + 75, v[4]):SetText(v[3]):SetWidth(x)
    end
    dialog:CreateButton(x * 2 + 45, y_grid[3]):SetText("?"):SetWidth(20)
        :AddHandleCommand(function()
            finenv.UI():AlertInfo(finaleplugin.Notes:gsub(" %s+", " "), "About " .. plugindef())
        end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.offset = offset:GetInteger()
        config.layer = layer_num:GetInteger()
        config.make_floating = float:GetCheck()
    end)
    dialog:RegisterCloseWindow(function(self)
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
            if (config.make_floating == 1) then
                entry:SetFloatingRest(true)
            else
                note_entry.rest_offset(entry, config.offset)
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
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK and no_errors() then
        make_the_change()
    end
end

change_rest_offset()

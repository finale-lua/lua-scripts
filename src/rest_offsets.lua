function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v1.57"
    finaleplugin.Date = "2023/10/30"
    finaleplugin.Notes = [[ 
        This script alters the vertical position of rests. 
        It duplicates Finale's inbuilt "Move Rests..." plug-in but with less mouse activity. 
        It is also a quick way to reset rest positions in every layer, the default setting.

        New rests are "floating" and will avoid entries in other layers (if present) 
        using the setting for "Adjust Floating Rests by..." at 
        Finale → Document → Document Options → Layers.  
        This script can stop them "floating", instead "fixing" them 
        to a specific offset from the default position. 
        On transposing staves these "fixed" rests will behave like notes 
        and change position if "Display in Concert Pitch" is selected.

        Hit the "f" key or select the "Floating Rests" checkbox to return all rests on 
        the chosen layer to "floating". 
        Hit the "q" key to view these notes. 
        To repeat the same action as before without a confirmation dialog, 
        hold down the SHIFT key when starting the script.

        == INFO ==

        A Space is the vertical distance between staff lines, and a Step is half a Space. 
        The distance between the top and bottom lines of a 5-line staff is 4 Spaces or 8 Steps. 
        Rests usually "centre" on the middle staff line, 4 Steps below the top line of a 5-line staff. 
        This script, like Finale, shifts rests by Steps relative to the default position.
    ]]
    return "Rest Offsets...", "Rest Offsets", "Change the vertical offset of rests by layer"
end

local config = {
    offset = 0,
    layer = 0,
    make_floating = 0,
    pos_x = false,
    pos_y = false
}
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local note_entry = require("library.note_entry")
local script_name = "rest_offsets"

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

local function no_errors()
    local max_step = 48 -- (2 inches)
    if math.abs(config.offset) > max_step then
        local msg = "Rest offset value must be reasonable, say +/- "
        .. max_step .. " steps or less ...\nnot " .. config.offset .. " steps"
        finenv.UI():AlertInfo(msg, "User Error")
        return false
    end
    return true
end

local function user_chooses()
    local max = layer.max_layers()
    local notes = finaleplugin.Notes:gsub(" %s+", " "):gsub("\n ", "\n"):sub(2)
    local function show_info() finenv.UI():AlertInfo(notes, "About " .. plugindef()) end
    local x = 122
    local y_grid = { 15, 45, 70 }
    local x_off = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac Edit box
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    local edit = {}
    local saved = { offset = config.offset, layer = config.layer, float = config.make_floating }

    edit.title = dialog:CreateStatic(0, y_grid[1]):SetText("Vertical offset (steps)")
        :SetWidth(x):SetEnable(saved.float == 0)
    edit.offset = dialog:CreateEdit(x, y_grid[1] - x_off):SetInteger(config.offset)
        :SetWidth(50):SetEnable(saved.float == 0)
    dialog:CreateStatic(0, y_grid[2]):SetText("Layer 1-" .. max .. " (0 = all)"):SetWidth(x)
    edit.layer = dialog:CreateEdit(x, y_grid[2] - x_off):SetInteger(config.layer):SetWidth(50)

        local function offset_enabled()
            local n = edit.float:GetCheck()
            edit.title:SetEnable(n == 0)
            edit.offset:SetEnable(n == 0)
            edit[(n == 0) and "offset" or "layer"]:SetKeyboardFocus()
        end
        local function key_check(id)
            local s = edit[id]:GetText():lower()
            if s:find("[^-0-9]") or (id == "layer" and s:find("[-5-9]")) then
                if s:find("[?q]") then show_info()
                elseif s:find("f") then -- toggle "float" checkbox
                    edit.float:SetCheck((edit.float:GetCheck() == 0) and 1 or 0)
                    offset_enabled()
                end
                edit[id]:SetText(saved[id])
            else
                if id == "layer" then
                    s = s:sub(-1)
                    edit[id]:SetText(s)
                end
                saved[id] = edit[id]:GetText()
            end
        end
    edit.float = dialog:CreateCheckbox(0, y_grid[3]):SetText("Floating Rests (f)")
        :SetCheck(config.make_floating):SetWidth(x * 2)
        :AddHandleCommand(function() offset_enabled() end)

    local texts = { -- offset number / x offset / description /  vertical position
        {  "4", 5, "= top staff line",    0 },
        {  "0", 5, "= middle staff line", 15 },
        { "-4", 0, "= bottom staff line", 30 },
        { "",   0, "(for 5-line staff)",  45 },
    }
    for _, v in ipairs(texts) do -- static text information lines
        dialog:CreateStatic(x + 60 + v[2], v[4]):SetText(v[1])
        dialog:CreateStatic(x + 75, v[4]):SetText(v[3]):SetWidth(x)
    end
    edit.offset:AddHandleCommand(function() key_check("offset") end)
    edit.layer:AddHandleCommand(function() key_check("layer") end)

    dialog:CreateButton(x * 2 + 45, y_grid[3]):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.offset = edit.offset:GetInteger()
        config.layer = edit.layer:GetInteger()
        config.make_floating = edit.float:GetCheck()
        dialog_save_position(self)
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function change_rest_offset()
    configuration.get_user_settings(script_name, config, true)
    local shift_key = finenv.QueryInvokedModifierKeys and
        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
         or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    if shift_key or (user_chooses() and no_errors()) then
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
end

change_rest_offset()

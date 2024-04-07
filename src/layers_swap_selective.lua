function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.71"
    finaleplugin.Date = "2024/02/27"
    finaleplugin.MinJWLuaVersion = 0.63
    finaleplugin.Notes = [[
        Swaps notes in the selected region between two nominated layers. 
        To repeat the same action as last time without a confirmation dialog 
        hold down [Shift] when opening the script.
    ]]
    return "Swap Layers Selective...", "Swap Layers Selective",
        "Swaps notes in the selected region between two chosen layers"
end

local config = {
    layer_1 = 1,
    layer_2 = 2,
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local library = require("library.general_library")
local script_name = library.calc_script_name()

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

local function user_chooses()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef():sub(1, 11))
    local max = layer.max_layers()
    local mid_x, x_gap, y_off = 30, 72, 22
    local saved = { config.layer_1, config.layer_2 }
    local ctl = {}
        -- local functions
        local function key_check(id)
            local val = ctl[id]:GetText()
            if val:find("[1-" .. max .. "]") then
                val = val:sub(-1) -- only last entered digit
                saved[id] = val
            end
            ctl[id]:SetText(saved[id]):SetKeyboardFocus()
        end
        local function create_line(index, name, dx)
            local offset = finenv.UI():IsOnMac() and 3 or 0 -- Mac Edit y-offset
            local y = index * y_off -- y_pos from line index
            dialog:CreateStatic(dx, y):SetWidth(mid_x + 5):SetText(name)
            dialog:CreateStatic(mid_x, y):SetWidth(40):SetText("layer#:")
            ctl[index] = dialog:CreateEdit(x_gap, y - offset):SetText(saved[index]):SetWidth(20)
                :AddHandleCommand(function() key_check(index) end)
            dialog:CreateStatic(x_gap + 23, y):SetWidth(35):SetText("(1-" .. max .. ")")
        end
    -- dialog contents
    local title = dialog:CreateStatic(0, 0):SetWidth(x_gap + 60)
        :SetText(plugindef():gsub("%.%.%.", ""))
    create_line(1, "swap", 0)
    create_line(2, "with", 5)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function()
        title:SetFont(title:CreateFontInfo():SetBold(true))
        ctl[1]:SetKeyboardFocus()
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        config.layer_1 = ctl[1]:GetInteger()
        config.layer_2 = ctl[2]:GetInteger()
    end)
    dialog_set_position(dialog)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    local ok = (dialog:ExecuteModal() == finale.EXECMODAL_OK)
    local different_layers = (ctl[1]:GetInteger() ~= ctl[2]:GetInteger())
    return (ok and different_layers)
end

local function swap_layers()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    if mod_key or user_chooses() then
        layer.swap(finenv.Region(), config.layer_1, config.layer_2)
    end
end

swap_layers()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.58 NO MIXIN"
    finaleplugin.Date = "2022/08/07"
    finaleplugin.Notes = [[
        Swaps notes in the selected region between two chosen layers
    ]]
    return "Swap Layers Selective", "Swap Layers Selective", "Swaps notes in the selected region between two chosen layers"
end

-- RetainLuaState retains one global:
config = config or {}
local layer = require("library.layer")

function any_errors()
    local error_message = ""
    if config.layer_a < 1 or  config.layer_a > 4 or config.layer_b < 1 or config.layer_b > 4  then 
        error_message = "Layer numbers must both\nbe integers between 1 and 4"
    elseif config.layer_a == config.layer_b  then 
        error_message = "Please choose two\ndifferent layer numbers"
    end
    if error_message ~= "" then  -- error dialog and exit
        finenv.UI():AlertNeutral("(script: " .. plugindef() .. ")", error_message)
        return true
    end
    return false
end

function create_dialog_box()
    local str = finale.FCString()
    local dialog = finale.FCCustomLuaWindow()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra horizontal offset for Mac edit box
    local offset_x, offset_y = 105, 22
    local edit_boxes = {}

    local texts = { -- text, default value
        { "swap layer# (1-4):", config.layer_a or 1 },
        { "with layer# (1-4):", config.layer_b or 2 }
    }
    for i, v in ipairs(texts) do
        local vertical = offset_y * (i - 1)
        str.LuaString = v[1]
        local static = dialog:CreateStatic(0, vertical)
        static:SetText(str)
        static:SetWidth(offset_x)
        edit_boxes[i] = dialog:CreateEdit(offset_x, vertical - mac_offset)
        edit_boxes[i]:SetInteger(v[2])
    end

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        config.layer_a = edit_boxes[1]:GetInteger()
        config.layer_b = edit_boxes[2]:GetInteger()
        dialog:StorePosition()
        config.pos_x = dialog.StoredX
        config.pos_y = dialog.StoredY
    end)
    return dialog
end

function layers_swap_selective()
    local dialog = create_dialog_box()
    if config.pos_x and config.pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
        dialog:RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK or any_errors() then
        return
    end
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    layer.swap(finenv.Region(), config.layer_a, config.layer_b)
end

layers_swap_selective()

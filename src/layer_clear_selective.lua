function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.05"
    finaleplugin.Date = "2022/08/02"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.Notes = [[
        Clear all music from the chosen layer in the surrently selected region. 
        (The chosen layer will be cleared for the whole measure even if the measure is only partially selected).
    ]]
    return "Clear layer selective", "Clear layer selective", "Clear the chosen layer"
end

-- RetainLuaState retains global variable: config
local layer = require("library.layer")

function user_chooses_layer()
    local y_offset = 10
    local x_offset = 110
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box

    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    str.LuaString = "Clear Layer (1-4):"
    local static = dialog:CreateStatic(0, y_offset)
    static:SetText(str)
    static:SetWidth(x_offset)

    local layer_choice = dialog:CreateEdit(x_offset, y_offset - mac_offset)
    layer_choice:SetInteger(config.layer or 1)  -- default layer 1
    layer_choice:SetWidth(50)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
            dialog:StorePosition()
            config.pos_x = global_dialog.StoredX
            config.pos_y = global_dialog.StoredY
            config.layer = layer_choice:GetInteger()
        end
    )
    return dialog
end

function clear_layer()
    config = config or { layer = nil, pos_x = false, pos_y = false }
    global_dialog = user_chooses_layer()

    if config.pos_x and config.pos_y then
        global_dialog:StorePosition()
        global_dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
        global_dialog:RestorePosition()
    end
    if global_dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK then
        return -- user cancelled
    end
    if not config.layer or config.layer < 1 or config.layer > 4 then
        finenv.UI():AlertNeutral("script: " .. plugindef(),
            "The layer number must be\nan integer between 1 and 4\n(not " .. config.layer .. ")")
        return
    end
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    layer.clear(finenv.Region(), config.layer)
end

clear_layer()

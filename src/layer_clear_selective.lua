function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.04"
    finaleplugin.Date = "2022/06/15"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.Notes = [[
        Clear all music from the chosen layer in the surrently selected region. 
        (Note that all of a measure's layer will be cleared even if it is partially selected).
    ]]
    return "Clear layer selective", "Clear layer selective", "Clear the chosen layer"
end

-- RetainLuaState will return global variable: clear_layer_number
local layer = require("library.layer")

function get_user_choice()
    local vertical = 10
    local horizontal = 110
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    str.LuaString = "Clear Layer (1-4):"
    local static = dialog:CreateStatic(0, vertical)
    static:SetText(str)
    static:SetWidth(horizontal)

    local layer_choice = dialog:CreateEdit(horizontal, vertical - mac_offset)
    layer_choice:SetInteger(clear_layer_number or 1)  -- default layer 1
    layer_choice:SetWidth(50)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK), layer_choice:GetInteger()
end

function clear_layers()
    local is_ok = false
    is_ok, clear_layer_number = get_user_choice()
    if not is_ok then -- user cancelled
        return
    end
    if clear_layer_number < 1 or clear_layer_number > 4 then
        finenv.UI():AlertNeutral("script: " .. plugindef(),
            "The layer number must be\nan integer between 1 and 4\n(not " .. clear_layer_number .. ")")
        return
    end
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    layer.clear(finenv.Region(), clear_layer_number)
end

clear_layers()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.50"
    finaleplugin.Date = "2022/05/17"
    finaleplugin.Notes = [[
        Swaps notes in the selected region between two layers chosen by the user.
    ]]
    return "Swap layers selective", "Swap layers selective", "Swap layers selectively"
end

local layer = require("library.layer")

function find_errors(layer_a, layer_b)
    local error_message = ""
    if layer_a < 1 or  layer_a > 4 or layer_b < 1 or layer_b > 4  then 
        error_message = "Layer numbers must be\nintegers between 1 and 4"
    elseif layer_a == layer_b  then 
        error_message = "Please nominate two DIFFERENT layers"
    end
    if (error_message ~= "") then  -- error dialog and exit
        finenv.UI():AlertNeutral("(script: " .. plugindef() .. ")", error_message)
        return true
    end
    return false
end

function choose_layers_to_swap()
    local current_vertical = 10 -- first vertical position
    local vertical_step = 25 -- vertical step for each line
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra horizontal offset for Mac edit box
    local horiz_offset = 110
    local edit_boxes = {} -- array of edit boxes for user data input
    local string = finale.FCString()
    local dialog = finale.FCCustomWindow()

    string.LuaString = plugindef()
    dialog:SetTitle(string)
    local texts = { -- words, default value
        { "swap layer# (1-4):", 1 },
        { "with layer# (1-4):", 2 }
    }
        
    for i,v in ipairs(texts) do
        string.LuaString = v[1]
        local static = dialog:CreateStatic(0, current_vertical)
        static:SetText(string)
        static:SetWidth(200)
        edit_boxes[i] = dialog:CreateEdit(horiz_offset, current_vertical - mac_offset)
        edit_boxes[i]:SetInteger(v[2])
        current_vertical = current_vertical + vertical_step
    end

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return dialog:ExecuteModal(nil), -- == 1 if Ok button pressed, else nil
        edit_boxes[1]:GetInteger(), edit_boxes[2]:GetInteger()
end

function layers_swap_selective()
    local ok, layer_a, layer_b = choose_layers_to_swap()
    if ok == finale.EXECMODAL_OK and not find_errors(layer_a, layer_b) then
        layer.swap(finenv.Region(), layer_a, layer_b)
    end
end

layers_swap_selective()

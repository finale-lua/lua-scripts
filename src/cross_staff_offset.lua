function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Version = "v1.27"
    finaleplugin.Date = "2022/07/10"
    finaleplugin.AdditionalMenuOptions = [[  CrossStaff Offset No Dialog  ]]
    finaleplugin.AdditionalUndoText = [[     CrossStaff Offset No Dialog  ]]
    finaleplugin.AdditionalPrefixes = [[     no_user_dialog = true  ]]
    finaleplugin.AdditionalDescriptions = [[ Offset horizontal position of cross-staff note entries - NO DIALOG ]]
    finaleplugin.Notes = [[
        When creating cross-staff notes using the option-downarrow shortcut, the stems of 
        'crossed' notes are reversed (on the wrong side of the notehead) and appear too far 
        to the right (if shifting downwards) by the width of one notehead, typically 24EVPU. 
        This script lets you set a horizontal offset for all cross-staff notes in the 
        selected region, with a different offset for non-crossed notes.  
        For crossing to the staff below use (-24,0) or (-12,12).  
        For crossing to the staff above use (24,0) or (12,-12).  
        Also specify which layer number to act upon (1-4) or "all layers" (0). 
        (This also offers a simple way to reset the horizontal offset of all notes in the selection to zero).
    
        Under RGPLua (version 0.62+) the script adds an extra menu item that repeats the last 
        chosen offset without presenting a dialog, for faster changes duplicating the last settings. 
]]
   return "CrossStaff Offset…", "CrossStaff Offset", "Offset horizontal position of cross-staff note entries"
end

no_user_dialog = no_user_dialog or false

local config = {
    cross_staff_offset = 0,
    non_cross_offset = 0,
    layer_number = 0,
    window_pos_x = 70,
    window_pos_y = 1200
}

local configuration = require("library.configuration")
configuration.get_user_settings("cross_staff_offset", config, true)

function user_selects_offset()
    local current_vert = 10
    local vertical_step = 25
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local edit_box_horiz = 120
    
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    local answer = {}
    local texts = { -- words, default value
        { "Cross-staff offset:", "cross_staff_offset" }, --> answer[1]
        { "Non-crossed offset:", "non_cross_offset" }, --> answer[2]
        { "Layer 1-4 (0 = all):", "layer_number" } --> answer[3]
    }
        local function make_static(msg, horiz, vert, width, red)
            local static = dialog:CreateStatic(horiz, vert)
            str.LuaString = msg
            static:SetText(str)
            static:SetWidth(width)
            if red then
                static:SetTextColor(204, 51, 0)
            end
        end
    for i,v in ipairs(texts) do
        make_static(v[1], 0, current_vert, 200, false)
        answer[i] = dialog:CreateEdit(edit_box_horiz, current_vert - mac_offset)
        answer[i]:SetInteger(config[v[2]]) -- display the saved config value
        answer[i]:SetWidth(75)
        if i < 3 then
            make_static( "EVPUs", edit_box_horiz + 80, current_vert, 75, false)
        end
        current_vert = current_vert + vertical_step
    end

    dialog:StorePosition()
    dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
    dialog:RestorePosition()
    local test_txt = "X" .. config.window_pos_x .. " Y" .. config.window_pos_y
    make_static("cross to staff below = [ -24, 0 ] or [ -12, 12 ]" .. test_txt, 0, current_vert + 8, 320, true) -- 240?
    make_static("cross to staff above = [ 24, 0 ] or [ 12, -12 ]", 0, current_vert + vertical_step, 280, true)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()

    local ok = ( dialog:ExecuteModal(nil) == finale.EXECMODAL_OK )
    if ok then
        for i,v in ipairs(texts) do -- save the 3 integer values
           config[v[2]] = answer[i]:GetInteger()
        end
        dialog:StorePosition()
        config.window_pos_x = dialog.StoredX
        config.window_pos_y = dialog.StoredY
    end
    return ok
end

function is_out_of_range(horiz_offset)
    max_value = 999 -- some unrealistic horizontal offset (EVPUs)
    return ( horiz_offset > max_value or horiz_offset < max_value * -1 )
end

function cross_staff_offset()
    if not no_user_dialog then
        if not user_selects_offset() then -- user cancelled
            return
        else -- check new selections
            local error = ""  -- TEST FOR ERRORS (note that all user responses are perforce already integers)
            if config.layer_number < 0 or config.layer_number > 4  then 
                error = "The layer number must\nbe between 0 and 4\n(not " .. config.layer_number .. ")"
            elseif is_out_of_range(config.cross_staff_offset) or is_out_of_range(config.non_cross_offset) then
                error = "Choose realistic offset\nvalues (say from -999 to 999)\n(not " .. config.cross_staff_offset .. " / " .. config.non_cross_offset .. ")"
            end
            if error ~= "" then  -- error dialog and exit
                finenv.UI():AlertNeutral("script: " .. plugindef(), error)
                return
            end
            -- save revised config file
            configuration.save_user_settings("cross_staff_offset", config)
        end
    end
    -- change entry offsets in the chosen layer (0 = all layers)
    for entry in eachentrysaved(finenv.Region(), config.layer_number) do
        if entry:IsNote() then
            entry.ManualPosition = entry.CrossStaff and config.cross_staff_offset or config.non_cross_offset
        end
    end
end

cross_staff_offset()

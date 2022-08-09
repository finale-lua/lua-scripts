function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.HandlesUndo = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Version = "v1.33"
    finaleplugin.Date = "2022/08/05"
	finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        When creating cross-staff notes using the option-downarrow shortcut, the stems of 
        'crossed' notes are reversed (on the wrong side of the notehead) and appear too far 
        to the right (if shifting downwards) by the width of one notehead, typically 24EVPU. 
        This script allows setting a horizontal offset for cross-staff notes in the 
        selected region, with a different offset for non-crossed notes, 
        and specify which layer to act on, 1-4 or "all layers" (0). 
        This also offers a simple way to reset the horizontal offset of all selected notes to zero.

        For crossing to the staff below use (-24,0) or (-12,12).  
        For crossing to the staff above use (24,0) or (12,-12).

        If you want to repeat your last settings without a confirmation dialog, 
        just hold down the `shift` or `alt` (option) key when selecting the script's menu item.
    ]]
   return "CrossStaff Offset...", "CrossStaff Offset", "Offset horizontal position of cross-staff note entries"
end

-- default config
local config = {
    cross_staff_offset  = 0,
    non_cross_offset = 0,
    layer = 0,
    pos_x = false,
    pos_y = false,
}
local configuration = require("library.configuration")

function is_error()
    local msg = ""
    if math.abs(config.cross_staff_offset) > 999 or math.abs(config.non_cross_offset) > 999 then
        msg = "Choose realistic offset\nvalues (say from -999 to 999)\n(not "
        .. config.cross_staff_offset .. " / " .. config.non_cross_offset .. ")"
    elseif config.layer < 0 or config.layer > 4 then
        msg = "Layer number must be an\ninteger between zero and 4\n(not " .. config.layer .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertNeutral("script: " .. plugindef(), msg)
        return true
    end
    return false
end

function create_user_dialog() -- attempting MODELESS operation
    local info_vertical = 75
    local edit_horiz = 120
    local edit_width = 75
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local answer = {}

    local dialog_options = { -- words, key value in config, y-offset
        { "Cross-staff offset:", "cross_staff_offset", 0 },
        { "Non-crossed offset:", "non_cross_offset", 25 },
        { "Layer 1-4 (0 = all):", "layer", 50 }
    }

    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

        function make_static(msg, horiz, vert, width, sepia)
            local static = dialog:CreateStatic(horiz, vert)
            str.LuaString = msg
            static:SetText(str)
            static:SetWidth(width)
            if sepia then
                static:SetTextColor(153, 51, 0)
            end
        end

    for i, v in ipairs(dialog_options) do
        make_static(v[1], 0, v[3], edit_horiz, false)
        answer[i] = dialog:CreateEdit(edit_horiz, v[3] - mac_offset)
        answer[i]:SetInteger(config[v[2]]) -- display the saved config value
        answer[i]:SetWidth(edit_width)
        if i < 3 then
            make_static("EVPUs", edit_horiz + edit_width + 5, v[3], 75, false)
        end
    end

    make_static("cross to staff below = [ -24, 0 ] or [ -12, 12 ]", 0, info_vertical, 290, true)
    make_static("cross to staff above = [ 24, 0 ] or [ 12, -12 ]", 0, info_vertical + 18, 290, true)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        config.cross_staff_offset = answer[1]:GetInteger()
        config.non_cross_offset = answer[2]:GetInteger()
        config.layer = answer[3]:GetInteger()
    end)
    dialog:RegisterCloseWindow(function()
        dialog:StorePosition()
        config.pos_x = dialog.StoredX
        config.pos_y = dialog.StoredY
    end)
    return dialog
end

function cross_staff_offset()
    configuration.get_user_settings("cross_staff_offset", config, true)
    -- does user want to skip the dialog?
    local mod_down = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    if not mod_down then
        local dialog = create_user_dialog()
        if config.pos_x and config.pos_y then
            dialog:StorePosition()
            dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
            dialog:RestorePosition()
        end
        if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK then
            return -- user cancelled
        end
        if is_error() then
            return
        end
        configuration.save_user_settings("cross_staff_offset", config)
    end
    -- *** DO THE WORK ***
    for entry in eachentrysaved(finenv.Region(), config.layer) do
        if entry:IsNote() then
            entry.ManualPosition = entry.CrossStaff and config.cross_staff_offset or config.non_cross_offset
        end
    end
end

cross_staff_offset()

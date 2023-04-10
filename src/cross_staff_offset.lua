function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v1.38"
    finaleplugin.Date = "2023/04/09"
	finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        When creating cross-staff notes the stems of 'crossed' notes are reversed 
        (on the wrong side of the notehead) and look too far 
        to the right (if shifting downwards) by the width of one notehead, typically 24 EVPU. 
        This script enables a horizontal offset just for cross-staffed notes in the 
        selected region, with a different offset for non-crossed notes, acting on any layer (1-4) or "all" (0). 
        This also offers a simple way to reset the horizontal offset of all selected notes to zero.

        For crossing to the staff below use (-24,0) or (-12,12).  
        For crossing to the staff above use (24,0) or (12,-12).

        If you want to repeat your last settings without a confirmation dialog, 
        just hold down the SHIFT or ALT (option) key when selecting the script's menu item.
    ]]
   return "CrossStaff Offset...", "CrossStaff Offset", "Offset horizontal position of cross-staff note entries"
end

local config = {
    cross_staff_offset  = 0,
    non_cross_offset = 0,
    layer = 0,
    pos_x = false,
    pos_y = false,
}
local configuration = require("library.configuration")
local layer = require("library.layer")
local mixin = require("library.mixin")
local script_name = "cross_staff_offset"
configuration.get_user_settings(script_name, config)

function is_error()
    local msg, cross, noncross = "", config.cross_staff_offset, config.non_cross_offset
    local max = layer.max_layers()
    if math.abs(cross) > 999 or math.abs(noncross) > 999 then
        msg = "Choose realistic offset values, say from -999 to 999, (not "
        .. cross .. " to " .. noncross .. ")\n\n"
    end
    if config.layer < 0 or config.layer > max then
        msg = msg .. "Layer number must be an integer\n from 0 to " .. max .. " (not " .. config.layer .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertInfo(msg, "User Error")
        return true
    end
    return false
end

function create_user_dialog()
    local y_grid = { 3, 23, 43, 66, 84 }
    local x_grid = { 0, 115, 170, 235 }
    local e_width = 50
    local offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local answer = {}

    local dialog_options = { -- words, key value in config, y-offset
        { "Cross-staff offset:", "cross_staff_offset", y_grid[1] },
        { "Non-crossed offset:", "non_cross_offset", y_grid[2] },
        { "Layer 1-" .. layer.max_layers() .. " (0 = all):", "layer", y_grid[3] }
    }

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    for i, v in ipairs(dialog_options) do
        dialog:CreateStatic(0, v[3]):SetText(v[1]):SetWidth(x_grid[2])
        answer[i] = dialog:CreateEdit(x_grid[2], v[3] - offset):SetInteger(config[ v[2] ]):SetWidth(e_width)
        if i < 3 then
            dialog:CreateStatic(x_grid[3], v[3]):SetText("EVPUs"):SetWidth(e_width)
        end
    end
    dialog:CreateStatic(x_grid[1], y_grid[4])
        :SetText("cross to staff below = [ -24, 0 ] or [ -12, 12 ]"):SetWidth(x_grid[4])
    dialog:CreateStatic(x_grid[1], y_grid[5])
        :SetText("cross to staff above = [ 24, 0 ] or [ 12, -12 ]"):SetWidth(x_grid[4])
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
            config.cross_staff_offset = answer[1]:GetInteger()
            config.non_cross_offset = answer[2]:GetInteger()
            config.layer = answer[3]:GetInteger()
            dialog:StorePosition()
            config.pos_x = dialog.StoredX
            config.pos_y = dialog.StoredY
        end
    )
    return dialog
end

function cross_staff_offset()
    local hide_dialog = finenv.QueryInvokedModifierKeys and
        (       finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
            or  finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
        )
    if not hide_dialog then
        local dialog = create_user_dialog()
        if config.pos_x and config.pos_y then
            dialog:StorePosition()
                :SetRestorePositionOnlyData(config.pos_x, config.pos_y)
                :RestorePosition()
        end
        if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK or is_error() then
            return -- user cancelled or intput error
        end
        configuration.save_user_settings(script_name, config)
    end
    -- *** DO THE WORK ***
    for entry in eachentrysaved(finenv.Region(), config.layer) do
        if entry:IsNote() then
            entry.ManualPosition = entry.CrossStaff and config.cross_staff_offset or config.non_cross_offset
        end
    end
end

cross_staff_offset()

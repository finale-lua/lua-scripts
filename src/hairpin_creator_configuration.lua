function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine after CJ Garcia"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.61"
    finaleplugin.Date = "2022/08/19"
    finaleplugin.Notes = [[
        This is a companion script for `hairpin_creator.lua` (version v0.61).

        If you use a macro program like KeyboardMaestro (MacOS) to trigger menu items in Finale, 
        it is tricky to simulate the `alt` (option) key trigger to access the script's configuration 
        (see: `http://carlvine.com/km_option/`). 
        Use this script to access to the `hairpin_creator` configuration file directly instead of using the modifier key. 
        The result will affect the action of all four `hairpin_creator` methods: 

        ```
        Hairpin ... Create Crescendo | Create Diminuendo | Create Swell | Create Unswell
        ```
        ]]
    return "Hairpin Creator Configuration", "Hairpin Creator Configuration", "Configuration utitlity for the hairpin_creator.lua script"
end

local dialog_options = { -- key value in config, explanation
    { "dynamics_match_hairpin", "move dynamics vertically to match hairpin height" },
    { "include_trailing_items", "consider notes and dynamics past the end of selection" },
    { "attach_over_end_barline", "attach right end of hairpin across the final barline" },
    { "attach_over_system_break", "attach across final barline even over a system break" },
    { "inclusions_EDU_margin", "(EDUs) the marginal duration for included trailing items" },
    { "shape_vert_adjust",  "vertical adjustment for hairpin to match dynamics" },
    { "below_note_cushion", "extra gap below notes" },
    { "downstem_cushion", "extra gap below down-stems" },
    { "below_artic_cushion", "extra gap below articulations" },
    { "left_horiz_offset",  "gap between the start of selection and hairpin (no dynamics)" },
    { "right_horiz_offset",  "gap between end of hairpin and end of selection (no dynamics)" },
    { "left_dynamic_cushion",  "gap between first dynamic and start of hairpin" },
    { "right_dynamic_cushion",  "gap between end of the hairpin and ending dynamic" },
}

local boolean_options = {
    dynamics_match_hairpin = true,
    include_trailing_items = true,
    attach_over_end_barline = true,
    attach_over_system_break = true,
}

local config = {
    dynamics_match_hairpin = true,
    include_trailing_items = true,
    attach_over_end_barline = true,
    attach_over_system_break = false,
    inclusions_EDU_margin = 256,
    shape_vert_adjust = 13,
    below_note_cushion = 56,
    downstem_cushion = 44,
    below_artic_cushion = 40,
    left_horiz_offset = 16,
    right_horiz_offset = -16,
    left_dynamic_cushion = 18,
    right_dynamic_cushion = -18,
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")

-- ============================= SCRIPT BEGINS =====================================

function create_user_dialog() -- attempting MODELESS operation
    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = "Hairpin Creator Configuration"
    dialog:SetTitle(str)
    local y_step = 20
    local max_text_width = 385
    local x_offset = {0, 130, 155, 190}
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra horizontal offset for Mac edit boxes
    local answer = {}

        local function make_static(msg, horiz, vert, width, sepia)
            local static = dialog:CreateStatic(horiz, vert)
            str.LuaString = msg
            static:SetText(str)
            static:SetWidth(width)
            if sepia and static.SetTextColor then
                static:SetTextColor(102, 0, 0)
            end
        end

    for i, v in ipairs(dialog_options) do -- run through config parameters
        local y_current = y_step * i
        str.LuaString = string.gsub(v[1], "_", " ")
        if boolean_options[v[1]] then -- boolean checkboxes
            answer[v[1]] = dialog:CreateCheckbox(x_offset[1], y_current)
            answer[v[1]]:SetCheck(config[v[1]] and 1 or 0)
            answer[v[1]]:SetText(str)
            answer[v[1]]:SetWidth(x_offset[3])
            make_static(v[2], x_offset[3], y_current, max_text_width, true) -- parameter explanation
        else  -- integer value (not measurement!)
            y_current = y_current + 10 -- gap before the integer variables
            make_static(str.LuaString .. ":", x_offset[1], y_current, x_offset[2], false) -- parameter name
            answer[v[1]] = dialog:CreateEdit(x_offset[2], y_current - mac_offset)
            answer[v[1]]:SetInteger(config[v[1]])
            answer[v[1]]:SetWidth(50)
            make_static(v[2], x_offset[4], y_current, max_text_width, true) -- parameter explanation
        end
    end
    -- measurement unit options = NIL without mixin
    y_step = (#dialog_options + 1.6) * y_step
    make_static("All Measurement Units: EVPU", x_offset[2], y_step, max_text_width, true)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        for _, v in ipairs(dialog_options) do
            if boolean_options[v[1]] then
                config[v[1]] = (answer[v[1]]:GetCheck() == 1)
            else
                config[v[1]] = answer[v[1]]:GetInteger()
            end
        end
        dialog:StorePosition()
        config.window_pos_x = dialog.StoredX
        config.window_pos_y = dialog.StoredY
        configuration.save_user_settings("hairpin_creator", config)
    end)
    return dialog
end

function change_configuration()
    configuration.get_user_settings("hairpin_creator", config, true)
    local dialog = create_user_dialog()
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
    dialog:ExecuteModal(nil)
end

change_configuration()

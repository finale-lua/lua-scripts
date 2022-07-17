function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine after CJ Garcia"
    finaleplugin.AuthorURL = "http://carlvine.com/lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.52"
    finaleplugin.Date = "2022/07/17"
    finaleplugin.Notes = [[
        This is a companion script for `hairpin_creator.lua`, listed in the 
        `finalelua.com` repository by its primary menu name, "Hairpin create crescendo". 

        If you use a macro program like KeyboardMaestro (MacOS) to trigger menu items in Finale, 
        using the `alt` or `option` key in `hairpin_creator.lua` won't allow access to its configuration. 
        If so, use this script to change the configuration file directly. 
        The result will affect the behaviour of all four of hairpin_creator's actions: 

        ```
        Crescendo | Diminuendo | Swell | Unswell
        ```
        ]]
    return "Hairpin creator configuration", "Hairpin creator configuration", "Configuration utitlity for the hairpin_creator.lua script"
end

-- global variables for modeless operation
global_dialog = nil
global_dialog_options = { -- key value in config, explanation, dialog control holder
    { "dynamics_match_hairpin", "move dynamics vertically to match hairpin height", nil},
    { "include_trailing_items", "consider notes and dynamics past the end of selection", nil},
    { "attach_over_end_barline", "attach right end of hairpin across the final barline", nil},
    { "attach_over_system_break", "attach across final barline even over a system break", nil},
    { "inclusions_EDU_margin", "(EDUs) the marginal duration for included trailing items", nil},
    { "shape_vert_adjust",  "(EVPUs) vertical adjustment for hairpin to match dynamics", nil},
    { "below_note_cushion", "(EVPUs) extra gap below notes", nil},
    { "downstem_cushion", "(EVPUs) extra gap below down-stems", nil},
    { "below_artic_cushion", "(EVPUs) extra gap below articulations", nil},
    { "left_horiz_offset",  "(EVPUs) gap between the start of selection and hairpin (no dynamics)", nil},
    { "right_horiz_offset",  "(EVPUs) gap between end of hairpin and end of selection (no dynamics)", nil},
    { "left_dynamic_cushion",  "(EVPUs) gap between first dynamic and start of hairpin", nil},
    { "right_dynamic_cushion",  "(EVPUs) gap between end of the hairpin and ending dynamic", nil},
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
    left_horiz_offset = 10,
    right_horiz_offset = -14,
    left_dynamic_cushion = 16,
    right_dynamic_cushion = -16,
    window_pos_x = 0,
    window_pos_y = 0,
    number_of_booleans = 4, -- number of boolean values at start of global_dialog_options
}

local configuration = require("library.configuration")

function create_user_dialog() -- attempting MODELESS operation
    local y_step = 20
    local max_text_width = 385
    local x_offset = {0, 130, 155, 190}
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra horizontal offset for Mac edit boxes
    local str = finale.FCString()
    local dialog = finale.FCCustomLuaWindow()
    str.LuaString = "HAIRPIN CREATOR CONFIGURATION"
    dialog:SetTitle(str)

        local function make_static(msg, horiz, vert, width, sepia)
            local str2 = finale.FCString()
            local static = dialog:CreateStatic(horiz, vert)
            str2.LuaString = msg
            static:SetText(str2)
            static:SetWidth(width)
            if sepia then
                static:SetTextColor(204, 102, 51)
            end
        end

    for i, v in ipairs(global_dialog_options) do -- run through config parameters
        local y_current = y_step * i
        str.LuaString = string.gsub(v[1], "_", " ")
        if i <= config.number_of_booleans then -- boolean checkboxes
            v[3] = dialog:CreateCheckbox(x_offset[1], y_current)
            v[3]:SetText(str)
            v[3]:SetWidth(x_offset[3])
            local checked = config[v[1]] and 1 or 0
            v[3]:SetCheck(checked)
            make_static(v[2], x_offset[3], y_current, max_text_width, true) -- parameter explanation
        else  -- integer value
            y_current = y_current + 10
            str.LuaString = str.LuaString .. ":"
            make_static(str.LuaString, x_offset[1], y_current, x_offset[2], false) -- parameter name
            v[3] = dialog:CreateEdit(x_offset[2], y_current - mac_offset)
            v[3]:SetInteger(config[v[1]])
            v[3]:SetWidth(50)
            make_static(v[2], x_offset[4], y_current, max_text_width, true) -- parameter explanation
        end
    end
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return dialog
end

function on_ok() -- config changed, now do the work
    for i, v in ipairs(global_dialog_options) do
        if i > config.number_of_booleans then
            config[v[1]] = v[3]:GetInteger()
        else
            config[v[1]] = (v[3]:GetCheck() == 1) -- "true" for checked
        end
    end
    global_dialog:StorePosition()
    config.window_pos_x = global_dialog.StoredX
    config.window_pos_y = global_dialog.StoredY
    configuration.save_user_settings("hairpin_creator", config)
end

function user_changes_configuration()
    configuration.get_user_settings("hairpin_creator", config) -- overwrite default preferences
    global_dialog = create_user_dialog()
    if config.window_pos_x > 0 and config.window_pos_y > 0 then
        global_dialog:StorePosition()
        global_dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        global_dialog:RestorePosition()
    end
    global_dialog:RegisterHandleOkButtonPressed(on_ok)
    finenv.RegisterModelessDialog(global_dialog)
    global_dialog:ShowModeless()
end

user_changes_configuration()

function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "6/28/2022"
    return "JetStream Configuration", "JetStream Configuration", "JetStream Configuration"
end

local configuration = require("library.configuration")

function config_jetstream()
    local script_name = "jetstream_config"
    local row_h = 20
    local col_w = 140
    local col_gap = 10
    local str = finale.FCString()
    str.LuaString = "JetStream Finale Controller - Settings"
    local dialog = finale.FCCustomLuaWindow()
    dialog:SetTitle(str)
    --
    local row = {}
    for i = 1, 100 do
        row[i] = (i - 1) * row_h
    end
    --
    local col = {}
    for i = 1, 11 do
        col[i] = (i - 1) * col_w
    end
    --
    --[[ File IO stuff ]] --
    --    local config = config_load()

    --[[ VARIABLES FOR JETSTREAM ]] --
    local tacet_text = finale.FCString()
    tacet_text.LuaString = config.tacet_text
    --
    local al_fine_text = finale.FCString()
    al_fine_text.LuaString = config.al_fine_text
    --
    local play_x_bars_prefix = finale.FCString()
    play_x_bars_prefix.LuaString = config.play_x_bars_prefix
    local play_x_bars_suffix = finale.FCString()
    play_x_bars_suffix.LuaString = config.play_x_bars_suffix
    --
    local play_x_more_prefix = finale.FCString()
    play_x_more_prefix.LuaString = config.play_x_more_prefix
    local play_x_more_suffix = finale.FCString()
    play_x_more_suffix.LuaString = config.play_x_more_suffix
    --
    local dynamic_L_cushion = finale.FCString()
    dynamic_L_cushion.LuaString = config.dynamic_L_cushion
    local dynamic_R_cushion = finale.FCString()
    dynamic_R_cushion.LuaString = config.dynamic_R_cushion
    --
    local noteentry_cushion = finale.FCString()
    noteentry_cushion.LuaString = config.noteentry_cushion
    local staff_cushion = finale.FCString()
    staff_cushion.LuaString = config.staff_cushion
    --
    local dynamic_above_cushion = finale.FCString()
    dynamic_above_cushion.LuaString = config.dynamic_above_cushion
    --
    local nudge_normal = finale.FCString()
    nudge_normal.LuaString = config.nudge_normal
    local nudge_large = finale.FCString()
    nudge_large.LuaString = config.nudge_large
    --
    --  local x_type = tonumber(config.x_type)
    local x_type = config.x_type
    --
    local lyrics_all = config.lyrics_all
    --
    function add_ctrl(dialog, ctrl_type, text, x, y, h, w, min, max)
        str.LuaString = text
        local ctrl = ""
        if ctrl_type == "button" then
            ctrl = dialog:CreateButton(x, y)
        elseif ctrl_type == "checkbox" then
            ctrl = dialog:CreateCheckbox(x, y)
        elseif ctrl_type == "datalist" then
            ctrl = dialog:CreateDataList(x, y)
        elseif ctrl_type == "edit" then
            ctrl = dialog:CreateEdit(x, y - 2)
        elseif ctrl_type == "horizontalline" then
            ctrl = dialog:CreateHorizontalLine(x, y, w)
        elseif ctrl_type == "listbox" then
            ctrl = dialog:CreateListBox(x, y)
        elseif ctrl_type == "popup" then
            ctrl = dialog:CreatePopup(x, y)
        elseif ctrl_type == "slider" then
            ctrl = dialog:CreateSlider(x, y)
            ctrl:SetMaxValue(max)
            ctrl:SetMinValue(min)
        elseif ctrl_type == "static" then
            ctrl = dialog:CreateStatic(x, y)
        elseif ctrl_type == "switcher" then
            ctrl = dialog:CreateSwitcher(x, y)
        elseif ctrl_type == "tree" then
            ctrl = dialog:CreateTree(x, y)
        elseif ctrl_type == "updown" then
            ctrl = dialog:CreateUpDown(x, y)
        elseif ctrl_type == "verticalline" then
            ctrl = dialog:CreateVerticalLine(x, y, h)
        end
        if ctrl_type == "edit" then
            ctrl:SetHeight(h - 2)
            ctrl:SetWidth(w - col_gap)
            local y = ctrl:GetTop() - 1
            ctrl:SetTop(y)
        else
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
        end
        ctrl:SetText(str)
        return ctrl
    end -- add_ctrl()

    local tacet_static = add_ctrl(dialog, "static", "Text for 'Tacet' parts:", col[1], row[1], row_h, col_w, 0, 0)
    local tacet_edit = add_ctrl(dialog, "edit", tacet_text.LuaString, col[2], row[1], row_h, col_w, 0, 0)
    --
    local al_fine_static = add_ctrl(dialog, "static", "Text for 'tacet al fine':", col[1], row[2], row_h, col_w, 0, 0)
    local al_fine_edit = add_ctrl(dialog, "edit", al_fine_text.LuaString, col[2], row[2], row_h, col_w, 0, 0)
    --
    add_ctrl(dialog, "horizontalline", "", col[1], row[3] + 10, 1, col_w * 3, 0, 0)
    --
    local play_x_bars_static = add_ctrl(dialog, "static", "Play X Bars:", col[1], row[4], row_h, col_w, 0, 0)
    local play_x_bars_prefix_edit = add_ctrl(dialog, "edit", play_x_bars_prefix.LuaString, col[2], row[4], row_h, col_w - 40, 0, 0)
    local play_x_bars_x_static = add_ctrl(dialog, "static", "X", col[3] - 45, row[4], row_h, col_w, 0, 0)
    local play_x_bars_suffix_edit = add_ctrl(dialog, "edit", play_x_bars_suffix.LuaString, col[3] - 30, row[4], row_h, col_w - 40, 0, 0)
    --
    local play_x_more_static = add_ctrl(dialog, "static", "Play X More:", col[1], row[5], row_h, col_w, 0, 0)
    local play_x_more_prefix_edit = add_ctrl(dialog, "edit", play_x_more_prefix.LuaString, col[2], row[5], row_h, col_w - 40, 0, 0)
    local play_x_more_x_static = add_ctrl(dialog, "static", "X", col[3] - 45, row[5], row_h, col_w, 0, 0)
    local play_x_more_suffix_edit = add_ctrl(dialog, "edit", play_x_more_suffix.LuaString, col[3] - 30, row[5], row_h, col_w - 40, 0, 0)
    --
    add_ctrl(dialog, "horizontalline", "", col[1], row[6] + 10, 1, col_w * 3, 0, 0)
    --
    local dynamics_cushions_static = add_ctrl(dialog, "static", "Dynamics Cushions (EVPUs: 24 = 1 space)", col[1], row[7], row_h, col_w * 3, 0, 0)
    local dynamic_cushion_1_static = add_ctrl(dialog, "static", "Dynamic to Hairpins:", col[1], row[8], row_h, col_w, 0, 0)
    local L = add_ctrl(dialog, "static", "L", col[2] - 10, row[8], row_h, 20, 0, 0)
    local R = add_ctrl(dialog, "static", "R", col[2] + 50, row[8], row_h, 20, 0, 0)
    local dynamic_L_cushion_edit = add_ctrl(dialog, "edit", dynamic_L_cushion.LuaString, col[2], row[8], row_h, 40, 0, 0)
    local dynamic_R_cushion_edit = add_ctrl(dialog, "edit", dynamic_R_cushion.LuaString, col[2] + 60, row[8], row_h, 40, 0, 0)
    --
    local dynamic_cushion_2_static = add_ctrl(dialog, "static", "Lone Hairpins:", col[1], row[9], row_h, col_w + 20, 0, 0)

    local noteentry_cushion_static = add_ctrl(dialog, "static", "Notes", col[2] - 30, row[9], row_h, 40, 0, 0)
    local staff_cushion_static = add_ctrl(dialog, "static", "Staff", col[2] + 35, row[9], row_h, 40, 0, 0)
    local noteentry_cushion_edit = add_ctrl(dialog, "edit", noteentry_cushion.LuaString, col[2], row[9], row_h, 40, 0, 0)
    local staff_cushion_edit = add_ctrl(dialog, "edit", staff_cushion.LuaString, col[2] + 60, row[9], row_h, 40, 0, 0)
    --
    local dynamic_above_static = add_ctrl(dialog, "static", "Above Staff:", col[1], row[10], row_h, col_w + 20, 0, 0)

    local dynamic_above_edit = add_ctrl(dialog, "edit", dynamic_above_cushion.LuaString, col[2], row[10], row_h, 40, 0, 0)

    --
    local nudge_static = add_ctrl(dialog, "static", "Nudge amounts:", col[1], row[11], row_h, col_w, 0, 0)
    local nudge_normal_edit = add_ctrl(dialog, "edit", nudge_normal.LuaString, col[2], row[11], row_h, 40, 0, 0)
    local nudge_large_edit = add_ctrl(dialog, "edit", nudge_large.LuaString, col[2] + 60, row[11], row_h, 40, 0, 0)
    nudge_large_edit:SetEnable(0)
    --
    add_ctrl(dialog, "horizontalline", "", col[1], row[12] + 10, 1, col_w * 3, 0, 0)
    --
    local x_type_static = add_ctrl(dialog, "static", "Default X-notehead type:", col[1], row[13], row_h, col_w, 0, 0)
    local x_type_popup = add_ctrl(dialog, "popup", "", col[2], row[13], row_h, col_w * 1.3, 0, 0)
    local x_types = {"Xs and Circled Xs (simple)", "Xs and Diamonds (simple)", "Xs and Circled Xs (ornate)", "Xs and Diamonds (ornate)"}
    for i, j in pairs(x_types) do
        str.LuaString = x_types[i]
        x_type_popup:AddString(str)
    end
    x_type_popup:SetSelectedItem(x_type)
    --
    add_ctrl(dialog, "horizontalline", "", col[1], row[14] + 10, 1, col_w * 3, 0, 0)
    --
    local lyrics_all_static = add_ctrl(dialog, "static", "Lyrics | Link Baselines:", col[1], row[15], row_h, col_w, 0, 0)
    local lyrics_all_check = add_ctrl(dialog, "checkbox", "", col[2], row[15] - 3, row_h, col_w, 0, 0)
    if lyrics_all == "true" or lyrics_all == true then
        lyrics_all_check:SetCheck(1)
    else
        lyrics_all_check:SetCheck(0)
    end

    --[[ ]]
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    --
    --    function callback(ctrl)
    --    end -- callback
    ----
    --    dialog:RegisterHandleCommand(callback)
    --
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        tacet_edit:GetText(tacet_text)
        config.tacet_text = tacet_text.LuaString
        --
        al_fine_edit:GetText(al_fine_text)
        config.al_fine_text = al_fine_text.LuaString
        --
        play_x_bars_prefix_edit:GetText(play_x_bars_prefix)
        config.play_x_bars_prefix = play_x_bars_prefix.LuaString
        play_x_bars_suffix_edit:GetText(play_x_bars_suffix)
        config.play_x_bars_suffix = play_x_bars_suffix.LuaString
        --
        play_x_more_prefix_edit:GetText(play_x_more_prefix)
        config.play_x_more_prefix = play_x_more_prefix.LuaString
        play_x_more_suffix_edit:GetText(play_x_more_suffix)
        config.play_x_more_suffix = play_x_more_suffix.LuaString
        --
        dynamic_L_cushion_edit:GetText(dynamic_L_cushion)
        config.dynamic_L_cushion = dynamic_L_cushion.LuaString
        dynamic_R_cushion_edit:GetText(dynamic_R_cushion)
        config.dynamic_R_cushion = dynamic_R_cushion.LuaString
        noteentry_cushion_edit:GetText(noteentry_cushion)
        config.noteentry_cushion = noteentry_cushion.LuaString
        staff_cushion_edit:GetText(staff_cushion)
        config.staff_cushion = staff_cushion.LuaString
        dynamic_above_edit:GetText(dynamic_above_cushion)
        config.dynamic_above_cushion = dynamic_above_cushion.LuaString
        --
        nudge_normal_edit:GetText(nudge_normal)
        config.nudge_normal = nudge_normal.LuaString
        nudge_large_edit:GetText(nudge_large)
        config.nudge_large = nudge_large.LuaString
        --
        config.x_type = x_type_popup:GetSelectedItem()
        --
        if lyrics_all_check:GetCheck() == 1 then
            config.lyrics_all = "true"
        else
            config.lyrics_all = "false"
        end
        --
        configuration.save_user_settings(script_name, config)
    end
end -- config_jetstream()

-- config_jetstream()

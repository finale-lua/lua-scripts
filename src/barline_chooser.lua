function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.11"
    finaleplugin.Date = "2023/07/17"
    finaleplugin.AdditionalMenuOptions = [[
        Barline Chooser Repeat
    ]]
    finaleplugin.AdditionalUndoText = [[
        Barline Chooser Repeat
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Change barlines in the current selection (no dialog)
    ]]
    finaleplugin.AdditionalPrefixes = [[
        no_dialog = true
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.ScriptGroupName = "Barline Chooser"
    finaleplugin.ScriptGroupDescription = "Change barlines in the selection by hotkey"
	finaleplugin.Notes = [[
        Change all barlines in the selection to one of seven styles by hotkey. 
        To repeat the same barline change as last time without a confirmation dialog, 
        select the "Barline Chooser Repeat" menu or hold down the SHIFT key when 
        starting the script.
    ]]
    return "Barline Chooser...", "Barline Chooser", "Change barlines in the selection by keystroke"
end

no_dialog = no_dialog or false
local barline_choice = {
    "Normal",   "Dashed",   "Double",    "Final",
    "None",     "Thick",    "Tick"
}
local config = {
    Normal = "N", -- keystroke bindings
    Dashed = "S",
    Double = "D",
    Final = "F",
    None = "X",
    Thick = "H",
    Tick = "I",
    chosen_barline = 1,
    ignore_duplicates = false,
    window_pos_x = false, -- saved dialog window position
    window_pos_y = false,
}
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local script_name = "barline_chooser"

function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

function reassign_keystrokes()
    local y_step, x_wide = 17, 160
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors = false, {}
    local y = 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Reassign Keys")
    for _, v in ipairs(barline_choice) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v):SetText(config[v]):SetWidth(20)
        dialog:CreateStatic(25, y):SetText(v):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide + 10)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore_duplicates or 0)
    dialog:CreateOkButton():SetText("Save")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for i, v in ipairs(barline_choice) do
            local key = self:GetControl(v):GetText()
            key = string.upper(string.sub(key, 1, 1)) -- 1st letter, upper case
            if key == "" then key = "?" end -- not null
            config[v] = key -- save for another possible run-through
            config.ignore_duplicates = ignore:GetCheck()
            if config.ignore_duplicates == 0 then -- DON'T IGNORE duplicates
                if assigned[key] then -- previously assigned
                    is_duplicate = true
                    if not errors[key] then errors[key] = { assigned[key] } end
                    table.insert(errors[key], i)
                else
                    assigned[key] = i -- flag key assigned
                end
            end
        end
        if is_duplicate then -- list reassignment duplications
            local msg = ""
            for k, v in pairs(errors) do
                msg = msg .. "Key \"" .. k .. "\" is assigned to: "
                for i, w in ipairs(v) do
                    if i > 1 then msg = msg .. " and " end
                    msg = msg .. "\"" .. barline_choice[w] .. "\""
                end
                msg = msg .. "\n\n"
            end
            finenv.UI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

function user_choices()
    local join = finenv.UI():IsOnMac() and "\t" or ": "
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Choose Barline Style:"):SetWidth(150)
    local y, box_high, box_wide = 20, 122, 152
    local barline_list = dialog:CreateListBox(0, y):SetWidth(box_wide):SetHeight(box_high)

    local function fill_barline_list()
        barline_list:Clear()
        for i, v in ipairs(barline_choice) do
            barline_list:AddString(config[v] .. join .. v)
            if i == config.chosen_barline then barline_list:SetSelectedItem(i - 1) end
        end
    end
    fill_barline_list()
    y = box_high + 30
    local reassign = dialog:CreateButton(box_wide / 8, y)
        :SetText("Reassign Keys"):SetWidth(box_wide * 3 / 4)
    reassign:AddHandleCommand(function()
        local ok, is_duplicate = true, true
        while ok and is_duplicate do -- wait for valid choices in reassign_keystrokes()
            ok, is_duplicate = reassign_keystrokes()
        end
        if ok then
            configuration.save_user_settings(script_name, config)
            fill_barline_list()
        end
    end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        config.chosen_barline = barline_list:GetSelectedItem() + 1
    end)
    dialog:RegisterInitWindow(function() barline_list:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function() dialog_save_position(dialog) end)
    dialog_set_position(dialog)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function change_barlines()
    configuration.get_user_settings(script_name, config, true)
    local mod_key = finenv.QueryInvokedModifierKeys and
        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
      or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
    )

    if no_dialog or mod_key or user_choices() then
        local style_name = "BARLINE_" .. string.upper( barline_choice[config.chosen_barline] )
        local measures = finale.FCMeasures()
        measures:LoadRegion(finenv.Region())
        for m in each(measures) do
            m.Barline = finale[style_name]
        end
        measures:SaveAll()
    end
    finenv.UI():ActivateDocumentWindow()
end

change_barlines()

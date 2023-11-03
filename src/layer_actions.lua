function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.06"
    finaleplugin.Date = "2023/10/15"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        Perform specific actions on individual note layers in the current selection. 
        Each action in the list begins with a configurable hotkey. 
        Open the script, type the hotkey and hit RETURN or ENTER. 
        To repeat the same action as last time without a confirmation dialog 
        hold down the SHIFT key when starting the script.

        Actions:
        - Erase Layer
        - Playback Enable
        - Playback Mute
        - Visible
        - Invisible
        - Stems Up
        - Stems Down
        - Stems Default

        Note that "Erase Layer" will delete a whole measure even if only part of 
        it is selected. All other actions respect selection boundaries. 
        This script replaces four old (deprecated) ones in the repo: 
        "layer_hide.lua", "layer_mute.lua", 
        "stem_direction_by_layer.lua" and "layer_clear_selective.lua".
	]]
    return "Layer Actions...", "Layer Actions", "Perform specific actions on individual layers in the current selection"
end

local dialog_options = { -- key, text description (ordered)
    { "erase", "Erase Layer"},
    { "play_yes", "Playback Enable" },
    { "play_no", "Playback Mute"},
    { "see_yes", "Visible"},
    { "see_no", "Invisible" },
    { "stems_up", "Stems Up"},
    { "stems_down", "Stems Down"},
    { "stems_default", "Stems Default"},
}

local config = { -- keystroke assignments and window position
    erase = "X",
    play_yes = "P",
    play_no = "M",
    see_yes = "V",
    see_no = "I",
    stems_up = "Q",
    stems_down = "W",
    stems_default = "E",
    layer_num = "1",
    last_selected = 0, -- last selected menu item number (0-based)
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local script_name = "layer_actions"

function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function change_layer_state(state)
    local rgn = finenv.Region()
    local layer_num = tonumber(config.layer_num)
    if state == "erase" then
        if layer_num == 0 then
            rgn:CutMusic()
            rgn:ReleaseMusic()
        else
            layer.clear(rgn, layer_num)
        end
    else
        for entry in eachentrysaved(rgn, layer_num) do
            local note = entry:IsNote()
            if state:find("see") then
                entry.Visible = (state == "see_yes")
            elseif state:find("play") then
                if note then entry.Playback = (state == "play_yes") end
            else -- if state:find("stems") then
                if note then
                    local default = (state == "stems_default")
                    entry.FreezeStem = not default
                    if not default then
                        entry.StemUp = (state == "stems_up")
                    end
                end
            end
        end
    end
end

local function reassign_keystrokes(index)
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors = false, {}
    local y = 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Reassign Keys")

    for _, v in ipairs(dialog_options) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v[1]):SetText(config[v[1]]):SetWidth(20)
            :AddHandleCommand(function(self)
                local str = self:GetText():upper()
                self:SetText(str:sub(-1)):SetKeyboardFocus()
            end)
        dialog:CreateStatic(25, y):SetText(v[2]):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore_duplicates or 0)
    dialog:CreateOkButton():SetText("Save")
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
        self:GetControl(dialog_options[index][1]):SetKeyboardFocus()
    end)
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for i, v in ipairs(dialog_options) do
            local key = self:GetControl(v[1]):GetText() or "?"
            if key == "" then key = "?" end -- not null
            config[v[1]] = key -- save for another possible run-through
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
                    msg = msg .. "\"" .. dialog_options[w][2] .. "\""
                end
                msg = msg .. "\n\n"
            end
            finenv.UI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

local function user_chooses()
    local max = layer.max_layers()
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local y, y_step = 0, 17
    local box_wide = 220
    local box_high = (#dialog_options * y_step) + 4
    local start, stop = finenv.Region().StartMeasure, finenv.Region().EndMeasure
    local message = (start == stop) and ("(m." .. start) or ("(mm." .. start .. "-" .. stop)
    local notes = finaleplugin.Notes:gsub(" %s+", " "):gsub("\n ", "\n"):sub(2)
    local function show_info() finenv.UI():AlertInfo(notes, "About " .. plugindef()) end

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, y):SetText("Choose Layer Action:"):SetWidth(box_wide)
    dialog:CreateStatic(box_wide - 80, y):SetText(message .. ")"):SetWidth(80)
    y = y + 20
    local key_list = dialog:CreateListBox(0, y):SetWidth(box_wide):SetHeight(box_high)

        local function fill_key_list()
            local join = finenv.UI():IsOnMac() and "\t" or ": "
            key_list:Clear()
            for _, option in ipairs(dialog_options) do -- add ordered options with keycodes
                key_list:AddString(config[option[1]] .. join .. option[2])
            end
            key_list:SetSelectedItem(config.last_selected)
        end
        local function change_keys()
            local ok, is_duplicate = true, true
            while ok and is_duplicate do -- wait for valid choice in reassign_keystrokes()
                ok, is_duplicate = reassign_keystrokes(key_list:GetSelectedItem() + 1)
            end
            if ok then fill_key_list() end
        end

    fill_key_list()
    local x_off = box_wide / 4
    y = y + box_high + 7
    dialog:CreateStatic(0, y):SetWidth(x_off + 4):SetText("Layer 1-" .. max .. ":")
    local save_layer = config.layer_num
    local layer_num = dialog:CreateEdit(x_off + 4, y - offset):SetWidth(30):SetText(save_layer)
        :AddHandleCommand(function(self)
            local val = self:GetText():lower()
            if val:find("[^0-4]") then
                if val:find("r") then change_keys()
                elseif val:find("q") then show_info()
                end
                self:SetText(save_layer):SetKeyboardFocus()
            else
                val = val:sub(-1)
                self:SetText(val)
                save_layer = val
            end
        end)
    dialog:CreateStatic(x_off + 36, y):SetWidth(80):SetText("(0 = all)")
    y = y + y_step + 2
    dialog:CreateButton(0, y)
        :SetText("Reassign Hotkeys"):SetWidth(x_off * 2) -- half box width
        :AddHandleCommand(function() change_keys() end)
    dialog:CreateButton(box_wide - 20, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dialog:CreateOkButton():SetText("Change")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function() key_list:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dialog:RegisterHandleOkButtonPressed(function()
        config.layer_num = layer_num:GetInteger()
        config.last_selected = key_list:GetSelectedItem() -- list choice, 0-based
    end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function layer_state()
    configuration.get_user_settings(script_name, config, true)
    local shift_key = finenv.QueryInvokedModifierKeys and finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)

    if shift_key or user_chooses() then
        local choice = config.last_selected + 1
        change_layer_state(dialog_options[choice][1])
    end
    finenv.UI():ActivateDocumentWindow()
end

layer_state()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.10"
    finaleplugin.Date = "2024/04/16"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        Perform specific actions on individual note layers in the current selection. 
        Each action in the list begins with a configurable _hotkey_. 
        Open the script, type the _hotkey_ and hit [Return] or [Enter]. 
        To repeat the same action as last time without a confirmation 
        dialog hold down [Shift] when starting the script. 
        Eight layer actions are available: 

        > - Erase Layer 
        > - Playback Enable 
        > - Playback Mute 
        > - Visible 
        > - Invisible 
        > - Stems Up 
        > - Stems Down 
        > - Stems Default 
	]]
    return "Layer Actions...", "Layer Actions",
        "Perform specific actions on individual layers in the current selection"
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
    layer_num = 0,
    selected = 0, -- last selected menu item number (0-based)
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local utils = require("library.utils")
local note_entry = require("library.note_entry")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false -- set to true if utils.show_notes_dialog is used

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
    if state == "erase" then -- LAYER ERASURE
        for entry in eachentrysaved(rgn, layer_num) do
            if entry:IsNote() then note_entry.make_rest(entry) end
        end
        for m, s in eachcell(rgn) do
            local c = finale.FCNoteEntryCell(m, s)
            c:Load()
            c:ReduceEntries()
            c:Save()
        end
    else -- other states are note-by-note
        for entry in eachentrysaved(rgn, layer_num) do
            if state:find("see") then -- notes and rests
                entry.Visible = (state == "see_yes")
            elseif entry:IsNote() then -- notes only
                if state:find("play") then
                    entry.Playback = (state == "play_yes")
                else -- stem condition
                    local not_default = (state ~= "stems_default")
                    entry.FreezeStem = not_default
                    if not_default then
                        entry.StemUp = (state == "stems_up")
                    end
                end
            end
        end
    end
end

local function reassign_keystrokes(parent, index)
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors = false, {}
    local y = 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Layers: Reassign Keys")

    for _, v in ipairs(dialog_options) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v[1]):SetText(config[v[1]]):SetWidth(20)
            :AddHandleCommand(function(self)
                local str = self:GetText():sub(-1):upper()
                self:SetText(str):SetKeyboardFocus()
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
            local key = self:GetControl(v[1]):GetText()
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
    local ok = (dialog:ExecuteModal(parent) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

local function user_chooses()
    local max = layer.max_layers()
    local y, y_step = 0, 17
    local box_wide = 220
    local box_high = (#dialog_options * y_step) + 4
    local name = plugindef():gsub("%.%.%.", "")
    local start, stop = finenv.Region().StartMeasure, finenv.Region().EndMeasure
    local message = (start == stop) and ("(m." .. start) or ("(mm." .. start .. "-" .. stop)

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
    dialog:CreateStatic(0, y):SetText("Choose Layer Action:"):SetWidth(box_wide)
    dialog:CreateStatic(box_wide - 80, y):SetText(message .. ")"):SetWidth(80)
    y = y + 20
    local key_list = dialog:CreateListBox(0, y):SetWidth(box_wide):SetHeight(box_high)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 400, 290)
            refocus_document = true
        end
        local function fill_key_list()
            local join = finenv.UI():IsOnMac() and "\t" or ": "
            key_list:Clear()
            for _, option in ipairs(dialog_options) do -- add ordered options with keycodes
                key_list:AddString(config[option[1]] .. join .. option[2])
            end
            key_list:SetSelectedItem(config.selected)
        end
        local function change_keys()
            local ok, is_duplicate = true, true
            while ok and is_duplicate do -- wait for valid choice in reassign_keystrokes()
                ok, is_duplicate = reassign_keystrokes(dialog, key_list:GetSelectedItem() + 1)
            end
            if ok then fill_key_list() end
        end

    fill_key_list()
    local x_off = box_wide / 4
    y = y + box_high + 7
    dialog:CreateStatic(0, y):SetWidth(x_off + 4):SetText("Layer 1-" .. max .. ":")
    local save_layer = tostring(config.layer_num)
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local layer_num = dialog:CreateEdit(x_off + 4, y - offset):SetWidth(20):SetText(save_layer)
        :AddHandleCommand(function(self)
            local val = self:GetText():lower()
            if val:find("[^0-" .. max .. "]") then
                if val:find("r") then change_keys()
                elseif val:find("[?q]") then show_info()
                end
            elseif val ~= "" then
                save_layer = val:sub(-1)
            end
            self:SetText(save_layer):SetKeyboardFocus()
        end)
    dialog:CreateStatic(x_off + 26, y):SetWidth(60):SetText("(0 = all)")
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
        config.selected = key_list:GetSelectedItem() -- list choice, 0-based
    end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function layer_state()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    if mod_key or user_chooses() then
        local choice = config.selected + 1
        change_layer_state(dialog_options[choice][1])
    end
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

layer_state()

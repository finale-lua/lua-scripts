function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.62"
    finaleplugin.Date = "2023/07/09"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        Change the condition of tuplets in the current selection to:

        - Avoid Staff
        - Don't Avoid Staff
        - Flat
        - Not Flat
        - Flip
        - Invisible
        - Visible
        - Bracket Unbeamed Only
        - Bracket Always
        - Bracket Opposite Beamed Side
        - Reset (to Default Preferences)
        
        The script provides a list of options, each line beginning with a configurable "hotkey". 
        Open the script, type the hotkey and hit [Enter] or [Return]. 
        Actions may optionally be limited to one of 4 layers.
	]]
    return "Tuplet Chooser...", "Tuplet Chooser", "Change the condition of tuplets in the current selection"
end

local dialog_options = { -- key, text description (ordered)
    { "avoid", "Avoid Staff" },
    { "not_avoid", "Don't Avoid Staff" },
    { "flat", "Flat" },
    { "not_flat", "Not Flat" },
    { "flip", "Flip" },
    { "invisible", "Invisible" },
    { "visible", "Visible" },
    { "bracket_unbeam", "Bracket Unbeamed Only" },
    { "bracket_always", "Bracket Always" },
    { "bracket_opp_beam", "Bracket Opp. Beamed Side" },
    { "reset", "Reset (Default Preferences)" },
}

local config = { -- keystroke assignments and window position
    avoid =  "A",
    not_avoid = "D",
    flat = "F",
    not_flat = "N",
    flip = "X",
    visible = "V",
    invisible = "I",
    bracket_unbeam = "U",
    bracket_always = "J",
    bracket_opp_beam = "O",
    reset = "R",
    layer_num = 0,
    ignore_duplicates = 0,
    last_selected = 0, -- last selected menu item number (0-based)
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local script_name = "tuplet_chooser"
configuration.get_user_settings(script_name, config, true)

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

function change_tuplet_state(state)
    for entry in eachentry(finenv.Region(), config.layer_num) do
        if entry:IsStartOfTuplet() then
            for tuplet in each(entry:CreateTuplets()) do
                if state == "visible" or state == "invisible" then
                    tuplet.Visible = (state == "visible")
                elseif state == "flat" or state == "not_flat" then
                    tuplet.AlwaysFlat = (state == "flat")
                elseif state == "avoid" or state == "not_avoid" then
                    tuplet.AvoidStaff = (state == "avoid")
                elseif state == "reset" then
                    tuplet:PrefsReset(true)
                elseif state == "flip" then
                    local placement = tuplet.PlacementMode
                    if placement == finale.TUPLETPLACEMENT_STEMSIDE then
                        tuplet.PlacementMode = finale.TUPLETPLACEMENT_NOTESIDE
                    elseif placement == finale.TUPLETPLACEMENT_NOTESIDE then
                        tuplet.PlacementMode = finale.TUPLETPLACEMENT_STEMSIDE
                    elseif placement == finale.TUPLETPLACEMENT_ABOVE then
                        tuplet.PlacementMode = finale.TUPLETPLACEMENT_BELOW
                    elseif placement == finale.TUPLETPLACEMENT_BELOW then
                        tuplet.PlacementMode = finale.TUPLETPLACEMENT_ABOVE
                    end
                elseif state:find("bracket") then
                    local bracket = finale.TUPLETBRACKET_ALWAYS -- (assume "always" bracket)
                    if state == "bracket_unbeam" then
                        bracket = finale.TUPLETBRACKET_UNBEAMEDONLY
                    elseif state == "bracket_opp_beam" then
                        bracket = finale.TUPLETBRACKET_NEVERBEAMEDONBEAMSIDE
                    end
                    tuplet.BracketMode = bracket
                end
                tuplet:Save()
            end
        end
    end
end

function reassign_keystrokes()
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors = false, {}
    local y = 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Tuplets: Reassign Keys")
    for _, v in ipairs(dialog_options) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v[1]):SetText(config[v[1]]):SetWidth(20)
        dialog:CreateStatic(25, y):SetText(v[2]):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore_duplicates or 0)
    dialog:CreateOkButton():SetText("Save")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for i, v in ipairs(dialog_options) do
            local key = self:GetControl(v[1]):GetText()
            key = string.upper(string.sub(key, 1, 1)) -- 1st letter, upper case
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

function user_chooses()
    local max = layer.max_layers()
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local join = finenv.UI():IsOnMac() and "\t" or ": "
    local y_step = 17
    local box_wide = 220
    local box_high = (#dialog_options * y_step) + 5
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Change Tuplets To:"):SetWidth(box_wide)

    local key_list = dialog:CreateListBox(0, 20):SetWidth(box_wide):SetHeight(box_high)
    local function fill_key_list()
        key_list:Clear()
        for _, option in ipairs(dialog_options) do -- add all options with keycodes
            key_list:AddString(config[option[1]] .. join .. option[2])
        end
        key_list:SetSelectedItem(config.last_selected or 0)
    end
    fill_key_list()

    local x_off = box_wide / 4
    local y = box_high + 30
    local reassign = dialog:CreateButton(x_off, y)
        :SetText("Reassign Keys"):SetWidth(x_off * 2) -- half box width
    reassign:AddHandleCommand(function()
        local ok, is_duplicate = true, true
        while ok and is_duplicate do -- wait for valid choices in reassign_keystrokes()
            ok, is_duplicate = reassign_keystrokes()
        end
        if ok then
            configuration.save_user_settings(script_name, config)
            fill_key_list()
        end
    end)
    y = y + 25
    dialog:CreateStatic(12, y):SetWidth(x_off * 2)
        :SetText("Active Layer 1-" .. max .. ":")
    local layer_num = dialog:CreateEdit(x_off * 2, y - offset):SetWidth(20)
        :SetInteger(config.layer_num or 0)
    dialog:CreateStatic(x_off * 2 + 24, y):SetWidth(80)
        :SetText("(0 = all)")
    dialog:CreateOkButton():SetText("Select")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function() key_list:SetKeyboardFocus() end)
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.last_selected = key_list:GetSelectedItem() -- save list choice
        config.layer_num = math.min(math.max(layer_num:GetInteger(), 0), max)
        dialog_save_position(self)
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function tuplets_change()
    if user_chooses() then
        local state = dialog_options[config.last_selected + 1][1]
        change_tuplet_state(state)
        finenv.UI():ActivateDocumentWindow()
    end
end

tuplets_change()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.70.1"
    finaleplugin.Date = "2023/11/15"
    finaleplugin.AdditionalMenuOptions = [[
        Tuplet Chooser Repeat
    ]]
    finaleplugin.AdditionalUndoText = [[
        Tuplet Chooser Repeat
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Repeat the last change of tuplet condition (no dialog)
    ]]
    finaleplugin.AdditionalPrefixes = [[
        no_dialog = true
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.ScriptGroupName = "Tuplet Chooser"
    finaleplugin.ScriptGroupDescription = "Change the condition of tuplets in the current selection by layer"
    finaleplugin.Notes = [[
        This script changes the tuplets in the current selection in 18 ways. 
        It shows an ordered list of options, 
        each line starting with a configurable "hotkey". 
        Activate the script, type the hotkey and hit [Enter] or [Return]. 
        The action may also be limited by layer.

        To repeat the same tuplet change as last time without a confirmation dialog, 
        hold down the SHIFT key when starting the script 
        or select the "Tuplet Chooser Repeat" menu.

        The layer number is "clamped" to a single character so to change 
        layer just type a new number - 'delete' key not needed.
	]]
    return  "Tuplet Chooser...", "Tuplet Chooser",
            "Change the condition of tuplets in the current selection by layer"
end

local info_notes = [[
This script changes the tuplets in the current selection in 18 ways. 
It shows an ordered list of options, 
each line starting with a configurable "hotkey". 
Activate the script, type the hotkey and hit [Enter] or [Return]. 
The action may also be limited by layer.  
]] .. "\n" .. [[
To repeat the same tuplet change as last time without a confirmation dialog, 
hold down the SHIFT key when starting the script 
or select the "Tuplet Chooser Repeat" menu.  
]] .. "\n" .. [[
The layer number is "clamped" to a single character so to change 
layer just type a new number - 'delete' key not needed.
]]

no_dialog = no_dialog or false
local dialog_options = { -- key, text description (ordered)
    { "avoid", "Avoid Staff" },
    { "not_avoid", "Don't Avoid Staff" },
    { "flat", "Flat" },
    { "not_flat", "Not Flat" },
    { "flip", "Flip" },
    { "invisible", "Invisible" },
    { "visible", "Visible" },
    { "TUPLETBRACKET_ALWAYS",       "Bracket: Always" },
    { "TUPLETBRACKET_NEVERBEAMEDONBEAMSIDE", "Bracket: Opp. Beamed Side" },
    { "TUPLETBRACKET_UNBEAMEDONLY", "Bracket: Unbeamed Only" },
    { "TUPLETPLACEMENT_ABOVE", "Place: Above" },
    { "TUPLETPLACEMENT_BELOW", "Place: Below" },
    { "TUPLETPLACEMENT_MANUAL", "Place: Manual" },
    { "TUPLETPLACEMENT_NOTESIDE", "Place: Note Side" },
    { "TUPLETPLACEMENT_STEMSIDE", "Place: Stem Side" },
    { "TUPLETSHAPE_NONE",     "Shape: None" },
    { "TUPLETSHAPE_BRACKET",  "Shape: Bracket" },
    { "TUPLETSHAPE_SLUR",     "Shape: Slur" },
    { "TUPLETNUMBER_NONE",    "Number: None" },
    { "TUPLETNUMBER_REGULAR", "Number: Regular" },
    { "TUPLETNUMBER_RATIO",   "Number: Ratio" },
    { "TUPLETNUMBER_RATIOANDNOTE",      "Number: Ratio+Note" },
    { "TUPLETNUMBER_RATIOANDNOTE_BOTH", "Number: Ratio+Note Both" },
    { "reset", "Reset (Default Preferences)" },
}

local config = { -- keystroke assignments and window position
    avoid =  "A",
    not_avoid = "D",
    flat = "F",
    not_flat = "N",
    flip = "X",
    invisible = "I",
    visible = "V",
    TUPLETPLACEMENT_ABOVE = "Y",
    TUPLETPLACEMENT_BELOW = "B",
    TUPLETPLACEMENT_MANUAL = "H",
    TUPLETPLACEMENT_STEMSIDE = "G",
    TUPLETPLACEMENT_NOTESIDE = "J",
    TUPLETBRACKET_UNBEAMEDONLY = "U",
    TUPLETBRACKET_ALWAYS = "K",
    TUPLETBRACKET_NEVERBEAMEDONBEAMSIDE = "O",
    TUPLETSHAPE_NONE = "0",
    TUPLETSHAPE_BRACKET = "1",
    TUPLETSHAPE_SLUR = "2",
    TUPLETNUMBER_NONE = "Q",
    TUPLETNUMBER_REGULAR = "W",
    TUPLETNUMBER_RATIO = "E",
    TUPLETNUMBER_RATIOANDNOTE = "R",
    TUPLETNUMBER_RATIOANDNOTE_BOTH = "T",
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

local function dialog_set_position(dialog)
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

local function change_tuplet_state(state)
    for entry in eachentry(finenv.Region(), config.layer_num) do
        if entry:IsStartOfTuplet() then
            for tuplet in eachbackwards(entry:CreateTuplets()) do
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
                    for _, v in ipairs({
                            {finale.TUPLETPLACEMENT_STEMSIDE, finale.TUPLETPLACEMENT_NOTESIDE},
                            {finale.TUPLETPLACEMENT_ABOVE,    finale.TUPLETPLACEMENT_BELOW}
                        }) do
                        if     placement == v[1] then tuplet.PlacementMode = v[2]
                        elseif placement == v[2] then tuplet.PlacementMode = v[1]
                        end
                    end
                elseif state:find("TUPLETPLACEMENT") then
                    tuplet.PlacementMode = finale[state]
                elseif state:find("TUPLETBRACKET") then
                    tuplet.BracketMode = finale[state]
                elseif state:find("TUPLETSHAPE") then
                    tuplet.ShapeStyle = finale[state]
                elseif state:find("TUPLETNUMBER") then
                    tuplet.NumberStyle = finale[state]
                end
                tuplet:Save()
            end
        end
    end
end

local function reassign_keystrokes(index)
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors = false, {}
    local y = 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Tuplets: Reassign Keys")
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
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

local function user_chooses()
    local max = layer.max_layers()
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local y_step = 17
    local box_wide = 220
    local box_high = (#dialog_options * y_step) + 4
    info_notes = info_notes:gsub("  \n",  "\n"):gsub(" %s+", " "):gsub("\n ", "\n")
    local function show_info()
        finenv.UI():AlertInfo(info_notes, "About " .. finaleplugin.ScriptGroupName)
    end
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Change Tuplets To:"):SetWidth(box_wide)
    dialog:CreateButton(box_wide - 20, 0):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    local key_list = dialog:CreateListBox(0, 22):SetWidth(box_wide):SetHeight(box_high)

        local function fill_key_list()
            local join = finenv.UI():IsOnMac() and "\t" or ": "
            key_list:Clear()
            for _, option in ipairs(dialog_options) do -- add options with keycodes
                key_list:AddString(config[option[1]] .. join .. option[2])
            end
            key_list:SetSelectedItem(config.last_selected or 0)
        end
        local function change_keys()
            local ok, is_duplicate = true, true
            while ok and is_duplicate do -- wait for good choice in reassign()
                ok, is_duplicate = reassign_keystrokes(key_list:GetSelectedItem() + 1)
            end
            if ok then fill_key_list() end
        end

    fill_key_list()
    local x_off = box_wide / 4
    local y = box_high + 32
    dialog:CreateButton(x_off, y):SetText("Reassign Hotkeys")
        :AddHandleCommand(function() change_keys() end):SetWidth(x_off * 2)
    y = y + 25
    dialog:CreateStatic(50, y):SetWidth(x_off * 2):SetText("Layer 1-" .. max .. ":")
    local save_layer = config.layer_num
    local layer_num = dialog:CreateEdit(x_off * 2, y - offset)
        :SetWidth(30):SetText(save_layer)
        :AddHandleCommand(function(self) -- key command replacements
            local val = self:GetText():lower()
            if val:find("[^0-4]") then
                if val:find("[?q]") then show_info()
                elseif val:find("r") then change_keys()
                end
                self:SetText(save_layer):SetKeyboardFocus()
            elseif val ~= "" then
                val = val:sub(-1)
                self:SetText(val)
                save_layer = val
            end
        end)

    dialog:CreateStatic(x_off * 2 + 34, y):SetWidth(80):SetText("(0 = all)")
    dialog:CreateOkButton():SetText("Select")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function() key_list:SetKeyboardFocus() end)
    dialog:RegisterHandleOkButtonPressed(function(_self)
        config.last_selected = key_list:GetSelectedItem() -- save list choice (0-based)
        config.layer_num = layer_num:GetInteger()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function tuplets_change()
    configuration.get_user_settings(script_name, config, true)
    local qimk = finenv.QueryInvokedModifierKeys
    local mod_key = qimk and (qimk(finale.CMDMODKEY_ALT) or qimk(finale.CMDMODKEY_SHIFT))

    if no_dialog or mod_key or user_chooses() then
        local state = dialog_options[config.last_selected + 1][1]
        change_tuplet_state(state)
    end
    finenv.UI():ActivateDocumentWindow()
end

tuplets_change()

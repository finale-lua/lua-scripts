function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.74"
    finaleplugin.Date = "2024/04/17"
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
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.ScriptGroupName = "Tuplet Chooser"
    finaleplugin.ScriptGroupDescription = "Change the condition of tuplets in the current selection by layer"
    finaleplugin.Notes = [[
        This script changes tuplets in the current selection in 
        24 ways on all or nominated layers. 
        It provides an ordered list of options,
        each line starting with a configurable _hotkey_. 
        Start the script, type the _hotkey_ and hit [Return]. 

        To repeat the same tuplet change as last time without a 
        confirmation dialog, select the __Tuplet Chooser Repeat__ menu 
        or hold down [Shift] when starting the script. 
	]]
    return  "Tuplet Chooser...",
            "Tuplet Chooser",
            "Change the condition of tuplets in the current selection by layer"
end

no_dialog = no_dialog or false

local dialog_options = { -- NAME key; HOTKEY; text description (ordered)
    { "avoid",                      "A", "Avoid Staff" },
    { "not_avoid",                  "D", "Don't Avoid Staff" },
    { "flat",                       "F", "Flat" },
    { "not_flat",                   "N", "Not Flat" },
    { "flip",                       "X", "Flip" },
    { "invisible",                  "I", "Invisible" },
    { "visible",                    "V", "Visible" },
    { "TUPLETBRACKET_ALWAYS",       "K", "Bracket: Always" },
    { "TUPLETBRACKET_NEVERBEAMEDONBEAMSIDE", "O", "Bracket: Opp. Beamed Side" },
    { "TUPLETBRACKET_UNBEAMEDONLY", "U", "Bracket: Unbeamed Only" },
    { "TUPLETPLACEMENT_ABOVE",      "Y", "Place: Above" },
    { "TUPLETPLACEMENT_BELOW",      "B", "Place: Below" },
    { "TUPLETPLACEMENT_MANUAL",     "H", "Place: Manual" },
    { "TUPLETPLACEMENT_NOTESIDE",   "J", "Place: Note Side" },
    { "TUPLETPLACEMENT_STEMSIDE",   "G", "Place: Stem Side" },
    { "TUPLETSHAPE_NONE",           "0", "Shape: None" },
    { "TUPLETSHAPE_BRACKET",        "1", "Shape: Bracket" },
    { "TUPLETSHAPE_SLUR",           "2", "Shape: Slur" },
    { "TUPLETNUMBER_NONE",          "Q", "Number: None" },
    { "TUPLETNUMBER_REGULAR",       "W", "Number: Regular" },
    { "TUPLETNUMBER_RATIO",         "E", "Number: Ratio" },
    { "TUPLETNUMBER_RATIOANDNOTE",  "R", "Number: Ratio+Note" },
    { "TUPLETNUMBER_RATIOANDNOTE_BOTH", "T", "Number: Ratio+Note Both" },
    { "reset",                      "Z", "Reset (Default Preferences)" }
}

local config = { -- user CONFIG
    layer_num = 0,
    ignore_duplicates = 0,
    last_selected = 0, -- last selected menu item number (0-based)
    window_pos_x = false,
    window_pos_y = false,
}
for _, v in ipairs(dialog_options) do -- add HOTKEYS to CONFIG
    config[v[1]] = v[2] -- map NAME key onto HOTKEY
end

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false -- set to true if utils.show_notes_dialog is used

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

local function change_tuplet_state()
    local state = dialog_options[config.last_selected + 1][1]
    for entry in eachentry(finenv.Region(), config.layer_num) do
        if entry:IsStartOfTuplet() then
            for tuplet in eachbackwards(entry:CreateTuplets()) do
                if state:find("visible") then
                    tuplet.Visible = (state == "visible")
                elseif state:find("flat") then
                    tuplet.AlwaysFlat = (state == "flat")
                elseif state:find("avoid") then
                    tuplet.AvoidStaff = (state == "avoid")
                elseif state == "reset" then
                    tuplet:PrefsReset(true)
                elseif state == "flip" then
                    local placement = tuplet.PlacementMode
                    for _, v in ipairs{
                            {finale.TUPLETPLACEMENT_STEMSIDE, finale.TUPLETPLACEMENT_NOTESIDE},
                            {finale.TUPLETPLACEMENT_ABOVE,    finale.TUPLETPLACEMENT_BELOW}
                        } do
                        if     placement == v[1] then tuplet.PlacementMode = v[2] break
                        elseif placement == v[2] then tuplet.PlacementMode = v[1] break
                        end
                    end
                elseif state:find("BRACKET_") then
                    tuplet.BracketMode = finale[state]
                elseif state:find("PLACEMENT_") then
                    tuplet.PlacementMode = finale[state]
                elseif state:find("SHAPE_") then
                    tuplet.ShapeStyle = finale[state]
                elseif state:find("NUMBER_") then
                    tuplet.NumberStyle = finale[state]
                end
                tuplet:Save()
            end
        end
    end
end

local function reassign_keystrokes(parent, index)
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors = false, {}
    local y = 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Tuplets: Reassign Keys")
    for _, v in ipairs(dialog_options) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v[1]):SetText(config[v[1]]):SetWidth(20)
            :AddHandleCommand(function(self)
                local str = self:GetText():sub(-1):upper()
                self:SetText(str):SetKeyboardFocus()
            end)
        dialog:CreateStatic(25, y):SetText(v[3]):SetWidth(x_wide)
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
        for _, v in ipairs(dialog_options) do
            local key = self:GetControl(v[1]):GetText()
            if key == "" then key = "?" end -- not null
            config[v[1]] = key -- save for another possible run-through
            config.ignore_duplicates = ignore:GetCheck()
            if config.ignore_duplicates == 0 then -- DON'T IGNORE duplicates
                if assigned[key] then -- previously assigned
                    is_duplicate = true
                    if not errors[key] then errors[key] = { assigned[key] } end
                    table.insert(errors[key], v[3])
                else
                    assigned[key] = v[3] -- flag key assigned
                end
            end
        end
        if is_duplicate then -- list reassignment duplications
            local msg = ""
            for k, v in pairs(errors) do
                if msg ~= "" then msg = msg .. "\n\n" end
                msg = msg .. "Key \"" .. k .. "\" is assigned to: "
                for i, w in ipairs(v) do
                    if i > 1 then msg = msg .. " and " end
                    msg = msg .. "\"" .. w .. "\""
                end
            end
            dialog:CreateChildUI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(parent) == finale.EXECMODAL_OK)
    refocus_document = true
    return ok, is_duplicate
end

local function user_chooses()
    local max = layer.max_layers()
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local y_step = 17
    local box_wide = 200
    local box_high = (#dialog_options * y_step) + 4
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(finaleplugin.ScriptGroupName)
    local function show_info()
        utils.show_notes_dialog(dialog, "About " .. finaleplugin.ScriptGroupName, 400, 140)
        refocus_document = true
    end
    dialog:CreateStatic(0, 0):SetText("Change Tuplets To:"):SetWidth(box_wide)
    dialog:CreateButton(box_wide - 20, 0, "q"):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    local key_list = dialog:CreateListBox(0, 22):SetWidth(box_wide):SetHeight(box_high)
        -- local functions
        local function fill_key_list()
            local join = finenv.UI():IsOnMac() and "\t" or ": "
            key_list:Clear()
            for _, option in ipairs(dialog_options) do -- add options with keycodes
                key_list:AddString(config[option[1]] .. join .. option[3])
            end
            key_list:SetSelectedItem(config.last_selected or 0)
        end
        local function change_keys()
            local ok, is_duplicate = true, true
            while ok and is_duplicate do -- wait for good choice in reassign()
                ok, is_duplicate = reassign_keystrokes(dialog, key_list:GetSelectedItem() + 1)
            end
            if ok then
                fill_key_list()
            else -- reinstall hotkeys from user config
                configuration.get_user_settings(script_name, config)
            end
        end

    fill_key_list()
    local x_off = box_wide / 4
    local y = box_high + 29
    dialog:CreateButton(x_off, y):SetText("Change Hotkeys")
        :AddHandleCommand(function() change_keys() end):SetWidth(x_off * 2)
    y = y + 22
    dialog:CreateStatic(42, y):SetWidth(x_off * 2):SetText("Layer 1-" .. max .. ":")
    local save_layer = config.layer_num
    local layer_num = dialog:CreateEdit(x_off * 2, y - offset)
        :SetWidth(20):SetText(save_layer)
        :AddHandleCommand(function(self) -- key command replacements
            local val = self:GetText():lower()
            if val:find("[^0-" .. max .. "]") then
                if val:find("[?q]") then show_info()
                elseif val:find("r") then change_keys()
                end
            elseif val ~= "" then
                val = val:sub(-1)
                save_layer = val:sub(-1)
            end
            self:SetText(save_layer):SetKeyboardFocus()
        end)

    dialog:CreateStatic(x_off * 2 + 20, y):SetWidth(80):SetText("(0 = all)")
    dialog:CreateOkButton():SetText("Select")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function()
        key_list:SetKeyboardFocus()
        local q = dialog:GetControl("q")
        q:SetFont(q:CreateFontInfo():SetBold(true))
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        config.last_selected = key_list:GetSelectedItem() -- save list choice (0-based)
        config.layer_num = layer_num:GetInteger()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function tuplets_change()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    if no_dialog or mod_key or user_chooses() then
        change_tuplet_state()
    end
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

tuplets_change()

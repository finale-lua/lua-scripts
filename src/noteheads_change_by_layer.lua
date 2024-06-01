function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.36"
    finaleplugin.Date = "2024/06/01"
    finaleplugin.AdditionalMenuOptions = [[
        Noteheads Change Repeat
    ]]
    finaleplugin.AdditionalUndoText = [[
        Noteheads Change Repeat
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Change notehead shapes on a specific layer of the current selection (no dialog)
    ]]
    finaleplugin.AdditionalPrefixes = [[
        no_dialog = true
    ]]
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.ScriptGroupName = "Noteheads Change by Layer"
    finaleplugin.ScriptGroupDescription = "Change notehead shapes on a specific layer of the current selection"
    finaleplugin.Notes = [[
        Change __notehead shapes__ on a specific layer of the current 
        selection to one of these options: 

        > Circled | Default | Diamond | Guitar Diamond  
        > Hidden | Number | Round | Slash | Square  
        > Strikethrough | Triangle | Wedge | X  

        This script produces an ordered list of notehead types, 
        each line beginning with a configurable _hotkey_. 
        Call the script, type the _hotkey_ and hit [Return].  

        In __SMuFL__ fonts like _Finale Maestro_, shapes can vary according 
        to duration values. Most duration-dependent shapes are not available 
        in Finale's old (non-SMuFL) _Maestro_ and _Engraver_ fonts. 
        _Diamond (Guitar)_ is like _Diamond_ except quarter notes and shorter use filled diamonds. 
        _Custom Glyph_ lets you specify any font character as a number including 
        __SMuFL__ (Unicode) numbers in the form __0xe0e1__ or __0xE0E1__. 

        To repeat the same action as last time without a confirmation dialog either select the 
        __Noteheads Change Repeat__ menu item or hold down [Shift] when opening the script.
    ]]
    return "Noteheads Change by Layer...", "Noteheads Change by Layer",
        "Change notehead shapes on a specific layer of the current selection"
end

no_dialog = no_dialog or false

local notehead = require("library.notehead")
local mixin = require("library.mixin")
local configuration = require("library.configuration")
local utils = require("library.utils")
local library = require("library.general_library")
local layer = require("library.layer")
local diamond = { smufl = 0xE0E1, non_smufl = 79 }
local script_name = library.calc_script_name()
local refocus_document = false

local dialog_options = { -- notehead name (and key), HOTKEY
    { "Circled",        "C" },
    { "Custom Glyph",   "U", "custom" }, -- special key
    { "Default",        "A" },
    { "Diamond",        "D" },
    { "Guitar Diamond", "G", "diamond_guitar" }, -- special key
    { "Hidden",         "H" }, -- (all other keys are just lower case identifier)
    { "Round",          "R" },
    { "Slash",          "S" },
    { "Square",         "Q" },
    { "Strikethrough",  "E" },
    { "Triangle",       "T" },
    { "Wedge",          "W" },
    { "X",              "Z" }
}
local config = {
    layer_num = 1,
    ignore_duplicates = 0,
    shape = "default",
    glyph = "0xe0e1",
    window_pos_x = false,
    window_pos_y = false
}
for _, v in ipairs(dialog_options) do -- add HOTKEYS to CONFIG
    config[v[1]] = v[2] -- map name (key) onto HOTKEY
end

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

local function user_chooses_glyph()
    local base_glyph = tonumber(config.glyph) or diamond.smufl
    local msg
    if library.is_font_smufl_font() then
        if base_glyph < 0xE000 then base_glyph = diamond.smufl end -- < 57344
        msg = "... as an integer or hex value like \"0xE0E1\". "
            .. "The Default Music Font of the current document "
            .. "is SMuFL compliant so glyph numbers "
            .. "should be higher than 57344 (\"0xE000\")."
    else
        if base_glyph >= 0x1000 then base_glyph = diamond.non_smufl end
        msg = "The Default Music Font of the current document "
        .. "is not SMuFL compliant so glyph numbers "
        .. "should be lower than 4096 (\"0x1000\") "
        .. "and might contain no characters higher than 255"
    end

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(finaleplugin.ScriptGroupName)
    local m_off = finenv.UI():IsOnMac() and 3 or 0 -- y-offset for Mac text box
    local glyph_edit = dialog:CreateEdit(180, 30 - m_off)
    local default_font = finale.FCFontInfo()
    default_font:LoadFontPrefs(finale.FONTPREF_MUSIC)
    dialog:CreateButton(80, 0):SetWidth(150)
        :SetText("Select Custom Glyph")
        :AddHandleCommand(function()
            base_glyph = dialog:CreateChildUI()
                :DisplaySymbolDialog(default_font, base_glyph)
            if base_glyph ~= 0 then
                config.glyph = library.is_font_smufl_font() and
                    string.format("0x%X", base_glyph) or tostring(base_glyph)
                    glyph_edit:SetText(config.glyph)
            end
        end)
    dialog:CreateStatic(50, 30):SetWidth(230):SetText("Custom Glyph Number:")
    dialog:CreateStatic(0, 55):SetWidth(330):SetHeight(50):SetText(msg)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function()
        config.glyph = library.is_font_smufl_font() and
            string.format("0x%X", base_glyph) or tostring(base_glyph)
        glyph_edit:SetText(config.glyph):SetKeyboardFocus()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dialog:RegisterHandleOkButtonPressed(function() config.glyph = glyph_edit:GetText() end)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK)
end

local function reassign_keystrokes(parent, index)
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Noteheads: Reassign Keys")
    local is_duplicate, errors = false, {}
    local y = 0
    for _, v in ipairs(dialog_options) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v[1]):SetText(config[v[1]]):SetWidth(20)
            :AddHandleCommand(function(self)
                local str = self:GetText():sub(-1):upper()
                self:SetText(str):SetKeyboardFocus()
            end)
        dialog:CreateStatic(25, y):SetText(v[1]):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore_duplicates or 0)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
        self:GetControl(dialog_options[index][1]):SetKeyboardFocus()
    end)
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for _, v in ipairs(dialog_options) do
            local key = self:GetControl(v[1]):GetText()
            if key == "" then key = "?" end
            config[v[1]] = key -- save for another possible run-through
            config.ignore_duplicates = ignore:GetCheck()
            if config.ignore_duplicates == 0 then -- DON'T ignore duplicates
                if assigned[key] then -- previously assigned
                    is_duplicate = true
                    if not errors[key] then errors[key] = { assigned[key] } end
                    table.insert(errors[key], v[1])
                else
                    assigned[key] = v[1] -- flag key assigned
                end
            end
        end
        if is_duplicate then -- list reassignment duplications
            local msg = ""
            for i, v in pairs(errors) do
                if msg ~= "" then msg = msg .. "\n\n" end
                msg = msg .. "Key \"" .. i .. "\" is assigned to: "
                for j, w in ipairs(v) do
                    if j > 1 then msg = msg .. " and " end
                    msg = msg .. "\"" .. w .. "\""
                end
            end
            dialog:CreateChildUI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(parent) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

local function user_chooses_shape()
    local x_offset = 140
    local y_step = 18
    local box_high = #dialog_options * 17 + 5
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(finaleplugin.ScriptGroupName)
    dialog:CreateStatic(0, 0):SetText("Select note shape:"):SetWidth(150)
    local shape_list = dialog:CreateListBox(0, y_step):SetWidth(x_offset - 10):SetHeight(box_high)
        local function fill_shape_list()
            local join = finenv.UI():IsOnMac() and "\t" or ": "
            shape_list:Clear()
            for i, v in ipairs(dialog_options) do
                shape_list:AddString(config[v[1]] .. join .. v[1])
                if config.shape == v[1]:lower() or config.shape == v[3] then
                    shape_list:SetSelectedItem(i - 1)
                end
            end
        end
    fill_shape_list()
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. finaleplugin.ScriptGroupName, 420, 310)
            refocus_document = true
        end
        local function reassign_keys()
            local ok, is_duplicate = true, true
            while ok and is_duplicate do -- wait for valid choice in reassign_keystrokes()
                ok, is_duplicate = reassign_keystrokes(dialog, shape_list:GetSelectedItem() + 1)
                refocus_document = true
            end
            if ok then
                fill_shape_list()
            else -- reinstall hotkeys from user config
                configuration.get_user_settings(script_name, config)
            end
        end

    local y = y_step * 3
    local max = layer.max_layers()
    dialog:CreateStatic(x_offset, y):SetText("Layer number (1-" .. max .. "):"):SetWidth(110)
    y = y + y_step-- + 2
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- vertical offset for Mac edit boxes
    local save_layer = config.layer_num
    local layer_num = dialog:CreateEdit(x_offset + 38, y - mac_offset):SetWidth(20)
        :SetText(save_layer)
        :AddHandleCommand(function(self)
            local val = self:GetText():lower()
            if val:find("[^0-" .. max .. "]") then
                if val:find("r") then reassign_keys()
                elseif val:find("[?q]") then show_info()
                end
            elseif val ~= "" then
                save_layer = val:sub(-1) -- layer number has one char
            end
            self:SetText(save_layer):SetKeyboardFocus()
        end)
    y = y + y_step-- + 2
    dialog:CreateStatic(x_offset + 12, y):SetText("(0 = all layers)"):SetWidth(105)
    y = y + y_step-- + 2
    dialog:CreateButton(x_offset + 38, y, "q"):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    y = y_step * 3 + y
    dialog:CreateButton(x_offset, y)
        :SetText("Change Hotkeys"):SetWidth(100)
        :AddHandleCommand(function() reassign_keys() end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function()
        local q = dialog:GetControl("q")
        q:SetFont(q:CreateFontInfo():SetBold(true))
        shape_list:SetKeyboardFocus()
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        local item = shape_list:GetSelectedItem() + 1
        config.shape = dialog_options[item][3] or dialog_options[item][1]:lower()
        config.layer_num = layer_num:GetInteger()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK)
end

local function change_noteheads()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    if no_dialog or mod_key or user_chooses_shape() then
        if config.shape == "custom" then -- "Custom Glyph" is chosen
            if not user_chooses_glyph() then return end -- user cancelled
            config.shape = tonumber(config.glyph) -- glyph -> shape NUMBER
        end
        for entry in eachentrysaved(finenv.Region(), config.layer_num) do
            if entry:IsNote() then
                for note in each(entry) do
                    notehead.change_shape(note, config.shape)
                end
            end
        end
    end
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

change_noteheads()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.19"
    finaleplugin.Date = "2023/06/12"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        Change notehead shapes on a specific layer of the current selection to one of these shapes:  
        Circled / Default / Diamond / Guitar Diamond / Hidden / Number  
        Round / Slash / Square / Strikethrough / Triangle / Wedge / X

        This script produces an ordered list 
        of notehead types, each line beginning with a configurable "key" code. 
        Call the script, type the key code and hit [Enter] or [Return].  

        In SMuFL fonts like Finale Maestro, shapes will change according to duration values. 
        Most duration-dependent shapes are not available in Finale's old (non-SMuFL) Maestro font. 
        "Diamond (Guitar)" is like "Diamond" except quarter notes and shorter use filled diamonds. 
        "Number" lets you specify any shape character as a number including SMuFL numbers like "0xe0e1".

    ]]
    return "Noteheads Change by Layer...", "Noteheads Change by Layer", "Change notehead shapes on a specific layer of the current selection"
end

local notehead = require("library.notehead")
local mixin = require("library.mixin")
local configuration = require("library.configuration")
local library = require("library.general_library")
local layer = require("library.layer")
local diamond = { smufl = 0xE0E1, non_smufl = 79 }

local dialog_options = { -- ordered list for menu (list_box) selection
    "Circled", "Default", "Diamond", "Diamond_Guitar", "Hidden",
    "Number", "Round", "Slash", "Square", "Strikethrough", "Triangle", "Wedge", "X"
}
local config = {
    Circled = "C", -- map dialog options onto key codes
    Default = "A",
    Diamond = "D",
    Diamond_Guitar = "G",
    Hidden = "H",
    Number = "N",
    Round = "R",
    Slash = "S",
    Square = "Q",
    Strikethrough = "E",
    Triangle = "T",
    Wedge = "W",
    X = "X",
    layer = 0,
    ignore_duplicates = 0,
    shape = "default",
    glyph = "0xe0e1",
    window_pos_x = false,
    window_pos_y = false
}
local script_name = "noteheads_change_by_layer"

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

function user_chooses_glyph()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    local x = 230
    local y_diff = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box

    local base_glyph = tonumber(config.glyph) or diamond.smufl
    local msg = ""
    if library.is_font_smufl_font() then
        if base_glyph < 0xE000 then base_glyph = diamond.smufl end -- < 57344
        config.glyph = string.format("0x%X", base_glyph)
        msg = "The Default Music Font is SMuFL compliant so glyph numbers "
        .. "should be higher than 57344 (\"0xE000\")"
    else
        if base_glyph >= 0x1000 then base_glyph = diamond.non_smufl end
        config.glyph = tostring(base_glyph)
        msg = "The Default Music Font is not SMuFL compliant so glyph numbers "
        .. "should be lower than 4096 (\"0x1000\")"
    end

    dialog:CreateStatic(0, y_diff):SetWidth(x + 70)
        :SetText("Enter required character (glyph) number:")
    dialog:CreateStatic(0, y_diff + 25):SetWidth(x + 100):SetHeight(60)
        :SetText("... as plain integer, or hex value like \"0xE0E1\".\n\n" .. msg)
    local glyph = dialog:CreateEdit(x, 0):SetText(config.glyph)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function() glyph:SetKeyboardFocus() end)
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.glyph = glyph:GetText()
        dialog_save_position(self)
    end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function reassign_keystrokes()
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Noteheads: Reassign Keys")
    local is_duplicate, errors = false, {}
    local y = 0
    for _, v in ipairs(dialog_options) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v):SetText(config[v]):SetWidth(20)
        dialog:CreateStatic(25, y):SetText(v):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore_duplicates or 0)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for i, v in ipairs(dialog_options) do
            local key = self:GetControl(v):GetText() or "?"
            key = string.upper(string.sub(key, 1, 1)) -- 1st letter, upper case
            config[v] = key -- save for another possible run-through
            config.ignore_duplicates = ignore:GetCheck()
            if config.ignore_duplicates == 0 then -- DON'T ignore duplicates
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
                    msg = msg .. "\"" .. dialog_options[w] .. "\""
                end
                msg = msg .. "\n\n"
            end
            finenv.UI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

function user_chooses_shape()
    local x_offset = 185
    local y_step = 17
    local join = finenv.UI():IsOnMac() and "\t" or ": "
    local box_high = (#dialog_options * y_step) + 5
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- + vertical offset for Mac edit boxes

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Select note shape:"):SetWidth(150)
    local shape_list = dialog:CreateListBox(0, y_step):SetWidth(x_offset - 20):SetHeight(box_high)
        local function fill_shape_list()
            shape_list:Clear()
            for i, v in ipairs(dialog_options) do
                local item = (i == 4) and "Guitar Diamond" or v
                shape_list:AddString(config[v] .. join .. item)
                if v:lower() == config.shape then
                    shape_list:SetSelectedItem(i - 1)
                end
            end
        end
    fill_shape_list()

    local max = layer.max_layers()
    dialog:CreateStatic(x_offset, y_step * 3):SetText("Layer number (1-" .. max .. "):"):SetWidth(110)
    dialog:CreateEdit(x_offset + 35, (y_step * 4) - mac_offset, "layer"):SetWidth(30):SetInteger(config.layer or 0)
    dialog:CreateStatic(x_offset + 15, y_step * 5):SetText("(0 = all layers)"):SetWidth(105)

    local reassign = dialog:CreateButton(x_offset, y_step * 9)
        :SetText("Reassign Keys"):SetWidth(100)
    reassign:AddHandleCommand(function()
        local ok, is_duplicate = true, true
        while ok and is_duplicate do -- wait for valid choices in reassign_keystrokes()
            ok, is_duplicate = reassign_keystrokes()
        end
        if ok then
            configuration.save_user_settings(script_name, config)
            fill_shape_list()
        end
    end)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function() shape_list:SetKeyboardFocus() end)
    dialog:RegisterHandleOkButtonPressed(function(self)
        -- convert shape codes back to lower case
        config.shape = string.lower( dialog_options[shape_list:GetSelectedItem() + 1] )
        local n = self:GetControl("layer"):GetInteger()
        if n < 0 or n > max then
            n = 0
        end
        config.layer = n
        dialog_save_position(self)
    end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function change_noteheads()
    configuration.get_user_settings(script_name, config, true)
    if not user_chooses_shape() then return end -- user cancelled

    -- else chosen shape is in config.shape
    if config.shape == "number" then
        if not user_chooses_glyph() then return end -- user cancelled
        config.shape = tonumber(config.glyph) -- glyph -> shape NUMBER
    end

    for entry in eachentrysaved(finenv.Region(), config.layer) do
        if entry:IsNote() then
            for note in each(entry) do
                notehead.change_shape(note, config.shape)
            end
        end
    end
    finenv.UI():ActivateDocumentWindow()
end

change_noteheads()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.16"
    -- COMMENT: streamlined window positioning / capitalized shape listbox / code optimization
    finaleplugin.Date = "2023/02/12"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        Change notehead shapes on a specific layer of the current selection to one of these shapes:  
        Circled / Default / Diamond / Guitar Diamond / Hidden / Number  
        Round / Slash / Square / Strikethrough / Triangle / Wedge / X

        In SMuFL fonts like Finale Maestro, shapes will correspond to appropriate duration values. 
        Most duration-dependent shapes are not available in Finale's old (non-SMuFL) Maestro font. 
        "Diamond (Guitar)" is like "Diamond" except quarter notes and shorter use filled diamonds. 
        "Number" lets you specify any shape character numerically including SMuFL numbers like "0xe0e1".

        This script offers the same functionality as "noteheads_change.lua" but offers 
        layer filtering with one menu item and a single confirmation dialog. 
    ]]
    return "Noteheads Change by Layer...", "Noteheads Change by Layer", "Change notehead shapes on a specific layer of the current selection"
end

local notehead = require("library.notehead")
local mixin = require("library.mixin")
local configuration = require("library.configuration")
local layer = require("library.layer")

local config = {
    layer = 0,
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

    dialog:CreateStatic(0, y_diff):SetWidth(x + 70)
        :SetText("Enter required character (glyph) number:")
    dialog:CreateStatic(0, y_diff + 25):SetWidth(x + 100)
        :SetText("(as plain integer, or hex value like 0xe0e1 or 0xE0E1)")

    local glyph = tonumber(config.glyph)
    if glyph >= 0xe000 then -- SMuFL spec
        config.glyph = string.format("0x%x", glyph)
    else
        config.glyph = tostring(glyph)
    end
    local answer = dialog:CreateEdit(x, 0):SetText(config.glyph)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.glyph = answer:GetText()
        dialog_save_position(self)
    end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function user_chooses_shape()
    local shapes = { "Circled", "Default", "Diamond", "Diamond_Guitar", "Hidden",
        "Number", "Round", "Slash", "Square", "Strikethrough", "Triangle", "Wedge", "X"
    } -- alphabetized and capitalized for User benefit

    local x_offset = 190
    local y_step = 20
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- + vertical offset for Mac edit boxes

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Select note shape:"):SetWidth(150)
    local shape_list = dialog:CreateListBox(0, y_step):SetWidth(x_offset - 20):SetHeight(y_step * 11)
    for i, v in ipairs(shapes) do
        shape_list:AddString((i == 4) and "Guitar Diamond" or v)
        if v:lower() == config.shape then -- shape codes are lower case
            shape_list:SetSelectedItem(i - 1)
        end
    end

    local max = layer.max_layers()
    dialog:CreateStatic(x_offset, y_step * 4):SetText("Layer number (0-" .. max .. "):"):SetWidth(150)
    dialog:CreateEdit(x_offset, (y_step * 5) - mac_offset, "layer"):SetWidth(50):SetInteger(config.layer or 0)
    dialog:CreateStatic(x_offset, y_step * 6):SetText("(\"0\" = all layers)"):SetWidth(150)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)

    dialog:RegisterHandleOkButtonPressed(function(self)
        -- convert shape codes back to lower case
        config.shape = string.lower( shapes[shape_list:GetSelectedItem() + 1] )
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
end

change_noteheads()

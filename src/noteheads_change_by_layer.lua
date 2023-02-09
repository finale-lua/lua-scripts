function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.11"
    finaleplugin.Date = "2023/02/09"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        Change notehead shapes on a specific layer of the current selection to one of these shapes:  
        X / Diamond / Diamond (Guitar) / Square Triangle / Slash / Wedge  
        Strikethrough / Circled / Round / Hidden / Number / Default  

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

function user_chooses_glyph()
    local dlg = mixin.FCMCustomLuaWindow():SetTitle(plugindef())
    local x, y = 200, 10
    local y_diff = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box

    dlg:CreateStatic(0, y):SetWidth(x + 100)
        :SetText("Enter required character (glyph) number:")
    dlg:CreateStatic(0, y + 20):SetWidth(x + 100)
        :SetText("(as plain integer, or hex value like \"0xe0e1\")")

    local glyph = tonumber(config.glyph)
    if glyph >= 0xe000 then -- SMuFL spec
        config.glyph = string.format("0x%x", glyph)
    else
        config.glyph = tostring(glyph)
    end
    local answer = dlg:CreateEdit(x + 30, y - y_diff):SetText(config.glyph)
    dlg:CreateOkButton()
    dlg:CreateCancelButton()
    if config.window_pos_x and config.window_pos_y then
        dlg:StorePosition()
        dlg:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dlg:RestorePosition()
    end

    local ok = dlg:ExecuteModal(nil)
    config.glyph = answer:GetText()
    return (ok == finale.EXECMODAL_OK)
end

function user_chooses_shape()
    local shapes = { "circled", "default", "diamond", "diamond_guitar", "hidden",
        "number", "round", "slash", "square", "strikethrough", "triangle", "wedge", "x"
    } -- (alphabetical order)
    local x_offset = 190
    local y_step = 20
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- + vertical offset for Mac edit boxes

    local dialog = mixin.FCMCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Select note shape:"):SetWidth(150)
    local shape_list = dialog:CreateListBox(0, y_step):SetWidth(x_offset - 20):SetHeight(y_step * 11)
    for i, v in ipairs(shapes) do
        shape_list:AddString(v)
        if v == config.shape then
            shape_list:SetSelectedItem(i - 1)
        end
    end

    dialog:CreateStatic(x_offset, y_step * 4):SetText("Layer number (0-4):"):SetWidth(150)
    dialog:CreateEdit(x_offset, (y_step * 5) - mac_offset, "layer"):SetWidth(50):SetInteger(config.layer or 0)
    dialog:CreateStatic(x_offset, y_step * 6):SetText("(\"0\" = all layers)"):SetWidth(150)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()

    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end

    dialog:RegisterHandleOkButtonPressed(function(self)
        config.shape = shapes[shape_list:GetSelectedItem() + 1]
        config.layer = self:GetControl("layer"):GetInteger()
        if config.layer < 0 or config.layer > layer.max_layers() then
            config.layer = 0
        end
        dialog:StorePosition()
        config.window_pos_x = self.StoredX
        config.window_pos_y = self.StoredY
        configuration.save_user_settings("noteheads_change_by_layer", config)
    end)

    local ok = dialog:ExecuteModal(nil)
    return (ok == finale.EXECMODAL_OK)
end

function change_noteheads()
    configuration.get_user_settings("noteheads_change_by_layer", config, true)
    if not user_chooses_shape() then return end -- user cancelled

    -- else answer is already saved in config.shape
    if config.shape == "number" then
        local ok = user_chooses_glyph() -- get user's numeric choice in config.glyph (string)
        if not ok then return end -- user cancelled
        configuration.save_user_settings("noteheads_change_by_layer", config)
        -- now use the glyph number below as a shape but don't save it back to config file
        config.shape = tonumber(config.glyph)
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

function plugindef()
    finaleplugin.RequireDocument = true -- manipulating font information requires a document
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.3"
    finaleplugin.Date = "June 22, 2025"
    finaleplugin.MinJWLuaVersion = 0.75
    finaleplugin.Notes = [[
        A utility for mapping legacy music font glyphs to SMuFL glyphs. It emits a json
        file in the same format as those provided in the Finale installation for MakeMusic's
        legacy fonts.
    ]]
    return "Map Legacy Fonts to SMuFL...", "Map Legacy Fonts to SMuFL", "Map legacy font glyphs to SMuFL glyphs"
end

-- luacheck: ignore 11./global_dialog

local mixin = require("library.mixin")
local smufl_glyphs =require("library.smufl_glyphs")

context = {
    current_font = finale.FCFontInfo("Maestro", 24),
    current_mapping = {},
    popup_keys = {}
}

local function format_codepoint(cp)
    local glyph_name = smufl_glyphs.get_glyph_info(cp)
    return "'" .. glyph_name .. "' [" .. string.format("U+%04X", cp) .. "]"
end

local function enable_disable(dialog)
    local addable = #(dialog:GetControl("legacy_box"):GetText()) > 0 and
        #(dialog:GetControl("smufl_box"):GetText()) > 0
    dialog:GetControl("add_mapping"):SetEnable(addable)
end

local function change_font(dialog, font_info)
    if font_info.IsSMuFLFont then
        finenv.UI():AlertError("Unable to map SMuFL font " .. font_info:CreateDescription(), "SMuFL Font")
        return
    end
    context.current_font = font_info
    context.current_mapping = {}
    context.popup_keys = {}
    print(dialog:ClassName())
    local control = dialog:GetControl("legacy_box")
    control:SetText("")
    control:SetFont(context.current_font)
    dialog:GetControl("show_font"):SetText(font_info:CreateDescription())
    dialog:GetControl("popup"):Clear()
    enable_disable(dialog)
end

local function get_codepoint(control)
    local fcstr = finale.FCString()
    control:GetText(fcstr)
    if control:CreateFontInfo():IsMacSymbolFont() then
        fcstr:EncodeToMacRoman()
    end
    return fcstr.Length > 0 and fcstr:GetCodePointAt(0) or 0
end

local function set_codepoint(control, codepoint)
    local fcstr = finale.FCString(utf8.char(codepoint))
    if control:CreateFontInfo():IsMacSymbolFont() then
        fcstr:EncodeFromMacRoman()
    end
    control:SetText(fcstr)
end

local function on_popup(popup)
    local legacy_codepoint = context.popup_keys[popup:GetSelectedItem() + 1] or 0
    local smufl_codepoint = legacy_codepoint > 0 and context.current_mapping[legacy_codepoint] or 0
    local dialog = popup:GetParent()
    set_codepoint(dialog:GetControl("legacy_box"), legacy_codepoint)
    set_codepoint(dialog:GetControl("smufl_box"), smufl_codepoint)
end

local function update_popup(popup, current_codepoint)
    context.popup_keys = {}
    for k in pairs(context.current_mapping) do
        table.insert(context.popup_keys, k)
    end
    table.sort(context.popup_keys)
    popup:Clear()
    local current_index
    for k, v in ipairs(context.popup_keys) do
        popup:AddString(tostring(v) .. " maps to " .. format_codepoint(context.current_mapping[v]))
        if v == current_codepoint then
            current_index = k - 1
        end
    end
    if current_index then
        popup:SetSelectedItem(current_index)
        on_popup(popup)
    end
end

local function on_select_font(control)
    local font_info = finale.FCFontInfo(context.current_font.Name, context.current_font.Size)
    local font_dialog = finale.FCFontDialog(finenv.UI(), font_info)
    font_dialog.UseSizes = true
    font_dialog.UseStyles = false
    if font_dialog:Execute() then
        font_info = font_dialog.FontInfo
        if font_info.FontID ~= context.current_font.FontID then
            change_font(control:GetParent(), font_dialog.FontInfo)
        end
    end
end

local function on_select_file(control)
end

local function on_edit_box(control)
    local fcstr = finale.FCString()
    control:GetText(fcstr)
    if fcstr.Length > 0 then
        local cp, x = fcstr:GetCodePointAt(fcstr.Length - 1)
        if x > 0 then
            fcstr.LuaString = utf8.char(cp)
            control:SetText(fcstr)
        end
    end
    enable_disable(control:GetParent())
end

local function on_symbol_select(box)
    local dialog = box:GetParent()
    local last_point = get_codepoint(box)
    local new_point = dialog:CreateChildUI():DisplaySymbolDialog(box:CreateFontInfo(), last_point)
    if new_point ~= 0 then
        set_codepoint(box, new_point)
    end
    enable_disable(dialog)
end

local function on_add_mapping(control)
    local dialog = control:GetParent()
    local popup = dialog:GetControl("mappings")
    local legacy_point = get_codepoint(dialog:GetControl("legacy_box"))
    if legacy_point == 0 then return end
    local smufl_point = get_codepoint(dialog:GetControl("smufl_box"))
    if (smufl_point == 0) then return end
    if context.current_mapping[legacy_point] then
        if finale.YESRETURN ~= finenv:UI():AlertYesNo("Symbol " .. legacy_point .. " is already mapped to " .. format_codepoint(smufl_point) .. ". Continue?", "Already Mapped") then
            return
        end
    end
    context.current_mapping[legacy_point] = smufl_point
    update_popup(popup, legacy_point)
end

function font_map_legacy()
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle("Map Legacy Fonts to SMuFL")
    local editor_width = 60
    local editor_height = 80
    local smufl_y_diff = 20 -- Extra height to show entire SMuFL glyph
    --local edit_offset = 3
    local button_height = 20
    local y_increment = 10
    local current_y = 0
    -- font selection
    dialog:CreateButton(0, current_y, "font_sel")
        :SetText("Font...")
        :DoAutoResizeWidth(0)
        :AddHandleCommand(on_select_font)
    dialog:CreateButton(0, current_y, "file_sel")
        :SetText("File...")
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dialog:GetControl("font_sel"), 10)
        :AddHandleCommand(on_select_file)
    current_y = current_y + 1.5 * button_height
    -- font name
    dialog:CreateStatic(0, current_y, "show_font")
        :DoAutoResizeWidth()
        :SetText(context.current_font:CreateDescription())
    current_y = current_y + button_height
    -- boxes
    dialog:CreateEdit(0, current_y, "legacy_box")
        :SetHeight(editor_height)
        :SetWidth(editor_width)
        :SetFont(context.current_font)
        :AddHandleCommand(on_edit_box)
    dialog:CreateButton(0, current_y + editor_height + y_increment, "legacy_sel")
        :SetText("Symbol...")
        :SetWidth(editor_width)
        :AddHandleCommand(function(control)
            on_symbol_select(control:GetParent():GetControl("legacy_box"))
        end)
    dialog:CreateButton(0, current_y + editor_height / 2 - button_height / 2, "add_mapping")
        :SetText("Add Mapping")
        :SetEnable(false)
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dialog:GetControl("legacy_box"), editor_width / 2)
        :AddHandleCommand(on_add_mapping)
    dialog:CreateEdit(0, current_y - smufl_y_diff, "smufl_box")
        :SetHeight(editor_height + smufl_y_diff)
        :SetWidth(editor_width)
        :SetFont(finale.FCFontInfo("Finale Maestro", 24))
        :AssureNoHorizontalOverlap(dialog:GetControl("add_mapping"), editor_width/2)
        :AddHandleCommand(on_edit_box)
    dialog:CreateButton(0, current_y + editor_height + y_increment, "smufl_sel")
        :SetText("Symbol...")
        :SetWidth(editor_width)
        :HorizontallyAlignLeftWith(dialog:GetControl("smufl_box"))
        :AddHandleCommand(function(control)
            on_symbol_select(control:GetParent():GetControl("smufl_box"))
        end)
    current_y = current_y + editor_height + 2 * y_increment + button_height
    dialog:CreatePopup(0, current_y, "mappings")
        :StretchToAlignWithRight()
        :AddHandleCommand(on_popup)
    -- close button
    dialog:CreateCancelButton("cancel"):SetText("Close")
    -- registrations
    dialog:ExecuteModal() -- modal dialog prevents document changes in modeless callbacks
end

font_map_legacy()

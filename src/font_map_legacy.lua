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

local utils = require("library.utils")
local client = require("library.client")
local library = require("library.general_library")
local mixin = require("library.mixin")
local smufl_glyphs = require("library.smufl_glyphs")
local cjson = require("cjson")

context = {
    smufl_list = library.get_smufl_font_list(),
    current_font = finale.FCFontInfo("Maestro", 24),
    current_mapping = {},
    popup_keys = {},
    current_directory = finenv.RunningLuaFolderPath()
}

local function format_mapping(mapping)
    local codepoint_desc = "[" .. utils.format_codepoint(mapping.codepoint) .. "]"
    if mapping.glyph then
        codepoint_desc = "'" .. mapping.glyph .. "' " .. codepoint_desc
    end
    if mapping.smuflFontName then
        codepoint_desc = codepoint_desc .. "(" .. mapping.smuflFontName ..")"
    end
    return codepoint_desc
end

local function enable_disable(dialog)
    local delable = #(dialog:GetControl("legacy_box"):GetText()) > 0
    local addable = delable and #(dialog:GetControl("smufl_box"):GetText()) > 0
    if delable then
        local popup = dialog:GetControl("mappings")
        delable = popup:GetCount() > 0 and context.popup_keys[popup:GetSelectedItem() + 1] ~= nil
    end
    dialog:GetControl("add_mapping"):SetEnable(addable)
    dialog:GetControl("delete_mapping"):SetEnable(delable)
end

local function change_font(dialog, font_info)
    if font_info.IsSMuFLFont then
        dialog:CreateChildUI():AlertError("Unable to map SMuFL font " .. font_info:CreateDescription(), "SMuFL Font")
        return
    end
    context.current_font = font_info
    context.current_mapping = {}
    context.popup_keys = {}
    local control = dialog:GetControl("legacy_box")
    control:SetText("")
    control:SetFont(context.current_font)
    dialog:GetControl("show_font"):SetText(font_info:CreateDescription())
    dialog:GetControl("mappings"):Clear()
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

local function on_smufl_popup(popup)
    local dialog = popup:GetParent()
    local smufl_box = dialog:GetControl("smufl_box")
    local fcstr = finale.FCString()
    popup:GetItemText(popup:GetSelectedItem(), fcstr)
    smufl_box:SetFont(finale.FCFontInfo(fcstr.LuaString, 24))
end

local function on_popup(popup)
    local legacy_codepoint = context.popup_keys[popup:GetSelectedItem() + 1] or 0
    local current_mapping = legacy_codepoint > 0 and context.current_mapping[legacy_codepoint]
    local smufl_codepoint = current_mapping and current_mapping.codepoint or 0
    local dialog = popup:GetParent()
    if current_mapping and current_mapping.smuflFontName then
        local smufl_list = dialog:GetControl("smufl_list")
        for index = 0, smufl_list:GetCount() - 1 do
            local str = finale.FCString()
            smufl_list:GetItemText(index, str)
            if str.LuaString == current_mapping.smuflFontName then
                smufl_list:SetSelectedItem(index)
                on_smufl_popup(smufl_list)
            end
        end
    end
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
        popup:AddString(tostring(v) .. " maps to " .. format_mapping(context.current_mapping[v]))
        if v == current_codepoint then
            current_index = k - 1
        end
    end
    if not current_index and popup:GetCount() > 0 then
        current_index = 0
    end
    if current_index then
        popup:SetSelectedItem(current_index)
        on_popup(popup)
    end
    enable_disable(popup:GetParent())
end

local function on_select_font(control)
    local font_info = finale.FCFontInfo(context.current_font.Name, context.current_font.Size)
    local font_dialog = finale.FCFontDialog(control:GetParent():CreateChildUI(), font_info)
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
    local dialog = control:GetParent()
    local open_dialog = mixin.FCMFileOpenDialog(dialog:CreateChildUI())
        :SetWindowTitle(finale.FCString("Select existing JSON file"))
        :SetInitFolder(finale.FCString(context.current_directory))
        :AddFilter(finale.FCString("*.json"), finale.FCString("Legacy Font Mapping"))
    if not open_dialog:Execute() then
        return
    end
    local selected_file = finale.FCString()
    open_dialog:GetFileName(selected_file)
    local path, name = utils.split_file_path(selected_file.LuaString)
    if not finenv.UI():IsFontAvailable(finale.FCString(name)) then
        dialog:CreateChildUI():AlertError("Font " .. name .. " is not available on the system.", "Missing Font")
        return
    end
    local font_info = finale.FCFontInfo(name, context.current_font.Size)
    if font_info.IsSMuFLFont then
        dialog:CreateChildUI():AlertError("Font " .. name .. " is a SMuFL font.", "SMuFL Font")
        return
    end
    local file = io.open(client.encode_with_client_codepage(selected_file.LuaString))
    if file then
        local json_contents = file:read("*a")
        file:close()
        local json = cjson.decode(json_contents)
        context.current_directory = path
        change_font(dialog, font_info)
        context.current_mapping = {}
        for glyph, v in pairs(json) do
            local t = {}
            t.glyph = glyph
            t.codepoint = utils.parse_codepoint(v.codepoint)
            t.nameIsMakeMusic = v.nameIsMakeMusic
            t.smuflFontName = v.smuflFontName
            if t.codepoint == 0xFFFD then
                local smufl_box = dialog:GetControl("smufl_box")
                local _, info = smufl_glyphs.get_glyph_info(glyph, smufl_box:CreateFontInfo())
                if info then
                    t.codepoint = info.codepoint
                end
            end
            context.current_mapping[tonumber(v.legacyCodepoint)] = t
        end
        update_popup(dialog:GetControl("mappings"))
    end
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
    if smufl_point == 0 then return end
    local current_mapping = context.current_mapping[legacy_point]
    if current_mapping then
        if finale.YESRETURN ~= dialog:CreateChildUI():AlertYesNo("Symbol " .. legacy_point .. " is already mapped to " .. format_mapping(current_mapping) .. ". Continue?", "Already Mapped") then
            return
        end
    end
    local font = dialog:GetControl("smufl_box"):CreateFontInfo()
    current_mapping = {codepoint = smufl_point}
    local glyph, info = smufl_glyphs.get_glyph_info(smufl_point, font)
    if info then
        current_mapping.glyph = glyph
    else
        current_mapping.glyph = utils.format_codepoint(smufl_point)
    end
    if font and smufl_point >= 0xF400 and smufl_point <= 0xF8FF then
        current_mapping.smuflFontName = font.Name
    end
    context.current_mapping[legacy_point] = current_mapping
    update_popup(popup, legacy_point)
end

local function on_delete_mapping(control)
    local dialog = control:GetParent()
    local popup = dialog:GetControl("mappings")
    if popup:GetCount() > 0 then
        local legacy_codepoint = context.popup_keys[popup:GetSelectedItem() + 1]
        if legacy_codepoint then
            context.current_mapping[legacy_codepoint] = nil
            update_popup(popup)
        end
    end
end

-- use hand-crafted json encoder to control order of elements
local function emit_json(mapping, reverse_lookup)
    local function quote(str)
        return '"' .. tostring(str):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    end

    local function emit_entry(entry, legacy_codepoint)
        local parts = {}
        if type(entry.nameIsMakeMusic) == "boolean" then
            table.insert(parts, '\t\t"nameIsMakeMusic": ' .. tostring(entry.nameIsMakeMusic))
        end
        if entry.codepoint then
            table.insert(parts, '\t\t"codepoint": ' .. quote(utils.format_codepoint(entry.codepoint)))
        end
        table.insert(parts, '\t\t"legacyCodepoint": ' .. quote(tostring(legacy_codepoint)))
        if entry.description then
            table.insert(parts, '\t\t"description": ' .. quote(entry.description))
        else
            table.insert(parts, '\t\t"description": ' .. quote(""))
        end
        if entry.smuflFontName then
            table.insert(parts, '\t\t"smuflFontName": ' .. quote(entry.smuflFontName))
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n\t}"
    end

    local lines = { "{" }
    local first = true
    for key, entry in pairsbykeys(mapping) do
        if reverse_lookup[entry.glyph] then
            if not first then
                lines[#lines] = lines[#lines] .. ","  -- ← append comma to previous line
            end
            table.insert(lines, "\t" .. quote(entry.glyph) .. ": " .. emit_entry(entry, key))
            first = false
        end
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

local function on_save(control)
    local dialog = control:GetParent()
    if type(context.current_mapping) ~= "table" or not next(context.current_mapping) then
        dialog:CreateChildUI():AlertInfo("Nothing has been mapped.", "No Mapping")
        return
    end
    local save_dialog = finale.FCFileSaveAsDialog(dialog:CreateChildUI())
    save_dialog:SetWindowTitle(finale.FCString("Save mapping as"))
    save_dialog:AddFilter(finale.FCString("*.json"), finale.FCString("Legacy Font Mapping"))
    save_dialog:SetInitFolder(finale.FCString(context.current_directory))
    save_dialog:SetFileName(finale.FCString(context.current_font.Name .. ".json"))
    save_dialog:AssureFileExtension("json")
    if not save_dialog:Execute() then
        return
    end
    local path_fstr = finale.FCString()
    save_dialog:GetFileName(path_fstr)
    local reverse_lookup = {}
    for legacy_codepoint, info in pairs(context.current_mapping) do
        if type(info.glyph) ~= "string" then
            dialog:CreateChildUI():AlertError("No glyph name found for legacy codepoint " .. legacy_codepoint .. ".",
            "No Glyph Name")
            return
        elseif reverse_lookup[info.glyph] then
            if finale.YESRETURN ~= dialog:CreateChildUI():AlertYesNo("Glyph name " .. info.glyph .. " is mapped more than once. Continue?", "Duplicate Glyph Name") then
                return
            end
        end
        reverse_lookup[info.glyph] = true
    end
    local result = emit_json(context.current_mapping, reverse_lookup)
    local file = io.open(client.encode_with_client_codepage(path_fstr.LuaString), "w")
    if not file then
        dialog:CreateChildUI():AlertError("Unable to write to file " .. path_fstr.LuaString .. ".", "File Error")
        return
    end
    file:write(result)
    file:close()
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
    local smufl_popup = dialog:CreatePopup(0, current_y, "smufl_list")
        :AssureNoHorizontalOverlap(dialog:GetControl("file_sel"), 10)
        :StretchToAlignWithRight()
        :AddHandleCommand(on_smufl_popup)
    local start_index = 0
    for name, _ in pairsbykeys(context.smufl_list) do
        smufl_popup:AddString(name)
        if name == "Finale Maestro" then
            start_index = smufl_popup:GetCount() - 1
        end
    end
    if smufl_popup:GetCount() <= 0 then
        finenv.UI():AlertError("No SMuFL fonts found on system.", "SMuFL Required")
        return
    end
    smufl_popup:SetSelectedItem(start_index)
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
    dialog:CreateButton(0, current_y + editor_height / 2 - button_height, "add_mapping")
        :SetText("Add/Update Mapping")
        :SetWidth(140)
        :SetEnable(false)
        :AssureNoHorizontalOverlap(dialog:GetControl("legacy_box"), editor_width / 2)
        :AddHandleCommand(on_add_mapping)
    dialog:CreateButton(0, current_y + editor_height / 2 + y_increment, "delete_mapping")
        :SetText("Delete Mapping")
        :SetWidth(140)
        :SetEnable(false)
        :AssureNoHorizontalOverlap(dialog:GetControl("legacy_box"), editor_width / 2)
        :AddHandleCommand(on_delete_mapping)
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
    current_y = current_y + button_height + y_increment
    -- save and close buttons
    dialog:CreateButton(0, current_y, "save")
        :SetText("Save...")
        :DoAutoResizeWidth(0)
        :AddHandleCommand(on_save)
    dialog:CreateCloseButton(0, current_y, "close")
        :SetText("Close")
        :DoAutoResizeWidth(0)
        :HorizontallyAlignRightWithFurthest()
    -- registrations
    dialog:RegisterInitWindow(function(self)
        on_smufl_popup(self:GetControl("smufl_list"))
    end)
    -- execute
    dialog:ExecuteModal() -- modal dialog prevents document changes in modeless callbacks
end

font_map_legacy()

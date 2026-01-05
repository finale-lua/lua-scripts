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
    entries_by_glyph = {},
    popup_entries = {},
    current_directory = finenv.RunningLuaFolderPath()
}

local enable_disable
local get_popup_entry

local function reset_mapping_state()
    context.current_mapping = {}
    context.entries_by_glyph = {}
    context.popup_entries = {}
end

local function parse_legacy_codepoint_string(str)
    if type(str) == "number" then
        return str
    end
    if type(str) ~= "string" then
        return nil
    end
    str = utils.trim(str)
    if str:match("^0[xX]%x+$") then
        return tonumber(str, 16)
    end
    return tonumber(str)
end

local function legacy_codepoint_to_string(legacy_codepoint, original)
    if type(original) == "string" and #original > 0 then
        return original
    end
    return tostring(legacy_codepoint)
end

local function register_entry_glyph(entry)
    if not entry or type(entry.glyph) ~= "string" then
        return
    end
    local glyph_name = entry.glyph
    if entry._registered_glyph == glyph_name then
        return
    end
    if entry._registered_glyph then
        local old_list = context.entries_by_glyph[entry._registered_glyph]
        if old_list then
            for index, candidate in ipairs(old_list) do
                if candidate == entry then
                    table.remove(old_list, index)
                    break
                end
            end
            if #old_list == 0 then
                context.entries_by_glyph[entry._registered_glyph] = nil
            end
        end
    end
    context.entries_by_glyph[glyph_name] = context.entries_by_glyph[glyph_name] or {}
    local glyph_list = context.entries_by_glyph[glyph_name]
    local exists = false
    for _, candidate in ipairs(glyph_list) do
        if candidate == entry then
            exists = true
            break
        end
    end
    if not exists then
        table.insert(glyph_list, entry)
    end
    entry._registered_glyph = glyph_name
end

local function ensure_entry_registration(entry)
    if not entry or type(entry.glyph) ~= "string" then
        return
    end
    if not entry.legacyCodepoints or #entry.legacyCodepoints == 0 then
        return
    end
    entry.legacyStrings = entry.legacyStrings or {}
    register_entry_glyph(entry)
    for index, legacy_cp in ipairs(entry.legacyCodepoints) do
        entry.legacyStrings[index] = entry.legacyStrings[index] or legacy_codepoint_to_string(legacy_cp)
        context.current_mapping[legacy_cp] = context.current_mapping[legacy_cp] or {}
        local mapping_list = context.current_mapping[legacy_cp]
        local exists = false
        for _, candidate in ipairs(mapping_list) do
            if candidate == entry then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(mapping_list, entry)
        end
    end
end

local function unregister_entry_if_empty(entry)
    if not entry or not entry.legacyCodepoints or #entry.legacyCodepoints > 0 then
        return
    end
    if not entry._registered_glyph then
        return
    end
    local glyph_list = context.entries_by_glyph[entry._registered_glyph]
    if not glyph_list then
        return
    end
    for index, candidate in ipairs(glyph_list) do
        if candidate == entry then
            table.remove(glyph_list, index)
            break
        end
    end
    if #glyph_list == 0 then
        context.entries_by_glyph[entry._registered_glyph] = nil
    end
    entry._registered_glyph = nil
end

local function remove_legacy_codepoint_from_entry(entry, legacy_codepoint)
    if not entry or not entry.legacyCodepoints then
        return
    end
    for i, value in ipairs(entry.legacyCodepoints) do
        if value == legacy_codepoint then
            table.remove(entry.legacyCodepoints, i)
            if entry.legacyStrings then
                table.remove(entry.legacyStrings, i)
            end
            break
        end
    end
    local mapping_list = context.current_mapping[legacy_codepoint]
    if mapping_list then
        for i, candidate in ipairs(mapping_list) do
            if candidate == entry then
                table.remove(mapping_list, i)
                break
            end
        end
        if #mapping_list == 0 then
            context.current_mapping[legacy_codepoint] = nil
        end
    end
    unregister_entry_if_empty(entry)
end

local function set_entry_smufl_info(entry, smufl_point, font)
    if not entry then
        return
    end
    local glyph_name, info = smufl_glyphs.get_glyph_info(smufl_point, font)
    entry.codepoint = smufl_point
    if info then
        entry.glyph = glyph_name
    else
        entry.glyph = utils.format_codepoint(smufl_point)
    end
    if font and smufl_point >= 0xF400 and smufl_point <= 0xF8FF then
        entry.smuflFontName = font.Name
    else
        entry.smuflFontName = nil
    end
    register_entry_glyph(entry)
end

local function normalize_entry_legacy_arrays(entry)
    if not entry or not entry.legacyCodepoints then
        return
    end
    local zipped = {}
    for index, cp in ipairs(entry.legacyCodepoints) do
        if cp then
            local str
            if entry.legacyStrings and entry.legacyStrings[index] then
                str = entry.legacyStrings[index]
            else
                str = legacy_codepoint_to_string(cp)
            end
            table.insert(zipped, {codepoint = cp, value = str})
        end
    end
    table.sort(zipped, function(a, b)
        if a.codepoint == b.codepoint then
            return (a.value or "") < (b.value or "")
        end
        return (a.codepoint or 0) < (b.codepoint or 0)
    end)
    entry.legacyCodepoints = {}
    entry.legacyStrings = {}
    for index, item in ipairs(zipped) do
        entry.legacyCodepoints[index] = item.codepoint
        entry.legacyStrings[index] = item.value
    end
end

local function format_mapping(mapping)
    if not mapping then
        return ""
    end
    local codepoint_desc = "[" .. utils.format_codepoint(mapping.codepoint or 0) .. "]"
    if mapping.glyph then
        codepoint_desc = "'" .. mapping.glyph .. "' " .. codepoint_desc
    end
    if mapping.smuflFontName then
        codepoint_desc = codepoint_desc .. "(" .. mapping.smuflFontName ..")"
    end
    return codepoint_desc
end

local function change_font(dialog, font_info)
    if font_info.IsSMuFLFont then
        dialog:CreateChildUI():AlertError("Unable to map SMuFL font " .. font_info:CreateDescription(), "SMuFL Font")
        return
    end
    context.current_font = font_info
    reset_mapping_state()
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

get_popup_entry = function(popup)
    if not popup then
        return nil
    end
    local index = popup:GetSelectedItem()
    if index == nil or index < 0 then
        return nil
    end
    return context.popup_entries[index + 1]
end

enable_disable = function(dialog)
    local delable = #(dialog:GetControl("legacy_box"):GetText()) > 0
    local addable = delable and #(dialog:GetControl("smufl_box"):GetText()) > 0
    if delable then
        local popup = dialog:GetControl("mappings")
        delable = popup:GetCount() > 0 and get_popup_entry(popup) ~= nil
    end
    dialog:GetControl("add_mapping"):SetEnable(addable)
    dialog:GetControl("delete_mapping"):SetEnable(delable)
end

local function on_smufl_popup(popup)
    local dialog = popup:GetParent()
    local smufl_box = dialog:GetControl("smufl_box")
    local fcstr = finale.FCString()
    popup:GetItemText(popup:GetSelectedItem(), fcstr)
    smufl_box:SetFont(finale.FCFontInfo(fcstr.LuaString, 24))
end

local function on_popup(popup)
    local selection = get_popup_entry(popup)
    local legacy_codepoint = selection and selection.legacy_codepoint or 0
    local current_mapping = selection and selection.entry
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

local function update_popup(popup, target_codepoint, target_entry)
    context.popup_entries = {}
    for legacy_codepoint, entry_list in pairs(context.current_mapping) do
        if type(entry_list) == "table" then
            for legacy_index, entry in ipairs(entry_list) do
                table.insert(context.popup_entries, {
                    legacy_codepoint = legacy_codepoint,
                    entry = entry,
                    legacy_index = legacy_index
                })
            end
        end
    end
    table.sort(context.popup_entries, function(a, b)
        if a.legacy_codepoint == b.legacy_codepoint then
            local glyph_a = (a.entry and a.entry.glyph) or ""
            local glyph_b = (b.entry and b.entry.glyph) or ""
            if glyph_a == glyph_b then
                local codepoint_a = (a.entry and a.entry.codepoint) or 0
                local codepoint_b = (b.entry and b.entry.codepoint) or 0
                return codepoint_a < codepoint_b
            end
            return glyph_a < glyph_b
        end
        return a.legacy_codepoint < b.legacy_codepoint
    end)
    popup:Clear()
    local current_index
    for index, info in ipairs(context.popup_entries) do
        local label = tostring(info.legacy_codepoint) .. " maps to " .. format_mapping(info.entry)
        popup:AddString(label)
        if target_entry and info.entry == target_entry and info.legacy_codepoint == target_codepoint then
            current_index = index - 1
        elseif not current_index and target_codepoint and info.legacy_codepoint == target_codepoint then
            current_index = index - 1
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
        if type(json) ~= "table" then
            dialog:CreateChildUI():AlertError("Selected file is not a valid mapping.", "Invalid File")
            return
        end
        context.current_directory = path
        change_font(dialog, font_info)
        local smufl_box = dialog:GetControl("smufl_box")
        for glyph, value in pairs(json) do
            if type(glyph) == "string" and type(value) == "table" then
                local entries = value
                if not entries[1] and (entries.codepoint or entries.legacyCodepoint) then
                    entries = {entries}
                end
                for _, entry_data in ipairs(entries) do
                    if type(entry_data) == "table" then
                        local entry = {
                            glyph = glyph,
                            codepoint = utils.parse_codepoint(entry_data.codepoint or ""),
                            description = entry_data.description or "",
                            nameIsMakeMusic = entry_data.nameIsMakeMusic,
                            smuflFontName = entry_data.smuflFontName,
                            xOffset = entry_data.xOffset,
                            yOffset = entry_data.yOffset,
                            alternate = entry_data.alternate,
                            notes = entry_data.notes,
                            legacyCodepoints = {},
                            legacyStrings = {}
                        }
                        if entry.codepoint == 0xFFFD then
                            local _, info = smufl_glyphs.get_glyph_info(glyph, smufl_box:CreateFontInfo())
                            if info then
                                entry.codepoint = info.codepoint
                            end
                        end
                        if type(entry_data.legacyCodepoints) == "table" then
                            for _, legacy_str in ipairs(entry_data.legacyCodepoints) do
                                local cp_value = parse_legacy_codepoint_string(legacy_str)
                                if cp_value then
                                    table.insert(entry.legacyCodepoints, cp_value)
                                    table.insert(entry.legacyStrings, legacy_codepoint_to_string(cp_value, legacy_str))
                                end
                            end
                        elseif entry_data.legacyCodepoint ~= nil then
                            local legacy_str = tostring(entry_data.legacyCodepoint)
                            local cp_value = parse_legacy_codepoint_string(entry_data.legacyCodepoint)
                            if cp_value then
                                table.insert(entry.legacyCodepoints, cp_value)
                                table.insert(entry.legacyStrings, legacy_codepoint_to_string(cp_value, legacy_str))
                            end
                        end
                        normalize_entry_legacy_arrays(entry)
                        if entry.codepoint and #entry.legacyCodepoints > 0 then
                            ensure_entry_registration(entry)
                        end
                    end
                end
            end
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
    local font = dialog:GetControl("smufl_box"):CreateFontInfo()
    local selection = get_popup_entry(popup)
    local editing_entry = selection and selection.legacy_codepoint == legacy_point and selection.entry
    if editing_entry then
        set_entry_smufl_info(editing_entry, smufl_point, font)
        update_popup(popup, legacy_point, editing_entry)
        return
    end
    local existing_entries = context.current_mapping[legacy_point]
    if existing_entries and #existing_entries > 0 then
        local message
        if #existing_entries == 1 then
            message = "Symbol " .. legacy_point .. " is already mapped to " .. format_mapping(existing_entries[1]) .. ". Add another mapping?"
        else
            message = "Symbol " .. legacy_point .. " already has " .. #existing_entries .. " mappings. Add another mapping?"
        end
        if finale.YESRETURN ~= dialog:CreateChildUI():AlertYesNo(message, "Already Mapped") then
            return
        end
    end
    local glyph, info = smufl_glyphs.get_glyph_info(smufl_point, font)
    local new_entry = {
        codepoint = smufl_point,
        glyph = info and glyph or utils.format_codepoint(smufl_point),
        description = "",
        nameIsMakeMusic = nil,
        smuflFontName = nil,
        xOffset = nil,
        yOffset = nil,
        alternate = nil,
        notes = nil,
        legacyCodepoints = { legacy_point },
        legacyStrings = { legacy_codepoint_to_string(legacy_point) }
    }
    if font and smufl_point >= 0xF400 and smufl_point <= 0xF8FF then
        new_entry.smuflFontName = font.Name
    end
    ensure_entry_registration(new_entry)
    update_popup(popup, legacy_point, new_entry)
end

local function on_delete_mapping(control)
    local dialog = control:GetParent()
    local popup = dialog:GetControl("mappings")
    if popup:GetCount() > 0 then
        local selection = get_popup_entry(popup)
        if selection and selection.entry and selection.legacy_codepoint then
            remove_legacy_codepoint_from_entry(selection.entry, selection.legacy_codepoint)
            update_popup(popup)
        end
    end
end

-- use hand-crafted json encoder to control order of elements
local function emit_json(entries_by_glyph)
    local function quote(str)
        return '"' .. tostring(str):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    end

    local function format_legacy_array(entry)
        local strings = {}
        if entry.legacyCodepoints then
            for index, legacy_cp in ipairs(entry.legacyCodepoints) do
                local str = entry.legacyStrings and entry.legacyStrings[index] or legacy_codepoint_to_string(legacy_cp)
                table.insert(strings, str)
            end
        end
        if #strings == 0 then
            return '            "legacyCodepoints": []'
        end
        local parts = {}
        for _, str in ipairs(strings) do
            table.insert(parts, '                ' .. quote(str))
        end
        return '            "legacyCodepoints": [\n' .. table.concat(parts, ",\n") .. '\n            ]'
    end

    local function emit_entry(entry)
        local parts = { format_legacy_array(entry) }
        table.insert(parts, '            "codepoint": ' .. quote(utils.format_codepoint(entry.codepoint)))
        table.insert(parts, '            "description": ' .. quote(entry.description or ""))
        if type(entry.nameIsMakeMusic) == "boolean" then
            table.insert(parts, '            "nameIsMakeMusic": ' .. tostring(entry.nameIsMakeMusic))
        end
        if entry.smuflFontName then
            table.insert(parts, '            "smuflFontName": ' .. quote(entry.smuflFontName))
        end
        if entry.xOffset then
            table.insert(parts, '            "xOffset": ' .. quote(tostring(entry.xOffset)))
        end
        if entry.yOffset then
            table.insert(parts, '            "yOffset": ' .. quote(tostring(entry.yOffset)))
        end
        if type(entry.alternate) == "boolean" then
            table.insert(parts, '            "alternate": ' .. tostring(entry.alternate))
        end
        if entry.notes and #entry.notes > 0 then
            table.insert(parts, '            "notes": ' .. quote(entry.notes))
        end
        return "        {\n" .. table.concat(parts, ",\n") .. "\n        }"
    end

    local lines = { "{" }
    local first_glyph = true
    for glyph, entry_list in pairsbykeys(entries_by_glyph) do
        if type(glyph) == "string" and type(entry_list) == "table" and #entry_list > 0 then
            local sortable = {}
            for _, entry in ipairs(entry_list) do
                if entry.legacyCodepoints and #entry.legacyCodepoints > 0 then
                    table.insert(sortable, entry)
                end
            end
            if #sortable > 0 then
                table.sort(sortable, function(a, b)
                    local a_codepoint = a.legacyCodepoints and a.legacyCodepoints[1] or 0
                    local b_codepoint = b.legacyCodepoints and b.legacyCodepoints[1] or 0
                    if a_codepoint == b_codepoint then
                        return (a.codepoint or 0) < (b.codepoint or 0)
                    end
                    return a_codepoint < b_codepoint
                end)
                if not first_glyph then
                    lines[#lines] = lines[#lines] .. ","
                end
                table.insert(lines, "    " .. quote(glyph) .. ": [")
                for index, entry in ipairs(sortable) do
                    local entry_text = emit_entry(entry)
                    if index < #sortable then
                        entry_text = entry_text .. ","
                    end
                    table.insert(lines, entry_text)
                end
                table.insert(lines, "    ]")
                first_glyph = false
            end
        end
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

local function on_save(control)
    local dialog = control:GetParent()
    local function has_mappings()
        for _, entry_list in pairs(context.entries_by_glyph) do
            if type(entry_list) == "table" then
                for _, entry in ipairs(entry_list) do
                    if entry.legacyCodepoints and #entry.legacyCodepoints > 0 then
                        return true
                    end
                end
            end
        end
        return false
    end
    if not has_mappings() then
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
    for _, entry_list in pairs(context.entries_by_glyph) do
        if type(entry_list) == "table" then
            for _, entry in ipairs(entry_list) do
                if entry.legacyCodepoints and #entry.legacyCodepoints > 0 then
                    if type(entry.glyph) ~= "string" or entry.glyph == "" then
                        dialog:CreateChildUI():AlertError("A mapping is missing a glyph name.", "Missing Glyph Name")
                        return
                    end
                    if not entry.codepoint then
                        dialog:CreateChildUI():AlertError("A mapping is missing a SMuFL codepoint.", "Missing Codepoint")
                        return
                    end
                end
            end
        end
    end
    local result = emit_json(context.entries_by_glyph)
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

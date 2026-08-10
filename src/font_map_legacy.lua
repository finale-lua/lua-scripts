function plugindef()
    finaleplugin.RequireDocument = true -- manipulating font information requires a document
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1.0"
    finaleplugin.Date = "August 7, 2026"
    finaleplugin.MinJWLuaVersion = 0.75
    finaleplugin.Notes = [[
        A utility for mapping legacy music font glyphs to SMuFL glyphs. It emits a json
        file in the format used by the smufl-mapping project:

            { "fontMetadata": { ... }, "glyphs": { <glyph name>: [ <entries> ] } }

        The `fontMetadata` block records what is known about the legacy font as a whole:
        whether it is placed in the score (`engraving`) or set inline with running text
        (`text`), whether it imitates plate engraving or manuscript, which SMuFL font
        supersedes it, and how many staff spaces one em spans. Those font-level facts
        cannot be derived from the glyph mappings, so they are entered here.

        Files in the older flat format — including those shipped with Finale for
        MakeMusic's legacy fonts, where every top-level key was a glyph name — are still
        read. They are saved back out in the current format.
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

-- The two enumerations from the fontMetadata schema. fontType is the font's role
-- (where it goes) and fontStyle is its appearance; neither can be derived from the
-- other, so a font may be handwritten and still be set inline with text.
local FONT_TYPES = {
    { value = "engraving", label = "engraving (placed in the score)" },
    { value = "text",      label = "text (set inline with running text)" }
}
local FONT_STYLES = {
    { value = "engraved",    label = "engraved (imitates plate engraving)" },
    { value = "handwritten", label = "handwritten (imitates manuscript)" }
}
local NO_SUCCESSOR_LABEL = "(none established)"

context = {
    smufl_list = library.get_smufl_font_list(),
    current_font = finale.FCFontInfo("Maestro", 24),
    current_mapping = {},
    entries_by_glyph = {},
    popup_entries = {},
    font_metadata = {},
    current_directory = finenv.RunningLuaFolderPath()
}

local enable_disable
local get_popup_entry

-- cjson decodes JSON null to a sentinel rather than nil, so a present-but-null
-- smuflSuccessorFont or staffSpacesPerEm arrives as cjson.null and would otherwise
-- test as a value.
local function json_or_nil(value)
    if value == nil or value == cjson.null then
        return nil
    end
    return value
end

local function default_font_metadata()
    return {
        fontType = "engraving",
        fontStyle = "engraved",
        smuflSuccessorFont = nil,
        successorNotes = nil,
        staffSpacesPerEm = nil,
        sizeNotes = nil
    }
end

local function reset_mapping_state()
    context.current_mapping = {}
    context.entries_by_glyph = {}
    context.popup_entries = {}
    context.font_metadata = default_font_metadata()
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

local function enum_index(enum_list, value)
    for index, item in ipairs(enum_list) do
        if item.value == value then
            return index - 1 -- popups are 0-based
        end
    end
    return 0
end

local function select_popup_string(popup, text)
    for index = 0, popup:GetCount() - 1 do
        local str = finale.FCString()
        popup:GetItemText(index, str)
        if str.LuaString == text then
            popup:SetSelectedItem(index)
            return true
        end
    end
    return false
end

local function popup_string(popup)
    local str = finale.FCString()
    popup:GetItemText(popup:GetSelectedItem(), str)
    return str.LuaString
end

-- Push context.font_metadata into the controls. Called whenever the mapping is
-- reset or a file is loaded.
local function metadata_to_dialog(dialog)
    local metadata = context.font_metadata
    dialog:GetControl("font_type"):SetSelectedItem(enum_index(FONT_TYPES, metadata.fontType))
    dialog:GetControl("font_style"):SetSelectedItem(enum_index(FONT_STYLES, metadata.fontStyle))
    local successor = dialog:GetControl("successor")
    if not metadata.smuflSuccessorFont or not select_popup_string(successor, metadata.smuflSuccessorFont) then
        successor:SetSelectedItem(0) -- NO_SUCCESSOR_LABEL
    end
    dialog:GetControl("successor_notes"):SetText(metadata.successorNotes or "")
    dialog:GetControl("spaces_per_em"):SetText(
        metadata.staffSpacesPerEm and tostring(metadata.staffSpacesPerEm) or "")
    dialog:GetControl("size_notes"):SetText(metadata.sizeNotes or "")
end

-- Pull the controls back into context.font_metadata. Returns nil plus a message
-- when a field cannot be interpreted, so that save can refuse rather than write a
-- file the validator will reject.
local function metadata_from_dialog(dialog)
    local function trimmed(name)
        local text = utils.trim(dialog:GetControl(name):GetText())
        return #text > 0 and text or nil
    end

    local metadata = default_font_metadata()
    metadata.fontType = FONT_TYPES[dialog:GetControl("font_type"):GetSelectedItem() + 1].value
    metadata.fontStyle = FONT_STYLES[dialog:GetControl("font_style"):GetSelectedItem() + 1].value

    local successor = popup_string(dialog:GetControl("successor"))
    if successor ~= NO_SUCCESSOR_LABEL then
        metadata.smuflSuccessorFont = successor
    end
    metadata.successorNotes = trimmed("successor_notes")
    metadata.sizeNotes = trimmed("size_notes")

    -- Present-but-null is how the file says "opts out of size mapping", so an empty
    -- box is a legitimate value rather than an omission.
    local spaces_text = trimmed("spaces_per_em")
    if spaces_text then
        local spaces = tonumber(spaces_text)
        if not spaces or spaces <= 0 then
            return nil, "Staff spaces per em must be a number greater than zero, or blank to opt out of size mapping."
        end
        metadata.staffSpacesPerEm = spaces
    end

    context.font_metadata = metadata
    return metadata
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
    dialog:GetControl("entry_notes"):SetText("")
    metadata_to_dialog(dialog)
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

-- An entry carrying notes is one whose mapping has not been confirmed by hand.
-- The notes text says why; "Mark Verified" clears it once the slot has been checked.
local function entry_is_flagged(entry)
    return entry ~= nil and type(entry.notes) == "string" and #entry.notes > 0
end

enable_disable = function(dialog)
    local delable = #(dialog:GetControl("legacy_box"):GetText()) > 0
    local addable = delable and #(dialog:GetControl("smufl_box"):GetText()) > 0
    local popup = dialog:GetControl("mappings")
    local selection = popup:GetCount() > 0 and get_popup_entry(popup) or nil
    if delable then
        delable = selection ~= nil
    end
    dialog:GetControl("add_mapping"):SetEnable(addable)
    dialog:GetControl("delete_mapping"):SetEnable(delable)
    dialog:GetControl("mark_verified"):SetEnable(entry_is_flagged(selection and selection.entry))
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
    dialog:GetControl("entry_notes"):SetText(
        entry_is_flagged(current_mapping) and current_mapping.notes or "")
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
        if entry_is_flagged(info.entry) then
            label = "[?] " .. label -- not yet confirmed by hand
        end
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
        -- The current format wraps the glyph table so that font-level facts are
        -- distinguishable from glyph names; the older flat format, including the
        -- files shipped with Finale, put glyph names at the top level.
        local glyph_table = json
        local metadata = nil
        if type(json.fontMetadata) == "table" or type(json.glyphs) == "table" then
            glyph_table = type(json.glyphs) == "table" and json.glyphs or {}
            metadata = type(json.fontMetadata) == "table" and json.fontMetadata or nil
        end
        context.current_directory = path
        change_font(dialog, font_info) -- resets metadata to defaults
        if metadata then
            local loaded = default_font_metadata()
            local font_type = json_or_nil(metadata.fontType)
            local font_style = json_or_nil(metadata.fontStyle)
            -- Fall back to the defaults rather than carrying a value the schema
            -- would reject straight back out again.
            if font_type == "engraving" or font_type == "text" then
                loaded.fontType = font_type
            end
            if font_style == "engraved" or font_style == "handwritten" then
                loaded.fontStyle = font_style
            end
            loaded.smuflSuccessorFont = json_or_nil(metadata.smuflSuccessorFont)
            loaded.successorNotes = json_or_nil(metadata.successorNotes)
            loaded.sizeNotes = json_or_nil(metadata.sizeNotes)
            local spaces = json_or_nil(metadata.staffSpacesPerEm)
            if type(spaces) == "number" and spaces > 0 then
                loaded.staffSpacesPerEm = spaces
            end
            context.font_metadata = loaded
            metadata_to_dialog(dialog)
        end
        local smufl_box = dialog:GetControl("smufl_box")
        for glyph, value in pairs(glyph_table) do
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

-- Clearing the notes is what records "I have checked this slot against the font".
-- Correcting a mapping does not clear it on its own: an edit may itself be a guess,
-- so confirmation stays an explicit act.
local function on_mark_verified(control)
    local dialog = control:GetParent()
    local popup = dialog:GetControl("mappings")
    local selection = get_popup_entry(popup)
    if not selection or not entry_is_flagged(selection.entry) then
        return
    end
    selection.entry.notes = nil
    update_popup(popup, selection.legacy_codepoint, selection.entry)
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
local function emit_json(entries_by_glyph, metadata)
    local function quote(str)
        return '"' .. tostring(str):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    end

    -- staffSpacesPerEm is a JSON number, and the committed files write whole values
    -- as "4.0". tostring(4.0) yields "4.0" in Lua 5.3+ but "4" in 5.1/5.2, so pin it.
    local function format_number(value)
        local text = string.format("%.10g", value)
        if not text:find("[%.eE]") then
            text = text .. ".0"
        end
        return text
    end

    local function emit_metadata()
        local parts = {}
        table.insert(parts, '        "fontType": ' .. quote(metadata.fontType))
        table.insert(parts, '        "fontStyle": ' .. quote(metadata.fontStyle))
        -- smuflSuccessorFont and staffSpacesPerEm are always written, even when
        -- null: present-but-null is how the file says "none established" / "opts
        -- out of size mapping", and an absent key would be an oversight instead.
        table.insert(parts, '        "smuflSuccessorFont": ' ..
            (metadata.smuflSuccessorFont and quote(metadata.smuflSuccessorFont) or "null"))
        if metadata.successorNotes then
            table.insert(parts, '        "successorNotes": ' .. quote(metadata.successorNotes))
        end
        table.insert(parts, '        "staffSpacesPerEm": ' ..
            (metadata.staffSpacesPerEm and format_number(metadata.staffSpacesPerEm) or "null"))
        if metadata.sizeNotes then
            table.insert(parts, '        "sizeNotes": ' .. quote(metadata.sizeNotes))
        end
        return '    "fontMetadata": {\n' .. table.concat(parts, ",\n") .. "\n    },"
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
            return '                "legacyCodepoints": []'
        end
        local parts = {}
        for _, str in ipairs(strings) do
            table.insert(parts, '                    ' .. quote(str))
        end
        return '                "legacyCodepoints": [\n' .. table.concat(parts, ",\n") .. '\n                ]'
    end

    local function emit_entry(entry)
        local parts = { format_legacy_array(entry) }
        table.insert(parts, '                "codepoint": ' .. quote(utils.format_codepoint(entry.codepoint)))
        table.insert(parts, '                "description": ' .. quote(entry.description or ""))
        if type(entry.nameIsMakeMusic) == "boolean" then
            table.insert(parts, '                "nameIsMakeMusic": ' .. tostring(entry.nameIsMakeMusic))
        end
        if entry.smuflFontName then
            table.insert(parts, '                "smuflFontName": ' .. quote(entry.smuflFontName))
        end
        if entry.xOffset then
            table.insert(parts, '                "xOffset": ' .. quote(tostring(entry.xOffset)))
        end
        if entry.yOffset then
            table.insert(parts, '                "yOffset": ' .. quote(tostring(entry.yOffset)))
        end
        if type(entry.alternate) == "boolean" then
            table.insert(parts, '                "alternate": ' .. tostring(entry.alternate))
        end
        if entry.notes and #entry.notes > 0 then
            table.insert(parts, '                "notes": ' .. quote(entry.notes))
        end
        return "            {\n" .. table.concat(parts, ",\n") .. "\n            }"
    end

    local glyph_lines = {}
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
                    glyph_lines[#glyph_lines] = glyph_lines[#glyph_lines] .. ","
                end
                table.insert(glyph_lines, "        " .. quote(glyph) .. ": [")
                for index, entry in ipairs(sortable) do
                    local entry_text = emit_entry(entry)
                    if index < #sortable then
                        entry_text = entry_text .. ","
                    end
                    table.insert(glyph_lines, entry_text)
                end
                table.insert(glyph_lines, "        ]")
                first_glyph = false
            end
        end
    end

    local lines = { "{", emit_metadata() }
    if #glyph_lines == 0 then
        -- A font whose successor and sizing are known while its codepoint mappings
        -- are not is a valid record, as for Sonata and Ash Music.
        table.insert(lines, '    "glyphs": {}')
    else
        table.insert(lines, '    "glyphs": {')
        for _, line in ipairs(glyph_lines) do
            table.insert(lines, line)
        end
        table.insert(lines, "    }")
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n") .. "\n" -- committed mapping files end with a newline
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
    local metadata, metadata_error = metadata_from_dialog(dialog)
    if not metadata then
        dialog:CreateChildUI():AlertError(metadata_error, "Invalid Font Metadata")
        return
    end
    if not has_mappings() then
        -- Not an error: the format allows a file that records what is known about
        -- the font while its codepoint mappings are unavailable.
        dialog:CreateChildUI():AlertInfo(
            "No glyphs are mapped, so a metadata-only file will be written.", "Metadata Only")
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
    local result = emit_json(context.entries_by_glyph, metadata)
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
    -- Mappings that have not been confirmed by hand are prefixed "[?]" in the popup
    -- above and explain themselves here.
    dialog:CreateButton(0, current_y, "mark_verified")
        :SetText("Mark Verified")
        :DoAutoResizeWidth(0)
        :SetEnable(false)
        :AddHandleCommand(on_mark_verified)
    dialog:CreateStatic(0, current_y, "entry_notes")
        :AssureNoHorizontalOverlap(dialog:GetControl("mark_verified"), 10)
        :StretchToAlignWithRight()
    current_y = current_y + button_height + y_increment
    -- font metadata: font-level facts that cannot be derived from the glyph
    -- mappings, so they have to be entered rather than measured here.
    local label_gap = 5
    dialog:CreateStatic(0, current_y, "type_label")
        :SetText("Type:")
        :DoAutoResizeWidth()
    local type_popup = dialog:CreatePopup(0, current_y, "font_type")
        :SetWidth(200)
        :AssureNoHorizontalOverlap(dialog:GetControl("type_label"), label_gap)
    for _, item in ipairs(FONT_TYPES) do
        type_popup:AddString(item.label)
    end
    type_popup:SetSelectedItem(0)
    current_y = current_y + button_height + y_increment
    dialog:CreateStatic(0, current_y, "style_label")
        :SetText("Style:")
        :DoAutoResizeWidth()
    local style_popup = dialog:CreatePopup(0, current_y, "font_style")
        :SetWidth(200)
        :AssureNoHorizontalOverlap(dialog:GetControl("style_label"), label_gap)
    for _, item in ipairs(FONT_STYLES) do
        style_popup:AddString(item.label)
    end
    style_popup:SetSelectedItem(0)
    current_y = current_y + button_height + y_increment
    dialog:CreateStatic(0, current_y, "successor_label")
        :SetText("SMuFL successor:")
        :DoAutoResizeWidth()
    local successor_popup = dialog:CreatePopup(0, current_y, "successor")
        :AssureNoHorizontalOverlap(dialog:GetControl("successor_label"), label_gap)
        :StretchToAlignWithRight()
    successor_popup:AddString(NO_SUCCESSOR_LABEL)
    for name, _ in pairsbykeys(context.smufl_list) do
        successor_popup:AddString(name)
    end
    successor_popup:SetSelectedItem(0)
    current_y = current_y + button_height + y_increment
    dialog:CreateStatic(0, current_y, "successor_notes_label")
        :SetText("Successor notes:")
        :DoAutoResizeWidth()
    dialog:CreateEdit(0, current_y, "successor_notes")
        :AssureNoHorizontalOverlap(dialog:GetControl("successor_notes_label"), label_gap)
        :StretchToAlignWithRight()
    current_y = current_y + button_height + y_increment
    dialog:CreateStatic(0, current_y, "spaces_label")
        :SetText("Staff spaces per em (blank to opt out):")
        :DoAutoResizeWidth()
    dialog:CreateEdit(0, current_y, "spaces_per_em")
        :SetWidth(60)
        :AssureNoHorizontalOverlap(dialog:GetControl("spaces_label"), label_gap)
    current_y = current_y + button_height + y_increment
    dialog:CreateStatic(0, current_y, "size_notes_label")
        :SetText("Size notes:")
        :DoAutoResizeWidth()
    dialog:CreateEdit(0, current_y, "size_notes")
        :AssureNoHorizontalOverlap(dialog:GetControl("size_notes_label"), label_gap)
        :StretchToAlignWithRight()
    current_y = current_y + button_height + 2 * y_increment
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
        context.font_metadata = default_font_metadata()
        metadata_to_dialog(self)
    end)
    -- execute
    dialog:ExecuteModal() -- modal dialog prevents document changes in modeless callbacks
end

font_map_legacy()

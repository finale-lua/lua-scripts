function plugindef()
    finaleplugin.RequireScore = false
    finaleplugin.RequireSelection = false
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "2.0.1"
    finaleplugin.Date = "2023-02-24"
    finaleplugin.CategoryTags = "Report"   
    finaleplugin.Id = "9c05a4c4-9508-4608-bb1b-2819cba96101" 
    finaleplugin.AdditionalMenuOptions = [[
        Import Document Options from JSON...
    ]]
    finaleplugin.AdditionalPrefixes = [[
        action = "import"
    ]]
    finaleplugin.RevisionNotes = [[
        v2.0.1      Add ability to import
        v1.2.1      Add Grid/Guide snap-tos; better organization of SmartShapes
        v1.1.2      First public release
    ]]
    finaleplugin.Notes = [[
        While other plugins exist that let you copy document options directly from one document to another, 
        this script saves the options from the current document in an organized human-readable form, as a 
        JSON file. You can then use a diff program to compare the JSON files generated from 
        two Finale documents, or you can keep track of how the settings in a document have changed 
        over time. The script will also let you import settings from a full or partial JSON file.
        Please see https://url.sherber.com/finalelua/options-as-json for more information.
        
        The focus is on document-specific settings, rather than program-wide ones, and in particular on 
        the ones that affect the look of a document. Most of these come from the Document Options dialog 
        in Finale, although some come from the Category Designer, the Page Format dialog, and the 
        SmartShape menu.

        All physical measurements are given in EVPUs, except for a couple of values that Finale always 
        displays as spaces. (1 EVPU is 1/288 of an inch, 1/24 of a space, or 1/4 of a point.) So if your 
        measurement units are set to EVPUs, the values given here should match what you see in Finale.
    ]]

    return "Save Document Options as JSON...", "", "Saves all current document options to a JSON file"
end

--[[
    BASIC WORKFLOW FOR SAVING PREFERENCES
    - Load all preferences with prefs object and use dumpproperties() to turn them
      into one big table, using custom handlers if needed (RAW PREFS and HANDLERS sections)
    - NORMALIZE units (mainly to EVPU, but also to standard percent values, etc.)
    - TRANSFORM the raw prefs table into a table grouped the way a user would see things
    - Serialize to alpha order JSON

    Loading preferences essentially follows this workflow in reverse. 
  ]]

action = action or "export"
local debug = {
    raw_categories = false,
    raw_units = false
}

local mixin = require('library.mixin')
local json = require("lunajson.lunajson")

-- region DIALOGS

local fcstr = function(str)
    return mixin.FCMString():SetLuaString(str)
end

function simplify_finale_version(ver)
    if type(ver) == "number" then
        return ver < 10000 and ver or (ver - 10000)
    else
        return nil
    end
end

function get_file_options_tag()
    local temp_table = {}
    if debug.raw_categories then table.insert(temp_table, "raw prefs") end
    if debug.raw_units then table.insert(temp_table, "raw units") end
    local result = table.concat(temp_table, ", ")
    if #result > 0 then result = " - " .. result end
    return result
end

function get_path_and_file(document)
    local file_name = mixin.FCMString()
    local path_name = mixin.FCMString()
    local file_path = mixin.FCMString()
    document:GetPath(file_path)
    file_path:SplitToPathAndFile(path_name, file_name)
    return path_name, file_name
end

function do_file_open_dialog(document)
    local text_extension = ".json"
    local filter_text = "JSON files"

    local path_name, file_name = get_path_and_file(document)
    local open_dialog = mixin.FCMFileOpenDialog(finenv.UI())
            :SetWindowTitle(fcstr("Open JSON Settings"))
            :SetInitFolder(path_name)
            :AddFilter(fcstr("*" .. text_extension), fcstr(filter_text))
    if not open_dialog:Execute() then
        return nil
    end

    local selected_file_name = finale.FCString()
    open_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end

function confirm_file_import(meta)
    -- If no meta section then don't confirm
    if meta == nil then return true end

    local col_1_width = 85
    local width_factor = 6
    local row_height = 17
    local max_string_length = 0

    local dialog = mixin.FCMCustomWindow()
        :SetTitle("Confirm Import")

    local t = {
        { "Import these settings?" },
        {},
        { "Music File", meta.File or meta.MusicFile},
        { "Date", meta.Date },
        { "Finale Version", simplify_finale_version(meta.FinaleVersion) },
        { "Description", meta.Description }
    }

    for row, labels in ipairs(t) do
        for col, label in ipairs(labels) do
            max_string_length = math.max(max_string_length, string.len(label or ""))
            dialog:CreateStatic((col - 1) * col_1_width, (row - 1) * row_height)
                :SetText(label)
        end
    end

    for ctrl in each(dialog) do
        ctrl:SetWidth(max_string_length * width_factor)
    end
    
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return dialog:ExecuteModal(nil) == finale.EXECMODAL_OK
end

function do_save_as_dialog(document)
    local text_extension = ".json"
    local filter_text = "JSON files"

    local path_name, file_name = get_path_and_file(document)
    local full_file_name = file_name.LuaString
    local extension = mixin.FCMString()
                            :SetLuaString(file_name.LuaString)
                            :ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("." .. extension.LuaString))
    end
    file_name:AppendLuaString(" settings")
            :AppendLuaString(get_file_options_tag())
            :AppendLuaString(text_extension)
    local save_dialog = mixin.FCMFileSaveAsDialog(finenv.UI())
            :SetWindowTitle(fcstr("Save As"))
            :AddFilter(fcstr("*" .. text_extension), fcstr(filter_text))
            :SetInitFolder(path_name)
            :SetFileName(file_name)
    if not save_dialog:Execute() then
        return nil
    end
    save_dialog:AssureFileExtension(text_extension)
    local selected_file_name = finale.FCString()
    save_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end

function get_description()
    local dialog = mixin.FCMCustomWindow():SetTitle("Save As")

    dialog:CreateStatic(0, 0):SetText("Settings Description"):SetWidth(120)
    dialog:CreateEdit(0, 17, "input"):SetWidth(360)
    dialog:CreateOkButton()

    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        return dialog:GetControl("input"):GetText()
    else
        return ""
    end
end

-- endregion

-- region HANDLERS

--[[
    Functions to assist with moving raw preferences
    between tables and PDK objects.
  ]]  

function getter_name(...) return "Get" .. table.concat{...} end
function setter_name(...) return "Set" .. table.concat{...} end
function delete_from_table(prefs_table, exclusions)
    if not prefs_table or not exclusions then return end
    for _, e in pairs(exclusions) do prefs_table[e] = nil end
end

function add_props_to_table(prefs_table, prefs_obj, tag, exclusions)
    if tag then
        prefs_table[tag] = {}
        prefs_table = prefs_table[tag]
    end
    for k, v in pairs(dumpproperties(prefs_obj)) do
        prefs_table[k] = v
    end
    delete_from_table(prefs_table, exclusions)
end

function set_props_from_table(prefs_table, prefs_obj, exclusions)
    prefs_table = prefs_table or {}
    delete_from_table(prefs_table, exclusions)
    for k, v in pairs(prefs_table) do
        if type(v) ~= "table" then
            local setter = prefs_obj[setter_name(k)]
            if setter then setter(prefs_obj, v) end
        end
    end
end

function handle_page_format_prefs(prefs_obj, prefs_table, load)
    local SCORE, PARTS = "Score", "Parts"
    if load then
        prefs_obj:LoadScore()
        add_props_to_table(prefs_table, prefs_obj, SCORE)
        prefs_obj:LoadParts()
        add_props_to_table(prefs_table, prefs_obj, PARTS)
    else
        prefs_obj:LoadScore()
        set_props_from_table(prefs_table[SCORE], prefs_obj)
        prefs_obj:Save()
        prefs_obj:LoadParts()
        set_props_from_table(prefs_table[PARTS], prefs_obj)
        prefs_obj:Save()
    end
end

function handle_name_position_prefs(prefs_obj, prefs_table, load)
    local FULL, ABBREVIATED = "Full", "Abbreviated"
    if load then
        prefs_obj:LoadFull()
        add_props_to_table(prefs_table, prefs_obj, FULL)
        prefs_obj:LoadAbbreviated()
        add_props_to_table(prefs_table, prefs_obj, ABBREVIATED)
    else
        prefs_obj:LoadFull()
        set_props_from_table(prefs_table[FULL], prefs_obj)
        prefs_obj:Save()
        prefs_obj:LoadAbbreviated()
        set_props_from_table(prefs_table[ABBREVIATED], prefs_obj)
        prefs_obj:Save()
    end
end

function handle_layer_prefs(prefs_obj, prefs_table, load)
    for i = 0, 3 do
        prefs_obj:Load(i)
        local layer_name = "Layer" .. i + 1
        if load then
            add_props_to_table(prefs_table, prefs_obj, layer_name)
        else
            set_props_from_table(prefs_table[layer_name], prefs_obj)
            prefs_obj:Save()
        end
    end
end

local FONT_EXCLUSIONS = { "EnigmaStyles", "IsSMuFLFont", "Size" }

function handle_font_prefs(prefs_obj, prefs_table, load)
    local font_pref_types = {
        [finale.FONTPREF_MUSIC]              = 'Music',
        [finale.FONTPREF_KEYSIG]             = 'KeySignatures',
        [finale.FONTPREF_CLEF]               = 'Clefs',
        [finale.FONTPREF_TIMESIG]            = 'TimeSignatureScore',
        [finale.FONTPREF_CHORDSYMBOL]        = 'ChordSymbols',
        [finale.FONTPREF_CHORDALTERATION]    = 'ChordAlterations',
        [finale.FONTPREF_ENDING]             = 'EndingRepeats',
        [finale.FONTPREF_TUPLET]             = 'Tuplets',
        [finale.FONTPREF_TEXTBLOCK]          = 'TextBlocks',
        [finale.FONTPREF_LYRICSVERSE]        = 'LyricVerses',
        [finale.FONTPREF_LYRICSCHORUS]       = 'LyricChoruses',
        [finale.FONTPREF_LYRICSSECTION]      = 'LyricSections',
        [finale.FONTPREF_MULTIMEASUREREST]   = 'MultimeasureRests',
        [finale.FONTPREF_CHORDSUFFIX]        = 'ChordSuffixes',
        [finale.FONTPREF_EXPRESSION]         = 'Expressions',
        [finale.FONTPREF_REPEAT]             = 'TextRepeats',
        [finale.FONTPREF_CHORDFRETBOARD]     = 'ChordFretboards',
        [finale.FONTPREF_FLAG]               = 'Flags',
        [finale.FONTPREF_ACCIDENTAL]         = 'Accidentals',
        [finale.FONTPREF_ALTERNATESLASH]     = 'AlternateNotation',
        [finale.FONTPREF_ALTERNATENUMBER]    = 'AlternateNotationNumbers',
        [finale.FONTPREF_REST]               = 'Rests',
        [finale.FONTPREF_REPEATDOT]          = 'RepeatDots',
        [finale.FONTPREF_NOTEHEAD]           = 'Noteheads',
        [finale.FONTPREF_AUGMENTATIONDOT]    = 'AugmentationDots',
        [finale.FONTPREF_TIMESIGPLUS]        = 'TimeSignaturePlusScore',
        [finale.FONTPREF_ARTICULATION]       = 'Articulations',
        [finale.FONTPREF_DEFTABLATURE]       = 'Tablature',
        [finale.FONTPREF_PERCUSSION]         = 'PercussionNoteheads',
        [finale.FONTPREF_8VA]                = 'SmartShape8va',
        [finale.FONTPREF_MEASURENUMBER]      = 'MeasureNumbers',
        [finale.FONTPREF_STAFFNAME]          = 'StaffNames',
        [finale.FONTPREF_ABRVSTAFFNAME]      = 'StaffNamesAbbreviated',
        [finale.FONTPREF_GROUPNAME]          = 'GroupNames',
        [finale.FONTPREF_8VB]                = 'SmartShape8vb',
        [finale.FONTPREF_15MA]               = 'SmartShape15ma',
        [finale.FONTPREF_15MB]               = 'SmartShape15mb',
        [finale.FONTPREF_TR]                 = 'SmartShapeTrill',
        [finale.FONTPREF_WIGGLE]             = 'SmartShapeWiggle',
        [finale.FONTPREF_ABRVGROUPNAME]      = 'GroupNamesAbbreviated',
        [finale.FONTPREF_GUITARBENDFULL]     = 'GuitarBendFull',
        [finale.FONTPREF_GUITARBENDNUMBER]   = 'GuitarBendNumber',
        [finale.FONTPREF_GUITARBENDFRACTION] = 'GuitarBendFraction',
        [finale.FONTPREF_TIMESIG_PARTS]      = 'TimeSignatureParts',
        [finale.FONTPREF_TIMESIGPLUS_PARTS]  = 'TimeSignaturePlusParts',
    }

    for pref_type, tag in pairs(font_pref_types) do
        if load then
            prefs_obj:LoadFontPrefs(pref_type)
            add_props_to_table(prefs_table, prefs_obj, tag, FONT_EXCLUSIONS)
        else
            set_props_from_table(prefs_table[tag], prefs_obj, FONT_EXCLUSIONS)
            prefs_obj:SaveFontPrefs(pref_type)
        end
    end
end

function handle_tie_placement_prefs(prefs_obj, prefs_table, load)
    local tie_placement_types = {
        [finale.TIEPLACE_OVERINNER]      = "Over/Inner",
        [finale.TIEPLACE_UNDERINNER]     = "Under/Inner",
        [finale.TIEPLACE_OVEROUTERNOTE]  = "Over/Outer/Note",
        [finale.TIEPLACE_UNDEROUTERNOTE] = "Under/Outer/Note",
        [finale.TIEPLACE_OVEROUTERSTEM]  = "Over/Outer/Stem",
        [finale.TIEPLACE_UNDEROUTERSTEM] = "Under/Outer/Stem"
    }

    local prop_names = {
        "HorizontalStart",
        "VerticalStart",
        "HorizontalEnd",
        "VerticalEnd"
    }

    for placement_type, tag in pairs(tie_placement_types) do
        prefs_obj:Load(placement_type)
        if load then            
            local t = {}
            for _, name in pairs(prop_names) do
                t[name] = prefs_obj[getter_name(name)](prefs_obj, placement_type)
            end
            prefs_table[tag] = t
        else
            local t = prefs_table[tag]
            for _, name in pairs(prop_names) do
                prefs_obj[setter_name(name)](prefs_obj, placement_type, t[name])
            end
            prefs_obj:Save()
        end
    end
end

function handle_tie_contour_prefs(prefs_obj, prefs_table, load)
    local tie_contour_types = {
        [finale.TCONTOURIDX_SHORT]   = "Short",
        [finale.TCONTOURIDX_MEDIUM]  = "Medium",
        [finale.TCONTOURIDX_LONG]    = "Long",
        [finale.TCONTOURIDX_TIEENDS] = "TieEnds"
    }

    local prop_names = {
        "Span",
        "LeftRelativeInset",
        "LeftRawRelativeInset",
        "LeftHeight",
        "LeftFixedInset",
        "RightRelativeInset",
        "RightRawRelativeInset",
        "RightHeight",
        "RightFixedInset",
    }
        
    for contour_type, tag in pairs(tie_contour_types) do
        prefs_obj:Load(contour_type)
        if load then
            local t = {}
            for _, name in pairs(prop_names) do
                t[name] = prefs_obj[getter_name(name)](prefs_obj, contour_type)
            end
            prefs_table[tag] = t
        else
            local t = prefs_table[tag]
            for _, name in pairs(prop_names) do
                prefs_obj[setter_name(name)](prefs_obj, contour_type, t[name])                
            end
            prefs_obj:Save()
        end
    end
end

function handle_base_prefs(prefs_obj, prefs_table, load, exclusions)
    exclusions = exclusions or {}
    prefs_obj:Load(1)
    if load then
        add_props_to_table(prefs_table, prefs_obj, nil, exclusions)
    else
        set_props_from_table(prefs_table, prefs_obj, exclusions)
        prefs_obj:Save()
    end
end

function handle_tie_prefs(prefs_obj, prefs_table, load)
    handle_base_prefs(prefs_obj, prefs_table, load)
    local TIE_CONTOURS, TIE_PLACEMENT = "TieContours", "TiePlacement"
    if load then
        local function load_sub_prefs(sub_prefs, handler, tag)
            local t = {}
            handler(sub_prefs, t, true)
            prefs_table[tag] = t
        end

        load_sub_prefs(prefs_obj:CreateTieContourPrefs(), handle_tie_contour_prefs, TIE_CONTOURS)
        load_sub_prefs(prefs_obj:CreateTiePlacementPrefs(), handle_tie_placement_prefs, TIE_PLACEMENT)
    else
        handle_tie_contour_prefs(prefs_obj:CreateTieContourPrefs(), prefs_table[TIE_CONTOURS], false)
        handle_tie_placement_prefs(prefs_obj:CreateTiePlacementPrefs(), prefs_table[TIE_PLACEMENT], false)
    end
end

function handle_category_prefs(prefs_obj, prefs_table, load)
    local font = finale.FCFontInfo()
    local font_types = { "Text", "Music", "Number" }
    local FONTS, FONT_INFO, TYPE = "Fonts", "FontInfo", "Type"
    local EXCLUSIONS = { "ID" }
    local function get_cat_tag(cat) return cat:CreateName().LuaString:gsub(" ", "") end
    local function humanize(tag) return string.gsub(tag, "(%l)(%u)", "%1 %2") end

    prefs_obj:LoadAll()

    if load then
        for raw_cat in each(prefs_obj) do
            if raw_cat:IsDefaultMiscellaneous() then
                goto cat_continue
            end

            local raw_cat_tag = get_cat_tag(raw_cat)

            add_props_to_table(prefs_table, raw_cat, raw_cat_tag, EXCLUSIONS)

            local font_table = {}
            prefs_table[raw_cat_tag][FONTS] = font_table
            for _, font_type in pairs(font_types) do
                if raw_cat[getter_name(font_type, FONT_INFO)](raw_cat, font) then
                    add_props_to_table(font_table, font, font_type, FONT_EXCLUSIONS)
                end
            end
            ::cat_continue::
        end
    else
        local function populate_raw_cat(cat_values, raw_cat)
            set_props_from_table(cat_values, raw_cat, EXCLUSIONS)
            for _, font_type in pairs(font_types) do
                if raw_cat[getter_name(font_type, FONT_INFO)](raw_cat, font) then
                    set_props_from_table(cat_values[FONTS][font_type], font, FONT_EXCLUSIONS)
                    raw_cat[setter_name(font_type, FONT_INFO)](raw_cat, font)
                end
            end
        end

        for cat_tag, cat_values in pairs(prefs_table) do
            local this_cat = nil
            for raw_cat in each(prefs_obj) do
                if get_cat_tag(raw_cat) == cat_tag then
                    this_cat = raw_cat
                    break
                end                
            end
            if this_cat then
                populate_raw_cat(cat_values, this_cat)
                this_cat:Save()
            else
                local new_cat = finale.FCCategoryDef()
                local cat_type = cat_values[TYPE]
                new_cat:Load(cat_type)
                new_cat:SetName(mixin.FCMString():SetLuaString(humanize(cat_tag)))
                populate_raw_cat(cat_values, new_cat)
                new_cat:SaveNewWithType(cat_type)
            end
        end
    end
end

function handle_smart_shape_prefs(prefs_obj, prefs_table, load)
    handle_base_prefs(prefs_obj, prefs_table, load)

    local contour_prefs = prefs_obj:CreateSlurContourPrefs()
    local span_types = { 'Short', 'Medium', 'Long', 'ExtraLong' }
    local prop_names = { 'Span', 'Inset', 'Height' }
    local SLUR_CONTOURS = "SlurContours"

    if load then
        local contour_table = {}
        prefs_table[SLUR_CONTOURS] = contour_table
    
        for _, type in pairs(span_types) do
            local t = {}
            for _, name in pairs(prop_names) do
                t[name] = contour_prefs[getter_name(type, name)](contour_prefs)
            end
            contour_table[type] = t
        end
    else
        for _, type in pairs(span_types) do
            for _, name in pairs(prop_names) do
                local contour_table = prefs_table[SLUR_CONTOURS]
                if contour_table and contour_table[type] and contour_table[type][name] then
                    contour_prefs[setter_name(type, name)](contour_prefs, contour_table[type][name])
                end
            end
        end
        contour_prefs:Save()
    end
end

function handle_grid_prefs(prefs_obj, prefs_table, load)
    local snap_items = {
        [finale.SNAPITEM_BRACKETS ] = "Brackets",
        [finale.SNAPITEM_CHORDS ] = "Chords",
        [finale.SNAPITEM_EXPRESSIONS ] = "Expressions",
        [finale.SNAPITEM_FRETBOARDS ] = "Fretboards",
        [finale.SNAPITEM_GRAPHICSMOVE ] = "GraphicsMove",
        [finale.SNAPITEM_GRAPHICSSIZING ] = "GraphicsSizing",
        [finale.SNAPITEM_MEASURENUMBERS ] = "MeasureNumbers",
        [finale.SNAPITEM_REPEATS ] = "Repeats",
        [finale.SNAPITEM_SPECIALTOOLS ] = "SpecialTools",
        [finale.SNAPITEM_STAFFNAMES ] = "StaffNames",
        [finale.SNAPITEM_STAVES ] = "Staves",
        [finale.SNAPITEM_TEXTBLOCKMOVE ] = "TextBlockMove",
        [finale.SNAPITEM_TEXTBLOCKSIZING ] = "TextBlockSizing",
    }
    local SNAP_TO_GRID, SNAP_TO_GUIDE = "SnapToGrid", "SnapToGuide"

    handle_base_prefs(prefs_obj, prefs_table, load, { "HorizontalGuideCount", "VerticalGuideCount" })

    if load then
        prefs_table[SNAP_TO_GRID] = {}
        prefs_table[SNAP_TO_GUIDE] = {}
        for item, name in pairs(snap_items) do
            prefs_table[SNAP_TO_GRID][name] = prefs_obj:GetGridSnapToItem(item)
            prefs_table[SNAP_TO_GUIDE][name] = prefs_obj:GetGuideSnapToItem(item)
        end
    else
        for item, name in pairs(snap_items) do
            prefs_obj:SetGridSnapToItem(item, prefs_table[SNAP_TO_GRID][name])
            prefs_obj:SetGuideSnapToItem(item, prefs_table[SNAP_TO_GUIDE][name])
        end
        prefs_obj:Save()
    end
end

function handle_music_spacing_prefs(prefs_obj, prefs_table, load)
    handle_base_prefs(prefs_obj, prefs_table, load, { "ScalingValue" })
end

-- endregion

-- region RAW PREFS

--[[ 
    List of PDK objects to load, along with a handler for ones 
    that don't follow the common pattern.
  ]]
local raw_pref_definitions = {
    { prefs = finale.FCCategoryDefs(), handler = handle_category_prefs },
    { prefs = finale.FCChordPrefs() },
    { prefs = finale.FCDistancePrefs() },
    { prefs = finale.FCFontInfo(), handler = handle_font_prefs },
    { prefs = finale.FCGridsGuidesPrefs(), handler = handle_grid_prefs },
    { prefs = finale.FCGroupNamePositionPrefs(), handler = handle_name_position_prefs },
    { prefs = finale.FCLayerPrefs(), handler = handle_layer_prefs },
    { prefs = finale.FCLyricsPrefs() }, 
    { prefs = finale.FCMiscDocPrefs() },
    { prefs = finale.FCMultiMeasureRestPrefs() },
    { prefs = finale.FCMusicCharacterPrefs() },
    { prefs = finale.FCMusicSpacingPrefs(), handler = handle_music_spacing_prefs },
    { prefs = finale.FCPageFormatPrefs(), handler = handle_page_format_prefs },
    { prefs = finale.FCPianoBracePrefs() },
    { prefs = finale.FCRepeatPrefs() },
    { prefs = finale.FCSizePrefs() },
    { prefs = finale.FCSmartShapePrefs(), handler = handle_smart_shape_prefs },
    { prefs = finale.FCStaffNamePositionPrefs(), handler = handle_name_position_prefs },     
    { prefs = finale.FCTiePrefs(), handler = handle_tie_prefs },
    { prefs = finale.FCTupletPrefs() },
}

function load_all_raw_prefs()
    local result = {}
    
    for _, obj in ipairs(raw_pref_definitions) do
        local tag = obj.prefs:ClassName()
        if obj.handler == nil then
            obj.prefs:Load(1)
            add_props_to_table(result, obj.prefs, tag)
        else
            result[tag] = {}
            obj.handler(obj.prefs, result[tag], true)
        end
        if not debug.raw_units then
            normalize_units_for_raw_section(result[tag], tag)
        end
    end

    return result
end

function save_all_raw_prefs(prefs_table)
    for _, obj in pairs(raw_pref_definitions) do
        local tag = obj.prefs:ClassName()
        denormalize_units_for_raw_section(prefs_table[tag], tag)

        if obj.handler == nil then
            obj.prefs:Load(1)
            set_props_from_table(prefs_table[tag], obj.prefs)
            obj.prefs:Save()
        else
            obj.handler(obj.prefs, prefs_table[tag], false)
        end
    end
end

-- endregion

-- region TRANSFORM

-- Functions for transforming between raw and friendly pref tables

--[[
    The keys in this table are the names of sections in "transformed"
    preferences -- the sections in Document Options or other Finale
    menus where a user would find the preferences.

    For each key, there is then a table of where in the raw prefs the
    preferences come from. The keys here are the names of the PDK classes;
    the values are an array of locators, which can be:

      - a literal string (to match a preference name exactly)
      - a Lua pattern (to match a number of preference names)
      - a negated Lua pattern, beginning with "!" (for all preferences except the ones matching the pattern)

    If the key for the sub-table includes a ">", it indicates a sub-table in the 
    transformed table. So "FCFontInfo>Fonts" (under "SmartShapes") means to take the 
    preferences from FCFontInfo and put them into Fonts under SmartShapes.

    If the key for the sub-table includes a "/", it indicates a sub-table in the 
    source table. So "FCFontInfo/Music" (under "DefaultMusicFont") means that the 
    preferences are drawn from Music table under FCFontInfo.
  ]]
local transform_definitions = {
    Accidentals = { 
        FCDistancePrefs  = { "^Accidental" },
        FCMusicSpacingPrefs = { "AccidentalsGutter" },
        FCMusicCharacterPrefs = {
            "SymbolNatural", "SymbolFlat", "SymbolSharp", "SymbolDoubleFlat",
            "SymbolDoubleSharp", "SymbolPar."
        },
    },
    AlternateNotation = {
        FCDistancePrefs = { "^Alternate" },
        FCMusicCharacterPrefs = {
            "VerticalTwoMeasureRepeatOffset", ".Slash",            
            "SymbolOneBarRepeat", "SymbolTwoBarRepeat",
        },
    },
    AugmentationDots = {
        FCMiscDocPrefs = { "AdjustDotForMultiVoices" },
        FCMusicCharacterPrefs = { "SymbolAugmentationDot" },
        FCDistancePrefs = { "^AugmentationDot" }
    },
    Barlines = {
        FCDistancePrefs = { "^Barline" },
        FCSizePrefs = { "Barline." },
        FCMiscDocPrefs = { ".Barline" }
    },
    Beams = {
        FCDistancePrefs = { "Beam." },
        FCSizePrefs = { "Beam." },
        FCMiscDocPrefs = { "Beam.", "IncludeRestsInFour", "AllowFloatingRests" }
    },
    Chords = {
        FCChordPrefs = { "." },
        FCMusicCharacterPrefs = { "Chord." },
        FCMiscDocPrefs = { "Chord.", "Fretboard." }
    },
    Clefs = {
        FCMiscDocPrefs = { "ClefResize", ".Clef" },
        FCDistancePrefs = { "^Clef" }
    },
    Flags = {
        FCMusicCharacterPrefs = { ".Flag", "VerticalSecondaryGroupAdjust" }
    },
    Fonts = {
        FCFontInfo = { 
            "^Lyric", "^Text", "^Time", ".Names", "Noteheads$", "^Chord",
            "^Alternate", "Dots$", "EndingRepeats",  "MeasureNumbers", 
            "Tablature",  "Accidentals",  "Flags", "Rests", "Clefs", 
            "KeySignatures", "MultimeasureRests", 
            "Tuplets", "Articulations", "Expressions"
        }
    },
    GraceNotes = {
        FCSizePrefs = { "Grace." },
        FCDistancePrefs = { "GraceNoteSpacing" },
        FCMiscDocPrefs = { "Grace." },
    },
    GridsAndGuides = {
        FCGridsGuidesPrefs = { "." }
    },
    KeySignatures = {
        FCDistancePrefs = { "^Key" },
        FCMusicCharacterPrefs = { "^SymbolKey" },
        FCMiscDocPrefs = { "^Key", "CourtesyKeySigAtSystemEnd" }
    },
    Layers = {
        FCLayerPrefs = { "." },
        FCMiscDocPrefs = { "ConsolidateRestsAcrossLayers" }
    },
    LinesAndCurves = {
        FCSizePrefs = { "^Ledger", "EnclosureThickness", "StaffLineThickness", "ShapeSlurTipWidth" },
        FCMiscDocPrefs = { "CurveResolution" }
    },
    Lyrics = {
        FCLyricsPrefs = { "." }
    },
    MultimeasureRests = {
        FCMultiMeasureRestPrefs = { "." }
    },
    MusicSpacing = {
        FCMusicSpacingPrefs = { "!Gutter$" },
        FCMiscDocPrefs = { "ScaleManualNotePositioning" }
    },
    NotesAndRests = {
        FCMiscDocPrefs = { "UseNoteShapes", "CrossStaffNotesInOriginal" },
        FCDistancePrefs = { "^Space" },
        FCMusicCharacterPrefs = { "^Symbol.*Rest$", "^Symbol.*Notehead$", "^Vertical.*Rest$"}
    },
    PianoBracesAndBrackets = {
        FCPianoBracePrefs = { "." },
        FCDistancePrefs = { "GroupBracketDefaultDistance" }
    },
    Repeats = {
        FCRepeatPrefs = { "." },
        FCMusicCharacterPrefs = { "RepeatDot$" }
    },
    Stems = {
        FCSizePrefs = { "Stem." },
        FCDistancePrefs = { "StemVerticalNoteheadOffset" },
        FCMiscDocPrefs = { "UseStemConnections", "DisplayReverseStemming" }
    },
    Text = {
        FCMiscDocPrefs = { "DateFormat", "SecondsInTimeStamp", "TextTabCharacters" },
    },
    Ties = {
        FCTiePrefs = { "." }
    },
    TimeSignatures = {
        FCMiscDocPrefs = { ".TimeSig", "TimeSigCompositeDecimals" },
        FCMusicCharacterPrefs = { ".TimeSig" },
        FCDistancePrefs = { "^TimeSig" },
    },
    Tuplets = {
        FCTupletPrefs = { "." }
    },
    Categories = {
        FCCategoryDefs = { "." }
    },
    PageFormat = {
        FCPageFormatPrefs = { "." }
    },
    SmartShapes = {        
        FCSmartShapePrefs = { "^Symbol", "^Hairpin", "^Line", "HookLength", "OctavesAsText", "ID$" },
        FCMusicCharacterPrefs = { ".Octave", "SymbolTrill", "SymbolWiggle" },
        ["FCFontInfo>Fonts"] = { "^SmartShape" },    -- incorporate a top-level menu from the source as a submenu
        ["FCSmartShapePrefs>SmartSlur"] = { "Slur." },
        ["FCSmartShapePrefs>GuitarBend"] = { "GuitarBend[^D]" },
        ["FCFontInfo>GuitarBend>Fonts"] = { "^Guitar" }
    },
    NamePositions = {
        ["FCGroupNamePositionPrefs>GroupNames"] = { "." },
        ["FCStaffNamePositionPrefs>StaffNames"] = { "." },
    },
    DefaultMusicFont = {
        ["FCFontInfo/Music"] = { "." }
    }
}

function is_pattern(s) return string.find(s, "[^%a%d]") end

function matches_negatable_pattern(s, pattern)
    local negate = pattern:sub(1, 1) == '!'
    if negate then pattern = pattern:sub(2) end

    local found = string.find(s, pattern)
    return (found ~= nil) ~= negate
end

function transform_to_friendly(all_raw_prefs)
    local function copy_items(source_table, dest_table, all_defs)
        local target

        local function copy_matching(pattern, category)
            local source = source_table[category];
            if string.find(category, "/") then
                local main, sub = string.match(category, "([%a%d]+)/([%a%d]+)")
                source = source_table[main][sub]
            end

            for k, v in pairs(source) do
                if matches_negatable_pattern(k, pattern) then target[k] = v end
            end
        end

        for category, locators in pairs(all_defs) do
            if string.find(category, ">") then
                target = dest_table
                for dest_menu in string.gmatch(category, ">(%a+)") do
                    if target[dest_menu] == nil then target[dest_menu] = {} end
                    target = target[dest_menu]
                end
                category = string.match(category, "^%a+")
            else
                target = dest_table
            end
            
            for _, locator in pairs(locators) do            
                if is_pattern(locator) then
                    copy_matching(locator, category)
                else
                    target[locator] = source_table[category][locator]
                end
            end
        end
    end

    local result = {}
    for transformed_category, all_defs in pairs(transform_definitions) do
        result[transformed_category] = {}
        copy_items(all_raw_prefs, result[transformed_category], all_defs)
    end
    return result
end

function transform_to_raw(prefs_to_import)
    local function copy_matching(import_items, raw_items, pattern)
        if not import_items then return end
        for k, _ in pairs(raw_items) do
            if matches_negatable_pattern(k, pattern) then
                if type(raw_items[k]) == "table" then                    
                    copy_matching(import_items[k], raw_items[k], ".")
                elseif import_items[k] ~= nil then       
                    raw_items[k] = import_items[k]
                end
            end
        end
    end

    local function copy_section(import_items, raw_items, locators)
        if raw_items then
            for _, locator in pairs(locators) do
                if not is_pattern(locator) then
                    locator = "^" .. locator .. "$"
                end
                copy_matching(import_items, raw_items, locator)
            end
        end
    end

    local raw_prefs = load_all_raw_prefs()
    for import_cat, import_values in pairs(prefs_to_import) do        
        local transform_defs = transform_definitions[import_cat]
        if transform_defs then
            for raw_cat, locators in pairs(transform_defs) do
                local source = import_values
                local dest = raw_prefs[raw_cat]
                if string.find(raw_cat, ">") then
                    local first = true
                    for segment in string.gmatch(raw_cat, "[%a%d]+") do
                        if first then 
                            dest = raw_prefs[segment]
                            first = false
                        else
                            source = source and source[segment]
                        end
                    end                    
                elseif string.find(raw_cat, "/") then
                    for segment in string.gmatch(raw_cat, "[%a%d]+") do
                        dest = raw_prefs[segment] or dest[segment]
                    end
                end
                copy_section(source, dest, locators)
            end
        end        
    end

    -- Copy new expression categories
    local cat_defs_to_import = prefs_to_import["Categories"]
    if cat_defs_to_import then
        local raw_cat_defs = raw_prefs["FCCategoryDefs"]
        for k, v in pairs(cat_defs_to_import) do
            if not raw_cat_defs[k] then raw_cat_defs[k] = v end
        end
    end

    return raw_prefs
end

-- endregion

-- region NORMALIZE

--[[
    Functions for normalizing/denormalizing between PDK native values and
    user-friendly values. Currently, "user-friendly" = EVPU for measurements;
    normalizing to a selectable unit may come later.

    The keys in the selector table are the names of PDK classes; the values are 
    arrays whose keys are either property names or Lua patterns matching multiple
    property names and whose values are string values indicating the normalizing
    function. The first character in this string indicates whether we need to 
    "d"ivide or "m"ultiply, and the rest of the string is the operand to be used.
    So "d64" means that we need to divide by 64 to normalize to EVPU (i.e., PDK
    units are EFIX).

    An optional parameter passed into modify_units_for_section indicates whether
    the operation should be inverted -- that is, whether we are denormalizing
    instead of normalizing and need to flip m/d operations.
  ]]

local norm_func_selectors = {
    FCDistancePrefs = {
        BarlineDoubleSpace = "d64",
        BarlineFinalSpace = "d64",
        StemVerticalNoteheadOffset = "d64"
    },
    FCGridsGuidesPrefs = {
        GravityZoneSize = "d64",
        GridDistance = "d64"
    },
    FCLyricsPrefs = {
        WordExtLineThickness = "d64"
    },
    FCMiscDocPrefs = {
        FretboardsResizeFraction = "d10000"
    },
    FCMusicCharacterPrefs = {
        DefaultStemLift = "d64",
        ["[HV].+Flag[UD]"] = "d64",        
    },
    FCPageFormatPrefs = {
        SystemStaffHeight = "d16"
    },
    FCPianoBracePrefs = {
        ["."] = "d10000"
    },
    FCRepeatPrefs = {
        ["Thickness$"] = "d64",
        SpaceBetweenLines = "d64",        
    },
    FCSizePrefs = {
        ["Thickness$"] = "d64",
        ShapeSlurTipWidth = "d10000",
    },
    FCSmartShapePrefs = {
        EngraverSlurMaxAngle = "d100",
        EngraverSlurMaxLift = "d64",
        EngraverSlurMaxStretchFixed = "d64",
        EngraverSlurMaxStretchPercent = "d100",
        EngraverSlurSymmetryPercent = "d100",
        HairpinLineWidth = "d64",
        ["^LineWidth$"] = "d64",
        SlurTipWidth = "d10000",
        Inset = "d20.48",
    },
    FCTiePrefs = {
        TipWidth = "d10000",
        ["tRelativeInset"] = "m100"
    },
    FCTupletPrefs = {
        BracketThickness = "d64",
        MaxSlope = "d10"
    }    
}

-- Applies an operation to items in a table whose keys match a pattern
function modify_units_for_selected(t, pattern, op)
    local operation, operand = string.match(op, "(.)(.+)")
    for key, value in pairs(t) do
        if type(value) == "table" then 
            modify_units_for_selected(value, pattern, op)
        elseif string.find(key, pattern) then
            local new_value = operation == "m" and (value * operand) or (value / operand)
            t[key] = new_value
        end
    end
end    

function modify_units_for_raw_section(section_table, tag, invert)
    local selectors = norm_func_selectors[tag]
    if selectors then
        for pattern, op in pairs(selectors) do
            if invert then 
                op = (op:sub(1, 1) == "m" and "d" or "m") .. op:sub(2)
            end
            modify_units_for_selected(section_table, pattern, op)
        end
    end
end

--[[
    Given a table of raw prefs and the tag for that table
    (i.e., PDK class name), normalize or denormalize the units.
  ]]
function normalize_units_for_raw_section(section_table, tag)
    modify_units_for_raw_section(section_table, tag, false)
end

function denormalize_units_for_raw_section(section_table, tag)
    modify_units_for_raw_section(section_table, tag, true)
end

-- endregion



--[[
    Simple implementation of JSON serialization because we know
    our inputs are simple.

    Can't use a JSON library because we need to keep keys in order
    so that the output can be diffed.
  ]]
function get_as_ordered_json(t, indent_level, in_array)
    local function get_last_key(this_table)
        local result
        for k, _ in pairsbykeys(this_table) do result = k end
        return result
    end

    local function quote_and_escape(s)
        s = string.gsub(s, "\\", "\\\\")
        s = string.gsub(s, '"', '\\"')
        return string.format('"%s"', s)
    end

    
    indent_level = indent_level or 0
    local result = {}

    table.insert(result, (in_array and '[' or '{') .. '\n')
    indent_level = indent_level + 1
    local indent = string.rep(" ", indent_level * 2) 

    local last_key = get_last_key(t)
    for key, val in pairsbykeys(t) do
        local maybe_comma_plus_newline = key ~= last_key and ',\n' or '\n'    
        local maybe_element_name = in_array and '' or quote_and_escape(key) .. ': '
        if type(val) == "table" then 
            local val_is_array = val[1] ~= nil
            local new_line = table.concat({
                indent,
                maybe_element_name,
                get_as_ordered_json(val, indent_level, val_is_array),
                indent,
                val_is_array and ']' or '}',
                maybe_comma_plus_newline
            })
            table.insert(result, new_line)
        elseif type(val) == "string" or type(val) == "number" or type(val) == "boolean" then
            local new_line = table.concat({
                indent,
                maybe_element_name,
                type(val) == "string" and quote_and_escape(val) or tostring(val),
                maybe_comma_plus_newline
            })            
            table.insert(result, new_line)
        end
    end

    if indent_level == 1 then
        table.insert(result, "}")
    end 
    return table.concat(result)
end

function insert_header(prefs_table, document, description)
    local file_path = finale.FCString()
    document:GetPath(file_path)
    local key = "@Meta"
    prefs_table[key] = {
        MusicFile = file_path.LuaString,
        Date =  os.date(),
        FinaleVersion = simplify_finale_version(finenv.FinaleVersion),
        PluginVersion = finaleplugin.Version,
        Description = description
    }
    if debug.raw_categories then 
        prefs_table[key].Transformed = false 
    end
    if not debug.raw_units then
        prefs_table[key].DefaultUnit = "ev"
    end
end

function get_current_document()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    return documents:FindCurrent()
end

function open_file(file_path, mode)
    local file = io.open(file_path, mode)
    if not file then
        finenv.UI():AlertError("Unable to open " .. file_path .. ". Please check folder permissions.", "")
    else
        return file        
    end
end

function options_import_from_json()
    local file_to_open = do_file_open_dialog(get_current_document())
    if file_to_open then    
        local file = open_file(file_to_open, "r")
        if file then
            local prefs_json = file:read("*a")
            file:close()
            local prefs_to_import = json.decode(prefs_json)
            
            if confirm_file_import(prefs_to_import["@Meta"]) then
                local raw_prefs = transform_to_raw(prefs_to_import)
                save_all_raw_prefs(raw_prefs)
                finenv.UI():AlertInfo("Done.", "Import Settings")
            end
        end
    end
end

function options_save_as_json()
    local document = get_current_document()
    local file_to_write = do_save_as_dialog(document)
    if file_to_write then
        local file = open_file(file_to_write, "w")
        if file then
            local raw_prefs = load_all_raw_prefs()
            local prefs_to_save = debug.raw_categories and raw_prefs or transform_to_friendly(raw_prefs)
            insert_header(prefs_to_save, document, get_description())
            file:write(get_as_ordered_json(prefs_to_save))
            file:close()
        end
    end
end



if action == "export" then
    options_save_as_json()
elseif action == "import" then
    options_import_from_json()
end

function plugindef()
    finaleplugin.RequireScore = false
    finaleplugin.RequireSelection = false
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.2.1"
    finaleplugin.Date = "2023-02-12"
    finaleplugin.CategoryTags = "Report"   
    finaleplugin.Id = "9c05a4c4-9508-4608-bb1b-2819cba96101" 
    finaleplugin.RevisionNotes = [[
        v1.1.2      First public release
        v1.2.1      Add Grid/Guide snap-tos; better organization of SmartShapes
    ]]
    finaleplugin.Notes = [[
        While other plugins exist that let you copy document options from one document to another, 
        this script saves the options from the current document in an organized human-readable form, as a 
        JSON file. You can then use a diff program to compare the JSON files generated from 
        two Finale documents, or you can keep track of how the settings in a document have changed 
        over time.
        
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

local normalize_units = true
local transform_categories = true

local mixin = require('library.mixin')

local fcstr = function(str)
    return mixin.FCMString():SetLuaString(str)
end

function get_file_options_tag()
    local temp_table = {}
    if not transform_categories then table.insert(temp_table, "raw prefs") end
    if not normalize_units then table.insert(temp_table, "raw units") end
    local result = table.concat(temp_table, ", ")
    if #result > 0 then result = " - " .. result end
    return result
end

function do_save_as_dialog(document)
    local text_extension = ".json"
    local filter_text = "JSON files"

    local path_name = finale.FCString()
    local file_name = mixin.FCMString()
    local file_path = finale.FCString()
    document:GetPath(file_path)
    file_path:SplitToPathAndFile(path_name, file_name)
    local full_file_name = file_name.LuaString
    local extension = mixin.FCMString()
                            :SetLuaString(file_name.LuaString)
                            :ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("."..extension.LuaString))
    end
    file_name:AppendLuaString(" settings")
            :AppendLuaString(get_file_options_tag())
            :AppendLuaString(text_extension)
    local save_dialog = mixin.FCMFileSaveAsDialog(finenv.UI())
            :SetWindowTitle(fcstr("Save "..full_file_name.." As"))
            :AddFilter(fcstr("*"..text_extension), fcstr(filter_text))
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

function add_props(result, obj, tag)
    local props = dumpproperties(obj)
    result[tag] = props
end

-- region LOADERS

function load_page_format_prefs(prefs, table)
    prefs:LoadScore()
    add_props(table, prefs, "Score")
    prefs:LoadParts()
    add_props(table, prefs, "Parts")
end

function load_name_position_prefs(prefs, table)
    prefs:LoadFull()
    add_props(table, prefs, "Full")
    prefs:LoadAbbreviated()
    add_props(table, prefs, "Abbreviated")
end

function load_layer_prefs(prefs, table)
    for i = 0, 3 do
        prefs:Load(i)
        add_props(table, prefs, "Layer" .. i + 1)
    end
end

local font_prefs_table = {
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

function load_font_prefs(prefs, table)
    for pref_type, tag in pairs(font_prefs_table) do
        prefs:LoadFontPrefs(pref_type)
        add_props(table, prefs, tag)
    end
end

function load_tie_placement_prefs(prefs, table)
    local tie_placement_table = {
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

    for placement_type, tag in pairs(tie_placement_table) do
        prefs:Load(placement_type)
        
        local t = {}
        for _, name in pairs(prop_names) do
            t[name] = prefs['Get' .. name](prefs, placement_type)
        end

        table[tag] = t
    end
end

function load_tie_contour_prefs(prefs, table)
    local tie_contour_table = {
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
    
    for contour_type, tag in pairs(tie_contour_table) do
        prefs:Load(contour_type)

        local t = {}
        for _, name in pairs(prop_names) do
            t[name] = prefs['Get' .. name](prefs, contour_type)
        end

        table[tag] = t
    end
end

function load_base_prefs(prefs, table)
    prefs:Load(1)
    for k, v in pairs(dumpproperties(prefs)) do
        table[k] = v
    end
end

function load_tie_prefs(prefs, table)
    load_base_prefs(prefs, table)

    function load_sub_prefs(sub_prefs, loader, tag)
        local t = {}
        loader(sub_prefs, t)
        table[tag] = t
    end

    load_sub_prefs(prefs:CreateTieContourPrefs(), load_tie_contour_prefs, "TieContours")
    load_sub_prefs(prefs:CreateTiePlacementPrefs(), load_tie_placement_prefs, "TiePlacement")
end

function load_category_prefs(prefs, table)
    for cat in loadall(prefs) do
        if cat:IsDefaultMiscellaneous() then
            goto cat_continue
        end

        local tag = cat:CreateName().LuaString
        tag = tag:gsub(" ", "")
        add_props(table, cat, tag)

        local font = finale.FCFontInfo()
        local font_table = {}
        table[tag]["Fonts"] = font_table

        local font_types = { "Text", "Music", "Number" }
        for _, t in pairs(font_types) do
            if cat["Get" .. t .. "FontInfo"](cat, font) then
                add_props(font_table, font, t)
            end
        end

        ::cat_continue::
    end
end

function load_smart_shape_prefs(prefs, table)
    load_base_prefs(prefs, table)

    local contour_prefs = prefs:CreateSlurContourPrefs()
    local contour_table = {}
    table["SlurContours"] = contour_table

    local span_types = { 'Short', 'Medium', 'Long', 'ExtraLong' }
    local prop_names = { 'Span', 'Inset', 'Height' }
    
    for _, type in pairs(span_types) do
        local t = {}
        for _, name in pairs(prop_names) do
            t[name] = contour_prefs["Get" .. type .. name](contour_prefs)
        end
        contour_table[type] = t
    end
end

function load_grid_prefs(prefs, table)
    load_base_prefs(prefs, table)

    local guide_types = { "Horizontal", "Vertical" }
    for _, type in pairs(guide_types) do
        local guides = prefs["Get" .. type .. "Guides"](prefs)
        table[type .. "GuideCount"] = guides.Count
    end

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

    table["SnapToGrid"] = {}
    table["SnapToGuide"] = {}
    for item, name in pairs(snap_items) do
        table["SnapToGrid"][name] = prefs:GetGridSnapToItem(item)
        table["SnapToGuide"][name] = prefs:GetGuideSnapToItem(item)
    end
end

-- endregion

-- region RAW PREFS

local raw_prefs_table = {
    { prefs = finale.FCCategoryDefs(), loader = load_category_prefs },
    { prefs = finale.FCChordPrefs() },
    { prefs = finale.FCDistancePrefs() },
    { prefs = finale.FCFontInfo(), loader = load_font_prefs },
    { prefs = finale.FCGridsGuidesPrefs(), loader = load_grid_prefs },
    { prefs = finale.FCGroupNamePositionPrefs(), loader = load_name_position_prefs },
    { prefs = finale.FCLayerPrefs(), loader = load_layer_prefs },
    { prefs = finale.FCLyricsPrefs() }, 
    { prefs = finale.FCMiscDocPrefs() },
    { prefs = finale.FCMultiMeasureRestPrefs() },
    { prefs = finale.FCMusicCharacterPrefs() },
    { prefs = finale.FCMusicSpacingPrefs() },
    { prefs = finale.FCPageFormatPrefs(), loader = load_page_format_prefs },
    { prefs = finale.FCPianoBracePrefs() },
    { prefs = finale.FCPlaybackPrefs() },
    { prefs = finale.FCRepeatPrefs() },
    { prefs = finale.FCSizePrefs() },
    { prefs = finale.FCSmartShapePrefs(), loader = load_smart_shape_prefs },
    { prefs = finale.FCStaffNamePositionPrefs(), loader = load_name_position_prefs },     
    { prefs = finale.FCTiePrefs(), loader = load_tie_prefs },
    { prefs = finale.FCTupletPrefs() },
}

function load_all_raw_prefs()
    local result = {}
    
    for _, obj in ipairs(raw_prefs_table) do
        local tag = obj.prefs:ClassName()
        if obj.loader == nil then
            obj.prefs:Load(1)
            add_props(result, obj.prefs, tag)
        else
            result[tag] = {}
            obj.loader(obj.prefs, result[tag])
        end
        if normalize_units then
            normalize_units_for_section(result[tag], tag)
        end
    end

    return result
end

-- endregion

-- region TRANSFORM

local transform_table = {
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
            "Tuplets", "Articulations", 
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

function copy_items(source_table, dest_table, refs)
    local target

    function copy_matching(pattern, category)
        local source = source_table[category];
        if string.find(category, "/") then
            local main, sub = string.match(category, "([%a%d]+)/([%a%d]+)")
            source = source_table[main][sub]
        end

        local negate = pattern:sub(1, 1) == '!'
        if negate then pattern = pattern:sub(2) end

        for k, v in pairs(source) do
            local found = string.find(k, pattern)
            if (found ~= nil) ~= negate then target[k]= v end
        end
    end

    for source_menu, items in pairs(refs) do
        if string.find(source_menu, ">") then
            target = dest_table
            for dest_menu in string.gmatch(source_menu, ">(%a+)") do
                if target[dest_menu] == nil then target[dest_menu] = {} end
                target = target[dest_menu]
            end
            source_menu = string.match(source_menu, "^%a+")
        else
            target = dest_table
        end
        
        for _, item in pairs(items) do            
            if string.find(item, "[^%a%d]") then
                copy_matching(item, source_menu)
            else
                target[item] = source_table[source_menu][item]
            end
        end
    end
end

function apply_transform(all_raw_prefs)
    local result = {}
    for transformed_category, refs in pairs(transform_table) do
        result[transformed_category] = {}
        copy_items(all_raw_prefs, result[transformed_category], refs)
    end
    return result
end

-- endregion

-- region NORMALIZE

local normalize_funcs = {
    d64 = function(value) return value / 64 end,
    d10k = function(value) return value / 10000 end,
    d16 = function(value) return value / 16 end,
    d100 = function(value) return value / 100 end,
    d10 = function(value) return value / 10 end,
    d20_48 = function(value) return value / 20.48 end,
    m100 = function(value) return value * 100 end,
}

local norm_func_selectors = {
    FCDistancePrefs = {
        BarlineDoubleSpace = normalize_funcs.d64,
        BarlineFinalSpace = normalize_funcs.d64,
        StemVerticalNoteheadOffset = normalize_funcs.d64
    },
    FCGridsGuidesPrefs = {
        GravityZoneSize = normalize_funcs.d64,
        GridDistance = normalize_funcs.d64
    },
    FCLyricsPrefs = {
        WordExtLineThickness = normalize_funcs.d64
    },
    FCMiscDocPrefs = {
        FretboardsResizeFraction = normalize_funcs.d10k
    },
    FCMusicCharacterPrefs = {
        DefaultStemLift = normalize_funcs.d64,
        ["[HV].+Flag[UD]"] = normalize_funcs.d64,        
    },
    FCPageFormatPrefs = {
        SystemStaffHeight = normalize_funcs.d16
    },
    FCPianoBracePrefs = {
        ["."] = normalize_funcs.d10k
    },
    FCRepeatPrefs = {
        ["Thickness$"] = normalize_funcs.d64,
        SpaceBetweenLines = normalize_funcs.d64,        
    },
    FCSizePrefs = {
        ["Thickness$"] = normalize_funcs.d64,
        ShapeSlurTipWidth = normalize_funcs.d10k,
    },
    FCSmartShapePrefs = {
        EngraverSlurMaxAngle = normalize_funcs.d100,
        EngraverSlurMaxLift = normalize_funcs.d64,
        EngraverSlurMaxStretchFixed = normalize_funcs.d64,
        EngraverSlurMaxStretchPercent = normalize_funcs.d100,
        EngraverSlurSymmetryPercent = normalize_funcs.d100,
        HairpinLineWidth = normalize_funcs.d64,
        ["^LineWidth$"] = normalize_funcs.d64,
        SlurTipWidth = normalize_funcs.d10k,
        Inset = normalize_funcs.d20_48,
    },
    FCTiePrefs = {
        TipWidth = normalize_funcs.d10k,
        ["tRelativeInset"] = normalize_funcs.m100
    },
    FCTupletPrefs = {
        BracketThickness = normalize_funcs.d64,
        MaxSlope = normalize_funcs.d10
    }    
}

function normalize_units_for_table(t, pattern, func)
    for key, value in pairs(t) do
        if type(value) == "table" then 
            normalize_units_for_table(value, pattern, func)
        elseif string.find(key, pattern) then
            t[key] = func(value)
        end
    end
end    

function normalize_units_for_section(section_table, section_tag)
    local selectors = norm_func_selectors[section_tag]
    if selectors then
        for pattern, func in pairs(selectors) do            
            normalize_units_for_table(section_table, pattern, func)
        end
    end
end

-- endregion

function get_last_key(t)
    local result
    for k, _ in pairsbykeys(t) do result = k end
    return result
end

function quote_and_escape(s)
    s = string.gsub(s, "\\", "\\\\")
    s = string.gsub(s, '"', '\\"')
    return string.format('"%s"', s)
end

-- Simple implementation because we know our inputs are simple
-- Can't use a json library because we need to keep keys in order
function get_as_ordered_json(t, indent_level, in_array)
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
            table.insert(result, indent)
            table.insert(result, maybe_element_name)
            table.insert(result, get_as_ordered_json(val, indent_level, val_is_array))
            table.insert(result, indent)
            table.insert(result, val_is_array and ']' or '}')
            table.insert(result, maybe_comma_plus_newline)
        elseif type(val) == "string" or type(val) == "number" or type(val) == "boolean" then
            table.insert(result, indent)
            table.insert(result, maybe_element_name)
            table.insert(result, type(val) == "string" and quote_and_escape(val) or tostring(val))
            table.insert(result, maybe_comma_plus_newline)
        end
    end

    if indent_level == 1 then
        table.insert(result, "}")
    end 
    return table.concat(result)
end

function insert_header(prefs_table, document)
    local file_path = finale.FCString()
    document:GetPath(file_path)
    local key = "@Meta"
    prefs_table[key] = {
      File = file_path.LuaString,
      Date =  os.date(),
      FinaleVersion = finenv.FinaleVersion,
      PluginVersion = finaleplugin.Version
    }
    if not transform_categories then 
        prefs_table[key].Transformed = false 
    end
    if normalize_units then
        prefs_table[key].DefaultUnit = "ev"
    end
end

function options_save_as_json()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    local document = documents:FindCurrent()

    local file_to_write = do_save_as_dialog(document)
    if not file_to_write then
        return
    end

    local file = io.open(file_to_write, "w")
    if not file then
        finenv.UI():AlertError("Unable to open " .. file_to_write .. ". Please check folder permissions.", "")
        return
    end

    local raw_prefs = load_all_raw_prefs()
    local prefs_to_save = transform_categories and apply_transform(raw_prefs) or raw_prefs
    insert_header(prefs_to_save, document)
    file:write(get_as_ordered_json(prefs_to_save))
    file:close()
end

options_save_as_json()

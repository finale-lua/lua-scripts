function plugindef()
    finaleplugin.RequireScore = false
    finaleplugin.RequireSelection = false
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1.1"
    finaleplugin.Date = "2023-02-09"
    finaleplugin.CategoryTags = "Report"   
    finaleplugin.Id = "9c05a4c4-9508-4608-bb1b-2819cba96101" 
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
end

-- endregion

-- region RAW PREFS

local raw_pref_names = {
    CATEGORIES = "Categories",
    CHORDS = "Chords",
    DISTANCES = "Distances",
    FONTS = "Fonts",
    GRIDS = "GridsAndGuides",
    GROUPNAMEPOS = "GroupNamePositions",
    LAYERS = "Layers",
    LYRICS = "Lyrics",
    MISCDOC = "MiscellaneousDocument",
    MMRESTS = "MultimeasureRests",
    MUSICCHAR = "MusicCharacters",
    MUSICSPACING = "MusicSpacing",
    PAGEFORMAT = "PageFormat",
    PIANOBRACES = "PianoBraces",
    PLAYBACK = "Playback",
    REPEATS = "Repeats",
    SIZES = "Sizes",
    SMARTSHAPES = "SmartShapes",
    STAFFNAMEPOS = "StaffNamePositions",
    TIES = "Ties",
    TUPLETS = "Tuplets"
}

local raw_prefs_table = {
    { prefs = finale.FCCategoryDefs(), tag = raw_pref_names.CATEGORIES, loader = load_category_prefs },
    { prefs = finale.FCChordPrefs(), tag = raw_pref_names.CHORDS },
    { prefs = finale.FCDistancePrefs(), tag = raw_pref_names.DISTANCES },
    { prefs = finale.FCFontInfo(), tag = raw_pref_names.FONTS, loader = load_font_prefs },
    { prefs = finale.FCGridsGuidesPrefs(), tag = raw_pref_names.GRIDS, loader = load_grid_prefs },
    { prefs = finale.FCGroupNamePositionPrefs(), tag = raw_pref_names.GROUPNAMEPOS, loader = load_name_position_prefs },
    { prefs = finale.FCLayerPrefs(), tag = raw_pref_names.LAYERS, loader = load_layer_prefs },
    { prefs = finale.FCLyricsPrefs(), tag = raw_pref_names.LYRICS }, 
    { prefs = finale.FCMiscDocPrefs(), tag = raw_pref_names.MISCDOC },
    { prefs = finale.FCMultiMeasureRestPrefs(), tag = raw_pref_names.MMRESTS },
    { prefs = finale.FCMusicCharacterPrefs(), tag = raw_pref_names.MUSICCHAR },
    { prefs = finale.FCMusicSpacingPrefs(), tag = raw_pref_names.MUSICSPACING },
    { prefs = finale.FCPageFormatPrefs(), tag = raw_pref_names.PAGEFORMAT, loader = load_page_format_prefs },
    { prefs = finale.FCPianoBracePrefs(), tag = raw_pref_names.PIANOBRACES },
    { prefs = finale.FCPlaybackPrefs(), tag = raw_pref_names.PLAYBACK },
    { prefs = finale.FCRepeatPrefs(), tag = raw_pref_names.REPEATS },
    { prefs = finale.FCSizePrefs(), tag = raw_pref_names.SIZES },
    { prefs = finale.FCSmartShapePrefs(), tag = raw_pref_names.SMARTSHAPES, loader = load_smart_shape_prefs },
    { prefs = finale.FCStaffNamePositionPrefs(), tag = raw_pref_names.STAFFNAMEPOS, loader = load_name_position_prefs },     
    { prefs = finale.FCTiePrefs(), tag = raw_pref_names.TIES, loader = load_tie_prefs },
    { prefs = finale.FCTupletPrefs(), tag = raw_pref_names.TUPLETS },
}

function load_all_raw_prefs()
    local result = {}
    
    for _, obj in ipairs(raw_prefs_table) do
        if obj.loader == nil then
            obj.prefs:Load(1)
            add_props(result, obj.prefs, obj.tag)
        else
            result[obj.tag] = {}
            obj.loader(obj.prefs, result[obj.tag])
        end
        if normalize_units then
            normalize_units_for_section(result[obj.tag], obj.tag)
        end
    end

    return result
end

-- endregion

-- region TRANSFORM

local transform_table = {
    Accidentals = { 
        [raw_pref_names.DISTANCES]  = { "^Accidental" },
        [raw_pref_names.MUSICSPACING] = { "AccidentalsGutter" },
        [raw_pref_names.MUSICCHAR] = {
            "SymbolNatural", "SymbolFlat", "SymbolSharp", "SymbolDoubleFlat",
            "SymbolDoubleSharp", "SymbolPar."
        },
    },
    AlternateNotation = {
        [raw_pref_names.DISTANCES] = { "^Alternate" },
        [raw_pref_names.MUSICCHAR] = {
            "VerticalTwoMeasureRepeatOffset", ".Slash",            
            "SymbolOneBarRepeat", "SymbolTwoBarRepeat",
        },
    },
    AugmentationDots = {
        [raw_pref_names.MISCDOC] = { "AdjustDotForMultiVoices" },
        [raw_pref_names.MUSICCHAR] = { "SymbolAugmentationDot" },
        [raw_pref_names.DISTANCES] = { "^AugmentationDot" }
    },
    Barlines = {
        [raw_pref_names.DISTANCES] = { "^Barline" },
        [raw_pref_names.SIZES] = { "Barline." },
        [raw_pref_names.MISCDOC] = { ".Barline" }
    },
    Beams = {
        [raw_pref_names.DISTANCES] = { "Beam." },
        [raw_pref_names.SIZES] = { "Beam." },
        [raw_pref_names.MISCDOC] = { "Beam.", "IncludeRestsInFour", "AllowFloatingRests" }
    },
    Chords = {
        [raw_pref_names.CHORDS] = { "." },
        [raw_pref_names.MUSICCHAR] = { "Chord." },
        [raw_pref_names.MISCDOC] = { "Chord.", "Fretboard." }
    },
    Clefs = {
        [raw_pref_names.MISCDOC] = { "ClefResize", ".Clef" },
        [raw_pref_names.DISTANCES] = { "^Clef" }
    },
    Flags = {
        [raw_pref_names.MUSICCHAR] = { ".Flag", "VerticalSecondaryGroupAdjust" }
    },
    Fonts = {
        [raw_pref_names.FONTS] = { 
            "^Lyric", "^Text", "^Time", ".Names", "Noteheads$", "^Chord",
            "^Alternate", "Dots$", "EndingRepeats",  "MeasureNumbers", 
            "Tablature",  "Accidentals",  "Flags", "Rests", "Clefs", 
            "KeySignatures", "MultimeasureRests", 
            "Tuplets", "Articulations", 
        }
    },
    GraceNotes = {
        [raw_pref_names.SIZES] = { "Grace." },
        [raw_pref_names.DISTANCES] = { "GraceNoteSpacing" },
        [raw_pref_names.MISCDOC] = { "Grace." },
    },
    GridsAndGuides = {
        [raw_pref_names.GRIDS] = { "." }
    },
    KeySignatures = {
        [raw_pref_names.DISTANCES] = { "^Key" },
        [raw_pref_names.MUSICCHAR] = { "^SymbolKey" },
        [raw_pref_names.MISCDOC] = { "^Key", "CourtesyKeySigAtSystemEnd" }
    },
    Layers = {
        [raw_pref_names.LAYERS] = { "." },
        [raw_pref_names.MISCDOC] = { "ConsolidateRestsAcrossLayers" }
    },
    LinesAndCurves = {
        [raw_pref_names.SIZES] = { "^Ledger", "EnclosureThickness", "StaffLineThickness", "ShapeSlurTipWidth" },
        [raw_pref_names.MISCDOC] = { "CurveResolution" }
    },
    Lyrics = {
        [raw_pref_names.LYRICS] = { "." }
    },
    MultimeasureRests = {
        [raw_pref_names.MMRESTS] = { "." }
    },
    MusicSpacing = {
        [raw_pref_names.MUSICSPACING] = { "!Gutter$" },
        [raw_pref_names.MISCDOC] = { "ScaleManualNotePositioning" }
    },
    NotesAndRests = {
        [raw_pref_names.MISCDOC] = { "UseNoteShapes", "CrossStaffNotesInOriginal" },
        [raw_pref_names.DISTANCES] = { "^Space" },
        [raw_pref_names.MUSICCHAR] = { "^Symbol.*Rest$", "^Symbol.*Notehead$", "^Vertical.*Rest$"}
    },
    PianoBracesAndBrackets = {
        [raw_pref_names.PIANOBRACES] = { "." },
        [raw_pref_names.DISTANCES] = { "GroupBracketDefaultDistance" }
    },
    Repeats = {
        [raw_pref_names.REPEATS] = { "." },
        [raw_pref_names.MUSICCHAR] = { "RepeatDot$" }
    },
    Stems = {
        [raw_pref_names.SIZES] = { "Stem." },
        [raw_pref_names.DISTANCES] = { "StemVerticalNoteheadOffset" },
        [raw_pref_names.MISCDOC] = { "UseStemConnections", "DisplayReverseStemming" }
    },
    Text = {
        [raw_pref_names.MISCDOC] = { "DateFormat", "SecondsInTimeStamp", "TextTabCharacters" },
    },
    Ties = {
        [raw_pref_names.TIES] = { "." }
    },
    TimeSignatures = {
        [raw_pref_names.MISCDOC] = { ".TimeSig", "TimeSigCompositeDecimals" },
        [raw_pref_names.MUSICCHAR] = { ".TimeSig" },
        [raw_pref_names.DISTANCES] = { "^TimeSig" },
    },
    Tuplets = {
        [raw_pref_names.TUPLETS] = { "." }
    },
    Categories = {
        [raw_pref_names.CATEGORIES] = { "." }
    },
    PageFormat = {
        [raw_pref_names.PAGEFORMAT] = { "." }
    },
    SmartShapes = {
        [raw_pref_names.SMARTSHAPES] = { "." },
        [raw_pref_names.MUSICCHAR] = { ".Octave", "SymbolTrill", "SymbolWiggle" },
        [">" .. raw_pref_names.FONTS] = { "^SmartShape", "^Guitar" }    -- incorporate a top-level menu from the source as a submenu
    },
    NamePositions = {
        [">" .. raw_pref_names.GROUPNAMEPOS] = { "." },
        [">" .. raw_pref_names.STAFFNAMEPOS] = { "." },
    },
    DefaultMusicFont = {
        [raw_pref_names.FONTS .. "/Music"] = { "." }
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
        if source_menu:sub(1, 1) == ">" then
            source_menu = source_menu:sub(2)        
            dest_table[source_menu] = {}
            target = dest_table[source_menu]    
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
    [raw_pref_names.DISTANCES] = {
        BarlineDoubleSpace = normalize_funcs.d64,
        BarlineFinalSpace = normalize_funcs.d64,
        StemVerticalNoteheadOffset = normalize_funcs.d64
    },
    [raw_pref_names.GRIDS] = {
        GravityZoneSize = normalize_funcs.d64,
        GridDistance = normalize_funcs.d64
    },
    [raw_pref_names.LYRICS] = {
        WordExtLineThickness = normalize_funcs.d64
    },
    [raw_pref_names.MISCDOC] = {
        FretboardsResizeFraction = normalize_funcs.d10k
    },
    [raw_pref_names.MUSICCHAR] = {
        DefaultStemLift = normalize_funcs.d64,
        ["[HV].+Flag[UD]"] = normalize_funcs.d64,        
    },
    [raw_pref_names.PAGEFORMAT] = {
        SystemStaffHeight = normalize_funcs.d16
    },
    [raw_pref_names.PIANOBRACES] = {
        ["."] = normalize_funcs.d10k
    },
    [raw_pref_names.REPEATS] = {
        ["Thickness$"] = normalize_funcs.d64,
        SpaceBetweenLines = normalize_funcs.d64,        
    },
    [raw_pref_names.SIZES] = {
        ["Thickness$"] = normalize_funcs.d64,
        ShapeSlurTipWidth = normalize_funcs.d10k,
    },
    [raw_pref_names.SMARTSHAPES] = {
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
    [raw_pref_names.TIES] = {
        TipWidth = normalize_funcs.d10k,
        ["tRelativeInset"] = normalize_funcs.m100
    },
    [raw_pref_names.TUPLETS] = {
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

-- Simple implementation because we know our inputs are simple
-- Can't use a json library because we need to keep keys in order
function get_as_json(t, indent)
    indent = indent or 0
    local result = {}

    table.insert(result, '{\n')
    indent = indent + 1
    local spaces = string.rep(" ", indent * 2) 

    local last_key = get_last_key(t)
    for key, val in pairsbykeys(t) do
        local maybe_comma = key ~= last_key and ',' or ''
        if type(val) == "table" then 
            table.insert(result, string.format('%s"%s": ', spaces, key))
            table.insert(result, get_as_json(val, indent))
            table.insert(result, string.format("%s}%s\n",
                spaces,
                maybe_comma
            ))
        else 
            table.insert(result, string.format('%s"%s": %s%s\n',
                spaces, 
                key, 
                type(val) == "string" and string.format('"%s"', val) or tostring(val),
                maybe_comma
            ))
        end
    end

    if indent == 1 then
        table.insert(result, "}")
    end 
    return table.concat(result)
end

function insert_header(prefs_table, document)
    local file_path = finale.FCString()
    document:GetPath(file_path)
    local key = "@Meta"
    prefs_table[key] = {
      File = string.gsub(file_path.LuaString, "\\", "\\\\"),
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
    file:write(get_as_json(prefs_to_save))
    file:close()
end

options_save_as_json()

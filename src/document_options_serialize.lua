function plugindef()
    finaleplugin.RequireScore = false
    finaleplugin.RequireSelection = false
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "2023-02-07"
    finaleplugin.CategoryTags = "Report"   
    finaleplugin.Id = "9c05a4c4-9508-4608-bb1b-2819cba96101" 
    finaleplugin.Notes = [[
        While other plugins exist that let you copy document options from one document to another, 
        this script saves the options from the current document in an organized human-readable form, as a 
        YAML (text) file. You can then use a diff program to compare the YAML files generated from 
        two Finale documents, or you can keep track of how the settings in a document have changed 
        over time.
        
        The focus is on document-specific settings, rather than program-wide ones, and in particular on 
        the ones that affect the look of a document. Most of these come from the Document Options dialog 
        in Finale, although some come from the Category Designer, the Page Format dialog, and the 
        SmartShape menu.

        Note that numbers for measurements don't always represent the units you might expect, but they
        will be consistent between documents. For example, most measurements are in EVPUs (1 EVPU is 
        1/288 of an inch, 1/24 of a space, or 1/4 of a point), but some are in EFIX (1 EFIX is 1/64 of an 
        EVPU). Even within one group of settings, like Beams, the length of a broken beam is in EVPU, but 
        the beam thickness is in EFIX. This is just the way that Finale stores these values internally.
    ]]

    return "Serialize Document Options...", "", "Saves all current document options to a YAML file"
end

local save_raw_file = false
local mixin = require('library.mixin')

function add_props(result, obj, tag)
    local props = dumpproperties(obj)
    result[tag] = props
end

local fcstr = function(str)
    return mixin.FCMString():SetLuaString(str)
end

function do_save_as_dialog(document)
    local text_extension = ".yaml"
    local filter_text = "YAML files"

    local path_name = finale.FCString()
    local file_name = finale.FCString()
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
    if save_raw_file then file_name:AppendLuaString(" - raw") end
    file_name:AppendLuaString(text_extension)
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

local prefs_table = {
    { prefs = finale.FCCategoryDefs(), tag = "Categories", loader = load_category_prefs },
    { prefs = finale.FCChordPrefs(), tag = "Chords" },
    { prefs = finale.FCDistancePrefs(), tag = "Distances" },
    { prefs = finale.FCFontInfo(), tag = "Fonts", loader = load_font_prefs },
    { prefs = finale.FCGridsGuidesPrefs(), tag = "GridsAndGuides", loader = load_grid_prefs },
    { prefs = finale.FCGroupNamePositionPrefs(), tag = "GroupNamePositions", loader = load_name_position_prefs },
    { prefs = finale.FCLayerPrefs(), tag = "Layers", loader = load_layer_prefs },
    { prefs = finale.FCLyricsPrefs(), tag = "Lyrics" }, 
    { prefs = finale.FCMiscDocPrefs(), tag = "MiscellaneousDocument" },
    { prefs = finale.FCMultiMeasureRestPrefs(), tag = "MultimeasureRests" },
    { prefs = finale.FCMusicCharacterPrefs(), tag = "MusicCharacters" },
    { prefs = finale.FCMusicSpacingPrefs(), tag = "MusicSpacing" },
    { prefs = finale.FCPageFormatPrefs(), tag = "PageFormat", loader = load_page_format_prefs },
    { prefs = finale.FCPianoBracePrefs(), tag = "PianoBracesAndBrackets" },
    { prefs = finale.FCPlaybackPrefs(), tag = "Playback" },
    { prefs = finale.FCRepeatPrefs(), tag = "Repeats" },
    { prefs = finale.FCSizePrefs(), tag = "Sizes" },
    { prefs = finale.FCSmartShapePrefs(), tag = "SmartShapes", loader = load_smart_shape_prefs },
    { prefs = finale.FCStaffNamePositionPrefs(), tag = "StaffNamePositions", loader = load_name_position_prefs },     
    { prefs = finale.FCTiePrefs(), tag = "Ties", loader = load_tie_prefs },
    { prefs = finale.FCTupletPrefs(), tag = "Tuplets" },
}

function collect_all_prefs()
    local result = {}
    
    for _, obj in ipairs(prefs_table) do
        if obj.loader == nil then
            obj.prefs:Load(1)
            add_props(result, obj.prefs, obj.tag)
        else
            result[obj.tag] = {}
            obj.loader(obj.prefs, result[obj.tag])
        end
    end

    return result
end

local transform_table = {
    Accidentals = { 
        Distances  = { "^Accidental" },
        MusicSpacing = { "AccidentalsGutter" },
        MusicCharacters = {
            "SymbolNatural", "SymbolFlat", "SymbolSharp", "SymbolDoubleFlat",
            "SymbolDoubleSharp", "SymbolPar."
        },
    },
    AlternateNotation = {
        Distances = { "^Alternate" },
        MusicCharacters = {
            "VerticalTwoMeasureRepeatOffset", ".Slash",            
            "SymbolOneBarRepeat", "SymbolTwoBarRepeat",
        },
    },
    AugmentationDots = {
        MiscellaneousDocument = { "AdjustDotForMultiVoices" },
        MusicCharacters = { "SymbolAugmentationDot" },
        Distances = { "^AugmentationDot" }
    },
    Barlines = {
        Distances = { "^Barline" },
        Sizes = { "Barline." },
        MiscellaneousDocument = { ".Barline" }
    },
    Beams = {
        Distances = { "Beam." },
        Sizes = { "Beam." },
        MiscellaneousDocument = { "Beam.", "IncludeRestsInFour", "AllowFloatingRests" }
    },
    Chords = {
        Chords = { "." },
        MusicCharacters = { "Chord." },
        MiscellaneousDocument = { "Chord.", "Fretboard." }
    },
    Clefs = {
        MiscellaneousDocument = { "ClefResize", ".Clef" },
        Distances = { "^Clef" }
    },
    Flags = {
        MusicCharacters = { ".Flag", "VerticalSecondaryGroupAdjust" }
    },
    Fonts = {
        Fonts = { 
            "^Lyric", "^Text", "^Time", ".Names", "Noteheads$", "^Chord",
            "^Alternate", "Dots$", "EndingRepeats",  "MeasureNumbers", 
            "Tablature",  "Accidentals",  "Flags", "Rests", "Clefs", 
            "KeySignatures", "MultimeasureRests", 
            "Tuplets", "Articulations", 
        }
    },
    GraceNotes = {
        Sizes = { "Grace." },
        Distances = { "GraceNoteSpacing" },
        MiscellaneousDocument = { "Grace." },
    },
    GridsAndGuides = {
        GridsAndGuides = { "." }
    },
    KeySignatures = {
        Distances = { "^Key" },
        MusicCharacters = { "^SymbolKey" },
        MiscellaneousDocument = { "^Key", "CourtesyKeySigAtSystemEnd" }
    },
    Layers = {
        Layers = { "." },
        MiscellaneousDocument = { "ConsolidateRestsAcrossLayers" }
    },
    LinesAndCurves = {
        Sizes = { "^Ledger", "EnclosureThickness", "StaffLineThickness", "ShapeSlurTipWidth" },
        MiscellaneousDocument = { "CurveResolution" }
    },
    Lyrics = {
        Lyrics = { "." }
    },
    MultimeasureRests = {
        MultimeasureRests = { "." }
    },
    MusicSpacing = {
        MusicSpacing = { "!Gutter$" },
        MiscellaneousDocument = { "ScaleManualNotePositioning" }
    },
    NotesAndRests = {
        MiscellaneousDocument = { "UseNoteShapes", "CrossStaffNotesInOriginal" },
        Distances = { "^Space" },
        MusicCharacters = { "^Symbol.*Rest$", "^Symbol.*Notehead$", "^Vertical.*Rest$"}
    },
    PianoBracesAndBrackets = {
        PianoBracesAndBrackets = { "." },
        Distances = { "GroupBracketDefaultDistance" }
    },
    Repeats = {
        Repeats = { "." },
        MusicCharacters = { "RepeatDot$" }
    },
    Stems = {
        Sizes = { "Stem." },
        Distances = { "StemVerticalNoteheadOffset" },
        MiscellaneousDocument = { "UseStemConnections", "DisplayReverseStemming" }
    },
    Text = {
        MiscellaneousDocument = { "DateFormat", "SecondsInTimeStamp", "TextTabCharacters" },
    },
    Ties = {
        Ties = { "." }
    },
    TimeSignatures = {
        MiscellaneousDocument = { ".TimeSig", "TimeSigCompositeDecimals" },
        MusicCharacters = { ".TimeSig" },
        Distances = { "^TimeSig" },
    },
    Tuplets = {
        Tuplets = { "." }
    },
    Categories = {
        Categories = { "." }
    },
    PageFormat = {
        PageFormat = { "." }
    },
    SmartShapes = {
        SmartShapes = { "." },
        MusicCharacters = { ".Octave", "SymbolTrill", "SymbolWiggle" },
        _Fonts = { "^SmartShape", "^Guitar" }    -- incorporate a top-level menu from the source as a submenu
    },
    NamePositions = {
        _GroupNamePositions = { "." },
        _StaffNamePositions = { "." },
    },
    DefaultMusicFont = {
        ["Fonts/Music"] = { "." }
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
        if source_menu:sub(1, 1) == "_" then
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

function apply_transform(prefs)
    local result = {}
    for transformed_category, refs in pairs(transform_table) do
        result[transformed_category] = {}
        copy_items(prefs, result[transformed_category], refs)
    end
    return result
end

-- Simple implementation because we know our inputs are simple
function get_as_yaml(t, indent)
    indent = indent or 0
    local spaces = string.rep(" ", indent * 2)
    local result = {}

    local first_element = true
    for key, val in pairsbykeys(t) do
        if type(val) == "table" then 
            if not first_element then table.insert(result, '') end
            first_element = false
            table.insert(result, string.format('%s%s:', spaces, key))
            table.insert(result, get_as_yaml(val, indent + 1))        
        else
            table.insert(result, string.format('%s%s: %s', spaces, key, tostring(val)))
        end 
    end

    return table.concat(result, '\n')
end

function get_header(document)
    local file_path = finale.FCString()
    document:GetPath(file_path)
    local meta = { Meta = {
      File = file_path.LuaString,
      Date =  os.date(),
      FinaleVersion = finenv.FinaleVersion,
      PluginVersion = finaleplugin.Version
    } };
    if save_raw_file then meta.Meta.Raw = true end
    return '---\n' .. get_as_yaml(meta) .. '\n\n'
end

function options_save_as_yaml()
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

    local all_prefs = collect_all_prefs()
    local prefs_to_save = save_raw_file and all_prefs or apply_transform(all_prefs)
    file:write(get_header(document))
    file:write(get_as_yaml(prefs_to_save))
    file:close()
end


options_save_as_yaml()

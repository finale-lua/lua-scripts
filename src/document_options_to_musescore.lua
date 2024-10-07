function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "October 6, 2024"
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.75
    finaleplugin.Notes = [[
        Exports settings from one or more Finale documents into a MuseScore `.mss` style settings file.
        Only a subset of possible MuseScore settings are exported. The rest will be taken
        from the default settings you have set up for MuseScore when you load it in MuseScore.

        This script addresses two uses cases.

        ## Setting up your MuseScore defaults to be close to those of Finale ##

        - Open a Finale template file or document style file that you wish to use as the basis for your MuseScore defaults.
        - Select the score or part for which you wish to export style settings.
        - Choose "Export Document Options to MuseScore...".
        - Choose a location where to save the output. It is recommended to append `.part.mss` to the name of the style settings for parts.
        - Import each of the score and part settings into a blank document in MuseScore.
        - Make any style adjustments as needed and then save them back out. (This gives them all the settings.)
        - Use the score `.mss` file for Preferences->Score->Style.
        - Use the parts `.mss` file for Preferences->Score->Style for part.

        Now any new projects will start up with these defaults.

        ## Improving MusicXML imports of your documents ##

        - Choose "Export Folder Document Options to MuseScore..." with no document open.
        - Select a folder containing your Finale files. All subfolders will be searched as well.
        - For every Finale file found, a parallel `.mss` file is created.
        - If the source Finale file contains at least one linked part, a parallel `.part.mss` file is created as well (from the first part found).
        - After importing the MusicXML version of your document, use Style->Load style in MuseScore to load the settings for the document.
        - Repeat the process for each part, if any.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Export Folder Document Options to MuseScore...
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Recursively search a folder and its subfolders and export document options for Finale files to score and part MuseScore style files.
    ]]
    finaleplugin.AdditionalPrefixes = [[
        do_folder = true
    ]]
    return "Export Document Options to MuseScore...", "Export Document Options to MuseScore", "Export document options for the current Finale document and part view to a MuseScore style file."
end

-- A lot of Finale settings do not translate to MuseScore very well. They are commented out to show that
-- we tested them but they did not produce useful results.

-- luacheck: ignore 11./global_dialog

local text = require("luaosutils").text

local mixin = require("library.mixin")
local enigma_string = require("library.enigma_string")
local utils = require("library.utils")

do_folder = do_folder or false

local logfile_name = "FinaleMuseScoreSettingsExportLog.txt"

local MUSX_EXTENSION <const> = ".musx"
local MUS_EXTENSION <const> = ".mus"
local TEXT_EXTENSION <const> = ".mss"
local PART_EXTENSION <const> = ".part" .. TEXT_EXTENSION
local MSS_VERSION <const> = "4.40"

-- hard-coded scaling values
local EVPU_PER_INCH <const> = 288
local EVPU_PER_MM <const> = 288 / 25.4
local EVPU_PER_SPACE <const> = 24
local EFIX_PER_EVPU <const> = 64
local EFIX_PER_SPACE <const> = EVPU_PER_SPACE * EFIX_PER_EVPU
local MUSE_FINALE_SCALE_DIFFERENTIAL <const> = 20 / 24

-- Current state
local TIMER_ID <const> = 1 -- value that identifies our timer
local error_occured = false
local current_is_part
local currently_processing
local logfile_path

function log_message(msg, is_error)
    if is_error and not logfile_path then
        error(msg, 2)
    end
    if is_error then
        error_occured = true
    end
    local file <close> = io.open(logfile_path, "a")
    if not file then
        error("unable to append to logfile " .. logfile_path)
    end
    local log_entry = "[" .. (is_error and "Error " or "Success ") .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. currently_processing .. " " .. msg
    if finenv.ConsoleIsAvailable then
        print(log_entry)
    end
    file:write(log_entry .. "\n")
    file:close()
end

-- Finale preferences:
local default_music_font
local distance_prefs
local size_prefs
local misc_prefs
local music_character_prefs
local page_prefs
local spacing_prefs
local repeat_prefs
local smart_shape_prefs
local part_scope_prefs
local layer_one_prefs
local mmrest_prefs
local tie_prefs
local tuplet_prefs
local text_exps

function open_current_prefs()
    local font_prefs = finale.FCFontPrefs()
    font_prefs:Load(finale.FONTPREF_MUSIC)
    default_music_font = font_prefs:CreateFontInfo()
    distance_prefs = finale.FCDistancePrefs()
    distance_prefs:Load(1)
    size_prefs = finale.FCSizePrefs()
    size_prefs:Load(1)
    misc_prefs = finale.FCMiscDocPrefs()
    misc_prefs:Load(1)
    music_character_prefs = finale.FCMusicCharacterPrefs()
    music_character_prefs:Load(1)
    page_prefs = finale.FCPageFormatPrefs()
    if current_is_part then
        page_prefs:LoadParts()
    else
        page_prefs:LoadScore()
    end
    spacing_prefs = finale.FCMusicSpacingPrefs()
    spacing_prefs:Load(1)
    repeat_prefs = finale.FCRepeatPrefs()
    repeat_prefs:Load(1)
    smart_shape_prefs = finale.FCSmartShapePrefs()
    smart_shape_prefs:Load(1)
    part_scope_prefs = finale.FCPartScopePrefs()
    part_scope_prefs:Load(1) -- loads for current part or score
    layer_one_prefs = finale.FCLayerPrefs()
    layer_one_prefs:Load(0)
    mmrest_prefs = finale.FCMultiMeasureRestPrefs()
    mmrest_prefs:Load(1)
    tie_prefs = finale.FCTiePrefs()
    tie_prefs:Load(1)
    tuplet_prefs = finale.FCTupletPrefs()
    tuplet_prefs:Load(1)
    text_exps = finale.FCTextExpressionDefs()
    text_exps:LoadAll()
end

function set_element_text(style_element, name, value)
    local setter_func = "SetText"
    if type(value) == "nil" then
        log_message("incorrect property for " .. name, true)
    elseif type(value) == "number" then
        if math.type(value) == "float" then
            value = string.format("%.5g", value)
            setter_func = "SetText"
        else
            setter_func = "SetIntText"
        end
    elseif type(value) == "boolean" then
        value = value and 1 or 0
        setter_func = "SetIntText"
    end
    local element = style_element:FirstChildElement(name)
    if not element then
        element = style_element:InsertNewChildElement(name)
    end
    element[setter_func](element, value)
    return element
end

function muse_font_efx(font_info)
    local retval = 0
    if font_info.Bold then
        retval = retval | 0x01
    end
    if font_info.Italic then
        retval = retval | 0x02
    end
    if font_info.Underline then
        retval = retval | 0x03
    end
    if font_info.Strikethrough then
        retval = retval | 0x04
    end
    return retval
end

function muse_mag_val(default_font_setting)
    local font_prefs = finale.FCFontPrefs()
    if font_prefs:Load(default_font_setting) then
        local font_info = font_prefs:CreateFontInfo()
        if font_info.Name == default_music_font.Name then
            return font_info.Size / default_music_font.Size
        end
    end
    return 1.0
end

function write_font_pref(style_element, name_prefix, font_info)
    set_element_text(style_element, name_prefix .. "FontFace", font_info.Name)
    set_element_text(style_element, name_prefix .. "FontSize", font_info.Size * (font_info.Absolute and 1 or MUSE_FINALE_SCALE_DIFFERENTIAL))
    set_element_text(style_element, name_prefix .. "FontSpatiumDependent", not font_info.Absolute)
    set_element_text(style_element, name_prefix .. "FontStyle", muse_font_efx(font_info))
end

function write_default_font_pref(style_element, name_prefix, default_font_id)
    local default_font = finale.FCFontPrefs()
    if not default_font:Load(default_font_id) then
        log_message("Unable to load default font pref for " .. name_prefix, true)
    end
    write_font_pref(style_element, name_prefix, default_font:CreateFontInfo())
end

function write_line_prefs(style_element, name_prefix, width_efix, dash_length, dash_gap, style_string)
    local line_width_evpu <const> = width_efix / EFIX_PER_EVPU
    set_element_text(style_element, name_prefix .. "LineWidth", width_efix / EFIX_PER_SPACE)
    if style_string then
        set_element_text(style_element, name_prefix .. "LineStyle", style_string)
    end
    set_element_text(style_element, name_prefix .. "DashLineLen", dash_length / line_width_evpu)
    set_element_text(style_element, name_prefix .. "DashGapLen", dash_gap / line_width_evpu)
end

function write_frame_prefs(style_element, name_prefix, enclosure)
    if not enclosure or enclosure.Shape == finale.ENCLOSURE_NONE or enclosure.LineWidth == 0 then
        set_element_text(style_element, name_prefix .. "FrameType", 0)
        return -- do not override any other defaults if no enclosure shape
    elseif enclosure.Shape == finale.ENCLOSURE_ELLIPSE then
        set_element_text(style_element, name_prefix .. "FrameType", 2)
    else
        set_element_text(style_element, name_prefix .. "FrameType", 1)
    end
    set_element_text(style_element, name_prefix .. "FramePadding", enclosure.HorizontalMargin / EVPU_PER_SPACE)
    set_element_text(style_element, name_prefix .. "FrameWidth", enclosure.LineWidth / EFIX_PER_SPACE)
    set_element_text(style_element, name_prefix .. "FrameRound", enclosure.RoundedCorners and enclosure.RoundedCornerRadius / EFIX_PER_EVPU or 0)
end

function write_category_text_font_pref(style_element, name_prefix, category_id)
    local cat = finale.FCCategoryDef()
    if not cat:Load(category_id) then
        log_message("unable to load category def for " .. name_prefix, true)
    end
    write_font_pref(style_element, name_prefix, cat:CreateTextFontInfo())
    for exp in each(text_exps) do
        if exp.CategoryID == category_id then
            write_frame_prefs(style_element, name_prefix, exp.UseEnclosure and exp:CreateEnclosure() or nil)
            break
        end
    end
end

function write_page_prefs(style_element)
    set_element_text(style_element, "pageWidth", page_prefs.PageWidth / EVPU_PER_INCH)
    set_element_text(style_element, "pageHeight", page_prefs.PageHeight / EVPU_PER_INCH)
    set_element_text(style_element, "pagePrintableWidth",
        (page_prefs.PageWidth - page_prefs.LeftPageRightMargin - page_prefs.LeftPageRightMargin) / EVPU_PER_INCH)
    set_element_text(style_element, "pageEvenLeftMargin", page_prefs.LeftPageLeftMargin / EVPU_PER_INCH)
    set_element_text(style_element, "pageOddLeftMargin",
        (page_prefs.UseFacingPages and page_prefs.RightPageLeftMargin or page_prefs.LeftPageLeftMargin) / EVPU_PER_INCH)
    set_element_text(style_element, "pageEvenTopMargin", page_prefs.LeftPageTopMargin / EVPU_PER_INCH)
    set_element_text(style_element, "pageEvenBottomMargin", page_prefs.LeftPageBottomMargin / EVPU_PER_INCH)
    set_element_text(style_element, "pageOddTopMargin",
        (page_prefs.UseFacingPages and page_prefs.RightPageTopMargin or page_prefs.LeftPageTopMargin) / EVPU_PER_INCH)
    set_element_text(style_element, "pageOddBottomMargin",
        (page_prefs.UseFacingPages and page_prefs.RightPageBottomMargin or page_prefs.LeftPageBottomMargin) / EVPU_PER_INCH)
    set_element_text(style_element, "pageTwosided", page_prefs.UseFacingPages)
    set_element_text(style_element, "enableIndentationOnFirstSystem", page_prefs.UseFirstSystemMargins)
    set_element_text(style_element, "firstSystemIndentationValue", page_prefs.FirstSystemLeft / EVPU_PER_SPACE)
    local page_percent = page_prefs.PageScaling / 100
    local staff_percent = (page_prefs.SystemStaffHeight / (EVPU_PER_SPACE * 4 * 16)) * (page_prefs.SystemScaling / 100)
    set_element_text(style_element, "Spatium", (EVPU_PER_SPACE * staff_percent * page_percent) / EVPU_PER_MM)
    if default_music_font.IsSMuFLFont then
        set_element_text(style_element, "musicalSymbolFont", default_music_font.Name)
        set_element_text(style_element, "musicalTextFont", default_music_font.Name .. " Text")
    end
end

function write_lyrics_prefs(style_element)
    local font_info = finale.FCFontInfo()
    local lyrics_text = finale.FCVerseLyricsText()
    font_info:LoadFontPrefs(finale.FONTPREF_LYRICSVERSE)
    for verse_number, even_odd in ipairs({ "Odd", "Even" }) do
        if lyrics_text:Load(verse_number) then
            local str = lyrics_text:CreateString()
            local font = str and str.Length > 0 and enigma_string.trim_first_enigma_font_tags(str)
            font_info = font or font_info
        end
        write_font_pref(style_element, "lyrics" .. even_odd, font_info)
    end
end

function write_line_measure_prefs(style_element)
    set_element_text(style_element, "barWidth", size_prefs.ThinBarlineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "doubleBarWidth", size_prefs.ThinBarlineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "endBarWidth", size_prefs.HeavyBarlineThickness / EFIX_PER_SPACE)
    -- Finale's double bar distance is measured from the beginning of the thin line
    set_element_text(style_element, "doubleBarDistance", (distance_prefs.BarlineDoubleSpace - size_prefs.ThinBarlineThickness) / EFIX_PER_SPACE)
    -- Finale's final bar distance is the separatioln amount
    set_element_text(style_element, "endBarDistance", (distance_prefs.BarlineFinalSpace) / EFIX_PER_SPACE)
    set_element_text(style_element, "repeatBarlineDotSeparation", repeat_prefs.ForwardSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "repeatBarTips", repeat_prefs.WingStyle ~= finale.REPWING_NONE)
    set_element_text(style_element, "startBarlineSingle", misc_prefs.LeftBarlineDisplaySingle)
    set_element_text(style_element, "startBarlineMultiple", misc_prefs.LeftBarlineDisplayMultiple)
    set_element_text(style_element, "bracketWidth", 0.5) -- hard-coded in Finale
    set_element_text(style_element, "bracketDistance", -distance_prefs.GroupBracketDefaultDistance / EVPU_PER_SPACE)
    set_element_text(style_element, "akkoladeBarDistance", -distance_prefs.GroupBracketDefaultDistance / EVPU_PER_SPACE)
    set_element_text(style_element, "clefLeftMargin", distance_prefs.ClefSpaceBefore / EVPU_PER_SPACE)
    set_element_text(style_element, "keysigLeftMargin", distance_prefs.KeySpaceBefore / EVPU_PER_SPACE)
    local time_sig_space_before = current_is_part and distance_prefs.TimeSigPartsSpaceBefore or distance_prefs.TimeSigSpaceBefore
    set_element_text(style_element, "timesigLeftMargin", time_sig_space_before / EVPU_PER_SPACE)
    set_element_text(style_element, "clefKeyDistance", (distance_prefs.ClefSpaceAfter + distance_prefs.ClefKeyExtraSpace + distance_prefs.KeySpaceBefore) / EVPU_PER_SPACE)
    set_element_text(style_element, "clefTimesigDistance", (distance_prefs.ClefSpaceAfter + distance_prefs.ClefTimeExtraSpace + time_sig_space_before) / EVPU_PER_SPACE)
    set_element_text(style_element, "keyTimesigDistance", (distance_prefs.KeySpaceAfter + distance_prefs.KeyTimeExtraSpace + time_sig_space_before) / EVPU_PER_SPACE)
    set_element_text(style_element, "keyBarlineDistance", repeat_prefs.AfterKeySpace / EVPU_PER_SPACE)
    -- differences in how MuseScore and Finale interpret these settings means the following two are better off left alone
    -- set_element_text(style_element, "systemHeaderDistance", distance_prefs.KeySpaceAfter / EVPU_PER_SPACE)
    -- set_element_text(style_element, "systemHeaderTimeSigDistance", distance_prefs.TimeSigSpaceAfter / EVPU_PER_SPACE)
    set_element_text(style_element, "clefBarlineDistance", repeat_prefs.AfterClefSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "timesigBarlineDistance", repeat_prefs.AfterClefSpace / EVPU_PER_SPACE)  
    set_element_text(style_element, "measureRepeatNumberPos", -(music_character_prefs.VerticalTwoMeasureRepeatOffset + 0.5) / EVPU_PER_SPACE)
    set_element_text(style_element, "staffLineWidth", size_prefs.StaffLineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "ledgerLineWidth", size_prefs.LedgerLineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "ledgerLineLength", (size_prefs.LedgerLeftHalf + size_prefs.LedgerRightHalf) / (2 * EVPU_PER_SPACE))
    set_element_text(style_element, "keysigAccidentalDistance", (distance_prefs.KeySpaceBetweenAccidentals + 4) / EVPU_PER_SPACE) -- observed fudge factor
    set_element_text(style_element, "keysigNaturalDistance", (distance_prefs.KeySpaceBetweenAccidentals + 6) / EVPU_PER_SPACE) -- observed fudge factor
    set_element_text(style_element, "smallClefMag", misc_prefs.ClefResize / 100)
    set_element_text(style_element, "genClef", not misc_prefs.OnlyFirstSystemClef)
    set_element_text(style_element, "genKeysig", not misc_prefs.KeySigOnlyFirstSystem)
    set_element_text(style_element, "genCourtesyTimesig", misc_prefs.CourtesyTimeSigAtSystemEnd)
    set_element_text(style_element, "genCourtesyKeysig", misc_prefs.CourtesyKeySigAtSystemEnd)
    set_element_text(style_element, "genCourtesyClef", misc_prefs.CourtesyClefAtSystemEnd)
    set_element_text(style_element, "keySigCourtesyBarlineMode", misc_prefs.DoubleBarlineAtKeyChange)
    set_element_text(style_element, "timeSigCourtesyBarlineMode", 0)
    set_element_text(style_element, "hideEmptyStaves", not current_is_part)
end

function write_stem_prefs(style_element)
    set_element_text(style_element, "useStraightNoteFlags", music_character_prefs.UseStraightFlags)
    set_element_text(style_element, "stemWidth", size_prefs.StemLineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "shortenStem", true)
    set_element_text(style_element, "stemLength", size_prefs.NormalStemLength / EVPU_PER_SPACE)
    set_element_text(style_element, "shortestStem", size_prefs.ShortenedStemLength / EVPU_PER_SPACE)
    set_element_text(style_element, "stemSlashThickness", size_prefs.GraceSlashThickness / EFIX_PER_SPACE)
end

function write_spacing_prefs(style_element)
    set_element_text(style_element, "minMeasureWidth", spacing_prefs.MinMeasureWidth / EVPU_PER_SPACE)
    set_element_text(style_element, "minNoteDistance", spacing_prefs.MinimumItemDistance / EVPU_PER_SPACE)
    set_element_text(style_element, "measureSpacing", spacing_prefs.ScalingFactor)
    set_element_text(style_element, "minTieLength", spacing_prefs.MinimumDistanceWithTies / EVPU_PER_SPACE)
end

function write_note_related_prefs(style_element)
    set_element_text(style_element, "accidentalDistance", distance_prefs.AccidentalMultiSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "accidentalNoteDistance", distance_prefs.AccidentalNoteSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "beamWidth", size_prefs.BeamThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "useWideBeams", distance_prefs.SecondaryBeamSpace > 0.75 * EVPU_PER_SPACE)
    -- Finale randomly adds twice the stem width to the length of a beam stub. (Observed behavior)
    set_element_text(style_element, "beamMinLen", (size_prefs.BrokenBeamLength + (2 * size_prefs.StemLineThickness / EFIX_PER_EVPU)) / EVPU_PER_SPACE)
    set_element_text(style_element, "beamNoSlope", misc_prefs.BeamSlopeStyle == finale.BEAMSLOPE_FLATTENALL)
    set_element_text(style_element, "dotMag", muse_mag_val(finale.FONTPREF_AUGMENTATIONDOT))
    set_element_text(style_element, "dotNoteDistance", distance_prefs.AugmentationDotNoteSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "dotRestDistance", distance_prefs.AugmentationDotNoteSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "dotDotDistance", distance_prefs.AugmentationDotSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "articulationMag", muse_mag_val(finale.FONTPREF_ARTICULATION))
    set_element_text(style_element, "graceNoteMag", size_prefs.GraceNoteSize / 100)
    set_element_text(style_element, "concertPitch", part_scope_prefs.DisplayInConcertPitch)
    set_element_text(style_element, "multiVoiceRestTwoSpaceOffset", math.abs(layer_one_prefs.RestOffset) >= 4)
end

function write_smart_shape_prefs(style_element)
    set_element_text(style_element, "hairpinHeight", smart_shape_prefs.HairpinDefaultOpening / EVPU_PER_SPACE)
    set_element_text(style_element, "hairpinContHeight", 0.5) -- not configurable in Finale: hard-coded to a half space
    write_category_text_font_pref(style_element, "hairpin", finale.DEFAULTCATID_DYNAMICS)
    write_line_prefs(style_element, "hairpin", smart_shape_prefs.HairpinLineWidth, smart_shape_prefs.LineDashLength, smart_shape_prefs.LineDashSpace)
    set_element_text(style_element, "slurEndWidth", smart_shape_prefs.SlurTipWidth / (10000 * EVPU_PER_SPACE))
    --set_element_text(style_element, "slurMidWidth", math.max(smart_shape_prefs.SlurThicknessVerticalLeft, smart_shape_prefs.SlurThicknessVerticalRight) / EVPU_PER_SPACE)
    set_element_text(style_element, "slurDottedWidth", smart_shape_prefs.LineWidth / EFIX_PER_SPACE)
    set_element_text(style_element, "tieEndWidth", tie_prefs.TipWidth / (10000 * EVPU_PER_SPACE))
    --set_element_text(style_element, "tieMidWidth", math.max(tie_prefs.ThicknessLeft, tie_prefs.ThicknessRight) / EVPU_PER_SPACE)
    set_element_text(style_element, "tieDottedWidth", smart_shape_prefs.LineWidth / EFIX_PER_SPACE)
    set_element_text(style_element, "tiePlacementSingleNote", tie_prefs.UseOuterPlacement and "outside" or "inside")
    set_element_text(style_element, "tiePlacementChord", tie_prefs.UseOuterPlacement and "outside" or "inside")
    set_element_text(style_element, "ottavaHookAbove", smart_shape_prefs.HookLength / EVPU_PER_SPACE)
    set_element_text(style_element, "ottavaHookBelow", -smart_shape_prefs.HookLength / EVPU_PER_SPACE)
    write_line_prefs(style_element, "ottava", smart_shape_prefs.LineWidth, smart_shape_prefs.LineDashLength, smart_shape_prefs.LineDashSpace, "dashed")
    set_element_text(style_element, "ottavaNumbersOnly", smart_shape_prefs.OctavesAsText)
end

function write_measure_number_prefs(style_element)
    local meas_num_regions = finale.FCMeasureNumberRegions()
    set_element_text(style_element, "showMeasureNumber", meas_num_regions:LoadAll() > 0)
    if meas_num_regions.Count > 0 then
        local meas_nums = meas_num_regions:GetItemAt(0)
        set_element_text(style_element, "showMeasureNumberOne", not meas_nums:GetHideFirstNumber(current_is_part))
        set_element_text(style_element, "measureNumberInterval", meas_nums:GetMultipleValue(current_is_part))
        set_element_text(style_element, "measureNumberSystem", meas_nums:GetShowOnSystemStart(current_is_part) and not meas_nums:GetShowMultiples(current_is_part))
        local function process_segment(font_info, enclosure, use_enclosure, justification, alignment, vertical, prefix)
            local function justification_string(justi)
                if justi == finale.MNJUSTIFY_LEFT then
                    return "left,baseline"
                elseif justi == finale.MNJUSTIFY_CENTER then
                    return "center,baseline"
                else
                    return "right,baseline"
                end
            end
            local function horz_alignment(align)
                if align == finale.MNALIGN_LEFT then
                    return 0
                elseif align == finale.MNALIGN_CENTER then
                    return 1
                else
                    return 2
                end
            end
            local function vert_alignment(vert)
                return vert >= 0 and 0 or 1
            end
            write_font_pref(style_element, prefix, font_info)
            set_element_text(style_element, prefix .. "VPlacement", vert_alignment(vertical))
            set_element_text(style_element, prefix .. "HPlacement", horz_alignment(alignment))
            set_element_text(style_element, prefix .. "Align", justification_string(justification))
            write_frame_prefs(style_element, prefix, use_enclosure and enclosure or nil)
        end
        local font_info = meas_nums:GetShowOnSystemStart(current_is_part) and meas_nums:CreateStartFontInfo(current_is_part) or meas_nums:CreateMultipleFontInfo(current_is_part)
        local enclosure = meas_nums:GetShowOnSystemStart(current_is_part) and meas_nums:GetEnclosureStart(current_is_part) or meas_nums:GetEnclosureMultiple(current_is_part)
        local use_enclosure = meas_nums:GetShowOnSystemStart(current_is_part) and meas_nums:GetUseEnclosureStart(current_is_part) or meas_nums:GetUseEnclosureMultiple(current_is_part)
        local justification = meas_nums:GetShowMultiples(current_is_part) and meas_nums:GetMultipleJustification(current_is_part) or meas_nums:GetStartJustification(current_is_part)
        local alignment = meas_nums:GetShowMultiples(current_is_part) and meas_nums:GetMultipleAlignment(current_is_part) or meas_nums:GetStartAlignment(current_is_part)
        local vertical = meas_nums:GetShowOnSystemStart(current_is_part) and meas_nums:GetStartVerticalPosition(current_is_part) or meas_nums:GetMultipleVerticalPosition(current_is_part)
        set_element_text(style_element, "measureNumberOffsetType", 1)
        process_segment(font_info, enclosure, use_enclosure, justification, alignment, vertical, "measureNumber")
        set_element_text(style_element, "mmRestShowMeasureNumberRange", meas_nums:GetShowMultiMeasureRange(current_is_part))
        local left_char = meas_nums:GetMultiMeasureBracketLeft(current_is_part)
        if left_char == 0 then
            set_element_text(style_element, "mmRestRangeBracketType", 2)
        elseif left_char == '(' then
            set_element_text(style_element, "mmRestRangeBracketType", 1)
        else
            set_element_text(style_element, "mmRestRangeBracketType", 0)
        end
        process_segment(meas_nums:CreateMultiMeasureFontInfo(current_is_part), meas_nums:GetEnclosureMultiple(current_is_part), meas_nums:GetUseEnclosureMultiple(current_is_part),
                meas_nums:GetMultiMeasureJustification(current_is_part), meas_nums:GetMultiMeasureAlignment(current_is_part),
                meas_nums:GetMultiMeasureVerticalPosition(current_is_part), "mmRestRange")
    end
    set_element_text(style_element, "createMultiMeasureRests", current_is_part)
    set_element_text(style_element, "minEmptyMeasures", mmrest_prefs.StartNumberingAt)
    set_element_text(style_element, "minMMRestWidth", mmrest_prefs.Width / EVPU_PER_SPACE)
    set_element_text(style_element, "mmRestNumberPos", (mmrest_prefs.NumberVerticalAdjust / EVPU_PER_SPACE) + 1)
    --set_element_text(style_element, "multiMeasureRestMargin", mmrest_prefs.ShapeStartAdjust / EVPU_PER_SPACE)
    set_element_text(style_element, "oldStyleMultiMeasureRests", mmrest_prefs.UseSymbols and mmrest_prefs.UseSymbolsLessThan > 1)
    set_element_text(style_element, "mmRestOldStyleMaxMeasures", math.max(mmrest_prefs.UseSymbolsLessThan - 1, 0))
    set_element_text(style_element, "mmRestOldStyleSpacing", mmrest_prefs.SymbolSpace / EVPU_PER_SPACE)
end

function write_repeat_ending_prefs(style_element)
    --local element = set_element_text(style_element, "voltaPosAbove", "")
    --element:SetDoubleAttribute("x", 0)
    --element:SetDoubleAttribute("y", repeat_prefs.EndingBracketHeight / EVPU_PER_SPACE)
    --set_element_text(style_element, "voltaHook", repeat_prefs.EndingFrontHookLength / EVPU_PER_SPACE)
    set_element_text(style_element, "voltaLineWidth", repeat_prefs.EndingLineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "voltaLineStyle", "solid")
    write_default_font_pref(style_element, "volta", finale.FONTPREF_ENDING)
    set_element_text(style_element, "voltaAlign", "left,baseline")
    --element = set_element_text(style_element, "voltaOffset", "")
    --element:SetDoubleAttribute("x", repeat_prefs.EndingHorizontalText / EVPU_PER_SPACE)
    --element:SetDoubleAttribute("y", repeat_prefs.EndingVerticalText / EVPU_PER_SPACE)
end

function write_tuplet_prefs(style_element)
    set_element_text(style_element, "tupletOutOfStaff", tuplet_prefs.AvoidStaff)
    set_element_text(style_element, "tupletStemLeftDistance", tuplet_prefs.LeftExtension / EVPU_PER_SPACE)
    set_element_text(style_element, "tupletStemRightDistance", tuplet_prefs.RightExtension / EVPU_PER_SPACE)
    set_element_text(style_element, "tupletNoteLeftDistance", tuplet_prefs.LeftExtension / EVPU_PER_SPACE)
    set_element_text(style_element, "tupletNoteRightDistance", tuplet_prefs.RightExtension / EVPU_PER_SPACE)
    set_element_text(style_element, "tupletBracketWidth", tuplet_prefs.BracketThickness / EFIX_PER_SPACE)
    if tuplet_prefs.PlacementMode == finale.TUPLETPLACEMENT_ABOVE then
        set_element_text(style_element, "tupletDirection", 1)
    elseif tuplet_prefs.PlacementMode == finale.TUPLETPLACEMENT_BELOW then
        set_element_text(style_element, "tupletDirection", 2)
    else
        set_element_text(style_element, "tupletDirection", 0)
    end
    if tuplet_prefs.NumberStyle == finale.TUPLETNUMBER_NONE then
        set_element_text(style_element, "tupletNumberType", 2)
    elseif tuplet_prefs.NumberStyle == finale.TUPLETNUMBER_REGULAR then
        set_element_text(style_element, "tupletNumberType", 0)
    else
        set_element_text(style_element, "tupletNumberType", 1)
    end
    if tuplet_prefs.ShapeStyle == finale.TUPLETSHAPE_NONE then
        set_element_text(style_element, "tupletBracketType", 2)
    elseif tuplet_prefs.BracketMode == finale.TUPLETBRACKET_ALWAYS then
        set_element_text(style_element, "tupletBracketType", 1)
    else
        set_element_text(style_element, "tupletBracketType", 0)
    end
    local font_pref = finale.FCFontPrefs()
    if not font_pref:Load(finale.FONTPREF_TUPLET) then
        log_message("unable to load font pref for tuplets", true)
    end
    local font_info = font_pref:CreateFontInfo()
    if font_info.IsSMuFLFont then
        set_element_text(style_element, "tupletMusicalSymbolsScale", muse_mag_val(finale.FONTPREF_TUPLET))
        set_element_text(style_element, "tupletUseSymbols", true)
    else
        write_font_pref(style_element, "tuplet", font_info)
        set_element_text(style_element, "tupletMusicalSymbolsScale", 1)
        set_element_text(style_element, "tupletUseSymbols", false)
    end
    set_element_text(style_element, "tupletBracketHookHeight",
    math.max(tuplet_prefs.LeftHookLength, tuplet_prefs.RightHookLength) / EVPU_PER_SPACE)
end

function write_marking_prefs(style_element)
    local cat = finale.FCCategoryDef()
    if not cat:Load(finale.DEFAULTCATID_DYNAMICS) then
        log_message("unable to load FCCategoryDef for dynamics", true)
    end
    local font_info = finale.FCFontInfo()
    local override = cat:GetMusicFontInfo(font_info) and font_info.IsSMuFLFont and font_info.FontID ~= 0
    set_element_text(style_element, "dynamicsOverrideFont", override)
    if override then
        set_element_text(style_element, "dynamicsFont", font_info.Name)
        set_element_text(style_element, "dynamicsSize", font_info.Size / default_music_font.Size)
    else
        set_element_text(style_element, "dynamicsFont", default_music_font.Name)
        set_element_text(style_element, "dynamicsSize",
            font_info.IsSMuFLFont and (font_info.Size / default_music_font.Size) or 1)
    end
    local font_pref = finale.FCFontPrefs()
    if not font_pref:Load(finale.FONTPREF_TEXTBLOCK) then
        log_message("unable to load font prefs for Text Blocks", true)
    end
    font_info = font_pref:CreateFontInfo()
    write_font_pref(style_element, "default", font_info)
    -- since the following depend on Page Titles, just update the font face with the TEXTBLOCK font name
    set_element_text(style_element, "titleFontFace", font_info.Name)
    set_element_text(style_element, "subTitleFontFace", font_info.Name)
    set_element_text(style_element, "composerFontFace", font_info.Name)
    set_element_text(style_element, "lyricistFontFace", font_info.Name)
    write_default_font_pref(style_element, "longInstrument", finale.FONTPREF_STAFFNAME)
    local position = finale.FCStaffNamePositionPrefs()
    local function justify_to_alignment()
        if position.Justification == finale.TEXTJUSTIFY_LEFT then
            return "left,center"
        elseif position.Justification == finale.TEXTJUSTIFY_RIGHT then
            return "right,center"
        else
            return "center,center"
        end
    end
    position:LoadFull()
    set_element_text(style_element, "longInstrumentAlign", justify_to_alignment())
    write_default_font_pref(style_element, "shortInstrument", finale.FONTPREF_ABRVSTAFFNAME)
    position:LoadAbbreviated()
    set_element_text(style_element, "shortInstrumentAlign", justify_to_alignment())
    write_default_font_pref(style_element, "partInstrument", finale.FONTPREF_STAFFNAME)
    write_category_text_font_pref(style_element, "dynamics", finale.DEFAULTCATID_DYNAMICS)
    write_category_text_font_pref(style_element, "expression", finale.DEFAULTCATID_EXPRESSIVETEXT)
    write_category_text_font_pref(style_element, "tempo", finale.DEFAULTCATID_TEMPOMARKS)
    write_category_text_font_pref(style_element, "tempoChange", finale.DEFAULTCATID_EXPRESSIVETEXT)
    write_line_prefs(style_element, "tempoChange", smart_shape_prefs.LineWidth, smart_shape_prefs.LineDashLength, smart_shape_prefs.LineDashSpace, "dashed")
    write_category_text_font_pref(style_element, "metronome", finale.DEFAULTCATID_TEMPOMARKS)
    set_element_text(style_element, "translatorFontFace", font_info.Name)
    write_category_text_font_pref(style_element, "systemText", finale.DEFAULTCATID_EXPRESSIVETEXT)
    write_category_text_font_pref(style_element, "staffText", finale.DEFAULTCATID_TECHNIQUETEXT)
    write_category_text_font_pref(style_element, "rehearsalMark", finale.DEFAULTCATID_REHEARSALMARK)
    write_default_font_pref(style_element, "repeatLeft", finale.FONTPREF_REPEAT)
    write_default_font_pref(style_element, "repeatRight", finale.FONTPREF_REPEAT)
    write_font_pref(style_element, "frame", font_info)
    write_category_text_font_pref(style_element, "textLine", finale.DEFAULTCATID_TECHNIQUETEXT)
    write_category_text_font_pref(style_element, "systemTextLine", finale.DEFAULTCATID_EXPRESSIVETEXT)
    write_category_text_font_pref(style_element, "glissando", finale.DEFAULTCATID_TECHNIQUETEXT)
    write_category_text_font_pref(style_element, "bend", finale.DEFAULTCATID_TECHNIQUETEXT)
    write_font_pref(style_element, "header", font_info)
    write_font_pref(style_element, "footer", font_info)
    write_font_pref(style_element, "copyright", font_info)
    write_font_pref(style_element, "pageNumber", font_info)
    write_font_pref(style_element, "instrumentChange", font_info)
    write_font_pref(style_element, "sticking", font_info)
    write_font_pref(style_element, "user1", font_info)
    write_font_pref(style_element, "user2", font_info)
    write_font_pref(style_element, "user3", font_info)
    write_font_pref(style_element, "user4", font_info)
    write_font_pref(style_element, "user5", font_info)
    write_font_pref(style_element, "user6", font_info)
    write_font_pref(style_element, "user7", font_info)
    write_font_pref(style_element, "user8", font_info)
    write_font_pref(style_element, "user9", font_info)
    write_font_pref(style_element, "user10", font_info)
    write_font_pref(style_element, "user11", font_info)
    write_font_pref(style_element, "user12", font_info)
end

function write_xml(output_path)
    local mssxml <close> = tinyxml2.XMLDocument()
    mssxml:InsertEndChild(mssxml:NewDeclaration(nil))
    local ms_element = mssxml:NewElement("museScore")
    ms_element:SetAttribute("version", MSS_VERSION)
    mssxml:InsertEndChild(ms_element)
    local style_element = ms_element:InsertNewChildElement("Style")
    currently_processing = output_path
    error_occured = false
    open_current_prefs()
    write_page_prefs(style_element)
    write_lyrics_prefs(style_element)
    write_line_measure_prefs(style_element)
    write_stem_prefs(style_element)
    write_spacing_prefs(style_element)
    write_note_related_prefs(style_element)
    write_smart_shape_prefs(style_element)
    write_measure_number_prefs(style_element)
    write_repeat_ending_prefs(style_element)
    write_tuplet_prefs(style_element)
    write_marking_prefs(style_element)
    if mssxml:SaveFile(output_path) ~= tinyxml2.XML_SUCCESS then
        log_message("unable to save " .. output_path .. ". " .. mssxml:ErrorStr(), true)
    elseif logfile_path then
        log_message(error_occured and " saved with errors" or "", false)
    else
        finenv:UI():AlertInfo(output_path .. (error_occured and " saved with errors." or " saved."), "Success")
    end
end

-- Windows closes plugin dialogs when the last document window closes, so keep the first
-- one open till all are done (on Windows only)
local first_document

function process_document(document_file_path)
    local document = finale.FCDocument()
    if document:Open(finale.FCString(document_file_path), true, nil, false, false, true) then
        local parts = finale.FCParts()
        parts:LoadAll()
        -- it is not actually necessary to switch to the part to get its settings
        local path_name, file_name_no_ext = utils.split_file_path(document_file_path)
        current_is_part = false
        write_xml(path_name .. file_name_no_ext .. TEXT_EXTENSION)
        for part in each(parts) do
            if not part:IsScore() then
                current_is_part = true
                write_xml(path_name .. file_name_no_ext .. PART_EXTENSION)
                break
            end
        end
        if finenv.UI():IsOnWindows() and not first_document then
            first_document = document
        else
            document.Dirty = false
            local closed = document:CloseCurrentDocumentAndWindow(false) -- false: rollback any edits (which there should be none)
            if not closed then
                currently_processing = document_file_path
                log_message("failed to close", true)
            end
        end
    else
        currently_processing = document_file_path
        log_message("unable to open Finale document", true)
    end
    document:SwitchBack()
end

function create_status_dialog(selected_directory, files_to_process)
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle("Export Settings to MuseScore")
    local current_y = 0
    -- processing folder
    dialog:CreateStatic(0, current_y + 2, "folder_label")
        :SetText("Folder:")
        :DoAutoResizeWidth(0)
    dialog:CreateStatic(0, current_y + 2, "folder")
        :SetText("")
        :SetWidth(400)
        :AssureNoHorizontalOverlap(dialog:GetControl("folder_label"), 5)
        :StretchToAlignWithRight()
    current_y = current_y + 20
    -- processing file
    dialog:CreateStatic(0, current_y + 2, "file_path_label")
        :SetText("File:")
        :DoAutoResizeWidth(0)
    dialog:CreateStatic(0, current_y + 2, "file_path")
        :SetText("")
        :SetWidth(300)
        :AssureNoHorizontalOverlap(dialog:GetControl("file_path_label"), 5)
        :HorizontallyAlignLeftWith(dialog:GetControl("folder"))
        :StretchToAlignWithRight()
    -- cancel
    dialog:CreateCancelButton("cancel")
    -- registrations
    dialog:RegisterInitWindow(function(self)
        self:SetTimer(TIMER_ID, 100) -- 100 milliseconds
    end)
    dialog:RegisterHandleTimer(function(self, timer)
        assert(timer == TIMER_ID, "incorrect timer id value " .. timer)
        if #files_to_process <= 0 then
            self:GetControl("folder"):SetText(selected_directory)
            self:GetControl("file_path"):SetText("Export complete.")
            self:StopTimer(TIMER_ID)
            currently_processing = selected_directory
            log_message("processing complete")
            self:GetControl("cancel"):SetText("Close")
            return
        end
        self:GetControl("folder"):SetText("..." .. files_to_process[1].folder:sub(#selected_directory))
            :RedrawImmediate()
        self:GetControl("file_path"):SetText(files_to_process[1].name)
            :RedrawImmediate()
        process_document(files_to_process[1].folder .. files_to_process[1].name)
        table.remove(files_to_process, 1)
    end)
    dialog:RegisterCloseWindow(function(self)
        self:StopTimer(TIMER_ID)
        if #files_to_process > 0 then
            currently_processing = selected_directory
            log_message("processing aborted by user", true)
        end
        if first_document then
            first_document.Dirty = false
            first_document:CloseCurrentDocumentAndWindow(false)
        end
        finenv.RetainLuaState = false
    end)
    dialog:RunModeless()
end

function select_target(file_path_str)
    local path_name, file_name_no_ext = utils.split_file_path(file_path_str)
    local file_name = file_name_no_ext .. (current_is_part and PART_EXTENSION or TEXT_EXTENSION)
    local save_dialog = finale.FCFileSaveAsDialog(finenv.UI())
    save_dialog:SetWindowTitle(finale.FCString("Save MuseScore style settings as"))
    save_dialog:AddFilter(finale.FCString("*" .. TEXT_EXTENSION), finale.FCString("MuseScore Style Settings File"))
    save_dialog:SetInitFolder(finale.FCString(path_name))
    save_dialog:SetFileName(finale.FCString(file_name))
    save_dialog:AssureFileExtension(TEXT_EXTENSION)
    if not save_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    save_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end

function select_directory()
    local default_folder_path = finale.FCString()
    default_folder_path:SetMusicFolderPath()
    local open_dialog = finale.FCFolderBrowseDialog(finenv.UI())
    open_dialog:SetWindowTitle(finale.FCString("Select folder containing Finale files"))
    open_dialog:SetFolderPath(default_folder_path)
    open_dialog:SetUseFinaleAPI(finenv:UI():IsOnMac())
    if not open_dialog:Execute() then
        return nil
    end
    local selected_folder = finale.FCString()
    open_dialog:GetFolderPath(selected_folder)
    selected_folder:AssureEndingPathDelimiter()
    return selected_folder.LuaString
end

function document_options_to_musescore()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    local document = documents:FindCurrent()
    if do_folder then
        if document then
            finenv:UI():AlertInfo("Run this plugin with no documents open.", "")
            return
        end
        local selected_directory = select_directory()
        if selected_directory then
            logfile_path = text.convert_encoding(selected_directory, text.get_utf8_codepage(), text.get_default_codepage()) .. logfile_name
            local file <close> = io.open(logfile_path, "w")
            if not file then
                error("unable to create logfile " .. logfile_path)
            end
            file:close()
            local files_to_process = {}
            for folder, filename in utils.eachfile(selected_directory, true) do
                print(folder, filename)
                if (filename:sub(-MUSX_EXTENSION:len()) == MUSX_EXTENSION) or (filename:sub(-MUS_EXTENSION:len()) == MUS_EXTENSION) then
                    table.insert(files_to_process, {name = filename, folder = folder})
                end
            end
            create_status_dialog(selected_directory, files_to_process)
        end
    else
        if not document then
            finenv:UI():AlertInfo("Run this plugin with a document open.", "")
            return
        end
        local file_path_fcstr = finale.FCString()
        document:GetPath(file_path_fcstr)
        current_is_part = finale.FCPart(finale.PARTID_CURRENT):IsPart()
        local output_path = select_target(file_path_fcstr.LuaString)
        if output_path then
            write_xml(output_path)
        end
    end
end

document_options_to_musescore()

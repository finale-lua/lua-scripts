function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "2.0"
    finaleplugin.Date = "March 24, 2023"
    finaleplugin.CategoryTags = "Layout"
    finaleplugin.MinJWLuaVersion = 0.67 -- https://robertgpatterson.com/-fininfo/-rgplua/rgplua.html
    return "Load SMuFL Engraving Defaults", "Load SMuFL Engraving Defaults", "Loads engraving defaults for the current SMuFL Default Music Font."
end

local library = require("library.general_library")
local json = library.require_embedded("cjson")

function smufl_load_engraving_defaults()
    local font_info = finale.FCFontInfo()
    font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    local font_json_file = library.get_smufl_metadata_file(font_info)
    if nil == font_json_file then
        finenv.UI():AlertError("The current Default Music Font (" .. font_info.Name .. ") is not a SMuFL font, or else the json file with its engraving defaults is not installed.", "Default Music Font is not SMuFL")
        return
    end
    local json = font_json_file:read("*all")
    io.close(font_json_file)
    local font_metadata = json.decode(json)

    local evpuPerSpace = 24.0
    local efixPerEvpu = 64.0
    local efixPerSpace = evpuPerSpace * efixPerEvpu

    -- read our current doc options
    local music_char_prefs = finale.FCMusicCharacterPrefs()
    music_char_prefs:Load(1)
    local distance_prefs = finale.FCDistancePrefs()
    distance_prefs:Load(1)
    local size_prefs = finale.FCSizePrefs()
    size_prefs:Load(1)
    local lyrics_prefs = finale.FCLyricsPrefs()
    lyrics_prefs:Load(1)
    local smart_shape_prefs = finale.FCSmartShapePrefs()
    smart_shape_prefs:Load(1)
    local repeat_prefs = finale.FCRepeatPrefs()
    repeat_prefs:Load(1)
    local tie_prefs = finale.FCTiePrefs()
    tie_prefs:Load(1)
    local tuplet_prefs = finale.FCTupletPrefs()
    tuplet_prefs:Load(1)

    -- Beam spacing has to be calculated in terms of beam thickness, because the json spec
    -- calls for inner distance whereas Finale is top edge to top edge. So hold the value
    local beamSpacingFound = 0
    local beamWidthFound = math.floor(size_prefs.BeamThickness/efixPerEvpu + 0.5)

    -- define actions for each of the fields of font_info.engravingDefaults
    local action = {
        staffLineThickness = function(v) size_prefs.StaffLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        stemThickness = function(v) size_prefs.StemLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        beamThickness = function(v)
            size_prefs.BeamThickness = math.floor(efixPerSpace*v + 0.5)
            beamWidthFound = math.floor(evpuPerSpace*v + 0.5)
        end,
        beamSpacing = function(v) beamSpacingFound = math.floor(evpuPerSpace*v + 0.5) end,
        legerLineThickness = function(v) size_prefs.LedgerLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        legerLineExtension = function(v)
                size_prefs.LedgerLeftHalf = math.floor(evpuPerSpace*v + 0.5)
                size_prefs.LedgerRightHalf = size_prefs.LedgerLeftHalf
                size_prefs.LedgerLeftRestHalf = size_prefs.LedgerLeftHalf
                size_prefs.LedgerRightRestHalf = size_prefs.LedgerLeftHalf
            end,
        slurEndpointThickness = function(v)
                size_prefs.ShapeSlurTipWidth = math.floor(evpuPerSpace*v*10000.0 +0.5)
                smart_shape_prefs.SlurTipWidth = math.floor(evpuPerSpace*v*10000.0 +0.5)
            end,
        slurMidpointThickness = function(v)
                smart_shape_prefs.SlurThicknessVerticalLeft = math.floor(evpuPerSpace*v +0.5)
                smart_shape_prefs.SlurThicknessVerticalRight = math.floor(evpuPerSpace*v +0.5)
            end,
        tieEndpointThickness = function(v) tie_prefs.TipWidth = math.floor(evpuPerSpace*v*10000.0 +0.5) end,
        tieMidpointThickness = function(v)
            tie_prefs.ThicknessLeft = math.floor(evpuPerSpace*v +0.5)
            tie_prefs.ThicknessRight = math.floor(evpuPerSpace*v +0.5)
        end,
        thinBarlineThickness = function(v)
                size_prefs.ThinBarlineThickness = math.floor(efixPerSpace*v + 0.5)
                repeat_prefs.ThinLineThickness = math.floor(efixPerSpace*v + 0.5)
            end,
        thickBarlineThickness = function(v)
                size_prefs.HeavyBarlineThickness = math.floor(efixPerSpace*v + 0.5)
                repeat_prefs.HeavyLineThickness = math.floor(efixPerSpace*v + 0.5)
            end,
        dashedBarlineThickness = function(v) size_prefs.ThinBarlineThickness = math.floor(efixPerSpace*v + 0.5) end,
        dashedBarlineDashLength = function(v) size_prefs.BarlineDashLength = math.floor(evpuPerSpace*v + 0.5) end,
        dashedBarlineGapLength = function(v) distance_prefs.BarlineDashSpace = math.floor(evpuPerSpace*v + 0.5)end,
        barlineSeparation = function(v) distance_prefs.BarlineDoubleSpace = math.floor(efixPerSpace*v + 0.5) end,
        thinThickBarlineSeparation = function(v)
                distance_prefs.BarlineFinalSpace = math.floor(efixPerSpace*v + 0.5)
                repeat_prefs.SpaceBetweenLines = math.floor(efixPerSpace*v + 0.5)
            end,
        repeatBarlineDotSeparation = function(v)
                local text_met = finale.FCTextMetrics()
                text_met:LoadSymbol(music_char_prefs.SymbolForwardRepeatDot, font_info, 100)
                local newVal = evpuPerSpace*v + text_met:CalcWidthEVPUs()
                repeat_prefs:SetForwardSpace(math.floor(newVal + 0.5))
                repeat_prefs:SetBackwardSpace(math.floor(newVal + 0.5))
            end,
        bracketThickness = function(v) end, -- Not supported. (Finale doesn't seem to have this pref setting.)
        subBracketThickness = function(v) end, -- Not supported. (Finale doesn't seem to have this pref setting.)
        hairpinThickness = function(v) smart_shape_prefs.HairpinLineWidth = math.floor(efixPerSpace*v + 0.5) end,
        octaveLineThickness = function(v) smart_shape_prefs.LineWidth = math.floor(efixPerSpace*v + 0.5) end,
        pedalLineThickness = function(v) end, -- To Do: requires finding and editing Custom Lines
        repeatEndingLineThickness = function(v) repeat_prefs.EndingLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        arrowShaftThickness = function(v) end, -- To Do: requires finding and editing Custom Lines
        lyricLineThickness = function(v) lyrics_prefs.WordExtLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        textEnclosureThickness = function(v)
                size_prefs.EnclosureThickness = math.floor(efixPerSpace*v + 0.5)
                local expression_defs = finale.FCTextExpressionDefs()
                expression_defs:LoadAll()
                for def in each(expression_defs) do
                    if def.UseEnclosure then
                        local enclosure = def:CreateEnclosure()
                        if ( nil ~= enclosure) then
                            enclosure.LineWidth = size_prefs.EnclosureThickness
                            enclosure:Save()
                        end
                    end
                end
                local numbering_regions = finale.FCMeasureNumberRegions()
                numbering_regions:LoadAll()
                for region in each(numbering_regions) do
                    local got1 = false
                    for _, for_parts in pairs({false, true}) do
                        if region:GetUseEnclosureStart(for_parts) then
                            local enc_start = region:GetEnclosureStart(for_parts)
                            if nil ~= enc_start then
                                enc_start.LineWidth = size_prefs.EnclosureThickness
                                got1 = true
                            end
                        end
                        if region:GetUseEnclosureMultiple(for_parts) then
                            local enc_multiple = region:GetEnclosureMultiple(for_parts)
                            if nil ~= enc_multiple then
                                enc_multiple.LineWidth = size_prefs.EnclosureThickness
                                got1 = true
                            end
                        end
                    end
                    if got1 then
                        region:Save()
                    end
                end
                local separate_numbers = finale.FCSeparateMeasureNumbers()
                separate_numbers:LoadAll()
                for sepnum in each(separate_numbers) do
                    if sepnum.UseEnclosure then
                        local enc_sep = sepnum:GetEnclosure()
                        if nil ~= enc_sep then
                            enc_sep.LineWidth = size_prefs.EnclosureThickness
                        end
                        sepnum:Save()
                    end
                end
            end,
        tupletBracketThickness = function(v)
                tuplet_prefs.BracketThickness = math.floor(efixPerSpace*v + 0.5)
            end,
        hBarThickness = function(v) end -- Not supported. (Can't edit FCShape in Lua. Hard even in PDK.)
    }

    -- apply each action from the json file
    for k, v in pairs(font_metadata.engravingDefaults) do
        local action_function = action[k]
        if nil ~= action_function then
            action_function(tonumber(v))
        end
    end

    if 0 ~= beamSpacingFound then
        distance_prefs.SecondaryBeamSpace = beamSpacingFound + beamWidthFound

        -- Currently, the json files for Finale measure beam separation from top edge to top edge
        -- whereas the spec specifies that it be only the distance between the inner edges. This will
        -- probably be corrected at some point, but for now hard-code around it. Hopefully this code will
        -- get a Finale version check at some point.

        local finale_prefix = "Finale "
        if finale_prefix == font_info.Name:sub(1, #finale_prefix) then
            distance_prefs.SecondaryBeamSpace = beamSpacingFound
        end
    end

    -- save new preferences
    distance_prefs:Save()
    size_prefs:Save()
    lyrics_prefs:Save()
    smart_shape_prefs:Save()
    repeat_prefs:Save()
    tie_prefs:Save()
    tuplet_prefs:Save()
end

smufl_load_engraving_defaults()

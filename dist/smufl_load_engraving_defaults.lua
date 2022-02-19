function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 18, 2021"
    finaleplugin.CategoryTags = "Layout"
    return "Load SMuFL Engraving Defaults", "Load SMuFL Engraving Defaults", "Loads engraving defaults for the current SMuFL Default Music Font."
end


local luna = require("lunajson.lunajson")
--[[
$module Library
]]
local library = {}

--[[
% finale_version(major, minor, build)

Returns a raw Finale version from major, minor, and (optional) build parameters. For 32-bit Finale
this is the internal major Finale version, not the year.

@ major (number) Major Finale version
@ minor (number) Minor Finale version
@ [build] (number) zero if omitted
: (number)
]]
function library.finale_version(major, minor, build)
    local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
    if build then
        retval = bit32.bor(retval, math.floor(build))
    end
    return retval
end

--[[
% group_overlaps_region(staff_group, region)

Returns true if the input staff group overlaps with the input music region, otherwise false.

@ staff_group (FCGroup)
@ region (FCMusicRegion)
: (boolean)
]]
function library.group_overlaps_region(staff_group, region)
    if region:IsFullDocumentSpan() then
        return true
    end
    local staff_exists = false
    local sys_staves = finale.FCSystemStaves()
    sys_staves:LoadAllForRegion(region)
    for sys_staff in each(sys_staves) do
        if staff_group:ContainsStaff(sys_staff:GetStaff()) then
            staff_exists = true
            break
        end
    end
    if not staff_exists then
        return false
    end
    if (staff_group.StartMeasure > region.EndMeasure) or (staff_group.EndMeasure < region.StartMeasure) then
        return false
    end
    return true
end

--[[
% group_is_contained_in_region(staff_group, region)

Returns true if the entire input staff group is contained within the input music region.
If the start or end staff are not visible in the region, it returns false.

@ staff_group (FCGroup)
@ region (FCMusicRegion)
: (boolean)
]]
function library.group_is_contained_in_region(staff_group, region)
    if not region:IsStaffIncluded(staff_group.StartStaff) then
        return false
    end
    if not region:IsStaffIncluded(staff_group.EndStaff) then
        return false
    end
    return true
end

--[[
% staff_group_is_multistaff_instrument(staff_group)

Returns true if the entire input staff group is a multistaff instrument.

@ staff_group (FCGroup)
: (boolean)
]]
function library.staff_group_is_multistaff_instrument(staff_group)
    local multistaff_instruments = finale.FCMultiStaffInstruments()
    multistaff_instruments:LoadAll()
    for inst in each(multistaff_instruments) do
        if inst:ContainsStaff(staff_group.StartStaff) and (inst.GroupID == staff_group:GetItemID()) then
            return true
        end
    end
    return false
end

--[[
% get_selected_region_or_whole_doc()

Returns a region that contains the selected region if there is a selection or the whole document if there isn't.
SIDE-EFFECT WARNING: If there is no selected region, this function also changes finenv.Region() to the whole document.

: (FCMusicRegion)
]]
function library.get_selected_region_or_whole_doc()
    local sel_region = finenv.Region()
    if sel_region:IsEmpty() then
        sel_region:SetFullDocument()
    end
    return sel_region
end

--[[
% get_first_cell_on_or_after_page(page_num)

Returns the first FCCell at the top of the input page. If the page is blank, it returns the first cell after the input page.

@ page_num (number)
: (FCCell)
]]
function library.get_first_cell_on_or_after_page(page_num)
    local curr_page_num = page_num
    local curr_page = finale.FCPage()
    local got1 = false
    --skip over any blank pages
    while curr_page:Load(curr_page_num) do
        if curr_page:GetFirstSystem() > 0 then
            got1 = true
            break
        end
        curr_page_num = curr_page_num + 1
    end
    if got1 then
        local staff_sys = finale.FCStaffSystem()
        staff_sys:Load(curr_page:GetFirstSystem())
        return finale.FCCell(staff_sys.FirstMeasure, staff_sys.TopStaff)
    end
    --if we got here there were nothing but blank pages left at the end
    local end_region = finale.FCMusicRegion()
    end_region:SetFullDocument()
    return finale.FCCell(end_region.EndMeasure, end_region.EndStaff)
end

--[[
% get_top_left_visible_cell()

Returns the topmost, leftmost visible FCCell on the screen, or the closest possible estimate of it.

: (FCCell)
]]
function library.get_top_left_visible_cell()
    if not finenv.UI():IsPageView() then
        local all_region = finale.FCMusicRegion()
        all_region:SetFullDocument()
        return finale.FCCell(finenv.UI():GetCurrentMeasure(), all_region.StartStaff)
    end
    return library.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())
end

--[[
% get_top_left_selected_or_visible_cell()

If there is a selection, returns the topmost, leftmost cell in the selected region.
Otherwise returns the best estimate for the topmost, leftmost currently visible cell.

: (FCCell)
]]
function library.get_top_left_selected_or_visible_cell()
    local sel_region = finenv.Region()
    if not sel_region:IsEmpty() then
        return finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
    end
    return library.get_top_left_visible_cell()
end

--[[
% is_default_measure_number_visible_on_cell (meas_num_region, cell, staff_system, current_is_part)

Returns true if measure numbers for the input region are visible on the input cell for the staff system.

@ meas_num_region (FCMeasureNumberRegion)
@ cell (FCCell)
@ staff_system (FCStaffSystem)
@ current_is_part (boolean) true if the current view is a linked part, otherwise false
: (boolean)
]]
function library.is_default_measure_number_visible_on_cell (meas_num_region, cell, staff_system, current_is_part)
    local staff = finale.FCCurrentStaffSpec()
    if not staff:LoadForCell(cell, 0) then
        return false
    end
    if meas_num_region:GetShowOnTopStaff() and (cell.Staff == staff_system.TopStaff) then
        return true
    end
    if meas_num_region:GetShowOnBottomStaff() and (cell.Staff == staff_system:CalcBottomStaff()) then
        return true
    end
    if staff.ShowMeasureNumbers then
        return not meas_num_region:GetExcludeOtherStaves(current_is_part)
    end
    return false
end

--[[
% is_default_number_visible_and_left_aligned (meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)

Returns true if measure number for the input cell is visible and left-aligned.

@ meas_num_region (FCMeasureNumberRegion)
@ cell (FCCell)
@ system (FCStaffSystem)
@ current_is_part (boolean) true if the current view is a linked part, otherwise false
@ is_for_multimeasure_rest (boolean) true if the current cell starts a multimeasure rest
: (boolean)
]]
function library.is_default_number_visible_and_left_aligned (meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)
    if meas_num_region.UseScoreInfoForParts then
        current_is_part = false
    end
    if is_for_multimeasure_rest and meas_num_region:GetShowOnMultiMeasureRests(current_is_part) then
        if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultiMeasureAlignment(current_is_part)) then
            return false
        end
    elseif (cell.Measure == system.FirstMeasure) then
        if not meas_num_region:GetShowOnSystemStart() then
            return false
        end
        if (finale.MNALIGN_LEFT ~= meas_num_region:GetStartAlignment(current_is_part)) then
            return false
        end
    else
        if not meas_num_region:GetShowMultiples(current_is_part) then
            return false
        end
        if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultipleAlignment(current_is_part)) then
            return false
        end
    end
    return library.is_default_measure_number_visible_on_cell (meas_num_region, cell, system, current_is_part)
end

--[[
% update_layout(from_page, unfreeze_measures)

Updates the page layout.

@ [from_page] (number) page to update from, defaults to 1
@ [unfreeze_measures] (boolean) defaults to false
]]
function library.update_layout(from_page, unfreeze_measures)
    from_page = from_page or 1
    unfreeze_measures = unfreeze_measures or false
    local page = finale.FCPage()
    if page:Load(from_page) then
        page:UpdateLayout(unfreeze_measures)
    end
end

--[[
% get_current_part()

Returns the currently selected part or score.

: (FCPart)
]]
function library.get_current_part()
    local parts = finale.FCParts()
    parts:LoadAll()
    return parts:GetCurrent()
end

--[[
% get_page_format_prefs()

Returns the default page format prefs for score or parts based on which is currently selected.

: (FCPageFormatPrefs)
]]
function library.get_page_format_prefs()
    local current_part = library.get_current_part()
    local page_format_prefs = finale.FCPageFormatPrefs()
    local success = false
    if current_part:IsScore() then
        success = page_format_prefs:LoadScore()
    else
        success = page_format_prefs:LoadParts()
    end
    return page_format_prefs, success
end

--[[
% get_smufl_metadata_file(font_info)

@ [font_info] (FCFontInfo) if non-nil, the font to search for; if nil, search for the Default Music Font
: (file handle|nil)
]]
function library.get_smufl_metadata_file(font_info)
    if nil == font_info then
        font_info = finale.FCFontInfo()
        font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    end

    local try_prefix = function(prefix, font_info)
        local file_path = prefix .. "/SMuFL/Fonts/" .. font_info.Name .. "/" .. font_info.Name .. ".json"
        return io.open(file_path, "r")
    end

    local smufl_json_user_prefix = ""
    if finenv.UI():IsOnWindows() then
        smufl_json_user_prefix = os.getenv("LOCALAPPDATA")
    else
        smufl_json_user_prefix = os.getenv("HOME") .. "/Library/Application Support"
    end
    local user_file = try_prefix(smufl_json_user_prefix, font_info)
    if nil ~= user_file then
        return user_file
    end

    local smufl_json_system_prefix = "/Library/Application Support"
    if finenv.UI():IsOnWindows() then
        smufl_json_system_prefix = os.getenv("COMMONPROGRAMFILES") 
    end
    return try_prefix(smufl_json_system_prefix, font_info)
end

--[[
% is_font_smufl_font(font_info)

@ [font_info] (FCFontInfo) if non-nil, the font to check; if nil, check the Default Music Font
: (boolean)
]]
function library.is_font_smufl_font(font_info)
    if nil == font_info then
        font_info = finale.FCFontInfo()
        font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    end
    
    if finenv.RawFinaleVersion >= library.finale_version(27, 1) then
        if nil ~= font_info.IsSMuFLFont then -- if this version of the lua interpreter has the IsSMuFLFont property (i.e., RGP Lua 0.59+)
            return font_info.IsSMuFLFont
        end
    end
    
    local smufl_metadata_file = library.get_smufl_metadata_file(font_info)
    if nil ~= smufl_metadata_file then
        io.close(smufl_metadata_file)
        return true
    end
    return false
end

--[[
% simple_input(title, text)

Creates a simple dialog box with a single 'edit' field for entering values into a script, similar to the old UserValueInput command. Will automatically resize the width to accomodate longer strings.

@ [title] (string) the title of the input dialog box
@ [text] (string) descriptive text above the edit field
: string
]]
function library.simple_input(title, text)
  local return_value = finale.FCString()
  return_value.LuaString = ""
  local str = finale.FCString()
  local min_width = 160
  --
  function format_ctrl(ctrl, h, w, st)
      ctrl:SetHeight(h)
      ctrl:SetWidth(w)
      str.LuaString = st
      ctrl:SetText(str)
  end -- function format_ctrl
  --
  title_width = string.len(title) * 6 + 54
  if title_width > min_width then min_width = title_width end
  text_width = string.len(text) * 6
  if text_width > min_width then min_width = text_width end
  --
  str.LuaString = title
  local dialog = finale.FCCustomLuaWindow()
  dialog:SetTitle(str)
  local descr = dialog:CreateStatic(0, 0)
  format_ctrl(descr, 16, min_width, text)
  local input = dialog:CreateEdit(0, 20)
  format_ctrl(input, 20, min_width, "") -- edit "" for defualt value
  dialog:CreateOkButton()
  dialog:CreateCancelButton()
  --
  function callback(ctrl)
  end -- callback
  --
  dialog:RegisterHandleCommand(callback)
  --
  if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
    return_value.LuaString = input:GetText(return_value)
    --print(return_value.LuaString)
    return return_value.LuaString
  -- OK button was pressed
  end
end -- function simple_input








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
    local font_metadata = luna.decode(json)

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

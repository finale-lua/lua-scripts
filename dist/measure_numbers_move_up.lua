function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 21, 2020"
    finaleplugin.CategoryTags = "Measure"
    return "Measure Numbers Move Up", "Measure Numbers Move Up", "Moves selected measure numbers up by one staff space."
end

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








local move_amount = 24 -- evpus

function measure_numbers_move_up()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local meas_num_regions = finale.FCMeasureNumberRegions()
    meas_num_regions:LoadAll()
    local parts = finale.FCParts()
    parts:LoadAll()
    local current_part = parts:GetCurrent()
    local current_is_part = not current_part:IsScore()
    local sel_region = library.get_selected_region_or_whole_doc()

    local cells = finale.FCCells()
    cells:ApplyRegion(sel_region)
    for cell in each(cells) do
        local system = systems:FindMeasureNumber(cell.Measure)
        local meas_num_region = meas_num_regions:FindMeasure(cell.Measure)
        if (nil ~= system) and (nil ~= meas_num_region) then
            if library.is_default_measure_number_visible_on_cell(meas_num_region, cell, system, current_is_part) then
                local sep_nums = finale.FCSeparateMeasureNumbers()
                sep_nums:LoadAllInCell(cell)
                if (sep_nums.Count > 0) then
                    for sep_num in each(sep_nums) do
                        sep_num.VerticalPosition = sep_num.VerticalPosition + move_amount
                        sep_num:Save()
                    end
                else
                    local sep_num = finale.FCSeparateMeasureNumber()
                    sep_num:ConnectCell(cell)
                    sep_num:AssignMeasureNumberRegion(meas_num_region)
                    sep_num.VerticalPosition = sep_num.VerticalPosition + move_amount
                    --sep_num:SetShowOverride(true) -- enable this line if you want to force show the number. otherwise it will show or hide based on the measure number region
                    if sep_num:SaveNew() then
                        local measure = finale.FCMeasure()
                        measure:Load(cell.Measure)
                        measure:SetContainsManualMeasureNumbers(true)
                        measure:Save()
                    end
                end
            end
        end
    end
end

measure_numbers_move_up()

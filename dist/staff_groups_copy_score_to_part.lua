function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "Staff"
    return "Group Copy Score to Part", "Group Copy Score to Part",
           "Copies any applicable groups from the score to the current part in view."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
--[[
$module Library
]]
local library = {}

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

    local smufl_json_system_prefix = "/Library/Application Support"
    if finenv.UI():IsOnWindows() then
        smufl_json_system_prefix = os.getenv("COMMONPROGRAMFILES") 
    end
    local system_file = try_prefix(smufl_json_system_prefix, font_info)
    if nil ~= system_file then
        return system_file
    end

    local smufl_json_user_prefix = ""
    if finenv.UI():IsOnWindows() then
        smufl_json_user_prefix = os.getenv("LOCALAPPDATA")
    else
        smufl_json_user_prefix = os.getenv("HOME") .. "/Library/Application Support"
    end
    return try_prefix(smufl_json_user_prefix, font_info)
end

--[[
% is_font_smufl_font(font_info)

@ [font_info] (FCFontInfo) if non-nil, the font to check; if nil, check the Default Music Font
: (boolean)
]]
function library.is_font_smufl_font(font_info)
    local smufl_metadata_file = library.get_smufl_metadata_file(font_info)
    if nil ~= smufl_metadata_file then
        io.close(smufl_metadata_file)
        return true
    end
    return false
end




function staff_groups_copy_score_to_part()

    local parts = finale.FCParts()
    parts:LoadAll()
    local current_part = parts:GetCurrent()
    if current_part:IsScore() then
        finenv.UI():AlertInfo("This script is only valid when viewing a part.", "Not In Part View")
        return
    end

    local del_groups = finale.FCGroups()
    del_groups:LoadAll()
    for del_group in each(del_groups) do
        if not library.staff_group_is_multistaff_instrument(del_group) then
            del_group:DeleteData()
        end
    end

    local score = parts:GetScore()
    score:SwitchTo()
    local staff_groups = finale.FCGroups()
    staff_groups:LoadAll()
    for staff_group in each(staff_groups) do
        local start_staff = staff_group.StartStaff
        local end_staff = staff_group.EndStaff
        if not library.staff_group_is_multistaff_instrument(staff_group) then
            score:SwitchBack()
            if current_part:IsStaffIncluded(start_staff) and current_part:IsStaffIncluded(end_staff) then
                local new_group = finale.FCGroup()
                new_group.StartStaff = staff_group.StartStaff
                new_group.EndStaff = staff_group.EndStaff
                new_group.StartMeasure = staff_group.StartMeasure
                new_group.EndMeasure = staff_group.EndMeasure
                new_group.AbbreviatedNameAlign = staff_group.AbbreviatedNameAlign
                new_group.AbbreviatedNameExpandSingle = staff_group.AbbreviatedNameExpandSingle
                new_group.AbbreviatedNameHorizontalOffset = staff_group.AbbreviatedNameHorizontalOffset
                new_group.AbbreviatedNameJustify = staff_group.AbbreviatedNameJustify
                new_group.AbbreviatedNameVerticalOffset = staff_group.AbbreviatedNameVerticalOffset
                new_group.BarlineShapeID = staff_group.BarlineShapeID
                new_group.BarlineStyle = staff_group.BarlineStyle
                new_group.BarlineUse = staff_group.BarlineUse
                new_group.BracketHorizontalPos = staff_group.BracketHorizontalPos
                new_group.BracketSingleStaff = staff_group.BracketSingleStaff
                new_group.BracketStyle = staff_group.BracketStyle
                new_group.BracketVerticalBottomPos = staff_group.BracketVerticalBottomPos
                new_group.BracketVerticalTopPos = staff_group.BracketVerticalTopPos
                new_group.DrawBarlineMode = staff_group.DrawBarlineMode
                new_group.EmptyStaffHide = staff_group.EmptyStaffHide
                new_group.FullNameAlign = staff_group.FullNameAlign
                new_group.FullNameExpandSingle = staff_group.FullNameExpandSingle
                new_group.FullNameHorizontalOffset = staff_group.FullNameHorizontalOffset
                new_group.FullNameJustify = staff_group.FullNameJustify
                new_group.FullNameVerticalOffset = staff_group.FullNameVerticalOffset
                new_group.ShowGroupName = staff_group.ShowGroupName
                new_group.UseAbbreviatedNamePositioning = staff_group.UseAbbreviatedNamePositioning
                new_group.UseFullNamePositioning = staff_group.UseFullNamePositioning
                if staff_group.HasFullName and (0 ~= staff_group:GetFullNameID()) then
                    new_group:SaveNewFullNameBlock(staff_group:CreateFullNameString())
                end
                if staff_group.HasAbbreviatedName and (0 ~= staff_group:GetAbbreviatedNameID()) then
                    new_group:SaveNewAbbreviatedNameBlock(staff_group:CreateAbbreviatedNameString())
                end
                new_group:SaveNew(0)
            end
            score:SwitchTo()
        end
    end
    score:SwitchBack()
end

staff_groups_copy_score_to_part()

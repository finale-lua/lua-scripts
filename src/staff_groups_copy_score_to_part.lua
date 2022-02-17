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

local library = require("library.general_library")

function set_draw_barline_mode(new_group, source_group)
    -- This function works around a bug in JW Lua (as of v0.54) where assigning 0 to FCGroup.DrawBarlineMode
    -- causes 1 to be assigned and assigning 1 causes 0 to be assigned.
    new_group.DrawBarlineMode = source_group.DrawBarlineMode
    -- Only do something if this version of JW Lua has the bug.
    if new_group.DrawBarlineMode ~= source_group.DrawBarlineMode then
        if source_group.DrawBarlineMode == finale.GROUPBARLINESTYLE_ONLYON then
            new_group.DrawBarlineMode = finale.GROUPBARLINESTYLE_ONLYBETWEEN
        elseif source_group.DrawBarlineMode == finale.GROUPBARLINESTYLE_ONLYBETWEEN then
            new_group.DrawBarlineMode  = finale.GROUPBARLINESTYLE_ONLYON
        end
    end
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
                set_draw_barline_mode(new_group, staff_group) -- use workaround function for JW Lua bug (see comments in function)
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

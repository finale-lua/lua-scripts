--[[
$module Dynamics
]] --

local metrics = require("library.metrics")
local score = require("library.score")
local expression = require("library.expression")

local dynamics = {}

--[[
% expressions_set_vertical_pos

Sets the vertical position of 'dynamics' and 'expressive text' to the input target position.
Also returns a table containing left and right coordinates for the expressions, to adjust hairpins.

@ region (FCMusicRegion) 
@ target_pos (number) Target for dynamic vertical placement

@ cell_metrics (table)

@ cushions (table) Every member of this table is OPTIONAL (values will get replaced by defaults if missing). The values determine the extra space to add between dynamics and various elements. The table parameters are:
@ cushions.exp_left (number) Number of EVPUs to separate the left side of hairpins from expressions.
@ cushions.exp_right (number) Number of EVPUs to separate the right side of hairpins from expressions.
@ cushions.hairpin_vert_off (number) EVPUs to offset hairpins from expressions.

:(table) Each entry has two values, left and right. These are numbers representing the points hairpin endpoints should not overlap.
]]
function dynamics.expressions_set_vertical_pos(region, target_pos, cell_metrics, cushions)
    local exclusion_zones = {}

    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    local staff_system = staff_systems:FindMeasureNumber(region.StartMeasure)

    if not cushions or not cushions.exp_left or not cushions.exp_right then
        cushions.exp_left = 24
        cushions.exp_right = 24
    end

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)

    for express in each(expressions) do
        if staff_systems:FindMeasureNumber(express.Measure):GetItemNo() ~= staff_system.ItemNo then
            staff_system = staff_systems:FindMeasureNumber(express.Measure)
            cell_metrics = metrics.calc_cell_metrics(express.Measure, express.Staff)
        end

        local create_def = express:CreateTextExpressionDef()
        local cat_def = finale.FCCategoryDef()
        if cat_def:Load(create_def:GetCategoryID()) then
            if ((cat_def:GetID() == finale.DEFAULTCATID_DYNAMICS) or 
                (string.find(cat_def:CreateName().LuaString, "Dynamic"))) or
            (cat_def:GetID() == finale.DEFAULTCATID_EXPRESSIVETEXT) then
                if not cell_metrics or not cell_metrics.system_scaling or not cell_metrics.horiz_stretch then
                    cell_metrics = metrics.calc_cell_metrics(express.Measure, express.Staff)
                end

                local exp_top, exp_bottom, exp_left, exp_right, exp_y, exp_x = metrics.calc_expression_bounding_box(express, cell_metrics)

                local vert_pos_difference = (target_pos - exp_y) / cell_metrics.system_scaling
                express:SetVerticalPos(express:GetVerticalPos() + vert_pos_difference)
                express:Save()

                local exclusion_zone = {left = (exp_left - cushions.exp_left), right = (exp_right + cushions.exp_right)}

                table.insert(exclusion_zones, exclusion_zone)
            end
        end
    end
    return exclusion_zones
end

--[[
% hairpins_set_vertical_pos

Sets the vertical position of hairpins to the input target position.
ALSO adjusts horizontal position to avoid any analyzed expressions.

@ region (FCMusicRegion) 
@ target_pos (number) Target for hairpin vertical placement
@ excl_zones (table) Each value is another table containing two values, zone.left and zone.right.
@ cell_metrics (table) To pass on.
@ hairpin_vert_off (number) An offset in EVPUs to align hairpins and expressions. If not provided, will default to 10.
]]
function dynamics.hairpins_set_vertical_pos(region, target_pos, excl_zones, cell_metrics, hairpin_vert_off)
    if not hairpin_vert_off then
        hairpin_vert_off = 10
    end

    if not cell_metrics or not cell_metrics.system_scaling then
        cell_metrics = metrics.calc_cell_metrics(region.StartMeasure, region.StartStaff)
    end

    local marks = finale.FCSmartShapeMeasureMarks()
    local ui = finenv.UI()  
    marks:LoadAll()

    marks:KeepStaffOnly(region.StartStaff)
    marks:KeepHairpinsOnly()

    if not ui:IsPageView() then
        marks:RemoveDuplicateReferences()
    end

    for mark in each(marks) do
        if region:IsMeasureIncluded(mark:GetMeasure()) then
            local hairpin_data = metrics.calc_hairpin_from_mark(mark, region, cell_metrics)
            local hairpin = hairpin_data.hairpin
            local left_seg = hairpin:GetTerminateSegmentLeft()
            local right_seg = hairpin:GetTerminateSegmentRight()

            local vert_pos_difference = ((hairpin_data.left_y - target_pos) - hairpin_vert_off) / cell_metrics.system_scaling

            local adjust_left_x = false
            local adjust_right_x = false

            if not hairpin_data.crosses_system then
                left_seg:SetEndpointOffsetY(left_seg:GetEndpointOffsetY() - vert_pos_difference)
                right_seg:SetEndpointOffsetY(right_seg:GetEndpointOffsetY() - vert_pos_difference)
                adjust_left_x = true
                adjust_right_x = true

            elseif hairpin_data.crosses_system then
                if region:IsMeasureIncluded(left_seg:GetMeasure()) then
                    vert_pos_difference = ((hairpin_data.left_y - target_pos) - hairpin_vert_off) / cell_metrics.system_scaling
                    left_seg:SetEndpointOffsetY(left_seg:GetEndpointOffsetY() - vert_pos_difference)
                    adjust_left_x = true
                end

                if region:IsMeasureIncluded(right_seg:GetMeasure()) then
                    vert_pos_difference = ((hairpin_data.right_y - target_pos) - hairpin_vert_off) / cell_metrics.system_scaling
                    right_seg:SetEndpointOffsetY(right_seg:GetEndpointOffsetY() - vert_pos_difference)
                    adjust_right_x = true
                end
            end

            if adjust_left_x then
                for i, zone in pairs(excl_zones) do
                    if hairpin_data.left_x > zone.left and hairpin_data.left_x < zone.right then
                        local horiz_diff = (zone.right - hairpin_data.left_x)
                        local new_left = left_seg:GetEndpointOffsetX() + horiz_diff
                        left_seg:SetEndpointOffsetX(new_left)
                    end
                end
            end

            if adjust_right_x then
                for i, zone in pairs(excl_zones) do
                    if hairpin_data.right_x > zone.left and hairpin_data.right_x < zone.right then
                        local horiz_diff = (zone.left - hairpin_data.right_x)
                        local new_right = right_seg:GetEndpointOffsetX() + horiz_diff
                        right_seg:SetEndpointOffsetX(new_right)
                    end
                end
            end

            hairpin:Save()
        end
    end
end

--[[
% set_vertical_pos

Sets the vertical position of dynamics and hairpins in the given region. This includes expressive text.

@ region (FCMusicRegion) The region to process.
@ placement_mode (string) If absent, defaults to "auto" (dynamics are placed below the staff, unless it is a voice staff).
Other options include: "above" (position above the staff), "below" (position below the staff), and "align" (dynamics are lined up with the farthest element. If any of the dynamics are above the staff, they are all aligned there.)

@ cushions (table) Every member of this table is OPTIONAL (values will get replaced by defaults if missing). The values determine the extra space to add between dynamics and various elements. The table parameters are:
@ cushions.staff_below (number) Number of EVPUs to put between the bottom staffline and dynamics.
@ cushions.entry_below (number) Number of EVPUs to put between entries below the staff and dynamics (similar to "additional entry offset")
@ cushions.staff_above (number) Number of EVPUs o put between the top staffline and dynamics.
@ cushions.entry_above (number) Number of EVPUs to put between entries above the staff and dynamics.
@ cushions.exp_left (number) Number of EVPUs to separate the left side of hairpins from expressions.
@ cushions.exp_right (number) Number of EVPUs to separate the right side of hairpins from expressions.
@ cushions.hairpin_vert_off (number) Number of EVPUs to adjust hairpins in relation to expressions.
]]
function dynamics.set_vertical_pos(region, placement_mode, cushions)
    region:AssureSortedStaves()
    if not placement_mode then
        placement_mode = "auto"
    end

    local ui = finenv.UI()
    if ui:IsPageView() then
        local staff_systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
        local start_system = staff_systems:FindMeasureNumber(region.StartMeasure)
        local end_system = staff_systems:FindMeasureNumber(region.EndMeasure)

        for staff_system in each(staff_systems) do
            local system_staves = staff_system:CreateSystemStaves()
            for system_staff in each(system_staves) do
                if (staff_system.ItemNo >= start_system.ItemNo) and (staff_system.ItemNo <= end_system.ItemNo) then
                    if region:IsStaffIncluded(system_staff.Staff) then
                        local staff_region = finale.FCMusicRegion()
                        staff_region:SetStartStaff(system_staff.Staff)
                        staff_region:SetEndStaff(system_staff.Staff)

                        if staff_system:ContainsMeasure(region.StartMeasure) then
                            staff_region:SetStartMeasure(region.StartMeasure)
                            staff_region:SetStartMeasurePos(region.StartMeasurePos)
                        else
                            staff_region:SetStartMeasure(staff_system:GetFirstMeasure())
                            staff_region:SetStartMeasurePos(0)
                        end

                        if staff_system:ContainsMeasure(region.EndMeasure) then
                            staff_region:SetEndMeasure(region.EndMeasure)
                            staff_region:SetEndMeasurePos(region.EndMeasurePos)
                        else
                            local system_last_meas = staff_system:GetNextSysMeasure() - 1
                            staff_region:SetEndMeasure(system_last_meas)
                            staff_region:SetEndMeasurePos(metrics.calc_measure_duration(system_last_meas))
                        end

                        local cell_metrics = metrics.calc_cell_metrics(staff_region.StartMeasure, staff_region.StartStaff)

                        local dynamic_pos = cell_metrics.page_height
                        local is_vocal_staff = score.calc_voice_staff(staff_region:GetStartStaff())
                        if placement_mode == "above" or (placement_mode == "auto" and is_vocal_staff) then
                            dynamic_pos = 0
                            dynamic_pos = metrics.calc_dynamic_vertical_pos_above(staff_region, cell_metrics, cushions)
                        elseif placement_mode == "align" then
                            dynamic_pos = metrics.calc_dynamic_far_pos(staff_region, cell_metrics)
                        else
                            dynamic_pos = metrics.calc_dynamic_vertical_pos_below(staff_region, cell_metrics, cushions)
                        end

                        local exclusion_zones = dynamics.expressions_set_vertical_pos(staff_region, dynamic_pos, cell_metrics, cushions)
                        dynamics.hairpins_set_vertical_pos(staff_region, dynamic_pos, exclusion_zones, cell_metrics,  cushions.hairpin_vert_off)
                    end
                end
            end
        end
    else -- for Scroll view
        local system_staves = finale.FCSystemStaves()
        system_staves:LoadAllForRegion(region)
        for staff in each(system_staves) do
            local staff_region = finale.FCMusicRegion()
            staff_region:SetStartMeasure(region.StartMeasure)
            staff_region:SetStartMeasurePos(region.StartMeasurePos)
            staff_region:SetEndMeasure(region.EndMeasure)
            staff_region:SetEndMeasurePos(region.EndMeasurePos)
            staff_region:SetStartStaff(staff.Staff)
            staff_region:SetEndStaff(staff.Staff)

            local cell_metrics = metrics.calc_cell_metrics(staff_region.StartMeasure, staff_region.StartStaff)
            local dynamic_pos = 0
            local is_vocal_staff = score.calc_voice_staff(staff_region:GetStartStaff())

            if placement_mode == "above" or (placement_mode == "auto" and is_vocal_staff) then
                dynamic_pos = 0
                dynamic_pos = metrics.calc_dynamic_vertical_pos_above(staff_region, cell_metrics, cushions)
            elseif placement_mode == "align" then
                dynamic_pos = metrics.calc_dynamic_far_pos(staff_region, cell_metrics, cushions.hairpin_vert_off)
            else
                dynamic_pos = metrics.calc_dynamic_vertical_pos_below(staff_region, cell_metrics, cushions)
            end

            local exclusion_zones = dynamics.expressions_set_vertical_pos(staff_region, dynamic_pos, cell_metrics, cushions)

            dynamics.hairpins_set_vertical_pos(staff_region, dynamic_pos, exclusion_zones, cell_metrics,  cushions.hairpin_vert_off)
        end
    end
end

--[[
% nudge_expressions

Nudges dynamics and expressive text dynamics by the input amount.

@ region (FCMusicRegion) The region to process.
@ nudge_by (number) EVPUs to nudge by.
]]
function dynamics.nudge_expressions(region, nudge_by)
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    for express in each(expressions) do
        local create_def = express:CreateTextExpressionDef()
        local cat_def = finale.FCCategoryDef()
        if cat_def:Load(create_def:GetCategoryID()) then
            if ((cat_def:GetID() == finale.DEFAULTCATID_DYNAMICS) or 
                (string.find(cat_def:CreateName().LuaString, "Dynamic"))) or
            (cat_def:GetID() == finale.DEFAULTCATID_EXPRESSIVETEXT) then
                local system_scale = metrics.calc_system_scaling(express:GetMeasure(), express:GetStaff())
                express:SetVerticalPos(express:GetVerticalPos() + (nudge_by * system_scale))
                express:Save()
            end
        end
    end
end

--[[
% nudge_hairpins

Nudges hairpins by the input amount.

@ region (FCMusicRegion) The region to process.
@ nudge_by (number) EVPUs to nudge by.
]]
function dynamics.nudge_hairpins(region, nudge_by)
    local marks = finale.FCSmartShapeMeasureMarks()
    marks:LoadAll()

    marks:KeepStaffOnly(region.StartStaff)
    marks:KeepHairpinsOnly()

    for mark in each(marks) do
        if region:IsMeasureIncluded(mark:GetMeasure()) then
            local hairpin_data = metrics.calc_hairpin_from_mark(mark, region)
            local hairpin = hairpin_data.hairpin
            local left_seg = hairpin:GetTerminateSegmentLeft()
            local right_seg = hairpin:GetTerminateSegmentRight()
            local system_scale = metrics.calc_system_scaling(left_seg:GetMeasure(), left_seg:GetStaff())
            nudge_by = nudge_by * system_scale
            if not hairpin_data.crosses_system then
                left_seg:SetEndpointOffsetY(left_seg:GetEndpointOffsetY() + nudge_by)
                right_seg:SetEndpointOffsetY(right_seg:GetEndpointOffsetY() + nudge_by)
            elseif hairpin_data.crosses_system then
                if region:IsMeasureIncluded(left_seg:GetMeasure()) then
                    left_seg:SetEndpointOffsetY(left_seg:GetEndpointOffsetY() + nudge_by)
                elseif region:IsMeasureIncluded(right_seg:GetMeasure()) then
                    right_seg:SetEndpointOffsetY(right_seg:GetEndpointOffsetY()  + nudge_by)
                end
            end
            hairpin:Save()
        end
    end
end


--[[
% nudge

Nudges dynamics by the input amount.

@ region (FCMusicRegion) The region to process.
@ nudge_by (number) EVPUs to nudge by.
]]
function dynamics.nudge(region, nudge_by)
    dynamics.nudge_expressions(region, nudge_by)
    dynamics.nudge_hairpins(region, nudge_by)
end

return dynamics

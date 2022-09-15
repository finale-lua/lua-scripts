--[[
$module Metrics
]] --
local metrics = {}

local expression = require("library.expression")

--[[
% calc_current_page_height

Returns the page height for the given measure (in the current view).

@ measure (number) The measure number
:(number) The current page height in EVPUs
]]
function metrics.calc_current_page_height(measure)
    local pages = finale.FCPages()
    pages:LoadAll()
    local page_height = nil
    for page in each(pages) do
        local start_measure = page:CalcFirstMeasure()
        local end_measure = page:CalcLastMeasure()
        if ((start_measure <= measure) and (end_measure >= measure)) then
            page_height = page:GetHeight()
        end
    end
    return page_height
end

--[[
% calc_cell_metrics

Returns a table of all cell metrics (including the height of the current page), that can be passed from function to function.

@ measure (number) The measure number of the cell.
@ staff (number) The staff number of the cell.

:(table) A table with the following keys:
:(number) .measure
:(number) .staff
:(number) .page_height
:(number) .system_scaling
:(number) .staff_scaling
:(number) .horiz_stretch
:(number) left_edge
:(number) width
:(number) music_start
:(number) music_width
:(number) back_repeat
:(number) front_repeat
:(number) system_top
:(number) top_staffline
:(number) bottom_staffline
]]
function metrics.calc_cell_metrics(measure, staff)
    local cell_metrics_tbl = {} 
    cell_metrics_tbl.page_height = metrics.calc_current_page_height(measure)
    local cell = finale.FCCell(measure, staff)
    local cell_metrics = cell:CreateCellMetrics()
    cell_metrics_tbl.measure = measure
    cell_metrics_tbl.staff = staff

    cell_metrics_tbl.system_scaling = cell_metrics:GetSystemScaling() / 10000
    cell_metrics_tbl.staff_scaling = cell_metrics:GetStaffScaling() / 10000
    cell_metrics_tbl.horiz_stretch = cell_metrics:GetHorizontalStretch() / 10000
    cell_metrics_tbl.left_edge = cell_metrics:GetLeftEdge()
    cell_metrics_tbl.width = cell_metrics:GetWidth()
    cell_metrics_tbl.music_start = cell_metrics:GetMusicStartPos()
    cell_metrics_tbl.music_width = cell_metrics:GetMusicWidth()
    cell_metrics_tbl.back_repeat = cell_metrics:GetBackRepeatWidth()
    cell_metrics_tbl.front_repeat = cell_metrics:GetFrontRepeatWidth()
    cell_metrics_tbl.front_repeat = cell_metrics:GetFrontRepeatWidth()
    cell_metrics_tbl.system_top = cell_metrics:GetSystemTopPos()

    cell_metrics_tbl.top_staffline = cell_metrics:GetTopStafflinePos() * cell_metrics_tbl.system_scaling
    cell_metrics_tbl.bottom_staffline = cell_metrics:GetBottomStafflinePos() * cell_metrics_tbl.system_scaling

    cell_metrics:FreeMetrics()
    return cell_metrics_tbl
end

--[[
% calc_system_scaling

Returns the cumulative system scaling factor for a given measure/staff.

@ measure (number) The measure number
@ staff (number) The staff number
:(number) The system scaling factor
]]
function metrics.calc_system_scaling(measure, staff)
    local cell = finale.FCCell(measure, staff)
    local cell_metrics = cell:CreateCellMetrics()
    local system_scaling = cell_metrics:GetSystemScaling() / 10000
    cell_metrics:FreeMetrics()
    return system_scaling
end

--[[
% calc_staff_scaling

Returns the staff scaling factor for a given measure/staff.

@ measure (number) The measure number
@ staff (number) The staff number
:(number) The staff scaling factor
]]
function metrics.calc_staff_scaling(measure, staff)
    local cell = finale.FCCell(measure, staff)
    local cell_metrics = cell:CreateCellMetrics()
    local staff_scaling = cell_metrics:GetSystemScaling() / 10000
    cell_metrics:FreeMetrics()
    return staff_scaling
end

--[[
% calc_horizontal_stretch

Returns the staff scaling factor for a given measure/staff.

@ measure (number) The measure number
@ staff (number) The staff number
:(number) The staff scaling factor
]]
function metrics.calc_horizontal_stretch(measure, staff)
    local cell = finale.FCCell(measure, staff)
    local cell_metrics = cell:CreateCellMetrics()
    local horz_stretch = cell_metrics:GetHorizontalStretch() / 10000
    cell_metrics:FreeMetrics()
    return horz_stretch
end


--[[
% calc_top_staffline_pos(measure, staff)

@ measure (number) The measure number
@ staff (number) The staff number
: (number) The position of the top staff line (from the bottom of the page)
]]
function metrics.calc_top_staffline_pos(measure, staff)
    local cell = finale.FCCell(measure, staff)
    local cell_metrics = cell:CreateCellMetrics()
    local system_scaling = cell_metrics:GetSystemScaling()
    local top_staff_line_pos = cell_metrics:GetTopStafflinePos() * system_scaling
    cell_metrics:FreeMetrics()
    return top_staff_line_pos
end

--[[
% calc_bottom_staffline_pos(measure, staff)

@ measure (number) The measure number
@ staff (number) The staff number
: (number) The position of the bottom staff line (from the bottom of the page)
]]
function metrics.calc_bottom_staffline_pos(measure, staff)
    local cell = finale.FCCell(measure, staff)
    local cell_metrics = cell:CreateCellMetrics()
    local system_scaling = cell_metrics:GetSystemScaling()
    local bottom_staff_line_pos = cell_metrics:GetBottomStafflinePos() * system_scaling
    cell_metrics:FreeMetrics()
    return bottom_staff_line_pos
end

--[[
% calc_top_staffline_pos_entry(entry)

Returns the top staffline position for a given entry.

@ entry (FCNoteEntry) 
: (number) The position of the top staff line (from the bottom of the page)
]]
function metrics.calc_top_staffline_pos_entry(entry)
    local cell_metrics = finale.FCCellMetrics()

    if cell_metrics:LoadAtEntry(entry) then
        local system_scaling = cell_metrics:GetSystemScaling()
        local top_staff_line_pos = cell_metrics:GetTopStafflinePos() * system_scaling
        cell_metrics:FreeMetrics()
        return top_staff_line_pos
    else 
        return nil
    end
end

--[[
% calc_bottom_staffline_pos_entry(entry)

Returns the bottom staffline position for a given entry.

@ entry (FCNoteEntry) 
: (number) The position of the bottom staff line (from the bottom of the page)
]]
function metrics.calc_bottom_staffline_pos_entry(entry)
    local cell_metrics = finale.FCCellMetrics()

    if cell_metrics:LoadAtEntry(entry) then
        local system_scaling = cell_metrics:GetSystemScaling()
        local bottom_staff_line_pos = cell_metrics:GetTopStafflinePos() * system_scaling
        cell_metrics:FreeMetrics()
        return bottom_staff_line_pos
    else 
        return nil
    end
end

--[[
% calc_entry_top_pos

Returns the top position of an entry (noteheads or stem), adjusted for staff scaling.

@ entry (FCNoteEntry) The entry
@ cell_metrics (table) Needs .system_scaling and .staff_scaling. If not found, will recalculate.

:(number) The top position
]]
function metrics.calc_entry_top_pos(entry, cell_metrics)
    if not cell_metrics or not cell_metrics.staff_scaling or not cell_metrics.system_scaling then
        cell_metrics = metrics.calc_cell_metrics(entry.Measure, entry.Staff)
    end
    local entry_metrics = finale.FCEntryMetrics()
    entry_metrics:Load(entry)

    local entry_top_pos = entry_metrics:GetTopPosition(0) / cell_metrics.staff_scaling * cell_metrics.system_scaling
    entry_top_pos = entry_top_pos - cell_metrics.top_staffline
    entry_metrics:FreeMetrics()
    return entry_top_pos
end

--[[
% calc_entry_bottom_pos

Returns the bottom position of an entry (noteheads or stem), adjusted for staff scaling.

@ entry (FCNoteEntry) The entry
@ cell_metrics (table) Needs .system_scaling and .staff_scaling. If not found, will recalculate.

:(number) The bottom position of the entry
]]
function metrics.calc_entry_bottom_pos(entry, cell_metrics)
    if not cell_metrics or not cell_metrics.staff_scaling or not cell_metrics.system_scaling or not cell_metrics.top_staffline then
        cell_metrics = metrics.calc_cell_metrics(entry.Measure, entry.Staff)
    end
    local entry_metrics = finale.FCEntryMetrics()
    entry_metrics:Load(entry)

    local entry_bottom_pos = entry_metrics:GetBottomPosition(0) / cell_metrics.staff_scaling * cell_metrics.system_scaling
    entry_bottom_pos = entry_bottom_pos - cell_metrics.top_staffline
    entry_metrics:FreeMetrics()
    return entry_bottom_pos
end

--[[
% calc_lowest_entry

Returns the lowest entry in a given region.

@ region (FCMusicRegion) The region to check.
@ cell_metrics (table) Needs .page_height. If not found, will recalculate.
:(number) The position of the lowest entry.
]]
function metrics.calc_lowest_entry(region, cell_metrics)
    if not cell_metrics or not cell_metrics.page_height then
        cell_metrics.page_height =  metrics.calc_cell_metrics(region.StartMeasure, region.StartStaff)
    end
    local lowest_entry = cell_metrics.page_height
    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    local staff_system = staff_systems:FindMeasureNumber(region.StartMeasure)

    for entry in eachentry(region) do
        if staff_systems:FindMeasureNumber(entry.Measure):GetItemNo() ~= staff_system.ItemNo then
            staff_system = staff_systems:FindMeasureNumber(entry.Measure)
            cell_metrics = metrics.calc_cell_metrics(entry.Measure, entry.Staff)
        end
        local entry_y = metrics.calc_entry_bottom_pos(entry, cell_metrics)
        if entry_y < lowest_entry then
            lowest_entry = entry_y
        end
    end
    return lowest_entry
end

--[[
% calc_highest_entry

Returns the highest entry in a given region.

@ region (FCMusicRegion) The region to check.
@ cell_metrics (table) For passing along
:(number) The position of the highest entry.
]]
function metrics.calc_highest_entry(region, cell_metrics)
    local highest_entry = 0
    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    local staff_system = staff_systems:FindMeasureNumber(region.StartMeasure)

    for entry in eachentry(region) do
        if staff_systems:FindMeasureNumber(entry.Measure):GetItemNo() ~= staff_system.ItemNo then
            staff_system = staff_systems:FindMeasureNumber(entry.Measure)
            cell_metrics = metrics.calc_cell_metrics(entry.Measure, entry.Staff)
        end

        local entry_y = metrics.calc_entry_top_pos(entry, cell_metrics)
        if entry_y > highest_entry then
            highest_entry = entry_y
        end
    end
    return highest_entry
end

--[[
% calc_lowest_entry_artic

Returns the lowest position from either the entry OR any articulations attached to that entry for a given region.

@ region (FCMusicRegion) The region to check.
@ cell_metrics (table) For passing along
:(number) The lowest position found (entry OR articulation)
]]
function metrics.calc_lowest_entry_artic(region, cell_metrics)
    local lowest_entry = metrics.calc_current_page_height(region:GetStartMeasure())
    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    local staff_system = staff_systems:FindMeasureNumber(region.StartMeasure)

    for entry in eachentry(region) do
        if staff_systems:FindMeasureNumber(express.Measure):GetItemNo() ~= staff_system.ItemNo then
            staff_system = staff_systems:FindMeasureNumber(express.Measure)
            cell_metrics = metrics.calc_cell_metrics(express.Measure, express.Staff)
        end

        local entry_y = metrics.calc_entry_bottom_pos(entry, cell_metrics)
        if entry_y < lowest_entry then
            lowest_entry = entry_y
        end
        local artics = entry:CreateArticulations()
        for articulation in each(artics) do
            local artic_bottom = metrics.calc_articulation_bottom_pos(articulation, cell_metrics)
            if artic_bottom < lowest_entry then
                lowest_entry = artic_bottom
            end
        end
    end
    return lowest_entry
end

--[[
% calc_expression_bounding_box

Returns the bounding box edges, in EVPUs.

@ expression (FCExpression) The expression
@ cell_metrics (table) Needs .system_scaling. Will recalculate if missing.

:(number) The top edge.
:(number) The bottom edge.
:(number) The left edge.
:(number) The right edge.
]]
function metrics.calc_expression_bounding_box(express, cell_metrics)
    if not cell_metrics or not cell_metrics.system_scaling or not cell_metrics.horiz_stretch then
        cell_metrics = metrics.calc_cell_metrics(express.Measure, express.Staff)
    end

    local exp_top = 0
    local exp_bottom = 0
    local exp_left = 0
    local exp_right = 0
    local exp_width = 0
    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()

    local measure = express:GetMeasure()
    local staff = express:GetStaff()

    if (systems:FindMeasureNumber(measure)) then
        local express_point = finale.FCPoint(0, 0)
        if express:CalcMetricPos(express_point) then
            local exp_ted = express:CreateTextExpressionDef()
            local exp_string = exp_ted:CreateTextString()
            local font_info = exp_string:CreateLastFontInfo()
            exp_string:TrimEnigmaTags()
            local text_metrics = finale.FCTextMetrics()
            text_metrics:LoadString(exp_string, font_info, 100)
            if (text_metrics) then
                exp_top = text_metrics:GetTopEVPUs() * cell_metrics.system_scaling
                exp_bottom = text_metrics:GetBottomEVPUs() * cell_metrics.system_scaling
                exp_left = text_metrics:GetLeftEVPUs()
                exp_right = text_metrics:GetRightEVPUs()
            end
            exp_width = expression.calc_text_width(exp_ted)
            local exp_y = (express_point.Y * cell_metrics.system_scaling) - cell_metrics.top_staffline
            local top_y = exp_y + exp_top
            local bottom_y = exp_y + exp_bottom

            local exp_x = express_point.X

            local exp_justification = exp_ted:GetHorizontalJustification()

            local left_x = exp_x + exp_left
            local right_x = exp_x + exp_right

            if exp_justification == finale.EXPRJUSTIFY_LEFT then
                left_x = exp_x
                right_x = exp_x + exp_width
            elseif exp_justification == finale.EXPRJUSTIFY_CENTER then
                left_x = exp_x - (exp_width / 2)
                right_x = exp_x + (exp_width / 2)
            elseif exp_justification == finale.EXPRJUSTIFY_RIGHT then
                left_x = exp_x - exp_width
                right_x = exp_x
            end

            return top_y, bottom_y, left_x, right_x, exp_y, exp_x
        end
    end
end

--[[
% calc_expression_y_pos

Returns the basic y position of an expression (regardless of actual text metrics).

@ express (FCExpression) The expression
@ cell_metrics (table) needs .system_scaling and .top_staffline. Will recalculate if omitted.
:(number) The y position
]]
function metrics.calc_expression_y_pos(express, cell_metrics)
    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
    local measure = express:GetMeasure()
    local staff = express:GetStaff()

    if not cell_metrics or not cell_metrics.system_scaling or not cell_metrics.top_staffline then
        cell_metrics = metrics.calc_cell_metrics(measure, staff)
    end

    if (systems:FindMeasureNumber(measure)) then
        local express_point = finale.FCPoint(0, 0)
        if express:CalcMetricPos(express_point) then
            local exp_y = (express_point.Y * cell_metrics.system_scaling) - cell_metrics.top_staffline
            return exp_y
        end
    end
end

--[[
% calc_lowest_highest_dynamic_expressions

Returns the lowest and highest expressions in the given region.

@ region (FCMusicRegion) The region to check.
@ cell_metrics (table) Needs .top_staffline. Will recalculate if omitted.
:(number) The y position of the lowest expression.
:(number) The y position of the highest expression.
]]
function metrics.calc_lowest_highest_dynamic_expressions(region, cell_metrics)
    if not cell_metrics or not cell_metrics.top_staffline then
        cell_metrics = metrics.calc_cell_metrics(region.StartMeasure, region.StartStaff)
    end

    local lowest_expression_pos = cell_metrics.top_staffline + 1000
    local highest_expression_pos = cell_metrics.bottom_staffline - 1000
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)

    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
    local last_system = systems:FindMeasureNumber(region.StartMeasure)

    for express in each(expressions) do
        local cur_system = systems:FindMeasureNumber(express.Measure)
        if cur_system.ItemNo ~= last_system.ItemNo then
            cell_metrics = metrics.calc_cell_metrics(express.Measure, express.Staff)
        end

        local create_def = express:CreateTextExpressionDef()
        local cat_def = finale.FCCategoryDef()
        if cat_def:Load(create_def:GetCategoryID()) then
            if ((cat_def:GetID() == finale.DEFAULTCATID_DYNAMICS) or 
                (string.find(cat_def:CreateName().LuaString, "Dynamic"))) then
                local expression_y = metrics.calc_expression_y_pos(express, cell_metrics)
                if expression_y < lowest_expression_pos then
                    lowest_expression_pos = expression_y
                end
                if expression_y > highest_expression_pos then
                    highest_expression_pos = expression_y
                end
            end
        end
    end

    return lowest_expression_pos, highest_expression_pos
end

--[[
% calc_lowest_dynamic_expression

Returns the lowest expression in the given region.

@ region (FCMusicRegion) The region to check.
@ cell_metrics (table) To pass on.
:(number) The y position of the lowest expression.
]]
function metrics.calc_lowest_dynamic_expression(region, cell_metrics)
    local lowest_expression_pos, highest_expression_pos = metrics.calc_lowest_highest_dynamic_expressions(region, cell_metrics)
    return lowest_expression_pos
end

--[[
% calc_highest_dynamic_expression

Returns the highest expression in the given region.

@ region (FCMusicRegion) The region to check.
@ cell_metrics (table) To pass on.
:(number) The y position of the highest expression.
]]
function metrics.calc_highest_dynamic_expression(region, cell_metrics)
    local lowest_expression_pos, highest_expression_pos = metrics.calc_lowest_highest_expression(region, cell_metrics)
    return highest_expression_pos
end

--[[
% calc_articulation_top_bottom

Returns the top and bottom positions of an articulation, based on the main symbol.

@ expression (FCArticulation) The articulation
@ cell_metrics (table) Needs .top_staffline and .system_scaling. If not present, will recalculate
:(number) The top position
:(number) The bottom position
]]
function metrics.calc_articulation_top_bottom(articulation, cell_metrics)

    local entry = articulation:GetNoteEntry()
    local art_top
    local art_bottom
    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
    local measure = entry:GetMeasure()
    local staff = entry:GetStaff()

    if not cell_metrics or not cell_metrics.system_scaling or not cell_metrics.top_staffline then
        metrics = metrics.calc_cell_metrics(measure, staff)
    end

    if (systems:FindMeasureNumber(measure)) then
        local articulation_point = finale.FCPoint(0, 0)
        if articulation:CalcMetricPos(articulation_point) then
            local art_def = articulation:CreateArticulationDef()
            local art_symbol = art_def:GetMainSymbolChar()
            local font_info = art_def:CreateMainSymbolFontInfo()
            local art_string = finale.FCString()
            art_string.LuaString = utf8.char(art_symbol)
            local text_metrics = finale.FCTextMetrics()
            text_metrics:LoadString(art_string, font_info, 100)
            if (text_metrics) then
                art_top = text_metrics:GetTopEVPUs() * cell_metrics.system_scaling
                art_bottom = text_metrics:GetBottomEVPUs() * cell_metrics.system_scaling
            end
            local art_y = (articulation_point.Y * system_scaling) - cell_metrics.top_staffline
            local top_y = art_y
            local bottom_y = art_y - art_top
            return top_y, bottom_y
        end
    end
end

--[[
% calc_articulation_top_pos

Returns the top position of an articulation, based on the main symbol.

@ artic (FCArticulation) The articulation
@ cell_metrics (table) To pass on
:(number) The top position
]]
function metrics.calc_articulation_top_pos(artic, cell_metrics)
    local art_top, art_bottom = metrics.calc_articulation_top_bottom(artic, cell_metrics)
    return art_top
end

--[[
% calc_articulation_bottom_pos

Returns the bottom position of an articulation, based on the main symbol.

@ artic (FCArticulation) The articulation
@ cell_metrics (table) To pass on
:(number) The bottom position
]]
function metrics.calc_articulation_bottom_pos(artic, cell_metrics)
    local art_top, art_bottom = metrics.calc_articulation_top_bottom(artic, cell_metrics)
    return art_bottom
end

--[[
% calc_hairpin_from_mark

Returns a table containing information about a hairpin given an input FCSmartShapeMeasureMark.
The input mark is assumed to be part of a hairpin.

@ mark (FCSmartShapeMeasureMark) The mark.
@ region (FCMusicRegion) The region in which the mark is found.
@ cell_metrics (table) Needs .system_scaling. If not found, will re-calculate.

:(table) A table of useful information about the hairpin. This includes:
:(FCSmartShape) .hairpin = The SmartShape itself.
:(boolean) .cross_system = 'true' if the hairpin crosses from one system to another.
:(number) .left_measure = The measure # of the left endpoint.
:(number) .left_measure_pos = The measure position of the left endpoint, in EDUs.
:(number) .left_system = The system number of the left endpoint, for the current part layout.
:(number) .left_x = The X position of the left endpoint, in EVPUs.
:(number) .left_y = The Y position of the left endpoint, in EVPUs.
:(number) .right_measure = The measure # of the right endpoint.
:(number) .right_measure_pos = The measure position of the right endpoint, in EDUs.
:(number) .right_system = The system number of the right endpoint, for the current part layout.
:(number) .right_x = The X position of the right endpoint, in EVPUs.
:(number) .right_y = The Y position of the right endpoint, in EVPUs.
]]
function metrics.calc_hairpin_from_mark(mark, region, cell_metrics)
    local hairpin = mark:CreateSmartShape()
    local left_seg = hairpin:GetTerminateSegmentLeft()
    local right_seg = hairpin:GetTerminateSegmentRight()
    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
    local crosses_system = false
    local hairpin_start_system = systems:FindMeasureNumber(left_seg:GetMeasure())
    hairpin_start_system = hairpin_start_system:GetItemNo()
    local hairpin_end_system = systems:FindMeasureNumber(right_seg:GetMeasure())
    hairpin_end_system = hairpin_end_system:GetItemNo()
    if hairpin_start_system ~= hairpin_end_system then
        crosses_system = true
    end
    local region_system = systems:FindMeasureNumber(region:GetStartMeasure())
    if not cell_metrics or not cell_metrics.system_scaling or not cell_metrics.top_staffline then
        cell_metrics = metrics.calc_cell_metrics(left_seg:GetMeasure(), left_seg:GetStaff())
    end
    local hairpin_data = {}

    local arg_point = finale.FCPoint(0, 0)

    local hairpin_left_metrics = hairpin:CalcLeftCellMetricPos(arg_point)
    hairpin_data.left_x = arg_point.X
    hairpin_data.left_y = (arg_point.Y * cell_metrics.system_scaling) - cell_metrics.top_staffline
    hairpin_data.left_measure = left_seg:GetMeasure()
    hairpin_data.left_system = hairpin_start_system
    hairpin_data.left_measure_pos = left_seg:GetMeasurePos()

    local hairpin_right_metrics = hairpin:CalcRightCellMetricPos(arg_point)
    if crosses_system then
        cell_metrics = metrics.calc_cell_metrics(right_seg:GetMeasure(), right_seg:GetStaff())
    end
    hairpin_data.right_x = arg_point.X
    hairpin_data.right_y = (arg_point.Y * cell_metrics.system_scaling) - cell_metrics.top_staffline
    hairpin_data.right_measure = right_seg:GetMeasure()
    hairpin_data.right_system = hairpin_end_system
    hairpin_data.right_measure_pos = right_seg:GetMeasurePos()

    hairpin_data.crosses_system = crosses_system
    hairpin_data.hairpin = hairpin

    return hairpin_data
end

--[[
% calc_lowest_highest_hairpin_pos

Returns the y positions of the lowest and highest hairpin endpoints in the region. 
This will work best when fed one system (FCStaffSystem) at a time.

@ region (FCMusicRegion) The region to check.
@ cell_metrics (table) To pass on.
@ hairpin_vert_off (number) Adjusts for the difference between hairpins and expressions. If not provided, will default to 10.


:(number) Lowest hairpin position.
:(number) Highest hairpin position.
]]
function metrics.calc_lowest_highest_hairpin_pos(region, cell_metrics, hairpin_vert_off)
    if not hairpin_vert_off then
        hairpin_vert_off = 10
    end

    if not cell_metrics or not cell_metrics.top_staffline then
        cell_metrics = metrics.calc_cell_metrics(region.StartMeasure, region.StartStaff)
    end

    local lowest_hairpin_pos = cell_metrics.top_staffline + 1000
    local highest_hairpin_pos = cell_metrics.bottom_staffline - 1000
    local marks = finale.FCSmartShapeMeasureMarks()
    marks:LoadAll()
    marks:KeepStaffOnly(region.StartStaff)
    marks:KeepHairpinsOnly()

    local ui = finenv.UI()
    if not ui:IsPageView() then
        marks:RemoveDuplicateReferences()
    end

    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
    local last_system = systems:FindMeasureNumber(region.StartMeasure)

    for mark in each(marks) do
        if region:IsMeasureIncluded(mark:GetMeasure()) then
            local cur_system = systems:FindMeasureNumber(mark:GetMeasure())
            if cur_system then
                if cur_system.ItemNo ~= last_system.ItemNo then
                    cell_metrics = metrics.calc_cell_metrics(mark:GetMeasure(), region.StartStaff)
                end
            end

            local hairpin_data = metrics.calc_hairpin_from_mark(mark, region, cell_metrics)
            if region:IsMeasureIncluded(hairpin_data.left_measure) then
                if (hairpin_data.left_y < lowest_hairpin_pos) then
                    lowest_hairpin_pos = hairpin_data.left_y - hairpin_vert_off
                end
                if (hairpin_data.left_y > highest_hairpin_pos) then
                    highest_hairpin_pos = hairpin_data.left_y - hairpin_vert_off
                end
            end
            if region:IsMeasureIncluded(hairpin_data.right_measure) then
                if (hairpin_data.right_y < lowest_hairpin_pos) then
                    lowest_hairpin_pos = hairpin_data.right_y - hairpin_vert_off
                end
                if (hairpin_data.right_y > highest_hairpin_pos) then
                    highest_hairpin_pos = hairpin_data.right_y - hairpin_vert_off
                end
            end
        end
    end
    return lowest_hairpin_pos, highest_hairpin_pos
end

--[[
% calc_lowest_hairpin_pos

Returns the y position of the lowest hairpin endpoint in the region. 
This will work best when fed one system (FCStaffSystem) at a time.

@ region (FCMusicRegion) The region to check.
@ cell_metrics
@ hairpin_vert_off (number) Adjusts for the difference between hairpins and expressions. If not provided, will default to 10.
:(number) The lowest hairpin Y position in the input region.
]]
function metrics.calc_lowest_hairpin_pos(region, cell_metrics,  hairpin_vert_off)
    local lowest_hairpin_pos, highest_hairpin_pos = metrics.calc_lowest_highest_hairpin_pos(region, cell_metrics,  hairpin_vert_off)
    return lowest_hairpin_pos
end

--[[
% calc_highest_hairpin_pos

Returns the y position of the highest hairpin endpoint in the region. 
This will work best when fed one system (FCStaffSystem) at a time.

@ region (FCMusicRegion) The region to check.
@ cell_metrics
@ hairpin_vert_off (number) Adjusts for the difference between hairpins and expressions. If not provided, will default to 10.
:(number) The highest hairpin Y position in the input region.
]]
function metrics.calc_highest_hairpin_pos(region, cell_metrics,  hairpin_vert_off)
    local lowest_hairpin_pos, highest_hairpin_pos = metrics.calc_lowest_highest_hairpin_pos(region, cell_metrics,  hairpin_vert_off)
    return highest_hairpin_pos
end

--[[
% calc_dynamic_vertical_pos_below

Calculates the 'ideal' vertical position of dynamics for the given region below the staff, based on the settings of the 'Dynamics' expression category.
These settings can be overridden by optional arguments for cushions for the bottom staff line and for entries (including articulations).

@ region (FCMusicRegion) The region to check.

@ cell_metrics (table) see details from calc_cell_metrics function. Parameters used here are:
cell_metrics.bottom_staffline
cell_metrics.system_scaling
cell_metrics.page_height

@ cushions (table) Every member of this table is OPTIONAL (values will get replaced by defaults if missing). The values determine the extra space to add between dynamics and various elements. The table parameters are:
@ cushions.staff_below (number) Number of EVPUs to put between the bottom staffline and dynamics.
@ cushions.entry_below (number) Number of EVPUs to put between entries below the staff and dynamics (similar to "additional entry offset")

:(number) The lowest hairpin Y position in the input region.
]]
function metrics.calc_dynamic_vertical_pos_below(region, cell_metrics, cushions)
    if not cell_metrics or not cell_metrics.bottom_staffline or not cell_metrics.system_scaling or not cell_metrics.page_height then
        cell_metrics = metrics.calc_cell_metrics(region.StartMeasure, region.StartStaff)
    end
    local dynamic_pos = cell_metrics.page_height
    local expr_below_baseline = finale.FCBaseline()
    expr_below_baseline:LoadDefaultForMode(finale.BASELINEMODE_EXPRESSIONBELOW)
    local baseline_pos = expr_below_baseline:GetVerticalOffset()
    local category_def = finale.FCCategoryDef()
    category_def:Load(finale.DEFAULTCATID_DYNAMICS)

    if not cushions or not cushions.staff_below then
        cushions.staff_below = (baseline_pos + category_def:GetVerticalBaselineOffset()) * cell_metrics.system_scaling
    end
    if not cushions or not cushions.entry_below then
        cushions.entry_below = category_def:GetVerticalEntryOffset() * cell_metrics.system_scaling
    end

    cushions.staff_below = math.abs(cushions.staff_below)
    cushions.entry_below = math.abs(cushions.entry_below)

    if (cell_metrics.bottom_staffline - cushions.staff_below) < dynamic_pos then
        dynamic_pos = (cell_metrics.bottom_staffline - cushions.staff_below)
    end
    local entry_pos = metrics.calc_lowest_entry(region, cell_metrics)
    if (entry_pos - cushions.entry_below) < dynamic_pos then
        dynamic_pos = (entry_pos - cushions.entry_below)
    end

    return dynamic_pos
end

--[[
% calc_dynamic_vertical_pos_above

Calculates the 'ideal' vertical position of dynamics for the given region ABOVE the staff, based on the settings of the 'Dynamics' expression category but adjusted.
These settings can be overridden by optional arguments for cushions for the bottom staff line and for entries (including articulations).

@ region (FCMusicRegion) The region to check.

@ cell_metrics (table) see details from calc_cell_metrics function. Will get recalculated if missing. Parameters used here are:
cell_metrics.top_staffline
cell_metrics.system_scaling

@ cushions (table) Every member of this table is OPTIONAL (values will get replaced by defaults if missing). The values determine the extra space to add between dynamics and various elements. The table parameters are:
@ cushions.staff_above (number) Number of EVPUs o put between the top staffline and dynamics.
@ cushions.entry_above (number) Number of EVPUs to put between entries above the staff and dynamics.
@ cushions.staff_above_add_offset (number) OPTIONAL. An additional adjustment for determining spacing from the staff.
@ cushions.entry_above_add_offset (number) OPTIONAL. An additional adjustment for determining spacing from entries.

:(number) The lowest hairpin Y position in the input region.
]]
function metrics.calc_dynamic_vertical_pos_above(region, cell_metrics, cushions)
    if not cell_metrics or not cell_metrics.top_staffline or not cell_metrics.system_scaling then
        cell_metrics = metrics.calc_cell_metrics(region.StartMeasure, region.StartStaff)
    end

    local dynamic_pos = 0
    local category_def = finale.FCCategoryDef()
    category_def:Load(finale.DEFAULTCATID_DYNAMICS)

    if not cushions or not cushions.staff_above_add_offset then 
        cushions.staff_above_add_offset = 0
    end

    if not cushions or not cushions.entry_above_add_offset then
        cushions.entry_above_add_offset  = -36
    end

    if not cushions or not cushions.staff_above then
        cushions.staff_above = 24
    end

    if not cushions or not cushions.entry_above then
        cushions.entry_above = (math.abs(category_def:GetVerticalEntryOffset()) + cushions.entry_above_add_offset) * cell_metrics.system_scaling
    end

    cushions.staff_above = math.abs(cushions.staff_above)
    cushions.entry_above = math.abs(cushions.entry_above)

    if (cushions.staff_above) > dynamic_pos then
        dynamic_pos = (cushions.staff_above)
    end

    local entry_pos = metrics.calc_highest_entry(region, cell_metrics)
    if (entry_pos + cushions.entry_above) > dynamic_pos then
        dynamic_pos = (entry_pos + cushions.entry_above)
    end

    return dynamic_pos
end

--[[
% calc_dynamic_far_pos

Calculates the farthest dynamic (expression or hairpin) from the staff. 
If any of the dynamics are above the staff, they will all align to the highest position. 
Otherwise, they will align to the lowest position below the staff.

@ region (FCMusicRegion) The region to check.
@ cell_metrics (table) If missing, will re-calculate
@ hairpin_vert_off (number) An offset between a hairpin and an expression. If not present, will default to 10.
:(number) The farthest position.
]]
function metrics.calc_dynamic_far_pos(region, cell_metrics, hairpin_vert_off)
    local dynamic_pos = 0
    local lowest_hairpin_pos, highest_hairpin_pos = metrics.calc_lowest_highest_hairpin_pos(region, cell_metrics, hairpin_vert_off)
    local lowest_dyn_expr, highest_dyn_expr = metrics.calc_lowest_highest_dynamic_expressions(region, cell_metrics)

    if not cell_metrics or not cell_metrics.top_staffline or not cell_metrics.bottom_staffline then
        cell_metrics = metrics.calc_cell_metrics(region.StartMeasure, region.StartStaff)
    end
    local highest_pos = cell_metrics.top_staffline
    local lowest_pos = cell_metrics.bottom_staffline

    if (highest_hairpin_pos > highest_pos) or (highest_dyn_expr > highest_pos) then
        if highest_hairpin_pos > highest_pos then
            highest_pos = highest_hairpin_pos
        end
        if highest_dyn_expr > highest_pos then
            highest_pos = highest_dyn_expr
        end
        dynamic_pos = highest_pos
    else
        if lowest_hairpin_pos < lowest_pos then
            lowest_pos = lowest_hairpin_pos
        end
        if lowest_dyn_expr < lowest_pos then
            lowest_pos = lowest_dyn_expr
        end
        dynamic_pos = lowest_pos
    end

    return dynamic_pos
end

--[[
% calc_measure_duration

Finds the duration of a measure by analyzing its time signature.

@ measure_num (number) The measure number to analyze.
:(number) The measure duration in EDUs.
]]
function metrics.calc_measure_duration(measure_num)
    local measure = finale.FCMeasure()
    measure:Load(measure_num)
    local timesig = measure:GetTimeSignature()
    local measure_dur = 0

    if timesig:GetCompositeTop() then
        local ts_top = timesig:CreateCompositeTop()
        local ts_btm = timesig:CreateCompositeBottom()
        local top_num_group_cnt = ts_top:GetGroupCount()
        for top_grp_num = 0, top_num_group_cnt - 1, 1 do
            local top_grp_element_cnt = ts_top:GetGroupElementCount(top_grp_num)
            for top_group_element = 0, top_grp_element_cnt - 1, 1 do
                local btm_grp_element_cnt = ts_btm:GetGroupElementCount(top_grp_num)
                for btm_grp_element = 0, btm_grp_element_cnt - 1, 1 do
                    local top_el_beats = ts_top:GetGroupElementBeats(top_grp_num, top_group_element)
                    local btm_el_dur = ts_btm:GetGroupElementBeatDuration(top_grp_num, btm_grp_element)
                    measure_dur = measure_dur + (top_el_beats * btm_el_dur)
                end
            end
        end
    else
        measure_dur = timesig:CalcBeats() * timesig:GetBeatDuration()
    end
    return measure_dur
end

return metrics

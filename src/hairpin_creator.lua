function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine after CJ Garcia"
    finaleplugin.AuthorURL = "http://carlvine.com/lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.49"
    finaleplugin.Date = "2022/07/13"
    finaleplugin.AdditionalMenuOptions = [[
        Hairpin create diminuendo
        Hairpin create swell
        Hairpin create unswell
    ]]
    finaleplugin.AdditionalUndoText = [[
        Hairpin create diminuendo
        Hairpin create swell
        Hairpin create unswell
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Create diminuendo spanning the selected region
        Create a swell (messa di voce) spanning the selected region
        Create an unswell (inverse messa di voce) spanning the selected region
    ]]
    finaleplugin.AdditionalPrefixes = [[
        hairpin_type = finale.SMARTSHAPE_DIMINUENDO
        hairpin_type = -1 -- "swell"
        hairpin_type = -2 -- "unswell"
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        This script creates hairpins spanning the currently selected music region. 
        The default hairpin type is `CRESCENDO`, with three additional menu items provided to create:  
        `DIMINUENDO`, `SWELL` (messa di voce) and `UNSWELL` (inverse messa di voce). 

        Hairpins are positioned vertically to avoid colliding with the lowest notes, down-stem tails, 
        articulations and dynamics on each staff in the selection. 
        Dynamics are shifted vertically to match the calculated hairpin positions. 
        Dynamics in the middle of a hairpin span will also be levelled, so 
        give them an opaque background so they will appear to sit "above" the hairpin. 
        The script also considers `trailing` notes and dynamics, just beyond the end of the selected music, 
        since a hairpin is normally expected to end just before the note with the destination dynamic. 

        Hairpin positions in Finale are more accurate when're attached to these "trailing" notes and dynamics, 
        but this can be problematic if trailing items fall across a barline and especially if they are 
        on a different system from the end of the hairpin. 
        (Elaine Gould - "Behind Bars" pp.103-106 - outlines contrasting scenarios for hairpin placement 
        over barlines. Your typical preferences might differ.)

        You will probably get the best results by entering dynamic markings before running the script. 
        It will find the lowest acceptable vertical offset for the hairpin, but if you want it lower than that then 
        first move one or more dynamic to the lowest point you want. 
        (Dynamics will not be shifted left-or-right, only up-and-down).
        
        You can change the script's default settings by creating a `configuration` file. 
        To do so, if it doesn't exist, inside the folder containing this script create a subfolder called `script_settings`. 
        In that folder create a plain text file called `hairpin_creator.config.txt`. 
        Write in that file single lines of text containing a different value for any or all of the default parameters:

        ```
        dynamics_match_hairpin = true -- change to "false" to skip moving dynamics vertically
        include_trailing_items = true -- change to "false" to ignore "trailing" notes and dynamics
        attach_over_end_barline = true -- change to "false" to NOT attach the right end of hairpins to notes across a barline
        attach_over_system_break = false -- change to "true" if you WANT to attach the right end hairpins to notes over a system break
        -- (attach_over_system_break = true will only work if attach_over_end_barline is also true)
        inclusions_EDU_margin = 256 -- the duration margin (in EDUs) for items INCLUDED beyond the end of the selected music
        -- (obviously inclusions_EDU_margin is irrelevant if include_trailing_items is false)
        shape_vert_adjust = 13 -- upward shift of hairpin to match the median-height of dynamic markings
        below_note_cushion = 56 -- extra vertical space (EVPUs) for the hairpin to leave below the lowest note
        downstem_cushion = 44 -- extra vertical space (EVPUs) for the hairpin to leave below the lowest downstem
        below_artic_cushion = 40 -- extra vertical space (EVPUs) for the hairpin to leave below the lowest articulation
        left_horiz_offset = 10 -- horizontal gap (EVPUs) between the start of the region and the start of the hairpin (if no dynamic)
        right_horiz_offset = -10 -- horizontal gap (EVPUs) between the end of the hairpin and the end of the region (if no dynamic)
        left_dynamic_cushion = 16 -- horizontal gap (EVPUs) between the starting dynamic (if present) and the start of the hairpin
        right_dynamic_cushion = -16 -- horizontal gap (EVPUs) between the end of the hairpin and the ending dynamic (if present)
        ```
    ]]
    return "Hairpin create crescendo", "Hairpin create crescendo", "Create crescendo spanning the selected region"
end

hairpin_type = hairpin_type or finale.SMARTSHAPE_CRESCENDO

local config = {
    dynamics_match_hairpin = true, -- false
    include_trailing_items = true, -- false
    attach_over_end_barline = true, -- true,
    attach_over_system_break = false, -- true,
    inclusions_EDU_margin = 256,
    shape_vert_adjust = 13,
    below_note_cushion = 56,
    downstem_cushion = 44,
    below_artic_cushion = 40,
    left_horiz_offset = 10, -- basic offset values overridden by dynamic measurements
    right_horiz_offset = -10,
    left_dynamic_cushion = 16,
    right_dynamic_cushion = -16,
}

local configuration = require("library.configuration")
local expression = require("library.expression")
configuration.get_parameters("hairpin_creator.config.txt", config) -- overwrite default preferences

local function measure_width(measure_number)
    local m = finale.FCMeasure()
    m:Load(measure_number)
    return m:GetDuration()
end

local function add_to_position(measure_number, end_position, add_duration)
    local m_width = measure_width(measure_number)
    if end_position > m_width then
        end_position = m_width
    end
    local remaining_to_add = end_position + add_duration
    while remaining_to_add > m_width do
        remaining_to_add = remaining_to_add - m_width
        measure_number = measure_number + 1 -- next measure
        m_width = measure_width(measure_number) -- how long?
    end
    return measure_number, remaining_to_add
end

local function extend_region_by_EDU(region, add_duration)
    local new_end, new_position = add_to_position(region.EndMeasure, region.EndMeasurePos, add_duration)
    region.EndMeasure = new_end
    region.EndMeasurePos = new_position
end

local function duration_gap(measureA, positionA, measureB, positionB)
    local diff, duration = 0, 0
    if measureA == measureB then -- simple EDU offset
        diff = positionB - positionA
    elseif measureB < measureA then
        duration = - positionB
        while measureB < measureA do -- add up measures until they meet
            duration = duration + measure_width(measureB)
            measureB = measureB + 1
        end
        diff = - duration - positionA
    elseif measureA < measureB then
        duration = - positionA
        while measureA < measureB do
            duration = duration + measure_width(measureA)
            measureA = measureA + 1
        end
        diff = duration + positionB
    end
    return diff
end

function delete_hairpins(rgn)
    local mark_rgn = finale.FCMusicRegion()
    mark_rgn:SetRegion(rgn)
    if config.include_trailing_items then -- extend it
        extend_region_by_EDU(mark_rgn, config.inclusions_EDU_margin)
    end

    local marks = finale.FCSmartShapeMeasureMarks()
    marks:LoadAllForRegion(mark_rgn, true)
    for mark in each(marks) do
        local shape = mark:CreateSmartShape()
        if shape:IsHairpin() then
            shape:DeleteData()
        end
    end
end

local function draw_staff_hairpin(rgn, vert_offset, left_offset, right_offset, shape, end_measure, end_postion)
    local smartshape = finale.FCSmartShape()
    smartshape.ShapeType = shape
    smartshape.EntryBased = false
    smartshape.MakeHorizontal = true
    smartshape.BeatAttached = true
    smartshape.PresetShape = true
    smartshape.Visible = true
    smartshape.LineID = 3

    local leftseg = smartshape:GetTerminateSegmentLeft()
    leftseg:SetMeasure(rgn.StartMeasure)
    leftseg.Staff = rgn.StartStaff
    leftseg:SetCustomOffset(true)
    leftseg:SetEndpointOffsetX(left_offset)
    leftseg:SetEndpointOffsetY(vert_offset + config.shape_vert_adjust)
    leftseg:SetMeasurePos(rgn.StartMeasurePos)

    end_measure = end_measure or rgn.EndMeasure -- nil value or new end measure
    end_postion = end_postion or rgn.EndMeasurePos
    local rightseg = smartshape:GetTerminateSegmentRight()
    rightseg:SetMeasure(end_measure)
    rightseg.Staff = rgn.StartStaff
    rightseg:SetCustomOffset(true)
    rightseg:SetEndpointOffsetX(right_offset)
    rightseg:SetEndpointOffsetY(vert_offset + config.shape_vert_adjust)
    rightseg:SetMeasurePos(end_postion)
    smartshape:SaveNewEverything(nil, nil)
end

local function calc_top_of_staff(measure, staff)
    local fccell = finale.FCCell(measure, staff)
    local staff_top = 0
    local cell_metrics = fccell:CreateCellMetrics()
    if cell_metrics then
        staff_top = cell_metrics.ReferenceLinePos
        cell_metrics:FreeMetrics()
    end
    return staff_top
end

local function calc_measure_system(measure, staff)
    local fccell = finale.FCCell(measure, staff)
    local system_number = 0
    local cell_metrics = fccell:CreateCellMetrics()
    if cell_metrics then
        system_number = cell_metrics.StaffSystem
        cell_metrics:FreeMetrics()
    end
    return system_number
end

local function articulation_metric_vertical(entry)
    -- this assumes an upstem entry, flagged, with articulation(s) BELOW the lowest note
    local text_mets = finale.FCTextMetrics()
    local arg_point = finale.FCPoint(0, 0)
    local lowest = 999999
    for articulation in eachbackwards(entry:CreateArticulations()) do
        local vertical = 0
        if articulation:CalcMetricPos(arg_point) then
            vertical = arg_point.Y
        end
        local art_def = articulation:CreateArticulationDef() -- subtract articulation HEIGHT
        -- ???? does metrics:LoadArticulation work on SMuFL characters ????
        if text_mets:LoadArticulation(art_def, false, 100) then
            vertical = vertical - math.floor(text_mets:CalcHeightEVPUs() + 0.5)
        end
        if lowest > vertical then
            lowest = vertical
        end
    end
    return lowest
end

local function lowest_note_element(rgn)
    local lowest_vert = -13 * 12 -- at least to bottom of staff
    local current_measure, top_of_staff, bottom_pos = 0, 0, 0

    for entry in eachentry(rgn) do
        if entry:IsNote() then
            if current_measure ~= entry.Measure then  -- new measure, new top of staff vertical
                current_measure = entry.Measure
                top_of_staff = calc_top_of_staff(current_measure, entry.Staff)
            end
            bottom_pos = (entry:CalcLowestStaffPosition() * 12) - config.below_note_cushion
            if entry:CalcStemUp() then -- stem up
                if lowest_vert > bottom_pos then
                    lowest_vert = bottom_pos
                end
                if entry:GetArticulationFlag() then -- check for articulations below the lowest note
                    local articulation_offset = articulation_metric_vertical(entry) - top_of_staff - config.below_artic_cushion
                    if lowest_vert > articulation_offset then
                        lowest_vert = articulation_offset
                    end
                end
            else -- stem down
                local top_pos = entry:CalcHighestStaffPosition()
                local this_stem = (top_pos * 12) - entry:CalcStemLength() - config.downstem_cushion
                -- if entry.StemDetailFlag then -- stem adjustment?
                if top_of_staff == 0 or (bottom_pos - 50) < this_stem then -- staff hidden from score
                    this_stem = bottom_pos - 50 -- so use up-stem, lowest note
                end
                if lowest_vert > this_stem then
                    lowest_vert = this_stem
                end
            end
        end
    end
    return lowest_vert
end

local function expression_is_dynamic(exp)
    if not exp:IsShape() and exp.StaffGroupID == 0 then
        local cd = finale.FCCategoryDef()
        local text_def = exp:CreateTextExpressionDef()
        if text_def and cd:Load(text_def.CategoryID) then
            if text_def.CategoryID == finale.DEFAULTCATID_DYNAMICS or string.find(cd:CreateName().LuaString, "Dynamic") then
                return true
            end
        end
    end
    return false
end

local function lowest_dynamic_in_region(rgn)
    local arg_point = finale.FCPoint(0, 0)
    local top_of_staff, current_measure, lowest_vert = 0, 0, 0
    local dynamics_list = {}

    local dynamic_rgn = finale.FCMusicRegion()
    dynamic_rgn:SetRegion(rgn) -- make a copy of region
    if config.include_trailing_items then -- extend it
        extend_region_by_EDU(dynamic_rgn, config.inclusions_EDU_margin)
    end
    local dynamics = finale.FCExpressions()
    dynamics:LoadAllForRegion(dynamic_rgn)

    for dyn in each(dynamics) do -- find lowest dynamic expression
        if not dyn:IsShape() and dyn.StaffGroupID == 0 and expression_is_dynamic(dyn) then
            if current_measure ~= dyn.Measure then
                current_measure = dyn.Measure -- new measure, new top of cell staff
                top_of_staff = calc_top_of_staff(current_measure, rgn.StartStaff)
            end
            if dyn:CalcMetricPos(arg_point) then
                local exp_y = arg_point.Y - top_of_staff  -- add dynamic, vertical offset, TextEprDef
                table.insert(dynamics_list, { dyn, exp_y } )
                if lowest_vert == 0 or exp_y < lowest_vert then
                    lowest_vert = exp_y
                end
            end
        end
    end
    return lowest_vert, dynamics_list
end

local function simple_dynamic_scan(rgn)
    local dynamic_list = {}
    local dynamic_rgn = finale.FCMusicRegion()
    dynamic_rgn:SetRegion(rgn) -- make a copy of region for DYNAMICS, expanded to the RIGHT
    if config.include_trailing_items then -- extend it
        extend_region_by_EDU(dynamic_rgn, config.inclusions_EDU_margin)
    end
    local dynamics = finale.FCExpressions()
    dynamics:LoadAllForRegion(dynamic_rgn)
    for dyn in each(dynamics) do -- find lowest dynamic expression
        if expression_is_dynamic(dyn) then
            table.insert(dynamic_list, dyn)
        end
    end
    return dynamic_list
end

local function dynamic_horiz_offset(dyn_exp, left_or_right)
    local total_offset = 0
    local dyn_def = dyn_exp:CreateTextExpressionDef()
    local dyn_width = expression.calc_text_width(dyn_def)
    local horiz_just = dyn_def.HorizontalJustification
    if horiz_just == finale.EXPRJUSTIFY_CENTER then
        dyn_width = dyn_width / 2 -- half width for cetnre justification
    elseif
        (left_or_right == "left" and horiz_just == finale.EXPRJUSTIFY_RIGHT) or
        (left_or_right == "right" and horiz_just == finale.EXPRJUSTIFY_LEFT)
        then
        dyn_width = 0
    end
    if left_or_right == "left" then
        total_offset = config.left_dynamic_cushion + dyn_width
    else -- "right" alignment
        total_offset = config.right_dynamic_cushion - dyn_width
    end
    total_offset = total_offset + expression.calc_handle_offset_for_smart_shape(dyn_exp)
    return total_offset
end

local function design_staff_swell(rgn, hairpin_shape, lowest_vert)
    local left_offset = config.left_horiz_offset -- basic offsets over-ridden by dynamic adjustments
    local right_offset = config.right_horiz_offset

    local new_end_measure, new_end_postion = nil, nil -- assume they're nil for now
    local dynamic_list = simple_dynamic_scan(rgn)
    if #dynamic_list > 0 then -- check horizontal alignments + positions
        local first_dyn = dynamic_list[1]
        if duration_gap(rgn.StartMeasure, rgn.StartMeasurePos, first_dyn.Measure, first_dyn.MeasurePos) < config.inclusions_EDU_margin then
            local offset = dynamic_horiz_offset(first_dyn, "left")
            if offset > left_offset then
                left_offset = offset
            end
        end
        local last_dyn = dynamic_list[#dynamic_list]
        local end_dynamic_gap = duration_gap(last_dyn.Measure, last_dyn.MeasurePos, rgn.EndMeasure, rgn.EndMeasurePos)
        if math.abs(end_dynamic_gap) < config.inclusions_EDU_margin then
            local offset = dynamic_horiz_offset(last_dyn, "right")
            if offset < right_offset then
                right_offset = offset
            end
            if last_dyn.Measure ~= rgn.EndMeasure and config.attach_over_end_barline then -- matching final dynamic is in the following measure
                new_end_measure = last_dyn.Measure
                new_end_postion = last_dyn.MeasurePos
            end
        end
    end
    draw_staff_hairpin(rgn, lowest_vert, left_offset, right_offset, hairpin_shape, new_end_measure, new_end_postion)
end

local function design_staff_hairpin(rgn, hairpin_shape)
    local left_offset = config.left_horiz_offset -- basic offsets over-ridden by dynamic adjustments below
    local right_offset = config.right_horiz_offset
    
    -- check vertical alignments
    local lowest_vert = lowest_note_element(rgn)
    local lowest_dynamic, dynamics_list = lowest_dynamic_in_region(rgn)
    if lowest_dynamic < lowest_vert then
        lowest_vert = lowest_dynamic
    end

    -- any dynamics in selection?
    local new_end_measure, new_end_postion = nil, nil -- assume they're nil for now
    if #dynamics_list > 0 then
        if config.dynamics_match_hairpin then -- move all dynamics to equal lowest vertical
            for i, v in ipairs(dynamics_list) do
                local vert_difference = v[2] - lowest_vert
                v[1].VerticalPos = v[1].VerticalPos - vert_difference
                v[1]:Save()
            end
        end
        -- check horizontal alignments + positions
        local first_dyn = dynamics_list[1][1]
        if duration_gap(rgn.StartMeasure, rgn.StartMeasurePos, first_dyn.Measure, first_dyn.MeasurePos) < config.inclusions_EDU_margin then
            local offset = dynamic_horiz_offset(first_dyn, "left")
            if offset > left_offset then
                left_offset = offset
            end
        end
        local last_dyn = dynamics_list[#dynamics_list][1]
        local edu_gap = duration_gap(last_dyn.Measure, last_dyn.MeasurePos, rgn.EndMeasure, rgn.EndMeasurePos)
        if math.abs(edu_gap) < config.inclusions_EDU_margin then
            local offset = dynamic_horiz_offset(last_dyn, "right") -- (negative value)
            if right_offset > offset then
                right_offset = offset
            end
            if last_dyn.Measure ~= rgn.EndMeasure and config.attach_over_end_barline then -- matching final dynamic is in the following measure
                local dyn_system = calc_measure_system(last_dyn.Measure, last_dyn.Staff)
                local rgn_system = calc_measure_system(rgn.EndMeasure, rgn.StartStaff)
                if config.attach_over_system_break or dyn_system == rgn_system then
                    new_end_measure = last_dyn.Measure
                    new_end_postion = last_dyn.MeasurePos
                end
            end
        end
    end
    draw_staff_hairpin(rgn, lowest_vert, left_offset, right_offset, hairpin_shape, new_end_measure, new_end_postion)
end

local function create_swell(swell_type)
    local selection = finenv.Region()
    delete_hairpins(selection)
    local staff_rgn = finale.FCMusicRegion()
    staff_rgn:SetRegion(selection)
    -- make sure "full" final measure has a valid duration
    local m_width = measure_width(staff_rgn.EndMeasure)
    if staff_rgn.EndMeasurePos > m_width then
        staff_rgn.EndMeasurePos = m_width
    end
    delete_hairpins(staff_rgn)
    -- get midpoint of full region span
    local total_duration = duration_gap(staff_rgn.StartMeasure, staff_rgn.StartMeasurePos, staff_rgn.EndMeasure, staff_rgn.EndMeasurePos)
    local midpoint_measure, midpoint_position = add_to_position(staff_rgn.StartMeasure, staff_rgn.StartMeasurePos, total_duration / 2)

    for slot = selection.StartSlot, selection.EndSlot do
        local staff_number = selection:CalcStaffNumber(slot)
        staff_rgn:SetStartStaff(staff_number)
        staff_rgn:SetEndStaff(staff_number)
    
        -- check vertical dynamic alignments for FULL REGION
        local lowest_vertical = lowest_note_element(staff_rgn)
        local lowest_dynamic, dynamics_list = lowest_dynamic_in_region(staff_rgn)
        if lowest_vertical > lowest_dynamic then
            lowest_vertical = lowest_dynamic
        end
        -- any dynamics in selection?
        if #dynamics_list > 0 and config.dynamics_match_hairpin then
            for i, v in ipairs(dynamics_list) do
                local vert_difference = v[2] - lowest_vertical
                v[1].VerticalPos = v[1].VerticalPos - vert_difference
                v[1]:Save()
            end
        end

        -- LH hairpin half
        local half_rgn = finale.FCMusicRegion()
        half_rgn:SetRegion(staff_rgn)
        half_rgn.EndMeasure = midpoint_measure
        half_rgn.EndMeasurePos = midpoint_position
        local this_shape = (swell_type) and finale.SMARTSHAPE_CRESCENDO or finale.SMARTSHAPE_DIMINUENDO
        design_staff_swell(half_rgn, this_shape, lowest_vertical)

        -- RH hairpin half
        if midpoint_position == measure_width(midpoint_measure) then -- very end of first half of span
            midpoint_measure = midpoint_measure + 1 -- so move to start of next measure
            midpoint_position = 0
        end
        half_rgn.StartMeasure = midpoint_measure
        half_rgn.StartMeasurePos = midpoint_position
        half_rgn.EndMeasure = staff_rgn.EndMeasure
        half_rgn.EndMeasurePos = staff_rgn.EndMeasurePos
        this_shape = (swell_type) and finale.SMARTSHAPE_DIMINUENDO or finale.SMARTSHAPE_CRESCENDO
        design_staff_swell(half_rgn, this_shape, lowest_vertical)
    end
end

local function create_hairpin(shape_type)
    local selection = finenv.Region()
    delete_hairpins(selection)
    local staff_rgn = finale.FCMusicRegion()
    staff_rgn:SetRegion(selection)
    -- make sure "full" final measure has a valid duration
    local m_width = measure_width(staff_rgn.EndMeasure)
    if staff_rgn.EndMeasurePos > m_width then
        staff_rgn.EndMeasurePos = m_width
    end

    for slot = selection.StartSlot, selection.EndSlot do
        local staff_number = selection:CalcStaffNumber(slot)
        staff_rgn:SetStartStaff(staff_number)
        staff_rgn:SetEndStaff(staff_number)
        design_staff_hairpin(staff_rgn, shape_type)
    end
end

-- =================== DO THE WORK! ======================
if hairpin_type < 0 then -- SWELL / UNSWELL
    create_swell(hairpin_type == -1) -- true for SWELL, otherwise UNSWELL
else
    create_hairpin(hairpin_type) -- preset CRESC / DIM
end

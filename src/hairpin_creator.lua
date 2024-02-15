function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.84"
    finaleplugin.Date = "2024/02/05"
    finaleplugin.AdditionalMenuOptions = [[
        Hairpin Create Diminuendo
        Hairpin Create Swell
        Hairpin Create Unswell
        Hairpin Creator Configuration...
    ]]
    finaleplugin.AdditionalUndoText = [[
        Hairpin Create Diminuendo
        Hairpin Create Swell
        Hairpin Create Unswell
        Hairpin Creator Configuration
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Create diminuendo spanning the selected region
        Create a swell (messa di voce) spanning the selected region
        Create an unswell (inverse messa di voce) spanning the selected region
        Configure Hairpin Creator default settings
    ]]
    finaleplugin.AdditionalPrefixes = [[
        hairpin_type = finale.SMARTSHAPE_DIMINUENDO
        hairpin_type = -1 -- "swell"
        hairpin_type = -2 -- "unswell"
        hairpin_type = -3 -- "configure"
    ]]
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.ScriptGroupName = "Hairpin Creator"
    finaleplugin.ScriptGroupDescription =
        "Create four different types of hairpin spanning the currently selected music region"
    finaleplugin.Notes = [[
        This script creates hairpins spanning the currently selected music region. 
        It provides four menu items to create __Crescendo__, __Diminuendo__, 
        __Swell__ (_messa di voce_) and __Unswell__ (_inverse messa di voce_) hairpins. 

        Hairpins are shifted vertically to avoid colliding with the lowest notes, 
        down-stem tails, articulations and dynamics on each staff in the selection. 
        Dynamics are shifted to match the hairpin vertical. 
        Dynamics in the middle of a hairpin will also be levelled, so 
        give them an opaque background to sit "above" the hairpin. 
        The script also considers trailing notes and dynamics, just beyond 
        the end of the selected music, since a hairpin is normally expected 
        to end just before the note with the destination dynamic. 

        Hairpin positions are more accurate when attached to these 
        "trailing" notes and dynamics, but this can be a problem if they 
        fall across a barline and especially if they are 
        on a different system from the end of the hairpin. 
        (Elaine Gould, _Behind Bars_ pp.103-106, outlines several scenarios 
        in which hairpins either should or shouldn't "attach" across barlines. 
        Individual preferences may differ.) 

        This script works better if dynamic markings are added first. 
        It will find the lowest matching vertical offset for the hairpin, 
        but if you want the hairpin lower than that then first move a dynamic 
        to the lowest required point. 

        To change options use the _Configuration_ menu or hold down the [Shift] key 
        when selecting a _Hairpin Creator_ menu. 
        For simple hairpins that don't mess around with trailing barlines and dynamics 
        try selecting _Dynamics Match Hairpin_ with no other options. 

        > __Key Commands__ in the _Configuration_ window:

        > - __d - f - g - h__ toggle the checkboxes 
        > - __z__: reset default values 
        > - __q__: display these notes  
        > - Change measurement units: 
        > - __e__ - EVPU; __i__ - Inches; __c__ - Centimeters; 
        > - __o__ - Points; __a__ - Picas; __s__ - Spaces; 
    ]]
    return "Hairpin Create Crescendo", "Hairpin Create Crescendo",
        "Create crescendo hairpin spanning the selected region"
end

hairpin_type = hairpin_type or finale.SMARTSHAPE_CRESCENDO

local config = { -- other values populated from "defaults"
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    window_pos_x = false,
    window_pos_y = false,
}

local defaults = { -- and pre-populate config
    dynamics_match_hairpin = true,
    include_trailing_items = true,
    attach_over_end_barline = false,
    attach_over_system_break = false,
    inclusions_EDU_margin = 256,
    shape_vert_adjust = 13,
    below_note_cushion = 56,
    downstem_cushion = 44,
    below_artic_cushion = 40,
    left_horiz_offset = 14,
    right_horiz_offset = -14,
    left_dynamic_cushion = 18,
    right_dynamic_cushion = -18,
}
for k, v in pairs(defaults) do config[k] = v end -- populate config

local options = { -- key value from config; text description
    boolean = {
        { "dynamics_match_hairpin", "[d] - move dynamics vertically to match hairpin height" },
        { "include_trailing_items", "[f] - consider notes and dynamics past the end of selection" },
        { "attach_over_end_barline", "[g] - attach right end of hairpin across the final barline" },
        { "attach_over_system_break", "[h] - attach across final barline even over a system break" },
    },
    integer = {
        { "inclusions_EDU_margin", "(EDUs) the marginal duration for included trailing items" }
    },
    measure = {
        { "shape_vert_adjust",  "vertical adjustment for hairpin to match dynamics" },
        { "below_note_cushion", "extra gap below notes" },
        { "downstem_cushion", "extra gap below down-stems" },
        { "below_artic_cushion", "extra gap below articulations" },
        { "left_horiz_offset",  "gap between the start of selection and hairpin (no dynamics)" },
        { "right_horiz_offset",  "gap between end of hairpin and end of selection (no dynamics)" },
        { "left_dynamic_cushion",  "gap between first dynamic and start of hairpin" },
        { "right_dynamic_cushion",  "gap between end of the hairpin and ending dynamic" },
    }
}

local configuration = require("library.configuration")
local expression = require("library.expression")
local mixin = require("library.mixin")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false -- set to true if utils.show_notes_dialog is used

local function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function measure_width(measure_number)
    local m = finale.FCMeasure()
    local duration = m:Load(measure_number) and m:GetDuration() or 0
    return duration
end

local function max_end_width(rgn)
    local m_width = measure_width(rgn.EndMeasure)
    if rgn.EndMeasurePos > m_width then
        rgn.EndMeasurePos = m_width
    end
end

local function add_to_position(measure_number, end_position, add_duration)
    local m_width = measure_width(measure_number)
    if m_width == 0 then -- measure didn't load
        return measure_number, 0
    end
    if end_position > m_width then
        end_position = m_width
    end
    local remaining_to_add = end_position + add_duration
    while remaining_to_add > m_width do
        remaining_to_add = remaining_to_add - m_width
        local next_width = measure_width(measure_number + 1) -- another measure?
        if next_width == 0 then -- no more measures
            remaining_to_add = m_width -- finished calculating
        else
            measure_number = measure_number + 1 -- next measure
            m_width = next_width
        end
    end
    return measure_number, remaining_to_add
end

local function extend_region_by_EDU(region, add_duration)
    local new_end, new_position = add_to_position(region.EndMeasure, region.EndMeasurePos, add_duration)
    region.EndMeasure = new_end
    region.EndMeasurePos = new_position
end

local function duration_gap(measureA, positionA, measureB, positionB)
    local diff = 0
    if measureA == measureB then -- simple EDU offset
        diff = positionB - positionA
    elseif measureB < measureA then
        local duration = - positionB
        while measureB < measureA do -- add up measures until they meet
            duration = duration + measure_width(measureB)
            measureB = measureB + 1
        end
        diff = - duration - positionA
    elseif measureA < measureB then
        local duration = - positionA
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
        if shape and shape:IsHairpin() then
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
    leftseg:SetCustomOffset(false)
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

local function calc_top_of_staff(measure, staff_number)
    local fccell = finale.FCCell(measure, staff_number)
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
    local current_measure, top_of_staff = 0, 0

    for entry in eachentry(rgn) do
        if entry:IsNote() then
            if current_measure ~= entry.Measure then  -- new measure, new top of staff vertical
                current_measure = entry.Measure
                top_of_staff = calc_top_of_staff(current_measure, entry.Staff)
            end
            local bottom_pos = (entry:CalcLowestStaffPosition() * 12) - config.below_note_cushion
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

local function lowest_dynamic_in_region(rgn)
    local arg_point = finale.FCPoint(0, 0)
    local top_of_staff, current_measure, lowest_vert = 0, 0, 0
    local dynamics_list = {}

    local dynamic_rgn = finale.FCMusicRegion()
    dynamic_rgn:SetRegion(rgn) -- make a copy of the given region
    if config.include_trailing_items then -- extend it
        extend_region_by_EDU(dynamic_rgn, config.inclusions_EDU_margin)
    end
    local dynamics = finale.FCExpressions()
    dynamics:LoadAllForRegion(dynamic_rgn)

    for dyn in each(dynamics) do -- find lowest dynamic expression
        if expression.is_dynamic(dyn) then
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
    dynamic_rgn:SetRegion(rgn) -- make a copy of given region
    if config.include_trailing_items then -- extend it
        extend_region_by_EDU(dynamic_rgn, config.inclusions_EDU_margin)
    end
    local dynamics = finale.FCExpressions()
    dynamics:LoadAllForRegion(dynamic_rgn)
    for dyn in each(dynamics) do -- find lowest dynamic expression
        if expression.is_dynamic(dyn) then
            table.insert(dynamic_list, dyn)
        end
    end
    return dynamic_list
end

local function dynamic_horiz_offset(dyn_exp, left_or_right)
    local total_offset
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

function region_contains_notes(rgn)
    for entry in eachentry(rgn) do
        if entry.Count > 0 then
            return true
        end
    end
    return false
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
            if rgn.StartMeasurePos ~= first_dyn.MeasurePos then -- align them horizontally
                rgn:SetStartMeasurePos(first_dyn.MeasurePos):SetStartMeasure(first_dyn.Measure)
            end
        end
        local last_dyn = dynamic_list[#dynamic_list]
        local edu_gap = duration_gap(last_dyn.Measure, last_dyn.MeasurePos, rgn.EndMeasure, rgn.EndMeasurePos)
        if math.abs(edu_gap) < config.inclusions_EDU_margin then
            local offset = dynamic_horiz_offset(last_dyn, "right") -- (negative value)
            if right_offset > offset then
                right_offset = offset
            end
            if last_dyn.Measure ~= rgn.EndMeasure then
                if config.attach_over_end_barline then -- matching final dynamic is in the following measure
                    local dyn_system = calc_measure_system(last_dyn.Measure, last_dyn.Staff)
                    local rgn_system = calc_measure_system(rgn.EndMeasure, rgn.StartStaff)
                    if config.attach_over_system_break or dyn_system == rgn_system then
                        new_end_measure = last_dyn.Measure
                        new_end_postion = last_dyn.MeasurePos
                    end
                else
                    right_offset = config.right_horiz_offset -- revert to end-of-measure position
                end
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
            for _, v in ipairs(dynamics_list) do
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
            if rgn.StartMeasurePos ~= first_dyn.MeasurePos then -- align them horizontally
                rgn:SetStartMeasurePos(first_dyn.MeasurePos):SetStartMeasure(first_dyn.Measure)
            end
        end
        local last_dyn = dynamics_list[#dynamics_list][1]
        local edu_gap = duration_gap(last_dyn.Measure, last_dyn.MeasurePos, rgn.EndMeasure, rgn.EndMeasurePos)
        if math.abs(edu_gap) < config.inclusions_EDU_margin then
            local offset = dynamic_horiz_offset(last_dyn, "right") -- (negative value)
            if right_offset > offset then
                right_offset = offset
            end
            if last_dyn.Measure ~= rgn.EndMeasure then
                if config.attach_over_end_barline then -- matching final dynamic is in the following measure
                    local dyn_system = calc_measure_system(last_dyn.Measure, last_dyn.Staff)
                    local rgn_system = calc_measure_system(rgn.EndMeasure, rgn.StartStaff)
                    if config.attach_over_system_break or dyn_system == rgn_system then
                        new_end_measure = last_dyn.Measure
                        new_end_postion = last_dyn.MeasurePos
                    end
                else
                    right_offset = config.right_horiz_offset -- revert to end-of-measure position
                end
            end
        end
    end
    draw_staff_hairpin(rgn, lowest_vert, left_offset, right_offset, hairpin_shape, new_end_measure, new_end_postion)
end

local function create_swell(swell_type) -- (and inverse swell)
    local selection = finenv.Region()
    local staff_rgn = mixin.FCMMusicRegion()
    staff_rgn:SetRegion(selection)
    max_end_width(staff_rgn)

    -- get midpoint of full region span
    local total_duration = duration_gap(staff_rgn.StartMeasure, staff_rgn.StartMeasurePos, staff_rgn.EndMeasure, staff_rgn.EndMeasurePos)
    local midpoint_measure, midpoint_position = add_to_position(staff_rgn.StartMeasure, staff_rgn.StartMeasurePos, total_duration / 2)

    for staff_number in eachstaff(selection) do
        staff_rgn:SetStartStaff(staff_number):SetEndStaff(staff_number)
        if region_contains_notes(staff_rgn) then
            delete_hairpins(staff_rgn)
            -- check vertical dynamic alignments for FULL REGION
            local lowest_vertical = lowest_note_element(staff_rgn)
            local lowest_dynamic, dynamics_list = lowest_dynamic_in_region(staff_rgn)
            if lowest_vertical > lowest_dynamic then
                lowest_vertical = lowest_dynamic
            end
            -- any dynamics in selection?
            if #dynamics_list > 0 and config.dynamics_match_hairpin then
                for _, v in ipairs(dynamics_list) do
                    local vert_difference = v[2] - lowest_vertical
                    v[1].VerticalPos = v[1].VerticalPos - vert_difference
                    v[1]:Save()
                end
            end

            -- LH hairpin half
            local half_rgn = mixin.FCMMusicRegion()
            half_rgn:SetRegion(staff_rgn)
                :SetEndMeasure(midpoint_measure):SetEndMeasurePos(midpoint_position)
            local this_shape = (swell_type) and finale.SMARTSHAPE_CRESCENDO or finale.SMARTSHAPE_DIMINUENDO
            design_staff_swell(half_rgn, this_shape, lowest_vertical)

            -- RH hairpin half
            if midpoint_position == measure_width(midpoint_measure) then -- very end of first half of span
                midpoint_measure = midpoint_measure + 1 -- so move to start of next measure
                midpoint_position = 0
            end
            half_rgn:SetStartMeasure(midpoint_measure):SetStartMeasurePos(midpoint_position)
                :SetEndMeasure(staff_rgn.EndMeasure):SetEndMeasurePos(staff_rgn.EndMeasurePos)
            this_shape = (swell_type) and finale.SMARTSHAPE_DIMINUENDO or finale.SMARTSHAPE_CRESCENDO
            design_staff_swell(half_rgn, this_shape, lowest_vertical)
        end
    end
end

local function create_hairpin(shape_type)
    local selection = finenv.Region()
    local staff_rgn = mixin.FCMMusicRegion()
    staff_rgn:SetRegion(selection)
    max_end_width(staff_rgn)

    for staff_number in eachstaff(selection) do
        staff_rgn:SetStartStaff(staff_number):SetEndStaff(staff_number)
        if region_contains_notes(staff_rgn) then
            delete_hairpins(staff_rgn)
            design_staff_hairpin(staff_rgn, shape_type)
        end
    end
end

function user_dialog()
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle(finaleplugin.ScriptGroupName .. " Configuration")
    local y, y_step = 0, 20
    local max_text_width = 340
    local x_offset = { 0, 132, 157, 190 }
    local answer, save_value = {}, {}
    local units = { -- triggered by keystroke within "[eicoas]"
        e = finale.MEASUREMENTUNIT_EVPUS,       i = finale.MEASUREMENTUNIT_INCHES,
        c = finale.MEASUREMENTUNIT_CENTIMETERS, o = finale.MEASUREMENTUNIT_POINTS,
        a = finale.MEASUREMENTUNIT_PICAS,       s = finale.MEASUREMENTUNIT_SPACES,
    }
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- horizontal offset for Mac Edit boxes
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. finaleplugin.ScriptGroupName)
            refocus_document = true
        end
        local function stat(sx, sy, str, wid)
            dialog:CreateStatic(sx, sy):SetText(str):SetWidth(wid)
        end
        local function update_saved()
            for _, v in ipairs(options.measure) do
                save_value[v[1]] = answer[v[1]]:GetText()
            end
            save_value[options.integer[1][1]] = answer[options.integer[1][1]]:GetText()
        end
        local function reset_defaults()
            for key, value in pairs(defaults) do
                local ctl = answer[key]
                if key:find("EDU") then ctl:SetInteger(value)
                elseif type(value) == "boolean" then ctl:SetCheck(value and 1 or 0)
                else ctl:SetMeasurementInteger(value)
                end
            end
            update_saved()
        end
        local function toggle(idx)
            local ctl = answer[options.boolean[idx][1]]
            ctl:SetCheck((ctl:GetCheck() + 1) % 2)
        end
        local function key_check(id)
            local s = answer[id]:GetText():lower()
            if     (s:find("p") and dialog:GetMeasurementUnit() ~= finale.MEASUREMENTUNIT_PICAS)
                or  s:find("[^-.p0-9]") then
                if     s:find("[?q]") then show_info()
                elseif s:find("z") then reset_defaults()
                elseif s:find("d") then toggle(1) -- index of options.boolean
                elseif s:find("f") then toggle(2)
                elseif s:find("g") then toggle(3)
                elseif s:find("h") then toggle(4)
                elseif s:find("[eicoas]") then -- change measurement unit
                    for k, v in pairs(units) do
                        if s:find(k) then
                            answer[id]:SetText(save_value[id])
                            dialog:SetMeasurementUnit(v)
                            answer.popup:UpdateMeasurementUnit()
                            update_saved()
                            break
                        end
                    end
                end
                answer[id]:SetText(save_value[id]):SetKeyboardFocus()
            elseif s ~= "" then  -- save new "clean" number
                if s == "." then s = "0." -- offsets, leading zero
                elseif s == "-." then s = "-0."
                end
                answer[id]:SetText(s)
                save_value[id] = s
            end
        end
        local function add_number_edit(v)
            local s = v[1]:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return string.upper(a) .. b end)
            stat(x_offset[1], y, s .. ":", x_offset[2])
            stat(x_offset[4], y, v[2], max_text_width)
            answer[v[1]] = v[1]:find("EDU")
                and dialog:CreateEdit(x_offset[2], y - mac_offset)
                or dialog:CreateMeasurementEdit(x_offset[2], y - mac_offset)
            answer[v[1]]:SetWidth(50):SetInteger(config[v[1]])
                :AddHandleCommand(function() key_check(v[1]) end)
            save_value[v[1]] = answer[v[1]]:GetText()
            y = y + y_step
        end
    -- draw checkboxes
    for _, v in ipairs(options.boolean) do
        local s = v[1]:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return string.upper(a) .. b end)
        answer[v[1]] = dialog:CreateCheckbox(x_offset[1], y):SetText(s)
            :SetWidth(x_offset[3]):SetCheck(config[v[1]] and 1 or 0)
        stat(x_offset[3], y, v[2], max_text_width)
        y = y + y_step
    end
    y = y + 8 -- extra gap before numeric values start
    -- integer/measurement editboxes
    for _, v in ipairs(options.integer) do add_number_edit(v) end
    for _, v in ipairs(options.measure) do add_number_edit(v) end

    -- measurement units
    y = y + 6 -- extra gap
    dialog:CreateStatic(x_offset[2] - 40, y):SetText("Units:")
    dialog:SetMeasurementUnit(config.measurement_unit)
    answer.popup = dialog:CreateMeasurementUnitPopup(x_offset[2], y)
    dialog:CreateButton(x_offset[4] + 100, y):SetText("Reset Defaults (z)")
        :SetWidth(150):AddHandleCommand(function() reset_defaults() end)
    dialog:CreateButton(x_offset[4] + 260, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        for key, value in pairs(defaults) do
            local ctl = answer[key]
            if key:find("EDU") then config[key] = ctl:GetInteger()
            elseif type(value) == "boolean" then config[key] = (ctl:GetCheck() == 1)
            else config[key] = ctl:GetMeasurementInteger()
            end
        end
        config.measurement_unit = self:GetMeasurementUnit()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK)
end

function hairpin_selector()
    configuration.get_user_settings(script_name, config) -- overwrite saved user prefs
    local qim = finenv.QueryInvokedModifierKeys
    local mod_down = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))
    local ok = true

    if mod_down or (hairpin_type == -3) then -- user wants to change preferences
        ok = user_dialog()
    end
    if ok and hairpin_type ~= -3 then -- ready to make hairpins
        if finenv.Region():IsEmpty() then
            local msg = "Please select some music \n before running \n\"" .. finaleplugin.ScriptGroupName .. "\""
            finenv.UI():AlertError(msg, "Error")
        else
            -- do the work!!!
            if hairpin_type < 0 then -- SWELL (-1) / UNSWELL (-2) / CONFIGURE (-3)
                create_swell(hairpin_type == -1) -- true for SWELL, otherwise UNSWELL
            else
                create_hairpin(hairpin_type) -- finale CRESC / DIM enums
            end
        end
    end
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

hairpin_selector()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "CJ Garcia"
    finaleplugin.Copyright = "© 2021 CJ Garcia Music"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "2/29/2021"
    return "Hairpin and Dynamic Adjustments", "Hairpin and Dynamic Adjustments", "Adjusts hairpins to remove collisions with dynamics and aligns hairpins with dynamics."
end

function vertical_dynamic_adjustment(region, direction)
    local lowest_item = {}
    local staff_pos = {}
    local has_dynamics = false
    local has_hairpins = false
    local arg_point = finale.FCPoint(0, 0)

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    for e in each(expressions) do
        local create_def = e:CreateTextExpressionDef()
        local cd = finale.FCCategoryDef()
        if cd:Load(create_def:GetCategoryID()) then
            if string.find(cd:CreateName().LuaString, "Dynamic") then
                if e:CalcMetricPos(arg_point) then
                    has_dynamics = true
                    table.insert(lowest_item, arg_point:GetY())
                end
            end
        end
    end

    local ssmm = finale.FCSmartShapeMeasureMarks()
    ssmm:LoadAllForRegion(region, true)
    for mark in each(ssmm) do
        local smart_shape = mark:CreateSmartShape()
        if smart_shape:IsHairpin() then
            has_hairpins = true
            if smart_shape:CalcLeftCellMetricPos(arg_point) then 
                table.insert(lowest_item, arg_point:GetY())
            elseif smart_shape:CalcRightCellMetricPos(arg_point) then
                table.insert(lowest_item, arg_point:GetY())
            end
        end
    end

    table.sort(lowest_item)

    if has_dynamics == true then
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(region)
        for e in each(expressions) do
            local create_def = e:CreateTextExpressionDef()
            local cd = finale.FCCategoryDef()
            if cd:Load(create_def:GetCategoryID()) then
                if string.find(cd:CreateName().LuaString, "Dynamic") then
                    if e:CalcMetricPos(arg_point) then
                        local difference_pos =  arg_point:GetY() - lowest_item[1]
                        if direction == "near" then
                            difference_pos = lowest_item[#lowest_item] - arg_point:GetY()
                        end
                        local current_pos = e:GetVerticalPos()
                        if direction == "far" then
                            e:SetVerticalPos(current_pos - difference_pos)
                        else
                            e:SetVerticalPos(current_pos + difference_pos)
                        end
                        e:Save()
                    end
                end
            end
        end
    else
        for noteentry in eachentrysaved(region) do
            if noteentry:IsNote() then
                for note in each(noteentry) do
                    table.insert(staff_pos, note:CalcStaffPosition())
                end
            end
        end

        table.sort(staff_pos)

        if staff_pos[1] ~= nil then
            if staff_pos[1] > -7 then
                lowest_item[1] = -160
            else
                local below_note_cushion = 45
                lowest_item[1] = (staff_pos[1] * 12) - below_note_cushion
            end
        end
    end



    if has_hairpins == true then
        local ssmm = finale.FCSmartShapeMeasureMarks()
        ssmm:LoadAllForRegion(region, true)
        for mark in each(ssmm) do
            local smart_shape = mark:CreateSmartShape()
            if smart_shape:IsHairpin() then
                if smart_shape:CalcLeftCellMetricPos(arg_point) then
                    local left_seg = smart_shape:GetTerminateSegmentLeft()
                    local right_seg = smart_shape:GetTerminateSegmentRight()
                    local current_pos = left_seg:GetEndpointOffsetY()
                    local difference_pos = arg_point:GetY() - lowest_item[1]
                    if direction == "near" then
                        difference_pos = lowest_item[#lowest_item] - arg_point:GetY()
                    end
                    if has_dynamics == true then
                        if direction == "far" then
                            left_seg:SetEndpointOffsetY((current_pos - difference_pos) + 12)
                            right_seg:SetEndpointOffsetY((current_pos - difference_pos) + 12)
                        else
                            left_seg:SetEndpointOffsetY((current_pos + difference_pos) + 12)
                            right_seg:SetEndpointOffsetY((current_pos + difference_pos) + 12)
                        end
                    else
                        left_seg:SetEndpointOffsetY(lowest_item[1])
                        right_seg:SetEndpointOffsetY(lowest_item[1])
                    end
                    smart_shape:Save()
                end
            end
        end
    end
end

function horizontal_hairpin_adjustment(left_or_right, hairpin, region_settings, cushion_bool, multiple_hairpin_bool)
    local the_seg = hairpin:GetTerminateSegmentLeft()
    local left_dynamic_cushion = 9
    local right_dynamic_cushion = -9
    local left_selection_cushion = 0
    local right_selection_cushion = -18

    if left_or_right == "left" then
        the_seg = hairpin:GetTerminateSegmentLeft()
    end
    if left_or_right == "right" then
        the_seg = hairpin:GetTerminateSegmentRight()
    end

    local region = finenv.Region()
    region:SetStartStaff(region_settings[1])
    region:SetEndStaff(region_settings[1])

    if multiple_hairpin_bool == false then
        region:SetStartMeasure(region_settings[2])
        region:SetEndMeasure(region_settings[2])
        region:SetStartMeasurePos(region_settings[3])
        region:SetEndMeasurePos(region_settings[3])
        the_seg:SetMeasurePos(region_settings[3])
    else
        region:SetStartMeasure(the_seg:GetMeasure())
        region:SetStartMeasurePos(the_seg:GetMeasurePos())
        region:SetEndMeasure(the_seg:GetMeasure())
        region:SetEndMeasurePos(the_seg:GetMeasurePos())
    end


    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    local expression_list = {}
    for e in each(expressions) do
        local create_def = e:CreateTextExpressionDef()
        local cd = finale.FCCategoryDef()
        if cd:Load(create_def:GetCategoryID()) then
            if string.find(cd:CreateName().LuaString, "Dynamic") then
                local text_met = finale.FCTextMetrics()
                local string = create_def:CreateTextString()
                string:TrimEnigmaTags()
                text_met:LoadString(string, create_def:CreateTextString():CreateLastFontInfo(), 100)
                table.insert(expression_list, {text_met:CalcWidthEVPUs(), e, e:GetItemInci()})
            end
        end
    end
    if #expression_list > 0 then
        local dyn_width = (expression_list[1][1] / 2)
        local dyn_def = expression_list[1][2]:CreateTextExpressionDef()
        local manual_horizontal = expression_list[1][2]:GetHorizontalPos()
        local horizontal_offset = dyn_def:GetHorizontalOffset()
        local total_offset = manual_horizontal + horizontal_offset
        if left_or_right == "left" then
            local total_x = dyn_width + left_dynamic_cushion + total_offset
            the_seg:SetEndpointOffsetX(total_x)
        elseif left_or_right == "right" then
            cushion_bool = false
            local total_x = (0 - dyn_width) + right_dynamic_cushion + total_offset
            the_seg:SetEndpointOffsetX(total_x)
        end
    end
    if cushion_bool == true then
        the_seg = hairpin:GetTerminateSegmentRight()
        the_seg:SetEndpointOffsetX(right_selection_cushion)
    end
    hairpin:Save()
end

function hairpin_adjustments(range_settings, adjustment_type)

    local music_reg = finenv.Region()
    music_reg:SetStartStaff(range_settings[1])
    music_reg:SetEndStaff(range_settings[1])
    music_reg:SetStartMeasure(range_settings[2])
    music_reg:SetEndMeasure(range_settings[3])

    local hairpin_list = {}

    local ssmm = finale.FCSmartShapeMeasureMarks()
    ssmm:LoadAllForRegion(music_reg, true)
    for mark in each(ssmm) do
        local smartshape = mark:CreateSmartShape()
        if smartshape:IsHairpin() then
            table.insert(hairpin_list, smartshape)
        end
    end

    function has_dynamic(region)
        
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(region)
        local expression_list = {}
        for e in each(expressions) do
            local create_def = e:CreateTextExpressionDef()
            local cd = finale.FCCategoryDef()
            if cd:Load(create_def:GetCategoryID()) then
                if string.find(cd:CreateName().LuaString, "Dynamic") then
                    table.insert(expression_list, e)
                end
            end
        end
        if #expression_list > 0 then
            return true
        else
            return false
        end
    end

    local end_pos = range_settings[5]
    local end_cushion = false

    local notes_in_region = {}
    for noteentry in eachentrysaved(music_reg) do
        if noteentry:IsNote() then
            table.insert(notes_in_region, noteentry)
        end
    end

    music_reg:SetStartMeasure(notes_in_region[#notes_in_region]:GetMeasure())
    music_reg:SetEndMeasure(notes_in_region[#notes_in_region]:GetMeasure())
    music_reg:SetStartMeasurePos(notes_in_region[#notes_in_region]:GetMeasurePos())
    music_reg:SetEndMeasurePos(notes_in_region[#notes_in_region]:GetMeasurePos())
    
    if (has_dynamic(music_reg) == true) and (#notes_in_region > 1) then
        end_pos = notes_in_region[#notes_in_region]:GetMeasurePos()
    elseif (has_dynamic(music_reg) == true) and (#notes_in_region == 1) then
        end_pos = range_settings[5]
    else
        end_cushion = true
    end

    if adjustment_type == "both" then
        if #hairpin_list == 1 then
            horizontal_hairpin_adjustment("left", hairpin_list[1], {range_settings[1], range_settings[2], range_settings[4]}, end_cushion, false)
            horizontal_hairpin_adjustment("right", hairpin_list[1], {range_settings[1], range_settings[3], end_pos}, end_cushion, false)
        elseif #hairpin_list > 1 then
            for key, value in pairs(hairpin_list) do
                horizontal_hairpin_adjustment("left", value, {range_settings[1], range_settings[2], range_settings[4]}, end_cushion, true)
                horizontal_hairpin_adjustment("right", value, {range_settings[1], range_settings[3], end_pos}, end_cushion, true)
            end
        end
        music_reg:SetStartStaff(range_settings[1])
        music_reg:SetEndStaff(range_settings[1])
        music_reg:SetStartMeasure(range_settings[2])
        music_reg:SetEndMeasure(range_settings[3])
        music_reg:SetStartMeasurePos(range_settings[4])
        music_reg:SetEndMeasurePos(end_pos)

        vertical_dynamic_adjustment(music_reg, "far")
    else 
        music_reg:SetStartStaff(range_settings[1])
        music_reg:SetEndStaff(range_settings[1])
        music_reg:SetStartMeasure(range_settings[2])
        music_reg:SetEndMeasure(range_settings[3])
        music_reg:SetStartMeasurePos(range_settings[4])
        music_reg:SetEndMeasurePos(end_pos)

        vertical_dynamic_adjustment(music_reg, adjustment_type)
    end
end

function set_first_last_note_in_range(staff)

    local music_region = finenv.Region()
    local range_settings = {}
    music_region:SetCurrentSelection()
    music_region:SetStartStaff(staff)
    music_region:SetEndStaff(staff)

    local notes_in_region = {}

    for noteentry in eachentrysaved(music_region) do
        if noteentry:IsNote() then
            table.insert(notes_in_region, noteentry)
        end
    end

    if #notes_in_region > 0 then
        
        local start_pos = notes_in_region[1]:GetMeasurePos()
        
        local end_pos = notes_in_region[#notes_in_region]:GetMeasurePos() 

        local start_measure = notes_in_region[1]:GetMeasure()

        local end_measure = notes_in_region[#notes_in_region]:GetMeasure()
        
        if notes_in_region[#notes_in_region]:GetDuration() >= 2048 then
            end_pos = end_pos + notes_in_region[#notes_in_region]:GetDuration() 
        end
        
        range_settings[staff] = {staff, start_measure, end_measure, start_pos, end_pos}

        for key, value in pairs(range_settings) do
            local a = value[1]
            local b = value[2]
            local c = value[3]
            local d = value[4]
            local e = value[5]
            return {a, b, c, d, e}
        end
    else
        return false
    end
end

function dynamics_align_hairpins_and_dynamics()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            if set_first_last_note_in_range(staff:GetItemNo()) ~= false then
                hairpin_adjustments(set_first_last_note_in_range(staff:GetItemNo()), "both")
            end
        end
    end
end

dynamics_align_hairpins_and_dynamics()
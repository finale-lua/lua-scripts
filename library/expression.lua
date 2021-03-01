-- A collection of helpful JW Lua articulation scripts
-- Simply import this file to another Lua script to use any of these scripts
local expression = {}

function expression.get_music_region(expression)
    if not expression:IsSingleStaffAssigned() then
        return nil
    end
    local exp_region = finenv.Region()
    exp_region.StartStaff = expression.Staff
    exp_region.EndStaff = expression.Staff
    exp_region.StartMeasure = expression.Measure
    exp_region.EndMeasure = expression.Measure
    exp_region.StartMeasurePos = expression.MeasurePos
    exp_region.EndMeasurePos = expression.MeasurePos
    return exp_region
end

function expression.get_associated_entry(expression)
    local exp_region = expression.get_music_region(expression)
    if nil == exp_region then
        return nil
    end
    for entry in eachentry(exp_region) do
        if (0 == exp_region.LayerAssignment) or (entry.LayerNumber == exp.LayerAssignment) then
            if not entry:GetGraceNote() then -- for now skip all grace notes: we can revisit this if need be
                return entry
            end
        end
    end
    return nil
end

function expression.handle_offset_for_smart_shape(expression)
    local manual_horizontal = expression.HorizontalPos
    local def_horizontal = 0 
    local alignment_offset = 0
    local exp_def = expression:CreateTextExpressionDef()
    if nil ~= exp_def then
        def_horizontal = exp_def.HorizontalOffset
    end
    local exp_entry = expression.get_associated_entry(expression)
    if (nil ~= exp_entry) && (nil ~= exp_def) then
        local em = finale.FCEntryMetrics()
        if em.Load(exp_entry) then
            if 
        end
    end
    return (manual_horizontal + def_horizontal + alignment_offset)
end

return expression

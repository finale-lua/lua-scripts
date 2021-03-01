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
end

function expression.get_associated_entry(expression)
    local exp_region = expression.get_music_region(expression)
    if nil == exp_region then
        return nil
    end
    for entry in eachentry(exp_region) do
        if (0 == exp_region.LayerAssignment) or (entry.LayerNumber == exp.LayerAssignment) then
            return entry
        end
    end
    return nil
end

function expression.handle_offset(expression)
    local exp_entry = expression.get_associated_entry(expression)
end

return expression

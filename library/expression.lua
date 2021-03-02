-- A collection of helpful JW Lua articulation scripts
-- Simply import this file to another Lua script to use any of these scripts
local expression = {}

local note_entry = require("library.note_entry")

function expression.get_music_region(exp_assign)
    if not exp_assign:IsSingleStaffAssigned() then
        return nil
    end
    local exp_region = finenv.Region()
    exp_region.StartStaff = exp_assign.Staff
    exp_region.EndStaff = exp_assign.Staff
    exp_region.StartMeasure = exp_assign.Measure
    exp_region.EndMeasure = exp_assign.Measure
    exp_region.StartMeasurePos = exp_assign.MeasurePos
    exp_region.EndMeasurePos = exp_assign.MeasurePos
    return exp_region
end

function expression.get_associated_entry(exp_assign)
    local exp_region = expression.get_music_region(exp_assign)
    if nil == exp_region then
        return nil
    end
    for entry in eachentry(exp_region) do
        if (0 == exp_assign.LayerAssignment) or (entry.LayerNumber == exp_assign.LayerAssignment) then
            if not entry:GetGraceNote() then -- for now skip all grace notes: we can revisit this if need be
                return entry
            end
        end
    end
    return nil
end

function expression.calc_handle_offset_for_smart_shape(exp_assign)
    local manual_horizontal = exp_assign.HorizontalPos
    local def_horizontal = 0 
    local alignment_offset = 0 -- zero is for finale.ALIGNHORIZ_LEFTOFALLNOTEHEAD
    local exp_def = exp_assign:CreateTextExpressionDef()
    if nil ~= exp_def then
        def_horizontal = exp_def.HorizontalOffset
    end
    local exp_entry = expression.get_associated_entry(exp_assign)
    if nil == exp_entry then
        finenv.UI():AlertInfo("entry is nil", "info")
    end
    if (nil ~= exp_entry) and (nil ~= exp_def) then
        if finale.ALIGNHORIZ_LEFTOFPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_left_of_primary_notehead(exp_entry)
        elseif finale.ALIGNHORIZ_STEM == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_stem_offset(exp_entry)
        elseif finale.ALIGNHORIZ_CENTERPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_center_of_primary_notehead(exp_entry)
        elseif finale.ALIGNHORIZ_CENTERALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_center_of_all_noteheads(exp_entry)
        elseif finale.ALIGNHORIZ_RIGHTALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_width(exp_entry)
        end
    end
    return (manual_horizontal + def_horizontal + alignment_offset)
end

return expression

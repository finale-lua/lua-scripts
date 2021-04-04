--[[
$module Expression
]]
local expression = {}

local library = require("library.general_library")
local note_entry = require("library.note_entry")
local enigma_string = require("library.enigma_string")

function expression.get_music_region(exp_assign)
    if not exp_assign:IsSingleStaffAssigned() then
        return nil
    end
    local exp_region = finale.FCMusicRegion()
    exp_region:SetCurrentSelection() -- called to match the selected IU list (e.g., if using Staff Sets)
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
    local alignment_offset = 0
    local exp_def = exp_assign:CreateTextExpressionDef()
    if nil ~= exp_def then
        def_horizontal = exp_def.HorizontalOffset
    end
    local exp_entry = expression.get_associated_entry(exp_assign)
    if (nil ~= exp_entry) and (nil ~= exp_def) then
        if finale.ALIGNHORIZ_LEFTOFALLNOTEHEAD == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_left_of_all_noteheads(exp_entry)
        elseif finale.ALIGNHORIZ_LEFTOFPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_left_of_primary_notehead(exp_entry)
        elseif finale.ALIGNHORIZ_STEM == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_stem_offset(exp_entry)
        elseif finale.ALIGNHORIZ_CENTERPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_center_of_primary_notehead(exp_entry)
        elseif finale.ALIGNHORIZ_CENTERALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_center_of_all_noteheads(exp_entry)
        elseif finale.ALIGNHORIZ_RIGHTALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_right_of_all_noteheads(exp_entry)
        end
    end
    return (manual_horizontal + def_horizontal + alignment_offset)
end

--[[
% calc_text_width(expression_def, expand_tags)

@ expression_def (FCExpessionDef)
@ [expand_tags] (boolean) defaults to false, currently only suppoerts `^value()`
]]
function expression.calc_text_width(expression_def, expand_tags)
    expand_tags = expand_tags or false
    local fcstring = expression_def:CreateTextString()
    if expand_tags then
        enigma_string.expand_value_tag(fcstring, expression_def:GetPlaybackTempoValue())
    end
    local retval = enigma_string.calc_text_advance_width(fcstring)
    return retval
end

--[[
% is_for_current_part(exp_assign, current_part)

@ exp_assign (unknown)
@ [current_part] (unknown)
]]
function expression.is_for_current_part(exp_assign, current_part)
    current_part = current_part or library.get_current_part()
    if current_part:IsScore() and exp_assign.ScoreAssignment then
        return true
    elseif current_part:IsPart() and exp_assign.PartAssignment then
        return true
    end
    return false
end

return expression

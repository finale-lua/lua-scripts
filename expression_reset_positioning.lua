function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "February 28, 2020"
    finaleplugin.CategoryTags = "Expression"
    return "Reset Expression Positions", "Reset Expression Positions", "Resets the assignment position of all selected single-staff expressions."
end

function expression_reset_positioning()
    local parts = finale.FCParts()
    parts:LoadAll()
    local current_part = parts:GetCurrent()
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(finenv.Region())
    for expression in each(expressions) do
        if 0 == expression.StaffListID then -- note: IsSingleStaffAssigned() appears to be not 100% accurate for exps with staff lists
            local do_reset = false
            if current_part:IsScore() and expression.ScoreAssignment then
                do_reset = true
            end
            if current_part:IsPart() and expression.PartAssignment then
                do_reset = true
            end
            if do_reset then
                expression:ResetPos()
                expression:Save()
            end
        end
    end
end

expression_reset_positioning()

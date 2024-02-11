function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "January 29, 2023"
    finaleplugin.CategoryTags = "Expression"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        This script implements three menu options to modify expressions.

        - Expression Set To Score And Parts
        - Expression Set To Score Only
        - Expression Set To Parts Only

        It changes any selected single-staff expressions that is visible in the current score or part view.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Expression Set To Score Only
        Expression Set To Parts Only
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Set any single-staff text expression in the currenly selected region to Score Only assignment.
        Set any single-staff text expression in the currenly selected region to Parts Only assignment.
    ]]
    finaleplugin.AdditionalPrefixes = [[
        set_for_score = true set_for_parts = false
        set_for_score = false set_for_parts = true
    ]]
    return "Expression Set To Score And Parts", "Expression Set To Score And Parts", "Set any single-staff text expression in the currenly selected region to both Score and Parts assignment."
end

local library = require("library.general_library")
local expression = require("library.expression")

if set_for_score == nil then set_for_score = true end
if set_for_parts == nil then set_for_parts = true end

function expression_score_parts_assignment()
    local current_part = library.get_current_part()
    local expression_assignments = finale.FCExpressions()
    expression_assignments:LoadAllForRegion(finenv.Region())
    for expression_assignment in each(expression_assignments) do
        if 0 == expression_assignment.StaffListID then -- note: IsSingleStaffAssigned() appears to be not 100% accurate for exps with staff lists
            if expression.is_for_current_part(expression_assignment, current_part) then
                expression_assignment.ScoreAssignment = set_for_score
                expression_assignment.PartAssignment = set_for_parts
                expression_assignment:Save()
            end
        end
    end
end

expression_score_parts_assignment()

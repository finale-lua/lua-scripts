function plugindef()
   -- This function and the 'finaleplugin' namespace
   -- are both reserved for the plug-in definition.
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 20, 2021"
    finaleplugin.CategoryTags = "Expression"
    return "Expression Set To Score Only", "Expression Set To Score Only", "Set any single-staff text expression in the currenly selected region to Score Only assignment."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library.general_library")
local expression = require("library.expression")

function expression_set_to_score_only()
    local current_part = library.get_current_part()
    local expression_assignments = finale.FCExpressions()
    expression_assignments:LoadAllForRegion(finenv.Region())
    for expression_assignment in each(expression_assignments) do
        if 0 == expression_assignment.StaffListID then -- note: IsSingleStaffAssigned() appears to be not 100% accurate for exps with staff lists
            if expression.is_for_current_part(expression_assignment, current_part) then
                expression_assignment.ScoreAssignment = true
                expression_assignment.PartAssignment = false
                expression_assignment:Save()
            end
        end
    end
end

expression_set_to_score_only()

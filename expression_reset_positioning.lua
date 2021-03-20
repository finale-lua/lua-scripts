function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "March 20, 2021"
    finaleplugin.CategoryTags = "Expression"
    return "Reset Expression Positions", "Reset Expression Positions", "Resets the assignment position of all selected single-staff expressions."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library.general_library")
local expression = require("library.expression")

function expression_reset_positioning()
    local current_part = library.get_current_part()
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(finenv.Region())
    for exp_assign in each(expressions) do
        if 0 == exp_assign.StaffListID then -- note: IsSingleStaffAssigned() appears to be not 100% accurate for exps with staff lists
            if expression.is_for_current_part(exp_assign, current_part) then
                exp_assign:ResetPos()
                exp_assign:Save()
            end
        end
    end
end

expression_reset_positioning()

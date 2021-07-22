function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "July 7, 2021"
    finaleplugin.CategoryTags = "Measure"
    return "Measure Numbers Reset Vertical", "Measure Numbers Reset Vertical", "Reset vertical position to default for selected measure numbers."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library.general_library")

function measure_numbers_reset_vertical()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local meas_num_regions = finale.FCMeasureNumberRegions()
    meas_num_regions:LoadAll()
    local parts = finale.FCParts()
    parts:LoadAll()
    local current_part = parts:GetCurrent()
    local current_is_part = not current_part:IsScore()
    local sel_region = library.get_selected_region_or_whole_doc()

    local cells = finale.FCCells()
    cells:ApplyRegion(sel_region)
    for cell in each(cells) do
        local system = systems:FindMeasureNumber(cell.Measure)
        local meas_num_region = meas_num_regions:FindMeasure(cell.Measure)
        if (nil ~= system) and (nil ~= meas_num_region) then
            if library.is_default_measure_number_visible_on_cell(meas_num_region, cell, system, current_is_part) then
                local sep_nums = finale.FCSeparateMeasureNumbers()
                sep_nums:LoadAllInCell(cell)
                if (sep_nums.Count > 0) then
                    for sep_num in each(sep_nums) do
                        sep_num.VerticalPosition = 0
                        sep_num:Save()
                    end
                end
            end
        end
    end
end

measure_numbers_reset_vertical()

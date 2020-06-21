function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 21, 2020"
    finaleplugin.CategoryTags = "Measure"
    return "Measure Numbers Move Up", "Measure Numbers Move Up", "Moves all measure numbers up by one staff space."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library.general_library")

local move_amount = 24 -- evpus

function measure_numbers_move_up()
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
                        sep_num.VerticalPosition = sep_num.VerticalPosition + move_amount
                        sep_num:Save()
                    end
                elseif (0 ~= lead_in) then
                    local sep_num = finale.FCSeparateMeasureNumber()
                    sep_num:ConnectCell(cell)
                    sep_num:AssignMeasureNumberRegion(meas_num_region)
                    sep_num.VerticalPosition = sep_num.VerticalPosition + move_amount
                    --sep_num:SetShowOverride(true) -- enable this line if you want to force show the number. otherwise it will show or hide based on the measure number region
                    if sep_num:SaveNew() then
                        local measure = finale.FCMeasure()
                        measure:Load(cell.Measure)
                        measure:SetContainsManualMeasureNumbers(true)
                        measure:Save()
                    end
                end
            end
        end
    end
end

measure_numbers_move_up()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 19, 2020"
    finaleplugin.CategoryTags = "Measure"
    return "Measure Numbers Adjust for Key, Time, Repeat", "Measure Numbers Adjust for Key, Time, Repeat", "Adjusts all measure numbers left where there is a key signature, time signature, or start repeat."
end

-- Currently the PDK Framework does not appear to provide access to the true barline thickness per measure from the PDK metrics.
-- As a subtitute this sets barline_thickness to your configured single barline thickness in your document prefs (in evpus)
-- This will makes it right at least for single barlines.

local size_prefs = finale.FCSizePrefs()
size_prefs:Load(1)
local barline_thickness = math.floor(size_prefs.ThinBarlineThickness/64.0 + 0.5) -- barline thickness in evpu

-- additional_offset allows you to tweak the result. it is only applied if the measure is being moved, as opposed to barline_thickness
-- which is always applied

local additional_offset = 0 -- add more here evpu to taste (positive values move the number to the right)

local is_mid_system_default_number_visible = function (meas_num_region, cell, system, current_is_part)
    if cell.Measure == system.FirstMeasure then
        return false
    end
    if not meas_num_region:GetShowMultiples(current_is_part) then
        return false
    end
    local staff = finale.FCCurrentStaffSpec()
    if not staff:LoadForCell(cell, 0) then
        return false
    end
    if staff.ShowMeasureNumbers then
        return true
    end
    if meas_num_region:GetShowOnTopStaff() and (cell.Staff == system.TopStaff) then
        return true
    end
    if meas_num_region:GetShowOnBottomStaff() and (cell.Staff == system:CalcBottomStaff()) then
        return true
    end
    return false
end

function measure_numbers_adjust_for_leadin()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local meas_num_regions = finale.FCMeasureNumberRegions()
    meas_num_regions:LoadAll()
    local parts = finale.FCParts()
    parts:LoadAll()
    local current_part = parts:GetCurrent()
    local current_is_part = not current_part:IsScore()

    for meas_num, staff in eachcell(finenv.Region()) do
        local system = systems:FindMeasureNumber(meas_num)
        local meas_num_region = meas_num_regions:FindMeasure(meas_num)
        if (nil ~= system) and (nil ~= meas_num_region) then
            if ( meas_num > system.FirstMeasure ) then
                local cell_metrics = finale.FCCellMetrics()
                local cell = finale.FCCell(meas_num, staff)
                if cell_metrics:LoadAtCell(cell) and (cell_metrics.StaffScaling ~= 0) then --metrics are all zero for measures inside mm rests, so skip those
                    if is_mid_system_default_number_visible(meas_num_region, cell, system, current_is_part) then
                        local lead_in = cell_metrics.MusicStartPos - cell_metrics:GetLeftEdge()
                        -- FCCellMetrics currently does not provide the barline width, which is available in the underlying PDK struct.
                        -- if it did, we would subtract it here. Instead use the valus derived from document settings above.
                        lead_in = lead_in - barline_thickness
                        if (0 ~= lead_in) then
                            print ("lead in found at cell ", cell.Measure, " ", cell.Staff)
                            lead_in = lead_in - additional_offset
                            -- Finale scales the lead_in by the staff percent, so remove that if any
                            local staff_percent = (cell_metrics.StaffScaling / 10000.0) / (cell_metrics.SystemScaling / 10000.0)
                            lead_in = math.floor(lead_in/staff_percent + 0.5)
                            -- FCSeparateMeasureNumber is scaled horizontally by the horizontal stretch, so back that out
                            local horz_percent = cell_metrics.HorizontalStretch / 10000.0
                            lead_in = math.floor(lead_in/horz_percent + 0.5)
                        end
                        local sep_nums = finale.FCSeparateMeasureNumbers()
                        sep_nums:LoadAllInCell(cell)
                        if (sep_nums.Count > 0) then
                            for sep_num in each(sep_nums) do
                                sep_num.HorizontalPosition = -lead_in
                                sep_num:Save()
                            end
                        elseif (0 ~= lead_in) then
                            local sep_num = finale.FCSeparateMeasureNumber()
                            sep_num:ConnectCell(cell)
                            sep_num:AssignMeasureNumberRegion(meas_num_region)
                            sep_num.HorizontalPosition = -lead_in
                            --sep_num:SetShowOverride(true) -- enable this line if you want to force show the number. otherwise it will show or hide based on the measure number region
                            if sep_num:SaveNew() then
                                local measure = finale.FCMeasure()
                                measure:Load(meas_num)
                                measure:SetContainsManualMeasureNumbers(true)
                                measure:Save()
                            end
                        end
                    end
                end
            end
        end
    end
end

measure_numbers_adjust_for_leadin()

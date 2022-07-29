function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 19, 2020"
    finaleplugin.CategoryTags = "Measure"
    return "Measure Numbers Adjust for Key, Time, Repeat", "Measure Numbers Adjust for Key, Time, Repeat", "Adjusts all measure numbers left where there is a key signature, time signature, or start repeat."
end

local library = require("library.general_library")

-- Before v0.59, the PDK Framework did not provide access to the true barline thickness per measure from the PDK metrics.
-- As a substitute this sets barline_thickness to your configured single barline thickness in your document prefs (in evpus)
-- This makes it come out right at least for single barlines.

local size_prefs = finale.FCSizePrefs()
size_prefs:Load(1)
local default_barline_thickness = math.floor(size_prefs.ThinBarlineThickness/64.0 + 0.5) -- barline thickness in evpu

-- additional_offset allows you to tweak the result. it is only applied if the measure number is being moved

local additional_offset = 0 -- here you can add more evpu to taste (positive values move the number to the right)

function measure_numbers_adjust_for_leadin()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local meas_num_regions = finale.FCMeasureNumberRegions()
    meas_num_regions:LoadAll()
    local parts = finale.FCParts()
    parts:LoadAll()
    local current_part = parts:GetCurrent()
    local current_is_part = not current_part:IsScore()
    local sel_region = library.get_selected_region_or_whole_doc()

    for system in each(systems) do
        local system_region = finale.FCMusicRegion()
        if system:CalcRegion(system_region) and system_region:IsOverlapping(sel_region) then
            -- getting metrics doesn't work for mm rests (past the first measure) but it takes a really big performance hit, so skip any that aren't first
            -- it is for this reason we are doing our own nested for loops instead of using for cell in each(cells)
            local skip_past_meas_num = 0
            local previous_meas_num = system_region.StartMeasure
            for meas_num = system_region.StartMeasure, system_region.EndMeasure do
                if meas_num > skip_past_meas_num then
                    local meas_num_region = meas_num_regions:FindMeasure(meas_num)
                    if nil ~= meas_num_region then
                        local parts_val = library.calc_parts_boolean_for_measure_number_region(meas_num_region, current_is_part)
                        multimeasure_rest = finale.FCMultiMeasureRest()
                        local is_for_multimeasure_rest = multimeasure_rest:Load(meas_num)
                        if is_for_multimeasure_rest then
                            skip_past_meas_num = multimeasure_rest.EndMeasure
                        end
                        if sel_region:IsMeasureIncluded(meas_num)  then
                            for slot = system_region.StartSlot, system_region.EndSlot do
                                local staff = system_region:CalcStaffNumber(slot)
                                if sel_region:IsStaffIncluded(staff) then
                                    local cell = finale.FCCell(meas_num, staff)
                                    if library.is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest) then
                                        local lead_in = 0
                                        if cell.Measure ~= system.FirstMeasure then
                                            local cell_metrics = finale.FCCellMetrics()
                                            if cell_metrics:LoadAtCell(cell) then
                                                lead_in = cell_metrics.MusicStartPos - cell_metrics:GetLeftEdge()
                                                -- FCCellMetrics did not provide the barline width before v0.59.
                                                -- Use the value derived from document settings above if we can't get the real width.
                                                local barline_thickness = default_barline_thickness
                                                if cell_metrics.GetRightBarlineWidth then -- if the property getter exists, then we are at 0.59+
                                                    local previous_cell_metrics = finale.FCCellMetrics()
                                                    if previous_cell_metrics:LoadAtCell(finale.FCCell(previous_meas_num, staff)) then
                                                        barline_thickness = previous_cell_metrics.RightBarlineWidth
                                                        previous_cell_metrics:FreeMetrics()
                                                    end
                                                end
                                                lead_in = lead_in - barline_thickness
                                                if meas_num_region:GetMultipleJustification(parts_val) == finale.MNJUSTIFY_CENTER then
                                                    lead_in = lead_in + math.floor(barline_thickness/2.0 + 0.5)
                                                end
                                                if (0 ~= lead_in) then
                                                    -- Finale scales the lead_in by the staff percent, so remove that if any
                                                    local staff_percent = (cell_metrics.StaffScaling / 10000.0) / (cell_metrics.SystemScaling / 10000.0)
                                                    lead_in = math.floor(lead_in/staff_percent + 0.5)
                                                    -- FCSeparateMeasureNumber is scaled horizontally by the horizontal stretch, so back that out
                                                    local horz_percent = cell_metrics.HorizontalStretch / 10000.0
                                                    lead_in = math.floor(lead_in/horz_percent + 0.5)
                                                end
                                                lead_in = lead_in + meas_num_region:GetMultipleHorizontalPosition(parts_val)
                                            end
                                            cell_metrics:FreeMetrics() -- not sure if this is needed, but it can't hurt
                                        end
                                        local sep_nums = finale.FCSeparateMeasureNumbers()
                                        sep_nums:LoadAllInCell(cell)
                                        if (sep_nums.Count > 0) then
                                            for sep_num in each(sep_nums) do
                                                sep_num.HorizontalPosition = -lead_in + additional_offset
                                                sep_num:Save()
                                            end
                                        elseif (0 ~= lead_in) then
                                            local sep_num = finale.FCSeparateMeasureNumber()
                                            sep_num:ConnectCell(cell)
                                            sep_num:AssignMeasureNumberRegion(meas_num_region)
                                            sep_num.HorizontalPosition = -lead_in + additional_offset
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
                    end
                    previous_meas_num = meas_num
                end
            end
        end
    end
end

measure_numbers_adjust_for_leadin()

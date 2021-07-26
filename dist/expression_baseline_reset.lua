function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Version = "1.0"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Date = "July 7, 2021"
    finaleplugin.CategoryTags = "Expression"
    finaleplugin.AuthorURL = "http://robertgpatterson.com"
    return "Reset Expression Baseline", "Reset Expression Baseline",
           "Resets the selected expression above baselines"
end

function expression_baseline_reset()
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()

    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local lastSys_number = lastSys:GetItemNo()
    local start_slot = region:GetStartSlot()
    local end_slot = region:GetEndSlot()

    for i = system_number, lastSys_number, 1 do
        local baselines = finale.FCBaselines()
        baselines:LoadAllForSystem(finale.BASELINEMODE_EXPRESSIONABOVE, i)
        for baseline in each(baselines) do
            local baseline_slot = region:CalcSlotNumber(baseline.Staff)
            if (start_slot <= baseline_slot) and (baseline_slot <= end_slot) then
                baseline:DeleteData()
            end
        end
end
end

expression_baseline_reset()

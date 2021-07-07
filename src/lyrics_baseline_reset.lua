function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Version = "1.0"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Date = "July 7, 2021"
    finaleplugin.CategoryTags = "Lyric"
    finaleplugin.AuthorURL = "http://robertgpatterson.com"
    return "Reset Lyric Baselines", "Reset Lyrics Baselines",
           "Resets all selected lyrics baselines to default"
end

local baseline_types = {
    finale.BASELINEMODE_LYRICSVERSE,
    finale.BASELINEMODE_LYRICSCHORUS,
    finale.BASELINEMODE_LYRICSSECTION
}

function lyrics_baseline_reset()
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
        for _, baseline_type in pairs(baseline_types) do
            baselines:LoadAllForSystem(baseline_type, i)
            for baseline in each(baselines) do
                local baseline_slot = region:CalcSlotNumber(baseline.Staff)
                if (start_slot <= baseline_slot) and (baseline_slot <= end_slot) then
                    baseline:DeleteData()
                end
            end
        end
    end
end

lyrics_baseline_reset()

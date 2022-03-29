function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "March 26, 2022"
    finaleplugin.CategoryTags = "Chord"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        Select system staves for which you want to move the chord baseline down, then run this script
    ]]
    return "Move chord baseline down", "Move chord baseline down", "Moves the selected chord baseline down one space"
end

-- A measurement of helpful JW Lua scripts
-- Simply import this file to another Lua script to use any of these scripts
local measurement = {}

function measurement.convert_to_EVPUs(text)
    local str = finale.FCString()
    str.LuaString = text
    return str:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)
end




function chord_baseline_move_down()
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()

    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local last_system = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local last_system_number = last_system:GetItemNo()
    local start_staff = region:GetStartStaff()
    local end_staff = region:GetEndStaff()

    for i = system_number, last_system_number, 1 do
        local baselines = finale.FCBaselines()
        baselines:LoadAllForSystem(finale.BASELINEMODE_CHORD, i)
        for j = start_staff, end_staff, 1 do
            local baseline = baselines:AssureSavedStaff(finale.BASELINEMODE_CHORD, i, j)
            baseline.VerticalOffset = baseline.VerticalOffset + measurement.convert_to_EVPUs("-1s")
            baseline:Save()
        end
    end
end

chord_baseline_move_down()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 20, 2020"
    finaleplugin.CategoryTags = "System"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Move System Up", "Move System Up", "Moves the selected system up one space"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
-- A measurement of helpful JW Lua scripts
-- Simply import this file to another Lua script to use any of these scripts
local measurement = {}

function measurement.convert_to_EVPUs(text)
    local str = finale.FCString()
    str.LuaString = text
    return str:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)
end




function system_move_up()
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()

    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local last_system = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local last_system_number = last_system:GetItemNo()

    for i = system_number, last_system_number, 1 do
        local system = systems:GetItemAt(i - 1)
        system.TopMargin = system.TopMargin + measurement.convert_to_EVPUs("-1s")
        system:Save()
    end
end

system_move_up()


-- A measurement of helpful JW Lua scripts
-- Simply import this file to another Lua script to use any of these scripts
local measurement = {}

function measurement.convert_to_EVPUs(text)
    local str = finale.FCString()
    str.LuaString = text
    return str:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)
end

return measurement

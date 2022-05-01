function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Version = "1.0"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Date = "July 7, 2021"
    finaleplugin.CategoryTags = "Expression"
    finaleplugin.AuthorURL = "http://robertgpatterson.com"
    return "Move Expression Baseline Below Down", "Move Expression Baseline Below Down",
           "Moves the selected expression above baseline down one space"
end

--[[
$module measurement
]] --
local measurement = {}

--[[
% convert_to_EVPUs

Converts the specified string into EVPUs. Like text boxes in Finale, this supports
the usage of units at the end of the string. The following are a few examples:

- `12s` => 288 (12 spaces is 288 EVPUs)
- `8.5i` => 2448 (8.5 inches is 2448 EVPUs)
- `10cm` => 1133 (10 centimeters is 1133 EVPUs)
- `10mm` => 113 (10 millimeters is 113 EVPUs)
- `1pt` => 4 (1 point is 4 EVPUs)
- `2.5p` => 120 (2.5 picas is 120 EVPUs)

Read the [Finale User Manual](https://usermanuals.finalemusic.com/FinaleMac/Content/Finale/def-equivalents.htm#overriding-global-measurement-units)
for more details about measurement units in Finale.

@ text (string) the string to convert
: (number) the converted number of EVPUs
]]
function measurement.convert_to_EVPUs(text)
    local str = finale.FCString()
    str.LuaString = text
    return str:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)
end




function expression_baseline_below_move_down()
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
        baselines:LoadAllForSystem(finale.BASELINEMODE_EXPRESSIONBELOW, i)
        for j = start_slot, end_slot do
            bl = baselines:AssureSavedStaff(finale.BASELINEMODE_EXPRESSIONBELOW, i, region:CalcStaffNumber(j))
            bl.VerticalOffset = bl.VerticalOffset - measurement.convert_to_EVPUs("1s")
            bl:Save()
        end
    end
end

expression_baseline_below_move_down()

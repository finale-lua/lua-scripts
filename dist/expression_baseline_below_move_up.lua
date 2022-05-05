function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Version = "1.0"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Date = "July 7, 2021"
    finaleplugin.CategoryTags = "Expression"
    finaleplugin.AuthorURL = "http://robertgpatterson.com"
    return "Move Expression Baseline Below Up", "Move Expression Baseline Below Up",
           "Moves the selected expression below baseline up one space"
end

--[[
$module measurement
]] --
local measurement = {}

local unit_names = {
    [finale.MEASUREMENTUNIT_EVPUS] = "EVPUs",
    [finale.MEASUREMENTUNIT_INCHES] = "Inches",
    [finale.MEASUREMENTUNIT_CENTIMETERS] = "Centimeters",
    [finale.MEASUREMENTUNIT_POINTS] = "Points",
    [finale.MEASUREMENTUNIT_PICAS] = "Picas",
    [finale.MEASUREMENTUNIT_SPACES] = "Spaces",
}

local unit_suffixes = {
    [finale.MEASUREMENTUNIT_EVPUS] = "e",
    [finale.MEASUREMENTUNIT_INCHES] = "i",
    [finale.MEASUREMENTUNIT_CENTIMETERS] = "c",
    [finale.MEASUREMENTUNIT_POINTS] = "pt",
    [finale.MEASUREMENTUNIT_PICAS] = "p",
    [finale.MEASUREMENTUNIT_SPACES] = "s",
}

local unit_abbreviations = {
    [finale.MEASUREMENTUNIT_EVPUS] = "ev",
    [finale.MEASUREMENTUNIT_INCHES] = "in",
    [finale.MEASUREMENTUNIT_CENTIMETERS] = "cm",
    [finale.MEASUREMENTUNIT_POINTS] = "pt",
    [finale.MEASUREMENTUNIT_PICAS] = "pc",
    [finale.MEASUREMENTUNIT_SPACES] = "sp",
}

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

--[[
% get_unit_name

Returns the name of a measurement unit.

@ unit (number) A finale MEASUREMENTUNIT constant.
: (string)
]]
function measurement.get_unit_name(unit)
    if unit == finale.MEASUREMENTUNIT_DEFAULT then
        unit = measurement.get_real_default_unit()
    end

    return unit_names[unit]
end

--[[
% get_unit_suffix

Returns the measurement unit's suffix. Suffixes can be used to force the text value (eg in `FCString` or `FCCtrlEdit`) to be treated as being from a particular measurement unit
Note that although this method returns a "p" for Picas, the fractional part goes after the "p" (eg `1p6`), so in practice it may be that no suffix is needed.

@ unit (number) A finale MEASUREMENTUNIT constant.
: (string)
]]
function measurement.get_unit_suffix(unit)
    if unit == finale.MEASUREMENTUNIT_DEFAULT then
        unit = measurement.get_real_default_unit()
    end

    return unit_suffixes[unit]
end

--[[
% get_unit_abbreviation

Returns measurement unit abbreviations that are more human-readable than Finale's internal suffixes.
Abbreviations are also compatible with the internal ones because Finale discards everything after the first letter that isn't part of the suffix.

For example:
```lua
local str_internal = finale.FCString()
str.LuaString = "2i"

local str_display = finale.FCString()
str.LuaString = "2in"

print(str_internal:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT) == str_display:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)) -- true
```

@ unit (number) A finale MEASUREMENTUNIT constant.
: (string)
]]
function measurement.get_unit_abbreviation(unit)
    if unit == finale.MEASUREMENTUNIT_DEFAULT then
        unit = measurement.get_real_default_unit()
    end

    return unit_abbreviations[unit]
end

--[[
% is_valid_unit

Checks if a number is equal to one of the finale MEASUREMENTUNIT constants.

@ unit (number) The unit to check.
: (boolean) `true` if valid, `false` if not.
]]
function measurement.is_valid_unit(unit)
    return unit_names[unit] and true or false
end

--[[
% get_real_default_unit

Resolves `finale.MEASUREMENTUNIT_DEFAULT` to the value of one of the other `MEASUREMENTUNIT` constants.

: (number)
]]
function measurement.get_real_default_unit()
    local str = finale.FCString()
    finenv.UI():GetDecimalSeparator(str)
    local separator = str.LuaString
    str:SetMeasurement(72, finale.MEASUREMENTUNIT_DEFAULT)

    if str.LuaString == "72" then
        return finale.MEASUREMENTUNIT_EVPUS
    elseif str.LuaString == "0" .. separator .. "25" then
        return finale.MEASUREMENTUNIT_INCHES
    elseif str.LuaString == "0" .. separator .. "635" then
        return finale.MEASUREMENTUNIT_CENTIMETERS
    elseif str.LuaString == "18" then
        return finale.MEASUREMENTUNIT_POINTS
    elseif str.LuaString == "1p6" then
        return finale.MEASUREMENTUNIT_PICAS
    elseif str.LuaString == "3" then
        return finale.MEASUREMENTUNIT_SPACES
    end
end




function expression_baseline_below_move_up()
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
            bl.VerticalOffset = bl.VerticalOffset + measurement.convert_to_EVPUs("1s")
            bl:Save()
        end
    end
end

expression_baseline_below_move_up()

local __imports = {}
local __import_results = {}

function require(item)
    if not __imports[item] then
        error("module '" .. item .. "' not found")
    end

    if __import_results[item] == nil then
        __import_results[item] = __imports[item]()
        if __import_results[item] == nil then
            __import_results[item] = true
        end
    end

    return __import_results[item]
end

__imports["library.measurement"] = function()
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

    return measurement

end

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "June 20, 2020"
    finaleplugin.CategoryTags = "Staff"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Move Staff Down", "Move Staff Down", "Moves the selected staves down by 1 space"
end

local measurement = require("library.measurement")

local single_space_evpus =  measurement.convert_to_EVPUs(tostring("1s"))

function staff_move_down()
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local start_system = systems:FindMeasureNumber(region.StartMeasure)
    local end_system = systems:FindMeasureNumber(region.EndMeasure)

    for system_number = start_system.ItemNo, end_system.ItemNo do
        local system_staves = finale.FCSystemStaves()
        system_staves:LoadAllForItem(system_number)
        local accumulated_offset = 0
        local skipped_first = false
        for system_staff in each(system_staves) do
            if skipped_first then
                if region:IsStaffIncluded(system_staff.Staff) then
                    accumulated_offset = accumulated_offset + single_space_evpus
                end
                if accumulated_offset > 0 then
                    system_staff.Distance = system_staff.Distance + accumulated_offset
                    system_staff:Save()
                end
            else
                skipped_first = true
            end
        end
    end
end

staff_move_down()

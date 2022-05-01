function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "June 20, 2020"
    finaleplugin.CategoryTags = "Staff"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Move Staff Up", "Move Staff Up", "Moves the selected staves up by 1 space"
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




local single_space_evpus =  measurement.convert_to_EVPUs(tostring("1s"))

function staff_move_up()
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
                    system_staff.Distance = system_staff.Distance - accumulated_offset
                    system_staff:Save()
                end
            else
                skipped_first = true
            end
        end
    end
end

staff_move_up()

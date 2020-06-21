function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 20, 2020"
    finaleplugin.CategoryTags = "Staff"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Move Staff Up", "Move Staff Up", "Moves the selected staves up by 1 space"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local measurement = require("library.measurement")

function staff_move_down()
    local region = finenv.Region()
    local start_staff = region:GetStartStaff()
    local end_staff = region:GetEndStaff()
    local start_measure = region:GetStartMeasure()

    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local system = systems:FindMeasureNumber(start_measure)

    local system_number = system:GetItemNo()

    local system_staves = finale.FCSystemStaves()

    system_staves:LoadAllForItem(system_number)
    for system_staff in each(system_staves) do
        if (system_staff.Staff + 1 > start_staff) then
            local move_distance = math.min(system_staff.Staff - start_staff + 1, end_staff - start_staff + 1)
            system_staff.Distance = system_staff.Distance +
                                        measurement.convert_to_EVPUs(tostring(-1 * move_distance) .. "s")
            system_staff:Save()
        end
    end
end

staff_move_down()

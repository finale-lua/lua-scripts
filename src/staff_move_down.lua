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

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
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

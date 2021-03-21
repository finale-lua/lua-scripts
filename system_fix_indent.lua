function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Robert Patteson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 21, 2021"
    finaleplugin.CategoryTags = "System"
    finaleplugin.AuthorURL = "https://robertgpatterson.com"
    return "Fix Indent From Doc. Settings", "Fix Indent From Doc. Settings", "Using the Page Format For options, adjusts indentation of selected systems."
end

-- This script recreates the Fix Indent function of the JW New Piece plugin. The reason for the script is
-- that JW New Piece uses the indentation of System 1 for the other first systems, and it assumes 0 for
-- non-first systems. This script gets those values out of Page Format For Score or Page Format For Parts,
-- depending on whether we are currently viewing score or part.

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library.general_library")

function system_fix_indent()
    local region = library.get_selected_region_or_whole_doc()
    local page_format_prefs = library.get_page_format_prefs()

    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local first_system_number = systems:FindMeasureNumber(region.StartMeasure).ItemNo
    local last_system_number = systems:FindMeasureNumber(region.EndMeasure).ItemNo

    for i = first_system_number, last_system_number do
        local system = systems:GetItemAt(i - 1)
        local first_meas = finale.FCMeasure()
        local is_first_system = (system.FirstMeasure == 1)
        if (not is_first_system) and first_meas:Load(system.FirstMeasure) then
            if first_meas.ShowFullNames then
                is_first_system = true
            end
        end
        if is_first_system and page_format_prefs.UseFirstSystemMargins then
            system.LeftMargin = page_format_prefs.FirstSystemLeft
        else
            system.LeftMargin = page_format_prefs.SystemLeft
        end
        system:Save()
    end

    library.update_layout()
end

system_fix_indent()


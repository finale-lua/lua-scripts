function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Robert Patteson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "April 23, 2022"
    finaleplugin.CategoryTags = "System"
    finaleplugin.AuthorURL = "https://robertgpatterson.com"
    finaleplugin.Notes = [[
        This script replaces the Fix Indent function of the JW New Piece plugin. It behaves slightly differently, however.
        The JW New Piece plugin uses the indentation of System 1 for the other first systems, and it assumes 0 for
        non-first systems. This script gets those values out of Page Format For Score or Page Format For Parts,
        depending on whether we are currently viewing score or part.
    ]]
    return "Fix Indent From Doc. Settings", "Fix Indent From Doc. Settings", "Resets the left-side indentation of selected systems using the Page Format For options."
end

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
        library.system_indent_set_to_prefs(system, page_format_prefs)
    end

    library.update_layout()
end

system_fix_indent()


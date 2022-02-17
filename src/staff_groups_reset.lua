function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "Staff"
    return "Groups Reset", "Groups Reset",
           "Deletes all groups except those starting on the first measure, and extends those for the entire length of the document."
end

local library = require("library.general_library")

function staff_groups_reset()
    local sel_region = library.get_selected_region_or_whole_doc()
    local groups = finale.FCGroups()
    groups:LoadAll()
    for group in each(groups) do
        if library.group_is_contained_in_region(group, sel_region) then
            if (group.StartMeasure == 1) then -- EMEAS_MIN in PDK
                group.EndMeasure = 32767 -- EMEAS_MAX in PDK
                group:Save()
            else
                group:DeleteData()
            end
        end
    end
end

staff_groups_reset()

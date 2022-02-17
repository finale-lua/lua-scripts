function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "Staff"
    return "Reset Full Group Name Fonts", "Reset Full Group Name Fonts",
           "Reset all full group names to document's default font settings."
end

local library = require("library.general_library")
local enigma_string = require("library.enigma_string")

function prefs_reset_group_full_name_fonts()
    local sel_region = library.get_selected_region_or_whole_doc()
    local font_info = finale.FCFontInfo()
    font_info:LoadFontPrefs(finale.FONTPREF_GROUPNAME)
    local groups = finale.FCGroups()
    groups:LoadAll()
    for group in each(groups) do
        if library.group_overlaps_region(group, sel_region) then
            if group:HasFullName() then
                text_block = finale.FCTextBlock()
                if text_block:Load(group:GetFullNameID()) then
                    if enigma_string.change_first_text_block_font(text_block, font_info) then
                        text_block:Save()
                    end
                end
            end
        end
    end
end

prefs_reset_group_full_name_fonts()

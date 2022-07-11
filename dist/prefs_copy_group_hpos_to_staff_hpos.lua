function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 9, 2020"
    finaleplugin.CategoryTags = "Staff"
    finaleplugin.Notes = [[
        This script mitigates a bug that existed in Finale 2012 but was fixed as of Finale 2014.5. Editing a linked part
        with a plugin frequently caused the horizontal position of staves to be randomly modified in the score. This
        script restores the staff horizontal position by setting it to match the default horizontal group name position.
    ]]
    return "Copy Default Group Name Horizontal Position To Staff", "Copy Default Group Name Horizontal Position To Staff", "Copies default horizontal group name positions to default staff name positions. (Reverses Finale bug that was fixed as of Finale 2014.5.)"
end

--Warning: this script does not work in Finale 26.2 and later due to the rewrite of document preferences
--in Finale 26.2. It will not work unless and until JW Lua is rebuilt with the Finale 26.2 PDK or later.
--However, this script exists to mitigate a Finale bug that was prevalent in Finale 2012 and fixed
--in Finale 2014.5 where using plugins on a linked part would randomly modify the default staff name positions.
--Therefore this script is probably of limited use in Finale 26.2 anyway.

--If this script is running in RGP Lua 0.58 or higher, it should work in any version of Finale 25+.

function copy_horizontal_settings_to_staff(group_prefs, staff_prefs)
    staff_prefs.HorizontalPos = group_prefs.HorizontalPos
    staff_prefs.Justification = group_prefs.Justification
    staff_prefs.Alignment = group_prefs.Alignment
    return staff_prefs:Save()
end

function prefs_copy_group_hpos_to_staff_hpos()
    local staff_full_name_position_prefs = finale.FCStaffNamePositionPrefs()
    staff_full_name_position_prefs:LoadFull()
    local group_full_name_position_prefs = finale.FCGroupNamePositionPrefs()
    group_full_name_position_prefs:LoadFull()
    copy_horizontal_settings_to_staff(group_full_name_position_prefs, staff_full_name_position_prefs)
    local staff_abbreviated_name_position_prefs = finale.FCStaffNamePositionPrefs()
    staff_abbreviated_name_position_prefs:LoadAbbreviated()
    local group_abbreviated_name_position_prefs = finale.FCGroupNamePositionPrefs()
    group_abbreviated_name_position_prefs:LoadAbbreviated()
    copy_horizontal_settings_to_staff(group_abbreviated_name_position_prefs, staff_abbreviated_name_position_prefs)
end

prefs_copy_group_hpos_to_staff_hpos()

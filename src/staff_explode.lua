function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.40"
    finaleplugin.Date = "2022/03/13"
    finaleplugin.Notes = [[
        This script explodes a set of chords from one staff onto single lines on subsequent staves. It warns if pre-existing music in the destination will be erased. It duplicates all markings from the original, and sets the copies in the current clef for each destination.

        This script allows for the following configuration:

        ```
        fix_note_spacing = true -- to respace music automatically when the script finishes
        ```
    ]]
    return "Staff Explode", "Staff Explode", "Staff Explode onto consecutive single staves"
end

local configuration = require("library.configuration")
local clef = require("library.clef")

local config = {fix_note_spacing = true}

configuration.get_parameters("staff_explode.config.txt", config)

function show_error(error_code)
    local errors = {
        need_more_staves = "There are not enough empty\nstaves to explode onto",
        only_one_staff = "Please select only one staff!",
        same_note_count = "Every chord must contain\nthe same number of pitches",
        empty_region = "Please select a region\nwith some notes in it!",
        require_chords = "Chords must contain\nat least two pitches",
    }
    finenv.UI():AlertNeutral("script: " .. plugindef(), errors[error_code])
    return -1
end

function should_overwrite_existing_music()
    local alert = finenv.UI():AlertOkCancel("script: " .. plugindef(), "Overwrite existing music?")
    local should_overwrite = alert == 0
    return should_overwrite
end

function get_note_count(source_staff_region)
    local note_count = 0
    local unique_counts = 0
    local seen_counts = {}
    for entry in eachentry(source_staff_region) do
        if entry.Count > 0 then
            if not seen_counts[entry.Count] then
                seen_counts[entry.Count] = true
                unique_counts = unique_counts + 1
            end
            if note_count < entry.Count then
                note_count = entry.Count
            end
        end
    end
    if unique_counts > 1 then
        return show_error("same_note_count")
    end
    if note_count == 0 then
        return show_error("empty_region")
    end
    if note_count < 2 then
        return show_error("require_chords")
    end
    return note_count
end

function ensure_score_has_enough_staves(staff, note_count)
    local staves = finale.FCStaves()
    staves:LoadAll()
    if note_count > staves.Count + 1 - staff then
        show_error("need_more_staves")
        return
    end
end

function staff_explode()
    local source_staff_region = finenv.Region()
    if source_staff_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    end
    local staff = source_staff_region.StartStaff
    local start_measure = source_staff_region.StartMeasure
    local end_measure = source_staff_region.EndMeasure
    local regions = {}
    regions[1] = source_staff_region

    local note_count = get_note_count(source_staff_region)
    if note_count <= 0 then
        return
    end

    ensure_score_has_enough_staves(staff, note_count)

    -- copy top staff to note_count lower staves (one-based index)
    local destination_has_content = false
    local staves = -1
    for i = 2, note_count do
        regions[i] = finale.FCMusicRegion()
        regions[i]:SetRegion(regions[1])
        regions[i]:CopyMusic()
        staves = staff + i - 1 -- "real" staff number, indexed[1]
        regions[i].StartStaff = staves
        regions[i].EndStaff = staves
        if not destination_has_content then
            for entry in eachentry(regions[i]) do
                if entry.Count > 0 then
                    destination_has_content = true
                    break
                end
            end
        end
    end

    if not destination_has_content or (destination_has_content and should_overwrite_existing_music()) then
        -- run through all staves deleting requisite notes in each entry
        for ss = 1, note_count do
            if ss > 1 then
                regions[ss]:PasteMusic()
                local real_staff_number = staff + ss - 1
                clef.restore_default_clef(start_measure, end_measure, real_staff_number)
            end

            local from_top = ss - 1 -- delete how many notes from top?
            local from_bottom = note_count - ss -- how many from bottom?
            -- run the ENTRIES loop for current selection on all staff copies
            for entry in eachentrysaved(regions[ss]) do
                if from_top > 0 then -- delete TOP notes
                    for _ = 1, from_top do
                        entry:DeleteNote(entry:CalcHighestNote(nil))
                    end
                end
                if from_bottom > 0 then -- delete BOTTOM notes
                    for i = 1, from_bottom do
                        entry:DeleteNote(entry:CalcLowestNote(nil))
                    end
                end
            end
        end

        if config.fix_note_spacing then
            regions[1].EndStaff = staff + note_count - 1 -- full staff range
            regions[1]:SetFullMeasureStack()
            regions[1]:SetInDocument()
            finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
            regions[1].StartStaff = staff
            regions[1].StartStaff = staff
            regions[1].EndStaff = staff
            regions[1]:SetInDocument()
        end
    end

    -- ALL DONE -- empty out the copied clip files
    for i = 2, note_count do
        regions[i]:ReleaseMusic()
    end
end

staff_explode()

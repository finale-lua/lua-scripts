function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.48"
    finaleplugin.Date = "2022/07/14"
    finaleplugin.Notes = [[
        This script explodes a set of chords from one staff into pairs of notes, top to bottom, on subsequent staves. 
        Chords may contain different numbers of notes, the number of destination staves determined by the chord with the largest number of notes.
        It duplicates all markings from the original, and resets the current clef for each destination staff.
        It warns if pre-existing music in the destination will be erased. 

        By default this script doesn't respace the selected music after it completes. 
        If you want automatic respacing, hold down the `shift` or `alt` (option) key when selecting the script's menu item. 

        Alternatively, if you want the default behaviour to include spacing then create a `configuration` file:  
        If it does not exist, create a subfolder called `script_settings` in the folder containing this script. 
        In that folder create a plain text file  called `staff_explode_pairs.config.txt` containing the line: 

        ```
        fix_note_spacing = true -- respace music when the script finishes
        ```
        If you subsequently hold down the `shift` or `alt` (option) key, spacing will not be included.
    ]]
    return "Staff Explode Pairs", "Staff Explode Pairs", "Explode chords from one staff into pairs of notes on consecutive single staves"
end

local configuration = require("library.configuration")
local clef = require("library.clef")
local config = { fix_note_spacing = false }
configuration.get_parameters("staff_explode_pairs.config.txt", config)

function show_error(error_code)
    local errors = {
        need_more_staves = "There are not enough empty\nstaves to explode onto",
        only_one_staff = "Please select only one staff!",
        empty_region = "Please select a region\nwith some notes in it!",
        three_or_more = "Explode Pairs needs\nthree or more notes per chord",
    }
    finenv.UI():AlertNeutral("script: " .. plugindef(), errors[error_code])
    return -1
end

function should_overwrite_existing_music()
    local alert = finenv.UI():AlertOkCancel("script: " .. plugindef(), "Overwrite existing music?")
    local should_overwrite = (alert == 0)
    return should_overwrite
end

function get_note_count(source_staff_region)
    local note_count = 0
    for entry in eachentry(source_staff_region) do
        if entry.Count > 0 then
            if note_count < entry.Count then
                note_count = entry.Count
            end
        end
    end
    if note_count == 0 then
        return show_error("empty_region")
    elseif note_count < 3 then
        return show_error("three_or_more")
    end
    return note_count
end

function ensure_score_has_enough_staves(slot, staff_count)
    local staves = finale.FCStaves()
    staves:LoadAll()
    if staff_count > staves.Count - slot + 1 then
        return false
    end
    return true
end

function staff_explode()
    if finenv.QueryInvokedModifierKeys and
    (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
        then
        config.fix_note_spacing = not config.fix_note_spacing
    end

    local source_staff_region = finale.FCMusicRegion()
    source_staff_region:SetCurrentSelection()
    if source_staff_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    end
    local start_slot = source_staff_region.StartSlot
    local start_measure = source_staff_region.StartMeasure
    local end_measure = source_staff_region.EndMeasure
    local regions = {}
    regions[1] = source_staff_region

    local max_note_count = get_note_count(source_staff_region)
    if max_note_count <= 0 then
        return
    end

    local staff_count = math.floor((max_note_count / 2) + 0.5) -- allow for odd number of notes
    if not ensure_score_has_enough_staves(start_slot, staff_count) then
        show_error("need_more_staves")
        return
    end

    -- copy top staff to (staff_count-1) lower staves (one-based index)
    local destination_is_empty = true
    for slot = 2, staff_count do
        regions[slot] = finale.FCMusicRegion()
        regions[slot]:SetRegion(regions[1])
        regions[slot]:CopyMusic()
        local this_slot = start_slot + slot - 1 -- "real" slot number, indexed[1]
        regions[slot].StartSlot = this_slot
        regions[slot].EndSlot = this_slot
        
        if destination_is_empty then
            for entry in eachentry(regions[slot]) do
                if entry.Count > 0 then
                    destination_is_empty = false
                    break
                end
            end
        end
    end

    if destination_is_empty or should_overwrite_existing_music() then
        -- run through all staves deleting requisite notes in each entry
        for slot = 1, staff_count do
            if slot > 1 then
                regions[slot]:PasteMusic()
                clef.restore_default_clef(start_measure, end_measure, regions[slot].StartStaff)
            end

            local from_top = (slot - 1) * 2 -- delete how many notes from the top of the chord?
            for entry in eachentrysaved(regions[slot]) do -- check each note in the entry
                if entry:IsNote() then
                    local from_bottom = entry.Count - (slot * 2) -- how many from the bottom?
                    if from_top > 0 then
                        for i = 1, from_top do
                            entry:DeleteNote(entry:CalcHighestNote(nil))
                        end
                    end
                    if from_bottom > 0 then
                        for i = 1, from_bottom do
                            entry:DeleteNote(entry:CalcLowestNote(nil))
                        end
                    end
                end
            end
        end

        if config.fix_note_spacing then
            regions[1]:SetFullMeasureStack()
            regions[1]:SetInDocument()
            finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
            regions[1].StartSlot = start_slot -- reset display to original values
            regions[1].EndSlot = start_slot
            regions[1]:SetInDocument()
        end
    end

    -- ALL DONE -- empty out the copied clip files
    for slot = 2, staff_count do
        regions[slot]:ReleaseMusic()
    end
    finenv:Region():SetInDocument()
end

staff_explode()

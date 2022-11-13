function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.47"
    finaleplugin.Date = "2022/11/13"
    finaleplugin.Notes = [[
        Chords on layer 1 in the selected region are split into independent layers on the same staff. 
        Multiple measures and staves can be selected at once. 
        More than four notes in a chord are deposited on layer 4. 
        As a special case, if a staff contains only single-note entries, they are duplicated to layer 2. 
        Markings on the original are not copied to other layers.
    ]]
    return "Staff Explode To Layers", "Staff Explode To Layers", "Explode chords on layer 1 into independent layers"
end

local layer = require("library.layer")

function get_note_count(region)
    local note_count = 0
    for entry in eachentry(region) do
        if entry.Count > note_count then
            note_count = entry.Count
        end
    end
    return note_count
end

function explode_one_slot(slot, max_layers)
    local region = finenv.Region()
    region.StartSlot = slot
    region.EndSlot = slot
    local max_note_count = get_note_count(region)
    if max_note_count == 0 then return end -- no notes in this slot

    local start_measure = region.StartMeasure
    local end_measure = region.EndMeasure
    local staff = region:CalcStaffNumber(slot)

    -- assume that user wants to double single layer 1 notes to layer 2
    local unison_doubling = (max_note_count == 1) and 1 or 0

    -- copy top staff to max_note_count layers
    local layers = {}
    layers[1] = finale.FCNoteEntryLayer(0, staff, start_measure, end_measure)
    layers[1]:Load()

    for i = 2, (max_note_count + unison_doubling) do  -- copy to the other layers
        if i > max_layers then break end -- observe maximum layers
        layer.copy(region, 1, i)
    end

    if unison_doubling == 1 then  -- special unison doubling, so don't delete layer 2
        return
    end

    -- run through all entries and split by layer
    for entry in eachentrysaved(region) do
        if entry:IsNote() then
            local this_layer = entry.LayerNumber
            local from_top = this_layer - 1   -- delete how many notes from top?
            local from_bottom = entry.Count - this_layer -- how many from bottom?

            if from_top > 0 then -- delete TOP notes
                for i = 1, from_top do
                    entry:DeleteNote(entry:CalcHighestNote(nil))
                end
            end
            if from_bottom > 0 and this_layer < max_layers then -- delete BOTTOM notes
                for i = 1, from_bottom do
                    entry:DeleteNote(entry:CalcLowestNote(nil))
                end
            end
        end
    end
end

function staff_layer_explode()
    local region = finenv.Region()
    local note_count = get_note_count(region)
    if note_count == 0 then -- nothing here ... go home
        finenv.UI():AlertNeutral("", "Please select a region\nwith some notes in it!")
        return
    end
    local max_layers = layer.max_layers()
    for slot = region.StartSlot, region.EndSlot do
        explode_one_slot(slot, max_layers)
    end
end

staff_layer_explode()

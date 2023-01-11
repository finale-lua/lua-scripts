function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.AuthorURL = "https://www.robertgpatterson.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.0"
    finaleplugin.Date = "2023/1/11"
    finaleplugin.Notes = [[
        Chords from the source layers in the selected region are split into another layer on the same staff based on a split point. 
        Multiple measures and staves can be selected at once. 
        Articulations on the original are optionally copied to the other layer.
    ]]
    return "Staff Split Layers", "Staff Split Layers", "Split chords from one layer 1 into two independent layers, based on a split point."
end

local note_entry = require("library.note_entry")
local layer = require("library.layer")

local split_from_top = 2
local source_layer = 1
local destination_layer = 2
local clone_artics = true

function explode_one_slot(slot)
    local region = finale.FCMusicRegion()
    region:SetCurrentSelection()
    region.StartSlot = slot
    region.EndSlot = slot
    region:SetStartMeasurePosLeft()
    region:SetEndMeasurePosRight()

    local start_measure = region.StartMeasure
    local end_measure = region.EndMeasure
    local staff = region:CalcStaffNumber(slot)

    layer.copy(region, source_layer, destination_layer, clone_artics)

    -- run through all entries and split by layer
    for entry in eachentrysaved(region) do
        if entry:IsNote() then
            local this_layer = entry.LayerNumber
            if this_layer == source_layer and entry.Count > split_from_top then
                for index = 0, entry.Count - split_from_top - 1 do
                    note_entry.delete_note(entry:GetItemAt(0))
                end
            end
            if this_layer == destination_layer then
                if entry.Count > split_from_top then
                    for index = 0, split_from_top - 1 do
                        note_entry.delete_note(entry:GetItemAt(entry.Count-1))
                    end
                else
                    note_entry.make_rest(entry)
                end
            end
        end
    end
end

function staff_split_layers()
    local region = finale.FCMusicRegion()
    if not region:SetCurrentSelection() then
        return -- no selection, which should be impossible due to plugindef() setting
    end
    for slot = region.StartSlot, region.EndSlot do
        explode_one_slot(slot)
    end
end

staff_split_layers()

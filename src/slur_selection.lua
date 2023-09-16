function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.56"
    finaleplugin.Date = "2023/09/16"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        A good trick in Sibelius is hitting the 'S' key to create a slur across currently selected notes. 
        Activate this script in Finale with a macro hotkey utility to do the same thing. 
        Each layer will be slurred independently, and if there are 
        several runs of notes separated by rests, each run will be slurred separately. 
        If you want to automate slurs on specific rhythmic patterns then try 
        JW Pattern (→ Performance Notation → Slurs) or TGTools (→ Music → Create Slurs...).
    ]]
    return "Slur Selection", "Slur Selection", "Create slurs across the current selection"
end

local smartshape = require("library.smartshape")
local layer = require("library.layer")

function delete_region_slurs(rgn)
    -- first beat-attached slurs
    for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), rgn) do
        local shape = mark:CreateSmartShape()
        if shape and shape:IsSlur() then shape:DeleteData() end
    end
    -- then note-attached slurs .. may not be needed in RGPLua 0.68+
    local shape_starts, shape_ends = {}, {}
    for entry in eachentry(rgn) do
        for mark in loadall(finale.FCSmartShapeEntryMarks(entry)) do
            local shape = mark:CreateSmartShape()
            if mark:CalcLeftMark() then
                shape_starts[shape.ItemNo] = true
            end
            if mark:CalcRightMark() then
                shape_ends[shape.ItemNo] = true
            end
        end
    end
    for itemno, _ in pairs(shape_starts) do
        if shape_ends[itemno] ~= nil then -- we have a fully specified shape
            local shape = finale.FCSmartShape()
            shape:Load(itemno)
            if shape:IsSlur() then shape:DeleteData() end
        end
    end
end

function make_slurs()
    local rgn = finenv.Region()
    delete_region_slurs(rgn)

    for staff_number in eachstaff(rgn) do
        for layer_number = 1, layer.max_layers() do
            local entry_layer = finale.FCNoteEntryLayer(layer_number - 1, staff_number, rgn.StartMeasure, rgn.EndMeasure)
            entry_layer:Load()
            local start_slur = false -- begin looking for first slurred passage

            for entry in each(entry_layer) do
                if rgn:IsEntryPosWithin(entry) then -- FCNoteEntryLayer() doesn't obey region boundaries
                    if not start_slur then
                        if entry:IsNote() then
                            start_slur = entry -- start of potential new phrase
                        end
                    elseif entry:IsRest() then -- started a slur but found no useful endpoint
                        start_slur = false -- so cancel and start again
                    -- but having started a slur, is this the END of a run of notes?
                    elseif not entry:Next() or entry:Next():IsRest() or not rgn:IsEntryPosWithin(entry:Next()) then
                        smartshape.add_entry_based_smartshape(start_slur, entry, "auto_slur")
                        start_slur = false -- start looking for a new phrase
                    end
                end
            end
        end
    end
end

make_slurs()

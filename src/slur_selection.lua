function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.53"
    finaleplugin.Date = "2022/11/14"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        A nice trick in Sibelius is hitting the 'S' key to create a slur joining the currently selected notes. 
        Activate this script in Finale with a macro hotkey utility to do the same thing. 
        Each layer will be slurred independently, and if there are 
        multiple runs of notes separated by rests, each run will be slurred independently. 
        If you want to automate slurs on specific note patterns then try 
        JW Pattern (Performance Notation -> Slurs) or TGTools (Music -> Create Slurs...").
    ]]
    return "Slur Selection", "Slur Selection", "Create slurs across the current selection"
end

local smartshape = require("library.smartshape")
local layer = require("library.layer")

function make_slurs()
    local region = finenv.Region()
    for staff_number = region.StartStaff, region.EndStaff do
        for layer_number = 1, layer.max_layers() do
            local entry_layer = finale.FCNoteEntryLayer(layer_number - 1, staff_number, region.StartMeasure, region.EndMeasure)
            entry_layer:Load()
            local start_slur = false

            for entry in each(entry_layer) do
                if region:IsEntryPosWithin(entry) then
                    if not start_slur then
                        if entry:IsNote() then
                            start_slur = entry
                        end
                    elseif entry:IsRest() then
                        start_slur = false -- not starting a new phrase here
                    elseif not entry:Next() or entry:Next():IsRest() or not region:IsEntryPosWithin(entry:Next()) then
                        smartshape.add_entry_based_smartshape(start_slur, entry, "auto_slur")
                        start_slur = false -- look for a new phrase
                    end
                end
            end
        end
    end
end

make_slurs()

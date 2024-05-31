function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.58"
    finaleplugin.Date = "2024/01/29"
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.Notes = [[
        A good trick in Sibelius is hitting the __S__ key to create a slur across currently selected notes. 
        Activate this script in _Finale_ with a macro hotkey utility to do the same thing. 
        Each layer will be slurred independently, and if there are 
        several runs of notes separated by rests, each run will be slurred separately. 
        If you want to automate slurs on specific rhythmic patterns then try 
        __JW Pattern__ (→ _Performance Notation_ → _Slurs_) or __TGTools__ (→ _Music_ → _Create Slurs..._).
    ]]
    return "Slur Selection", "Slur Selection", "Create slurs across the current selection"
end

local smartshape = require("library.smartshape")
local layer = require("library.layer")

function make_slurs()
    local rgn = finenv.Region()
    -- delete old slurs
    for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), rgn) do
        local shape = mark:CreateSmartShape()
        if shape and shape:IsSlur() then shape:DeleteData() end
    end

    for staff_number in eachstaff(rgn) do
        for layer_number = 1, layer.max_layers() do
            local entry_layer = finale.FCNoteEntryLayer(layer_number - 1, staff_number, rgn.StartMeasure, rgn.EndMeasure)
            entry_layer:Load()
            local started_slur = false -- begin looking for first slurred passage

            for entry in each(entry_layer) do
                if rgn:IsEntryPosWithin(entry) then -- FCNoteEntryLayer() doesn't obey region boundaries
                    local next = entry:Next() -- nil if end of selection
                    if not started_slur then
                        if entry:IsNote() then
                            started_slur = entry -- start of potential new phrase
                        end
                    elseif entry:IsRest() then -- started a slur but found no viable endpoint
                        started_slur = false -- so cancel and start again
                    -- but having started a slur, is this the END of a run of notes?
                    elseif not next or next:IsRest() or not rgn:IsEntryPosWithin(next) then
                        smartshape.add_entry_based_smartshape(started_slur, entry, "auto_slur")
                        started_slur = false -- start looking for a new phrase
                    end
                end
            end
        end
    end
end

make_slurs()

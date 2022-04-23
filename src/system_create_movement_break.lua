function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patteson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "April 23, 2022"
    finaleplugin.CategoryTags = "System"
    finaleplugin.AuthorURL = "https://robertgpatterson.com"
    finaleplugin.Notes = [[
        This script replaces the JW New Piece plugin, which no longer works on Macs running M1 code. It creates a movement
        break starting with the first selected measure.
    ]]
    return "Create Movement Break", "Create Movement Break", "Creates a movement break at the first selected measure."
end

local library = require("library.general_library")

function system_create_movement_break()
    local measure_number = finenv.Region().StartMeasure
    if measure_number > 1 then
        local measure = finale.FCMeasure()
        measure:Load(measure_number)
        measure.BreakMMRest = true
        measure.BreakWordExtension = true
        measure.ShowFullNames = true
        measure.SystemBreak = true
        measure.ShowKeySignature = finale.SHOWSTATE_SHOW
        measure.ShowTimeSignature = finale.SHOWSTATE_SHOW
        measure:Save()
        local prev_measure = finale.FCMeasure()
        prev_measure:Load(measure_number - 1)
        prev_measure.Barline = finale.BARLINE_FINAL
        prev_measure.HideCautionary = true
        prev_measure:Save()
        -- ToDo: split Measure Number region, if any
        library.update_layout()
    end

    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local system = systems:FindMeasureNumber(measure_number)
    library.system_indent_set_to_prefs(system)

    library.update_layout()
end

system_create_movement_break()


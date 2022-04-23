function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "April 23, 2022"
    finaleplugin.CategoryTags = "Measure"
    finaleplugin.AuthorURL = "https://robertgpatterson.com"
    finaleplugin.Notes = [[
        This script replaces the JW New Piece plugin, which is no longer available on Macs running M1 code.
        It creates a movement break starting with the first selected measure.
    ]]
    return "Create Movement Break", "Create Movement Break", "Creates a movement break at the first selected measure."
end

local library = require("library.general_library")

function measure_create_movement_break()
    local measure_number = finenv.Region().StartMeasure
    if measure_number > 1 then
        local measure = finale.FCMeasure()
        measure:Load(measure_number)
        measure.BreakWordExtension = true
        measure.ShowFullNames = true
        measure.SystemBreak = true
        if measure.ShowKeySignature ~= finale.SHOWSTATE_HIDE then
            measure.ShowKeySignature = finale.SHOWSTATE_SHOW
        end
        if measure.ShowTimeSignature ~= finale.SHOWSTATE_HIDE then
            measure.ShowTimeSignature = finale.SHOWSTATE_SHOW
        end
        measure:Save()
        local prev_measure = finale.FCMeasure()
        prev_measure:Load(measure_number - 1)
        prev_measure.BreakMMRest = true
        prev_measure.Barline = finale.BARLINE_FINAL
        prev_measure.HideCautionary = true
        prev_measure:Save()
        local meas_num_regions = finale.FCMeasureNumberRegions()
        meas_num_regions:LoadAll()
        for meas_num_region in each(meas_num_regions) do
            if meas_num_region:IsMeasureIncluded(measure_number) and meas_num_region:IsMeasureIncluded(measure_number - 1) then
                local curr_last_meas = meas_num_region.EndMeasure
                meas_num_region.EndMeasure = measure_number - 1
                meas_num_region:Save()
                meas_num_region.StartMeasure = measure_number
                meas_num_region.EndMeasure = curr_last_meas
                meas_num_region.StartNumber = 1
                meas_num_region:SaveNew()
            end
        end
    end

    local parts = finale.FCParts()
    parts:LoadAll()
    for part in each(parts) do
        part:SwitchTo()
        local multimeasure_rests = finale.FCMultiMeasureRests()
        multimeasure_rests:LoadAll()
        for multimeasure_rest in each(multimeasure_rests) do
            if multimeasure_rest:IsMeasureIncluded(measure_number) and multimeasure_rest:IsMeasureIncluded(measure_number - 1) then
                local curr_last_meas = multimeasure_rest.EndMeasure
                multimeasure_rest.EndMeasure = measure_number - 1
                multimeasure_rest:Save()
                multimeasure_rest.StartMeasure = measure_number
                multimeasure_rest.EndMeasure = curr_last_meas
                multimeasure_rest:Save()
            end
        end
        library.update_layout()
        local systems = finale.FCStaffSystems()
        systems:LoadAll()
        local system = systems:FindMeasureNumber(measure_number)
        library.system_indent_set_to_prefs(system)
        library.update_layout()
        part:SwitchBack()
    end
end

measure_create_movement_break()

function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1.0"
    finaleplugin.Date = "February 6, 2023"
    finaleplugin.CategoryTags = "Meter"
    finaleplugin.MinJWLuaVersion = 0.63
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.RequireSelection = true
    finaleplugin.Notes = [[
        Changes the meter in a selected range.
        
        If a single measure is selected,
        the meter will be set for all measures until the next
        meter change, or until the next measure with Time Signature
        set to "Always Show", or for the remaining measures in the score.
        You can override stopping at "Always Show" measures with a configuration
        file script_settings/meter_change.config.txt that contains the following
        line:

        ```
        stop_at_always_show = false
        ```

        You can limit the meter change to one bar by holding down Shift or Option
        keys when invoking the script. Then the meter is changed only
        for the single measure you selected.

        If multiple measures are selected, the meter will be set
        exactly for the selected measures. 
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Meter - 1/2
        Meter - 2/2
        Meter - 3/2
        Meter - 4/2
        Meter - 5/2
        Meter - 6/2
        Meter - 1/4
        Meter - 2/4
        Meter - 3/4
        Meter - 5/4
        Meter - 6/4
        Meter - 7/4
        Meter - 3/8
        Meter - 5/8 (2+3)
        Meter - 5/8 (3+2)
        Meter - 6/8
        Meter - 7/8 (2+2+3)
        Meter - 7/8 (3+2+2)
        Meter - 9/8
        Meter - 12/8
        Meter - 15/8
    ]]
    finaleplugin.AdditionalPrefixes = [[
        numerator = 1 denominator = 2
        numerator = 2 denominator = 2
        numerator = 3 denominator = 2
        numerator = 4 denominator = 2
        numerator = 5 denominator = 2
        numerator = 6 denominator = 2
        numerator = 1 denominator = 4
        numerator = 2 denominator = 4
        numerator = 3 denominator = 4
        numerator = 5 denominator = 4
        numerator = 6 denominator = 4
        numerator = 7 denominator = 4
        numerator = 3 denominator = 8
        numerator = 5 denominator = 8 composite = {2, 3}
        numerator = 5 denominator = 8 composite = {3, 2}
        numerator = 6 denominator = 8
        numerator = 7 denominator = 8 composite = {2, 2, 3}
        numerator = 7 denominator = 8 composite = {3, 2, 2}
        numerator = 9 denominator = 8
        numerator = 12 denominator = 8
        numerator = 15 denominator = 8
    ]]
    return "Meter - 4/4", "Meter - 4/4", "Sets the meter as indicated in a selected range."
end

local configuration = require("library.configuration")

config =
{
    stop_at_always_show = true
}
configuration.get_parameters("meter_change.config.txt", config)


numerator = numerator or 4
denominator = denominator or 4
composite = composite or nil
if denominator == 8 and not composite then
    numerator = numerator / 3
end
num_composite = 0
if composite then
    for k, v in pairs(composite) do
        num_composite = num_composite + 1
    end
end

local denominators = {}
denominators[2] = 2048
denominators[4] = 1024
denominators[8] = composite and 512 or 1536 -- for compound meters

local do_single_bar = finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)

local measures_processed = {}

function apply_new_time(measure_or_cell, beat_num, beat_duration)
    if measure_or_cell:ClassName() == "FCMeasure" then
        if measures_processed[measure_or_cell.ItemNo] then
            return
        end
        measures_processed[measure_or_cell.ItemNo] = true
    end
    local time_sig = measure_or_cell:GetTimeSignature()
    if composite then
        local top_list = finale.FCCompositeTimeSigTop()
        top_list:AddGroup(num_composite)
        for k, v in ipairs(composite) do
            top_list:SetGroupElementBeats(0, k-1, v)
        end
        time_sig:SaveNewCompositeTop(top_list)
        local abrv_time_sig = (function()
            if measure_or_cell.UseTimeSigForDisplay ~= nil then -- FCMeasure
                measure_or_cell.UseTimeSigForDisplay = true
                return measure_or_cell:GetTimeSignatureForDisplay()
            end
            return measure_or_cell:AssureSavedIndependentTimeSigForDisplay() -- FCCell
        end)()
        abrv_time_sig:RemoveCompositeTop(beat_num)
        abrv_time_sig:RemoveCompositeBottom(beat_duration)
    else
        if measure_or_cell.UseTimeSigForDisplay then -- FCMeasure
            local abrv_time_sig = measure_or_cell:GetTimeSignatureForDisplay()
            abrv_time_sig:RemoveCompositeTop(beat_num)
            abrv_time_sig:RemoveCompositeBottom(beat_duration)
            measure_or_cell.UseTimeSigForDisplay = false
        elseif measure_or_cell.RemoveIndependentTimeSigForDisplay then -- FCCell
            measure_or_cell:RemoveIndependentTimeSigForDisplay()
        end
        time_sig:RemoveCompositeTop(beat_num)
    end
    time_sig:RemoveCompositeBottom(beat_duration)
    measure_or_cell:Save()
end

function set_time(beat_num, beat_duration)
    local measures_selected = finale.FCMeasures()
    measures_selected:LoadRegion(finenv.Region())
    local all_measures = finale.FCMeasures()
    all_measures:LoadAll()
    for staff_num in eachstaff(finenv.Region()) do
        if measures_selected.Count > 1 or do_single_bar then
            for m in each(measures_selected) do
                local cell = finale.FCCell(m.ItemNo, staff_num)
                if cell:HasIndependentTimeSig() then
                    apply_new_time(cell, beat_num, beat_duration)
                else
                    apply_new_time(m, beat_num, beat_duration)
                end
            end
        else
            local selected_measure = measures_selected:GetItemAt(0)
            local is_measure_stack = true 
            local selected_time_signature, selected_item = (function()
                local selected_cell = finale.FCCell(selected_measure.ItemNo, staff_num)
                if selected_cell:HasIndependentTimeSig() then
                    is_measure_stack = false
                    return selected_cell:GetTimeSignature(), selected_cell
                end
                return selected_measure:GetTimeSignature(), selected_measure
            end)()
            -- Do the selected measure last in case it is a composite time sig.
            -- We have to preserve the composite time sig record for it so that comparisons with selected_time_signature work.
            for m in each(all_measures) do
                if (m.ItemNo > selected_measure.ItemNo) then
                    if config.stop_at_always_show and m.ShowTimeSignature == finale.SHOWSTATE_SHOW then
                        break
                    end
                    local this_item = m
                    if not is_measure_stack then
                        local cell = finale.FCCell(m.ItemNo, staff_num)
                        if not cell:HasIndependentTimeSig() then
                            break
                        end
                        this_item = cell
                    end
                    if not selected_time_signature:IsIdentical(this_item:GetTimeSignature()) then
                        break
                    end
                    apply_new_time(this_item, beat_num, beat_duration)
                end
            end
            apply_new_time(selected_item, beat_num, beat_duration)
        end
    end
    for measure_number, _ in pairs(measures_processed) do
        local measure = finale.FCMeasure()
        measure:Load(measure_number)
        local beat_chart = measure:CreateBeatChartElements()
        if beat_chart.Count > 0 then
            if beat_chart:GetItemAt(0).MeasurePos ~= measure:GetDuration() then -- FCBeatChartElement.MeasurePos for element 0 is the total duration of the beat chart 
                beat_chart:DeleteDataForItem(measure_number)
                if measure.PositioningNotesMode == finale.POSITIONING_BEATCHART then
                    measure.PositioningNotesMode = finale.POSITIONING_TIMESIG
                    measure:Save()
                end
            end
        end
    end
end

set_time(numerator, denominators[denominator])

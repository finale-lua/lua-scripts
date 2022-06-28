function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "June 4, 2022"
    finaleplugin.CategoryTags = "Meter"
    finaleplugin.MinJWLuaVersion = 0.62
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

function apply_new_time(measure, beat_num, beat_duration)
    local time_sig = measure:GetTimeSignature()
    if composite then
        local top_list = finale.FCCompositeTimeSigTop()
        top_list:AddGroup(num_composite)
        for k, v in ipairs(composite) do
            top_list:SetGroupElementBeats(0, k-1, v)
        end
        time_sig:SaveNewCompositeTop(top_list)
        measure.UseTimeSigForDisplay = true
        local abrv_time_sig = measure:GetTimeSignatureForDisplay()
        abrv_time_sig:RemoveCompositeTop(beat_num)
        abrv_time_sig:RemoveCompositeBottom(beat_duration)
    else
        if measure.UseTimeSigForDisplay then
            local abrv_time_sig = measure:GetTimeSignatureForDisplay()
            abrv_time_sig:RemoveCompositeTop(beat_num)
            abrv_time_sig:RemoveCompositeBottom(beat_duration)
            measure.UseTimeSigForDisplay = false
        end
        time_sig:RemoveCompositeTop(beat_num)
    end
    time_sig:RemoveCompositeBottom(beat_duration)
end

function set_time(beat_num, beat_duration)
    local measures = finale.FCMeasures()
    measures:LoadRegion(finenv.Region())
    if measures.Count > 1 or do_single_bar then
        for m in each(measures) do
            apply_new_time(m, beat_num, beat_duration)
            m:Save()
        end
    else
        local selected_measure = measures:GetItemAt(0)
        local selected_time_signature = selected_measure:GetTimeSignature()
        -- Do the selected measure last in case it is a composite time sig.
        -- We have to preserve the composite time sig record for it so that comparisons with selected_time_signature work.
        for m in loadall(finale.FCMeasures()) do
            if (m.ItemNo > selected_measure.ItemNo) then
                if config.stop_at_always_show and m.ShowTimeSignature == finale.SHOWSTATE_SHOW then
                    break
                end
                if not selected_time_signature:IsIdentical(m:GetTimeSignature()) then
                    break
                end
                apply_new_time(m, beat_num, beat_duration)
                m:Save()
            end
        end
        apply_new_time(selected_measure, beat_num, beat_duration)
        selected_measure:Save()
    end
end

set_time(numerator, denominators[denominator])

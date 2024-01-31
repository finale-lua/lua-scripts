function plugindef()
    finaleplugin.Author = "Michael McClennan & Jacob Winkler"
    finaleplugin.Version = 2.0
    finaleplugin.Copyright = "2023/12/05"
    finaleplugin.RequireSelection = true
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/region_replicate_music.hash"
return "Replicate Music", "Replicate Music", "Inspired by the 'r' key in Sibelius, this script copies the selected music, and pastes it directly to the right"
end
local function replicate_music()
    local region = finenv.Region()
    local start_measure = finenv.Region().StartMeasure
    local start_measure_pos = finenv.Region().StartMeasurePos
    local end_measure = finenv.Region().EndMeasure
    local end_measure_pos = finenv.Region().EndMeasurePos
    local sum_measures = end_measure - start_measure
    local start_paste_region_measure
    local start_paste_region_measure_pos = 0
    local partial_measure_duration = 0
    if sum_measures == 0 then
        partial_measure_duration = end_measure_pos - start_measure_pos
    end

    if finenv.Region():IsAbsoluteEndMeasurePos() then
        start_paste_region_measure = end_measure + 1
    else
        start_paste_region_measure = end_measure
        start_paste_region_measure_pos = end_measure_pos + 1
    end

    region:CopyMusic()
    finenv.Region():SetStartMeasure(start_paste_region_measure)
    finenv.Region():SetStartMeasurePos(start_paste_region_measure_pos)
    finenv.Region():SetEndMeasure(start_paste_region_measure + sum_measures)
    if sum_measures == 0 then
        if finenv.Region():IsAbsoluteEndMeasurePos() then
            finenv.Region():SetEndMeasurePos(partial_measure_duration)
        else
            finenv.Region():SetEndMeasurePos(start_paste_region_measure_pos + partial_measure_duration)
        end
    end
    region:PasteMusic()
    region:ReleaseMusic()
end
replicate_music()
function plugindef()
    finaleplugin.Author = "Michael McClennan"
    finaleplugin.Version = 1.0
    finaleplugin.Copyright = "2022/01/03"
    finaleplugin.HandlesUndo = true
end

local function replicate_music()
    local region = finenv.Region()
    local start_measure = finenv.Region().StartMeasure
    local end_measure = finenv.Region().EndMeasure
    local sum_measures = end_measure - start_measure
    local start_paste_region = end_measure + 1
    finenv.StartNewUndoBlock("Replicate Music", true) 
    region:CopyMusic()
    finenv.Region():SetStartMeasure(start_paste_region) 
    finenv.Region():SetEndMeasure(start_paste_region + sum_measures) 
    region:PasteMusic()
    region:ReleaseMusic()
    finenv.EndUndoBlock(true)
end

replicate_music()
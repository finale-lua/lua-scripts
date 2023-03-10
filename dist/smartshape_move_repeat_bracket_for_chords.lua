function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Michael McClennan"
    finaleplugin.Copyright = "©2021 Michael McClennan"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "May 22, 2021"
    finaleplugin.AuthorEmail = "info@michaelmcclennan.com"
    return "Move Repeat Brackets for Chords", "Move Repeat Brackets for Chords", ""
end
local region = finenv.Region()
for measure = region.StartMeasure, region.EndMeasure do
    local baseline = finale.FCBaseline()
    baseline:LoadDefaultForMode(3)
    local bracket_position = baseline.VerticalOffset - 145
    local offset = 72
    local repeat_ending = finale.FCEndingRepeat()
    if repeat_ending:Load(measure) then
        repeat_ending.VerticalTopBracketPosition = bracket_position + offset
        repeat_ending.VerticalRightBracketPosition = bracket_position + offset
        repeat_ending.VerticalTextPosition = bracket_position + offset + 25
        repeat_ending:Save()
    end
    for measure = region.StartMeasure, region.EndMeasure do
        local backwards_repeat = finale.FCBackwardRepeat()
        if backwards_repeat:Load(measure) then
            backwards_repeat.TopBracketPosition = bracket_position + offset
            backwards_repeat:Save()
        end
    end
end

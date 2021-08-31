function plugindef()
   -- This function and the 'finaleplugin' namespace
   -- are both reserved for the plug-in definition.
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
    local bracketpos = baseline.VerticalOffset - 145
    local userVar = 72 -- sets how far above the chord baseline the brackets should go (in EVPUs)

    local r = finale.FCEndingRepeat()
        if r:Load(measure) then
        r.VerticalTopBracketPosition = bracketpos + userVar -- adjusts bracket height
        r.VerticalRightBracketPosition = bracketpos + userVar -- adjusts bracket height
       r.VerticalTextPosition = bracketpos + userVar +25 --**height of repeat text
       r:Save()
    end

        for measure = region.StartMeasure, region.EndMeasure do
        local b = finale.FCBackwardRepeat()
            if b:Load(measure) then
            b.TopBracketPosition = bracketpos + userVar --adjusts backwards repeat bracket height
            b:Save()
        end
    end
end
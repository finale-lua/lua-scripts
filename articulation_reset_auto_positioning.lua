function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "February 28, 2020"
    finaleplugin.CategoryTags = "Articulation"
    return "Reset Automatic Articulation Positions", "Reset Automatic Articulation Positions", "Resets the position of automatically positioned articulations while ignoring those with manual positioning."
end

-- Before Finale 26, the automatic positioning of articulations was calculated by Finale and stored as the default offset
-- values of the assignment. Starting with Finale 26, the automatic positioning of articulations is inherent in the
-- coded behavior of Finale. The assignment only contains offsets from the default position. Therefore, resetting
-- articulations positions in earlier versions would require reverse-engineering all the automatic positioning
-- options. But resetting articulations to default in Finale 26 and higher is a simple matter of zeroing out
-- the horizontal and/or vertical offsets.

local finale_26_base_version = 0x1A000000

if finenv.RawFinaleVersion < finale_26_base_version then
    finenv.UI():AlertError("This script is not compatible with versions of Finale before Finale 26.", "Finale Version Error")
    return
end

function articulation_reset_auto_positioning()
    for note_entry in eachentry(finenv.Region()) do
        local articulations = note_entry:CreateArticulations()
        for articulation in each(articulations) do
            local articulation_def = finale.FCArticulationDef()
            if articulation_def:Load(articulation.ID) then
                local do_save = false
                if articulation_def.CenterHorizontally then
                    articulation.HorizontalPos = 0
                    do_save = true
                end
                if finale.ARTPOS_MANUAL_POSITIONING ~= articulation_def.AutoPosSide then
                    articulation.VerticalPos = 0
                    do_save = true
                end
                if do_save then
                    articulation:Save()
                end
            end
        end
    end
end

articulation_reset_auto_positioning()

function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "July 29, 2024"
    finaleplugin.CategoryTags = "Articulation"
    finaleplugin.MinFinaleVersionRaw = 0x1a000000
    finaleplugin.MinJWLuaVersion = 0.58
    finaleplugin.RequireSelection = true
    finaleplugin.Notes = [[
This script resets all selected articulations to their default positions but only if they are not manually positioned.
Due to complications arising from how Finale stored articulation positions before Finale 26, it requires Finale 26 or higher.
Due to issues around maintaining the context for automatic stacking, it must be run under RGP Lua. JW Lua does not have the necessary
logic to manage the stacking context.
    ]]
    return "Reset Automatic Articulation Positions", "Reset Automatic Articulation Positions",
        "Resets the position of automatically positioned articulations while ignoring those with manual positioning."
end

local articulation = require("library.articulation")

-- Before Finale 26, the automatic positioning of articulations was calculated by Finale and stored as the default offset
-- values of the assignment. Starting with Finale 26, the automatic positioning of articulations is inherent in the
-- coded behavior of Finale. The assignment only contains offsets from the default position. Therefore, resetting
-- articulations positions in earlier versions would require reverse-engineering all the automatic positioning
-- options. But resetting articulations to default in Finale 26 and higher is a simple matter of zeroing out
-- the horizontal and/or vertical offsets.

function articulation_reset_auto_positioning()
    for note_entry in eachentry(finenv.Region()) do
        local articulations = note_entry:CreateArticulations()
        for artic_assign in each(articulations) do
            local articulation_def = finale.FCArticulationDef()
            if articulation_def:Load(artic_assign.ID) then
                local do_save = false
                if articulation_def.CenterHorizontally then
                    artic_assign.HorizontalPos = 0
                    do_save = true
                end
                if finale.ARTPOS_MANUAL_POSITIONING ~= articulation_def.AutoPosSide then
                    local save_horzpos = artic_assign.HorizontalPos
                    local save_flip = artic_assign.PlacementMode
                    articulation.reset_to_default(artic_assign, articulation_def) -- use reset_to_default to fix up Finale's internal stacking flags
                    artic_assign.HorizontalPos = save_horzpos
                    artic_assign.PlacementMode = save_flip
                    do_save = true
                end
                if do_save then
                    artic_assign:Save()
                end
            end
        end
    end
end

articulation_reset_auto_positioning()

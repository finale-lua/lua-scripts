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
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script resets all selected articulations to their default positions but only if they are not manually positioned. Due to complications arising from how Finale stored articulation positions before Finale 26, it requires Finale 26 or higher. Due to issues around maintaining the context for automatic stacking, it must be run under RGP Lua. JW Lua does not have the necessary logic to manage the stacking context.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/articulation_reset_auto_positioning.hash"
    return "Reset Automatic Articulation Positions", "Reset Automatic Articulation Positions",
        "Resets the position of automatically positioned articulations while ignoring those with manual positioning."
end
local articulation = require("library/articulation")
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
                    articulation.reset_to_default(artic_assign, articulation_def)
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

function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "February 28, 2020"
    finaleplugin.CategoryTags = "Articulation"
    finaleplugin.MinFinaleVersionRaw = 0x1a000000
    finaleplugin.MinJWLuaVersion = 0.58
    finaleplugin.RequireSelection = true
    finaleplugin.Notes = [[
This script resets all selected articulations to their default positions. Due to complications arising from
how Finale stored articulation positions before Finale 26, it requires Finale 26 or higher. Due to issues around
maintaining the context for automatic stacking, it must be run under RGP Lua. JW Lua does not have the necessary
logic to manage the stacking context.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \ql \f0 \sa180 \li0 \fi0 This script resets all selected articulations to their default positions. Due to complications arising from how Finale stored articulation positions before Finale 26, it requires Finale 26 or higher. Due to issues around maintaining the context for automatic stacking, it must be run under RGP Lua. JW Lua does not have the necessary logic to manage the stacking context.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/articulation_reset_positioning.hash"
    return "Reset Articulation Positions", "Reset Articulation Positions", "Resets the position of all selected articulations."
end
function articulation_reset_positioning()
    for note_entry in eachentry(finenv.Region()) do
        local articulations = note_entry:CreateArticulations()
        for articulation in each(articulations) do
            local artic_def = articulation:CreateArticulationDef()
            articulation:ResetPos(artic_def)
            articulation:Save()
        end
    end
end
articulation_reset_positioning()

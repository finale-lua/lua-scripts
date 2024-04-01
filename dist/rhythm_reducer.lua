function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.12"
    finaleplugin.Date = "2024/03/10"
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.Notes = [[
        This script adjusts the rhythm of the selection to conform 
        to conventional notation rules and Finale's inbuilt quantization rules. 
        This may not always be exactly what you want but is 
        a great expedient for eliminating multiple (unwanted) rests 
        and as a quick check on the suitability of your rhyhthmic choices.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script adjusts the rhythm of the selection to conform to conventional notation rules and Finale\u8217's inbuilt quantization rules. This may not always be exactly what you want but is a great expedient for eliminating multiple (unwanted) rests and as a quick check on the suitability of your rhyhthmic choices.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/rhythm_reducer.hash"
    return "Rhythm Reducer", "Rhythm Reducer",
        "Adjust the rhythm of the selection to conform to conventional notation rules"
end
local function reduce_rhythms()
    for m, s in eachcell(finenv.Region()) do
        local c = finale.FCNoteEntryCell(m, s)
        c:Load()
        c:ReduceEntries()
        c:Save()
    end
end
reduce_rhythms()

function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 26, 2022"
    finaleplugin.CategoryTags = "Rest"
    finaleplugin.MinJWLuaVersion = 0.59
    finaleplugin.Notes = [[
        This script removes all default whole rests from the entire score.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script removes all default whole rests from the entire score.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/rest_remove_default_whole_rests.hash"
    return "Remove default whole rests", "Remove default whole rests",
           "Removes all default whole rests from the entire score"
end
function rest_remove_default_whole_rests()
    for staff in loadall(finale.FCStaves()) do
        staff:SetDisplayEmptyRests()
        staff:Save()
    end
end
rest_remove_default_whole_rests()

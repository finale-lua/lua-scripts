function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "2022-08-30"
    finaleplugin.RequireSelection = true
--    finale.MinJWLuaVersion = 0.63 -- https://robertgpatterson.com/-fininfo/-rgplua/rgplua.html
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.AdditionalMenuOptions = [[
    Clef 2: Bass
    Clef 3: Alto
    Clef 4: Tenor
    Clef 5: Tenor (Voice)
    Clef 6: Percussion
    ]]
    finaleplugin.AdditionalUndoText = [[
    Clef 2: Bass
    Clef 3: Alto
    Clef 4: Tenor
    Clef 5: Tenor (Voice)
    Clef 6: Percussion
    ]]
    finaleplugin.AdditionalDescriptions = [[
    Changes the selected region to bass clef
    Changes the selected region to alto clef
    Changes the selected region to tenor clef
    Changes the selected region to tenor voice (treble 8ba) clef
    Changes the selected region to percussion clef
    ]]
    finaleplugin.AdditionalPrefixes = [[
    clef_type = "bass"
    clef_type = "alto"
    clef_type = "tenor"
    clef_type = "tenor_voice"
    clef_type = "percussion"
    ]]
    return "Clef 1: Treble", "Clef 1: Treble", "Changes the selected region to treble clef"
end

clef_type = clef_type or "treble"

local clef = require("library.clef")

local region = finenv.Region()
region:SetCurrentSelection()
clef.clef_change(clef_type, region)
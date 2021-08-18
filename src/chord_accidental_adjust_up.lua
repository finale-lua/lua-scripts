function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Michael McClennan"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "August 14, 2021"
    finaleplugin.AuthorURL = "www.michaelmcclennan.com"
    finaleplugin.AuthorEmail = "info@michaelmcclennan.com"
    finaleplugin.CategoryTags = "Chord"
    return "Chord Accidental - Move Up", "Adjust Chord Accidental Up", "Adjust the accidental of chord symbol up"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"

local configuration = require("library.configuration")
local config = {vertical_increment = 5}

configuration.get_parameters("chord_accidental_adjust.config.txt", config)

function chord_accidental_adjust_up()
    local chordprefs = finale.FCChordPrefs()
    chordprefs:Load(1)
    local my_distance_result_flat = chordprefs:GetFlatBaselineAdjustment()
    local my_distance_result_sharp = chordprefs:GetSharpBaselineAdjustment()
    local my_distance_result_natural = chordprefs:GetNaturalBaselineAdjustment()
    local chordprefs = finale.FCChordPrefs()
    chordprefs:Load(1)
    chordprefs:GetFlatBaselineAdjustment()
    chordprefs.FlatBaselineAdjustment = config.vertical_increment + my_distance_result_flat
    chordprefs:GetSharpBaselineAdjustment()
    chordprefs.SharpBaselineAdjustment = config.vertical_increment + my_distance_result_sharp
    chordprefs:GetNaturalBaselineAdjustment()
    chordprefs.NaturalBaselineAdjustment = config.vertical_increment + my_distance_result_natural
    chordprefs:Save()
end

chord_accidental_adjust_up()

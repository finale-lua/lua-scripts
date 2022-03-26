function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "September 2, 2021"
    finaleplugin.CategoryTags = "Staff"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Create Trombone Choir Ensemble", "Create Trombone Choir Ensemble",
           "Creates the score setup correctly for trombone choir"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local score = require("library.score")
local configuration = require("library.configuration")

local config = {use_large_time_signatures = false, use_large_measure_numbers = false}

configuration.get_parameters("score_create_trombone_choir_score.config.txt", config)

local function score_create_trombone_choir_score()
    score.delete_all_staves()
    local trombone_staves = {}
    for i = 1, 6, 1 do
        trombone_staves[i] = score.set_show_staff_time_signature(
                                 score.create_staff(
                                     "Trombone " .. i, "Tbn. " .. i, finale.FFUUID_TROMBONE,
                                     (i < 3) and "tenor" or "bass"),
                                 (not config.use_large_time_signatures) or i == 1 or i == 5)
    end

    local bass_trombone_staves = {}
    for i = 1, 2, 1 do
        bass_trombone_staves[i] = score.set_show_staff_time_signature(
                                      score.create_staff(
                                          "Bass Trombone " .. i, "B. Tbn. " .. i, finale.FFUUID_BASSTROMBONE, "bass"),
                                      not config.use_large_time_signatures)
    end

    score.create_group_primary(trombone_staves[1], bass_trombone_staves[#bass_trombone_staves])
    score.create_group_secondary(trombone_staves[1], trombone_staves[#trombone_staves])
    score.create_group_secondary(bass_trombone_staves[1], bass_trombone_staves[#bass_trombone_staves])

    score.set_global_system_scaling(63)
    score.set_single_system_scaling(0, 56)
    score.set_single_system_scaling(1, 56)

    if config.use_large_time_signatures then
        score.use_large_time_signatures()
    end
    if config.use_large_measure_numbers then
        score.use_large_measure_numbers("14s")
    end
    score.set_minimum_measure_width("25s")
end

score_create_trombone_choir_score()

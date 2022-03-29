function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1.0"
    finaleplugin.Date = "September 2, 2021"
    finaleplugin.CategoryTags = "Score"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        This script sets up a score for trombone octet - 6 tenors, 2 basses.

        To use it, first open your default document or document styles. Then, run the script.
        All existing staffs will be deleted. And in their place, the trombone octet will be created.

        This script uses the standard ensemble creation configuration options.
    ]]
    return "Create trombone choir score", "Create trombone choir score",
           "Creates the score setup correctly for trombone choir"
end

local score = require("library.score")
local configuration = require("library.configuration")

local config = score.create_default_config()
config.systems_per_page = 2
config.large_measure_number_space = "24s"
configuration.get_parameters("score_create_trombone_choir_score.config.txt", config)

local function score_create_trombone_choir_score()
    score.reset_and_clear_score()

    local staves = {}
    staves.trombone_1 = score.create_staff("Trombone 1", "Tbn. 1", finale.FFUUID_TROMBONE, "tenor")
    staves.trombone_2 = score.create_staff("Trombone 2", "Tbn. 2", finale.FFUUID_TROMBONE, "tenor")
    staves.trombone_3 = score.create_staff("Trombone 3", "Tbn. 3", finale.FFUUID_TROMBONE, "tenor")
    staves.trombone_4 = score.create_staff("Trombone 4", "Tbn. 4", finale.FFUUID_TROMBONE, "bass")
    staves.trombone_5 = score.create_staff("Trombone 5", "Tbn. 5", finale.FFUUID_TROMBONE, "bass")
    staves.trombone_6 = score.create_staff("Trombone 6", "Tbn. 6", finale.FFUUID_TROMBONE, "bass")
    staves.bass_trombone_1 = score.create_staff("Bass Trombone 1", "B. Tbn. 1", finale.FFUUID_BASSTROMBONE, "bass")
    staves.bass_trombone_2 = score.create_staff("Bass Trombone 2", "B. Tbn. 2", finale.FFUUID_BASSTROMBONE, "bass")

    score.create_group_primary(staves.trombone_1, staves.bass_trombone_2)
    score.create_group_secondary(staves.trombone_1, staves.trombone_6)
    score.create_group_secondary(staves.bass_trombone_1, staves.bass_trombone_2)

    score.apply_config(config, {force_staves_show_time_signatures = {staves.trombone_1, staves.trombone_5}})
end

score_create_trombone_choir_score()

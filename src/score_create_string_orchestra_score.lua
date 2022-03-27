function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "March 26, 2022"
    finaleplugin.CategoryTags = "Score"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        This script sets up a score for string orchestra:

        - Violin 1
        - Violin 2
        - Viola
        - Cello
        - Bass

        To use it, first open your default document or document styles. Then, run the script.
        All existing staffs will be deleted. And in their place, the string orchestra will be created.

        This script uses the standard ensemble creation configuration options.
    ]]
    return "Create string orchestra score", "Create string orchestra score",
           "Creates the score setup correctly for string orchestra"
end

local score = require("library.score")
local configuration = require("library.configuration")

local config = score.create_default_config()
config.systems_per_page = 2
config.large_measure_number_space = "12s"
configuration.get_parameters("score_create_string_orchestra_score.config.txt", config)

local function score_create_string_orchestra_score()
    score.reset_and_clear_score()

    local staves = {}
    staves.violin_1 = score.create_staff("Violin I", "Vln. I", finale.FFUUID_VIOLINSECTION, "treble")
    staves.violin_2 = score.create_staff("Violin II", "Vln. II", finale.FFUUID_VIOLINSECTION, "treble")
    staves.viola = score.create_staff("Viola", "Vla.", finale.FFUUID_VIOLASECTION, "alto")
    staves.cello = score.create_staff("Cello", "Vc.", finale.FFUUID_CELLOSECTION, "bass")
    staves.bass = score.create_staff("Double Bass", "D.B.", finale.FFUUID_DOUBLEBASSSECTION, "bass")

    score.set_staff_transposition(staves.bass, "C", 7)

    score.create_group_primary(staves.violin_1, staves.bass)
    score.create_group_secondary(staves.violin_1, staves.violin_2)

    score.apply_config(config, {force_staves_show_time_signatures = {staves.violin_2}})
end

score_create_string_orchestra_score()

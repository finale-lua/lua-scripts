function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "July 12, 2022"
    finaleplugin.CategoryTags = "Score"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        This script sets up a score for brass quintet:

        - Trumpet in C 1
        - Trumpet in C 2
        - Horn in F
        - Trombone
        - Tuba

        To use it, first open your default document or document styles. Then, run the script.
        All existing staffs will be deleted. And in their place, the brass quintet will be created.

        This script uses the standard ensemble creation configuration options.
    ]]
    return "Create brass quintet score", "Create brass quintet score", "Creates the score setup correctly for brass quintet"
end

local score = require("library.score")
local configuration = require("library.configuration")

local config = score.create_default_config()
config.systems_per_page = 2
config.large_measure_number_space = "12s"
configuration.get_parameters("score_create_brass_quintet_score.config.txt", config)

local function score_create_brass_quintet_score()
    score.reset_and_clear_score()

    local staves = {}

    staves.trumpet_1 = score.create_staff("Trumpet in C 1", "Tpt. 1", finale.FFUUID_TRUMPETC, "treble")
    staves.trumpet_2 = score.create_staff("Trumpet in C 2", "Tpt. 2", finale.FFUUID_TRUMPETC, "treble")
    -- Yes, I know, alto clef for horns. Trust me, though, it's better
    -- to read horns in alto clef when viewing the score in concert pitch.
    -- Alto clef fits the horns' concert pitch range perfectly.
    staves.horn = score.create_staff("Horn in F", "Hn.", finale.FFUUID_HORNF, "alto")
    staves.trombone = score.create_staff("Trombone", "Tbn.", finale.FFUUID_TROMBONE, "bass")
    staves.tuba = score.create_staff("Tuba", "Tba.", finale.FFUUID_TUBA, "bass")

    score.create_group_primary(staves.trumpet_1, staves.tuba)
    score.create_group_secondary(staves.trumpet_1, staves.trumpet_2)

    score.set_staff_transposition(staves.horn, "F", 4, "treble")

    score.apply_config(config, {force_staves_show_time_signatures = {staves.trumpet_2}})
end

score_create_brass_quintet_score()

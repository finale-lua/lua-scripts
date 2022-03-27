function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1.0"
    finaleplugin.Date = "March 26, 2022"
    finaleplugin.CategoryTags = "Score"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        This script sets up a score for double wind orchestra:

        - Flute 1, 2
        - Oboe 1, 2
        - Clarinet 1, 2
        - Bassoon 1, 2
        - Horn in F 1, 2, 3, 4
        - Trumpet 1, 2, 3
        - Trombone 1, 2, bass
        - Tuba
        - Timpani
        - Percussion 1, 2, 3
        - Violin 1
        - Violin 2
        - Viola
        - Cello
        - Double bass

        To use it, first open your default document or document styles. Then, run the script.
        All existing staffs will be deleted. And in their place, the orchestra will be created.

        This script uses the standard ensemble creation configuration options.
    ]]
    return "Create double wind orchestra score", "Create double wind orchestra score",
           "Creates the score setup correctly for double wind orchestra"
end

local score = require("library.score")
local configuration = require("library.configuration")

local config = score.create_default_config()
config.large_measure_number_space = "13s"
config.score_page_width = "11i"
config.score_page_height = "17i"
configuration.get_parameters("score_create_trombone_choir_score.config.txt", config)

local function score_create_trombone_choir_score()
    score.reset_and_clear_score()

    local staves = {}

    staves.flutes_1_2 = score.create_staff("Flute", "Fl.", finale.FFUUID_FLUTE, "treble", 1)
    staves.oboes_1_2 = score.create_staff("Oboe", "Ob.", finale.FFUUID_OBOE, "treble", 1)
    staves.clarinets_1_2 = score.create_staff("Clarinet", "Cl.", finale.FFUUID_CLARINETBFLAT, "treble", 1)
    staves.bassoons_1_2 = score.create_staff("Bassoon", "Bsn.", finale.FFUUID_BASSOON, "treble", 1)

    -- Staff names are added via secondary bracket groups.
    -- Yes, I know, alto clef for horns. Trust me, though, it's better
    -- to read horns in alto clef when viewing the score in concert pitch.
    -- Alto clef fits the horns' concert pitch range perfectly.
    staves.horns_1_2 = score.create_staff("", "", finale.FFUUID_HORNF, "alto", 1)
    staves.horns_3_4 = score.create_staff("", "", finale.FFUUID_HORNF, "alto", 3)
    staves.trumpets_1_2 = score.create_staff("", "", finale.FFUUID_TRUMPETC, "treble", 1)
    staves.trumpets_3_4 = score.create_staff("3", "3", finale.FFUUID_TRUMPETC, "treble")
    staves.trombones_1_2 = score.create_staff("", "", finale.FFUUID_TROMBONE, "bass", 1)
    staves.trombone_bass = score.create_staff("Bass", "B.", finale.FFUUID_BASSTROMBONE, "bass")
    staves.tuba = score.create_staff("Tuba", "Tba.", finale.FFUUID_TUBA, "bass")

    staves.timpani = score.create_staff("Timpani", "Tmp.", finale.FFUUID_TIMPANI, "bass")
    staves.percussion_1 = score.create_staff_percussion("Percussion 1", "Prc. 1")
    staves.percussion_2 = score.create_staff_percussion("Percussion 2", "Prc. 2")
    staves.percussion_3 = score.create_staff_percussion("Percussion 3", "Prc. 3")

    staves.violin_1 = score.create_staff("Violin I", "Vln. I", finale.FFUUID_VIOLINSECTION, "treble")
    staves.violin_2 = score.create_staff("Violin II", "Vln. II", finale.FFUUID_VIOLINSECTION, "treble")
    staves.viola = score.create_staff("Viola", "Vla.", finale.FFUUID_VIOLASECTION, "alto")
    staves.cello = score.create_staff("Cello", "Vc.", finale.FFUUID_CELLOSECTION, "bass")
    staves.double_bass = score.create_staff("Double Bass", "D.B.", finale.FFUUID_DOUBLE_BASSSECTION, "bass")

    score.create_group_primary(staves.flutes_1_2, staves.bassoons_1_2)
    score.create_group_primary(staves.horns_1_2, staves.tuba)
    score.create_group_primary(staves.percussion_1, staves.percussion_3)
    score.create_group_primary(staves.violin_1, staves.double_bass)
    score.create_group_secondary(staves.horns_1_2, staves.horns_3_4, "Horn in F", "Hn.")
    score.create_group_secondary(staves.trumpets_1_2, staves.trumpets_3_4, "Trumpet in C", "Tpt.")
    score.create_group_secondary(staves.trombones_1_2, staves.trombone_bass, "Trombone", "Tbn.")
    score.create_group_secondary(staves.violin_1, staves.violin_2)

    score.set_staff_transposition(staves.clarinets_1_2, "Bb", 1)
    score.set_staff_transposition(staves.horns_1_2, "F", 4, "treble")
    score.set_staff_transposition(staves.horns_3_4, "F", 4, "treble")
    score.set_staff_transposition(staves.double_bass, "C", 7)

    score.apply_config(
        config,
        {force_staves_show_time_signatures = {staves.flutes_1_2, staves.horns_1_2, staves.timpani, staves.violin_1}})
end

score_create_trombone_choir_score()

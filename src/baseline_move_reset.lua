function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Version = "1.0"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Date = "May 15, 2022"
    finaleplugin.CategoryTags = "Baseline"
    finaleplugin.AuthorURL = "http://robertgpatterson.com"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        This script nudges system baselines up or down by a single staff-space (24 evpus). It introduces 10
        menu options to nudge each baseline type up or down. It also introduces 5 menu options to reset
        the baselines to their staff-level values.

        The possible prefix inputs to the script are

        ```
        direction -- 1 for up, -1 for down, 0 for reset
        baseline_types -- a table containing a list of the baseline types to process
        nudge_evpus -- a positive number indicating the size of the nudge
        ```

        You can also change the size of the nudge by creating a configuration file called `baseline_move.config.txt` and
        adding a single line with the size of the nudge in evpus.

        ```
        nudge_evpus = 36 -- or whatever size you wish
        ```

        A value in a prefix overrides any setting in a configuration file.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Move Lyric Baselines Up
        Reset Lyric Baselines
        Move Expression Baseline Above Down
        Move Expression Baseline Above Up
        Reset Expression Baseline Above
        Move Expression Baseline Below Down
        Move Expression Baseline Below Up
        Reset Expression Baseline Below
        Move Chord Baseline Down
        Move Chord Baseline Up
        Reset Chord Baseline
        Move Fretboard Baseline Down
        Move Fretboard Baseline Up
        Reset Fretboard Baseline
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Moves all lyrics baselines up one space in the selected systems
        Resets all selected lyrics baselines to default
        Moves the selected expression above baseline down one space
        Moves the selected expression above baseline up one space
        Resets the selected expression above baselines
        Moves the selected expression below baseline down one space
        Moves the selected expression below baseline up one space
        Resets the selected expression below baselines
        Moves the selected chord baseline down one space
        Moves the selected chord baseline up one space
        Resets the selected chord baselines
        Moves the selected fretboard baseline down one space
        Moves the selected fretboard baseline up one space
        Resets the selected fretboard baselines
    ]]
    finaleplugin.AdditionalPrefixes = [[
        direction = 1 -- no baseline_types table, which picks up the default (lyrics)
        direction = 0 -- no baseline_types table, which picks up the default (lyrics)
        direction = -1 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = 1 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = 0 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = -1 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = 1 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = 0 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = -1 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = 1 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = 0 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = -1 baseline_types = {finale.BASELINEMODE_FRETBOARD}
        direction = 1 baseline_types = {finale.BASELINEMODE_FRETBOARD}
        direction = 0 baseline_types = {finale.BASELINEMODE_FRETBOARD}
    ]]
    return "Move Lyric Baselines Down", "Move Lyrics Baselines Down", "Moves all lyrics baselines down one space in the selected systems"
end

local configuration = require("library.configuration")

local config = {nudge_evpus = 24}

if nil ~= configuration then
    configuration.get_parameters("baseline_move.config.txt", config)
end

local lyric_baseline_types = {
    [finale.BASELINEMODE_LYRICSVERSE] = function()
        return finale.FCVerseLyricsText()
    end,
    [finale.BASELINEMODE_LYRICSCHORUS] = function()
        return finale.FCChorusLyricsText()
    end,
    [finale.BASELINEMODE_LYRICSSECTION] = function()
        return finale.FCSectionLyricsText()
    end,
}

local find_valid_lyric_nums = function(baseline_type)
    local lyrics_text_class_constructor = lyric_baseline_types[baseline_type]
    if lyrics_text_class_constructor then
        local valid_lyric_nums = {}
        local lyrics_text_class = lyrics_text_class_constructor()
        for i = 1, 32767, 1 do
            if lyrics_text_class:Load(i) then
                local str = finale.FCString()
                lyrics_text_class:GetText(str)
                if not str:IsEmpty() then
                    valid_lyric_nums[{baseline_type, i}] = 1
                end
            end
        end
        return valid_lyric_nums
    end
    return nil
end

function baseline_move()
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()

    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local lastSys_number = lastSys:GetItemNo()
    local start_slot = region:GetStartSlot()
    local end_slot = region:GetEndSlot()

    for _, baseline_type in pairs(baseline_types) do
        local valid_lyric_nums = find_valid_lyric_nums(baseline_type) -- will be nil for non-lyric baseline types
        for i = system_number, lastSys_number, 1 do
            local baselines = finale.FCBaselines()
            if direction ~= 0 then
                baselines:LoadAllForSystem(baseline_type, i)
                for j = start_slot, end_slot do
                    local bl
                    if valid_lyric_nums then
                        for lyric_info, _ in pairs(valid_lyric_nums) do
                            local _, lyric_number = table.unpack(lyric_info)
                            bl = baselines:AssureSavedLyricNumber(baseline_type, i, region:CalcStaffNumber(j), lyric_number)
                            bl.VerticalOffset = bl.VerticalOffset + direction * nudge_evpus
                            bl:Save()
                        end
                    else
                        bl = baselines:AssureSavedStaff(baseline_type, i, region:CalcStaffNumber(j))
                        bl.VerticalOffset = bl.VerticalOffset + direction * nudge_evpus
                        bl:Save()
                    end
                end
            else
                for j = start_slot, end_slot do
                    baselines:LoadAllForSystemStaff(baseline_type, i, region:CalcStaffNumber(j))
                    -- iterate backwards to preserve lower inci numbers when deleting
                    for baseline in eachbackwards(baselines) do
                        baseline:DeleteData()
                    end
                end
            end
        end
    end
end

-- parameters for additional menu options
baseline_types = baseline_types or {finale.BASELINEMODE_LYRICSVERSE, finale.BASELINEMODE_LYRICSCHORUS, finale.BASELINEMODE_LYRICSSECTION}
direction = direction or -1
nudge_evpus = nudge_evpus or config.nudge_evpus

baseline_move()

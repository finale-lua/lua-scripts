function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Version = "1.0"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Date = "June 23, 2021"
    finaleplugin.CategoryTags = "Lyric"
    finaleplugin.AuthorURL = "http://robertgpatterson.com"
    return "Move Lyric Baselines Up", "Move Lyrics Baselines Up",
           "Moves all selected lyrics baselines up one space"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local configuration = require("library.configuration")

local config = {
    nudge_up_evpus = 24
}

if nil ~= configuration then
    configuration.get_parameters("lyrics_baseline_move.config.txt", config)
end

local baseline_types = {
    [finale.BASELINEMODE_LYRICSVERSE] = function() return finale.FCVerseLyricsText() end,
    [finale.BASELINEMODE_LYRICSCHORUS] = function() return finale.FCChorusLyricsText() end,
    [finale.BASELINEMODE_LYRICSSECTION] = function() return finale.FCSectionLyricsText() end
}

function find_valid_lyric_nums()
    local valid_lyric_nums = {}
    for baseline_type, lyrics_text_class_constructor in pairs(baseline_types) do
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
    end
    return valid_lyric_nums
end

function lyrics_baseline_move_up()
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()

    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local lastSys_number = lastSys:GetItemNo()
    local start_staff = region:GetStartStaff()
    local end_staff = region:GetEndStaff()

    local valid_lyric_nums = find_valid_lyric_nums()

    for i = system_number, lastSys_number, 1 do
        local baselines = finale.FCBaselines()
        for lyric_info, _ in pairs(valid_lyric_nums) do
            local baseline_type, lyric_number = table.unpack(lyric_info)
            baselines:LoadAllForSystem(baseline_type, i)
            for j = start_staff, end_staff, 1 do
                bl = baselines:AssureSavedLyricNumber(baseline_type, i, j, lyric_number)
                bl.VerticalOffset = bl.VerticalOffset + config.nudge_up_evpus
                bl:Save()
            end
        end
    end
end

lyrics_baseline_move_up()

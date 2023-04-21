function plugindef()


       finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "2022-10-20"
    finaleplugin.RequireSelection = true
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/lyrics_baseline_reset.hash"
   return "Reset Lyric Baselines (system specific)", "Reset Lyric Baselines (system specific)", "Resets Lyric Baselines on a system-by-system basis (3rd triangle)"
end
function lyrics_baseline_reset()
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
    for i = system_number, lastSys_number, 1 do
        local baselines_verse = finale.FCBaselines()
        local baselines_chorus = finale.FCBaselines()
        local baselines_section = finale.FCBaselines()
        local lyric_number = 1
        baselines_verse:LoadAllForSystem(finale.BASELINEMODE_LYRICSVERSE, i)
        baselines_chorus:LoadAllForSystem(finale.BASELINEMODE_LYRICSCHORUS, i)
        baselines_section:LoadAllForSystem(finale.BASELINEMODE_LYRICSSECTION, i)
        for j = start_staff, end_staff, 1 do
            for k = lyric_number, 100, 1 do
                baseline_verse = baselines_verse:AssureSavedLyricNumber(finale.BASELINEMODE_LYRICSVERSE, i, j, k)
                baseline_verse.VerticalOffset = 0
                baseline_verse:Save()

                baseline_chorus = baselines_chorus:AssureSavedLyricNumber(finale.BASELINEMODE_LYRICSCHORUS, i, j, k)
                baseline_chorus.VerticalOffset = 0
                baseline_chorus:Save()

                baseline_section = baselines_section:AssureSavedLyricNumber(finale.BASELINEMODE_LYRICSSECTION, i, j, k)
                baseline_section.VerticalOffset = 0
                baseline_section:Save()
            end
        end
    end
end
lyrics_baseline_reset()
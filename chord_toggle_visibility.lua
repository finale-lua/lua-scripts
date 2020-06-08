function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "July 2, 2019"
    finaleplugin.CategoryTags = "Chord"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Toggle Chord Visibility 2", "Toggle Chord Visibility 2", "Toggles the chords' visibility"
end

local musicRegion = finenv.Region()
musicRegion:SetCurrentSelection()
local chords = finale.FCChords()
chords:LoadAllForRegion(musicRegion)
for chord in each(chords) do
    chord.ChordVisible = not chord:GetChordVisible()
    chord:Save()
end


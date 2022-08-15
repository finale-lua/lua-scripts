function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 19, 2020"
    finaleplugin.CategoryTags = "Playback"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Mute Cue Notes", "Mute Cue Notes", "Mutes notes that are 85% normal size or smaller"
end
function playback_cues_mute()
    local notesize_limit = 85
    for entry in eachentrysaved(finenv.Region()) do
        local playback = false
        local notehead_mod = finale.FCNoteheadMod()
        if entry:CalcResize() > notesize_limit then
            for note in each(entry) do
                notehead_mod:LoadAt(note)
                if (notehead_mod.Resize > notesize_limit) then
                    playback = true
                end
            end
        end
        entry.Playback = playback
    end
end
playback_cues_mute()

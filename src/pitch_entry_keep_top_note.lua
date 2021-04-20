function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 7, 2020"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Chord Line - Keep Top Note", "Chord Line - Keep Top Note",
           "Keeps the top note of every chord and deletes the rest"
end

function pitch_entry_keep_top_note()
    for entry in eachentrysaved(finenv.Region()) do
        while (entry.Count >= 2) do
            local bottom_note = entry:CalcLowestNote(nil)
            entry:DeleteNote(bottom_note)
        end
    end
end

pitch_entry_keep_top_note()

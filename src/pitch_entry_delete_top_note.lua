function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 7, 2020"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Chord Line - Delete Top Note", "Chord Line - Delete Top Note", "Deletes the top note of every chord"
end

function pitch_entry_delete_top_note()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local top_note = entry:CalcHighestNote(nil)
            entry:DeleteNote(top_note)
        end
    end
end

pitch_entry_delete_top_note()

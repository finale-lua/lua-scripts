function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 9, 2020"
    finaleplugin.CategoryTags = "Note"
    return "Add Augmentation Dots", "Add Augmentation Dots", "Add an augmentation dot to all notes and rests in selected region."
end

function note_add_augmentation_dots()
    for entry in eachentrysaved(finenv.Region()) do
        entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
    end
    finenv.Region():RebeamMusic()
end

note_add_augmentation_dots()

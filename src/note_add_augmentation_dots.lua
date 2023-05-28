function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "May 27, 2023"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.RequireSelection = true
    finaleplugin.AdditionalMenuOptions = [[
        Remove Augmentation Dots
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Removes the right-most augmentation dot from all notes and rests in the selected region."
    ]]
    finaleplugin.AdditionalPrefixes = [[
        remove_dots = true
    ]]
    finaleplugin.Notes = [[
        This plugin adds two menu items, "Add Augmentation Dots" and "Remove Augmentation Dots". The
        "Remove" function reverses the result of the "Add" function, which means it removes only the
        right-most dot each time you invoke it. However, if you invoke the "Remove" function while holding
        down the Shift or Option keys, the script removes all augmentation dots in a single invocation.
        (This requires a version of RGP Lua that supports it, which includes the current version.)
    ]]
    return "Add Augmentation Dots", "Add Augmentation Dots",
           "Add an augmentation dot to all notes and rests in selected region."
end

local note_entry = require("library.note_entry")

remove_dots = remove_dots or false

local remove_all = remove_dots and finenv.QueryInvokedModifierKeys and
                    (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))

function note_add_augmentation_dots()
    for entry in eachentrysaved(finenv.Region()) do
        if remove_dots then
            while note_entry.remove_augmentation_dot(entry) do
                if not remove_all then
                    break
                end
            end
        else
            note_entry.add_augmentation_dot(entry)
        end
    end
    finenv.Region():RebeamMusic()
end

note_add_augmentation_dots()

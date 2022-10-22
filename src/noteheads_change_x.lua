function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.53"
    finaleplugin.Date = "2022/10/22"
    finaleplugin.Notes = [[
        This script changes all noteheads in the current selection to X-Noteheads (SMuFL compliant). 
        To revert all noteheads to the default character hold down the the `shift` or `alt` (option) key when choosing the menu item.
        ]]
    return "Noteheads Change to X", "Noteheads Change to X", "Change all noteheads in the selection to X-Noteheads (SMuFL compliant)"
end

local notehead = require("library.notehead")

function change_notehead_x()
    local mod_down = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    local new_shape = mod_down and "default" or "x"
    -- other allowable notehead shape descriptors:
    -- "diamond" / "guitar_diamond" / "x"

    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() then
            for note in each(entry) do
                notehead.change_shape(note, new_shape)
            end
        end
    end
end

change_notehead_x()

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Date = "2022/10/19"
    return "Noteheads Crossed", "Noteheads Crossed", "Convert all noteheads in the selection to crosses (SMuFL compliant)"
end

local library = require("library.general_library")

function change_notehead()
    local cross_head = 0x00bf -- non-SMuFL character
    if library.is_font_smufl_font() then
        cross_head = 0xe0a9   -- SMuFL version
    end

    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() then
            for note in each(entry) do
                local notehead = finale.FCNoteheadMod() -- create a notehead modification object
                notehead:EraseAt(note) -- remove any old notehead data for this entry
                notehead.CustomChar = cross_head
                notehead:SaveAt(note)
            end
        end
    end
end

change_notehead()

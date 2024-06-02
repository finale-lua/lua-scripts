function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.62"
    finaleplugin.Date = "2024/06/02"
    finaleplugin.Notes = [[
        Create diamond noteheads on the top note of dyads identified as viable string harmonics. 
        Note that this uses MIDI note values to identify acceptable intervals to 
        avoid the complications of key signatures and transposing instruments. 
        This is inelegant but simple and should work in most situations! 
    ]]
    return "String Harmonics", "String Harmonics",
        "Create diamond noteheads on the top note of dyads identified as viable string harmonics"
end

local notehead = require("library.notehead")

function string_harmonics()
    -- allowable intervals for string harmonics, measured in interval STEPS
    local allowed = { 3, 4, 5, 7, 9, 12, 16, 19, 24, 28, 31 }
    local allowable = {}
    for _, v in ipairs(allowed) do allowable[v] = true end

    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() and (entry.Count == 2) then -- only treat 2-note chords
            local highest = entry:CalcHighestNote(nil)
            local lowest = entry:CalcLowestNote(nil)
            local midi_diff = highest:CalcMIDIKey() - lowest:CalcMIDIKey()

            if allowable[midi_diff] then -- only permissible intervals
                finale.FCNoteheadMod():EraseAt(lowest)
                notehead.change_shape(highest, "diamond")
            end
        end
    end
end

string_harmonics()

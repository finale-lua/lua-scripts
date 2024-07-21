function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.63"
    finaleplugin.Date = "2024/07/21"
    finaleplugin.Notes = [[
        This script converts the __upper__ note of allowable _string harmonic_
        dyads (two-note chords) into __diamond__ noteheads. 
        The first twelve harmonics of the lower _root_ pitch are recognised. 

        Three other scripts currently in the 
        [FinaleLua.com ](https://FinaleLua.com) repository 
        ("_String harmonics_ __X__ _sounding pitch_") take single-pitch 
        _sounding_ notes and create an equivalent played _string harmonic_ by adding a
        __diamond-headed__ _harmonic_ note, and transposing the resulting dyad 
        downwards by the interval of the harmonic.
    ]]
    return "String Harmonics",
        "String Harmonics",
        "Identify suitable string harmonic dyads and change the top note to a diamond notehead"
end

local notehead = require("library.notehead")

function string_harmonics()
    -- recognised intervals for string harmonics measured in semitone STEPS,
    -- mapped to the corresponding diatonic interval
    local allowed = {
         [3] = 2,   [4] = 2,   [5] = 3,  [7] = 4,
         [9] = 5,  [12] = 7,  [16] = 9, [19] = 11,
        [24] = 14, [28] = 16, [31] = 18
    }
    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() and (entry.Count == 2) then -- only treat dyads
            local highest = entry:CalcHighestNote(nil)
            local lowest = entry:CalcLowestNote(nil)
            local midi_diff = highest:CalcMIDIKey() - lowest:CalcMIDIKey()
            local displacement_diff = highest.Displacement - lowest.Displacement
            if allowed[midi_diff] and allowed[midi_diff] == displacement_diff then
                finale.FCNoteheadMod():EraseAt(lowest)
                notehead.change_shape(highest, "diamond")
            end
        end
    end
end

string_harmonics()

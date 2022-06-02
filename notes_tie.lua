function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.58"
    finaleplugin.Date = "2022/06/01"
    finaleplugin.AdditionalMenuOptions = [[ Untie Notes ]]
    finaleplugin.AdditionalUndoText = [[    Untie Notes ]]
    finaleplugin.AdditionalPrefixes = [[    untie_notes = true ]]
    finaleplugin.AdditionalDescriptions = [[ Untie all notes in the selected region ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[ 
    Ties notes in adjacent entries if matching pitches are available. 
    RGPLua (0.62 and above) creates a companion menu item, UNTIE Notes.
    ]]
    return "Tie Notes", "Tie Notes", "Tie suitable notes in the selected region, with matching Untie option"
end

-- default to "tie" notes for normal operation
untie_notes = untie_notes or false

local function note_pitch(note)
    -- thanks for this bitwise math magic, Robert G Patterson!
    return bit32.bor(note.RaiseLower, bit32.lshift(note.Displacement, 16))
end

local function tie_notes_in_selection()
    local rgn = finenv.Region()
    local chords = {} -- collate pitches in each chord
    local slot = 1 -- count each entry slot

    for entry in eachentry(rgn) do -- just collating pitches, not SAVING entries
        chords[slot] = {} -- start with empty chord
        if entry:IsNote() then
            for note in each(entry) do
                chords[slot][note_pitch(note)] = true -- flag this pitch in the chord
            end
        end
        slot = slot + 1
    end

    slot = 1 -- restart from slot 1
    for entry in eachentrysaved(rgn) do
        if entry:IsNote() then
            for note in each(entry) do
                if nil == chords[slot+1] then -- last chord
                    break
                end
                if chords[slot+1][note_pitch(note)] then
                    note.Tie = true -- tie the note forward
                end
            end
        end
        slot = slot + 1
    end
end

function untie_notes_in_selection()
    for entry in eachentrysaved(finenv.Region()) do
        for note in each(entry) do
            note.Tie = false
            note.TieBackwards = false
        end
    end
end

if untie_notes then
    untie_notes_in_selection()
else
    tie_notes_in_selection()
end

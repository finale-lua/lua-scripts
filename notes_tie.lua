function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.74"
    finaleplugin.Date = "2022/06/04"
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

function tie_between_entries(entry_one, entry_two)
    if not entry_one or not entry_two -- entries must exist
        or entry_one:IsRest() or entry_two:IsRest() -- not rests
        or entry_one.Voice2 ~= entry_two.Voice2 -- on same voice
        or entry_two.GraceNote
        then return
    end
    for note in each(entry_one) do
        local note_tied_to = entry_two:FindPitch(note) -- find the pitch?
        if note_tied_to then
            note.Tie = true -- then tie it
            note_tied_to.TieBackwards = true -- and backwards
        end
    end
end

function tie_notes_in_selection()
    local region = finenv.Region()

    for staff_number = region.StartStaff, region.EndStaff do
        for layer_number = 0, 3 do  -- run through layers [0-based]
            local saved_v1_entry = nil -- v1 entry held while v2 running
            local v2_is_active = false
            local entry_layer = finale.FCNoteEntryLayer(layer_number, staff_number, region.StartMeasure, region.EndMeasure)
            entry_layer:Load()

            for entry in each(entry_layer) do
                if not entry:Next() then -- this is the final entry
                    if not entry.Voice2 and v2_is_active then -- possible left-over V1 ties
                        tie_between_entries(saved_v1_entry, entry)
                    end -- finished with this layer
                else
                    -- voice 1, launching V2
                    if not entry.Voice2 and entry.Voice2Launch and entry:Next().Voice2 then -- voice 2 is launching
                        saved_v1_entry = entry -- save V1 entry for later
                        v2_is_active = true -- set V2 flag; nothing else to do
                    else
                        if not entry.Voice2 and v2_is_active then -- returning to V1 chain, so check saved_v1_entry
                            tie_between_entries(saved_v1_entry, entry) -- check backwards tie to last saved V1 entry
                            saved_v1_entry = nil -- clear the saved V1 entry
                            v2_is_active = false -- clear V2 flag
                        end
                        -- check for normal forward tie
                        tie_between_entries(entry, entry:Next()) -- tests for all compliance
                    end
                end
            end
            entry_layer:Save()
        end
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

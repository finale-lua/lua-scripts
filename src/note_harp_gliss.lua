function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.MinFinaleVersion = "2012"
    finaleplugin.Author = "Jari Williamsson"
    finaleplugin.Version = "0.01"
    finaleplugin.Notes = [[
        This script will only process 7-tuplets that appears on staves that has been defined as "Harp" in the Score Manager.
    ]]
    finaleplugin.CategoryTags = "Idiomatic, Note, Plucked Strings, Region, Tuplet, Woodwinds"
    return "Harp gliss", "Harp gliss", "Transforms 7-tuplets to harp gliss notation."
end

local configuration = require("library.configuration")

local config = {
    stem_length = 84, -- Stem Length of the first note in EVPUs
    small_note_size = 70, -- Resize % of small notes
}

configuration.get_parameters("harp_gliss.config.txt", config)

-- Sets the beam width to 0 and resizes the stem for the first note (by moving
-- the primary beam)
-- This is a sub-function to ChangePrimaryBeam()
function change_beam_info(primary_beam, entry)
    local current_length = entry:CalcStemLength()
    primary_beam.Thickness = 0
    if entry:CalcStemUp() then
        primary_beam.LeftVerticalOffset = primary_beam.LeftVerticalOffset + config.stem_length - current_length
    else
        primary_beam.LeftVerticalOffset = primary_beam.LeftVerticalOffset - config.stem_length + current_length
    end
end

-- Changes a primary beam for and entry
function change_primary_beam(entry)
    local primary_beams = finale.FCPrimaryBeamMods(entry)
    primary_beams:LoadAll()
    if primary_beams.Count > 0 then
        -- Modify the existing beam modification record to hide the beam
        local primary_beam = primary_beams:GetItemAt(0)
        change_beam_info(primary_beam, entry)
        primary_beam:Save()
    else
        -- Create a beam modification record and hide the beam
        local primary_beam = finale.FCBeamMod(false)
        primary_beam:SetNoteEntry(entry)
        change_beam_info(primary_beam, entry)
        primary_beam:SaveNew()
    end
end

-- Assures that the entries that spans the entries are
-- considered "valid" for a harp gliss. Rests and too few
-- notes in the tuplet are things that aren't ok.
-- This is a sub-function to GetMatchingTuplet()
function verify_entries(entry, tuplet)
    local entry_staff_spec = finale.FCCurrentStaffSpec()
    entry_staff_spec:LoadForEntry(entry)
    if entry_staff_spec.InstrumentUUID ~= finale.FFUUID_HARP then
        return false
    end
    local symbolic_duration = 0
    local first_entry = entry
    for _ = 0, 6 do
        if entry == nil then
            return false
        end
        if entry:IsRest() then
            return false
        end
        if entry.Duration >= finale.QUARTER_NOTE then
            return false
        end
        if entry.Staff ~= first_entry.Staff then
            return false
        end
        if entry.Layer ~= first_entry.Layer then
            return false
        end
        if entry:CalcDots() > 0 then
            return false
        end
        symbolic_duration = symbolic_duration + entry.Duration
        entry = entry:Next()
    end
    return (symbolic_duration == tuplet:CalcFullSymbolicDuration())
end

-- If a "valid" harp tuplet is found for an entry, this method returns it.
function get_matching_tuplet(entry)
    local tuplets = entry:CreateTuplets()
    for tuplet in each(tuplets) do
        if tuplet.SymbolicNumber == 7 and verify_entries(entry, tuplet) then
            return tuplet
        end
    end
    return nil
end

-- Hides a tuplet (both by visibility and appearance)
function hide_tuplet(tuplet)
    tuplet.ShapeStyle = finale.TUPLETSHAPE_NONE
    tuplet.NumberStyle = finale.TUPLETNUMBER_NONE
    tuplet.Visible = false
    tuplet:Save()
end

-- Hide stems for the small notes in the gliss. If the "full" note has a long
-- enough duration to not have a stem, the first entry also gets a hidden stem.
function hide_stems(entry, tuplet)
    local hide_first_entry = (tuplet:CalcFullReferenceDuration() >= finale.WHOLE_NOTE)
    for i = 0, 6 do
        if i > 0 or hide_first_entry then
            local stem = finale.FCCustomStemMod()
            stem:SetNoteEntry(entry)
            stem:UseUpStemData(entry:CalcStemUp())
            if stem:LoadFirst() then
                stem.ShapeID = 0
                stem:Save()
            else
                stem.ShapeID = 0
                stem:SaveNew()
            end
        end
        entry = entry:Next()
    end
end

-- Change the notehead shapes and notehead sizes
function set_noteheads(entry, tuplet)
    for i = 0, 6 do
        for chord_note in each(entry) do
            local notehead = finale.FCNoteheadMod()
            if i == 0 then
                local reference_duration = tuplet:CalcFullReferenceDuration()
                if reference_duration >= finale.WHOLE_NOTE then
                    notehead.CustomChar = 119 -- Whole note character
                elseif reference_duration >= finale.HALF_NOTE then
                    notehead.CustomChar = 250 -- Half note character
                end
            else
                notehead.Resize = config.small_note_size
            end
            notehead:SaveAt(chord_note)
        end
        entry = entry:Next()
    end
end

-- If the tuplet spans a duration that is dotted, modify the
-- rhythm at the beginning of the tuplet
function change_dotted_first_entry(entry, tuplet)
    local reference_duration = tuplet:CalcFullReferenceDuration()
    local tuplet_dots = finale.FCNoteEntry.CalcDotsForDuration(reference_duration)
    local entry_dots = entry:CalcDots()
    if tuplet_dots == 0 then
        return
    end
    if tuplet_dots > 3 then
        return
    end -- Don't support too complicated gliss rhythm values
    if entry_dots > 0 then
        return
    end
    -- Create dotted rhythm
    local next_entry = entry:Next()
    local next_duration = next_entry.Duration / 2
    for _ = 1, tuplet_dots do
        entry.Duration = entry.Duration + next_duration
        next_entry.Duration = next_entry.Duration - next_duration
        next_duration = next_duration / 2
    end
end

function harp_gliss()
    -- Make sure the harp tuplets are beamed
    local harp_tuplets_exist = false
    for entry in eachentrysaved(finenv.Region()) do
        local harp_tuplet = get_matching_tuplet(entry)
        if harp_tuplet then
            harp_tuplets_exist = true
            for i = 1, 6 do
                entry = entry:Next()
                entry.BeamBeat = false
            end
        end
    end

    if not harp_tuplets_exist then
        return
    end

    -- Since the entries might change direction when they are beamed,
    -- tell Finale to update the entry metric data info
    finale.FCNoteEntry.MarkEntryMetricsForUpdate()

    -- Change the harp tuplets
    for entry in eachentrysaved(finenv.Region()) do
        local harp_tuplet = get_matching_tuplet(entry)
        if harp_tuplet then
            change_dotted_first_entry(entry, harp_tuplet)
            change_primary_beam(entry)
            hide_tuplet(harp_tuplet)
            hide_stems(entry, harp_tuplet)
            set_noteheads(entry, harp_tuplet)
        end
    end
end

harp_gliss()


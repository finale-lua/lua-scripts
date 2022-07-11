function plugindef()
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "3/18/2022"
    finaleplugin.Notes = [[
        USING THE 'BARIOLAGE' SCRIPT

        This script creates bariolage-style notation where layers 1 and 2 interlock. It works well for material that has even-numbered beam groups like 4x 16th notes or 6x 16th notes (in compound meters). 32nd notes also work. Odd numbers of notes produce undesirable results.

        To use, create a suitable musical passage in layer 1, then run the script. The script does the following:
        - Duplicates layer 1 to layer 2.
        - Mutes playback of layer 2.
        - Iterates through the notes in layer 1. For even-numbered notes (i.e. the 2nd and 4th 16ths in a group of 4) it replaces the stem with a blank shape, effectively hiding it.
        - Any note in layer 1 that is the last note of a beamed group is hidden.
        - Iterates through the notes in layer 2 and changes the stems of the odd-numbered notes.
        - Any note in layer 2 that is the beginning of a beamed group is hidden.
    ]]
    return "Bariolage", "Bariolage",
           "Bariolage: Creates alternating layer pattern from layer 1. Doesn't play nicely with odd numbered groups!"
end

--[[
$module Layer
]] --
local layer = {}

--[[
% copy

Duplicates the notes from the source layer to the destination. The source layer remains untouched.

@ region (FCMusicRegion) the region to be copied
@ source_layer (number) the number (1-4) of the layer to duplicate
@ destination_layer (number) the number (1-4) of the layer to be copied to
]]
function layer.copy(region, source_layer, destination_layer)
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(region)
    source_layer = source_layer - 1
    destination_layer = destination_layer - 1
    for sysstaff in each(sysstaves) do
        staffNum = sysstaff.Staff
        local noteentry_source_layer = finale.FCNoteEntryLayer(source_layer, staffNum, start, stop)
        noteentry_source_layer:Load()
        local noteentry_destination_layer = noteentry_source_layer:CreateCloneEntries(
                                                destination_layer, staffNum, start)
        noteentry_destination_layer:Save()
        noteentry_destination_layer:CloneTuplets(noteentry_source_layer)
        noteentry_destination_layer:Save()
    end
end -- function layer_copy

--[[
% clear

Clears all entries from a given layer.

@ region (FCMusicRegion) the region to be cleared
@ layer_to_clear (number) the number (1-4) of the layer to clear
]]
function layer.clear(region, layer_to_clear)
    layer_to_clear = layer_to_clear - 1 -- Turn 1 based layer to 0 based layer
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(region)
    for sysstaff in each(sysstaves) do
        staffNum = sysstaff.Staff
        local noteentrylayer = finale.FCNoteEntryLayer(layer_to_clear, staffNum, start, stop)
        noteentrylayer:Load()
        noteentrylayer:ClearAllEntries()
    end
end

--[[
% swap

Swaps the entries from two different layers (e.g. 1-->2 and 2-->1).

@ region (FCMusicRegion) the region to be swapped
@ swap_a (number) the number (1-4) of the first layer to be swapped
@ swap_b (number) the number (1-4) of the second layer to be swapped
]]
function layer.swap(region, swap_a, swap_b)
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(region)
    -- Set layers for 0 based
    swap_a = swap_a - 1
    swap_b = swap_b - 1
    for sysstaff in each(sysstaves) do
        staffNum = sysstaff.Staff
        local noteentrylayer_1 = finale.FCNoteEntryLayer(swap_a, staffNum, start, stop)
        noteentrylayer_1:Load()
        noteentrylayer_1.LayerIndex = swap_b
        --
        local noteentrylayer_2 = finale.FCNoteEntryLayer(swap_b, staffNum, start, stop)
        noteentrylayer_2:Load()
        noteentrylayer_2.LayerIndex = swap_a
        noteentrylayer_1:Save()
        noteentrylayer_2:Save()
    end
end



--[[
$module Note Entry
]] --
local note_entry = {}

--[[
% get_music_region

Returns an intance of `FCMusicRegion` that corresponds to the metric location of the input note entry.

@ entry (FCNoteEntry)
: (FCMusicRegion)
]]
function note_entry.get_music_region(entry)
    local exp_region = finale.FCMusicRegion()
    exp_region:SetCurrentSelection() -- called to match the selected IU list (e.g., if using Staff Sets)
    exp_region.StartStaff = entry.Staff
    exp_region.EndStaff = entry.Staff
    exp_region.StartMeasure = entry.Measure
    exp_region.EndMeasure = entry.Measure
    exp_region.StartMeasurePos = entry.MeasurePos
    exp_region.EndMeasurePos = entry.MeasurePos
    return exp_region
end

-- entry_metrics can be omitted, in which case they are constructed and released here
-- return entry_metrics, loaded_here
local use_or_get_passed_in_entry_metrics = function(entry, entry_metrics)
    if entry_metrics then
        return entry_metrics, false
    end
    entry_metrics = finale.FCEntryMetrics()
    if entry_metrics:Load(entry) then
        return entry_metrics, true
    end
    return nil, false
end

--[[
% get_evpu_notehead_height

Returns the calculated height of the notehead rectangle.

@ entry (FCNoteEntry)

: (number) the EVPU height
]]
function note_entry.get_evpu_notehead_height(entry)
    local highest_note = entry:CalcHighestNote(nil)
    local lowest_note = entry:CalcLowestNote(nil)
    local evpu_height = (2 + highest_note:CalcStaffPosition() - lowest_note:CalcStaffPosition()) * 12 -- 12 evpu per staff step; add 2 staff steps to accommodate for notehead height at top and bottom
    return evpu_height
end

--[[
% get_top_note_position

Returns the vertical page coordinate of the top of the notehead rectangle, not including the stem.

@ entry (FCNoteEntry)
@ [entry_metrics] (FCEntryMetrics) entry metrics may be supplied by the caller if they are already available
: (number)
]]
function note_entry.get_top_note_position(entry, entry_metrics)
    local retval = -math.huge
    local loaded_here = false
    entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
    if nil == entry_metrics then
        return retval
    end
    if not entry:CalcStemUp() then
        retval = entry_metrics.TopPosition
    else
        local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
        if nil ~= cell_metrics then
            local evpu_height = note_entry.get_evpu_notehead_height(entry)
            local scaled_height = math.floor(((cell_metrics.StaffScaling * evpu_height) / 10000) + 0.5)
            retval = entry_metrics.BottomPosition + scaled_height
            cell_metrics:FreeMetrics()
        end
    end
    if loaded_here then
        entry_metrics:FreeMetrics()
    end
    return retval
end

--[[
% get_bottom_note_position

Returns the vertical page coordinate of the bottom of the notehead rectangle, not including the stem.

@ entry (FCNoteEntry)
@ [entry_metrics] (FCEntryMetrics) entry metrics may be supplied by the caller if they are already available
: (number)
]]
function note_entry.get_bottom_note_position(entry, entry_metrics)
    local retval = math.huge
    local loaded_here = false
    entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
    if nil == entry_metrics then
        return retval
    end
    if entry:CalcStemUp() then
        retval = entry_metrics.BottomPosition
    else
        local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
        if nil ~= cell_metrics then
            local evpu_height = note_entry.get_evpu_notehead_height(entry)
            local scaled_height = math.floor(((cell_metrics.StaffScaling * evpu_height) / 10000) + 0.5)
            retval = entry_metrics.TopPosition - scaled_height
            cell_metrics:FreeMetrics()
        end
    end
    if loaded_here then
        entry_metrics:FreeMetrics()
    end
    return retval
end

--[[
% calc_widths

Get the widest left-side notehead width and widest right-side notehead width.

@ entry (FCNoteEntry)
: (number, number) widest left-side notehead width and widest right-side notehead width
]]
function note_entry.calc_widths(entry)
    local left_width = 0
    local right_width = 0
    for note in each(entry) do
        local note_width = note:CalcNoteheadWidth()
        if note_width > 0 then
            if note:CalcRightsidePlacement() then
                if note_width > right_width then
                    right_width = note_width
                end
            else
                if note_width > left_width then
                    left_width = note_width
                end
            end
        end
    end
    return left_width, right_width
end

-- These functions return the offset for an expression handle.
-- Expression handles are vertical when they are left-aligned
-- with the primary notehead rectangle.

--[[
% calc_left_of_all_noteheads

Calculates the handle offset for an expression with "Left of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_left_of_all_noteheads(entry)
    if entry:CalcStemUp() then
        return 0
    end
    local left, right = note_entry.calc_widths(entry)
    return -left
end

--[[
% calc_left_of_primary_notehead

Calculates the handle offset for an expression with "Left of Primary Notehead" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_left_of_primary_notehead(entry)
    return 0
end

--[[
% calc_center_of_all_noteheads

Calculates the handle offset for an expression with "Center of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_center_of_all_noteheads(entry)
    local left, right = note_entry.calc_widths(entry)
    local width_centered = (left + right) / 2
    if not entry:CalcStemUp() then
        width_centered = width_centered - left
    end
    return width_centered
end

--[[
% calc_center_of_primary_notehead

Calculates the handle offset for an expression with "Center of Primary Notehead" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_center_of_primary_notehead(entry)
    local left, right = note_entry.calc_widths(entry)
    if entry:CalcStemUp() then
        return left / 2
    end
    return right / 2
end

--[[
% calc_stem_offset

Calculates the offset of the stem from the left edge of the notehead rectangle. Eventually the PDK Framework may be able to provide this instead.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset of stem from the left edge of the notehead rectangle.
]]
function note_entry.calc_stem_offset(entry)
    if not entry:CalcStemUp() then
        return 0
    end
    local left, right = note_entry.calc_widths(entry)
    return left
end

--[[
% calc_right_of_all_noteheads

Calculates the handle offset for an expression with "Right of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_right_of_all_noteheads(entry)
    local left, right = note_entry.calc_widths(entry)
    if entry:CalcStemUp() then
        return left + right
    end
    return right
end

--[[
% calc_note_at_index

This function assumes `for note in each(note_entry)` always iterates in the same direction.
(Knowing how the Finale PDK works, it probably iterates from bottom to top note.)
Currently the PDK Framework does not seem to offer a better option.

@ entry (FCNoteEntry)
@ note_index (number) the zero-based index
]]
function note_entry.calc_note_at_index(entry, note_index)
    local x = 0
    for note in each(entry) do
        if x == note_index then
            return note
        end
        x = x + 1
    end
    return nil
end

--[[
% stem_sign

This is useful for many x,y positioning fields in Finale that mirror +/-
based on stem direction.

@ entry (FCNoteEntry)
: (number) 1 if upstem, -1 otherwise
]]
function note_entry.stem_sign(entry)
    if entry:CalcStemUp() then
        return 1
    end
    return -1
end

--[[
% duplicate_note

@ note (FCNote)
: (FCNote | nil) reference to added FCNote or `nil` if not success
]]
function note_entry.duplicate_note(note)
    local new_note = note.Entry:AddNewNote()
    if nil ~= new_note then
        new_note.Displacement = note.Displacement
        new_note.RaiseLower = note.RaiseLower
        new_note.Tie = note.Tie
        new_note.TieBackwards = note.TieBackwards
    end
    return new_note
end

--[[
% delete_note

Removes the specified FCNote from its associated FCNoteEntry.

@ note (FCNote)
: (boolean) true if success
]]
function note_entry.delete_note(note)
    local entry = note.Entry
    if nil == entry then
        return false
    end

    -- attempt to delete all associated entry-detail mods, but ignore any failures
    finale.FCAccidentalMod():EraseAt(note)
    finale.FCCrossStaffMod():EraseAt(note)
    finale.FCDotMod():EraseAt(note)
    finale.FCNoteheadMod():EraseAt(note)
    finale.FCPercussionNoteMod():EraseAt(note)
    finale.FCTablatureNoteMod():EraseAt(note)
    if finale.FCTieMod then -- added in RGP Lua 0.62
        finale.FCTieMod(finale.TIEMODTYPE_TIESTART):EraseAt(note)
        finale.FCTieMod(finale.TIEMODTYPE_TIEEND):EraseAt(note)
    end

    return entry:DeleteNote(note)
end

--[[
% calc_spans_number_of_octaves

Calculates the numer of octaves spanned by a chord (considering only staff positions, not accidentals).

@ entry (FCNoteEntry) the entry to calculate from
: (number) of octaves spanned
]]
function note_entry.calc_spans_number_of_octaves(entry)
    local top_note = entry:CalcHighestNote(nil)
    local bottom_note = entry:CalcLowestNote(nil)
    local displacement_diff = top_note.Displacement - bottom_note.Displacement
    local num_octaves = math.ceil(displacement_diff / 7)
    return num_octaves
end

--[[
% add_augmentation_dot

Adds an augentation dot to the entry. This works even if the entry already has one or more augmentation dots.

@ entry (FCNoteEntry) the entry to which to add the augmentation dot
]]
function note_entry.add_augmentation_dot(entry)
    -- entry.Duration = entry.Duration | (entry.Duration >> 1) -- For Lua 5.3 and higher
    entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
end

--[[
% get_next_same_v

Returns the next entry in the same V1 or V2 as the input entry.
If the input entry is V2, only the current V2 launch is searched.
If the input entry is V1, only the current measure and layer is searched.

@ entry (FCNoteEntry) the entry to process
: (FCNoteEntry) the next entry or `nil` in none
]]
function note_entry.get_next_same_v(entry)
    local next_entry = entry:Next()
    if entry.Voice2 then
        if (nil ~= next_entry) and next_entry.Voice2 then
            return next_entry
        end
        return nil
    end
    if entry.Voice2Launch then
        while (nil ~= next_entry) and next_entry.Voice2 do
            next_entry = next_entry:Next()
        end
    end
    return next_entry
end

--[[
% hide_stem

Hides the stem of the entry by replacing it with Shape 0.

@ entry (FCNoteEntry) the entry to process
]]
function note_entry.hide_stem(entry)
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



---
function bariolage()
    local region = finenv.Region()
    layer.copy(region, 1, 2)
    local layer1_ct = 1
    local layer2_ct = 1
    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() then
            if entry.LayerNumber == 1 then
                if entry:CalcBeamedGroupEnd() then
                    entry.Visible = false
                end
                if layer1_ct % 2 == 0 then
                    print()
                    note_entry.hide_stem(entry)
                end
                layer1_ct = layer1_ct + 1
            elseif entry.LayerNumber == 2 then
                if entry:GetBeamBeat() then
                    entry.Visible = false
                end
                if layer2_ct % 2 == 1 then
                    print()
                    note_entry.hide_stem(entry)
                end
                entry:SetPlayback(false)
                layer2_ct = layer2_ct + 1
            end
        end
    end
end -- function bariolage

bariolage()

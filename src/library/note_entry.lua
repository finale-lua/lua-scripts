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
    finale.FCPerformanceMod():EraseAt(note)
    if finale.FCTieMod then -- added in RGP Lua 0.62
        finale.FCTieMod(finale.TIEMODTYPE_TIESTART):EraseAt(note)
        finale.FCTieMod(finale.TIEMODTYPE_TIEEND):EraseAt(note)
    end

    return entry:DeleteNote(note)
end

--[[
% make_rest

Deletes all notes and turns the note_entry into a floating rest. This function also
deletes any attached entry details such as articulations and special tools edits.

@ entry (FCNoteEntry)
: (boolean) success
]]

function note_entry.make_rest(entry)
    local articulations = entry:CreateArticulations()
    for articulation in each(articulations) do
        articulation:DeleteData()
    end
    if entry:IsNote() then
        while entry.Count > 0 do
            note_entry.delete_note(entry:GetItemAt(0)) -- cleans up note details
        end
    end
    entry:MakeRest()
    return true -- for now, always success. we can get fancier if we need to.
end

--[[
% calc_pitch_string

Calculates the pitch string of a note for display purposes.

@ note (FCNote)
: (string) display string for note
]]

function note_entry.calc_pitch_string(note)
    local pitch_string = finale.FCString()
    local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
    local key_signature = cell:GetKeySignature()
    note:GetString(pitch_string, key_signature, false, false)
    return pitch_string
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
% remove_augmentation_dot

Removes an augentation dot from the entry. This does nothing if the entry has no augmentation dots.

@ entry (FCNoteEntry) the entry to which to add the augmentation dot
: (boolean) true if the entry was modified, otherwise false
]]
function note_entry.remove_augmentation_dot(entry)
    if entry.Duration <= 0 then
        return false
    end
    local lowest_order_bit = 1
    if bit32.band(entry.Duration, lowest_order_bit) == 0 then -- if entry.Duration & lowest_order_bit then
        -- lowest_order_bit = (entry.Duration & (entry.Duration - 1)) ~ entry.Duration -- For Lua 5.3 and higher
        lowest_order_bit = bit32.bxor(bit32.band(entry.Duration, entry.Duration - 1), entry.Duration)
    end
    -- local new_value = entry.Duration & ~lowest_order_bit -- For Lua 5.3 and higher
    local new_value = bit32.band(entry.Duration, bit32.bnot(lowest_order_bit))
    if new_value ~= 0 then
        entry.Duration = new_value
        return true
    end
    return false
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

--[[
% rest_offset

Confirms the entry is a rest then offsets it from the staff rest "center" position. 

@ entry (FCNoteEntry) the entry to process
@ offset (number) offset in half spaces
: (boolean) true if success
]]
function note_entry.rest_offset(entry, offset)
    if entry:IsNote() then
        return false
    end
    local rest_prop = "OtherRestPosition"
    if entry.Duration >= finale.BREVE then
        rest_prop = "DoubleWholeRestPosition"
    elseif entry.Duration >= finale.WHOLE_NOTE then
        rest_prop = "WholeRestPosition"
    elseif entry.Duration >= finale.HALF_NOTE then
        rest_prop = "HalfRestPosition"
    end
    entry:MakeMovableRest()
    local rest = entry:GetItemAt(0)
    local curr_staffpos = rest:CalcStaffPosition()
    local staff_spec = finale.FCCurrentStaffSpec()
    staff_spec:LoadForEntry(entry)
    local total_offset = staff_spec[rest_prop] + offset - curr_staffpos
    entry:SetRestDisplacement(entry:GetRestDisplacement() + total_offset)
    return true
end

return note_entry

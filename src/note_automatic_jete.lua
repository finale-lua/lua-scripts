function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 14, 2020"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.Notes = [[
        This script automatically creates a “jeté”-style bowing effect. These mimic examples shown on p. 404 of “Behind Bars"
        by Elaine Gould. For the best results with staccato dots, use an articulation with “Avoid Staff Lines” unchecked.

        By default, the script searches for articulations using the '.' character (ASCII code 46) for non-SMuFL fonts and
        the SMuFL dot character (UTF code 0xe4a2) for SMuFL fonts. This character must be the Main Character in Finale's
        articulation definition dialog. You can override this to search for a different character code using a
        configuration file. (See below.)

        To use the script, you enter the notes you want to display, and it removes the noteheads in between the first
        and last notehead, adjusts any staccato dots, and adds a gliss mark (tab slide) between the first and last notes,
        unless there is one already there. If you want a slur as well, add it manually before or after running the script.
        
        The steps to use this script are:

        1. Add the notes you want to display, with or without accidentals. Normally you choose notes with noteheads
        that follow a straight-line path as closely as possible. They can be reduced size or grace notes. 
        2. Add staccato dots if you want them.
        3. Add a slur if you want it.
        4. Run the script on the pattern you just entered.

        The script takes the following actions:

        1. Searches for a selected pattern, skipping rests at the beginning and stopping at the first rest it encounters.
        2. Hides the noteheads on all but the first and (optionally) last entry.
        3. Hides accidentals on any noteheads that were hidden.
        4. Aligns the staccato dots in a straight line path. (The path may not be exactly straight
            if the articulation is set to avoid staff lines.)
        5. Adds a gliss mark (tab slide) between the first and last notes, if one does not already exist.
            If you have entered parallel chords, it adds a gliss mark for each note in the chord.
        
        By default, the script does not hide the last selected note (or any accidentals it may have). You can override
        this behavior with a configuration file or if you are using RGP Lua 0.59 or higher, you can cause the script
        to hide the last note by holding down Shift, Option (Mac), or Alt (Win) when you invoke it.

        To use a configuration file:

        1. If it does not exist, create a subfolder called `script_settings` in the folder where this script resides.
        2. Create a text file in the `script_settings` folder called `note_automatic_jete.config.txt`.
        3. Add either or both of the following lines to it.

        ```
        dot_character = 46           -- This may be any character code you wish to search use, including a SMuFL character code.
        hide_last_note = true        -- This value will be reversed if you hold down a modifier key when invoking the script. (See above.)
        ```
    ]]
    return "Automatic Jeté", "Automatic Jete", -- JW Lua has trouble with non-ascii chars in the Undo string, so eliminate the accent on "é" for Undo
           "Add gliss. marks, hide noteheads, and adjust staccato marks as needed for jeté bowing."
end

-- The goal of this script is to automate jeté bowing notation as given in Gould, Elaine, "Behind Bars", p. 404
-- For the best results with staccato dots, use an articulation with "Avoid Staff Lines" unchecked.

local note_entry = require("library.note_entry")
local articulation = require("library.articulation")
local configuration = require("library.configuration")
local library = require("library.general_library")

local max_layers = 4            -- this should be in the PDK, but for some reason isn't

local config = {
    dot_character = 46,         -- ascii code for '.'
    hide_last_note = false
}

if library.is_font_smufl_font() then
    config.dot_character = 0xe4a2 -- SMuFL staccato dot above, which must be the "Main Character" in the Articulation Definition
end

configuration.get_parameters("note_automatic_jete.config.txt", config)

if finenv.QueryInvokedModifierKeys then
    if finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT) then
        config.hide_last_note = not config.hide_last_note
    end
end

function add_gliss_line_if_needed(start_note, end_note)
    -- search for existing
    local smartshapeentrymarks = finale.FCSmartShapeEntryMarks(start_note.Entry)
    smartshapeentrymarks:LoadAll()
    for ssem in each(smartshapeentrymarks) do
        if ssem:CalcLeftMark() then
            local ss = finale.FCSmartShape()
            if ss:Load(ssem.ShapeNumber) then
                if ss:IsTabSlide() then
                    local rightseg = ss:GetTerminateSegmentRight()
                    if (rightseg.EntryNumber == end_note.Entry.EntryNumber) and (rightseg.NoteID == end_note.NoteID) then
                        return ss -- return the found smart shape, in case caller needs it
                    end
                end
            end
        end
    end
    -- not found, so create new
    local smartshape = finale.FCSmartShape()
    smartshape.ShapeType = finale.SMARTSHAPE_TABSLIDE
    smartshape.EntryBased = true
    smartshape.BeatAttached= false
    smartshape.MakeHorizontal = false
    smartshape.PresetShape = true
    smartshape.Visible = true
    smartshape:SetSlurFlags(false)
    smartshape:SetEntryAttachedFlags(true)
    local leftseg = smartshape:GetTerminateSegmentLeft()
    leftseg.Measure = start_note.Entry.Measure
    leftseg.Staff = start_note.Entry.Staff
    leftseg:SetEntry(start_note.Entry)
    leftseg:SetNoteID(start_note.NoteID)
    local rightseg = smartshape:GetTerminateSegmentRight()
    rightseg.Measure = end_note.Entry.Measure
    rightseg.Staff = end_note.Entry.Staff
    rightseg:SetEntry(end_note.Entry)
    rightseg:SetNoteID(end_note.NoteID)
    if smartshape:SaveNewEverything(start_note.Entry, end_note.Entry) then
        return smartshape
    end
    return nil
end

-- return found articulation and point position
-- if we are finding by the character, it must be note-side
function find_staccato_articulation(entry, find_by_def_id)
    find_by_def_id = find_by_def_id or 0
    local artics = entry:CreateArticulations()
    for artic in each(artics) do
        local fcpoint = finale.FCPoint(0, 0)
        if artic:CalcMetricPos(fcpoint) then
            if find_by_def_id == artic.ID then
                return artic, fcpoint
            elseif 0 == find_by_def_id then
                local artic_def = artic:CreateArticulationDef()
                if nil ~= artic_def then
                    if config.dot_character == artic_def.MainSymbolChar then
                        if articulation.is_note_side(artic, fcpoint) then
                            return artic, fcpoint
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

function note_automatic_jete()
    local sel_region = finenv.Region() -- total selected region
    for slot = sel_region.StartSlot, sel_region.EndSlot do
        -- get selected region for this staff
        local staff_region = finale.FCMusicRegion()
        staff_region:SetCurrentSelection()
        staff_region.StartSlot = slot
        staff_region.EndSlot = slot
        for layer = 1, max_layers do
            -- find first and last entries
            local first_entry_num = nil
            local last_entry_num = nil
            local entries = {}
            local last_meas = nil
            for entry in eachentry(staff_region) do
                if entry.LayerNumber == layer then
                    -- break if we skipped a measure
                    if last_meas and (last_meas < (entry.Measure - 1)) then
                        break
                    end
                    last_meas = entry.Measure
                    local is_rest = entry:IsRest()
                    -- break on rests, but only if we've found a non-rest
                    if is_rest and (nil ~= first_entry_num) then
                        break
                    end
                    if not is_rest then
                        if nil == first_entry_num then
                            first_entry_num = entry.EntryNumber
                        end
                        last_entry_num = entry.EntryNumber
                        entries[entry.EntryNumber] = entry
                    end
                end
            end
            if first_entry_num ~= last_entry_num then
                local lpoint = nil
                local rpoint = nil
                local dot_artic_def = 0
                for entry in eachentrysaved(staff_region) do    -- don't use pairs(entries) because we need to save the entries on this pass
                    if nil ~= entries[entry.EntryNumber] then
                        if entry.EntryNumber == first_entry_num then
                            local last_entry = entries[last_entry_num]
                            if nil ~= last_entry then
                                local x = 0
                                for note in each(entry) do
                                    local last_note = note_entry.calc_note_at_index(last_entry, x)
                                    if nil ~= note then
                                        add_gliss_line_if_needed(note, last_note)
                                    end
                                    x = x + 1
                                end
                                -- get first and last points for artic defs
                                local lartic = nil
                                lartic, lpoint = find_staccato_articulation(entry)
                                if nil ~= lartic then
                                    dot_artic_def = lartic.ID
                                    _, rpoint = find_staccato_articulation(last_entry, dot_artic_def)
                                end
                            end
                        elseif (entry.EntryNumber ~= last_entry_num) or config.hide_last_note then
                            entry.LedgerLines = false
                            entry:SetAccidentals(false)
                            for note in each(entry) do
                                note.Accidental = false
                                note.AccidentalFreeze = true
                                local nm = finale.FCNoteheadMod()
                                nm:SetNoteEntry(entry)
                                nm:LoadAt(note)
                                nm.CustomChar = string.byte(" ")
                                nm:SaveAt(note)
                            end
                        end
                    end
                end
                -- shift dot articulations, if any
                if lpoint and rpoint and (lpoint.X ~= rpoint.X) then -- prevent divide-by-zero, but it should not happen if we're here
                    local linear_multplier = (rpoint.Y - lpoint.Y) / (rpoint.X - lpoint.X)
                    local linear_constant = (rpoint.X*lpoint.Y - lpoint.X*rpoint.Y) / (rpoint.X - lpoint.X)
                    finale.FCNoteEntry.MarkEntryMetricsForUpdate()
                    for key, entry in pairs(entries) do
                        if (entry.EntryNumber ~= first_entry_num) and (entry.EntryNumber ~= last_entry_num) then
                            local artic, arg_point = find_staccato_articulation(entry, dot_artic_def)
                            if nil ~= artic then
                                local new_y = linear_multplier*arg_point.X + linear_constant -- apply linear equation
                                local old_vpos = artic.VerticalPos
                                artic.VerticalPos = artic.VerticalPos - (note_entry.stem_sign(entry) * (math.floor(new_y + 0.5) - arg_point.Y))
                                artic:Save()
                            end
                        end
                    end
                end
            end
        end
    end
end

note_automatic_jete()

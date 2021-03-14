function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 14, 2020"
    finaleplugin.CategoryTags = "Note"
    return "Automatic Jeté", "Automatic Jete", -- JW Lua has trouble with non-ascii chars in the Undo string, so eliminate accent on "é"
           "Add gliss. marks, hide noteheads, and adjust staccato marks as needed for jeté bowing."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local note_entry = require("library.note_entry")

function add_gliss_line_if_needed(start_note, end_note)
    -- search for existing
    local smartshapeentrymarks = finale.FCSmartShapeEntryMarks(start_note.Entry)
    smartshapeentrymarks:LoadAll()
    for ssem in each(smartshapeentrymarks) do
        if ssem:CalcLeftMark() then
            local ss = finale.FCSmartShape()
            if ss:Load(ssem.ShapeNumber) then
                if (ss.ShapeType == finale.SMARTSHAPE_TABSLIDE) then
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
    smartshape:SetSlurFlags( false )
    smartshape:SetEntryAttachedFlags( true )
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

function note_automatic_jete()
    local sel_region = finenv.Region() -- total selected region
    for slot = sel_region.StartSlot, sel_region.EndSlot do
        -- get selected region for this staff
        local staff_region = finale.FCMusicRegion()
        staff_region:SetCurrentSelection()
        staff_region.StartSlot = slot
        staff_region.EndSlot = slot
        -- find first and last slots
        local first_entry_num = nil
        local last_entry_num = nil
        for entry in eachentry(staff_region) do
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
            end
        end
        if first_entry_num ~= last_entry_num then
            for entry in eachentrysaved(staff_region) do
                if entry.EntryNumber == first_entry_num then
                    local last_entry = entry
                    while (nil ~= last_entry) and (last_entry.EntryNumber ~= last_entry_num) do
                        last_entry = last_entry:Next()
                    end
                    if nil ~= last_entry then
                        local x = 0
                        for note in each(entry) do
                            local last_note = note_entry.calc_note_at_index(last_entry, x)
                            if nil ~= note then
                                add_gliss_line_if_needed(note, last_note)
                            end
                            x = x + 1
                        end
                    end
                elseif entry.EntryNumber ~= last_entry_num then
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
    end
end

note_automatic_jete()

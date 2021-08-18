function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 8, 2021"
    finaleplugin.CategoryTags = "Note"
    return "Delete Duplicate Noteheads", "Delete Duplicate Noteheads", "Removes duplicate noteheads from chords and adjusts ties as needed."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local note_entry = require("library.note_entry")

-- This script was a request from the Facebook Finale Powerusers group.
-- I believe it is mainly useful for cleaning up after a MIDI file import.

function notehead_delete_duplicates()
    for entry in eachentrysaved(finenv.Region()) do
        local note_list = {}
        for note in each(entry) do
            local pitch = bit32.bor(note.RaiseLower, bit32.lshift(note.Displacement, 16))
            if nil == note_list[pitch] then
                note_list[pitch] = note
            else
                if note.Tie then
                    note_list[pitch].Tie = true
                end
                if note.TieBackwards then
                    note_list[pitch].TieBackwards = true
                end
                if note.AccidentalFreeze then
                    note_list[pitch].AccidentalFreeze = true
                    note_list[pitch].Accidental = note.AccidentalFreeze
                    if note.AccidentalParentheses then
                        note_list[pitch].AccidentalParentheses = true
                    end
                end
                note_entry.delete_note(note)
            end
        end
    end    
end

notehead_delete_duplicates()

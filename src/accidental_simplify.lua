function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "January 9, 2024"
    finaleplugin.CategoryTags = "Accidental"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Simplify accidentals", "Simplify accidentals", "Removes all double sharps and flats by respelling them"
end

local transposition = require("library.transposition")
local json = require("cjson")
local lfs = require("lfs")
local luaosutils = require("luaosutils")
-- local foo = require("foo")
    --      local bar = require("bar")


function accidentals_simplify()
    for entry in eachentrysaved(finenv.Region()) do
        local measure_number = entry.Measure
        local staff_number = entry.Staff
        local cell = finale.FCCell(measure_number, staff_number)
        local key_signature = cell:GetKeySignature()
        
        for note in transposition.each_to_transpose(entry) do
            if note.RaiseLower ~= 0 then
                -- Use note_string rather than note.RaiseLower because
                -- with key signatures, note.RaiseLower returns the alteration
                -- from the key signature, not the actual accidental.
                -- For instance, in the key of A, a Gb has a RaiseLower of -2
                -- even though Gb is not a double flat.

                local fs_note_string = finale.FCString()
                note:GetString(fs_note_string, key_signature, false, false)
                local note_string = fs_note_string:GetLuaString()

                -- checking for 'bb' and '##' will also match triple sharps and flats
                if string.match(note_string, "bb") or string.match(note_string, "##") then
                    transposition.enharmonic_transpose(note, note.RaiseLower)
                    transposition.simplify_spelling(note)
                end
            end
        end
    end
end

accidentals_simplify()

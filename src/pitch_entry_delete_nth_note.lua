function plugindef()
  finaleplugin.RequireSelection = true
  finaleplugin.Author = "Jacob Winkler, Nick Mazuk"
  finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
  finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
  finaleplugin.Version = "1.0"
  finaleplugin.Date = "2024-01-26"
  finaleplugin.CategoryTags = "Pitch"
  finaleplugin.Notes = [[
USING THE 'DELETE Nth NOTE' SCRIPT

This script allows the user to select a note within a chord to delete, as numbered form the top. Entering "1" will delete the top note, "2" will delete the 2nd note from the top, entering "3" the third, and so on.

This script also replicates Nick Mazuk's functions for deleting or keeping the top or bottom note in a chord.

To access these functions, enter the following commands:

"top" - Deletes the top note in the chord
"bottom" or "btm" - Deletes the bottom note in the chord
"keeptop" - Keeps the top note in the chord, deleting all others
"keepbottom" or "keepbtm" - Keeps the bottom note in the chord, deleting all others.
]]
  return "Chord: Delete nth note", "Chord: Delete nth note", "Deletes a user selected note"
end

local note_entry = require("library.note_entry")
local library = require("library.general_library")

function pitch_entry_delete_n_note(n)
  for entry in eachentrysaved(finenv.Region()) do
    if (entry.Count >= 2) then
      local target = entry.Count - n
      local i = 0
      for note in each(entry) do
        if i == target then
          note_entry.delete_note(note)
        end
        i = i + 1
      end
    end
  end
end

function pitch_entry_delete_bottom_note()
  for entry in eachentrysaved(finenv.Region()) do
    if (entry.Count >= 2) then
      local bottom_note = entry:CalcLowestNote(nil)
      note_entry.delete_note(bottom_note)
    end
  end
end

function pitch_entry_keep_bottom_note()
  for entry in eachentrysaved(finenv.Region()) do
    while (entry.Count >= 2) do
      local top_note = entry:CalcHighestNote(nil)
      note_entry.delete_note(top_note)
    end
  end
end

function pitch_entry_keep_top_note()
  for entry in eachentrysaved(finenv.Region()) do
    while (entry.Count >= 2) do
      local bottom_note = entry:CalcLowestNote(nil)
      note_entry.delete_note(bottom_note)
    end
  end
end

local n = library.simple_input("Delete nth note", "Note to delete (numbered from top)") or 0

if n == "top" then
  n = 1
  pitch_entry_delete_n_note(n)
elseif n == "bottom" or n == "btm" then
  pitch_entry_delete_bottom_note()
elseif n == "keeptop" then
  pitch_entry_keep_top_note()
elseif n == "keepbottom" or n == "keepbtm" then
  pitch_entry_keep_bottom_note()
else
  pitch_entry_delete_n_note(n)
end

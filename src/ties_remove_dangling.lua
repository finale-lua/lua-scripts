function plugindef()
  -- This function and the 'finaleplugin' namespace
  -- are both reserved for the plug-in definition.
  finaleplugin.Author = "Jacob Winkler"
  finaleplugin.Copyright = "2022"
  finaleplugin.Version = "1.0.1"
  finaleplugin.Date = "2022-08-26"
  finaleplugin.RequireSelection = true
  finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
  return "Ties: Remove Dangling", "Ties: Remove Dangling", "Removes dangling ties (ties that go nowhere)."
end

local tie = require("library.tie")

local music_region = finale.FCMusicRegion()
music_region:SetCurrentSelection()

for working_staff = music_region:GetStartStaff(), music_region:GetEndStaff() do
  for layer_num = 0, 3, 1 do
    local current_note
    local note_entry_layer = finale.FCNoteEntryLayer(layer_num, working_staff, music_region.StartMeasure, music_region.EndMeasure)
    note_entry_layer:Load()
    for index = 0, note_entry_layer.Count-1, 1 do
      local entry = note_entry_layer:GetRegionItemAt(index, music_region)
      if entry and entry:IsTied() then
          for note in each(entry) do
              local tie_must_exist = true
              local tied_note = tie.calc_tied_to(note, tie_must_exist)
              if not tied_note then
                  note.Tie = false
              end
          end
      end
    end
    note_entry_layer:Save()
  end
end
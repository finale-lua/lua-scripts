function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "2022-09-04"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.AdditionalMenuOptions = [[
    Ties: Replace Dangling w/Slurs
    ]]
    finaleplugin.AdditionalUndoText = [[
    Ties: Replace Dangling w/Slurs
    ]]
    finaleplugin.AdditionalDescriptions = [[
    Removes dangling ties and replaces them with slurs
    ]]
    finaleplugin.AdditionalPrefixes = [[
    replace_with_slur = true
    ]]
      finaleplugin.Notes = [[
      TIES: REMOVE DANGLING
      
      This script will search for 'dangling ties' - ties that go to rests rather than other notes - and either remove them or replace them with slurs.
      ]]
    return "Ties: Remove Dangling", "Ties: Remove Dangling", "Removes dangling ties (ties that go nowhere)."
end

replace_with_slur = replace_with_slur or false

local tie = require("library.tie")
local smartshape = require("library.smartshape")

local music_region = finale.FCMusicRegion()
music_region:SetFullDocument()

for working_staff = music_region:GetStartStaff(), music_region:GetEndStaff() do
    for layer_num = 0, 3, 1 do
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
                        if replace_with_slur then
                            local next_entry = note_entry_layer:GetRegionItemAt(index + 1, music_region)
                            if next_entry then
                                smartshape.add_entry_based_smartshape(entry, next_entry)
                            end
                        end
                    end
                end
            end
        end
        note_entry_layer:Save()
    end
end
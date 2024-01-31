function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Jacob Winkler" 
    finaleplugin.Copyright = "©2019 Jacob Winkler"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "11/02/2019"
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/note_cluster_indeterminate.hash"
    return "Cluster - Indeterminate", "Cluster - Indeterminate", "Creates Indeterminate Clusters"
end
local distance_preferences = finale.FCDistancePrefs()
distance_preferences:Load(1)
local size_preferences = finale.FCSizePrefs()
size_preferences:Load(1)
function cluster_indeterminate()
    for note_entry in eachentrysaved(finenv.Region()) do
        if note_entry:IsNote() and note_entry.Count > 1 then
            local max = note_entry.Count
            local n = 1
            local dot = finale.FCDotMod()
            local lowest_note = note_entry:CalcLowestNote(nil)
            local lowest_note_pos = lowest_note:CalcStaffPosition()
            local low_space = lowest_note_pos % 2
            local low_span = 0
            local adjust_dots = false

            local i = 1
            for note in each(note_entry) do
                local stem_direction = note_entry:CalcStemUp()
                local right_side = note:CalcRightsidePlacement()
                if (stem_direction == true and right_side == true) then
                    adjust_dots = true
                end
                if i == 2 then
                    low_span = note:CalcStaffPosition() - lowest_note_pos
                end
                i = i + 1
            end

            for note in each(note_entry) do
                local stem_direction = note_entry:CalcStemUp()
                local notehead = finale.FCNoteheadMod()
                notehead:EraseAt(note)
                notehead:SetUseCustomFont(true)
                notehead.FontName = "Engraver Font Set"
                local notehead_offset = 35
                local rightside = note:CalcRightsidePlacement()

                if note_entry.Duration < 2048 then
                    notehead.CustomChar = 242

                    if stem_direction == true and rightside == true then
                        notehead.HorizontalPos = -notehead_offset
                    end

                    if stem_direction == false and rightside == false then
                        notehead.HorizontalPos = notehead_offset
                    end
                end
                if (note_entry.Duration >= 2048) and (note_entry.Duration < 4096) then
                    if n == 1 then
                        notehead.CustomChar = 201
                    elseif n == max then
                        notehead.CustomChar = 59
                    else
                        notehead.CustomChar = 58
                    end

                    if stem_direction == true and rightside == true then
                        notehead.HorizontalPos = -notehead_offset
                    end

                    if stem_direction == false and rightside == false then
                        notehead.HorizontalPos = notehead_offset
                    end
                end
                if (note_entry.Duration >= 4096) then
                    if n == 1 then
                        notehead.CustomChar = 201
                    elseif n == max then
                        notehead.CustomChar = 59
                    else
                        notehead.CustomChar = 58
                    end
                    notehead_offset = 32
                    if stem_direction == true and rightside == true then
                        notehead.HorizontalPos = -notehead_offset
                    end

                    if stem_direction == false and rightside == false then
                        notehead.HorizontalPos = notehead_offset
                    end
                end
                if n > 1 and n < max then
                    note.Tie = false
                end

                if note_entry:IsDotted() then
                    local horizontal = 0
                    if adjust_dots == true then
                        horizontal = -notehead_offset
                    end
                    if n == 1 and low_span <= 1 and low_space == 1 then
                        dot.VerticalPos = 24
                    elseif n > 1 and n < max then

                        dot.VerticalPos = 10000
                        dot.HorizontalPos = 10000
                    else
                        dot.VerticalPos = 0
                    end
                    dot.HorizontalPos = horizontal
                    dot:SaveAt(note)
                end
                note.AccidentalFreeze = true
                note.Accidental = false
                notehead:SaveAt(note)
                n = n + 1
            end
            note_entry.LedgerLines = false
        end
    end
end
cluster_indeterminate()

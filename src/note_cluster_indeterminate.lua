function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Jacob Winkler" -- With help & advice from CJ Garcia, Nick Mazuk, and Jan Angermüller. Thanks guys!
    finaleplugin.Copyright = "©2019 Jacob Winkler"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "11/02/2019"
    return "Cluster - Indeterminate", "Cluster - Indeterminate", "Creates Indeterminate Clusters"
end

local distance_preferences = finale.FCDistancePrefs()
distance_preferences:Load(1)
local size_preferences = finale.FCSizePrefs()
size_preferences:Load(1)
local stem_thickness = size_preferences.StemLineThickness -- stem thickness in EFIXes
stem_thickness = stem_thickness / 64 -- This converts EFIX to EVPU

function cluster_indeterminate()
    for note_entry in eachentrysaved(finenv.Region()) do
        -- if noteentry:IsRest() == true then goto continue end
        if note_entry:IsNote() and note_entry.Count > 1 then
            local max = note_entry.Count
            local n = 1
            local dot = finale.FCDotMod()
            local lowest_note = note_entry:CalcLowestNote(nil)
            local lowest_note_pos = lowest_note:CalcStaffPosition()
            local low_space = lowest_note_pos % 2 -- 0 if lowest note is on a line, 1 if on a space
            local low_span = 0
            local adjust_dots = false

            -- Quick calculation to see if dots need to move...
            local i = 1
            for note in each(note_entry) do
                local stem_direction = note_entry:CalcStemUp()
                local right_side = note:CalcRightsidePlacement()
                if (stem_direction == true and right_side == true) then
                    adjust_dots = true
                end
                if i == 2 then
                    low_span = note:CalcStaffPosition() - lowest_note_pos
                end -- end "if i == 2..."
                i = i + 1
            end -- end "for note..."
            -- Process the notes
            for note in each(note_entry) do
                -- Calculate stem direction
                local stem_direction = note_entry:CalcStemUp()
                -- Setup notehead variable, including fonts
                local notehead = finale.FCNoteheadMod()
                notehead:EraseAt(note)
                notehead:SetUseCustomFont(true)
                notehead.FontName = "Engraver Font Set"
                local notehead_offset = 35 -- 35 is a good value for quarter/half notes in Maestro font. Whole notes need to be larger...
                local rightside = note:CalcRightsidePlacement()

                -- Thank you to CJ Garcia for the duration logic!

                if note_entry.Duration < 2048 then -- for notes less than half notes
                    notehead.CustomChar = 242
                    -- For stems up = true, notes to the right are 'secondary' --> move them to the left
                    if stem_direction == true and rightside == true then
                        notehead.HorizontalPos = -notehead_offset
                    end
                    -- For stems down, notes to the left are 'secondary' --> move them to the right
                    if stem_direction == false and rightside == false then
                        notehead.HorizontalPos = notehead_offset
                    end
                end -- end of notes less than half notes

                if (note_entry.Duration >= 2048) and (note_entry.Duration < 4096) then -- for half notes
                    if n == 1 then
                        notehead.CustomChar = 201
                    elseif n == max then
                        notehead.CustomChar = 59
                    else
                        notehead.CustomChar = 58
                    end
                    -- For stems up = true, notes to the right are 'secondary' --> move them to the left
                    if stem_direction == true and rightside == true then
                        notehead.HorizontalPos = -notehead_offset
                    end
                    -- For stems down, notes to the left are 'secondary' --> move them to the right
                    if stem_direction == false and rightside == false then
                        notehead.HorizontalPos = notehead_offset
                    end
                end -- end of half notes

                if (note_entry.Duration >= 4096) then -- for whole notes
                    if n == 1 then
                        notehead.CustomChar = 201
                    elseif n == max then
                        notehead.CustomChar = 59
                    else
                        notehead.CustomChar = 58
                    end
                    notehead_offset = 32 -- Slightly lower value for whole note... Maybe because no stem?
                    if stem_direction == true and rightside == true then
                        notehead.HorizontalPos = -notehead_offset
                    end
                    -- For stems down, notes to the left are 'secondary' --> move them to the right
                    if stem_direction == false and rightside == false then
                        notehead.HorizontalPos = notehead_offset
                    end
                end -- end of whole notes

                if n > 1 and n < max then -- for all inner notes, set ties to off
                    note.Tie = false
                end -- end of for all inner notes

                --
                if note_entry:IsDotted() then
                    local horizontal = 0
                    if adjust_dots == true then
                        horizontal = -notehead_offset
                    end
                    if n == 1 and low_span <= 1 and low_space == 1 then
                        dot.VerticalPos = 24
                    elseif n > 1 and n < max then
                        -- local vert_offset = ((lowest_note_pos - note:CalcStaffPosition()) * 12 ) -- + dot:GetVerticalPos()/4
                        -- dot.VerticalPos = vert_offset
                        -- I believe 10000 is enough to move the dots off any page I can conceive of...
                        dot.VerticalPos = 10000
                        dot.HorizontalPos = 10000
                    else
                        dot.VerticalPos = 0
                    end -- end of "if..."
                    dot.HorizontalPos = horizontal
                    dot:SaveAt(note)
                end -- end if noteentry:IsDotted

                note.AccidentalFreeze = true
                note.Accidental = false
                notehead:SaveAt(note)

                -- print (n.." of "..max) -- Checking note order...
                n = n + 1
            end -- end "for note..."
            note_entry.LedgerLines = false
        end -- end "if noteentry:IsNote..."
        -- ::continue::
    end -- end "for noteentry..."
end

-- Activate!!!
cluster_indeterminate()

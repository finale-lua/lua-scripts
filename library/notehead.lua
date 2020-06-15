-- A collection of helpful JW Lua notehead scripts
-- Simply import this file to another Lua script to use any of these scripts
local notehead = {}

function notehead.change_shape(note, shape)
    local notehead = finale.FCNoteheadMod()
    notehead:EraseAt(newnote)

    if shape == "diamond" then
        notehead.CustomChar = 79
        notehead.Resize = 110
        local entry = note:GetEntry()
        if (entry:GetDuration() == 4096) then
            if (note:CalcStaffPosition() >= -5) then
                notehead.HorizontalPos = 5
            else
                notehead.HorizontalPos = -5
            end
        end
    end

    notehead:SaveAt(note)
end

return notehead

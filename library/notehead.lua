-- A collection of helpful JW Lua notehead scripts
-- Simply import this file to another Lua script to use any of these scripts
local notehead = {}

local config = {
    diamond_open                = 79,
    diamond_closed              = 79,   -- per Elaine Gould, use open diamond even on closed regular notes, but allow it to be overridden
    diamond_resize              = 110,
    diamond_whole_offset        = 5,
    diamond_breve_offset        = 14
}

-- use this func because CalcStemUp is not reliable for wholes or breves
-- also it's not reliable after transposition
local calc_stem_up = function(note)
    if note.Entry.FreezeStem then
        return note.Entry:CalcStemUp()
    end
    return (note:CalcStaffPosition() < -5) -- this works a lot of the time, and when it doesn't the user can use free-stem to make it right
end

function notehead.change_shape(note, shape)
    local notehead = finale.FCNoteheadMod()
    notehead:EraseAt(newnote)

    if shape == "diamond" then
        local entry = note:GetEntry()
        local offset = 0
        local notehead_char = config.diamond_open
        if entry.Duration >= finale.BREVE then
            offset = config.diamond_breve_offset
        elseif entry.Duration >= finale.WHOLE_NOTE then
            offset = config.diamond_whole_offset
        elseif entry.Duration < finale.HALF_NOTE then
            notehead_char = config.diamond_closed
        end
        if (0 ~= offset) then
            if calc_stem_up(note) then
                notehead.HorizontalPos = -1*offset
            else
                notehead.HorizontalPos = offset
            end
        end
        notehead.CustomChar = notehead_char
        notehead.Resize = config.diamond_resize
    end

    notehead:SaveAt(note)
end

return notehead

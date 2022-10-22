--[[
$module Notehead
]] --
local notehead = {}

local configuration = require("library.configuration")
local library = require("library.general_library")

local config = {
    diamond_open = 79,
    diamond_closed = 79, -- Maestro lacks alternate diamond shapes
    diamond_whole = 79,
    diamond_breve = 79,
    diamond_resize = 110,
    diamond_whole_offset = 5,
    diamond_breve_offset = 14,
    x_normal = 192,
    x_circled = 192, -- Maestro has no option for the "long" crossed notehead
    default_notehead = 207,
}

-- recognised names for noteheads
local notehead_shape_names = {
    x = true,
    diamond = true,
    guitar_diamond = true, -- diamonds are CLOSED for quarter note or shorter
}

-- Default to SMuFL characters for SMuFL font (without needing a config file)
if library.is_font_smufl_font() then
    config.diamond_closed = 0xe0e2
    config.diamond_open = 0xe0e1
    config.diamond_whole = 0xe0d8
    config.diamond_breve = 0xe0d7
    config.x_normal = 0xe0a9
    config.x_circled = 0xe0ec
    config.default_notehead = 0xe0a4
end

configuration.get_parameters("notehead.config.txt", config)

--[[
% change_shape

Changes the given notehead to a specified notehead descriptor string. Currently only supports "diamond".

@ note (FCNote)
@ shape (lua string)

: (FCNoteheadMod) the new notehead mod record created
]]
function notehead.change_shape(note, shape)
    local notehead = finale.FCNoteheadMod()
    notehead:EraseAt(note)
    shape = notehead_shape_names[shape] and shape or "default"

    if shape == "default" then
        notehead:ClearChar()
    else
        local entry = note:GetEntry()
        local offset = 0
        local resize = 100
        local notehead_char = config.default_notehead

        --  --------
        if string.find(shape, "diamond") then
            notehead_char = config.diamond_open
            resize = config.diamond_resize
            if entry.Duration >= finale.BREVE then
                offset = config.diamond_breve_offset
                notehead_char = config.diamond_breve
            elseif entry.Duration >= finale.WHOLE_NOTE then
                offset = config.diamond_whole_offset
                notehead_char = config.diamond_whole
            elseif entry.Duration < finale.HALF_NOTE and string.find(shape, "guitar") then
                notehead_char = config.diamond_closed
            end
        --  --------
        elseif shape == "x" then
            notehead_char = (entry.Duration >= finale.HALF_NOTE) and config.x_circled or config.x_normal
        end
        --  ALL DONE --
        notehead.CustomChar = notehead_char
        if resize ~= 100 then
            notehead.Resize = resize
        end
        if offset ~= 0 then
            if entry:CalcStemUp() then
                notehead.HorizontalPos = -1 * offset
            else
                notehead.HorizontalPos = offset
            end
        end
        notehead:SaveAt(note)
    end
end

return notehead

--[[
$module Notehead
]]

-- A collection of helpful JW Lua notehead scripts
-- Simply import this file to another Lua script to use any of these scripts
local notehead = {}

local configuration = require("library.configuration")
local library = require("library.general_library")

local config = {
    diamond_open                = 79,
    diamond_closed              = 79,   -- per Elaine Gould, use open diamond even on closed regular notes, but allow it to be overridden
    diamond_resize              = 110,
    diamond_whole_offset        = 5,
    diamond_breve_offset        = 14
}

-- Default to SMuFL characters for SMuFL font (without needing a config file)
if library.is_font_smufl_font() then
    config.diamond_open = 0xe0e1
    config.diamond_closed = 0xe0e1  -- (in config) override to 0xe0e2 for closest matching closed diamond if you want to disregard Elain Gould and use a closed notehead
end

configuration.get_parameters("notehead.config.txt", config)

--[[
% change_shape(note, shape)

Changes the given notehead to a specified notehead descriptor string. Currently only supports "diamond".

@ note (FCNote)
@ shape (lua string)

: (FCNoteheadMod) the new notehead mod record created
]]
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
            if entry:CalcStemUp() then
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

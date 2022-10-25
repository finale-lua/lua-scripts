--[[
$module Notehead
]] --
-- version cv0.51 2022/10/26

local notehead = {}
local configuration = require("library.configuration")
local library = require("library.general_library")

local config = {
    diamond = {
        quarter = { glyph = 79, size = 110 },
        half  = { glyph = 79, size = 110 },
        whole = { glyph = 79, size = 110, offset = 5 },
        breve = { glyph = 79, size = 110, offset = 14 },
    },
    diamond_guitar = {
        quarter = { glyph = 226, size = 110 },
        half  = { glyph = 79, size = 110 },
        whole = { glyph = 79, size = 110, offset = 5 },
        breve = { glyph = 79, size = 110, offset = 14 },
    },
    x = {
        quarter = { glyph = 192 },
        half  = { glyph = 192 },
        whole = { glyph = 192 },
        breve = { glyph = 192, size = 120 },
    },
    triangle = {     -- triangle "up" glyphs
        quarter = { glyph = 209 },
        half  = { glyph = 177 },
        whole = { glyph = 177 },
        breve = { glyph = 177 },
    },
    triangle_down = { -- special case!
        quarter = { glyph = 224 },
        half  = { glyph = 198 },
        whole = { glyph = 198 },
        breve = { glyph = 198 },
    },
    slash = {
        quarter = { glyph = 243 },
        half  = { glyph = 203 },
        whole = { glyph = 213 },
        breve = { glyph = 213 },
    },
    square = {
        quarter = { glyph = 208 },
        half  = { glyph = 173 },
        whole = { glyph = 194 },
        breve = { glyph = 221 },
    },
    wedge = {
        quarter = { glyph = 108 },
        half  = { glyph = 231 },
        whole = { glyph = 231, offset = -14 },
        breve = { glyph = 231, offset = -14 },
    },
    hidden = {
        quarter = { glyph = 202 },
        half  = { glyph = 202 },
        whole = { glyph = 202 },
        breve = { glyph = 202 },
    }
}

-- Default to SMuFL characters for SMuFL font (without needing a config file)
if library.is_font_smufl_font() then
    config = {
        diamond = {
            quarter = { glyph = 0xe0e1, size = 110 },
            half  = { glyph = 0xe0e1, size = 110 },
            whole = { glyph = 0xe0d8, size = 110 },
            breve = { glyph = 0xe0d7, size = 110 },
        },
        diamond_guitar = {
            quarter = { glyph = 0xe0e2, size = 110 },
            half  = { glyph = 0xe0e1, size = 110 },
            whole = { glyph = 0xe0d8, size = 110 },
            breve = { glyph = 0xe0d7, size = 110 },
        },
        x = {
            quarter = { glyph = 0xe0a9 },
            half  = { glyph = 0xe0ec },
            whole = { glyph = 0xe0ec },
            breve = { glyph = 0xe0b4, size = 120 },
        },
        triangle = {     -- triangle "up" glyphs
            quarter = { glyph = 0xe0be },
            half  = { glyph = 0xe0bd },
            whole = { glyph = 0xe0ef },
            breve = { glyph = 0xe0ed },
        },
        triangle_down = { -- special case ... triangle "down" glyphs
            quarter = { glyph = 0xe0c7 },
            half  = { glyph = 0xe0c6 },
            whole = { glyph = 0xe0f3 },
            breve = { glyph = 0xe0f1 },
        },
        slash = {
            quarter = { glyph = 0xe100 },
            half  = { glyph = 0xe103 },
            whole = { glyph = 0xe102 },
            breve = { glyph = 0xe10a },
        },
        square = {
            quarter = { glyph = 0xe934 },
            half  = { glyph = 0xe935 },
            whole = { glyph = 0xe937 },
            breve = { glyph = 0xe933 },
        },
        wedge = {
            quarter = { glyph = 0xe1c5 },
            half  = { glyph = 0xe1c8, size = 120 },
            whole = { glyph = 0xe1c4, size = 120, offset = -14 },
            breve = { glyph = 0xe1ca, size = 120, offset = -14 },
        },
        hidden = {
            quarter = { glyph = 0xe0a5 },
            half  = { glyph = 0xe0a5 },
            whole = { glyph = 0xe0a5 },
            breve = { glyph = 0xe0a5 },
        },
    }
end

configuration.get_parameters("notehead.config.txt", config)

--[[
% change_shape

Changes the given notehead to a specified notehead descriptor string. 

@ note (FCNote)
@ shape (lua string) or (number)

: (FCNoteheadMod) the new notehead mod record created
]]
function notehead.change_shape(note, shape)
    local notehead = finale.FCNoteheadMod()
    notehead:EraseAt(note)
    local notehead_char

    if type(shape) == "number" then -- specific character GLYPH requested, not notehead "family"
        notehead_char = shape
        shape = "number"
    elseif not config[shape] then
        shape = "default" -- unrecognised shape name or "default" requested
    end

    if shape == "default" then
        notehead:ClearChar()
    else
        local entry = note:GetEntry()
        local duration = entry.Duration
        local offset = 0
        local resize = 100

        if shape ~= "number" then -- "number" is a specific glyph that needs no further modification
            local note_type = "quarter"
            if duration >= finale.BREVE then
                note_type = "breve"
            elseif duration >= finale.WHOLE_NOTE then
                note_type = "whole"
            elseif duration >= finale.HALF_NOTE then
                note_type = "half"
            end

            local ref_table = config[shape][note_type]
            if shape == "triangle" and entry:CalcStemUp() then
                ref_table = config["triangle_down"][note_type]
            end
            notehead_char = ref_table.glyph
            if ref_table.size then
                resize = ref_table.size
            end
            if ref_table.offset then
                offset = ref_table.offset
            end
        end

        --  finished testing notehead family --
        notehead.CustomChar = notehead_char
        if resize ~= 100 then
            notehead.Resize = resize
        end
        if offset ~= 0 then
            notehead.HorizontalPos = (entry:CalcStemUp()) and (-1 * offset) or offset
        end
    end
    notehead:SaveAt(note)
end

return notehead

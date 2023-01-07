--[[
$module Notehead

User-created config file "notehead.config.txt" will overwrite any of the values in this file.
Store the file in a folder called "script_settings" in the same location as the calling script.

To change the shape (glyph) of a note, add to the config file a line of the form:
    config.diamond.quarter.glyph = 0xea07 -- (SMuFL character)
        OR
    config.diamond.quarter.glyph = 173 -- (non-SMuFL character)

To change the size of a specific shape add a line:
    config.diamond.half.size = 120
And for offset (horizontal - left/right):
    config.diamond.whole.offset = -5 -- (offset 5 EVPU to the left)

Note that many of the shapes assumed in this file don't exist in Maestro but only in proper SMuFL fonts.

version cv0.55 2022/11/01
]] --

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
    triangle = {
        -- change_shape() defaults to use "triangle_down" glyphs on "triangle" up-stems
        -- use shape = "triangle_up" to force all up glyphs
        -- use shape = "triangle_down" to force all down glyphs
        quarter = { glyph = 209 },
        half  = { glyph = 177 },
        whole = { glyph = 177 },
        breve = { glyph = 177 },
    },
    triangle_down = {
        quarter = { glyph = 224 },
        half  = { glyph = 198 },
        whole = { glyph = 198 },
        breve = { glyph = 198 },
    },
    triangle_up = {
        quarter = { glyph = 209 },
        half  = { glyph = 177 },
        whole = { glyph = 177 },
        breve = { glyph = 177 },
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
    strikethrough = {
        quarter = { glyph = 191 }, -- doesn't exist in Maestro
        half  = { glyph = 191 },
        whole = { glyph = 191 },
        breve = { glyph = 191 },
    },
    circled = {
        quarter = { glyph = 76 }, -- doesn't exist in Maestro
        half  = { glyph = 76 },
        whole = { glyph = 76 },
        breve = { glyph = 76 },
    },
    round = {
        quarter = { glyph = 76 },
        half  = { glyph = 76 },
        whole = { glyph = 191 },
        breve = { glyph = 191 },
    },
    hidden = {
        quarter = { glyph = 202 },
        half  = { glyph = 202 },
        whole = { glyph = 202 },
        breve = { glyph = 202 },
    },
    default = {
        quarter = { glyph = 207 }
    },
}

-- change to SMuFL characters for SMuFL font (without needing a config file)
if library.is_font_smufl_font() then
    config = {
        diamond = {
            quarter = { glyph = 0xe0e1, size = 110 },
            half  = { glyph = 0xe0da, size = 110 }, -- or "0xe0e1" to match quarter notehead
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
            half  = { glyph = 0xe0a8 },
            whole = { glyph = 0xe0a7 },
            breve = { glyph = 0xe0a6 },
        },
        triangle = {
        -- change_shape() defaults to use "triangle_down" glyphs on "triangle" up-stems
        -- use shape = "triangle_up" to force all up glyphs
        -- use shape = "triangle_down" to force all down glyphs
            quarter = { glyph = 0xe0be },
            half  = { glyph = 0xe0bd },
            whole = { glyph = 0xe0bc },
            breve = { glyph = 0xe0bb },
        },
        triangle_down = {
            quarter = { glyph = 0xe0c7 },
            half  = { glyph = 0xe0c6 },
            whole = { glyph = 0xe0c5 },
            breve = { glyph = 0xe0c4 },
        },
        triangle_up = {
            quarter = { glyph = 0xe0be },
            half  = { glyph = 0xe0bd },
            whole = { glyph = 0xe0bc },
            breve = { glyph = 0xe0bb },
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
        strikethrough = {
            quarter = { glyph = 0xe0cf },
            half  = { glyph = 0xe0d1 },
            whole = { glyph = 0xe0d3 },
            breve = { glyph = 0xe0d5 },
        },
        circled = {
            quarter = { glyph = 0xe0e4 },
            half  = { glyph = 0xe0e5 },
            whole = { glyph = 0xe0e6 },
            breve = { glyph = 0xe0e7 },
        },
        round = {
            quarter = { glyph = 0xe113 },
            half  = { glyph = 0xe114 },
            whole = { glyph = 0xe115 },
            breve = { glyph = 0xe112 },
        },
        hidden = {
            quarter = { glyph = 0xe0a5 },
            half  = { glyph = 0xe0a5 },
            whole = { glyph = 0xe0a5 },
            breve = { glyph = 0xe0a5 },
        },
        default = {
            quarter = { glyph = 0xe0a4 }
        },
    }
end

configuration.get_parameters("notehead.config.txt", config)

--[[
% change_shape

Changes the given notehead to a specified notehead descriptor string, or specified numeric character.

@ note (FCNote)
@ shape (lua string) or (number)

: (FCNoteheadMod) the new notehead mod record created
]]
function notehead.change_shape(note, shape)
    local notehead_mod = finale.FCNoteheadMod()
    notehead_mod:EraseAt(note)
    local notehead_char = config.default.quarter.glyph

    if type(shape) == "number" then -- specific character GLYPH requested, not notehead "family"
        notehead_char = shape
        shape = "number"
    elseif not config[shape] then
        shape = "default" -- unrecognised shape name or "default" requested
    end

    if shape == "default" then
        notehead_mod:ClearChar()
    else
        local entry = note:GetEntry()
        if not entry then return end -- invalid note supplied

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
            if ref_table.glyph then
                notehead_char = ref_table.glyph
            end
            if ref_table.size then
                resize = ref_table.size
            end
            if ref_table.offset then
                offset = ref_table.offset
            end
        end

        --  finished testing notehead family --
        notehead_mod.CustomChar = notehead_char
        if resize > 0 and resize ~= 100 then
            notehead_mod.Resize = resize
        end
        if offset ~= 0 then
            notehead_mod.HorizontalPos = (entry:CalcStemUp()) and (-1 * offset) or offset
        end
    end
    notehead_mod:SaveAt(note)
    return notehead_mod
end

return notehead

--[[
$module Notehead
]] --
local notehead = {}

local configuration = require("library.configuration")

local library = require("library.general_library")

local config = {
    diamond_hollow = 79,
    diamond_filled = 226,
    diamond_whole = 79, -- Maestro lacks alternate diamond shapes
    diamond_breve = 79,
    diamond_resize = 110,
    diamond_whole_offset = 5,
    diamond_breve_offset = 14,
    x_normal = 192,
    x_circled = 192, -- Maestro has no option for the "long" crossed notehead
    x_breve = 192,
    triangle_up_hollow = 177,
    triangle_down_hollow = 198,
    triangle_up_filled = 209,
    triangle_down_filled = 224,
    triangle_up_breve = 177,
    triangle_down_breve = 198,
    slash_quarter = 243,
    slash_half = 203,
    slash_whole = 213,
    slash_breve = 213,
    square_quarter = 208,
    square_half = 173,
    square_whole = 194,
    square_breve = 221,
    hidden = 202,
    default_notehead = 207,
}

-- allowable names for noteheads
local notehead_shape_names = {
    x = true,
    diamond = true,
    guitar_diamond = true, -- diamonds are CLOSED for quarter note or shorter
    triangle = true,
    slash = true,
    square = true,
    hidden = true,
}

-- Default to SMuFL characters for SMuFL font (without needing a config file)
if library.is_font_smufl_font() then
    config.diamond_filled = 0xe0e2
    config.diamond_hollow = 0xe0e1
    config.diamond_whole = 0xe0d8
    config.diamond_breve = 0xe0d7
    config.x_normal = 0xe0a9
    config.x_circled = 0xe0ec
    config.x_breve = 0xe0b4 -- not perfect but best in Finale Maestro
    config.triangle_up_hollow = 0xe0bd
    config.triangle_down_hollow = 0xe0c6
    config.triangle_up_filled = 0xe0be
    config.triangle_down_filled = 0xe0c7
    config.triangle_up_whole = 0xe0ef
    config.triangle_down_whole = 0xe0f3
    config.triangle_up_breve = 0xe0ed
    config.triangle_down_breve = 0xe0f1
    config.slash_quarter = 0xe100
    config.slash_half = 0xe101
    config.slash_whole = 0xe102
    config.slash_breve = 0xe10a
    config.square_quarter = 0xe934
    config.square_half = 0xe935
    config.square_whole = 0xe937
    config.square_breve = 0xe933
    config.hidden = 0xe0a5
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
    local notehead_char = config.default_notehead
    if type(shape) == "number" then -- specific character GLYPH requsted, not notehead "family"
        notehead_char = shape
        shape = "number"
    else -- check for valid shape identifier
        shape = notehead_shape_names[shape] and shape or "default"
    end

    if shape == "default" then
        notehead:ClearChar()
    else
        local entry = note:GetEntry()
        local duration = entry.Duration
        local offset = 0
        local resize = 100
        if shape ~= "number" then
            if shape == "hidden" then
                notehead_char = config.hidden
            --  --------
            elseif string.find(shape, "diamond") then
                notehead_char = config.diamond_hollow
                resize = config.diamond_resize
                if duration >= finale.BREVE then
                    offset = config.diamond_breve_offset
                    notehead_char = config.diamond_breve
                elseif duration >= finale.WHOLE_NOTE then
                    offset = config.diamond_whole_offset
                    notehead_char = config.diamond_whole
                elseif duration < finale.HALF_NOTE and string.find(shape, "guitar") then
                    notehead_char = config.diamond_filled
                end
            --  --------
            elseif shape == "slash" then
                notehead_char = config.slash_quarter
                if duration >= finale.BREVE then
                    notehead_char = config.slash_breve
                elseif duration >= finale.WHOLE_NOTE then
                    notehead_char = config.slash_whole
                elseif duration >= finale.HALF_NOTE then
                    notehead_char = config.slash_half
                end
            --  --------
            elseif shape == "square" then
                notehead_char = config.square_quarter
                if duration >= finale.BREVE then
                    notehead_char = config.square_breve
                elseif duration >= finale.WHOLE_NOTE then
                    notehead_char = config.square_whole
                elseif duration >= finale.HALF_NOTE then
                    notehead_char = config.square_half
                end
                --  --------
            elseif shape == "x" then
                notehead_char = (duration >= finale.HALF_NOTE) and config.x_circled or config.x_normal
                if duration >= finale.BREVE then
                    notehead_char = config.x_breve
                    resize = 120
                end
            --  --------
            elseif shape == "triangle" then
                if entry:CalcStemUp() then
                    notehead_char = config.triangle_down_filled
                    if duration >= finale.BREVE then
                        notehead_char = config.triangle_down_breve
                    elseif duration >= finale.WHOLE_NOTE then
                        notehead_char = config.triangle_down_whole
                    elseif duration >= finale.HALF_NOTE then
                        notehead_char = config.triangle_down_hollow
                    end
                else
                    notehead_char = config.triangle_up_filled
                    if duration >= finale.BREVE then
                        notehead_char = config.triangle_up_breve
                    elseif duration >= finale.WHOLE_NOTE then
                        notehead_char = config.triangle_up_whole
                    elseif duration >= finale.HALF_NOTE then
                        notehead_char = config.triangle_up_hollow
                    end
                end
            end
        end
        --  all done testing notehead family --
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

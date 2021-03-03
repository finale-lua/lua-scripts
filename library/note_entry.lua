-- Helpful JW Lua scripts for note entries
-- Simply import this file to another Lua script to use any of these scripts
local note_entry = {}

-- return widest left-side notehead width and widest right-side notehead width
function note_entry.calc_widths(entry)
    local left_width = 0
    local right_width = 0
    for note in each(entry) do
        local note_width = note:CalcNoteheadWidth()
        if note_width > 0 then
            if note:CalcRightsidePlacement() then
                if note_width > right_width then
                    right_width = note_width
                end
            else
                if note_width > left_width then
                    left_width = note_width
                end
            end
        end
    end
    return left_width, right_width
end

function note_entry.calc_width(entry)
    local left, right = note_entry.calc_widths(entry)
    return left + right
end

function note_entry.calc_left_of_primary_notehead(entry)
    if entry:CalcStemUp() then
        return 0
    end
    local left, right = note_entry.calc_widths(entry)
    return left
end

function note_entry.calc_center_of_all_noteheads(entry)
    local width = note_entry.calc_width(entry)
    return width / 2
end

function note_entry.calc_center_of_primary_notehead(entry)
    local left, right = note_entry.calc_widths(entry)
    if entry:CalcStemUp() then
        return left / 2
    end
    return left + (right / 2)
end

function note_entry.calc_stem_offset(entry)
    local left, right = note_entry.calc_widths(entry)
    return left
end

return note_entry

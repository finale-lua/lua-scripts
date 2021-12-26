--[[
$module Articulation
]]

local articulation = {}

local note_entry = require("library.note_entry")

--[[
% delete_from_entry_by_char_num(entry, char_num)

Removes any articulation assignment that has the specified character as its above-character.

@ entry (FCNoteEntry)
@ char_num (number) UTF-32 code of character (which is the same as ASCII for ASCII characters)
]]
function articulation.delete_from_entry_by_char_num(entry, char_num)
    local artics = entry:CreateArticulations()
    for a in eachbackwards(artics) do
        local defs = a:CreateArticulationDef()
        if defs:GetAboveSymbolChar() == char_num then
            a:DeleteData()
        end
    end
end

--[[
% is_note_side(artic, curr_pos)

Uses `FCArticulation.CalcMetricPos` to determine if the input articulation is on the note-side.

@ artic (FCArticulation)
@ [curr_pos] (FCPoint) current position of articulation that will be calculated if not supplied
: (boolean) true if on note-side, otherwise false
]]
function articulation.is_note_side(artic, curr_pos)
    if nil == curr_pos then
        curr_pos = finale.FCPoint(0, 0)
        if not artic:CalcMetricPos(curr_pos) then
            return false
        end
    end
    local entry = artic:GetNoteEntry()
    local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
    if nil == cell_metrics then
        return false
    end
    if entry:CalcStemUp() then
        local bot_pos = note_entry.get_bottom_note_position(entry)
        bot_pos = math.floor(((10000*bot_pos)/cell_metrics.StaffScaling) + 0.5)
        return curr_pos.Y <= bot_pos
    else
        local top_pos = note_entry.get_top_note_position(entry)
        top_pos = math.floor(((10000*top_pos)/cell_metrics.StaffScaling) + 0.5)
        return curr_pos.Y >= top_pos
    end
    return false
end


--[[
% calc_main_character_dimensions(artic)

Uses `FCTextMetrics:LoadArticulation` to determine the dimensions of the main character

@ artic_def (FCArticulationDef)
: (number, number) the width and height of the main articulation character in (possibly fractional) evpus, or 0, 0 if it failed to load metrics
]]
function articulation.calc_main_character_dimensions(artic_def)
    local text_mets = finale.FCTextMetrics()
    if not text_mets:LoadArticulation(artic_def, false, 100) then
        return 0, 0
    end
    return text_mets:CalcWidthEVPUs(), text_mets:CalcHeightEVPUs()
end

return articulation

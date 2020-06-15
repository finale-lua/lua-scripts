-- A collection of helpful JW Lua articulation scripts
-- Simply import this file to another Lua script to use any of these scripts
local articulation = {}

function articulation.delete_from_entry_by_char_num(entry, char_num)
    local artics = entry:CreateArticulations()
    for a in eachbackwards(artics) do
        local defs = a:CreateArticulationDef()
        if defs:GetAboveSymbolChar() == char_num then
            a:DeleteData()
        end
    end
end

return articulation

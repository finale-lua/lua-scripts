--[[
$module Utility Functions

A library of general Lua utility functions.
]]

local utils = {}

--[[
% copy_table(t)

If a table is passed, returns a copy, otherwise returns the passed value.

@ t (mixed)
: (mixed)
]]
function utils.copy_table(t)
    if type(t) == 'table' then
        local new = {}
        for k, v in pairs(t) do
            new[utils.copy_table(k)] = utils.copy_table(v)
        end
        setmetatable(new, utils.copy_table(getmetatable(t)))
        return new
    else
        return t
    end
end

--[[
% table_remove_first

Removes the first occurrence of a value from an array table.

@ t (table)
@ value (mixed)
]]
function utils.table_remove_first(t, value)
    for k = 1, #t do
        if t[k] == value then
            table.remove(t, k)
            return
        end
    end
end


return utils

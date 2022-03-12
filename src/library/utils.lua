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
% unpack(t)

Unpacks a table into separate values (for compatibility with Lua <= 5.1).

@ t (table)
: (mixed)
]]
utils.unpack = unpack or table.unpack


return utils

--[[
$module Utility Functions

A library of general Lua utility functions.
]] --
local utils = {}

--[[
% copy_table

If a table is passed, returns a copy, otherwise returns the passed value.

@ t (mixed)
: (mixed)
]]
function utils.copy_table(t)
    if type(t) == "table" then
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

--[[
% iterate_keys

Returns an unordered iterator for the keys in a table.

@ t (table)
: (function)
]]
function utils.iterate_keys(t)
    local a, b, c = pairs(t)

    return function()
        c = a(b, c)
        return c
    end
end

--[[
% round

Rounds a number to the nearest whole integer.

@ num (number)
: (number)
]]
function utils.round(num)
    return math.floor(num + 0.5)
end

--[[ 
% calc_roman_numeral

Calculates the roman numeral for the input number. Adapted from https://exercism.org/tracks/lua/exercises/roman-numerals/solutions/Nia11 on 2022-08-13

@ num (number)
: (string)
]]
function utils.calc_roman_numeral(num)
    local thousands = {'M','MM','MMM'}
    local hundreds = {'C','CC','CCC','CD','D','DC','DCC','DCCC','CM'}
    local tens = {'X','XX','XXX','XL','L','LX','LXX','LXXX','XC'}	
    local ones = {'I','II','III','IV','V','VI','VII','VIII','IX'}
    local roman_numeral = ''
    if math.floor(num/1000)>0 then roman_numeral = roman_numeral..thousands[math.floor(num/1000)] end
    if math.floor((num%1000)/100)>0 then roman_numeral=roman_numeral..hundreds[math.floor((num%1000)/100)] end
    if math.floor((num%100)/10)>0 then roman_numeral=roman_numeral..tens[math.floor((num%100)/10)] end
    if num%10>0 then roman_numeral = roman_numeral..ones[num%10] end
    return roman_numeral
end

--[[ 
% calc_ordinal

Calculates the ordinal for the input number (e.g. 1st, 2nd, 3rd).

@ num (number)
: (string)
]]
function utils.calc_ordinal(num)
    local units = num % 10
    local tens = num % 100
    if units == 1 and tens ~= 11 then
        return num .. "st"
    elseif units == 2 and tens ~= 12 then
        return num .. "nd"
    elseif units == 3 and tens ~= 13 then
        return num .. "rd"
    end

    return num .. "th"
end

--[[ 
% calc_alphabet

This returns one of the ways that Finale handles numbering things alphabetically, such as rehearsal marks or measure numbers.

This function was written to emulate the way Finale numbers saves when Autonumber is set to A, B, C... When the end of the alphabet is reached it goes to A1, B1, C1, then presumably to A2, B2, C2. 

@ num (number)
: (string)
]]
function utils.calc_alphabet(num)
    local letter = ((num - 1) % 26) + 1
    local n = math.floor((num - 1) / 26)

    return string.char(64 + letter) .. (n > 0 and n or "")
end

return utils


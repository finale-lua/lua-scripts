-- A library of helpful JW Lua scripts
-- Simply import this file to another Lua script to use any of these scripts
local library = {}

function library.change_octave(pitch_string, n)
    pitch_string.LuaString = pitch_string.LuaString:sub(1, -2) .. (tonumber(string.sub(pitch_string.LuaString, -1)) + n)
    return pitch_string
end

return library

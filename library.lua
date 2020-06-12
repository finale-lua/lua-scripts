-- A library of helpful JW Lua scripts
-- Simply import this file to another Lua script to use any of these scripts
local library = {}

function library.change_octave(pitch_string, n)
    pitch_string.LuaString = pitch_string.LuaString:sub(1, -2) .. (tonumber(string.sub(pitch_string.LuaString, -1)) + n)
    return pitch_string
end

function library.add_augmentation_dot(entry)
    entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
end

function library.get_next_same_v (entry)
    local next_entry = entry:Next()
    if entry.Voice2 then
        if (nil ~= next_entry) and next_entry.Voice2 then
            return next_entry
        end
        return nil
    end
    if entry.Voice2Launch then
        while (nil ~= next_entry) and next_entry.Voice2 do
            next_entry = next_entry:Next()
        end
    end
    return next_entry
end

function library.change_string_font (string, font_info)
    local final_text = font_info:CreateEnigmaStyleString()
    string:TrimEnigmaFontTags()
    final_text:AppendString(string)
    string:SetString (final_text)
end

function library.change_text_block_font (text_block, font_info)
    local new_text = text_block:CreateRawTextString()
    library.change_string_font(new_text, font_info)
    text_block:SaveRawTextString(new_text)
end

return library

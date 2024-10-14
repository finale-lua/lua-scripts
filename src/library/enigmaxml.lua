--[[
$module Functions for accessing Enigma XML files.

Enigma XML is the underlying file format of a Finale `.musx` file. It is undocumented
by MakeMusic and must be extracted from the `.musx` file. There is an effort to document
it underway at the [EnigmaXML Documentation](https://github.com/finale-lua/enigmaxml-documentation)
repository.
]] --
local enigmaxml = {}

local utils = require("library.utils")

-- symmetrical encryption/decryption function
local function crypt_enigmaxml_buffer(buffer)
    local state = 0x28006D45 -- this value was determined empirically
    local result = {}
    
    for i = 1, #buffer do
        -- BSD rand()
        state = (state * 0x41c64e6d + 0x3039) & 0xFFFFFFFF  -- Simulate 32-bit overflow
        local upper = state >> 16
        local c = upper + math.floor(upper / 255)
        
        local byte = string.byte(buffer, i)
        byte = byte ~ (c & 0xFF)  -- XOR operation on the byte
        
        table.insert(result, string.char(byte))
    end
    
    return table.concat(result)
end

--[[
%extract_xml

Extracts an enigmaxml buffer from a `.musx` file. Note that this function does not work with Finale's
older `.mus` format.

Windows users must have `7z` installed and macOS users must have `unzip`.

@ filepath (string) a file path to a `.musx` file.
: (string) buffer of xml data containing the EnigmaXml extracted from the `.musx`
]]
function enigmaxml.extract_xml(filepath)
    if finenv.MajorVersion <= 0 and finenv.MinorVersion < 68 then
        error("enigmaxml.extract_xml requires at least RGP Lua v0.68.", 2)
    end
    if finenv.TrustedMode == finenv.TrustedModeType.UNTRUSTED then
        error("enigmaxml.extract_xml must run in Trusted mode.", 2)
    end
    local _, _, extension = utils.split_file_path(filepath)
    if extension ~= ".musx" then
        error(filepath .. " is not a .musx file.", 2)
    end

    local text = require("luaosutils").text
    local process = require("luaosutils").process
    
    local os_filepath = text.convert_encoding(filepath, text.get_utf8_codepage(), text.get_default_codepage())
    local output_dir = os.tmpname()
    local rmcommand = (finenv.UI():IsOnMac() and "rm " or "cmd /c del ") .. output_dir
    process.execute(rmcommand)

    local zipcommand
    if finenv.UI():IsOnMac() then
        zipcommand = "unzip \"" .. os_filepath .. "\" -d " .. output_dir
    else
        zipcommand = "cmd /c 7z x -o" .. output_dir .. " \"" .. os_filepath .. "\""
    end
    if not process.execute(zipcommand) then
        error(zipcommand .. " failed")
    end

    local file <close> = io.open(output_dir .. "/score.dat", "rb")
    if not file then
        error("unable to read " .. output_dir .. "/score.dat")
    end
    local buffer = file:read("*all")
    file:close()

    local delcommand = (finenv.UI():IsOnMac() and "rm -r " or "cmd /c rmdir /s /q ") .. output_dir
    process.execute(delcommand)

    return crypt_enigmaxml_buffer(buffer)
end

return enigmaxml

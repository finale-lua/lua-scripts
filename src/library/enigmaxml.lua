--[[
$module enigmaxml

EnigmaXML is the underlying file format of a Finale `.musx` file. It is undocumented
by MakeMusic and must be extracted from the `.musx` file. There is an effort to document
it underway at the [EnigmaXML Documentation](https://github.com/Project-Attacca/enigmaxml-documentation)
repository.
]] --
local enigmaxml = {}

local utils = require("library.utils")
local client = require("library.client")
local ziputils = require("library.ziputils")

-- symmetrical encryption/decryption function for EnigmaXML
local function crypt_enigmaxml_buffer(buffer)
    -- do not use <const> because this library must be loadable by Lua 5.2 (JW Lua)
    local INITIAL_STATE = 0x28006D45 -- this value was determined empirically
    local state = INITIAL_STATE
    local result = {}
    
    for i = 1, #buffer do
        -- BSD rand()
        if (i - 1) % 0x20000 == 0 then
            state = INITIAL_STATE
        end
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
% extract_enigmaxml

EnigmaXML is the underlying file format of a Finale `.musx` file. It is undocumented
by MakeMusic and must be extracted from the `.musx` file. There is an effort to document
it underway at the [EnigmaXML Documentation](https://github.com/finale-lua/ziputils-documentation)
repository.

This function extracts the EnigmaXML buffer from a `.musx` file. Note that it does not work with Finale's
older `.mus` format.

@ filepath (string) utf8-encoded file path to a `.musx` file.
: (string) utf8-encoded buffer of xml data containing the EnigmaXml extracted from the `.musx`.
]]
function enigmaxml.extract_enigmaxml(filepath)
    local not_supported_message
    if not client.supports("luaosutils") and false then --finenv.UI():IsOnWindows() then
        -- io.popen doesn't work with our Windows PowerShell commands
        not_supported_message = "enigmaxma.extract_enigmaxml requires embedded luaosutils"
    elseif finenv.TrustedMode == finenv.TrustedModeType.UNTRUSTED then
        not_supported_message = "enigmaxml.extract_enigmaxml must run in Trusted mode."
    elseif not finaleplugin.ExecuteExternalCode then
        not_supported_message = "enigmaxml.extract_enigmaxml must have finaleplugin.ExecuteExternalCode set to true."
    end
    if not_supported_message then
        error(not_supported_message, 2)
    end
    local _, _, extension = utils.split_file_path(filepath)
    if extension ~= ".musx" then
        error(filepath .. " is not a .musx file.", 2)
    end

    -- Steps to extract:
    --      Unzip the `.musx` (which is `.zip` in disguise)
    --      Run the `score.dat` file through `crypt_enigmaxml_buffer` to get a gzip archive of the EnigmaXML file.
    --      Gunzip the extracted EnigmaXML gzip archive into a string and return it.
    
    local os_filepath = client.encode_with_client_codepage(filepath)
    local output_dir, zipcommand = ziputils.calc_temp_output_path(os_filepath)
    if not client.execute(zipcommand) then
        error(zipcommand .. " failed")
    end

    -- do not use <close> because this library must be loadable by Lua 5.2 (JW Lua)
    local file = io.open(output_dir .. "/score.dat", "rb")
    if not file then
        error("unable to read " .. output_dir .. "/score.dat")
    end
    local buffer = file:read("*all")
    file:close()

    local delcommand = ziputils.calc_rmdir_command(output_dir)
    client.execute(delcommand)

    buffer = crypt_enigmaxml_buffer(buffer)
    if ziputils.calc_is_gzip(buffer) then
        local gzip_path = ziputils.calc_temp_output_path()
        local gzip_file = io.open(gzip_path, "wb")
        if not gzip_file then
            error("unable to create " .. gzip_file)
        end
        gzip_file:write(buffer)
        gzip_file:close()
        local gunzip_command = ziputils.calc_gunzip_command(gzip_path)
        buffer = client.execute(gunzip_command)
        client.execute(ziputils.calc_delete_file_command(gzip_path))
        if not buffer or buffer == "" then
            error(gunzip_command .. " failed")
        end
    end
    
    return buffer
end

return enigmaxml

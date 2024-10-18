--[[
$module Client

Get information about the current client. For the purposes of Finale Lua, the client is
the Finale application that's running on someones machine. Therefore, the client has
details about the user's setup, such as their Finale version, plugin version, and
operating system.

One of the main uses of using client details is to check its capabilities. As such,
the bulk of this library is helper functions to determine what the client supports.
]] --
local client = {}

local function to_human_string(feature)
    return string.gsub(feature, "_", " ")
end

local function requires_later_plugin_version(feature)
    if feature then
        return "This script uses " .. to_human_string(feature) .. " which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
    end
    return "This script requires a later version of RGP Lua. Please update RGP Lua instead to use this script."
end

local function requires_rgp_lua(feature)
    if feature then
        return "This script uses " .. to_human_string(feature) .. " which is not available on JW Lua. Please use RGP Lua instead to use this script."
    end
    return "This script requires RGP Lua, the successor of JW Lua. Please use RGP Lua instead to use this script."
end

local function requires_plugin_version(version, feature)
    if tonumber(version) <= 0.54 then
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua or JW Lua version " .. version ..
                       " or later. Please update your plugin to use this script."
        end
        return "This script requires RGP Lua or JW Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    if feature then
        return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    return "This script requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
end

local function requires_finale_version(version, feature)
    return "This script uses " .. to_human_string(feature) .. ", which is only available on Finale " .. version .. " or later"
end

--[[
% get_raw_finale_version
Returns a raw Finale version from major, minor, and (optional) build parameters. For 32-bit Finale
this is the internal major Finale version, not the year.

@ major (number) Major Finale version
@ minor (number) Minor Finale version
@ [build] (number) zero if omitted

: (number)
]]
function client.get_raw_finale_version(major, minor, build)
    local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
    if build then
        retval = bit32.bor(retval, math.floor(build))
    end
    return retval
end

--[[
% get_lua_plugin_version
Returns a number constructed from `finenv.MajorVersion` and `finenv.MinorVersion`. The reason not
to use `finenv.StringVersion` is that `StringVersion` can contain letters if it is a pre-release
version.

: (number)
]]
function client.get_lua_plugin_version()
    local num_string = tostring(finenv.MajorVersion) .. "." .. tostring(finenv.MinorVersion)
    return tonumber(num_string)
end

local features = {
    clef_change = {
        test = client.get_lua_plugin_version() >= 0.60,
        error = requires_plugin_version("0.58", "a clef change"),
    },
    ["FCKeySignature::CalcTotalChromaticSteps"] = {
        test = finenv.IsRGPLua and finale.FCKeySignature.__class.CalcTotalChromaticSteps,
        error = requires_later_plugin_version("a custom key signature"),
    },
    ["FCCategory::SaveWithNewType"] = {
        test = client.get_lua_plugin_version() >= 0.58,
        error = requires_plugin_version("0.58"),
    },
    ["finenv.QueryInvokedModifierKeys"] = {
        test = finenv.IsRGPLua and finenv.QueryInvokedModifierKeys,
        error = requires_later_plugin_version(),
    },
    ["FCCustomLuaWindow::ShowModeless"] = {
        test = finenv.IsRGPLua,
        error = requires_rgp_lua("a modeless dialog")
    },
    ["finenv.RetainLuaState"] = {
        test = finenv.IsRGPLua and finenv.RetainLuaState ~= nil,
        error = requires_later_plugin_version(),
    },
    smufl = {
        test = finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1),
        error = requires_finale_version("27.1", "a SMUFL font"),
    },
    luaosutils = {
        test = finenv.EmbeddedLuaOSUtils,
        error = requires_later_plugin_version("the embedded luaosutils library")
    }
}

--[[
% supports

Checks the client supports a given feature. Returns true if the client
supports the feature, false otherwise.

To assert the client must support a feature, use `client.assert_supports`.

For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

@ feature (string) The feature the client should support.
: (boolean)
]]
function client.supports(feature)
    if features[feature] == nil then
        error("a test does not exist for feature " .. feature, 2)
    end
    return features[feature].test
end

--[[
% assert_supports

Asserts that the client supports a given feature. If the client doesn't
support the feature, this function will throw an friendly error then
exit the program.

To simply check if a client supports a feature, use `client.supports`.

For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

@ feature (string) The feature the client should support.
: (boolean)
]]
function client.assert_supports(feature)
    local error_level = finenv.DebugEnabled and 2 or 0
    if not client.supports(feature) then
        if features[feature].error then
            error(features[feature].error, error_level)
        end
        -- Generic error message
        error("Your Finale version does not support " .. to_human_string(feature), error_level)
    end
    return true
end


--[[
% encode_with_client_codepage

If the client supports `luaosutils`, the filepath is encoded from utf8 to the current client
encoding. On macOS, this is always also utf8, so the situation where the string may be re-encoded
is only on Windows. (Recent versions of Windows also allow utf8 as the client encoding, so it may
not be re-encoded even on Windows.)

If `luaosutils` is not available, the string is returned unchanged.

A primary use-case for this function is filepaths. Windows requires 8-bit filepaths to be encoded
with the client codepage.

@ input_string (string) the utf8-encoded string to re-encode
: (string) the string re-encoded with the client codepage
]]
function client.encode_with_client_codepage(input_string)
    if client.supports("luaosutils") then
        local text = require("luaosutils").text
        if text and text.get_default_codepage() ~= text.get_utf8_codepage() then
            return text.convert_encoding(input_string, text.get_utf8_codepage(), text.get_default_codepage())
        end
    end
    return input_string
end

--[[
% encode_with_utf8_codepage

If the client supports `luaosutils`, the filepath is encoded from the current client encoding
to utf8. On macOS, the client encoding is always also utf8, so the situation where the string may
be re-encoded is only on Windows. (Recent versions of Windows also allow utf8 as the client encoding, so it may
not be re-encoded even on Windows.)

If `luaosutils` is not available, the string is returned unchanged.

A primary use-case for this function is filepaths. Windows requires 8-bit filepaths to be encoded
with the client codepage.

@ input_string (string) the client-encoded string to re-encode
: (string) the string re-encoded with the utf8 codepage
]]
function client.encode_with_utf8_codepage(input_string)
    if client.supports("luaosutils") then
        local text = require("luaosutils").text
        if text and text.get_default_codepage() ~= text.get_utf8_codepage() then
            return text.convert_encoding(input_string, text.get_default_codepage(), text.get_utf8_codepage())
        end
    end
    return input_string
end

--[[
% execute

If the client supports `luaosutils`, the command is executed using `luaosutils.execute`. Otherwise it uses `io.popen`.
In either case, the output from the command is returned.

Starting with v0.67, this function throws an error if the script is not trusted or has not set
`finaleplugin.ExecuteExternalCode` to `true`.

@ command (string) The command to execute encoded with **client encoding**.
: (string) The `stdout` from the command, in whatever encoding it generated.
]]
function client.execute(command)
    if client.supports("luaosutils") then
        local process = require("luaosutils").process
        if process then
            return process.execute(command)
        end
    end
    print("popen " .. command)
    local handle = io.popen(command)
    if not handle then return nil end
    local retval = handle:read("*a")
    handle:close()
    return retval
end

return client

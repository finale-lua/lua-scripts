--[[
$module Client

Get information about the current client. For the purposes of Finale Lua, the client is
the Finale application that's running on someones machine. Therefore, the client has
details about the user's setup, such as their Finale version, plugin version, and
operating system.

One of the main uses of using client details is to check its capabilities. As such,
the bulk of this library is helper functions to determine what the client supports.
All functions to check a client's capabilities should start with `client.supports_`.
These functions don't accept any arguments, and should always return a boolean.
]] --
local client = {}

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
% supports_smufl_fonts()

Returns true if the current client supports SMuFL fonts.

: (boolean)
]]
function client.supports_smufl_fonts()
    return finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1)
end

--[[
% supports_category_save_with_new_type()

Returns true if the current client supports FCCategory::SaveWithNewType().

: (boolean)
]]
function client.supports_category_save_with_new_type()
    return finenv.StringVersion >= "0.58"
end

--[[
% supports_finenv_query_invoked_modifier_keys()

Returns true if the current client supports finenv.QueryInvokedModifierKeys().

: (boolean)
]]
function client.supports_finenv_query_invoked_modifier_keys()
    return finenv.IsRGPLua and finenv.QueryInvokedModifierKeys
end

--[[
% supports_retained_state()

Returns true if the current client supports retaining state between runs.

: (boolean)
]]
function client.supports_retained_state()
    return finenv.IsRGPLua and finenv.RetainLuaState ~= nil
end

--[[
% supports_modeless_dialog()

Returns true if the current client supports modeless dialogs.

: (boolean)
]]
function client.supports_modeless_dialog()
    return finenv.IsRGPLua
end

--[[
% supports_clef_changes()

Returns true if the current client supports changing clefs.

: (boolean)
]]
function client.supports_clef_changes()
    return finenv.IsRGPLua or finenv.StringVersion >= "0.60"
end

--[[
% supports_custom_key_signatures()

Returns true if the current client supports changing clefs.

: (boolean)
]]
function client.supports_custom_key_signatures()
    local key = finale.FCKeySignature()
    return finenv.IsRGPLua and key.CalcTotalChromaticSteps
end

return client

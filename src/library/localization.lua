--[[
$module Localization

This library provides localization services to scripts. Note that this library cannot be used inside
a `plugindef` function, because the Lua plugin does not load any dependencies when it calls `plugindef`.

**Executive Summary**

- Create language tables containing each user-facing string as key with a translation as the value.
- Save them in the `localization` subdirectory as shown below.
- Use the `...Localized` methods with `mixin` or if not using `mixin`, require the `localization`
library directly and wrap any user-facing string in a call to `localization.localize`.

**Details**

To use the library, scripts must define each localization
as a table appended to this library table. If you provide region-specific localizations, you should also
provide a generic localization for the 2-character language code as a fallback.

```
local localization = require("library.localization")
--
-- append localizations to the table returned by `require`:
--
localization.es = localization.es or {
    ["Hello"] = "Hola",
    ["Goodbye"] = "Adiós",
    ["Computer"] = "Computadora"
}

-- specific localization for Spain
-- it is only necessary to specify items that are different than the fallback language table.
localization.es_ES = localization.es_ES or {
    ["Computer"] = "Ordenador"
}

localization.jp = localization.jp or {
    ["Hello"] = "今日は",
    ["Goodbye"] = "さようなら",
    ["Computer"] =  "コンピュータ" 
}
```

The keys do not have to be in English, but they should be the same in all tables. For scripts in the `src` directory of
the FinalaLua GitHub repository, it is recommended to place localization tables in the `localization` subdirectory as
follows.

```
src/
    my_highly_useful_script.lua
    localization/
        my_highly_useful_script/
            de.lua
            es.lua
            es_ES.lua
            jp.lua
            ...

```

Note that it is not necessary to provide a table for the language the keys are in. That is,
if the keys are in English, it is not necessary to provide `en.lua`. Each of the localization `lua` files should return
a table as described above.

If you wish to add another language, you simply add it to the subfolder for the script, and no further action is
required.

The `mixin` library provides automatic localization with the `...Localized` methods. Localized versions of text-based
`mixin` methods should be added as needed, if they do not already exist. If your script does not require the
`mixin` library, then you can require the `localization` library in your script and call `localization.localize`
directly.

Due to the architecture of the Lua environment on Finale, it is not possible to use this library to localize strings
in the `plugindef` function. Those must be handled directly inside the script. However, if you call the `plugindef`
function inside your script, it is recommended to pass `localization.get_locale()` to the `plugindef` function. This
guarantees that the plugindef function will return strings that are the closest match to the locale the library
is running with.
]]

local localization = {}

local library = require("library.general_library")

local locale = (function()
        if finenv.UI().GetUserLocaleName then
            local fcstr = finale.FCString()
            finenv.UI():GetUserLocaleName(fcstr)
            return fcstr.LuaString:gsub("-", "_")
        end
        return "en_US"
    end)()

local script_name = library.calc_script_name()

--[[
% set_locale

Sets the locale to a specified value. By default, the locale language is the same value as finenv.UI():GetUserLocaleName.
If you are running a version of Finale Lua that does not have GetUserLocaleName, you can either manually set the locale
from your script or accept the default, "en_US".

This function can also be used to test different localizations without the need to switch user preferences in the OS.

@ input_locale (string) the 2-letter lowercase language code or 5-character regional locale code
]]
function localization.set_locale(input_locale)
    locale = input_locale:gsub("-", "_")
end

--[[
% get_locale

Returns the locale value that the localization library is using. Normally it matches the value returned by
`finenv.UI():GetUserLocaleName`, however it returns a value in any Lua plugin version including JW Lua.

: (string) the current locale string that the localization library is using
]]
function localization.get_locale()
    return locale
end

-- This function finds a localization string table if it exists or requires it if it doesn't.
local function get_localized_table(try_locale)
    if type(localization[try_locale]) == "table" then
        return localization[try_locale]
    end
    local require_library = "localization" .. "." .. script_name .. "." .. try_locale
    local success, result = pcall(function() return require(require_library) end)
    if success and type(result) == "table" then
        localization[try_locale] = result
    else
        -- doing this allows us to only try to require it once
        localization[try_locale] = {}
    end
    return localization[try_locale]
end

--[[
% localize

Localizes a string based on the localization language

@ input_string (string) the string to be localized
: (string) the localized version of the string or input_string if not found
]]
function localization.localize(input_string)
    assert(type(input_string) == "string", "expected string, got " .. type(input_string))

    if locale == nil then
        return input_string
    end
    assert(type(locale) == "string", "invalid locale setting " .. tostring(locale))
    
    local t = get_localized_table(locale)
    if t and t[input_string] then
        return t[input_string]
    end

    if #locale > 2 then
        t = get_localized_table(locale:sub(1, 2))
    end
    
    return t and t[input_string] or input_string
end

return localization

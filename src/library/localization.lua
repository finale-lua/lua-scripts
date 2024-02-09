--[[
$module Localization

This library provides localization services to scripts. Note that this library cannot be used inside
a `plugindef` function, because the Lua plugin for Finale does not load any dependencies when it calls `plugindef`.

**Executive Summary**

- Create language tables containing each user-facing string as a value with a key. The key can be any string value.
- Save the language tables in the `localization` subdirectory as shown below.
- Use the `*Localized` methods with `mixin` or if not using `mixin`, require the `localization`
library directly and wrap any user-facing string in a call to `localization.localize`.

**Details**

To use the library, scripts must define each localization in a specified subfolder of the `localization` folder.
If you provide region-specific localizations, you should also provide a generic localization for the 2-character
language code as a fallback. The directory structure is as follows (where `my_highly_useful_script.lua` is your
script file).

```
src/
    my_highly_useful_script.lua
    localization/
        my_highly_useful_script/
            de.lua
            en.lua
            es.lua
            es_ES.lua
            jp.lua
            ...

```

Each localization lua should return a table of keys and translations.

English:

```
--
-- en.lua:
--
local t = {
    hello = "Hello",
    goodbye = "Goodbye",
    computer =  "Computer" 
}


Japanese:

```
--
-- jp.lua:
--
local t = {
    hello = "今日は",
    goodbye = "さようなら",
    computer =  "コンピュータ" 
}

return t
```

Spanish:

```
--
-- es.lua:
--
local t = {
    hello = "Hola",
    goodbye = "Adiós",
    computer = "Computadora"
}

return t
```

You can specify vocabulary for a specific locale. It is only necessary to specify items that
differ from the the fallback language table.

```
--
-- es_ES.lua:
--
local t = {
    computer = "Ordenador"
}

return t
```

The keys do not have to be user-friendly strings, but they should be the same in all tables. The default
fallback language is `en.lua` (English). These will be used if no languges exists that matches the user's
preferences. You can override this default with a different language by calling `set_fallback_locale`.
Any time you wish to add another language, you simply add it to the subfolder for the script,
and no further action is required.

The `mixin` library provides automatic localization with the `...Localized` methods. Localized versions of user-facing
text-based `mixin` methods should be added as needed, if they do not already exist. If your script does not require the
`mixin` library, then you can require the `localization` library in your script and call `localization.localize`
directly.

Due to the architecture of the Lua environment on Finale, it is not possible to use this library to localize strings
in the `plugindef` function. Those must be handled directly inside the script. However, if you call the `plugindef`
function inside your script, it is recommended to pass `localization.get_locale()` to the `plugindef` function. This
guarantees that the `plugindef` function returns strings that are the closest match to the locale the library
is running with.
]]

local localization = {}

local library = require("library.general_library")
local utils = require("library.utils")

local locale = (function()
        if finenv.UI().GetUserLocaleName then
            local fcstr = finale.FCString()
            finenv.UI():GetUserLocaleName(fcstr)
            return fcstr.LuaString:gsub("-", "_")
        end
        return "en_US"
    end)()

local fallback_locale = "en"

local script_name = library.calc_script_name()

local tried_locales = {} -- track which locales we've tried to load

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

--[[
% set_fallback_locale

Sets the fallback locale to a specified value. This value is used when no locale exists that matches the user's
set locale. The default is "en".

@ input_locale (string) the 2-letter lowercase language code or 5-character regional locale code
]]
function localization.set_fallback_locale(input_locale)
    fallback_locale = input_locale:gsub("-", "_")
end

--[[
% get_fallback_locale

Returns the fallback locale value that the localization library is using. See `set_fallback_locale` for more information.

: (string) the current fallback locale string that the localization library is using
]]
function localization.get_fallback_locale()
    return fallback_locale
end

local function get_original_locale_table(try_locale)
    local require_library = "localization" .. "." .. script_name .. "." .. try_locale
    local success, result = pcall(function() return require(require_library) end)
    if success and type(result) == "table" then
        return result
    end
    return nil
end

-- This function finds a localization string table if it exists or requires it if it doesn't.
-- AutoLocalize functions can add key/value pairs separately, so preserve them if they are there.
local function get_localized_table(try_locale)
    local table_exists = type(localization[try_locale]) == "table"
    if not table_exists or not tried_locales[try_locale] then
        assert(table_exists or type(localization[try_locale]) == "nil",
                    "incorrect type for localization[" .. try_locale .. "]; got " .. type(localization[try_locale]))
        local original_table = get_original_locale_table(try_locale)
        if type(original_table) == "table" then
            -- this overwrites previously added values if they exist in the newly required localization table,
            -- but it preserves the previously added values if they don't exist in the newly required table.
            localization[try_locale] = utils.copy_table(original_table, localization[try_locale])
        end
        -- doing this allows us to only try to require it once
        tried_locales[try_locale] = true
    end
    return localization[try_locale]
end

--[[
% add_to_locale

Adds values to to the locale table, but only if the locale table already exists. If a utility function needs
to expand a locale table, it should use this function. This function does not replace keys that already exist.

@ (try_locale) the locale to add to
@ (table) the key/value pairs to add
: (boolean) true if addded
]]
function localization.add_to_locale(try_locale, t)
    if type(localization[try_locale]) ~= "table" then
        if not get_original_locale_table(try_locale) then
            return false
        end
    end
    localization[try_locale] = utils.copy_table(t, localization[try_locale], false)
    return true
end

local function try_locale_or_language(try_locale)
    local t = get_localized_table(try_locale)
    if t then
        return t
    end
    if #try_locale > 2 then
        t = get_localized_table(try_locale:sub(1, 2))
        if t then
            return t
        end
    end
    return nil
end

--[[
% localize

Localizes a string based on the localization language.

@ input_string (string) the string to be localized
: (string) the localized version of the string or input_string if not found
]]
function localization.localize(input_string)
    assert(type(input_string) == "string", "expected string, got " .. type(input_string))

    if locale == nil then
        return input_string
    end
    assert(type(locale) == "string", "invalid locale setting " .. tostring(locale))
    
    local t = try_locale_or_language(locale)
    if t and t[input_string] then
        return t[input_string]
    end

    t = get_localized_table(fallback_locale)
    
    return t and t[input_string] or input_string
end

return localization

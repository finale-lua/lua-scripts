--[[
$module Localization

This library provides localization services to scripts. To use it, scripts must define each localization
as a table appended to this library table. If you provide region-specific localizations, you should also
provide a generic localization for the 2-character language code as a fallback.

```
local localization = require("library.localization")
--
-- append localizations to the library table:
--
localization.en = localization.en or {
    ["Hello"] = "Hello",
    ["Goodbye"] = "Goodbye",
    ["Computer"] = "Computer"
}

localization.es = localization.es or {
    ["Hello"] = "Hola",
    ["Goodbye"] = "Adiós",
    ["Computer"] = "Ordenador"
}

-- specific localization for Mexico
-- it is only necessary to specify items that are different from the fallback language table.
localization.es_MX = localization.es_MX or {
    ["Computer"] = "Computadora"
}

localization.jp = localization.jp or {
    ["Hello"] = "今日は",
    ["Goodbye"] = "さようなら",
    ["Computer"] =  "コンピュータ" 
}
```

The keys do not have to be in English, but they should be the same in all tables. You can embed the localizations
in your script or include them with `require`. Example:

```
local region_code = "de_CH" -- get this from `finenv.UI():GetUserLocaleName(): you could also use just the language code "de"
local localization_table_name = "localization_" region_code
localization[region_code] = require(localization_table_name)
```

In this case, `localization_de_CH.lua` could be installed in the folder alongside the localized script. This is just
one possible approach. You can manage the dependencies in the manner that is best for your script. The easiest
deployment will always be to avoid dependencies and embed the localizations in your script.

The `library.localization_developer` library provides tools for automatically generating localization tables to
copy into scripts. You can then edit them to suit your needs.
]]

local localization = {}

local locale = (function()
        if finenv.UI().GetUserLocaleName then
            local fcstr = finale.FCString()
            finenv.UI():GetUserLocaleName(fcstr)
            return fcstr.LuaString:gsub("-", "_")
        end
        return nil
    end)()

--[[
% set_locale

Sets the locale to a specified value. By default, the locale language is the same value as finenv.UI():GetUserLocaleName.
If you are running a version of Finale Lua that does not have GetUserLocaleName, you must manually set the locale from your script.

This function can also be used to test different localizations without the need to switch user preferences in the OS.

@ input_locale (string) the 2-letter lowercase language code or 5-character regional locale code
]]
function localization.set_locale(input_locale)
    locale = input_locale:gsub("-", "_")
end

--[[
% localize

Localizes a string based on the localization language

@ input_string (string) the string to be localized
: (string) the localized version of the string or input_string if not found
]]
function localization.localize(input_string)
    assert(type(input_string) == "string", "expected string, got " .. type(input_string))

    if not locale then return input_string end
    assert(type(locale) == "string", "invalid locale setting " .. tostring(locale))
    
    local t = localization[locale]
    if t and t[input_string] then
        return t[input_string]
    end

    if #locale > 2 then
        t = localization[locale:sub(1, 2)]
    end
    
    return t and t[input_string] or input_string
end

return localization

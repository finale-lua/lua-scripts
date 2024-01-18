--[[
$module Localization

This library provides localization services to scripts. To use it, scripts must define each localization
as a global table with the 2-letter language code appended.

```
localization_en = {
    ["Hello"] = "Hello",
    ["Goodbye"] = "Goodbye"
}

localization_es = {
    ["Hello"] = "Hola",
    ["Goodbye"] = "Adios"
}

localization_jp = {
    ["Hello"] = "今日は",
    ["Goodbye"] = "さようなら"
}
```

The keys do not have to be in English, but they should be the same in all tables. You can embed the localizations
in your script or include them with require. Example:

```
local language_code = "de" -- get this from `finenv.UI():GetUserLocaleName()`
local localization_table_name = "localization_" language_code
_G[localization_table_name] = require(localization_table_name)
```

In this case, `localization_de.lua` could be installed in the folder alongside the localized script. This is just
an example. You can manage the dependencies however is best for your script. The easiest deployment will always be
to avoid dependencies and embed the localizations in your script.

The `library.localization_developer` library provides tools for automatically generating localization tables to
copy into scripts. You can then edit them to suit your needs.
]]

local localization = {}

local localization_language = (function()
        if finenv.UI().GetUserLocaleName then
            local fcstr = finale.FCString()
            finenv.UI():GetUserLocaleName(fcstr)
            return fcstr.LuaString:sub(1, 2)
        end
        return nil
    end)()

--[[
% set_language

Sets the localization language to a specified value. By default, the localization language is the 2-letter language
code extracted from finenv.UI():GetUserLocaleName. If you are running a version of Finale Lua that does not have
GetUserLocaleName, you must manually set the language from your script.

This function can also be used to test different localizations without the need to switch user preferences in the OS.

@ language_code (string) the two-letter lowercase language code of the language to use
]]
function localization.set_language(language_code)
    localization_language = language_code
end

--[[
% localize

Localizes a string based on the localization language

@ input_string (string) the string to be localized
: (string) the localized version of the string or input_string if not found
]]
function localization.localize(input_string)
    assert(type(localization_language) == "string", "no localization language is set")
    local t = _G["localization_" .. localization_language]
    return t and t[input_string] or input_string
end

return localization

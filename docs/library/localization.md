# Localization

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

## Functions

- [set_locale(input_locale)](#set_locale)
- [get_locale()](#get_locale)
- [set_fallback_locale(input_locale)](#set_fallback_locale)
- [get_fallback_locale()](#get_fallback_locale)
- [add_to_locale()](#add_to_locale)
- [localize(input_string)](#localize)

### set_locale

```lua
localization.set_locale(input_locale)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/localization.lua#L143)

Sets the locale to a specified value. By default, the locale language is the same value as finenv.UI():GetUserLocaleName.
If you are running a version of Finale Lua that does not have GetUserLocaleName, you can either manually set the locale
from your script or accept the default, "en_US".

This function can also be used to test different localizations without the need to switch user preferences in the OS.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `input_locale` | `string` | the 2-letter lowercase language code or 5-character regional locale code |

### get_locale

```lua
localization.get_locale()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/localization.lua#L155)

Returns the locale value that the localization library is using. Normally it matches the value returned by
`finenv.UI():GetUserLocaleName`, however it returns a value in any Lua plugin version including JW Lua.

| Return type | Description |
| ----------- | ----------- |
| `string` | the current locale string that the localization library is using |

### set_fallback_locale

```lua
localization.set_fallback_locale(input_locale)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/localization.lua#L167)

Sets the fallback locale to a specified value. This value is used when no locale exists that matches the user's
set locale. The default is "en".

| Input | Type | Description |
| ----- | ---- | ----------- |
| `input_locale` | `string` | the 2-letter lowercase language code or 5-character regional locale code |

### get_fallback_locale

```lua
localization.get_fallback_locale()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/localization.lua#L178)

Returns the fallback locale value that the localization library is using. See `set_fallback_locale` for more information.

| Return type | Description |
| ----------- | ----------- |
| `string` | the current fallback locale string that the localization library is using |

### add_to_locale

```lua
localization.add_to_locale()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/localization.lua#L220)

Adds values to to the locale table, but only if the locale table already exists. If a utility function needs
to expand a locale table, it should use this function. This function does not replace keys that already exist.

@ (try_locale) the locale to add to
@ (table) the key/value pairs to add

| Return type | Description |
| ----------- | ----------- |
| `boolean` | true if addded |

### localize

```lua
localization.localize(input_string)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/localization.lua#L252)

Localizes a string based on the localization language.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `input_string` | `string` | the string to be localized |

| Return type | Description |
| ----------- | ----------- |
| `string` | the localized version of the string or input_string if not found |

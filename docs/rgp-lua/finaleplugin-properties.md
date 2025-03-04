finaleplugin properties
=======================

This page contains a detailed description of the `finaleplugin` properties that can be set in the `plugindef()` function. For _RGP Lua_ use a text editor to set them. For _JW Lua_ you can use the _Plug-in Def_ dialog box in _JW Lua_ to set many of them.

(Items with an asterisk are recognized by _RGP Lua_ but not _JW Lua_.)

---

#### RequireSelection (boolean)

If this is set to `true`, the script will not execute if a selection region isn't available for the current document. Instead, a user alert will display with information that the user should first select a region. (_RGP Lua_ grays it out rather than showing an alert.) Example:

```lua
finaleplugin.RequireSelection = true
```

Default is `false`.

---

#### RequireScore (boolean)

If this is set to `true`, the script will not execute if a part is viewed for the current document. Instead, a user alert will display with information that the user should first switch to the score view. (_RGP Lua_ grays it out rather than showing an alert.) Example:

```lua
finaleplugin.RequireScore = true
```

Default is `false`.

---

#### RequireDocument\* (boolean)

If this is set to `false`, the script will be available in _RGP Lua_ even if no documents are open in Finale. _JW Lua_ ignores this value.  Example:

```lua
finaleplugin.RequireDocument = false
```

Default is `true`.

---

#### NoStore (boolean)

If this is set to `true`, the script will run in “sandbox mode”. After the script has run, any saves made to Finale's database are automatically rolled back, so such a script will never do any permanent edits to a document. This might be useful for example when creating diagnostic scripts, or during development to check that the script syntax will work.

NOTE: Callbacks from modeless dialog windows are not automatically protected by `NoStore`. You should always add explicit calls to `StartNewUndoBlock` and `EndUndoBlock` in modeless callbacks that modify or potentially modify the document. Provided you do this, however, `NoStore = true` prevents `EndUndoBlock` from saving any permanent edits, even if you specify `true` for the "save" parameter.

Example:

```lua
finaleplugin.NoStore = true
```

Default is `false`.

---

#### ExecuteAtStartup\* (boolean)

If this value is `true` _RGP Lua_ executes the script during Finale initialization, provided certain security restrictions are met. The script executes after the Finale application has completely finished initializing and is ready for user input. However, there is no guarantee in which order scripts will run if multiple scripts have requested to execute at startup. Some other 3rd-party plugins (notably TGTools, Patterson Plugins, and JWLuaMenu) rearrange Finale's menus at this time, and there is no guarantee in which order they run.

The security restrictions are:

- Scripts with this value set to true must be explicitly configured in the [configuration dialog](/docs/rgp-lua/rgp-lua-configuration). They are not included as part of an Auto Folder.
- The script must have the `Allow Startup` checkbox enabled in its configuration.
- The script file must not have been modified since it was configured. If you modify it, RGP Lua reports an error, and you must reopen the configuration for that script and accept it again by hitting OK. You can disable this check if you select `Enable Debug`, but this is extremely ill-advised unless you are actively debugging the script. Remember that these scripts run invisibly every time you start up Finale.
- Trusted status is *not* required.

You can check if a script is running at startup with `finenv.QueryInitializationInProgress()`. Only the primary script runs at startup. If the script specifies `AdditionalMenuOptions`, the additional options are added to Finale's plugin menu, but they do not run at startup. 

You can set `IncludeInPluginMenu` to `false` to suppress the script from Finale's plugin menu. In this case the script *only* runs at startup.

Example:

```lua
finaleplugin.ExecuteAtStartup = true
```

Default is `false`.

---

#### ExecuteExternalCode\* (boolean)

If this value is set to `true`, the script can execute:

- `os.execute`
- `io.popen`
- `luaosutils.process.execute`
- `luaosutils.process.launch`

This value also enables the loading of binary C libraries with `require` or `package.loadlib`.

The script must be running with trusted status.

Example:

```lua
finaleplugin.ExecuteExternalCode = true
```

Default is `false`.

---

#### ExecuteHttpsCalls\* (boolean)

If this value is set to `true`, the script can execute:

- `luaosutils.internet.get` (`get_sync`)
- `luaosutils.internet.post` (`post_sync`)

Trusted status is not required, but any call to `post` must be confirmed by the user (who then has the option to approve all further `post` calls to that server from that script).

Example:

```lua
finaleplugin.ExecuteHttpsCalls = true
```

Default is `false`.

---

#### ModifyFinaleMenus\* (boolean)

If this value is set to `true`, the script can execute any of the functions in `luaosutils.menu` that modify Finale's menus.

Trusted status is required.

Example:

```lua
finaleplugin.ModifyFinaleMenus = true
```

Default is `false`.

---

#### HandlesUndo\* (boolean)

Both _JW Lua_ and _RGP Lua_ (by default) automatically run scripts within an undo block named according the undo string returned by the `plugindef()` function. However, it is possible for a script to notify _RGP Lua_ that it will handle undo blocks on its own by setting this value to `true`. This tells _RGP Lua_ to cancel the automatic undo block when the main script exits.

One primary reason a script might enable this option when creating a modeless dialog window. 

Example:

```lua
finaleplugin.HandlesUndo = true
```

Default is `false`.

---

#### HashURL\* (string)

If this property is present, _RGP Lua_ will attempt to hash-verify the script. As long as it has not been modified, a hash-verified script runs in trusted mode. The website specified in the URL must be a trusted website on a whitelist maintained by the Finale Lua organization at GitHub. The URL should point to a text file in the following format:

```
<sha-512 hash> <file name>
```

_RGP Lua_ computes the hash on the local copy of the script and compares it to the hash specified in the file at the URL. The file names must also match. As of v0.70, file names may contain spaces. Note that line endings affect the hash, so the line endings must be the same on both the server copy and the local copy of the script. If either the hash code or file name does not match, _RGP Lua_ still runs the script in untrusted mode. You can force an error instead by setting the "Error on Hash Mismatch" opton in the [configuration dialog](/docs/rgp-lua/rgp-lua-configuration).

---

#### IgnoreReturnValue\* (boolean)

_RGP Lua_ displays to the user any non-nil value returned by a script, regardless of whether an error occurred. You can suppress this display when there is no error by setting this value to `true`. Example:

```lua
finaleplugin.IgnoreReturnValue = true
```

Default is `false`.

---

#### IncludeInPluginMenu\* (boolean)

If this value is `false`, _RGP Lua_ does not include the script in Finale's plugin menu. A typical case where your might do this is in combination with `ExecuteAtStartup` set to `true`. This would allow your script to run at startup but not be accessible for the user to run from the menu.

This value applies only to the primary menu option. Any additional menu items specified with `AdditionalMenuOptions` *are* included in Finale's plugin menu.

Example:

```lua
finaleplugin.IncludeInPluginMenu = false
```

Default is `true`.

---

#### LoadAsString\* (boolean)

Setting this value to `true` tells _RGP Lua_ to load the script into an internal string and then send it to Lua. One reason to do this might be if the script file contains an embedded `NULL` character. This option would cause the Lua interpreter to stop at the `NULL`. It overrides the **Load As String** setting in the [configuration dialog](/docs/rgp-lua/rgp-lua-configuration).

```lua
finaleplugin.LoadAsString = true
```

Default is the script's “Load As String” setting in the _RGP Lua_ configuration dialog.

---

#### LoadLuaSocket\* (boolean)

Setting this value to `true` tells _RGP Lua_ to load the complete embedded `luasocket` package and change the `require` function to allow for easy loading of external lua files from the `luasocket` package. This happens even if **Enable Debugging** is not selected in the [configuration dialog](/docs/rgp-lua/rgp-lua-configuration). See the [this link](/docs/rgp-lua#the-socket-namespace) for more information.

```lua
finaleplugin.LoadLuaSocket = true
```

Default is `false`.

---

#### LoadLuaOSUtils\* (boolean)

By default, _RGP Lua_ pre-loads an embedded version of `luaosutils` package. Note that you must still `require` it to use it. See the [this link](/docs/rgp-lua) for more information. You can suppress this by setting the value to `false`. This allows you to load an external version.

```lua
finaleplugin.LoadLuaOSUtils = false
```

Default is `true`.

---

#### MinFinaleVersion (number)

The minimum version of Finale that can run the script. The number should match that returned by `finenv.FinaleVersion`. _JW Lua_ reads this value every time a script runs and displays an error message if the running Finale version is too low. _RGP Lua_ reads the value once and omits it from Finale's Plug-in menu if the running Finale version is too low. Examples:

```lua
finaleplugin.MinFinaleVersion = 2014 -- Finale 2014 (recognized by both RGP Lua and JW Lua)
```

or

```lua
finaleplugin.MinFinaleVersion = 10026 -- Finale 26 (recognized by RGP Lua but not JW Lua)
```

Note that _JW Lua_ sees all versions of Finale starting with Finale 26 as being version 9999. Therefore the above example of 10026 for `MinFinaleVersion` will prevent _JW Lua_ from running the script at all. It will produce a somewhat confusing error message, however, so it is recommended to use `MinFinaleVersionRaw` along with `MinJWLuaVersion` to prevent _JW Lua_ from running a script that requires Finale 26. (Or handle it yourself in the script.) This produces a better error message in _JW Lua_.

---

#### MaxFinaleVersion (number)

The minimum version of Finale that can run the script. The number should match that returned by `finenv.FinaleVersion`. _JW Lua_ reads this value every time a script runs and displays an error message if the running Finale version is too high. _RGP Lua_ reads the value once and omits it from Finale's Plug-in menu if the running Finale version is too high. Examples:

```lua
finaleplugin.MaxFinaleVersion = 2012 -- Finale 2012 (recognized by both RGP Lua and JW Lua)
```

or

```lua
finaleplugin.MaxFinaleVersion = 10025 -- Finale 25 (recognized by RGP Lua but not JW Lua)
```

(_JW Lua_ sees Finale 25 as `2025` whereas _RGP Lua_ sees it as `10025`.)

---

#### MinFinaleVersionRaw\* (number)

The minimum raw version of Finale that can run the script. Example:

```lua
finaleplugin.MinFinaleVersionRaw = 0x1a200000 -- Finale 26.2: 0x1a == 26 in hexadecimal
```

---

#### MaxFinaleVersionRaw\* (number)

The maximum raw version of Finale that can run the script. Example:

```lua
finaleplugin.MaxFinaleVersionRaw = 0x1b100000 -- Finale 27.1: 0x1b == 27 in hexadecimal
```

---

#### MinJWLuaVersion (number)

The minimum version of _JW/RGP Lua_ that can run the script. This is a decimal number of the form `<major>.<minor>`. The highest _JW Lua_ version is 0.54 and the lowest _RGP Lua_ version is 0.55. _JW Lua_ reads this value every time a script runs and displays an error message if the running _JW Lua_ version is too low. _RGP Lua_ reads the value once and omits it from Finale's Plugin menu if the running _RGP Lua_ version is too low. Example:

```lua
finaleplugin.MinJWLuaVersion = 0.55
```

---

#### MaxJWLuaVersion (number)

The maximum version of _JW/RGP Lua_ that can run the script. This is a decimal number of the form `<major>.<minor>`. The highest _JW Lua_ version is 0.54 and the lowest _RGP Lua_ version is 0.55. _JW Lua_ reads this value every time a script runs and displays an error message if the running _JW Lua_ version is too high. _RGP Lua_ reads the value once and omits it from Finale's Plugin menu if the running _RGP Lua_ version is too high. Example:

```lua
finaleplugin.MaxJWLuaVersion = 0.54
```

---

#### Author (string)

The full name of the author. Example:

```lua
finaleplugin.Author = "John Smith"
```

---

#### Copyright (string)

One-line copyright string. Example:

```lua
finaleplugin.Copyright = "Copyright (c) John Smith, 2013"
```

---

#### Version (string or number)

The version number of the current plug-in. Examples:

```lua
finaleplugin.Version = 1.01
```

or

```lua
finaleplugin.Version = "1.5.2"
```

or

```lua
finaleplugin.Version = "1.01, build 14"
```

---

#### CategoryTags (string)

The tags that would categorize the plug-in script. Each tag is separated by a spaces and/or commas, and each category name is case insensitive and can contain the characters a-z only. A category name is used to filter the scripts that should be displayed in a _JW Lua_ file folder (which helps the user to organize the scripts based on each script's functionality). The categories in the table below are considered to be “standard categories” and should be used whenever possible. (However, there is no restriction on the keywords you may use for tags.)

| Tag | Description |
| --- | --- |
| Articulation | Affects character or shape articulations. |
| Chord | Affects chords. |
| Debug | Debug-only tasks for developers. |
| Development | Tasks aimed at script development. |
| Diagnose | Diagnostics tasks. |
| Expression | Affects text or shape expressions. |
| Layout | Layout tasks. |
| Lyric | Affects lyrics. |
| Measure | Affects measures (such as measure attributes). |
| MIDI | Affects MIDI data. |
| Note | Affects notes entries. |
| Page | Affects pages. |
| Percussion | Affects percussion notation. |
| Playback | Affects playback. |
| Pitch | Affects note pitches. |
| Region | Tasks that require region selections. |
| Rest | Affects rests. |
| Report | Report-only tasks. |
| Smartshape | Affects smart shapes. |
| Staff | Affects staves. |
| System | Affects staff systems. |
| Tempo | Affects tempo (notated or playback). |
| Test | Plug-ins for test purposes. |
| Text | Affects text blocks. |
| UI  | Contains a user interface. |

Example:

```lua
finaleplugin.CategoryTags = "Page, Layout"
```

---

#### Date (string)

The release date (in any text format). Example:

```lua
finaleplugin.Date = "July 28, 2013"
```

---

#### Notes (multiline string)

Longer description of the plug-in and user instructions. The string can contain multiple lines. Example:

```lua
finaleplugin.Notes = [[
    This plug-in hides all rests in the selected region.
    Select the region before running the plug-in.
]]
```

Notes may contain simple Markdown syntax for creating paragraph breaks (two newlines), line breaks (two spaces at the end of lines), and numbered or bullet lists. These will be interpreted correctly at the [Finale Lua](https://finalelua.com) site if the script is uploaded there.

---

#### RevisionNotes (multiline string)

Revision history text that might be of interest to an end user. The string can contain multiple lines. Example:

```lua
finaleplugin.RevisionNotes = [[
July 26, 2013: Version 1.00
July 28, 2013: Version 1.01
]]
```

---

#### AuthorURL (string)

A URL to the script's home page. Example:

```lua
finaleplugin.AuthorURL = "http://www.theurl.com"
```

---

#### AuthorEmail (string)

The contact e-mail to the author. Example:

```lua
finaleplugin.AuthorEmail = "john.smith@theurl.com"
```

---

#### Id (string)

A unique identifier that is specific to the plug-in. It may someday be useful if the plug-in should be shared through the _Finale Lua_ repository. (Note: this repository is still a work-in-progress, so the use of an id is currently not required.) The id is case insenitive and can contain the characters `abcdefghijklmnopqrstuvwxyz0123456789_.-`. Suggested identifiers are a _author.pluginname_ syntax, or a true GUID. Examples:

```lua
finaleplugin.Id = "johnsmith.hiderests"
```

or

```lua
finaleplugin.Id = "742d0ea0-c109-4b81-87ae-d059f27cb028"
```

---

Additional Menu Options
=======================

---

Frequently you may wish to have shortcuts to functions that differ from each other by only one or a few variables. For example, you might wish to have a script that transposes a selected music region up an octave. If you then wanted another script to transpose a region _down_ an octave, you might duplicate the up-octave script and change a single value in it. You could instead reuse the first script by defining the interval value in a variable. This would allow for separate configurations of the script in the [configuration dialog](/docs/rgp-lua/rgp-lua-configuration), but it still would require end-users to set up the configurations for themselves. And they would have to be somewhat knowledgable of Lua syntax to do it.

_RGP Lua_ version 0.62 introduces the concept of **Additional Menu Options**. These allow a script to configure multiple versions of itself to appear in Finale's Plug-ins menu. The setup of Additional Menu Options is similar to the setup of the deprecated [Parameters](#parameters-deprecated) fields in _JW Lua_. Each of the necessary fields (menu option text, undo text, description, and prefix) appear in parallel lists delimited by line breaks. Each list is a multiline string value in the `finaleplugin` namespace.

_JW Lua_ does not support Additional Menu Options. It loads only the base menu option of the script, even if Additional Menu Options are supplied.

---

#### AdditionalMenuOptions (multiline string)

The text for each of the menu options to be added (in addition to the main menu option returned by the `plugindef()` function. Each line of the string represents a menu option to be added. Whitespace is ignored.

```lua
finaleplugin.AdditionalMenuOptions = [[
    Transpose Octave Down
    Transpose Third Up
    Transpose Third Down
]]
```

---

#### AdditionalUndoText (multiline string)

The undo text corresponding to each of the additional menu options defined in the `AdditionalMenuOptions` field. This field may be omitted, and _RGP Lua_ then uses each menu item text for its corresponding undo text.

```lua
finaleplugin.AdditionalUndoText = [[
    Transpose Octave Down
    Transpose Third Up
    Transpose Third Down
]]
```

---

#### AdditionalDescriptions (multiline string)

The description text corresponding to each of the additional menu options defined in the `AdditionalMenuOptions` field. If you omit these fields, _RGP Lua_ uses the default description returned by the `plugindef()` function. It is highly recommended to supply separate description text for each additional menu option, but if your base description is generic enough to cover all the different menu options, then it is not necessary.

```lua
finaleplugin.AdditionalDescriptions = [[
    Transposes the selected region an octave lower
    Transposes the selected region a third higher
    Transposes the selected region a third lower
]]
```

---

#### AdditionalPrefixes (multiline string)

The prefixes corresponding to each of the additional menu options defined in the `AdditionalMenuOptions` field. Each prefix is a line of Lua code that defines how the script should behave for that menu option. Keep in mind that, if necessary, you can define more than one variable on a single line of Lua code, for example:

```lua
var_a = 1 var_b = true var_c = "EVPU"
```

Since each prefix can be any Lua code you wish, the sky is pretty much the limit on what you can do with it. In the example below it is a simple variable assignment, but it could instead (or in addition) be a string that the script then `requires` or that contains a function name to execute. Or if there are so many variables to assign that a single line of Lua is confusing, you could define a configuration table inside the script and use the prefix to supply an index into the configuration table.

Each additional prefix executes _in addition to_ and _after_ any prefix defined in the [configuration dialog](/docs/rgp-lua/rgp-lua-configuration). (Note, however, that _RGP Lua_ ignores the `AdditionalMenuOptions` fields if the configuration includes Optional Menu Text.) Each additional prefix also executes after any System Prefix, if defined.

```lua
finaleplugin.AdditionalPrefixes = [[
    input_interval = -7
    input_interval = 2
    input_interval = -2
]]
```

---

Group scripts
=============

---

If you use additional menu properties, you'll often want to categorize your script as a group script. That way, users trying to find and download your script on this website will see a title and description that represents the group of menu items, not just one of the individual menu items.

---

#### ScriptGroupName (string)

The name of the group script. Example:

```lua
finaleplugin.ScriptGroupName = "Hairpin creator"
```

---

#### ScriptGroupDescription (string)

The description of the group script. Example:

```lua
finaleplugin.ScriptGroupDescription = "Creates hairpins of all varieties"
```

---

Parameters (Deprecated)
=======================

---

**NOTE:** Parameters are not well supported by _JW Lua_ and not supported at all by _RGP Lua_. For _RGP Lua_ you can have a similar type of flexibility with a **prefix** and/or [Additional Menu Options](#additional-menu-options). The parameter properties described here are **deprecated** and ignored by _RGP Lua_.

---

#### ParameterTypes (multiline string)

The types to the script parameters. The syntax is similar to the `SetTypes()` method when using [UserInputValue dialog input](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:uservalueinput "jwlua:uservalueinput"). Use one line for each parameter. Don't use quotation marks around the types. The number of types must be identical to the number of descriptions.

Valid types are `Number`, `String`, `Boolean` and `NumberedList`. Example:

```lua
finaleplugin.ParameterTypes = [[
Number
Boolean
]]
```

---

#### ParameterDescriptions (multiline string)

The syntax is similar to the `SetDescriptions()` method when using [UserInputValue dialog input](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:uservalueinput "jwlua:uservalueinput"). Use one line for each parameter. Don't put quotation marks around the descriptions. The number of descriptions must be identical to the number of types. Example:

```lua
finaleplugin.ParameterDecriptions = [[
Resize (in percent)
Resize relative
]]
```

---

#### ParameterLists (multiline string)

The syntax is similar to the `SetLists()` method when using [UserInputValue dialog input](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:uservalueinput "jwlua:uservalueinput"). These settings are optional for script parameters. Use one line for each parameter, but _don't_ put `{}` around the list. If a list isn't required for a parameter, set it to `nil`. If a comma is needed within a list item, quotation marks can be used around that list item. Example:

```lua
finaleplugin.ParameterLists = [[
nil
Yes, No
]]
```

---

#### ParameterInitValues (multiline string)

The syntax is similar to the `SetInitValues()` method when using [UserInputValue dialog input](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:uservalueinput "jwlua:uservalueinput"). These settings are optional for script parameters. Use one line for each parameter. If a user value isn't required for a parameter, set it to `nil`. Example:

```lua
finaleplugin.ParameterInitValues = [[
nil
true
]]
```

(Much of this content was copied from [Jari Williamsson's site](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:finaleplugin_properties) and will be removed or revised if so requested.)

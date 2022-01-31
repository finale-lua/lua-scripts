finaleplugin properties
=======================

This page contains a detailed description of the `finaleplugin` properties that can be set in the `plugindef()` function. For _RGP Lua_ use a text editor to set them. For _JW Lua_ you can use the _Plug-in Def_ dialog box in _JW Lua_ to set many of them.

(Items with an asterisk are recognized by _RGP Lua_ but not _JW Lua_.)

#### RequireSelection (boolean)

If this is set to `true`, the script will not execute if a selection region isn't available for the current document. Instead, a user alert will display with information that the user should first select a region. (_RGP Lua_ grays it out rather than showing an alert.) Example:

```lua
finaleplugin.RequireSelection = true
```
Default is `false`.

#### RequireScore (boolean)

If this is set to `true`, the script will not execute if a part is viewed for the current document. Instead, a user alert will display with information that the user should first switch to the score view. (_RGP Lua_ grays it out rather than showing an alert.) Example:

```lua
finaleplugin.RequireScore = true
```
Default is `false`.

#### RequireDocument\* (boolean)


If this is set to `false`, the script will be available in _RGP Lua_ even if no documents are open in Finale. _JW Lua_ ignores this value.  Example:

```lua
finaleplugin.RequireDocument = false
```
Default is `true`.

#### NoStore (boolean)

If this is set to `true`, the script will run in “sandbox mode”. After the script has run, any saves made to Finale's database are automatically rolled back, so such a script will never do any permanent edits to a document. This might be useful for example when creatin diagnostic scripts, or during development to check that the script syntax will work. Example:

```lua
finaleplugin.NoStore = true
```
Default is `false`.

#### HandlesUndo\* (boolean)

Both _JW Lua_ and _RGP Lua_ (by default) automatically run scripts within an undo block named according the undo string returned by the `plugindef()` function. However, it is possible for a script to notify _RGP Lua_ that it will handle undo blocks on its own by setting this value to `true`. One primary reason a script might enable this option is to open a modeless dialog window. Example:

```lua
finaleplugin.HandlesUndo = true
```
Default is `false`.

#### LoadAsString\* (boolean)

Setting this value to `true` tells _RGP Lua_ to load the script into an internal string and then send it to Lua. One reason to do this might be if the script file contains an embedded `NULL` character. This option would cause the Lua interpreter to stop at the `NULL`. It overrides the **Load As String** setting in the [configuration dialog](rgpluaconfig).

```lua
finaleplugin.LoadAsString = true
```
Default is the script's “Load As String” setting in the _RGP Lua_ configuration dialog.

#### LoadLuaSocket\* (boolean)

Setting this value to `true` tells _RGP Lua_ to load `luasocket` into global variable `socket`, even if **Enable Debugging** is not selected in the [configuration dialog](rgpluaconfig). If debugging *is* enabled, this value is ignored and `luasocket` is loaded. Example:

```lua
finaleplugin.LoadLuaSocket = true
```
Default is `false`.

#### MinFinaleVersion (number)

The minimum version of Finale that can run the script. The number should match that returned by `finenv.FinaleVersion`. _JW Lua_ reads this value every time a script runs and displays an error message if the running Finale version is too low. _RGP Lua_ reads the value once and omits it from Finale's Plug-in menu if the running Finale version is too low. Examples:

```lua
finaleplugin.MinFinaleVersion = 2014 -- Finale 2014 (recognized by both RGP Lua and JW Lua)
```
or

```lua
finaleplugin.MinFinaleVersion = 10026 -- Finale 26 (recognized by RGP Lua but not JW Lua)
```
Note that _JW Lua_ sees all versions of Finale starting with Finale 25 as being version 9999. Therefore the above example of 10026 for `MinFinaleVersion` will prevent _JW Lua_ from running the script at all. It will produce a somewhat confusing error message, however, so it is recommended to use `MinFinaleVersionRaw` along with `MinJWLuaVersion` to prevent _JW Lua_ from running a script that requires Finale 26. (Or handle it yourself in the script.) This produces a better error message in _JW Lua_.

#### MaxFinaleVersion (number)

The minimum version of Finale that can run the script. The number should match that returned by `finenv.FinaleVersion`. _JW Lua_ reads this value every time a script runs and displays an error message if the running Finale version is too high. _RGP Lua_ reads the value once and omits it from Finale's Plug-in menu if the running Finale version is too high. Examples:

```lua
finaleplugin.MaxFinaleVersion = 2012 -- Finale 2012 (recognized by both RGP Lua and JW Lua)
```
or

```lua
finaleplugin.MaxFinaleVersion = 10025 -- Finale 25 (recognized by RGP Lua but not JW Lua)
```

#### MinFinaleVersionRaw\* (number)

The minimum raw version of Finale that can run the script. Example:

```lua
finaleplugin.MinFinaleVersionRaw = 0x1a020000 -- Finale 26.2
```
#### MaxFinaleVersionRaw\* (number)

The maximum raw version of Finale that can run the script. Example:

```lua
finaleplugin.MaxFinaleVersionRaw = 0x1b010000 -- Finale 27.1
```
#### MinJWLuaVersion (number)

The minimum version of _JW/RGP Lua_ that can run the script. This is a decimal number of the form `<major>.<minor>`. The highest _JW Lua_ version is 0.54 and the lowest _RGP Lua_ version is 0.55. _JW Lua_ reads this value every time a script runs and displays an error message if the running _JW Lua_ version is too low. _RGP Lua_ reads the value once and omits it from Finale's Plugin menu if the running _RGP Lua_ version is too low. Example:

```lua
finaleplugin. MinJWLuaVersion = 0.55
```
#### MaxJWLuaVersion (number)

The maximum version of _JW/RGP Lua_ that can run the script. This is a decimal number of the form `<major>.<minor>`. The highest _JW Lua_ version is 0.54 and the lowest _RGP Lua_ version is 0.55. _JW Lua_ reads this value every time a script runs and displays an error message if the running _JW Lua_ version is too high. _RGP Lua_ reads the value once and omits it from Finale's Plugin menu if the running _RGP Lua_ version is too high. Example:

```lua
finaleplugin. MaxJWLuaVersion = 0.54
```
#### Author (string)

The full name of the author. Example:

```lua
finaleplugin.Author = "John Smith"
```

#### Copyright (string)

One-line copyright string. Example:

```lua
finaleplugin.Copyright = "Copyright (c) John Smith, 2013"
```

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

#### Date (string)

The release date (in any text format). Example:

```lua
finaleplugin.Date = "July 28, 2013"
```

#### Notes (multiline string)

Longer description of the plug-in and user instructions. The string can contain multiple lines. Example:

```lua
finaleplugin.Notes = [[
    This plug-in hides all rests in the selected region.
    Select the region before running the plug-in.
]]
```

Notes may contain simple Markdown syntax for creating paragraph breaks (two newlines), line breaks (two spaces at the end of lines), and numbered or bullet lists. These will be interpreted correctly at the [Finale Lua](https://finalelua.com) site if the script is uploaded there.

#### RevisionNotes (multiline string)

Revision history text that might be of interest to an end user. The string can contain multiple lines. Example:

```lua
finaleplugin.RevisionNotes = [[
July 26, 2013: Version 1.00
July 28, 2013: Version 1.01 
]]
```

#### AuthorURL (string)

A URL to the script's home page. Example:

```lua
finaleplugin.AuthorURL = "http://www.theurl.com"
```

#### AuthorEmail (string)

The contact e-mail to the author. Example:

```lua
finaleplugin.AuthorEmail = "john.smith@theurl.com"
```

#### Id (string)

A unique identifier that is specific to the plug-in. It may someday be useful if the plug-in should be shared through the _Finale Lua_ repository. (Note: this repository is still a work-in-progress, so the use of an id is currently not required.) The id is case insenitive and can contain the characters `abcdefghijklmnopqrstuvwxyz0123456789_.-`. Suggested identifiers are a _author.pluginname_ syntax, or a true GUID. Examples:

```lua
finaleplugin.Id = "johnsmith.hiderests"
```

or

```lua
finaleplugin.Id = "742d0ea0-c109-4b81-87ae-d059f27cb028"
```

Parameters (Deprecated)
=======================

**NOTE:** Parameters are not well supported by _JW Lua_ and not supported at all by _RGP Lua_. For _RGP Lua_ you can have a similar type of flexibility with a **prefix**. The parameter properties described here are **deprecated** and ignored by _RGP Lua_.

#### ParameterTypes (multiline string)

**NOTE:** Parameters are not well supported on _JW Lua_ and not supported at all on _RGP Lua_. For _RGP Lua_ you can get a similar type of funcitonality with a _prefix_. The parameter properties described here are **deprecated**..

The types to the script parameters. The syntax is similar to the `SetTypes()` method when using [UserInputValue dialog input](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:uservalueinput "jwlua:uservalueinput"). Use one line for each parameter. Don't use quotation marks around the types. The number of types must be identical to the number of descriptions.

Valid types are `Number`, `String`, `Boolean` and `NumberedList`. Example:

```lua
finaleplugin.ParameterTypes = [[
Number
Boolean
]]
```

#### ParameterDescriptions (multiline string)

The syntax is similar to the `SetDescriptions()` method when using [UserInputValue dialog input](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:uservalueinput "jwlua:uservalueinput"). Use one line for each parameter. Don't put quotation marks around the descriptions. The number of descriptions must be identical to the number of types. Example:

```lua
finaleplugin.ParameterDecriptions = [[
Resize (in percent)
Resize relative
]]
```

#### ParameterLists (multiline string)

The syntax is similar to the `SetLists()` method when using [UserInputValue dialog input](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:uservalueinput "jwlua:uservalueinput"). These settings are optional for script parameters. Use one line for each parameter, but _don't_ put `{}` around the list. If a list isn't required for a parameter, set it to `nil`. If a comma is needed within a list item, quotation marks can be used around that list item. Example:

```lua
finaleplugin.ParameterLists = [[
nil
Yes, No
]]
```

#### ParameterInitValues (multiline string)

The syntax is similar to the `SetInitValues()` method when using [UserInputValue dialog input](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:uservalueinput "jwlua:uservalueinput"). These settings are optional for script parameters. Use one line for each parameter. If a user value isn't required for a parameter, set it to `nil`. Example:

```lua
finaleplugin.ParameterInitValues = [[
nil
true
]]
```

(Much of this content was copied from [Jari Williamsson's site](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:finaleplugin_properties) and will be removed or revised if so requested.)

RGP Lua
=======

_RGP Lua_ is an environment to run scripts written in the [Lua Programming Language](https://www.lua.org/) as plugins in the [Finale Music Notation](https://www.finalemusic.com/) program. _RGP Lua_ is free and compatible with all 64-bit versions of Finale. It is the successor to the very successful [JW Lua plugin](https://www.finaletips.nu/index.php/download/category/28-beta-version), which unfortunately ceased being updated in 2017.

Writing scripts for _RGP Lua_ is as simple as setting up a [development environment](/docs/rgp-lua/development-environment) to create a script file (which is a `.lua` text file) and then configuring that file in the [RGP Lua Configuration Window](/docs/rgp-lua/rgp-lua-configuration). The rest of this page describes how to get started and applies to scripts written either for _RGP Lua_ or _JW Lua_ or both (with minor differences noted).

Your First Script
-----------------

Every programming reference seems to require a “Hello, world!” example, so here it is in Lua:

```lua
print ("Hello, world!")
```

If you want a “Hello, world!” example that shows up as a menu option in Finale's Plug-in menu, here is a slightly more complex version:

```lua
function plugindef()
    return "Hello World", "Hello World", 'Displays a message box saying, "Hello, World!"'
end

finenv.UI():AlertInfo("Hello World, "")
```

A Quick Start
-------------

The fastest way to get a feel for how the Lua script language works is probably to read and test existing source code material, such as the scripts at [Finale Lua](https://finalelua.com). Make small changes to the script code and try and see what happens when you run it.

PDK Framework
-------------

Both _RGP Lua_ and _JW Lua_ map the Lua script language to the [PDK Framework](https://pdk.finalelua.com) (created by [Jari Williamsson](http://finaletips.nu)). For more info about how to interpret the PDK Framework documentation for scripting in _JW Lua_, please refer to [this page](http://jwmusic.nu//jwplugins/wiki/doku.php?id=jwlua:frameworkdocs "jwlua:frameworkdocs").

All accessible PDK Framework classes starts with the `FC` prefix, such as [`FCMeasure`](https://pdk.finalelua.com/class_f_c_measure.html), [`FCMusicRegion`](https://pdk.finalelua.com/class_f_c_music_region.html), [`FCNoteEntry`](https://pdk.finalelua.com/class_f_c_note_entry.html), etc.

The methods names (and as a result, the Lua properties) in the PDK Framework are in _CamelCase_. The constants are all-uppercase.

The Lua Language
----------------

_RGP Lua_ and _JW Lua_ are based on Lua 5.2. More information about the Lua computer language (and books about Lua) is available at the [Lua](http://www.lua.org/) home page, including [the Lua 5.2 Reference Manual](http://www.lua.org/manual/5.2/manual.html) and the online version of ["Programming in Lua", First Edition](http://www.lua.org/pil/) (this book covers Lua 5.0, but for Finale Lua programming purposes, it should cover what you need.)

Lua is case sensitive. The basic Lua syntax is very similar to other computer languages and Lua is an easy language to learn. To be able to write plug-in scripts there are just a few concepts in Lua you need to be aware of, such as:

* Variables
* Tables
* Functions
* Namespaces
* `for … do … end` loops
* `if … then … end` conditional statements

However, to really take advantage of the full power of Lua, there are other very powerful tools (such as iterators, closures and coroutines) to explore.

Both _RGP Lua_ and _JW Lua_ include all the standard Lua modules (`string`, `math`, `file`, etc). Additionally, _RGP Lua_ embeds [`luasocket`](https://aiq0.github.io/luasocket/index.html) if you select the **Enable Debugging** option when you [configure](/docs/rgp-lua//docs/rgp-lua/rgp-lua-configuration) it (or with the `finaleplugin.LoadLuaSocket` option). These modules can be used in any Finale Lua script, such as :

```lua
print (math.random(1, 10))
```

The 'finale' namespace
----------------------

All functionality that accesses Finale through the Lua/PDK Framework resides within the `finale` namespace (namespaces use the dot separator).

For example:

```lua
page = finale.FCPage()
```

The 'finenv' namespace
----------------------

The `finenv` namespace has been created to provide “programming shortcuts” to some objects that are often needed for a Finale Lua scripts. `finenv` currently contains these functions:

|Member|Description|
|----------|---------------|
|finenv.Region()|Returns an object with the currently selected region (in the document/part currently in editing scope), without the need for any other method calls. When running a modeless dialog in _RGP Lua_, this value is reinitialized to the current selected region every time you call the function. This could have side-effects if you have assigned it to a Lua variable, because the assigned variable will change as well.|
|finenv.UI()|Returns the global “user interface” object (of the [`FCUI`](https://pdk.finalelua.com/class_f_c_u_i.html) class). The `FCUI` class contains Finale and system-global tasks, such as displaying alert boxes, sounding a system beep, or getting the width of the screen, etc.|
|finenv.UserValueInput()|**Not supported** in _RGP Lua_. Instead, it displays an error message box and returns `nil`. See comments below for how it works in _JW Lua_.|
|finenv.StartNewUndoBlock(string, bool)|Ends the currently active Undo/Redo block in Finale (if any) and starts a new one with a new undo text. The first parameter (a Lua string) is the name of the new Undo/Redo block. The second parameter (optional, default is true) is a boolean, indicating if the edits in the previous Undo/Redo block should be stored (=true) or canceled (=false). Finale will only store Undo/Redo blocks that contain edit changes to the documents. These calls cannot be nested. If your script has set `finaleplugin.NoStore = true`, then this function has no effect and any changes to the document are rolled back.|
|finenv.EndUndoBlock(bool)*|Ends the currently active Undo/Redo block in Finale (if any). The parameter indicates if the edits in the previous Undo/Redo block should be stored (=true) or canceled (=false). Finale will only store Undo/Redo blocks that contain edit changes to the documents. These calls cannot be nested. If your script will make further changes to the document after this call, it should call `StartNewUndoBlock()` again before making them. Otherwise, Finale's Undo stack could become corrupted.|
|finenv.RunningLuaFilePath()\*|A function that returns a Lua string containing the full path and filename of the current running script.|
|finenv.RunningLuaFolderPath()\*|A function that returns a Lua string containing the full folder path of the current running script.|
|finenv.QueryInvokedModifierKeys(value)\*|A function that returns `true` if the input modifier key(s) were pressed when the menu item was invoked that started the script. The input value is any combination of [COMMAND\_MOD\_KEYS](https://pdk.finalelua.com/class_____f_c_user_window.html#af07ed05132bac987ff3acab63a001e47).|
|finenv.RegisterModelessDialog(dialog)\*|Registers a newly created [`FCCustomLuaWindow`](https://pdk.finalelua.com/class_f_c_custom_lua_window.html) dialog box with _RGP Lua_ so that you can then display it as a modeless window with [`ShowModeless`](https://pdk.finalelua.com/class_f_c_custom_lua_window.html#a002f165377f6191657f809a30e42b0ad). You can register more than one dialog. The script terminates when all its modeless windows close.|
|finenv.FinaleVersion|A read-only property with the running Finale “year” version, such as 2011, 2012, etc. For Finale 25 and later, _JW Lua_ returns this value as 9999. However, _RGP Lua_ (starting with v0.56) returns the major version + 10000. So Finale 25 returns 10025, Finale 26 returns 10026, etc.|
|finenv.RawFinaleVersion|A read-only property with the full Finale version number. It's constructed as 4 bytes with different version info. The highest byte is the major version, the next is subversion, etc. Use this only if you need the revision number of a specific major Finale version.|
|finenv.MajorVersion|A read-only property with the major version number of _RGP/JW Lua_. Beta versions return 0, version 1.xx gives 1, etc.|
|finenv.MinorVersion|A read-only property with the minor version number of _RGP/JW Lua_. A version 1.07 would give 7, etc.|
|finenv.StringVersion|A read-only property that returns the full _RGP/JW Lua_ version. This string can potentially contain non-numeric characters, but normally it is just `<major>.<minor>`, i.e., "1.07".|
|finenv.ConsoleIsAvailable|A read-only property that will return true if there is a console available for `print()` statements. Scripts that run from the Finale menu do not have a console. _RGP Lua_ always returns this value as `false`.|
|finenv.IsRGPLua\*|A read-only property that always returns `true` in _RGP Lua_. In _JW Lua_ it returns `nil`, which is the syntactically the equivalent to `false` in nearly every situation.|
|finenv.RetainLuaState\*|A read-write property that starts out as `false` in _RGP Lua_. If a script sets the value to `true` before exiting, the next time it is invoked it receives the same Lua state as before, including all global variables, require statements, etc. If there is an error, the Lua state is not retained, regardless of the setting. A script can change the value back to `false` at any time if it needs a fresh Lua state on the next invocation.|

\*Items with an asterisk are available in _RGP Lua_ but not _JW Lua_.


Dialog Boxes
------------

_JW Lua_ supports dialog boxes to the user through the `finenv.UserValueInput()` call. Programming of these dialog boxes is explained in full detail on [this page](http://jwmusic.nu//jwplugins/wiki/doku.php?id=jwlua:uservalueinput "jwlua:uservalueinput"). However, _RGP Lua_ does not support `UserValueInput`, and it should be considered as deprecated. Use [`FCCustomWindow`](https://pdk.finalelua.com/class_f_c_custom_window.html) or [`FCCustomLuaWindow`](https://pdk.finalelua.com/class_f_c_custom_lua_window.html) instead. These work in _JW Lua_ as well.

Finale Concepts
---------------

When you access Finale data in _RGP Lua_ or _JW Lua_, the data is internally handled in a way that sometimes is very different from how a Finale user experience the data. This section lists some internal concepts in Finale that a Lua programmer for Finale should be aware of.

### Enigma Database

Internally, Finale stores its database, historically called _Enigma data_ which is loaded/saved from/to the database. Different data record types have different access parameters. However, the PDK Framework “hides” all calls to the database through its classes and methods.

Some data (such as the “page spec” record, which describes a page with its width, height, etc) is really simple and has no linked connections to other data in the database. Other types of data demand more, and might consist of linked data records across the database (for example an expression added to the score in Finale, which contains a number of different data records).

### TGF Entry Frame

Note entries however, are not accessed through Finale's usual database calls. They are accessed through a concept called the **TGF entry frame**, where all note entries in a single measure+staff+layer are accessed through one variable-sized data record. The TGF frame can actually be browsed directly in Finale, using Finale's _Edit Frame_ dialog box (in the _Speedy Entry Tool_).

A note entry can contain multiple notes (which are the different pitches in a chord), but the notes are just sub-data in the note entry.

### Optimization Flags

Finale makes extensive use of bit flags (accessed through class properties in PDK Framework classes) to signal that the data should behave in a certain way.

However, when connecting some data types to measures and note entries, Finale also uses some internal _flags_ to mark if the database should be accessed for the specific measure/entry. These flags are optimization flags, to speed up the performance in Finale. In the PDK Framework, all optimization flags end with `Flag`.

Example: if a note entry has _articulations_, there is a specific optimization flag for them that is accessed through the `FCNoteEntry.ArticulationFlag` property.

### Editing Scope

Finale will edit the document and part that currently has the **editing focus**. Technically, the editing focus might be different from what the user sees on the screen (the _visual focus_), so a script can edit data in a document/part that is not currently visible. However, as a plug-in script programmer, it is extremely important that you make sure that the editing focus and the visual focus are identical when the plug-in script ends.

Class Concepts
--------------

### Collections

An important concept in the PDK Framework is the **collection**. Usually, collection classes ends with a plural 's' version of the “single-object” version. For example:

```lua
measure = finale.FCMeasure()      -- A single measure
measures = finale.FCMeasures()    -- A collection of multiple measures
```

Collections are not compatible with Lua tables, but they can be converted to Lua tables with the `coll2table()` function (see below).

### Cells

A **cell** in PDK Framework termonology is a reference to a single measure on a single specific staff. The concept is used with the [`FCCell`](https://pdk.finalelua.com/class_f_c_cell.html) and [`FCNoteEntryCell`](https://pdk.finalelua.com/class_f_c_note_entry_cell.html) classes, but it affects many other classes as well. The coordinate system for cells (at object creation, for example) always is _x, y_, which in the cell concept means _measure\_number, staff\_number_.

Connect to Finale/Lua
---------------------

To fully integrate a plug-in script with _Finale_ (and _RGP Lua_ or _JW Lua_)—so it behaves like an independent plug-in—the script can describe the script through the `plugindef()` function.

Please note that _JW Lua_ can handle many of the items in the `plugindef()` function automatically, by using _JW Lua’s_ “Plug-in Def” dialog box. With _RGP Lua_ you will need to use a text editor or IDE.

### The 'plugindef()' function

The `plugindef()` function is an optional function that **only** should do a _maximum_ of 2 things:

* Return the _plug-in name_, _undo string_ and _brief description_ to be used in the _Finale_ plug-in menu and for automatic undo blocks.
* Define the `finaleplugin` namespace environment to further describe the plug-in (see below).


A simple `plugindef()` implementation might look like this:

```lua
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.CategoryTags = "Rest, Region"
    return "Hide Rests", "Hide Rests", "Hides all rests in the selected region."
end
```

`plugindef()` is considered to be a reserved name in the global namespace. If the script has a function named `plugindef()`, _RGP/JW Lua_ may call it at any time (not only during script execution) to gather information about the plug-in. The `plugindef()` function can **NOT** have dependencies outside the function itself.

All aspects of the `plugindef()` are optional, but for a plug-in script that is going to be used repeatedly, the minimum should be to return a plug-in name, undo string, and short description.

The `plugindef()` function can return a maximum of 3 return values (all of them should be strings):

* The **first** return value is the _name_ of the plug-in. On Windows, the `&` character may be used before a letter to specify that letter as a mnemonic character keystroke when the script appears in Finale's plug-in menu. _(Example: “My &Plug-in” would make `p` the shortcut mnemonic key.)_

* The **second** return value is the _undo text_ for the plug-in. _JW Lua_ will append “ \[JW Lua\]” to the undo text when it sends the undo record to Finale. (Note: _RGP Lua_ does not do this.)

* The **third** return value is a _brief description text_ (for the status/message bar in _Finale_ and the _JW Lua_ user interface).


Again, all these return values are optional.

### The 'finaleplugin' namespace

The `finaleplugin` namespace is a reserved and defined namespace for the `plugindef()` execution. It can both contain properties that affect how the script will run and properties that further describes the script to the outside world.

Please note that since the execution of `plugindef()` is completely silent (no errors are displayed on failure), make absolutely certain that all spellings are correct (including correct upper/lower case).

The `finaleplugin` properties should **only** be set in the `plugindef()` function.

The properties are discussed in details on the [finaleplugin properties](/docs/rgp-lua/finaleplugin-properties) page.

print() Redirection
-------------------

_JW Lua_ redirects the output of the standard Lua `print` function to the _JW Lua_ window, so all output from the `print` function shows up there:

![JW Lua Window](rgp-lua/assets/jwlua_beta0_01-print.png "JW Lua Window")

_RGP Lua_ has no output window, but there are a number of ways to see output from the `print` function.

* Redirect it to an external debugger. See instructions for setting up a [Development Environment](/docs/rgp-lua/development-environment) for more details. (This works on both `macOS` and `Windows` and is the recommended approach with _RGP Lua_.)
* Debug Finale under XCode on `macOS`. The `print` output appears in XCode's “Output” window.
* Run Finale from a `macOS` Terminal prompt. The `print` output appears in the Terminal window.

Additional Finale Lua Functions
-------------------------------

_RGP Lua_ and _JW Lua_ add some some functions to the global namespace that are specially designed for plug-in script programming. They are listed below:

### coll2table()

`coll2table()` transforms a PDK Framework collection object into a Lua-style table, so the items can be used with the Lua standard functions for tables (such as the standard `table.` library). The resulting table is 1-based (not 0-based as the PDK Framework collections). For example:

```lua
-- Load all measure objects
allmeasures = finale.FCMeasures()
allmeasures:LoadAll()
-- Convert to table
measuretable = coll2table(allmeasures)
-- Sort the measure objects according to their width (widest measure first)
table.sort(measuretable, function (a,b) return (a.Width > b.Width) end)
-- Print the sorted result
for i, v in ipairs(measuretable) do
   print ("Item", i, "is measure number", v.ItemNo, "with the width", v.Width)
end
```

### dumpproperties()

`dumpproperties()` creates a table consisting of all available properties for an object and their values. The keys in the table is the property names; the values in the table are the property values. Use the `pairsbykeys()` iterator (see below) to get the properties sorted in alphabetical order.

```lua
page = finale.FCPage()
page:Load(1)
properties = dumpproperties(page)
for k, v in pairsbykeys(properties) do
   print (k, "=", v)
end
```

### each()

`each()` is the general iterator “factory” for PDK Framework collection objects. It feeds the `for` loop with all the elements of the collection:

```lua
-- Print the widths for all the pages
allpages = finale.FCPages()
allpages:LoadAll()
for v in each(allpages) do
     print ("Page", v.ItemNo, "has the width", v.Width)
end
```

### eachbackwards()

`eachbackwards()` does the same as the `each()` iterator, but parses the elements backwards starting from the end of the collection. It feeds the `for` loop with all the elements of the collection. This iterator is available in beta version 0.31 and later.

```lua
-- Print the widths for all the pages, starting from the last page
allpages = finale.FCPages()
allpages:LoadAll()
for v in eachbackwards(allpages) do
     print ("Page", v.ItemNo, "has the width", v.Width)
end
```

### eachentry()

`eachentry()` feeds a `for` loop with all the note entry objects in a region, without saving them back. Mirror entries are processed with `eachentry()`.

First parameter to this function is the region to process, where you could use `finenv.Region()` to get the current selection.

The second parameter is optional, but can be used to indicate the note entry layer(s) to load in Finale. The default is to load all visible layers. These values are available:

| Value | Description |
| --- | --- |
| -3  | Don't load any entries. |
| -2  | The non-visible layers(s). |
| -1  | All layers, regardless if they're visible or not. |
| 0   | All visible layer(s). This is the default. |
| 1 through 4 | Load only the one-based layer number. The layer is loaded regardless of the layer visibility. |
| A bit mask combination of hex values `0x100`, `0x200`, `0x400`, `0x800` | The layers 1-4 in any combination. |

Example:

```lua
counter = 0
for e in eachentry(finenv.Region()) do
   if e:IsRest() then
      counter = counter + 1
   end
end
print ("The region contains", counter, "rest entries.")
```

### eachentrysaved()

`eachentrysaved()` feeds a `for` loop with all the note entry objects in a region and automatically saves the entries back to Finale after processing. Only use this function when the entries actually needs to be saved. It requires the same parameter(s) as `eachentry()` (see above). Mirror entries are _not_ processed with `eachentrysaved()`.

One other task that can be automatically done with `eachentrysaved()` is to delete entries. Just set the duration to 0, and `eachentrysaved()` will automatically delete the entry prior to saving it.

```lua
-- Let eachentrysaved() delete all rests in the selected region
for e in eachentrysaved(finenv.Region()) do
   if e:IsRest() then e.Duration = 0  end
end
```

Due to the way the TGF frame works, the note entry is not saved directly after each loop turn, but only when a frame has been fully processed.

### eachcell()

`eachcell()` feeds a `for` loop with all the cell coordinates for a region. Partially selected measures are treated as being selected. The first coordinate is the measure, the second is the staff ID. `eachcell()` requires a region as the parameter, the easiest way is to refer to `finenv.Region()` to get the currently selected region.

Example:

```lua
for m, s in eachcell(finenv.Region()) do
   print ("Measure: ", m, "Staff: ", s)
end
```

### loadall()

`loadall()` feeds a `for` loop with the elements from a collection, typically where the data hasn't been loaded. The supplied collection must support the `LoadAll()` method. This is a useful shortcut when the collection itself isn't important, but rather all the items in the collection.

Example:

```lua
for m in loadall(finale.FCMeasures()) do
   print ("Measure width: ", m.Width)
end
```

### loadallforregion()

`loadallforregion()` feeds a `for` loop with the elements from a collection, based on a region. The first argument is a created collection, typically without any loaded objects. The second argument is the region.

The supplied collection must support the `LoadAllForRegion()` method. This is a useful shortcut when the collection itself isn't important, but rather all the items in the collection.

Example:

```lua
local region = finenv.Region()
for e in loadallforregion(finale.FCExpressions(), region) do
   print ("Expression's measure:", e.Measure)
end
```

### pairsbykeys()

`pairsbykeys()` feeds a `for` loop with the table elements, where the elements appear sorted by key. It returns the key/value pair just like the `pairs()` iterator in _Lua_.

Example:

```lua
t = {}
t["test"] = 12
t["a test"] = 100
for k, v in pairsbykeys(t) do
   print (k, "=", v)
end
```

Memory Management
-----------------

The Lua language handles memory through garbage collection, so allocated memory is released automatically by Lua. However, there are a couple of points that a plug-in programmer should be aware of.

* Define variables as `local` as often as possible. This becomes particularly important when group scripts (_JW Lua_ only) are used (global variables survive to the subsequent scripts in the group as well), or when using libraries. However, if you are using `finenv.RetainLuaState` in _RGP Lua_, keep in mind that `local` variables can disappear between invocations of the script. Any cross-invocation state should be held in global variables.
* The memory allocated by the PDK Framework's `Create` methods is handled automatically in different ways by _RGP Lua_ and _JW Lua_. _JW Lua_ releases these memory objects _after_ the full script has been run. _RGP Lua_ allows the Lua engine to release them as part of normal Lua garbage collection.
* For _JW Lua_, the `Create` methods can sometimes result in a huge number of objects waiting for release, for example, in a tight loop. `Lookup` classes (classes that end with `Lookup`) are available as a faster and more memory-efficient approach.
* For _RGP Lua_, calling `Create` methods in tight loops is less of an issue, since Lua garbage collection releases unused items as the loop progresses. However the same `Lookup` classes are supported as in _JW Lua_.
* When using the `FCCellMetrics` or `FCNoteEntryMetrics` class, make sure to call the `FreeMetrics()` method separately for the loaded object as soon as the data is no longer is needed. Finale allocates loaded metrics data internally, and metrics with a garbage collector can otherwise impact performance in scripts where lots of metrics data are loaded without release. This is not as big of an issue in _RGP Lua_ because Lua garbage collection also releases the internal metrics data, but `FreeMetrics()` still gives you the control to free it as soon as you no longer need it.

Tips
----

* If you don't need a collection object anymore, you can set it to `nil`. That might benefit the performance in large scripts with huge collections of data (since it signals to the garbage collector that it can free the allocated memory).
* There's virtually no performance penalty to put lots of comments in the script code. Once the script has been loaded into the Lua engine, the code resides in (quite efficient) bytecode where only the actual execution code appears.
* An alternative syntax for properties is to use the property name as a string table index with the object as a table. For example, the syntax `mymeasure.Width` is equivalent to `mymeasure["Width"]`. This alternative syntax might be useful when referencing properties dynamically through the code, especially in string variables. Example:

```lua
function print_property(obj, property_name)
    print(tostring(obj[property_name])
end

print_property(mymeasure, "Width")
```

(Most of this content was copied from [Jari Williamsson's site](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:development) and will be removed or revised if so requested.)

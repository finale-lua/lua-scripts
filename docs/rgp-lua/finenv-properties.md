# Namespace 'finenv'

This page contains a detailed description of the `finenv` functions and properties that are available in the Finale Lua environment.

(Items with an asterisk are available in _RGP Lua_ but not _JW Lua_.)

#### ConsoleIsAvailable (read-only property)

Returns true if there is a console available for `print()` statements. Scripts that run from the Finale menu do not have a console. _RGP Lua_ always returns this value as `false`.

Example:

```lua
if finenv.ConsoleIsAvailable then
   print("Hello World")
else
   finenv.UI():AlertInfo("Hello World", "")
end
```

#### CreateLuaScriptItems\* (function)

Returns an instance of `FCLuaScriptItems` containing a collection of every menu item configured for the current running instance of _RGP Lua_. You can execute these items from within your script, and they will behave as if you had selected them from the menu. More information can be found at [`FCLuaScriptItem`](https://pdk.finalelua.com/class_f_c_lua_script_item.html). You do not have to maintain your reference to the collection for the executed script(s) to keep running, nor does your script have to keep running. Invoking these items is launch-and-forget.


|Input Type|Description|
|------|------|
|(none)||

|Output Type|Description|
|------|------|
|FCLuaScriptItems|A collection of all configured menu items in the current running instance of _RGP Lua_|

Example:

```lua
local configured_items = finenv.CreateLuaScriptItems()
```

#### CreateLuaScriptItemsFromFilePath\* (function)

Returns an instance of `FCLuaScriptItems` that can be used to launch ad-hoc scripts. The input is a string containing the fully qualified path to the script file.

|Input Type|Description|
|------|------|
|string|A Lua string containing the fully qualified path to the script file.|

|Output Type|Description|
|------|------|
|FCLuaScriptItems|A collection of menu items defined in the script.|

The returned collection includes one item for the script file and one item for each additional menu item specified in the `plugindef` function, if it has any. The items are also initialized with other properties from the `plugindef` function as appropriate, but you may modify them.

Example:

```lua
local script_items = finenv.CreateLuaScriptItemsFromFilePath("/Users/Me/MyScripts/script.lua")
```

See comments about executing ad-hoc scripts [below](#executeluascriptitemfunction).

#### DebugEnabled\* (read-only property)

Returns the setting of “Enable Debugging” in _RGP Lua’s_ configuration dialog. You could use this to add debug-only code to your script.

Example:

```lua
if finenv.DebugEnabled then
   -- print data to log
end
```

#### EndUndoBlock\* (function)

Ends the currently active Undo/Redo block in Finale (if any). Finale will only store Undo/Redo blocks that contain edit changes to the documents. These calls cannot be nested. If your script will make further changes to the document after this call, it should call `StartNewUndoBlock()` again before making them. Otherwise, Finale's Undo stack could become corrupted.

|Input Type|Description|
|------|------|
|boolean|The previous Undo/Redo block should be stored (=true) or canceled (=false).|

|Output Type|Description|
|------|------|
|(none)||

Example

```lua
-- false: discards any changes that have been made
finenv.StartNewUndoBlock(false)
```

#### ExecuteLuaScriptItem\* (function)

Accepts an instance of [`FCLuaScriptItem`](https://pdk.finalelua.com/class_f_c_lua_script_item.html) and launches it in a separate Lua state. If the item is an ad-hoc script (created with [CreateLuaScriptItemsFromFilePath](#CreateLuaScriptItemsFromFilePathfunction)), you must maintain your reference to the script item until the ad-hoc script terminates. If you allow your reference to be garbage collected, or if your script terminates, the separate executing ad-hoc script terminates immediately. The function returns either a single value or three values if the executed item returns a message.


|Input Type|Description|
|------|------|
|FCLuaScriptItem|The script item to execute.|

|Output Type|Description|
|------|------|
|boolean|true if success|
|string|the returned message in a Lua string or `nil` if none|
|number|one of the `finenv.MessageResultType` constants if there is a message or `nil` if none|

Example:

```lua
local scripts = finenv.CreateLuaScriptItems()
local success, error_msg, msg_type = finenv.ExecuteLuaScriptItem(scripts:GetItemAt(0))
```

#### FinaleVersion (read-only property)

Returns the running Finale “year” version, such as 2011, 2012, etc. For Finale 25 and later, _JW Lua_ returns this value as 9999. However, _RGP Lua_ (starting with v0.56) returns the major version + 10000. So Finale 25 returns 10025, Finale 26 returns 10026, etc.

Example:

```lua
if finenv.FinaleVersion > 10025 then
   -- Finale 26+ feature implemented here
end
```

#### LoadedAsString\* (read-only property)

A read-only property that returns the setting of “Load As String”, either from _RGP Lua’s_ configuration dialog or from the `plugindef()` function, whichever is in effect.

Example:

```lua
if finenv.LoadedAsString then
   -- read binary data from the end of the script file
end
```

#### IsRGPLua\* (read-only property)

Always returns `true` in _RGP Lua_. In _JW Lua_ it returns `nil`, which is syntactically the equivalent of `false` in nearly every situation.

Example:

```lua
if finenv.IsRGPLua then
   -- do something available only in RGP Lua
end
```

#### MajorVersion & MinorVersion (read-only properties)

Return the major and minor version numbers, respectively, of the running Lua plugin. (Either _RGP Lua_ or _JW Lua_.)

Example:

```lua
if finenv.MajorVersion > 0 or finenv.MinorVersion > 54 then
   -- RGP Lua v0.55+ feature implemented here
end
```

#### MessageResultType\* (constants)

A list of constants that define the type of message returned by `finenv.ExecuteLuaScriptItem` (if any).

|Value|Description|
|-----|-----|
|**SCRIPT\_RESULT**|The message was returned by Lua. It could be either an error or a value returned by the script. If it is an error, the first value returned by `ExecuteLuaScriptItem` is false.|
|**DOCUMENT\_REQUIRED**|The script was not executed because it specified `finaleplugin.RequireDocument = true` but no document was open.|
|**SELECTION\_REQUIRED**|The script was not executed because it specified `finaleplugin.RequireSelection = true` but there was no selection.|
|**SCORE\_REQUIRED**|The script was not executed because it specified `finaleplugin.RequireScore = true` but the document was viewing a part.|
|**FINALE\_VERSION\_MISMATCH**|The script was not executed because it specified a minimum or maximum Finale version and the current running version of Finale does not meet the requirement.|
|**LUA\_PLUGIN\_VERSION\_MISMATCH**|The script was not executed because it specified a minimum or maximum Lua plugin version and the current running version of _RGP Lua_ does not meet the requirement.|

Example:

```lua
local scripts = finenv.CreateLuaScriptItems()
local success, error_msg, msg_type = finenv.ExecuteLuaScriptItem(scripts:GetItemAt(0))
if not success then
   if msg_type == finenv.MessageResultType.SCRIPT_RESULT then
      -- take some action
   end
end
```

#### QueryInvokedModifierKeys\* (function)

A function that returns `true` if the input modifier key(s) were pressed when the menu item was invoked that started the script. The input value is any combination of [COMMAND\_MOD\_KEYS](https://pdk.finalelua.com/class_____f_c_user_window.html#af07ed05132bac987ff3acab63a001e47). You can create combinations by adding together the key codes.

|Input Type|Description|
|------|------|
|number|The modifier keys to check.|

|Output Type|Description|
|------|------|
|boolean|True if all of the specified modifier keys were pressed.|

Example:

```lua
-- end the Lua session if both alt/option and shift are pressed when the menu is invoked.
if finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT + finale.CMDMODKEY_SHIFT) then
    finenv.RetainLuaState = false
    return
end
```

#### RawFinaleVersion (read-only property)

Returns the full running Finale version number. It is constructed as 4 bytes with different version info. The highest byte is the major version, the next nybble is subversion, etc. Use this only if you need the revision number of a specific major Finale version.

Example:

```lua
if finenv.RawFinaleVersion >= 0x1b200000 then
   -- Finale 27.2+ feature implemented here
end
```

#### Region (function)

Returns an object with the currently selected region (in the document/part currently in editing scope), without the need for any other method calls. When running a modeless dialog in _RGP Lua_, this value is reinitialized to the current selected region every time you call the function. This could have side-effects if you have assigned it to a Lua variable, because the assigned variable will change as well.

|Input Type|Description|
|------|------|
|(none)||

|Output Type|Description|
|------|------|
|FCMusicRegion|The region currently selected in Finale. (Empty if none.)|

Example:

```lua
local sel_rgn = finenv.Region() -- get the current selected region
if not sel_rgn:IsEmpty() then
	-- do something
end
```

It is important to note that in the example above, any change you make to `sel_rgn` will also be reflected in `finenv.Region()`, unless running a modeless dialog. (See above comment.) If you need to modify the selected region, perhaps a safer method is to create a separate instance of `FCMusicRegion` as follows:

```lua
local sel_rgn = finale.FCMusicRegion()
if sel_rgn:SetCurrentSelection() then
	-- do something that modifies sel_rgn
	-- finenv.Region() is unaffected
end
```

#### RegisterModelessDialog\* (function)

Registers a newly created [`FCCustomLuaWindow`](https://pdk.finalelua.com/class_f_c_custom_lua_window.html) dialog box with _RGP Lua_ so that you can then display it as a modeless window with [`ShowModeless`](https://pdk.finalelua.com/class_f_c_custom_lua_window.html#a002f165377f6191657f809a30e42b0ad). You can register more than one dialog. The script terminates when all its modeless windows close unless `finenv.RetainLuaState = true` is specified.

|Input Type|Description|
|------|------|
|FCCustomLuaWindow|The window to register.|

|Output Type|Description|
|------|------|
|(none)||

Example:

```lua
local dialog = finale.FCCustomLuaWindow()
-- add some controls to the window
finenv.RegisterModelessDialog(dialog)
dialog:ShowModeless()
```

#### RetainLuaState\* (read/write property)

A writable property that starts out as `false` in _RGP Lua_. If a script sets the value to `true` before exiting, the next time it is invoked it receives the same Lua state as before, including all global variables, required modules, etc. If there is an error, the Lua state is not retained, regardless of the setting. A script can change the value back to `false` at any time if it needs a fresh Lua state on the next invocation.

Example:

```lua
global_var = global_var or initialize_global()
finenv.RetainLuaState = true -- retain the global_var we just created
```

#### RunningLuaFilePath\* (function)

Returns a Lua string containing the full path and filename of the current running script. Scripts written for _RGP Lua_ should always use this instead of `FCString::SetRunningLuaFilePath`. The `FCString` method depends on a global varible and is not reliable past the initial execution of the script. It exists only for backwards compatibility with older scripts.

|Input Type|Description|
|------|------|
|(none)||

|Output Type|Description|
|------|------|
|string|A Lua string containing the path.|

Example:

```
local my_path = finenv.RunningLuaFilePath()
```

#### RunningLuaFolderPath\* (function)

A function that returns a Lua string containing the full folder path of the current running script. Scripts written for _RGP Lua_ should always use this instead of `FCString::SetRunningLuaFolderPath`. The `FCString` method depends on a global varible and is not reliable past the initial execution of the script. It exists only for backwards compatibility with older scripts.

|Input Type|Description|
|------|------|
|(none)||

|Output Type|Description|
|------|------|
|string|A Lua string containing the path.|

Example:

```
local my_path = finenv.RunningLuaFolderPath()
```

#### StartNewUndoBlock (function)

Ends the currently active Undo/Redo block in Finale (if any) and starts a new one with new undo text. The first parameter (a Lua string) is the name of the new Undo/Redo block. The second parameter (optional, default is true) is a boolean, indicating if the edits in the previous Undo/Redo block should be stored (=true) or canceled (=false). Finale will only store Undo/Redo blocks that contain edit changes to the documents. These calls cannot be nested. If your script has set `finaleplugin.NoStore = true`, then this function has no effect and any changes to the document are rolled back.


|Input Type|Description|
|------|------|
|string|The name of the new Undo/Redo block.|
|boolean|The previous Undo/Redo block should be stored (=true) or canceled (=false).|

|Output Type|Description|
|------|------|
|(none)||

Example:

```lua
-- "Merge Layers": starts a new undo/redo block called "Merge Layers"
-- true: saves any prior changes
finenv.StartNewUndoBlock("Merge Layers", true)
```
#### StringVersion (read-only property)

Returns the full _RGP Lua_ or _JW Lua_ version. This string can potentially contain non-numeric characters, but normally it is just `<major>.<minor>`, e.g., "1.07".

Example:

```lua
print("Running Lua plugin version: "..finenv.StringVersion)
```

#### UI (function)

Returns the global “user interface” instance (of the [`FCUI`](https://pdk.finalelua.com/class_f_c_u_i.html) class). The `FCUI` class contains Finale and system-global tasks, such as displaying alert boxes, sounding a system beep, or getting the width of the screen, etc.

|Input Type|Description|
|------|------|
|(none)||

|Output Type|Description|
|------|------|
|FCUI|The global "user interface" instance.|

Example:

```lua
finenv.UI():AlertInfo("This message appears in a message box.". "")
```

#### UserValueInput (deprecated function)

**Not supported** in _RGP Lua_. Instead, it displays an error message box and returns `nil`. Use [`FCCustomWindow`](https://pdk.finalelua.com/class_f_c_custom_window.html) or [`FCCustomLuaWindow`](https://pdk.finalelua.com/class_f_c_custom_lua_window.html) instead. These work in _JW Lua_ as well.

_JW Lua_ supports dialog boxes to the user through the `finenv.UserValueInput()` call. Programming of these dialog boxes is explained in full detail on [this page](http://jwmusic.nu//jwplugins/wiki/doku.php?id=jwlua:uservalueinput).


|Input Type|Description|
|------|------|
|(none)||

|Output Type|Description|
|------|------|
|UserValueInput|An instance of the deprecated `UserValueInput` class (_JW Lua_) or `nil` (_RGP Lua_).|

Example:

```lua
local dialog = finenv.UserValueInput()
```



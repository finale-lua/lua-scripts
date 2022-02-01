RGP Lua Development Environment
===============================

_RGP Lua_ is compatible with any external text editor or IDE. The only requirement is that the script you are developing has to have been configured in the [RGP Lua Configuration Window](/docs/rgp-lua/rgp-lua-configuration) and be visible in Finale's plugin window. This can be done before you have actually added any code to the script.

Two common development environments for Lua are [Visual Studio Code](https://code.visualstudio.com/) and [ZeroBrane Studio](https://studio.zerobrane.com/). Both have their advantages and drawbacks, and both were useful in the development of _RGP Lua_. Each have extensive documentation pages that need not be replicated here. These instructions focus on setting up debugging in ZeroBrane Studio because it is very easy to set up and use.

One of the effects of the “Enable Debugging” option in _RGP Lua_ is to pre-embed [`luasocket`](https://aiq0.github.io/luasocket/index.html) library in the Lua machine before calling the script. Many of the solutions for debugging embedded Lua over the years have used this library for communicating between the host program and the IDE.

The debugging solution presented here uses the script `mobdebug.lua` within ZeroBrane Studio.

Download and install ZeroBrane Studio from the [website](https://studio.zerobrane.com/). The installation includes a version of `mobdebug.lua`, but it may be out of date and incompatible with the version of `luasocket` embedded in _RGP Lua_. Instead, download the latest version of `mobdebug.lua` from its [github repository](https://github.com/pkulchenko/MobDebug).

To debug a script:

1. Copy `mobdebug.lua` to the script directory. (_RGP Lua_ ignores it.)
2. Add this line of code to the script immediately before the point in the script you wish to debug:  
    `require('mobdebug').start()`
3. In ZeroBrane Studio, start the debugger server by selecting `Project->Start Debugger Server`.
4. Execute the script from Finale. It halts in ZeroBrane Studio at the next executable line after the `require`.

Any changes you make to the script in the IDE editor are recognized by _RGP Lua_ the next time you execute the script from Finale. This allows for fast iteration of the test, debug, and correct cycle. However, be aware that ZeroBrane Studio does not permit editing of a script while it is being debugged. (See below for more information.)

The IDE for ZeroBrane Studio offers many [customization options](https://studio.zerobrane.com/doc-general-preferences). You set them on a per-user basis by selecting `Edit->Preferences->Settings: User`.

To capture `print()` output from the remote script:

```lua
debugger.redirect = "c"  -- "c" copies the output to ZeroBrane; "r" redirects it
```

To change your tab width to 4 instead of the default 2:

```lua
editor.tabwidth = 4 -- the default is 2. If you like 2, you don't need this line.
```

#### Editing While Debugging

ZeroBrane Studio does not permit editing a script while a Debugger session is in progress. This becomes particularly an issue if you are using the `finenv.RetainLuaState=true` option. For these scripts, once the Debugger session starts, it is not possible to edit the file until Finale exits unless you build in a way for the script to set `finenv.RetainLuaState=false` before it exits.

One effective way to do this is to detect modifier keys. If your script has a dialog box, you might use `dialog:QueryLastCommandModifierKeys(finale.CMDMODKEY_SHIFT)` to detect the shift key as you close the window and request a new Lua state there. If your script has no dialog box, you could use `finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)` to detect the shift key and request a new Lua state there. In either case, exiting the script with `finenv.RetainLuaState=false` ends the Debugger session in ZeroBrane Studio. You can then edit your script file.

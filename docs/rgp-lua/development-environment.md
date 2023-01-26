RGP Lua Development Environment
===============================

_RGP Lua_ is compatible with any external text editor or IDE. The only requirement is that the script you are developing has to have been configured in the [RGP Lua Configuration Window](/docs/rgp-lua/rgp-lua-configuration) and be visible in Finale's plugin menu. This can be done before you have actually added any code to the script.

One of the effects of the “Enable Debugging” option in _RGP Lua_ is to pre-embed the [`luasocket`](https://aiq0.github.io/luasocket/index.html) library in the Lua machine before calling the script. Many of the solutions for debugging embedded Lua over the years have used this library for communicating between the host program and the IDE.

Two common development environments for Lua are [Visual Studio Code](https://code.visualstudio.com/) and [ZeroBrane Studio](https://studio.zerobrane.com/). Both have their advantages and drawbacks, and both were useful in the development of _RGP Lua_. Each has extensive documentation pages that need not be replicated here. Instructions for setting up a development environment in each application appear below.

## Using ZeroBrane Studio

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

## Using Visual Studio Code

1. Install the extensions [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) (language server) and [Lua Debugger](https://marketplace.visualstudio.com/items?itemName=devCAT.lua-debug) (and optionally [vscode-lua-format](https://marketplace.visualstudio.com/items?itemName=Koihik.vscode-lua-format)).

2. As of 1/25/2023, there's an error in the package manifest for Lua Debugger that prevents VS Code from creating breakpoints in lua files. ([Pull request](https://github.com/devcat-studio/VSCodeLuaDebug/pull/28) created.) In order to fix this:

   1. Go to your local extension installation directory, usually `~/.vscode/extensions`. 

   2. Find the folder for the extension, `devcat.lua-debug-1.1.1`

   3. Inside the folder, edit `packages.json`, deleting the `enableBreakpointsFor` element under `debuggers` and adding a `breakpoints` element under `contributes`.

      ```diff
      --- package.json.original
      +++ package.json.revised
      @@ -21,21 +21,21 @@
           "devDependencies": {},
           "contributes": {
      +        "breakpoints": [
      +            {
      +                "language": "lua"
      +            }
      +        ],
               "debuggers": [
                   {
                       "type": "lua",
                       "label": "Lua Debugger",
      -                "enableBreakpointsFor": {
      -                    "languageIds": [
      -                        "lua"
      -                    ]
      -                },
                       "program": "./DebugAdapter.exe",
      ```

   4. If VS Code was open, close and restart it. You may then be prompted to reload the window when VS Code notices that the extension has changed on disk.

3. For a development folder, it can be convenient to fork and clone the [Finale Lua repo](https://github.com/finale-lua/lua-scripts) and put any new scripts in the `src` folder. This lets you include existing things from the `library` and `mixin` folders. You can also set up a development folder somewhere else, if you prefer.

4. Save the file [vscode-debuggee.lua](https://raw.githubusercontent.com/devcat-studio/VSCodeLuaDebug/master/debuggee/vscode-debuggee.lua) to your development folder, next to your script file. If you are developing outside of the repo `src` folder, also save the file [dkjson.lua](http://dkolf.de/src/dkjson-lua.fsl/raw/dkjson.lua?name=6c6486a4a589ed9ae70654a2821e956650299228) to your development folder, next to your script.

5. Open your development folder in VS Code.

5. Add the following three lines to your lua script. If you are developing outside the repo `src` folder, use `dkjson` in the first line instead of `lunajson.lunajson`. The `redirectPrint` argument tells your script to send any `print` output to the VS Code output window; it can be omitted or set to `false` if you prefer.

    ```lua
    local json = require 'lunajson.lunajson'
    local debuggee = require 'vscode-debuggee'
    debuggee.start(json, { redirectPrint = true })
    ```
   
6. Type <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> or click on the "Run and Debug" icon in the side bar, then click on the "create a launch.json file" link. From the "Select debugger" dropdown that appears, select `Lua Debugger`. This will create a default `launch.json` file with a `wait` section that should look like this:

	```
    "name": "wait",
    "type": "lua",
    "request": "attach",
    "workingDirectory": "${workspaceRoot}",
    "sourceBasePath": "${workspaceRoot}",
    "listenPublicly": false,
    "listenPort": 56789,
    "encoding": "UTF-8"
    ```

8. Launch the `wait` configuration by selecting it from the dropdown at the top of the "Run and Debug" panel and clicking the arrow next to it (or hitting <kbd>F5</kbd>). This tells VS Code to listen for messages from remote execution of your script.

9.  Run your script from Finale. Any breakpoints you have set in VS Code will be hit, and then you can use VS Code's debugging capabilities. 
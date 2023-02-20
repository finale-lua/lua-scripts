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

There are several different VS Code extensions for Lua debugging, each with different pros and cons. Here is one setup that gives satisfactory results.

1. Install the extensions [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) (language server) and [Lua MobDebug adapter](https://marketplace.visualstudio.com/items?itemName=AlexeyMelnichuk.lua-mobdebug).

2. For a development folder, it can be convenient to fork and clone the [Finale Lua repo](https://github.com/finale-lua/lua-scripts) and put any new scripts in the `src` folder. This lets you include existing things from the `library` and `mixin` folders. You can also set up a development folder somewhere else, if you prefer.

3. Open your development folder in VS Code.

4. Add the following lines to your lua script:

    ```lua
    local home = os.getenv("HOME") or os.getenv("HOMEDRIVE") .. os.getenv("HOMEPATH")
    package.path = home .. "/.vscode/extensions/alexeymelnichuk.lua-mobdebug-0.0.5/lua/?.lua"
        .. ";" .. package.path
    require("vscode-mobdebug").start('127.0.0.1', 8172)
    ```

5. Type <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> or click on the "Run and Debug" icon in the side bar to bring up the "Run and Debug" panel. The process for adding the Lua MobDebug launch configurations to your `launch.json` file depends on whether or not you already have a `launch.json` in your workspace.

    - If you don't have a `launch.json` file yet, you'll see a link to "create a launch.json file"; click it. If you have a Lua file open in the editor, VS Code will automatically create the appropriate `launch.json` file for you. Otherwise, from the dropdown that appears, select `Lua MobDebug`. Your `launch.json` should include these elements as part of the `configurations` array:
        ```json
        {
            "name": "Lua MobDebug: Listen",
            "type": "luaMobDebug",
            "request": "attach",
            "workingDirectory": "${workspaceFolder}",
            "sourceBasePath": "${workspaceFolder}",
            "listenPublicly": false,
            "listenPort": 8172,
            "stopOnEntry": true,
            "sourceEncoding": "UTF-8"
        },
        {
            "name": "Lua MobDebug: Current File",
            "type": "luaMobDebug",
            "request": "launch",
            "workingDirectory": "${workspaceFolder}",
            "sourceBasePath": "${workspaceFolder}",
            "listenPort": 8172,
            "stopOnEntry": true,
            "sourceEncoding": "UTF-8",
            "interpreter": "lua",
            "arguments": [
                "${relativeFile}"
            ]
        }
        ```
    - If you do have a `launch.json`, click on the gear icon at the top of the "Run and Debug" panel to bring it up. You can then either click the "Add Configuration" button in the lower left and select the two `Lua MobDebug` items one after the other, or add the above elements to the `configurations` array directly.

6. Launch the `Lua MobDebug: Listen` configuration by selecting it from the dropdown at the top of the "Run and Debug" panel and clicking the arrow next to it (or hitting <kbd>F5</kbd>). This tells VS Code to listen for messages from remote execution of your script.

7. Run your script from Finale. Any breakpoints you have set in VS Code will be hit, and then you can use VS Code's debugging capabilities. **Note** that the line `"stopOnEntry": true` in the launch configuration will cause the debugger to stop at the top of your script even if you have no breakpoints set. If you don't like this behavior, you can change the value to `false`.

8. The extension collects any `print` statements and outputs them all at the end of the script. In order to work around this and print values while your script is running, you'll need to define a local function:
    ```lua
    local print = function(...) print(...); io.flush() end
    ```


9. When the script exits, your debug session will end; you'll need to launch a new session from VS Code before invoking the script from Finale again.

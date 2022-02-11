Configuring Scripts As Standalone Plugins
=========================================

Starting with RGP Lua version 0.61, it is possible to configure one or more scripts as
standalone plugins, appearing to be independent from RGP Lua. It is also possible to
suppress RGP Lua’s configuration dialog box, which is the recommended option when running
in this mode.

Standalone mode requires

- A custom configuration file `com.robertgpatterson.RGPPluginSettings.xml`.
- Your stand-alone plugin script(s) plus any supporting files.
- A separate folder in Finale's Plug-ins folder containing a copy of the _RGP Lua_ plugin, the custom configuration file, and (recommended) your script(s).

_RGP Lua_ searches the folder where it is running and uses a configuration file there if it finds one. If not, it searches the user's preferences folder and creates a new one there if it isn't found.

Here is an example of a `macOS` configuration file that installs a script called `myplugin.lua`. It should be installed in the subfolder “My Plugin” of Finale’s Plug-ins folder, and Finale places it in a submenu of the same name.

```xml
<RGPPluginSettings>
    <RGPLua IncludeUI="false">
        <Scripts>
            <Script Path="/Library/Application Support/MakeMusic/Finale 27/Plug-ins/My Plugin/myplugin.lua" IsDirectory="false" Debug="false" UseString="false"/>
        </Scripts>
    </RGPLua>
</RGPPluginSettings>
```
The file can have multiple `Script` elements. These can be directories (`IsDirectory="true"`) or individual files. The scripts do not have to reside in the same directory with _RGP Lua_ and your custom coniguration file, but it makes for a clean installation if they do.

Everything about your custom configuration is separate from the main configuration. If you want a System Prefix for your custom configuration, it must be included in the custom configuration file. The scripts can overlap with scripts configured in the main configuration, but they run independently.

A simple way to create this file is to configure the main instance of _RGP Lua_ the way you want it for your standalone installation and then fish that file out of your preferences folder. The location of the preferences folder is

**macOS**

```
~/Library/Preferences
```

**Windows**

```
C:\Users\<user>\AppData\Roaming
```

Of particular interest is the `IncludeUI` attribute on the `RGPLua` tag. Setting it to `"false"` suppresses the menu option to open RGP Lua’s configuration dialog. The _RGP Lua_ plugin itself cannot modify this attribute. You must use a text editor to change it. _RGP Lua_ ignores the attribute if it reads its configuration from the default location in the user’s preferences folder.

To keep the user experience as simple as possible, it is **strongly recommended** to suppress _RGP Lua’s_  configuration option for these kinds of installations. The goal should be that users only see configuration options for instances they have installed themselves.

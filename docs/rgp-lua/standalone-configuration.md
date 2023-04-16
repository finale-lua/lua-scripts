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

Here is a simple example of a configuration file that installs a script called `myplugin.lua`. It could be installed in a subfolder “My Plugin” of Finale’s Plug-ins folder, and Finale would place it in a submenu of the same name.

```xml
<RGPPluginSettings>
    <RGPLua IncludeUI="false">
        <Scripts>
            <Script Path="myplugin.lua" IsDirectory="false" Debug="false" UseString="false" FromRGPLuaDirectory="true"/>
        </Scripts>
    </RGPLua>
</RGPPluginSettings>
```
The file can have multiple `Script` elements. These can be directories (`IsDirectory="true"`) or individual files. The scripts do not have to reside in the same directory with _RGP Lua_ and your custom configuration file, but it makes for a clean installation if they do. (See below.)

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

Note that if you change the contents of the config file in the preferences folder externally to _RGP Lua_, it will challenge the user to confirm the modified configuration the next time Finale starts up.

Of particular interest are the following attributes. Neither can be modified by the _RGP Lua_ plugin itself. You must edit them in a text editor.

```
IncludeUI (RGPLua tag)
```
A setting of `false` suppresses the menu option to open RGP Lua’s configuration dialog. _RGP Lua_ ignores the attribute if it reads its configuration from the default location in the user’s preferences folder.

```
FromRGPLuaDirectory (Script tag)
```
A setting of `true` causes _RGP Lua_ to prepend its running folder to the file path specified by the `Path` tag. It allows you to create a stand-alone configuration that is not dependent on any particular user's setup. If any `Script` element sets this value to `true`, it is advisable also to set `IncludeUI` to `false`.

To keep the user experience as simple as possible, it is **strongly recommended** to suppress _RGP Lua’s_  configuration option for these kinds of installations. The goal should be that users only see configuration options for the instance(s) of the plugin that they have installed themselves.

```
AllowStartup (Script tag)
```

Special care must be given to the configuration of scripts that request `ExecuteAtStartup`. In addition to setting this value to `true`, you must also provide a hash value that verifies the contents of the script file. There are a number of simple ways to get the hash of a file.

- MacOS command prompt:

```
shasum -a 512 <filename>
```

- Windows command prompt:

```
certutil -hashfile <filename> SHA512
```

- Configure the file in RGP Lua and then copy the Script tag for it (including "Hash" xml tag) directly to your custom configuration file.

Keep in mind that `ExecuteAtStartup` scripts are not included as part of an Auto Folder. You must provide a separate per-script Script tag for each.
# JW Lua Scripts

A central repository for all JW Lua scripts for Finale. These guidelines are suggestions for now until we agree on some way to standardize and organize things.

1. [Adding Scripts](#adding-scripts)
   1. [Naming scripts](#naming-scripts)
   2. [Style Guide](#style-guide)
2. [Submit a bug](#submit-a-bug)
3. [Submit ideas for future scripts](#submit-ideas-for-future-scripts)
4. [Become a contributor](#become-a-contributor)

## Adding Scripts

Just create a pull request. All scripts must have in their [PluginDef](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:development#connect_to_finale_jw_lua):

- finaleplugin.Author
- finaleplugin.Version (beta versions OK)
- finaleplugin.RevisionNotes (if there are revisions and/or bug fixes)

Note: All scripts added to the repo will have a CC1 license. See [LICENSE](https://github.com/Nick-Mazuk/jw-lua-scripts/blob/master/LICENSE) for specific terms. This is to encourage widespread use and encourage other JW Lua coders to build off your scripts.

### Naming scripts

Let's follow a unified syntax to help organize everything. Use snake case:

✓ articulation_delete_from_rests.lua

✖ articulationDeleteFromRests.lua

✖ articulationdeletefromrests.lua

✖ articulation-delete-from-rests.lua

✖ articulation_Delete_From_Rests.lua

Each word should take things from general to specific. So anything dealing with articulations should start with "articulations". Anything with page layout should start with "layout". See the [JW Lua docs for Category Tags](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:finaleplugin_properties#categorytags_string) to find an good starting place.

### Style Guide

Though not strictly necessesary, try to follow the [style guide](https://github.com/Nick-Mazuk/jw-lua-scripts/blob/master/Style%20Guide.md). That way, we can all edit and read each other's code easily.

## Submit a bug, feature request, or script request

[Please submit an issue to keep things organized](https://github.com/Nick-Mazuk/jw-lua-scripts/issues/new/choose).

## Become a contributor

To become a collaberator and edit the repo freely, email hello@finalesuperuser.com.

Note: not all requests to become a collaberator will be accepted. You may always create a pull request even if you are not a collaberator.

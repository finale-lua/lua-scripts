# Adding Scripts

Just create a pull request. All scripts must have in their [PluginDef](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:development#connect_to_finale_jw_lua):

- finaleplugin.Author
- finaleplugin.Version (beta versions OK)
- finaleplugin.RevisionNotes (if there are revisions and/or bug fixes)
- Name, undo text, and description (in the `return` statement)

Note: All scripts added to the repo will have a CC1 license. See [LICENSE](https://github.com/Nick-Mazuk/jw-lua-scripts/blob/master/LICENSE) for specific terms. This is to encourage widespread use and encourage other JW Lua coders to build off your scripts.

## Naming scripts

Let's follow a unified syntax to help organize everything. Use snake case:

```
✓ articulation_delete_from_rests.lua

✖ articulationDeleteFromRests.lua

✖ articulationdeletefromrests.lua

✖ articulation-delete-from-rests.lua

✖ articulation_Delete_From_Rests.lua
```

Each word should take things from general to specific. So anything dealing with articulations should start with "articulations". Anything with page layout should start with "layout". See the [JW Lua docs for Category Tags](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:finaleplugin_properties#categorytags_string) to find an good starting place.
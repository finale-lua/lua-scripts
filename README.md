# JW Lua Scripts

A central repository for all JW Lua scripts for Finale.

## Adding Scripts
Just create a pull request. All scripts must have in their [PluginDef](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:development#connect_to_finale_jw_lua):

- finaleplugin.Author
- finaleplugin.Version (beta versions OK)
- finaleplugin.Notes (detailed description of the plugin)
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

## Submit a bug

If you find a bug, please create an issue with the label "bug". Include the following:

- Script name and version
- Mention the author of the script (e.g., @Nick-Mazuk)
- Expected behavior
- Actual behavior
- Your setup details
  - Finale Version
  - Mac or Windows
  - JW Lua version

## Submit ideas for future scripts

If you have an idea for a future script, create an issue with the label "script request". Include the following:

- Expected behavior (more detail, the better)
- Use cases (why it will be helpful)

## Become a contributor

To become a collaberator and edit the repo freely, email hello@finalesuperuser.com.

Note: not all requests to become a collaberator will be accepted. You may always create a pull request even if you are not a collaberator.

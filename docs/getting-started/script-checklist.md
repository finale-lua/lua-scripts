# Script checklist

To keep the project organized and easy to maintain, there are a few rules that should be followed when writing scripts. Here's a checklist to ensure you follow them.

Don't worry about getting things perfect, though. When you add your script, we'll review everything and help you fix any issues should they arise.

## 1. Include a PluginDef

All scripts must have at least some minimal details in their [PluginDef](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:development#connect_to_finale_jw_lua):

- finaleplugin.Author
- finaleplugin.Version (beta versions OK)
- finaleplugin.RevisionNotes (if there are revisions and/or bug fixes)
- Name, undo text, and description (in the `return` statement)

Of course, the more complete the PluginDef, the better. This info is also used to generate the script's documentation, and it's what's shown to users when the download the script.

### Naming scripts

A script's name as returned by plugindef() should be in title case. [Windows and macOS use title case for their menu items](https://github.com/finale-lua/lua-scripts/issues/313), so we should be consistent with that. If you aren't familiar with Title case, here's a relevant description from [this Grammarly blog post](https://www.grammarly.com/blog/capitalization-rules/):

> The capitalization rules for titles of books, movies, and other works vary a little between style guides. In general, you should capitalize the first word, all nouns, all verbs (even short ones, like is), all adjectives, and all proper nouns. That means you should lowercase articles, conjunctions, and prepositions—however, some style guides say to capitalize conjunctions and prepositions that are longer than five letters.

Additionally, if you're creating a [script group](../rgp-lua/finaleplugin-properties.md#group-scripts), the start of each menu item should be the same. Menu bar items are sorted alphabetically. So that way when a user tries to find the different menu items in their menu bar, they are listed together.

## 2. Use a consistent file name

Let's follow a unified syntax for the file name. Use snake case:

```
✓ articulation_delete_from_rests.lua

✖ articulationDeleteFromRests.lua

✖ articulationdeletefromrests.lua

✖ articulation-delete-from-rests.lua

✖ articulation_Delete_From_Rests.lua
```

Each word should take things from general to specific. So anything dealing with articulations should start with "articulations". Anything with page layout should start with "layout". See the [JW Lua docs for Category Tags](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:finaleplugin_properties#categorytags_string) to find an good starting place.

## 3. Follow the style guide

There are two ways to do this:

1. Read through the style guide and manually follow it
2. Use the [Lua Linter plugin for VS Code](/docs/getting-started/style-guide#automated-styling-with-vs-code-linter) to automatically apply the style guide

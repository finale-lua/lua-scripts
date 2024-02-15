# Get metadata

This action gets the metadata for each Lua script and writes it to a JSON file. This way, users can easily find scripts that they'd like to use. This action creates the metadata for the [docs](https://finalelua.com/) website.

## Format

Each script is represented as a JSON object with the following properties:

- `name (string)`: The name of the script
- `undoText (string)`: The undo text for the script
- `shortDescription (string)`: A short description of the script
- `requireSelection (boolean)`: Whether or not the script requires a selection
- `requireScore (boolean)`: Whether or not the script requires a score
- `noStore (boolean)`: Whether or not the script is in [sandbox mode](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:finaleplugin_properties#nostore_boolean)
- `author (Author)`: The author of the script (see [author](#author) for more detail)
- `copyright (string)`: Copyright information for the script
- `version (string)`: The version of the script
- `categories (string[])`: An array of categories for the script
- `date (string)`: The date the script was created in the format `YYYY-MM-DD` ([ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html))
- `notes (string)`: Longer description of the plug-in and user instructions, can contain multiple lines
- `revisionNotes (string[])`: Revision **history** text that might be of interest to an end user, can contain multiple lines
- `authorUrl (string)`: The author's URL
- `authorEmail (string)`: The author's email
- `id (string)`: The ID of the script

Some of these values may be empty. For instance, if the script does not define an `id`, the `id` property will be an empty string.

### Author

This is the author data from the script. It contains the following properties:

- `name (string)`: The name of the author
- `website (string)`: The author's website
- `email (string)`: The author's email

## How it works

- Loop through all the `lua` files in the `src` folder
- Load the text of each file
- Extract the contents of the `plugindef` function with a regular expression
- Pass the `plugindef` function to the Lua interpreter, along with Lua code that
  invokes the function and grabs its return values and the values from the
  `finaleplugin` table
- Return the captured data as a JSON object
- Perform some manipulation on the JSON (dates, string arrays, etc.)
- Build an array of the returned JSON and save to a file

## Caution

`MinJWLuaVersion` and `MaxJWLuaVersion` Min/MaxJWLuaVersion are defined as numbers in Lua,
but they're expected to have two decimal places -- v0.70 is not v0.7. A function in `parse.ts`
ensures that the values will display with two decimal places. If there's eveer a case where
the input value has more or fewer decimal places (e.g., v0.100), this will need to be revisited.

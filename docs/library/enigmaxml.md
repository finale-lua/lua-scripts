# enigmaxml

EnigmaXML is the underlying file format of a Finale `.musx` file. It is undocumented
by MakeMusic and must be extracted from the `.musx` file. There is an effort to document
it underway at the [EnigmaXML Documentation](https://github.com/Project-Attacca/enigmaxml-documentation)
repository.

## Functions

- [extract_enigmaxml(filepath)](#extract_enigmaxml)

### extract_enigmaxml

```lua
enigmaxml.extract_enigmaxml(filepath)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/enigmaxml.lua#L49)

This function extracts the EnigmaXML buffer from a `.musx` file. Note that it does not work with Finale's
older `.mus` format.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `filepath` | `string` | utf8-encoded file path to a `.musx` file. |

| Return type | Description |
| ----------- | ----------- |
| `string` | buffer of EnigmaXml data extracted from the `.musx`. (The xml declaration specifies the encoding, but expect it to be utf8.) |

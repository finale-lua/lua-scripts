# measurement

- [convert_to_EVPUs](#convert_to_EVPUs)

## convert_to_EVPUs

```lua
measurement.convert_to_EVPUs(text)
```

Converts the specified string into EVPUs. Like text boxes in Finale, this supports
the usage of units at the end of the string. The following are a few examples:

- `12s` => 288 (12 spaces is 288 EVPUs)
- `8.5i` => 2448 (8.5 inches is 2448 EVPUs)
- `10cm` => 1133 (10 centimeters is 1133 EVPUs)
- `10mm` => 113 (10 millimeters is 113 EVPUs)
- `1pt` => 4 (1 point is 4 EVPUs)
- `2.5p` => 120 (2.5 picas is 120 EVPUs)

Read the [Finale User Manual](https://usermanuals.finalemusic.com/FinaleMac/Content/Finale/def-equivalents.htm#overriding-global-measurement-units)
for more details about measurement units in Finale.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `text` | `string` | the string to convert |

| Return type | Description |
| ----------- | ----------- |
| `number` | the converted number of EVPUs |

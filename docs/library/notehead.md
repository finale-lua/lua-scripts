# Notehead

- [change_shape](#change_shape)

## change_shape

```lua
notehead.change_shape(note, shape)
```

Changes the given notehead to a specified notehead descriptor string. Currently only supports "diamond".

| Input | Type | Description |
| --- | --- | --- |
| `note` | `FCNote` |  |
| `shape` | `lua string` |  |

| Output type | Description |
| --- | --- |
| `FCNoteheadMod` | the new notehead mod record created |
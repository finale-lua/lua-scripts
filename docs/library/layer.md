# Layer

## Functions

- [copy(region, source_layer, destination_layer, clone_articulations)](#copy)
- [clear(region, layer_to_clear)](#clear)
- [swap(region, swap_a, swap_b)](#swap)
- [max_layers()](#max_layers)

### copy

```lua
layer.copy(region, source_layer, destination_layer, clone_articulations)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/layer.lua#L16)

Duplicates the notes from the source layer to the destination. The source layer remains untouched.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `region` | `FCMusicRegion` | the region to be copied |
| `source_layer` | `number` | the number (1-4) of the layer to duplicate |
| `destination_layer` | `number` | the number (1-4) of the layer to be copied to |
| `clone_articulations` (optional) | `boolean` | if true, clone articulations (default is false) |

### clear

```lua
layer.clear(region, layer_to_clear)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/layer.lua#L56)

Clears all entries from a given layer.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `region` | `FCMusicRegion` | the region to be cleared |
| `layer_to_clear` | `number` | the number (1-4) of the layer to clear |

### swap

```lua
layer.swap(region, swap_a, swap_b)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/layer.lua#L80)

Swaps the entries from two different layers (e.g. 1-->2 and 2-->1).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `region` | `FCMusicRegion` | the region to be swapped |
| `swap_a` | `number` | the number (1-4) of the first layer to be swapped |
| `swap_b` | `number` | the number (1-4) of the second layer to be swapped |

### max_layers

```lua
layer.max_layers()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/library/layer.lua#L126)

Return the maximum number of layers available in the current document.

| Return type | Description |
| ----------- | ----------- |
| `number` | maximum number of available layers |

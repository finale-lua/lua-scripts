# Layer

- [copy](#copy)
- [clear](#clear)
- [swap](#swap)

## copy

```lua
layer.copy(source_layer, destination_layer)
```

Duplicates the notes from the source layer to the destination. The source layer remains untouched.


| Input | Type | Description |
| --- | --- | --- |
| `region` | `FCMusicRegion` | the region to be copied |
@ source_layer number the number (1-4) of the layer to duplicate
@ destination_layer number the number (1-4) of the layer to be copied to

## clear

```lua
layer.clear(layer_to_clear)
```

Clears all entries from a given layer.


| Input | Type | Description |
| --- | --- | --- |
| `region` | `FCMusicRegion` | the region to be cleared |
@ layer_to_clear number the number (1-4) of the layer to clear

## swap

```lua
layer.swap(swap_a, swap_b)
```

Swaps the entries from two different layers (e.g. 1-->2 and 2-->1).


| Input | Type | Description |
| --- | --- | --- |
| `region` | `FCMusicRegion` | the region to be swapped |
@ swap_a number the number (1-4) of the first layer to be swapped
@ swap_b number the number (1-4) of the second layer to be swapped
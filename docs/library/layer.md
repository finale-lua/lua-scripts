# Layer

- [copy](#copy)
- [clear](#clear)
- [swap](#swap)

## copy

```lua
layer.copy(region)
```


Duplicates the notes from the source layer to the destination. The source layer remains untouched.

@ source_layer number the number (1-4) of the layer to duplicate
@ destination_layer number the number (1-4) of the layer to be copied to

| Input | Type | Description |
| ----- | ---- | ----------- |
| `region` | `FCMusicRegion` | the region to be copied |

## clear

```lua
layer.clear(region)
```


Clears all entries from a given layer.

@ layer_to_clear number the number (1-4) of the layer to clear

| Input | Type | Description |
| ----- | ---- | ----------- |
| `region` | `FCMusicRegion` | the region to be cleared |

## swap

```lua
layer.swap(region)
```


Swaps the entries from two different layers (e.g. 1-->2 and 2-->1).

@ swap_a number the number (1-4) of the first layer to be swapped
@ swap_b number the number (1-4) of the second layer to be swapped

| Input | Type | Description |
| ----- | ---- | ----------- |
| `region` | `FCMusicRegion` | the region to be swapped |

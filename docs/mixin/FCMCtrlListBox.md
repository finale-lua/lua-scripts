# FCMCtrlListBox

## Summary of Modifications
- Setters that accept `FCString` will also accept a Lua `string` or `number`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
- Setters that accept `FCStrings` will also accept multiple arguments of `FCString`, Lua `string`, or `number`.
- Added numerous methods for accessing and modifying listbox items.
- Added `SelectionChange` custom control event.
- Added hooks into control state preservation.

## Functions

- [Init(self)](#init)
- [StoreState(self)](#storestate)
- [RestoreState(self)](#restorestate)
- [Clear(self)](#clear)
- [GetCount(self)](#getcount)
- [GetSelectedItem(self)](#getselecteditem)
- [SetSelectedItem(self, index)](#setselecteditem)
- [SetSelectedLast(self)](#setselectedlast)
- [HasSelection(self)](#hasselection)
- [ItemExists(self, index)](#itemexists)
- [AddString(self, str)](#addstring)
- [AddStringLocalized(self)](#addstringlocalized)
- [AddStrings(self)](#addstrings)
- [AddStringsLocalized(self)](#addstringslocalized)
- [GetStrings(self, strs)](#getstrings)
- [SetStrings(self)](#setstrings)
- [GetItemText(self, index, str)](#getitemtext)
- [SetItemText(self, index, str)](#setitemtext)
- [GetSelectedString(self, str)](#getselectedstring)
- [SetSelectedString(self, str)](#setselectedstring)
- [InsertItem(self, index, str)](#insertitem)
- [DeleteItem(self, index)](#deleteitem)
- [HandleSelectionChange(control, last_item, last_item_text, is_deleted)](#handleselectionchange)
- [AddHandleSelectionChange(self, callback)](#addhandleselectionchange)
- [RemoveHandleSelectionChange(self, callback)](#removehandleselectionchange)

### Init

```lua
fcmctrllistbox.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L33)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### StoreState

```lua
fcmctrllistbox.StoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L55)

**[Fluid] [Internal] [Override]**

Override Changes:
- Stores `FCMCtrlListBox`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### RestoreState

```lua
fcmctrllistbox.RestoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L72)

**[Fluid] [Internal] [Override]**

Override Changes:
- Restores `FCMCtrlListBox`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### Clear

```lua
fcmctrllistbox.Clear(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L95)

**[Fluid] [Override]**

Override Changes:
- Ensures that `SelectionChange` event is triggered.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### GetCount

```lua
fcmctrllistbox.GetCount(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L122)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetSelectedItem

```lua
fcmctrllistbox.GetSelectedItem(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L141)

**[Override]**

Override Changes:
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetSelectedItem

```lua
fcmctrllistbox.SetSelectedItem(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L161)

**[Fluid] [Override]**

Override Changes:
- Ensures that `SelectionChange` event is triggered.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` |  |

### SetSelectedLast

```lua
fcmctrllistbox.SetSelectedLast(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L185)

**[Override]**

Override Changes:
- Ensures that `SelectionChange` event is triggered.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if a selection was possible. |

### HasSelection

```lua
fcmctrllistbox.HasSelection(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L208)

Checks if the popup has a selection. If the parent window does not exist (ie `WindowExists() == false`), this result is theoretical.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if something is selected, `false` if no selection. |

### ItemExists

```lua
fcmctrllistbox.ItemExists(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L221)

Checks if there is an item at the specified index.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` | 0-based item index. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if the item exists, `false` if it does not exist. |

### AddString

```lua
fcmctrllistbox.AddString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L239)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `str` | `FCString \| string \| number` |  |

### AddStringLocalized

```lua
fcmctrllistbox.AddStringLocalized(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L262)

**[Fluid]**

Localized version of `AddString`.

@ key (string | FCString, number) The key into the localization table. If there is no entry in the appropriate localization table, the key is the text.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### AddStrings

```lua
fcmctrllistbox.AddStrings(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L274)

**[Fluid]**

Adds multiple strings to the list box.

@ ... (FCStrings | FCString | string | number | table)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### AddStringsLocalized

```lua
fcmctrllistbox.AddStringsLocalized(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L286)

**[Fluid]**

Adds multiple localized strings to the combobox.

@ ... (FCStrings | FCString | string | number) keys of strings to be added. If no localization is found, the key is added.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### GetStrings

```lua
fcmctrllistbox.GetStrings(self, strs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L299)

**[?Fluid]**

Returns a copy of all strings in the list box.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `strs` (optional) | `FCStrings` | An optional `FCStrings` object to populate with strings. |

| Return type | Description |
| ----------- | ----------- |
| `table` | If `strs` is omitted, a table of strings (1-indexed - beware if accessing by key!). |

### SetStrings

```lua
fcmctrllistbox.SetStrings(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L322)

**[Fluid] [Override]**

Override Changes:
- Accepts multiple arguments.
- Accepts `FCString`, Lua `string` or `number` in addition to `FCStrings`.
- Hooks into control state preservation.

@ ... (FCStrings | FCString | string | number) `number`s will be automatically cast to `string`

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### GetItemText

```lua
fcmctrllistbox.GetItemText(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L362)

**[?Fluid]**

Returns the text for an item in the list box.
This method works in all JW/RGP Lua versions and irrespective of whether `InitWindow` has been called.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` | 0-based index of item. |
| `str` (optional) | `FCString` | Optional `FCString` object to populate with text. |

| Return type | Description |
| ----------- | ----------- |
| `string` | Returned if `str` is omitted. |

### SetItemText

```lua
fcmctrllistbox.SetItemText(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L391)

**[Fluid] [Override]**

Override Changes:
- Added polyfill for JWLua.
- Is valid irrespective of whether `InitWindow` has been called.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` | 0-based index of item. |
| `str` | `FCString \| string \| number` |  |

### GetSelectedString

```lua
fcmctrllistbox.GetSelectedString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L433)

**[?Fluid]**

Returns the text for the item that is currently selected.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `str` (optional) | `FCString` | Optional `FCString` object to populate with text. If no item is currently selected, it will be populated with an empty string. |

| Return type | Description |
| ----------- | ----------- |
| `string \\| nil` | Returned if `str` is omitted. `nil` if no item is selected. |

### SetSelectedString

```lua
fcmctrllistbox.SetSelectedString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L456)

**[Fluid]**

Sets the currently selected item to the first item with a matching text value.
If no match is found, the current selected item will remain selected. Matches are case-sensitive.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `str` | `FCString \| string \| number` |  |

### InsertItem

```lua
fcmctrllistbox.InsertItem(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L482)

**[Fluid] [PDKPort]**

Inserts a string at the specified index.
If index is <= 0, will insert at the start.
If index is >= GetCount(), will insert at the end.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` | 0-based index to insert new item. |
| `str` | `FCString \| string \| number` | The value to insert. |

### DeleteItem

```lua
fcmctrllistbox.DeleteItem(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L521)

**[Fluid] [PDK Port]**
Deletes an item from the list box.
If the currently selected item is deleted, items will be deselected (ie set to -1)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` | 0-based index of item to delete. |

### HandleSelectionChange

```lua
fcmctrllistbox.HandleSelectionChange(control, last_item, last_item_text, is_deleted)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L573)

**[Callback Template]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCMCtrlListBox` |  |
| `last_item` | `number` | The 0-based index of the previously selected item. If no item was selected, the value will be `-1`. |
| `last_item_text` | `string` | The text value of the previously selected item. |
| `is_deleted` | `boolean` | `true` if the previously selected item is no longer in the control. |

### AddHandleSelectionChange

```lua
fcmctrllistbox.AddHandleSelectionChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L596)

**[Fluid]**

Adds a handler for SelectionChange events.
If the selected item is changed by a handler, that same handler will not be called again for that change.

The event will fire in the following cases:
- When the window is created (if an item is selected)
- Change in selected item by user or programatically (inserting an item before or after will not trigger the event)
- Changing the text value of the currently selected item
- Deleting the currently selected item
- Clearing the control (including calling `Clear` and `SetStrings`)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `callback` | `function` | See `HandleSelectionChange` for callback signature. |

### RemoveHandleSelectionChange

```lua
fcmctrllistbox.RemoveHandleSelectionChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlListBox.lua#L601)

**[Fluid]**

Removes a handler added with `AddHandleSelectionChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `callback` | `function` | Handler to remove. |

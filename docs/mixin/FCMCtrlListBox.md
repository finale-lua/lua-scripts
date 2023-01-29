# FCMCtrlListBox

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
- Setters that accept `FCStrings` now also accept multiple arguments of `FCString`, Lua `string`, or `number`.
- Numerous additional methods for accessing and modifying listbox items.
- Added `SelectionChange` custom control event.
- Added hooks for restoring control state

## Functions

- [Init(self)](#init)
- [StoreState(self)](#storestate)
- [RestoreState(self)](#restorestate)
- [Clear(self)](#clear)
- [GetCount(self)](#getcount)
- [GetSelectedItem(self)](#getselecteditem)
- [SetSelectedItem(self, index)](#setselecteditem)
- [SetSelectedLast(self)](#setselectedlast)
- [IsItemSelected(self)](#isitemselected)
- [ItemExists(self, index)](#itemexists)
- [AddString(self, str)](#addstring)
- [AddStrings(self)](#addstrings)
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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L33)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### StoreState

```lua
fcmctrllistbox.StoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L48)

**[Fluid] [Internal] [Override]**
Stores the control's current state.
Do not disable this method. Override as needed but call the parent first.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### RestoreState

```lua
fcmctrllistbox.RestoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L62)

**[Fluid] [Internal] [Override]**
Restores the control's stored state.
Do not disable this method. Override as needed but call the parent first.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### Clear

```lua
fcmctrllistbox.Clear(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L81)

**[Fluid] [Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### GetCount

```lua
fcmctrllistbox.GetCount(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L106)

**[Override]**
Hooks into control state restoration.

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L123)

**[Override]**
Hooks into control state restoration.

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L141)

**[Fluid] [Override]**
Ensures that SelectionChange is triggered.
Also hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` |  |

### SetSelectedLast

```lua
fcmctrllistbox.SetSelectedLast(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L162)

**[Override]**
Ensures that `SelectionChange` is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if a selection was possible. |

### IsItemSelected

```lua
fcmctrllistbox.IsItemSelected(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L185)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L198)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L214)

**[Fluid] [Override]**

Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `str` | `FCString\|string\|number` |  |

### AddStrings

```lua
fcmctrllistbox.AddStrings(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L239)

**[Fluid]**
Adds multiple strings to the list box.

@ ... (FCStrings|FCString|string|number)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### GetStrings

```lua
fcmctrllistbox.GetStrings(self, strs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L263)

Returns a copy of all strings in the list box.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `strs` (optional) | `FCStrings` | An optional `FCStrings` object to populate with strings. |

| Return type | Description |
| ----------- | ----------- |
| `table` | A table of strings (1-indexed - beware if accessing keys!). |

### SetStrings

```lua
fcmctrllistbox.SetStrings(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L286)

**[Fluid] [Override]**
Accepts multiple arguments.

@ ... (FCStrings|FCString|string|number) `number`s will be automatically cast to `string`

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### GetItemText

```lua
fcmctrllistbox.GetItemText(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L323)

Returns the text for an item in the list box.
This method works in all JW/RGP Lua versions and irrespective of whether `InitWindow` has been called.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` | 0-based index of item. |
| `str` (optional) | `FCString` | Optional `FCString` object to populate with text. |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### SetItemText

```lua
fcmctrllistbox.SetItemText(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L348)

**[Fluid] [PDK Port]**
Sets the text for an item.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` | 0-based index of item. |
| `str` | `FCString\|string\|number` |  |

### GetSelectedString

```lua
fcmctrllistbox.GetSelectedString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L395)

Returns the text for the item that is currently selected.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `str` (optional) | `FCString` | Optional `FCString` object to populate with text. If no item is currently selected, it will be populated with an empty string. |

| Return type | Description |
| ----------- | ----------- |
| `string\\|nil` | `nil` if no item is currently selected. |

### SetSelectedString

```lua
fcmctrllistbox.SetSelectedString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L425)

**[Fluid]**
Sets the currently selected item to the first item with a matching text value.
If no match is found, the current selected item will remain selected. Matches are case-sensitive.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `str` | `FCString\|string\|number` |  |

### InsertItem

```lua
fcmctrllistbox.InsertItem(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L450)

**[Fluid] [PDKPort]**
Inserts a string at the specified index.
If index is <= 0, will insert at the start.
If index is >= Count, will insert at the end.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` | 0-based index to insert new item. |
| `str` | `FCString\|string\|number` | The value to insert. |

### DeleteItem

```lua
fcmctrllistbox.DeleteItem(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L495)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L553)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L574)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlListBox.lua#L579)

**[Fluid]**
Removes a handler added with `AddHandleSelectionChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `callback` | `function` | Handler to remove. |

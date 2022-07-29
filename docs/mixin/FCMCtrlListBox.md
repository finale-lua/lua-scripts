# FCMCtrlListBox

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
- Setters that accept `FCStrings` now also accept multiple arguments of `FCString`, Lua `string`, or `number`.
- Numerous additional methods for accessing and modifying listbox items.
- Added `SelectionChange` custom control event.

## Functions

- [Init(self)](#init)
- [Clear(self)](#clear)
- [SetSelectedItem(self, index)](#setselecteditem)
- [SetSelectedLast(self)](#setselectedlast)
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

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### Clear

```lua
fcmctrllistbox.Clear(self)
```

**[Fluid] [Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

### SetSelectedItem

```lua
fcmctrllistbox.SetSelectedItem(self, index)
```

**[Fluid] [Override]**
Ensures that `SelectionChange` is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `index` | `number` |  |

### SetSelectedLast

```lua
fcmctrllistbox.SetSelectedLast(self)
```

**[Override]**
Ensures that `SelectionChange` is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if a selection was possible. |

### AddString

```lua
fcmctrllistbox.AddString(self, str)
```

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

**[Fluid]**
Sets the currently selected item to the first item with a matching text value.

If no match is found, the current selected item will remain selected.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `str` | `FCString\|string\|number` |  |

### InsertItem

```lua
fcmctrllistbox.InsertItem(self, index, str)
```

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

**[Fluid]**
Removes a handler added with `AddHandleSelectionChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlListBox` |  |
| `callback` | `function` | Handler to remove. |

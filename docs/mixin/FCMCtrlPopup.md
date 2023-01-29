# FCMCtrlPopup

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
- Setters that accept `FCStrings` now also accept multiple arguments of `FCString`, Lua `string`, or `number`.
- Numerous additional methods for accessing and modifying popup items.
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
- [InsertString(self, index, str)](#insertstring)
- [DeleteItem(self, index)](#deleteitem)
- [HandleSelectionChange(control, last_item, last_item_text, is_deleted)](#handleselectionchange)
- [AddHandleSelectionChange(self, callback)](#addhandleselectionchange)
- [RemoveHandleSelectionChange(self, callback)](#removehandleselectionchange)

### Init

```lua
fcmctrlpopup.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L34)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

### StoreState

```lua
fcmctrlpopup.StoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L50)

**[Fluid] [Internal] [Override]**
Stores the control's current state.
Do not disable this method. Override as needed but call the parent first.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

### RestoreState

```lua
fcmctrlpopup.RestoreState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L64)

**[Fluid] [Internal] [Override]**
Restores the control's stored state.
Do not disable this method. Override as needed but call the parent first.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

### Clear

```lua
fcmctrlpopup.Clear(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L83)

**[Fluid] [Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

### GetCount

```lua
fcmctrlpopup.GetCount(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L109)

**[Override]**
Hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### GetSelectedItem

```lua
fcmctrlpopup.GetSelectedItem(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L126)

**[Override]**
Hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetSelectedItem

```lua
fcmctrlpopup.SetSelectedItem(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L144)

**[Fluid] [Override]**
Ensures that SelectionChange is triggered.
Also hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `index` | `number` |  |

### SetSelectedLast

```lua
fcmctrlpopup.SetSelectedLast(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L164)

**[Fluid]**
Selects the last item in the popup. If popup is empty, will be set to -1.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

### IsItemSelected

```lua
fcmctrlpopup.IsItemSelected(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L176)

Checks if the popup has a selection. If the parent window does not exist (ie `WindowExists() == false`), this result is theoretical.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if something is selected, `false` if no selection. |

### ItemExists

```lua
fcmctrlpopup.ItemExists(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L189)

Checks if there is an item at the specified index.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `index` | `number` | 0-based item index. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if the item exists, `false` if it does not exist. |

### AddString

```lua
fcmctrlpopup.AddString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L206)

**[Fluid] [Override]**

Accepts Lua `string` and `number` in addition to `FCString`.
Also hooks into control state restoration.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `str` | `FCString\|string\|number` |  |

### AddStrings

```lua
fcmctrlpopup.AddStrings(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L231)

**[Fluid]**
Adds multiple strings to the popup.

@ ... (FCStrings|FCString|string|number)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

### GetStrings

```lua
fcmctrlpopup.GetStrings(self, strs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L255)

Returns a copy of all strings in the popup.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `strs` (optional) | `FCStrings` | An optional `FCStrings` object to populate with strings. |

| Return type | Description |
| ----------- | ----------- |
| `table` | A table of strings (1-indexed - beware when accessing by key!). |

### SetStrings

```lua
fcmctrlpopup.SetStrings(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L278)

**[Fluid] [Override]**
Accepts multiple arguments.

@ ... (FCStrings|FCString|string|number) `number`s will be automatically cast to `string`

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |

### GetItemText

```lua
fcmctrlpopup.GetItemText(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L314)

Returns the text for an item in the popup.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `index` | `number` | 0-based index of item. |
| `str` (optional) | `FCString` | Optional `FCString` object to populate with text. |

| Return type | Description |
| ----------- | ----------- |
| `string\\|nil` | `nil` if the item doesn't exist |

### SetItemText

```lua
fcmctrlpopup.SetItemText(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L339)

**[Fluid] [PDK Port]**
Sets the text for an item.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `index` | `number` | 0-based index of item. |
| `str` | `FCString\|string\|number` |  |

### GetSelectedString

```lua
fcmctrlpopup.GetSelectedString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L378)

Returns the text for the item that is currently selected.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `str` (optional) | `FCString` | Optional `FCString` object to populate with text. If no item is currently selected, it will be populated with an empty string. |

| Return type | Description |
| ----------- | ----------- |
| `string\\|nil` | `nil` if no item is currently selected. |

### SetSelectedString

```lua
fcmctrlpopup.SetSelectedString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L409)

**[Fluid]**
Sets the currently selected item to the first item with a matching text value.

If no match is found, the current selected item will remain selected. Matching is case-sensitive.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `str` | `FCString\|string\|number` |  |

### InsertString

```lua
fcmctrlpopup.InsertString(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L434)

**[Fluid] [PDKPort]**
Inserts a string at the specified index.
If index is <= 0, will insert at the start.
If index is >= Count, will insert at the end.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `index` | `number` | 0-based index to insert new item. |
| `str` | `FCString\|string\|number` | The value to insert. |

### DeleteItem

```lua
fcmctrlpopup.DeleteItem(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L479)

**[Fluid] [PDK Port]**
Deletes an item from the popup.
If the currently selected item is deleted, items will be deselected (ie set to -1)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `index` | `number` | 0-based index of item to delete. |

### HandleSelectionChange

```lua
fcmctrlpopup.HandleSelectionChange(control, last_item, last_item_text, is_deleted)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L537)

**[Callback Template]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCMCtrlPopup` |  |
| `last_item` | `number` | The 0-based index of the previously selected item. If no item was selected, the value will be `-1`. |
| `last_item_text` | `string` | The text value of the previously selected item. |
| `is_deleted` | `boolean` | `true` if the previously selected item is no longer in the control. |

### AddHandleSelectionChange

```lua
fcmctrlpopup.AddHandleSelectionChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L558)

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
| `self` | `FCMCtrlPopup` |  |
| `callback` | `function` | See `HandleSelectionChange` for callback signature. |

### RemoveHandleSelectionChange

```lua
fcmctrlpopup.RemoveHandleSelectionChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCtrlPopup.lua#L563)

**[Fluid]**
Removes a handler added with `AddHandleSelectionChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlPopup` |  |
| `callback` | `function` | Handler to remove. |

# FCXCtrlPageSizePopup

*Extends `FCMCtrlPopup`*

A popup for selecting a defined page size. The dimensions in the current unit are displayed along side each page size in the same way as the Page Format dialog.

## Summary of Modifications
- `SelectionChange` has been overridden with a new event, `PageSizeChange`, to match the specialised functionality.
- Setting and getting is now only performed based on page size.

## Disabled Methods
The following inherited methods have been disabled:
- `Clear`
- `AddString`
- `AddStrings`
- `SetStrings`
- `GetSelectedItem`
- `SetSelectedItem`
- `SetSelectedLast`
- `ItemExists`
- `InsertString`
- `DeleteItem`
- `GetItemText`
- `SetItemText`
- `AddHandleSelectionChange`
- `RemoveHandleSelectionChange`

## Functions

- [Init(self)](#init)
- [GetSelectedPageSize(self, str)](#getselectedpagesize)
- [SetSelectedPageSize(self, size)](#setselectedpagesize)
- [UpdateMeasurementUnit(self)](#updatemeasurementunit)
- [HandlePageSizeChange(control, last_page_size)](#handlepagesizechange)
- [AddHandlePageSizeChange(self, callback)](#addhandlepagesizechange)
- [RemoveHandlePageSizeChange(self, callback)](#removehandlepagesizechange)

### Init

```lua
fcxctrlpagesizepopup.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCtrlPageSizePopup.lua#L83)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlPageSizePopup` |  |

### GetSelectedPageSize

```lua
fcxctrlpagesizepopup.GetSelectedPageSize(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCtrlPageSizePopup.lua#L104)

**[?Fluid]**

Returns the selected page size.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlPageSizePopup` |  |
| `str` (optional) | `FCString` | Optional `FCString` to populate with page size. |

| Return type | Description |
| ----------- | ----------- |
| `string \\| nil` | Returned if `str` is omitted. The page size or `nil` if nothing is selected. |

### SetSelectedPageSize

```lua
fcxctrlpagesizepopup.SetSelectedPageSize(self, size)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCtrlPageSizePopup.lua#L129)

**[Fluid]**

Sets the selected page size. Must be a valid page size.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlPageSizePopup` |  |
| `size` | `FCString \| string` | Name of page size (case-sensitive). |

### UpdateMeasurementUnit

```lua
fcxctrlpagesizepopup.UpdateMeasurementUnit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCtrlPageSizePopup.lua#L159)

**[Fluid] [Internal]**

Checks the parent window's measurement and updates the displayed page dimensions if necessary.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlPageSizePopup` |  |

### HandlePageSizeChange

```lua
fcxctrlpagesizepopup.HandlePageSizeChange(control, last_page_size)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCtrlPageSizePopup.lua#L173)

**[Callback Template]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCXCtrlPageSizePopup` |  |
| `last_page_size` | `string` | The last page size that was selected. If no page size was previously selected, will be `false`. |

### AddHandlePageSizeChange

```lua
fcxctrlpagesizepopup.AddHandlePageSizeChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCtrlPageSizePopup.lua#L193)

**[Fluid]**

Adds a handler for `PageSizeChange` events.
If the selected item is changed by a handler, that same handler will not be called again for that change.

The event will fire in the following cases:
- When the window is created (if an item is selected)
- Change in selected item by user or programatically (inserting an item before or after will not trigger the event)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlPageSizePopup` |  |
| `callback` | `function` | See `HandlePageSizeChange` for callback signature. |

### RemoveHandlePageSizeChange

```lua
fcxctrlpagesizepopup.RemoveHandlePageSizeChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCtrlPageSizePopup.lua#L198)

**[Fluid]**

Removes a handler added with `AddHandlePageSizeChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlPageSizePopup` |  |
| `callback` | `function` | Handler to remove. |

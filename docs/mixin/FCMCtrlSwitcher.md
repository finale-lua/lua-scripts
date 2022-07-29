# FCMCtrlSwitcher

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- Additional methods for accessing and adding pages and page titles.
- Added `PageChange` custom control event.

## Functions

- [Init(self)](#init)
- [AddPage(self, title)](#addpage)
- [AddPages(self)](#addpages)
- [AttachControlByTitle(self, control, title)](#attachcontrolbytitle)
- [SetSelectedPage(self, index)](#setselectedpage)
- [SetSelectedPageByTitle(self, title)](#setselectedpagebytitle)
- [GetSelectedPageTitle(self, title)](#getselectedpagetitle)
- [GetPageTitle(self, index, str)](#getpagetitle)
- [HandlePageChange(control, last_page, last_page_title)](#handlepagechange)
- [AddHandlePageChange(self, callback)](#addhandlepagechange)
- [RemoveHandlePageChange(self, callback)](#removehandlepagechange)

### Init

```lua
fcmctrlswitcher.Init(self)
```

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |

### AddPage

```lua
fcmctrlswitcher.AddPage(self, title)
```

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `title` | `FCString\|string\|number` |  |

### AddPages

```lua
fcmctrlswitcher.AddPages(self)
```

**[Fluid]**
Adds multiple pages, one page for each argument.

@ ... (FCString|string|number)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |

### AttachControlByTitle

```lua
fcmctrlswitcher.AttachControlByTitle(self, control, title)
```

Attaches a control to a page.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `control` | `FCMControl` | The control to attach. |
| `title` | `FCString\|string\|number` | The title of the page. Must be an exact match. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### SetSelectedPage

```lua
fcmctrlswitcher.SetSelectedPage(self, index)
```

**[Fluid] [Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `index` | `number` |  |

### SetSelectedPageByTitle

```lua
fcmctrlswitcher.SetSelectedPageByTitle(self, title)
```

**[Fluid]**
Set the selected page by its title. If the page is not found, an error will be thrown.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `title` | `FCString\|string\|number` | Title of page to select. Must be an exact match. |

### GetSelectedPageTitle

```lua
fcmctrlswitcher.GetSelectedPageTitle(self, title)
```

Returns the title of the currently selected page.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `title` (optional) | `FCString` | Optional `FCString` object to populate. |

| Return type | Description |
| ----------- | ----------- |
| `string\\|nil` | Nil if no page is selected |

### GetPageTitle

```lua
fcmctrlswitcher.GetPageTitle(self, index, str)
```

Returns the title of a page.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `index` | `number` | The 0-based index of the page. |
| `str` (optional) | `FCString` | An optional `FCString` object to populate. |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### HandlePageChange

```lua
fcmctrlswitcher.HandlePageChange(control, last_page, last_page_title)
```

**[Callback Template]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `control` | `FCMCtrlSwitcher` | The control on which the event occurred. |
| `last_page` | `number` | The 0-based index of the previously selected page. If no page was previously selected, this will be `-1` (eg when the window is created). |
| `last_page_title` | `string` | The title of the previously selected page. |

### AddHandlePageChange

```lua
fcmctrlswitcher.AddHandlePageChange(self, callback)
```

**[Fluid]**
Adds an event listener for PageChange events.
The event fires when:
- The window is created (if pages have been added)
- The user switches page
- The selected page is changed programmatically (if the selected page is changed within a handler, that *same* handler will not be called for that change)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `callback` | `function` | See `HandlePageChange` for callback signature. |

### RemoveHandlePageChange

```lua
fcmctrlswitcher.RemoveHandlePageChange(self, callback)
```

**[Fluid]**
Removes a handler added with `AddHandlePageChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `callback` | `function` |  |

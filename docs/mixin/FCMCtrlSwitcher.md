# FCMCtrlSwitcher

## Summary of Modifications
- Setters that accept `FCString` will also accept Lua `string` and `number`.
- Methods that returned a boolean to indicate success/failure now throw an error instead.
- Added methods for accessing and adding pages.
- Added `PageChange` custom control event.

## Functions

- [Init(self)](#init)
- [AddPage(self, title)](#addpage)
- [AddPages(self)](#addpages)
- [AttachControl(self, control, pageindex)](#attachcontrol)
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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L30)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |

### AddPage

```lua
fcmctrlswitcher.AddPage(self, title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L52)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `title` | `FCString \| string \| number` |  |

### AddPages

```lua
fcmctrlswitcher.AddPages(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L72)

**[Fluid]**

Adds multiple pages, one page for each argument.

@ ... (FCString | string | number)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |

### AttachControl

```lua
fcmctrlswitcher.AttachControl(self, control, pageindex)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L92)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `control` | `FCControl \| FCMControl` |  |
| `pageindex` | `number` |  |

### AttachControlByTitle

```lua
fcmctrlswitcher.AttachControlByTitle(self, control, title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L110)

**[Fluid]**

Attaches a control to a page by its title.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `control` | `FCControl \| FCMControl` | The control to attach. |
| `title` | `FCString \| string \| number` | The title of the page. Must be an exact match. |

### SetSelectedPage

```lua
fcmctrlswitcher.SetSelectedPage(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L134)

**[Fluid] [Override]**

Override Changes:
- Ensures that `PageChange` event is triggered.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `index` | `number` |  |

### SetSelectedPageByTitle

```lua
fcmctrlswitcher.SetSelectedPageByTitle(self, title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L152)

**[Fluid]**

Set the selected page by its title. If the page is not found, an error will be thrown.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `title` | `FCString \| string \| number` | Title of page to select. Must be an exact, case-sensitive match. |

### GetSelectedPageTitle

```lua
fcmctrlswitcher.GetSelectedPageTitle(self, title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L173)

**[?Fluid]**

Retrieves the title of the currently selected page.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `title` (optional) | `FCString` | Optional `FCString` object to populate. |

| Return type | Description |
| ----------- | ----------- |
| `string \\| nil` | Returned if `title` is omitted. `nil` if no page is selected |

### GetPageTitle

```lua
fcmctrlswitcher.GetPageTitle(self, index, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L201)

**[?Fluid]**

Retrieves the title of a page.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `index` | `number` | The 0-based index of the page. |
| `str` (optional) | `FCString` | An optional `FCString` object to populate. |

| Return type | Description |
| ----------- | ----------- |
| `string` | Returned if `str` is omitted. |

### HandlePageChange

```lua
fcmctrlswitcher.HandlePageChange(control, last_page, last_page_title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L226)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L245)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlSwitcher.lua#L250)

**[Fluid]**

Removes a handler added with `AddHandlePageChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlSwitcher` |  |
| `callback` | `function` |  |

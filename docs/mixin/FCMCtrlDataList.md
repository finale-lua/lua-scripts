# FCMCtrlDataList

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- Handlers for the `DataListCheck` and `DataListSelect` events can now be set on a control.

## Functions

- [AddColumn(self, title, columnwidth)](#addcolumn)
- [SetColumnTitle(self, columnindex, title)](#setcolumntitle)
- [AddHandleCheck(self, callback)](#addhandlecheck)
- [RemoveHandleCheck(self, callback)](#removehandlecheck)
- [AddHandleSelect(self, callback)](#addhandleselect)
- [RemoveHandleSelect(self, callback)](#removehandleselect)

### AddColumn

```lua
fcmctrldatalist.AddColumn(self, title, columnwidth)
```

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlDataList` |  |
| `title` | `FCString\|string\|number` |  |
| `columnwidth` | `number` |  |

### SetColumnTitle

```lua
fcmctrldatalist.SetColumnTitle(self, columnindex, title)
```

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlDataList` |  |
| `columnindex` | `number` |  |
| `title` | `FCString\|string\|number` |  |

### AddHandleCheck

```lua
fcmctrldatalist.AddHandleCheck(self, callback)
```

**[Fluid]**
Adds a handler for DataListCheck events.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlDataList` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListCheck` in the PDK for callback signature. |

### RemoveHandleCheck

```lua
fcmctrldatalist.RemoveHandleCheck(self, callback)
```

**[Fluid]**
Removes a handler added with `AddHandleCheck`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlDataList` |  |
| `callback` | `function` |  |

### AddHandleSelect

```lua
fcmctrldatalist.AddHandleSelect(self, callback)
```

**[Fluid]**
Adds a handler for DataListSelect events.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature. |

### RemoveHandleSelect

```lua
fcmctrldatalist.RemoveHandleSelect(self, callback)
```

**[Fluid]**
Removes a handler added with `AddHandleSelect`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMControl` |  |
| `callback` | `function` |  |

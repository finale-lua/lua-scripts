# FCMCtrlDataList

## Summary of Modifications
- Setters that accept `FCString` will also accept a Lua `string` or `number`.
- Added methods to allow handlers for the `DataListCheck` and `DataListSelect` events be set directly on the control.

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlDataList.lua#L30)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlDataList` |  |
| `title` | `FCString \| string \| number` |  |
| `columnwidth` | `number` |  |

### SetColumnTitle

```lua
fcmctrldatalist.SetColumnTitle(self, columnindex, title)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlDataList.lua#L49)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlDataList` |  |
| `columnindex` | `number` |  |
| `title` | `FCString \| string \| number` |  |

### AddHandleCheck

```lua
fcmctrldatalist.AddHandleCheck(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlDataList.lua#L72)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlDataList.lua#L77)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlDataList.lua#L95)

**[Fluid]**

Adds a handler for `DataListSelect` events.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlDataList` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature. |

### RemoveHandleSelect

```lua
fcmctrldatalist.RemoveHandleSelect(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlDataList.lua#L100)

**[Fluid]**

Removes a handler added with `AddHandleSelect`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlDataList` |  |
| `callback` | `function` |  |

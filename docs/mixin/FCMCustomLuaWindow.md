# FCMCustomLuaWindow

Summary of modifications:
- All `Register*` methods (apart from `RegisterHandleControlEvent` and `RegisterHandleTimer`) have accompanying `Add*` and `Remove*` methods to enable multiple handlers to be added per event.
- Handlers for non-control events can receive the window object as an optional additional parameter.
- Control handlers are passed original object to preserve mixin data.
- Added custom callback queue which can be used by custom events to add dispatchers that will run with the next control event.
- Added `HasBeenShown` method for checking if the window has been shown
- Added methods for the automatic restoration of previous window position when showing (RGPLua > 0.60) for use with `finenv.RetainLuaState` and modeless windows.
- Added DebugClose option to assist with debugging (if ALT or SHIFT key is pressed when window is closed and debug mode is enabled, finenv.RetainLuaState will be set to false)

## Functions

- [Init(self)](#init)
- [RegisterHandleCommand(self, callback)](#registerhandlecommand)
- [RegisterHandleDataListCheck(self, callback)](#registerhandledatalistcheck)
- [RegisterHandleDataListSelect(self, callback)](#registerhandledatalistselect)
- [RegisterHandleUpDownPressed(self, callback)](#registerhandleupdownpressed)
- [CancelButtonPressed(window)](#cancelbuttonpressed)
- [RegisterHandleCancelButtonPressed(self, callback)](#registerhandlecancelbuttonpressed)
- [OkButtonPressed(window)](#okbuttonpressed)
- [RegisterHandleOkButtonPressed(self, callback)](#registerhandleokbuttonpressed)
- [InitWindow(window)](#initwindow)
- [RegisterInitWindow(self, callback)](#registerinitwindow)
- [CloseWindow(window)](#closewindow)
- [RegisterCloseWindow(self, callback)](#registerclosewindow)
- [AddHandleCommand(self, callback)](#addhandlecommand)
- [AddHandleDataListCheck(self, callback)](#addhandledatalistcheck)
- [AddHandleDataListSelect(self, callback)](#addhandledatalistselect)
- [AddHandleUpDownPressed(self, callback)](#addhandleupdownpressed)
- [AddHandleCancelButtonPressed(self, callback)](#addhandlecancelbuttonpressed)
- [AddHandleOkButtonPressed(self, callback)](#addhandleokbuttonpressed)
- [AddInitWindow(self, callback)](#addinitwindow)
- [AddCloseWindow(self, callback)](#addclosewindow)
- [RemoveHandleCommand(self, callback)](#removehandlecommand)
- [RemoveHandleDataListCheck(self, callback)](#removehandledatalistcheck)
- [RemoveHandleDataListSelect(self, callback)](#removehandledatalistselect)
- [RemoveHandleUpDownPressed(self, callback)](#removehandleupdownpressed)
- [RemoveHandleCancelButtonPressed(self, callback)](#removehandlecancelbuttonpressed)
- [RemoveHandleOkButtonPressed(self, callback)](#removehandleokbuttonpressed)
- [RemoveInitWindow(self, callback)](#removeinitwindow)
- [RemoveCloseWindow(self, callback)](#removeclosewindow)
- [QueueHandleCustom(self, callback)](#queuehandlecustom)
- [HasBeenShown(self)](#hasbeenshown)
- [SetEnableDebugClose(self, enabled)](#setenabledebugclose)
- [GetEnableDebugClose(self)](#getenabledebugclose)
- [ExecuteModal(self)](#executemodal)
- [ShowModeless(self)](#showmodeless)

### Init

```lua
fcmcustomluawindow.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L48)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

### RegisterHandleCommand

```lua
fcmcustomluawindow.RegisterHandleCommand(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L289)

**[Override]**
Ensures that the handler is passed the original control object.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### RegisterHandleDataListCheck

```lua
fcmcustomluawindow.RegisterHandleDataListCheck(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L300)

**[Override]**
Ensures that the handler is passed the original control object.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListCheck` in the PDK for callback signature. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### RegisterHandleDataListSelect

```lua
fcmcustomluawindow.RegisterHandleDataListSelect(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L311)

**[Override]**
Ensures that the handler is passed the original control object.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### RegisterHandleUpDownPressed

```lua
fcmcustomluawindow.RegisterHandleUpDownPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L322)

**[Override]**
Ensures that the handler is passed the original control object.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### CancelButtonPressed

```lua
fcmcustomluawindow.CancelButtonPressed(window)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L211)

**[Callback Template] [Override]**
Can optionally receive the window object.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `window` (optional) | `FCMCustomLuaWindow` |  |

### RegisterHandleCancelButtonPressed

```lua
fcmcustomluawindow.RegisterHandleCancelButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `CancelButtonPressed` for callback signature. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### OkButtonPressed

```lua
fcmcustomluawindow.OkButtonPressed(window)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L230)

**[Callback Template] [Override]**
Can optionally receive the window object.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `window` (optional) | `FCMCustomLuaWindow` |  |

### RegisterHandleOkButtonPressed

```lua
fcmcustomluawindow.RegisterHandleOkButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  See `OkButtonPressed` for callback signature. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### InitWindow

```lua
fcmcustomluawindow.InitWindow(window)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L249)

**[Callback Template] [Override]**
Can optionally receive the window object.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `window` (optional) | `FCMCustomLuaWindow` |  |

### RegisterInitWindow

```lua
fcmcustomluawindow.RegisterInitWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L362)

**[Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `InitWindow` for callback signature. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### CloseWindow

```lua
fcmcustomluawindow.CloseWindow(window)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L268)

**[Callback Template] [Override]**
Can optionally receive the window object.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `window` (optional) | `FCMCustomLuaWindow` |  |

### RegisterCloseWindow

```lua
fcmcustomluawindow.RegisterCloseWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L373)

**[Override]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `CloseWindow` for callback signature. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` on success |

### AddHandleCommand

```lua
fcmcustomluawindow.AddHandleCommand(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L391)

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleCommand` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature. |

### AddHandleDataListCheck

```lua
fcmcustomluawindow.AddHandleDataListCheck(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L401)

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleDataListCheck` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListCheck` in the PDK for callback signature. |

### AddHandleDataListSelect

```lua
fcmcustomluawindow.AddHandleDataListSelect(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L411)

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleDataListSelect` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature. |

### AddHandleUpDownPressed

```lua
fcmcustomluawindow.AddHandleUpDownPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L421)

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterHandleUpDownPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature. |

### AddHandleCancelButtonPressed

```lua
fcmcustomluawindow.AddHandleCancelButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L438)

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterCancelButtonPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `CancelButtonPressed` for callback signature. |

### AddHandleOkButtonPressed

```lua
fcmcustomluawindow.AddHandleOkButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L448)

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterOkButtonPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `OkButtonPressed` for callback signature. |

### AddInitWindow

```lua
fcmcustomluawindow.AddInitWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L458)

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterInitWindow` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `InitWindow` for callback signature. |

### AddCloseWindow

```lua
fcmcustomluawindow.AddCloseWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L468)

**[Fluid]**
Adds a handler. Similar to the equivalent `RegisterCloseWindow` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `CloseWindow` for callback signature. |

### RemoveHandleCommand

```lua
fcmcustomluawindow.RemoveHandleCommand(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Fluid]**
Removes a handler added by `AddHandleCommand`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RemoveHandleDataListCheck

```lua
fcmcustomluawindow.RemoveHandleDataListCheck(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Fluid]**
Removes a handler added by `AddHandleDataListCheck`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RemoveHandleDataListSelect

```lua
fcmcustomluawindow.RemoveHandleDataListSelect(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Fluid]**
Removes a handler added by `AddHandleDataListSelect`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RemoveHandleUpDownPressed

```lua
fcmcustomluawindow.RemoveHandleUpDownPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Fluid]**
Removes a handler added by `AddHandleUpDownPressed`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RemoveHandleCancelButtonPressed

```lua
fcmcustomluawindow.RemoveHandleCancelButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Fluid]**
Removes a handler added by `AddHandleCancelButtonPressed`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RemoveHandleOkButtonPressed

```lua
fcmcustomluawindow.RemoveHandleOkButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Fluid]**
Removes a handler added by `AddHandleOkButtonPressed`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RemoveInitWindow

```lua
fcmcustomluawindow.RemoveInitWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Fluid]**
Removes a handler added by `AddInitWindow`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RemoveCloseWindow

```lua
fcmcustomluawindow.RemoveCloseWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L-1)

**[Fluid]**
Removes a handler added by `AddCloseWindow`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### QueueHandleCustom

```lua
fcmcustomluawindow.QueueHandleCustom(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L492)

**[Fluid] [Internal]**
Adds a function to the queue which will be executed in the same context as an event handler at the next available opportunity.
Once called, the callback will be removed from tbe queue (i.e. it will only be called once). For multiple calls, the callback will need to be added to the queue again.
The callback will not be passed any arguments.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### HasBeenShown

```lua
fcmcustomluawindow.HasBeenShown(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L529)

Checks if the window has been shown, either as a modal or modeless.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if it has been shown, `false` if not |

### SetEnableDebugClose

```lua
fcmcustomluawindow.SetEnableDebugClose(self, enabled)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L623)

**[Fluid]**
If enabled and in debug mode, when the window is closed with either ALT or SHIFT key pressed, `finenv.RetainLuaState` will be set to `false`.
This is done before CloseWindow handlers are called.
Default state is disabled.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `enabled` | `boolean` |  |

### GetEnableDebugClose

```lua
fcmcustomluawindow.GetEnableDebugClose(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L637)

Returns the enabled state of the DebugClose option.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if enabled, `false` if disabled. |

### ExecuteModal

```lua
fcmcustomluawindow.ExecuteModal(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L650)

**[Override]**
Sets the `HasBeenShown` flag and restores the previous position if auto restore is on.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### ShowModeless

```lua
fcmcustomluawindow.ShowModeless(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua.lua#L665)

**[Override]**
Sets the `HasBeenShown` flag and restores the previous position if auto restore is on.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

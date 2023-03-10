# FCMCustomLuaWindow

## Summary of Modifications
- Window is automatically registered with `finenv.RegisterModelessDialog` when `ShowModeless` is called.
- All `Register*` methods (apart from `RegisterHandleControlEvent`) have accompanying `Add*` and `Remove*` methods to enable multiple handlers to be added per event.
- Handlers for all window events (ie not control events) recieve the window object as the first argument.
- Control handlers are passed original object to preserve mixin data.
- Added custom callback queue which can be used by custom events to add dispatchers that will run with the next control event.
- Added `HasBeenShown` method for checking if the window has been previously shown.
- Added methods for the automatic restoration of previous window position when showing (RGPLua > 0.60) for use with `finenv.RetainLuaState` and modeless windows.
- Added `DebugClose` option to assist with debugging (if ALT or SHIFT key is pressed when window is closed and debug mode is enabled, finenv.RetainLuaState will be set to false).
- Measurement unit can be set on the window or changed by the user through a `FCXCtrlMeasurementUnitPopup`.
- Windows also have the option of inheriting the parent window's measurement unit when opening.
- Introduced a `MeasurementUnitChange` event.
- All controls with an `UpdateMeasurementUnit` method will have that method called upon a measurement unit change to allow them to immediately update their displayed values without needing to wait for a `MeasurementUnitChange` event.

## Functions

- [Init(self)](#init)
- [RegisterHandleCommand(self, callback)](#registerhandlecommand)
- [AddHandleCommand(self, callback)](#addhandlecommand)
- [RemoveHandleCommand(self, callback)](#removehandlecommand)
- [RegisterHandleDataListCheck(self, callback)](#registerhandledatalistcheck)
- [AddHandleDataListCheck(self, callback)](#addhandledatalistcheck)
- [RemoveHandleDataListCheck(self, callback)](#removehandledatalistcheck)
- [RegisterHandleDataListSelect(self, callback)](#registerhandledatalistselect)
- [AddHandleDataListSelect(self, callback)](#addhandledatalistselect)
- [RemoveHandleDataListSelect(self, callback)](#removehandledatalistselect)
- [RegisterHandleUpDownPressed(self, callback)](#registerhandleupdownpressed)
- [AddHandleUpDownPressed(self, callback)](#addhandleupdownpressed)
- [RemoveHandleUpDownPressed(self, callback)](#removehandleupdownpressed)
- [CancelButtonPressed(self)](#cancelbuttonpressed)
- [RegisterHandleCancelButtonPressed(self, callback)](#registerhandlecancelbuttonpressed)
- [AddHandleCancelButtonPressed(self, callback)](#addhandlecancelbuttonpressed)
- [RemoveHandleCancelButtonPressed(self, callback)](#removehandlecancelbuttonpressed)
- [OkButtonPressed(self)](#okbuttonpressed)
- [RegisterHandleOkButtonPressed(self, callback)](#registerhandleokbuttonpressed)
- [AddHandleOkButtonPressed(self, callback)](#addhandleokbuttonpressed)
- [RemoveHandleOkButtonPressed(self, callback)](#removehandleokbuttonpressed)
- [InitWindow(self)](#initwindow)
- [RegisterInitWindow(self, callback)](#registerinitwindow)
- [AddInitWindow(self, callback)](#addinitwindow)
- [RemoveInitWindow(self, callback)](#removeinitwindow)
- [CloseWindow(self)](#closewindow)
- [RegisterCloseWindow(self, callback)](#registerclosewindow)
- [AddCloseWindow(self, callback)](#addclosewindow)
- [RemoveCloseWindow(self, callback)](#removeclosewindow)
- [QueueHandleCustom(self, callback)](#queuehandlecustom)
- [RegisterHandleControlEvent(self, control, callback)](#registerhandlecontrolevent)
- [HandleTimer(self, timerid)](#handletimer)
- [RegisterHandleTimer(self, callback)](#registerhandletimer)
- [AddHandleTimer(self, timerid, callback)](#addhandletimer)
- [RemoveHandleTimer(self, timerid, callback)](#removehandletimer)
- [SetTimer(self, timerid, msinterval)](#settimer)
- [GetNextTimerID(self)](#getnexttimerid)
- [SetNextTimer(self, msinterval)](#setnexttimer)
- [SetEnableAutoRestorePosition(self, enabled)](#setenableautorestoreposition)
- [GetEnableAutoRestorePosition(self)](#getenableautorestoreposition)
- [SetRestorePositionData(self, x, y, width, height)](#setrestorepositiondata)
- [SetRestorePositionOnlyData(self, x, y)](#setrestorepositiononlydata)
- [SetEnableDebugClose(self, enabled)](#setenabledebugclose)
- [GetEnableDebugClose(self)](#getenabledebugclose)
- [SetRestoreControlState(self, enabled)](#setrestorecontrolstate)
- [GetRestoreControlState(self)](#getrestorecontrolstate)
- [HasBeenShown(self)](#hasbeenshown)
- [ExecuteModal(self, parent)](#executemodal)
- [ShowModeless(self)](#showmodeless)
- [RunModeless(self, selection_not_required, default_action_override)](#runmodeless)
- [GetMeasurementUnit(self)](#getmeasurementunit)
- [SetMeasurementUnit(self, unit)](#setmeasurementunit)
- [GetMeasurementUnitName(self)](#getmeasurementunitname)
- [GetUseParentMeasurementUnit(self)](#getuseparentmeasurementunit)
- [SetUseParentMeasurementUnit(self, enabled)](#setuseparentmeasurementunit)
- [HandleMeasurementUnitChange(self, last_unit)](#handlemeasurementunitchange)
- [AddHandleMeasurementUnitChange(self, callback)](#addhandlemeasurementunitchange)
- [RemoveHandleMeasurementUnitChange(self, callback)](#removehandlemeasurementunitchange)
- [CreateMeasurementEdit(self, x, y, control_name)](#createmeasurementedit)
- [CreateMeasurementUnitPopup(self, x, y, control_name)](#createmeasurementunitpopup)
- [CreatePageSizePopup(self, x, y, control_name)](#createpagesizepopup)

### Init

```lua
fcmcustomluawindow.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L92)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

### RegisterHandleCommand

```lua
fcmcustomluawindow.RegisterHandleCommand(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L239)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature. |

### AddHandleCommand

```lua
fcmcustomluawindow.AddHandleCommand(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L251)

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterHandleCommand` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature. |

### RemoveHandleCommand

```lua
fcmcustomluawindow.RemoveHandleCommand(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L-1)

**[Fluid]**

Removes a handler added by `AddHandleCommand`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RegisterHandleDataListCheck

```lua
fcmcustomluawindow.RegisterHandleDataListCheck(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L275)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListCheck` in the PDK for callback signature. |

### AddHandleDataListCheck

```lua
fcmcustomluawindow.AddHandleDataListCheck(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L287)

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterHandleDataListCheck` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListCheck` in the PDK for callback signature. |

### RemoveHandleDataListCheck

```lua
fcmcustomluawindow.RemoveHandleDataListCheck(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L-1)

**[Fluid]**

Removes a handler added by `AddHandleDataListCheck`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RegisterHandleDataListSelect

```lua
fcmcustomluawindow.RegisterHandleDataListSelect(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L311)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature. |

### AddHandleDataListSelect

```lua
fcmcustomluawindow.AddHandleDataListSelect(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L323)

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterHandleDataListSelect` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature. |

### RemoveHandleDataListSelect

```lua
fcmcustomluawindow.RemoveHandleDataListSelect(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L-1)

**[Fluid]**

Removes a handler added by `AddHandleDataListSelect`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RegisterHandleUpDownPressed

```lua
fcmcustomluawindow.RegisterHandleUpDownPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L347)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature. |

### AddHandleUpDownPressed

```lua
fcmcustomluawindow.AddHandleUpDownPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L359)

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterHandleUpDownPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature. |

### RemoveHandleUpDownPressed

```lua
fcmcustomluawindow.RemoveHandleUpDownPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L-1)

**[Fluid]**

Removes a handler added by `AddHandleUpDownPressed`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### CancelButtonPressed

```lua
fcmcustomluawindow.CancelButtonPressed(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L380)

**[Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

### RegisterHandleCancelButtonPressed

```lua
fcmcustomluawindow.RegisterHandleCancelButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L-1)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `CancelButtonPressed` for callback signature. |

### AddHandleCancelButtonPressed

```lua
fcmcustomluawindow.AddHandleCancelButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L409)

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterCancelButtonPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `CancelButtonPressed` for callback signature. |

### RemoveHandleCancelButtonPressed

```lua
fcmcustomluawindow.RemoveHandleCancelButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L-1)

**[Fluid]**

Removes a handler added by `AddHandleCancelButtonPressed`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### OkButtonPressed

```lua
fcmcustomluawindow.OkButtonPressed(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L427)

**[Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

### RegisterHandleOkButtonPressed

```lua
fcmcustomluawindow.RegisterHandleOkButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L942)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  See `OkButtonPressed` for callback signature. |

### AddHandleOkButtonPressed

```lua
fcmcustomluawindow.AddHandleOkButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L456)

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterOkButtonPressed` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `OkButtonPressed` for callback signature. |

### RemoveHandleOkButtonPressed

```lua
fcmcustomluawindow.RemoveHandleOkButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L-1)

**[Fluid]**

Removes a handler added by `AddHandleOkButtonPressed`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### InitWindow

```lua
fcmcustomluawindow.InitWindow(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L474)

**[Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

### RegisterInitWindow

```lua
fcmcustomluawindow.RegisterInitWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L491)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `InitWindow` for callback signature. |

### AddInitWindow

```lua
fcmcustomluawindow.AddInitWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L503)

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterInitWindow` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `InitWindow` for callback signature. |

### RemoveInitWindow

```lua
fcmcustomluawindow.RemoveInitWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L-1)

**[Fluid]**

Removes a handler added by `AddInitWindow`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### CloseWindow

```lua
fcmcustomluawindow.CloseWindow(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L521)

**[Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

### RegisterCloseWindow

```lua
fcmcustomluawindow.RegisterCloseWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L538)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `CloseWindow` for callback signature. |

### AddCloseWindow

```lua
fcmcustomluawindow.AddCloseWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L550)

**[Fluid]**

Adds a handler. Similar to the equivalent `RegisterCloseWindow` except there is no limit to the number of handlers that can be added.
Added handlers are called in the order they are added after the registered handler, if there is one.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `CloseWindow` for callback signature. |

### RemoveCloseWindow

```lua
fcmcustomluawindow.RemoveCloseWindow(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L-1)

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

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L570)

**[Fluid] [Internal]**
Adds a function to the queue which will be executed in the same context as an event handler at the next available opportunity.
Once called, the callback will be removed from tbe queue (i.e. it will only be called once). For multiple calls, the callback will need to be added to the queue again.
The callback will not be passed any arguments.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### RegisterHandleControlEvent

```lua
fcmcustomluawindow.RegisterHandleControlEvent(self, control, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L591)

**[>= v0.56] [Breaking Change] [Fluid] [Override]**

Override Changes:
- Ensures that the handler is passed the original control object.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `control` | `FCMControl` |  |
| `callback` | `function` | See `FCCustomLuaWindow.HandleControlEvent` in the PDK for callback signature. |

### HandleTimer

```lua
fcmcustomluawindow.HandleTimer(self, timerid)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L617)

**[Breaking Change] [Callback Template] [Override]**

Override Changes:
- Receives the window object as the first parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `timerid` | `number` |  |

### RegisterHandleTimer

```lua
fcmcustomluawindow.RegisterHandleTimer(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L628)

**[>= v0.56] [Breaking Change] [Fluid] [Override]**

Override Changes:
- Uses overridden callback signature.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `HandleTimer` for callback signature (note the change in arguments). |

### AddHandleTimer

```lua
fcmcustomluawindow.AddHandleTimer(self, timerid, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L646)

**[>= v0.56] [Fluid]**

Adds a handler for a timer. Handlers added by this method will be called after the registered handler, if there is one.
If a handler is added for a timer that hasn't been set, the timer ID will no longer be available to `GetNextTimerID` and `SetNextTimer`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `timerid` | `number` |  |
| `callback` | `function` | See `HandleTimer` for callback signature. |

### RemoveHandleTimer

```lua
fcmcustomluawindow.RemoveHandleTimer(self, timerid, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L666)

**[>= v0.56] [Fluid]**

Removes a handler added with `AddHandleTimer`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `timerid` | `number` |  |
| `callback` | `function` |  |

### SetTimer

```lua
fcmcustomluawindow.SetTimer(self, timerid, msinterval)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L689)

**[>= v0.56] [Fluid] [Override]**

Override Changes:
- Add setup to allow multiple handlers to be added for a timer.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCCustomLuaWindow` |  |
| `timerid` | `number` |  |
| `msinterval` | `number` |  |

### GetNextTimerID

```lua
fcmcustomluawindow.GetNextTimerID(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L708)

**[>= v0.56]**

Returns the next available timer ID.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### SetNextTimer

```lua
fcmcustomluawindow.SetNextTimer(self, msinterval)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L727)

**[>= v0.56]**

Sets a timer using the next available ID (according to `GetNextTimerID`) and returns the ID.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `msinterval` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` | The ID of the newly created timer. |

### SetEnableAutoRestorePosition

```lua
fcmcustomluawindow.SetEnableAutoRestorePosition(self, enabled)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L750)

**[>= v0.60] [Fluid]**

Enables/disables automatic restoration of the window's position on subsequent openings.
This is disabled by default.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `enabled` | `boolean` |  |

### GetEnableAutoRestorePosition

```lua
fcmcustomluawindow.GetEnableAutoRestorePosition(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L766)

**[>= v0.60]**

Returns whether automatic restoration of window position is enabled.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if enabled, `false` if disabled. |

### SetRestorePositionData

```lua
fcmcustomluawindow.SetRestorePositionData(self, x, y, width, height)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L784)

**[>= v0.60] [Fluid] [Override]**

Override Changes:
- If this method is called while the window is closed, the new position data will be used in automatic position restoration when window is next shown.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `width` | `number` |  |
| `height` | `number` |  |

### SetRestorePositionOnlyData

```lua
fcmcustomluawindow.SetRestorePositionOnlyData(self, x, y)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L810)

**[>= v0.60] [Fluid] [Override]**

Override Changes:
- If this method is called while the window is closed, the new position data will be used in automatic position restoration when window is next shown.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |

### SetEnableDebugClose

```lua
fcmcustomluawindow.SetEnableDebugClose(self, enabled)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L835)

**[Fluid]**

If enabled and in debug mode, when the window is closed with either ALT or SHIFT key pressed, `finenv.RetainLuaState` will be set to `false`.
This is done before CloseWindow handlers are called.
This is disabled by default.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `enabled` | `boolean` |  |

### GetEnableDebugClose

```lua
fcmcustomluawindow.GetEnableDebugClose(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L849)

Returns the enabled state of the `DebugClose` option.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if enabled, `false` if disabled. |

### SetRestoreControlState

```lua
fcmcustomluawindow.SetRestoreControlState(self, enabled)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L864)

**[Fluid]**

Enables or disables the automatic restoration of control state on subsequent showings of the window.
This is disabled by default.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `enabled` | `boolean` | `true` to enable, `false` to disable. |

### GetRestoreControlState

```lua
fcmcustomluawindow.GetRestoreControlState(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L878)

Checks if control state restoration is enabled.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if enabled, `false` if disabled. |

### HasBeenShown

```lua
fcmcustomluawindow.HasBeenShown(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L890)

Checks if the window has been shown at least once prior, either as a modal or modeless.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if it has been shown, `false` if not |

### ExecuteModal

```lua
fcmcustomluawindow.ExecuteModal(self, parent)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L907)

**[Override]**

Override Changes:
- If a parent window is passed and the `UseParentMeasurementUnit` setting is enabled, this window's measurement unit is automatically changed to match the parent window.
- Restores the previous position if `AutoRestorePosition` is enabled.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `parent` | `FCCustomWindow \| FCMCustomWindow \| nil` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### ShowModeless

```lua
fcmcustomluawindow.ShowModeless(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L928)

**[Override]**

Override Changes:
- Automatically registers the dialog with `finenv.RegisterModelessDialog`.
- Restores the previous position if `AutoRestorePosition` is enabled.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### RunModeless

```lua
fcmcustomluawindow.RunModeless(self, selection_not_required, default_action_override)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L949)

**[Fluid]**

Runs the window as a self-contained modeless plugin, performing the following steps:
- The first time the plugin is run, if ALT or SHIFT keys are pressed, sets `OkButtonCanClose` to true
- On subsequent runnings, if ALT or SHIFT keys are pressed the default action will be called without showing the window
- The default action defaults to the function registered with `RegisterHandleOkButtonPressed`
- If in JWLua, the window will be shown as a modal and it will check that a music region is currently selected

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `selection_not_required` (optional) | `boolean` | If `true` and showing as a modal, will skip checking if a region is selected. |
| `default_action_override` (optional) | `boolean \| function` | If `false`, there will be no default action. If a `function`, overrides the registered `OkButtonPressed` handler as the default action. |

### GetMeasurementUnit

```lua
fcmcustomluawindow.GetMeasurementUnit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L985)

Returns the window's current measurement unit.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` | The value of one of the finale MEASUREMENTUNIT constants. |

### SetMeasurementUnit

```lua
fcmcustomluawindow.SetMeasurementUnit(self, unit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1001)

**[Fluid]**

Sets the window's current measurement unit. Millimeters are not supported.

All controls that have an `UpdateMeasurementUnit` method will have that method called to allow them to immediately update their displayed measurement unit immediately without needing to wait for a `MeasurementUnitChange` event.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `unit` | `number` | One of the finale MEASUREMENTUNIT constants. |

### GetMeasurementUnitName

```lua
fcmcustomluawindow.GetMeasurementUnitName(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1035)

Returns the name of the window's current measurement unit.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### GetUseParentMeasurementUnit

```lua
fcmcustomluawindow.GetUseParentMeasurementUnit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1047)

Returns a boolean indicating whether this window will use the measurement unit of its parent window when opened.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### SetUseParentMeasurementUnit

```lua
fcmcustomluawindow.SetUseParentMeasurementUnit(self, enabled)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1061)

**[Fluid]**

Sets whether to use the parent window's measurement unit when opening this window. Default is enabled.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `enabled` | `boolean` |  |

### HandleMeasurementUnitChange

```lua
fcmcustomluawindow.HandleMeasurementUnitChange(self, last_unit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1079)

**[Callback Template]**

Template for MeasurementUnitChange handlers.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `last_unit` | `number` | The window's previous measurement unit. |

### AddHandleMeasurementUnitChange

```lua
fcmcustomluawindow.AddHandleMeasurementUnitChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1098)

**[Fluid]**

Adds a handler for a change in the window's measurement unit.
The even will fire when:
- The window is created (if the measurement unit is not `finale.MEASUREMENTUNIT_DEFAULT`)
- The measurement unit is changed by the user via a `FCXCtrlMeasurementUnitPopup`
- The measurement unit is changed programmatically (if the measurement unit is changed within a handler, that *same* handler will not be called again for that change.)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` | See `HandleMeasurementUnitChange` for callback signature. |

### RemoveHandleMeasurementUnitChange

```lua
fcmcustomluawindow.RemoveHandleMeasurementUnitChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1103)

**[Fluid]**

Removes a handler added with `AddHandleMeasurementUnitChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `callback` | `function` |  |

### CreateMeasurementEdit

```lua
fcmcustomluawindow.CreateMeasurementEdit(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1124)

Creates an `FCXCtrlMeasurementEdit` control.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlMeasurementEdit` |  |

### CreateMeasurementUnitPopup

```lua
fcmcustomluawindow.CreateMeasurementUnitPopup(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1144)

Creates a popup which allows the user to change the window's measurement unit.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlMeasurementUnitPopup` |  |

### CreatePageSizePopup

```lua
fcmcustomluawindow.CreatePageSizePopup(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomLuaWindow.lua#L1164)

Creates a popup which allows the user to select a page size.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlPageSizePopup` |  |

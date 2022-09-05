# FCXCustomLuaWindow

*Extends `FCMCustomLuaWindow`*

Summary of modifications:
- Changed argument order for timer handlers so that window is passed first, before `timerid` (enables handlers to be method of window).
- Added `Add*` and `Remove*` handler methods for timers
- Measurement unit can be set on the window or changed by the user through a `FCXCtrlMeasurementUnitPopup`.
- Windows also have the option of inheriting the parent window's measurement unit when opening.
- Introduced a `MeasurementUnitChange` event.
- All controls with an `UpdateMeasurementUnit` method will have that method called upon a measurement unit change to allow them to immediately update their displayed values without needing to wait for a `MeasurementUnitChange` event.
- Changed the default auto restoration behaviour for window position to enabled
- finenv.RegisterModelessDialog is called automatically when ShowModeless is called
- DebugClose is enabled by default

## Functions

- [Init(self)](#init)
- [GetMeasurementUnit(self)](#getmeasurementunit)
- [SetMeasurementUnit(self, unit)](#setmeasurementunit)
- [GetMeasurementUnitName(self)](#getmeasurementunitname)
- [UseParentMeasurementUnit(self, on)](#useparentmeasurementunit)
- [CreateMeasurementEdit(self, x, y, control_name)](#createmeasurementedit)
- [CreateMeasurementUnitPopup(self, x, y, control_name)](#createmeasurementunitpopup)
- [CreatePageSizePopup(self, x, y, control_name)](#createpagesizepopup)
- [CreateStatic(self, x, y, control_name)](#createstatic)
- [CreateUpDown(self, x, y, control_name)](#createupdown)
- [RegisterHandleOkButtonPressed(self, callback)](#registerhandleokbuttonpressed)
- [ExecuteModal(self, parent)](#executemodal)
- [ShowModeless(self)](#showmodeless)
- [RunModeless(self, no_selection_required, default_action_override)](#runmodeless)
- [HandleMeasurementUnitChange(window, last_unit)](#handlemeasurementunitchange)
- [AddHandleMeasurementUnitChange(self, callback)](#addhandlemeasurementunitchange)
- [RemoveHandleMeasurementUnitChange(self, callback)](#removehandlemeasurementunitchange)

### Init

```lua
fcxcustomluawindow.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L37)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |

### GetMeasurementUnit

```lua
fcxcustomluawindow.GetMeasurementUnit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L80)

Returns the window's current measurement unit.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` | The value of one of the finale MEASUREMENTUNIT constants. |

### SetMeasurementUnit

```lua
fcxcustomluawindow.SetMeasurementUnit(self, unit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L95)

**[Fluid]**
Sets the window's current measurement unit. Millimeters are not supported.

All controls that have an `UpdateMeasurementUnit` method will have that method called to allow them to immediately update their displayed measurement unit without needing to wait for a `MeasurementUnitChange` event.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `unit` | `number` | One of the finale MEASUREMENTUNIT constants. |

### GetMeasurementUnitName

```lua
fcxcustomluawindow.GetMeasurementUnitName(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L129)

Returns the name of the window's current measurement unit.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `string` |  |

### UseParentMeasurementUnit

```lua
fcxcustomluawindow.UseParentMeasurementUnit(self, on)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L142)

**[Fluid]**
Sets whether to use the parent window's measurement unit when opening this window. Defaults to `true`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `on` | `boolean` |  |

### CreateMeasurementEdit

```lua
fcxcustomluawindow.CreateMeasurementEdit(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L159)

Creates a `FCXCtrlMeasurementEdit` control.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlMeasurementEdit` |  |

### CreateMeasurementUnitPopup

```lua
fcxcustomluawindow.CreateMeasurementUnitPopup(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L179)

Creates a popup which allows the user to change the window's measurement unit.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlMeasurementUnitPopup` |  |

### CreatePageSizePopup

```lua
fcxcustomluawindow.CreatePageSizePopup(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L199)

Creates a popup which allows the user to select a page size.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlPageSizePopup` |  |

### CreateStatic

```lua
fcxcustomluawindow.CreateStatic(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L220)

**[Override]**
Creates an `FCXCtrlStatic` control.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlStatic` |  |

### CreateUpDown

```lua
fcxcustomluawindow.CreateUpDown(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L241)

**[Override]**
Creates an `FCXCtrlUpDown` control.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCXCtrlUpDown` |  |

### RegisterHandleOkButtonPressed

```lua
fcxcustomluawindow.RegisterHandleOkButtonPressed(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L383)

**[Fluid] [Override]**
Stores callback as default action for `RunModeless`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `callback` | `function` | See documentation for `FCMCustomLuaWindow.OkButtonPressed` for callback signature. |

### ExecuteModal

```lua
fcxcustomluawindow.ExecuteModal(self, parent)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L400)

**[Override]**
If a parent window is passed and the `UseParentMeasurementUnit` setting is on, the measurement unit is automatically changed to match the parent.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `parent` | `FCCustomWindow\|FCMCustomWindow\|nil` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

### ShowModeless

```lua
fcxcustomluawindow.ShowModeless(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L417)

**[Override]**
Automatically registers the dialog with `finenv.RegisterModelessDialog`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### RunModeless

```lua
fcxcustomluawindow.RunModeless(self, no_selection_required, default_action_override)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L436)

**[Fluid]**
Runs the window as a self-contained modeless plugin, performing the following steps:
- The first time the plugin is run, if ALT or SHIFT keys are pressed, sets `OkButtonCanClose` to true
- On subsequent runnings, if ALT or SHIFT keys are pressed the default action will be called without showing the window
- The default action defaults to the function registered with `RegisterHandleOkButtonPressed`
- If in JWLua, the window will be shown as a modal and it will check that a music region is currently selected

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `no_selection_required` (optional) | `boolean` | If `true` and showing as a modal, will skip checking if a region is selected. |
| `default_action_override` (optional) | `boolean\|function` | If `false`, there will be no default action. If a `function`, overrides the registered `OkButtonPressed` handler as the default action. |

### HandleMeasurementUnitChange

```lua
fcxcustomluawindow.HandleMeasurementUnitChange(window, last_unit)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L475)

**[Callback Template]**
Template for MeasurementUnitChange handlers.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `window` | `FCXCustomLuaWindow` | The window that triggered the event. |
| `last_unit` | `number` | The window's previous measurement unit. |

### AddHandleMeasurementUnitChange

```lua
fcxcustomluawindow.AddHandleMeasurementUnitChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L492)

**[Fluid]**
Adds a handler for a change in the window's measurement unit.
The even will fire when:
- The window is created (if the measurement unit is not `finale.MEASUREMENTUNIT_DEFAULT`)
- The measurement unit is changed by the user via a `FCXCtrlMeasurementUnitPopup`
- The measurement unit is changed programmatically (if the measurement unit is changed within a handler, that *same* handler will not be called again for that change.)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `callback` | `function` | See `HandleMeasurementUnitChange` for callback signature. |

### RemoveHandleMeasurementUnitChange

```lua
fcxcustomluawindow.RemoveHandleMeasurementUnitChange(self, callback)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCXCustomLuaWindow.lua#L497)

**[Fluid]**
Removes a handler added with `AddHandleMeasurementUnitChange`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCustomLuaWindow` |  |
| `callback` | `function` |  |

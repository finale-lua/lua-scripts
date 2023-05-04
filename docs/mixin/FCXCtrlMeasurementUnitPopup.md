# FCXCtrlMeasurementUnitPopup

*Extends `FCMCtrlPopup`*

This mixin defines a popup that can be used to change the window's measurement unit (eg like the one at the bottom of the settings dialog). It is largely internal, and other than setting the position and size, it runs automatically.
Programmatic changes of measurement unit should be handled at the parent window, not the control.

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

Event listeners for changes of measurement unit should be added to the parent window.

## Functions

- [Init(self)](#init)
- [UpdateMeasurementUnit(self)](#updatemeasurementunit)

### Init

```lua
fcxctrlmeasurementunitpopup.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCtrlMeasurementUnitPopup.lua#L59)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementUnitPopup` |  |

### UpdateMeasurementUnit

```lua
fcxctrlmeasurementunitpopup.UpdateMeasurementUnit(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCXCtrlMeasurementUnitPopup.lua#L88)

**[Fluid] [Internal]**

Checks the parent window's measurement unit and updates the selection if necessary.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCXCtrlMeasurementUnitPopup` |  |

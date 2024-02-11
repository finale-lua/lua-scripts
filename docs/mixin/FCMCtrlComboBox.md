# FCMCtrlComboBox

The PDK offers FCCtrlCombox which is an edit box with a pulldown menu attached. It has the following
features:

- It is an actual subclass of FCCtrlEdit, which means FCMCtrlComboBox is a subclass of FCMCtrlEdit.
- The text contents of the control does not have to match any of the pulldown values.

The PDK manages the pulldown values and selectied item well enough for our purposes. Furthermore, the order in
which you set text or set the selected item matters as to which one you'll end up with when the window
opens. The PDK takes the approach that setting text takes precedence over setting the selected item.
For that reason, this module (at least for now) does not manage those properties separately.

## Summary of Modifications
- Overrode `AddString` to allows Lua `string` or `number` in addition to `FCString`.
- Added `AddStrings` that accepts multiple arguments of `table`, `FCString`, Lua `string`, or `number`.
- Added localized versions `AddStringLocalized` and `AddStringsLocalized`.

## Functions

- [AddString(self, str)](#addstring)
- [AddStringLocalized(self)](#addstringlocalized)
- [AddStrings(self)](#addstrings)
- [AddStringsLocalized(self)](#addstringslocalized)

### AddString

```lua
fcmctrlcombobox.AddString(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlComboBox.lua#L43)

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.
- Hooks into control state preservation.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlComboBox` |  |
| `str` | `FCString \| string \| number` |  |

### AddStringLocalized

```lua
fcmctrlcombobox.AddStringLocalized(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlComboBox.lua#L60)

**[Fluid]**

Localized version of `AddString`.

@ key (string | FCString, number) The key into the localization table. If there is no entry in the appropriate localization table, the key is the text.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlComboBox` |  |

### AddStrings

```lua
fcmctrlcombobox.AddStrings(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlComboBox.lua#L72)

**[Fluid]**

Adds multiple strings to the combobox.

@ ... (FCStrings | FCString | string | number | table)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlComboBox` |  |

### AddStringsLocalized

```lua
fcmctrlcombobox.AddStringsLocalized(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMCtrlComboBox.lua#L84)

**[Fluid]**

Adds multiple localized strings to the combobox.

@ ... (FCStrings | FCString | string | number | table) keys of strings to be added. If no localization is found, the key is added.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCtrlComboBox` |  |

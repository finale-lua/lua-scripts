# FCMCustomWindow

Summary of modifications:
- `Create*` methods have an additional optional parameter for specifying a control name. Named controls can be retrieved via `GetControl`.
- Cache original control objects to preserve mixin data and override control getters to return the original objects.
- Added `Each` method for iterating over controls by class name.

## Functions

- [Init(self)](#init)
- [CreateCancelButton(self, control_name)](#createcancelbutton)
- [CreateOkButton(self, control_name)](#createokbutton)
- [CreateButton(self, x, y, control_name)](#createbutton)
- [CreateCheckbox(self, x, y, control_name)](#createcheckbox)
- [CreateDataList(self, x, y, control_name)](#createdatalist)
- [CreateEdit(self, x, y, control_name)](#createedit)
- [CreateListBox(self, x, y, control_name)](#createlistbox)
- [CreatePopup(self, x, y, control_name)](#createpopup)
- [CreateSlider(self, x, y, control_name)](#createslider)
- [CreateStatic(self, x, y, control_name)](#createstatic)
- [CreateSwitcher(self, x, y, control_name)](#createswitcher)
- [CreateTree(self, x, y, control_name)](#createtree)
- [CreateUpDown(self, x, y, control_name)](#createupdown)
- [CreateHorizontalLine(self, x, y, length, control_name)](#createhorizontalline)
- [CreateVerticalLine(self, x, y, length, control_name)](#createverticalline)
- [FindControl(self, control_id)](#findcontrol)
- [GetControl(self, control_name)](#getcontrol)
- [Each(self, class_filter)](#each)
- [GetItemAt(self, index)](#getitemat)
- [CreateCloseButton(self, x, y, control_name)](#createclosebutton)
- [GetParent(self)](#getparent)
- [ExecuteModal(self, parent)](#executemodal)

### Init

```lua
fcmcustomwindow.Init(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L23)

**[Internal]**

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |

### CreateCancelButton

```lua
fcmcustomwindow.CreateCancelButton(self, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlButton` |  |

### CreateOkButton

```lua
fcmcustomwindow.CreateOkButton(self, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlButton` |  |

### CreateButton

```lua
fcmcustomwindow.CreateButton(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlButton` |  |

### CreateCheckbox

```lua
fcmcustomwindow.CreateCheckbox(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlCheckbox` |  |

### CreateDataList

```lua
fcmcustomwindow.CreateDataList(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlDataList` |  |

### CreateEdit

```lua
fcmcustomwindow.CreateEdit(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlEdit` |  |

### CreateListBox

```lua
fcmcustomwindow.CreateListBox(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlListBox` |  |

### CreatePopup

```lua
fcmcustomwindow.CreatePopup(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlPopup` |  |

### CreateSlider

```lua
fcmcustomwindow.CreateSlider(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlSlider` |  |

### CreateStatic

```lua
fcmcustomwindow.CreateStatic(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlStatic` |  |

### CreateSwitcher

```lua
fcmcustomwindow.CreateSwitcher(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlSwitcher` |  |

### CreateTree

```lua
fcmcustomwindow.CreateTree(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlTree` |  |

### CreateUpDown

```lua
fcmcustomwindow.CreateUpDown(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlUpDown` |  |

### CreateHorizontalLine

```lua
fcmcustomwindow.CreateHorizontalLine(self, x, y, length, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `length` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlLine` |  |

### CreateVerticalLine

```lua
fcmcustomwindow.CreateVerticalLine(self, x, y, length, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L-1)

**[Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `length` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlLine` |  |

### FindControl

```lua
fcmcustomwindow.FindControl(self, control_id)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L306)

**[PDK Port]**
Finds a control based on its ID.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `control_id` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMControl\\|nil` |  |

### GetControl

```lua
fcmcustomwindow.GetControl(self, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L321)

Finds a control based on its name.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `control_name` | `FCString\|string` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMControl\\|nil` |  |

### Each

```lua
fcmcustomwindow.Each(self, class_filter)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L335)

An iterator for controls that can filter by class.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `class_filter` (optional) | `string` | A class name, can be a parent class. See documentation `mixin.is_instance_of` for details on class filtering. |

| Return type | Description |
| ----------- | ----------- |
| `function` | An iterator function. |

### GetItemAt

```lua
fcmcustomwindow.GetItemAt(self, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L360)

**[Override]**
Ensures that the original control object is returned.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `index` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMControl` |  |

### CreateCloseButton

```lua
fcmcustomwindow.CreateCloseButton(self, x, y, control_name)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L378)

**[>= v0.56] [Override]**
Add optional `control_name` parameter.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `x` | `number` |  |
| `y` | `number` |  |
| `control_name` (optional) | `FCString\|string` | Optional name to allow access from `GetControl` method. |

| Return type | Description |
| ----------- | ----------- |
| `FCMCtrlButton` |  |

### GetParent

```lua
fcmcustomwindow.GetParent(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L410)

**[PDK Port]**
Returns the parent window. The parent will only be available while the window is showing.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMCustomWindow\\|nil` | `nil` if no parent |

### ExecuteModal

```lua
fcmcustomwindow.ExecuteModal(self, parent)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/mixin/FCMCustomWindow.lua.lua#L424)

**[Override]**
Stores the parent window to make it available via `GetParent`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMCustomWindow` |  |
| `parent` | `FCCustomWindow\|FCMCustomWindow\|nil` |  |

| Return type | Description |
| ----------- | ----------- |
| `number` |  |

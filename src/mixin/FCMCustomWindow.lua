--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCustomWindow

## Summary of Modifications
- `Create*` methods have an additional optional parameter for specifying a control name. Named controls can be retrieved via `GetControl`.
- Cache original control objects to preserve mixin data and override control getters to return the original objects.
- Added `Each` method for iterating over controls by class name.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local loc = require("library.localization")

local class = {Methods = {}}
local methods = class.Methods
local private = setmetatable({}, {__mode = "k"})

local function create_control(self, func, num_args, ...)
    local result = self["Create" .. func .. "__"](self, ...)

    local function add_control(control)
        private[self].Controls[control:GetControlID()] = control
        control:RegisterParent(self)
    end

    if func == "RadioButtonGroup" then
        for control in each(result) do
            add_control(control)
        end
    else
        add_control(result)
    end

    local control_name = select(num_args + 1, ...)
    if control_name then
        control_name = type(control_name) == "userdata" and control_name.LuaString or control_name

        if private[self].NamedControls[control_name] then
            error("A control is already registered with the name '" .. control_name .. "'", 2)
        end

        private[self].NamedControls[control_name] = result
    end

    return result
end

--[[
% Init

**[Internal]**

@ self (FCMCustomWindow)
]]
function class:Init()
    if private[self] then
        return
    end

    private[self] = {
        Controls = {},
        NamedControls = {},
    }
end

--[[
% CreateCancelButton

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

--[[
% CreateOkButton

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

--[[
% CreateButton

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

--[[
% CreateCheckbox

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlCheckbox)
]]

--[[
% CreateCloseButton

**[>= v0.56] [Override]**

Override Changes:
- Added optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

--[[
% CreateDataList

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlDataList)
]]

--[[
% CreateEdit

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlEdit)
]]

--[[
% CreateTextEditor

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlTextEditor)
]]

--[[
% CreateListBox

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlListBox)
]]

--[[
% CreatePopup

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlPopup)
]]

--[[
% CreateSlider

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlSlider)
]]

--[[
% CreateStatic

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlStatic)
]]

--[[
% CreateSwitcher

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlSwitcher)
]]

--[[
% CreateTree

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlTree)
]]

--[[
% CreateUpDown

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlUpDown)
]]

--[[
% CreateHorizontalLine

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ length (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlLine)
]]

--[[
% CreateVerticalLine

**[Override]**

Override Changes:
- Added optional `control_name` parameter.
- Store reference to original control object.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ length (number)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlLine)
]]

-- Override Create* methods to store a reference to the original created object and its control ID
-- Also adds an optional parameter at the end for a control name
for num_args, ctrl_types in pairs({
    [0] = {"CancelButton", "OkButton",},
    [2] = {"Button", "Checkbox", "CloseButton", "DataList", "Edit", "TextEditor",
        "ListBox", "Popup", "Slider", "Static", "Switcher", "Tree", "UpDown", "ComboBox",
    },
    [3] = {"HorizontalLine", "VerticalLine", "RadioButtonGroup"},
}) do
    for _, control_type in pairs(ctrl_types) do
        local type_exists = false
        if finenv.IsRGPLua then
            type_exists = finale.FCCustomWindow.__class["Create" .. control_type]
        else
            -- JW Lua crashes if we index the __class table with an invalid key, so instead search it
            for k, _ in pairs(finale.FCCustomWindow.__class) do
                if tostring(k) == "Create" .. control_type then
                    type_exists = true
                    break
                end
            end
        end
        if not type_exists then
            goto continue
        end

        methods["Create" .. control_type] = function(self, ...)
            for i = 1, num_args do
                mixin_helper.assert_argument_type(i + 1, select(i, ...), "number")
            end
            mixin_helper.assert_argument_type(num_args + 2, select(num_args + 1, ...), "string", "nil", "FCString")

            return create_control(self, control_type, num_args, ...)
        end

        :: continue ::
    end
end

--[[
% CreateCancelButtonAutoLocalized

Localizes the button using the key "cancel". Transalations for English, Spanish, and German are
provided automatically. Other translations may be added here or in individual localization files
for the script

@ self (FCMCustomWindow)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

--[[
% CreateOkButtonAutoLocalized

Localizes the button using the key "ok". Transalations for English, Spanish, and German are
provided automatically. Other translations may be added here or in individual localization files
for the script

@ self (FCMCustomWindow)
@ [control_name] (FCString | string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

--[[
% CreateCloseButtonAutoLocalized

**[>= v0.56]**

Localizes the button using the key "cancel". Transalations for English, Spanish, and German are
provided automatically. Other translations may be added here or in individual localization files
for the script

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]
loc.add_to_locale("en", { ok = "OK", cancel = "Cancel", close = "Close" })
loc.add_to_locale("es", { ok = "Aceptar", cancel = "Cancelar", close = "Cerrar" })
loc.add_to_locale("de", { ok = "OK", cancel = "Abbrechen", close = "Schließen" })
for num_args, method_info in pairs({
    [0] = { CancelButton = "cancel", OkButton = "ok" },
    [2] = { CloseButton = "close" },
})
do
    for method_name, localization_key in pairs(method_info) do
        methods["Create" .. method_name .. "AutoLocalized"] = function(self, ...)
            for i = 1, num_args do
                mixin_helper.assert_argument_type(i + 1, select(i, ...), "number")
            end
            mixin_helper.assert_argument_type(num_args + 2, select(num_args + 1, ...), "string", "nil", "FCString")

            return self["Create" .. method_name](self, ...)
                :SetTextLocalized(localization_key)
                :_FallbackCall("DoAutoResizeWidth", nil)
        end
    end
end

--[[
% FindControl

**[PDK Port]**

Finds a control based on its ID.

Port Changes:
- Returns the original control object.

@ self (FCMCustomWindow)
@ control_id (number)
: (FCMControl | nil)
]]
function methods:FindControl(control_id)
    mixin_helper.assert_argument_type(2, control_id, "number")

    return private[self].Controls[control_id]
end

--[[
% GetControl

Finds a control based on its name.

@ self (FCMCustomWindow)
@ control_name (FCString | string)
: (FCMControl | nil)
]]
function methods:GetControl(control_name)
    mixin_helper.assert_argument_type(2, control_name, "string", "FCString")

    return private[self].NamedControls[control_name]
end

--[[
% Each

An iterator for controls that can filter by class.

@ self (FCMCustomWindow)
@ [class_filter] (string) A class name, can be a parent class. See documentation `mixin.is_instance_of` for details on class filtering.
: (function) An iterator function.
]]
function methods:Each(class_filter)
    local i = -1
    local v
    local iterator = function()
        repeat
            i = i + 1
            v = mixin.FCMCustomWindow.GetItemAt(self, i)
        until not v or not class_filter or mixin_helper.is_instance_of(v, class_filter)

        return v
    end

    return iterator
end

--[[
% GetItemAt

**[Override]**

Override Changes:
- Returns the original control object.

@ self (FCMCustomWindow)
@ index (number)
: (FCMControl)
]]
function methods:GetItemAt(index)
    local item = self:GetItemAt__(index)
    return item and private[self].Controls[item:GetControlID()] or item
end

--[[
% GetParent

**[PDK Port]**

Returns the parent window. The parent will only be available while the window is showing.

@ self (FCMCustomWindow)
: (FCMCustomWindow | nil) `nil` if no parent
]]
function methods:GetParent()
    return private[self].Parent
end

--[[
% ExecuteModal

**[Override]**

Override Changes:
- Stores the parent window to make it available via `GetParent`.

@ self (FCMCustomWindow)
@ parent (FCCustomWindow | FCMCustomWindow | nil)
: (number)
]]
function methods:ExecuteModal(parent)
    private[self].Parent = parent
    local ret = self:ExecuteModal__(parent)
    private[self].Parent = nil
    return ret
end

return class

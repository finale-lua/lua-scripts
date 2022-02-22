--[[
$module FCMCustomWindow
]]

local mixin = require("library.mixin")

local private = setmetatable({}, {__mode = "k"})
local props = {}


--[[
% Init

**[Internal]**

@ self (FCMCustomWindow)
]]
function props:Init()
    private[self] = private[self] or {Controls = {}, NamedControls = {}}
end


--[[
% CreateCancelButton

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

--[[
% CreateOkButton

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

-- Override Create* methods to store a reference to the original created object and its control ID
-- Also adds an optional parameter at the end for a control name
for _, f in ipairs({"CancelButton", "OkButton"}) do
    props["Create" .. f] = function(self, control_name)
        mixin.assert_argument(control_name, {"string", "nil", "FCString"}, 2)

        local control = self["Create" .. f .. "_"](self)
        private[self].Controls[control:GetControlID()] = control
        control:RegisterParent(self)

        if control_name then
            control_name = type(control_name) == "userdata" and control_name.LuaString or control_name

            if private[self].NamedControls[control_name] then
                error("A control is already registered with the name '" .. control_name .. "'", 2)
            end

            private[self].NamedControls[control_name] = control
        end

        return control
    end
end


--[[
% CreateButton

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

--[[
% CreateCheckbox

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlCheckbox)
]]

--[[
% CreateDataList

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlDataList)
]]

--[[
% CreateEdit

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlEdit)
]]

--[[
% CreateListBox

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlListBox)
]]

--[[
% CreatePopup

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlPopup)
]]

--[[
% CreateSlider

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlSlider)
]]

--[[
% CreateStatic

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlStatic)
]]

--[[
% CreateSwitcher

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlSwitcher)
]]

--[[
% CreateTree

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlTree)
]]

--[[
% CreateUpDown

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlUpDown)
]]

for _, f in ipairs({"Button", "Checkbox", "DataList", "Edit", "ListBox", "Popup", "Slider", "Static", "Switcher", "Tree", "UpDown"}) do
    props["Create" .. f] = function(self, x, y, control_name)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)
        mixin.assert_argument(control_name, {"string", "nil", "FCString"}, 4)

        local control = self["Create" .. f .. "_"](self, x, y)
        private[self].Controls[control:GetControlID()] = control
        control:RegisterParent(self)

        if control_name then
            control_name = type(control_name) == "userdata" and control_name.LuaString or control_name

            if private[self].NamedControls[control_name] then
                error("A control is already registered with the name '" .. control_name .. "'", 2)
            end

            private[self].NamedControls[control_name] = control
        end

        return control
    end
end

--[[
% CreateHorizontalLine

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ length (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlLine)
]]

--[[
% CreateVerticalLine

**[Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ length (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlLine)
]]

for _, f in ipairs({"HorizontalLine", "VerticalLine"}) do
    props["Create" .. f] = function(self, x, y, length, control_name)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)
        mixin.assert_argument(length, "number", 4)
        mixin.assert_argument(control_name, {"string", "nil", "FCString"}, 5)

        local control = self["Create" .. f .. "_"](self, x, y, length)
        private[self].Controls[control:GetControlID()] = control
        control:RegisterParent(self)

        if control_name then
            control_name = type(control_name) == "userdata" and control_name.LuaString or control_name

            if private[self].NamedControls[control_name] then
                error("A control is already registered with the name '" .. control_name .. "'", 2)
            end

            private[self].NamedControls[control_name] = control
        end

        return control
    end
end

--[[
% FindControl

**[PDK Port]**
Finds a control based on its ID.

@ self (FCMCustomWindow)
@ control_id (number)
: (FCMControl|nil)
]]
function props:FindControl(control_id)
    mixin.assert_argument(control_id, "number", 2)

    return private[self].Controls[control_id]
end

--[[
% GetControl

Finds a control based on its name.

@ self (FCMCustomWindow)
@ control_name (FCString|string)
: (FCMControl|nil)
]]
function props:GetControl(control_name)
    mixin.assert_argument(control_name, {"string", "FCString"}, 2)
    return private[self].NamedControls[control_name]
end


--[[
% CreateCloseButton

**[>= v0.56] [Override]**
Add optional `control_name` parameter.

@ self (FCMCustomWindow)
@ x (number)
@ y (number)
@ [control_name] (FCString|string) Optional name to allow access from `GetControl` method.
: (FCMCtrlButton)
]]

if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then
    function props.CreateCloseButton(self, x, y, control_name)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)
        mixin.assert_argument(control_name, {"string", "nil", "FCString"}, 4)

        local control = self:CreateCloseButton_(x, y)
        private[self].Controls[control:GetControlID()] = control
        control:RegisterParent(self)

        if control_name then
            control_name = type(control_name) == "userdata" and control_name.LuaString or control_name

            if private[self].NamedControls[control_name] then
                error("A control is already registered with the name '" .. control_name .. "'", 2)
            end

            private[self].NamedControls[control_name] = control
        end

        return control
    end
end


return props
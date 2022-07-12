--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlUpDown

Summary of modifications:
- `GetConnectedEdit` returns the original control object.
- Handlers for the `UpDownPressed` event can now be set on a control.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local private = setmetatable({}, {__mode = "k"})
local props = {}

--[[
% Init

**[Internal]**

@ self (FCMCtrlUpDown)
]]
function props:Init()
    private[self] = private[self] or {}
end

--[[
% GetConnectedEdit

**[Override]**
Ensures that original edit control is returned.

@ self (FCMCtrlUpDown)
: (FCMCtrlEdit|nil) `nil` if there is no edit connected.
]]
function props:GetConnectedEdit()
    return private[self].ConnectedEdit
end

--[[
% ConnectIntegerEdit

**[Override]**

@ self (FCMCtrlUpDown)
@ control (FCCtrlEdit)
@ minvalue (number)
@ maxvalue (number)
: (boolean) `true` on success
]]
function props:ConnectIntegerEdit(control, minvalue, maxvalue)
    mixin.assert_argument(control, "FCMCtrlEdit", 2)
    mixin.assert_argument(minvalue, "number", 3)
    mixin.assert_argument(maxvalue, "number", 4)

    local ret = self:ConnectIntegerEdit_(control, minvalue, maxvalue)

    if ret then
        private[self].ConnectedEdit = control
    end

    return ret
end

--[[
% ConnectMeasurementEdit

**[Override]**

@ self (FCMCtrlUpDown)
@ control (FCCtrlEdit)
@ minvalue (number)
@ maxvalue (number)
: (boolean) `true` on success
]]
function props:ConnectMeasurementEdit(control, minvalue, maxvalue)
    mixin.assert_argument(control, "FCMCtrlEdit", 2)
    mixin.assert_argument(minvalue, "number", 3)
    mixin.assert_argument(maxvalue, "number", 4)

    local ret = self:ConnectMeasurementEdit_(control, minvalue, maxvalue)

    if ret then
        private[self].ConnectedEdit = control
    end

    return ret
end

--[[
% AddHandlePress

**[Fluid]**
Adds a handler for UpDownPressed events.

@ self (FCMCtrlUpDown)
@ callback (function) See `FCCustomLuaWindow.HandleUpDownPressed` in the PDK for callback signature.
]]

--[[
% RemoveHandlePress

**[Fluid]**
Removes a handler added with `AddHandlePress`.

@ self (FCMCtrlUpDown)
@ callback (function)
]]
props.AddHandlePress, props.RemoveHandlePress = mixin_helper.create_standard_control_event("HandleUpDownPressed")

return props

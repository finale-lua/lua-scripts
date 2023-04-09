--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlUpDown

## Summary of Modifications
- Methods that returned a boolean to indicate success/failure now throw an error instead.
- `GetConnectedEdit` returns the original control object.
- Added methods to allow handlers for the `UpDownPressed` event to be set directly on the control.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local meta = {}
local public = {}
local private = setmetatable({}, {__mode = "k"})

--[[
% Init

**[Internal]**

@ self (FCMCtrlUpDown)
]]
function meta:Init()
    if private[self] then
        return
    end

    private[self] = {}
end

--[[
% GetConnectedEdit

**[Override]**

Override Changes:
- Ensures that original edit control is returned.

@ self (FCMCtrlUpDown)
: (FCMCtrlEdit | nil) `nil` if there is no edit connected.
]]
function public:GetConnectedEdit()
    return private[self].ConnectedEdit
end

--[[
% ConnectIntegerEdit

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Stores original control object.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCtrlUpDown)
@ control (FCCtrlEdit)
@ minvalue (number)
@ maxvalue (number)
]]
function public:ConnectIntegerEdit(control, minvalue, maxvalue)
    mixin_helper.assert_argument_type(2, control, "FCMCtrlEdit")
    mixin_helper.assert_argument_type(3, minvalue, "number")
    mixin_helper.assert_argument_type(4, maxvalue, "number")

    mixin_helper.boolean_to_error(self, "ConnectIntegerEdit", control, minvalue, maxvalue)

    -- If we've arrived here, it must have been successfully connected
    private[self].ConnectedEdit = control
end

--[[
% ConnectMeasurementEdit

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Stores original control object.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCtrlUpDown)
@ control (FCCtrlEdit)
@ minvalue (number)
@ maxvalue (number)
]]
function public:ConnectMeasurementEdit(control, minvalue, maxvalue)
    mixin_helper.assert_argument_type(2, control, "FCMCtrlEdit")
    mixin_helper.assert_argument_type(3, minvalue, "number")
    mixin_helper.assert_argument_type(4, maxvalue, "number")

    mixin_helper.boolean_to_error(self, "ConnectMeasurementEdit", control, minvalue, maxvalue)

    -- If we've arrived here, it must have been successfully connected
    private[self].ConnectedEdit = control
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
public.AddHandlePress, public.RemoveHandlePress = mixin_helper.create_standard_control_event("HandleUpDownPressed")

return {meta, public}

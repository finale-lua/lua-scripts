--  Author: Edward Koltun
--  Date: April 11, 2022
--[[
$module FCXCtrlMeasurementEdit

*Extends `FCMCtrlEdit`*

Summary of modifications:
- Parent window must be an instance of `FCXCustomLuaWindow`
- Displayed measurement unit will be automatically updated with the parent window
- Measurement edits can be set to one of three types which correspond to the `GetMeasurement*`, `SetMeasurement*` and *GetRangeMeasurement*` methods. The type affects which methods are used for changing measurement units, for events, and for interacting with an `FCXCtrlUpDown` control.
- All measurement get and set methods no longer accept a measurement unit as this is taken from the parent window.
- `Change` event has been overridden to pass a measurement.
- Added hooks for restoring control state
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local utils = require("library.utils")

local private = setmetatable({}, {__mode = "k"})
local props = {MixinParent = "FCMCtrlEdit"}

local trigger_change
local each_last_change

--[[
% Init

**[Internal]**

@ self (FCXCtrlMeasurementEdit)
]]
function props:Init()
    local parent = self:GetParent()
    mixin.assert(mixin.is_instance_of(parent, "FCXCustomLuaWindow"), "FCXCtrlMeasurementEdit must have a parent window that is an instance of FCXCustomLuaWindow")

    private[self] = private[self] or {
        Type = "MeasurementInteger",
        LastMeasurementUnit = parent:GetMeasurementUnit(),
    }
end

--[[
% SetText

**[Fluid] [Override]**
Ensures that the overridden `Change` event is triggered.


@ self (FCXCtrlMeasurementEdit)
@ str (FCString|string|number)
]]

--[[
% SetInteger

**[Fluid] [Override]**
Ensures that the overridden `Change` event is triggered.

@ self (FCXCtrlMeasurementEdit)
@ anint (number)
]]

--[[
% SetFloat

**[Fluid] [Override]**
Ensures that the overridden `Change` event is triggered.

@ self (FCXCtrlMeasurementEdit)
@ value (number)
]]

for method, valid_types in pairs({
    Text = {"string", "number", "FCString"},
    Integer = "number",
    Float = "number",
}) do
    props["Set" .. method] = function(self, value)
        mixin.assert_argument(value, valid_types, 2)

        mixin.FCMCtrlEdit["Set" .. method](self, value)
        trigger_change(self)
    end
end

--[[
% GetMeasurement

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

@ self (FCXCtrlMeasurementEdit)
: (number)
]]

--[[
% GetRangeMeasurement

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

@ self (FCXCtrlMeasurementEdit)
@ minimum (number)
@ maximum (number)
: (number)
]]

--[[
% SetMeasurement

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.
Also ensures that the overridden `Change` event is triggered.

@ self (FCXCtrlMeasurementEdit)
@ value (number)
]]

--[[
% GetMeasurementInteger

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

@ self (FCXCtrlMeasurementEdit)
: (number)
]]

--[[
% GetRangeMeasurementInteger

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

@ self (FCXCtrlMeasurementEdit)
@ minimum (number)
@ maximum (number)
: (number)
]]

--[[
% SetMeasurementInteger

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.
Also ensures that the overridden `Change` event is triggered.

@ self (FCXCtrlMeasurementEdit)
@ value (number)
]]

--[[
% GetMeasurementEfix

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

@ self (FCXCtrlMeasurementEdit)
: (number)
]]

--[[
% GetRangeMeasurementEfix

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

@ self (FCXCtrlMeasurementEdit)
@ minimum (number)
@ maximum (number)
: (number)
]]

--[[
% SetMeasurementEfix

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.
Also ensures that the overridden `Change` event is triggered.

@ self (FCXCtrlMeasurementEdit)
@ value (number)
]]

for method, valid_types in pairs({
    Measurement = "number",
    MeasurementInteger = "number",
    MeasurementEfix = "number",
}) do
    props["Get" .. method] = function(self)
        return mixin.FCMCtrlEdit["Get" .. method](self, private[self].LastMeasurementUnit)
    end

    props["GetRange" .. method] = function(self, minimum, maximum)
        mixin.assert_argument(minimum, "number", 2)
        mixin.assert_argument(maximum, "number", 3)

        return mixin.FCMCtrlEdit["GetRange" .. method](self, private[self].LastMeasurementUnit, minimum, maximum)
    end

    props["Set" .. method] = function (self, value)
        mixin.assert_argument(value, valid_types, 2)

        mixin.FCMCtrlEdit["Set" .. method](self, value, private[self].LastMeasurementUnit)
        trigger_change(self)
    end

    props["IsType" .. method] = function(self)
        return private[self].Type == method
    end
end

--[[
% GetType

Returns the measurement edit's type. Can also be appended to `"Get"`, `"GetRange"`, or `"Set"` to use type-specific methods.

@ self (FCXCtrlMeasurementEdit)
: (string) `"Measurement"`, `"MeasurementInteger"`, or `"MeasurementEfix"`
]]
function props:GetType()
    return private[self].Type
end

--[[
% IsTypeMeasurement

Checks if the type is `"Measurement"`.

@ self (FCXCtrlMeasurementEdit)
: (boolean) 
]]

--[[
% IsTypeMeasurementInteger

Checks if the type is `"MeasurementInteger"`.

@ self (FCXCtrlMeasurementEdit)
: (boolean) 
]]

--[[
% IsTypeMeasurementEfix

Checks if the type is `"MeasurementEfix"`.

@ self (FCXCtrlMeasurementEdit)
: (boolean) 
]]

--[[
% SetTypeMeasurement

**[Fluid]**
Sets the type to `"Measurement"`.
This means that the setters & getters used in events, measurement unit changes, and up down controls are `GetMeasurement`, `GetRangeMeasurement`, and `SetMeasurement`.

@ self (FCXCtrlMeasurementEdit)
]]
function props:SetTypeMeasurement()
    if private[self].Type == "Measurement" then
        return
    end

    if private[self].Type == "MeasurementEfix" then
        for v in each_last_change(self) do
            v.last_value = v.last_value / 64
        end
    end

    private[self].Type = "Measurement"
end

--[[
% SetTypeMeasurementInteger

**[Fluid]**
Sets the type to `"MeasurementInteger"`. This is the default type.
This means that the setters & getters used in events, measurement unit changes, and up down controls are `GetMeasurementInteger`, `GetRangeMeasurementInteger`, and `SetMeasurementInteger`.

@ self (FCXCtrlMeasurementEdit)
]]
function props:SetTypeMeasurementInteger()
    if private[self].Type == "MeasurementInteger" then
        return
    end

    if private[self].Type == "Measurement" then
        for v in each_last_change(self) do
            v.last_value = utils.round(v.last_value)
        end
    elseif private[self].Type == "MeasurementEfix" then
        for v in each_last_change(self) do
            v.last_value = utils.round(v.last_value / 64)
        end
    end

    private[self].Type = "MeasurementInteger"
end

--[[
% SetTypeMeasurementEfix

**[Fluid]**
Sets the type to `"MeasurementEfix"`.
This means that the setters & getters used in events, measurement unit changes, and up down controls are `GetMeasurementEfix`, `GetRangeMeasurementEfix`, and `SetMeasurementEfix`.

@ self (FCXCtrlMeasurementEdit)
]]
function props:SetTypeMeasurementEfix()
    if private[self].Type == "MeasurementEfix" then
        return
    end

    for v in each_last_change(self) do
        v.last_value = v.last_value * 64
    end

    private[self].Type = "MeasurementEfix"
end

--[[
% UpdateMeasurementUnit

**[Fluid] [Internal]**
Checks the parent window for a change in measurement unit and updates the control if needed.

@ self (FCXCtrlMeasurementEdit)
]]
function props:UpdateMeasurementUnit()
    local new_unit = self:GetParent():GetMeasurementUnit()

    if private[self].LastMeasurementUnit ~= new_unit then
        local val = self["Get" .. private[self].Type](self)
        private[self].LastMeasurementUnit = new_unit
        self["Set" .. private[self].Type](self, val)
    end
end

--[[
% HandleChange

**[Callback Template] [Override]**
The type and unit of `last_value` will change depending on the measurement edit's type. The possibilities are:
- `"Measurement"` => EVPUs (with fractional part)
- `"MeasurementInteger"` => whole EVPUs (without fractional part)
- `"MeasurementEfix"` => EFIXes (1 EFIX is 1/64th of an EVPU)

@ control (FCXCtrlMeasurementEdit) The control that was changed.
@ last_value (number) The previous measurement value of the control.
]]

--[[
% AddHandleChange

**[Fluid] [Override]**
Adds a handler for when the value of the control changes.
The even will fire when:
- The window is created (if the value of the control is not an empty string)
- The value of the control is changed by the user
- The value of the control is changed programmatically (if the value of the control is changed within a handler, that *same* handler will not be called again for that change.)
- A measurement unit change will only trigger the event if the underlying measurement value has changed.

@ self (FCXCtrlMeasurementEdit)
@ callback (function) See `HandleChange` for callback signature.
]]

--[[
% RemoveHandleChange

**[Fluid] [Override]**
Removes a handler added with `AddHandleChange`.

@ self (FCXCtrlMeasurementEdit)
@ callback (function)
]]
props.AddHandleChange, props.RemoveHandleChange, trigger_change, each_last_change = mixin_helper.create_custom_control_change_event(
    {
        name = "last_value",
        get = function(ctrl)
            return mixin.FCXCtrlMeasurementEdit["Get" .. private[ctrl].Type](ctrl)
        end,
        initial = 0,
    }
)

return props

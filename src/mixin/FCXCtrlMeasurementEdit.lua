--  Author: Edward Koltun
--  Date: April 11, 2022
--[[
$module FCXCtrlMeasurementEdit

*Extends `FCMCtrlEdit`*

_Note that the type should be set **before** setting any values._

Summary of modifications:
- Parent window must be an instance of `FCXCustomLuaWindow`.
- Displayed measurement unit will be automatically updated with the parent window.
- Measurement edits can be set to one of four types which correspond to the `GetMeasurement*`, `SetMeasurement*` and *GetRangeMeasurement*` methods. The type affects which methods are used for changing measurement units, for events, and for interacting with an `FCXCtrlUpDown` control.
- All measurement get and set methods no longer accept a measurement unit as this is taken from the parent window.
- Added measures to prevent underlying value from changing when the measurement unit is changed.
- `Change` event has been overridden to pass a measurement.
- Added hooks into control state restoration
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local utils = require("library.utils")

local private = setmetatable({}, {__mode = "k"})
local props = {MixinParent = "FCMCtrlEdit"}

local trigger_change
local each_last_change

-- Converts a measurement value from one type (Measurement, MeasurementInteger, MeasurementEfix, Measurement10000th) to another
local function convert_type(value, from, to)
    -- Sanitise all integer types
    if from ~= "Measurement" then
        value = utils.round(value)
    end

    if from == to then
        return value
    end

    if from == "MeasurementEfix" then
        value = value / 64
    elseif from == "Measurement10000th" then
        value = value / 10000
    end

    if to == "MeasurementEfix" then
        value = value * 64
    elseif to == "Measurement10000th" then
        value = value * 10000
    end

    if to == "Measurement" then
        return value
    end

    return utils.round(value)
end

--[[
% Init

**[Internal]**

@ self (FCXCtrlMeasurementEdit)
]]
function props:Init()
    local parent = self:GetParent()
    mixin_helper.assert(function() return mixin_helper.is_instance_of(parent, "FCXCustomLuaWindow") end, "FCXCtrlMeasurementEdit must have a parent window that is an instance of FCXCustomLuaWindow")

    private[self] = private[self] or {
        Type = "MeasurementInteger",
        LastMeasurementUnit = parent:GetMeasurementUnit(),
        LastText = mixin.FCMCtrlEdit.GetText(self),
        Value = mixin.FCMCtrlEdit.GetMeasurementInteger(self, parent:GetMeasurementUnit()),
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
    Integer = {"number"},
    Float = {"number"},
}) do
    props["Set" .. method] = function(self, value)
        mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))

        mixin.FCMCtrlEdit["Set" .. method](self, value)
        trigger_change(self)
    end
end

--[[
% GetType

Returns the measurement edit's type. The result can also be appended to `"Get"`, `"GetRange"`, or `"Set"` to use type-specific methods.
The default type is `"MeasurementInteger"`.

@ self (FCXCtrlMeasurementEdit)
: (string) `"Measurement"`, `"MeasurementInteger"`, `"MeasurementEfix"`, or `"Measurement10000th"`
]]
function props:GetType()
    return private[self].Type
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
% IsTypeMeasurement

Checks if the type is `"Measurement"`.

@ self (FCXCtrlMeasurementEdit)
: (boolean) 
]]

--[[
% SetTypeMeasurement

**[Fluid]**
Sets the type to `"Measurement"`.
This means that the getters & setters used in events, measurement unit changes, and up down controls are `GetMeasurement`, `GetRangeMeasurement`, and `SetMeasurement`.

@ self (FCXCtrlMeasurementEdit)
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
% IsTypeMeasurementInteger

Checks if the type is `"MeasurementInteger"`.

@ self (FCXCtrlMeasurementEdit)
: (boolean) 
]]

--[[
% SetTypeMeasurementInteger

**[Fluid]**
Sets the type to `"MeasurementInteger"`. This is the default type.
This means that the getters & setters used in events, measurement unit changes, and up down controls are `GetMeasurementInteger`, `GetRangeMeasurementInteger`, and `SetMeasurementInteger`.

@ self (FCXCtrlMeasurementEdit)
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

--[[
% IsTypeMeasurementEfix

Checks if the type is `"MeasurementEfix"`.

@ self (FCXCtrlMeasurementEdit)
: (boolean) 
]]

--[[
% SetTypeMeasurementEfix

**[Fluid]**
Sets the type to `"MeasurementEfix"`.
This means that the getters & setters used in events, measurement unit changes, and up down controls are `GetMeasurementEfix`, `GetRangeMeasurementEfix`, and `SetMeasurementEfix`.

@ self (FCXCtrlMeasurementEdit)
]]

--[[
% GetMeasurement10000th

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

@ self (FCXCtrlMeasurementEdit)
: (number)
]]

--[[
% GetRangeMeasurement10000th

**[Override]**
Removes the measurement unit parameter, taking it instead from the parent window.

@ self (FCXCtrlMeasurementEdit)
@ minimum (number)
@ maximum (number)
: (number)
]]

--[[
% SetMeasurement10000th

**[Fluid] [Override]**
Removes the measurement unit parameter, taking it instead from the parent window.
Also ensures that the overridden `Change` event is triggered.

@ self (FCXCtrlMeasurementEdit)
@ value (number)
]]

--[[
% IsTypeMeasurement10000th

Checks if the type is `"Measurement10000th"`.

@ self (FCXCtrlMeasurementEdit)
: (boolean) 
]]

--[[
% SetTypeMeasurement10000th

**[Fluid]**
Sets the type to `"Measurement10000th"`.
This means that the getters & setters used in events, measurement unit changes, and up down controls are `GetMeasurement10000th`, `GetRangeMeasurement10000th`, and `SetMeasurement10000th`.

@ self (FCXCtrlMeasurementEdit)
]]

for method, valid_types in pairs({
    Measurement = {"number"},
    MeasurementInteger = {"number"},
    MeasurementEfix = {"number"},
    Measurement10000th = {"number"},
}) do
    props["Get" .. method] = function(self)
        local text = mixin.FCMCtrlEdit.GetText(self)
        if (text ~= private[self].LastText) then
            private[self].Value = mixin.FCMCtrlEdit["Get" .. private[self].Type](self, private[self].LastMeasurementUnit)
            private[self].LastText = text
        end

        return convert_type(private[self].Value, private[self].Type, method)
    end

    props["GetRange" .. method] = function(self, minimum, maximum)
        mixin_helper.assert_argument_type(2, minimum, "number")
        mixin_helper.assert_argument_type(3, maximum, "number")

        minimum = method ~= "Measurement" and math.ceil(minimum) or minimum
        maximum = method ~= "Measurement" and math.floor(maximum) or maximum
        return utils.clamp(mixin.FCXCtrlMeasurementEdit["Get" .. method](self), minimum, maximum)
    end

    props["Set" .. method] = function (self, value)
        mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))

        private[self].Value = convert_type(value, method, private[self].Type)
        mixin.FCMCtrlEdit["Set" .. private[self].Type](self, private[self].Value, private[self].LastMeasurementUnit)
        private[self].LastText = mixin.FCMCtrlEdit.GetText(self)
        trigger_change(self)
    end

    props["IsType" .. method] = function(self)
        return private[self].Type == method
    end

    props["SetType" .. method] = function(self)
        private[self].Value = convert_type(private[self].Value, private[self].Type, method)
        for v in each_last_change(self) do
            v.last_value = convert_type(v.last_value, private[self].Type, method)
        end

        private[self].Type = method
    end
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
        local value = mixin.FCXCtrlMeasurementEdit["Get" .. private[self].Type](self)
        private[self].LastMeasurementUnit = new_unit
        mixin.FCXCtrlMeasurementEdit["Set" .. private[self].Type](self, value)
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
        get = function(self)
            return mixin.FCXCtrlMeasurementEdit["Get" .. private[self].Type](self)
        end,
        initial = 0,
    }
)

return props

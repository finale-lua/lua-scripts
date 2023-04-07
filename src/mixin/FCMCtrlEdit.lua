--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlEdit

## Summary of Modifications
- Added `Change` custom control event.
- Added hooks into control state preservation.
- `GetMeasurement*` and `SetMeasurement*` methods have been overridden to use the `FCMString` versions of those methods internally. For more details on any changes, see the documentation for `FCMString`.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local utils = require("library.utils")

local meta = {}
local public = {}

local trigger_change
local each_last_change
local temp_str = mixin.FCMString()

--[[
% SetText

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.

@ self (FCMCtrlEdit)
@ str (FCString | string | number)
]]
function public:SetText(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    mixin.FCMControl.SetText(self, str)
    trigger_change(self)
end

--[[
% GetInteger

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
: (number)
]]

--[[
% SetInteger

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ anint (number)
]]

--[[
% GetFloat

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
: (number)
]]

--[[
% SetFloat

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ value (number)
]]
for method, valid_types in pairs({
    Integer = {"number"},
    Float = {"number"},
}) do
    public["Get" .. method] = function(self)
        -- This is the long way around, but it ensures that the correct control value is used
        mixin.FCMControl.GetText(self, temp_str)
        return temp_str["Get" .. method](temp_str, 0)
    end

    public["Set" .. method] = function(self, value)
        mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))

        temp_str["Set" .. method](temp_str, value)
        mixin.FCMControl.SetText(self, temp_str)
        trigger_change(self)
    end
end

--[[
% GetMeasurement

**[Override]**

- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
: (number)
]]

--[[
% GetRangeMeasurement

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
@ minimum (number)
@ maximum (number)
: (number)
]]

--[[
% SetMeasurement

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]

--[[
% GetMeasurementEfix

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
: (number)
]]

--[[
% GetRangeMeasurementEfix

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
@ minimum (number)
@ maximum (number)
: (number)
]]

--[[
% SetMeasurementEfix

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]

--[[
% GetMeasurementInteger

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
: (number)
]]

--[[
% GetRangeMeasurementInteger

**[Override]**

Override Changes:
- Hooks into control state preservation.
- Fixes issue with decimal places in `minimum` being discarded instead of being correctly taken into account (see `FCMString.GetRangeMeasurementInteger`).

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
@ minimum (number)
@ maximum (number)
: (number)
]]

--[[
% SetMeasurementInteger

**[Fluid] [Override]**

Override Changes:
- Ensures that `Change` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]

--[[
% GetMeasurement10000th

Returns the measurement in 10000ths of an EVPU.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
: (number)
]]

--[[
% GetRangeMeasurement10000th

Returns the measurement in 10000ths of an EVPU, clamped between two values.

@ self (FCMCtrlEdit)
@ measurementunit (number) Any of the finale.MEASUREMENTUNIT_* constants.
@ minimum (number)
@ maximum (number)
: (number)
]]

--[[
% SetMeasurement10000th

**[Fluid]**
Sets a measurement in 10000ths of an EVPU.

@ self (FCMCtrlEdit)
@ value (number)
@ measurementunit (number)
]]
for method, valid_types in pairs({
    Measurement = {"number"},
    MeasurementEfix = {"number"},
    MeasurementInteger = {"number"},
    Measurement10000th = {"number"},
}) do
    public["Get" .. method] = function(self, measurementunit)
        mixin_helper.assert_argument_type(2, measurementunit, "number")

        mixin.FCMControl.GetText(self, temp_str)
        return temp_str["Get" .. method](temp_str, measurementunit)
    end

    public["GetRange" .. method] = function(self, measurementunit, minimum, maximum)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")

        mixin.FCMControl.GetText(self, temp_str)
        return temp_str["GetRange" .. method](temp_str, measurementunit, minimum, maximum)
    end

    public["Set" .. method] = function(self, value, measurementunit)
        mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
        mixin_helper.assert_argument_type(3, measurementunit, "number")

        temp_str["Set" .. method](temp_str, value, measurementunit)
        mixin.FCMControl.SetText(self, temp_str)
        trigger_change(self)
    end
end

--[[
% GetRangeInteger

**[Override]**

Override Changes:
- Hooks into control state preservation.
- Fixes issue with decimal places in `minimum` being discarded instead of being correctly taken into account.

@ self (FCMCtrlEdit)
@ minimum (number)
@ maximum (number)
: (number)
]]
function public:GetRangeInteger(minimum, maximum)
    mixin_helper.assert_argument_type(2, minimum, "number")
    mixin_helper.assert_argument_type(3, maximum, "number")

    return utils.clamp(mixin.FCMCtrlEdit.GetInteger(self), math.ceil(minimum), math.floor(maximum))
end

--[[
% HandleChange

**[Callback Template]**

@ control (FCMCtrlEdit) The control that was changed.
@ last_value (string) The previous value of the control.
]]

--[[
% AddHandleChange

**[Fluid]**

Adds a handler for when the value of the control changes.
The even will fire when:
- The window is created (if the value of the control is not an empty string)
- The value of the control is changed by the user
- The value of the control is changed programmatically (if the value of the control is changed within a handler, that *same* handler will not be called again for that change.)

@ self (FCMCtrlEdit)
@ callback (function) See `HandleChange` for callback signature.
]]

--[[
% RemoveHandleChange

**[Fluid]**

Removes a handler added with `AddHandleChange`.

@ self (FCMCtrlEdit)
@ callback (function)
]]
public.AddHandleChange, public.RemoveHandleChange, trigger_change, each_last_change = mixin_helper.create_custom_control_change_event(
    {
        name = "last_value",
        get = mixin.FCMControl.GetText,
        initial = ""
    }
)

return {meta, public}

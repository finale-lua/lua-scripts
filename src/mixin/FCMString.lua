--  Author: Edward Koltun
--  Date: August 8, 2022
--[[
$module FCMString

## Summary of Modifications
- Fixed rounding bugs in `GetMeasurement` and adjusted override handling behaviour to match `FCCtrlEdit.GetMeasurement` on Windows
- Fixed bug in `SetMeasurement` where all displayed numbers were truncated at 2 decimal places.
- Added `GetMeasurementInteger`, `GetRangeMeasurementInteger` and `SetMeasurementInteger` methods for parity with `FCCtrlEdit`
- Added `GetMeasurementEfix`, `GetRangeMeasurementEfix` and `SetMeasurementEfix methods for parity with `FCCtrlEdit`
- Added `*Measurement10000th` methods for setting and retrieving values in 10,000ths of an EVPU (eg for piano brace settings, slur tip width, etc)
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local utils = require("library.utils")
local measurement = require("library.measurement")

local meta = {}
local public = {}

-- Potential optimisation: reduce checked overrides to necessary minimum
local unit_overrides = {
    {unit = finale.MEASUREMENTUNIT_EVPUS, overrides = {"EVPUS", "evpus", "e"}},
    {unit = finale.MEASUREMENTUNIT_INCHES, overrides = {"inches", "in", "i", "”"}},
    {unit = finale.MEASUREMENTUNIT_CENTIMETERS, overrides = {"centimeters", "cm", "c"}},
    -- Points MUST come before Picas in checking order to prevent "p" from "pt" being incorrectly matched
    {unit = finale.MEASUREMENTUNIT_POINTS, overrides = {"points", "pts", "pt"}},
    {unit = finale.MEASUREMENTUNIT_PICAS, overrides = {"picas", "p"}},
    {unit = finale.MEASUREMENTUNIT_SPACES, overrides = {"spaces", "sp", "s"}},
    {unit = finale.MEASUREMENTUNIT_MILLIMETERS, overrides = {"millimeters", "mm", "m"}},
}

function split_string_start(str, pattern)
    return string.match(str, "^(" .. pattern .. ")(.*)")
end

local function split_number(str, allow_negative)
    return split_string_start(str, (allow_negative and "%-?" or "") .. "%d+%.?%d*")
end

local function calculate_picas(whole, fractional)
    fractional = fractional or 0
    return tonumber(whole) * 48 + tonumber(fractional) * 4
end

--[[
% GetMeasurement

**[Override]**

Override Changes:
- Fixes issue with incorrect rounding of returned value.
- Also changes handling of unit overrides to match the behaviour of `FCCtrlEdit` on Windows

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT_*` constants.
: (number) EVPUs with decimal part.
]]
function public:GetMeasurement(measurementunit)
    mixin_helper.assert_argument_type(2, measurementunit, "number")

    -- Normalise decimal separator
    local value = string.gsub(self.LuaString, "%" .. mixin.UI():GetDecimalSeparator(), '.')
    local start_number, remainder = split_number(value, true)

    if not start_number then
        return 0
    end

    if remainder then
        -- Spaces are allowed between the number and the override, so strip them
        remainder = utils.ltrim(remainder)

        if remainder == "" then
            goto continue
        end

        for _, unit in ipairs(unit_overrides) do
            for _, override in ipairs(unit.overrides) do
                local a, b = split_string_start(remainder, override)
                if a then
                    measurementunit = unit.unit
                    if measurementunit == finale.MEASUREMENTUNIT_PICAS then
                        return calculate_picas(start_number, split_number(utils.ltrim(b)))
                    end
                    goto continue
                end
            end
        end

        :: continue ::
    end

    if measurementunit == finale.MEASUREMENTUNIT_DEFAULT then
        measurementunit = measurement.get_real_default_unit()
    end

    start_number = tonumber(start_number)

    if measurementunit == finale.MEASUREMENTUNIT_EVPUS then
        return start_number
    elseif measurementunit == finale.MEASUREMENTUNIT_INCHES then
        return start_number * 288
    elseif measurementunit == finale.MEASUREMENTUNIT_CENTIMETERS then
        return start_number * 288 / 2.54
    elseif measurementunit == finale.MEASUREMENTUNIT_POINTS then
        return start_number * 4
    elseif measurementunit == finale.MEASUREMENTUNIT_PICAS then
        return start_number * 48
    elseif measurementunit == finale.MEASUREMENTUNIT_SPACES then
        return start_number * 24
    elseif measurementunit == finale.MEASUREMENTUNIT_MILLIMETERS then
        return start_number * 288 / 25.4
    end

    -- Original method returns 0 for invalid measurement units
    return 0
end

--[[
% GetRangeMeasurement

**[Override]**

Override Changes:
- See `FCMString.GetMeasurement`.

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
@ minimum (number)
@ maximum (number)
: (number)
]]
function public:GetRangeMeasurement(measurementunit, minimum, maximum)
    mixin_helper.assert_argument_type(2, measurementunit, "number")
    mixin_helper.assert_argument_type(3, minimum, "number")
    mixin_helper.assert_argument_type(4, maximum, "number")

    return utils.clamp(mixin.FCMString.GetMeasurement(measurementunit), minimum, maximum)
end

--[[
% SetMeasurement

**[Fluid] [Override]**

Override Changes:
- Fixes issue with displayed numbers being truncated at 2 decimal places.
- Emulates the behaviour of `FCCtrlEdit.SetMeasurement` on Windows while the window is showing.

@ self (FCMString)
@ value (number) The value to set in EVPUs.
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT_*` constants.
]]
function public:SetMeasurement(value, measurementunit)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, measurementunit, "number")

    if measurementunit == finale.MEASUREMENTUNIT_PICAS then
        local whole = math.floor(value / 48)
        local fractional = value - whole * 48
        fractional = fractional < 0 and fractional * -1 or fractional
        self.LuaString = whole .. "p" .. utils.to_integer_if_whole(utils.round(fractional / 4, 4))
        return
    end

    -- Invalid measurement units are treated the same as EVPUs (ie just set the raw value) in `FCCtrlEdit`
    if measurementunit == finale.MEASUREMENTUNIT_INCHES then
        value = value / 288
    elseif measurementunit == finale.MEASUREMENTUNIT_CENTIMETERS then
        value = value / 288 * 2.54
    elseif measurementunit == finale.MEASUREMENTUNIT_POINTS then
        value = value / 4
    elseif measurementunit == finale.MEASUREMENTUNIT_SPACES then
        value = value / 24
    elseif measurementunit == finale.MEASUREMENTUNIT_MILLIMETERS then
        value = value / 288 * 25.4
    end

    self.LuaString = tostring(utils.to_integer_if_whole(utils.round(value, 5)))
end

--[[
% GetMeasurementInteger

Returns the measurement in whole EVPUs.

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
: (number)
]]
function public:GetMeasurementInteger(measurementunit)
    mixin_helper.assert_argument_type(2, measurementunit, "number")

    return utils.round(mixin.FCMString.GetMeasurement(self, measurementunit))
end

--[[
% GetRangeMeasurementInteger

Returns the measurement in whole EVPUs, clamped between two values.
Also ensures that any decimal places in `minimum` are correctly taken into account instead of being discarded.

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
@ minimum (number)
@ maximum (number)
: (number)
]]
function public:GetRangeMeasurementInteger(measurementunit, minimum, maximum)
    mixin_helper.assert_argument_type(2, measurementunit, "number")
    mixin_helper.assert_argument_type(3, minimum, "number")
    mixin_helper.assert_argument_type(4, maximum, "number")

    return utils.clamp(mixin.FCMString.GetMeasurementInteger(measurementunit), math.ceil(minimum), math.floor(maximum))
end

--[[
% SetMeasurementInteger

**[Fluid]**

Sets a measurement in whole EVPUs.

@ self (FCMString)
@ value (number) The value in whole EVPUs.
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
]]
function public:SetMeasurementInteger(value, measurementunit)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, measurementunit, "number")

    mixin.FCMString.SetMeasurement(self, utils.round(value), measurementunit)
end

--[[
% GetMeasurementEfix

Returns the measurement in whole EFIXes (1/64th of an EVPU)

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
: (number)
]]
function public:GetMeasurementEfix(measurementunit)
    mixin_helper.assert_argument_type(2, measurementunit, "number")

    return utils.round(mixin.FCMString.GetMeasurement(self, measurementunit) * 64)
end

--[[
% GetRangeMeasurementEfix

Returns the measurement in whole EFIXes (1/64th of an EVPU), clamped between two values.

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
@ minimum (number)
@ maximum (number)
: (number)
]]
function public:GetRangeMeasurementEfix(measurementunit, minimum, maximum)
    mixin_helper.assert_argument_type(2, measurementunit, "number")
    mixin_helper.assert_argument_type(3, minimum, "number")
    mixin_helper.assert_argument_type(4, maximum, "number")

    return utils.clamp(mixin.FCMString.GetMeasurementEfix(measurementunit), math.ceil(minimum), math.floor(maximum))
end

--[[
% SetMeasurementEfix

**[Fluid]**

Sets a measurement in whole EFIXes.

@ self (FCMString)
@ value (number) The value in EFIXes (1/64th of an EVPU)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
]]
function public:SetMeasurementEfix(value, measurementunit)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, measurementunit, "number")

    mixin.FCMString.SetMeasurement(self, utils.round(value) / 64, measurementunit)
end

--[[
% GetMeasurement10000th

Returns the measurement in 10,000ths of an EVPU.

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
: (number)
]]
function public:GetMeasurement10000th(measurementunit)
    mixin_helper.assert_argument_type(2, measurementunit, "number")

    return utils.round(mixin.FCMString.GetMeasurement(self, measurementunit) * 10000)
end

--[[
% GetRangeMeasurement10000th

Returns the measurement in 10,000ths of an EVPU, clamped between two values.
Also ensures that any decimal places in `minimum` are handled correctly instead of being discarded.

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
@ minimum (number)
@ maximum (number)
: (number)
]]
function public:GetRangeMeasurement10000th(measurementunit, minimum, maximum)
    mixin_helper.assert_argument_type(2, measurementunit, "number")
    mixin_helper.assert_argument_type(3, minimum, "number")
    mixin_helper.assert_argument_type(4, maximum, "number")

    return utils.clamp(mixin.FCMString.GetMeasurement10000th(self, measurementunit), math.ceil(minimum), math.floor(maximum))
end

--[[
% SetMeasurement10000th

**[Fluid]**

Sets a measurement in 10,000ths of an EVPU.

@ self (FCMString)
@ value (number) The value in 10,000ths of an EVPU.
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
]]
function public:SetMeasurement10000th(value, measurementunit)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, measurementunit, "number")

    mixin.FCMString.SetMeasurement(self, utils.round(value) / 10000, measurementunit)
end

return {meta, public}

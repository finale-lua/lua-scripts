--  Author: Edward Koltun
--  Date: August 8, 2022
--[[
$module FCMString

Summary of modifications:
- Added `GetMeasurementInteger` and `SetMeasurementInteger` methods for parity with `FCCtrlEdit`
- Fixed rounding bugs in `GetMeasurement` and adjusted override handling behaviour to match `FCCtrlEdit.GetMeasurement` on Windows
- Added `*Measurement10000th` methods for setting and retrieving values in 10,000ths of an EVPU (eg for piano brace settings, slur tip width, etc)
]] --
local mixin = require("library.mixin")
local utils = require("library.utils")
local measurement = require("library.measurement")

local props = {}

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
Fixes issue with incorrect rounding of returned value.
Also changes handling of overrides to match the behaviour of `FCCtrlEdit` on Windows

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT_*` constants.
: (number) EVPUs with decimal part.
]]
function props:GetMeasurement(measurementunit)
    mixin.assert_argument(measurementunit, "number", 2)

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
See `FCMString.GetMeasurement`.

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
@ minimum (number)
@ maximum (number)
: (number)
]]
function props:GetRangeMeasurement(measurementunit, minimum, maximum)
    mixin.assert_argument(measurementunit, "number", 2)
    mixin.assert_argument(minimum, "number", 3)
    mixin.assert_argument(maximum, "number", 4)

    return utils.clamp(mixin.FCMString.GetMeasurement(measurementunit), minimum, maximum)
end

--[[
% GetMeasurementInteger

Returns the measurement in whole EVPUs.

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
: (number)
]]
function props:GetMeasurementInteger(measurementunit)
    mixin.assert_argument(measurementunit, "number", 2)

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
function props:GetRangeMeasurementInteger(measurementunit, minimum, maximum)
    mixin.assert_argument(measurementunit, "number", 2)
    mixin.assert_argument(minimum, "number", 3)
    mixin.assert_argument(maximum, "number", 4)

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
function props:SetMeasurementInteger(value, measurementunit)
    mixin.assert_argument(value, "number", 2)
    mixin.assert_argument(measurementunit, "number", 3)

    self:SetMeasurement_(utils.round(value), measurementunit)
end

--[[
% GetMeasurementEfix

Returns the measurement in whole EFIXes (1/64th of an EVPU)

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
: (number)
]]
function props:GetMeasurementEfix(measurementunit)
    mixin.assert_argument(measurementunit, "number", 2)

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
function props:GetRangeMeasurementEfix(measurementunit, minimum, maximum)
    mixin.assert_argument(measurementunit, "number", 2)
    mixin.assert_argument(minimum, "number", 3)
    mixin.assert_argument(maximum, "number", 4)

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
function props:SetMeasurementEfix(value, measurementunit)
    mixin.assert_argument(value, "number", 2)
    mixin.assert_argument(measurementunit, "number", 3)

    self:SetMeasurement_(utils.round(value) / 64, measurementunit)
end

--[[
% GetMeasurement10000th

Returns the measurement in 10,000ths of an EVPU.

@ self (FCMString)
@ measurementunit (number) One of the `finale.MEASUREMENTUNIT*_` constants.
: (number)
]]
function props:GetMeasurement10000th(measurementunit)
    mixin.assert_argument(measurementunit, "number", 2)

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
function props:GetRangeMeasurement10000th(measurementunit)
    mixin.assert_argument(measurementunit, "number", 2)
    mixin.assert_argument(minimum, "number", 3)
    mixin.assert_argument(maximum, "number", 4)

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
function props:SetMeasurement10000th(value, measurementunit)
    mixin.assert_argument(value, "number", 2)
    mixin.assert_argument(measurementunit, "number", 3)

    self:SetMeasurement_(utils.round(value) / 10000, measurementunit)
end

return props

--  Author: Edward Koltun
--  Date: August 8, 2022
--[[
$module FCMString

Summary of modifications:
- Added `GetMeasurementInteger` and `SetMeasurementInteger` methods for parity with `FCCtrlEdit`
]] --
local mixin = require("library.mixin")
local utils = require("library.utils")

local props = {}

--[[
% GetMeasurementInteger

Returns the measurement in whole EVPUs.

@ self (FCMString)
@ measurementunit (number) Any of the `finale.MEASUREMENTUNIT*_` constants.
: (number)
]]
function props:GetMeasurementInteger(measurementunit)
    mixin.assert_argument(measurementunit, "number", 2)

    return utils.round(self:GetMeasurement_(measurementunit))
end

--[[
% SetMeasurementInteger

**[Fluid]**
Sets a measurement in whole EVPUs.

@ self (FCMString)
@ value (number) The value in whole EVPUs.
@ measurementunit (number) Any of the `finale.MEASUREMENTUNIT*_` constants.
]]
function props:SetMeasurementInteger(value, measurementunit)
    mixin.assert_argument(value, "number", 2)
    mixin.assert_argument(measurementunit, "number", 3)

    self:SetMeasurement_(utils.round(value), measurementunit)
end

return props

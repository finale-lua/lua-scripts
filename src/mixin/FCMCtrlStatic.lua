--  Author: Edward Koltun
--  Date: September 18, 2022
--[[
$module FCMCtrlStatic

## Summary of Modifications
- Added hooks for control state preservation.
- SetTextColor updates visible color immediately if window is showing.
- Added methods for setting and displaying measurements.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local utils = require("library.utils")
local measurement = require("library.measurement")

local meta = {}
local public = {}
local private = setmetatable({}, {__mode = "k"})

local temp_str = mixin.FCMString()

local function get_suffix(unit, suffix_type)
    if suffix_type == 1 then
        return measurement.get_unit_suffix(unit)
    elseif suffix_type == 2 then
        return measurement.get_unit_abbreviation(unit)
    elseif suffix_type == 3 then
        return " " .. string.lower(measurement.get_unit_name(unit))
    end
end

local function set_measurement(self, measurementtype, measurementunit, value)
    mixin_helper.force_assert(private[self].MeasurementEnabled or measurementunit, "'measurementunit' can only be omitted if parent window is an instance of 'FCMCustomLuaWindow'", 3)

    private[self].MeasurementAutoUpdate = not measurementunit and true or false
    measurementunit = measurementunit or self:GetParent():GetMeasurementUnit()
    temp_str["Set" .. measurementtype](temp_str, value, measurementunit)
    temp_str:AppendLuaString(private[self].ShowMeasurementSuffix and get_suffix(measurementunit, private[self].MeasurementSuffixType) or "")

    mixin.FCMControl.SetText(self, temp_str)

    private[self].Measurement = value
    private[self].MeasurementType = measurementtype
end

--[[
% Init

**[Internal]**

@ self (FCMCtrlStatic)
]]
function meta:Init()
    if private[self] then
        return
    end

    private[self] = {
        ShowMeasurementSuffix = true,
        MeasurementSuffixType = 2,
        MeasurementEnabled = false,
    }
end

--[[
% RegisterParent

**[Fluid] [Internal] [Override]**

Override Changes:
- Set `MeasurementEnabled` flag.

*Do not disable this method.*

@ self (FCMCtrlStatic)
@ window (FCMCustomWindow)
]]
function public:RegisterParent(window)
    mixin.FCMControl.RegisterParent(self, window)

    private[self].MeasurementEnabled = mixin_helper.is_instance_of(window, "FCMCustomLuaWindow")
end

--[[
% SetTextColor

**[Fluid] [Override]**

Override Changes:
- Displays the new text color immediately.
- Hooks into control state preservation.

@ self (FCMCtrlStatic)
@ red (number)
@ green (number)
@ blue (number)
]]
function public:SetTextColor(red, green, blue)
    mixin_helper.assert_argument_type(2, red, "number")
    mixin_helper.assert_argument_type(3, green, "number")
    mixin_helper.assert_argument_type(4, blue, "number")

    private[self].TextColor = {red, green, blue}

    if not mixin.FCMControl.UseStoredState(self) then
        self:SetTextColor_(red, green, blue)

        -- If a new text color is set after the window has been shown, the visible color will not change until new text is set
        -- Getting and setting the text makes the new text color visible immediately
        mixin.FCMControl.SetText(self, mixin.FCMControl.GetText(self))
    end
end

--[[
% RestoreState

**[Fluid] [Internal] [Override]**

Override Changes:
- Restores `FCMCtrlStatic`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

@ self (FCMCtrlStatic)
]]
function public:RestoreState()
    mixin.FCMControl.RestoreState(self)

    -- Only need to restore color if it has been changed from the default
    if private[self].TextColor then
        mixin.FCMCtrlStatic.SetTextColor(self, private[self].TextColor[1], private[self].TextColor[2], private[self].TextColor[3])
    end
end

--[[
% SetText

**[Fluid] [Override]**

Override Changes:
- Switches the control's measurement status off.

@ self (FCMCtrlStatic)
@ str (FCString | string|  number)
]]
function public:SetText(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    mixin.FCMControl.SetText(self, str)

    private[self].Measurement = nil
    private[self].MeasurementType = nil
end

--[[
% SetMeasurement

**[Fluid]**

Sets a measurement in fractional EVPUs which will be displayed in either the specified measurement unit or the parent window's current measurement unit.
If using the parent window's measurement unit, it will be automatically updated if the parent window's measurement unit changes.

@ self (FCMCtrlStatic)
@ value (number) Value in EVPUs
@ [measurementunit] (number | nil) Forces the value to be displayed in this measurement unit. Can only be omitted if parent window is `FCMCustomLuaWindow`.
]]
function public:SetMeasurement(value, measurementunit)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, measurementunit, "number", "nil")

    set_measurement(self, "Measurement", measurementunit, value)
end

--[[
% SetMeasurementInteger

**[Fluid]**

Sets a measurement in whole EVPUs which will be displayed in either the specified measurement unit or the parent window's current measurement unit.
If using the parent window's measurement unit, it will be automatically updated if the parent window's measurement unit changes.

@ self (FCMCtrlStatic)
@ value (number) Value in whole EVPUs
@ [measurementunit] (number | nil) Forces the value to be displayed in this measurement unit. Can only be omitted if parent window is `FCMCustomLuaWindow`.
]]
function public:SetMeasurementInteger(value, measurementunit)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, measurementunit, "number", "nil")

    set_measurement(self, "MeasurementInteger", measurementunit, value)
end

--[[
% SetMeasurementEfix

**[Fluid]**

Sets a measurement in EFIXes which will be displayed in either the specified measurement unit or the parent window's current measurement unit.
If using the parent window's measurement unit, it will be automatically updated if the parent window's measurement unit changes.

@ self (FCMCtrlStatic)
@ value (number) Value in EFIXes
@ [measurementunit] (number | nil) Forces the value to be displayed in this measurement unit. Can only be omitted if parent window is `FCMCustomLuaWindow`.
]]
function public:SetMeasurementEfix(value, measurementunit)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, measurementunit, "number", "nil")

    set_measurement(self, "MeasurementEfix", measurementunit, value)
end

--[[
% SetMeasurement10000th

**[Fluid]**

Sets a measurement in 10000ths of an EVPU which will be displayed in either the specified measurement unit or the parent window's current measurement unit.
If using the parent window's measurement unit, it will be automatically updated if the parent window's measurement unit changes.

@ self (FCMCtrlStatic)
@ value (number) Value in 10000ths of an EVPU
@ [measurementunit] (number | nil) Forces the value to be displayed in this measurement unit. Can only be omitted if parent window is `FCMCustomLuaWindow`.
]]
function public:SetMeasurementEfix(value, measurementunit)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, measurementunit, "number", "nil")

    set_measurement(self, "Measurement10000th", measurementunit, value)
end

--[[
% SetShowMeasurementSuffix

**[Fluid]**

Sets whether to show a suffix at the end of a measurement (eg `cm` in `2.54cm`). This is enabled by default.

@ self (FCMCtrlStatic)
@ enabled (boolean)
]]
function public:SetShowMeasurementSuffix(enabled)
    mixin_helper.assert_argument_type(2, enabled, "boolean")

    private[self].ShowMeasurementSuffix = enabled and true or false
    mixin.FCMCtrlStatic.UpdateMeasurementUnit(self)
end

--[[
% SetMeasurementSuffixShort

**[Fluid]**

Sets the measurement suffix to the shortest form used by Finale's measurement overrides (eg `e`, `i`, `c`, etc)

@ self (FCMCtrlStatic)
]]
function public:SetMeasurementSuffixShort()
    private[self].MeasurementSuffixType = 1
    mixin.FCMCtrlStatic.UpdateMeasurementUnit(self)
end

--[[
% SetMeasurementSuffixAbbreviated

**[Fluid]**

Sets the measurement suffix to commonly known abbrevations (eg `in`, `cm`, `pt`, etc).

*This is the default style.*

@ self (FCMCtrlStatic)
]]
function public:SetMeasurementSuffixAbbreviated()
    private[self].MeasurementSuffixType = 2
    mixin.FCMCtrlStatic.UpdateMeasurementUnit(self)
end

--[[
% SetMeasurementSuffixFull

**[Fluid]**

Sets the measurement suffix to the full unit name. (eg `inches`, `centimeters`, etc).

@ self (FCMCtrlStatic)
]]
function public:SetMeasurementSuffixFull()
    private[self].MeasurementSuffixType = 3
    mixin.FCMCtrlStatic.UpdateMeasurementUnit(self)
end

--[[
% UpdateMeasurementUnit

**[Fluid] [Internal]**

Updates the displayed measurement unit in line with the parent window.

@ self (FCMCtrlStatic)
]]
function public:UpdateMeasurementUnit()
    if private[self].Measurement then
        mixin.FCMCtrlStatic["Set" .. private[self].MeasurementType](self, private[self].Measurement)
    end
end

return {meta, public}

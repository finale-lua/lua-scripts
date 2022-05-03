--  Author: Edward Koltun
--  Date: April 15, 2022
--[[
$module FCXCtrlStatic

*Extends `FCMCtrlStatic`*

Summary of changes:
- Parent window must be `FCXCustomLuaWindow`
- Added methods for setting and displaying measurements
]] --
local mixin = require("library.mixin")
local measurement = require("library.measurement")
local utils = require("library.utils")

local private = setmetatable({}, {__mode = "k"})
local props = {MixinParent = "FCMCtrlStatic"}

local temp_str = finale.FCString()

local function get_suffix(unit, suffix_type)
    if suffix_type == 1 then
        return measurement.get_unit_suffix(unit)
    elseif suffix_type == 2 then
        return measurement.get_unit_abbreviation(unit)
    elseif suffix_type == 3 then
        return " " .. string.lower(measurement.get_unit_name(unit))
    end
end

--[[
% Init

**[Internal]**

@ self (FCXCtrlStatic)
]]
function props:Init()
    mixin.assert(
        mixin.is_instance_of(self:GetParent(), "FCXCustomLuaWindow"),
        "FCXCtrlStatic must have a parent window that is an instance of FCXCustomLuaWindow")

    private[self] = private[self] or {ShowMeasurementSuffix = true, MeasurementSuffixType = 2}
end

--[[
% SetText

**[Fluid] [Override]**
Switches the control's measurement status off.

@ self (FCXCtrlStatic)
@ str (FCString|string|number)
]]
function props:SetText(str)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    mixin.FCMControl.SetText(self, str)

    private[self].Measurement = nil
    private[self].MeasurementType = nil
end

--[[
% SetMeasurement

**[Fluid]**
Sets a measurement in EVPUs which will be displayed in the parent window's current measurement unit. This will be automatically updated if the parent window's measurement unit changes.

@ self (FCXCtrlStatic)
@ value (number) Value in EVPUs
]]
function props:SetMeasurement(value)
    mixin.assert_argument(value, "number", 2)

    local unit = self:GetParent():GetMeasurementUnit()
    temp_str:SetMeasurement(value, unit)
    temp_str:AppendLuaString(
        private[self].ShowMeasurementSuffix and get_suffix(unit, private[self].MeasurementSuffixType) or "")

    self:SetText_(temp_str)

    private[self].Measurement = value
    private[self].MeasurementType = "Measurement"
end

--[[
% SetMeasurementInteger

**[Fluid]**
Sets a measurement in whole EVPUs which will be displayed in the parent window's current measurement unit. This will be automatically updated if the parent window's measurement unit changes.

@ self (FCXCtrlStatic)
@ value (number) Value in whole EVPUs (fractional part will be rounded to nearest integer)
]]
function props:SetMeasurementInteger(value)
    mixin.assert_argument(value, "number", 2)

    value = utils.round(value)
    local unit = self:GetParent():GetMeasurementUnit()
    temp_str:SetMeasurement(value, unit)
    temp_str:AppendLuaString(
        private[self].ShowMeasurementSuffix and get_suffix(unit, private[self].MeasurementSuffixType) or "")

    self:SetText_(temp_str)

    private[self].Measurement = value
    private[self].MeasurementType = "MeasurementInteger"
end

--[[
% SetMeasurementEfix

**[Fluid]**
Sets a measurement in EFIXes which will be displayed in the parent window's current measurement unit. This will be automatically updated if the parent window's measurement unit changes.

@ self (FCXCtrlStatic)
@ value (number) Value in EFIXes
]]
function props:SetMeasurementEfix(value)
    mixin.assert_argument(value, "number", 2)

    local evpu = value / 64
    local unit = self:GetParent():GetMeasurementUnit()
    temp_str:SetMeasurement(evpu, unit)
    temp_str:AppendLuaString(
        private[self].ShowMeasurementSuffix and get_suffix(unit, private[self].MeasurementSuffixType) or "")

    self:SetText_(temp_str)

    private[self].Measurement = value
    private[self].MeasurementType = "MeasurementEfix"
end

--[[
% SetShowMeasurementSuffix

**[Fluid]**
Sets whether to show a suffix at the end of a measurement (eg `cm` in `2.54cm`). This is on by default.

@ self (FCXCtrlStatic)
@ on (boolean)
]]
function props:SetShowMeasurementSuffix(on)
    mixin.assert_argument(on, "boolean", 2)

    private[self].ShowMeasurementSuffix = on
    self:UpdateMeasurementUnit()
end

--[[
% SetMeasurementSuffixShort

**[Fluid]**
Sets the measurement suffix to the short style used by Finale's internals (eg `e`, `i`, `c`, etc)

@ self (FCXCtrlStatic)
]]
function props:SetMeasurementSuffixShort()
    private[self].MeasurementSuffixType = 1
    self:UpdateMeasurementUnit()
end

--[[
% SetMeasurementSuffixAbbreviated

**[Fluid]**
Sets the measurement suffix to commonly known abbrevations (eg `in`, `cm`, `pt`, etc).
This is the default style.

@ self (FCXCtrlStatic)
]]
function props:SetMeasurementSuffixAbbreviated()
    private[self].MeasurementSuffixType = 2
    self:UpdateMeasurementUnit()
end

--[[
% SetMeasurementSuffixFull

**[Fluid]**
Sets the measurement suffix to the full unit name. (eg `inches`, `centimeters`, etc).

@ self (FCXCtrlStatic)
]]
function props:SetMeasurementSuffixFull()
    private[self].MeasurementSuffixType = 3
    self:UpdateMeasurementUnit()
end

--[[
% UpdateMeasurementUnit

**[Fluid] [Internal]**
Updates the displayed measurement unit in line with the parent window.

@ self (FCXCtrlStatic)
]]
function props:UpdateMeasurementUnit()
    if private[self].Measurement then
        self["Set" .. private[self].MeasurementType](self, private[self].Measurement)
    end
end

return props

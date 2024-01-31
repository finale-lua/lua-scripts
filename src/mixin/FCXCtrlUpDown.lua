--  Author: Edward Koltun
--  Date: April 10, 2022
--[[
$module FCXCtrlUpDown

*Extends `FCMCtrlUpDown`*

An up down control that is created by `FCXCustomLuaWindow`.

## Summary of Modifications
- The ability to set the step size on a per-measurement unit basis.
- Step size for integers can also be changed.
- Added a setting for forcing alignment to the next step when moving up or down.
- Connected edit must be an instance of `FCXCtrlEdit`
- Measurement edits can be connected in two additional ways which affect the underlying methods used in `GetValue` and `SetValue`
- Measurement EFIX edits have a different set of default step sizes.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local class = {Parent = "FCMCtrlUpDown", Methods = {}}
local methods = class.Methods
local private = setmetatable({}, {__mode = "k"})

local temp_str = finale.FCString()

-- Enumerates the edit type
local function enum_edit_type(edit, edit_type)
    if edit_type == "Integer" then
        return 1
    else
        if edit:IsTypeMeasurement() then
            return 2
        elseif edit:IsTypeMeasurementInteger() then
            return 3
        elseif edit:IsTypeMeasurementEfix() then
            return 4
        end
    end
end

local default_measurement_steps = {
    [finale.MEASUREMENTUNIT_EVPUS] = {value = 1, is_evpus = true},
    [finale.MEASUREMENTUNIT_INCHES] = {value = 0.03125, is_evpus = false},
    [finale.MEASUREMENTUNIT_CENTIMETERS] = {value = 0.01, is_evpus = false},
    [finale.MEASUREMENTUNIT_POINTS] = {value = 0.25, is_evpus = false},
    [finale.MEASUREMENTUNIT_PICAS] = {value = 1, is_evpus = true},
    [finale.MEASUREMENTUNIT_SPACES] = {value = 0.125, is_evpus = false},
}

local default_efix_steps = {
    [finale.MEASUREMENTUNIT_EVPUS] = {value = 0.015625, is_evpus = true},
    [finale.MEASUREMENTUNIT_INCHES] = {value = 0.03125, is_evpus = false},
    [finale.MEASUREMENTUNIT_CENTIMETERS] = {value = 0.001, is_evpus = false},
    [finale.MEASUREMENTUNIT_POINTS] = {value = 0.03125, is_evpus = false},
    [finale.MEASUREMENTUNIT_PICAS] = {value = 0.015625, is_evpus = true},
    [finale.MEASUREMENTUNIT_SPACES] = {value = 0.03125, is_evpus = false},
}

--[[
% Init

**[Internal]**

@ self (FCXCtrlUpDown)
]]
function class:Init()
    if private[self] then
        return
    end

    mixin_helper.assert(function() return mixin_helper.is_instance_of(self:GetParent(), "FCXCustomLuaWindow") end, "FCXCtrlUpDown must have a parent window that is an instance of FCXCustomLuaWindow")

    private[self] = {
        IntegerStepSize = 1,
        MeasurementSteps = {},
        AlignWhenMoving = true,
    }

    self:AddHandlePress(function(self, delta)   -- luacheck: ignore self
        if not private[self].ConnectedEdit then
            return
        end

        local edit = private[self].ConnectedEdit
        local edit_type = enum_edit_type(edit, private[self].ConnectedEditType)
        local unit = self:GetParent():GetMeasurementUnit()
        local separator = mixin.UI():GetDecimalSeparator()
        local step_def

        if edit_type == 1 then
            step_def = {value = private[self].IntegerStepSize}
        else
            step_def = private[self].MeasurementSteps[unit] or (edit_type == 4 and default_efix_steps[unit]) or default_measurement_steps[unit]
        end

        -- Get real value
        local value
        if edit_type == 1 then
            value = edit:GetText():match("^%-*[0-9%.%,%" .. separator .. "-]+")
            value = value and tonumber(value) or 0
        else
            if step_def.is_evpus then
                value = edit:GetMeasurement()
            else
                -- Strings like '2.75i' allow the unit to be overridden, so doing this extra step guarantees that it's normalised to the current unit
                temp_str:SetMeasurement(edit:GetMeasurement(), unit)
                value = temp_str.LuaString:gsub("%" .. separator, ".")
                value = tonumber(value)
            end
        end

        -- Align to closest step if needed
        if private[self].AlignWhenMoving then
            -- Casting back and forth works around floating point issues, such as 0.3/0.1 not being equal to 3 (even though 3 is displayed)
            local num_steps = tonumber(tostring(value / step_def.value)) or 0

            if num_steps ~= math.floor(num_steps) then
                if delta > 0 then
                    value = math.ceil(num_steps) * step_def.value
                    delta = delta - 1
                elseif delta < 0 then
                    value = math.floor(num_steps) * step_def.value
                    delta = delta + 1
                end
            end
        end

        -- Calculate new value
        local new_value = value + delta * step_def.value

        -- Set new value
        if edit_type == 1 then
            self:SetValue(new_value)
        else
            if step_def.is_evpus then
                self:SetValue(edit_type == 4 and new_value * 64 or new_value)
            else
                -- If we're not in EVPUs, we need the EVPU value to determine whether clamping is required
                temp_str.LuaString = tostring(new_value)
                local new_evpus = temp_str:GetMeasurement(unit)
                if new_evpus < private[self].Minimum or new_evpus > private[self].Maximum then
                    self:SetValue(edit_type == 4 and new_evpus * 64 or new_evpus)
                else
                    edit:SetText(temp_str.LuaString:gsub("%.", separator))
                end
            end
        end

    end)
end

--[[
% GetConnectedEdit

**[Override]**

Override Changes:
- Ensures that original edit control is returned.

@ self (FCXCtrlUpDown)
: (FCMCtrlEdit | nil) `nil` if there is no edit connected.
]]
function methods:GetConnectedEdit()
    return private[self].ConnectedEdit
end

--[[
% ConnectIntegerEdit

**[Fluid] [Override]**

Connects an integer edit.
The underlying methods used in `GetValue` and `SetValue` will be `GetRangeInteger` and `SetInteger` respectively.

@ self (FCXCtrlUpDown)
@ control (FCMCtrlEdit)
@ minimum (number)
@ maximum (maximum)
]]
function methods:ConnectIntegerEdit(control, minimum, maximum)
    mixin_helper.assert_argument_type(2, control, "FCMCtrlEdit")
    mixin_helper.assert_argument_type(3, minimum, "number")
    mixin_helper.assert_argument_type(4, maximum, "number")
    mixin_helper.assert(function() return not mixin_helper.is_instance_of(control, "FCXCtrlMeasurementEdit") end, "A measurement edit cannot be connected as an integer edit.")

    private[self].ConnectedEdit = control
    private[self].ConnectedEditType = "Integer"
    private[self].Minimum = minimum
    private[self].Maximum = maximum
end

--[[
% ConnectMeasurementEdit

**[Fluid] [Override]**
Connects a measurement edit. The control will be automatically registered as a measurement edit if it isn't already.
The underlying methods used in `GetValue` and `SetValue` will depend on the measurement edit's type.

@ self (FCXCtrlUpDown)
@ control (FCXCtrlMeasurementEdit)
@ minimum (number)
@ maximum (maximum)
]]
function methods:ConnectMeasurementEdit(control, minimum, maximum)
    mixin_helper.assert_argument_type(2, control, "FCXCtrlMeasurementEdit")
    mixin_helper.assert_argument_type(3, minimum, "number")
    mixin_helper.assert_argument_type(4, maximum, "number")

    private[self].ConnectedEdit = control
    private[self].ConnectedEditType = "Measurement"
    private[self].Minimum = minimum
    private[self].Maximum = maximum
end

--[[
% SetIntegerStepSize

**[Fluid]**

Sets the step size for integer edits.

@ self (FCXCtrlUpDown)
@ value (number)
]]
function methods:SetIntegerStepSize(value)
    mixin_helper.assert_argument_type(2, value, "number")

    private[self].IntegerStepSize = value
end

--[[
% SetEVPUsStepSize

**[Fluid]**

Sets the step size for measurement edits that are currently displaying in EVPUs.

@ self (FCXCtrlUpDown)
@ value (number)
]]
function methods:SetEVPUsStepSize(value)
    mixin_helper.assert_argument_type(2, value, "number")

    private[self].MeasurementSteps[finale.MEASUREMENTUNIT_EVPUS] = {value = value, is_evpus = true}
end

--[[
% SetInchesStepSize

**[Fluid]**

Sets the step size for measurement edits that are currently displaying in Inches.

@ self (FCXCtrlUpDown)
@ value (number)
@ [is_evpus] (boolean) If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Inches.
]]
function methods:SetInchesStepSize(value, is_evpus)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")

    private[self].MeasurementSteps[finale.MEASUREMENTUNIT_INCHES] = {
        value = value,
        is_evpus = is_evpus and true or false,
    }
end

--[[
% SetCentimetersStepSize

**[Fluid]**

Sets the step size for measurement edits that are currently displaying in Centimeters.

@ self (FCXCtrlUpDown)
@ value (number)
@ [is_evpus] (boolean) If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Centimeters.
]]
function methods:SetCentimetersStepSize(value, is_evpus)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")

    private[self].MeasurementSteps[finale.MEASUREMENTUNIT_CENTIMETERS] = {
        value = value,
        is_evpus = is_evpus and true or false,
    }
end

--[[
% SetPointsStepSize

**[Fluid]**

Sets the step size for measurement edits that are currently displaying in Points.

@ self (FCXCtrlUpDown)
@ value (number)
@ [is_evpus] (boolean) If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Points.
]]
function methods:SetPointsStepSize(value, is_evpus)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")

    private[self].MeasurementSteps[finale.MEASUREMENTUNIT_POINTS] = {
        value = value,
        is_evpus = is_evpus and true or false,
    }
end

--[[
% SetPicasStepSize

**[Fluid]**

Sets the step size for measurement edits that are currently displaying in Picas.

@ self (FCXCtrlUpDown)
@ value (number|string)
@ [is_evpus] (boolean) If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Picas.
]]
function methods:SetPicasStepSize(value, is_evpus)
    mixin_helper.assert_argument_type(2, value, "number", "string")

    if not is_evpus then
        temp_str:SetText(tostring(value))
        value = temp_str:GetMeasurement(finale.MEASUREMENTUNIT_PICAS)
    end

    private[self].MeasurementSteps[finale.MEASUREMENTUNIT_PICAS] = {value = value, is_evpus = true}
end

--[[
% SetSpacesStepSize

**[Fluid]**

Sets the step size for measurement edits that are currently displaying in Spaces.

@ self (FCXCtrlUpDown)
@ value (number)
@ [is_evpus] (boolean) If `true`, the value will be treated as an EVPU value. If `false` or omitted, the value will be treated in Spaces.
]]
function methods:SetSpacesStepSize(value, is_evpus)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")

    private[self].MeasurementSteps[finale.MEASUREMENTUNIT_SPACES] = {
        value = value,
        is_evpus = is_evpus and true or false,
    }
end

--[[
% AlignWSetAlignWhenMovinghenMoving

**[Fluid]**

Sets whether to align to the next multiple of a step when moving.

@ self (FCXCtrlUpDown)
@ on (boolean)
]]
function methods:SetAlignWhenMoving(on)
    mixin_helper.assert_argument_type(2, on, "boolean")

    private[self].AlignWhenMoving = on
end

--[[
% GetValue

**[Override]**

Returns the value of the connected edit, clamped according to the set minimum and maximum.

Different types of connected edits will return different types and use different methods to access the value of the edit. The methods are:
- Integer edit => `GetRangeInteger`
- Measurement edit ("Measurement") => `GetRangeMeasurement`
- Measurement edit ("MeasurementInteger") => `GetRangeMeasurementInteger`
- Measurement edit ("MeasurementEfix") => `GetRangeMeasurementEfix`

@ self (FCXCtrlUpDown)
: (number) An integer for an integer edit, EVPUs for a measurement edit, whole EVPUs for a measurement integer edit, or EFIXes for a measurement EFIX edit.
]]
function methods:GetValue()
    if not private[self].ConnectedEdit then
        return
    end

    local edit = private[self].ConnectedEdit

    if private[self].ConnectedEditType == "Measurement" then
        return edit["Get" .. edit:GetType()](edit, private[self].Minimum, private[self].Maximum)
    else
        return edit:GetRangeInteger(private[self].Minimum, private[self].Maximum)
    end
end

--[[
% SetValue

**[Fluid] [Override]**

Sets the value of the attached control, clamped according to the set minimum and maximum.

Different types of connected edits will accept different types and use different methods to set the value of the edit. The methods are:
- Integer edit => `SetRangeInteger`
- Measurement edit ("Measurement") => `SetRangeMeasurement`
- Measurement edit ("MeasurementInteger") => `SetRangeMeasurementInteger`
- Measurement edit ("MeasurementEfix") => `SetRangeMeasurementEfix`

@ self (FCXCtrlUpDown)
@ value (number) An integer for an integer edit, EVPUs for a measurement edit, whole EVPUs for a measurement integer edit, or EFIXes for a measurement EFIX edit.
]]
function methods:SetValue(value)
    mixin_helper.assert_argument_type(2, value, "number")
    mixin_helper.assert(private[self].ConnectedEdit, "Unable to set value: no connected edit.")

    -- Clamp the value
    value = value < private[self].Minimum and private[self].Minimum or value
    value = value > private[self].Maximum and private[self].Maximum or value

    local edit = private[self].ConnectedEdit

    if private[self].ConnectedEditType == "Measurement" then
        edit["Set" .. edit:GetType()](edit, value)
    else
        edit:SetInteger(value)
    end
end

--[[
% GetMinimum

**[Override]**

@ self (FCMCtrlUpDown)
: (number) An integer for integer edits or EVPUs for measurement edits.
]]
function methods:GetMinimum()
    return private[self].Minimum
end

--[[
% GetMaximum

**[Override]**

@ self (FCMCtrlUpDown)
: (number) An integer for integer edits or EVPUs for measurement edits.
]]

function methods:GetMaximum()
    return private[self].Maximum
end

--[[
% SetRange

**[Fluid] [Override]**

@ self (FCMCtrlUpDown)
@ minimum (number) An integer for integer edits or EVPUs for measurement edits.
@ maximum (number) An integer for integer edits or EVPUs for measurement edits.
]]
function methods:SetRange(minimum, maximum)
    mixin_helper.assert_argument_type(2, minimum, "number")
    mixin_helper.assert_argument_type(3, maximum, "number")

    private[self].Minimum = minimum
    private[self].Maximum = maximum
end

return class

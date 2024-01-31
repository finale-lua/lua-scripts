--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMControl

## Summary of Modifications
- Setters that accept `FCString` also accept a Lua `string` or `number`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
- Ported `GetParent` from PDK to allow the parent window to be accessed from a control.
- Added methods to allow handlers for the `Command` event to be set directly on the control.
- Added methods for storing and restoring control state, allowing controls to preserve their values across multiple script executions.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local class = {Methods = {}}
local methods = class.Methods
local private = setmetatable({}, {__mode = "k"})
-- So as not to prevent the window (and by extension the controls) from being garbage collected in the normal way, use weak keys and values for storing the parent window
local parent = setmetatable({}, {__mode = "kv"})

local temp_str = finale.FCString()

--[[
% Init

**[Internal]**

@ self (FCMControl)
]]
function class:Init()
    if private[self] then
        return
    end

    private[self] = {}
end

--[[
% GetParent

**[PDK Port]**

Returns the control's parent window.

*Do not override or disable this method.*

@ self (FCMControl)
: (FCMCustomWindow)
]]
function methods:GetParent()
    return parent[self]
end

--[[
% RegisterParent

**[Fluid] [Internal]**

Used to register the parent window when the control is created.

*Do not disable this method.*

@ self (FCMControl)
@ window (FCMCustomWindow)
]]
function methods:RegisterParent(window)
    mixin_helper.assert_argument_type(2, window, "FCMCustomWindow", "FCMCustomLuaWindow")

    if parent[self] then
        error("This method is for internal use only.", 2)
    end

    parent[self] = window
end

--[[
% GetEnable

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
: (boolean)
]]

--[[
% SetEnable

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
@ enable (boolean)
]]

--[[
% GetVisible

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
: (boolean)
]]

--[[
% SetVisible

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
@ visible (boolean)
]]

--[[
% GetLeft

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
: (number)
]]

--[[
% SetLeft

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
@ left (number)
]]

--[[
% GetTop

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
: (number)
]]

--[[
% SetTop

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
@ top (number)
]]

--[[
% GetHeight

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
: (number)
]]

--[[
% SetHeight

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
@ height (number)
]]

--[[
% GetWidth

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
: (number)
]]

--[[
% SetWidth

**[Fluid] [Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMControl)
@ width (number)
]]
for method, valid_types in pairs({
    Enable = {"boolean", "nil"},
    Visible = {"boolean", "nil"},
    Left = {"number"},
    Top = {"number"},
    Height = {"number"},
    Width = {"number"},
}) do
    methods["Get" .. method] = function(self)
        if mixin.FCMControl.UseStoredState(self) then
            return private[self][method]
        end

        return self["Get" .. method .. "__"](self)
    end

    methods["Set" .. method] = function(self, value)
        mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))

        if mixin.FCMControl.UseStoredState(self) then
            private[self][method] = value
        else
            -- Fix bug with text box content being cleared on Mac when Enabled or Visible state is changed
            if (method == "Enable" or method == "Visible") and finenv.UI():IsOnMac() and finenv.MajorVersion == 0 and finenv.MinorVersion < 63 then
                self:GetText__(temp_str)
                self:SetText__(temp_str)
            end

            self["Set" .. method .. "__"](self, value)
        end
    end
end


--[[
% GetText

**[?Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.
- Hooks into control state preservation.

@ self (FCMControl)
@ [str] (FCString)
: (string) Returned if `str` is omitted.
]]
function methods:GetText(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    local do_return = false

    if not str then
        str = temp_str
        do_return = true
    end

    if mixin.FCMControl.UseStoredState(self) then
        str.LuaString = private[self].Text
    else
        self:GetText__(str)
    end

    if do_return then
        return str.LuaString
    end
end

--[[
% SetText

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.
- Hooks into control state preservation.

@ self (FCMControl)
@ str (FCString | string | number)
]]
function methods:SetText(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    str = mixin_helper.to_fcstring(str, temp_str)

    if mixin.FCMControl.UseStoredState(self) then
        private[self].Text = str.LuaString
    else
        self:SetText__(str)
    end
end

--[[
% UseStoredState

**[Internal]**

Checks if this control should use its stored state instead of the live state from the control.

*Do not override or disable this method.*

@ self (FCMControl)
: (boolean)
]]
function methods:UseStoredState()
    local parent = self:GetParent()   -- luacheck: ignore parent
    return mixin_helper.is_instance_of(parent, "FCMCustomLuaWindow") and parent:GetRestoreControlState() and not parent:WindowExists() and parent:HasBeenShown()
end

--[[
% StoreState

**[Fluid] [Internal]**

Stores the control's current state.

*Do not disable this method. Override as needed but call the parent first.*

@ self (FCMControl)
]]
function methods:StoreState()
    self:GetText__(temp_str)
    private[self].Text = temp_str.LuaString
    private[self].Enable = self:GetEnable__()
    private[self].Visible = self:GetVisible__()
    private[self].Height = self:GetHeight__()
    private[self].Width = self:GetWidth__()
    private[self].Left = self:GetLeft__()
    private[self].Top = self:GetTop__()
end

--[[
% RestoreState

**[Fluid] [Internal]**

Restores the control's stored state.

*Do not disable this method. Override as needed but call the parent first.*

@ self (FCMControl)
]]
function methods:RestoreState()
    self:SetEnable__(private[self].Enable)
    self:SetVisible__(private[self].Visible)
    self:SetHeight__(private[self].Height)
    self:SetWidth__(private[self].Width)
    self:SetLeft__(private[self].Left)
    self:SetTop__(private[self].Top) -- keep SetTop after SetHeight to work around height bug in macOS buttons

    -- Call SetText last to work around the Mac text box issue described above
    temp_str.LuaString = private[self].Text
    self:SetText__(temp_str)
end

--[[
% AddHandleCommand

**[Fluid]**

Adds a handler for command events.

@ self (FCMControl)
@ callback (function) See `FCCustomLuaWindow.HandleCommand` in the PDK for callback signature.
]]

--[[
% RemoveHandleCommand

**[Fluid]**

Removes a handler added with `AddHandleCommand`.

@ self (FCMControl)
@ callback (function)
]]
methods.AddHandleCommand, methods.RemoveHandleCommand = mixin_helper.create_standard_control_event("HandleCommand")

return class

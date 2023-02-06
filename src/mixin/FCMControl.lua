--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMControl

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
- Ported `GetParent` from PDK to allow the parent window to be accessed from a control.
- Handlers for the `Command` event can now be set on a control.
- Added methods for storing and restoring control state, which allows controls to correctly maintain their values across multiple script executions
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

-- So as not to prevent the window (and by extension the controls) from being garbage collected in the normal way, use weak keys and values for storing the parent window
local parent = setmetatable({}, {__mode = "kv"})
local private = setmetatable({}, {__mode = "k"})
local props = {}

local temp_str = finale.FCString()

--[[
% Init

**[Internal]**

@ self (FCMControl)
]]
function props:Init()
    private[self] = private[self] or {}
end

--[[
% GetParent

**[PDK Port]**
Returns the control's parent window.
Do not override or disable this method.

@ self (FCMControl)
: (FCMCustomWindow)
]]
function props:GetParent()
    return parent[self]
end

--[[
% RegisterParent

**[Fluid] [Internal]**
Used to register the parent window when the control is created.
Do not disable this method.

@ self (FCMControl)
@ window (FCMCustomWindow)
]]
function props:RegisterParent(window)
    mixin_helper.assert_argument_type(2, window, "FCMCustomWindow", "FCMCustomLuaWindow")

    if parent[self] then
        error("This method is for internal use only.", 2)
    end

    parent[self] = window
end

--[[
% GetEnable

**[Override]**
Hooks into control state restoration.

@ self (FCMControl)
: (boolean)
]]

--[[
% SetEnable

**[Fluid] [Override]**
Hooks into control state restoration.

@ self (FCMControl)
@ enable (boolean)
]]

--[[
% GetVisible

**[Override]**
Hooks into control state restoration.

@ self (FCMControl)
: (boolean)
]]

--[[
% SetVisible

**[Fluid] [Override]**
Hooks into control state restoration.

@ self (FCMControl)
@ visible (boolean)
]]

--[[
% GetLeft

**[Override]**
Hooks into control state restoration.

@ self (FCMControl)
: (number)
]]

--[[
% SetLeft

**[Fluid] [Override]**
Hooks into control state restoration.

@ self (FCMControl)
@ left (number)
]]

--[[
% GetTop

**[Override]**
Hooks into control state restoration.

@ self (FCMControl)
: (number)
]]

--[[
% SetTop

**[Fluid] [Override]**
Hooks into control state restoration.

@ self (FCMControl)
@ top (number)
]]

--[[
% GetHeight

**[Override]**
Hooks into control state restoration.

@ self (FCMControl)
: (number)
]]

--[[
% SetHeight

**[Fluid] [Override]**
Hooks into control state restoration.

@ self (FCMControl)
@ height (number)
]]

--[[
% GetWidth

**[Override]**
Hooks into control state restoration.

@ self (FCMControl)
: (number)
]]

--[[
% SetWidth

**[Fluid] [Override]**
Hooks into control state restoration.

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
    props["Get" .. method] = function(self)
        if mixin.FCMControl.UseStoredState(self) then
            return private[self][method]
        end

        return self["Get" .. method .. "_"](self)
    end

    props["Set" .. method] = function(self, value)
        mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))

        if mixin.FCMControl.UseStoredState(self) then
            private[self][method] = value
        else
            -- Fix bug with text box content being cleared on Mac when Enabled or Visible state is changed
            if (method == "Enable" or method == "Visible") and finenv.UI():IsOnMac() and finenv.MajorVersion == 0 and finenv.MinorVersion < 63 then
                self:GetText_(temp_str)
                self:SetText_(temp_str)
            end

            self["Set" .. method .. "_"](self, value)
        end
    end
end


--[[
% GetText

**[Override]**
Returns a Lua `string` and makes passing an `FCString` optional.
Also hooks into control state restoration.

@ self (FCMControl)
@ [str] (FCString)
: (string)
]]
function props:GetText(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    if not str then
        str = temp_str
    end

    if mixin.FCMControl.UseStoredState(self) then
        str.LuaString = private[self].Text
    else
        self:GetText_(str)
    end

    return str.LuaString
end

--[[
% SetText

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.
Also hooks into control state restoration.

@ self (FCMControl)
@ str (FCString|string|number)
]]
function props:SetText(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    if mixin.FCMControl.UseStoredState(self) then
        private[self].Text = str.LuaString
    else
        self:SetText_(str)
    end
end

--[[
% UseStoredState

**[Internal]**
Checks if this control should use its stored state instead of the live state from the control.
Do not override or disable this method.

@ self (FCMControl)
: (boolean)
]]
function props:UseStoredState()
    local parent = self:GetParent()
    return mixin_helper.is_instance_of(parent, "FCMCustomLuaWindow") and parent:GetRestoreControlState() and not parent:WindowExists() and parent:HasBeenShown()
end

--[[
% StoreState

**[Fluid] [Internal]**
Stores the control's current state.
Do not disable this method. Override as needed but call the parent first.

@ self (FCMControl)
]]
function props:StoreState()
    self:GetText_(temp_str)
    private[self].Text = temp_str.LuaString
    private[self].Enable = self:GetEnable_()
    private[self].Visible = self:GetVisible_()
    private[self].Left = self:GetLeft_()
    private[self].Top = self:GetTop_()
    private[self].Height = self:GetHeight_()
    private[self].Width = self:GetWidth_()
end

--[[
% RestoreState

**[Fluid] [Internal]**
Restores the control's stored state.
Do not disable this method. Override as needed but call the parent first.

@ self (FCMControl)
]]
function props:RestoreState()
    self:SetEnable_(private[self].Enable)
    self:SetVisible_(private[self].Visible)
    self:SetLeft_(private[self].Left)
    self:SetTop_(private[self].Top)
    self:SetHeight_(private[self].Height)
    self:SetWidth_(private[self].Width)

    -- Call SetText last to work around the Mac text box issue described above
    temp_str.LuaString = private[self].Text
    self:SetText_(temp_str)
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
props.AddHandleCommand, props.RemoveHandleCommand = mixin_helper.create_standard_control_event("HandleCommand")

return props

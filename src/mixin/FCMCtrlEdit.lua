--[[
$module FCMCtrlEdit
]]

local mixin = require("library.mixin")
local utils = require("library.utils")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local handle_change_windows = {}

local function init_handle_change(window)
    if handle_change_windows[window] then
        return
    end

    window:AddHandleCommand(function(control)

        if not private[control] then
            return
        end

        local curr_value = finale.FCString()
        control:GetText_(curr_value)

        for _, v in ipairs(private[control].HandleChange) do
            local last_value = private[control].HandleChangeHistory[v]
            if last_value ~= curr_value.LuaString then
                v(control, curr_value.LuaString)

                control:GetText_(curr_value)
                private[control].HandleChangeHistory[v] = curr_value.LuaString
            end
        end
    end)

    handle_change_windows[window] = true
end


--[[
% Init

**[Internal]**

@ self (FCMCtrlEdit)
]]
function props:Init()
    private[self] = private[self] or {HandleChange = {}, HandleChangeHistory = {}}
end

--[[
% AddHandleChange

**[Fluid]**
Adds a handler for when the value of the control changes.
If the value of the control is changed by a handler, that same handler will not be called again for that change.

@ self (FCMCtrlEdit)
@ func (function) Handler with the signature `func((FCMCtrlEdit) control, (string) old_value)`
]]
function props:AddHandleChange(func)
    mixin.assert_argument(func, "function", 2)
    local parent = self:GetParent()
    mixin.assert(parent, "Cannot add handler to control with no parent window.")
    mixin.assert((parent.MixinBase or parent.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
    mixin.force_assert(private[self].HandleChangeHistory[func] == nil, "The callback has already been added as a change handler.")

    init_handle_change(parent)
    private[self].HandleChangeHistory[func] = self:GetText()
    table.insert(private[self].HandleChange, func)
end

--[[
% RemoveHandleChange

**[Fluid]**
Removes a handler added with `AddHandleChange`.

@ self (FCMCtrlEdit)
@ func (function)
]]
function props:RemoveHandleChange(func)
    mixin.assert_argument(func, "function", 2)

    utils.table_remove_first(private[self].HandleChange, func)
    private[self].HandleChangeHistory[func] = nil
end


return props
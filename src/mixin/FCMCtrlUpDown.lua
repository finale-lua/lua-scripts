--[[
$module FCMCtrlUpDown
]]

local mixin = require("library.mixin")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local handle_press_windows = {}

local function init_handle_press(window)
    if handle_press_windows[window] then
        return
    end

    window:AddHandleUpDownPressed(function(control, delta)
        if not private[control] then
            return
        end

        for _, v in ipairs(private[control].HandlePress) do
            v(control, delta)
        end
    end)

    handle_press_windows[window] = true
end


--[[
% Init

**[Internal]**

@ self (FCMCtrlUpDown)
]]
function props:Init()
    private[self] = private[self] or {HandlePress = {}}
end

--[[
% AddHandlePress

**[Fluid]**
Adds a handler for UpDownPressed events.

@ self (FCMCtrlUpDown)
@ func (function) Handler with the signature `func((FCMCtrlUpDowncontrol, (number) delta)`
]]
function props:AddHandlePress(func)
    mixin.assert_argument(func, "function", 2)
    local parent = self:GetParent()
    mixin.assert(parent, "Cannot add handler to control with no parent window.")
    mixin.assert((parent.MixinBase or parent.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")

    init_handle_press(parent)
    table.insert(private[self].HandlePress, func)
end

--[[
% RemoveHandlePress

**[Fluid]**
Removes a handler added with `AddHandlePress`.

@ self (FCMCtrlUpDown)
@ func (function)
]]
function props:RemoveHandlePress(func)
    mixin.assert_argument(func, "function", 2)

    utils.table_remove_first(private[self].HandlePress, func)
end


return props

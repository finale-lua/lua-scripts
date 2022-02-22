--[[
$module FCMCtrlDataList
]]

local mixin = require("library.mixin")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local temp_str = finale.FCString()
local handle_check_windows = {}
local handle_select_windows = {}

local function init_handle_check(window)
    if handle_check_windows[window] then
        return
    end

    window:AddHandleDataListCheck(function(control, lineindex, checkstate)
        if not private[control] then
            return
        end

        for _, v in ipairs(private[control].HandleCheck) do
            v(control, lineindex, checkstate)
        end
    end)

    handle_check_windows[window] = true
end

local function init_handle_select(window)
    if handle_select_windows[window] then
        return
    end

    window:AddHandleDataListSelect(function(control, lineindex)
        if not private[control] then
            return
        end

        for _, v in ipairs(private[control].HandleSelect) do
            v(control, lineindex)
        end
    end)

    handle_select_windows[window] = true
end


--[[
% Init

**[Internal]**

@ self (FCMCtrlDataList)
]]
function props:Init()
    private[self] = private[self] or {HandleCheck = {}, HandleSelect = {}}
end

--[[
% AddColumn

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMCtrlDataList)
@ title (FCString|string|number)
@ columnwidth (number)
]]
function props:AddColumn(title, columnwidth)
    mixin.assert_argument(title, {"string", "number", "FCString"}, 2)
    mixin.assert_argument(columnwidth, "number", 3)

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(title)
        title = temp_str
    end

    self:AddColumn_(title, columnwidth)
end

--[[
% SetColumnTitle

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMCtrlDataList)
@ columnindex (number)
@ title (FCString|string|number)
]]
function props:SetColumnTitle(columnindex, title)
    mixin.assert_argument(columnindex, "number", 2)
    mixin.assert_argument(title, {"string", "number", "FCString"}, 3)

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(title)
        title = temp_str
    end

    self:SetColumnTitle_(columnindex, title)
end

--[[
% AddHandleCheck

**[Fluid]**
Adds a handler for DataListCheck events.

@ self (FCMControl)
@ func (function) Handler with the signature `func((FCMCtrlDataList) control, (number) lineindex, (boolean) checkstate)`
]]
function props:AddHandleCheck(func)
    mixin.assert_argument(func, "function", 2)
    local parent = self:GetParent()
    mixin.assert(parent, "Cannot add handler to control with no parent window.")
    mixin.assert((parent.MixinBase or parent.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")

    init_handle_check(parent)
    table.insert(private[self].HandleCheck, func)
end

--[[
% RemoveHandleCheck

**[Fluid]**
Removes a handler added with `AddHandleCheck`.

@ self (FCMControl)
@ func (function)
]]
function props:RemoveHandleCheck(func)
    mixin.assert_argument(func, "function", 2)

    utils.table_remove_first(private[self].HandleCheck, func)
end

--[[
% AddHandleSelect

**[Fluid]**
Adds a handler for DataListSelect events.

@ self (FCMControl)
@ func (function) Handler with the signature `func((FCMCtrlDataList) control, (number) lineindex)`
]]
function props:AddHandleSelect(func)
    mixin.assert_argument(func, "function", 2)
    local parent = self:GetParent()
    mixin.assert(parent, "Cannot add handler to control with no parent window.")
    mixin.assert((parent.MixinBase or parent.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")

    init_handle_select(parent)
    table.insert(private[self].HandleSelect, func)
end

--[[
% RemoveHandleSelect

**[Fluid]**
Removes a handler added with `AddHandleSelect`.

@ self (FCMControl)
@ func (function)
]]
function props:RemoveHandleSelect(func)
    mixin.assert_argument(func, "function", 2)

    utils.table_remove_first(private[self].HandleSelect, func)
end


return props
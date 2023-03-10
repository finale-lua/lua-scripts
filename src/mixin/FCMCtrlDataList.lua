--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlDataList

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- Handlers for the `DataListCheck` and `DataListSelect` events can now be set on a control.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local props = {}

local temp_str = finale.FCString()

--[[
% AddColumn

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMCtrlDataList)
@ title (FCString|string|number)
@ columnwidth (number)
]]
function props:AddColumn(title, columnwidth)
    mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
    mixin_helper.assert_argument_type(3, columnwidth, "number")

    if type(title) ~= "userdata" then
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
    mixin_helper.assert_argument_type(2, columnindex, "number")
    mixin_helper.assert_argument_type(3, title, "string", "number", "FCString")

    if type(title) ~= "userdata" then
        temp_str.LuaString = tostring(title)
        title = temp_str
    end

    self:SetColumnTitle_(columnindex, title)
end

--[[
% AddHandleCheck

**[Fluid]**
Adds a handler for DataListCheck events.

@ self (FCMCtrlDataList)
@ callback (function) See `FCCustomLuaWindow.HandleDataListCheck` in the PDK for callback signature.
]]

--[[
% RemoveHandleCheck

**[Fluid]**
Removes a handler added with `AddHandleCheck`.

@ self (FCMCtrlDataList)
@ callback (function)
]]
props.AddHandleCheck, props.RemoveHandleCheck = mixin_helper.create_standard_control_event("HandleDataListCheck")

--[[
% AddHandleSelect

**[Fluid]**
Adds a handler for DataListSelect events.

@ self (FCMControl)
@ callback (function) See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature.
]]

--[[
% RemoveHandleSelect

**[Fluid]**
Removes a handler added with `AddHandleSelect`.

@ self (FCMControl)
@ callback (function)
]]
props.AddHandleSelect, props.RemoveHandleSelect = mixin_helper.create_standard_control_event("HandleDataListSelect")

return props

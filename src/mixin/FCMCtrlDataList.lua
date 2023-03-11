--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlDataList

## Summary of Modifications
- Setters that accept `FCString` will also accept a Lua `string` or `number`.
- Added methods to allow handlers for the `DataListCheck` and `DataListSelect` events be set directly on the control.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local meta = {}
local public = {}

local temp_str = finale.FCString()

--[[
% AddColumn

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

@ self (FCMCtrlDataList)
@ title (FCString | string | number)
@ columnwidth (number)
]]
function public:AddColumn(title, columnwidth)
    mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
    mixin_helper.assert_argument_type(3, columnwidth, "number")

    self:AddColumn_(mixin_helper.to_fcstring(title, temp_str), columnwidth)
end

--[[
% SetColumnTitle

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

@ self (FCMCtrlDataList)
@ columnindex (number)
@ title (FCString | string | number)
]]
function public:SetColumnTitle(columnindex, title)
    mixin_helper.assert_argument_type(2, columnindex, "number")
    mixin_helper.assert_argument_type(3, title, "string", "number", "FCString")

    self:SetColumnTitle_(columnindex, mixin_helper.to_fcstring(title, temp_str))
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
public.AddHandleCheck, public.RemoveHandleCheck = mixin_helper.create_standard_control_event("HandleDataListCheck")

--[[
% AddHandleSelect

**[Fluid]**

Adds a handler for `DataListSelect` events.

@ self (FCMCtrlDataList)
@ callback (function) See `FCCustomLuaWindow.HandleDataListSelect` in the PDK for callback signature.
]]

--[[
% RemoveHandleSelect

**[Fluid]**

Removes a handler added with `AddHandleSelect`.

@ self (FCMCtrlDataList)
@ callback (function)
]]
public.AddHandleSelect, public.RemoveHandleSelect = mixin_helper.create_standard_control_event("HandleDataListSelect")

return {meta, public}

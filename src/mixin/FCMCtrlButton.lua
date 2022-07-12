--  Author: Edward Koltun
--  Date: April 3, 2022
--[[
$module FCMCtrlButton

The following methods have been disabled from `FCMCtrlCheckbox`:
- `AddHandleCheckChange`
- `RemoveHandleCheckChange`

To handle button presses, use `AddHandleCommand` inherited from `FCMControl`.
]] --
local mixin_helper = require("library.mixin_helper")

local props = {}

mixin_helper.disable_methods(props, "AddHandleCheckChange", "RemoveHandleCheckChange")

return props

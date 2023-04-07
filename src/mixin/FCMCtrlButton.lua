--  Author: Edward Koltun
--  Date: April 3, 2022
--[[
$module FCMCtrlButton

## Disabled Methods
As `FCCtrlButton` inherits from `FCCtrlCheckbox`, the following methods have been disabled from `FCMCtrlCheckbox`:
- `AddHandleCheckChange`
- `RemoveHandleCheckChange`

To handle button presses, use `AddHandleCommand`, inherited from `FCMControl`.
]] --
local mixin_helper = require("library.mixin_helper")

local meta = {}
local public = {}

mixin_helper.disable_methods(public, "AddHandleCheckChange", "RemoveHandleCheckChange")

return {meta, public}

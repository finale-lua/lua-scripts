--  Author: Edward Koltun
--  Date: April 6, 2022
--[[
$module FCMCtrlTree

## Summary of Modifications
- Methods that accept `FCString` will also accept Lua `string` or `number`.
]] --
local mixin = require("library.mixin") -- luacheck: ignore
local mixin_helper = require("library.mixin_helper")

local class = {Methods = {}}
local methods = class.Methods

local temp_str = finale.FCString()

--[[
% AddNode

**[Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

@ self (FCMCtrlTree)
@ parentnode (FCTreeNode | nil)
@ iscontainer (boolean)
@ text (FCString | string | number)
: (FCMTreeNode)
]]
function methods:AddNode(parentnode, iscontainer, text)
    mixin_helper.assert_argument_type(2, parentnode, "nil", "FCTreeNode")
    mixin_helper.assert_argument_type(3, iscontainer, "boolean")
    mixin_helper.assert_argument_type(4, text, "string", "number", "FCString")

    return self:AddNode__(parentnode, iscontainer, mixin_helper.to_fcstring(text, temp_str))
end

return class

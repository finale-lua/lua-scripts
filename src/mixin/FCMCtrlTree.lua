--  Author: Edward Koltun
--  Date: April 6, 2022
--[[
$module FCMCtrlTree

Summary of modifications:
- Methods that accept `FCString` now also accept Lua `string` and `number`.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local props = {}

local temp_str = finale.FCString()

--[[
% AddNode

**[Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMCtrlTree)
@ parentnode (FCTreeNode|nil)
@ iscontainer (boolean)
@ text (FCString|string|number)
: (FCMTreeNode)
]]
function props:AddNode(parentnode, iscontainer, text)
    mixin_helper.assert_argument_type(2, parentnode, "nil", "FCTreeNode")
    mixin_helper.assert_argument_type(3, iscontainer, "boolean")
    mixin_helper.assert_argument_type(4, text, "string", "number", "FCString")

    if not text.ClassName then
        temp_str.LuaString = tostring(text)
        text = temp_str
    end

    return self:AddNode_(parentnode, iscontainer, text)
end

return props

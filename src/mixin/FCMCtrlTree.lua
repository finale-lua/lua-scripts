--  Author: Edward Koltun
--  Date: April 6, 2022

--[[
$module FCMCtrlTree

Summary of modifications:
- Methods that accept `FCString` now also accept Lua `string` and `number`.
]]

local mixin = require("library.mixin")

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
    mixin.assert_argument(parentnode, {"nil", "FCTreeNode"}, 2)
    mixin.assert_argument(iscontainer, "boolean", 3)
    mixin.assert_argument(text, {"string", "number", "FCString"}, 4)

    if not text.ClassName then
        temp_str.LuaString = tostring(text)
        text = temp_str
    end

    return self:AddNode_(parentnode, iscontainer, text)
end


return props
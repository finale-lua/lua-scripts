-- Author: Edward Koltun
-- Date: August 26, 2022
--[[
$module FCMNoteEntry

Summary of modifications:
- Added methods to keep parent collection in scope
]] --
local mixin = require("library.mixin")

local private = setmetatable({}, {__mode = "k"})
local props = {}

--[[
% Init

**[Internal]**

@ self (FCMNoteEntry)
]]
function props:Init()
    private[self] = private[self] or {}
end

--[[
% RegisterParent

**[Fluid]**
Registers the collection to which this object belongs.

@ self (FCMNoteEntry)
@ parent (FCNoteEntryCell)
]]
function props:RegisterParent(parent)
    mixin.assert_argument(parent, 'FCNoteEntryCell', 2)

    if not private[self].Parent then
        private[self].Parent = parent
    end
end

--[[
% GetParent

Returns the collection to which this object belongs.

@ self (FCMNoteEntry)
: (FCMNoteEntryCell|nil)
]]
function props:GetParent()
    return private[self].Parent
end

return props

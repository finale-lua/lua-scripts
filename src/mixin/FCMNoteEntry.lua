-- Author: Edward Koltun
-- Date: August 26, 2022
--[[
$module FCMNoteEntry

## Summary of Modifications
- Added methods to keep parent collection in scope.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local meta = {}
local public = {}
local private = setmetatable({}, {__mode = "k"})

--[[
% Init

**[Internal]**

@ self (FCMNoteEntry)
]]
function meta:Init()
    if private[self] then
        return
    end

    private[self] = {}
end

--[[
% RegisterParent

**[Fluid]**

Registers the collection to which this object belongs.

@ self (FCMNoteEntry)
@ parent (FCNoteEntryCell)
]]
function public:RegisterParent(parent)
    mixin_helper.assert_argument_type(2, parent, "FCNoteEntryCell")

    if not private[self].Parent then
        private[self].Parent = parent
    end
end

--[[
% GetParent

Returns the collection to which this object belongs.

@ self (FCMNoteEntry)
: (FCMNoteEntryCell | nil)
]]
function public:GetParent()
    return private[self].Parent
end

return {meta, public}

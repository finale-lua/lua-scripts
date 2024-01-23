-- Author: Edward Koltun
-- Date: August 26, 2022
--[[
$module FCMNoteEntry

## Summary of Modifications
- Added methods to keep parent collection in scope.
]] --
local mixin_helper = require("library.mixin_helper")

local class = {Methods = {}}
local methods = class.Methods
local private = setmetatable({}, {__mode = "k"})

--[[
% Init

**[Internal]**

@ self (FCMNoteEntry)
]]
function class:Init()
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
function methods:RegisterParent(parent)
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
function methods:GetParent()
    return private[self].Parent
end

return class

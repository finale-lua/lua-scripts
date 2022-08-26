-- Author: Edward Koltun
-- Date: August 26, 2022
--[[
$module FCMNoteEntryCell

Summary of modifications:
- Attach collection to child object before returning
]] --

local mixin = require("library.mixin")

local props = {}

--[[
% GetItemAt

**[Override]**
Registers this collection as the parent of the item before returning it.
This allows the item to be used outside of a `mixin.eachentry` loop.

@ self (FCMNoteEntryCell)
@ index (number)
: (FCMNoteEntry|nil)
]]
function props:GetItemAt(index)
    mixin.assert_argument(index, "number", 2)

    local item = self:GetItemAt_(index)
    if item then
        item:RegisterParent(self)
    end

    return item
end

return props

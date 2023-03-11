-- Author: Edward Koltun
-- Date: August 26, 2022
--[[
$module FCMNoteEntryCell

Summary of modifications:
- Attach collection to child object before returning
]] --

local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local meta = {}
local public = {}

--[[
% GetItemAt

**[Override]**

Override Changes:
- Registers this collection as the parent of the item before returning it.
This allows the item to be used outside of a `mixin.eachentry` loop.

@ self (FCMNoteEntryCell)
@ index (number)
: (FCMNoteEntry | nil)
]]
function public:GetItemAt(index)
    mixin_helper.assert_argument_type(2, index, "number")

    local item = self:GetItemAt_(index)
    if item then
        item:RegisterParent(self)
    end

    return item
end

return {meta, public}

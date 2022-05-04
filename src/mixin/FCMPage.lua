--  Author: Edward Koltun
--  Date: April 13, 2021
--[[
$module FCMPage

Summary of modifications:
- Added methods for getting and setting the page size by its name according to the `page_size` library.
- Added method for checking if the page is blank.
]] --
local mixin = require("library.mixin")
local page_size = require("library.page_size")

local props = {}

--[[
% GetSize

Returns the size of the page.

@ self (FCMPage)
: (string|nil) The page size or `nil` if there is no defined size that matches the dimensions of this page.
]]
function props:GetSize()
    return page_size.get_page_size(self)
end

--[[
% SetSize

**[Fluid]**
Sets the dimensions of this page to match the given size. Page orientation will be preserved.

@ self (FCMPage)
@ size (string) A defined page size.
]]
function props:SetSize(size)
    mixin.assert_argument(size, "string", 2)
    mixin.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")

    page_size.set_page_size(self, size)
end

--[[
% IsBlank

Checks if this is a blank page (ie it contains no systems).

@ self (FCMPage)
: (boolean) `true` if this is page is blank
]]
function props:IsBlank()
    return self:GetFirstSystem() == -1
end

return props

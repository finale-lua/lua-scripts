--  Author: Edward Koltun
--  Date: April 13, 2021
--[[
$module FCMPage

## Summary of Modifications
- Added methods for getting and setting the page size by its name according to the `page_size` library.
- Added `IsBlank` method.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local page_size = require("library.page_size")

local class = {Methods = {}}
local methods = class.Methods

--[[
% GetSize

Returns the size of the page.

@ self (FCMPage)
: (string | nil) The page size or `nil` if there is no defined size that matches the dimensions of this page.
]]
function methods:GetSize()
    return page_size.get_page_size(self)
end

--[[
% SetSize

**[Fluid]**
Sets the dimensions of this page to match the given size. Page orientation will be preserved.

@ self (FCMPage)
@ size (string) A defined page size.
]]
function methods:SetSize(size)
    mixin_helper.assert_argument_type(2, size, "string")
    mixin_helper.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")

    page_size.set_page_size(self, size)
end

--[[
% IsBlank

Checks if this is a blank page (ie it contains no systems).

@ self (FCMPage)
: (boolean) `true` if this page is blank
]]
function methods:IsBlank()
    return self:GetFirstSystem() == -1
end

return class

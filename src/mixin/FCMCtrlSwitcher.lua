--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlSwitcher

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- Additional methods for accessing and adding pages and page titles.
- Added `PageChange` custom control event.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local library = require("library.general_library")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local trigger_page_change
local each_last_page_change
local temp_str = finale.FCString()

--[[
% Init

**[Internal]**

@ self (FCMCtrlSwitcher)
]]
function props:Init()
    private[self] = private[self] or {Index = {}}
end

--[[
% AddPage

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMCtrlSwitcher)
@ title (FCString|string|number)
]]
function props:AddPage(title)
    mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")

    if type(title) ~= "userdata" then
        temp_str.LuaString = tostring(title)
        title = temp_str
    end

    self:AddPage_(title)
    table.insert(private[self].Index, title.LuaString)
end

--[[
% AddPages

**[Fluid]**
Adds multiple pages, one page for each argument.

@ self (FCMCtrlSwitcher)
@ ... (FCString|string|number)
]]
function props:AddPages(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString")
        mixin.FCMCtrlSwitcher.AddPage(self, v)
    end
end

--[[
% AttachControlByTitle

Attaches a control to a page.

@ self (FCMCtrlSwitcher)
@ control (FCMControl) The control to attach.
@ title (FCString|string|number) The title of the page. Must be an exact match.
: (boolean)
]]
function props:AttachControlByTitle(control, title)
    mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
    mixin_helper.assert_argument_type(3, title, "string", "number", "FCString")

    title = type(title) == "userdata" and title.LuaString or tostring(title)

    local index = -1
    for k, v in ipairs(private[self].Index) do
        if v == title then
            index = k - 1
        end
    end

    mixin_helper.force_assert(index ~= -1, "No page titled '" .. title .. "'")

    return self:AttachControl_(control, index)
end

--[[
% SetSelectedPage

**[Fluid] [Override]**

@ self (FCMCtrlSwitcher)
@ index (number)
]]
function props:SetSelectedPage(index)
    mixin_helper.assert_argument_type(2, index, "number")

    self:SetSelectedPage_(index)

    trigger_page_change(self)
end

--[[
% SetSelectedPageByTitle

**[Fluid]**
Set the selected page by its title. If the page is not found, an error will be thrown.

@ self (FCMCtrlSwitcher)
@ title (FCString|string|number) Title of page to select. Must be an exact match.
]]
function props:SetSelectedPageByTitle(title)
    mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")

    title = type(title) == "userdata" and title.LuaString or tostring(title)

    for k, v in ipairs(private[self].Index) do
        if v == title then
            mixin.FCMCtrlSwitcher.SetSelectedPage(self, k - 1)
            return
        end
    end

    error("No page titled '" .. title .. "'", 2)
end

--[[
% GetSelectedPageTitle

Returns the title of the currently selected page.

@ self (FCMCtrlSwitcher)
@ [title] (FCString) Optional `FCString` object to populate.
: (string|nil) Nil if no page is selected
]]
function props:GetSelectedPageTitle(title)
    mixin_helper.assert_argument_type(2, title, "nil", "FCString")

    local index = self:GetSelectedPage_()
    if index == -1 then
        if title then
            title.LuaString = ""
        end

        return nil
    else
        local text = private[self].Index[self:GetSelectedPage_() + 1]

        if title then
            title.LuaString = text
        end

        return text
    end
end

--[[
% GetPageTitle

Returns the title of a page.

@ self (FCMCtrlSwitcher)
@ index (number) The 0-based index of the page.
@ [str] (FCString) An optional `FCString` object to populate.
: (string)
]]
function props:GetPageTitle(index, str)
    mixin_helper.assert_argument_type(2, index, "number")
    mixin_helper.assert_argument_type(3, str, "nil", "FCString")

    local text = private[self].Index[index + 1]
    mixin.force_assert(text, "No page at index " .. tostring(index))

    if str then
        str.LuaString = text
    end

    return text
end

--[[
% HandlePageChange

**[Callback Template]**

@ control (FCMCtrlSwitcher) The control on which the event occurred.
@ last_page (number) The 0-based index of the previously selected page. If no page was previously selected, this will be `-1` (eg when the window is created).
@ last_page_title (string) The title of the previously selected page.
]]

--[[
% AddHandlePageChange

**[Fluid]**
Adds an event listener for PageChange events.
The event fires when:
- The window is created (if pages have been added)
- The user switches page
- The selected page is changed programmatically (if the selected page is changed within a handler, that *same* handler will not be called for that change)

@ self (FCMCtrlSwitcher)
@ callback (function) See `HandlePageChange` for callback signature.
]]

--[[
% RemoveHandlePageChange

**[Fluid]**
Removes a handler added with `AddHandlePageChange`.

@ self (FCMCtrlSwitcher)
@ callback (function)
]]
props.AddHandlePageChange, props.RemoveHandlePageChange, trigger_page_change, each_last_page_change =
    mixin_helper.create_custom_control_change_event(
        {name = "last_page", get = "GetSelectedPage_", initial = -1}, {
            name = "last_page_title",
            get = function(ctrl)
                return mixin.FCMCtrlSwitcher.GetSelectedPageTitle(ctrl)
            end,
            initial = "",
        } -- Wrap get in function to prevent infinite recursion
    )

return props

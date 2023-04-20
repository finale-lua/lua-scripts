--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlSwitcher

## Summary of Modifications
- Setters that accept `FCString` will also accept Lua `string` and `number`.
- Methods that returned a boolean to indicate success/failure now throw an error instead.
- Added methods for accessing and adding pages.
- Added `PageChange` custom control event.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local class = {Methods = {}}
local methods = class.Methods
local private = setmetatable({}, {__mode = "k"})

local trigger_page_change
local each_last_page_change
local temp_str = finale.FCString()

--[[
% Init

**[Internal]**

@ self (FCMCtrlSwitcher)
]]
function class:Init()
    if private[self] then
        return
    end

    private[self] = {
        Index = {},
        TitleIndex = {},
    }
end

--[[
% AddPage

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.

@ self (FCMCtrlSwitcher)
@ title (FCString | string | number)
]]
function methods:AddPage(title)
    mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")

    title = mixin_helper.to_fcstring(title, temp_str)

    self:AddPage__(title)
    table.insert(private[self].Index, title.LuaString)
    private[self].TitleIndex[title.LuaString] = #private[self].Index - 1
end

--[[
% AddPages

**[Fluid]**

Adds multiple pages, one page for each argument.

@ self (FCMCtrlSwitcher)
@ ... (FCString | string | number)
]]
function methods:AddPages(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString")
        mixin.FCMCtrlSwitcher.AddPage(self, v)
    end
end

--[[
% AttachControl

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMCtrlSwitcher)
@ control (FCControl | FCMControl)
@ pageindex (number)
]]
function methods:AttachControl(control, pageindex)
    mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
    mixin_helper.assert_argument_type(3, pageindex, "number")

    mixin_helper.boolean_to_error(self, "AttachControl", control, pageindex)
end

--[[
% AttachControlByTitle

**[Fluid]**

Attaches a control to a page by its title.

@ self (FCMCtrlSwitcher)
@ control (FCControl | FCMControl) The control to attach.
@ title (FCString | string | number) The title of the page. Must be an exact match.
]]
function methods:AttachControlByTitle(control, title)
    mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
    mixin_helper.assert_argument_type(3, title, "string", "number", "FCString")

    title = type(title) == "userdata" and title.LuaString or tostring(title)

    local index = private[self].TitleIndex[title] or -1

    mixin_helper.force_assert(index ~= -1, "No page titled '" .. title .. "'")

    mixin.FCMCtrlSwitcher.AttachControl(self, control, index)
end

--[[
% SetSelectedPage

**[Fluid] [Override]**

Override Changes:
- Ensures that `PageChange` event is triggered.

@ self (FCMCtrlSwitcher)
@ index (number)
]]
function methods:SetSelectedPage(index)
    mixin_helper.assert_argument_type(2, index, "number")

    self:SetSelectedPage__(index)

    trigger_page_change(self)
end

--[[
% SetSelectedPageByTitle

**[Fluid]**

Set the selected page by its title. If the page is not found, an error will be thrown.

@ self (FCMCtrlSwitcher)
@ title (FCString | string | number) Title of page to select. Must be an exact, case-sensitive match.
]]
function methods:SetSelectedPageByTitle(title)
    mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")

    title = type(title) == "userdata" and title.LuaString or tostring(title)

    local index = private[self].TitleIndex[title] or -1
    mixin_helper.force_assert(index ~= -1, "No page titled '" .. title .. "'")
    mixin.FCMCtrlSwitcher.SetSelectedPage(self, index)
end

--[[
% GetSelectedPageTitle

**[?Fluid]**

Retrieves the title of the currently selected page.

@ self (FCMCtrlSwitcher)
@ [title] (FCString) Optional `FCString` object to populate.
: (string | nil) Returned if `title` is omitted. `nil` if no page is selected
]]
function methods:GetSelectedPageTitle(title)
    mixin_helper.assert_argument_type(2, title, "nil", "FCString")

    local index = self:GetSelectedPage__()

    if index == -1 then
        if title then
            title.LuaString = ""
        else
            return nil
        end
    else
        return mixin.FCMCtrlSwitcher.GetPageTitle(self, index, title)
    end
end

--[[
% GetPageTitle

**[?Fluid]**

Retrieves the title of a page.

@ self (FCMCtrlSwitcher)
@ index (number) The 0-based index of the page.
@ [str] (FCString) An optional `FCString` object to populate.
: (string) Returned if `str` is omitted.
]]
function methods:GetPageTitle(index, str)
    mixin_helper.assert_argument_type(2, index, "number")
    mixin_helper.assert_argument_type(3, str, "nil", "FCString")

    local text = private[self].Index[index + 1]
    mixin_helper.force_assert(text, "No page at index " .. tostring(index))

    if str then
        str.LuaString = text
    else
        return text
    end
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
methods.AddHandlePageChange, methods.RemoveHandlePageChange, trigger_page_change, each_last_page_change = mixin_helper.create_custom_control_change_event(
    {
        name = "last_page",
        get = "GetSelectedPage__",
        initial = -1
    },
    {
        name = "last_page_title",
        -- Wrap get in function to prevent infinite recursion
        get = function(ctrl)
            return mixin.FCMCtrlSwitcher.GetSelectedPageTitle(ctrl)
        end,
        initial = "",
    }
)

return class

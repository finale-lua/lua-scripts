--  Author: Edward Koltun
--  Date: April 4, 2022

--[[
$module FCMCtrlListBox

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
- Setters that accept `FCStrings` now also accept multiple arguments of `FCString`, Lua `string`, or `number`.
- Numerous additional methods for accessing and modifying listbox items.
- Added `SelectionChange` custom control event.
]]

local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local library = require("library.general_library")
local utils = require("library.utils")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local trigger_selection_change
local each_last_selection_change
local temp_str = finale.FCString()


--[[
% Init

**[Internal]**

@ self (FCMCtrlListBox)
]]
function props:Init()
    private[self] = private[self] or {}
end

--[[
% Clear

**[Fluid] [Override]**

@ self (FCMCtrlListBox)
]]
function props:Clear()
    self:Clear_()
    private[self] = {}

    for v in each_last_selection_change(self) do
        if v.last_item >= 0 then
            v.is_deleted = true
        end
    end

    trigger_selection_change(self)
end

--[[
% SetSelectedItem

**[Fluid] [Override]**
Ensures that `SelectionChange` is triggered.

@ self (FCMCtrlListBox)
@ index (number)
]]
function props:SetSelectedItem(index)
    mixin.assert_argument(index, "number", 2)

    self:SetSelectedItem_(index)

    trigger_selection_change(self)
end

--[[
% SetSelectedLast

**[Override]**
Ensures that `SelectionChange` is triggered.

@ self (FCMCtrlListBox)
: (boolean) `true` if a selection was possible.
]]
function props:SetSelectedLast()
    trigger_selection_change(self)
    return self:SetSelectedLast_()
end

--[[
% AddString

**[Fluid] [Override]**

Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMCtrlListBox)
@ str (FCString|string|number)
]]
function props:AddString(str)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    self:AddString_(str)

    -- Since we've made it here without errors, str must be an FCString
    table.insert(private[self], str.LuaString)
end

--[[
% AddStrings

**[Fluid]**
Adds multiple strings to the list box.

@ self (FCMCtrlListBox)
@ ... (FCStrings|FCString|string|number)
]]
function props:AddStrings(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        mixin.assert_argument(v, {"string", "number", "FCString", "FCStrings"}, i + 1)

        if type(v) == "userdata" and v:ClassName() == "FCStrings" then
            for str in each(v) do
                mixin.FCMCtrlListBox.AddString(self, str)
            end
        else
            mixin.FCMCtrlListBox.AddString(self, v)
        end
    end
end

--[[
% GetStrings

Returns a copy of all strings in the list box.

@ self (FCMCtrlListBox)
@ [strs] (FCStrings) An optional `FCStrings` object to populate with strings.
: (table) A table of strings (1-indexed - beware if accessing keys!).
]]
function props:GetStrings(strs)
    mixin.assert_argument(strs, {"nil", "FCStrings"}, 2)

    if strs then
        strs:ClearAll()
        for _, v in ipairs(private[self]) do
            temp_str.LuaString = v
            strs:AddCopy(temp_str)
        end
    end

    return utils.copy_table(private[self])
end

--[[
% SetStrings

**[Fluid] [Override]**
Accepts multiple arguments.

@ self (FCMCtrlListBox)
@ ... (FCStrings|FCString|string|number) `number`s will be automatically cast to `string`
]]
function props:SetStrings(...)
    -- No argument validation in this method for now...
    local strs = select(1, ...)
    if select("#", ...) ~= 1 or not library.is_finale_object(strs) or strs:ClassName() ~= "FCStrings" then
        strs = mixin.FCMStrings()
        strs:CopyFrom(...)
    end

    self:SetStrings_(strs)

    private[self] = {}
    for str in each(strs) do
        table.insert(private[self], str.LuaString)
    end

    for v in each_last_selection_change(self) do
        if v.last_item >= 0 then
            v.is_deleted = true
        end
    end

    trigger_selection_change(self)
end

--[[
% GetItemText

Returns the text for an item in the list box.
This method works in all JW/RGP Lua versions and irrespective of whether `InitWindow` has been called.

@ self (FCMCtrlListBox)
@ index (number) 0-based index of item.
@ [str] (FCString) Optional `FCString` object to populate with text.
: (string)
]]
function props:GetItemText(index, str)
    mixin.assert_argument(index, "number", 2)
    mixin.assert_argument(str, {"nil", "FCString"}, 3)

    if not private[self][index + 1] then
        error("No item at index " .. tostring(index), 2)
    end

    if str then
        str.LuaString = private[self][index + 1]
    end

    return private[self][index + 1]
end

--[[
% SetItemText

**[Fluid] [PDK Port]**
Sets the text for an item.

@ self (FCMCtrlListBox)
@ index (number) 0-based index of item.
@ str (FCString|string|number)
]]
function props:SetItemText(index, str)
    mixin.assert_argument(index, "number", 2)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 3)

    if not private[self][index + 1] then
        error("No item at index " .. tostring(index), 2)
    end

    private[self][index + 1] = type(str) == "userdata" and str.LuaString or tostring(str)

    -- SetItemText was added to RGPLua in v0.56 and only works once the window has been created
    if self:GetParent():WindowExists_() and self.SetItemText_ then
        temp_str.LuaString = private[self][index + 1]
        self:SetItemText_(index, temp_str)

    -- Otherwise, use a polyfill
    else
        local strs = finale.FCStrings()
        for _, v in ipairs(private[self]) do
            temp_str.LuaString = v
            strs:AddCopy(temp_str)
        end

        local curr_item = self:GetSelectedItem_()
        self:SetStrings_(strs)
        self:SetSelectedItem_(curr_item)
    end
end

--[[
% GetSelectedString

Returns the text for the item that is currently selected.

@ self (FCMCtrlListBox)
@ [str] (FCString) Optional `FCString` object to populate with text. If no item is currently selected, it will be populated with an empty string.
: (string|nil) `nil` if no item is currently selected.
]]
function props:GetSelectedString(str)
    mixin.assert_argument(str, {"nil", "FCString"}, 2)

    local index = self:GetSelectedItem_()

    if index ~= -1 then
        if str then
            str.LuaString = private[self][index + 1]
        end

        return private[self][index + 1]
    else
        if str then
            str.LuaString = ""
        end

        return nil
    end
end

--[[
% SetSelectedString

**[Fluid]**
Sets the currently selected item to the first item with a matching text value.

If no match is found, the current selected item will remain selected.

@ self (FCMCtrlListBox)
@ str (FCString|string|number)
]]
function props:SetSelectedString(str)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    str = type(str) == "userdata" and str.LuaString or tostring(str)

    for k, v in ipairs(private[self]) do
        if str == v then
            self:SetSelectedItem_(k - 1)
            trigger_selection_change(self)
            return
        end
    end
end

--[[
% InsertItem

**[Fluid] [PDKPort]**
Inserts a string at the specified index.
If index is <= 0, will insert at the start.
If index is >= Count, will insert at the end.

@ self (FCMCtrlListBox)
@ index (number) 0-based index to insert new item.
@ str (FCString|string|number) The value to insert.
]]
function props:InsertItem(index, str)
    mixin.assert_argument(index, "number", 2)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 3)

    if index < 0 then
        index = 0
    elseif index >= #private[self] then
        self:AddString(str)
        return
    end

    table.insert(private[self], index + 1, type(str) == "userdata" and str.LuaString or tostring(str))

    local strs = finale.FCStrings()
    for _, v in ipairs(private[self]) do
        temp_str.LuaString = v
        strs:AddCopy(temp_str)
    end

    local curr_item = self:GetSelectedItem()
    self:SetStrings_(strs)

    if curr_item >= index then
        self:SetSelectedItem_(curr_item + 1)
    else
        self:SetSelectedItem_(curr_item)
    end

    for v in each_last_selection_change(self) do
        if v.last_item >= index then
            v.last_item = v.last_item+ 1
        end
    end
end

--[[
% DeleteItem

**[Fluid] [PDK Port]**
Deletes an item from the list box.
If the currently selected item is deleted, items will be deselected (ie set to -1)

@ self (FCMCtrlListBox)
@ index (number) 0-based index of item to delete.
]]
function props:DeleteItem(index)
    mixin.assert_argument(index, "number", 2)

    if index < 0 or index >= #private[self] then
        return
    end

    table.remove(private[self], index + 1)

    local strs = finale.FCStrings()
    for _, v in ipairs(private[self]) do
        temp_str.LuaString = v
        strs:AddCopy(temp_str)
    end

    local curr_item = self:GetSelectedItem()
    self:SetStrings_(strs)

    if curr_item > index then
        self:SetSelectedItem_(curr_item - 1)
    elseif curr_item == index then
        self:SetSelectedItem_(-1)
    else
        self:SetSelectedItem_(curr_item)
    end

    for v in each_last_selection_change(self) do
        if v.last_item == index then
            v.is_deleted = true
        elseif v.last_item > index then
            v.last_item = v.last_item - 1
        end
    end

    -- Only need to trigger event if the current selection was deleted
    if curr_item == index then
        trigger_selection_change(self)
    end
end

--[[
% HandleSelectionChange

**[Callback Template]**

@ control (FCMCtrlListBox)
@ last_item (number) The 0-based index of the previously selected item. If no item was selected, the value will be `-1`.
@ last_item_text (string) The text value of the previously selected item.
@ is_deleted (boolean) `true` if the previously selected item is no longer in the control.
]]

--[[
% AddHandleSelectionChange

**[Fluid]**
Adds a handler for SelectionChange events.
If the selected item is changed by a handler, that same handler will not be called again for that change.

The event will fire in the following cases:
- When the window is created (if an item is selected)
- Change in selected item by user or programatically (inserting an item before or after will not trigger the event)
- Changing the text value of the currently selected item
- Deleting the currently selected item
- Clearing the control (including calling `Clear` and `SetStrings`)

@ self (FCMCtrlListBox)
@ callback (function) See `HandleSelectionChange` for callback signature.
]]

--[[
% RemoveHandleSelectionChange

**[Fluid]**
Removes a handler added with `AddHandleSelectionChange`.

@ self (FCMCtrlListBox)
@ callback (function) Handler to remove.
]]
props.AddHandleSelectionChange, props.RemoveHandleSelectionChange, trigger_selection_change, each_last_selection_change = mixin_helper.create_custom_control_change_event(
    {name = 'last_item', get = "GetSelectedItem_", initial = -1},
    {name = 'last_item_text', get = function(ctrl) return mixin.FCMCtrlListBox.GetSelectedString(ctrl) or "" end, initial = ""},
    {name = 'is_deleted', get = function() return false end, initial = false}
)

return props
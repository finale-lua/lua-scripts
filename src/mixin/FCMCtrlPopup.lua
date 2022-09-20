--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlPopup

Summary of modifications:
- Setters that accept `FCString` now also accept Lua `string` and `number`.
- In getters with an `FCString` parameter, the parameter is now optional and a Lua `string` is returned. 
- Setters that accept `FCStrings` now also accept multiple arguments of `FCString`, Lua `string`, or `number`.
- Numerous additional methods for accessing and modifying popup items.
- Added `SelectionChange` custom control event.
- Added hooks for restoring control state
]] --
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

@ self (FCMCtrlPopup)
]]
function props:Init()
    private[self] = private[self] or {
        Items = {},
    }
end


--[[
% StoreState

**[Fluid] [Internal] [Override]**
Stores the control's current state.
Do not disable this method. Override as needed but call the parent first.

@ self (FCMCtrlPopup)
]]
function props:StoreState()
    mixin.FCMControl.StoreState(self)
    private[self].SelectedItem = self:GetSelectedItem_()
end

--[[
% RestoreState

**[Fluid] [Internal] [Override]**
Restores the control's stored state.
Do not disable this method. Override as needed but call the parent first.

@ self (FCMCtrlPopup)
]]
function props:RestoreState()
    mixin.FCMControl.RestoreState(self)

    self:Clear_()
    for _, str in ipairs(private[self].Items) do
        temp_str.LuaString = str
        self:AddString_(temp_str)
    end

    self:SetSelectedItem_(private[self].SelectedItem)
end

--[[
% Clear

**[Fluid] [Override]**

@ self (FCMCtrlPopup)
]]
function props:Clear()
    if not mixin.FCMControl.UseStoredState(self) then
        self:Clear_()
    end

    private[self].Items = {}

    for v in each_last_selection_change(self) do
        if v.last_item >= 0 then
            v.is_deleted = true
        end
    end

    -- Clearing doesn't trigger a Command event (which in turn triggers SelectionChange), so we need to trigger it manually
    trigger_selection_change(self)
end

--[[
% GetCount

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlPopup)
: (number)
]]
function props:GetCount()
    if mixin.FCMControl.UseStoredState(self) then
        return #private[self].Items
    end

    return self:GetCount_()
end

--[[
% GetSelectedItem

**[Override]**
Hooks into control state restoration.

@ self (FCMCtrlPopup)
: (number)
]]
function props:GetSelectedItem()
    if mixin.FCMControl.UseStoredState(self) then
        return private[self].SelectedItem
    end

    return self:GetSelectedItem_()
end

--[[
% SetSelectedItem

**[Fluid] [Override]**
Ensures that SelectionChange is triggered.
Also hooks into control state restoration.

@ self (FCMCtrlPopup)
@ index (number)
]]
function props:SetSelectedItem(index)
    mixin.assert_argument(index, "number", 2)

    if mixin.FCMControl.UseStoredState(self) then
        private[self].SelectedItem = index
    else
        self:SetSelectedItem_(index)
    end

    trigger_selection_change(self)
end

--[[
% SetSelectedLast

**[Fluid]**
Selects the last item in the popup. If popup is empty, will be set to -1.

@ self (FCMCtrlPopup)
]]
function props:SetSelectedLast()
    mixin.FCMCtrlPopup.SetSelectedItem(self, mixin.FCMCtrlPopup.GetCount(self) - 1)
end

--[[
% IsItemSelected

Checks if the popup has a selection. If the parent window does not exist (ie `WindowExists() == false`), this result is theoretical.

@ self (FCMCtrlPopup)
: (boolean) `true` if something is selected, `false` if no selection.
]]
function props:IsItemSelected()
    return mixin.FCMCtrlPopup.GetSelectedItem(self) >= 0
end

--[[
% ItemExists

Checks if there is an item at the specified index.

@ self (FCMCtrlPopup)
@ index (number) 0-based item index.
: (boolean) `true` if the item exists, `false` if it does not exist.
]]
function props:ItemExists(index)
    mixin.assert_argument(index, "number", 2)

    return private[self].Items[index + 1] and true or false
end

--[[
% AddString

**[Fluid] [Override]**

Accepts Lua `string` and `number` in addition to `FCString`.
Also hooks into control state restoration.

@ self (FCMCtrlPopup)
@ str (FCString|string|number)
]]
function props:AddString(str)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    if not mixin.FCMControl.UseStoredState(self) then
        self:AddString_(str)
    end

    -- Since we've made it here without errors, str must be an FCString
    table.insert(private[self].Items, str.LuaString)
end

--[[
% AddStrings

**[Fluid]**
Adds multiple strings to the popup.

@ self (FCMCtrlPopup)
@ ... (FCStrings|FCString|string|number)
]]
function props:AddStrings(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        mixin.assert_argument(v, {"string", "number", "FCString", "FCStrings"}, i + 1)

        if type(v) == "userdata" and v:ClassName() == "FCStrings" then
            for str in each(v) do
                mixin.FCMCtrlPopup.AddString(self, str)
            end
        else
            mixin.FCMCtrlPopup.AddString(self, v)
        end
    end
end

--[[
% GetStrings

Returns a copy of all strings in the popup.

@ self (FCMCtrlPopup)
@ [strs] (FCStrings) An optional `FCStrings` object to populate with strings.
: (table) A table of strings (1-indexed - beware when accessing by key!).
]]
function props:GetStrings(strs)
    mixin.assert_argument(strs, {"nil", "FCStrings"}, 2)

    if strs then
        strs:ClearAll()
        for _, v in ipairs(private[self].Items) do
            temp_str.LuaString = v
            strs:AddCopy(temp_str)
        end
    end

    return utils.copy_table(private[self].Items)
end

--[[
% SetStrings

**[Fluid] [Override]**
Accepts multiple arguments.

@ self (FCMCtrlPopup)
@ ... (FCStrings|FCString|string|number) `number`s will be automatically cast to `string`
]]
function props:SetStrings(...)
    -- No argument validation in this method for now...
    local strs = select(1, ...)
    if select("#", ...) ~= 1 or not library.is_finale_object(strs) or strs:ClassName() ~= "FCStrings" then
        strs = mixin.FCMStrings()
        strs:CopyFrom(...)
    end

    if not mixin.FCMControl.UseStoredState(self) then
        self:SetStrings_(strs)
    end

    private[self].Items = {}
    for str in each(strs) do
        table.insert(private[self].Items, str.LuaString)
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

Returns the text for an item in the popup.

@ self (FCMCtrlPopup)
@ index (number) 0-based index of item.
@ [str] (FCString) Optional `FCString` object to populate with text.
: (string|nil) `nil` if the item doesn't exist
]]
function props:GetItemText(index, str)
    mixin.assert_argument(index, "number", 2)
    mixin.assert_argument(str, {"nil", "FCString"}, 3)

    if not mixin.FCMCtrlPopup.ItemExists(self, index) then
        error("No item at index " .. tostring(index), 2)
    end

    if str then
        str.LuaString = private[self].Items[index + 1]
    end

    return private[self].Items[index + 1]
end

--[[
% SetItemText

**[Fluid] [PDK Port]**
Sets the text for an item.

@ self (FCMCtrlPopup)
@ index (number) 0-based index of item.
@ str (FCString|string|number)
]]
function props:SetItemText(index, str)
    mixin.assert_argument(index, "number", 2)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 3)

    if not mixin.FCMCtrlPopup.ItemExists(self, index) then
        error("No item at index " .. tostring(index), 2)
    end

    str = type(str) == "userdata" and str.LuaString or tostring(str)

    -- If the text is the same, then there is nothing to do
    if private[self].Items[index + 1] == str then
        return
    end

    private[self].Items[index + 1] = str

    if not mixin.FCMControl.UseStoredState(self) then
        local strs = finale.FCStrings()
        for _, v in ipairs(private[self].Items) do
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

@ self (FCMCtrlPopup)
@ [str] (FCString) Optional `FCString` object to populate with text. If no item is currently selected, it will be populated with an empty string.
: (string|nil) `nil` if no item is currently selected.
]]
function props:GetSelectedString(str)
    mixin.assert_argument(str, {"nil", "FCString"}, 2)

    local index = mixin.FCMCtrlPopup.GetSelectedItem(self)

    if mixin.FCMCtrlPopup.ItemExists(self, index) then
        if str then
            str.LuaString = private[self].Items[index + 1]
        end

        return private[self].Items[index + 1]
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

If no match is found, the current selected item will remain selected. Matching is case-sensitive.

@ self (FCMCtrlPopup)
@ str (FCString|string|number)
]]
function props:SetSelectedString(str)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    str = type(str) == "userdata" and str.LuaString or tostring(str)

    for k, v in ipairs(private[self].Items) do
        if str == v then
            mixin.FCMCtrlPopup.SetSelectedItem(self, k - 1)
            return
        end
    end
end

--[[
% InsertString

**[Fluid] [PDKPort]**
Inserts a string at the specified index.
If index is <= 0, will insert at the start.
If index is >= Count, will insert at the end.

@ self (FCMCtrlPopup)
@ index (number) 0-based index to insert new item.
@ str (FCString|string|number) The value to insert.
]]
function props:InsertString(index, str)
    mixin.assert_argument(index, "number", 2)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 3)

    if index < 0 then
        index = 0
    elseif index >= mixin.FCMCtrlPopup.GetCount(self) then
        mixin.FCMCtrlPopup.AddString(self, str)
        return
    end

    table.insert(private[self].Items, index + 1, type(str) == "userdata" and str.LuaString or tostring(str))

    local current_selection = mixin.FCMCtrlPopup.GetSelectedItem(self)

    if not mixin.FCMControl.UseStoredState(self) then
        local strs = finale.FCStrings()
        for _, v in ipairs(private[self].Items) do
            temp_str.LuaString = v
            strs:AddCopy(temp_str)
        end

        self:SetStrings_(strs)
    end

    local new_selection = current_selection >= index and current_selection + 1 or current_selection
    mixin.FCMCtrlPopup.SetSelectedItem(self, new_selection)

    for v in each_last_selection_change(self) do
        if v.last_item >= index then
            v.last_item = v.last_item + 1
        end
    end
end

--[[
% DeleteItem

**[Fluid] [PDK Port]**
Deletes an item from the popup.
If the currently selected item is deleted, items will be deselected (ie set to -1)

@ self (FCMCtrlPopup)
@ index (number) 0-based index of item to delete.
]]
function props:DeleteItem(index)
    mixin.assert_argument(index, "number", 2)

    if index < 0 or index >= mixin.FCMCtrlPopup.GetCount(self) then
        return
    end

    table.remove(private[self].Items, index + 1)

    local current_selection = mixin.FCMCtrlPopup.GetSelectedItem(self)

    if not mixin.FCMControl.UseStoredState(self) then
        local strs = finale.FCStrings()
        for _, v in ipairs(private[self].Items) do
            temp_str.LuaString = v
            strs:AddCopy(temp_str)
        end

        self:SetStrings_(strs)
    end

    local new_selection
    if current_selection > index then
        new_selection = current_selection - 1
    elseif current_selection == index then
        new_selection = -1
    else
        new_selection = current_selection
    end

    mixin.FCMCtrlPopup.SetSelectedItem(self, new_selection)

    for v in each_last_selection_change(self) do
        if v.last_item == index then
            v.is_deleted = true
        elseif v.last_item > index then
            v.last_item = v.last_item - 1
        end
    end

    -- Only need to trigger event if the current selection was deleted
    if current_selection == index then
        trigger_selection_change(self)
    end
end

--[[
% HandleSelectionChange

**[Callback Template]**

@ control (FCMCtrlPopup)
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

@ self (FCMCtrlPopup)
@ callback (function) See `HandleSelectionChange` for callback signature.
]]

--[[
% RemoveHandleSelectionChange

**[Fluid]**
Removes a handler added with `AddHandleSelectionChange`.

@ self (FCMCtrlPopup)
@ callback (function) Handler to remove.
]]
props.AddHandleSelectionChange, props.RemoveHandleSelectionChange, trigger_selection_change, each_last_selection_change = mixin_helper.create_custom_control_change_event(
    {
        name = "last_item",
        get = function(ctrl)
            return mixin.FCMCtrlPopup.GetSelectedItem(ctrl)
        end,
        initial = -1,
    }, {
        name = "last_item_text",
        get = function(ctrl)
            return mixin.FCMCtrlPopup.GetSelectedString(ctrl) or ""
        end,
        initial = "",
    }, {
        name = "is_deleted",
        get = function()
            return false
        end,
        initial = false,
    }
)

return props

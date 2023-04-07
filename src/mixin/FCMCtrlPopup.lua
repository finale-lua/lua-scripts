--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMCtrlPopup

## Summary of Modifications
- Setters that accept `FCString` will also accept a Lua `string` or `number`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
- Setters that accept `FCStrings` will also accept multiple arguments of `FCString`, Lua `string`, or `number`.
- Added numerous methods for accessing and modifying popup items.
- Added `SelectionChange` custom control event.
- Added hooks for preserving control state
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local library = require("library.general_library")
local utils = require("library.utils")

local meta = {}
local public = {}
local private = setmetatable({}, {__mode = "k"})

local trigger_selection_change
local each_last_selection_change
local temp_str = finale.FCString()


--[[
% Init

**[Internal]**

@ self (FCMCtrlPopup)
]]
function meta:Init()
    if private[self] then
        return
    end

    private[self] = {
        Items = {},
    }
end


--[[
% StoreState

**[Fluid] [Internal] [Override]**

Override Changes:
- Stores `FCMCtrlPopup`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

@ self (FCMCtrlPopup)
]]
function public:StoreState()
    mixin.FCMControl.StoreState(self)
    private[self].SelectedItem = self:GetSelectedItem_()
end

--[[
% RestoreState

**[Fluid] [Internal] [Override]**

Override Changes:
- Restores `FCMCtrlPopup`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

@ self (FCMCtrlPopup)
]]
function public:RestoreState()
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

Override Changes:
- Ensures that `SelectionChange` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlPopup)
]]
function public:Clear()
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

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlPopup)
: (number)
]]
function public:GetCount()
    if mixin.FCMControl.UseStoredState(self) then
        return #private[self].Items
    end

    return self:GetCount_()
end

--[[
% GetSelectedItem

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlPopup)
: (number)
]]
function public:GetSelectedItem()
    if mixin.FCMControl.UseStoredState(self) then
        return private[self].SelectedItem
    end

    return self:GetSelectedItem_()
end

--[[
% SetSelectedItem

**[Fluid] [Override]**

Override Changes:
- Ensures that `SelectionChange` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlPopup)
@ index (number)
]]
function public:SetSelectedItem(index)
    mixin_helper.assert_argument_type(2, index, "number")

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

Selects the last item in the popup. If the popup is empty, `SelectedItem` will be set to -1.

@ self (FCMCtrlPopup)
]]
function public:SetSelectedLast()
    mixin.FCMCtrlPopup.SetSelectedItem(self, mixin.FCMCtrlPopup.GetCount(self) - 1)
end

--[[
% HasSelection

Checks if the popup has a selection. If the parent window does not exist (ie `WindowExists() == false`), this result is theoretical.

@ self (FCMCtrlPopup)
: (boolean) `true` if something is selected, `false` if no selection.
]]
function public:HasSelection()
    return mixin.FCMCtrlPopup.GetSelectedItem(self) >= 0
end

--[[
% ItemExists

Checks if there is an item at the specified index.

@ self (FCMCtrlPopup)
@ index (number) 0-based item index.
: (boolean) `true` if the item exists, `false` if it does not exist.
]]
function public:ItemExists(index)
    mixin_helper.assert_argument_type(2, index, "number")

    return private[self].Items[index + 1] and true or false
end

--[[
% AddString

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.
- Hooks into control state preservation.

@ self (FCMCtrlPopup)
@ str (FCString | string | number)
]]
function public:AddString(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    str = mixin_helper.to_fcstring(str, temp_str)

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
@ ... (FCStrings | FCString | string | number)
]]
function public:AddStrings(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString", "FCStrings")

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

**[?Fluid]**

Returns a copy of all strings in the popup.

@ self (FCMCtrlPopup)
@ [strs] (FCStrings) An optional `FCStrings` object to populate with strings.
: (table) Returned if `strs` is omitted. A table of strings (1-indexed - beware when accessing by key!).
]]
function public:GetStrings(strs)
    mixin_helper.assert_argument_type(2, strs, "nil", "FCStrings")

    if strs then
        mixin.FCMStrings.CopyFromStringTable(strs, private[self].Items)
    else
        return utils.copy_table(private[self].Items)
    end
end

--[[
% SetStrings

**[Fluid] [Override]**

Override Changes:
- Acccepts `FCString` or Lua `string` or `number` in addition to `FCStrings`.
- Accepts multiple arguments.
- Hooks into control state preservation.

@ self (FCMCtrlPopup)
@ ... (FCStrings | FCString | string | number) `number`s will be automatically cast to `string`
]]
function public:SetStrings(...)
    for i = 1, select("#", ...) do
        mixin_helper.assert_argument_type(i + 1, select(i, ...), "FCStrings", "FCString", "string", "number")
    end

    local strs = select(1, ...)
    if select("#", ...) ~= 1 or not mixin_helper.is_instance_of(strs, "FCStrings") then
        strs = mixin.FCMStrings()
        strs:AddCopies(...)
    end

    if not mixin.FCMControl.UseStoredState(self) then
        self:SetStrings_(strs)
    end

    -- Call statically, since there's no guarantee that strs is mixin-enabled
    private[self].Items = mixin.FCMStrings.CreateStringTable(strs)

    for v in each_last_selection_change(self) do
        if v.last_item >= 0 then
            v.is_deleted = true
        end
    end

    trigger_selection_change(self)
end

--[[
% GetItemText

**[?Fluid]**

Returns the text for an item in the popup.

@ self (FCMCtrlPopup)
@ index (number) 0-based index of the item.
@ [str] (FCString) Optional `FCString` object to populate with text.
: (string | nil) Returned if `str` is omitted. `nil` if the item doesn't exist
]]
function public:GetItemText(index, str)
    mixin_helper.assert_argument_type(2, index, "number")
    mixin_helper.assert_argument_type(3, str, "nil", "FCString")

    if not mixin.FCMCtrlPopup.ItemExists(self, index) then
        error("No item at index " .. tostring(index), 2)
    end

    if str then
        str.LuaString = private[self].Items[index + 1]
    else
        return private[self].Items[index + 1]
    end
end

--[[
% SetItemText

**[Fluid] [PDK Port]**

Sets the text for an item.

Port Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.
- Hooks into control state preservation.

@ self (FCMCtrlPopup)
@ index (number) 0-based index of the item.
@ str (FCString | string | number)
]]
function public:SetItemText(index, str)
    mixin_helper.assert_argument_type(2, index, "number")
    mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")

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
        local curr_item = self:GetSelectedItem_()
        self:SetStrings_(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
        self:SetSelectedItem_(curr_item)
    end
end

--[[
% GetSelectedString

**[?Fluid]**

Returns the text for the item that is currently selected.

@ self (FCMCtrlPopup)
@ [str] (FCString) Optional `FCString` object to populate with text. If no item is currently selected, it will be populated with an empty string.
: (string | nil) Returned if `str` is omitted. `nil` if no item is currently selected.
]]
function public:GetSelectedString(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    local index = mixin.FCMCtrlPopup.GetSelectedItem(self)

    if str then
        str.LuaString = index ~= -1 and private[self].Items[index + 1] or ""
    else
        return index ~= -1 and private[self].Items[index + 1] or nil
    end
end

--[[
% SetSelectedString

**[Fluid]**

Sets the currently selected item to the first item with a matching text value.

If no match is found, the current selected item will remain selected. Matching is case-sensitive.

@ self (FCMCtrlPopup)
@ str (FCString | string | number)
]]
function public:SetSelectedString(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

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
If index is >= GetCount(), will insert at the end.

Port Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.
- Hooks into control state preservation.

@ self (FCMCtrlPopup)
@ index (number) 0-based index to insert new item.
@ str (FCString | string | number) The value to insert.
]]
function public:InsertString(index, str)
    mixin_helper.assert_argument_type(2, index, "number")
    mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")

    if index < 0 then
        index = 0
    elseif index >= mixin.FCMCtrlPopup.GetCount(self) then
        mixin.FCMCtrlPopup.AddString(self, str)
        return
    end

    table.insert(private[self].Items, index + 1, type(str) == "userdata" and str.LuaString or tostring(str))

    local current_selection = mixin.FCMCtrlPopup.GetSelectedItem(self)

    if not mixin.FCMControl.UseStoredState(self) then
        self:SetStrings_(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
    end

    local new_selection = current_selection + (index <= current_selection and 1 or 0)
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
If the currently selected item is deleted, it will be deselected (ie `SelectedItem = -1`)

@ self (FCMCtrlPopup)
@ index (number) 0-based index of item to delete.
]]
function public:DeleteItem(index)
    mixin_helper.assert_argument_type(2, index, "number")

    if index < 0 or index >= mixin.FCMCtrlPopup.GetCount(self) then
        return
    end

    table.remove(private[self].Items, index + 1)

    local current_selection = mixin.FCMCtrlPopup.GetSelectedItem(self)

    if not mixin.FCMControl.UseStoredState(self) then
        self:SetStrings_(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
    end

    local new_selection
    if index < current_selection then
        new_selection = current_selection - 1
    elseif index == current_selection then
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
    if index == current_selection then
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
public.AddHandleSelectionChange, public.RemoveHandleSelectionChange, trigger_selection_change, each_last_selection_change = mixin_helper.create_custom_control_change_event(
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

return {meta, public}

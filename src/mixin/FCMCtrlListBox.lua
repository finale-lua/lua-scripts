--  Author: Edward Koltun
--  Date: April 4, 2022
--[[
$module FCMCtrlListBox

## Summary of Modifications
- Setters that accept `FCString` will also accept a Lua `string` or `number`.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
- Setters that accept `FCStrings` will also accept multiple arguments of `FCString`, Lua `string`, or `number`.
- Added numerous methods for accessing and modifying listbox items.
- Added `SelectionChange` custom control event.
- Added hooks into control state preservation.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local utils = require("library.utils")

local class = {Methods = {}}
local methods = class.Methods
local private = setmetatable({}, {__mode = "k"})

local trigger_selection_change
local each_last_selection_change
local temp_str = finale.FCString()

--[[
% Init

**[Internal]**

@ self (FCMCtrlListBox)
]]
function class:Init()
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
- Stores `FCMCtrlListBox`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

@ self (FCMCtrlListBox)
]]
function methods:StoreState()
    mixin.FCMControl.StoreState(self)
    private[self].SelectedItem = self:GetSelectedItem__()
end

--[[
% RestoreState

**[Fluid] [Internal] [Override]**

Override Changes:
- Restores `FCMCtrlListBox`-specific properties.

*Do not disable this method. Override as needed but call the parent first.*

@ self (FCMCtrlListBox)
]]
function methods:RestoreState()
    mixin.FCMControl.RestoreState(self)

    self:Clear__()
    for _, str in ipairs(private[self].Items) do
        temp_str.LuaString = str
        self:AddString__(temp_str)
    end

    self:SetSelectedItem__(private[self].SelectedItem)
end

--[[
% Clear

**[Fluid] [Override]**

Override Changes:
- Ensures that `SelectionChange` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlListBox)
]]
function methods:Clear()
    if not mixin.FCMControl.UseStoredState(self) then
        self:Clear__()
    end

    private[self].Items = {}

    for v in each_last_selection_change(self) do
        if v.last_item >= 0 then
            v.is_deleted = true
        end
    end

    trigger_selection_change(self)
end

--[[
% GetCount

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlListBox)
: (number)
]]
function methods:GetCount()
    if mixin.FCMControl.UseStoredState(self) then
        return #private[self].Items
    end

    return self:GetCount__()
end

--[[
% GetSelectedItem

**[Override]**

Override Changes:
- Hooks into control state preservation.

@ self (FCMCtrlListBox)
: (number)
]]
function methods:GetSelectedItem()
    if mixin.FCMControl.UseStoredState(self) then
        return private[self].SelectedItem
    end

    return self:GetSelectedItem__()
end

--[[
% SetSelectedItem

**[Fluid] [Override]**

Override Changes:
- Ensures that `SelectionChange` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlListBox)
@ index (number)
]]
function methods:SetSelectedItem(index)
    mixin_helper.assert_argument_type(2, index, "number")

    if mixin.FCMControl.UseStoredState(self) then
        private[self].SelectedItem = index
    else
        self:SetSelectedItem__(index)
    end

    trigger_selection_change(self)
end

--[[
% SetSelectedLast

**[Override]**

Override Changes:
- Ensures that `SelectionChange` event is triggered.
- Hooks into control state preservation.

@ self (FCMCtrlListBox)
: (boolean) `true` if a selection was possible.
]]
function methods:SetSelectedLast()
    local return_value

    if mixin.FCMControl.UseStoredState(self) then
        local count = mixin.FCMCtrlListBox.GetCount(self)
        mixin.FCMCtrlListBox.SetSelectedItem(self, count - 1)
        return_value = count > 0 and true or false
    else
        return_value = self:SetSelectedLast__()
    end

    trigger_selection_change(self)
    return return_value
end

--[[
% HasSelection

Checks if the popup has a selection. If the parent window does not exist (ie `WindowExists() == false`), this result is theoretical.

@ self (FCMCtrlListBox)
: (boolean) `true` if something is selected, `false` if no selection.
]]
function methods:HasSelection()
    return mixin.FCMCtrlListBox.GetSelectedItem(self) >= 0
end

--[[
% ItemExists

Checks if there is an item at the specified index.

@ self (FCMCtrlListBox)
@ index (number) 0-based item index.
: (boolean) `true` if the item exists, `false` if it does not exist.
]]
function methods:ItemExists(index)
    mixin_helper.assert_argument_type(2, index, "number")

    return private[self].Items[index + 1] and true or false
end

--[[
% AddString

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.
- Hooks into control state preservation.

@ self (FCMCtrlListBox)
@ str (FCString | string | number)
]]
function methods:AddString(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    str = mixin_helper.to_fcstring(str, temp_str)

    if not mixin.FCMControl.UseStoredState(self) then
        self:AddString__(str)
    end

    -- Since we've made it here without errors, str must be an FCString
    table.insert(private[self].Items, str.LuaString)
end

--[[
% AddStringLocalized

**[Fluid]**

Localized version of `AddString`.

@ self (FCMCtrlListBox)
@ key (string | FCString, number) The key into the localization table. If there is no entry in the appropriate localization table, the key is the text.
]]
methods.AddStringLocalized = mixin_helper.create_localized_proxy("AddString")

--[[
% AddStrings

**[Fluid]**

Adds multiple strings to the list box.

@ self (FCMCtrlListBox)
@ ... (FCStrings | FCString | string | number)
]]
function methods:AddStrings(...)
    mixin_helper.process_string_arguments(self, mixin.FCMCtrlListBox.AddString, ...)
end

--[[
% AddStringsLocalized

**[Fluid]**

Adds multiple localized strings to the combobox.

@ self (FCMCtrlListBox)
@ ... (FCStrings | FCString | string | number) keys of strings to be added. If no localization is found, the key is added.
]]
function methods:AddStringsLocalized(...)
    mixin_helper.process_string_arguments(self, mixin.FCMCtrlComboBox.AddStringLocalized, ...)
end

--[[
% GetStrings

**[?Fluid]**

Returns a copy of all strings in the list box.

@ self (FCMCtrlListBox)
@ [strs] (FCStrings) An optional `FCStrings` object to populate with strings.
: (table) If `strs` is omitted, a table of strings (1-indexed - beware if accessing by key!).
]]
function methods:GetStrings(strs)
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
- Accepts multiple arguments.
- Accepts `FCString`, Lua `string` or `number` in addition to `FCStrings`.
- Hooks into control state preservation.

@ self (FCMCtrlListBox)
@ ... (FCStrings | FCString | string | number) `number`s will be automatically cast to `string`
]]
function methods:SetStrings(...)
    for i = 1, select("#", ...) do
        mixin_helper.assert_argument_type(i + 1, select(i, ...), "FCStrings", "FCString", "string", "number")
    end

    local strs = select(1, ...)
    if select("#", ...) ~= 1 or not mixin_helper.is_instance_of(strs, "FCStrings") then
        strs = mixin.FCMStrings()
        strs:AddCopies(...)
    end

    if not mixin.FCMControl.UseStoredState(self) then
        self:SetStrings__(strs)
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

Returns the text for an item in the list box.
This method works in all JW/RGP Lua versions and irrespective of whether `InitWindow` has been called.

@ self (FCMCtrlListBox)
@ index (number) 0-based index of item.
@ [str] (FCString) Optional `FCString` object to populate with text.
: (string) Returned if `str` is omitted.
]]
function methods:GetItemText(index, str)
    mixin_helper.assert_argument_type(2, index, "number")
    mixin_helper.assert_argument_type(3, str, "nil", "FCString")

    if not mixin.FCMCtrlListBox.ItemExists(self, index) then
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

**[Fluid] [Override]**

Override Changes:
- Added polyfill for JWLua.
- Is valid irrespective of whether `InitWindow` has been called.
- Hooks into control state preservation.

@ self (FCMCtrlListBox)
@ index (number) 0-based index of item.
@ str (FCString | string | number)
]]
function methods:SetItemText(index, str)
    mixin_helper.assert_argument_type(2, index, "number")
    mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")

    if not private[self].Items[index + 1] then
        error("No item at index " .. tostring(index), 2)
    end

    str = mixin_helper.to_fcstring(str, temp_str)

    -- If the text is the same, then there is nothing to do
    if private[self].Items[index + 1] == str then
        return
    end

    private[self].Items[index + 1] = str.LuaString

    if not mixin.FCMControl.UseStoredState(self) then
        -- SetItemText was added to RGPLua in v0.56 and only works once the window has been created
        if self.SetItemText__ and self:GetParent():WindowExists__() then
            self:SetItemText__(index, str)

        -- Otherwise, use a polyfill
        else
            local curr_item = mixin.FCMCtrlListBox.GetSelectedItem(self)
            self:SetStrings__(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
            self:SetSelectedItem__(curr_item)
        end
    end
end

--[[
% GetSelectedString

**[?Fluid]**

Returns the text for the item that is currently selected.

@ self (FCMCtrlListBox)
@ [str] (FCString) Optional `FCString` object to populate with text. If no item is currently selected, it will be populated with an empty string.
: (string | nil) Returned if `str` is omitted. `nil` if no item is selected.
]]
function methods:GetSelectedString(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    local index = mixin.FCMCtrlListBox.GetSelectedItem(self)

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
If no match is found, the current selected item will remain selected. Matches are case-sensitive.

@ self (FCMCtrlListBox)
@ str (FCString | string | number)
]]
function methods:SetSelectedString(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    str = type(str) == "userdata" and str.LuaString or tostring(str)

    for k, v in ipairs(private[self].Items) do
        if str == v then
            mixin.FCMCtrlListBox.SetSelectedItem(self, k - 1)
            return
        end
    end
end

--[[
% InsertItem

**[Fluid] [PDKPort]**

Inserts a string at the specified index.
If index is <= 0, will insert at the start.
If index is >= GetCount(), will insert at the end.

@ self (FCMCtrlListBox)
@ index (number) 0-based index to insert new item.
@ str (FCString | string | number) The value to insert.
]]
function methods:InsertItem(index, str)
    mixin_helper.assert_argument_type(2, index, "number")
    mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")

    if index < 0 then
        index = 0
    elseif index >= mixin.FCMCtrlListBox.GetCount(self) then
        mixin.FCMCtrlListBox.AddString(self, str)
        return
    end

    table.insert(private[self].Items, index + 1, type(str) == "userdata" and str.LuaString or tostring(str))

    local current_selection = mixin.FCMCtrlListBox.GetSelectedItem(self)

    if not mixin.FCMControl.UseStoredState(self) then
        self:SetStrings__(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
    end

    local new_selection = current_selection + (index <= current_selection and 1 or 0)
    mixin.FCMCtrlListBox.SetSelectedItem(self, new_selection)

    for v in each_last_selection_change(self) do
        if v.last_item >= index then
            v.last_item = v.last_item + 1
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
function methods:DeleteItem(index)
    mixin_helper.assert_argument_type(2, index, "number")

    if index < 0 or index >= mixin.FCMCtrlListBox.GetCount(self) then
        return
    end

    table.remove(private[self].Items, index + 1)
    
    local current_selection = mixin.FCMCtrlListBox.GetSelectedItem(self)

    if not mixin.FCMControl.UseStoredState(self) then
        self:SetStrings__(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
    end

    local new_selection
    if index < current_selection then
        new_selection = current_selection - 1
    elseif index == current_selection then
        new_selection = -1
    else
        new_selection = current_selection
    end

    mixin.FCMCtrlListBox.SetSelectedItem(self, new_selection)

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
methods.AddHandleSelectionChange, methods.RemoveHandleSelectionChange, trigger_selection_change, each_last_selection_change = mixin_helper.create_custom_control_change_event(
    {
        name = "last_item",
        get = function(ctrl)
            return mixin.FCMCtrlListBox.GetSelectedItem(ctrl)
        end,
        initial = -1,
    }, {
        name = "last_item_text",
        get = function(ctrl)
            return mixin.FCMCtrlListBox.GetSelectedString(ctrl) or ""
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

return class

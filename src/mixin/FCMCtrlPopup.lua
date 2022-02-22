--[[
$module FCMCtrlPopup
]]

local mixin = require("library.mixin")
local utils = require("library.utils")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local temp_str = finale.FCString()
local handle_selection_change_windows = {}

local function init_handle_selection_change(window)
    if handle_selection_change_windows[window] then
        return
    end

    window:AddHandleCommand(function(control)
        if not private[control] then
            return
        end

        local item = control:GetSelectedItem()
        local text = control:GetSelectedString() or ""

        for _, v in ipairs(private[control].HandleSelectionChange) do
            local history = private[control].HandleSelectionChangeHistory[v]

            if history.IsDeleted or history.Item ~= item or history.Text ~= text then
                v(control, history.Item, history.Text, history.IsDeleted)

                item = control:GetSelectedItem()
                text = control:GetSelectedString() or ""
                history.Item = item
                history.Text = text
                history.IsDeleted = false
            end
        end
    end)

    handle_selection_change_windows[window] = true
end


--[[
% Init

**[Internal]**

@ self (FCMCtrlPopup)
]]
function props:Init()
    private[self] = private[self] or {Index = {}, HandleSelectionChange = {}, HandleSelectionChangeHistory = {}}
end

--[[
% Clear

**[Fluid] [Override]**

@ self (FCMCtrlPopup)
]]
function props:Clear()
    self:Clear_()
    private[self].Index = {}

    for _, v in pairs(private[self].HandleSelectionChangeHistory) do
        if v.Item >= 0 then
            v.IsDeleted = true
        end
    end

    -- Clearing the control doesn't trigger an event, so we need to do it manually
    -- Since SelectionChange events are bootstrapped to Command events, this will flow on
    local parent = self:GetParent()
    if parent then
        parent:TriggerHandleCommand(self)
    end
end

--[[
% AddString

**[Fluid] [Override]**

Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMCtrlPopup)
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
    table.insert(private[self].Index, str.LuaString)
end

--[[
% GetStrings

Returns a copy of all strings in the popup.

@ self (FCMCtrlPopup)
@ [strs] (FCStrings) An optional `FCStrings` object to populate with strings.
: (table) A table of strings (1-indexed - beware if accessing keys!).
]]
function props:GetStrings(strs)
    mixin.assert_argument(strs, {"nil", "FCStrings"}, 2)

    if strs then
        strs:ClearAll()
        for _, v in ipairs(private[self].Index) do
            temp_str.LuaString = v
            strs:AddCopy(temp_str)
        end
    end

    return utils.copy_table(private[self].Index)
end

--[[
% SetStrings

**[Fluid] [Override]**
Accepts a `table` of Lua `string`s or `number`s in addition to `FCStrings`.

@ self (FCMCtrlPopup)
@ strs (FCStrings|table) If table, should only contain `string` or `number`.
]]
function props:SetStrings(strs)
    mixin.assert_argument(strs, {"table", "FCStrings"}, 2)

    if type(strs) ~= "userdata" then
        local temp = mixin.FCMStrings()
        for _, v in ipairs(strs) do
            temp:AddCopy(v)
        end

        strs = temp
    end

    self:SetStrings_(strs)

    private[self].Index = {}
    for str in each(strs) do
        table.insert(private[self].Index, str.LuaString)
    end

    for _, v in pairs(private[self].HandleSelectionChangeHistory) do
        if v.Item >= 0 then
            v.IsDeleted = true
        end
    end
end

--[[
% GetItemText

Returns the text for an item in the popup.

@ self (FCMCtrlPopup)
@ index (number) 0-based index of item.
@ [str] (FCString) Optional `FCString` object to populate with text.
: (string)
]]
function props:GetItemText(index, str)
    mixin.assert_argument(index, "number", 2)
    mixin.assert_argument(str, {"nil", "FCString"}, 3)

    if not private[self].Index[index + 1] then
        error("No item at index " .. tostring(index), 2)
    end

    if str then
        str.LuaString = private[self].Index[index + 1] or ""
    end

    return private[self].Index[index + 1]
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

    if not private[self].Index[index + 1] then
        error("No item at index " .. tostring(index), 2)
    end

    private[self].Index[index + 1] = type(str) == "userdata" and str.LuaString or tostring(str)

    local strs = finale.FCStrings()
    for _, v in ipairs(private[self].Index) do
        temp_str.LuaString = v
        strs:AddCopy(temp_str)
    end

    local curr_item = self:GetSelectedItem()
    self:SetStrings_(strs)
    self:SetSelectedItem(curr_item)
end

--[[
% GetSelectedString

Returns the text for the item that is currently selected.

@ self (FCMCtrlPopup)
@ [str] (FCString) Optional `FCString` object to populate with text. If no item is currently selected, it will be populated with an empty string.
: (string|nil) `nil` if no item ia currently selected.
]]
function props:GetSelectedString(str)
    mixin.assert_argument(str, {"nil", "FCString"}, 2)

    local index = self:GetSelectedItem()

    if index ~= -1 then
        if str then
            str.LuaString = private[self].Index[index + 1]
        end

        return private[self].Index[index + 1]
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

@ self (FCMCtrlPopup)
@ str (FCString|string|number)
]]
function props:SetSelectedString(str)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    str = type(str) == "userdata" and str.LuaString or tostring(str)

    for k, v in ipairs(private[self].Index) do
        if str == v then
            self:SetSelectedItem(k - 1)
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
    elseif index >= #private[self].Index then
        self:AddString(str)
        return
    end

    table.insert(private[self].Index, index + 1, type(str) == "userdata" and str.LuaString or tostring(str))

    local strs = finale.FCStrings()
    for _, v in ipairs(private[self].Index) do
        temp_str.LuaString = v
        strs:AddCopy(temp_str)
    end

    local curr_item = self:GetSelectedItem()
    self:SetStrings_(strs)

    if curr_item >= index then
        self:SetSelectedItem(curr_item + 1)
    else
        self:SetSelectedItem(curr_item)
    end

    for _, v in pairs(private[self].HandleSelectionChangeHistory) do
        if v.Item >= index then
            v.Item = v.Item + 1
        end
    end
end

--[[
% DeleteItem

**[Fluid] [PDK Port]**
Deletes an item from the popup.
If the currently selected item is deleted, items will be deselected (ie set to -1

@ self (FCMCtrlPopup)
@ index (number) 0-based index of item to delete.
]]
function props:DeleteItem(index)
    mixin.assert_argument(index, "number", 2)

    if index < 0 or index >= #private[self].Index then
        return
    end

    table.remove(private[self].Index, index + 1)

    local strs = finale.FCStrings()
    for _, v in ipairs(private[self].Index) do
        temp_str.LuaString = v
        strs:AddCopy(temp_str)
    end

    local curr_item = self:GetSelectedItem()
    self:SetStrings_(strs)

    if curr_item > index then
        self:SetSelectedItem(curr_item - 1)
    elseif curr_item == index then
        self:SetSelectedItem(-1)
    else
        self:SetSelectedItem(curr_item)
    end

    for _, v in pairs(private[self].HandleSelectionChangeHistory) do
        if v.Item == index then
            v.IsDeleted = true
        elseif v.Item > index then
            v.Item = v.Item - 1
        end
    end

    -- Trigger event
    local parent = self:GetParent()
    if parent then
        parent:TriggerHandleCommand(self)
    end
end

--[[
% AddHandleSelectionChange

**[Fluid]**
Adds a handler for selection change events.
If the selected item is changed by a handler, that same handler will not be called again for that change.

The event will fire in the following cases:
- Change in selected item (inserting an item before or after will not trigger the event)
- Changing the text value of an item
- Deleting an item

`last_item` is the index of the previously selected item.
`last_item_text` is the text string of the above item.
`is_deleted` is a flag for whether the item has been deleted (ie if there is an item currently at that index, it isn't the same item).

@ self (FCMCtrlPopup)
@ func (function) Handler with the signature `func((FCMCtrlPopup) control, (number) last_item, (string) last_item_text, (boolean) is_deleted)`
]]
function props:AddHandleSelectionChange(func)
    mixin.assert_argument(func, "function", 2)
    local parent = self:GetParent()
    mixin.assert(parent, "Cannot add handler to control with no parent window.")
    mixin.assert((parent.MixinBase or parent.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
    mixin.force_assert(private[self].HandleSelectionChangeHistory[func] == nil, "The callback has already been added as a change handler.")

    init_handle_selection_change(parent)
    private[self].HandleSelectionChangeHistory[func] = {Item = parent:WindowExists() and self:GetSelectedItem() or -1, Text = parent:WindowExists() and self:GetSelectedString() or "", IsDeleted = false}
    table.insert(private[self].HandleSelectionChange, func)
end

--[[
% RemoveHandleSelectionChange

**[Fluid]**
Removes a handler added with `AddHandleSelectionChange`.

@ self (FCMCtrlPopup)
@ func (function) Handler to remove.
]]
function props:RemoveHandleSelectionChange(func)
    mixin.assert_argument(func, "function", 2)

    utils.table_remove_first(private[self].HandleSelectionChange, func)
    private[self].HandleSelectionChangeHistory[func] = nil
end


return props
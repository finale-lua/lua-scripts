package.preload["mixin.FCMControl"] = package.preload["mixin.FCMControl"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})

    local parent = setmetatable({}, {__mode = "kv"})
    local temp_str = finale.FCString()

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {}
    end

    function methods:GetParent()
        return parent[self]
    end

    function methods:RegisterParent(window)
        mixin_helper.assert_argument_type(2, window, "FCMCustomWindow", "FCMCustomLuaWindow")
        if parent[self] then
            error("This method is for internal use only.", 2)
        end
        parent[self] = window
    end












    for method, valid_types in pairs({
        Enable = {"boolean", "nil"},
        Visible = {"boolean", "nil"},
        Left = {"number"},
        Top = {"number"},
        Height = {"number"},
        Width = {"number"},
    }) do
        methods["Get" .. method] = function(self)
            if mixin.FCMControl.UseStoredState(self) then
                return private[self][method]
            end
            return self["Get" .. method .. "__"](self)
        end
        methods["Set" .. method] = function(self, value)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            if mixin.FCMControl.UseStoredState(self) then
                private[self][method] = value
            else

                if (method == "Enable" or method == "Visible") and finenv.UI():IsOnMac() and finenv.MajorVersion == 0 and finenv.MinorVersion < 63 then
                    self:GetText__(temp_str)
                    self:SetText__(temp_str)
                end
                self["Set" .. method .. "__"](self, value)
            end
        end
    end

    function methods:GetText(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local do_return = false
        if not str then
            str = temp_str
            do_return = true
        end
        if mixin.FCMControl.UseStoredState(self) then
            str.LuaString = private[self].Text
        else
            self:GetText__(str)
        end
        if do_return then
            return str.LuaString
        end
    end

    function methods:SetText(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        if mixin.FCMControl.UseStoredState(self) then
            private[self].Text = str.LuaString
        else
            self:SetText__(str)
        end
    end

    function methods:UseStoredState()
        local parent = self:GetParent()
        return mixin_helper.is_instance_of(parent, "FCMCustomLuaWindow") and parent:GetRestoreControlState() and not parent:WindowExists() and parent:HasBeenShown()
    end

    function methods:StoreState()
        self:GetText__(temp_str)
        private[self].Text = temp_str.LuaString
        private[self].Enable = self:GetEnable__()
        private[self].Visible = self:GetVisible__()
        private[self].Height = self:GetHeight__()
        private[self].Width = self:GetWidth__()
        private[self].Left = self:GetLeft__()
        private[self].Top = self:GetTop__()
    end

    function methods:RestoreState()
        self:SetEnable__(private[self].Enable)
        self:SetVisible__(private[self].Visible)
        self:SetHeight__(private[self].Height)
        self:SetWidth__(private[self].Width)
        self:SetLeft__(private[self].Left)
        self:SetTop__(private[self].Top)

        temp_str.LuaString = private[self].Text
        self:SetText__(temp_str)
    end


    methods.AddHandleCommand, methods.RemoveHandleCommand = mixin_helper.create_standard_control_event("HandleCommand")

    methods.SetTextLocalized = mixin_helper.create_localized_proxy("SetText", "FCMControl")
    return class
end
package.preload["mixin.FCMCtrlButton"] = package.preload["mixin.FCMCtrlButton"] or function()



    local class = {}
    class.Disabled = {"AddHandleCheckChange", "RemoveHandleCheckChange"}
    return class
end
package.preload["mixin.FCMCtrlCheckbox"] = package.preload["mixin.FCMCtrlCheckbox"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local trigger_check_change
    local each_last_check_change

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {
            Check = 0,
        }
    end

    function methods:GetCheck()
        if mixin.FCMControl.UseStoredState(self) then
            return private[self].Check
        end
        return self:GetCheck__()
    end

    function methods:SetCheck(checked)
        mixin_helper.assert_argument_type(2, checked, "number")
        if mixin.FCMControl.UseStoredState(self) then
            private[self].Check = checked
        else
            self:SetCheck__(checked)
        end
        trigger_check_change(self)
    end



    methods.AddHandleCheckChange, methods.RemoveHandleCheckChange, trigger_check_change, each_last_check_change = mixin_helper.create_custom_control_change_event(


        {
            name = "last_check",
            get = "GetCheck__",
            initial = 0,
        }
    )

    function methods:StoreState()
        mixin.FCMControl.StoreState(self)
        private[self].Check = self:GetCheck__()
    end

    function methods:RestoreState()
        mixin.FCMControl.RestoreState(self)
        self:SetCheck__(private[self].Check)
    end
    return class
end
package.preload["mixin.FCMCtrlComboBox"] = package.preload["mixin.FCMCtrlComboBox"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local temp_str = finale.FCString()

    function methods:AddString(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        self:AddString__(str)
    end

    methods.AddStringLocalized = mixin_helper.create_localized_proxy("AddString")

    methods.AddStrings = mixin_helper.create_multi_string_proxy("AddString")

    methods.AddStringsLocalized = mixin_helper.create_multi_string_proxy("AddStringLocalized")
    return class
end
package.preload["mixin.FCMCtrlDataList"] = package.preload["mixin.FCMCtrlDataList"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local temp_str = finale.FCString()

    function methods:AddColumn(title, columnwidth)
        mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
        mixin_helper.assert_argument_type(3, columnwidth, "number")
        self:AddColumn__(mixin_helper.to_fcstring(title, temp_str), columnwidth)
    end

    function methods:SetColumnTitle(columnindex, title)
        mixin_helper.assert_argument_type(2, columnindex, "number")
        mixin_helper.assert_argument_type(3, title, "string", "number", "FCString")
        self:SetColumnTitle__(columnindex, mixin_helper.to_fcstring(title, temp_str))
    end


    methods.AddHandleCheck, methods.RemoveHandleCheck = mixin_helper.create_standard_control_event("HandleDataListCheck")


    methods.AddHandleSelect, methods.RemoveHandleSelect = mixin_helper.create_standard_control_event("HandleDataListSelect")
    return class
end
package.preload["mixin.FCMCtrlEdit"] = package.preload["mixin.FCMCtrlEdit"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local class = {Methods = {}}
    local methods = class.Methods
    local trigger_change
    local each_last_change
    local temp_str = mixin.FCMString()

    function methods:SetText(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        mixin.FCMControl.SetText(self, str)
        trigger_change(self)
    end




    for method, valid_types in pairs({
        Integer = {"number"},
        Float = {"number"},
    }) do
        methods["Get" .. method] = function(self)

            mixin.FCMControl.GetText(self, temp_str)
            return temp_str["Get" .. method](temp_str, 0)
        end
        methods["Set" .. method] = function(self, value)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            temp_str["Set" .. method](temp_str, value)
            mixin.FCMControl.SetText(self, temp_str)
            trigger_change(self)
        end
    end












    for method, valid_types in pairs({
        Measurement = {"number"},
        MeasurementEfix = {"number"},
        MeasurementInteger = {"number"},
        Measurement10000th = {"number"},
    }) do
        methods["Get" .. method] = function(self, measurementunit)
            mixin_helper.assert_argument_type(2, measurementunit, "number")
            mixin.FCMControl.GetText(self, temp_str)
            return temp_str["Get" .. method](temp_str, measurementunit)
        end
        methods["GetRange" .. method] = function(self, measurementunit, minimum, maximum)
            mixin_helper.assert_argument_type(2, measurementunit, "number")
            mixin_helper.assert_argument_type(3, minimum, "number")
            mixin_helper.assert_argument_type(4, maximum, "number")
            mixin.FCMControl.GetText(self, temp_str)
            return temp_str["GetRange" .. method](temp_str, measurementunit, minimum, maximum)
        end
        methods["Set" .. method] = function(self, value, measurementunit)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            mixin_helper.assert_argument_type(3, measurementunit, "number")
            temp_str["Set" .. method](temp_str, value, measurementunit)
            mixin.FCMControl.SetText(self, temp_str)
            trigger_change(self)
        end
    end

    function methods:GetRangeInteger(minimum, maximum)
        mixin_helper.assert_argument_type(2, minimum, "number")
        mixin_helper.assert_argument_type(3, maximum, "number")
        return utils.clamp(mixin.FCMCtrlEdit.GetInteger(self), math.ceil(minimum), math.floor(maximum))
    end



    methods.AddHandleChange, methods.RemoveHandleChange, trigger_change, each_last_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_value",
            get = mixin.FCMControl.GetText,
            initial = ""
        }
    )
    return class
end
package.preload["mixin.FCMCtrlListBox"] = package.preload["mixin.FCMCtrlListBox"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local trigger_selection_change
    local each_last_selection_change
    local temp_str = finale.FCString()

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {
            Items = {},
        }
    end

    function methods:StoreState()
        mixin.FCMControl.StoreState(self)
        private[self].SelectedItem = self:GetSelectedItem__()
    end

    function methods:RestoreState()
        mixin.FCMControl.RestoreState(self)
        self:Clear__()
        for _, str in ipairs(private[self].Items) do
            temp_str.LuaString = str
            self:AddString__(temp_str)
        end
        self:SetSelectedItem__(private[self].SelectedItem)
    end

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

    function methods:GetCount()
        if mixin.FCMControl.UseStoredState(self) then
            return #private[self].Items
        end
        return self:GetCount__()
    end

    function methods:GetSelectedItem()
        if mixin.FCMControl.UseStoredState(self) then
            return private[self].SelectedItem
        end
        return self:GetSelectedItem__()
    end

    function methods:SetSelectedItem(index)
        mixin_helper.assert_argument_type(2, index, "number")
        if mixin.FCMControl.UseStoredState(self) then
            private[self].SelectedItem = index
        else
            self:SetSelectedItem__(index)
        end
        trigger_selection_change(self)
    end

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

    function methods:HasSelection()
        return mixin.FCMCtrlListBox.GetSelectedItem(self) >= 0
    end

    function methods:ItemExists(index)
        mixin_helper.assert_argument_type(2, index, "number")
        return private[self].Items[index + 1] and true or false
    end

    function methods:AddString(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        if not mixin.FCMControl.UseStoredState(self) then
            self:AddString__(str)
        end

        table.insert(private[self].Items, str.LuaString)
    end

    methods.AddStringLocalized = mixin_helper.create_localized_proxy("AddString")

    methods.AddStrings = mixin_helper.create_multi_string_proxy("AddString")

    methods.AddStringsLocalized = mixin_helper.create_multi_string_proxy("AddStringLocalized")

    function methods:GetStrings(strs)
        mixin_helper.assert_argument_type(2, strs, "nil", "FCStrings")
        if strs then
            mixin.FCMStrings.CopyFromStringTable(strs, private[self].Items)
        else
            return utils.copy_table(private[self].Items)
        end
    end

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

        private[self].Items = mixin.FCMStrings.CreateStringTable(strs)
        for v in each_last_selection_change(self) do
            if v.last_item >= 0 then
                v.is_deleted = true
            end
        end
        trigger_selection_change(self)
    end

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

    function methods:SetItemText(index, str)
        mixin_helper.assert_argument_type(2, index, "number")
        mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")
        if not private[self].Items[index + 1] then
            error("No item at index " .. tostring(index), 2)
        end
        str = mixin_helper.to_fcstring(str, temp_str)

        if private[self].Items[index + 1] == str then
            return
        end
        private[self].Items[index + 1] = str.LuaString
        if not mixin.FCMControl.UseStoredState(self) then

            if self.SetItemText__ and self:GetParent():WindowExists__() then
                self:SetItemText__(index, str)

            else
                local curr_item = mixin.FCMCtrlListBox.GetSelectedItem(self)
                self:SetStrings__(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
                self:SetSelectedItem__(curr_item)
            end
        end
    end

    function methods:GetSelectedString(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local index = mixin.FCMCtrlListBox.GetSelectedItem(self)
        if str then
            str.LuaString = index ~= -1 and private[self].Items[index + 1] or ""
        else
            return index ~= -1 and private[self].Items[index + 1] or nil
        end
    end

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

        if index == current_selection then
            trigger_selection_change(self)
        end
    end



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
end
package.preload["mixin.FCMCtrlPopup"] = package.preload["mixin.FCMCtrlPopup"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local trigger_selection_change
    local each_last_selection_change
    local temp_str = finale.FCString()

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {
            Items = {},
        }
    end

    function methods:StoreState()
        mixin.FCMControl.StoreState(self)
        private[self].SelectedItem = self:GetSelectedItem__()
    end

    function methods:RestoreState()
        mixin.FCMControl.RestoreState(self)
        self:Clear__()
        for _, str in ipairs(private[self].Items) do
            temp_str.LuaString = str
            self:AddString__(temp_str)
        end
        self:SetSelectedItem__(private[self].SelectedItem)
    end

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

    function methods:GetCount()
        if mixin.FCMControl.UseStoredState(self) then
            return #private[self].Items
        end
        return self:GetCount__()
    end

    function methods:GetSelectedItem()
        if mixin.FCMControl.UseStoredState(self) then
            return private[self].SelectedItem
        end
        return self:GetSelectedItem__()
    end

    function methods:SetSelectedItem(index)
        mixin_helper.assert_argument_type(2, index, "number")
        if mixin.FCMControl.UseStoredState(self) then
            private[self].SelectedItem = index
        else
            self:SetSelectedItem__(index)
        end
        trigger_selection_change(self)
    end

    function methods:SetSelectedLast()
        mixin.FCMCtrlPopup.SetSelectedItem(self, mixin.FCMCtrlPopup.GetCount(self) - 1)
    end

    function methods:HasSelection()
        return mixin.FCMCtrlPopup.GetSelectedItem(self) >= 0
    end

    function methods:ItemExists(index)
        mixin_helper.assert_argument_type(2, index, "number")
        return private[self].Items[index + 1] and true or false
    end

    function methods:AddString(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        if not mixin.FCMControl.UseStoredState(self) then
            self:AddString__(str)
        end

        table.insert(private[self].Items, str.LuaString)
    end

    methods.AddStringLocalized = mixin_helper.create_localized_proxy("AddString")

    methods.AddStrings = mixin_helper.create_multi_string_proxy("AddString")

    methods.AddStringsLocalized = mixin_helper.create_multi_string_proxy("AddStringLocalized")

    function methods:GetStrings(strs)
        mixin_helper.assert_argument_type(2, strs, "nil", "FCStrings")
        if strs then
            mixin.FCMStrings.CopyFromStringTable(strs, private[self].Items)
        else
            return utils.copy_table(private[self].Items)
        end
    end

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

        private[self].Items = mixin.FCMStrings.CreateStringTable(strs)
        for v in each_last_selection_change(self) do
            if v.last_item >= 0 then
                v.is_deleted = true
            end
        end
        trigger_selection_change(self)
    end

    function methods:GetItemText(index, str)
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

    function methods:SetItemText(index, str)
        mixin_helper.assert_argument_type(2, index, "number")
        mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")
        if not mixin.FCMCtrlPopup.ItemExists(self, index) then
            error("No item at index " .. tostring(index), 2)
        end
        str = type(str) == "userdata" and str.LuaString or tostring(str)

        if private[self].Items[index + 1] == str then
            return
        end
        private[self].Items[index + 1] = str
        if not mixin.FCMControl.UseStoredState(self) then
            local curr_item = self:GetSelectedItem_()
            self:SetStrings__(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
            self:SetSelectedItem__(curr_item)
        end
    end

    function methods:GetSelectedString(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local index = mixin.FCMCtrlPopup.GetSelectedItem(self)
        if str then
            str.LuaString = index ~= -1 and private[self].Items[index + 1] or ""
        else
            return index ~= -1 and private[self].Items[index + 1] or nil
        end
    end

    function methods:SetSelectedString(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = type(str) == "userdata" and str.LuaString or tostring(str)
        for k, v in ipairs(private[self].Items) do
            if str == v then
                mixin.FCMCtrlPopup.SetSelectedItem(self, k - 1)
                return
            end
        end
    end

    function methods:InsertString(index, str)
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
            self:SetStrings__(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
        end
        local new_selection = current_selection + (index <= current_selection and 1 or 0)
        mixin.FCMCtrlPopup.SetSelectedItem(self, new_selection)
        for v in each_last_selection_change(self) do
            if v.last_item >= index then
                v.last_item = v.last_item + 1
            end
        end
    end

    function methods:DeleteItem(index)
        mixin_helper.assert_argument_type(2, index, "number")
        if index < 0 or index >= mixin.FCMCtrlPopup.GetCount(self) then
            return
        end
        table.remove(private[self].Items, index + 1)
        local current_selection = mixin.FCMCtrlPopup.GetSelectedItem(self)
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
        mixin.FCMCtrlPopup.SetSelectedItem(self, new_selection)
        for v in each_last_selection_change(self) do
            if v.last_item == index then
                v.is_deleted = true
            elseif v.last_item > index then
                v.last_item = v.last_item - 1
            end
        end

        if index == current_selection then
            trigger_selection_change(self)
        end
    end



    methods.AddHandleSelectionChange, methods.RemoveHandleSelectionChange, trigger_selection_change, each_last_selection_change = mixin_helper.create_custom_control_change_event(
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
    return class
end
package.preload["mixin.FCMCtrlSlider"] = package.preload["mixin.FCMCtrlSlider"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local windows = setmetatable({}, {__mode = "k"})
    local trigger_thumb_position_change
    local each_last_thumb_position_change
    local function bootstrap_command()

        trigger_thumb_position_change(true)
    end
    local function bootstrap_timer(timerid, window)

        trigger_thumb_position_change(true, true)
    end
    local bootstrap_timer_first

    bootstrap_timer_first = function(timerid, window)
        window:RemoveHandleCommand(bootstrap_command)
        window:RemoveHandleTimer(timerid, bootstrap_timer_first)
        window:AddHandleTimer(timerid, bootstrap_timer)
        bootstrap_timer(timerid, window)
    end

    function methods:RegisterParent(window)
        mixin.FCMControl.RegisterParent(self, window)
        if finenv.MajorVersion == 0 and finenv.MinorVersion < 64 and not windows[window] and mixin_helper.is_instance_of(window, "FCMCustomLuaWindow") then

            window:AddHandleCommand(bootstrap_command)
            if window.SetTimer_ then

                window:AddHandleTimer(window:SetNextTimer(1000), bootstrap_timer_first)
            end
            windows[window] = true
        end
    end

    function methods:SetThumbPosition(position)
        mixin_helper.assert_argument_type(2, position, "number")
        self:SetThumbPosition__(position)
        trigger_thumb_position_change(self)
    end

    function methods:SetMinValue(minvalue)
        mixin_helper.assert_argument_type(2, minvalue, "number")
        self:SetMinValue__(minvalue)
        trigger_thumb_position_change(self)
    end

    function methods:SetMaxValue(maxvalue)
        mixin_helper.assert_argument_type(2, maxvalue, "number")
        self:SetMaxValue__(maxvalue)
        trigger_thumb_position_change(self)
    end



    methods.AddHandleThumbPositionChange, methods.RemoveHandleThumbPositionChange, trigger_thumb_position_change, each_last_thumb_position_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_position",
            get = "GetThumbPosition__",
            initial = -1,
        }
    )
    return class
end
package.preload["mixin.FCMCtrlStatic"] = package.preload["mixin.FCMCtrlStatic"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local temp_str = mixin.FCMString()
    local function get_suffix(unit, suffix_type)
        if suffix_type == 1 then
            return measurement.get_unit_suffix(unit)
        elseif suffix_type == 2 then
            return measurement.get_unit_abbreviation(unit)
        elseif suffix_type == 3 then
            return " " .. string.lower(measurement.get_unit_name(unit))
        end
    end
    local function set_measurement(self, measurementtype, measurementunit, value)
        mixin_helper.force_assert(private[self].MeasurementEnabled or measurementunit, "'measurementunit' can only be omitted if parent window is an instance of 'FCMCustomLuaWindow'", 3)
        private[self].MeasurementAutoUpdate = not measurementunit and true or false
        measurementunit = measurementunit or self:GetParent():GetMeasurementUnit()
        temp_str["Set" .. measurementtype](temp_str, value, measurementunit)
        temp_str:AppendLuaString(private[self].ShowMeasurementSuffix and get_suffix(measurementunit, private[self].MeasurementSuffixType) or "")
        mixin.FCMControl.SetText(self, temp_str)
        private[self].Measurement = value
        private[self].MeasurementType = measurementtype
    end

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {
            ShowMeasurementSuffix = true,
            MeasurementSuffixType = 2,
            MeasurementEnabled = false,
        }
    end

    function methods:RegisterParent(window)
        mixin.FCMControl.RegisterParent(self, window)
        private[self].MeasurementEnabled = mixin_helper.is_instance_of(window, "FCMCustomLuaWindow")
    end

    function methods:SetTextColor(red, green, blue)
        mixin_helper.assert_argument_type(2, red, "number")
        mixin_helper.assert_argument_type(3, green, "number")
        mixin_helper.assert_argument_type(4, blue, "number")
        private[self].TextColor = {red, green, blue}
        if not mixin.FCMControl.UseStoredState(self) then
            self:SetTextColor__(red, green, blue)


            mixin.FCMControl.SetText(self, mixin.FCMControl.GetText(self))
        end
    end

    function methods:RestoreState()
        mixin.FCMControl.RestoreState(self)

        if private[self].TextColor then
            mixin.FCMCtrlStatic.SetTextColor(self, private[self].TextColor[1], private[self].TextColor[2], private[self].TextColor[3])
        end
    end

    function methods:SetText(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        mixin.FCMControl.SetText(self, str)
        private[self].Measurement = nil
        private[self].MeasurementType = nil
    end

    function methods:SetMeasurement(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number", "nil")
        set_measurement(self, "Measurement", measurementunit, value)
    end

    function methods:SetMeasurementInteger(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number", "nil")
        set_measurement(self, "MeasurementInteger", measurementunit, value)
    end

    function methods:SetMeasurementEfix(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number", "nil")
        set_measurement(self, "MeasurementEfix", measurementunit, value)
    end

    function methods:SetMeasurement10000th(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number", "nil")
        set_measurement(self, "Measurement10000th", measurementunit, value)
    end

    function methods:SetShowMeasurementSuffix(enabled)
        mixin_helper.assert_argument_type(2, enabled, "boolean")
        private[self].ShowMeasurementSuffix = enabled and true or false
        mixin.FCMCtrlStatic.UpdateMeasurementUnit(self)
    end

    function methods:SetMeasurementSuffixShort()
        private[self].MeasurementSuffixType = 1
        mixin.FCMCtrlStatic.UpdateMeasurementUnit(self)
    end

    function methods:SetMeasurementSuffixAbbreviated()
        private[self].MeasurementSuffixType = 2
        mixin.FCMCtrlStatic.UpdateMeasurementUnit(self)
    end

    function methods:SetMeasurementSuffixFull()
        private[self].MeasurementSuffixType = 3
        mixin.FCMCtrlStatic.UpdateMeasurementUnit(self)
    end

    function methods:UpdateMeasurementUnit()
        if private[self].Measurement then
            mixin.FCMCtrlStatic["Set" .. private[self].MeasurementType](self, private[self].Measurement)
        end
    end
    return class
end
package.preload["mixin.FCMCtrlSwitcher"] = package.preload["mixin.FCMCtrlSwitcher"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local trigger_page_change
    local each_last_page_change
    local temp_str = finale.FCString()

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {
            Index = {},
            TitleIndex = {},
        }
    end

    function methods:AddPage(title)
        mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
        title = mixin_helper.to_fcstring(title, temp_str)
        self:AddPage__(title)
        table.insert(private[self].Index, title.LuaString)
        private[self].TitleIndex[title.LuaString] = #private[self].Index - 1
    end

    function methods:AddPages(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString")
            mixin.FCMCtrlSwitcher.AddPage(self, v)
        end
    end

    function methods:AttachControl(control, pageindex)
        mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
        mixin_helper.assert_argument_type(3, pageindex, "number")
        mixin_helper.boolean_to_error(self, "AttachControl", control, pageindex)
    end

    function methods:AttachControlByTitle(control, title)
        mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
        mixin_helper.assert_argument_type(3, title, "string", "number", "FCString")
        title = type(title) == "userdata" and title.LuaString or tostring(title)
        local index = private[self].TitleIndex[title] or -1
        mixin_helper.force_assert(index ~= -1, "No page titled '" .. title .. "'")
        mixin.FCMCtrlSwitcher.AttachControl(self, control, index)
    end

    function methods:SetSelectedPage(index)
        mixin_helper.assert_argument_type(2, index, "number")
        self:SetSelectedPage__(index)
        trigger_page_change(self)
    end

    function methods:SetSelectedPageByTitle(title)
        mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
        title = type(title) == "userdata" and title.LuaString or tostring(title)
        local index = private[self].TitleIndex[title] or -1
        mixin_helper.force_assert(index ~= -1, "No page titled '" .. title .. "'")
        mixin.FCMCtrlSwitcher.SetSelectedPage(self, index)
    end

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



    methods.AddHandlePageChange, methods.RemoveHandlePageChange, trigger_page_change, each_last_page_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_page",
            get = "GetSelectedPage__",
            initial = -1
        },
        {
            name = "last_page_title",

            get = function(ctrl)
                return mixin.FCMCtrlSwitcher.GetSelectedPageTitle(ctrl)
            end,
            initial = "",
        }
    )
    return class
end
package.preload["mixin.FCMCtrlTree"] = package.preload["mixin.FCMCtrlTree"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local temp_str = finale.FCString()

    function methods:AddNode(parentnode, iscontainer, text)
        mixin_helper.assert_argument_type(2, parentnode, "nil", "FCTreeNode")
        mixin_helper.assert_argument_type(3, iscontainer, "boolean")
        mixin_helper.assert_argument_type(4, text, "string", "number", "FCString")
        return self:AddNode__(parentnode, iscontainer, mixin_helper.to_fcstring(text, temp_str))
    end
    return class
end
package.preload["mixin.FCMCtrlUpDown"] = package.preload["mixin.FCMCtrlUpDown"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {}
    end

    function methods:GetConnectedEdit()
        return private[self].ConnectedEdit
    end

    function methods:ConnectIntegerEdit(control, minvalue, maxvalue)
        mixin_helper.assert_argument_type(2, control, "FCMCtrlEdit")
        mixin_helper.assert_argument_type(3, minvalue, "number")
        mixin_helper.assert_argument_type(4, maxvalue, "number")
        mixin_helper.boolean_to_error(self, "ConnectIntegerEdit", control, minvalue, maxvalue)

        private[self].ConnectedEdit = control
    end

    function methods:ConnectMeasurementEdit(control, minvalue, maxvalue)
        mixin_helper.assert_argument_type(2, control, "FCMCtrlEdit")
        mixin_helper.assert_argument_type(3, minvalue, "number")
        mixin_helper.assert_argument_type(4, maxvalue, "number")
        mixin_helper.boolean_to_error(self, "ConnectMeasurementEdit", control, minvalue, maxvalue)

        private[self].ConnectedEdit = control
    end


    methods.AddHandlePress, methods.RemoveHandlePress = mixin_helper.create_standard_control_event("HandleUpDownPressed")
    return class
end
package.preload["mixin.FCMCustomLuaWindow"] = package.preload["mixin.FCMCustomLuaWindow"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local measurement = require("library.measurement")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local trigger_measurement_unit_change
    local each_last_measurement_unit_change

    local window_events = {"HandleCancelButtonPressed", "HandleOkButtonPressed", "InitWindow", "CloseWindow"}
    local control_events = {"HandleCommand", "HandleDataListCheck", "HandleDataListSelect", "HandleUpDownPressed"}
    local function flush_custom_queue(self)
        local queue = private[self].HandleCustomQueue
        private[self].HandleCustomQueue = {}
        for _, callback in ipairs(queue) do
            callback()
        end
    end
    local function restore_position(self)
        if private[self].HasBeenShown and private[self].EnableAutoRestorePosition and self.StorePosition then
            self:StorePosition(false)
            self:SetRestorePositionOnlyData__(private[self].StoredX, private[self].StoredY)
            self:RestorePosition()
        end
    end

    local function dispatch_event_handlers(self, event, context, ...)
        local handlers = private[self][event]
        if handlers.Registered then
            handlers.Registered(context, ...)
        end
        for _, handler in ipairs(handlers.Added) do
            handler(context, ...)
        end
    end
    local function create_handle_methods(event)

        methods["Register" .. event] = function(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            private[self][event].Registered = callback
        end
        methods["Add" .. event] = function(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            table.insert(private[self][event].Added, callback)
        end
        methods["Remove" .. event] = function(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            utils.table_remove_first(private[self][event].Added, callback)
        end
    end

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {
            HandleTimer = {},
            HandleCustomQueue = {},
            HasBeenShown = false,
            EnableDebugClose = false,
            RestoreControlState = true,
            EnableAutoRestorePosition = true,
            StoredX = nil,
            StoredY = nil,
            MeasurementUnit = measurement.get_real_default_unit(),
            UseParentMeasurementUnit = true,
        }

        for _, event in ipairs(control_events) do
            private[self][event] = {Added = {}}
            if self["Register" .. event .. "__"] then

                local is_running = false
                self["Register" .. event .. "__"](self, function(control, ...)
                    if is_running then
                        return
                    end
                    is_running = true

                    flush_custom_queue(self)

                    local real_control = self:FindControl(control:GetControlID())
                    if not real_control then
                        error("Control with ID #" .. tostring(control:GetControlID()) .. " not found in '" .. event .. "'")
                    end
                    dispatch_event_handlers(self, event, real_control, ...)

                    while #private[self].HandleCustomQueue > 0 do
                        flush_custom_queue(self)
                    end
                    is_running = false
                end)
            end
        end

        for _, event in ipairs(window_events) do
            private[self][event] = {Added = {}}
            if not self["Register" .. event .. "__"] then
                goto continue
            end
            if event == "InitWindow" then
                self["Register" .. event .. "__"](self, function(...)
                    if private[self].HasBeenShown and private[self].RestoreControlState then
                        for control in each(self) do
                            control:RestoreState()
                        end
                    end
                    dispatch_event_handlers(self, event, self, ...)
                end)
            elseif event == "CloseWindow" then
                self["Register" .. event .. "__"](self, function(...)
                    if private[self].EnableDebugClose and finenv.RetainLuaState ~= nil then
                        if finenv.DebugEnabled and (self:QueryLastCommandModifierKeys(finale.CMDMODKEY_ALT) or self:QueryLastCommandModifierKeys(finale.CMDMODKEY_SHIFT)) then
                            finenv.RetainLuaState = false
                        end
                    end

                    local success, error_msg = pcall(dispatch_event_handlers, self, event, self, ...)
                    if self.StorePosition then
                        self:StorePosition(false)
                        private[self].StoredX = self.StoredX
                        private[self].StoredY = self.StoredY
                    end
                    if private[self].RestoreControlState then
                        for control in each(self) do
                            control:StoreState()
                        end
                    end
                    private[self].HasBeenShown = true
                    if not success then
                        error(error_msg, 0)
                    end
                end)
            else
                self["Register" .. event .. "__"](self, function(...)
                    dispatch_event_handlers(self, event, self, ...)
                end)
            end
            :: continue ::
        end

        if self.RegisterHandleTimer__ then
            self:RegisterHandleTimer__(function(timerid)

                if private[self].HandleTimer.Registered then

                    private[self].HandleTimer.Registered(self, timerid)
                end

                if private[self].HandleTimer[timerid] then
                    for _, callback in ipairs(private[self].HandleTimer[timerid]) do

                        callback(self, timerid)
                    end
                end
            end)
        end
    end












    for _, event in ipairs(control_events) do
        create_handle_methods(event)
    end
















    for _, event in ipairs(window_events) do
        create_handle_methods(event)
    end

    function methods:QueueHandleCustom(callback)
        mixin_helper.assert_argument_type(2, callback, "function")
        table.insert(private[self].HandleCustomQueue, callback)
    end
    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then

        function methods:RegisterHandleControlEvent(control, callback)
            mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
            mixin_helper.assert_argument_type(3, callback, "function")
            if not self:RegisterHandleControlEvent__(control, function(ctrl)
                callback(self:FindControl(ctrl:GetControlID()))
            end) then
                error("'FCMCustomLuaWindow.RegisterHandleControlEvent' has encountered an error.", 2)
            end
        end
    end
    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then


        function methods:RegisterHandleTimer(callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            private[self].HandleTimer.Registered = callback
        end

        function methods:AddHandleTimer(timerid, callback)
            mixin_helper.assert_argument_type(2, timerid, "number")
            mixin_helper.assert_argument_type(3, callback, "function")
            private[self].HandleTimer[timerid] = private[self].HandleTimer[timerid] or {}
            table.insert(private[self].HandleTimer[timerid], callback)
        end

        function methods:RemoveHandleTimer(timerid, callback)
            mixin_helper.assert_argument_type(2, timerid, "number")
            mixin_helper.assert_argument_type(3, callback, "function")
            if not private[self].HandleTimer[timerid] then
                return
            end
            utils.table_remove_first(private[self].HandleTimer[timerid], callback)
        end

        function methods:SetTimer(timerid, msinterval)
            mixin_helper.assert_argument_type(2, timerid, "number")
            mixin_helper.assert_argument_type(3, msinterval, "number")
            self:SetTimer__(timerid, msinterval)
            private[self].HandleTimer[timerid] = private[self].HandleTimer[timerid] or {}
        end

        function methods:GetNextTimerID()
            while private[self].HandleTimer[private[self].NextTimerID] do
                private[self].NextTimerID = private[self].NextTimerID + 1
            end
            return private[self].NextTimerID
        end

        function methods:SetNextTimer(msinterval)
            mixin_helper.assert_argument_type(2, msinterval, "number")
            local timerid = mixin.FCMCustomLuaWindow.GetNextTimerID(self)
            mixin.FCMCustomLuaWindow.SetTimer(self, timerid, msinterval)
            return timerid
        end
    end
    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 60 then

        function methods:SetEnableAutoRestorePosition(enabled)
            mixin_helper.assert_argument_type(2, enabled, "boolean")
            private[self].EnableAutoRestorePosition = enabled
        end

        function methods:GetEnableAutoRestorePosition()
            return private[self].EnableAutoRestorePosition
        end

        function methods:SetRestorePositionData(x, y, width, height)
            mixin_helper.assert_argument_type(2, x, "number")
            mixin_helper.assert_argument_type(3, y, "number")
            mixin_helper.assert_argument_type(4, width, "number")
            mixin_helper.assert_argument_type(5, height, "number")
            self:SetRestorePositionOnlyData__(x, y, width, height)
            if private[self].HasBeenShown and not self:WindowExists() then
                private[self].StoredX = x
                private[self].StoredY = y
            end
        end

        function methods:SetRestorePositionOnlyData(x, y)
            mixin_helper.assert_argument_type(2, x, "number")
            mixin_helper.assert_argument_type(3, y, "number")
            self:SetRestorePositionOnlyData__(x, y)
            if private[self].HasBeenShown and not self:WindowExists() then
                private[self].StoredX = x
                private[self].StoredY = y
            end
        end
    end

    function methods:SetEnableDebugClose(enabled)
        mixin_helper.assert_argument_type(2, enabled, "boolean")
        private[self].EnableDebugClose = enabled and true or false
    end

    function methods:GetEnableDebugClose()
        return private[self].EnableDebugClose
    end

    function methods:SetRestoreControlState(enabled)
        mixin_helper.assert_argument_type(2, enabled, "boolean")
        private[self].RestoreControlState = enabled and true or false
    end

    function methods:GetRestoreControlState()
        return private[self].RestoreControlState
    end

    function methods:HasBeenShown()
        return private[self].HasBeenShown
    end

    function methods:ExecuteModal(parent)
        if mixin_helper.is_instance_of(parent, "FCMCustomLuaWindow") and private[self].UseParentMeasurementUnit then
            self:SetMeasurementUnit(parent:GetMeasurementUnit())
        end
        restore_position(self)
        return mixin.FCMCustomWindow.ExecuteModal(self, parent)
    end

    function methods:ShowModeless()
        finenv.RegisterModelessDialog(self)
        restore_position(self)
        return self:ShowModeless__()
    end

    function methods:RunModeless(selection_not_required, default_action_override)
        local modifier_keys_on_invoke = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
        local default_action = default_action_override == nil and private[self].HandleOkButtonPressed.Registered or default_action_override
        if modifier_keys_on_invoke and self:HasBeenShown() and default_action then
            default_action(self)
            return
        end
        if finenv.IsRGPLua then

            if self.OkButtonCanClose then
                self.OkButtonCanClose = modifier_keys_on_invoke
            end
            if self:ShowModeless() then
                finenv.RetainLuaState = true
            end
        else
            if not selection_not_required and finenv.Region():IsEmpty() then
                finenv.UI():AlertInfo("Please select a music region before running this script.", "Selection Required")
                return
            end
            self:ExecuteModal(nil)
        end
    end

    function methods:GetMeasurementUnit()
        return private[self].MeasurementUnit
    end

    function methods:SetMeasurementUnit(unit)
        mixin_helper.assert_argument_type(2, unit, "number")
        if unit == private[self].MeasurementUnit then
            return
        end
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end
        mixin_helper.force_assert(measurement.is_valid_unit(unit), "Measurement unit is not valid.")
        private[self].MeasurementUnit = unit

        for ctrl in each(self) do
            local func = ctrl.UpdateMeasurementUnit
            if func then
                func(ctrl)
            end
        end
        trigger_measurement_unit_change(self)
    end

    function methods:GetMeasurementUnitName()
        return measurement.get_unit_name(private[self].MeasurementUnit)
    end

    function methods:GetUseParentMeasurementUnit(enabled)
        return private[self].UseParentMeasurementUnit
    end

    function methods:SetUseParentMeasurementUnit(enabled)
        mixin_helper.assert_argument_type(2, enabled, "boolean")
        private[self].UseParentMeasurementUnit = enabled and true or false
    end



    methods.AddHandleMeasurementUnitChange, methods.RemoveHandleMeasurementUnitChange, trigger_measurement_unit_change, each_last_measurement_unit_change = mixin_helper.create_custom_window_change_event(
        {
            name = "last_unit",
            get = function(window)
                return mixin.FCMCustomLuaWindow.GetMeasurementUnit(window)
            end,
            initial = measurement.get_real_default_unit(),
        }
    )

    function methods:CreateMeasurementEdit(x, y, control_name)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, control_name, "string", "nil")
        local edit = mixin.FCMCustomWindow.CreateEdit(self, x, y, control_name)
        return mixin.subclass(edit, "FCXCtrlMeasurementEdit")
    end

    function methods:CreateMeasurementUnitPopup(x, y, control_name)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, control_name, "string", "nil")
        local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
        return mixin.subclass(popup, "FCXCtrlMeasurementUnitPopup")
    end

    function methods:CreatePageSizePopup(x, y, control_name)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, control_name, "string", "nil")
        local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
        return mixin.subclass(popup, "FCXCtrlPageSizePopup")
    end
    return class
end
package.preload["mixin.FCMCustomWindow"] = package.preload["mixin.FCMCustomWindow"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local loc = require("library.localization")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local function create_control(self, func, num_args, ...)
        local result = self["Create" .. func .. "__"](self, ...)
        local function add_control(control)
            private[self].Controls[control:GetControlID()] = control
            control:RegisterParent(self)
        end
        if func == "RadioButtonGroup" then
            for control in each(result) do
                add_control(control)
            end
        else
            add_control(result)
        end
        local control_name = select(num_args + 1, ...)
        if control_name then
            control_name = type(control_name) == "userdata" and control_name.LuaString or control_name
            if private[self].NamedControls[control_name] then
                error("A control is already registered with the name '" .. control_name .. "'", 2)
            end
            private[self].NamedControls[control_name] = result
        end
        return result
    end

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {
            Controls = {},
            NamedControls = {},
        }
    end



















    for num_args, ctrl_types in pairs({
        [0] = {"CancelButton", "OkButton",},
        [2] = {"Button", "Checkbox", "CloseButton", "DataList", "Edit", "TextEditor",
            "ListBox", "Popup", "Slider", "Static", "Switcher", "Tree", "UpDown", "ComboBox",
        },
        [3] = {"HorizontalLine", "VerticalLine", "RadioButtonGroup"},
    }) do
        for _, control_type in pairs(ctrl_types) do
            local type_exists = false
            if finenv.IsRGPLua then
                type_exists = finale.FCCustomWindow.__class["Create" .. control_type]
            else

                for k, _ in pairs(finale.FCCustomWindow.__class) do
                    if tostring(k) == "Create" .. control_type then
                        type_exists = true
                        break
                    end
                end
            end
            if not type_exists then
                goto continue
            end
            methods["Create" .. control_type] = function(self, ...)
                for i = 1, num_args do
                    mixin_helper.assert_argument_type(i + 1, select(i, ...), "number")
                end
                mixin_helper.assert_argument_type(num_args + 2, select(num_args + 1, ...), "string", "nil", "FCString")
                return create_control(self, control_type, num_args, ...)
            end
            :: continue ::
        end
    end



    loc.add_to_locale("en", { ok = "OK", cancel = "Cancel", close = "Close" })
    loc.add_to_locale("es", { ok = "Aceptar", cancel = "Cancelar", close = "Cerrar" })
    loc.add_to_locale("de", { ok = "OK", cancel = "Abbrechen", close = "Schließen" })
    for num_args, method_info in pairs({
        [0] = { CancelButton = "cancel", OkButton = "ok" },
        [2] = { CloseButton = "close" },
    })
    do
        for method_name, localization_key in pairs(method_info) do
            methods["Create" .. method_name .. "AutoLocalized"] = function(self, ...)
                for i = 1, num_args do
                    mixin_helper.assert_argument_type(i + 1, select(i, ...), "number")
                end
                mixin_helper.assert_argument_type(num_args + 2, select(num_args + 1, ...), "string", "nil", "FCString")
                return self["Create" .. method_name](self, ...)
                    :SetTextLocalized(localization_key)
                    :_FallbackCall("DoAutoResizeWidth", nil)
            end
        end
    end

    function methods:FindControl(control_id)
        mixin_helper.assert_argument_type(2, control_id, "number")
        return private[self].Controls[control_id]
    end

    function methods:GetControl(control_name)
        mixin_helper.assert_argument_type(2, control_name, "string", "FCString")
        return private[self].NamedControls[control_name]
    end

    function methods:Each(class_filter)
        local i = -1
        local v
        local iterator = function()
            repeat
                i = i + 1
                v = mixin.FCMCustomWindow.GetItemAt(self, i)
            until not v or not class_filter or mixin_helper.is_instance_of(v, class_filter)
            return v
        end
        return iterator
    end

    function methods:GetItemAt(index)
        local item = self:GetItemAt__(index)
        return item and private[self].Controls[item:GetControlID()] or item
    end

    function methods:GetParent()
        return private[self].Parent
    end

    function methods:ExecuteModal(parent)
        private[self].Parent = parent
        local ret = self:ExecuteModal__(parent)
        private[self].Parent = nil
        return ret
    end
    return class
end
package.preload["mixin.FCMNoteEntry"] = package.preload["mixin.FCMNoteEntry"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {}
    end

    function methods:RegisterParent(parent)
        mixin_helper.assert_argument_type(2, parent, "FCNoteEntryCell")
        if not private[self].Parent then
            private[self].Parent = parent
        end
    end

    function methods:GetParent()
        return private[self].Parent
    end
    return class
end
package.preload["mixin.FCMNoteEntryCell"] = package.preload["mixin.FCMNoteEntryCell"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods

    function methods:GetItemAt(index)
        mixin_helper.assert_argument_type(2, index, "number")
        local item = self:GetItemAt__(index)
        if item then
            item:RegisterParent(self)
        end
        return item
    end
    return class
end
package.preload["mixin.FCMPage"] = package.preload["mixin.FCMPage"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local page_size = require("library.page_size")
    local class = {Methods = {}}
    local methods = class.Methods

    function methods:GetSize()
        return page_size.get_page_size(self)
    end

    function methods:SetSize(size)
        mixin_helper.assert_argument_type(2, size, "string")
        mixin_helper.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")
        page_size.set_page_size(self, size)
    end

    function methods:IsBlank()
        return self:GetFirstSystem() == -1
    end
    return class
end
package.preload["mixin.FCMString"] = package.preload["mixin.FCMString"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local measurement = require("library.measurement")
    local class = {Methods = {}}
    local methods = class.Methods

    local unit_overrides = {
        {unit = finale.MEASUREMENTUNIT_EVPUS, overrides = {"EVPUS", "evpus", "e"}},
        {unit = finale.MEASUREMENTUNIT_INCHES, overrides = {"inches", "in", "i", "”"}},
        {unit = finale.MEASUREMENTUNIT_CENTIMETERS, overrides = {"centimeters", "cm", "c"}},

        {unit = finale.MEASUREMENTUNIT_POINTS, overrides = {"points", "pts", "pt"}},
        {unit = finale.MEASUREMENTUNIT_PICAS, overrides = {"picas", "p"}},
        {unit = finale.MEASUREMENTUNIT_SPACES, overrides = {"spaces", "sp", "s"}},
        {unit = finale.MEASUREMENTUNIT_MILLIMETERS, overrides = {"millimeters", "mm", "m"}},
    }
    function split_string_start(str, pattern)
        return string.match(str, "^(" .. pattern .. ")(.*)")
    end
    local function split_number(str, allow_negative)
        return split_string_start(str, (allow_negative and "%-?" or "") .. "%d+%.?%d*")
    end
    local function calculate_picas(whole, fractional)
        fractional = fractional or 0
        return tonumber(whole) * 48 + tonumber(fractional) * 4
    end

    function methods:GetMeasurement(measurementunit)
        mixin_helper.assert_argument_type(2, measurementunit, "number")

        local value = string.gsub(self.LuaString, "%" .. mixin.UI():GetDecimalSeparator(), '.')
        local start_number, remainder = split_number(value, true)
        if not start_number then
            return 0
        end
        if remainder then

            remainder = utils.ltrim(remainder)
            if remainder == "" then
                goto continue
            end
            for _, unit in ipairs(unit_overrides) do
                for _, override in ipairs(unit.overrides) do
                    local a, b = split_string_start(remainder, override)
                    if a then
                        measurementunit = unit.unit
                        if measurementunit == finale.MEASUREMENTUNIT_PICAS then
                            return calculate_picas(start_number, split_number(utils.ltrim(b)))
                        end
                        goto continue
                    end
                end
            end
            :: continue ::
        end
        if measurementunit == finale.MEASUREMENTUNIT_DEFAULT then
            measurementunit = measurement.get_real_default_unit()
        end
        start_number = tonumber(start_number)
        if measurementunit == finale.MEASUREMENTUNIT_EVPUS then
            return start_number
        elseif measurementunit == finale.MEASUREMENTUNIT_INCHES then
            return start_number * 288
        elseif measurementunit == finale.MEASUREMENTUNIT_CENTIMETERS then
            return start_number * 288 / 2.54
        elseif measurementunit == finale.MEASUREMENTUNIT_POINTS then
            return start_number * 4
        elseif measurementunit == finale.MEASUREMENTUNIT_PICAS then
            return start_number * 48
        elseif measurementunit == finale.MEASUREMENTUNIT_SPACES then
            return start_number * 24
        elseif measurementunit == finale.MEASUREMENTUNIT_MILLIMETERS then
            return start_number * 288 / 25.4
        end

        return 0
    end

    function methods:GetRangeMeasurement(measurementunit, minimum, maximum)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        return utils.clamp(mixin.FCMString.GetMeasurement(measurementunit), minimum, maximum)
    end

    function methods:SetMeasurement(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number")
        if measurementunit == finale.MEASUREMENTUNIT_PICAS then
            local whole = math.floor(value / 48)
            local fractional = value - whole * 48
            fractional = fractional < 0 and fractional * -1 or fractional
            self.LuaString = whole .. "p" .. utils.to_integer_if_whole(utils.round(fractional / 4, 4))
            return
        end

        if measurementunit == finale.MEASUREMENTUNIT_INCHES then
            value = value / 288
        elseif measurementunit == finale.MEASUREMENTUNIT_CENTIMETERS then
            value = value / 288 * 2.54
        elseif measurementunit == finale.MEASUREMENTUNIT_POINTS then
            value = value / 4
        elseif measurementunit == finale.MEASUREMENTUNIT_SPACES then
            value = value / 24
        elseif measurementunit == finale.MEASUREMENTUNIT_MILLIMETERS then
            value = value / 288 * 25.4
        end
        self.LuaString = tostring(utils.to_integer_if_whole(utils.round(value, 5)))
    end

    function methods:GetMeasurementInteger(measurementunit)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        return utils.round(mixin.FCMString.GetMeasurement(self, measurementunit))
    end

    function methods:GetRangeMeasurementInteger(measurementunit, minimum, maximum)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        return utils.clamp(mixin.FCMString.GetMeasurementInteger(measurementunit), math.ceil(minimum), math.floor(maximum))
    end

    function methods:SetMeasurementInteger(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number")
        mixin.FCMString.SetMeasurement(self, utils.round(value), measurementunit)
    end

    function methods:GetMeasurementEfix(measurementunit)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        return utils.round(mixin.FCMString.GetMeasurement(self, measurementunit) * 64)
    end

    function methods:GetRangeMeasurementEfix(measurementunit, minimum, maximum)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        return utils.clamp(mixin.FCMString.GetMeasurementEfix(measurementunit), math.ceil(minimum), math.floor(maximum))
    end

    function methods:SetMeasurementEfix(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number")
        mixin.FCMString.SetMeasurement(self, utils.round(value) / 64, measurementunit)
    end

    function methods:GetMeasurement10000th(measurementunit)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        return utils.round(mixin.FCMString.GetMeasurement(self, measurementunit) * 10000)
    end

    function methods:GetRangeMeasurement10000th(measurementunit, minimum, maximum)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        return utils.clamp(mixin.FCMString.GetMeasurement10000th(self, measurementunit), math.ceil(minimum), math.floor(maximum))
    end

    function methods:SetMeasurement10000th(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number")
        mixin.FCMString.SetMeasurement(self, utils.round(value) / 10000, measurementunit)
    end
    return class
end
package.preload["mixin.FCMStrings"] = package.preload["mixin.FCMStrings"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local temp_str = finale.FCString()

    function methods:AddCopy(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)



        if finenv.MajorVersion > 0 or finenv.MinorVersion >= 71 then
            mixin_helper.boolean_to_error(self, "AddCopy", str)
        else
            self:AddCopy__(str)
        end
    end

    methods.AddCopies = mixin_helper.create_multi_string_proxy("AddCopy")

    function methods:Find(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        return self:Find__(mixin_helper.to_fcstring(str, temp_str))
    end

    function methods:FindNocase(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        return self:FindNocase__(mixin_helper.to_fcstring(str, temp_str))
    end

    function methods:LoadFolderFiles(folderstring)
        mixin_helper.assert_argument_type(2, folderstring, "string", "FCString")
        mixin_helper.boolean_to_error(self, "LoadFolderFiles", mixin_helper.to_fcstring(folderstring, temp_str))
    end

    function methods:LoadSubfolders(folderstring)
        mixin_helper.assert_argument_type(2, folderstring, "string", "FCString")
        mixin_helper.boolean_to_error(self, "LoadSubfolders", mixin_helper.to_fcstring(folderstring, temp_str))
    end

    function methods:LoadSymbolFonts()
        mixin_helper.boolean_to_error(self, "LoadSymbolFonts")
    end

    function methods:LoadSystemFontNames()
        mixin_helper.boolean_to_error(self, "LoadSystemFontNames")
    end

    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 68 then


        function methods:InsertStringAt(str, index)
            mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
            mixin_helper.assert_argument_type(3, index, "number")
            self:InsertStringAt__(mixin_helper.to_fcstring(str, temp_str), index)
        end
    end

    function methods:CopyFromStringTable(strings)
        mixin_helper.assert_argument_type(2, strings, "table")
        local suffix = self.MixinClass and "__" or ""
        if finenv.MajorVersion == 0 and finenv.MinorVersion < 64 then
            self:ClearAll()
            for _, v in pairs(strings) do
                temp_str.LuaString = tostring(v)
                self["AddCopy" .. suffix](self, temp_str)
            end
        else
            self["CopyFromStringTable" .. suffix](self, strings)
        end
    end

    function methods:CreateStringTable()
        local t = {}
        for str in each(self) do
            table.insert(t, str.LuaString)
        end
        return t
    end
    return class
end
package.preload["mixin.FCMTextExpressionDef"] = package.preload["mixin.FCMTextExpressionDef"] or function()




    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local temp_str = finale.FCString()

    function methods:SaveNewTextBlock(str)
        mixin_helper.assert_argument_type(2, str, "string", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        mixin_helper.boolean_to_error(self, "SaveNewTextBlock", str)
    end

    function methods:AssignToCategory(cat_def)
        mixin_helper.assert_argument_type(2, cat_def, "FCCategoryDef")
        mixin_helper.boolean_to_error(self, "AssignToCategory", cat_def)
    end

    function methods:SetUseCategoryPos(enable)
        mixin_helper.assert_argument_type(2, enable, "boolean")
        mixin_helper.boolean_to_error(self, "SetUseCategoryPos", enable)
    end

    function methods:SetUseCategoryFont(enable)
        mixin_helper.assert_argument_type(2, enable, "boolean")
        mixin_helper.boolean_to_error(self, "SetUseCategoryFont", enable)
    end

    function methods:MakeRehearsalMark(str, measure)
        local do_return = false
        if type(measure) == "nil" then
            measure = str
            str = temp_str
            do_return = true
        else
            mixin_helper.assert_argument_type(2, str, "FCString")
        end
        mixin_helper.assert_argument_type(do_return and 2 or 3, measure, "number")
        mixin_helper.boolean_to_error(self, "MakeRehearsalMark", str, measure)
        if do_return then
            return str.LuaString
        end
    end

    function methods:SaveTextString(str)
        mixin_helper.assert_argument_type(2, str, "string", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        mixin_helper.boolean_to_error(self, "SaveTextString", str)
    end

    function methods:DeleteTextBlock()
        mixin_helper.boolean_to_error(self, "DeleteTextBlock")
    end

    function methods:SetDescription(str)
        mixin_helper.assert_argument_type(2, str, "string", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        self:SetDescription__(str)
    end

    function methods:GetDescription(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local do_return = not str
        str = str or temp_str
        self:GetDescription__(str)
        if do_return then
            return str.LuaString
        end
    end

    function methods:DeepSaveAs(item_num)
        mixin_helper.assert_argument_type(2, item_num, "number")
        mixin_helper.boolean_to_error(self, "DeepSaveAs", item_num)
    end

    function methods:DeepDeleteData()
        mixin_helper.boolean_to_error(self, "DeepDeleteData")
    end
    return class
end
package.preload["mixin.FCMTreeNode"] = package.preload["mixin.FCMTreeNode"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local temp_str = finale.FCString()

    function methods:GetText(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local do_return = false
        if not str then
            str = temp_str
            do_return = true
        end
        self:GetText__(str)
        if do_return then
            return str.LuaString
        end
    end

    function methods:SetText(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        self:SetText__(mixin_helper.to_fcstring(str, temp_str))
    end
    return class
end
package.preload["mixin.FCMUI"] = package.preload["mixin.FCMUI"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local temp_str = finale.FCString()

    function methods:GetDecimalSeparator(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local do_return = false
        if not str then
            str = temp_str
            do_return = true
        end
        self:GetDecimalSeparator__(str)
        if do_return then
            return str.LuaString
        end
    end

    function methods:GetUserLocaleName(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local do_return = false
        if not str then
            str = temp_str
            do_return = true
        end
        self:GetUserLocaleName__(str)
        if do_return then
            return str.LuaString
        end
    end

    methods.AlertErrorLocalized = mixin_helper.create_localized_proxy("AlertError")
    return class
end
package.preload["mixin.FCXCtrlMeasurementEdit"] = package.preload["mixin.FCXCtrlMeasurementEdit"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local class = {Parent = "FCMCtrlEdit", Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local trigger_change
    local each_last_change

    local function convert_type(value, from, to)

        if from ~= "Measurement" then
            value = utils.round(value)
        end
        if from == to then
            return value
        end
        if from == "MeasurementEfix" then
            value = value / 64
        elseif from == "Measurement10000th" then
            value = value / 10000
        end
        if to == "MeasurementEfix" then
            value = value * 64
        elseif to == "Measurement10000th" then
            value = value * 10000
        end
        if to == "Measurement" then
            return value
        end
        return utils.round(value)
    end

    function class:Init()
        if private[self] then
            return
        end
        local parent = self:GetParent()
        mixin_helper.assert(function() return mixin_helper.is_instance_of(parent, "FCMCustomLuaWindow") end, "FCXCtrlMeasurementEdit must have a parent window that is an instance of FCMCustomLuaWindow")
        private[self] = {
            Type = "MeasurementInteger",
            LastMeasurementUnit = parent:GetMeasurementUnit(),
            LastText = mixin.FCMCtrlEdit.GetText(self),
            Value = mixin.FCMCtrlEdit.GetMeasurementInteger(self, parent:GetMeasurementUnit()),
        }
    end



    for method, valid_types in pairs({
        Text = {"string", "number", "FCString"},
        Integer = {"number"},
        Float = {"number"},
    }) do
        methods["Set" .. method] = function(self, value)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            mixin.FCMCtrlEdit["Set" .. method](self, value)
            trigger_change(self)
        end
    end

    function methods:GetType()
        return private[self].Type
    end




















    for method, valid_types in pairs({
        Measurement = {"number"},
        MeasurementInteger = {"number"},
        MeasurementEfix = {"number"},
        Measurement10000th = {"number"},
    }) do
        methods["Get" .. method] = function(self)
            local text = mixin.FCMCtrlEdit.GetText(self)
            if (text ~= private[self].LastText) then
                private[self].Value = mixin.FCMCtrlEdit["Get" .. private[self].Type](self, private[self].LastMeasurementUnit)
                private[self].LastText = text
            end
            return convert_type(private[self].Value, private[self].Type, method)
        end
        methods["GetRange" .. method] = function(self, minimum, maximum)
            mixin_helper.assert_argument_type(2, minimum, "number")
            mixin_helper.assert_argument_type(3, maximum, "number")
            minimum = method ~= "Measurement" and math.ceil(minimum) or minimum
            maximum = method ~= "Measurement" and math.floor(maximum) or maximum
            return utils.clamp(mixin.FCXCtrlMeasurementEdit["Get" .. method](self), minimum, maximum)
        end
        methods["Set" .. method] = function (self, value)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            private[self].Value = convert_type(value, method, private[self].Type)
            mixin.FCMCtrlEdit["Set" .. private[self].Type](self, private[self].Value, private[self].LastMeasurementUnit)
            private[self].LastText = mixin.FCMCtrlEdit.GetText(self)
            trigger_change(self)
        end
        methods["IsType" .. method] = function(self)
            return private[self].Type == method
        end
        methods["SetType" .. method] = function(self)
            private[self].Value = convert_type(private[self].Value, private[self].Type, method)
            for v in each_last_change(self) do
                v.last_value = convert_type(v.last_value, private[self].Type, method)
            end
            private[self].Type = method
        end
    end

    function methods:UpdateMeasurementUnit()
        local new_unit = self:GetParent():GetMeasurementUnit()
        if private[self].LastMeasurementUnit ~= new_unit then
            local value = mixin.FCXCtrlMeasurementEdit["Get" .. private[self].Type](self)
            private[self].LastMeasurementUnit = new_unit
            mixin.FCXCtrlMeasurementEdit["Set" .. private[self].Type](self, value)
        end
    end



    methods.AddHandleChange, methods.RemoveHandleChange, trigger_change, each_last_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_value",
            get = function(self)
                return mixin.FCXCtrlMeasurementEdit["Get" .. private[self].Type](self)
            end,
            initial = 0,
        }
    )
    return class
end
package.preload["mixin.FCXCtrlMeasurementUnitPopup"] = package.preload["mixin.FCXCtrlMeasurementUnitPopup"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local class = {Parent = "FCMCtrlPopup", Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local unit_order = {
        finale.MEASUREMENTUNIT_EVPUS, finale.MEASUREMENTUNIT_INCHES, finale.MEASUREMENTUNIT_CENTIMETERS,
        finale.MEASUREMENTUNIT_POINTS, finale.MEASUREMENTUNIT_PICAS, finale.MEASUREMENTUNIT_SPACES,
    }
    local flipped_unit_order = {}
    for k, v in ipairs(unit_order) do
        flipped_unit_order[v] = k
    end

    class.Disabled = {"Clear", "AddString", "AddStrings", "SetStrings", "GetSelectedItem", "SetSelectedItem", "SetSelectedLast",
        "ItemExists", "InsertString", "DeleteItem", "GetItemText", "SetItemText", "AddHandleSelectionChange", "RemoveHandleSelectionChange"}

    function class:Init()
        if private[self] then
            return
        end
        mixin_helper.assert(function() return mixin_helper.is_instance_of(self:GetParent(), "FCMCustomLuaWindow") end, "FCXCtrlMeasurementUnitPopup must have a parent window that is an instance of FCMCustomLuaWindow")
        for _, v in ipairs(unit_order) do
            mixin.FCMCtrlPopup.AddString(self, measurement.get_unit_name(v))
        end
        self:UpdateMeasurementUnit()
        mixin.FCMCtrlPopup.AddHandleSelectionChange(self, function(control)
            control:GetParent():SetMeasurementUnit(unit_order[mixin.FCMCtrlPopup.GetSelectedItem(control) + 1])
        end)
        private[self] = true
    end

    function methods:UpdateMeasurementUnit()
        local unit = self:GetParent():GetMeasurementUnit()
        if unit == unit_order[mixin.FCMCtrlPopup.GetSelectedItem(self) + 1] then
            return
        end
        mixin.FCMCtrlPopup.SetSelectedItem(self, flipped_unit_order[unit] - 1)
    end
    return class
end
package.preload["library.page_size"] = package.preload["library.page_size"] or function()



    local page_size = {}
    local utils = require("library.utils")

    local sizes = {}

    sizes.A3 = {width = 3366, height = 4761}
    sizes.A4 = {width = 2381, height = 3368}
    sizes.A5 = {width = 1678, height = 2380}
    sizes.B4 = {width = 2920, height = 4127}
    sizes.B5 = {width = 1994, height = 2834}
    sizes.Concert = {width = 2592, height = 3456}
    sizes.Executive = {width = 2160, height = 2880}
    sizes.Folio = {width = 2448, height = 3744}
    sizes.Hymn = {width = 1656, height = 2376}
    sizes.Legal = {width = 2448, height = 4032}
    sizes.Letter = {width = 2448, height = 3168}
    sizes.Octavo = {width = 1944, height = 3024}
    sizes.Quarto = {width = 2448, height = 3110}
    sizes.Statement = {width = 1584, height = 2448}
    sizes.Tabloid = {width = 3168, height = 4896}


    function page_size.get_dimensions(size)
        return utils.copy_table(sizes[size])
    end

    function page_size.is_size(size)
        return sizes[size] and true or false
    end

    function page_size.get_size(width, height)

        if height < width then
            local temp = height
            height = width
            width = temp
        end
        for size, dimensions in pairs(sizes) do
            if dimensions.width == width and dimensions.height == height then
                return size
            end
        end
        return nil
    end

    function page_size.get_page_size(page)
        return page_size.get_size(page.Width, page.Height)
    end

    function page_size.set_page_size(page, size)
        if not sizes[size] then
            return
        end
        if page:IsPortrait() then
            page:SetWidth(sizes[size].width)
            page:SetHeight(sizes[size].height)
        else
            page:SetWidth(sizes[size].height)
            page:SetHeight(sizes[size].width)
        end
    end

    local sizes_index
    function page_size.pairs()
        if not sizes_index then
            sizes_index = {}
            for size in pairs(sizes) do
                table.insert(sizes_index, size)
            end
            table.sort(sizes_index)
        end
        local i = 0
        local iterator = function()
            i = i + 1
            if sizes_index[i] == nil then
                return nil
            else
                return sizes_index[i], sizes[sizes_index[i]]
            end
        end
        return iterator
    end
    return page_size
end
package.preload["mixin.FCXCtrlPageSizePopup"] = package.preload["mixin.FCXCtrlPageSizePopup"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local page_size = require("library.page_size")
    local class = {Parent = "FCMCtrlPopup", Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local trigger_page_size_change
    local each_last_page_size_change
    local temp_str = finale.FCString()

    class.Disabled = {"Clear", "AddString", "AddStrings", "SetStrings", "GetSelectedItem", "SetSelectedItem", "SetSelectedLast",
        "ItemExists", "InsertString", "DeleteItem", "GetItemText", "SetItemText", "AddHandleSelectionChange", "RemoveHandleSelectionChange"}
    local function repopulate(control)
        local unit = mixin_helper.is_instance_of(control:GetParent(), "FCXCustomLuaWindow") and control:GetParent():GetMeasurementUnit() or measurement.get_real_default_unit()
        if private[control].LastUnit == unit then
            return
        end
        local suffix = measurement.get_unit_abbreviation(unit)
        local selection = mixin.FCMCtrlPopup.GetSelectedItem(control)

        mixin.FCMCtrlPopup.Clear(control)
        for size, dimensions in page_size.pairs() do
            local str = size .. " ("
            temp_str:SetMeasurement(dimensions.width, unit)
            str = str .. temp_str.LuaString .. suffix .. " x "
            temp_str:SetMeasurement(dimensions.height, unit)
            str = str .. temp_str.LuaString .. suffix .. ")"
            mixin.FCMCtrlPopup.AddString(control, str)
        end
        mixin.FCMCtrlPopup.SetSelectedItem(control, selection)
        private[control].LastUnit = unit
    end

    function class:Init()
        if private[self] then
            return
        end
        private[self] = {}
        repopulate(self)
    end

    function methods:GetSelectedPageSize(str)
        mixin_helper.assert_argument_type(2, str, "FCString", "nil")
        local size = mixin.FCMCtrlPopup.GetSelectedString(self)
        if size then
           size = size:match("(.+) %(")
        end
        if str then
            str.LuaString = size or ""
        else
            return size
        end
    end

    function methods:SetSelectedPageSize(size)
        mixin_helper.assert_argument_type(2, size, "string", "FCString")

        size = type(size) == "userdata" and size.LuaString or tostring(size)
        mixin_helper.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")
        local index = 0
        for s in page_size.pairs() do
            if size == s then
                if index ~= mixin.FCMCtrlPopup.GetSelectedItem(self) then
                    mixin.FCMCtrlPopup.SetSelectedItem(self, index)
                    trigger_page_size_change(self)
                end
                return
            end
            index = index + 1
        end
    end

    function methods:UpdateMeasurementUnit()
        repopulate(self)
    end



    methods.AddHandlePageSizeChange, methods.RemoveHandlePageSizeChange, trigger_page_size_change, each_last_page_size_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_page_size",
            get = function(ctrl)
                return mixin.FCXCtrlPageSizePopup.GetSelectedPageSize(ctrl)
            end,
            initial = false,
        }
    )
    return class
end
package.preload["mixin.FCXCtrlUpDown"] = package.preload["mixin.FCXCtrlUpDown"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Parent = "FCMCtrlUpDown", Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local temp_str = finale.FCString()

    local function enum_edit_type(edit, edit_type)
        if edit_type == "Integer" then
            return 1
        else
            if edit:IsTypeMeasurement() then
                return 2
            elseif edit:IsTypeMeasurementInteger() then
                return 3
            elseif edit:IsTypeMeasurementEfix() then
                return 4
            end
        end
    end
    local default_measurement_steps = {
        [finale.MEASUREMENTUNIT_EVPUS] = {value = 1, is_evpus = true},
        [finale.MEASUREMENTUNIT_INCHES] = {value = 0.03125, is_evpus = false},
        [finale.MEASUREMENTUNIT_CENTIMETERS] = {value = 0.01, is_evpus = false},
        [finale.MEASUREMENTUNIT_POINTS] = {value = 0.25, is_evpus = false},
        [finale.MEASUREMENTUNIT_PICAS] = {value = 1, is_evpus = true},
        [finale.MEASUREMENTUNIT_SPACES] = {value = 0.125, is_evpus = false},
    }
    local default_efix_steps = {
        [finale.MEASUREMENTUNIT_EVPUS] = {value = 0.015625, is_evpus = true},
        [finale.MEASUREMENTUNIT_INCHES] = {value = 0.03125, is_evpus = false},
        [finale.MEASUREMENTUNIT_CENTIMETERS] = {value = 0.001, is_evpus = false},
        [finale.MEASUREMENTUNIT_POINTS] = {value = 0.03125, is_evpus = false},
        [finale.MEASUREMENTUNIT_PICAS] = {value = 0.015625, is_evpus = true},
        [finale.MEASUREMENTUNIT_SPACES] = {value = 0.03125, is_evpus = false},
    }

    function class:Init()
        if private[self] then
            return
        end
        mixin_helper.assert(function() return mixin_helper.is_instance_of(self:GetParent(), "FCXCustomLuaWindow") end, "FCXCtrlUpDown must have a parent window that is an instance of FCXCustomLuaWindow")
        private[self] = {
            IntegerStepSize = 1,
            MeasurementSteps = {},
            AlignWhenMoving = true,
        }
        self:AddHandlePress(function(self, delta)
            if not private[self].ConnectedEdit then
                return
            end
            local edit = private[self].ConnectedEdit
            local edit_type = enum_edit_type(edit, private[self].ConnectedEditType)
            local unit = self:GetParent():GetMeasurementUnit()
            local separator = mixin.UI():GetDecimalSeparator()
            local step_def
            if edit_type == 1 then
                step_def = {value = private[self].IntegerStepSize}
            else
                step_def = private[self].MeasurementSteps[unit] or (edit_type == 4 and default_efix_steps[unit]) or default_measurement_steps[unit]
            end

            local value
            if edit_type == 1 then
                value = edit:GetText():match("^%-*[0-9%.%,%" .. separator .. "-]+")
                value = value and tonumber(value) or 0
            else
                if step_def.is_evpus then
                    value = edit:GetMeasurement()
                else

                    temp_str:SetMeasurement(edit:GetMeasurement(), unit)
                    value = temp_str.LuaString:gsub("%" .. separator, ".")
                    value = tonumber(value)
                end
            end

            if private[self].AlignWhenMoving then

                local num_steps = tonumber(tostring(value / step_def.value)) or 0
                if num_steps ~= math.floor(num_steps) then
                    if delta > 0 then
                        value = math.ceil(num_steps) * step_def.value
                        delta = delta - 1
                    elseif delta < 0 then
                        value = math.floor(num_steps) * step_def.value
                        delta = delta + 1
                    end
                end
            end

            local new_value = value + delta * step_def.value

            if edit_type == 1 then
                self:SetValue(new_value)
            else
                if step_def.is_evpus then
                    self:SetValue(edit_type == 4 and new_value * 64 or new_value)
                else

                    temp_str.LuaString = tostring(new_value)
                    local new_evpus = temp_str:GetMeasurement(unit)
                    if new_evpus < private[self].Minimum or new_evpus > private[self].Maximum then
                        self:SetValue(edit_type == 4 and new_evpus * 64 or new_evpus)
                    else
                        edit:SetText(temp_str.LuaString:gsub("%.", separator))
                    end
                end
            end
        end)
    end

    function methods:GetConnectedEdit()
        return private[self].ConnectedEdit
    end

    function methods:ConnectIntegerEdit(control, minimum, maximum)
        mixin_helper.assert_argument_type(2, control, "FCMCtrlEdit")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        mixin_helper.assert(function() return not mixin_helper.is_instance_of(control, "FCXCtrlMeasurementEdit") end, "A measurement edit cannot be connected as an integer edit.")
        private[self].ConnectedEdit = control
        private[self].ConnectedEditType = "Integer"
        private[self].Minimum = minimum
        private[self].Maximum = maximum
    end

    function methods:ConnectMeasurementEdit(control, minimum, maximum)
        mixin_helper.assert_argument_type(2, control, "FCXCtrlMeasurementEdit")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        private[self].ConnectedEdit = control
        private[self].ConnectedEditType = "Measurement"
        private[self].Minimum = minimum
        private[self].Maximum = maximum
    end

    function methods:SetIntegerStepSize(value)
        mixin_helper.assert_argument_type(2, value, "number")
        private[self].IntegerStepSize = value
    end

    function methods:SetEVPUsStepSize(value)
        mixin_helper.assert_argument_type(2, value, "number")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_EVPUS] = {value = value, is_evpus = true}
    end

    function methods:SetInchesStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_INCHES] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function methods:SetCentimetersStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_CENTIMETERS] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function methods:SetPointsStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_POINTS] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function methods:SetPicasStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number", "string")
        if not is_evpus then
            temp_str:SetText(tostring(value))
            value = temp_str:GetMeasurement(finale.MEASUREMENTUNIT_PICAS)
        end
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_PICAS] = {value = value, is_evpus = true}
    end

    function methods:SetSpacesStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_SPACES] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function methods:SetAlignWhenMoving(on)
        mixin_helper.assert_argument_type(2, on, "boolean")
        private[self].AlignWhenMoving = on
    end

    function methods:GetValue()
        if not private[self].ConnectedEdit then
            return
        end
        local edit = private[self].ConnectedEdit
        if private[self].ConnectedEditType == "Measurement" then
            return edit["Get" .. edit:GetType()](edit, private[self].Minimum, private[self].Maximum)
        else
            return edit:GetRangeInteger(private[self].Minimum, private[self].Maximum)
        end
    end

    function methods:SetValue(value)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert(private[self].ConnectedEdit, "Unable to set value: no connected edit.")

        value = value < private[self].Minimum and private[self].Minimum or value
        value = value > private[self].Maximum and private[self].Maximum or value
        local edit = private[self].ConnectedEdit
        if private[self].ConnectedEditType == "Measurement" then
            edit["Set" .. edit:GetType()](edit, value)
        else
            edit:SetInteger(value)
        end
    end

    function methods:GetMinimum()
        return private[self].Minimum
    end

    function methods:GetMaximum()
        return private[self].Maximum
    end

    function methods:SetRange(minimum, maximum)
        mixin_helper.assert_argument_type(2, minimum, "number")
        mixin_helper.assert_argument_type(3, maximum, "number")
        private[self].Minimum = minimum
        private[self].Maximum = maximum
    end
    return class
end
package.preload["mixin.FCXCustomLuaWindow"] = package.preload["mixin.FCXCustomLuaWindow"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Parent = "FCMCustomLuaWindow", Methods = {}}
    local methods = class.Methods

    function class:Init()
        self:SetEnableDebugClose(true)
    end

    function methods:CreateUpDown(x, y, control_name)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, control_name, "string", "nil")
        local updown = mixin.FCMCustomWindow.CreateUpDown(self, x, y, control_name)
        return mixin.subclass(updown, "FCXCtrlUpDown")
    end
    return class
end
package.preload["mixin.__FCMBase"] = package.preload["mixin.__FCMBase"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods

    function methods:_FallbackCall(method_name, fallback_value, ...)
        if not self[method_name] then
            if fallback_value ~= nil then
                return fallback_value
            end
            return self
        end
        return self[method_name](self, ...)
    end
    return class
end
package.preload["library.lua_compatibility"] = package.preload["library.lua_compatibility"] or function()



    if not math.type then
        math.type = function(value)
            if type(value) == "number" then
                local _, fractional = math.modf(value)
                return fractional == 0 and "integer" or "float"
            end
            return nil
        end
    end
    if not math.tointeger then
        math.tointeger = function(value)
            return type(value) == "number" and math.floor(value) or nil
        end
    end
    return true
end
package.preload["library.localization"] = package.preload["library.localization"] or function()

    local localization = {}
    local library = require("library.general_library")
    local utils = require("library.utils")
    local locale = (function()
            if finenv.UI().GetUserLocaleName then
                local fcstr = finale.FCString()
                finenv.UI():GetUserLocaleName(fcstr)
                return fcstr.LuaString:gsub("-", "_")
            end
            return "en_US"
        end)()
    local fallback_locale = "en"
    local script_name = library.calc_script_name()
    local tried_locales = {}

    function localization.set_locale(input_locale)
        locale = input_locale:gsub("-", "_")
    end

    function localization.get_locale()
        return locale
    end

    function localization.set_fallback_locale(input_locale)
        fallback_locale = input_locale:gsub("-", "_")
    end

    function localization.get_fallback_locale()
        return fallback_locale
    end
    local function get_original_locale_table(try_locale)
        local require_library = "localization" .. "." .. script_name .. "." .. try_locale
        local success, result = pcall(function() return require(require_library) end)
        if success and type(result) == "table" then
            return result
        end
        return nil
    end


    local function get_localized_table(try_locale)
        local table_exists = type(localization[try_locale]) == "table"
        if not table_exists or not tried_locales[try_locale] then
            assert(table_exists or type(localization[try_locale]) == "nil",
                        "incorrect type for localization[" .. try_locale .. "]; got " .. type(localization[try_locale]))
            local original_table = get_original_locale_table(try_locale)
            if type(original_table) == "table" then


                localization[try_locale] = utils.copy_table(original_table, localization[try_locale])
            end

            tried_locales[try_locale] = true
        end
        return localization[try_locale]
    end

    function localization.add_to_locale(try_locale, t)
        if type(localization[try_locale]) ~= "table" then
            if not get_original_locale_table(try_locale) then
                return false
            end
        end
        localization[try_locale] = utils.copy_table(t, localization[try_locale], false)
        return true
    end
    local function try_locale_or_language(try_locale)
        local t = get_localized_table(try_locale)
        if t then
            return t
        end
        if #try_locale > 2 then
            t = get_localized_table(try_locale:sub(1, 2))
            if t then
                return t
            end
        end
        return nil
    end

    function localization.localize(input_string)
        assert(type(input_string) == "string", "expected string, got " .. type(input_string))
        if locale == nil then
            return input_string
        end
        assert(type(locale) == "string", "invalid locale setting " .. tostring(locale))

        local t = try_locale_or_language(locale)
        if t and t[input_string] then
            return t[input_string]
        end
        t = get_localized_table(fallback_locale)

        return t and t[input_string] or input_string
    end
    return localization
end
package.preload["library.mixin_helper"] = package.preload["library.mixin_helper"] or function()




    require("library.lua_compatibility")
    local utils = require("library.utils")
    local mixin = require("library.mixin")
    local library = require("library.general_library")
    local localization = require("library.localization")
    local mixin_helper = {}
    local debug_enabled = finenv.DebugEnabled

    function mixin_helper.is_instance_of(object, ...)
        if not library.is_finale_object(object) then
            return false
        end



        local class_names = {[0] = {}, [1] = {}, [2] = {}}
        for i = 1, select("#", ...) do
            local class_name = select(i, ...)

            local class_type = (mixin.is_fcx_class_name(class_name) and 2) or (mixin.is_fcm_class_name(class_name) and 1) or (mixin.is_fc_class_name(class_name) and 0) or false
            if class_type then

                class_names[class_type][class_type == 1 and mixin.fcm_to_fc_class_name(class_name) or class_name] = true
            end
        end
        local object_type = (mixin.is_fcx_class_name(object.MixinClass) and 2) or (mixin.is_fcm_class_name(object.MixinClass) and 1) or 0
        local parent = object_type == 0 and library.get_class_name(object) or object.MixinClass

        if object_type == 2 then
            repeat
                if class_names[2][parent] then
                    return true
                end

                parent = object.MixinParent
            until mixin.is_fcm_class_name(parent)
        end

        if object_type > 0 then
            parent = mixin.fcm_to_fc_class_name(parent)
        end

        repeat
            if (object_type < 2 and class_names[0][parent]) or (object_type > 0 and class_names[1][parent]) then
                return true
            end
            parent = library.get_parent_class(parent)
        until not parent

        return false
    end
    local function assert_argument_type(levels, argument_number, value, ...)
        local primary_type = type(value)
        local secondary_type
        if primary_type == "number" then
            secondary_type = math.type(value)
        end
        for i = 1, select("#", ...) do
            local t = select(i, ...)
            if t == primary_type or (secondary_type and t == secondary_type) then
                return
            end
        end
        if mixin_helper.is_instance_of(value, ...) then
            return
        end

        if library.is_finale_object(value) then
            secondary_type = value.MixinClass or value.ClassName
        end
        error("bad argument #" .. tostring(argument_number) .. " to 'tryfunczzz' (" .. table.concat(table.pack(...), " or ") .. " expected, got " .. (secondary_type or primary_type) .. ")", levels)
    end

    function mixin_helper.assert_argument_type(argument_number, value, ...)
        if debug_enabled then
            assert_argument_type(4, argument_number, value, ...)
        end
    end

    function mixin_helper.force_assert_argument_type(argument_number, value, ...)
        assert_argument_type(4, argument_number, value, ...)
    end
    local function to_key_string(value)
        if type(value) == "string" then
            value = "\"" .. value .. "\""
        end
        return "[" .. tostring(value) .. "]"
    end
    local function assert_table_argument_type(argument_number, table_value, ...)
        if type(table_value) ~= "table" then
            error("bad argument #2 to 'assert_table_argument_type' (table expected, got " .. type(table_value) .. ")", 3)
        end
        for k, v in pairsbykeys(table_value) do
            if k ~= "n" or type(k) ~= "number" then
                assert_argument_type(5, tostring(argument_number) .. to_key_string(k), v, ...)
            end
        end
    end

    function mixin_helper.assert_table_argument_type(argument_number, value, ...)
        if debug_enabled then
            assert_table_argument_type(argument_number, value, ...)
        end
    end

    function mixin_helper.force_assert_table_argument_type(argument_number, value, ...)
        assert_table_argument_type(argument_number, value, ...)
    end
    local function assert_func(condition, message, level)
        if type(condition) == "function" then
            condition = condition()
        end
        if not condition then
            error(message, level)
        end
    end

    function mixin_helper.assert(condition, message, level)
        if debug_enabled then
            assert_func(condition, message, level == 0 and 0 or 2 + (level or 2))
        end
    end

    function mixin_helper.force_assert(condition, message, level)
        assert_func(condition, message, level == 0 and 0 or 2 + (level or 2))
    end

    function mixin_helper.create_standard_control_event(name)
        local callbacks = setmetatable({}, {__mode = "k"})
        local windows = setmetatable({}, {__mode = "k"})
        local dispatcher = function(control, ...)
            if not callbacks[control] then
                return
            end
            for _, cb in ipairs(callbacks[control]) do
                cb(control, ...)
            end
        end
        local function init_window(window)
            if windows[window] then
                return
            end
            window["Add" .. name](window, dispatcher)
            windows[window] = true
        end
        local function add_func(control, callback)
            mixin_helper.assert_argument_type(3, callback, "function")
            local window = control:GetParent()
            mixin_helper.assert(window, "Cannot add handler to control with no parent window.")
            mixin_helper.assert((window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
            init_window(window)
            callbacks[control] = callbacks[control] or {}
            table.insert(callbacks[control], callback)
        end
        local function remove_func(control, callback)
            mixin_helper.assert_argument_type(3, callback, "function")
            utils.table_remove_first(callbacks[control], callback)
        end
        return add_func, remove_func
    end

    local function unpack_arguments(values, ...)
        local args = {}
        for i = 1, select("#", ...) do
            table.insert(args, values[select(i, ...).name])
        end
        return table.unpack(args)
    end
    local function get_event_value(target, func)
        if type(func) == "string" then
            return target[func](target)
        else
            return func(target)
        end
    end
    local function create_change_event(...)
        local callbacks = setmetatable({}, {__mode = "k"})
        local params = {...}
        local event = {}
        function event.dispatcher(target)
            if not callbacks[target] then
                return
            end

            local current = {}
            for _, p in ipairs(params) do
                current[p.name] = get_event_value(target, p.get)
            end
            for _, cb in ipairs(callbacks[target].order) do

                local called = false
                for k, _ in pairs(current) do
                    if current[k] ~= callbacks[target].history[cb][k] then
                        cb(target, unpack_arguments(callbacks[target].history[cb], table.unpack(params)))
                        called = true
                        goto continue
                    end
                end
                ::continue::

                for _, p in ipairs(params) do
                    current[p.name] = get_event_value(target, p.get)
                end


                if called then
                    callbacks[target].history[cb] = utils.copy_table(current)
                end
            end
        end
        function event.add(target, callback, initial)
            callbacks[target] = callbacks[target] or {order = {}, history = {}}
            local history = {}
            for _, p in ipairs(params) do
                if initial then
                    if type(p.initial) == "function" then
                        history[p.name] = p.initial(target)
                    else
                        history[p.name] = p.initial
                    end
                else
                    history[p.name] = get_event_value(target, p.get)
                end
            end
            callbacks[target].history[callback] = history
            table.insert(callbacks[target].order, callback)
        end
        function event.remove(target, callback)
            if not callbacks[target] then
                return
            end
            callbacks[target].history[callback] = nil
            table.insert(callbacks[target].order, callback)
        end
        function event.callback_exists(target, callback)
            return callbacks[target] and callbacks[target].history[callback] and true or false
        end
        function event.has_callbacks(target)
            return callbacks[target] and #callbacks[target].order > 0 or false
        end

        function event.history_iterator(control)
            local cb = callbacks[control]
            if not cb or #cb.order == 0 then
                return function()
                    return nil
                end
            end
            local i = 0
            local iterator = function()
                i = i + 1
                if not cb.order[i] then
                    return nil
                end
                return cb.history[cb.order[i]]
            end
            return iterator
        end
        function event.target_iterator()
            return utils.iterate_keys(callbacks)
        end
        return event
    end

    function mixin_helper.create_custom_control_change_event(...)
        local event = create_change_event(...)
        local windows = setmetatable({}, {__mode = "k"})
        local queued = setmetatable({}, {__mode = "k"})
        local function init_window(window)
            if windows[window] then
                return
            end
            window:AddInitWindow(function()

                for control in event.target_iterator() do
                    event.dispatcher(control)
                end
            end)
            window:AddHandleCommand(event.dispatcher)
        end
        local function add_func(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            local window = self:GetParent()
            mixin_helper.assert(window, "Cannot add handler to self with no parent window.")
            mixin_helper.assert((window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow", "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
            mixin_helper.force_assert(not event.callback_exists(self, callback), "The callback has already been added as a handler.")
            init_window(window)
            event.add(self, callback, not window:WindowExists__())
        end
        local function remove_func(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            event.remove(self, callback)
        end
        local function trigger_helper(control)
            if not event.has_callbacks(control) or queued[control] then
                return
            end
            local window = control:GetParent()
            if window:WindowExists__() then
                window:QueueHandleCustom(function()
                    queued[control] = nil
                    event.dispatcher(control)
                end)
                queued[control] = true
            end
        end



        local function trigger_func(control, immediate)
            if type(control) == "boolean" and control then
                for ctrl in event.target_iterator() do
                    if immediate then
                        event.dispatcher(ctrl)
                    else
                        trigger_helper(ctrl)
                    end
                end
            else
                if immediate then
                    event.dispatcher(control)
                else
                    trigger_helper(control)
                end
            end
        end
        return add_func, remove_func, trigger_func, event.history_iterator
    end

    function mixin_helper.create_custom_window_change_event(...)
        local event = create_change_event(...)
        local queued = setmetatable({}, {__mode = "k"})
        local function add_func(self, callback)
            mixin_helper.assert_argument_type(1, self, "FCMCustomLuaWindow")
            mixin_helper.assert_argument_type(2, callback, "function")
            mixin_helper.force_assert(not event.callback_exists(self, callback), "The callback has already been added as a handler.")
            event.add(self, callback)
        end
        local function remove_func(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            event.remove(self, callback)
        end
        local function trigger_helper(window)
            if not event.has_callbacks(window) or queued[window] or not window:WindowExists__() then
                return
            end
            window:QueueHandleCustom(function()
                queued[window] = nil
                event.dispatcher(window)
            end)
            queued[window] = true
        end
        local function trigger_func(window, immediate)
            if type(window) == "boolean" and window then
                for win in event.target_iterator() do
                    if immediate then
                        event.dispatcher(win)
                    else
                        trigger_helper(win)
                    end
                end
            else
                if immediate then
                    event.dispatcher(window)
                else
                    trigger_helper(window)
                end
            end
        end
        return add_func, remove_func, trigger_func, event.history_iterator
    end

    function mixin_helper.to_fcstring(value, fcstr)
        if mixin_helper.is_instance_of(value, "FCString") then
            return value
        end
        fcstr = fcstr or finale.FCString()
        fcstr.LuaString = value == nil and "" or tostring(value)
        return fcstr
    end

    function mixin_helper.to_string(value)
        if mixin_helper.is_instance_of(value, "FCString") then
            return value.LuaString
        end
        return value == nil and "" or tostring(value)
    end

    function mixin_helper.boolean_to_error(object, method, ...)
        if not object[method .. "__"](object, ...) then
            error("'" .. object.MixinClass .. "." .. method .. "' has encountered an error.", 3)
        end
    end

    function mixin_helper.create_localized_proxy(method_name, class_name, only_localize_args)
        local args_to_localize
        if only_localize_args == nil then
            args_to_localize = setmetatable({}, { __index = function() return true end })
        else
            args_to_localize = utils.create_lookup_table(only_localize_args)
        end
        return function(self, ...)
            local args = table.pack(...)
            for arg_num = 1, args.n do
                if args_to_localize[arg_num] then
                    mixin_helper.assert_argument_type(arg_num, args[arg_num], "string", "FCString")
                    args[arg_num] = localization.localize(mixin_helper.to_string(args[arg_num]))
                end
            end

            return (class_name and mixin[class_name] or self)[method_name](self, table.unpack(args, 1, args.n))
        end
    end

    function mixin_helper.create_multi_string_proxy(method_name)
        return function(self, ...)
            mixin_helper.assert_argument_type(1, self, "userdata")
            for i = 1, select("#", ...) do
                local v = select(i, ...)
                mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString", "FCStrings", "table")
                if type(v) == "userdata" and v:ClassName() == "FCStrings" then
                    for str in each(v) do
                        self[method_name](self, str)
                    end
                elseif type(v) == "table" then
                    mixin_helper.assert_table_argument_type(i + 1, v, "string", "number", "FCString")
                    for _, v2 in pairsbykeys(v) do
                        self[method_name](self, v2)
                    end
                else
                    self[method_name](self, v)
                end
            end
        end
    end
    return mixin_helper
end
package.preload["mixin.__FCMUserWindow"] = package.preload["mixin.__FCMUserWindow"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local class = {Methods = {}}
    local methods = class.Methods
    local temp_str = finale.FCString()

    function methods:GetTitle(title)
        mixin_helper.assert_argument_type(2, title, "nil", "FCString")
        local do_return = false
        if not title then
            title = temp_str
            do_return = true
        end
        self:GetTitle__(title)
        if do_return then
            return title.LuaString
        end
    end

    function methods:SetTitle(title)
        mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
        self:SetTitle__(mixin_helper.to_fcstring(title, temp_str))
    end

    methods.SetTitleLocalized = mixin_helper.create_localized_proxy("SetTitle")

    function methods:CreateChildUI()
        if self.CreateChildUI__ then
            return self:CreateChildUI__()
        end
        return mixin.UI()
    end
    return class
end
package.preload["library.mixin"] = package.preload["library.mixin"] or function()




    local utils = require("library.utils")
    local library = require("library.general_library")

    local mixin_public = {}

    local mixin_private = {}

    local mixin_classes = {}

    local mixin_lookup = {}

    local mixin_props = setmetatable({}, {__mode = "k"})

    local reserved_props = {
        MixinReady = function(class_name) return true end,
        MixinClass = function(class_name) return class_name end,
        MixinParent = function(class_name) return mixin_classes[class_name].Parent end,
        MixinBase = function(class_name) return mixin_classes[class_name].Base end,
        Init = function(class_name) return mixin_classes[class_name].Init end,
        __class = function(class_name) return mixin_private.create_method_reflection(class_name, "Methods") end,
        __static = function(class_name) return mixin_private.create_method_reflection(class_name, "StaticMethods") end,
        __propget = function(class_name) return mixin_private.create_property_reflection(class_name, "Get") end,
        __propset = function(class_name) return mixin_private.create_property_reflection(class_name, "Set") end,
        __disabled = function(class_name) return mixin_classes[class_name].Disabled and utils.copy_table(mixin_classes[class_name].Disabled) or {} end,
    }

    local instance_reserved_props = {
        MixinReady = true,
        MixinClass = true,
        MixinParent = true,
        MixinBase = true,
    }

    local mixin = setmetatable({}, {
        __newindex = function(t, k, v) end,
        __index = function(t, k)
            if mixin_public[k] then return mixin_public[k] end
            mixin_private.load_mixin_class(k)
            if not mixin_classes[k] then return nil end

            mixin_public[k] = setmetatable({}, {
                __newindex = function(tt, kk, vv) end,
                __index = function(tt, kk)
                    local value
                    if mixin_lookup[k].Methods[kk] then
                        value = mixin_private.create_fluid_proxy(mixin_lookup[k].Methods[kk])
                    elseif mixin_classes[k].StaticMethods and mixin_classes[k].StaticMethods[kk] then
                        value = mixin_private.create_proxy(mixin_classes[k].StaticMethods[kk])
                    elseif mixin_lookup[k].Properties[kk] then

                        value = {}
                        for kkkk, vvvv in pairs(mixin_lookup[k].Properties[kk]) do
                            value[kkkk] = mixin_private.create_proxy(vvvv)
                        end
                    elseif reserved_props[kk] then
                        value = reserved_props[kk](k)
                    end
                    return value
                end,
                __call = function(_, ...)
                    if mixin_private.is_fcm_class_name(k) then
                        return mixin_private.create_fcm(k, ...)
                    else
                        return mixin_private.create_fcx(k, ...)
                    end
                end
            })
            return mixin_public[k]
        end
    })
    function mixin_private.is_fc_class_name(class_name)
        return type(class_name) == "string" and not mixin_private.is_fcm_class_name(class_name) and not mixin_private.is_fcx_class_name(class_name) and (class_name:match("^FC%u") or class_name:match("^__FC%u")) and true or false
    end
    function mixin_private.is_fcm_class_name(class_name)
        return type(class_name) == "string" and (class_name:match("^FCM%u") or class_name:match("^__FCM%u")) and true or false
    end
    function mixin_private.is_fcx_class_name(class_name)
        return type(class_name) == "string" and class_name:match("^FCX%u") and true or false
    end
    function mixin_private.fcm_to_fc_class_name(class_name)
        return string.gsub(class_name, "FCM", "FC", 1)
    end
    function mixin_private.fc_to_fcm_class_name(class_name)
        return string.gsub(class_name, "FC", "FCM", 1)
    end
    function mixin_private.assert_valid_property_name(name, error_level, suffix)
        if type(name) ~= "string" then
            error("Mixin method and property names must be strings" .. suffix, error_level)
        end
        suffix = suffix or ""
        if name:sub(-2) == "__" then
            error("Mixin methods and properties cannot end in a double underscore" .. suffix, error_level)
        elseif name:sub(1, 5):lower() == "mixin" then
            error("Mixin methods and properties beginning with 'Mixin' are reserved" .. suffix, error_level)
        elseif reserved_props[name] then
            error("'" .. name .. "' is a reserved name and cannot be used for propertiea or methods" .. suffix, error_level)
        end
    end

    function mixin_private.try_load_module(name)
        local success, result = pcall(function(c) return require(c) end, name)

        if not success and not result:match("module '[^']-' not found") then
            error(result, 0)
        end
        return success, result
    end
    local find_ancestor_with_prop
    find_ancestor_with_prop = function(class, attr, prop)
        if class[attr] and class[attr][prop] then
            return class.Class
        end
        if not class.Parent then
            return nil
        end
        return find_ancestor_with_prop(mixin_classes[class.Parent], attr, prop)
    end

    function mixin_private.load_mixin_class(class_name, create_lookup)
        if mixin_classes[class_name] then return end
        local is_fcm = mixin_private.is_fcm_class_name(class_name)

        if not is_fcm and not mixin_private.is_fcx_class_name(class_name) then
            return
        end
        local is_personal_mixin = false
        local success
        local result


        if finenv.TrustedMode == nil or finenv.TrustedMode == finenv.TrustedModeType.USER_TRUSTED then
            success, result = mixin_private.try_load_module("personal_mixin." .. class_name)
        end
        if success then
            is_personal_mixin = true
        else
            success, result = mixin_private.try_load_module("mixin." .. class_name)
        end
        if not success then

            if is_fcm and finale[mixin_private.fcm_to_fc_class_name(class_name)] then
                result = {}
            else
                return
            end
        end
        local error_prefix = (is_personal_mixin and "personal_" or "") .. "mixin." .. class_name

        if type(result) ~= "table" then
            error("Mixin '" .. error_prefix .. "' is not a table.", 0)
        end
        local class = {Class = class_name}
        local function has_attr(attr, attr_type)
            if result[attr] == nil then
                return false
            end
            if type(result[attr]) ~= attr_type then
                error("Mixin '" .. attr .. "' must be a " .. attr_type .. ", " .. type(result[attr]) .. " given (" .. error_prefix .. "." .. attr .. ")", 0)
            end
            return true
        end

        has_attr("Parent", "string")

        if is_fcm then

            class.Parent = library.get_parent_class(mixin_private.fcm_to_fc_class_name(class_name))
            if class.Parent then

                class.Parent = mixin_private.fc_to_fcm_class_name(class.Parent)
                mixin_private.load_mixin_class(class.Parent)
            end

        else

            if not result.Parent then
                error("Mixin '" .. error_prefix .. "' does not have a parent class defined.", 0)
            end
            if not mixin_private.is_fcm_class_name(result.Parent) and not mixin_private.is_fcx_class_name(result.Parent) then
                error("Mixin parent must be an FCM or FCX class name, '" .. result.Parent .. "' given (" .. error_prefix .. ".Parent)", 0)
            end
            mixin_private.load_mixin_class(result.Parent)

            if not mixin_classes[result.Parent] then
                error("Unable to load mixin '" .. result.Parent .. "' as parent of '" .. error_prefix .. "'", 0)
            end
            class.Parent = result.Parent

            class.Base = mixin_classes[result.Parent].Base or result.Parent
        end

        local lookup = class.Parent and utils.copy_table(mixin_lookup[class.Parent]) or {Methods = {}, Properties = {}, Disabled = {}, FCMInits = {}}

        if has_attr("Init", "function") and is_fcm then
            table.insert(lookup.FCMInits, result.Init)
        end
        class.Init = result.Init
        if not is_fcm then
            lookup.FCMInits = nil
        end

        if has_attr("Disabled", "table") then
            class.Disabled = {}
            for _, v in pairs(result.Disabled) do
                mixin_private.assert_valid_property_name(v, 0, " (" .. error_prefix .. ".Disabled." .. tostring(v) .. ")")
                class.Disabled[v] = true
                lookup.Disabled[v] = true
                lookup.Methods[v] = nil
                lookup.Properties[v] = nil
            end
        end
        local function find_property_name_clash(name, attr_to_check)
            for _, attr in pairs(attr_to_check) do
                if attr == "StaticMethods" or (lookup[attr] and lookup[attr][name]) then
                    local cl = find_ancestor_with_prop(class, attr, name)
                    return cl and (cl .. "." .. attr .. "." .. name) or nil
                end
            end
        end
        if has_attr("Methods", "table") then
            class.Methods = {}
            for k, v in pairs(result.Methods) do
                mixin_private.assert_valid_property_name(k, 0, " (" .. error_prefix .. ".Methods." .. tostring(k) .. ")")
                if type(v) ~= "function" then
                    error("A mixin method must be a function, " .. type(v) .. " given (" .. error_prefix .. ".Methods." .. k .. ")", 0)
                end
                if lookup.Disabled[k] then
                    error("Mixin methods cannot be defined for disabled names (" .. error_prefix .. ".Methods." .. k .. ")", 0)
                end
                local clash = find_property_name_clash(k, {"StaticMethods", "Properties"})
                if clash then
                    error("A method, static method or property cannot share the same name (" .. error_prefix .. ".Methods." .. k .. " & " .. clash .. ")", 0)
                end
                class.Methods[k] = v
                lookup.Methods[k] = v
            end
        end
        if has_attr("StaticMethods", "table") then
            class.StaticMethods = {}
            for k, v in pairs(result.StaticMethods) do
                mixin_private.assert_valid_property_name(k, 0, " (" .. error_prefix .. ".StaticMethods." .. tostring(k) .. ")")
                if type(v) ~= "function" then
                    error("A mixin method must be a function, " .. type(v) .. " given (" .. error_prefix .. ".StaticMethods." .. k .. ")", 0)
                end
                if lookup.Disabled[k] then
                    error("Mixin methods cannot be defined for disabled names (" .. error_prefix .. ".StaticMethods." .. k .. ")", 0)
                end
                local clash = find_property_name_clash(k, {"Methods", "Properties"})
                if clash then
                    error("A method, static method or property cannot share the same name (" .. error_prefix .. ".StaticMethods." .. k .. " & " .. clash .. ")", 0)
                end
                class.Methods[k] = v
            end
        end
        if has_attr("Properties", "table") then
            class.Properties = {}
            for k, v in pairs(result.Properties) do
                mixin_private.assert_valid_property_name(k, 0, " (" .. error_prefix .. ".Properties." .. tostring(k) .. ")")
                if lookup.Disabled[k] then
                    error("Mixin properties cannot be defined for disabled names (" .. error_prefix .. ".Properties." .. k .. ")", 0)
                end
                local clash = find_property_name_clash(k, {"Methods", "StaticMethods"})
                if clash then
                    error("A method, static method or property cannot share the same name (" .. error_prefix .. ".Properties." .. k .. " & " .. clash .. ")", 0)
                end
                if type(v) ~= "table" then
                    error("A mixin property descriptor must be a table, " .. type(v) .. " given (" .. error_prefix .. ".Properties." .. k .. ")", 0)
                end
                if not v.Get and not v.Set then
                    error("A mixin property descriptor must have at least a 'Get' or 'Set' attribute (" .. error_prefix .. ".Properties." .. k .. ")", 0)
                end
                class.Properties[k] = {}
                lookup.Properties[k] = lookup.Properties[k] or {}
                for kk, vv in pairs(v) do
                    if kk ~= "Get" and kk ~= "Set" then
                        error("A mixin property descriptor can only have 'Get' and 'Set' attributes (" .. error_prefix .. ".Properties." .. k .. ")", 0)
                    end
                    if type(vv) ~= "function" then
                        error("A mixin property descriptor attribute must be a function, " .. type(vv) .. " given (" .. error_prefix .. ".Properties." .. k .. "." .. kk .. ")", 0)
                    end
                    class.Properties[k][kk] = vv
                    lookup.Properties[k][kk] = vv
                end
            end
        end
        mixin_lookup[class_name] = lookup
        mixin_classes[class_name] = class
    end
    function mixin_private.create_method_reflection(class_name, attr)
        local t = {}
        if mixin_classes[class_name][attr] then
            for k, v in pairs(mixin_classes[class_name][attr]) do
                t[k] = mixin_private.create_proxy(v)
            end
        end
        return t
    end
    function mixin_private.create_property_reflection(class_name, attr)
        local t = {}
        if mixin_classes[class_name].Properties then
            for k, v in pairs(mixin_classes[class_name].Properties) do
                if v[attr] then
                    t[k] = mixin_private.create_proxy(v[attr])
                end
            end
        end
        return t
    end


    local function fluid_proxy(t, ...)
        local n = select("#", ...)

        if n == 0 then
            return t
        end

        for i = 1, n do
            mixin_private.enable_mixin(select(i, ...))
        end
        return ...
    end
    local function proxy(t, ...)
        local n = select("#", ...)

        for i = 1, n do
            mixin_private.enable_mixin(select(i, ...))
        end
        return ...
    end

    function mixin_private.create_fluid_proxy(func)
        return function(t, ...)
            return fluid_proxy(t, utils.call_and_rethrow(2, func, t, ...))
        end
    end
    function mixin_private.create_proxy(func)
        return function(t, ...)
            return proxy(t, utils.call_and_rethrow(2, func, t, ...))
        end
    end

    function mixin_private.enable_mixin(object, fcm_class_name)
        if mixin_props[object] or not library.is_finale_object(object) then
            return object
        end
        mixin_private.apply_mixin_foundation(object)
        fcm_class_name = fcm_class_name or mixin_private.fc_to_fcm_class_name(library.get_class_name(object))
        mixin_private.load_mixin_class(fcm_class_name)
        mixin_props[object] = {MixinClass = fcm_class_name}
        for _, v in ipairs(mixin_lookup[fcm_class_name].FCMInits) do
            v(object)
        end
        return object
    end



    function mixin_private.apply_mixin_foundation(object)
        if object.MixinReady then return end

        local meta = getmetatable(object)

        local original_index = meta.__index
        local original_newindex = meta.__newindex
        meta.__index = function(t, k)


            if k == "MixinReady" then return true end

            if not mixin_props[t] then return original_index(t, k) end
            local class = mixin_props[t].MixinClass
            local prop

            if type(k) == "string" and k:sub(-2) == "__" then

                prop = original_index(t, k:sub(1, -3))

            elseif mixin_lookup[class].Properties[k] and mixin_lookup[class].Properties[k].Get then
                prop = utils.call_and_rethrow(2, mixin_lookup[class].Properties[k].Get, t)

            elseif mixin_props[t][k] ~= nil then
                prop = utils.copy_table(mixin_props[t][k])

            elseif mixin_lookup[class].Methods[k] then
                prop = mixin_lookup[class].Methods[k]

            elseif instance_reserved_props[k] then
                prop = reserved_props[k](class)

            else
                prop = original_index(t, k)
            end
            if type(prop) == "function" then
                return mixin_private.create_fluid_proxy(prop)
            end
            return prop
        end


        meta.__newindex = function(t, k, v)

            if not mixin_props[t] then
                return original_newindex(t, k, v)
            end
            local class = mixin_props[t].MixinClass

            if mixin_lookup[class].Disabled[k] or reserved_props[k] then
                error("No writable member '" .. tostring(k) .. "'", 2)
            end


            if mixin_lookup[class].Properties[k] then
                if mixin_lookup[class].Properties[k].Set then
                    return mixin_lookup[class].Properties[k].Set(t, v)
                else
                    return original_newindex(t, k, v)
                end
            end

            if type(k) ~= "string" then
                mixin_props[t][k] = v
                return
            end

            if k:sub(-2) == "__" then
                k = k:sub(1, -3)
                return original_newindex(t, k, v)
            end
            mixin_private.assert_valid_property_name(k, 3)
            local type_v_original = type(original_index(t, k))
            local type_v = type(v)
            local is_mixin_method = mixin_lookup[class].Methods[k] and true or false

            if type_v_original == "nil" then
                if is_mixin_method and not (type_v == "function" or type_v == "nil") then
                    error("A mixin method cannot be overridden with a property.", 2)
                end
                mixin_props[t][k] = v
                return

            elseif type_v_original == "function" then
                if not (type_v == "function" or type_v == "nil") then
                    error("A Finale PDK method cannot be overridden with a property.", 2)
                end
                mixin_props[t][k] = v
                return
            end

            return original_newindex(t, k, v)
        end
    end

    function mixin_private.subclass(object, class_name)
        if not library.is_finale_object(object) then
            error("Object is not a finale object.", 2)
        end
        if not utils.call_and_rethrow(2, mixin_private.subclass_helper, object, class_name) then
            error(class_name .. " is not a subclass of " .. object.MixinClass, 2)
        end
        return object
    end


    function mixin_private.subclass_helper(object, class_name, suppress_errors)
        if not object.MixinClass then
            if suppress_errors then
                return false
            end
            error("Object is not mixin-enabled.", 2)
        end
        if not mixin_private.is_fcx_class_name(class_name) then
            if suppress_errors then
                return false
            end
            error("Mixins can only be subclassed with an FCX class.", 2)
        end
        if object.MixinClass == class_name then return true end
        mixin_private.load_mixin_class(class_name)
        if not mixin_classes[class_name] then
            if suppress_errors then
                return false
            end
            error("Mixin '" .. class_name .. "' not found.", 2)
        end

        if mixin_private.is_fcm_class_name(mixin_classes[class_name].Parent) and mixin_classes[class_name].Parent ~= object.MixinClass then
            return false
        end

        if mixin_classes[class_name].Parent ~= object.MixinClass then
            if not utils.call_and_rethrow(2, mixin_private.subclass_helper, object, mixin_classes[class_name].Parent) then
                return false
            end
        end

        mixin_props[object].MixinClass = class_name

        if mixin_classes[class_name].Disabled then
            for k, _ in pairs(mixin_classes[class_name].Disabled) do
                mixin_props[object][k] = nil
            end
        end

        if mixin_classes[class_name].Init then
            utils.call_and_rethrow(2, mixin_classes[class_name].Init, object)
        end
        return true
    end

    function mixin_private.create_fcm(class_name, ...)
        mixin_private.load_mixin_class(class_name)
        if not mixin_classes[class_name] then return nil end
        return mixin_private.enable_mixin(utils.call_and_rethrow(2, finale[mixin_private.fcm_to_fc_class_name(class_name)], ...))
    end

    function mixin_private.create_fcx(class_name, ...)
        mixin_private.load_mixin_class(class_name)
        if not mixin_classes[class_name] then return nil end
        local object = mixin_private.create_fcm(mixin_classes[class_name].Base, ...)
        if not object then return nil end
        if not utils.call_and_rethrow(2, mixin_private.subclass_helper, object, class_name, false) then
            return nil
        end
        return object
    end

    mixin_public.is_fc_class_name = mixin_private.is_fc_class_name

    mixin_public.is_fcm_class_name = mixin_private.is_fcm_class_name

    mixin_public.is_fcx_class_name = mixin_private.is_fcx_class_name

    mixin_public.fc_to_fcm_class_name = mixin_private.fc_to_fcm_class_name

    mixin_public.fcm_to_fc_class_name = mixin_private.fcm_to_fc_class_name

    mixin_public.subclass = mixin_private.subclass

    function mixin_public.UI()
        return mixin_private.enable_mixin(finenv.UI(), "FCMUI")
    end

    function mixin_public.eachentry(region, layer)
        local measure = region.StartMeasure
        local slotno = region:GetStartSlot()
        local i = 0
        local layertouse = 0
        if layer ~= nil then layertouse = layer end
        local c = mixin.FCMNoteEntryCell(measure, region:CalcStaffNumber(slotno))
        c:SetLoadLayerMode(layertouse)
        c:Load()
        return function()
            while true do
                i = i + 1;
                local returnvalue = c:GetItemAt(i - 1)
                if returnvalue ~= nil then
                    if (region:IsEntryPosWithin(returnvalue)) then return returnvalue end
                else
                    measure = measure + 1
                    if measure > region.EndMeasure then
                        measure = region.StartMeasure
                        slotno = slotno + 1
                        if (slotno > region:GetEndSlot()) then return nil end
                        c = mixin.FCMNoteEntryCell(measure, region:CalcStaffNumber(slotno))
                        c:SetLoadLayerMode(layertouse)
                        c:Load()
                        i = 0
                    else
                        c = mixin.FCMNoteEntryCell(measure, region:CalcStaffNumber(slotno))
                        c:SetLoadLayerMode(layertouse)
                        c:Load()
                        i = 0
                    end
                end
            end
        end
    end
    return mixin
end
package.preload["library.enigma_string"] = package.preload["library.enigma_string"] or function()

    local enigma_string = {}
    local starts_with_font_command = function(string)
        local text_cmds = {"^font", "^Font", "^fontMus", "^fontTxt", "^fontNum", "^size", "^nfx"}
        for _, text_cmd in ipairs(text_cmds) do
            if string:StartsWith(text_cmd) then
                return true
            end
        end
        return false
    end


    function enigma_string.trim_first_enigma_font_tags(string)
        local font_info = finale.FCFontInfo()
        local found_tag = false
        while true do
            if not starts_with_font_command(string) then
                break
            end
            local end_of_tag = string:FindFirst(")")
            if end_of_tag < 0 then
                break
            end
            local font_tag = finale.FCString()
            if string:SplitAt(end_of_tag, font_tag, nil, true) then
                font_info:ParseEnigmaCommand(font_tag)
            end
            string:DeleteCharactersAt(0, end_of_tag + 1)
            found_tag = true
        end
        if found_tag then
            return font_info
        end
        return nil
    end

    function enigma_string.change_first_string_font(string, font_info)
        local final_text = font_info:CreateEnigmaString(nil)
        local current_font_info = enigma_string.trim_first_enigma_font_tags(string)
        if (current_font_info == nil) or not font_info:IsIdenticalTo(current_font_info) then
            final_text:AppendString(string)
            string:SetString(final_text)
            return true
        end
        return false
    end

    function enigma_string.change_first_text_block_font(text_block, font_info)
        local new_text = text_block:CreateRawTextString()
        if enigma_string.change_first_string_font(new_text, font_info) then
            text_block:SaveRawTextString(new_text)
            return true
        end
        return false
    end



    function enigma_string.change_string_font(string, font_info)
        local final_text = font_info:CreateEnigmaString(nil)
        string:TrimEnigmaFontTags()
        final_text:AppendString(string)
        string:SetString(final_text)
    end

    function enigma_string.change_text_block_font(text_block, font_info)
        local new_text = text_block:CreateRawTextString()
        enigma_string.change_string_font(new_text, font_info)
        text_block:SaveRawTextString(new_text)
    end

    function enigma_string.remove_inserts(fcstring, replace_with_generic, convert_tags_to_literals)
        local text_cmds = {
            "^arranger", "^composer", "^copyright", "^date", "^description", "^fdate", "^filename", "^lyricist", "^page",
            "^partname", "^perftime", "^subtitle", "^time", "^title", "^totpages", "^value", "^control", "^pass"
        }
        local lua_string = fcstring.LuaString
        for _, text_cmd in ipairs(text_cmds) do
            local starts_at = string.find(lua_string, text_cmd, 1, true)
            while starts_at ~= nil do
                local replace_with = ""
                if replace_with_generic then
                    if convert_tags_to_literals then
                        replace_with = "^" .. text_cmd
                    else
                        replace_with = "[" .. string.sub(text_cmd, 2) .. "]"
                    end
                end
                local next_at = starts_at + #text_cmd
                if not replace_with_generic or not convert_tags_to_literals then
                    next_at = string.find(lua_string, ")", next_at, true) + 1 or starts_at
                end
                lua_string = string.sub(lua_string, 1, starts_at - 1) .. replace_with .. string.sub(lua_string, next_at)
                starts_at = string.find(lua_string, text_cmd, starts_at + #replace_with, true)
            end
        end
        fcstring.LuaString = lua_string
    end

    function enigma_string.expand_value_tag(fcstring, value_num)
        value_num = math.floor(value_num + 0.5)
        fcstring.LuaString = fcstring.LuaString:gsub("%^value%(%)", tostring(value_num))
    end

    function enigma_string.calc_text_advance_width(inp_string)
        local accumulated_string = ""
        local accumulated_width = 0
        local enigma_strings = inp_string:CreateEnigmaStrings(true)
        for str in each(enigma_strings) do
            accumulated_string = accumulated_string .. str.LuaString
            if string.sub(str.LuaString, 1, 1) ~= "^" then
                local fcstring = finale.FCString()
                local text_met = finale.FCTextMetrics()
                fcstring.LuaString = accumulated_string
                local font_info = fcstring:CreateLastFontInfo()
                fcstring.LuaString = str.LuaString
                fcstring:TrimEnigmaTags()
                text_met:LoadString(fcstring, font_info, 100)
                accumulated_width = accumulated_width + text_met:GetAdvanceWidthEVPUs()
            end
        end
        return accumulated_width
    end
    return enigma_string
end
package.preload["library.client"] = package.preload["library.client"] or function()

    local client = {}
    local function to_human_string(feature)
        return string.gsub(feature, "_", " ")
    end
    local function requires_later_plugin_version(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
        end
        return "This script requires a later version of RGP Lua. Please update RGP Lua instead to use this script."
    end
    local function requires_rgp_lua(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which is not available on JW Lua. Please use RGP Lua instead to use this script."
        end
        return "This script requires RGP Lua, the successor of JW Lua. Please use RGP Lua instead to use this script."
    end
    local function requires_plugin_version(version, feature)
        if tonumber(version) <= 0.54 then
            if feature then
                return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua or JW Lua version " .. version ..
                           " or later. Please update your plugin to use this script."
            end
            return "This script requires RGP Lua or JW Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        return "This script requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    local function requires_finale_version(version, feature)
        return "This script uses " .. to_human_string(feature) .. ", which is only available on Finale " .. version .. " or later"
    end

    function client.get_raw_finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

    function client.get_lua_plugin_version()
        local num_string = tostring(finenv.MajorVersion) .. "." .. tostring(finenv.MinorVersion)
        return tonumber(num_string)
    end
    local features = {
        clef_change = {
            test = client.get_lua_plugin_version() >= 0.60,
            error = requires_plugin_version("0.58", "a clef change"),
        },
        ["FCKeySignature::CalcTotalChromaticSteps"] = {
            test = finenv.IsRGPLua and finale.FCKeySignature.__class.CalcTotalChromaticSteps,
            error = requires_later_plugin_version("a custom key signature"),
        },
        ["FCCategory::SaveWithNewType"] = {
            test = client.get_lua_plugin_version() >= 0.58,
            error = requires_plugin_version("0.58"),
        },
        ["finenv.QueryInvokedModifierKeys"] = {
            test = finenv.IsRGPLua and finenv.QueryInvokedModifierKeys,
            error = requires_later_plugin_version(),
        },
        ["FCCustomLuaWindow::ShowModeless"] = {
            test = finenv.IsRGPLua,
            error = requires_rgp_lua("a modeless dialog")
        },
        ["finenv.RetainLuaState"] = {
            test = finenv.IsRGPLua and finenv.RetainLuaState ~= nil,
            error = requires_later_plugin_version(),
        },
        smufl = {
            test = finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1),
            error = requires_finale_version("27.1", "a SMUFL font"),
        },
        luaosutils = {
            test = finenv.EmbeddedLuaOSUtils,
            error = requires_later_plugin_version("the embedded luaosutils library")
        },
        cjson = {
            test = client.get_lua_plugin_version() >= 0.67,
            error = requires_plugin_version("0.67", "the embedded cjson library"),
        }
    }

    function client.supports(feature)
        if features[feature] == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

    function client.assert_supports(feature)
        local error_level = finenv.DebugEnabled and 2 or 0
        if not client.supports(feature) then
            if features[feature].error then
                error(features[feature].error, error_level)
            end

            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end

    function client.encode_with_client_codepage(input_string)
        if client.supports("luaosutils") then
            local text = require("luaosutils").text
            if text and text.get_default_codepage() ~= text.get_utf8_codepage() then
                return text.convert_encoding(input_string, text.get_utf8_codepage(), text.get_default_codepage())
            end
        end
        return input_string
    end

    function client.encode_with_utf8_codepage(input_string)
        if client.supports("luaosutils") then
            local text = require("luaosutils").text
            if text and text.get_default_codepage() ~= text.get_utf8_codepage() then
                return text.convert_encoding(input_string, text.get_default_codepage(), text.get_utf8_codepage())
            end
        end
        return input_string
    end

    function client.execute(command)
        if client.supports("luaosutils") then
            local process = require("luaosutils").process
            if process then
                return process.execute(command)
            end
        end
        local handle = io.popen(command)
        if not handle then return nil end
        local retval = handle:read("*a")
        handle:close()
        return retval
    end
    return client
end
package.preload["library.general_library"] = package.preload["library.general_library"] or function()

    local library = {}
    local client = require("library.client")

    function library.group_overlaps_region(staff_group, region)
        if region:IsFullDocumentSpan() then
            return true
        end
        local staff_exists = false
        local sys_staves = finale.FCSystemStaves()
        sys_staves:LoadAllForRegion(region)
        for sys_staff in each(sys_staves) do
            if staff_group:ContainsStaff(sys_staff:GetStaff()) then
                staff_exists = true
                break
            end
        end
        if not staff_exists then
            return false
        end
        if (staff_group.StartMeasure > region.EndMeasure) or (staff_group.EndMeasure < region.StartMeasure) then
            return false
        end
        return true
    end

    function library.group_is_contained_in_region(staff_group, region)
        if not region:IsStaffIncluded(staff_group.StartStaff) then
            return false
        end
        if not region:IsStaffIncluded(staff_group.EndStaff) then
            return false
        end
        return true
    end

    function library.staff_group_is_multistaff_instrument(staff_group)
        local multistaff_instruments = finale.FCMultiStaffInstruments()
        multistaff_instruments:LoadAll()
        for inst in each(multistaff_instruments) do
            if inst:ContainsStaff(staff_group.StartStaff) and (inst.GroupID == staff_group:GetItemID()) then
                return true
            end
        end
        return false
    end

    function library.get_selected_region_or_whole_doc()
        local sel_region = finenv.Region()
        if sel_region:IsEmpty() then
            sel_region:SetFullDocument()
        end
        return sel_region
    end

    function library.get_first_cell_on_or_after_page(page_num)
        local curr_page_num = page_num
        local curr_page = finale.FCPage()
        local got1 = false

        while curr_page:Load(curr_page_num) do
            if curr_page:GetFirstSystem() > 0 then
                got1 = true
                break
            end
            curr_page_num = curr_page_num + 1
        end
        if got1 then
            local staff_sys = finale.FCStaffSystem()
            staff_sys:Load(curr_page:GetFirstSystem())
            return finale.FCCell(staff_sys.FirstMeasure, staff_sys.TopStaff)
        end

        local end_region = finale.FCMusicRegion()
        end_region:SetFullDocument()
        return finale.FCCell(end_region.EndMeasure, end_region.EndStaff)
    end

    function library.get_top_left_visible_cell()
        if not finenv.UI():IsPageView() then
            local all_region = finale.FCMusicRegion()
            all_region:SetFullDocument()
            return finale.FCCell(finenv.UI():GetCurrentMeasure(), all_region.StartStaff)
        end
        return library.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())
    end

    function library.get_top_left_selected_or_visible_cell()
        local sel_region = finenv.Region()
        if not sel_region:IsEmpty() then
            return finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
        end
        return library.get_top_left_visible_cell()
    end

    function library.is_default_measure_number_visible_on_cell(meas_num_region, cell, staff_system, current_is_part)
        local staff = finale.FCCurrentStaffSpec()
        if not staff:LoadForCell(cell, 0) then
            return false
        end
        if meas_num_region:GetShowOnTopStaff() and (cell.Staff == staff_system.TopStaff) then
            return true
        end
        if meas_num_region:GetShowOnBottomStaff() and (cell.Staff == staff_system:CalcBottomStaff()) then
            return true
        end
        if staff.ShowMeasureNumbers then
            return not meas_num_region:GetExcludeOtherStaves(current_is_part)
        end
        return false
    end

    function library.calc_parts_boolean_for_measure_number_region(meas_num_region, for_part)
        if meas_num_region.UseScoreInfoForParts then
            return false
        end
        if nil == for_part then
            return finenv.UI():IsPartView()
        end
        return for_part
    end

    function library.is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)
        current_is_part = library.calc_parts_boolean_for_measure_number_region(meas_num_region, current_is_part)
        if is_for_multimeasure_rest and meas_num_region:GetShowOnMultiMeasureRests(current_is_part) then
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultiMeasureAlignment(current_is_part)) then
                return false
            end
        elseif (cell.Measure == system.FirstMeasure) then
            if not meas_num_region:GetShowOnSystemStart() then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetStartAlignment(current_is_part)) then
                return false
            end
        else
            if not meas_num_region:GetShowMultiples(current_is_part) then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultipleAlignment(current_is_part)) then
                return false
            end
        end
        return library.is_default_measure_number_visible_on_cell(meas_num_region, cell, system, current_is_part)
    end

    function library.update_layout(from_page, unfreeze_measures)
        from_page = from_page or 1
        unfreeze_measures = unfreeze_measures or false
        local page = finale.FCPage()
        if page:Load(from_page) then
            page:UpdateLayout(unfreeze_measures)
        end
    end

    function library.get_current_part()
        local part = finale.FCPart(finale.PARTID_CURRENT)
        part:Load(part.ID)
        return part
    end

    function library.get_score()
        local part = finale.FCPart(finale.PARTID_SCORE)
        part:Load(part.ID)
        return part
    end

    function library.get_page_format_prefs()
        local current_part = library.get_current_part()
        local page_format_prefs = finale.FCPageFormatPrefs()
        local success
        if current_part:IsScore() then
            success = page_format_prefs:LoadScore()
        else
            success = page_format_prefs:LoadParts()
        end
        return page_format_prefs, success
    end
    local calc_smufl_directory = function(for_user)
        local is_on_windows = finenv.UI():IsOnWindows()
        local do_getenv = function(win_var, mac_var)
            if finenv.UI():IsOnWindows() then
                return win_var and os.getenv(win_var) or ""
            else
                return mac_var and os.getenv(mac_var) or ""
            end
        end
        local smufl_directory = for_user and do_getenv("LOCALAPPDATA", "HOME") or do_getenv("COMMONPROGRAMFILES")
        if not is_on_windows then
            smufl_directory = smufl_directory .. "/Library/Application Support"
        end
        smufl_directory = smufl_directory .. "/SMuFL/Fonts/"
        return smufl_directory
    end

    function library.get_smufl_font_list()
        local osutils = client.supports("luaosutils") and require("luaosutils")
        local font_names = {}
        local add_to_table = function(for_user)
            local smufl_directory = calc_smufl_directory(for_user)
            local get_dirs = function()
                local options = finenv.UI():IsOnWindows() and "/b /ad" or "-1"
                if osutils then
                    return osutils.process.list_dir(smufl_directory, options)
                end

                local cmd = finenv.UI():IsOnWindows() and "dir " or "ls "
                return client.execute(cmd .. options .. " \"" .. smufl_directory .. "\"") or ""
            end
            local is_font_available = function(dir)
                local fc_dir = finale.FCString()
                fc_dir.LuaString = dir
                return finenv.UI():IsFontAvailable(fc_dir)
            end
            local dirs = get_dirs() or ""
            for dir in dirs:gmatch("([^\r\n]*)[\r\n]?") do
                if not dir:find("%.") then
                    dir = dir:gsub(" Bold", "")
                    dir = dir:gsub(" Italic", "")
                    local fc_dir = finale.FCString()
                    fc_dir.LuaString = dir
                    if font_names[dir] or is_font_available(dir) then
                        font_names[dir] = for_user and "user" or "system"
                    end
                end
            end
        end
        add_to_table(false)
        add_to_table(true)
        return font_names
    end

    function library.get_smufl_metadata_file(font_info_or_name)
        local font_name
        if type(font_info_or_name) == "string" then
            font_name = font_info_or_name
        else
            if not font_info_or_name then
                font_info_or_name = finale.FCFontInfo()
                font_info_or_name:LoadFontPrefs(finale.FONTPREF_MUSIC)
            end
            font_name = font_info_or_name.Name
        end
        local try_prefix = function(prefix)
            local file_path = prefix .. font_name .. "/" .. font_name .. ".json"
            return io.open(file_path, "r")
        end
        local user_file = try_prefix(calc_smufl_directory(true))
        if user_file then
            return user_file
        end
        return try_prefix(calc_smufl_directory(false))
    end

    function library.get_smufl_metadata_table(font_info_or_name, subkey)
        if not client.assert_supports("cjson") then
            return
        end
        local cjson = require("cjson")
        local json_file = library.get_smufl_metadata_file(font_info_or_name)
        if not json_file then
            return nil
        end
        local contents = json_file:read("*a")
        json_file:close()
        local json_table = cjson.decode(contents)
        if json_table and subkey then
            return json_table[subkey]
        end
        return json_table
    end

    function library.is_font_smufl_font(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        if client.supports("smufl") then
            if nil ~= font_info.IsSMuFLFont then
                return font_info.IsSMuFLFont
            end
        end
        local smufl_metadata_file = library.get_smufl_metadata_file(font_info)
        if nil ~= smufl_metadata_file then
            io.close(smufl_metadata_file)
            return true
        end
        return false
    end

    function library.simple_input(title, text, default)
        local str = finale.FCString()
        local min_width = 160

        local function format_ctrl(ctrl, h, w, st)
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
            if st then
                str.LuaString = st
                ctrl:SetText(str)
            end
        end

        local title_width = string.len(title) * 6 + 54
        if title_width > min_width then
            min_width = title_width
        end
        local text_width = string.len(text) * 6
        if text_width > min_width then
            min_width = text_width
        end

        str.LuaString = title
        local dialog = finale.FCCustomLuaWindow()
        dialog:SetTitle(str)
        local descr = dialog:CreateStatic(0, 0)
        format_ctrl(descr, 16, min_width, text)
        local input = dialog:CreateEdit(0, 20)
        format_ctrl(input, 20, min_width, default)
        dialog:CreateOkButton()
        dialog:CreateCancelButton()
        if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
            input:GetText(str)
            return str.LuaString
        end
    end

    function library.is_finale_object(object)

        return object and type(object) == "userdata" and object.ClassName and object.GetClassID and true or false
    end

    function library.get_parent_class(classname)
        local class = finale[classname]
        if type(class) ~= "table" then
            return nil
        end
        if not finenv.IsRGPLua then
            local classt = class.__class
            if classt and classname ~= "__FCBase" then
                local classtp = classt.__parent
                if classtp and type(classtp) == "table" then
                    for k, v in pairs(finale) do
                        if type(v) == "table" then
                            if v.__class and v.__class == classtp then
                                return tostring(k)
                            end
                        end
                    end
                end
            end
        else
            if class.__parent then
                for k, _ in pairs(class.__parent) do
                    return tostring(k)
                end
            end
        end
        return nil
    end

    function library.get_class_name(object)
        local class_name = object:ClassName(object)
        if class_name == "__FCCollection" and object.ExecuteModal then
            return object.RegisterHandleCommand and "FCCustomLuaWindow" or "FCCustomWindow"
        elseif class_name == "FCControl" then
            if object.GetCheck then
                return "FCCtrlCheckbox"
            elseif object.GetThumbPosition then
                return "FCCtrlSlider"
            elseif object.AddPage then
                return "FCCtrlSwitcher"
            else
                return "FCCtrlButton"
            end
        elseif class_name == "FCCtrlButton" and object.GetThumbPosition then
            return "FCCtrlSlider"
        end
        return class_name
    end

    function library.system_indent_set_to_prefs(system, page_format_prefs)
        page_format_prefs = page_format_prefs or library.get_page_format_prefs()
        local first_meas = finale.FCMeasure()
        local is_first_system = (system.FirstMeasure == 1)
        if (not is_first_system) and first_meas:Load(system.FirstMeasure) then
            if first_meas.ShowFullNames then
                is_first_system = true
            end
        end
        if is_first_system and page_format_prefs.UseFirstSystemMargins then
            system.LeftMargin = page_format_prefs.FirstSystemLeft
        else
            system.LeftMargin = page_format_prefs.SystemLeft
        end
        return system:Save()
    end

    function library.calc_script_filepath()
        local fc_string = finale.FCString()
        if finenv.RunningLuaFilePath then

            fc_string.LuaString = finenv.RunningLuaFilePath()
        else


            fc_string:SetRunningLuaFilePath()
        end
        return fc_string.LuaString
    end

    function library.calc_script_name(include_extension)
        local fc_string = finale.FCString()
        fc_string.LuaString = library.calc_script_filepath()
        local filename_string = finale.FCString()
        fc_string:SplitToPathAndFile(nil, filename_string)
        local retval = filename_string.LuaString
        if not include_extension then
            retval = retval:match("(.+)%..+")
            if not retval or retval == "" then
                retval = filename_string.LuaString
            end
        end
        return retval
    end

    function library.get_default_music_font_name()
        local fontinfo = finale.FCFontInfo()
        local default_music_font_name = finale.FCString()
        if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
            fontinfo:GetNameString(default_music_font_name)
            return default_music_font_name.LuaString
        end
    end
    return library
end
package.preload["library.utils"] = package.preload["library.utils"] or function()

    local utils = {}




    function utils.copy_table(t, to_table, overwrite)
        overwrite = (overwrite == nil) and true or false
        if type(t) == "table" then
            local new = type(to_table) == "table" and to_table or {}
            for k, v in pairs(t) do
                local new_key = utils.copy_table(k)
                local new_value = utils.copy_table(v)
                if overwrite then
                    new[new_key] = new_value
                else
                    new[new_key] = new[new_key] == nil and new_value or new[new_key]
                end
            end
            setmetatable(new, utils.copy_table(getmetatable(t)))
            return new
        else
            return t
        end
    end

    function utils.table_remove_first(t, value)
        for k = 1, #t do
            if t[k] == value then
                table.remove(t, k)
                return
            end
        end
    end

    function utils.table_is_empty(t)
        if type(t) ~= "table" then
            return false
        end
        for _, _ in pairs(t) do
            return false
        end
        return true
    end

    function utils.iterate_keys(t)
        local a, b, c = pairs(t)
        return function()
            c = a(b, c)
            return c
        end
    end

    function utils.create_keys_table(t)
        local retval = {}
        for k, _ in pairsbykeys(t) do
            table.insert(retval, k)
        end
        return retval
    end

    function utils.create_lookup_table(t)
        local lookup = {}
        for _, v in pairs(t) do
            lookup[v] = true
        end
        return lookup
    end

    function utils.round(value, places)
        places = places or 0
        local multiplier = 10^places
        local ret = math.floor(value * multiplier + 0.5)

        return places == 0 and ret or ret / multiplier
    end

    function utils.to_integer_if_whole(value)
        local int = math.floor(value)
        return value == int and int or value
    end

    function utils.calc_roman_numeral(num)
        local thousands = {'M','MM','MMM'}
        local hundreds = {'C','CC','CCC','CD','D','DC','DCC','DCCC','CM'}
        local tens = {'X','XX','XXX','XL','L','LX','LXX','LXXX','XC'}	
        local ones = {'I','II','III','IV','V','VI','VII','VIII','IX'}
        local roman_numeral = ''
        if math.floor(num/1000)>0 then roman_numeral = roman_numeral..thousands[math.floor(num/1000)] end
        if math.floor((num%1000)/100)>0 then roman_numeral=roman_numeral..hundreds[math.floor((num%1000)/100)] end
        if math.floor((num%100)/10)>0 then roman_numeral=roman_numeral..tens[math.floor((num%100)/10)] end
        if num%10>0 then roman_numeral = roman_numeral..ones[num%10] end
        return roman_numeral
    end

    function utils.calc_ordinal(num)
        local units = num % 10
        local tens = num % 100
        if units == 1 and tens ~= 11 then
            return num .. "st"
        elseif units == 2 and tens ~= 12 then
            return num .. "nd"
        elseif units == 3 and tens ~= 13 then
            return num .. "rd"
        end
        return num .. "th"
    end

    function utils.calc_alphabet(num)
        local letter = ((num - 1) % 26) + 1
        local n = math.floor((num - 1) / 26)
        return string.char(64 + letter) .. (n > 0 and n or "")
    end

    function utils.clamp(num, minimum, maximum)
        return math.min(math.max(num, minimum), maximum)
    end

    function utils.ltrim(str)
        return string.match(str, "^%s*(.*)")
    end

    function utils.rtrim(str)
        return string.match(str, "(.-)%s*$")
    end

    function utils.trim(str)
        return utils.ltrim(utils.rtrim(str))
    end

    local pcall_wrapper
    local rethrow_placeholder = "tryfunczzz"
    local pcall_line = debug.getinfo(1, "l").currentline + 2
    function utils.call_and_rethrow(levels, tryfunczzz, ...)
        return pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))

    end

    local source = debug.getinfo(1, "S").source
    local source_is_file = source:sub(1, 1) == "@"
    if source_is_file then
        source = source:sub(2)
    end

    pcall_wrapper = function(levels, success, result, ...)
        if not success then
            local file
            local line
            local msg
            file, line, msg = result:match("([a-zA-Z]-:?[^:]+):([0-9]+): (.+)")
            msg = msg or result
            local file_is_truncated = file and file:sub(1, 3) == "..."
            file = file_is_truncated and file:sub(4) or file



            if file
                and line
                and source_is_file
                and (file_is_truncated and source:sub(-1 * file:len()) == file or file == source)
                and tonumber(line) == pcall_line
            then
                local d = debug.getinfo(levels, "n")

                msg = msg:gsub("'" .. rethrow_placeholder .. "'", "'" .. (d.name or "") .. "'")

                if d.namewhat == "method" then
                    local arg = msg:match("^bad argument #(%d+)")
                    if arg then
                        msg = msg:gsub("#" .. arg, "#" .. tostring(tonumber(arg) - 1), 1)
                    end
                end
                error(msg, levels + 1)


            else
                error(result, 0)
            end
        end
        return ...
    end

    function utils.rethrow_placeholder()
        return "'" .. rethrow_placeholder .. "'"
    end

    function utils.show_notes_dialog(parent, caption, width, height)
        if not finaleplugin.RTFNotes and not finaleplugin.Notes then
            return
        end
        if parent and (type(parent) ~= "userdata" or not parent.ExecuteModal) then
            error("argument 1 must be nil or an instance of FCResourceWindow", 2)
        end
        local function dedent(input)
            local first_line_indent = input:match("^(%s*)")
            local pattern = "\n" .. string.rep(" ", #first_line_indent)
            local result = input:gsub(pattern, "\n")
            result = result:gsub("^%s+", "")
            return result
        end
        local function replace_font_sizes(rtf)
            local font_sizes_json  = rtf:match("{\\info%s*{\\comment%s*(.-)%s*}}")
            if font_sizes_json then
                local cjson = require("cjson.safe")
                local font_sizes = cjson.decode('{' .. font_sizes_json .. '}')
                if font_sizes and font_sizes.os then
                    local this_os = finenv.UI():IsOnWindows() and 'win' or 'mac'
                    if (font_sizes.os == this_os) then
                        rtf = rtf:gsub("fs%d%d", font_sizes)
                    end
                end
            end
            return rtf
        end
        if not caption then
            caption = plugindef():gsub("%.%.%.", "")
            if finaleplugin.Version then
                local version = finaleplugin.Version
                if string.sub(version, 1, 1) ~= "v" then
                    version = "v" .. version
                end
                caption = string.format("%s %s", caption, version)
            end
        end
        if finenv.MajorVersion == 0 and finenv.MinorVersion < 68 and finaleplugin.Notes then
            finenv.UI():AlertInfo(dedent(finaleplugin.Notes), caption)
        else
            local notes = dedent(finaleplugin.RTFNotes or finaleplugin.Notes)
            if finaleplugin.RTFNotes then
                notes = replace_font_sizes(notes)
            end
            width = width or 500
            height = height or 350

            local dlg = finale.FCCustomLuaWindow()
            dlg:SetTitle(finale.FCString(caption))
            local edit_text = dlg:CreateTextEditor(10, 10)
            edit_text:SetWidth(width)
            edit_text:SetHeight(height)
            edit_text:SetUseRichText(finaleplugin.RTFNotes)
            edit_text:SetReadOnly(true)
            edit_text:SetWordWrap(true)
            local ok = dlg:CreateOkButton()
            dlg:RegisterInitWindow(
                function()
                    local notes_str = finale.FCString(notes)
                    if edit_text:GetUseRichText() then
                        edit_text:SetRTFString(notes_str)
                    else
                        local edit_font = finale.FCFontInfo()
                        edit_font.Name = "Arial"
                        edit_font.Size = finenv.UI():IsOnWindows() and 9 or 12
                        edit_text:SetFont(edit_font)
                        edit_text:SetText(notes_str)
                    end
                    edit_text:ResetColors()
                    ok:SetKeyboardFocus()
                end)
            dlg:ExecuteModal(parent)
        end
    end

    function utils.win_mac(windows_value, mac_value)
        if finenv.UI():IsOnWindows() then
            return windows_value
        end
        return mac_value
    end

    function utils.split_file_path(full_path)
        local path_name = finale.FCString()
        local file_name = finale.FCString()
        local file_path = finale.FCString(full_path)

        if file_path:FindFirst("/") >= 0 or (finenv.UI():IsOnWindows() and file_path:FindFirst("\\") >= 0) then
            file_path:SplitToPathAndFile(path_name, file_name)
        else
            file_name.LuaString = full_path
        end

        local extension = file_name.LuaString:match("^.+(%..+)$")
        extension = extension or ""
        if #extension > 0 then

            local truncate_pos = file_name.Length - finale.FCString(extension).Length
            if truncate_pos > 0 then
                file_name:TruncateAt(truncate_pos)
            else
                extension = ""
            end
        end
        path_name:AssureEndingPathDelimiter()
        return path_name.LuaString, file_name.LuaString, extension
    end

    function utils.eachfile(directory_path, recursive)
        if finenv.MajorVersion <= 0 and finenv.MinorVersion < 68 then
            error("utils.eachfile requires at least RGP Lua v0.68.", 2)
        end
        recursive = recursive or false
        local lfs = require('lfs')
        local text = require('luaosutils').text
        local fcstr = finale.FCString(directory_path)
        fcstr:AssureEndingPathDelimiter()
        directory_path = fcstr.LuaString

        local lfs_directory_path = text.convert_encoding(directory_path, text.get_utf8_codepage(), text.get_default_codepage())
        return coroutine.wrap(function()
            for lfs_file in lfs.dir(lfs_directory_path) do
                if lfs_file ~= "." and lfs_file ~= ".." then
                    local utf8_file = text.convert_encoding(lfs_file, text.get_default_codepage(), text.get_utf8_codepage())
                    local mode = lfs.attributes(lfs_directory_path .. lfs_file, "mode")
                    if mode == "directory" then
                        if recursive then
                            for subdir, subfile in utils.eachfile(directory_path .. utf8_file, recursive) do
                                coroutine.yield(subdir, subfile)
                            end
                        end
                    elseif (mode == "file" or mode == "link") and lfs_file:sub(1, 2) ~= "._" then
                        coroutine.yield(directory_path, utf8_file)
                    end
                end
            end
        end)
    end

    function utils.parse_codepoint(codepoint_string)
        return tonumber(codepoint_string:match("U%+(%x+)"), 16)
    end

    function utils.format_codepoint(codepoint)
        return string.format("U+%04X", codepoint)
    end
    return utils
end
package.preload["library.configuration"] = package.preload["library.configuration"] or function()



    local configuration = {}
    local utils = require("library.utils")
    local script_settings_dir = "script_settings"
    local comment_marker = "--"
    local parameter_delimiter = "="
    local path_delimiter = "/"
    local file_exists = function(file_path)
        local f = io.open(file_path, "r")
        if nil ~= f then
            io.close(f)
            return true
        end
        return false
    end
    parse_parameter = function(val_string)
        if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "\"(.+)\"", "%1")
        elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "'(.+)'", "%1")
        elseif "{" == val_string:sub(1, 1) and "}" == val_string:sub(#val_string, #val_string) then
            return load("return " .. val_string)()
        elseif "true" == val_string then
            return true
        elseif "false" == val_string then
            return false
        end
        return tonumber(val_string)
    end
    local get_parameters_from_file = function(file_path, parameter_list)
        local file_parameters = {}
        if not file_exists(file_path) then
            return false
        end
        for line in io.lines(file_path) do
            local comment_at = string.find(line, comment_marker, 1, true)
            if nil ~= comment_at then
                line = string.sub(line, 1, comment_at - 1)
            end
            local delimiter_at = string.find(line, parameter_delimiter, 1, true)
            if nil ~= delimiter_at then
                local name = utils.trim(string.sub(line, 1, delimiter_at - 1))
                local val_string = utils.trim(string.sub(line, delimiter_at + 1))
                file_parameters[name] = parse_parameter(val_string)
            end
        end
        local function process_table(param_table, param_prefix)
            param_prefix = param_prefix and param_prefix.."." or ""
            for param_name, param_val in pairs(param_table) do
                local file_param_name = param_prefix .. param_name
                local file_param_val = file_parameters[file_param_name]
                if nil ~= file_param_val then
                    param_table[param_name] = file_param_val
                elseif type(param_val) == "table" then
                        process_table(param_val, param_prefix..param_name)
                end
            end
        end
        process_table(parameter_list)
        return true
    end

    function configuration.get_parameters(file_name, parameter_list)
        local path
        if finenv.IsRGPLua then
            path = finenv.RunningLuaFolderPath()
        else
            local str = finale.FCString()
            str:SetRunningLuaFolderPath()
            path = str.LuaString
        end
        local file_path = path .. script_settings_dir .. path_delimiter .. file_name
        return get_parameters_from_file(file_path, parameter_list)
    end


    local calc_preferences_filepath = function(script_name)
        local str = finale.FCString()
        str:SetUserOptionsPath()
        local folder_name = str.LuaString
        if not finenv.IsRGPLua and finenv.UI():IsOnMac() then

            folder_name = os.getenv("HOME") .. folder_name:sub(2)
        end
        if finenv.UI():IsOnWindows() then
            folder_name = folder_name .. path_delimiter .. "FinaleLua"
        end
        local file_path = folder_name .. path_delimiter
        if finenv.UI():IsOnMac() then
            file_path = file_path .. "com.finalelua."
        end
        file_path = file_path .. script_name .. ".settings.txt"
        return file_path, folder_name
    end

    function configuration.save_user_settings(script_name, parameter_list)
        local file_path, folder_path = calc_preferences_filepath(script_name)
        local file = io.open(file_path, "w")
        if not file and finenv.UI():IsOnWindows() then

            local osutils = finenv.EmbeddedLuaOSUtils and require("luaosutils")
            if osutils then
                osutils.process.make_dir(folder_path)
            else
                os.execute('mkdir "' .. folder_path ..'"')
            end
            file = io.open(file_path, "w")
        end
        if not file then
            return false
        end
        file:write("-- User settings for " .. script_name .. ".lua\n\n")
        for k,v in pairs(parameter_list) do
            if type(v) == "string" then
                v = "\"" .. v .."\""
            else
                v = tostring(v)
            end
            file:write(k, " = ", v, "\n")
        end
        file:close()
        return true
    end

    function configuration.get_user_settings(script_name, parameter_list, create_automatically)
        if create_automatically == nil then create_automatically = true end
        local exists = get_parameters_from_file(calc_preferences_filepath(script_name), parameter_list)
        if not exists and create_automatically then
            configuration.save_user_settings(script_name, parameter_list)
        end
        return exists
    end
    return configuration
end
package.preload["library.measurement"] = package.preload["library.measurement"] or function()

    local measurement = {}
    local unit_names = {
        [finale.MEASUREMENTUNIT_EVPUS] = "EVPUs",
        [finale.MEASUREMENTUNIT_INCHES] = "Inches",
        [finale.MEASUREMENTUNIT_CENTIMETERS] = "Centimeters",
        [finale.MEASUREMENTUNIT_POINTS] = "Points",
        [finale.MEASUREMENTUNIT_PICAS] = "Picas",
        [finale.MEASUREMENTUNIT_SPACES] = "Spaces",
    }
    local unit_suffixes = {
        [finale.MEASUREMENTUNIT_EVPUS] = "e",
        [finale.MEASUREMENTUNIT_INCHES] = "i",
        [finale.MEASUREMENTUNIT_CENTIMETERS] = "c",
        [finale.MEASUREMENTUNIT_POINTS] = "pt",
        [finale.MEASUREMENTUNIT_PICAS] = "p",
        [finale.MEASUREMENTUNIT_SPACES] = "s",
    }
    local unit_abbreviations = {
        [finale.MEASUREMENTUNIT_EVPUS] = "ev",
        [finale.MEASUREMENTUNIT_INCHES] = "in",
        [finale.MEASUREMENTUNIT_CENTIMETERS] = "cm",
        [finale.MEASUREMENTUNIT_POINTS] = "pt",
        [finale.MEASUREMENTUNIT_PICAS] = "pc",
        [finale.MEASUREMENTUNIT_SPACES] = "sp",
    }

    function measurement.convert_to_EVPUs(text)
        local str = finale.FCString()
        str.LuaString = text
        return str:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)
    end

    function measurement.get_unit_name(unit)
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end
        return unit_names[unit]
    end

    function measurement.get_unit_suffix(unit)
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end
        return unit_suffixes[unit]
    end

    function measurement.get_unit_abbreviation(unit)
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end
        return unit_abbreviations[unit]
    end

    function measurement.is_valid_unit(unit)
        return unit_names[unit] and true or false
    end

    function measurement.get_real_default_unit()
        local str = finale.FCString()
        finenv.UI():GetDecimalSeparator(str)
        local separator = str.LuaString
        str:SetMeasurement(72, finale.MEASUREMENTUNIT_DEFAULT)
        if str.LuaString == "72" then
            return finale.MEASUREMENTUNIT_EVPUS
        elseif str.LuaString == "0" .. separator .. "25" then
            return finale.MEASUREMENTUNIT_INCHES
        elseif str.LuaString == "0" .. separator .. "635" then
            return finale.MEASUREMENTUNIT_CENTIMETERS
        elseif str.LuaString == "18" then
            return finale.MEASUREMENTUNIT_POINTS
        elseif str.LuaString == "1p6" then
            return finale.MEASUREMENTUNIT_PICAS
        elseif str.LuaString == "3" then
            return finale.MEASUREMENTUNIT_SPACES
        end
    end
    return measurement
end
package.preload["library.score"] = package.preload["library.score"] or function()

    local library = require("library.general_library")
    local configuration = require("library.configuration")
    local measurement = require("library.measurement")
    local config = {use_uppercase_staff_names = false, hide_default_whole_rests = false}
    configuration.get_parameters("score.config.txt", config)
    local score = {}
    local CLEF_MAP = {treble = 0, alto = 1, tenor = 2, bass = 3, percussion = 12, grand_staff = {0, 3}, organ = {0, 3, 3}, treble_8ba = 5, tenor_voice = 5}
    local BRACE_MAP = {
        none = finale.GRBRAC_NONE,
        plain = finale.GRBRAC_PLAIN,
        chorus = finale.GRBRAC_CHORUS,
        piano = finale.GRBRAC_PIANO,
        reverse_chorus = finale.GRBRAC_REVERSECHORUS,
        reverse_piano = finale.GRBRAC_REVERSEPIANO,
        curved_chorus = finale.GRBRAC_CURVEDCHORUS,
        reverse_curved_chorus = finale.GRBRAC_REVERSECURVEDCHORUS,
        desk = finale.GRBRAC_DESK,
        reverse_desk = finale.GRBRAC_REVERSEDESK,
    }
    local KEY_MAP = {}
    KEY_MAP.c = 0
    KEY_MAP.g = -1
    KEY_MAP.d = -2
    KEY_MAP.a = -3
    KEY_MAP.e = -4
    KEY_MAP.b = -5
    KEY_MAP["f#"] = -6
    KEY_MAP["c#"] = -7
    KEY_MAP["g#"] = -8
    KEY_MAP["d#"] = -9
    KEY_MAP["a#"] = -10
    KEY_MAP["e#"] = -11
    KEY_MAP["b#"] = -12
    KEY_MAP.f = 1
    KEY_MAP.bb = 2
    KEY_MAP.eb = 3
    KEY_MAP.ab = 4
    KEY_MAP.db = 5
    KEY_MAP.gb = 6
    KEY_MAP.cb = 7
    KEY_MAP.fb = 8

    local VOICE_INSTRUMENTS = {
        finale.FFUUID_ALTOVOICE,
        finale.FFUUID_BARITONEVOICE,
        finale.FFUUID_BASSBAROTONEVOICE,
        finale.FFUUID_BASSVOICE,
        finale.FFUUID_BEATBOX,
        finale.FFUUID_CHOIRAAHS,
        finale.FFUUID_CHOIROOHS,
        finale.FFUUID_CONTRALTOVOICE,
        finale.FFUUID_COUNTERTENORVOICE,
        finale.FFUUID_MEZZOSOPRANOVOICE,
        finale.FFUUID_SOPRANOVOICE,
        finale.FFUUID_TALKBOX,
        finale.FFUUID_TENORVOICE,
        finale.FFUUID_VOCALPERCUSSION,
        finale.FFUUID_VOCALS,
        finale.FFUUID_VOICE,
        finale.FFUUID_YODEL
    }

    function score.create_default_config()
        local default_config = {
            use_large_time_signatures = false,
            use_large_measure_numbers = false,
            use_keyless_staves = false,
            show_default_whole_rests = true,
            score_page_width = "8.5i",
            score_page_height = "11i",
            part_page_width = "8.5i",
            part_page_height = "11i",
            systems_per_page = 1,
            max_measures_per_system = 0,
            large_measure_number_space = "14s",
        }
        configuration.get_parameters("score_create_new_score_defaults.config.txt", default_config)
        return default_config
    end

    function score.delete_all_staves()
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            staff:DeleteData()
        end
        staves:SaveAll()
    end

    function score.reset_and_clear_score()
        score.delete_all_staves()
    end

    function score.set_show_staff_time_signature(staff_id, show_time_signature)
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        if show_time_signature == nil then
            staff.ShowScoreTimeSignatures = true
        else
            staff.ShowScoreTimeSignatures = show_time_signature
        end
        staff:Save()
        return staff_id
    end

    function score.set_show_all_staves_time_signature(show_time_signature)
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            score.set_show_staff_time_signature(staff:GetItemNo(), show_time_signature)
        end
    end

    function score.set_staff_transposition(staff_id, key, interval, clef)
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        staff.TransposeAlteration = KEY_MAP[key:lower()]
        staff.TransposeInterval = interval or 0
        if clef then
            staff.TransposeClefIndex = CLEF_MAP[clef]
            staff.TransposeUseClef = true
        end
        staff:Save()
        return staff_id
    end

    function score.set_staff_allow_hiding(staff_id, allow_hiding)
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        staff.AllowHiding = allow_hiding or true
        staff:Save()
        return staff_id
    end

    function score.set_staff_keyless(staff_id, is_keyless)
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        staff.NoKeySigShowAccidentals = is_keyless or true
        staff:Save()
        return staff_id
    end

    function score.set_all_staves_keyless(is_keyless)
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            score.set_staff_keyless(staff:GetItemNo(), is_keyless)
        end
    end

    function score.set_staff_show_default_whole_rests(staff_id, show_whole_rests)
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        staff:SetDisplayEmptyRests(show_whole_rests)
        staff:Save()
        return staff_id
    end

    function score.set_all_staves_show_default_whole_rests(show_whole_rests)
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            score.set_staff_show_default_whole_rests(staff:GetItemNo(), show_whole_rests)
        end
    end

    function score.add_space_above_staff(staff_id)
        local lists = finale.FCStaffLists()
        lists:SetMode(finale.SLMODE_CATEGORY_SCORE)
        lists:LoadAll()
        local list = lists:GetItemAt(0)
        list:AddStaff(staff_id)
        list:Save()

        local system_staves = finale.FCSystemStaves()
        system_staves:LoadAllForItem(1)
        for system_staff in each(system_staves) do
            if system_staff.Staff == staff_id then
                system_staff.Distance = system_staff.Distance + measurement.convert_to_EVPUs(tostring("6s"))
            end
            system_staff:Save()
        end
    end

    function score.set_staff_full_name(staff, full_name, double)
        local str = finale.FCString()
        if config.use_uppercase_staff_names then
            str.LuaString = string.upper(full_name):gsub("%^FLAT%(%)", "^flat()")
        else
            str.LuaString = full_name
        end
        if (double ~= nil) then
            str.LuaString = str.LuaString .. "^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. double ..
            "\r^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. (double + 1)
        end
        staff:SaveNewFullNameString(str)
    end

    function score.set_staff_short_name(staff, short_name, double)
        local str = finale.FCString()
        if config.use_uppercase_staff_names then
            str.LuaString = string.upper(short_name):gsub("%^FLAT%(%)", "^flat()")
        else
            str.LuaString = short_name
        end
        if (double ~= nil) then
            str.LuaString = str.LuaString .. "^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. double ..
            "\r^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. (double + 1)
        end
        staff:SaveNewAbbreviatedNameString(str)
    end

    function score.create_staff(full_name, short_name, type, clef, double)
        local staff_id = finale.FCStaves.Append()
        if staff_id then

            local staff = finale.FCStaff()
            staff:Load(staff_id)
            staff.InstrumentUUID = type
            staff:SetDefaultClef(CLEF_MAP[clef])
            if config.hide_default_whole_rests then
                staff:SetDisplayEmptyRests(false)
            end
            score.set_staff_full_name(staff, full_name, double)
            score.set_staff_short_name(staff, short_name, double)

            staff:Save()
            return staff:GetItemNo()
        end
        return -1
    end

    function score.create_staff_spaced(full_name, short_name, type, clef)
        local staff_id = score.create_staff(full_name, short_name, type, clef)
        score.add_space_above_staff(staff_id)
        return staff_id
    end

    function score.create_staff_percussion(full_name, short_name)
        local staff_id = score.create_staff(full_name, short_name, finale.FFUUID_PERCUSSIONGENERAL, "percussion")
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        staff:SetNotationStyle(finale.STAFFNOTATION_PERCUSSION)
        staff:SavePercussionLayout(1, 0)
        return staff_id
    end

    function score.create_group(start_staff, end_staff, brace_name, has_barline, level, full_name, short_name)
        local sg_cmper = {}
        local staff_groups = finale.FCGroups()
        staff_groups:LoadAll()
        for sg in each(staff_groups) do
            table.insert(sg_cmper, sg:GetItemID())
        end
        table.sort(sg_cmper)
        local sg = finale.FCGroup()
        sg:SetStartStaff(start_staff)
        sg:SetEndStaff(end_staff)
        sg:SetStartMeasure(1)
        sg:SetEndMeasure(32767)
        sg:SetBracketStyle(BRACE_MAP[brace_name])
        if start_staff == end_staff then
            sg:SetBracketSingleStaff(true)
        end
        if (has_barline) then
            sg:SetDrawBarlineMode(finale.GROUPBARLINESTYLE_THROUGH)
        end
        local bracket_position = -12 * level
        if brace_name == "desk" then
            bracket_position = bracket_position - 6
        end
        sg:SetBracketHorizontalPos(bracket_position)

        if full_name then
            local str = finale.FCString()
            str.LuaString = full_name
            sg:SaveNewFullNameBlock(str)
            sg:SetShowGroupName(true)
            sg:SetFullNameHorizontalOffset(measurement.convert_to_EVPUs("2s"))
        end
        if short_name then
            local str = finale.FCString()
            str.LuaString = short_name
            sg:SaveNewAbbreviatedNameBlock(str)
            sg:SetShowGroupName(true)
        end
        if sg_cmper[1] == nil then
            sg:SaveNew(1)
        else
            local save_num = sg_cmper[1] + 1
            sg:SaveNew(save_num)
        end
    end

    function score.create_group_primary(start_staff, end_staff, full_name, short_name)
        score.create_group(start_staff, end_staff, "curved_chorus", true, 1, full_name, short_name)
    end

    function score.create_group_secondary(start_staff, end_staff, full_name, short_name)
        score.create_group(start_staff, end_staff, "desk", false, 2, full_name, short_name)
    end

    function score.calc_system_scalings(systems_per_page)
        local score_page_format_prefs = finale.FCPageFormatPrefs()
        score_page_format_prefs:LoadScore()
        local page_height = score_page_format_prefs:GetPageHeight()
        local margin_top = score_page_format_prefs:GetLeftPageTopMargin()
        local margin_bottom = score_page_format_prefs:GetLeftPageBottomMargin()
        local available_height = page_height - margin_top - margin_bottom
        local staff_systems = finale.FCStaffSystems()
        staff_systems:LoadAll()

        local system = staff_systems:GetItemAt(0)
        local first_system_height = system:CalcHeight(false)

        local system_height = first_system_height
        system_height = system_height - score_page_format_prefs:GetFirstSystemTop()
        system_height = system_height + score_page_format_prefs:GetSystemTop()

        local staff_height = score_page_format_prefs:GetSystemStaffHeight() / 16
        local staff_scaling = staff_height / measurement.convert_to_EVPUs("4s")
        first_system_height = first_system_height * staff_scaling
        system_height = system_height * staff_scaling
        local total_systems_height = (system_height * (systems_per_page or 1))
        local first_page_total_systems_height = first_system_height + total_systems_height - system_height
        local global_scaling = available_height / total_systems_height
        local first_page_scaling = available_height / first_page_total_systems_height
        return math.floor(first_page_scaling * 100), math.floor(global_scaling * 100)
    end

    function score.set_global_system_scaling(scaling)
        local format = finale.FCPageFormatPrefs()
        format:LoadScore()
        format:SetSystemScaling(scaling)
        format:Save()
        local staff_systems = finale.FCStaffSystems()
        staff_systems:LoadAll()
        for system in each(staff_systems) do
            system:SetResize(scaling)
            system:Save()
        end
        finale.FCStaffSystems.UpdateFullLayout()
    end

    function score.set_single_system_scaling(system_number, scaling)
        local staff_systems = finale.FCStaffSystems()
        staff_systems:LoadAll()
        local system = staff_systems:GetItemAt(system_number)
        if system then
            system:SetResize(scaling)
            system:Save()
        end
    end

    function score.set_large_time_signatures_settings()
        local font_preferences = finale.FCFontPrefs()
        font_preferences:Load(finale.FONTPREF_TIMESIG)
        local font_info = font_preferences:CreateFontInfo()
        font_info:SetSize(40)
        font_info.Name = "EngraverTime"
        font_preferences:SetFontInfo(font_info)
        font_preferences:Save()
        local distance_preferences = finale.FCDistancePrefs()
        distance_preferences:Load(1)
        distance_preferences:SetTimeSigBottomVertical(-290)
        distance_preferences:Save()
    end

    function score.use_large_time_signatures(uses_large_time_signatures, staves_with_time_signatures)
        if not uses_large_time_signatures then
            return
        end
        score.set_large_time_signatures_settings()
        score.set_show_all_staves_time_signature(false)
        for _, staff_id in ipairs(staves_with_time_signatures) do
            score.set_show_staff_time_signature(staff_id, true)
        end
    end

    function score.use_large_measure_numbers(distance)
        local systems = finale.FCStaffSystem()
        systems:Load(1)
        local font_size = 0
        for m in loadall(finale.FCMeasureNumberRegions()) do
            m:SetUseScoreInfoForParts(false)
            local font_preferences = finale.FCFontPrefs()
            font_preferences:Load(finale.FONTPREF_MEASURENUMBER)
            local font = font_preferences:CreateFontInfo()
            m:SetMultipleFontInfo(font, false)
            m:SetShowOnTopStaff(false, false)
            m:SetShowOnSystemStart(false, false)
            m:SetShowOnBottomStaff(true, false)
            m:SetExcludeOtherStaves(true, false)
            m:SetShowMultiples(true, false)
            m:SetHideFirstNumber(false, false)
            m:SetMultipleAlignment(finale.MNALIGN_CENTER, false)
            m:SetMultipleJustification(finale.MNJUSTIFY_CENTER, false)

            local position = -1 * measurement.convert_to_EVPUs(distance)
            m:SetMultipleVerticalPosition(position, false)
            m:Save()
            font_size = font:GetSize()
        end

        local score_page_format_prefs = finale.FCPageFormatPrefs()
        score_page_format_prefs:LoadScore()
        local system_margin_bottom = score_page_format_prefs:GetSystemBottom()
        local needed_margin = font_size * 4 + measurement.convert_to_EVPUs(distance)
        if system_margin_bottom < needed_margin then
            score_page_format_prefs:SetSystemBottom(needed_margin)
            score_page_format_prefs:Save()
            local staff_systems = finale.FCStaffSystems()
            staff_systems:LoadAll()
            for staff_system in each(staff_systems) do
                staff_system:SetBottomMargin(needed_margin)
                staff_system:Save()
            end
        end
    end

    function score.set_max_measures_per_system(max_measures_per_system)
        if max_measures_per_system == 0 then
            return
        end
        local score_page_format_prefs = finale.FCPageFormatPrefs()
        score_page_format_prefs:LoadScore()
        local page_width = score_page_format_prefs:GetPageWidth()
        local page_margin_left = score_page_format_prefs:GetLeftPageLeftMargin()
        local page_margin_right = score_page_format_prefs:GetLeftPageRightMargin()
        local system_width = page_width - page_margin_left - page_margin_right
        local format = finale.FCPageFormatPrefs()
        format:LoadScore()
        local system_scaling = format:GetSystemScaling()
        local scaled_system_width = system_width / (system_scaling / 100)
        local music_spacing_preferences = finale.FCMusicSpacingPrefs()
        music_spacing_preferences:Load(1)
        music_spacing_preferences:SetMinMeasureWidth(scaled_system_width / max_measures_per_system)
        music_spacing_preferences:Save()
    end

    function score.set_score_page_size(width, height)
        local score_page_format_prefs = finale.FCPageFormatPrefs()
        score_page_format_prefs:LoadScore()
        score_page_format_prefs.PageWidth = measurement.convert_to_EVPUs(width)
        score_page_format_prefs.PageHeight = measurement.convert_to_EVPUs(height)
        score_page_format_prefs:Save()
        local pages = finale.FCPages()
        pages:LoadAll()
        for page in each(pages) do
            page:SetWidth(measurement.convert_to_EVPUs(width))
            page:SetHeight(measurement.convert_to_EVPUs(height))
        end
        pages:SaveAll()
    end

    function score.set_all_parts_page_size(width, height)
        local part_page_format_prefs = finale.FCPageFormatPrefs()
        part_page_format_prefs:LoadParts()
        part_page_format_prefs.PageWidth = measurement.convert_to_EVPUs(width)
        part_page_format_prefs.PageHeight = measurement.convert_to_EVPUs(height)
        part_page_format_prefs:Save()
        local parts = finale.FCParts()
        parts:LoadAll()
        local pages = finale.FCPages()
        for part in each(parts) do
            part:SwitchTo()
            if not part:IsScore() then
                pages:LoadAll()
                for page in each(pages) do
                    page:SetWidth(measurement.convert_to_EVPUs(width))
                    page:SetHeight(measurement.convert_to_EVPUs(height))
                end
                pages:SaveAll()
            end
        end
    end

    function score.apply_config(config, options)
        score.set_score_page_size(config.score_page_width, config.score_page_height)
        score.set_all_parts_page_size(config.part_page_width, config.part_page_height)
        library.update_layout()
        score.set_all_staves_keyless(config.use_keyless_staves)
        score.set_all_staves_show_default_whole_rests(config.show_default_whole_rests)
        score.use_large_time_signatures(config.use_large_time_signatures, options.force_staves_show_time_signatures)
        if config.use_large_measure_numbers then
            score.use_large_measure_numbers(config.large_measure_number_space)
        end
        local first_page_scaling, global_scaling = score.calc_system_scalings(config.systems_per_page)
        score.set_global_system_scaling(global_scaling)
        for i = 0, config.systems_per_page - 1, 1 do
            score.set_single_system_scaling(i, first_page_scaling)
        end
        score.set_max_measures_per_system(config.max_measures_per_system)
        library.update_layout()
    end

    function score.calc_voice_staff(staff_num)
        local is_voice_staff = false
        local staff = finale.FCStaff()
        if staff:Load(staff_num) then
            local staff_instrument = staff:GetInstrumentUUID()
            for _, v in pairs(VOICE_INSTRUMENTS) do
                if staff_instrument == v then
                    is_voice_staff = true
                end
            end
        end
        return is_voice_staff
    end

    function score.calc_has_optimized_systems()
        local staff_systems = finale.FCStaffSystems()
        staff_systems:LoadAll()
        local scroll_view = finale.FCSystemStaves()
        scroll_view:LoadScrollView()
        for staff_system in each(staff_systems) do
            local next_system = finale.FCSystemStaves()
            next_system:LoadAllForItem(staff_system.ItemNo)
            if next_system.Count ~= scroll_view.Count then
                return true
            end
            for staff_index = 0, next_system.Count - 1 do
                if next_system:GetItemAt(staff_index).Staff ~= scroll_view:GetItemAt(staff_index).Staff then
                    return true
                end
            end
        end
        return false
    end
    return score
end
function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.3"
    finaleplugin.Date = "December 31, 2024"
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.75
    finaleplugin.Notes = [[
        Exports settings from one or more Finale documents into a MuseScore `.mss` style settings file.
        Only a subset of possible MuseScore settings are exported. The rest will be taken
        from the default settings you have set up for MuseScore when you load it in MuseScore.

        This script addresses two uses cases.

        ## Setting up your MuseScore defaults to be close to those of Finale ##

        - Open a Finale template file or document style file that you wish to use as the basis for your MuseScore defaults.
        - Select the score or part for which you wish to export style settings.
        - Choose "Export Document Options to MuseScore...".
        - Choose a location where to save the output. It is recommended to append `.part.mss` to the name of the style settings for parts.
        - Import each of the score and part settings into a blank document in MuseScore.
        - Make any style adjustments as needed and then save them back out. (This gives them all the settings.)
        - Use the score `.mss` file for Preferences->Score->Style.
        - Use the parts `.mss` file for Preferences->Score->Style for part.

        Now any new projects will start up with these defaults.

        ## Improving MusicXML imports of your documents ##

        - Choose "Export Folder Document Options to MuseScore..." with no document open.
        - Select a folder containing your Finale files. All subfolders will be searched as well.
        - For every Finale file found, a parallel `.mss` file is created.
        - If the source Finale file contains at least one linked part, a parallel `.part.mss` file is created as well (from the first part found).
        - After importing the MusicXML version of your document, use Style->Load style in MuseScore to load the settings for the document.
        - Repeat the process for each part, if any.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Export Folder Document Options to MuseScore...
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Recursively search a folder and its subfolders and export document options for Finale files to score and part MuseScore style files.
    ]]
    finaleplugin.AdditionalPrefixes = [[
        do_folder = true
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 Exports settings from one or more Finale documents into a MuseScore {\f1 .mss} style settings file. Only a subset of possible MuseScore settings are exported. The rest will be taken from the default settings you have set up for MuseScore when you load it in MuseScore.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script addresses two uses cases.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 \outlinelevel1 \b \fs23 Setting up your MuseScore defaults to be close to those of Finale\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Open a Finale template file or document style file that you wish to use as the basis for your MuseScore defaults.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Select the score or part for which you wish to export style settings.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Choose \u8220"Export Document Options to MuseScore\u8230 ?\u8221".\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Choose a location where to save the output. It is recommended to append {\f1 .part.mss} to the name of the style settings for parts.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Import each of the score and part settings into a blank document in MuseScore.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Make any style adjustments as needed and then save them back out. (This gives them all the settings.)\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Use the score {\f1 .mss} file for Preferences->Score->Style.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Use the parts {\f1 .mss} file for Preferences->Score->Style for part.\sa180\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 Now any new projects will start up with these defaults.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 \outlinelevel1 \b \fs23 Improving MusicXML imports of your documents\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Choose \u8220"Export Folder Document Options to MuseScore\u8230 ?\u8221" with no document open.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Select a folder containing your Finale files. All subfolders will be searched as well.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab For every Finale file found, a parallel {\f1 .mss} file is created.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab If the source Finale file contains at least one linked part, a parallel {\f1 .part.mss} file is created as well (from the first part found).\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab After importing the MusicXML version of your document, use Style->Load style in MuseScore to load the settings for the document.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Repeat the process for each part, if any.\sa180\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/document_options_to_musescore.hash"
    return "Export Document Options to MuseScore...", "Export Document Options to MuseScore", "Export document options for the current Finale document and part view to a MuseScore style file."
end
local mixin = require("library.mixin")
local enigma_string = require("library.enigma_string")
local utils = require("library.utils")
local client = require("library.client")
local score = require("library.score")
do_folder = do_folder or false
local LOGFILE_NAME <const> = "FinaleMuseScoreSettingsExportLog.txt"
local MUSX_EXTENSION <const> = ".musx"
local MUS_EXTENSION <const> = ".mus"
local TEXT_EXTENSION <const> = ".mss"
local PART_EXTENSION <const> = ".part" .. TEXT_EXTENSION
local MSS_VERSION <const> = "4.50"
local EVPU_PER_INCH <const> = 288
local EVPU_PER_MM <const> = 288 / 25.4
local EVPU_PER_SPACE <const> = 24
local EFIX_PER_EVPU <const> = 64
local EFIX_PER_SPACE <const> = EVPU_PER_SPACE * EFIX_PER_EVPU
local MUSE_FINALE_SCALE_DIFFERENTIAL <const> = 20 / 24
local TIMER_ID <const> = 1
local error_occured = false
local current_is_part
local currently_processing
local logfile_path
function log_message(msg, is_error)
    if is_error and not logfile_path then
        error(msg, 2)
    end
    if is_error then
        error_occured = true
    end
    local file <close> = io.open(logfile_path, "a")
    if not file then
        error("unable to append to logfile " .. logfile_path)
    end
    local log_entry = "[" .. (is_error and "Error " or "Success ") .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. currently_processing .. " " .. msg
    if finenv.ConsoleIsAvailable then
        print(log_entry)
    end
    file:write(log_entry .. "\n")
    file:close()
end
local default_music_font
local distance_prefs
local size_prefs
local misc_prefs
local music_character_prefs
local page_prefs
local spacing_prefs
local repeat_prefs
local smart_shape_prefs
local part_scope_prefs
local layer_one_prefs
local mmrest_prefs
local tie_prefs
local tuplet_prefs
local text_exps
local music_font_name
function open_current_prefs()
    local font_prefs = finale.FCFontPrefs()
    font_prefs:Load(finale.FONTPREF_MUSIC)
    default_music_font = font_prefs:CreateFontInfo()
    distance_prefs = finale.FCDistancePrefs()
    distance_prefs:Load(1)
    size_prefs = finale.FCSizePrefs()
    size_prefs:Load(1)
    misc_prefs = finale.FCMiscDocPrefs()
    misc_prefs:Load(1)
    music_character_prefs = finale.FCMusicCharacterPrefs()
    music_character_prefs:Load(1)
    page_prefs = finale.FCPageFormatPrefs()
    if current_is_part then
        page_prefs:LoadParts()
    else
        page_prefs:LoadScore()
    end
    spacing_prefs = finale.FCMusicSpacingPrefs()
    spacing_prefs:Load(1)
    repeat_prefs = finale.FCRepeatPrefs()
    repeat_prefs:Load(1)
    smart_shape_prefs = finale.FCSmartShapePrefs()
    smart_shape_prefs:Load(1)
    part_scope_prefs = finale.FCPartScopePrefs()
    part_scope_prefs:Load(1)
    layer_one_prefs = finale.FCLayerPrefs()
    layer_one_prefs:Load(0)
    mmrest_prefs = finale.FCMultiMeasureRestPrefs()
    mmrest_prefs:Load(1)
    tie_prefs = finale.FCTiePrefs()
    tie_prefs:Load(1)
    tuplet_prefs = finale.FCTupletPrefs()
    tuplet_prefs:Load(1)
    text_exps = finale.FCTextExpressionDefs()
    text_exps:LoadAll()
    music_font_name = default_music_font.Name
    if default_music_font.IsSMuFLFont then
        music_font_name = default_music_font.Name
    elseif music_font_name == "Broadway Copyist" then
        music_font_name = "Finale Broadway"
    elseif music_font_name == "Engraver" then
        music_font_name = "Finale Engraver"
    elseif music_font_name == "Jazz" then
        music_font_name = "Finale Jazz"
    elseif music_font_name == "Maestro"
        or music_font_name == "Pmusic"
        or music_font_name == "Sonata" then
        music_font_name = "Finale Maestro"
    elseif music_font_name == "Petrucci" then
        music_font_name = "Finale Legacy"

    else
        music_font_name = nil
    end
end
function set_element_text(style_element, name, value)
    local setter_func = "SetText"
    if type(value) == "nil" then
        log_message("incorrect property for " .. name, true)
    elseif type(value) == "number" then
        if math.type(value) == "float" then
            value = string.format("%.5g", value)
            setter_func = "SetText"
        else
            setter_func = "SetIntText"
        end
    elseif type(value) == "boolean" then
        value = value and 1 or 0
        setter_func = "SetIntText"
    end
    local element = style_element:FirstChildElement(name)
    if not element then
        element = style_element:InsertNewChildElement(name)
    end
    element[setter_func](element, value)
    return element
end
function muse_font_efx(font_info)
    local retval = 0
    if font_info.Bold then
        retval = retval | 0x01
    end
    if font_info.Italic then
        retval = retval | 0x02
    end
    if font_info.Underline then
        retval = retval | 0x04
    end
    if font_info.Strikethrough then
        retval = retval | 0x08
    end
    return retval
end
function muse_mag_val(default_font_setting)
    local font_prefs = finale.FCFontPrefs()
    if font_prefs:Load(default_font_setting) then
        local font_info = font_prefs:CreateFontInfo()
        if font_info.Name == default_music_font.Name then
            return font_info.Size / default_music_font.Size
        end
    end
    return 1.0
end
function write_font_pref(style_element, name_prefix, font_info)
    set_element_text(style_element, name_prefix .. "FontFace", font_info.Name)
    set_element_text(style_element, name_prefix .. "FontSize", font_info.Size * (font_info.Absolute and 1 or MUSE_FINALE_SCALE_DIFFERENTIAL))
    set_element_text(style_element, name_prefix .. "FontSpatiumDependent", not font_info.Absolute)
    set_element_text(style_element, name_prefix .. "FontStyle", muse_font_efx(font_info))
end
function write_default_font_pref(style_element, name_prefix, default_font_id)
    local default_font = finale.FCFontPrefs()
    if not default_font:Load(default_font_id) then
        log_message("Unable to load default font pref for " .. name_prefix, true)
    end
    write_font_pref(style_element, name_prefix, default_font:CreateFontInfo())
end
function write_line_prefs(style_element, name_prefix, width_efix, dash_length, dash_gap, style_string)
    local line_width_evpu <const> = width_efix / EFIX_PER_EVPU
    set_element_text(style_element, name_prefix .. "LineWidth", width_efix / EFIX_PER_SPACE)
    if style_string then
        set_element_text(style_element, name_prefix .. "LineStyle", style_string)
    end
    set_element_text(style_element, name_prefix .. "DashLineLen", dash_length / line_width_evpu)
    set_element_text(style_element, name_prefix .. "DashGapLen", dash_gap / line_width_evpu)
end
function write_frame_prefs(style_element, name_prefix, enclosure)
    if not enclosure or enclosure.Shape == finale.ENCLOSURE_NONE or enclosure.LineWidth == 0 then
        set_element_text(style_element, name_prefix .. "FrameType", 0)
        return
    elseif enclosure.Shape == finale.ENCLOSURE_ELLIPSE then
        set_element_text(style_element, name_prefix .. "FrameType", 2)
    else
        set_element_text(style_element, name_prefix .. "FrameType", 1)
    end
    set_element_text(style_element, name_prefix .. "FramePadding", enclosure.HorizontalMargin / EVPU_PER_SPACE)
    set_element_text(style_element, name_prefix .. "FrameWidth", enclosure.LineWidth / EFIX_PER_SPACE)
    set_element_text(style_element, name_prefix .. "FrameRound", enclosure.RoundedCorners and enclosure.RoundedCornerRadius / EFIX_PER_EVPU or 0)
end
function write_category_text_font_pref(style_element, name_prefix, category_id)
    local cat = finale.FCCategoryDef()
    if not cat:Load(category_id) then
        log_message("unable to load category def for " .. name_prefix, true)
    end
    write_font_pref(style_element, name_prefix, cat:CreateTextFontInfo())
    for exp in each(text_exps) do
        if exp.CategoryID == category_id then
            write_frame_prefs(style_element, name_prefix, exp.UseEnclosure and exp:CreateEnclosure() or nil)
            break
        end
    end
end
function write_page_prefs(style_element)
    set_element_text(style_element, "pageWidth", page_prefs.PageWidth / EVPU_PER_INCH)
    set_element_text(style_element, "pageHeight", page_prefs.PageHeight / EVPU_PER_INCH)
    set_element_text(style_element, "pagePrintableWidth",
        (page_prefs.PageWidth - page_prefs.LeftPageLeftMargin - page_prefs.LeftPageRightMargin) / EVPU_PER_INCH)
    set_element_text(style_element, "pageEvenLeftMargin", page_prefs.LeftPageLeftMargin / EVPU_PER_INCH)
    set_element_text(style_element, "pageOddLeftMargin",
        (page_prefs.UseFacingPages and page_prefs.RightPageLeftMargin or page_prefs.LeftPageLeftMargin) / EVPU_PER_INCH)
    set_element_text(style_element, "pageEvenTopMargin", page_prefs.LeftPageTopMargin / EVPU_PER_INCH)
    set_element_text(style_element, "pageEvenBottomMargin", page_prefs.LeftPageBottomMargin / EVPU_PER_INCH)
    set_element_text(style_element, "pageOddTopMargin",
        (page_prefs.UseFacingPages and page_prefs.RightPageTopMargin or page_prefs.LeftPageTopMargin) / EVPU_PER_INCH)
    set_element_text(style_element, "pageOddBottomMargin",
        (page_prefs.UseFacingPages and page_prefs.RightPageBottomMargin or page_prefs.LeftPageBottomMargin) / EVPU_PER_INCH)
    set_element_text(style_element, "pageTwosided", page_prefs.UseFacingPages)
    set_element_text(style_element, "enableIndentationOnFirstSystem", page_prefs.UseFirstSystemMargins)
    set_element_text(style_element, "firstSystemIndentationValue", page_prefs.FirstSystemLeft / EVPU_PER_SPACE)
    local page_percent = page_prefs.PageScaling / 100
    local staff_percent = (page_prefs.SystemStaffHeight / (EVPU_PER_SPACE * 4 * 16)) * (page_prefs.SystemScaling / 100)
    set_element_text(style_element, "spatium", (EVPU_PER_SPACE * staff_percent * page_percent) / EVPU_PER_MM)
    local first_system = finale.FCStaffSystem()
    if first_system:LoadFirst() then
        local min_size = 100
        if first_system.UseStaffResize then
            local system_staves = finale.FCSystemStaves()
            system_staves.LoadAllForItem(first_system.ItemNo)
            for system_staff in each(system_staves) do
                if system_staff.Resize < min_size then
                    min_size = system_staff.Resize
                end
            end
        end
        if min_size < 100 then
            set_element_text(style_element, "smallStaffMag", min_size / 100)
            set_element_text(style_element, "smallNoteMag", min_size / 100)
        end
    end
    if music_font_name then
        set_element_text(style_element, "musicalSymbolFont", music_font_name)
        set_element_text(style_element, "musicalTextFont", music_font_name .. " Text")
    end
end
function write_lyrics_prefs(style_element)
    local font_info = finale.FCFontInfo()
    local lyrics_text = finale.FCVerseLyricsText()
    font_info:LoadFontPrefs(finale.FONTPREF_LYRICSVERSE)
    for verse_number, even_odd in ipairs({ "Odd", "Even" }) do
        if lyrics_text:Load(verse_number) then
            local str = lyrics_text:CreateString()
            local font = str and str.Length > 0 and enigma_string.trim_first_enigma_font_tags(str)
            font_info = font or font_info
        end
        write_font_pref(style_element, "lyrics" .. even_odd, font_info)
    end
end
function write_line_measure_prefs(style_element)
    set_element_text(style_element, "barWidth", size_prefs.ThinBarlineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "doubleBarWidth", size_prefs.ThinBarlineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "endBarWidth", size_prefs.HeavyBarlineThickness / EFIX_PER_SPACE)

    set_element_text(style_element, "doubleBarDistance", (distance_prefs.BarlineDoubleSpace - size_prefs.ThinBarlineThickness) / EFIX_PER_SPACE)

    set_element_text(style_element, "endBarDistance", (distance_prefs.BarlineFinalSpace) / EFIX_PER_SPACE)
    set_element_text(style_element, "repeatBarlineDotSeparation", repeat_prefs.ForwardSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "repeatBarTips", repeat_prefs.WingStyle ~= finale.REPWING_NONE)
    set_element_text(style_element, "startBarlineSingle", misc_prefs.LeftBarlineDisplaySingle)
    set_element_text(style_element, "startBarlineMultiple", misc_prefs.LeftBarlineDisplayMultiple)
    set_element_text(style_element, "bracketWidth", 0.5)

    set_element_text(style_element, "bracketDistance", ((-distance_prefs.GroupBracketDefaultDistance) - 0.25 * EVPU_PER_SPACE) / EVPU_PER_SPACE)
    set_element_text(style_element, "akkoladeBarDistance", -distance_prefs.GroupBracketDefaultDistance / EVPU_PER_SPACE)
    set_element_text(style_element, "clefLeftMargin", distance_prefs.ClefSpaceBefore / EVPU_PER_SPACE)
    set_element_text(style_element, "keysigLeftMargin", distance_prefs.KeySpaceBefore / EVPU_PER_SPACE)
    local time_sig_space_before = current_is_part and distance_prefs.TimeSigPartsSpaceBefore or distance_prefs.TimeSigSpaceBefore
    set_element_text(style_element, "timesigLeftMargin", time_sig_space_before / EVPU_PER_SPACE)
    set_element_text(style_element, "clefKeyDistance", (distance_prefs.ClefSpaceAfter + distance_prefs.ClefKeyExtraSpace + distance_prefs.KeySpaceBefore) / EVPU_PER_SPACE)
    set_element_text(style_element, "clefTimesigDistance", (distance_prefs.ClefSpaceAfter + distance_prefs.ClefTimeExtraSpace + time_sig_space_before) / EVPU_PER_SPACE)
    set_element_text(style_element, "keyTimesigDistance", (distance_prefs.KeySpaceAfter + distance_prefs.KeyTimeExtraSpace + time_sig_space_before) / EVPU_PER_SPACE)
    set_element_text(style_element, "keyBarlineDistance", repeat_prefs.AfterKeySpace / EVPU_PER_SPACE)



    set_element_text(style_element, "clefBarlineDistance", distance_prefs.ClefChangeOffset / EVPU_PER_SPACE)
    set_element_text(style_element, "timesigBarlineDistance", repeat_prefs.AfterClefSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "measureRepeatNumberPos", -(music_character_prefs.VerticalTwoMeasureRepeatOffset + 0.5) / EVPU_PER_SPACE)
    set_element_text(style_element, "staffLineWidth", size_prefs.StaffLineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "ledgerLineWidth", size_prefs.LedgerLineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "ledgerLineLength", (size_prefs.LedgerLeftHalf + size_prefs.LedgerRightHalf) / (2 * EVPU_PER_SPACE))
    set_element_text(style_element, "keysigAccidentalDistance", (distance_prefs.KeySpaceBetweenAccidentals + 4) / EVPU_PER_SPACE)
    set_element_text(style_element, "keysigNaturalDistance", (distance_prefs.KeySpaceBetweenAccidentals + 6) / EVPU_PER_SPACE)
    set_element_text(style_element, "smallClefMag", misc_prefs.ClefResize / 100)
    set_element_text(style_element, "genClef", not misc_prefs.OnlyFirstSystemClef)
    set_element_text(style_element, "genKeysig", not misc_prefs.KeySigOnlyFirstSystem)
    set_element_text(style_element, "genCourtesyTimesig", misc_prefs.CourtesyTimeSigAtSystemEnd)
    set_element_text(style_element, "genCourtesyKeysig", misc_prefs.CourtesyKeySigAtSystemEnd)
    set_element_text(style_element, "genCourtesyClef", misc_prefs.CourtesyClefAtSystemEnd)
    set_element_text(style_element, "keySigCourtesyBarlineMode", misc_prefs.DoubleBarlineAtKeyChange)
    set_element_text(style_element, "timeSigCourtesyBarlineMode", 0)
    set_element_text(style_element, "hideEmptyStaves", score.calc_has_optimized_systems())
end
function write_stem_prefs(style_element)
    set_element_text(style_element, "useStraightNoteFlags", music_character_prefs.UseStraightFlags)
    set_element_text(style_element, "stemWidth", size_prefs.StemLineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "shortenStem", true)
    set_element_text(style_element, "stemLength", size_prefs.NormalStemLength / EVPU_PER_SPACE)
    set_element_text(style_element, "shortestStem", size_prefs.ShortenedStemLength / EVPU_PER_SPACE)
    set_element_text(style_element, "stemSlashThickness", size_prefs.GraceSlashThickness / EFIX_PER_SPACE)
end
function write_spacing_prefs(style_element)
    set_element_text(style_element, "minMeasureWidth", spacing_prefs.MinMeasureWidth / EVPU_PER_SPACE)
    set_element_text(style_element, "minNoteDistance", spacing_prefs.MinimumItemDistance / EVPU_PER_SPACE)
    set_element_text(style_element, "measureSpacing", spacing_prefs.ScalingFactor)
    set_element_text(style_element, "minTieLength", spacing_prefs.MinimumDistanceWithTies / EVPU_PER_SPACE)
end
function write_note_related_prefs(style_element)
    set_element_text(style_element, "accidentalDistance", distance_prefs.AccidentalMultiSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "accidentalNoteDistance", distance_prefs.AccidentalNoteSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "beamWidth", size_prefs.BeamThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "useWideBeams", distance_prefs.SecondaryBeamSpace > 0.75 * EVPU_PER_SPACE)

    set_element_text(style_element, "beamMinLen", (size_prefs.BrokenBeamLength + (2 * size_prefs.StemLineThickness / EFIX_PER_EVPU)) / EVPU_PER_SPACE)
    set_element_text(style_element, "beamNoSlope", misc_prefs.BeamSlopeStyle == finale.BEAMSLOPE_FLATTENALL)
    local dot_mag = muse_mag_val(finale.FONTPREF_AUGMENTATIONDOT)
    set_element_text(style_element, "dotMag", dot_mag)
    set_element_text(style_element, "dotNoteDistance", distance_prefs.AugmentationDotNoteSpace / EVPU_PER_SPACE)
    set_element_text(style_element, "dotRestDistance", distance_prefs.AugmentationDotNoteSpace / EVPU_PER_SPACE)
    local dot_width = (function()
        local metrics = finale.FCTextMetrics()
        metrics:LoadSymbol(music_character_prefs.SymbolAugmentationDot, default_music_font, 100)
        return metrics:CalcWidthEVPUs()
    end)()

    set_element_text(style_element, "dotDotDistance", (distance_prefs.AugmentationDotSpace + dot_mag * dot_width) / EVPU_PER_SPACE)
    set_element_text(style_element, "articulationMag", muse_mag_val(finale.FONTPREF_ARTICULATION))
    set_element_text(style_element, "graceNoteMag", size_prefs.GraceNoteSize / 100)
    set_element_text(style_element, "concertPitch", part_scope_prefs.DisplayInConcertPitch)
    set_element_text(style_element, "multiVoiceRestTwoSpaceOffset", math.abs(layer_one_prefs.RestOffset) >= 4)
    set_element_text(style_element, "mergeMatchingRests", misc_prefs.ConsolidateRestsAcrossLayers)
end
function write_smart_shape_prefs(style_element)
    set_element_text(style_element, "hairpinHeight", smart_shape_prefs.HairpinDefaultShortOpening / EVPU_PER_SPACE)
    set_element_text(style_element, "hairpinContHeight", 0.5)
    write_category_text_font_pref(style_element, "hairpin", finale.DEFAULTCATID_DYNAMICS)
    write_line_prefs(style_element, "hairpin", smart_shape_prefs.HairpinLineWidth, smart_shape_prefs.LineDashLength, smart_shape_prefs.LineDashSpace)
    set_element_text(style_element, "slurEndWidth", smart_shape_prefs.SlurTipWidth / (10000 * EVPU_PER_SPACE))

    set_element_text(style_element, "slurDottedWidth", smart_shape_prefs.LineWidth / EFIX_PER_SPACE)
    set_element_text(style_element, "tieEndWidth", tie_prefs.TipWidth / (10000 * EVPU_PER_SPACE))

    set_element_text(style_element, "tieDottedWidth", smart_shape_prefs.LineWidth / EFIX_PER_SPACE)
    set_element_text(style_element, "tiePlacementSingleNote", tie_prefs.UseOuterPlacement and "outside" or "inside")
    set_element_text(style_element, "tiePlacementChord", tie_prefs.UseOuterPlacement and "outside" or "inside")
    set_element_text(style_element, "ottavaHookAbove", smart_shape_prefs.HookLength / EVPU_PER_SPACE)
    set_element_text(style_element, "ottavaHookBelow", -smart_shape_prefs.HookLength / EVPU_PER_SPACE)
    write_line_prefs(style_element, "ottava", smart_shape_prefs.LineWidth, smart_shape_prefs.LineDashLength, smart_shape_prefs.LineDashSpace, "dashed")
    set_element_text(style_element, "ottavaNumbersOnly", smart_shape_prefs.OctavesAsText)
end
function write_measure_number_prefs(style_element)
    local meas_num_regions = finale.FCMeasureNumberRegions()
    set_element_text(style_element, "showMeasureNumber", meas_num_regions:LoadAll() > 0)
    if meas_num_regions.Count > 0 then
        local meas_nums = meas_num_regions:GetItemAt(0)
        set_element_text(style_element, "showMeasureNumberOne", not meas_nums:GetHideFirstNumber(current_is_part))
        set_element_text(style_element, "measureNumberInterval", meas_nums:GetMultipleValue(current_is_part))
        set_element_text(style_element, "measureNumberSystem", meas_nums:GetShowOnSystemStart(current_is_part) and not meas_nums:GetShowMultiples(current_is_part))
        local function process_segment(font_info, enclosure, use_enclosure, justification, alignment, vertical, prefix)
            local function justification_string(justi)
                if justi == finale.MNJUSTIFY_LEFT then
                    return "left,baseline"
                elseif justi == finale.MNJUSTIFY_CENTER then
                    return "center,baseline"
                else
                    return "right,baseline"
                end
            end
            local function horz_alignment(align)
                if align == finale.MNALIGN_LEFT then
                    return 0
                elseif align == finale.MNALIGN_CENTER then
                    return 1
                else
                    return 2
                end
            end
            local function vert_alignment(vert)
                return vert >= 0 and 0 or 1
            end
            write_font_pref(style_element, prefix, font_info)
            set_element_text(style_element, prefix .. "VPlacement", vert_alignment(vertical))
            set_element_text(style_element, prefix .. "HPlacement", horz_alignment(alignment))
            set_element_text(style_element, prefix .. "Align", justification_string(justification))
            write_frame_prefs(style_element, prefix, use_enclosure and enclosure or nil)
        end
        local font_info = meas_nums:GetShowOnSystemStart(current_is_part) and meas_nums:CreateStartFontInfo(current_is_part) or meas_nums:CreateMultipleFontInfo(current_is_part)
        local enclosure = meas_nums:GetShowOnSystemStart(current_is_part) and meas_nums:GetEnclosureStart(current_is_part) or meas_nums:GetEnclosureMultiple(current_is_part)
        local use_enclosure = meas_nums:GetShowOnSystemStart(current_is_part) and meas_nums:GetUseEnclosureStart(current_is_part) or meas_nums:GetUseEnclosureMultiple(current_is_part)
        local justification = meas_nums:GetShowMultiples(current_is_part) and meas_nums:GetMultipleJustification(current_is_part) or meas_nums:GetStartJustification(current_is_part)
        local alignment = meas_nums:GetShowMultiples(current_is_part) and meas_nums:GetMultipleAlignment(current_is_part) or meas_nums:GetStartAlignment(current_is_part)
        local vertical = meas_nums:GetShowOnSystemStart(current_is_part) and meas_nums:GetStartVerticalPosition(current_is_part) or meas_nums:GetMultipleVerticalPosition(current_is_part)
        set_element_text(style_element, "measureNumberOffsetType", 1)
        process_segment(font_info, enclosure, use_enclosure, justification, alignment, vertical, "measureNumber")
        set_element_text(style_element, "mmRestShowMeasureNumberRange", meas_nums:GetShowMultiMeasureRange(current_is_part))
        local left_char = meas_nums:GetMultiMeasureBracketLeft(current_is_part)
        if left_char == 0 then
            set_element_text(style_element, "mmRestRangeBracketType", 2)
        elseif left_char == '(' then
            set_element_text(style_element, "mmRestRangeBracketType", 1)
        else
            set_element_text(style_element, "mmRestRangeBracketType", 0)
        end
        process_segment(meas_nums:CreateMultiMeasureFontInfo(current_is_part), meas_nums:GetEnclosureMultiple(current_is_part), meas_nums:GetUseEnclosureMultiple(current_is_part),
                meas_nums:GetMultiMeasureJustification(current_is_part), meas_nums:GetMultiMeasureAlignment(current_is_part),
                meas_nums:GetMultiMeasureVerticalPosition(current_is_part), "mmRestRange")
    end
    set_element_text(style_element, "createMultiMeasureRests", current_is_part)
    set_element_text(style_element, "minEmptyMeasures", mmrest_prefs.StartNumberingAt)
    set_element_text(style_element, "minMMRestWidth", mmrest_prefs.Width / EVPU_PER_SPACE)
    set_element_text(style_element, "mmRestNumberPos", (mmrest_prefs.NumberVerticalAdjust / EVPU_PER_SPACE) + 1)

    set_element_text(style_element, "oldStyleMultiMeasureRests", mmrest_prefs.UseSymbols and mmrest_prefs.UseSymbolsLessThan > 1)
    set_element_text(style_element, "mmRestOldStyleMaxMeasures", math.max(mmrest_prefs.UseSymbolsLessThan - 1, 0))
    set_element_text(style_element, "mmRestOldStyleSpacing", mmrest_prefs.SymbolSpace / EVPU_PER_SPACE)
end
function write_repeat_ending_prefs(style_element)




    set_element_text(style_element, "voltaLineWidth", repeat_prefs.EndingLineThickness / EFIX_PER_SPACE)
    set_element_text(style_element, "voltaLineStyle", "solid")
    write_default_font_pref(style_element, "volta", finale.FONTPREF_ENDING)
    set_element_text(style_element, "voltaAlign", "left,baseline")



end
function write_tuplet_prefs(style_element)
    set_element_text(style_element, "tupletOutOfStaff", tuplet_prefs.AvoidStaff)


    set_element_text(style_element, "tupletNumberRythmicCenter", tuplet_prefs.CenterUsingDuration);
    set_element_text(style_element, "tupletExtendToEndOfDuration", tuplet_prefs.BracketFullDuration);
    set_element_text(style_element, "tupletStemLeftDistance", tuplet_prefs.LeftExtension / EVPU_PER_SPACE)
    set_element_text(style_element, "tupletStemRightDistance", tuplet_prefs.RightExtension / EVPU_PER_SPACE)
    set_element_text(style_element, "tupletNoteLeftDistance", tuplet_prefs.LeftExtension / EVPU_PER_SPACE)
    set_element_text(style_element, "tupletNoteRightDistance", tuplet_prefs.RightExtension / EVPU_PER_SPACE)
    set_element_text(style_element, "tupletBracketWidth", tuplet_prefs.BracketThickness / EFIX_PER_SPACE)
    if tuplet_prefs.PlacementMode == finale.TUPLETPLACEMENT_ABOVE then
        set_element_text(style_element, "tupletDirection", 1)
    elseif tuplet_prefs.PlacementMode == finale.TUPLETPLACEMENT_BELOW then
        set_element_text(style_element, "tupletDirection", 2)
    else
        set_element_text(style_element, "tupletDirection", 0)
    end
    if tuplet_prefs.NumberStyle == finale.TUPLETNUMBER_NONE then
        set_element_text(style_element, "tupletNumberType", 2)
    elseif tuplet_prefs.NumberStyle == finale.TUPLETNUMBER_REGULAR then
        set_element_text(style_element, "tupletNumberType", 0)
    else
        set_element_text(style_element, "tupletNumberType", 1)
    end
    if tuplet_prefs.ShapeStyle == finale.TUPLETSHAPE_NONE then
        set_element_text(style_element, "tupletBracketType", 2)
    elseif tuplet_prefs.BracketMode == finale.TUPLETBRACKET_ALWAYS then
        set_element_text(style_element, "tupletBracketType", 1)
    else
        set_element_text(style_element, "tupletBracketType", 0)
    end
    local font_pref = finale.FCFontPrefs()
    if not font_pref:Load(finale.FONTPREF_TUPLET) then
        log_message("unable to load font pref for tuplets", true)
    end
    local font_info = font_pref:CreateFontInfo()
    if font_info.IsSMuFLFont then
        set_element_text(style_element, "tupletMusicalSymbolsScale", muse_mag_val(finale.FONTPREF_TUPLET))
        set_element_text(style_element, "tupletUseSymbols", true)
    else
        write_font_pref(style_element, "tuplet", font_info)
        set_element_text(style_element, "tupletMusicalSymbolsScale", 1)
        set_element_text(style_element, "tupletUseSymbols", false)
    end
    set_element_text(style_element, "tupletBracketHookHeight",
    math.max(tuplet_prefs.LeftHookLength, tuplet_prefs.RightHookLength) / EVPU_PER_SPACE)
end
function write_marking_prefs(style_element)
    local cat = finale.FCCategoryDef()
    if not cat:Load(finale.DEFAULTCATID_DYNAMICS) then
        log_message("unable to load FCCategoryDef for dynamics", true)
    end
    local font_info = finale.FCFontInfo()
    local override = cat:GetMusicFontInfo(font_info) and font_info.IsSMuFLFont and font_info.FontID ~= 0
    set_element_text(style_element, "dynamicsOverrideFont", override)
    if override then
        set_element_text(style_element, "dynamicsFont", font_info.Name)
        set_element_text(style_element, "dynamicsSize", font_info.Size / default_music_font.Size)
    else
        set_element_text(style_element, "dynamicsFont", default_music_font.Name)
        set_element_text(style_element, "dynamicsSize",
            font_info.IsSMuFLFont and (font_info.Size / default_music_font.Size) or 1)
    end
    local font_pref = finale.FCFontPrefs()
    if not font_pref:Load(finale.FONTPREF_TEXTBLOCK) then
        log_message("unable to load font prefs for Text Blocks", true)
    end
    font_info = font_pref:CreateFontInfo()
    write_font_pref(style_element, "default", font_info)

    set_element_text(style_element, "titleFontFace", font_info.Name)
    set_element_text(style_element, "subTitleFontFace", font_info.Name)
    set_element_text(style_element, "composerFontFace", font_info.Name)
    set_element_text(style_element, "lyricistFontFace", font_info.Name)
    write_default_font_pref(style_element, "longInstrument", finale.FONTPREF_STAFFNAME)
    local position = finale.FCStaffNamePositionPrefs()
    local function justify_to_alignment()
        if position.Justification == finale.TEXTJUSTIFY_LEFT then
            return "left,center"
        elseif position.Justification == finale.TEXTJUSTIFY_RIGHT then
            return "right,center"
        else
            return "center,center"
        end
    end
    position:LoadFull()
    set_element_text(style_element, "longInstrumentAlign", justify_to_alignment())
    write_default_font_pref(style_element, "shortInstrument", finale.FONTPREF_ABRVSTAFFNAME)
    position:LoadAbbreviated()
    set_element_text(style_element, "shortInstrumentAlign", justify_to_alignment())
    write_default_font_pref(style_element, "partInstrument", finale.FONTPREF_STAFFNAME)
    write_category_text_font_pref(style_element, "dynamics", finale.DEFAULTCATID_DYNAMICS)
    write_category_text_font_pref(style_element, "expression", finale.DEFAULTCATID_EXPRESSIVETEXT)
    write_category_text_font_pref(style_element, "tempo", finale.DEFAULTCATID_TEMPOMARKS)
    write_category_text_font_pref(style_element, "tempoChange", finale.DEFAULTCATID_EXPRESSIVETEXT)
    write_line_prefs(style_element, "tempoChange", smart_shape_prefs.LineWidth, smart_shape_prefs.LineDashLength, smart_shape_prefs.LineDashSpace, "dashed")
    write_category_text_font_pref(style_element, "metronome", finale.DEFAULTCATID_TEMPOMARKS)
    set_element_text(style_element, "translatorFontFace", font_info.Name)
    write_category_text_font_pref(style_element, "systemText", finale.DEFAULTCATID_EXPRESSIVETEXT)
    write_category_text_font_pref(style_element, "staffText", finale.DEFAULTCATID_TECHNIQUETEXT)
    write_category_text_font_pref(style_element, "rehearsalMark", finale.DEFAULTCATID_REHEARSALMARK)
    write_default_font_pref(style_element, "repeatLeft", finale.FONTPREF_REPEAT)
    write_default_font_pref(style_element, "repeatRight", finale.FONTPREF_REPEAT)
    write_font_pref(style_element, "frame", font_info)
    write_category_text_font_pref(style_element, "textLine", finale.DEFAULTCATID_TECHNIQUETEXT)
    write_category_text_font_pref(style_element, "systemTextLine", finale.DEFAULTCATID_EXPRESSIVETEXT)
    write_category_text_font_pref(style_element, "glissando", finale.DEFAULTCATID_TECHNIQUETEXT)
    write_category_text_font_pref(style_element, "bend", finale.DEFAULTCATID_TECHNIQUETEXT)
    write_font_pref(style_element, "header", font_info)
    write_font_pref(style_element, "footer", font_info)
    write_font_pref(style_element, "copyright", font_info)
    write_font_pref(style_element, "pageNumber", font_info)
    write_font_pref(style_element, "instrumentChange", font_info)
    write_font_pref(style_element, "sticking", font_info)
    write_font_pref(style_element, "user1", font_info)
    write_font_pref(style_element, "user2", font_info)
    write_font_pref(style_element, "user3", font_info)
    write_font_pref(style_element, "user4", font_info)
    write_font_pref(style_element, "user5", font_info)
    write_font_pref(style_element, "user6", font_info)
    write_font_pref(style_element, "user7", font_info)
    write_font_pref(style_element, "user8", font_info)
    write_font_pref(style_element, "user9", font_info)
    write_font_pref(style_element, "user10", font_info)
    write_font_pref(style_element, "user11", font_info)
    write_font_pref(style_element, "user12", font_info)
end
function write_xml(output_path)
    local mssxml <close> = tinyxml2.XMLDocument()
    mssxml:InsertEndChild(mssxml:NewDeclaration(nil))
    local ms_element = mssxml:NewElement("museScore")
    ms_element:SetAttribute("version", MSS_VERSION)
    mssxml:InsertEndChild(ms_element)
    local style_element = ms_element:InsertNewChildElement("Style")
    currently_processing = output_path
    error_occured = false
    open_current_prefs()
    write_page_prefs(style_element)
    write_lyrics_prefs(style_element)
    write_line_measure_prefs(style_element)
    write_stem_prefs(style_element)
    write_spacing_prefs(style_element)
    write_note_related_prefs(style_element)
    write_smart_shape_prefs(style_element)
    write_measure_number_prefs(style_element)
    write_repeat_ending_prefs(style_element)
    write_tuplet_prefs(style_element)
    write_marking_prefs(style_element)
    if mssxml:SaveFile(output_path) ~= tinyxml2.XML_SUCCESS then
        log_message("unable to save " .. output_path .. ". " .. mssxml:ErrorStr(), true)
    elseif logfile_path then
        log_message(error_occured and " saved with errors" or "", false)
    else
        finenv:UI():AlertInfo(output_path .. (error_occured and " saved with errors." or " saved."), "Success")
    end
end
local first_document
function process_document(document_file_path)
    local document = finale.FCDocument()
    if document:Open(finale.FCString(document_file_path), true, nil, false, false, true) then
        local parts = finale.FCParts()
        parts:LoadAll()

        local path_name, file_name_no_ext = utils.split_file_path(document_file_path)
        current_is_part = false
        write_xml(path_name .. file_name_no_ext .. TEXT_EXTENSION)
        for part in each(parts) do
            if not part:IsScore() then
                current_is_part = true
                write_xml(path_name .. file_name_no_ext .. PART_EXTENSION)
                break
            end
        end
        if finenv.UI():IsOnWindows() and not first_document then
            first_document = document
        else
            document.Dirty = false
            local closed = document:CloseCurrentDocumentAndWindow(false)
            if not closed then
                currently_processing = document_file_path
                log_message("failed to close", true)
            end
        end
    else
        currently_processing = document_file_path
        log_message("unable to open Finale document", true)
    end
    document:SwitchBack()
end
function create_status_dialog(selected_directory, files_to_process)
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle("Export Settings to MuseScore")
    local current_y = 0

    dialog:CreateStatic(0, current_y + 2, "folder_label")
        :SetText("Folder:")
        :DoAutoResizeWidth(0)
    dialog:CreateStatic(0, current_y + 2, "folder")
        :SetText("")
        :SetWidth(400)
        :AssureNoHorizontalOverlap(dialog:GetControl("folder_label"), 5)
        :StretchToAlignWithRight()
    current_y = current_y + 20

    dialog:CreateStatic(0, current_y + 2, "file_path_label")
        :SetText("File:")
        :DoAutoResizeWidth(0)
    dialog:CreateStatic(0, current_y + 2, "file_path")
        :SetText("")
        :SetWidth(300)
        :AssureNoHorizontalOverlap(dialog:GetControl("file_path_label"), 5)
        :HorizontallyAlignLeftWith(dialog:GetControl("folder"))
        :StretchToAlignWithRight()

    dialog:CreateCancelButton("cancel")

    dialog:RegisterInitWindow(function(self)
        self:SetTimer(TIMER_ID, 100)
    end)
    dialog:RegisterHandleTimer(function(self, timer)
        assert(timer == TIMER_ID, "incorrect timer id value " .. timer)
        if #files_to_process <= 0 then
            self:StopTimer(TIMER_ID)
            self:GetControl("folder"):SetText(selected_directory)
            self:GetControl("file_path_label"):SetText("Log:")
            self:GetControl("file_path"):SetText(LOGFILE_NAME .. " (export complete)")
            currently_processing = selected_directory
            log_message("processing complete")
            self:GetControl("cancel"):SetText("Close")
            return
        end
        self:GetControl("folder"):SetText("..." .. files_to_process[1].folder:sub(#selected_directory))
            :RedrawImmediate()
        self:GetControl("file_path"):SetText(files_to_process[1].name)
            :RedrawImmediate()
        process_document(files_to_process[1].folder .. files_to_process[1].name)
        table.remove(files_to_process, 1)
    end)
    dialog:RegisterCloseWindow(function(self)
        self:StopTimer(TIMER_ID)
        if #files_to_process > 0 then
            currently_processing = selected_directory
            log_message("processing aborted by user", true)
        end
        if first_document then
            first_document.Dirty = false
            first_document:CloseCurrentDocumentAndWindow(false)
        end
        finenv.RetainLuaState = false
    end)
    dialog:RunModeless()
end
function select_target(file_path_str)
    local path_name, file_name_no_ext = utils.split_file_path(file_path_str)
    local file_name = file_name_no_ext .. (current_is_part and PART_EXTENSION or TEXT_EXTENSION)
    local save_dialog = finale.FCFileSaveAsDialog(finenv.UI())
    save_dialog:SetWindowTitle(finale.FCString("Save MuseScore style settings as"))
    save_dialog:AddFilter(finale.FCString("*" .. TEXT_EXTENSION), finale.FCString("MuseScore Style Settings File"))
    save_dialog:SetInitFolder(finale.FCString(path_name))
    save_dialog:SetFileName(finale.FCString(file_name))
    save_dialog:AssureFileExtension(TEXT_EXTENSION)
    if not save_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    save_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end
function select_directory()
    local default_folder_path = finale.FCString()
    default_folder_path:SetMusicFolderPath()
    local open_dialog = finale.FCFolderBrowseDialog(finenv.UI())
    open_dialog:SetWindowTitle(finale.FCString("Select folder containing Finale files"))
    open_dialog:SetFolderPath(default_folder_path)
    open_dialog:SetUseFinaleAPI(finenv:UI():IsOnMac())
    if not open_dialog:Execute() then
        return nil
    end
    local selected_folder = finale.FCString()
    open_dialog:GetFolderPath(selected_folder)
    selected_folder:AssureEndingPathDelimiter()
    return selected_folder.LuaString
end
function document_options_to_musescore()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    local document = documents:FindCurrent()
    if do_folder then
        if document then
            finenv:UI():AlertInfo("Run this plugin with no documents open.", "")
            return
        end
        local selected_directory = select_directory()
        if selected_directory then
            logfile_path = client.encode_with_client_codepage(selected_directory) .. LOGFILE_NAME
            local file <close> = io.open(logfile_path, "w")
            if not file then
                error("unable to create logfile " .. logfile_path)
            end
            file:close()
            local files_to_process = {}
            for folder, filename in utils.eachfile(selected_directory, true) do
                if (filename:sub(-MUSX_EXTENSION:len()) == MUSX_EXTENSION) or (filename:sub(-MUS_EXTENSION:len()) == MUS_EXTENSION) then
                    table.insert(files_to_process, {name = filename, folder = folder})
                end
            end
            create_status_dialog(selected_directory, files_to_process)
        end
    else
        if not document then
            finenv:UI():AlertInfo("Run this plugin with a document open.", "")
            return
        end
        local file_path_fcstr = finale.FCString()
        document:GetPath(file_path_fcstr)
        current_is_part = finale.FCPart(finale.PARTID_CURRENT):IsPart()
        local output_path = select_target(file_path_fcstr.LuaString)
        if output_path then
            write_xml(output_path)
        end
    end
end
document_options_to_musescore()

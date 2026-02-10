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
package.preload["library.smufl_glyphs"] = package.preload["library.smufl_glyphs"] or function()

    local smufl_glyphs = {}
    local utils = require("library.utils")
    local library = require("library.general_library")
    local glyphs = {
        ["articStaccatissimoWedgeBelow"] = {codepoint = 0xE4A9, description = "Staccatissimo wedge below"},
        ["tremoloFingered2"] = {codepoint = 0xE226, description = "Fingered tremolo 2"},
        ["noteheadCowellThirteenthNoteSeriesBlack"] = {codepoint = 0xEEB2, description = "2/13 note (thirteenth note series, Cowell)"},
        ["fretboard4String"] = {codepoint = 0xE852, description = "4-string fretboard"},
        ["noteheadCowellFifthNoteSeriesBlack"] = {codepoint = 0xEEA6, description = "1/5 note (fifth note series, Cowell)"},
        ["chantEpisema"] = {codepoint = 0xE9D8, description = "Episema"},
        ["kievanNoteWhole"] = {codepoint = 0xEC33, description = "Kievan whole note"},
        ["handbellsSwingUp"] = {codepoint = 0xE818, description = "Swing up"},
        ["noteheadCowellThirteenthNoteSeriesHalf"] = {codepoint = 0xEEB1, description = "4/13 note (thirteenth note series, Cowell)"},
        ["accSagittalFlat19sUp"] = {codepoint = 0xE3BF, description = "Flat 19s-up"},
        ["pictBeaterSoftYarnLeft"] = {codepoint = 0xE7A5, description = "Soft yarn beater left"},
        ["fingeringRightParenthesis"] = {codepoint = 0xED29, description = "Fingering right parenthesis"},
        ["noteDoWhole"] = {codepoint = 0xE150, description = "Do (whole note)"},
        ["noteShapeSquareBlack"] = {codepoint = 0xE1B3, description = "Square black (4-shape la; Aikin 7-shape la)"},
        ["brassHarmonMuteStemHalfLeft"] = {codepoint = 0xE5E9, description = "Harmon mute, stem extended, left"},
        ["mensuralCustosUp"] = {codepoint = 0xEA02, description = "Mensural custos up"},
        ["chantStaffNarrow"] = {codepoint = 0xE8F2, description = "Plainchant staff (narrow)"},
        ["chantStrophicusLiquescens5th"] = {codepoint = 0xE9C5, description = "Strophicus liquescens, 5th"},
        ["pictBeaterBox"] = {codepoint = 0xE7EB, description = "Box for percussion beater"},
        ["stemPendereckiTremolo"] = {codepoint = 0xE213, description = "Combining Penderecki unmeasured tremolo stem"},
        ["arrowheadBlackDownRight"] = {codepoint = 0xEB7B, description = "Black arrowhead down-right (SE)"},
        ["fingering0Italic"] = {codepoint = 0xED80, description = "Fingering 0 italic (open string)"},
        ["arrowheadBlackUpRight"] = {codepoint = 0xEB79, description = "Black arrowhead up-right (NE)"},
        ["noteSiHalf"] = {codepoint = 0xE15F, description = "Si (half note)"},
        ["luteGermanILower"] = {codepoint = 0xEC08, description = "2nd course, 2nd fret (i)"},
        ["pictGlassTubeChimes"] = {codepoint = 0xE6C5, description = "Glass tube chimes"},
        ["csymAccidentalTripleFlat"] = {codepoint = 0xED66, description = "Triple flat"},
        ["accidentalSharpReversed"] = {codepoint = 0xE481, description = "Reversed sharp"},
        ["accidentalThreeQuarterTonesSharpArrowUp"] = {codepoint = 0xE274, description = "Three-quarter-tones sharp"},
        ["pictHiHat"] = {codepoint = 0xE722, description = "Hi-hat"},
        ["pictScrapeAroundRimClockwise"] = {codepoint = 0xE80E, description = "Scrape around rim (clockwise)"},
        ["accSagittal4TinasDown"] = {codepoint = 0xE3FF, description = "4 tinas down, 5²⋅11²/7-schismina down, 0.57 cents down"},
        ["windMouthpiecePop"] = {codepoint = 0xE60A, description = "Mouthpiece or hand pop"},
        ["accdnRicochetStem4"] = {codepoint = 0xE8D4, description = "Combining ricochet for stem (4 tones)"},
        ["noteASharpBlack"] = {codepoint = 0xE198, description = "A sharp (black note)"},
        ["pictBeaterSnareSticksDown"] = {codepoint = 0xE7D2, description = "Snare sticks down"},
        ["accdnRH3RanksOboe"] = {codepoint = 0xE8A5, description = "Right hand, 3 ranks, 4' stop + 8' stop (oboe)"},
        ["restHalf"] = {codepoint = 0xE4E4, description = "Half (minim) rest"},
        ["controlEndSlur"] = {codepoint = 0xE8E5, description = "End slur"},
        ["pictBeaterHammerPlasticDown"] = {codepoint = 0xE7CE, description = "Plastic hammer, down"},
        ["graceNoteAcciaccaturaStemDown"] = {codepoint = 0xE561, description = "Slashed grace note stem down"},
        ["arrowOpenDownLeft"] = {codepoint = 0xEB75, description = "Open arrow down-left (SW)"},
        ["octaveBaselineB"] = {codepoint = 0xEC93, description = "b (baseline)"},
        ["pictBeaterHardTimpaniRight"] = {codepoint = 0xE792, description = "Hard timpani stick right"},
        ["mensuralCombStemUpFlagFusa"] = {codepoint = 0xE94B, description = "Combining stem with fusa flag up"},
        ["fingeringQLower"] = {codepoint = 0xED8E, description = "Fingering q (right-hand little finger for guitar)"},
        ["accSagittalSharp23CUp"] = {codepoint = 0xE37C, description = "Sharp 23C-up, 10° up [96 EDO], 5/8-tone up"},
        ["dynamicSforzato"] = {codepoint = 0xE539, description = "Sforzato"},
        ["chantAccentusAbove"] = {codepoint = 0xE9D6, description = "Accentus above"},
        ["noteDSharpHalf"] = {codepoint = 0xE18A, description = "D sharp (half note)"},
        ["accSagittal11v49CommaDown"] = {codepoint = 0xE397, description = "11:49 comma down"},
        ["pictMar"] = {codepoint = 0xE6A6, description = "Marimba"},
        ["functionSUpper"] = {codepoint = 0xEA89, description = "Function theory major subdominant"},
        ["accSagittal7TinasUp"] = {codepoint = 0xE404, description = "7 tinas up, 7/(5²⋅17)-schismina up, 1.02 cents up"},
        ["accidentalThreeQuarterTonesFlatCouper"] = {codepoint = 0xE489, description = "Three-quarter-tones flat (Couper)"},
        ["medRenQuilismaCMN"] = {codepoint = 0xEA28, description = "Quilisma (Corpus Monodicum)"},
        ["accidentalDoubleFlat"] = {codepoint = 0xE264, description = "Double flat"},
        ["kahnSlam"] = {codepoint = 0xEDCE, description = "Slam"},
        ["mensuralWhiteSemiminima"] = {codepoint = 0xE960, description = "White mensural semiminima"},
        ["kievanEndingSymbol"] = {codepoint = 0xEC31, description = "Kievan ending symbol"},
        ["dynamicMF"] = {codepoint = 0xE52D, description = "mf"},
        ["accidentalSharpTwoArrowsUp"] = {codepoint = 0xE2D2, description = "Sharp raised by two syntonic commas"},
        ["wiggleTrillSlowest"] = {codepoint = 0xEAA8, description = "Trill wiggle segment, slowest"},
        ["gClefTurned"] = {codepoint = 0xE074, description = "Turned G clef"},
        ["accdnRicochet5"] = {codepoint = 0xE8D0, description = "Ricochet (5 tones)"},
        ["fClefTurned"] = {codepoint = 0xE077, description = "Turned F clef"},
        ["noteBSharpBlack"] = {codepoint = 0xE19B, description = "B sharp (black note)"},
        ["brassBend"] = {codepoint = 0xE5E3, description = "Bend"},
        ["windReedPositionIn"] = {codepoint = 0xE606, description = "Much more reed (push inwards)"},
        ["accSagittalSharp7v19CDown"] = {codepoint = 0xE3B4, description = "Sharp 7:19C-down"},
        ["noteMiBlack"] = {codepoint = 0xE162, description = "Mi (black note)"},
        ["accidentalSharpRepeatedLineStockhausen"] = {codepoint = 0xED5E, description = "Repeated sharp, note on line (Stockhausen)"},
        ["noteShapeTriangleUpBlack"] = {codepoint = 0xE1BB, description = "Triangle up black (Aikin 7-shape do)"},
        ["fermataLongAbove"] = {codepoint = 0xE4C6, description = "Long fermata above"},
        ["pictCastanetsWithHandle"] = {codepoint = 0xE6F9, description = "Castanets with handle"},
        ["noteheadClusterDoubleWholeMiddle"] = {codepoint = 0xE12D, description = "Combining double whole note cluster, middle"},
        ["timeSig3"] = {codepoint = 0xE083, description = "Time signature 3"},
        ["pictOnRim"] = {codepoint = 0xE7F4, description = "On rim"},
        ["accSagittalDoubleSharp19sDown"] = {codepoint = 0xE3EE, description = "Double sharp 19s-down"},
        ["accidentalOneQuarterToneSharpFerneyhough"] = {codepoint = 0xE48E, description = "One-quarter-tone sharp (Ferneyhough)"},
        ["mensuralWhiteLonga"] = {codepoint = 0xE95D, description = "White mensural longa"},
        ["wiggleVibratoMediumFaster"] = {codepoint = 0xEADD, description = "Vibrato medium, faster"},
        ["textCont16thBeamLongStem"] = {codepoint = 0xE1FA, description = "Continuing 16th beam for long stem"},
        ["guitarString0"] = {codepoint = 0xE833, description = "String number 0"},
        ["handbellsEcho1"] = {codepoint = 0xE81B, description = "Echo"},
        ["vocalsSussurando"] = {codepoint = 0xE646, description = "Combining sussurando for stem"},
        ["ornamentTopLeftConcaveStroke"] = {codepoint = 0xE590, description = "Ornament top left concave stroke"},
        ["augmentationDot"] = {codepoint = 0xE1E7, description = "Augmentation dot"},
        ["ornamentHighRightConvexStroke"] = {codepoint = 0xE5A3, description = "Ornament high right convex stroke"},
        ["noteheadXWhole"] = {codepoint = 0xE0A7, description = "X notehead whole"},
        ["accidentalWyschnegradsky4TwelfthsFlat"] = {codepoint = 0xE42E, description = "1/3 tone flat"},
        ["beamAccelRit1"] = {codepoint = 0xEAF4, description = "Accel./rit. beam 1 (widest)"},
        ["fClefArrowDown"] = {codepoint = 0xE068, description = "F clef, arrow down"},
        ["accidentalCombiningRaise41Comma"] = {codepoint = 0xEE55, description = "Combining raise by one 41-limit comma"},
        ["noteheadNancarrowSine"] = {codepoint = 0xEEA0, description = "Sine notehead (Nancarrow)"},
        ["fingeringLeftParenthesis"] = {codepoint = 0xED28, description = "Fingering left parenthesis"},
        ["arrowheadWhiteUpRight"] = {codepoint = 0xEB81, description = "White arrowhead up-right (NE)"},
        ["accSagittal49MediumDiesisDown"] = {codepoint = 0xE3A5, description = "49 medium diesis down"},
        ["arrowBlackDownLeft"] = {codepoint = 0xEB65, description = "Black arrow down-left (SW)"},
        ["noteHBlack"] = {codepoint = 0xE1AB, description = "H (black note)"},
        ["articSoftAccentAbove"] = {codepoint = 0xED40, description = "Soft accent above"},
        ["organGerman3Semifusae"] = {codepoint = 0xEE33, description = "Three Semifusae"},
        ["stringsChangeBowDirection"] = {codepoint = 0xE626, description = "Change bow direction, indeterminate"},
        ["accidentalQuarterSharpEqualTempered"] = {codepoint = 0xE2F6, description = "Raise by one equal tempered quarter tone"},
        ["metNote1024thUp"] = {codepoint = 0xECB5, description = "1024th note (semihemidemisemihemidemisemiquaver) stem up"},
        ["chantVirgula"] = {codepoint = 0xE8F7, description = "Virgula"},
        ["noteheadRoundBlackLarge"] = {codepoint = 0xE110, description = "Large round black notehead"},
        ["quindicesima"] = {codepoint = 0xE514, description = "Quindicesima"},
        ["note128thUp"] = {codepoint = 0xE1DF, description = "128th note (semihemidemisemiquaver) stem up"},
        ["accSagittalFlat49SUp"] = {codepoint = 0xE3B3, description = "Flat 49S-up"},
        ["noteCBlack"] = {codepoint = 0xE19D, description = "C (black note)"},
        ["fermataVeryLongAbove"] = {codepoint = 0xE4C8, description = "Very long fermata above"},
        ["noteheadHeavyX"] = {codepoint = 0xE0F8, description = "Heavy X notehead"},
        ["accdnRH3RanksFullFactory"] = {codepoint = 0xE8B3, description = "Right hand, 3 ranks, 4' stop + lower tremolo 8' stop + 8' stop + upper tremolo 8' stop + 16' stop"},
        ["accSagittal7TinasDown"] = {codepoint = 0xE405, description = "7 tinas down, 7/(5²⋅17)-schismina down, 1.02 cents down"},
        ["organGerman2Semiminimae"] = {codepoint = 0xEE2D, description = "Two Semiminimae"},
        ["harpSalzedoThunderEffect"] = {codepoint = 0xE686, description = "Thunder effect (Salzedo)"},
        ["accdnRicochetStem6"] = {codepoint = 0xE8D6, description = "Combining ricochet for stem (6 tones)"},
        ["analyticsThemeRetrogradeInversion"] = {codepoint = 0xE866, description = "Retrograde inversion of theme"},
        ["pictCastanets"] = {codepoint = 0xE6F8, description = "Castanets"},
        ["controlBeginBeam"] = {codepoint = 0xE8E0, description = "Begin beam"},
        ["noteheadHalfFilled"] = {codepoint = 0xE0FB, description = "Filled half (minim) notehead"},
        ["pictBeaterBrassMalletsDown"] = {codepoint = 0xE7DA, description = "Brass mallets down"},
        ["accidentalFlatRaisedStockhausen"] = {codepoint = 0xED52, description = "Raised flat (Stockhausen)"},
        ["staff1LineNarrow"] = {codepoint = 0xE01C, description = "1-line staff (narrow)"},
        ["accSagittalSharp17kUp"] = {codepoint = 0xE3C2, description = "Sharp 17k-up"},
        ["mensuralRestFusa"] = {codepoint = 0xE9F7, description = "Fusa rest"},
        ["wiggleRandom1"] = {codepoint = 0xEAF0, description = "Quasi-random squiggle 1"},
        ["wiggleVibratoMediumSlowest"] = {codepoint = 0xEAE1, description = "Vibrato medium, slowest"},
        ["mensuralProlationCombiningThreeDotsTri"] = {codepoint = 0xE923, description = "Combining three dots triangular"},
        ["brassFallRoughLong"] = {codepoint = 0xE5DF, description = "Rough fall, long"},
        ["fingering1"] = {codepoint = 0xED11, description = "Fingering 1 (thumb)"},
        ["elecVideoCamera"] = {codepoint = 0xEB17, description = "Video camera"},
        ["accSagittal11v19MediumDiesisUp"] = {codepoint = 0xE3A2, description = "11:19 medium diesis up, (11:19M, 11M plus 19s)"},
        ["mensuralProportion2"] = {codepoint = 0xE927, description = "Mensural proportion 2"},
        ["metNote32ndUp"] = {codepoint = 0xECAB, description = "32nd note (demisemiquaver) stem up"},
        ["swissRudimentsNoteheadHalfFlam"] = {codepoint = 0xEE71, description = "Swiss rudiments flam half (minim) notehead"},
        ["noteheadClusterQuarterMiddle"] = {codepoint = 0xE136, description = "Combining quarter note cluster, middle"},
        ["fermataShortAbove"] = {codepoint = 0xE4C4, description = "Short fermata above"},
        ["elecLoudspeaker"] = {codepoint = 0xEB1A, description = "Loudspeaker"},
        ["noteheadCowellThirdNoteSeriesBlack"] = {codepoint = 0xEEA3, description = "1/6 note (third note series, Cowell)"},
        ["pictVibSmithBrindle"] = {codepoint = 0xE6AD, description = "Vibraphone (Smith Brindle)"},
        ["mensuralColorationStartRound"] = {codepoint = 0xEA0E, description = "Coloration start, round"},
        ["brassFallRoughShort"] = {codepoint = 0xE5DD, description = "Rough fall, short"},
        ["kievanAccidentalFlat"] = {codepoint = 0xEC3E, description = "Kievan flat"},
        ["accidentalXenakisOneThirdToneSharp"] = {codepoint = 0xE470, description = "One-third-tone sharp (Xenakis)"},
        ["controlBeginTie"] = {codepoint = 0xE8E2, description = "Begin tie"},
        ["noteheadSlashVerticalEndsSmall"] = {codepoint = 0xE105, description = "Small slash with vertical ends"},
        ["accidentalHalfSharpArrowDown"] = {codepoint = 0xE29A, description = "Half sharp with arrow down"},
        ["functionBracketRight"] = {codepoint = 0xEA90, description = "Function theory bracket right"},
        ["mensuralBlackDragma"] = {codepoint = 0xE95A, description = "Black mensural dragma"},
        ["articMarcatoTenutoBelow"] = {codepoint = 0xE4BD, description = "Marcato-tenuto below"},
        ["brassFallSmoothLong"] = {codepoint = 0xE5DC, description = "Smooth fall, long"},
        ["accidentalRaiseOneTridecimalQuartertone"] = {codepoint = 0xE2E5, description = "Raise by one tridecimal quartertone"},
        ["stringsHarmonic"] = {codepoint = 0xE614, description = "Harmonic"},
        ["wiggleVibratoMediumFasterStill"] = {codepoint = 0xEADC, description = "Vibrato medium, faster still"},
        ["kahnLeftTurn"] = {codepoint = 0xEDF0, description = "Left-turn"},
        ["accidentalNaturalLoweredStockhausen"] = {codepoint = 0xED55, description = "Lowered natural (Stockhausen)"},
        ["accdnRH3RanksPiccolo"] = {codepoint = 0xE8A0, description = "Right hand, 3 ranks, 4' stop (piccolo)"},
        ["note256thUp"] = {codepoint = 0xE1E1, description = "256th note (demisemihemidemisemiquaver) stem up"},
        ["scaleDegree9"] = {codepoint = 0xEF08, description = "Scale degree 9"},
        ["accSagittalFlat23CDown"] = {codepoint = 0xE37D, description = "Flat 23C-down, 10° down [96 EDO], 5/8-tone down"},
        ["wiggleRandom4"] = {codepoint = 0xEAF3, description = "Quasi-random squiggle 4"},
        ["accSagittalFlat17kUp"] = {codepoint = 0xE3BD, description = "Flat 17k-up"},
        ["metNote256thDown"] = {codepoint = 0xECB2, description = "256th note (demisemihemidemisemiquaver) stem down"},
        ["timeSigX"] = {codepoint = 0xE09C, description = "Open time signature"},
        ["accSagittal25SmallDiesisDown"] = {codepoint = 0xE307, description = "25 small diesis down, 2° down [53 EDO]"},
        ["mensuralObliqueDesc5thBlack"] = {codepoint = 0xE98C, description = "Oblique form, descending 5th, black"},
        ["accidentalNarrowReversedFlat"] = {codepoint = 0xE284, description = "Narrow reversed flat(quarter-tone flat)"},
        ["accidentalWyschnegradsky10TwelfthsSharp"] = {codepoint = 0xE429, description = "5/6 tone sharp"},
        ["accSagittalFlat7v19CUp"] = {codepoint = 0xE3B5, description = "Flat 7:19C-up"},
        ["vocalNasalVoice"] = {codepoint = 0xE647, description = "Nasal voice"},
        ["noteheadMoonBlack"] = {codepoint = 0xE0CB, description = "Moon notehead black"},
        ["chantCustosStemDownPosHigh"] = {codepoint = 0xEA08, description = "Plainchant custos, stem down, high position"},
        ["lyricsElision"] = {codepoint = 0xE551, description = "Elision"},
        ["ottavaAlta"] = {codepoint = 0xE511, description = "Ottava alta"},
        ["arrowheadOpenRight"] = {codepoint = 0xEB8A, description = "Open arrowhead right (E)"},
        ["noteBFlatWhole"] = {codepoint = 0xE16B, description = "B flat (whole note)"},
        ["noteheadSlashedHalf1"] = {codepoint = 0xE0D1, description = "Slashed half notehead (bottom left to top right)"},
        ["keyboardPedalS"] = {codepoint = 0xE65A, description = "Pedal S"},
        ["barlineHeavyHeavy"] = {codepoint = 0xE035, description = "Heavy double barline"},
        ["ornamentRightFacingHook"] = {codepoint = 0xE573, description = "Right-facing hook"},
        ["accSagittal5v23SmallDiesisUp"] = {codepoint = 0xE374, description = "5:23 small diesis up, (5:23S, 5C plus 23C), 2° up [60 EDO], 1/5-tone up"},
        ["guitarString9"] = {codepoint = 0xE83C, description = "String number 9"},
        ["chantOriscusDescending"] = {codepoint = 0xE99D, description = "Oriscus descending"},
        ["pictBeaterWoodTimpaniUp"] = {codepoint = 0xE794, description = "Wood timpani stick up"},
        ["mensuralNoteheadLongaWhite"] = {codepoint = 0xE937, description = "Longa/brevis notehead, white"},
        ["accidentalUpsAndDownsLess"] = {codepoint = 0xEE63, description = "Accidental less"},
        ["keyboardBebung2DotsAbove"] = {codepoint = 0xE668, description = "Clavichord bebung, 2 finger movements (above)"},
        ["accSagittal5v13MediumDiesisUp"] = {codepoint = 0xE3A0, description = "5:13 medium diesis up, (5:13M, ~37M, 5C plus 13C)"},
        ["windLessTightEmbouchure"] = {codepoint = 0xE600, description = "Somewhat tight embouchure"},
        ["figbassDoubleFlat"] = {codepoint = 0xEA63, description = "Figured bass double flat"},
        ["brassLiftSmoothLong"] = {codepoint = 0xE5EE, description = "Smooth lift, long"},
        ["noteRaHalf"] = {codepoint = 0xEEEB, description = "Ra (half note)"},
        ["cClef8vb"] = {codepoint = 0xE05D, description = "C clef ottava bassa"},
        ["daseianSuperiores3"] = {codepoint = 0xEA3A, description = "Daseian superiores 3"},
        ["fermataShortHenzeAbove"] = {codepoint = 0xE4CC, description = "Short fermata (Henze) above"},
        ["gClef8vb"] = {codepoint = 0xE052, description = "G clef ottava bassa"},
        ["miscEyeglasses"] = {codepoint = 0xEC62, description = "Eyeglasses"},
        ["accdnRH4RanksSoprano"] = {codepoint = 0xE8B4, description = "Right hand, 4 ranks, soprano"},
        ["elecAudioChannelsSeven"] = {codepoint = 0xEB45, description = "Seven channels"},
        ["accidentalTripleFlat"] = {codepoint = 0xE266, description = "Triple flat"},
        ["chantStaffWide"] = {codepoint = 0xE8F1, description = "Plainchant staff (wide)"},
        ["arpeggiato"] = {codepoint = 0xE63C, description = "Arpeggiato"},
        ["analyticsThemeRetrograde"] = {codepoint = 0xE865, description = "Retrograde of theme"},
        ["mensuralProportionMajor"] = {codepoint = 0xE92B, description = "Mensural proportion major"},
        ["accidentalQuarterToneSharpArabic"] = {codepoint = 0xED35, description = "Arabic quarter-tone sharp"},
        ["accidentalThreeQuarterTonesFlatZimmermann"] = {codepoint = 0xE281, description = "Reversed flat and flat (three-quarter-tones flat) (Zimmermann)"},
        ["stringsMuteOff"] = {codepoint = 0xE617, description = "Mute off"},
        ["guitarString7"] = {codepoint = 0xE83A, description = "String number 7"},
        ["elecMonitor"] = {codepoint = 0xEB18, description = "Monitor"},
        ["brassLiftShort"] = {codepoint = 0xE5D1, description = "Lift, short"},
        ["accSagittalSharp11v49CUp"] = {codepoint = 0xE3C6, description = "Sharp 11:49C-up"},
        ["functionTLower"] = {codepoint = 0xEA8C, description = "Function theory minor tonic"},
        ["accSagittal6TinasDown"] = {codepoint = 0xE403, description = "6 tinas down, 2 minas down, 65/77-schismina down, 0.83 cents down"},
        ["organGerman6Minimae"] = {codepoint = 0xEE3C, description = "Six Minimae"},
        ["kahnToeDrop"] = {codepoint = 0xEDB7, description = "Toe-drop"},
        ["doubleLateralRollStevens"] = {codepoint = 0xE234, description = "Double lateral roll (Stevens)"},
        ["accidentalWyschnegradsky5TwelfthsSharp"] = {codepoint = 0xE424, description = "5/12 tone sharp"},
        ["noteDoubleWhole"] = {codepoint = 0xE1D0, description = "Double whole note (breve)"},
        ["noteBFlatBlack"] = {codepoint = 0xE199, description = "B flat (black note)"},
        ["mensuralNoteheadSemibrevisBlackVoid"] = {codepoint = 0xE93A, description = "Semibrevis notehead, black and void"},
        ["pictBeaterHardGlockenspielDown"] = {codepoint = 0xE785, description = "Hard glockenspiel stick down"},
        ["luteFrenchAppoggiaturaAbove"] = {codepoint = 0xEBD5, description = "Appoggiatura from above"},
        ["fermataShortBelow"] = {codepoint = 0xE4C5, description = "Short fermata below"},
        ["elecPlay"] = {codepoint = 0xEB1C, description = "Play"},
        ["daseianResidua2"] = {codepoint = 0xEA41, description = "Daseian residua 2"},
        ["noteSoBlack"] = {codepoint = 0xE164, description = "So (black note)"},
        ["accSagittalSharp5v49MUp"] = {codepoint = 0xE3D6, description = "Sharp 5:49M-up, (one and a half apotomes)"},
        ["functionFour"] = {codepoint = 0xEA74, description = "Function theory 4"},
        ["luteItalianFret2"] = {codepoint = 0xEBE2, description = "Second fret (2)"},
        ["timeSigFractionalSlash"] = {codepoint = 0xE08E, description = "Time signature fraction slash"},
        ["wiggleTrillSlower"] = {codepoint = 0xEAA6, description = "Trill wiggle segment, slower"},
        ["tuplet7"] = {codepoint = 0xE887, description = "Tuplet 7"},
        ["textHeadlessBlackNoteFrac8thLongStem"] = {codepoint = 0xE207, description = "Headless black note, fractional 8th beam, long stem"},
        ["chantDivisioMaior"] = {codepoint = 0xE8F4, description = "Divisio maior"},
        ["accSagittalFlat11v49CUp"] = {codepoint = 0xE3B9, description = "Flat 11:49C-up"},
        ["accdnLH3RanksTuttiSquare"] = {codepoint = 0xE8C5, description = "Left hand, 3 ranks, 2' stop + double 8' stop (tutti) (square)"},
        ["brassFallLipShort"] = {codepoint = 0xE5D7, description = "Lip fall, short"},
        ["mensuralCustosCheckmark"] = {codepoint = 0xEA0A, description = "Checkmark custos"},
        ["accSagittal17KleismaDown"] = {codepoint = 0xE393, description = "17 kleisma down"},
        ["articTenutoStaccatoBelow"] = {codepoint = 0xE4B3, description = "Louré (tenuto-staccato) below"},
        ["articSoftAccentTenutoStaccatoAbove"] = {codepoint = 0xED46, description = "Soft accent-tenuto-staccato above"},
        ["handbellsHandMartellato"] = {codepoint = 0xE812, description = "Hand martellato"},
        ["luteFingeringRHThird"] = {codepoint = 0xEBB0, description = "Right-hand fingering, third finger"},
        ["noteShapeTriangleUpWhite"] = {codepoint = 0xE1BA, description = "Triangle up white (Aikin 7-shape do)"},
        ["pictSiren"] = {codepoint = 0xE753, description = "Siren"},
        ["brassFlip"] = {codepoint = 0xE5E1, description = "Flip"},
        ["kahnGraceTapChange"] = {codepoint = 0xEDD1, description = "Grace-tap-change"},
        ["fingeringMLower"] = {codepoint = 0xED1A, description = "Fingering m (medio; right-hand middle finger for guitar)"},
        ["accidentalJohnstonUp"] = {codepoint = 0xE2B4, description = "Up arrow (raise by 33:32)"},
        ["ornamentShortObliqueLineBeforeNote"] = {codepoint = 0xE579, description = "Short oblique straight line SW-NE"},
        ["dynamicPPPPP"] = {codepoint = 0xE528, description = "ppppp"},
        ["accSagittalFlat11v19LDown"] = {codepoint = 0xE3DB, description = "Flat 11:19L-down"},
        ["ornamentObliqueLineBeforeNote"] = {codepoint = 0xE57B, description = "Oblique straight line SW-NE"},
        ["accSagittalDoubleFlat7v11kUp"] = {codepoint = 0xE367, description = "Double flat 7:11k-up"},
        ["articTenutoBelow"] = {codepoint = 0xE4A5, description = "Tenuto below"},
        ["ornamentTopRightConvexStroke"] = {codepoint = 0xE5A1, description = "Ornament top right convex stroke"},
        ["accidentalReversedFlatAndFlatArrowDown"] = {codepoint = 0xE295, description = "Reversed flat and flat with arrow down"},
        ["handbellsMalletBellSuspended"] = {codepoint = 0xE814, description = "Mallet, bell suspended"},
        ["accSagittalFractionalTinaDown"] = {codepoint = 0xE40B, description = "Fractional tina down, 77/(5⋅37)-schismina down, 0.08 cents down"},
        ["accidentalDoubleSharpThreeArrowsDown"] = {codepoint = 0xE2D8, description = "Double sharp lowered by three syntonic commas"},
        ["accidentalUpsAndDownsMore"] = {codepoint = 0xEE62, description = "Accidental more"},
        ["organGerman5Minimae"] = {codepoint = 0xEE38, description = "Five Minimae"},
        ["accSagittal11v19MediumDiesisDown"] = {codepoint = 0xE3A3, description = "11:19 medium diesis down"},
        ["mensuralCombStemUpFlagSemiminima"] = {codepoint = 0xE949, description = "Combining stem with semiminima flag up"},
        ["accSagittalFlat5v13MDown"] = {codepoint = 0xE3D1, description = "Flat 5:13M-down"},
        ["accidentalWyschnegradsky8TwelfthsSharp"] = {codepoint = 0xE427, description = "2/3 tone sharp"},
        ["pictFootballRatchet"] = {codepoint = 0xE6F5, description = "Football rattle"},
        ["fermataVeryShortAbove"] = {codepoint = 0xE4C2, description = "Very short fermata above"},
        ["timeSigOpenPenderecki"] = {codepoint = 0xE09D, description = "Open time signature (Penderecki)"},
        ["buzzRoll"] = {codepoint = 0xE22A, description = "Buzz roll"},
        ["accSagittalUnused4"] = {codepoint = 0xE3DF, description = "Unused"},
        ["quindicesimaBassa"] = {codepoint = 0xE516, description = "Quindicesima bassa"},
        ["fingeringSeparatorSlash"] = {codepoint = 0xED2E, description = "Fingering forward slash separator"},
        ["noteheadClusterDoubleWholeBottom"] = {codepoint = 0xE12E, description = "Combining double whole note cluster, bottom"},
        ["reversedBracketBottom"] = {codepoint = 0xE006, description = "Reversed bracket bottom"},
        ["noteShapeQuarterMoonWhite"] = {codepoint = 0xE1C2, description = "Quarter moon white (Walker 7-shape re)"},
        ["accidentalNarrowReversedFlatAndFlat"] = {codepoint = 0xE285, description = "Narrow reversed flat and flat(three-quarter-tones flat)"},
        ["mensuralRestSemifusa"] = {codepoint = 0xE9F8, description = "Semifusa rest"},
        ["dynamicNiente"] = {codepoint = 0xE526, description = "Niente"},
        ["beamAccelRit7"] = {codepoint = 0xEAFA, description = "Accel./rit. beam 7"},
        ["chantPunctumDeminutum"] = {codepoint = 0xE9A1, description = "Punctum deminutum"},
        ["noteDBlack"] = {codepoint = 0xE1A0, description = "D (black note)"},
        ["keyboardPedalHalf3"] = {codepoint = 0xE65C, description = "Half pedal mark 2"},
        ["accidentalQuarterToneFlatPenderecki"] = {codepoint = 0xE478, description = "Quarter tone flat (Penderecki)"},
        ["noteShapeDiamondBlack"] = {codepoint = 0xE1B9, description = "Diamond black (4-shape mi; 7-shape mi)"},
        ["accSagittal5v49MediumDiesisDown"] = {codepoint = 0xE3A7, description = "5:49 medium diesis down"},
        ["metricModulationArrowLeft"] = {codepoint = 0xEC63, description = "Left-pointing arrow for metric modulation"},
        ["analyticsNebenstimme"] = {codepoint = 0xE861, description = "Nebenstimme"},
        ["accSagittal8TinasDown"] = {codepoint = 0xE407, description = "8 tinas down, 11⋅17/(5²⋅7)-schismina down, 1.14 cents down"},
        ["kahnBrushBackward"] = {codepoint = 0xEDA7, description = "Brush-backward"},
        ["accSagittalDoubleFlat143CUp"] = {codepoint = 0xE3EB, description = "Double flat 143C-up"},
        ["noteheadParenthesisRight"] = {codepoint = 0xE0F6, description = "Closing parenthesis"},
        ["lyricsHyphenBaseline"] = {codepoint = 0xE553, description = "Baseline hyphen"},
        ["accidentalTripleSharp"] = {codepoint = 0xE265, description = "Triple sharp"},
        ["noteFSharpBlack"] = {codepoint = 0xE1A7, description = "F sharp (black note)"},
        ["luteItalianClefCSolFaUt"] = {codepoint = 0xEBF1, description = "C sol fa ut clef"},
        ["guitarBarreHalf"] = {codepoint = 0xE849, description = "Half barré"},
        ["noteAFlatHalf"] = {codepoint = 0xE17F, description = "A flat (half note)"},
        ["flag64thUp"] = {codepoint = 0xE246, description = "Combining flag 4 (64th) above"},
        ["pictBeaterWoodXylophoneUp"] = {codepoint = 0xE77C, description = "Wood xylophone stick up"},
        ["noteheadDiamondBlack"] = {codepoint = 0xE0DB, description = "Diamond black notehead"},
        ["accidentalLoweredStockhausen"] = {codepoint = 0xED51, description = "Lowered (Stockhausen)"},
        ["mensuralObliqueAsc4thBlack"] = {codepoint = 0xE978, description = "Oblique form, ascending 4th, black"},
        ["noteReWhole"] = {codepoint = 0xE151, description = "Re (whole note)"},
        ["caesuraShort"] = {codepoint = 0xE4D3, description = "Short caesura"},
        ["pictBeaterMediumYarnRight"] = {codepoint = 0xE7A8, description = "Medium yarn beater right"},
        ["wiggleCircularConstantFlippedLarge"] = {codepoint = 0xEAC3, description = "Constant circular motion segment (flipped, large)"},
        ["luteItalianHoldNote"] = {codepoint = 0xEBF3, description = "Hold note"},
        ["elecVideoIn"] = {codepoint = 0xEB4B, description = "Video in"},
        ["note1024thUp"] = {codepoint = 0xE1E5, description = "1024th note (semihemidemisemihemidemisemiquaver) stem up"},
        ["metNoteWhole"] = {codepoint = 0xECA2, description = "Whole note (semibreve)"},
        ["accdnCombRH3RanksEmpty"] = {codepoint = 0xE8C6, description = "Combining right hand, 3 ranks, empty"},
        ["noteheadCircledWhole"] = {codepoint = 0xE0E6, description = "Circled whole notehead"},
        ["kahnRipple"] = {codepoint = 0xEDE8, description = "Ripple"},
        ["accidentalNaturalTwoArrowsDown"] = {codepoint = 0xE2CC, description = "Natural lowered by two syntonic commas"},
        ["mensuralObliqueAsc5thBlackVoid"] = {codepoint = 0xE97E, description = "Oblique form, ascending 5th, black and void"},
        ["dynamicFF"] = {codepoint = 0xE52F, description = "ff"},
        ["accSagittal143CommaUp"] = {codepoint = 0xE394, description = "143 comma up, (143C, 13L less 11M)"},
        ["luteStaff6Lines"] = {codepoint = 0xEBA0, description = "Lute tablature staff, 6 courses"},
        ["accidentalDoubleFlatOneArrowDown"] = {codepoint = 0xE2C0, description = "Double flat lowered by one syntonic comma"},
        ["accidentalHabaQuarterToneLower"] = {codepoint = 0xEE67, description = "Quarter-tone lower (Alois Hába)"},
        ["kahnFleaHop"] = {codepoint = 0xEDB0, description = "Flea-hop"},
        ["mensuralObliqueDesc2ndVoid"] = {codepoint = 0xE981, description = "Oblique form, descending 2nd, void"},
        ["noteSoHalf"] = {codepoint = 0xE15C, description = "So (half note)"},
        ["noteGWhole"] = {codepoint = 0xE17B, description = "G (whole note)"},
        ["octaveParensLeft"] = {codepoint = 0xE51A, description = "Left parenthesis for octave signs"},
        ["keyboardPedalToe1"] = {codepoint = 0xE664, description = "Pedal toe 1"},
        ["keyboardRightPedalPictogram"] = {codepoint = 0xE660, description = "Right pedal pictogram"},
        ["noteCFlatWhole"] = {codepoint = 0xE16E, description = "C flat (whole note)"},
        ["accSagittal8TinasUp"] = {codepoint = 0xE406, description = "8 tinas up, 11⋅17/(5²⋅7)-schismina up, 1.14 cents up"},
        ["accidentalSharp"] = {codepoint = 0xE262, description = "Sharp"},
        ["noteBBlack"] = {codepoint = 0xE19A, description = "B (black note)"},
        ["accSagittalSharp25SDown"] = {codepoint = 0xE310, description = "Sharp 25S-down, 3° up [53 EDO]"},
        ["articSoftAccentBelow"] = {codepoint = 0xED41, description = "Soft accent below"},
        ["ornamentPrecompTurnTrillBach"] = {codepoint = 0xE5B7, description = "Turn-trill with two-note suffix (J.S. Bach)"},
        ["textTupletBracketStartShortStem"] = {codepoint = 0xE1FE, description = "Tuplet bracket start for short stem"},
        ["noteTeWhole"] = {codepoint = 0xEEE8, description = "Te (whole note)"},
        ["textTuplet3LongStem"] = {codepoint = 0xE202, description = "Tuplet number 3 for long stem"},
        ["accSagittal5v13MediumDiesisDown"] = {codepoint = 0xE3A1, description = "5:13 medium diesis down"},
        ["pictGobletDrum"] = {codepoint = 0xE6E2, description = "Goblet drum (djembe, dumbek)"},
        ["accSagittalSharp5v23SUp"] = {codepoint = 0xE380, description = "Sharp 5:23S-up, 7° up [60 EDO], 7/10-tone up"},
        ["mensuralBlackSemibrevisCaudata"] = {codepoint = 0xE959, description = "Black mensural semibrevis caudata"},
        ["functionZero"] = {codepoint = 0xEA70, description = "Function theory 0"},
        ["noteFiHalf"] = {codepoint = 0xEEED, description = "Fi (half note)"},
        ["brassMuteClosed"] = {codepoint = 0xE5E5, description = "Muted (closed)"},
        ["wiggleTrillSlowerStill"] = {codepoint = 0xEAA7, description = "Trill wiggle segment, slower still"},
        ["articUnstressAbove"] = {codepoint = 0xE4B8, description = "Unstress above"},
        ["stringsJeteAbove"] = {codepoint = 0xE620, description = "Jeté (gettato) above"},
        ["functionFUpper"] = {codepoint = 0xEA99, description = "Function theory F"},
        ["accSagittal4TinasUp"] = {codepoint = 0xE3FE, description = "4 tinas up, 5²⋅11²/7-schismina up, 0.57 cents up"},
        ["staff6Lines"] = {codepoint = 0xE015, description = "6-line staff"},
        ["stemHarpStringNoise"] = {codepoint = 0xE21F, description = "Combining harp string noise stem"},
        ["noteTeHalf"] = {codepoint = 0xEEF1, description = "Te (half note)"},
        ["accSagittal7v19CommaDown"] = {codepoint = 0xE39B, description = "7:19 comma down"},
        ["accSagittal25SmallDiesisUp"] = {codepoint = 0xE306, description = "25 small diesis up, (25S, ~5:13S, ~37S, 5C plus 5C), 2° up [53 EDO]"},
        ["repeatRight"] = {codepoint = 0xE041, description = "Right (end) repeat sign"},
        ["accdnPush"] = {codepoint = 0xE8CB, description = "Push"},
        ["brassLiftSmoothShort"] = {codepoint = 0xE5EC, description = "Smooth lift, short"},
        ["accidental1CommaSharp"] = {codepoint = 0xE450, description = "1-comma sharp"},
        ["legerLineWide"] = {codepoint = 0xE023, description = "Leger line (wide)"},
        ["noteDSharpWhole"] = {codepoint = 0xE173, description = "D sharp (whole note)"},
        ["elecPause"] = {codepoint = 0xEB1E, description = "Pause"},
        ["accSagittal11MediumDiesisDown"] = {codepoint = 0xE30B, description = "11 medium diesis down, 1°[17 31] 2°46 down, 1/4-tone down"},
        ["noteEmptyWhole"] = {codepoint = 0xE1AD, description = "Empty whole note"},
        ["guitarFadeIn"] = {codepoint = 0xE843, description = "Fade in"},
        ["kahnHeel"] = {codepoint = 0xEDAA, description = "Heel"},
        ["kahnZink"] = {codepoint = 0xEDDF, description = "Zink"},
        ["accidentalWyschnegradsky3TwelfthsFlat"] = {codepoint = 0xE42D, description = "1/4 tone flat"},
        ["noteESharpWhole"] = {codepoint = 0xE176, description = "E sharp (whole note)"},
        ["wiggleVibratoMediumFast"] = {codepoint = 0xEADE, description = "Vibrato medium, fast"},
        ["mensuralColorationStartSquare"] = {codepoint = 0xEA0C, description = "Coloration start, square"},
        ["dynamicHairpinBracketLeft"] = {codepoint = 0xE544, description = "Left bracket (for hairpins)"},
        ["accSagittalDoubleFlat7CUp"] = {codepoint = 0xE32F, description = "Double flat 7C-up, 5° down [43 EDO], 10° down [72 EDO], 5/6-tone down"},
        ["accSagittal11LargeDiesisDown"] = {codepoint = 0xE30D, description = "11 large diesis down, 3° down [46 EDO]"},
        ["mensuralNoteheadMaximaBlackVoid"] = {codepoint = 0xE932, description = "Maxima notehead, black and void"},
        ["accidentalFiveQuarterTonesSharpArrowUp"] = {codepoint = 0xE276, description = "Five-quarter-tones sharp"},
        ["ornamentTurnUp"] = {codepoint = 0xE56A, description = "Turn up"},
        ["noteheadRoundWhite"] = {codepoint = 0xE114, description = "Round white notehead"},
        ["daseianExcellentes2"] = {codepoint = 0xEA3D, description = "Daseian excellentes 2"},
        ["noteShapeArrowheadLeftBlack"] = {codepoint = 0xE1C9, description = "Arrowhead left black (Funk 7-shape re)"},
        ["daseianFinales4"] = {codepoint = 0xEA37, description = "Daseian finales 4"},
        ["accidentalKoron"] = {codepoint = 0xE460, description = "Koron (quarter tone flat)"},
        ["chantLigaturaDesc4th"] = {codepoint = 0xE9BB, description = "Ligated stroke, descending 4th"},
        ["accidentalNaturalThreeArrowsUp"] = {codepoint = 0xE2DB, description = "Natural raised by three syntonic commas"},
        ["kahnChug"] = {codepoint = 0xEDDD, description = "Chug"},
        ["elecMicrophoneUnmute"] = {codepoint = 0xEB29, description = "Unmute microphone"},
        ["noteheadClusterHalf2nd"] = {codepoint = 0xE126, description = "Half note cluster, 2nd"},
        ["csymAlteredBassSlash"] = {codepoint = 0xE87B, description = "Slash for altered bass note"},
        ["accidentalDoubleFlatTurned"] = {codepoint = 0xE485, description = "Turned double flat"},
        ["pictBeaterMetalBassDrumDown"] = {codepoint = 0xE79F, description = "Metal bass drum stick down"},
        ["pictWoundSoftRight"] = {codepoint = 0xE7B9, description = "Wound beater, soft core right"},
        ["stemVibratoPulse"] = {codepoint = 0xE219, description = "Combining vibrato pulse accent (Saunders) stem"},
        ["elecTape"] = {codepoint = 0xEB14, description = "Tape"},
        ["smnHistorySharp"] = {codepoint = 0xEC54, description = "Sharp history sign"},
        ["luteGermanTLower"] = {codepoint = 0xEC12, description = "2nd course, 4th fret (t)"},
        ["mensuralObliqueAsc2ndBlackVoid"] = {codepoint = 0xE972, description = "Oblique form, ascending 2nd, black and void"},
        ["articTenutoAccentAbove"] = {codepoint = 0xE4B4, description = "Tenuto-accent above"},
        ["barlineFinal"] = {codepoint = 0xE032, description = "Final barline"},
        ["reversedBrace"] = {codepoint = 0xE001, description = "Reversed brace"},
        ["pictBeaterMediumTimpaniLeft"] = {codepoint = 0xE78F, description = "Medium timpani stick left"},
        ["stemMultiphonicsBlack"] = {codepoint = 0xE21A, description = "Combining multiphonics (black) stem"},
        ["repeat1Bar"] = {codepoint = 0xE500, description = "Repeat last bar"},
        ["accSagittalFlat7v11kDown"] = {codepoint = 0xE355, description = "Flat 7:11k-down"},
        ["organGerman6Semiminimae"] = {codepoint = 0xEE3D, description = "Six Semiminimae"},
        ["accidentalEnharmonicTilde"] = {codepoint = 0xE2F9, description = "Enharmonically reinterpret accidental tilde"},
        ["accSagittalSharp143CDown"] = {codepoint = 0xE3BA, description = "Sharp 143C-down"},
        ["accdnLH2RanksMasterRound"] = {codepoint = 0xE8BE, description = "Left hand, 2 ranks, master (round)"},
        ["accidentalThreeQuarterTonesFlatTartini"] = {codepoint = 0xE487, description = "Three-quarter-tones flat (Tartini)"},
        ["mensuralObliqueDesc3rdBlack"] = {codepoint = 0xE984, description = "Oblique form, descending 3rd, black"},
        ["accSagittalSharp5CDown"] = {codepoint = 0xE314, description = "Sharp 5C-down, 2°[22 29] 3°[27 34 41] 4°[39 46 53] 5°[72] 7°[96] up, 5/12-tone up"},
        ["accidentalReversedFlatArrowDown"] = {codepoint = 0xE291, description = "Reversed flat with arrow down"},
        ["noteESharpHalf"] = {codepoint = 0xE18D, description = "E sharp (half note)"},
        ["wiggleGlissandoGroup2"] = {codepoint = 0xEABE, description = "Group glissando 2"},
        ["fingeringSLower"] = {codepoint = 0xED8F, description = "Fingering s (right-hand little finger for guitar)"},
        ["noteheadTriangleRoundDownWhite"] = {codepoint = 0xE0CC, description = "Triangle-round notehead down white"},
        ["arrowheadBlackUp"] = {codepoint = 0xEB78, description = "Black arrowhead up (N)"},
        ["arrowheadOpenUpRight"] = {codepoint = 0xEB89, description = "Open arrowhead up-right (NE)"},
        ["noteheadTriangleUpWhole"] = {codepoint = 0xE0BB, description = "Triangle notehead up whole"},
        ["pictBeaterDoubleBassDrumUp"] = {codepoint = 0xE7A0, description = "Double bass drum stick up"},
        ["accdnRH4RanksAlto"] = {codepoint = 0xE8B5, description = "Right hand, 4 ranks, alto"},
        ["accidentalBracketLeft"] = {codepoint = 0xE26C, description = "Accidental bracket, left"},
        ["keyboardPedalHeelToe"] = {codepoint = 0xE666, description = "Pedal heel or toe"},
        ["staffPosRaise4"] = {codepoint = 0xEB93, description = "Raise 4 staff positions"},
        ["accidentalThreeQuarterTonesSharpArabic"] = {codepoint = 0xED37, description = "Arabic three-quarter-tones sharp"},
        ["accSagittalFlat7v19CDown"] = {codepoint = 0xE3CB, description = "Flat 7:19C-down"},
        ["scaleDegree5"] = {codepoint = 0xEF04, description = "Scale degree 5"},
        ["accSagittalFlat55CDown"] = {codepoint = 0xE359, description = "Flat 55C-down, 11° down [96 EDO], 11/16-tone down"},
        ["pictTomTomJapanese"] = {codepoint = 0xE6D9, description = "Japanese tom-tom"},
        ["luteBarlineEndRepeat"] = {codepoint = 0xEBA4, description = "Lute tablature end repeat barline"},
        ["noteDoBlack"] = {codepoint = 0xE160, description = "Do (black note)"},
        ["accidentalDoubleSharpTwoArrowsDown"] = {codepoint = 0xE2CE, description = "Double sharp lowered by two syntonic commas"},
        ["noteHalfDown"] = {codepoint = 0xE1D4, description = "Half note (minim) stem down"},
        ["luteGermanRLower"] = {codepoint = 0xEC10, description = "4th course, 4th fret (r)"},
        ["noteShapeTriangleRightDoubleWhole"] = {codepoint = 0xECD2, description = "Triangle right double whole (stem down; 4-shape fa; 7-shape fa)"},
        ["mensuralProlation10"] = {codepoint = 0xE919, description = "Tempus imperfectum cum prolatione imperfecta diminution 4"},
        ["accidentalRaiseTwoSeptimalCommas"] = {codepoint = 0xE2E1, description = "Raise by two septimal commas"},
        ["functionKLower"] = {codepoint = 0xEA9D, description = "Function theory k"},
        ["accSagittalFlat7v11CUp"] = {codepoint = 0xE34D, description = "Flat 7:11C-up, 4° down [60 EDO], 2/5-tone down"},
        ["accidentalCombiningLower41Comma"] = {codepoint = 0xEE54, description = "Combining lower by one 41-limit comma"},
        ["stringsUpBowBeyondBridge"] = {codepoint = 0xEE85, description = "Up bow, beyond bridge"},
        ["brassFallLipLong"] = {codepoint = 0xE5D9, description = "Lip fall, long"},
        ["dynamicFFFFFF"] = {codepoint = 0xE533, description = "ffffff"},
        ["functionEight"] = {codepoint = 0xEA78, description = "Function theory 8"},
        ["accSagittal5v19CommaUp"] = {codepoint = 0xE372, description = "5:19 comma up, (5:19C, 5C plus 19s), 1/20-tone up"},
        ["pictGumMediumLeft"] = {codepoint = 0xE7C2, description = "Medium gum beater, left"},
        ["accidentalWyschnegradsky11TwelfthsFlat"] = {codepoint = 0xE435, description = "11/12 tone flat"},
        ["noteheadWholeFilled"] = {codepoint = 0xE0FA, description = "Filled whole (semibreve) notehead"},
        ["pictBeaterWoodXylophoneLeft"] = {codepoint = 0xE77F, description = "Wood xylophone stick left"},
        ["pictBeaterMetalRight"] = {codepoint = 0xE7C9, description = "Metal beater, right"},
        ["noteRaBlack"] = {codepoint = 0xEEF4, description = "Ra (black note)"},
        ["noteLiBlack"] = {codepoint = 0xEEF8, description = "Li (black note)"},
        ["note32ndUp"] = {codepoint = 0xE1DB, description = "32nd note (demisemiquaver) stem up"},
        ["noteheadRoundBlackSlashed"] = {codepoint = 0xE118, description = "Round black notehead, slashed"},
        ["controlEndPhrase"] = {codepoint = 0xE8E7, description = "End phrase"},
        ["arrowheadOpenUpLeft"] = {codepoint = 0xEB8F, description = "Open arrowhead up-left (NW)"},
        ["accSagittalFlat11MDown"] = {codepoint = 0xE327, description = "Flat 11M-down, 3° down [17 31 EDOs], 7° down [46 EDO], 3/4-tone down"},
        ["noteBHalf"] = {codepoint = 0xE183, description = "B (half note)"},
        ["handbellsSwing"] = {codepoint = 0xE81A, description = "Swing"},
        ["fingering7"] = {codepoint = 0xED25, description = "Fingering 7"},
        ["stringsOverpressurePossibileUpBow"] = {codepoint = 0xE61E, description = "Overpressure possibile, up bow"},
        ["stringsScrapeParallelInward"] = {codepoint = 0xEE86, description = "Scrape, parallel inward"},
        ["smnNatural"] = {codepoint = 0xEC58, description = "Natural (N)"},
        ["mensuralBlackMaxima"] = {codepoint = 0xE950, description = "Black mensural maxima"},
        ["noteShapeQuarterMoonBlack"] = {codepoint = 0xE1C3, description = "Quarter moon black (Walker 7-shape re)"},
        ["accidentalBracketRight"] = {codepoint = 0xE26D, description = "Accidental bracket, right"},
        ["accdnLH3Ranks2Plus8Square"] = {codepoint = 0xE8C4, description = "Left hand, 3 ranks, 2' stop + 8' stop (square)"},
        ["noteShapeTriangleRoundLeftWhite"] = {codepoint = 0xE1CA, description = "Triangle-round left white (Funk 7-shape ti)"},
        ["arrowheadOpenLeft"] = {codepoint = 0xEB8E, description = "Open arrowhead left (W)"},
        ["accidentalDoubleSharpOneArrowDown"] = {codepoint = 0xE2C4, description = "Double sharp lowered by one syntonic comma"},
        ["noteheadCircledHalf"] = {codepoint = 0xE0E5, description = "Circled half notehead"},
        ["fingering7Italic"] = {codepoint = 0xED87, description = "Fingering 7 italic"},
        ["kahnSnap"] = {codepoint = 0xEDB9, description = "Snap"},
        ["noteheadDiamondClusterBlack3rd"] = {codepoint = 0xE13B, description = "Black diamond cluster, 3rd"},
        ["flag8thUp"] = {codepoint = 0xE240, description = "Combining flag 1 (8th) above"},
        ["guitarFadeOut"] = {codepoint = 0xE844, description = "Fade out"},
        ["csymDiminished"] = {codepoint = 0xE870, description = "Diminished"},
        ["mensuralRestLongaImperfecta"] = {codepoint = 0xE9F2, description = "Longa imperfecta rest"},
        ["wiggleVibratoSmallSlow"] = {codepoint = 0xEAD8, description = "Vibrato small, slow"},
        ["elecLoop"] = {codepoint = 0xEB23, description = "Loop"},
        ["beamAccelRit9"] = {codepoint = 0xEAFC, description = "Accel./rit. beam 9"},
        ["analyticsEndStimme"] = {codepoint = 0xE863, description = "End of stimme"},
        ["accdnRicochetStem2"] = {codepoint = 0xE8D2, description = "Combining ricochet for stem (2 tones)"},
        ["functionGUpper"] = {codepoint = 0xEA83, description = "Function theory G"},
        ["luteGermanFLower"] = {codepoint = 0xEC05, description = "5th course, 2nd fret (f)"},
        ["noteAFlatWhole"] = {codepoint = 0xE168, description = "A flat (whole note)"},
        ["staff3LinesWide"] = {codepoint = 0xE018, description = "3-line staff (wide)"},
        ["organGermanGisUpper"] = {codepoint = 0xEE08, description = "German organ tablature great Gis"},
        ["noteheadCowellNinthNoteSeriesHalf"] = {codepoint = 0xEEAB, description = "4/9 note (ninth note series, Cowell)"},
        ["pictSistrum"] = {codepoint = 0xE746, description = "Sistrum"},
        ["cClefCombining"] = {codepoint = 0xE061, description = "Combining C clef"},
        ["fingeringSubstitutionAbove"] = {codepoint = 0xED20, description = "Finger substitution above"},
        ["noteheadSlashDiamondWhite"] = {codepoint = 0xE104, description = "Large white diamond"},
        ["noteheadClusterQuarter3rd"] = {codepoint = 0xE12B, description = "Quarter note cluster, 3rd"},
        ["wiggleArpeggiatoUpSwash"] = {codepoint = 0xEAAB, description = "Arpeggiato upward swash"},
        ["pictGuiro"] = {codepoint = 0xE6F3, description = "Guiro"},
        ["ornamentPinceCouperin"] = {codepoint = 0xE588, description = "Pincé (Couperin)"},
        ["chantEntryLineAsc4th"] = {codepoint = 0xE9B6, description = "Entry line, ascending 4th"},
        ["accidentalFlat"] = {codepoint = 0xE260, description = "Flat"},
        ["textCont16thBeamShortStem"] = {codepoint = 0xE1F9, description = "Continuing 16th beam for short stem"},
        ["noteheadSlashHorizontalEnds"] = {codepoint = 0xE101, description = "Slash with horizontal ends"},
        ["mensuralProlation1"] = {codepoint = 0xE910, description = "Tempus perfectum cum prolatione perfecta (9/8)"},
        ["pictBeaterBrassMalletsLeft"] = {codepoint = 0xE7EE, description = "Brass mallets left"},
        ["ornamentLeftShakeT"] = {codepoint = 0xE596, description = "Ornament left shake t"},
        ["pictDuckCall"] = {codepoint = 0xE757, description = "Duck call"},
        ["keyboardPedalE"] = {codepoint = 0xE652, description = "Pedal e"},
        ["pictScrapeCenterToEdge"] = {codepoint = 0xE7F1, description = "Scrape from center to edge"},
        ["noteDiWhole"] = {codepoint = 0xEEE0, description = "Di (whole note)"},
        ["noteheadDiamondClusterWhiteMiddle"] = {codepoint = 0xE13D, description = "Combining white diamond cluster, middle"},
        ["accidentalFlatRepeatedLineStockhausen"] = {codepoint = 0xED5C, description = "Repeated flat, note on line (Stockhausen)"},
        ["brassValveTrill"] = {codepoint = 0xE5EF, description = "Valve trill"},
        ["tuplet2"] = {codepoint = 0xE882, description = "Tuplet 2"},
        ["noteSeHalf"] = {codepoint = 0xEEEE, description = "Se (half note)"},
        ["noteheadSlashedDoubleWhole2"] = {codepoint = 0xE0D6, description = "Slashed double whole notehead (top left to bottom right)"},
        ["pictXylBass"] = {codepoint = 0xE6A3, description = "Bass xylophone"},
        ["fingering6Italic"] = {codepoint = 0xED86, description = "Fingering 6 italic"},
        ["guitarVibratoStroke"] = {codepoint = 0xEAB2, description = "Vibrato wiggle segment"},
        ["luteBarlineStartRepeat"] = {codepoint = 0xEBA3, description = "Lute tablature start repeat barline"},
        ["kahnToe"] = {codepoint = 0xEDAB, description = "Toe"},
        ["arrowWhiteRight"] = {codepoint = 0xEB6A, description = "White arrow right (E)"},
        ["accidentalQuarterToneSharpArrowDown"] = {codepoint = 0xE275, description = "Quarter-tone sharp"},
        ["ornamentDoubleObliqueLinesBeforeNote"] = {codepoint = 0xE57D, description = "Double oblique straight lines SW-NE"},
        ["luteFrenchFretN"] = {codepoint = 0xEBCC, description = "12th fret (n)"},
        ["noteheadCircleX"] = {codepoint = 0xE0B3, description = "Circle X notehead"},
        ["wiggleVibratoSmallestFast"] = {codepoint = 0xEAD0, description = "Vibrato smallest, fast"},
        ["accSagittal5v7KleismaDown"] = {codepoint = 0xE301, description = "5:7 kleisma down"},
        ["handbellsEcho2"] = {codepoint = 0xE81C, description = "Echo 2"},
        ["pictTubularBells"] = {codepoint = 0xE6C0, description = "Tubular bells"},
        ["tuplet5"] = {codepoint = 0xE885, description = "Tuplet 5"},
        ["functionTUpper"] = {codepoint = 0xEA8B, description = "Function theory tonic"},
        ["timeSigPlusSmall"] = {codepoint = 0xE08D, description = "Time signature + (for numerators)"},
        ["accSagittalDoubleSharp11v49CDown"] = {codepoint = 0xE3E8, description = "Double sharp 11:49C-down"},
        ["functionPLower"] = {codepoint = 0xEA88, description = "Function theory p"},
        ["accSagittalDoubleFlat7v11CUp"] = {codepoint = 0xE361, description = "Double flat 7:11C-up, 9° down [60 EDO], 9/10-tone down"},
        ["functionRLower"] = {codepoint = 0xED03, description = "Function theory r"},
        ["scaleDegree1"] = {codepoint = 0xEF00, description = "Scale degree 1"},
        ["ornamentPrecompMordentRelease"] = {codepoint = 0xE5C5, description = "Mordent with release"},
        ["chantStrophicus"] = {codepoint = 0xE99F, description = "Strophicus"},
        ["harpTuningKeyHandle"] = {codepoint = 0xE691, description = "Use handle of tuning key pictogram"},
        ["accSagittalSharp17kDown"] = {codepoint = 0xE3BC, description = "Sharp 17k-down"},
        ["fingering4"] = {codepoint = 0xED14, description = "Fingering 4 (ring finger)"},
        ["dynamicSforzandoPiano"] = {codepoint = 0xE537, description = "Sforzando-piano"},
        ["accdnRH4RanksBassAlto"] = {codepoint = 0xE8BA, description = "Right hand, 4 ranks, bass/alto"},
        ["ornamentPrecompSlide"] = {codepoint = 0xE5B0, description = "Slide"},
        ["noteheadCowellThirteenthNoteSeriesWhole"] = {codepoint = 0xEEB0, description = "8/13 note (thirteenth note series, Cowell)"},
        ["kahnZank"] = {codepoint = 0xEDE4, description = "Zank"},
        ["chantStrophicusAuctus"] = {codepoint = 0xE9A0, description = "Strophicus auctus"},
        ["luteGermanEUpper"] = {codepoint = 0xEC1B, description = "6th course, 5th fret (E)"},
        ["mensuralObliqueDesc4thBlack"] = {codepoint = 0xE988, description = "Oblique form, descending 4th, black"},
        ["accidentalKomaSharp"] = {codepoint = 0xE444, description = "Koma (sharp)"},
        ["luteItalianReleaseFinger"] = {codepoint = 0xEBF5, description = "Release finger"},
        ["pictBeaterSnareSticksUp"] = {codepoint = 0xE7D1, description = "Snare sticks up"},
        ["functionNUpperSuperscript"] = {codepoint = 0xED02, description = "Function theory superscript N"},
        ["accSagittal7CommaDown"] = {codepoint = 0xE305, description = "7 comma down, 1° down [43 EDO], 2° down [72 EDO], 1/6-tone down"},
        ["figbassTripleSharp"] = {codepoint = 0xECC2, description = "Figured bass triple sharp"},
        ["guitarStrumDown"] = {codepoint = 0xE847, description = "Strum direction down"},
        ["csymDiagonalArrangementSlash"] = {codepoint = 0xE87C, description = "Slash for chord symbols arranged diagonally"},
        ["luteItalianTempoFast"] = {codepoint = 0xEBEA, description = "Fast tempo indication (de Mudarra)"},
        ["legerLine"] = {codepoint = 0xE022, description = "Leger line"},
        ["flagInternalDown"] = {codepoint = 0xE251, description = "Internal combining flag below"},
        ["mensuralObliqueDesc2ndBlackVoid"] = {codepoint = 0xE982, description = "Oblique form, descending 2nd, black and void"},
        ["accSagittalFlat17CUp"] = {codepoint = 0xE351, description = "Flat 17C-up"},
        ["pictCelesta"] = {codepoint = 0xE6B0, description = "Celesta"},
        ["functionSlashedDD"] = {codepoint = 0xEA82, description = "Function theory double dominant seventh"},
        ["keyboardBebung4DotsBelow"] = {codepoint = 0xE66D, description = "Clavichord bebung, 4 finger movements (below)"},
        ["accidentalLowerOneUndecimalQuartertone"] = {codepoint = 0xE2E2, description = "Lower by one undecimal quartertone"},
        ["pictChineseCymbal"] = {codepoint = 0xE726, description = "Chinese cymbal"},
        ["harpSalzedoDampBelow"] = {codepoint = 0xE699, description = "Damp below (Salzedo)"},
        ["kahnRiffle"] = {codepoint = 0xEDE7, description = "Riffle"},
        ["accSagittalDoubleSharp23CDown"] = {codepoint = 0xE386, description = "Double sharp 23C-down, 14°up [96 EDO], 7/8-tone up"},
        ["pictBeaterMediumBassDrumDown"] = {codepoint = 0xE79B, description = "Medium bass drum stick down"},
        ["timeSig9Turned"] = {codepoint = 0xECE9, description = "Turned time signature 9"},
        ["tuplet1"] = {codepoint = 0xE881, description = "Tuplet 1"},
        ["csymParensRightVeryTall"] = {codepoint = 0xE87A, description = "Triple-height right parenthesis"},
        ["organGerman4Fusae"] = {codepoint = 0xEE36, description = "Four Fusae"},
        ["codaSquare"] = {codepoint = 0xE049, description = "Square coda"},
        ["noteDSharpBlack"] = {codepoint = 0xE1A1, description = "D sharp (black note)"},
        ["mensuralObliqueAsc2ndWhite"] = {codepoint = 0xE973, description = "Oblique form, ascending 2nd, white"},
        ["dynamicForte"] = {codepoint = 0xE522, description = "Forte"},
        ["brace"] = {codepoint = 0xE000, description = "Brace"},
        ["noteShapeKeystoneDoubleWhole"] = {codepoint = 0xECD8, description = "Inverted keystone double whole (Walker 7-shape do)"},
        ["mensuralObliqueAsc4thWhite"] = {codepoint = 0xE97B, description = "Oblique form, ascending 4th, white"},
        ["arrowOpenUp"] = {codepoint = 0xEB70, description = "Open arrow up (N)"},
        ["noteheadSquareWhite"] = {codepoint = 0xE0B8, description = "Square notehead white"},
        ["pictEdgeOfCymbal"] = {codepoint = 0xE729, description = "Edge of cymbal"},
        ["organGerman5Semifusae"] = {codepoint = 0xEE3B, description = "Five Semifusae"},
        ["noteheadLargeArrowUpDoubleWhole"] = {codepoint = 0xE0ED, description = "Large arrow up (highest pitch) double whole notehead"},
        ["luteGermanYLower"] = {codepoint = 0xEC15, description = "4th course, 5th fret (y)"},
        ["chantCustosStemUpPosMiddle"] = {codepoint = 0xEA06, description = "Plainchant custos, stem up, middle position"},
        ["accidentalDoubleFlatReversed"] = {codepoint = 0xE483, description = "Reversed double flat"},
        ["accSagittal5v7KleismaUp"] = {codepoint = 0xE300, description = "5:7 kleisma up, (5:7k, ~11:13k, 7C less 5C)"},
        ["noteheadSlashX"] = {codepoint = 0xE106, description = "Large X notehead"},
        ["noteheadTriangleUpHalf"] = {codepoint = 0xE0BC, description = "Triangle notehead up half"},
        ["pictBeaterHammerPlasticUp"] = {codepoint = 0xE7CD, description = "Plastic hammer, up"},
        ["accSagittalDoubleFlat19sUp"] = {codepoint = 0xE3EF, description = "Double flat 19s-up"},
        ["accSagittal55CommaDown"] = {codepoint = 0xE345, description = "55 comma down, 3° down [96 EDO], 3/16-tone down"},
        ["guitarString11"] = {codepoint = 0xE84B, description = "String number 11"},
        ["pictBeaterSoftGlockenspielDown"] = {codepoint = 0xE781, description = "Soft glockenspiel stick down"},
        ["csymBracketLeftTall"] = {codepoint = 0xE877, description = "Double-height left bracket"},
        ["organGermanGUpper"] = {codepoint = 0xEE07, description = "German organ tablature great G"},
        ["elecMicrophoneMute"] = {codepoint = 0xEB28, description = "Mute microphone"},
        ["noteheadPlusWhole"] = {codepoint = 0xE0AD, description = "Plus notehead whole"},
        ["noteheadMoonWhite"] = {codepoint = 0xE0CA, description = "Moon notehead white"},
        ["fClef8va"] = {codepoint = 0xE065, description = "F clef ottava alta"},
        ["staff6LinesNarrow"] = {codepoint = 0xE021, description = "6-line staff (narrow)"},
        ["arrowWhiteUp"] = {codepoint = 0xEB68, description = "White arrow up (N)"},
        ["luteItalianFret9"] = {codepoint = 0xEBE9, description = "Ninth fret (9)"},
        ["accSagittal1TinaDown"] = {codepoint = 0xE3F9, description = "1 tina down, 7²⋅11⋅19/5-schismina down, 0.17 cents down"},
        ["figbass9Raised"] = {codepoint = 0xEA62, description = "Figured bass 9 raised by half-step"},
        ["noteheadTriangleDownHalf"] = {codepoint = 0xE0C5, description = "Triangle notehead down half"},
        ["swissRudimentsNoteheadHalfDouble"] = {codepoint = 0xEE73, description = "Swiss rudiments doublé half (minim) notehead"},
        ["noteheadClusterDoubleWhole2nd"] = {codepoint = 0xE124, description = "Double whole note cluster, 2nd"},
        ["mensuralProlation11"] = {codepoint = 0xE91A, description = "Tempus imperfectum cum prolatione imperfecta diminution 5"},
        ["noteLaBlack"] = {codepoint = 0xE165, description = "La (black note)"},
        ["accidentalNaturalTwoArrowsUp"] = {codepoint = 0xE2D1, description = "Natural raised by two syntonic commas"},
        ["fermataBelow"] = {codepoint = 0xE4C1, description = "Fermata below"},
        ["timeSigParensRightSmall"] = {codepoint = 0xE093, description = "Right parenthesis for numerator only"},
        ["mensuralObliqueAsc4thVoid"] = {codepoint = 0xE979, description = "Oblique form, ascending 4th, void"},
        ["accidentalFlatOneArrowDown"] = {codepoint = 0xE2C1, description = "Flat lowered by one syntonic comma"},
        ["accidentalCombiningLower29LimitComma"] = {codepoint = 0xEE50, description = "Combining lower by one 29-limit comma"},
        ["medRenFlatWithDot"] = {codepoint = 0xE9E4, description = "Flat with dot"},
        ["mensuralObliqueAsc2ndBlack"] = {codepoint = 0xE970, description = "Oblique form, ascending 2nd, black"},
        ["luteItalianTempoSomewhatFast"] = {codepoint = 0xEBEB, description = "Somewhat fast tempo indication (de Narvaez)"},
        ["accidentalDoubleSharpOneArrowUp"] = {codepoint = 0xE2C9, description = "Double sharp raised by one syntonic comma"},
        ["ornamentTurnSlash"] = {codepoint = 0xE569, description = "Turn with slash"},
        ["wiggleRandom2"] = {codepoint = 0xEAF1, description = "Quasi-random squiggle 2"},
        ["noteheadSlashVerticalEnds"] = {codepoint = 0xE100, description = "Slash with vertical ends"},
        ["mensuralCombStemDownFlagFlared"] = {codepoint = 0xE946, description = "Combining stem with flared flag down"},
        ["chantConnectingLineAsc5th"] = {codepoint = 0xE9C0, description = "Connecting line, ascending 5th"},
        ["accidentalNatural"] = {codepoint = 0xE261, description = "Natural"},
        ["noteheadSquareBlack"] = {codepoint = 0xE0B9, description = "Square notehead black"},
        ["accidentalSharpSharp"] = {codepoint = 0xE269, description = "Sharp sharp"},
        ["figbass4"] = {codepoint = 0xEA55, description = "Figured bass 4"},
        ["dynamicRinforzando1"] = {codepoint = 0xE53C, description = "Rinforzando 1"},
        ["harpSalzedoSlideWithSuppleness"] = {codepoint = 0xE684, description = "Slide with suppleness (Salzedo)"},
        ["windTrillKey"] = {codepoint = 0xE5FA, description = "Trill key"},
        ["accSagittalSharp11v19MUp"] = {codepoint = 0xE3D2, description = "Sharp 11:19M-up"},
        ["pictWoundHardDown"] = {codepoint = 0xE7B4, description = "Wound beater, hard core down"},
        ["articLaissezVibrerAbove"] = {codepoint = 0xE4BA, description = "Laissez vibrer (l.v.) above"},
        ["accidentalJohnstonSeven"] = {codepoint = 0xE2B3, description = "Seven (lower by 36:35)"},
        ["functionGreaterThan"] = {codepoint = 0xEA7C, description = "Function theory greater than"},
        ["accidentalXenakisTwoThirdTonesSharp"] = {codepoint = 0xE471, description = "Two-third-tones sharp (Xenakis)"},
        ["organGermanCUpper"] = {codepoint = 0xEE00, description = "German organ tablature great C"},
        ["accSagittal5CommaDown"] = {codepoint = 0xE303, description = "5 comma down, 1° down [22 27 29 34 41 46 53 96 EDOs], 1/12-tone down"},
        ["accidentalThreeQuarterTonesSharpArrowDown"] = {codepoint = 0xE277, description = "Three-quarter-tones sharp"},
        ["mensuralCombStemUp"] = {codepoint = 0xE93E, description = "Combining stem up"},
        ["accSagittalFlat17CDown"] = {codepoint = 0xE357, description = "Flat 17C-down"},
        ["brassDoitLong"] = {codepoint = 0xE5D6, description = "Doit, long"},
        ["articAccentStaccatoBelow"] = {codepoint = 0xE4B1, description = "Accent-staccato below"},
        ["pictBeaterBrassMalletsUp"] = {codepoint = 0xE7D9, description = "Brass mallets up"},
        ["elecDataIn"] = {codepoint = 0xEB4D, description = "Data in"},
        ["ornamentOriscus"] = {codepoint = 0xEA21, description = "Oriscus"},
        ["elecDownload"] = {codepoint = 0xEB4F, description = "Download"},
        ["textBlackNoteFrac16thShortStem"] = {codepoint = 0xE1F4, description = "Black note, fractional 16th beam, short stem"},
        ["csymAccidentalDoubleSharp"] = {codepoint = 0xED63, description = "Double sharp"},
        ["dynamicFFFFF"] = {codepoint = 0xE532, description = "fffff"},
        ["wiggleWavyNarrow"] = {codepoint = 0xEAB4, description = "Narrow wavy line segment"},
        ["accdnRH3RanksTremoloUpper8ve"] = {codepoint = 0xE8B0, description = "Right hand, 3 ranks, 4' stop + lower tremolo 8' stop + upper tremolo 8' stop"},
        ["beamAccelRit3"] = {codepoint = 0xEAF6, description = "Accel./rit. beam 3"},
        ["figbassCombiningRaising"] = {codepoint = 0xEA6D, description = "Combining raise"},
        ["noteheadCircledDoubleWholeLarge"] = {codepoint = 0xE0EB, description = "Double whole notehead in large circle"},
        ["mensuralCombStemDownFlagLeft"] = {codepoint = 0xE944, description = "Combining stem with flag left down"},
        ["keyboardPedalDot"] = {codepoint = 0xE654, description = "Pedal dot"},
        ["ornamentPrecompCadenceUpperPrefix"] = {codepoint = 0xE5C1, description = "Cadence with upper prefix"},
        ["pictLotusFlute"] = {codepoint = 0xE75A, description = "Lotus flute"},
        ["noteRiHalf"] = {codepoint = 0xEEEA, description = "Ri (half note)"},
        ["mensuralObliqueAsc3rdBlack"] = {codepoint = 0xE974, description = "Oblique form, ascending 3rd, black"},
        ["accidentalArrowUp"] = {codepoint = 0xE27A, description = "Arrow up (raise by one quarter-tone)"},
        ["mensuralObliqueAsc5thVoid"] = {codepoint = 0xE97D, description = "Oblique form, ascending 5th, void"},
        ["handbellsDamp3"] = {codepoint = 0xE81E, description = "Damp 3"},
        ["elecProjector"] = {codepoint = 0xEB19, description = "Projector"},
        ["tripleTongueAbove"] = {codepoint = 0xE5F2, description = "Triple-tongue above"},
        ["noteReBlack"] = {codepoint = 0xE161, description = "Re (black note)"},
        ["luteItalianFret3"] = {codepoint = 0xEBE3, description = "Third fret (3)"},
        ["noteheadRectangularClusterWhiteBottom"] = {codepoint = 0xE147, description = "Combining white rectangular cluster, bottom"},
        ["accidentalSori"] = {codepoint = 0xE461, description = "Sori (quarter tone sharp)"},
        ["daseianGraves2"] = {codepoint = 0xEA31, description = "Daseian graves 2"},
        ["noteHSharpWhole"] = {codepoint = 0xE17E, description = "H sharp (whole note)"},
        ["kahnHeelClick"] = {codepoint = 0xEDBB, description = "Heel-click"},
        ["timeSigParensLeftSmall"] = {codepoint = 0xE092, description = "Left parenthesis for numerator only"},
        ["noteCSharpBlack"] = {codepoint = 0xE19E, description = "C sharp (black note)"},
        ["accSagittalDoubleFlat"] = {codepoint = 0xE335, description = "Double flat, (2 apotomes down)[almost all EDOs], whole-tone down"},
        ["luteItalianTempoNeitherFastNorSlow"] = {codepoint = 0xEBEC, description = "Neither fast nor slow tempo indication (de Mudarra)"},
        ["staff1Line"] = {codepoint = 0xE010, description = "1-line staff"},
        ["keyboardPedalHyphen"] = {codepoint = 0xE658, description = "Pedal hyphen"},
        ["accidentalOneQuarterToneFlatStockhausen"] = {codepoint = 0xED59, description = "One-quarter-tone flat (Stockhausen)"},
        ["fingeringLeftBracketItalic"] = {codepoint = 0xED8C, description = "Fingering left bracket italic"},
        ["luteDurationQuarter"] = {codepoint = 0xEBA9, description = "Quarter note (crotchet) duration sign"},
        ["articMarcatoBelow"] = {codepoint = 0xE4AD, description = "Marcato below"},
        ["accidentalKucukMucennebSharp"] = {codepoint = 0xE446, description = "Küçük mücenneb (sharp)"},
        ["noteheadCircledBlack"] = {codepoint = 0xE0E4, description = "Circled black notehead"},
        ["elecFastForward"] = {codepoint = 0xEB1F, description = "Fast-forward"},
        ["accidentalBuyukMucennebSharp"] = {codepoint = 0xE447, description = "Büyük mücenneb (sharp)"},
        ["kahnHeelStep"] = {codepoint = 0xEDC4, description = "Heel-step"},
        ["mensuralNoteheadLongaBlack"] = {codepoint = 0xE934, description = "Longa/brevis notehead, black"},
        ["accSagittalFlat7v11CDown"] = {codepoint = 0xE35B, description = "Flat 7:11C-down, 6° down [60 EDO], 3/5- tone down"},
        ["accidentalWyschnegradsky4TwelfthsSharp"] = {codepoint = 0xE423, description = "1/3 tone sharp"},
        ["chantPodatusLower"] = {codepoint = 0xE9B0, description = "Podatus, lower"},
        ["accidentalCombiningLower47Quartertone"] = {codepoint = 0xEE58, description = "Combining lower by one 47-limit quartertone"},
        ["noteHalfUp"] = {codepoint = 0xE1D3, description = "Half note (minim) stem up"},
        ["noteheadCowellFifthNoteSeriesWhole"] = {codepoint = 0xEEA4, description = "4/5 note (fifth note series, Cowell)"},
        ["pictTriangle"] = {codepoint = 0xE700, description = "Triangle"},
        ["windHalfClosedHole2"] = {codepoint = 0xE5F7, description = "Half-closed hole 2"},
        ["accSagittal5v23SmallDiesisDown"] = {codepoint = 0xE375, description = "5:23 small diesis down, 2° down [60 EDO], 1/5-tone down"},
        ["stringsOverpressureDownBow"] = {codepoint = 0xE61B, description = "Overpressure, down bow"},
        ["accSagittalFlat49MDown"] = {codepoint = 0xE3D5, description = "Flat 49M-down"},
        ["clef15"] = {codepoint = 0xE07E, description = "15 for clefs"},
        ["noteShapeMoonLeftDoubleWhole"] = {codepoint = 0xECDB, description = "Moon left double whole (Funk 7-shape do)"},
        ["articStaccatissimoAbove"] = {codepoint = 0xE4A6, description = "Staccatissimo above"},
        ["pictGumMediumDown"] = {codepoint = 0xE7C0, description = "Medium gum beater, down"},
        ["octaveSuperscriptV"] = {codepoint = 0xEC98, description = "v (superscript)"},
        ["noteheadClusterWhole3rd"] = {codepoint = 0xE129, description = "Whole note cluster, 3rd"},
        ["csymAccidentalFlat"] = {codepoint = 0xED60, description = "Flat"},
        ["dynamicSforzandoPianissimo"] = {codepoint = 0xE538, description = "Sforzando-pianissimo"},
        ["pictSnareDrum"] = {codepoint = 0xE6D1, description = "Snare drum"},
        ["textBlackNoteFrac32ndLongStem"] = {codepoint = 0xE1F6, description = "Black note, fractional 32nd beam, long stem"},
        ["guitarString4"] = {codepoint = 0xE837, description = "String number 4"},
        ["accdnRH4RanksSoftBass"] = {codepoint = 0xE8B8, description = "Right hand, 4 ranks, soft bass"},
        ["luteFingeringRHSecond"] = {codepoint = 0xEBAF, description = "Right-hand fingering, second finger"},
        ["organGermanSemifusa"] = {codepoint = 0xEE2B, description = "Semifusa"},
        ["analyticsInversion1"] = {codepoint = 0xE869, description = "Inversion 1"},
        ["noteheadDiamondClusterBlackTop"] = {codepoint = 0xE13F, description = "Combining black diamond cluster, top"},
        ["figbass3"] = {codepoint = 0xEA54, description = "Figured bass 3"},
        ["mensuralCombStemDownFlagExtended"] = {codepoint = 0xE948, description = "Combining stem with extended flag down"},
        ["stringsDownBowBeyondBridge"] = {codepoint = 0xEE84, description = "Down bow, beyond bridge"},
        ["accSagittal35LargeDiesisDown"] = {codepoint = 0xE30F, description = "35 large diesis down, 2° down [50 EDO], 5/18-tone down"},
        ["accSagittalFlat35MDown"] = {codepoint = 0xE325, description = "Flat 35M-down, 4° down [50 EDO], 6° down [27 EDO], 13/18-tone down"},
        ["stringsHalfHarmonic"] = {codepoint = 0xE615, description = "Half-harmonic"},
        ["pictSuspendedCymbal"] = {codepoint = 0xE721, description = "Suspended cymbal"},
        ["tremoloFingered3"] = {codepoint = 0xE227, description = "Fingered tremolo 3"},
        ["note16thDown"] = {codepoint = 0xE1DA, description = "16th note (semiquaver) stem down"},
        ["wiggleVibratoSmallFast"] = {codepoint = 0xEAD7, description = "Vibrato small, fast"},
        ["csymAccidentalNatural"] = {codepoint = 0xED61, description = "Natural"},
        ["wiggleCircularEnd"] = {codepoint = 0xEACB, description = "Circular motion end"},
        ["mensuralNoteheadMaximaBlack"] = {codepoint = 0xE930, description = "Maxima notehead, black"},
        ["pictBeaterBow"] = {codepoint = 0xE7DE, description = "Bow"},
        ["metricModulationArrowRight"] = {codepoint = 0xEC64, description = "Right-pointing arrow for metric modulation"},
        ["arrowheadOpenUp"] = {codepoint = 0xEB88, description = "Open arrowhead up (N)"},
        ["accSagittalDoubleFlat25SUp"] = {codepoint = 0xE32D, description = "Double flat 25S-up, 8°down [53 EDO]"},
        ["accidentalFilledReversedFlatArrowDown"] = {codepoint = 0xE293, description = "Filled reversed flat with arrow down"},
        ["pictBeaterMetalHammer"] = {codepoint = 0xE7E0, description = "Metal hammer"},
        ["smnHistoryFlat"] = {codepoint = 0xEC56, description = "Flat history sign"},
        ["medRenSharpCroix"] = {codepoint = 0xE9E3, description = "Croix"},
        ["noteASharpHalf"] = {codepoint = 0xE181, description = "A sharp (half note)"},
        ["pluckedLeftHandPizzicato"] = {codepoint = 0xE633, description = "Left-hand pizzicato"},
        ["timeSigCommon"] = {codepoint = 0xE08A, description = "Common time"},
        ["accSagittal5v19CommaDown"] = {codepoint = 0xE373, description = "5:19 comma down, 1/20-tone down"},
        ["note512thUp"] = {codepoint = 0xE1E3, description = "512th note (hemidemisemihemidemisemiquaver) stem up"},
        ["restQuarterOld"] = {codepoint = 0xE4F2, description = "Old-style quarter (crotchet) rest"},
        ["accSagittal35MediumDiesisDown"] = {codepoint = 0xE309, description = "35 medium diesis down, 1°[50] 2°[27] down, 2/9-tone down"},
        ["accSagittalSharp5v19CUp"] = {codepoint = 0xE37E, description = "Sharp 5:19C-up, 11/20-tone up"},
        ["chantLigaturaDesc5th"] = {codepoint = 0xE9BC, description = "Ligated stroke, descending 5th"},
        ["stringsUpBow"] = {codepoint = 0xE612, description = "Up bow"},
        ["accSagittalFlat55CUp"] = {codepoint = 0xE34F, description = "Flat 55C-up, 5° down [96 EDO], 5/16-tone down"},
        ["pictBeaterMediumTimpaniRight"] = {codepoint = 0xE78E, description = "Medium timpani stick right"},
        ["functionNUpper"] = {codepoint = 0xEA85, description = "Function theory N"},
        ["keyboardPedalHalf"] = {codepoint = 0xE656, description = "Half-pedal mark"},
        ["pictLeftHandCircle"] = {codepoint = 0xE807, description = "Right hand (Agostini)"},
        ["mensuralBlackSemiminima"] = {codepoint = 0xE955, description = "Black mensural semiminima"},
        ["noteheadDiamondClusterBlackBottom"] = {codepoint = 0xE141, description = "Combining black diamond cluster, bottom"},
        ["accdnCombDot"] = {codepoint = 0xE8CA, description = "Combining accordion coupler dot"},
        ["luteFrenchFretE"] = {codepoint = 0xEBC4, description = "Fourth fret (e)"},
        ["accidentalWilsonPlus"] = {codepoint = 0xE47B, description = "Wilson plus (5 comma up)"},
        ["fretboardO"] = {codepoint = 0xE85A, description = "Open string (O)"},
        ["organGermanSemibrevis"] = {codepoint = 0xEE27, description = "Semibrevis"},
        ["luteDurationWhole"] = {codepoint = 0xEBA7, description = "Whole note (semibreve) duration sign"},
        ["accidentalQuarterToneFlatFilledReversed"] = {codepoint = 0xE480, description = "Filled reversed flat (quarter-tone flat)"},
        ["keyboardPedalHeel1"] = {codepoint = 0xE661, description = "Pedal heel 1"},
        ["staffPosLower5"] = {codepoint = 0xEB9C, description = "Lower 5 staff positions"},
        ["note64thUp"] = {codepoint = 0xE1DD, description = "64th note (hemidemisemiquaver) stem up"},
        ["accidental1CommaFlat"] = {codepoint = 0xE454, description = "1-comma flat"},
        ["fingering2Italic"] = {codepoint = 0xED82, description = "Fingering 2 italic (index finger)"},
        ["guitarVolumeSwell"] = {codepoint = 0xE845, description = "Volume swell"},
        ["keyboardPedalUpSpecial"] = {codepoint = 0xE65D, description = "Pedal up special"},
        ["pictBeaterSoftXylophoneDown"] = {codepoint = 0xE771, description = "Soft xylophone stick down"},
        ["bracket"] = {codepoint = 0xE002, description = "Bracket"},
        ["timeSigFractionHalf"] = {codepoint = 0xE098, description = "Time signature fraction ½"},
        ["scaleDegree6"] = {codepoint = 0xEF05, description = "Scale degree 6"},
        ["luteItalianFret7"] = {codepoint = 0xEBE7, description = "Seventh fret (7)"},
        ["noteheadCowellFifteenthNoteSeriesBlack"] = {codepoint = 0xEEB5, description = "2/15 note (fifteenth note series, Cowell)"},
        ["kahnKneeInward"] = {codepoint = 0xEDAD, description = "Knee-inward"},
        ["barlineDotted"] = {codepoint = 0xE037, description = "Dotted barline"},
        ["ornamentPrecompAppoggTrillSuffix"] = {codepoint = 0xE5B3, description = "Supported appoggiatura trill with two-note suffix"},
        ["luteGermanOLower"] = {codepoint = 0xEC0D, description = "2nd course, 3rd fret (o)"},
        ["stringsScrapeParallelOutward"] = {codepoint = 0xEE87, description = "Scrape, parallel outward"},
        ["functionDLower"] = {codepoint = 0xEA80, description = "Function theory minor dominant"},
        ["accidentalQuarterToneFlatArrowUp"] = {codepoint = 0xE270, description = "Quarter-tone flat"},
        ["pictHandbell"] = {codepoint = 0xE715, description = "Handbell"},
        ["ornamentRightFacingHalfCircle"] = {codepoint = 0xE571, description = "Right-facing half circle"},
        ["noteTiWhole"] = {codepoint = 0xE156, description = "Ti (whole note)"},
        ["elecUpload"] = {codepoint = 0xEB50, description = "Upload"},
        ["cClefChange"] = {codepoint = 0xE07B, description = "C clef change"},
        ["staff5LinesNarrow"] = {codepoint = 0xE020, description = "5-line staff (narrow)"},
        ["accidentalQuarterFlatEqualTempered"] = {codepoint = 0xE2F5, description = "Lower by one equal tempered quarter-tone"},
        ["fClefChange"] = {codepoint = 0xE07C, description = "F clef change"},
        ["noteheadHalf"] = {codepoint = 0xE0A3, description = "Half (minim) notehead"},
        ["luteFrenchFretI"] = {codepoint = 0xEBC8, description = "Eighth fret (i)"},
        ["elecEject"] = {codepoint = 0xEB2B, description = "Eject"},
        ["kahnBackRiff"] = {codepoint = 0xEDE1, description = "Back-riff"},
        ["noteheadTriangleDownWhole"] = {codepoint = 0xE0C4, description = "Triangle notehead down whole"},
        ["accSagittal1MinaUp"] = {codepoint = 0xE3F4, description = "1 mina up, 1/(5⋅7⋅13)-schismina up, 0.42 cents up"},
        ["accSagittalSharp7v19CUp"] = {codepoint = 0xE3CA, description = "Sharp 7:19C-up"},
        ["csymAugmented"] = {codepoint = 0xE872, description = "Augmented"},
        ["noteheadClusterHalf3rd"] = {codepoint = 0xE12A, description = "Half note cluster, 3rd"},
        ["accidentalWyschnegradsky9TwelfthsFlat"] = {codepoint = 0xE433, description = "3/4 tone flat"},
        ["brassMuteOpen"] = {codepoint = 0xE5E7, description = "Open"},
        ["mensuralModusImperfectumVert"] = {codepoint = 0xE92D, description = "Modus imperfectum, vertical"},
        ["luteItalianFret8"] = {codepoint = 0xEBE8, description = "Eighth fret (8)"},
        ["restQuarter"] = {codepoint = 0xE4E5, description = "Quarter (crotchet) rest"},
        ["accidentalNaturalReversed"] = {codepoint = 0xE482, description = "Reversed natural"},
        ["dynamicDiminuendoHairpin"] = {codepoint = 0xE53F, description = "Diminuendo"},
        ["reversedBracketTop"] = {codepoint = 0xE005, description = "Reversed bracket top"},
        ["wiggleCircularLarger"] = {codepoint = 0xEAC7, description = "Circular motion segment, larger"},
        ["wiggleSawtoothNarrow"] = {codepoint = 0xEABA, description = "Narrow sawtooth line segment"},
        ["ornamentPrecompInvertedMordentUpperPrefix"] = {codepoint = 0xE5C7, description = "Inverted mordent with upper prefix"},
        ["pictBeaterCombiningParentheses"] = {codepoint = 0xE7E9, description = "Combining parentheses for round beaters (padded)"},
        ["noteheadLargeArrowDownHalf"] = {codepoint = 0xE0F3, description = "Large arrow down (lowest pitch) half notehead"},
        ["organGermanSemibrevisRest"] = {codepoint = 0xEE1F, description = "Semibrevis Rest"},
        ["noteLeBlack"] = {codepoint = 0xEEF9, description = "Le (black note)"},
        ["handbellsMalletLft"] = {codepoint = 0xE816, description = "Mallet lift"},
        ["restWholeLegerLine"] = {codepoint = 0xE4F4, description = "Whole rest on leger line"},
        ["barlineSingle"] = {codepoint = 0xE030, description = "Single barline"},
        ["arrowOpenLeft"] = {codepoint = 0xEB76, description = "Open arrow left (W)"},
        ["functionDD"] = {codepoint = 0xEA81, description = "Function theory dominant of dominant"},
        ["luteGermanSLower"] = {codepoint = 0xEC11, description = "3rd course, 4th fret (s)"},
        ["organGermanAugmentationDot"] = {codepoint = 0xEE1C, description = "Rhythm Dot"},
        ["mensuralBlackSemibrevis"] = {codepoint = 0xE953, description = "Black mensural semibrevis"},
        ["articMarcatoAbove"] = {codepoint = 0xE4AC, description = "Marcato above"},
        ["accSagittalDoubleFlat5v11SUp"] = {codepoint = 0xE35F, description = "Double flat 5:11S-up"},
        ["pictCowBell"] = {codepoint = 0xE711, description = "Cow bell"},
        ["kievanNoteQuarterStemDown"] = {codepoint = 0xEC38, description = "Kievan quarter note, stem down"},
        ["kodalyHandRe"] = {codepoint = 0xEC41, description = "Re hand sign"},
        ["keyboardBebung3DotsAbove"] = {codepoint = 0xE66A, description = "Clavichord bebung, 3 finger movements (above)"},
        ["accSagittal23CommaDown"] = {codepoint = 0xE371, description = "23 comma down, 2° down [96 EDO], 1/8-tone down"},
        ["noteShapeRoundDoubleWhole"] = {codepoint = 0xECD0, description = "Round double whole (4-shape sol; 7-shape so)"},
        ["smnFlat"] = {codepoint = 0xEC52, description = "Flat"},
        ["noteShapeMoonWhite"] = {codepoint = 0xE1BC, description = "Moon white (Aikin 7-shape re)"},
        ["metNote1024thDown"] = {codepoint = 0xECB6, description = "1024th note (semihemidemisemihemidemisemiquaver) stem down"},
        ["accidental3CommaFlat"] = {codepoint = 0xE456, description = "3-comma flat"},
        ["noteGSharpBlack"] = {codepoint = 0xE1AA, description = "G sharp (black note)"},
        ["kievanNoteHalfStaffLine"] = {codepoint = 0xEC35, description = "Kievan half note (on staff line)"},
        ["pluckedDampOnStem"] = {codepoint = 0xE63B, description = "Damp for stem"},
        ["accidentalSharpOneArrowUp"] = {codepoint = 0xE2C8, description = "Sharp raised by one syntonic comma"},
        ["noteheadCowellSeventhNoteSeriesHalf"] = {codepoint = 0xEEA8, description = "2/7 note (seventh note series, Cowell)"},
        ["accidentalThreeQuarterTonesFlatArrowDown"] = {codepoint = 0xE271, description = "Three-quarter-tones flat"},
        ["mensuralObliqueDesc2ndBlack"] = {codepoint = 0xE980, description = "Oblique form, descending 2nd, black"},
        ["pictTamTam"] = {codepoint = 0xE730, description = "Tam-tam"},
        ["accidentalLargeDoubleSharp"] = {codepoint = 0xE47D, description = "Large double sharp"},
        ["chantQuilisma"] = {codepoint = 0xE99B, description = "Quilisma"},
        ["articLaissezVibrerBelow"] = {codepoint = 0xE4BB, description = "Laissez vibrer (l.v.) below"},
        ["ornamentPrecompTrillLowerSuffix"] = {codepoint = 0xE5C8, description = "Trill with lower suffix"},
        ["windSharpEmbouchure"] = {codepoint = 0xE5FC, description = "Sharper embouchure"},
        ["noteheadCircleXDoubleWhole"] = {codepoint = 0xE0B0, description = "Circle X double whole"},
        ["functionILower"] = {codepoint = 0xEA9B, description = "Function theory i"},
        ["mensuralProportion9"] = {codepoint = 0xEE94, description = "Mensural proportion 9"},
        ["staffPosRaise3"] = {codepoint = 0xEB92, description = "Raise 3 staff positions"},
        ["accSagittalDoubleSharp7CDown"] = {codepoint = 0xE32E, description = "Double sharp 7C-down, 5°[43] 10°[72] up, 5/6-tone up"},
        ["luteGermanXLower"] = {codepoint = 0xEC14, description = "5th course, 5th fret (x)"},
        ["noteheadParenthesisLeft"] = {codepoint = 0xE0F5, description = "Opening parenthesis"},
        ["noteheadBlack"] = {codepoint = 0xE0A4, description = "Black notehead"},
        ["functionIUpper"] = {codepoint = 0xEA9A, description = "Function theory I"},
        ["daseianFinales3"] = {codepoint = 0xEA36, description = "Daseian finales 3"},
        ["ornamentBottomRightConvexStroke"] = {codepoint = 0xE5A8, description = "Ornament bottom right convex stroke"},
        ["kahnFlam"] = {codepoint = 0xEDCF, description = "Flam"},
        ["schaefferClef"] = {codepoint = 0xE06F, description = "Schäffer clef"},
        ["medRenNaturalWithCross"] = {codepoint = 0xE9E5, description = "Natural with interrupted cross"},
        ["fingering3"] = {codepoint = 0xED13, description = "Fingering 3 (middle finger)"},
        ["elecVolumeLevel40"] = {codepoint = 0xEB30, description = "Volume level 40%"},
        ["noteheadWhole"] = {codepoint = 0xE0A2, description = "Whole (semibreve) notehead"},
        ["luteFrench9thCourse"] = {codepoint = 0xEBCF, description = "Ninth course (diapason)"},
        ["accdnRH3RanksTremoloLower8ve"] = {codepoint = 0xE8AF, description = "Right hand, 3 ranks, lower tremolo 8' stop + upper tremolo 8' stop + 16' stop"},
        ["metNoteHalfDown"] = {codepoint = 0xECA4, description = "Half note (minim) stem down"},
        ["brassLiftLong"] = {codepoint = 0xE5D3, description = "Lift, long"},
        ["kahnBackFlap"] = {codepoint = 0xEDD8, description = "Back-flap"},
        ["mensuralObliqueDesc5thBlackVoid"] = {codepoint = 0xE98E, description = "Oblique form, descending 5th, black and void"},
        ["accidentalCombiningLower19Schisma"] = {codepoint = 0xE2E8, description = "Combining lower by one 19-limit schisma"},
        ["noteheadCowellThirdNoteSeriesHalf"] = {codepoint = 0xEEA2, description = "1/3 note (third note series, Cowell)"},
        ["fingering5"] = {codepoint = 0xED15, description = "Fingering 5 (little finger)"},
        ["noteheadTriangleDownBlack"] = {codepoint = 0xE0C7, description = "Triangle notehead down black"},
        ["fingeringTLower"] = {codepoint = 0xED18, description = "Fingering t (right-hand thumb for guitar)"},
        ["ornamentVerticalLine"] = {codepoint = 0xE583, description = "Vertical line"},
        ["swissRudimentsNoteheadBlackFlam"] = {codepoint = 0xEE70, description = "Swiss rudiments flam black notehead"},
        ["noteShapeTriangleLeftDoubleWhole"] = {codepoint = 0xECD3, description = "Triangle left double whole (stem up; 4-shape fa; 7-shape fa)"},
        ["noteheadTriangleLeftBlack"] = {codepoint = 0xE0C0, description = "Triangle notehead left black"},
        ["pictLionsRoar"] = {codepoint = 0xE763, description = "Lion's roar"},
        ["accSagittalSharp7v11CDown"] = {codepoint = 0xE34C, description = "Sharp 7:11C-down, 4° up [60 EDO], 2/5-tone up"},
        ["brassFallSmoothMedium"] = {codepoint = 0xE5DB, description = "Smooth fall, medium"},
        ["accidentalWyschnegradsky7TwelfthsSharp"] = {codepoint = 0xE426, description = "7/12 tone sharp"},
        ["accidentalSharpRepeatedSpaceStockhausen"] = {codepoint = 0xED5D, description = "Repeated sharp, note in space (Stockhausen)"},
        ["pictSwishStem"] = {codepoint = 0xE808, description = "Combining swish for stem"},
        ["pictSlitDrum"] = {codepoint = 0xE6E0, description = "Slit drum"},
        ["stemSwished"] = {codepoint = 0xE212, description = "Combining swished stem"},
        ["metNote128thDown"] = {codepoint = 0xECB0, description = "128th note (semihemidemisemiquaver) stem down"},
        ["daseianExcellentes3"] = {codepoint = 0xEA3E, description = "Daseian excellentes 3"},
        ["luteItalianHoldFinger"] = {codepoint = 0xEBF4, description = "Hold finger in place"},
        ["mensuralProlationCombiningStroke"] = {codepoint = 0xE925, description = "Combining vertical stroke"},
        ["pictGlassHarp"] = {codepoint = 0xE764, description = "Glass harp"},
        ["accidentalDoubleFlatTwoArrowsUp"] = {codepoint = 0xE2CF, description = "Double flat raised by two syntonic commas"},
        ["tremoloDivisiDots2"] = {codepoint = 0xE22E, description = "Divide measured tremolo by 2"},
        ["windMultiphonicsWhiteStem"] = {codepoint = 0xE608, description = "Combining multiphonics (white) for stem"},
        ["restDoubleWhole"] = {codepoint = 0xE4E2, description = "Double whole (breve) rest"},
        ["accSagittal17CommaDown"] = {codepoint = 0xE343, description = "17 comma down"},
        ["noteReHalf"] = {codepoint = 0xE159, description = "Re (half note)"},
        ["noteheadClusterSquareWhite"] = {codepoint = 0xE120, description = "Cluster notehead white (square)"},
        ["elecMIDIController20"] = {codepoint = 0xEB37, description = "MIDI controller 20%"},
        ["noteheadRectangularClusterWhiteMiddle"] = {codepoint = 0xE146, description = "Combining white rectangular cluster, middle"},
        ["metNote128thUp"] = {codepoint = 0xECAF, description = "128th note (semihemidemisemiquaver) stem up"},
        ["accSagittalDoubleSharp5v11SDown"] = {codepoint = 0xE35E, description = "Double sharp 5:11S-down"},
        ["dynamicSforzando1"] = {codepoint = 0xE536, description = "Sforzando 1"},
        ["wiggleVibratoLargeSlower"] = {codepoint = 0xEAE7, description = "Vibrato large, slower"},
        ["luteItalianFret0"] = {codepoint = 0xEBE0, description = "Open string (0)"},
        ["noteheadClusterRoundBlack"] = {codepoint = 0xE123, description = "Cluster notehead black (round)"},
        ["daCapo"] = {codepoint = 0xE046, description = "Da capo"},
        ["guitarOpenPedal"] = {codepoint = 0xE83D, description = "Open wah/volume pedal"},
        ["elecMicrophone"] = {codepoint = 0xEB10, description = "Microphone"},
        ["chantStrophicusLiquescens3rd"] = {codepoint = 0xE9C3, description = "Strophicus liquescens, 3rd"},
        ["luteFrenchMordentUpper"] = {codepoint = 0xEBD1, description = "Mordent with upper auxiliary"},
        ["noteheadDiamondHalfOld"] = {codepoint = 0xE0E1, description = "Diamond half notehead (old)"},
        ["noteShapeTriangleRightBlack"] = {codepoint = 0xE1B5, description = "Triangle right black (stem down; 4-shape fa; 7-shape fa)"},
        ["controlEndBeam"] = {codepoint = 0xE8E1, description = "End beam"},
        ["textHeadlessBlackNoteLongStem"] = {codepoint = 0xE205, description = "Headless black note, long stem"},
        ["accSagittal23SmallDiesisUp"] = {codepoint = 0xE39E, description = "23 small diesis up, (23S)"},
        ["noteCSharpHalf"] = {codepoint = 0xE187, description = "C sharp (half note)"},
        ["noteHSharpBlack"] = {codepoint = 0xE1AC, description = "H sharp (black note)"},
        ["functionSSUpper"] = {codepoint = 0xEA7D, description = "Function theory major subdominant of subdominant"},
        ["luteFingeringRHFirst"] = {codepoint = 0xEBAE, description = "Right-hand fingering, first finger"},
        ["stringsThumbPosition"] = {codepoint = 0xE624, description = "Thumb position"},
        ["accSagittalFlat7CDown"] = {codepoint = 0xE321, description = "Flat 7C-down, 4° down [43 EDO], 8° down [72 EDO], 2/3-tone down"},
        ["pictTurnLeftStem"] = {codepoint = 0xE80A, description = "Combining turn left for stem"},
        ["noteShapeArrowheadLeftDoubleWhole"] = {codepoint = 0xECDC, description = "Arrowhead left double whole (Funk 7-shape re)"},
        ["repeatBarSlash"] = {codepoint = 0xE504, description = "Repeat bar slash"},
        ["conductorBeat2Compound"] = {codepoint = 0xE897, description = "Beat 2, compound time"},
        ["pictQuijada"] = {codepoint = 0xE6FA, description = "Quijada (jawbone)"},
        ["accidentalJohnstonDown"] = {codepoint = 0xE2B5, description = "Down arrow (lower by 33:32)"},
        ["mensuralCustosTurn"] = {codepoint = 0xEA0B, description = "Turn-like custos"},
        ["pictTomTomIndoAmerican"] = {codepoint = 0xE6DA, description = "Indo-American tom tom"},
        ["gClefReversed"] = {codepoint = 0xE073, description = "Reversed G clef"},
        ["fClefReversed"] = {codepoint = 0xE076, description = "Reversed F clef"},
        ["mensuralObliqueDesc5thVoid"] = {codepoint = 0xE98D, description = "Oblique form, descending 5th, void"},
        ["mensuralBlackLonga"] = {codepoint = 0xE951, description = "Black mensural longa"},
        ["stringsDownBowAwayFromBody"] = {codepoint = 0xEE82, description = "Down bow, away from body"},
        ["metNote512thDown"] = {codepoint = 0xECB4, description = "512th note (hemidemisemihemidemisemiquaver) stem down"},
        ["accSagittalFlat25SUp"] = {codepoint = 0xE311, description = "Flat 25S-up, 3° down [53 EDO]"},
        ["wiggleVibratoSmallestFastest"] = {codepoint = 0xEACD, description = "Vibrato smallest, fastest"},
        ["accdnRH3RanksMaster"] = {codepoint = 0xE8AD, description = "Right hand, 3 ranks, 4' stop + lower tremolo 8' stop + upper tremolo 8' stop + 16' stop (master)"},
        ["chantIctusBelow"] = {codepoint = 0xE9D1, description = "Ictus below"},
        ["bracketTop"] = {codepoint = 0xE003, description = "Bracket top"},
        ["daseianExcellentes1"] = {codepoint = 0xEA3C, description = "Daseian excellentes 1"},
        ["accSagittalSharp25SUp"] = {codepoint = 0xE322, description = "Sharp 25S-up, 7° up [53 EDO]"},
        ["functionTwo"] = {codepoint = 0xEA72, description = "Function theory 2"},
        ["ornamentBottomLeftConcaveStroke"] = {codepoint = 0xE59A, description = "Ornament bottom left concave stroke"},
        ["functionLessThan"] = {codepoint = 0xEA7A, description = "Function theory less than"},
        ["cClefReversed"] = {codepoint = 0xE075, description = "Reversed C clef"},
        ["fingering8Italic"] = {codepoint = 0xED88, description = "Fingering 8 italic"},
        ["luteGermanFUpper"] = {codepoint = 0xEC1C, description = "6th course, 6th fret (F)"},
        ["pictOpen"] = {codepoint = 0xE7F8, description = "Open"},
        ["arrowheadOpenDown"] = {codepoint = 0xEB8C, description = "Open arrowhead down (S)"},
        ["functionRepetition2"] = {codepoint = 0xEA96, description = "Function theory repetition 2"},
        ["keyboardPedalParensLeft"] = {codepoint = 0xE676, description = "Left parenthesis for pedal marking"},
        ["glissandoDown"] = {codepoint = 0xE586, description = "Glissando down"},
        ["figbassBracketRight"] = {codepoint = 0xEA69, description = "Figured bass ]"},
        ["keyboardPlayWithRH"] = {codepoint = 0xE66E, description = "Play with right hand"},
        ["noteheadSlashedBlack2"] = {codepoint = 0xE0D0, description = "Slashed black notehead (top left to bottom right)"},
        ["pictBeaterFingernails"] = {codepoint = 0xE7E6, description = "Fingernails"},
        ["noteheadClusterDoubleWholeTop"] = {codepoint = 0xE12C, description = "Combining double whole note cluster, top"},
        ["accSagittalSharp143CUp"] = {codepoint = 0xE3C4, description = "Sharp 143C-up"},
        ["noteShapeIsoscelesTriangleBlack"] = {codepoint = 0xE1C5, description = "Isosceles triangle black (Walker 7-shape ti)"},
        ["elecMIDIController80"] = {codepoint = 0xEB3A, description = "MIDI controller 80%"},
        ["accSagittalDoubleFlat49SUp"] = {codepoint = 0xE3E3, description = "Double flat 49S-up"},
        ["noteheadRectangularClusterBlackBottom"] = {codepoint = 0xE144, description = "Combining black rectangular cluster, bottom"},
        ["mensuralProlation4"] = {codepoint = 0xE913, description = "Tempus perfectum cum prolatione perfecta diminution 2 (9/16)"},
        ["mensuralProlation5"] = {codepoint = 0xE914, description = "Tempus imperfectum cum prolatione perfecta (6/8)"},
        ["mensuralNoteheadMaximaVoid"] = {codepoint = 0xE931, description = "Maxima notehead, void"},
        ["noteheadCowellSeventhNoteSeriesWhole"] = {codepoint = 0xEEA7, description = "4/7 note (seventh note series, Cowell)"},
        ["rest64th"] = {codepoint = 0xE4E9, description = "64th (hemidemisemiquaver) rest"},
        ["accSagittalDoubleFlat17kUp"] = {codepoint = 0xE3ED, description = "Double flat 17k-up"},
        ["accidentalLowerOneTridecimalQuartertone"] = {codepoint = 0xE2E4, description = "Lower by one tridecimal quartertone"},
        ["fretboard6StringNut"] = {codepoint = 0xE857, description = "6-string fretboard at nut"},
        ["figbass7Diminished"] = {codepoint = 0xECC0, description = "Figured bass 7 diminished"},
        ["accSagittalFlat"] = {codepoint = 0xE319, description = "Flat, (apotome down)[almost all EDOs], 1/2-tone down"},
        ["accSagittal3TinasDown"] = {codepoint = 0xE3FD, description = "3 tinas down, 1 mina down, 1/(5⋅7⋅13)-schismina down, 0.42 cents down"},
        ["luteGermanHUpper"] = {codepoint = 0xEC1E, description = "6th course, 8th fret (H)"},
        ["noteheadXOrnate"] = {codepoint = 0xE0AA, description = "Ornate X notehead"},
        ["guitarVibratoBarScoop"] = {codepoint = 0xE830, description = "Guitar vibrato bar scoop"},
        ["noteSiBlack"] = {codepoint = 0xE167, description = "Si (black note)"},
        ["doubleTongueAbove"] = {codepoint = 0xE5F0, description = "Double-tongue above"},
        ["metNoteQuarterUp"] = {codepoint = 0xECA5, description = "Quarter note (crotchet) stem up"},
        ["flag32ndUp"] = {codepoint = 0xE244, description = "Combining flag 3 (32nd) above"},
        ["arpeggiatoUp"] = {codepoint = 0xE634, description = "Arpeggiato up"},
        ["noteShapeArrowheadLeftWhite"] = {codepoint = 0xE1C8, description = "Arrowhead left white (Funk 7-shape re)"},
        ["handbellsSwingDown"] = {codepoint = 0xE819, description = "Swing down"},
        ["timeSig3Turned"] = {codepoint = 0xECE3, description = "Turned time signature 3"},
        ["kahnRightCross"] = {codepoint = 0xEDBE, description = "Right-cross"},
        ["brassDoitShort"] = {codepoint = 0xE5D4, description = "Doit, short"},
        ["noteMiWhole"] = {codepoint = 0xE152, description = "Mi (whole note)"},
        ["noteheadCircleXHalf"] = {codepoint = 0xE0B2, description = "Circle X half"},
        ["mensuralProportion5"] = {codepoint = 0xEE90, description = "Mensural proportion 5"},
        ["mensuralTempusPerfectumHoriz"] = {codepoint = 0xE92E, description = "Tempus perfectum, horizontal"},
        ["luteItalianTempoVerySlow"] = {codepoint = 0xEBEE, description = "Very slow indication (de Narvaez)"},
        ["functionSLower"] = {codepoint = 0xEA8A, description = "Function theory minor subdominant"},
        ["accSagittalDoubleSharp5v23SDown"] = {codepoint = 0xE382, description = "Double sharp 5:23S-down, 8° up [60 EDO], 4/5-tone up"},
        ["fingeringTUpper"] = {codepoint = 0xED16, description = "Fingering T (left-hand thumb for guitar)"},
        ["noteShapeTriangleRoundDoubleWhole"] = {codepoint = 0xECD7, description = "Triangle-round white (Aikin 7-shape ti)"},
        ["organGermanOctaveDown"] = {codepoint = 0xEE1A, description = "Combining single octave line below"},
        ["accdnLH3Ranks2Square"] = {codepoint = 0xE8C2, description = "Left hand, 3 ranks, 2' stop (square)"},
        ["accSagittalSharp17CUp"] = {codepoint = 0xE356, description = "Sharp 17C-up"},
        ["wiggleCircularConstantLarge"] = {codepoint = 0xEAC2, description = "Constant circular motion segment (large)"},
        ["accSagittalDoubleSharp5v7kDown"] = {codepoint = 0xE332, description = "Double sharp 5:7k-down"},
        ["pictLogDrum"] = {codepoint = 0xE6DF, description = "Log drum"},
        ["windLessRelaxedEmbouchure"] = {codepoint = 0xE5FE, description = "Somewhat relaxed embouchure"},
        ["functionSSLower"] = {codepoint = 0xEA7E, description = "Function theory minor subdominant of subdominant"},
        ["luteGermanKUpper"] = {codepoint = 0xEC20, description = "6th course, 10th fret (K)"},
        ["functionBracketLeft"] = {codepoint = 0xEA8F, description = "Function theory bracket left"},
        ["fermataAbove"] = {codepoint = 0xE4C0, description = "Fermata above"},
        ["harpSalzedoTimpanicSounds"] = {codepoint = 0xE68B, description = "Timpanic sounds (Salzedo)"},
        ["mensuralProlation6"] = {codepoint = 0xE915, description = "Tempus imperfectum cum prolatione imperfecta (2/4)"},
        ["rest16th"] = {codepoint = 0xE4E7, description = "16th (semiquaver) rest"},
        ["fingering4Italic"] = {codepoint = 0xED84, description = "Fingering 4 italic (ring finger)"},
        ["figbass6Raised"] = {codepoint = 0xEA5C, description = "Figured bass 6 raised by half-step"},
        ["organGermanMinima"] = {codepoint = 0xEE28, description = "Minima"},
        ["luteFrenchMordentInverted"] = {codepoint = 0xEBD3, description = "Inverted mordent"},
        ["luteFrench7thCourse"] = {codepoint = 0xEBCD, description = "Seventh course (diapason)"},
        ["noteheadTriangleUpRightWhite"] = {codepoint = 0xE0C8, description = "Triangle notehead up right white"},
        ["pictBeaterWireBrushesDown"] = {codepoint = 0xE7D8, description = "Wire brushes down"},
        ["kahnBackRip"] = {codepoint = 0xEDDA, description = "Back-rip"},
        ["conductorBeat2Simple"] = {codepoint = 0xE894, description = "Beat 2, simple time"},
        ["textTupletBracketStartLongStem"] = {codepoint = 0xE201, description = "Tuplet bracket start for long stem"},
        ["noteheadXDoubleWhole"] = {codepoint = 0xE0A6, description = "X notehead double whole"},
        ["organGerman4Minimae"] = {codepoint = 0xEE34, description = "Four Minimae"},
        ["luteGermanLUpper"] = {codepoint = 0xEC21, description = "6th course, 11th fret (L)"},
        ["noteEmptyHalf"] = {codepoint = 0xE1AE, description = "Empty half note"},
        ["dynamicSforzatoPiano"] = {codepoint = 0xE53A, description = "Sforzato-piano"},
        ["noteheadDiamondClusterWhiteBottom"] = {codepoint = 0xE13E, description = "Combining white diamond cluster, bottom"},
        ["fermataLongHenzeAbove"] = {codepoint = 0xE4CA, description = "Long fermata (Henze) above"},
        ["organGermanDisLower"] = {codepoint = 0xEE0F, description = "German organ tablature small Dis"},
        ["accSagittalFlat25SDown"] = {codepoint = 0xE323, description = "Flat 25S-down, 7° down [53 EDO]"},
        ["noteheadRoundWhiteLarge"] = {codepoint = 0xE111, description = "Large round white notehead"},
        ["accSagittalSharp35MUp"] = {codepoint = 0xE324, description = "Sharp 35M-up, 4° up [50 EDO], 6° up [27 EDO], 13/18-tone up"},
        ["chantCirculusAbove"] = {codepoint = 0xE9D2, description = "Circulus above"},
        ["conductorBeat4Compound"] = {codepoint = 0xE899, description = "Beat 4, compound time"},
        ["elecAudioChannelsOne"] = {codepoint = 0xEB3E, description = "One channel (mono)"},
        ["accidentalFilledReversedFlatAndFlat"] = {codepoint = 0xE296, description = "Filled reversed flat and flat"},
        ["kahnRip"] = {codepoint = 0xEDD6, description = "Rip"},
        ["accSagittal17CommaUp"] = {codepoint = 0xE342, description = "17 comma up, (17C)"},
        ["noteheadCowellNinthNoteSeriesBlack"] = {codepoint = 0xEEAC, description = "2/9 note (ninth note series, Cowell)"},
        ["ornamentPrecompDescendingSlide"] = {codepoint = 0xE5B1, description = "Descending slide"},
        ["accidentalDoubleFlatTwoArrowsDown"] = {codepoint = 0xE2CA, description = "Double flat lowered by two syntonic commas"},
        ["accidentalJohnston13"] = {codepoint = 0xE2B6, description = "Thirteen (raise by 65:64)"},
        ["textCont8thBeamLongStem"] = {codepoint = 0xE1F8, description = "Continuing 8th beam for long stem"},
        ["accSagittalFlat5v19CDown"] = {codepoint = 0xE37F, description = "Flat 5:19C-down, 11/20-tone down"},
        ["noteFaHalf"] = {codepoint = 0xE15B, description = "Fa (half note)"},
        ["keyboardPedalP"] = {codepoint = 0xE651, description = "Pedal P"},
        ["medRenFlatSoftB"] = {codepoint = 0xE9E0, description = "Flat, soft b (fa)"},
        ["functionParensLeft"] = {codepoint = 0xEA91, description = "Function theory parenthesis left"},
        ["accSagittalSharp5CUp"] = {codepoint = 0xE31E, description = "Sharp 5C-up, 4°[22 29] 5°[27 34 41] 6°[39 46 53] up, 7/12-tone up"},
        ["accSagittalDoubleFlat19CUp"] = {codepoint = 0xE3E7, description = "Double flat 19C-up"},
        ["luteFrenchFretL"] = {codepoint = 0xEBCA, description = "10th fret (l)"},
        ["keyboardBebung3DotsBelow"] = {codepoint = 0xE66B, description = "Clavichord bebung, 3 finger movements (below)"},
        ["medRenFlatHardB"] = {codepoint = 0xE9E1, description = "Flat, hard b (mi)"},
        ["arrowBlackDown"] = {codepoint = 0xEB64, description = "Black arrow down (S)"},
        ["accdnCombLH3RanksEmptySquare"] = {codepoint = 0xE8C9, description = "Combining left hand, 3 ranks, empty (square)"},
        ["elecMute"] = {codepoint = 0xEB26, description = "Mute"},
        ["accSagittal1TinaUp"] = {codepoint = 0xE3F8, description = "1 tina up, 7²⋅11⋅19/5-schismina up, 0.17 cents up"},
        ["restHBarRight"] = {codepoint = 0xE4F1, description = "H-bar, right half"},
        ["accidental3CommaSharp"] = {codepoint = 0xE452, description = "3-comma sharp"},
        ["mensuralProportion3"] = {codepoint = 0xE928, description = "Mensural proportion 3"},
        ["accSagittal5CommaUp"] = {codepoint = 0xE302, description = "5 comma up, (5C), 1° up [22 27 29 34 41 46 53 96 EDOs], 1/12-tone up"},
        ["pluckedDampAll"] = {codepoint = 0xE639, description = "Damp all"},
        ["pictBeaterSoftXylophoneLeft"] = {codepoint = 0xE773, description = "Soft xylophone stick left"},
        ["accSagittalFlat143CUp"] = {codepoint = 0xE3BB, description = "Flat 143C-up"},
        ["accidentalBakiyeFlat"] = {codepoint = 0xE442, description = "Bakiye (flat)"},
        ["pictSnareDrumMilitary"] = {codepoint = 0xE6D3, description = "Military snare drum"},
        ["conductorRightBeat"] = {codepoint = 0xE892, description = "Right-hand beat or cue"},
        ["accidentalFlatOneArrowUp"] = {codepoint = 0xE2C6, description = "Flat raised by one syntonic comma"},
        ["tuplet9"] = {codepoint = 0xE889, description = "Tuplet 9"},
        ["accidentalCombiningRaise53LimitComma"] = {codepoint = 0xE2F8, description = "Combining raise by one 53-limit comma"},
        ["ornamentObliqueLineHorizBeforeNote"] = {codepoint = 0xE57F, description = "Oblique straight line tilted SW-NE"},
        ["noteTiHalf"] = {codepoint = 0xE15E, description = "Ti (half note)"},
        ["fermataLongBelow"] = {codepoint = 0xE4C7, description = "Long fermata below"},
        ["kodalyHandSo"] = {codepoint = 0xEC44, description = "So hand sign"},
        ["mensuralObliqueDesc4thWhite"] = {codepoint = 0xE98B, description = "Oblique form, descending 4th, white"},
        ["kahnFlapStep"] = {codepoint = 0xEDD7, description = "Flap-step"},
        ["elecHeadset"] = {codepoint = 0xEB12, description = "Headset"},
        ["luteFrenchFretH"] = {codepoint = 0xEBC7, description = "Seventh fret (h)"},
        ["pictBeaterHammerWoodDown"] = {codepoint = 0xE7CC, description = "Wooden hammer, down"},
        ["accidentalWilsonMinus"] = {codepoint = 0xE47C, description = "Wilson minus (5 comma down)"},
        ["noteShapeTriangleLeftWhite"] = {codepoint = 0xE1B6, description = "Triangle left white (stem up; 4-shape fa; 7-shape fa)"},
        ["accidentalParensLeft"] = {codepoint = 0xE26A, description = "Accidental parenthesis, left"},
        ["accSagittalSharp17CDown"] = {codepoint = 0xE350, description = "Sharp 17C-down"},
        ["arrowBlackRight"] = {codepoint = 0xEB62, description = "Black arrow right (E)"},
        ["accSagittalSharp5v13LUp"] = {codepoint = 0xE3DC, description = "Sharp 5:13L-up"},
        ["luteFrenchFretG"] = {codepoint = 0xEBC6, description = "Sixth fret (g)"},
        ["noteShapeTriangleRoundWhite"] = {codepoint = 0xE1BE, description = "Triangle-round white (Aikin 7-shape ti)"},
        ["accSagittalDoubleFlat5CUp"] = {codepoint = 0xE331, description = "Double flat 5C-up, 5°[22 29] 7°[34 41] 9°53 down, 11/12 tone down"},
        ["medRenOriscusCMN"] = {codepoint = 0xEA2A, description = "Oriscus (Corpus Monodicum)"},
        ["noteABlack"] = {codepoint = 0xE197, description = "A (black note)"},
        ["mensuralCombStemDownFlagRight"] = {codepoint = 0xE942, description = "Combining stem with flag right down"},
        ["analyticsStartStimme"] = {codepoint = 0xE862, description = "Start of stimme"},
        ["elecAudioChannelsFive"] = {codepoint = 0xEB43, description = "Five channels"},
        ["noteheadCircleSlash"] = {codepoint = 0xE0F7, description = "Circle slash notehead"},
        ["wiggleWavy"] = {codepoint = 0xEAB5, description = "Wavy line segment"},
        ["mensuralProportionTempusPerfectum"] = {codepoint = 0xE91B, description = "Tempus perfectum"},
        ["staff4LinesWide"] = {codepoint = 0xE019, description = "4-line staff (wide)"},
        ["accidentalSims4Up"] = {codepoint = 0xE2A5, description = "1/4 tone high"},
        ["arrowWhiteUpRight"] = {codepoint = 0xEB69, description = "White arrow up-right (NE)"},
        ["segnoSerpent1"] = {codepoint = 0xE04A, description = "Segno (serpent)"},
        ["daseianExcellentes4"] = {codepoint = 0xEA3F, description = "Daseian excellentes 4"},
        ["segnoSerpent2"] = {codepoint = 0xE04B, description = "Segno (serpent with vertical lines)"},
        ["noteheadRoundWhiteWithDot"] = {codepoint = 0xE115, description = "Round white notehead with dot"},
        ["noteheadHeavyXHat"] = {codepoint = 0xE0F9, description = "Heavy X with hat notehead"},
        ["guitarStrumUp"] = {codepoint = 0xE846, description = "Strum direction up"},
        ["wiggleTrillFast"] = {codepoint = 0xEAA3, description = "Trill wiggle segment, fast"},
        ["organGerman5Semiminimae"] = {codepoint = 0xEE39, description = "Five Semiminimae"},
        ["accSagittal11v19LargeDiesisUp"] = {codepoint = 0xE3AA, description = "11:19 large diesis up, (11:19L, apotome less 11:19M)"},
        ["metNoteDoubleWhole"] = {codepoint = 0xECA0, description = "Double whole note (breve)"},
        ["accSagittal49LargeDiesisUp"] = {codepoint = 0xE3A8, description = "49 large diesis up, (49L, ~31L, apotome less 49M)"},
        ["noteFSharpHalf"] = {codepoint = 0xE190, description = "F sharp (half note)"},
        ["accidentalWyschnegradsky10TwelfthsFlat"] = {codepoint = 0xE434, description = "5/6 tone flat"},
        ["mensuralCclefPetrucciPosHigh"] = {codepoint = 0xE90A, description = "Petrucci C clef, high position"},
        ["figbass2Raised"] = {codepoint = 0xEA53, description = "Figured bass 2 raised by half-step"},
        ["breathMarkTick"] = {codepoint = 0xE4CF, description = "Breath mark (tick-like)"},
        ["elecVideoOut"] = {codepoint = 0xEB4C, description = "Video out"},
        ["pictSandpaperBlocks"] = {codepoint = 0xE762, description = "Sandpaper blocks"},
        ["beamAccelRit5"] = {codepoint = 0xEAF8, description = "Accel./rit. beam 5"},
        ["accidentalNaturalFlat"] = {codepoint = 0xE267, description = "Natural flat"},
        ["wiggleArpeggiatoDownArrow"] = {codepoint = 0xEAAE, description = "Arpeggiato arrowhead down"},
        ["accdnRH3RanksTwoChoirs"] = {codepoint = 0xE8AE, description = "Right hand, 3 ranks, lower tremolo 8' stop + upper tremolo 8' stop"},
        ["note256thDown"] = {codepoint = 0xE1E2, description = "256th note (demisemihemidemisemiquaver) stem down"},
        ["accSagittalUnused3"] = {codepoint = 0xE3DE, description = "Unused"},
        ["keyboardPedalHookStart"] = {codepoint = 0xE672, description = "Pedal hook start"},
        ["keyboardMiddlePedalPictogram"] = {codepoint = 0xE65F, description = "Middle pedal pictogram"},
        ["windHalfClosedHole3"] = {codepoint = 0xE5F8, description = "Half-open hole"},
        ["kahnOverTheTopTap"] = {codepoint = 0xEDED, description = "Over-the-top-tap"},
        ["timeSig2Turned"] = {codepoint = 0xECE2, description = "Turned time signature 2"},
        ["wiggleVibratoLargeSlowest"] = {codepoint = 0xEAE8, description = "Vibrato large, slowest"},
        ["accSagittalSharp7v11CUp"] = {codepoint = 0xE35A, description = "Sharp 7:11C-up, 6° up [60 EDO], 3/5- tone up"},
        ["chantConnectingLineAsc2nd"] = {codepoint = 0xE9BD, description = "Connecting line, ascending 2nd"},
        ["organGermanSemifusaRest"] = {codepoint = 0xEE23, description = "Semifusa Rest"},
        ["pictMusicalSaw"] = {codepoint = 0xE766, description = "Musical saw"},
        ["accdnRH4RanksTenor"] = {codepoint = 0xE8B6, description = "Right hand, 4 ranks, tenor"},
        ["elecMIDIController100"] = {codepoint = 0xEB3B, description = "MIDI controller 100%"},
        ["organGerman2Minimae"] = {codepoint = 0xEE2C, description = "Two Minimae"},
        ["accSagittalDoubleFlat17CUp"] = {codepoint = 0xE365, description = "Double flat 17C-up"},
        ["mensuralCustosDown"] = {codepoint = 0xEA03, description = "Mensural custos down"},
        ["chantAuctumAsc"] = {codepoint = 0xE994, description = "Punctum auctum, ascending"},
        ["dynamicPP"] = {codepoint = 0xE52B, description = "pp"},
        ["pictBeaterBrassMalletsRight"] = {codepoint = 0xE7ED, description = "Brass mallets right"},
        ["wiggleWavyWide"] = {codepoint = 0xEAB6, description = "Wide wavy line segment"},
        ["accidentalQuarterToneFlatNaturalArrowDown"] = {codepoint = 0xE273, description = "Quarter-tone flat"},
        ["pictBambooScraper"] = {codepoint = 0xE6FB, description = "Bamboo scraper"},
        ["functionKUpper"] = {codepoint = 0xEA9C, description = "Function theory K"},
        ["elecVolumeLevel20"] = {codepoint = 0xEB2F, description = "Volume level 20%"},
        ["pictBongos"] = {codepoint = 0xE6DD, description = "Bongos"},
        ["pictBeaterMediumYarnDown"] = {codepoint = 0xE7A7, description = "Medium yarn beater down"},
        ["tremolo1"] = {codepoint = 0xE220, description = "Combining tremolo 1"},
        ["keyboardPedalSost"] = {codepoint = 0xE659, description = "Sostenuto pedal mark"},
        ["pictGong"] = {codepoint = 0xE732, description = "Gong"},
        ["noteheadLargeArrowDownBlack"] = {codepoint = 0xE0F4, description = "Large arrow down (lowest pitch) black notehead"},
        ["accSagittalSharp49LUp"] = {codepoint = 0xE3D8, description = "Sharp 49L-up"},
        ["accidentalDoubleFlatThreeArrowsUp"] = {codepoint = 0xE2D9, description = "Double flat raised by three syntonic commas"},
        ["daseianResidua1"] = {codepoint = 0xEA40, description = "Daseian residua 1"},
        ["fingering1Italic"] = {codepoint = 0xED81, description = "Fingering 1 italic (thumb)"},
        ["accidentalThreeQuarterTonesSharpBusotti"] = {codepoint = 0xE474, description = "Three quarter tones sharp (Bussotti)"},
        ["harpSalzedoWhistlingSounds"] = {codepoint = 0xE687, description = "Whistling sounds (Salzedo)"},
        ["pictGumMediumRight"] = {codepoint = 0xE7C1, description = "Medium gum beater, right"},
        ["noteRaWhole"] = {codepoint = 0xEEE2, description = "Ra (whole note)"},
        ["chantStrophicusLiquescens4th"] = {codepoint = 0xE9C4, description = "Strophicus liquescens, 4th"},
        ["medRenStrophicusCMN"] = {codepoint = 0xEA29, description = "Strophicus (Corpus Monodicum)"},
        ["accidentalBuyukMucennebFlat"] = {codepoint = 0xE440, description = "Büyük mücenneb (flat)"},
        ["pictBrakeDrum"] = {codepoint = 0xE6E1, description = "Brake drum"},
        ["keyboardPedalToe2"] = {codepoint = 0xE665, description = "Pedal toe 2"},
        ["clef8"] = {codepoint = 0xE07D, description = "8 for clefs"},
        ["mensuralObliqueAsc3rdBlackVoid"] = {codepoint = 0xE976, description = "Oblique form, ascending 3rd, black and void"},
        ["flag512thDown"] = {codepoint = 0xE24D, description = "Combining flag 7 (512th) below"},
        ["accidentalJohnstonMinus"] = {codepoint = 0xE2B1, description = "Minus (lower by 81:80)"},
        ["accSagittalDoubleFlat11v49CUp"] = {codepoint = 0xE3E9, description = "Double flat 11:49C-up"},
        ["fretboard5String"] = {codepoint = 0xE854, description = "5-string fretboard"},
        ["kahnToeStep"] = {codepoint = 0xEDC5, description = "Toe-step"},
        ["accSagittal7v11KleismaUp"] = {codepoint = 0xE340, description = "7:11 kleisma up, (7:11k, ~29k)"},
        ["harpTuningKeyGlissando"] = {codepoint = 0xE693, description = "Retune strings for glissando"},
        ["accdnPull"] = {codepoint = 0xE8CC, description = "Pull"},
        ["chantEntryLineAsc3rd"] = {codepoint = 0xE9B5, description = "Entry line, ascending 3rd"},
        ["figbassParensRight"] = {codepoint = 0xEA6B, description = "Figured bass )"},
        ["medRenLiquescenceCMN"] = {codepoint = 0xEA22, description = "Liquescence"},
        ["accidentalJohnston31"] = {codepoint = 0xE2B7, description = "Inverted 13 (lower by 65:64)"},
        ["vocalMouthOpen"] = {codepoint = 0xE642, description = "Mouth open"},
        ["windClosedHole"] = {codepoint = 0xE5F4, description = "Closed hole"},
        ["accdnDiatonicClef"] = {codepoint = 0xE079, description = "Diatonic accordion clef"},
        ["accSagittalSharp5v19CDown"] = {codepoint = 0xE378, description = "Sharp 5:19C-down, 9/20-tone up"},
        ["functionSeven"] = {codepoint = 0xEA77, description = "Function theory 7"},
        ["mensuralCombStemUpFlagRight"] = {codepoint = 0xE941, description = "Combining stem with flag right up"},
        ["splitBarDivider"] = {codepoint = 0xE00A, description = "Split bar divider (bar spans a system break)"},
        ["noteheadSlashWhiteWhole"] = {codepoint = 0xE102, description = "White slash whole"},
        ["noteLeWhole"] = {codepoint = 0xEEE7, description = "Le (whole note)"},
        ["chantPunctumLinea"] = {codepoint = 0xE999, description = "Punctum linea"},
        ["noteGSharpHalf"] = {codepoint = 0xE193, description = "G sharp (half note)"},
        ["pictWoundSoftLeft"] = {codepoint = 0xE7BA, description = "Wound beater, soft core left"},
        ["articSoftAccentTenutoAbove"] = {codepoint = 0xED44, description = "Soft accent-tenuto above"},
        ["accidentalOneThirdToneSharpFerneyhough"] = {codepoint = 0xE48A, description = "One-third-tone sharp (Ferneyhough)"},
        ["kahnTrench"] = {codepoint = 0xEDAF, description = "Trench"},
        ["timeSig1Turned"] = {codepoint = 0xECE1, description = "Turned time signature 1"},
        ["octaveBaselineM"] = {codepoint = 0xEC95, description = "m (baseline)"},
        ["pictBeaterMediumYarnUp"] = {codepoint = 0xE7A6, description = "Medium yarn beater up"},
        ["chantAccentusBelow"] = {codepoint = 0xE9D7, description = "Accentus below"},
        ["timeSigFractionTwoThirds"] = {codepoint = 0xE09B, description = "Time signature fraction ⅔"},
        ["noteheadLargeArrowDownDoubleWhole"] = {codepoint = 0xE0F1, description = "Large arrow down (lowest pitch) double whole notehead"},
        ["elecVolumeLevel80"] = {codepoint = 0xEB32, description = "Volume level 80%"},
        ["accSagittalDoubleSharp5v19CDown"] = {codepoint = 0xE384, description = "Double sharp 5:19C-down, 19/20-tone up"},
        ["pluckedPlectrum"] = {codepoint = 0xE63A, description = "Plectrum"},
        ["noteheadClusterWholeBottom"] = {codepoint = 0xE131, description = "Combining whole note cluster, bottom"},
        ["accSagittal23CommaUp"] = {codepoint = 0xE370, description = "23 comma up, (23C), 2° up [96 EDO], 1/8-tone up"},
        ["note32ndDown"] = {codepoint = 0xE1DC, description = "32nd note (demisemiquaver) stem down"},
        ["elecVolumeFader"] = {codepoint = 0xEB2C, description = "Combining volume fader"},
        ["restHBarLeft"] = {codepoint = 0xE4EF, description = "H-bar, left half"},
        ["octaveSuperscriptB"] = {codepoint = 0xEC94, description = "b (superscript)"},
        ["figbass5Raised2"] = {codepoint = 0xEA59, description = "Figured bass 5 raised by half-step 2"},
        ["kahnStamp"] = {codepoint = 0xEDC3, description = "Stamp"},
        ["rest128th"] = {codepoint = 0xE4EA, description = "128th (semihemidemisemiquaver) rest"},
        ["chantCustosStemUpPosLowest"] = {codepoint = 0xEA04, description = "Plainchant custos, stem up, lowest position"},
        ["accidentalLowerTwoSeptimalCommas"] = {codepoint = 0xE2E0, description = "Lower by two septimal commas"},
        ["guitarBarreFull"] = {codepoint = 0xE848, description = "Full barré"},
        ["accdnRH3RanksAccordion"] = {codepoint = 0xE8AC, description = "Right hand, 3 ranks, 8' stop + upper tremolo 8' stop + 16' stop (accordion)"},
        ["accSagittal23SmallDiesisDown"] = {codepoint = 0xE39F, description = "23 small diesis down"},
        ["wiggleCircularLargerStill"] = {codepoint = 0xEAC6, description = "Circular motion segment, larger still"},
        ["wiggleVibratoLargeFasterStill"] = {codepoint = 0xEAE3, description = "Vibrato large, faster still"},
        ["stringsMuteOn"] = {codepoint = 0xE616, description = "Mute on"},
        ["pictBeaterMallet"] = {codepoint = 0xE7DF, description = "Chime hammer up"},
        ["guitarString1"] = {codepoint = 0xE834, description = "String number 1"},
        ["noteheadDiamondDoubleWholeOld"] = {codepoint = 0xE0DF, description = "Diamond double whole notehead (old)"},
        ["metNote16thDown"] = {codepoint = 0xECAA, description = "16th note (semiquaver) stem down"},
        ["noteheadDiamondClusterBlack2nd"] = {codepoint = 0xE139, description = "Black diamond cluster, 2nd"},
        ["noteheadLargeArrowDownWhole"] = {codepoint = 0xE0F2, description = "Large arrow down (lowest pitch) whole notehead"},
        ["accSagittalDoubleSharp55CDown"] = {codepoint = 0xE362, description = "Double sharp 55C-down, 13° up [96 EDO], 13/16-tone up"},
        ["noteheadClusterWholeTop"] = {codepoint = 0xE12F, description = "Combining whole note cluster, top"},
        ["chantEntryLineAsc2nd"] = {codepoint = 0xE9B4, description = "Entry line, ascending 2nd"},
        ["stringsFouette"] = {codepoint = 0xE622, description = "Fouetté"},
        ["pictBeaterSoftTimpaniLeft"] = {codepoint = 0xE78B, description = "Soft timpani stick left"},
        ["pictBeaterSoftGlockenspielUp"] = {codepoint = 0xE780, description = "Soft glockenspiel stick up"},
        ["mensuralSignumDown"] = {codepoint = 0xEA01, description = "Signum congruentiae down"},
        ["ornamentTremblementCouperin"] = {codepoint = 0xE589, description = "Tremblement appuyé (Couperin)"},
        ["accidentalTavenerFlat"] = {codepoint = 0xE477, description = "Byzantine-style Bakiye flat (Tavener)"},
        ["mensuralRestLongaPerfecta"] = {codepoint = 0xE9F1, description = "Longa perfecta rest"},
        ["mensuralCclefPetrucciPosLow"] = {codepoint = 0xE908, description = "Petrucci C clef, low position"},
        ["tuplet0"] = {codepoint = 0xE880, description = "Tuplet 0"},
        ["accSagittalFlat5CUp"] = {codepoint = 0xE315, description = "Flat 5C-up, 2°[22 29] 3°[27 34 41] 4°[39 46 53] 5°72 7°[96] down, 5/12-tone down"},
        ["windTightEmbouchure"] = {codepoint = 0xE5FF, description = "Tight embouchure"},
        ["noteheadXBlack"] = {codepoint = 0xE0A9, description = "X notehead black"},
        ["luteGermanNUpper"] = {codepoint = 0xEC23, description = "6th course, 13th fret (N)"},
        ["stemSprechgesang"] = {codepoint = 0xE211, description = "Combining sprechgesang stem"},
        ["windStrongAirPressure"] = {codepoint = 0xE603, description = "Very tight embouchure / strong air pressure"},
        ["arrowBlackLeft"] = {codepoint = 0xEB66, description = "Black arrow left (W)"},
        ["pluckedBuzzPizzicato"] = {codepoint = 0xE632, description = "Buzz pizzicato"},
        ["pictMarSmithBrindle"] = {codepoint = 0xE6AC, description = "Marimba (Smith Brindle)"},
        ["elecSkipForwards"] = {codepoint = 0xEB21, description = "Skip forwards"},
        ["repeatDot"] = {codepoint = 0xE044, description = "Single repeat dot"},
        ["textCont32ndBeamLongStem"] = {codepoint = 0xE1FB, description = "Continuing 32nd beam for long stem"},
        ["pictConga"] = {codepoint = 0xE6DE, description = "Conga"},
        ["windRelaxedEmbouchure"] = {codepoint = 0xE5FD, description = "Relaxed embouchure"},
        ["windReedPositionOut"] = {codepoint = 0xE605, description = "Very little reed (pull outwards)"},
        ["accidentalSharpLoweredStockhausen"] = {codepoint = 0xED57, description = "Lowered sharp (Stockhausen)"},
        ["fClef15ma"] = {codepoint = 0xE066, description = "F clef quindicesima alta"},
        ["timeSigFractionQuarter"] = {codepoint = 0xE097, description = "Time signature fraction ¼"},
        ["windReedPositionNormal"] = {codepoint = 0xE604, description = "Normal reed position"},
        ["windOpenHole"] = {codepoint = 0xE5F9, description = "Open hole"},
        ["windMultiphonicsBlackWhiteStem"] = {codepoint = 0xE609, description = "Combining multiphonics (black and white) for stem"},
        ["windMultiphonicsBlackStem"] = {codepoint = 0xE607, description = "Combining multiphonics (black) for stem"},
        ["kahnLeftToeStrike"] = {codepoint = 0xEDC1, description = "Left-toe-strike"},
        ["windFlatEmbouchure"] = {codepoint = 0xE5FB, description = "Flatter embouchure"},
        ["rest256th"] = {codepoint = 0xE4EB, description = "256th rest"},
        ["pictTurnRightLeftStem"] = {codepoint = 0xE80B, description = "Combining turn left or right for stem"},
        ["wiggleVibratoWide"] = {codepoint = 0xEAB1, description = "Wide vibrato / shake wiggle segment"},
        ["accidentalFlatThreeArrowsUp"] = {codepoint = 0xE2DA, description = "Flat raised by three syntonic commas"},
        ["chantCaesura"] = {codepoint = 0xE8F8, description = "Caesura"},
        ["mensuralBlackSemibrevisOblique"] = {codepoint = 0xE95B, description = "Black mensural oblique semibrevis"},
        ["wiggleVibratoSmallestSlowest"] = {codepoint = 0xEAD3, description = "Vibrato smallest, slowest"},
        ["wiggleVibratoSmallestSlower"] = {codepoint = 0xEAD2, description = "Vibrato smallest, slower"},
        ["wiggleVibratoSmallestSlow"] = {codepoint = 0xEAD1, description = "Vibrato smallest, slow"},
        ["chantSemicirculusAbove"] = {codepoint = 0xE9D4, description = "Semicirculus above"},
        ["wiggleVibratoSmallestFasterStill"] = {codepoint = 0xEACE, description = "Vibrato smallest, faster still"},
        ["wiggleVibratoSmallestFaster"] = {codepoint = 0xEACF, description = "Vibrato smallest, faster"},
        ["elecUnmute"] = {codepoint = 0xEB27, description = "Unmute"},
        ["noteheadRoundBlack"] = {codepoint = 0xE113, description = "Round black notehead"},
        ["accidentalFlatArabic"] = {codepoint = 0xED32, description = "Arabic half-tone flat"},
        ["staff1LineWide"] = {codepoint = 0xE016, description = "1-line staff (wide)"},
        ["harpSalzedoAeolianAscending"] = {codepoint = 0xE695, description = "Ascending aeolian chords (Salzedo)"},
        ["daseianSuperiores4"] = {codepoint = 0xEA3B, description = "Daseian superiores 4"},
        ["wiggleVibratoSmallSlower"] = {codepoint = 0xEAD9, description = "Vibrato small, slower"},
        ["pictSleighBell"] = {codepoint = 0xE710, description = "Sleigh bell"},
        ["graceNoteAppoggiaturaStemDown"] = {codepoint = 0xE563, description = "Grace note stem down"},
        ["ornamentLowRightConcaveStroke"] = {codepoint = 0xE5A5, description = "Ornament low right concave stroke"},
        ["dynamicPPP"] = {codepoint = 0xE52A, description = "ppp"},
        ["wiggleVibratoSmallFasterStill"] = {codepoint = 0xEAD5, description = "Vibrato small, faster still"},
        ["wiggleVibratoSmallFaster"] = {codepoint = 0xEAD6, description = "Vibrato small, faster"},
        ["wiggleVibratoMediumSlow"] = {codepoint = 0xEADF, description = "Vibrato medium, slow"},
        ["wiggleVibratoMediumFastest"] = {codepoint = 0xEADB, description = "Vibrato medium, fastest"},
        ["figbass5"] = {codepoint = 0xEA57, description = "Figured bass 5"},
        ["csymParensRightTall"] = {codepoint = 0xE876, description = "Double-height right parenthesis"},
        ["ottavaBassaBa"] = {codepoint = 0xE513, description = "Ottava bassa (ba)"},
        ["accdnRH3RanksClarinet"] = {codepoint = 0xE8A1, description = "Right hand, 3 ranks, 8' stop (clarinet)"},
        ["noteheadNull"] = {codepoint = 0xE0A5, description = "Null notehead"},
        ["accSagittalSharp11v49CDown"] = {codepoint = 0xE3B8, description = "Sharp 11:49C-down"},
        ["articSoftAccentStaccatoBelow"] = {codepoint = 0xED43, description = "Soft accent-staccato below"},
        ["noteFaWhole"] = {codepoint = 0xE153, description = "Fa (whole note)"},
        ["articTenutoAbove"] = {codepoint = 0xE4A4, description = "Tenuto above"},
        ["mensuralCclefPetrucciPosMiddle"] = {codepoint = 0xE909, description = "Petrucci C clef, middle position"},
        ["accidentalDoubleSharpThreeArrowsUp"] = {codepoint = 0xE2DD, description = "Double sharp raised by three syntonic commas"},
        ["wiggleVibratoLargestSlow"] = {codepoint = 0xEAED, description = "Vibrato largest, slow"},
        ["wiggleVibratoLargestFastest"] = {codepoint = 0xEAE9, description = "Vibrato largest, fastest"},
        ["wiggleVibratoLargestFasterStill"] = {codepoint = 0xEAEA, description = "Vibrato largest, faster still"},
        ["daseianSuperiores2"] = {codepoint = 0xEA39, description = "Daseian superiores 2"},
        ["pictDamp2"] = {codepoint = 0xE7FA, description = "Damp 2"},
        ["ornamentPrecompSlideTrillSuffixMuffat"] = {codepoint = 0xE5BA, description = "Slide-trill with two-note suffix (Muffat)"},
        ["accidentalFlatLoweredStockhausen"] = {codepoint = 0xED53, description = "Lowered flat (Stockhausen)"},
        ["pictXylTenor"] = {codepoint = 0xE6A2, description = "Tenor xylophone"},
        ["wiggleVibratoLargestFast"] = {codepoint = 0xEAEC, description = "Vibrato largest, fast"},
        ["dynamicHairpinBracketRight"] = {codepoint = 0xE545, description = "Right bracket (for hairpins)"},
        ["harpSalzedoFluidicSoundsLeft"] = {codepoint = 0xE68D, description = "Fluidic sounds, left hand (Salzedo)"},
        ["chantAuctumDesc"] = {codepoint = 0xE995, description = "Punctum auctum, descending"},
        ["timeSig4Reversed"] = {codepoint = 0xECF4, description = "Reversed time signature 4"},
        ["wiggleVibratoLargeFastest"] = {codepoint = 0xEAE2, description = "Vibrato large, fastest"},
        ["accidentalRaisedStockhausen"] = {codepoint = 0xED50, description = "Raised (Stockhausen)"},
        ["wiggleVibratoLargeFaster"] = {codepoint = 0xEAE4, description = "Vibrato large, faster"},
        ["accidentalHalfSharpArrowUp"] = {codepoint = 0xE299, description = "Half sharp with arrow up"},
        ["dynamicCombinedSeparatorColon"] = {codepoint = 0xE546, description = "Colon separator for combined dynamics"},
        ["organGermanFusa"] = {codepoint = 0xEE2A, description = "Fusa"},
        ["noteheadCircledXLarge"] = {codepoint = 0xE0EC, description = "Cross notehead in large circle"},
        ["luteGermanELower"] = {codepoint = 0xEC04, description = "1st course, 1st fret (e)"},
        ["accidentalCombiningOpenCurlyBrace"] = {codepoint = 0xE2EE, description = "Combining open curly brace"},
        ["wiggleVibratoLargeFast"] = {codepoint = 0xEAE5, description = "Vibrato large, fast"},
        ["elecVolumeLevel100"] = {codepoint = 0xEB33, description = "Volume level 100%"},
        ["noteheadRoundWhiteWithDotLarge"] = {codepoint = 0xE112, description = "Large round white notehead with dot"},
        ["wiggleVibrato"] = {codepoint = 0xEAB0, description = "Vibrato / shake wiggle segment"},
        ["wiggleVIbratoMediumSlower"] = {codepoint = 0xEAE0, description = "Vibrato medium, slower"},
        ["kahnStampStamp"] = {codepoint = 0xEDC8, description = "Stamp-stamp"},
        ["articStaccatissimoBelow"] = {codepoint = 0xE4A7, description = "Staccatissimo below"},
        ["clefChangeCombining"] = {codepoint = 0xE07F, description = "Combining clef change"},
        ["accdnRH3RanksHarmonium"] = {codepoint = 0xE8AA, description = "Right hand, 3 ranks, 4' stop + 8' stop + 16' stop (harmonium)"},
        ["luteDurationDoubleWhole"] = {codepoint = 0xEBA6, description = "Double whole note (breve) duration sign"},
        ["chantConnectingLineAsc3rd"] = {codepoint = 0xE9BE, description = "Connecting line, ascending 3rd"},
        ["noteFFlatWhole"] = {codepoint = 0xE177, description = "F flat (whole note)"},
        ["unmeasuredTremolo"] = {codepoint = 0xE22C, description = "Wieniawski unmeasured tremolo"},
        ["guitarHalfOpenPedal"] = {codepoint = 0xE83E, description = "Half-open wah/volume pedal"},
        ["accidentalSharpOneHorizontalStroke"] = {codepoint = 0xE473, description = "One or three quarter tones sharp"},
        ["mensuralProlation2"] = {codepoint = 0xE911, description = "Tempus perfectum cum prolatione imperfecta (3/4)"},
        ["accdnLH2Ranks16Round"] = {codepoint = 0xE8BC, description = "Left hand, 2 ranks, 16' stop (round)"},
        ["noteShapeTriangleRoundLeftDoubleWhole"] = {codepoint = 0xECDD, description = "Triangle-round left double whole (Funk 7-shape ti)"},
        ["pictSizzleCymbal"] = {codepoint = 0xE724, description = "Sizzle cymbal"},
        ["wiggleTrillSlow"] = {codepoint = 0xEAA5, description = "Trill wiggle segment, slow"},
        ["functionAngleLeft"] = {codepoint = 0xEA93, description = "Function theory angle bracket left"},
        ["wiggleTrillFasterStill"] = {codepoint = 0xEAA1, description = "Trill wiggle segment, faster still"},
        ["dynamicPF"] = {codepoint = 0xE52E, description = "pf"},
        ["wiggleTrillFaster"] = {codepoint = 0xEAA2, description = "Trill wiggle segment, faster"},
        ["wiggleTrill"] = {codepoint = 0xEAA4, description = "Trill wiggle segment"},
        ["wiggleSquareWaveWide"] = {codepoint = 0xEAB9, description = "Wide square wave line segment"},
        ["wiggleSquareWaveNarrow"] = {codepoint = 0xEAB7, description = "Narrow square wave line segment"},
        ["accdnRH3RanksImitationMusette"] = {codepoint = 0xE8A7, description = "Right hand, 3 ranks, 4' stop + 8' stop + upper tremolo 8' stop (imitation musette)"},
        ["wiggleSquareWave"] = {codepoint = 0xEAB8, description = "Square wave line segment"},
        ["wiggleSawtoothWide"] = {codepoint = 0xEABC, description = "Wide sawtooth line segment"},
        ["wiggleSawtooth"] = {codepoint = 0xEABB, description = "Sawtooth line segment"},
        ["accidentalNaturalOneArrowUp"] = {codepoint = 0xE2C7, description = "Natural raised by one syntonic comma"},
        ["wiggleGlissandoGroup3"] = {codepoint = 0xEABF, description = "Group glissando 3"},
        ["beamAccelRitFinal"] = {codepoint = 0xEB03, description = "Accel./rit. beam terminating line"},
        ["luteFrench8thCourse"] = {codepoint = 0xEBCE, description = "Eighth course (diapason)"},
        ["organGermanFusaRest"] = {codepoint = 0xEE22, description = "Fusa Rest"},
        ["daseianGraves3"] = {codepoint = 0xEA32, description = "Daseian graves 3"},
        ["wiggleGlissando"] = {codepoint = 0xEAAF, description = "Glissando wiggle segment"},
        ["noteDWhole"] = {codepoint = 0xE172, description = "D (whole note)"},
        ["pictHiHatOnStand"] = {codepoint = 0xE723, description = "Hi-hat cymbals on stand"},
        ["wiggleCircularStart"] = {codepoint = 0xEAC4, description = "Circular motion start"},
        ["daseianFinales2"] = {codepoint = 0xEA35, description = "Daseian finales 2"},
        ["pictCabasa"] = {codepoint = 0xE743, description = "Cabasa"},
        ["wiggleCircularLargest"] = {codepoint = 0xEAC5, description = "Circular motion segment, largest"},
        ["accSagittal5v13LargeDiesisDown"] = {codepoint = 0xE3AD, description = "5:13 large diesis down"},
        ["noteheadDiamondClusterBlackMiddle"] = {codepoint = 0xE140, description = "Combining black diamond cluster, middle"},
        ["functionMinus"] = {codepoint = 0xEA7B, description = "Function theory minus"},
        ["textTupletBracketEndShortStem"] = {codepoint = 0xE200, description = "Tuplet bracket end for short stem"},
        ["pictBellTree"] = {codepoint = 0xE71A, description = "Bell tree"},
        ["accidentalNaturalRaisedStockhausen"] = {codepoint = 0xED54, description = "Raised natural (Stockhausen)"},
        ["wiggleCircularConstantFlipped"] = {codepoint = 0xEAC1, description = "Constant circular motion segment (flipped)"},
        ["wiggleCircularConstant"] = {codepoint = 0xEAC0, description = "Constant circular motion segment"},
        ["chantStaff"] = {codepoint = 0xE8F0, description = "Plainchant staff"},
        ["brassLiftSmoothMedium"] = {codepoint = 0xE5ED, description = "Smooth lift, medium"},
        ["pictBeaterHardYarnRight"] = {codepoint = 0xE7AC, description = "Hard yarn beater right"},
        ["accidentalCombiningCloseCurlyBrace"] = {codepoint = 0xE2EF, description = "Combining close curly brace"},
        ["noteheadCowellEleventhNoteSeriesWhole"] = {codepoint = 0xEEAD, description = "8/11 note (eleventh note series, Cowell)"},
        ["wiggleCircular"] = {codepoint = 0xEAC9, description = "Circular motion segment"},
        ["articStaccatissimoWedgeAbove"] = {codepoint = 0xE4A8, description = "Staccatissimo wedge above"},
        ["functionFive"] = {codepoint = 0xEA75, description = "Function theory 5"},
        ["wiggleArpeggiatoUpArrow"] = {codepoint = 0xEAAD, description = "Arpeggiato arrowhead up"},
        ["accSagittalFlat23CUp"] = {codepoint = 0xE37B, description = "Flat 23C-up, 6° down [96 EDO], 3/8-tone down"},
        ["wiggleArpeggiatoUp"] = {codepoint = 0xEAA9, description = "Arpeggiato wiggle segment, upwards"},
        ["noteheadDiamondHalfFilled"] = {codepoint = 0xE0E3, description = "Half-filled diamond notehead"},
        ["accSagittalSharp5v23SDown"] = {codepoint = 0xE376, description = "Sharp 5:23S-down, 3° up [60 EDO], 3/10-tone up"},
        ["accSagittalSharp5v13MUp"] = {codepoint = 0xE3D0, description = "Sharp 5:13M-up"},
        ["luteFrench10thCourse"] = {codepoint = 0xEBD0, description = "10th course (diapason)"},
        ["wiggleArpeggiatoDownSwash"] = {codepoint = 0xEAAC, description = "Arpeggiato downward swash"},
        ["wiggleArpeggiatoDown"] = {codepoint = 0xEAAA, description = "Arpeggiato wiggle segment, downwards"},
        ["vocalTongueFingerClickStockhausen"] = {codepoint = 0xE64A, description = "Tongue and finger click (Stockhausen)"},
        ["accidentalJohnstonPlus"] = {codepoint = 0xE2B0, description = "Plus (raise by 81:80)"},
        ["accSagittalSharp5v11SDown"] = {codepoint = 0xE34A, description = "Sharp 5:11S-down"},
        ["vocalTongueClickStockhausen"] = {codepoint = 0xE648, description = "Tongue click (Stockhausen)"},
        ["ornamentPrecompMordentUpperPrefix"] = {codepoint = 0xE5C6, description = "Mordent with upper prefix"},
        ["noteDFlatBlack"] = {codepoint = 0xE19F, description = "D flat (black note)"},
        ["vocalSprechgesang"] = {codepoint = 0xE645, description = "Sprechgesang"},
        ["accidentalNaturalEqualTempered"] = {codepoint = 0xE2F2, description = "Natural equal tempered semitone"},
        ["pictEmptyTrap"] = {codepoint = 0xE6A9, description = "Empty trapezoid"},
        ["vocalMouthWideOpen"] = {codepoint = 0xE643, description = "Mouth wide open"},
        ["accSagittalSharp7CUp"] = {codepoint = 0xE320, description = "Sharp 7C-up, 4° up [43 EDO], 8° up [72 EDO], 2/3-tone up"},
        ["accidentalOneThirdToneFlatFerneyhough"] = {codepoint = 0xE48B, description = "One-third-tone flat (Ferneyhough)"},
        ["noteShapeTriangleUpDoubleWhole"] = {codepoint = 0xECD5, description = "Triangle up double whole (Aikin 7-shape do)"},
        ["noteheadParenthesis"] = {codepoint = 0xE0CE, description = "Parenthesis notehead"},
        ["harpPedalDivider"] = {codepoint = 0xE683, description = "Harp pedal divider"},
        ["vocalMouthPursed"] = {codepoint = 0xE644, description = "Mouth pursed"},
        ["vocalMouthClosed"] = {codepoint = 0xE640, description = "Mouth closed"},
        ["vocalHalbGesungen"] = {codepoint = 0xE64B, description = "Halb gesungen (semi-sprechgesang)"},
        ["vocalFingerClickStockhausen"] = {codepoint = 0xE649, description = "Finger click (Stockhausen)"},
        ["ventiduesimaBassaMb"] = {codepoint = 0xE51E, description = "Ventiduesima bassa (mb)"},
        ["harpSalzedoMuffleTotally"] = {codepoint = 0xE68C, description = "Muffle totally (Salzedo)"},
        ["ventiduesimaBassa"] = {codepoint = 0xE519, description = "Ventiduesima bassa"},
        ["ventiduesimaAlta"] = {codepoint = 0xE518, description = "Ventiduesima alta"},
        ["ventiduesima"] = {codepoint = 0xE517, description = "Ventiduesima"},
        ["noteFBlack"] = {codepoint = 0xE1A6, description = "F (black note)"},
        ["unpitchedPercussionClef2"] = {codepoint = 0xE06A, description = "Unpitched percussion clef 2"},
        ["unpitchedPercussionClef1"] = {codepoint = 0xE069, description = "Unpitched percussion clef 1"},
        ["unmeasuredTremoloSimple"] = {codepoint = 0xE22D, description = "Wieniawski unmeasured tremolo (simpler)"},
        ["tupletColon"] = {codepoint = 0xE88A, description = "Tuplet colon"},
        ["handbellsTablePairBells"] = {codepoint = 0xE821, description = "Table pair of handbells"},
        ["pictWindMachine"] = {codepoint = 0xE754, description = "Wind machine"},
        ["tuplet6"] = {codepoint = 0xE886, description = "Tuplet 6"},
        ["tuplet4"] = {codepoint = 0xE884, description = "Tuplet 4"},
        ["noteheadSlashedBlack1"] = {codepoint = 0xE0CF, description = "Slashed black notehead (bottom left to top right)"},
        ["noteheadDiamondBlackOld"] = {codepoint = 0xE0E2, description = "Diamond black notehead (old)"},
        ["noteShapeIsoscelesTriangleWhite"] = {codepoint = 0xE1C4, description = "Isosceles triangle white (Walker 7-shape ti)"},
        ["tuplet3"] = {codepoint = 0xE883, description = "Tuplet 3"},
        ["accSagittalFlat7CUp"] = {codepoint = 0xE313, description = "Flat 7C-up, 2° down [43 EDO], 4° down [72 EDO], 1/3-tone down"},
        ["metNoteDoubleWholeSquare"] = {codepoint = 0xECA1, description = "Double whole note (square)"},
        ["tripleTongueBelow"] = {codepoint = 0xE5F3, description = "Triple-tongue below"},
        ["noteheadDoubleWholeSquare"] = {codepoint = 0xE0A1, description = "Double whole (breve) notehead (square)"},
        ["tremoloFingered5"] = {codepoint = 0xE229, description = "Fingered tremolo 5"},
        ["noteheadCircledWholeLarge"] = {codepoint = 0xE0EA, description = "Whole notehead in large circle"},
        ["pictFingerCymbals"] = {codepoint = 0xE727, description = "Finger cymbals"},
        ["tremoloFingered1"] = {codepoint = 0xE225, description = "Fingered tremolo 1"},
        ["accSagittalDoubleFlat23SUp"] = {codepoint = 0xE3E1, description = "Double flat 23S-up"},
        ["articStaccatissimoStrokeBelow"] = {codepoint = 0xE4AB, description = "Staccatissimo stroke below"},
        ["keyboardPedalToeToHeel"] = {codepoint = 0xE675, description = "Pedal toe to heel"},
        ["noteheadTriangleUpRightBlack"] = {codepoint = 0xE0C9, description = "Triangle notehead up right black"},
        ["figbassSharp"] = {codepoint = 0xEA66, description = "Figured bass sharp"},
        ["textHeadlessBlackNoteFrac16thShortStem"] = {codepoint = 0xE208, description = "Headless black note, fractional 16th beam, short stem"},
        ["mensuralNoteheadSemiminimaWhite"] = {codepoint = 0xE93D, description = "Semiminima/fusa notehead, white"},
        ["timeSig6"] = {codepoint = 0xE086, description = "Time signature 6"},
        ["noteheadSlashWhiteDoubleWhole"] = {codepoint = 0xE10A, description = "White slash double whole"},
        ["accdnRicochet4"] = {codepoint = 0xE8CF, description = "Ricochet (4 tones)"},
        ["noteheadRoundBlackSlashedLarge"] = {codepoint = 0xE116, description = "Large round black notehead, slashed"},
        ["accSagittal11v49CommaUp"] = {codepoint = 0xE396, description = "11:49 comma up, (11:49C, 11M less 49C)"},
        ["tremoloDivisiDots3"] = {codepoint = 0xE22F, description = "Divide measured tremolo by 3"},
        ["tremolo5"] = {codepoint = 0xE224, description = "Combining tremolo 5"},
        ["tremolo4"] = {codepoint = 0xE223, description = "Combining tremolo 4"},
        ["textBlackNoteLongStem"] = {codepoint = 0xE1F1, description = "Black note, long stem"},
        ["smnSharp"] = {codepoint = 0xEC50, description = "Sharp stem up"},
        ["flag64thDown"] = {codepoint = 0xE247, description = "Combining flag 4 (64th) below"},
        ["tremolo2"] = {codepoint = 0xE221, description = "Combining tremolo 2"},
        ["organGermanFUpper"] = {codepoint = 0xEE05, description = "German organ tablature great F"},
        ["arrowOpenDown"] = {codepoint = 0xEB74, description = "Open arrow down (S)"},
        ["elecDisc"] = {codepoint = 0xEB13, description = "Disc"},
        ["pictXylTenorTrough"] = {codepoint = 0xE6A5, description = "Trough tenor xylophone"},
        ["timeSigSlash"] = {codepoint = 0xEC84, description = "Time signature slash separator"},
        ["timeSigPlus"] = {codepoint = 0xE08C, description = "Time signature +"},
        ["timeSigParensRight"] = {codepoint = 0xE095, description = "Right parenthesis for whole time signature"},
        ["timeSigParensLeft"] = {codepoint = 0xE094, description = "Left parenthesis for whole time signature"},
        ["mensuralAlterationSign"] = {codepoint = 0xEA10, description = "Alteration sign"},
        ["brassSmear"] = {codepoint = 0xE5E2, description = "Smear"},
        ["daseianGraves1"] = {codepoint = 0xEA30, description = "Daseian graves 1"},
        ["timeSigMultiply"] = {codepoint = 0xE091, description = "Time signature multiply"},
        ["mensuralProportion8"] = {codepoint = 0xEE93, description = "Mensural proportion 8"},
        ["timeSigMinus"] = {codepoint = 0xE090, description = "Time signature minus"},
        ["timeSigFractionThreeQuarters"] = {codepoint = 0xE099, description = "Time signature fraction ¾"},
        ["accSagittalFlat5v13LDown"] = {codepoint = 0xE3DD, description = "Flat 5:13L-down"},
        ["mensuralRestMaxima"] = {codepoint = 0xE9F0, description = "Maxima rest"},
        ["pictTimbales"] = {codepoint = 0xE6DC, description = "Timbales"},
        ["timeSigEquals"] = {codepoint = 0xE08F, description = "Time signature equals"},
        ["pictRatchet"] = {codepoint = 0xE6F4, description = "Ratchet"},
        ["chantDeminutumUpper"] = {codepoint = 0xE9B2, description = "Punctum deminutum, upper"},
        ["timeSigCutCommonReversed"] = {codepoint = 0xECFB, description = "Reversed cut time"},
        ["timeSigCutCommon"] = {codepoint = 0xE08B, description = "Cut time"},
        ["noteShapeMoonLeftWhite"] = {codepoint = 0xE1C6, description = "Moon left white (Funk 7-shape do)"},
        ["fretboard5StringNut"] = {codepoint = 0xE855, description = "5-string fretboard at nut"},
        ["ornamentUpCurve"] = {codepoint = 0xE577, description = "Curve above"},
        ["mensuralColorationEndRound"] = {codepoint = 0xEA0F, description = "Coloration end, round"},
        ["elecMixingConsole"] = {codepoint = 0xEB15, description = "Mixing console"},
        ["timeSigCommonTurned"] = {codepoint = 0xECEA, description = "Turned common time"},
        ["timeSigCommonReversed"] = {codepoint = 0xECFA, description = "Reversed common time"},
        ["arrowheadWhiteLeft"] = {codepoint = 0xEB86, description = "White arrowhead left (W)"},
        ["timeSigComma"] = {codepoint = 0xE096, description = "Time signature comma"},
        ["timeSigCombNumerator"] = {codepoint = 0xE09E, description = "Control character for numerator digit"},
        ["timeSigCombDenominator"] = {codepoint = 0xE09F, description = "Control character for denominator digit"},
        ["timeSigBracketRightSmall"] = {codepoint = 0xEC83, description = "Right bracket for numerator only"},
        ["timeSigBracketRight"] = {codepoint = 0xEC81, description = "Right bracket for whole time signature"},
        ["pictCenter3"] = {codepoint = 0xE800, description = "Center (Caltabiano)"},
        ["timeSigBracketLeft"] = {codepoint = 0xEC80, description = "Left bracket for whole time signature"},
        ["luteItalianVibrato"] = {codepoint = 0xEBF6, description = "Vibrato (verre cassé)"},
        ["timeSig9Reversed"] = {codepoint = 0xECF9, description = "Reversed time signature 9"},
        ["pictBeaterWoodTimpaniDown"] = {codepoint = 0xE795, description = "Wood timpani stick down"},
        ["accidental2CommaSharp"] = {codepoint = 0xE451, description = "2-comma sharp"},
        ["timeSig8Turned"] = {codepoint = 0xECE8, description = "Turned time signature 8"},
        ["ornamentDoubleObliqueLinesAfterNote"] = {codepoint = 0xE57E, description = "Double oblique straight lines NW-SE"},
        ["timeSig8Reversed"] = {codepoint = 0xECF8, description = "Reversed time signature 8"},
        ["luteGermanQLower"] = {codepoint = 0xEC0F, description = "5th course, 4th fret (q)"},
        ["chantCustosStemUpPosLow"] = {codepoint = 0xEA05, description = "Plainchant custos, stem up, low position"},
        ["octaveParensRight"] = {codepoint = 0xE51B, description = "Right parenthesis for octave signs"},
        ["mensuralProlation7"] = {codepoint = 0xE916, description = "Tempus imperfectum cum prolatione imperfecta diminution 1 (2/2)"},
        ["noteDiHalf"] = {codepoint = 0xEEE9, description = "Di (half note)"},
        ["keyboardBebung2DotsBelow"] = {codepoint = 0xE669, description = "Clavichord bebung, 2 finger movements (below)"},
        ["barlineTick"] = {codepoint = 0xE039, description = "Tick barline"},
        ["pictCrotales"] = {codepoint = 0xE6AE, description = "Crotales"},
        ["accdnRH3RanksDoubleTremoloUpper8ve"] = {codepoint = 0xE8B2, description = "Right hand, 3 ranks, 4' stop + lower tremolo 8' stop + 8' stop + upper tremolo 8' stop"},
        ["kievanNoteReciting"] = {codepoint = 0xEC32, description = "Kievan reciting note"},
        ["accidentalHabaFlatThreeQuarterTonesLower"] = {codepoint = 0xEE69, description = "Three quarter-tones lower (Alois Hába)"},
        ["organGermanBuxheimerBrevis3"] = {codepoint = 0xEE24, description = "Brevis (Ternary) Buxheimer Orgelbuch"},
        ["kievanNoteBeam"] = {codepoint = 0xEC3B, description = "Kievan beam"},
        ["chantFclef"] = {codepoint = 0xE902, description = "Plainchant F clef"},
        ["kahnScuffle"] = {codepoint = 0xEDE6, description = "Scuffle"},
        ["ornamentPrecompCadenceUpperPrefixTurn"] = {codepoint = 0xE5C2, description = "Cadence with upper prefix and turn"},
        ["timeSig7"] = {codepoint = 0xE087, description = "Time signature 7"},
        ["noteheadDiamondClusterWhite2nd"] = {codepoint = 0xE138, description = "White diamond cluster, 2nd"},
        ["noteShapeRoundWhite"] = {codepoint = 0xE1B0, description = "Round white (4-shape sol; 7-shape so)"},
        ["mensuralCombStemUpFlagLeft"] = {codepoint = 0xE943, description = "Combining stem with flag left up"},
        ["timeSig6Turned"] = {codepoint = 0xECE6, description = "Turned time signature 6"},
        ["keyboardLeftPedalPictogram"] = {codepoint = 0xE65E, description = "Left pedal pictogram"},
        ["noteLiWhole"] = {codepoint = 0xEEE6, description = "Li (whole note)"},
        ["accidentalSharpRaisedStockhausen"] = {codepoint = 0xED56, description = "Raised sharp (Stockhausen)"},
        ["pictGumHardDown"] = {codepoint = 0xE7C4, description = "Hard gum beater, down"},
        ["timeSig6Reversed"] = {codepoint = 0xECF6, description = "Reversed time signature 6"},
        ["timeSig5Turned"] = {codepoint = 0xECE5, description = "Turned time signature 5"},
        ["wiggleVIbratoLargestSlower"] = {codepoint = 0xEAEE, description = "Vibrato largest, slower"},
        ["elecHeadphones"] = {codepoint = 0xEB11, description = "Headphones"},
        ["timeSig5"] = {codepoint = 0xE085, description = "Time signature 5"},
        ["timeSig4Turned"] = {codepoint = 0xECE4, description = "Turned time signature 4"},
        ["luteGermanMUpper"] = {codepoint = 0xEC22, description = "6th course, 12th fret (M)"},
        ["timeSig4"] = {codepoint = 0xE084, description = "Time signature 4"},
        ["brassLiftMedium"] = {codepoint = 0xE5D2, description = "Lift, medium"},
        ["timeSig3Reversed"] = {codepoint = 0xECF3, description = "Reversed time signature 3"},
        ["timeSig2Reversed"] = {codepoint = 0xECF2, description = "Reversed time signature 2"},
        ["luteFingeringRHThumb"] = {codepoint = 0xEBAD, description = "Right-hand fingering, thumb"},
        ["timeSig2"] = {codepoint = 0xE082, description = "Time signature 2"},
        ["articMarcatoStaccatoAbove"] = {codepoint = 0xE4AE, description = "Marcato-staccato above"},
        ["kahnRightTurn"] = {codepoint = 0xEDF1, description = "Right-turn"},
        ["kahnScrape"] = {codepoint = 0xEDAE, description = "Scrape"},
        ["timeSig8"] = {codepoint = 0xE088, description = "Time signature 8"},
        ["accSagittal6TinasUp"] = {codepoint = 0xE402, description = "6 tinas up, 2 minas up, 65/77-schismina up, 0.83 cents up"},
        ["timeSig0Reversed"] = {codepoint = 0xECF0, description = "Reversed time signature 0"},
        ["gClefLigatedNumberBelow"] = {codepoint = 0xE058, description = "Combining G clef, number below"},
        ["harpSalzedoDampLowStrings"] = {codepoint = 0xE697, description = "Damp only low strings (Salzedo)"},
        ["timeSig0"] = {codepoint = 0xE080, description = "Time signature 0"},
        ["figbass6Raised2"] = {codepoint = 0xEA6F, description = "Figured bass 6 raised by half-step 2"},
        ["textTupletBracketEndLongStem"] = {codepoint = 0xE203, description = "Tuplet bracket end for long stem"},
        ["textTuplet3ShortStem"] = {codepoint = 0xE1FF, description = "Tuplet number 3 for short stem"},
        ["chantDivisioMinima"] = {codepoint = 0xE8F3, description = "Divisio minima"},
        ["textTie"] = {codepoint = 0xE1FD, description = "Tie"},
        ["accidentalWyschnegradsky1TwelfthsFlat"] = {codepoint = 0xE42B, description = "1/12 tone flat"},
        ["textHeadlessBlackNoteFrac8thShortStem"] = {codepoint = 0xE206, description = "Headless black note, fractional 8th beam, short stem"},
        ["restWhole"] = {codepoint = 0xE4E3, description = "Whole (semibreve) rest"},
        ["accdnRH3RanksBassoon"] = {codepoint = 0xE8A4, description = "Right hand, 3 ranks, 16' stop (bassoon)"},
        ["textHeadlessBlackNoteFrac32ndLongStem"] = {codepoint = 0xE20A, description = "Headless black note, fractional 32nd beam, long stem"},
        ["tremoloDivisiDots6"] = {codepoint = 0xE231, description = "Divide measured tremolo by 6"},
        ["textHeadlessBlackNoteFrac16thLongStem"] = {codepoint = 0xE209, description = "Headless black note, fractional 16th beam, long stem"},
        ["organGermanBUpper"] = {codepoint = 0xEE0A, description = "German organ tablature great B"},
        ["textBlackNoteShortStem"] = {codepoint = 0xE1F0, description = "Black note, short stem"},
        ["textBlackNoteFrac8thShortStem"] = {codepoint = 0xE1F2, description = "Black note, fractional 8th beam, short stem"},
        ["restLonga"] = {codepoint = 0xE4E1, description = "Longa rest"},
        ["staff6LinesWide"] = {codepoint = 0xE01B, description = "6-line staff (wide)"},
        ["dynamicFFFF"] = {codepoint = 0xE531, description = "ffff"},
        ["pictSlideBrushOnGong"] = {codepoint = 0xE734, description = "Slide brush on gong"},
        ["articTenutoStaccatoAbove"] = {codepoint = 0xE4B2, description = "Louré (tenuto-staccato) above"},
        ["noteDFlatWhole"] = {codepoint = 0xE171, description = "D flat (whole note)"},
        ["systemDividerLong"] = {codepoint = 0xE008, description = "Long system divider"},
        ["ornamentTrill"] = {codepoint = 0xE566, description = "Trill"},
        ["systemDividerExtraLong"] = {codepoint = 0xE009, description = "Extra long system divider"},
        ["pictCencerro"] = {codepoint = 0xE716, description = "Cencerro"},
        ["analyticsThemeInversion"] = {codepoint = 0xE867, description = "Inversion of theme"},
        ["stringsBowBehindBridgeThreeStrings"] = {codepoint = 0xE629, description = "Bow behind bridge on three strings"},
        ["swissRudimentsNoteheadBlackDouble"] = {codepoint = 0xEE72, description = "Swiss rudiments doublé black notehead"},
        ["stringsVibratoPulse"] = {codepoint = 0xE623, description = "Vibrato pulse accent (Saunders) for stem"},
        ["stringsUpBowTurned"] = {codepoint = 0xE613, description = "Turned up bow"},
        ["accidentalCombiningLower23Limit29LimitComma"] = {codepoint = 0xE2EA, description = "Combining lower by one 23-limit comma"},
        ["pictBeaterTriangleDown"] = {codepoint = 0xE7D6, description = "Triangle beater down"},
        ["stringsScrapeCircularCounterclockwise"] = {codepoint = 0xEE89, description = "Scrape, circular counter-clockwise"},
        ["mensuralNoteheadLongaVoid"] = {codepoint = 0xE935, description = "Longa/brevis notehead, void"},
        ["accSagittalDoubleFlat7v19CUp"] = {codepoint = 0xE3E5, description = "Double flat 7:19C-up"},
        ["accidentalSharpArabic"] = {codepoint = 0xED36, description = "Arabic half-tone sharp"},
        ["mensuralObliqueAsc2ndVoid"] = {codepoint = 0xE971, description = "Oblique form, ascending 2nd, void"},
        ["figbass7Raised1"] = {codepoint = 0xEA5E, description = "Figured bass 7 raised by half-step"},
        ["accidentalCombiningRaise43Comma"] = {codepoint = 0xEE57, description = "Combining raise by one 43-limit comma"},
        ["caesuraSingleStroke"] = {codepoint = 0xE4D7, description = "Single stroke caesura"},
        ["accSagittalFlat5v49MDown"] = {codepoint = 0xE3D7, description = "Flat 5:49M-down"},
        ["accSagittalSharp49MUp"] = {codepoint = 0xE3D4, description = "Sharp 49M-up"},
        ["stringsTripleChopInward"] = {codepoint = 0xEE8A, description = "Triple chop, inward"},
        ["elecStop"] = {codepoint = 0xEB1D, description = "Stop"},
        ["mensuralCombStemUpFlagExtended"] = {codepoint = 0xE947, description = "Combining stem with extended flag up"},
        ["noteSiWhole"] = {codepoint = 0xE157, description = "Si (whole note)"},
        ["brassJazzTurn"] = {codepoint = 0xE5E4, description = "Jazz turn"},
        ["kahnWingChange"] = {codepoint = 0xEDEA, description = "Wing-change"},
        ["stringsScrapeCircularClockwise"] = {codepoint = 0xEE88, description = "Scrape, circular clockwise"},
        ["fingering9"] = {codepoint = 0xED27, description = "Fingering 9"},
        ["stringsOverpressureUpBow"] = {codepoint = 0xE61C, description = "Overpressure, up bow"},
        ["caesuraCurved"] = {codepoint = 0xE4D4, description = "Curved caesura"},
        ["stringsOverpressurePossibileDownBow"] = {codepoint = 0xE61D, description = "Overpressure possibile, down bow"},
        ["stringsOverpressureNoDirection"] = {codepoint = 0xE61F, description = "Overpressure, no bow direction"},
        ["pictBeaterWoodTimpaniLeft"] = {codepoint = 0xE797, description = "Wood timpani stick left"},
        ["accSagittalFlat17kDown"] = {codepoint = 0xE3C3, description = "Flat 17k-down"},
        ["windWeakAirPressure"] = {codepoint = 0xE602, description = "Very relaxed embouchure / weak air-pressure"},
        ["medRenPunctumCMN"] = {codepoint = 0xEA25, description = "Punctum (Corpus Monodicum)"},
        ["stringsDownBowTurned"] = {codepoint = 0xE611, description = "Turned down bow"},
        ["csymAccidentalDoubleFlat"] = {codepoint = 0xED64, description = "Double flat"},
        ["stringsDownBowTowardsBody"] = {codepoint = 0xEE80, description = "Down bow, towards body"},
        ["stringsDownBow"] = {codepoint = 0xE610, description = "Down bow"},
        ["stringsBowOnTailpiece"] = {codepoint = 0xE61A, description = "Bow on tailpiece"},
        ["accdnRicochet2"] = {codepoint = 0xE8CD, description = "Ricochet (2 tones)"},
        ["pictCenter1"] = {codepoint = 0xE7FE, description = "Center (Weinberg)"},
        ["noteheadTriangleRightBlack"] = {codepoint = 0xE0C2, description = "Triangle notehead right black"},
        ["keyboardPluckInside"] = {codepoint = 0xE667, description = "Pluck strings inside piano (Maderna)"},
        ["stringsBowBehindBridgeTwoStrings"] = {codepoint = 0xE628, description = "Bow behind bridge on two strings"},
        ["noteCWhole"] = {codepoint = 0xE16F, description = "C (whole note)"},
        ["stringsBowBehindBridgeOneString"] = {codepoint = 0xE627, description = "Bow behind bridge on one string"},
        ["mensuralProportion4"] = {codepoint = 0xE929, description = "Mensural proportion 4"},
        ["noteEFlatHalf"] = {codepoint = 0xE18B, description = "E flat (half note)"},
        ["noteSoWhole"] = {codepoint = 0xE154, description = "So (whole note)"},
        ["stringsBowBehindBridgeFourStrings"] = {codepoint = 0xE62A, description = "Bow behind bridge on four strings"},
        ["accidentalCombiningRaise47Quartertone"] = {codepoint = 0xEE59, description = "Combining raise by one 47-limit quartertone"},
        ["organGermanOctaveUp"] = {codepoint = 0xEE18, description = "Combining single octave line above"},
        ["stockhausenTremolo"] = {codepoint = 0xE232, description = "Stockhausen irregular tremolo (\"Morsen\", like Morse code)"},
        ["stemSussurando"] = {codepoint = 0xE21D, description = "Combining sussurando stem"},
        ["fingeringLeftParenthesisItalic"] = {codepoint = 0xED8A, description = "Fingering left parenthesis italic"},
        ["stemSulPonticello"] = {codepoint = 0xE214, description = "Combining sul ponticello (bow behind bridge) stem"},
        ["noteheadClusterHalfTop"] = {codepoint = 0xE132, description = "Combining half note cluster, top"},
        ["accSagittalDoubleSharp5CDown"] = {codepoint = 0xE330, description = "Double sharp 5C-down, 5°[22 29] 7°[34 41] 9°53 up, 11/12 tone up"},
        ["stemRimShot"] = {codepoint = 0xE21E, description = "Combining rim shot stem"},
        ["stemMultiphonicsWhite"] = {codepoint = 0xE21B, description = "Combining multiphonics (white) stem"},
        ["noteLiHalf"] = {codepoint = 0xEEEF, description = "Li (half note)"},
        ["csymAccidentalTripleSharp"] = {codepoint = 0xED65, description = "Triple sharp"},
        ["stemMultiphonicsBlackWhite"] = {codepoint = 0xE21C, description = "Combining multiphonics (black and white) stem"},
        ["stemDamp"] = {codepoint = 0xE218, description = "Combining damp stem"},
        ["stemBuzzRoll"] = {codepoint = 0xE217, description = "Combining buzz roll stem"},
        ["stemBowOnTailpiece"] = {codepoint = 0xE216, description = "Combining bow on tailpiece stem"},
        ["stemBowOnBridge"] = {codepoint = 0xE215, description = "Combining bow on bridge stem"},
        ["pictBeaterHardXylophoneRight"] = {codepoint = 0xE77A, description = "Hard xylophone stick right"},
        ["noteheadClusterRoundWhite"] = {codepoint = 0xE122, description = "Cluster notehead white (round)"},
        ["organGermanFisLower"] = {codepoint = 0xEE12, description = "German organ tablature small Fis"},
        ["guitarGolpe"] = {codepoint = 0xE842, description = "Golpe (tapping the pick guard)"},
        ["staffPosRaise8"] = {codepoint = 0xEB97, description = "Raise 8 staff positions"},
        ["accidentalCommaSlashUp"] = {codepoint = 0xE479, description = "Syntonic/Didymus comma (80:81) up (Bosanquet)"},
        ["staffPosRaise7"] = {codepoint = 0xEB96, description = "Raise 7 staff positions"},
        ["mensuralObliqueDesc3rdWhite"] = {codepoint = 0xE987, description = "Oblique form, descending 3rd, white"},
        ["pictBeaterSoftXylophone"] = {codepoint = 0xE7DB, description = "Soft xylophone beaters"},
        ["staffPosRaise5"] = {codepoint = 0xEB94, description = "Raise 5 staff positions"},
        ["staffPosRaise2"] = {codepoint = 0xEB91, description = "Raise 2 staff positions"},
        ["noteheadClusterQuarter2nd"] = {codepoint = 0xE127, description = "Quarter note cluster, 2nd"},
        ["staffPosRaise1"] = {codepoint = 0xEB90, description = "Raise 1 staff position"},
        ["kahnJumpTogether"] = {codepoint = 0xEDA4, description = "Jump-together"},
        ["staffPosLower8"] = {codepoint = 0xEB9F, description = "Lower 8 staff positions"},
        ["staffPosLower7"] = {codepoint = 0xEB9E, description = "Lower 7 staff positions"},
        ["staffPosLower6"] = {codepoint = 0xEB9D, description = "Lower 6 staff positions"},
        ["staffPosLower4"] = {codepoint = 0xEB9B, description = "Lower 4 staff positions"},
        ["noteheadSquareBlackWhite"] = {codepoint = 0xE11B, description = "Large square white notehead"},
        ["brassDoitMedium"] = {codepoint = 0xE5D5, description = "Doit, medium"},
        ["pictBeaterSoftYarnDown"] = {codepoint = 0xE7A3, description = "Soft yarn beater down"},
        ["staffPosLower3"] = {codepoint = 0xEB9A, description = "Lower 3 staff positions"},
        ["staffPosLower2"] = {codepoint = 0xEB99, description = "Lower 2 staff positions"},
        ["chantIctusAbove"] = {codepoint = 0xE9D0, description = "Ictus above"},
        ["staffDivideArrowUpDown"] = {codepoint = 0xE00D, description = "Staff divide arrows"},
        ["flag128thUp"] = {codepoint = 0xE248, description = "Combining flag 5 (128th) above"},
        ["pictStickShot"] = {codepoint = 0xE7F0, description = "Stick shot"},
        ["staffDivideArrowUp"] = {codepoint = 0xE00C, description = "Staff divide arrow up"},
        ["accSagittalDoubleSharp49SDown"] = {codepoint = 0xE3E2, description = "Double sharp 49S-down"},
        ["noteheadClusterHalfBottom"] = {codepoint = 0xE134, description = "Combining half note cluster, bottom"},
        ["pluckedSnapPizzicatoAbove"] = {codepoint = 0xE631, description = "Snap pizzicato above"},
        ["accidentalDoubleFlatArabic"] = {codepoint = 0xED30, description = "Arabic double flat"},
        ["textBlackNoteFrac16thLongStem"] = {codepoint = 0xE1F5, description = "Black note, fractional 16th beam, long stem"},
        ["staff5LinesWide"] = {codepoint = 0xE01A, description = "5-line staff (wide)"},
        ["pictBassDrum"] = {codepoint = 0xE6D4, description = "Bass drum"},
        ["accdnLH3RanksDouble8Square"] = {codepoint = 0xE8C3, description = "Left hand, 3 ranks, double 8' stop (square)"},
        ["organGermanCLower"] = {codepoint = 0xEE0C, description = "German organ tablature small C"},
        ["conductorWeakBeat"] = {codepoint = 0xE893, description = "Weak beat or cue"},
        ["staff4Lines"] = {codepoint = 0xE013, description = "4-line staff"},
        ["staff3LinesNarrow"] = {codepoint = 0xE01E, description = "3-line staff (narrow)"},
        ["accSagittalDoubleFlat5v23SUp"] = {codepoint = 0xE383, description = "Double flat 5:23S-up, 8° down [60 EDO], 4/5-tone down"},
        ["staff3Lines"] = {codepoint = 0xE012, description = "3-line staff"},
        ["kahnRightToeStrike"] = {codepoint = 0xEDC2, description = "Right-toe-strike"},
        ["accidentalOneQuarterToneFlatFerneyhough"] = {codepoint = 0xE48F, description = "One-quarter-tone flat (Ferneyhough)"},
        ["staff2LinesWide"] = {codepoint = 0xE017, description = "2-line staff (wide)"},
        ["accidentalCombiningLower53LimitComma"] = {codepoint = 0xE2F7, description = "Combining lower by one 53-limit comma"},
        ["staff2LinesNarrow"] = {codepoint = 0xE01D, description = "2-line staff (narrow)"},
        ["vocalMouthSlightlyOpen"] = {codepoint = 0xE641, description = "Mouth slightly open"},
        ["arrowheadOpenDownRight"] = {codepoint = 0xEB8B, description = "Open arrowhead down-right (SE)"},
        ["wiggleVibratoSmallSlowest"] = {codepoint = 0xEADA, description = "Vibrato small, slowest"},
        ["accidentalCommaSlashDown"] = {codepoint = 0xE47A, description = "Syntonic/Didymus comma (80:81) down (Bosanquet)"},
        ["smnSharpWhiteDown"] = {codepoint = 0xEC5A, description = "Sharp (white) stem down"},
        ["fingeringSubstitutionDash"] = {codepoint = 0xED22, description = "Finger substitution dash"},
        ["pictScrapeAroundRim"] = {codepoint = 0xE7F3, description = "Scrape around rim (counter-clockwise)"},
        ["luteGermanALower"] = {codepoint = 0xEC00, description = "5th course, 1st fret (a)"},
        ["elecMIDIController60"] = {codepoint = 0xEB39, description = "MIDI controller 60%"},
        ["accSagittal11LargeDiesisUp"] = {codepoint = 0xE30C, description = "11 large diesis up, (11L), (sharp less 11M), 3° up [46 EDO]"},
        ["smnHistoryDoubleFlat"] = {codepoint = 0xEC57, description = "Double flat history sign"},
        ["accSagittal9TinasDown"] = {codepoint = 0xE409, description = "9 tinas down, 1/(7²⋅11)-schismina down, 1.26 cents down"},
        ["smnFlatWhite"] = {codepoint = 0xEC53, description = "Flat (white)"},
        ["mensuralRestMinima"] = {codepoint = 0xE9F5, description = "Minima rest"},
        ["elecMIDIController0"] = {codepoint = 0xEB36, description = "MIDI controller 0%"},
        ["functionOne"] = {codepoint = 0xEA71, description = "Function theory 1"},
        ["semipitchedPercussionClef2"] = {codepoint = 0xE06C, description = "Semi-pitched percussion clef 2"},
        ["accidentalSims4Down"] = {codepoint = 0xE2A2, description = "1/4 tone low"},
        ["articMarcatoTenutoAbove"] = {codepoint = 0xE4BC, description = "Marcato-tenuto above"},
        ["semipitchedPercussionClef1"] = {codepoint = 0xE06B, description = "Semi-pitched percussion clef 1"},
        ["kievanAugmentationDot"] = {codepoint = 0xEC3C, description = "Kievan augmentation dot"},
        ["segno"] = {codepoint = 0xE047, description = "Segno"},
        ["schaefferPreviousClef"] = {codepoint = 0xE070, description = "Schäffer previous clef"},
        ["gClefLigatedNumberAbove"] = {codepoint = 0xE059, description = "Combining G clef, number above"},
        ["pictSlideWhistle"] = {codepoint = 0xE750, description = "Slide whistle"},
        ["schaefferGClefToFClef"] = {codepoint = 0xE071, description = "Schäffer G clef to F clef change"},
        ["harpSalzedoDampBothHands"] = {codepoint = 0xE698, description = "Damp with both hands (Salzedo)"},
        ["metNote256thUp"] = {codepoint = 0xECB1, description = "256th note (demisemihemidemisemiquaver) stem up"},
        ["figbass7Raised2"] = {codepoint = 0xEA5F, description = "Figured bass 7 lowered by a half-step"},
        ["luteGermanAUpper"] = {codepoint = 0xEC17, description = "6th course, 1st fret (A)"},
        ["scaleDegree4"] = {codepoint = 0xEF03, description = "Scale degree 4"},
        ["barlineShort"] = {codepoint = 0xE038, description = "Short barline"},
        ["organGermanBuxheimerSemibrevis"] = {codepoint = 0xEE26, description = "Semibrevis Buxheimer Orgelbuch"},
        ["figbassDoubleSharp"] = {codepoint = 0xEA67, description = "Figured bass double sharp"},
        ["restQuarterZ"] = {codepoint = 0xE4F6, description = "Z-style quarter (crotchet) rest"},
        ["restMaxima"] = {codepoint = 0xE4E0, description = "Maxima rest"},
        ["textBlackNoteFrac8thLongStem"] = {codepoint = 0xE1F3, description = "Black note, fractional 8th beam, long stem"},
        ["mensuralCclefPetrucciPosLowest"] = {codepoint = 0xE907, description = "Petrucci C clef, lowest position"},
        ["accidentalTavenerSharp"] = {codepoint = 0xE476, description = "Byzantine-style Büyük mücenneb sharp (Tavener)"},
        ["accdnRH3RanksViolin"] = {codepoint = 0xE8A6, description = "Right hand, 3 ranks, 8' stop + upper tremolo 8' stop (violin)"},
        ["harpSalzedoSnareDrum"] = {codepoint = 0xE69D, description = "Snare drum effect (Salzedo)"},
        ["accidentalReversedFlatAndFlatArrowUp"] = {codepoint = 0xE294, description = "Reversed flat and flat with arrow up"},
        ["organGerman3Semiminimae"] = {codepoint = 0xEE31, description = "Three Semiminimae"},
        ["noteheadDiamondWhite"] = {codepoint = 0xE0DD, description = "Diamond white notehead"},
        ["arrowWhiteDownRight"] = {codepoint = 0xEB6B, description = "White arrow down-right (SE)"},
        ["accSagittal2MinasDown"] = {codepoint = 0xE3F7, description = "2 minas down, 65/77-schismina down, 0.83 cents down"},
        ["harpTuningKey"] = {codepoint = 0xE690, description = "Tuning key pictogram"},
        ["pictBeaterSoftXylophoneUp"] = {codepoint = 0xE770, description = "Soft xylophone stick up"},
        ["kahnStomp"] = {codepoint = 0xEDCA, description = "Stomp"},
        ["keyboardPedalUpNotch"] = {codepoint = 0xE657, description = "Pedal up notch"},
        ["arrowheadBlackDownLeft"] = {codepoint = 0xEB7D, description = "Black arrowhead down-left (SW)"},
        ["restHBar"] = {codepoint = 0xE4EE, description = "Multiple measure rest"},
        ["restDoubleWholeLegerLine"] = {codepoint = 0xE4F3, description = "Double whole rest on leger lines"},
        ["metNote512thUp"] = {codepoint = 0xECB3, description = "512th note (hemidemisemihemidemisemiquaver) stem up"},
        ["mensuralProlation9"] = {codepoint = 0xE918, description = "Tempus imperfectum cum prolatione imperfecta diminution 3 (2/2)"},
        ["accidentalCombiningLower43Comma"] = {codepoint = 0xEE56, description = "Combining lower by one 43-limit comma"},
        ["rest512th"] = {codepoint = 0xE4EC, description = "512th rest"},
        ["accSagittalFlat5v19CUp"] = {codepoint = 0xE379, description = "Flat 5:19C-up, 9/20-tone down"},
        ["ornamentLowLeftConcaveStroke"] = {codepoint = 0xE598, description = "Ornament low left concave stroke"},
        ["ornamentQuilisma"] = {codepoint = 0xEA20, description = "Quilisma"},
        ["noteheadDiamondClusterWhite3rd"] = {codepoint = 0xE13A, description = "White diamond cluster, 3rd"},
        ["rest32nd"] = {codepoint = 0xE4E8, description = "32nd (demisemiquaver) rest"},
        ["mensuralProportionProportioDupla2"] = {codepoint = 0xE91D, description = "Proportio dupla 2"},
        ["repeatRightLeft"] = {codepoint = 0xE042, description = "Right and left repeat sign"},
        ["mensuralNoteheadLongaBlackVoid"] = {codepoint = 0xE936, description = "Longa/brevis notehead, black and void"},
        ["organGermanDUpper"] = {codepoint = 0xEE02, description = "German organ tablature great D"},
        ["noteheadPlusDoubleWhole"] = {codepoint = 0xE0AC, description = "Plus notehead double whole"},
        ["accidentalDoubleFlatThreeArrowsDown"] = {codepoint = 0xE2D4, description = "Double flat lowered by three syntonic commas"},
        ["repeatDots"] = {codepoint = 0xE043, description = "Repeat dots"},
        ["articStressBelow"] = {codepoint = 0xE4B7, description = "Stress below"},
        ["mensuralObliqueDesc5thWhite"] = {codepoint = 0xE98F, description = "Oblique form, descending 5th, white"},
        ["repeat4Bars"] = {codepoint = 0xE502, description = "Repeat last four bars"},
        ["repeat2Bars"] = {codepoint = 0xE501, description = "Repeat last two bars"},
        ["functionNLower"] = {codepoint = 0xEA86, description = "Function theory n"},
        ["pictRimShotOnStem"] = {codepoint = 0xE7FD, description = "Rim shot for stem"},
        ["quindicesimaBassaMb"] = {codepoint = 0xE51D, description = "Quindicesima bassa (mb)"},
        ["chantConnectingLineAsc4th"] = {codepoint = 0xE9BF, description = "Connecting line, ascending 4th"},
        ["quindicesimaAlta"] = {codepoint = 0xE515, description = "Quindicesima alta"},
        ["pictCoins"] = {codepoint = 0xE7E7, description = "Coins"},
        ["pluckedSnapPizzicatoBelow"] = {codepoint = 0xE630, description = "Snap pizzicato below"},
        ["pluckedFingernailFlick"] = {codepoint = 0xE637, description = "Fingernail flick"},
        ["pluckedDamp"] = {codepoint = 0xE638, description = "Damp"},
        ["pictXylTrough"] = {codepoint = 0xE6A4, description = "Trough xylophone"},
        ["wiggleVibratoLargestFaster"] = {codepoint = 0xEAEB, description = "Vibrato largest, faster"},
        ["chantStrophicusLiquescens2nd"] = {codepoint = 0xE9C2, description = "Strophicus liquescens, 2nd"},
        ["metNote8thDown"] = {codepoint = 0xECA8, description = "Eighth note (quaver) stem down"},
        ["noteShapeIsoscelesTriangleDoubleWhole"] = {codepoint = 0xECDA, description = "Isosceles triangle double whole (Walker 7-shape ti)"},
        ["pictXyl"] = {codepoint = 0xE6A1, description = "Xylophone"},
        ["pictWoundSoftUp"] = {codepoint = 0xE7B7, description = "Wound beater, soft core up"},
        ["pictWoundSoftDown"] = {codepoint = 0xE7B8, description = "Wound beater, soft core down"},
        ["pictWoundHardUp"] = {codepoint = 0xE7B3, description = "Wound beater, hard core up"},
        ["pictWoundHardRight"] = {codepoint = 0xE7B5, description = "Wound beater, hard core right"},
        ["pictBeaterSuperballDown"] = {codepoint = 0xE7AF, description = "Superball beater down"},
        ["pictWoundHardLeft"] = {codepoint = 0xE7B6, description = "Wound beater, hard core left"},
        ["accSagittal9TinasUp"] = {codepoint = 0xE408, description = "9 tinas up, 1/(7²⋅11)-schismina up, 1.26 cents up"},
        ["luteGermanBLower"] = {codepoint = 0xEC01, description = "4th course, 1st fret (b)"},
        ["pictWoodBlock"] = {codepoint = 0xE6F0, description = "Wood block"},
        ["pictWindWhistle"] = {codepoint = 0xE758, description = "Wind whistle (or mouth siren)"},
        ["pictMegaphone"] = {codepoint = 0xE759, description = "Megaphone"},
        ["tuplet8"] = {codepoint = 0xE888, description = "Tuplet 8"},
        ["chantDeminutumLower"] = {codepoint = 0xE9B3, description = "Punctum deminutum, lower"},
        ["figbass5Raised3"] = {codepoint = 0xEA5A, description = "Figured bass diminished 5"},
        ["pictWindChimesGlass"] = {codepoint = 0xE6C1, description = "Wind chimes (glass)"},
        ["mensuralWhiteMaxima"] = {codepoint = 0xE95C, description = "White mensural maxima"},
        ["barlineDouble"] = {codepoint = 0xE031, description = "Double barline"},
        ["pictWhip"] = {codepoint = 0xE6F6, description = "Whip"},
        ["mensuralBlackMinima"] = {codepoint = 0xE954, description = "Black mensural minima"},
        ["pictVietnameseHat"] = {codepoint = 0xE725, description = "Vietnamese hat cymbal"},
        ["metNote32ndDown"] = {codepoint = 0xECAC, description = "32nd note (demisemiquaver) stem down"},
        ["pictVibraslap"] = {codepoint = 0xE745, description = "Vibraslap"},
        ["accSagittalDoubleSharp25SDown"] = {codepoint = 0xE32C, description = "Double sharp 25S-down, 8°up [53 EDO]"},
        ["pictVibMotorOff"] = {codepoint = 0xE6A8, description = "Metallophone (vibraphone motor off)"},
        ["pictVib"] = {codepoint = 0xE6A7, description = "Vibraphone"},
        ["pictTurnRightStem"] = {codepoint = 0xE809, description = "Combining turn right for stem"},
        ["pictTubaphone"] = {codepoint = 0xE6B2, description = "Tubaphone"},
        ["pictTomTomChinese"] = {codepoint = 0xE6D8, description = "Chinese tom-tom"},
        ["controlBeginPhrase"] = {codepoint = 0xE8E6, description = "Begin phrase"},
        ["pictTomTom"] = {codepoint = 0xE6D7, description = "Tom-tom"},
        ["pictTimpani"] = {codepoint = 0xE6D0, description = "Timpani"},
        ["timeSigFractionOneThird"] = {codepoint = 0xE09A, description = "Time signature fraction ⅓"},
        ["accSagittalSharp7v11kDown"] = {codepoint = 0xE352, description = "Sharp 7:11k-down"},
        ["pictThundersheet"] = {codepoint = 0xE744, description = "Thundersheet"},
        ["pictBeaterHand"] = {codepoint = 0xE7E3, description = "Hand"},
        ["pictTempleBlocks"] = {codepoint = 0xE6F1, description = "Temple blocks"},
        ["noteheadClusterQuarterTop"] = {codepoint = 0xE135, description = "Combining quarter note cluster, top"},
        ["accSagittal5TinasDown"] = {codepoint = 0xE401, description = "5 tinas down, 7⁴/25-schismina down, 0.72 cents down"},
        ["arrowBlackUpLeft"] = {codepoint = 0xEB67, description = "Black arrow up-left (NW)"},
        ["pictTamTamWithBeater"] = {codepoint = 0xE731, description = "Tam-tam with beater (Smith Brindle)"},
        ["pictTabla"] = {codepoint = 0xE6E3, description = "Indian tabla"},
        ["pictRightHandSquare"] = {codepoint = 0xE806, description = "Left hand (Agostini)"},
        ["pictSuperball"] = {codepoint = 0xE7B2, description = "Superball"},
        ["accSagittalSharp23SUp"] = {codepoint = 0xE3CE, description = "Sharp 23S-up"},
        ["oneHandedRollStevens"] = {codepoint = 0xE233, description = "One-handed roll (Stevens)"},
        ["pictSteelDrums"] = {codepoint = 0xE6AF, description = "Steel drums"},
        ["pictSnareDrumSnaresOff"] = {codepoint = 0xE6D2, description = "Snare drum, snares off"},
        ["wiggleVibratoSmallFastest"] = {codepoint = 0xEAD4, description = "Vibrato small, fastest"},
        ["flag16thUp"] = {codepoint = 0xE242, description = "Combining flag 2 (16th) above"},
        ["pictShellChimes"] = {codepoint = 0xE6C4, description = "Shell chimes"},
        ["pictShellBells"] = {codepoint = 0xE718, description = "Shell bells"},
        ["pictScrapeEdgeToCenter"] = {codepoint = 0xE7F2, description = "Scrape from edge to center"},
        ["accidentalThreeQuarterTonesFlatGrisey"] = {codepoint = 0xE486, description = "Three-quarter-tones flat (Grisey)"},
        ["smnSharpDown"] = {codepoint = 0xEC59, description = "Sharp stem down"},
        ["pictRim3"] = {codepoint = 0xE803, description = "Rim (Caltabiano)"},
        ["accidentalFilledReversedFlatAndFlatArrowUp"] = {codepoint = 0xE297, description = "Filled reversed flat and flat with arrow up"},
        ["pictBeaterGuiroScraper"] = {codepoint = 0xE7DD, description = "Guiro scraper"},
        ["pictRecoReco"] = {codepoint = 0xE6FC, description = "Reco-reco"},
        ["timeSigCutCommonTurned"] = {codepoint = 0xECEB, description = "Turned cut time"},
        ["pictRainstick"] = {codepoint = 0xE747, description = "Rainstick"},
        ["dynamicNienteForHairpin"] = {codepoint = 0xE541, description = "Niente (for hairpins)"},
        ["pictPoliceWhistle"] = {codepoint = 0xE752, description = "Police whistle"},
        ["pictPistolShot"] = {codepoint = 0xE760, description = "Pistol shot"},
        ["note128thDown"] = {codepoint = 0xE1E0, description = "128th note (semihemidemisemiquaver) stem down"},
        ["pictOpenRimShot"] = {codepoint = 0xE7F5, description = "Closed / rim shot"},
        ["pictNormalPosition"] = {codepoint = 0xE804, description = "Normal position (Caltabiano)"},
        ["pictMetalTubeChimes"] = {codepoint = 0xE6C7, description = "Metal tube chimes"},
        ["pictMetalPlateChimes"] = {codepoint = 0xE6C8, description = "Metal plate chimes"},
        ["kahnBallChange"] = {codepoint = 0xEDC6, description = "Ball-change"},
        ["pictMaracas"] = {codepoint = 0xE742, description = "Maracas"},
        ["kahnGraceTap"] = {codepoint = 0xEDA8, description = "Grace-tap"},
        ["miscDoNotCopy"] = {codepoint = 0xEC61, description = "Do not copy"},
        ["windRimOnly"] = {codepoint = 0xE60B, description = "Rim only"},
        ["pictLithophone"] = {codepoint = 0xE6B1, description = "Lithophone"},
        ["flag512thUp"] = {codepoint = 0xE24C, description = "Combining flag 7 (512th) above"},
        ["luteGermanVLower"] = {codepoint = 0xEC13, description = "1st course, 4th fret (v)"},
        ["pictKlaxonHorn"] = {codepoint = 0xE756, description = "Klaxon horn"},
        ["fermataVeryLongBelow"] = {codepoint = 0xE4C9, description = "Very long fermata below"},
        ["pictJingleBells"] = {codepoint = 0xE719, description = "Jingle bells"},
        ["pictJawHarp"] = {codepoint = 0xE767, description = "Jaw harp"},
        ["noteheadSlashedWhole1"] = {codepoint = 0xE0D3, description = "Slashed whole notehead (bottom left to top right)"},
        ["metNoteQuarterDown"] = {codepoint = 0xECA6, description = "Quarter note (crotchet) stem down"},
        ["luteFrenchFretC"] = {codepoint = 0xEBC2, description = "Second fret (c)"},
        ["pictHalfOpen2"] = {codepoint = 0xE7F7, description = "Half-open 2 (Weinberg)"},
        ["pictHalfOpen1"] = {codepoint = 0xE7F6, description = "Half-open"},
        ["pictBeaterWoodXylophoneRight"] = {codepoint = 0xE77E, description = "Wood xylophone stick right"},
        ["pictGumSoftUp"] = {codepoint = 0xE7BB, description = "Soft gum beater, up"},
        ["pictGumSoftRight"] = {codepoint = 0xE7BD, description = "Soft gum beater, right"},
        ["glissandoUp"] = {codepoint = 0xE585, description = "Glissando up"},
        ["noteheadSlashHorizontalEndsMuted"] = {codepoint = 0xE108, description = "Muted slash with horizontal ends"},
        ["noteheadDiamondBlackWide"] = {codepoint = 0xE0DC, description = "Diamond black notehead (wide)"},
        ["noteheadLargeArrowUpWhole"] = {codepoint = 0xE0EE, description = "Large arrow up (highest pitch) whole notehead"},
        ["arrowheadBlackLeft"] = {codepoint = 0xEB7E, description = "Black arrowhead left (W)"},
        ["noteGFlatWhole"] = {codepoint = 0xE17A, description = "G flat (whole note)"},
        ["functionSix"] = {codepoint = 0xEA76, description = "Function theory 6"},
        ["pictBeaterSuperballUp"] = {codepoint = 0xE7AE, description = "Superball beater up"},
        ["functionRing"] = {codepoint = 0xEA97, description = "Function theory prefix ring"},
        ["dynamicRinforzando2"] = {codepoint = 0xE53D, description = "Rinforzando 2"},
        ["accdnRH3RanksAuthenticMusette"] = {codepoint = 0xE8A8, description = "Right hand, 3 ranks, lower tremolo 8' stop + 8' stop + upper tremolo 8' stop (authentic musette)"},
        ["pictGumHardUp"] = {codepoint = 0xE7C3, description = "Hard gum beater, up"},
        ["pictGumHardRight"] = {codepoint = 0xE7C5, description = "Hard gum beater, right"},
        ["elecLineIn"] = {codepoint = 0xEB47, description = "Line in"},
        ["pictGumHardLeft"] = {codepoint = 0xE7C6, description = "Hard gum beater, left"},
        ["pictGongWithButton"] = {codepoint = 0xE733, description = "Gong with button (nipple)"},
        ["pictGlspSmithBrindle"] = {codepoint = 0xE6AA, description = "Glockenspiel (Smith Brindle)"},
        ["pictGlsp"] = {codepoint = 0xE6A0, description = "Glockenspiel"},
        ["pictGlassPlateChimes"] = {codepoint = 0xE6C6, description = "Glass plate chimes"},
        ["accidentalThreeQuarterTonesSharpStockhausen"] = {codepoint = 0xED5A, description = "Three-quarter-tones sharp (Stockhausen)"},
        ["pictGlassHarmonica"] = {codepoint = 0xE765, description = "Glass harmonica"},
        ["pictFlexatone"] = {codepoint = 0xE740, description = "Flexatone"},
        ["flag8thDown"] = {codepoint = 0xE241, description = "Combining flag 1 (8th) below"},
        ["noteBSharpWhole"] = {codepoint = 0xE16D, description = "B sharp (whole note)"},
        ["pictDamp4"] = {codepoint = 0xE7FC, description = "Damp 4"},
        ["accdnCombLH2RanksEmpty"] = {codepoint = 0xE8C8, description = "Combining left hand, 2 ranks, empty"},
        ["pictDamp3"] = {codepoint = 0xE7FB, description = "Damp 3"},
        ["accidentalFlatTwoArrowsUp"] = {codepoint = 0xE2D0, description = "Flat raised by two syntonic commas"},
        ["accidentalEnharmonicAlmostEqualTo"] = {codepoint = 0xE2FA, description = "Enharmonically reinterpret accidental almost equal to"},
        ["pictDamp1"] = {codepoint = 0xE7F9, description = "Damp"},
        ["chantEntryLineAsc6th"] = {codepoint = 0xE9B8, description = "Entry line, ascending 6th"},
        ["fretboard4StringNut"] = {codepoint = 0xE853, description = "4-string fretboard at nut"},
        ["noteShapeDiamondWhite"] = {codepoint = 0xE1B8, description = "Diamond white (4-shape mi; 7-shape mi)"},
        ["accdnRicochetStem5"] = {codepoint = 0xE8D5, description = "Combining ricochet for stem (5 tones)"},
        ["pictCuica"] = {codepoint = 0xE6E4, description = "Cuica"},
        ["accSagittalFlat11LDown"] = {codepoint = 0xE329, description = "Flat 11L-down, 8° up [46 EDO]"},
        ["noteGBlack"] = {codepoint = 0xE1A9, description = "G (black note)"},
        ["pictCrashCymbals"] = {codepoint = 0xE720, description = "Crash cymbals"},
        ["accSagittal7v11CommaUp"] = {codepoint = 0xE346, description = "7:11 comma up, (7:11C, ~13:17S, ~29S, 11L less 7C), 1° up [60 EDO]"},
        ["pluckedWithFingernails"] = {codepoint = 0xE636, description = "With fingernails"},
        ["pictClaves"] = {codepoint = 0xE6F2, description = "Claves"},
        ["noteheadClusterSquareBlack"] = {codepoint = 0xE121, description = "Cluster notehead black (square)"},
        ["brassScoop"] = {codepoint = 0xE5D0, description = "Scoop"},
        ["pictChokeCymbal"] = {codepoint = 0xE805, description = "Choke (Weinberg)"},
        ["kahnScuff"] = {codepoint = 0xEDDC, description = "Scuff"},
        ["pictChimes"] = {codepoint = 0xE6C2, description = "Chimes"},
        ["pictChainRattle"] = {codepoint = 0xE748, description = "Chain rattle"},
        ["timeSigBracketLeftSmall"] = {codepoint = 0xEC82, description = "Left bracket for numerator only"},
        ["pictCenter2"] = {codepoint = 0xE7FF, description = "Center (Ghent)"},
        ["stringsBowOnBridge"] = {codepoint = 0xE619, description = "Bow on top of bridge"},
        ["systemDivider"] = {codepoint = 0xE007, description = "System divider"},
        ["pictCarHorn"] = {codepoint = 0xE755, description = "Car horn"},
        ["pictCannon"] = {codepoint = 0xE761, description = "Cannon"},
        ["pictBeaterMediumXylophoneRight"] = {codepoint = 0xE776, description = "Medium xylophone stick right"},
        ["ornamentLeftPlus"] = {codepoint = 0xE597, description = "Ornament left +"},
        ["luteGermanKLower"] = {codepoint = 0xEC09, description = "1st course, 2nd fret (k)"},
        ["wiggleCircularSmall"] = {codepoint = 0xEACA, description = "Circular motion segment, small"},
        ["chantLigaturaDesc3rd"] = {codepoint = 0xE9BA, description = "Ligated stroke, descending 3rd"},
        ["pictBirdWhistle"] = {codepoint = 0xE751, description = "Bird whistle"},
        ["accSagittalFlat5v23SUp"] = {codepoint = 0xE377, description = "Flat 5:23S-up, 3° down [60 EDO], 3/10-tone down"},
        ["wiggleCircularLarge"] = {codepoint = 0xEAC8, description = "Circular motion segment, large"},
        ["timeSig0Turned"] = {codepoint = 0xECE0, description = "Turned time signature 0"},
        ["articMarcatoStaccatoBelow"] = {codepoint = 0xE4AF, description = "Marcato-staccato below"},
        ["chantConnectingLineAsc6th"] = {codepoint = 0xE9C1, description = "Connecting line, ascending 6th"},
        ["arrowBlackUp"] = {codepoint = 0xEB60, description = "Black arrow up (N)"},
        ["pictBellOfCymbal"] = {codepoint = 0xE72A, description = "Bell of cymbal"},
        ["dynamicRinforzando"] = {codepoint = 0xE523, description = "Rinforzando"},
        ["pictBell"] = {codepoint = 0xE714, description = "Bell"},
        ["pictBeaterWoodXylophoneDown"] = {codepoint = 0xE77D, description = "Wood xylophone stick down"},
        ["arrowheadWhiteDownLeft"] = {codepoint = 0xEB85, description = "White arrowhead down-left (SW)"},
        ["pictDeadNoteStem"] = {codepoint = 0xE80D, description = "Combining X for stem (dead note)"},
        ["stringsJeteBelow"] = {codepoint = 0xE621, description = "Jeté (gettato) below"},
        ["pictBeaterWireBrushesUp"] = {codepoint = 0xE7D7, description = "Wire brushes up"},
        ["pictBeaterTriangleUp"] = {codepoint = 0xE7D5, description = "Triangle beater up"},
        ["pictBeaterTrianglePlain"] = {codepoint = 0xE7EF, description = "Triangle beater plain"},
        ["organGerman2OctaveUp"] = {codepoint = 0xEE19, description = "Combining double octave line above"},
        ["pictBeaterSuperballRight"] = {codepoint = 0xE7B0, description = "Superball beater right"},
        ["pictBeaterSuperballLeft"] = {codepoint = 0xE7B1, description = "Superball beater left"},
        ["ornamentPrecompDoubleCadenceUpperPrefixTurn"] = {codepoint = 0xE5C4, description = "Double cadence with upper prefix and turn"},
        ["fingeringLeftBracket"] = {codepoint = 0xED2A, description = "Fingering left bracket"},
        ["pictBeaterSoftYarnUp"] = {codepoint = 0xE7A2, description = "Soft yarn beater up"},
        ["accSagittalFlat19CDown"] = {codepoint = 0xE3C9, description = "Flat 19C-down"},
        ["noteShapeRoundBlack"] = {codepoint = 0xE1B1, description = "Round black (4-shape sol; 7-shape so)"},
        ["pictBeaterHardBassDrumUp"] = {codepoint = 0xE79C, description = "Hard bass drum stick up"},
        ["accidentalNaturalThreeArrowsDown"] = {codepoint = 0xE2D6, description = "Natural lowered by three syntonic commas"},
        ["ornamentPrecompTrillWithMordent"] = {codepoint = 0xE5BD, description = "Trill with mordent"},
        ["mensuralBlackSemibrevisVoid"] = {codepoint = 0xE957, description = "Black mensural void semibrevis"},
        ["noteheadDiamondWhole"] = {codepoint = 0xE0D8, description = "Diamond whole notehead"},
        ["staffPosRaise6"] = {codepoint = 0xEB95, description = "Raise 6 staff positions"},
        ["pictBeaterSoftTimpaniUp"] = {codepoint = 0xE788, description = "Soft timpani stick up"},
        ["accidentalNaturalOneArrowDown"] = {codepoint = 0xE2C2, description = "Natural lowered by one syntonic comma"},
        ["pictBeaterSoftTimpaniDown"] = {codepoint = 0xE789, description = "Soft timpani stick down"},
        ["accidentalSims6Up"] = {codepoint = 0xE2A4, description = "1/6 tone high"},
        ["pictBeaterSoftGlockenspielRight"] = {codepoint = 0xE782, description = "Soft glockenspiel stick right"},
        ["fingeringRightBracket"] = {codepoint = 0xED2B, description = "Fingering right bracket"},
        ["harpTuningKeyShank"] = {codepoint = 0xE692, description = "Use shank of tuning key pictogram"},
        ["chantCirculusBelow"] = {codepoint = 0xE9D3, description = "Circulus below"},
        ["pictBeaterSoftGlockenspielLeft"] = {codepoint = 0xE783, description = "Soft glockenspiel stick left"},
        ["arrowBlackUpRight"] = {codepoint = 0xEB61, description = "Black arrow up-right (NE)"},
        ["pictBeaterSoftBassDrumUp"] = {codepoint = 0xE798, description = "Soft bass drum stick up"},
        ["dynamicCombinedSeparatorSpace"] = {codepoint = 0xE548, description = "Space separator for combined dynamics"},
        ["pictBeaterSoftBassDrumDown"] = {codepoint = 0xE799, description = "Soft bass drum stick down"},
        ["pictBeaterMetalUp"] = {codepoint = 0xE7C7, description = "Metal beater, up"},
        ["accSagittal49SmallDiesisDown"] = {codepoint = 0xE39D, description = "49 small diesis down"},
        ["pictBeaterMetalLeft"] = {codepoint = 0xE7CA, description = "Metal beater, left"},
        ["pictBeaterMetalDown"] = {codepoint = 0xE7C8, description = "Metal beater down"},
        ["pictBeaterMetalBassDrumUp"] = {codepoint = 0xE79E, description = "Metal bass drum stick up"},
        ["accSagittal2MinasUp"] = {codepoint = 0xE3F6, description = "2 minas up, 65/77-schismina up, 0.83 cents up"},
        ["kahnSlideTap"] = {codepoint = 0xEDB5, description = "Slide-tap"},
        ["pictBeaterMediumXylophoneUp"] = {codepoint = 0xE774, description = "Medium xylophone stick up"},
        ["pictBeaterMediumXylophoneLeft"] = {codepoint = 0xE777, description = "Medium xylophone stick left"},
        ["noteheadCowellNinthNoteSeriesWhole"] = {codepoint = 0xEEAA, description = "8/9 note (ninth note series, Cowell)"},
        ["pictBeaterMediumXylophoneDown"] = {codepoint = 0xE775, description = "Medium xylophone stick down"},
        ["medRenGClefCMN"] = {codepoint = 0xEA24, description = "G clef (Corpus Monodicum)"},
        ["fretboard3String"] = {codepoint = 0xE850, description = "3-string fretboard"},
        ["pictBeaterMediumTimpaniUp"] = {codepoint = 0xE78C, description = "Medium timpani stick up"},
        ["pictBeaterMediumTimpaniDown"] = {codepoint = 0xE78D, description = "Medium timpani stick down"},
        ["accidental5CommaSharp"] = {codepoint = 0xE453, description = "5-comma sharp"},
        ["noteLeHalf"] = {codepoint = 0xEEF0, description = "Le (half note)"},
        ["pictBeaterMediumBassDrumUp"] = {codepoint = 0xE79A, description = "Medium bass drum stick up"},
        ["pictBeaterMalletDown"] = {codepoint = 0xE7EC, description = "Chime hammer down"},
        ["pictBeaterKnittingNeedle"] = {codepoint = 0xE7E2, description = "Knitting needle"},
        ["noteLaHalf"] = {codepoint = 0xE15D, description = "La (half note)"},
        ["noteheadCowellEleventhNoteSeriesHalf"] = {codepoint = 0xEEAE, description = "4/11 note (eleventh note series, Cowell)"},
        ["pictBeaterJazzSticksUp"] = {codepoint = 0xE7D3, description = "Jazz sticks up"},
        ["pictBeaterJazzSticksDown"] = {codepoint = 0xE7D4, description = "Jazz sticks down"},
        ["dynamicForzando"] = {codepoint = 0xE535, description = "Forzando"},
        ["noteGHalf"] = {codepoint = 0xE192, description = "G (half note)"},
        ["accSagittal19CommaUp"] = {codepoint = 0xE398, description = "19 comma up, (19C)"},
        ["organGermanFisUpper"] = {codepoint = 0xEE06, description = "German organ tablature great Fis"},
        ["pictBeaterHardYarnDown"] = {codepoint = 0xE7AB, description = "Hard yarn beater down"},
        ["pictBeaterHardXylophoneUp"] = {codepoint = 0xE778, description = "Hard xylophone stick up"},
        ["accSagittalFlat5v7kDown"] = {codepoint = 0xE31D, description = "Flat 5:7k-down"},
        ["stem"] = {codepoint = 0xE210, description = "Combining stem"},
        ["noteFiWhole"] = {codepoint = 0xEEE4, description = "Fi (whole note)"},
        ["mensuralCombStemDown"] = {codepoint = 0xE93F, description = "Combining stem down"},
        ["pictBeaterHardXylophoneLeft"] = {codepoint = 0xE77B, description = "Hard xylophone stick left"},
        ["pictBeaterHardXylophoneDown"] = {codepoint = 0xE779, description = "Hard xylophone stick down"},
        ["accSagittal7v11CommaDown"] = {codepoint = 0xE347, description = "7:11 comma down, 1° down [60 EDO], 1/10-tone down"},
        ["noteheadTriangleUpDoubleWhole"] = {codepoint = 0xE0BA, description = "Triangle notehead up double whole"},
        ["noteDFlatHalf"] = {codepoint = 0xE188, description = "D flat (half note)"},
        ["noteheadDiamondHalf"] = {codepoint = 0xE0D9, description = "Diamond half notehead"},
        ["noteheadLargeArrowUpHalf"] = {codepoint = 0xE0EF, description = "Large arrow up (highest pitch) half notehead"},
        ["pictBeaterHardTimpaniUp"] = {codepoint = 0xE790, description = "Hard timpani stick up"},
        ["pictBeaterHardTimpaniLeft"] = {codepoint = 0xE793, description = "Hard timpani stick left"},
        ["pictBeaterHardTimpaniDown"] = {codepoint = 0xE791, description = "Hard timpani stick down"},
        ["noteheadSlashWhiteMuted"] = {codepoint = 0xE109, description = "Muted white slash"},
        ["pictBeaterHardGlockenspielUp"] = {codepoint = 0xE784, description = "Hard glockenspiel stick up"},
        ["pictBeaterHardGlockenspielRight"] = {codepoint = 0xE786, description = "Hard glockenspiel stick right"},
        ["pictBeaterHardGlockenspielLeft"] = {codepoint = 0xE787, description = "Hard glockenspiel stick left"},
        ["medRenLiquescentAscCMN"] = {codepoint = 0xEA26, description = "Liquescent ascending (Corpus Monodicum)"},
        ["noteFFlatBlack"] = {codepoint = 0xE1A5, description = "F flat (black note)"},
        ["accSagittalSharp19CDown"] = {codepoint = 0xE3B6, description = "Sharp 19C-down"},
        ["noteheadDoubleWhole"] = {codepoint = 0xE0A0, description = "Double whole (breve) notehead"},
        ["noteheadRoundWhiteSlashedLarge"] = {codepoint = 0xE117, description = "Large round white notehead, slashed"},
        ["kahnStep"] = {codepoint = 0xEDA0, description = "Step"},
        ["pictBeaterSoftYarnRight"] = {codepoint = 0xE7A4, description = "Soft yarn beater right"},
        ["accSagittalFlat23SDown"] = {codepoint = 0xE3CF, description = "Flat 23S-down"},
        ["accSagittal7v19CommaUp"] = {codepoint = 0xE39A, description = "7:19 comma up, (7:19C, 7C less 19s)"},
        ["noteShapeSquareDoubleWhole"] = {codepoint = 0xECD1, description = "Square double whole (4-shape la; Aikin 7-shape la)"},
        ["dynamicSforzando"] = {codepoint = 0xE524, description = "Sforzando"},
        ["pictBeaterHardBassDrumDown"] = {codepoint = 0xE79D, description = "Hard bass drum stick down"},
        ["pictTenorDrum"] = {codepoint = 0xE6D6, description = "Tenor drum"},
        ["pictBeaterHammerWoodUp"] = {codepoint = 0xE7CB, description = "Wooden hammer, up"},
        ["elecPowerOnOff"] = {codepoint = 0xEB2A, description = "Power on/off"},
        ["harpSalzedoAeolianDescending"] = {codepoint = 0xE696, description = "Descending aeolian chords (Salzedo)"},
        ["pictBeaterHammerMetalUp"] = {codepoint = 0xE7CF, description = "Metal hammer, up"},
        ["mensuralObliqueAsc4thBlackVoid"] = {codepoint = 0xE97A, description = "Oblique form, ascending 4th, black and void"},
        ["noteheadDiamondWholeOld"] = {codepoint = 0xE0E0, description = "Diamond whole notehead (old)"},
        ["mensuralObliqueAsc5thBlack"] = {codepoint = 0xE97C, description = "Oblique form, ascending 5th, black"},
        ["pictBeaterHammer"] = {codepoint = 0xE7E1, description = "Hammer"},
        ["pictRim1"] = {codepoint = 0xE801, description = "Rim or edge (Weinberg)"},
        ["pictBeaterFist"] = {codepoint = 0xE7E5, description = "Fist"},
        ["pictBeaterFinger"] = {codepoint = 0xE7E4, description = "Finger"},
        ["controlEndTie"] = {codepoint = 0xE8E3, description = "End tie"},
        ["noteheadClusterWholeMiddle"] = {codepoint = 0xE130, description = "Combining whole note cluster, middle"},
        ["pictBeaterHardYarnUp"] = {codepoint = 0xE7AA, description = "Hard yarn beater up"},
        ["pictBassDrumOnSide"] = {codepoint = 0xE6D5, description = "Bass drum on side"},
        ["pictBambooChimes"] = {codepoint = 0xE6C3, description = "Bamboo tube chimes"},
        ["pictAnvil"] = {codepoint = 0xE701, description = "Anvil"},
        ["ornamentPrecompTrillSuffixDandrieu"] = {codepoint = 0xE5BB, description = "Trill with two-note suffix (Dandrieu)"},
        ["accSagittalDoubleSharp143CDown"] = {codepoint = 0xE3EA, description = "Double sharp 143C-down"},
        ["pictAgogo"] = {codepoint = 0xE717, description = "Agogo"},
        ["noteheadCircledHalfLarge"] = {codepoint = 0xE0E9, description = "Half notehead in large circle"},
        ["pendereckiTremolo"] = {codepoint = 0xE22B, description = "Penderecki unmeasured tremolo"},
        ["ottavaBassaVb"] = {codepoint = 0xE51C, description = "Ottava bassa (8vb)"},
        ["ottavaBassa"] = {codepoint = 0xE512, description = "Ottava bassa"},
        ["beamAccelRit12"] = {codepoint = 0xEAFF, description = "Accel./rit. beam 12"},
        ["ottava"] = {codepoint = 0xE510, description = "Ottava"},
        ["noteGSharpWhole"] = {codepoint = 0xE17C, description = "G sharp (whole note)"},
        ["ornamentZigZagLineWithRightEnd"] = {codepoint = 0xE59E, description = "Ornament zig-zag line with right-hand end"},
        ["ornamentZigZagLineNoRightEnd"] = {codepoint = 0xE59D, description = "Ornament zig-zag line without right-hand end"},
        ["chantPunctumLineaCavum"] = {codepoint = 0xE99A, description = "Punctum linea cavum"},
        ["timeSigCut2"] = {codepoint = 0xEC85, description = "Cut time (Bach)"},
        ["mensuralCclefPetrucciPosHighest"] = {codepoint = 0xE90B, description = "Petrucci C clef, highest position"},
        ["ornamentPrecompSlideTrillMuffat"] = {codepoint = 0xE5B9, description = "Slide-trill (Muffat)"},
        ["gClefArrowDown"] = {codepoint = 0xE05B, description = "G clef, arrow down"},
        ["ornamentTurn"] = {codepoint = 0xE567, description = "Turn"},
        ["windVeryTightEmbouchure"] = {codepoint = 0xE601, description = "Very tight embouchure"},
        ["ornamentTremblement"] = {codepoint = 0xE56E, description = "Tremblement"},
        ["kahnDrawTap"] = {codepoint = 0xEDB3, description = "Draw-tap"},
        ["elecVolumeLevel0"] = {codepoint = 0xEB2E, description = "Volume level 0%"},
        ["accSagittal2TinasDown"] = {codepoint = 0xE3FB, description = "2 tinas down, 1/(7³⋅17)-schismina down, 0.30 cents down"},
        ["elecAudioChannelsThreeFrontal"] = {codepoint = 0xEB40, description = "Three channels (frontal)"},
        ["ornamentTopRightConcaveStroke"] = {codepoint = 0xE5A0, description = "Ornament top right concave stroke"},
        ["accidentalKomaFlat"] = {codepoint = 0xE443, description = "Koma (flat)"},
        ["elecMIDIIn"] = {codepoint = 0xEB34, description = "MIDI in"},
        ["ornamentTopLeftConvexStroke"] = {codepoint = 0xE591, description = "Ornament top left convex stroke"},
        ["ornamentShortTrill"] = {codepoint = 0xE56C, description = "Short trill"},
        ["ornamentShortObliqueLineAfterNote"] = {codepoint = 0xE57A, description = "Short oblique straight line NW-SE"},
        ["ornamentShakeMuffat1"] = {codepoint = 0xE584, description = "Shake (Muffat)"},
        ["ornamentShake3"] = {codepoint = 0xE582, description = "Shake"},
        ["note64thDown"] = {codepoint = 0xE1DE, description = "64th note (hemidemisemiquaver) stem down"},
        ["accSagittalFlat19CUp"] = {codepoint = 0xE3B7, description = "Flat 19C-up"},
        ["ornamentSchleifer"] = {codepoint = 0xE587, description = "Schleifer (long mordent)"},
        ["accSagittal1MinaDown"] = {codepoint = 0xE3F5, description = "1 mina down, 1/(5⋅7⋅13)-schismina down, 0.42 cents down"},
        ["chantPunctumVirga"] = {codepoint = 0xE996, description = "Punctum virga"},
        ["dynamicMessaDiVoce"] = {codepoint = 0xE540, description = "Messa di voce"},
        ["luteGermanCUpper"] = {codepoint = 0xEC19, description = "6th course, 3rd fret (C)"},
        ["ornamentPrecompTurnTrillDAnglebert"] = {codepoint = 0xE5B4, description = "Turn-trill (D'Anglebert)"},
        ["luteItalianFret6"] = {codepoint = 0xEBE6, description = "Sixth fret (6)"},
        ["pictAlmglocken"] = {codepoint = 0xE712, description = "Almglocken"},
        ["ornamentTurnUpS"] = {codepoint = 0xE56B, description = "Inverted turn up"},
        ["ornamentPrecompSlideTrillMarpurg"] = {codepoint = 0xE5B6, description = "Slide-trill with one-note suffix (Marpurg)"},
        ["guitarLeftHandTapping"] = {codepoint = 0xE840, description = "Left-hand tapping"},
        ["ornamentPrecompSlideTrillDAnglebert"] = {codepoint = 0xE5B5, description = "Slide-trill (D'Anglebert)"},
        ["ornamentPrecompSlideTrillBach"] = {codepoint = 0xE5B8, description = "Slide-trill with two-note suffix (J.S. Bach)"},
        ["ornamentPrecompPortDeVoixMordent"] = {codepoint = 0xE5BC, description = "Pre-beat port de voix followed by multiple mordent (Dandrieu)"},
        ["pictBeaterSpoonWoodenMallet"] = {codepoint = 0xE7DC, description = "Spoon-shaped wooden mallet"},
        ["ornamentPrecompDoubleCadenceUpperPrefix"] = {codepoint = 0xE5C3, description = "Double cadence with upper prefix"},
        ["kodalyHandDo"] = {codepoint = 0xEC40, description = "Do hand sign"},
        ["accSagittalFlat5CDown"] = {codepoint = 0xE31F, description = "Flat 5C-down, 4°[22 29] 5°[27 34 41] 6°[39 46 53] down, 7/12-tone down"},
        ["brassHarmonMuteStemHalfRight"] = {codepoint = 0xE5EA, description = "Harmon mute, stem extended, right"},
        ["ornamentPrecompCadence"] = {codepoint = 0xE5BE, description = "Cadence"},
        ["arrowWhiteUpLeft"] = {codepoint = 0xEB6F, description = "White arrow up-left (NW)"},
        ["ornamentPrecompAppoggTrill"] = {codepoint = 0xE5B2, description = "Supported appoggiatura trill"},
        ["harpSalzedoMetallicSounds"] = {codepoint = 0xE688, description = "Metallic sounds (Salzedo)"},
        ["figbassParensLeft"] = {codepoint = 0xEA6A, description = "Figured bass ("},
        ["ornamentPortDeVoixV"] = {codepoint = 0xE570, description = "Port de voix"},
        ["ornamentObliqueLineHorizAfterNote"] = {codepoint = 0xE580, description = "Oblique straight line tilted NW-SE"},
        ["accidentalKucukMucennebFlat"] = {codepoint = 0xE441, description = "Küçük mücenneb (flat)"},
        ["ornamentMordent"] = {codepoint = 0xE56D, description = "Mordent"},
        ["functionNine"] = {codepoint = 0xEA79, description = "Function theory 9"},
        ["accidentalFlatTwoArrowsDown"] = {codepoint = 0xE2CB, description = "Flat lowered by two syntonic commas"},
        ["metNote16thUp"] = {codepoint = 0xECA9, description = "16th note (semiquaver) stem up"},
        ["ornamentLowRightConvexStroke"] = {codepoint = 0xE5A6, description = "Ornament low right convex stroke"},
        ["accidentalArrowDown"] = {codepoint = 0xE27B, description = "Arrow down (lower by one quarter-tone)"},
        ["noteTeBlack"] = {codepoint = 0xEEFA, description = "Te (black note)"},
        ["ornamentLowLeftConvexStroke"] = {codepoint = 0xE599, description = "Ornament low left convex stroke"},
        ["ornamentLeftVerticalStrokeWithCross"] = {codepoint = 0xE595, description = "Ornament left vertical stroke with cross (+)"},
        ["ornamentLeftVerticalStroke"] = {codepoint = 0xE594, description = "Ornament left vertical stroke"},
        ["ornamentLeftFacingHook"] = {codepoint = 0xE574, description = "Left-facing hook"},
        ["ornamentLeftFacingHalfCircle"] = {codepoint = 0xE572, description = "Left-facing half circle"},
        ["ornamentHookBeforeNote"] = {codepoint = 0xE575, description = "Hook before note"},
        ["noteShapeTriangleRoundLeftBlack"] = {codepoint = 0xE1CB, description = "Triangle-round left black (Funk 7-shape ti)"},
        ["noteheadRectangularClusterBlackMiddle"] = {codepoint = 0xE143, description = "Combining black rectangular cluster, middle"},
        ["ornamentHookAfterNote"] = {codepoint = 0xE576, description = "Hook after note"},
        ["chantAugmentum"] = {codepoint = 0xE9D9, description = "Augmentum (mora)"},
        ["medRenLiquescentDescCMN"] = {codepoint = 0xEA27, description = "Liquescent descending (Corpus Monodicum)"},
        ["mensuralObliqueAsc5thWhite"] = {codepoint = 0xE97F, description = "Oblique form, ascending 5th, white"},
        ["ornamentHighLeftConvexStroke"] = {codepoint = 0xE593, description = "Ornament high left convex stroke"},
        ["noteheadSquareBlackLarge"] = {codepoint = 0xE11A, description = "Large square black notehead"},
        ["organGermanBLower"] = {codepoint = 0xEE16, description = "German organ tablature small B"},
        ["luteGermanMLower"] = {codepoint = 0xEC0B, description = "4th course, 3rd fret (m)"},
        ["ornamentHighLeftConcaveStroke"] = {codepoint = 0xE592, description = "Ornament high left concave stroke"},
        ["accSagittal17KleismaUp"] = {codepoint = 0xE392, description = "17 kleisma up, (17k)"},
        ["ornamentHaydn"] = {codepoint = 0xE56F, description = "Haydn ornament"},
        ["noteheadDiamondWhiteWide"] = {codepoint = 0xE0DE, description = "Diamond white notehead (wide)"},
        ["ornamentDownCurve"] = {codepoint = 0xE578, description = "Curve below"},
        ["ornamentComma"] = {codepoint = 0xE581, description = "Comma"},
        ["metNote64thDown"] = {codepoint = 0xECAE, description = "64th note (hemidemisemiquaver) stem down"},
        ["noteCHalf"] = {codepoint = 0xE186, description = "C (half note)"},
        ["chantEntryLineAsc5th"] = {codepoint = 0xE9B7, description = "Entry line, ascending 5th"},
        ["noteBWhole"] = {codepoint = 0xE16C, description = "B (whole note)"},
        ["accdnLH2RanksMasterPlus16Round"] = {codepoint = 0xE8BF, description = "Left hand, 2 ranks, master + 16' stop (round)"},
        ["mensuralCombStemDiagonal"] = {codepoint = 0xE940, description = "Combining stem diagonal"},
        ["accidentalCombiningLower17Schisma"] = {codepoint = 0xE2E6, description = "Combining lower by one 17-limit schisma"},
        ["accidentalOneAndAHalfSharpsArrowUp"] = {codepoint = 0xE29B, description = "One and a half sharps with arrow up"},
        ["chantLigaturaDesc2nd"] = {codepoint = 0xE9B9, description = "Ligated stroke, descending 2nd"},
        ["dynamicHairpinParenthesisRight"] = {codepoint = 0xE543, description = "Right parenthesis (for hairpins)"},
        ["mensuralWhiteSemibrevis"] = {codepoint = 0xE962, description = "White mensural semibrevis"},
        ["ornamentBottomRightConcaveStroke"] = {codepoint = 0xE5A7, description = "Ornament bottom right concave stroke"},
        ["ornamentBottomLeftConvexStroke"] = {codepoint = 0xE59C, description = "Ornament bottom left convex stroke"},
        ["ornamentBottomLeftConcaveStrokeLarge"] = {codepoint = 0xE59B, description = "Ornament bottom left concave stroke, large"},
        ["accidentalCombiningLower37Quartertone"] = {codepoint = 0xEE52, description = "Combining lower by one 37-limit quartertone"},
        ["accdnRH3RanksLowerTremolo8"] = {codepoint = 0xE8A3, description = "Right hand, 3 ranks, lower tremolo 8' stop"},
        ["organGermanSemiminimaRest"] = {codepoint = 0xEE21, description = "Semiminima Rest"},
        ["organGerman4Semifusae"] = {codepoint = 0xEE37, description = "Four Semifusae"},
        ["guitarString8"] = {codepoint = 0xE83B, description = "String number 8"},
        ["organGermanSemiminima"] = {codepoint = 0xEE29, description = "Semiminima"},
        ["stringsBowBehindBridge"] = {codepoint = 0xE618, description = "Bow behind bridge (sul ponticello)"},
        ["organGermanMinimaRest"] = {codepoint = 0xEE20, description = "Minima Rest"},
        ["restHBarMiddle"] = {codepoint = 0xE4F0, description = "H-bar, middle"},
        ["mensuralBlackBrevisVoid"] = {codepoint = 0xE956, description = "Black mensural void brevis"},
        ["accidentalFlatTurned"] = {codepoint = 0xE484, description = "Turned flat"},
        ["timeSig7Reversed"] = {codepoint = 0xECF7, description = "Reversed time signature 7"},
        ["elecLineOut"] = {codepoint = 0xEB48, description = "Line out"},
        ["accSagittalSharp"] = {codepoint = 0xE318, description = "Sharp, (apotome up)[almost all EDOs], 1/2-tone up"},
        ["organGermanGisLower"] = {codepoint = 0xEE14, description = "German organ tablature small Gis"},
        ["organGermanGLower"] = {codepoint = 0xEE13, description = "German organ tablature small G"},
        ["accSagittalDoubleFlat55CUp"] = {codepoint = 0xE363, description = "Double flat 55C-up, 13° down [96 EDO], 13/16-tone down"},
        ["kodalyHandMi"] = {codepoint = 0xEC42, description = "Mi hand sign"},
        ["wiggleGlissandoGroup1"] = {codepoint = 0xEABD, description = "Group glissando 1"},
        ["pictBeaterHardYarnLeft"] = {codepoint = 0xE7AD, description = "Hard yarn beater left"},
        ["dalSegno"] = {codepoint = 0xE045, description = "Dal segno"},
        ["organGermanFLower"] = {codepoint = 0xEE11, description = "German organ tablature small F"},
        ["organGermanEUpper"] = {codepoint = 0xEE04, description = "German organ tablature great E"},
        ["noteShapeKeystoneWhite"] = {codepoint = 0xE1C0, description = "Inverted keystone white (Walker 7-shape do)"},
        ["daseianFinales1"] = {codepoint = 0xEA34, description = "Daseian finales 1"},
        ["accidentalWyschnegradsky6TwelfthsFlat"] = {codepoint = 0xE430, description = "1/2 tone flat"},
        ["accdnLH2Ranks8Plus16Round"] = {codepoint = 0xE8BD, description = "Left hand, 2 ranks, 8' stop + 16' stop (round)"},
        ["organGermanDisUpper"] = {codepoint = 0xEE03, description = "German organ tablature great Dis"},
        ["4stringTabClef"] = {codepoint = 0xE06E, description = "4-string tab clef"},
        ["accSagittalAcute"] = {codepoint = 0xE3F2, description = "Acute, 5 schisma up (5s), 2 cents up"},
        ["noteESharpBlack"] = {codepoint = 0xE1A4, description = "E sharp (black note)"},
        ["fingeringXLower"] = {codepoint = 0xED1D, description = "Fingering x (right-hand little finger for guitar)"},
        ["lyricsElisionNarrow"] = {codepoint = 0xE550, description = "Narrow elision"},
        ["smnSharpWhite"] = {codepoint = 0xEC51, description = "Sharp (white) stem up"},
        ["metNoteHalfUp"] = {codepoint = 0xECA3, description = "Half note (minim) stem up"},
        ["staff5Lines"] = {codepoint = 0xE014, description = "5-line staff"},
        ["organGermanBuxheimerSemibrevisRest"] = {codepoint = 0xEE1D, description = "Semibrevis Rest Buxheimer Orgelbuch"},
        ["scaleDegree2"] = {codepoint = 0xEF01, description = "Scale degree 2"},
        ["organGermanBuxheimerMinimaRest"] = {codepoint = 0xEE1E, description = "Minima Rest Buxheimer Orgelbuch"},
        ["accidentalOneQuarterToneSharpStockhausen"] = {codepoint = 0xED58, description = "One-quarter-tone sharp (Stockhausen)"},
        ["lyricsHyphenBaselineNonBreaking"] = {codepoint = 0xE554, description = "Non-breaking baseline hyphen"},
        ["accidentalHabaSharpQuarterToneLower"] = {codepoint = 0xEE68, description = "Quarter-tone lower (Alois Hába)"},
        ["organGermanHLower"] = {codepoint = 0xEE17, description = "German organ tablature small H"},
        ["fingeringOLower"] = {codepoint = 0xED1F, description = "Fingering o (right-hand little finger for guitar)"},
        ["textCont8thBeamShortStem"] = {codepoint = 0xE1F7, description = "Continuing 8th beam for short stem"},
        ["arrowOpenUpLeft"] = {codepoint = 0xEB77, description = "Open arrow up-left (NW)"},
        ["organGermanAUpper"] = {codepoint = 0xEE09, description = "German organ tablature great A"},
        ["accSagittalSharp11MUp"] = {codepoint = 0xE326, description = "Sharp 11M-up, 3° up [17 31 EDOs], 7° up [46 EDO], 3/4-tone up"},
        ["organGerman6Semifusae"] = {codepoint = 0xEE3F, description = "Six Semifusae"},
        ["accidentalQuarterToneSharpStein"] = {codepoint = 0xE282, description = "Half sharp (quarter-tone sharp) (Stein)"},
        ["organGerman6Fusae"] = {codepoint = 0xEE3E, description = "Six Fusae"},
        ["accdnRH3RanksUpperTremolo8"] = {codepoint = 0xE8A2, description = "Right hand, 3 ranks, upper tremolo 8' stop"},
        ["noteSeWhole"] = {codepoint = 0xEEE5, description = "Se (whole note)"},
        ["organGerman5Fusae"] = {codepoint = 0xEE3A, description = "Five Fusae"},
        ["organGerman4Semiminimae"] = {codepoint = 0xEE35, description = "Four Semiminimae"},
        ["organGerman2Semifusae"] = {codepoint = 0xEE2F, description = "Two Semifusae"},
        ["organGerman3Fusae"] = {codepoint = 0xEE32, description = "Three Fusae"},
        ["organGerman3Minimae"] = {codepoint = 0xEE30, description = "Three Minimae"},
        ["fClef15mb"] = {codepoint = 0xE063, description = "F clef quindicesima bassa"},
        ["gClef15mb"] = {codepoint = 0xE051, description = "G clef quindicesima bassa"},
        ["organGerman2Fusae"] = {codepoint = 0xEE2E, description = "Two Fusae"},
        ["octaveSuperscriptM"] = {codepoint = 0xEC96, description = "m (superscript)"},
        ["elecDataOut"] = {codepoint = 0xEB4E, description = "Data out"},
        ["octaveSuperscriptA"] = {codepoint = 0xEC92, description = "a (superscript)"},
        ["octaveLoco"] = {codepoint = 0xEC90, description = "Loco"},
        ["kahnLeftCatch"] = {codepoint = 0xEDBF, description = "Left-catch"},
        ["octaveBaselineV"] = {codepoint = 0xEC97, description = "v (baseline)"},
        ["chantCclef"] = {codepoint = 0xE906, description = "Plainchant C clef"},
        ["octaveBaselineA"] = {codepoint = 0xEC91, description = "a (baseline)"},
        ["noteheadXOrnateEllipse"] = {codepoint = 0xE0AB, description = "Ornate X notehead in ellipse"},
        ["noteheadXHalf"] = {codepoint = 0xE0A8, description = "X notehead half"},
        ["windThreeQuartersClosedHole"] = {codepoint = 0xE5F5, description = "Three-quarters closed hole"},
        ["noteheadWholeWithX"] = {codepoint = 0xE0B5, description = "Whole notehead with X"},
        ["noteheadVoidWithX"] = {codepoint = 0xE0B7, description = "Void notehead with X"},
        ["noteheadTriangleUpWhite"] = {codepoint = 0xE0BD, description = "Triangle notehead up white"},
        ["noteheadTriangleRoundDownBlack"] = {codepoint = 0xE0CD, description = "Triangle-round notehead down black"},
        ["breathMarkUpbow"] = {codepoint = 0xE4D0, description = "Breath mark (upbow-like)"},
        ["functionParensRight"] = {codepoint = 0xEA92, description = "Function theory parenthesis right"},
        ["mensuralProlationCombiningTwoDots"] = {codepoint = 0xE921, description = "Combining two dots"},
        ["accSagittalDoubleSharp7v11CDown"] = {codepoint = 0xE360, description = "Double sharp 7:11C-down, 9° up [60 EDO], 9/10-tone up"},
        ["wiggleVibratoStart"] = {codepoint = 0xEACC, description = "Vibrato start"},
        ["stringsThumbPositionTurned"] = {codepoint = 0xE625, description = "Turned thumb position"},
        ["mensuralFclefPetrucci"] = {codepoint = 0xE904, description = "Petrucci F clef"},
        ["elecAudioChannelsThreeSurround"] = {codepoint = 0xEB41, description = "Three channels (surround)"},
        ["elecSkipBackwards"] = {codepoint = 0xEB22, description = "Skip backwards"},
        ["arrowheadOpenDownLeft"] = {codepoint = 0xEB8D, description = "Open arrowhead down-left (SW)"},
        ["chantDivisioMaxima"] = {codepoint = 0xE8F5, description = "Divisio maxima"},
        ["noteheadCowellThirdNoteSeriesWhole"] = {codepoint = 0xEEA1, description = "2/3 note (third note series, Cowell)"},
        ["arrowheadBlackDown"] = {codepoint = 0xEB7C, description = "Black arrowhead down (S)"},
        ["elecAudioOut"] = {codepoint = 0xEB4A, description = "Audio out"},
        ["accdnLH2RanksFullMasterRound"] = {codepoint = 0xE8C0, description = "Left hand, 2 ranks, full master (round)"},
        ["accidentalDoubleSharp"] = {codepoint = 0xE263, description = "Double sharp"},
        ["dynamicCombinedSeparatorSlash"] = {codepoint = 0xE549, description = "Slash separator for combined dynamics"},
        ["noteEWhole"] = {codepoint = 0xE175, description = "E (whole note)"},
        ["elecAudioChannelsFour"] = {codepoint = 0xEB42, description = "Four channels"},
        ["noteheadClusterQuarterBottom"] = {codepoint = 0xE137, description = "Combining quarter note cluster, bottom"},
        ["conductorBeat3Compound"] = {codepoint = 0xE898, description = "Beat 3, compound time"},
        ["tremoloFingered4"] = {codepoint = 0xE228, description = "Fingered tremolo 4"},
        ["noteheadTriangleLeftWhite"] = {codepoint = 0xE0BF, description = "Triangle notehead left white"},
        ["accSagittal19CommaDown"] = {codepoint = 0xE399, description = "19 comma down"},
        ["dynamicMP"] = {codepoint = 0xE52C, description = "mp"},
        ["noteWhole"] = {codepoint = 0xE1D2, description = "Whole note (semibreve)"},
        ["rightRepeatSmall"] = {codepoint = 0xE04D, description = "Right repeat sign within bar"},
        ["barlineDashed"] = {codepoint = 0xE036, description = "Dashed barline"},
        ["noteShapeMoonDoubleWhole"] = {codepoint = 0xECD6, description = "Moon double whole (Aikin 7-shape re)"},
        ["pictCymbalTongs"] = {codepoint = 0xE728, description = "Cymbal tongs"},
        ["stringsUpBowTowardsBody"] = {codepoint = 0xEE81, description = "Up bow, towards body"},
        ["noteheadDoubleWholeWithX"] = {codepoint = 0xE0B4, description = "Double whole notehead with X"},
        ["luteDuration8th"] = {codepoint = 0xEBAA, description = "Eighth note (quaver) duration sign"},
        ["chantDivisioFinalis"] = {codepoint = 0xE8F6, description = "Divisio finalis"},
        ["mensuralWhiteMinima"] = {codepoint = 0xE95F, description = "White mensural minima"},
        ["daseianGraves4"] = {codepoint = 0xEA33, description = "Daseian graves 4"},
        ["beamAccelRit4"] = {codepoint = 0xEAF7, description = "Accel./rit. beam 4"},
        ["noteQuarterDown"] = {codepoint = 0xE1D6, description = "Quarter note (crotchet) stem down"},
        ["chantPunctumInclinatum"] = {codepoint = 0xE991, description = "Punctum inclinatum"},
        ["curlewSign"] = {codepoint = 0xE4D6, description = "Curlew (Britten)"},
        ["flagInternalUp"] = {codepoint = 0xE250, description = "Internal combining flag above"},
        ["kahnFlap"] = {codepoint = 0xEDD5, description = "Flap"},
        ["csymMinor"] = {codepoint = 0xE874, description = "Minor"},
        ["accidentalWyschnegradsky9TwelfthsSharp"] = {codepoint = 0xE428, description = "3/4 tone sharp"},
        ["functionVUpper"] = {codepoint = 0xEA8D, description = "Function theory V"},
        ["kahnTap"] = {codepoint = 0xEDA1, description = "Tap"},
        ["accidentalHabaQuarterToneHigher"] = {codepoint = 0xEE64, description = "Quarter-tone higher (Alois Hába)"},
        ["note512thDown"] = {codepoint = 0xE1E4, description = "512th note (hemidemisemihemidemisemiquaver) stem down"},
        ["noteHWhole"] = {codepoint = 0xE17D, description = "H (whole note)"},
        ["mensuralBlackMinimaVoid"] = {codepoint = 0xE958, description = "Black mensural void minima"},
        ["repeatLeft"] = {codepoint = 0xE040, description = "Left (start) repeat sign"},
        ["functionGLower"] = {codepoint = 0xEA84, description = "Function theory g"},
        ["noteHHalf"] = {codepoint = 0xE194, description = "H (half note)"},
        ["controlBeginSlur"] = {codepoint = 0xE8E4, description = "Begin slur"},
        ["staff4LinesNarrow"] = {codepoint = 0xE01F, description = "4-line staff (narrow)"},
        ["accSagittalDoubleSharp7v11kDown"] = {codepoint = 0xE366, description = "Double sharp 7:11k-down"},
        ["accdnLH2Ranks8Round"] = {codepoint = 0xE8BB, description = "Left hand, 2 ranks, 8' stop (round)"},
        ["noteFSharpWhole"] = {codepoint = 0xE179, description = "F sharp (whole note)"},
        ["noteheadLargeArrowUpBlack"] = {codepoint = 0xE0F0, description = "Large arrow up (highest pitch) black notehead"},
        ["restHalfLegerLine"] = {codepoint = 0xE4F5, description = "Half rest on leger line"},
        ["noteDiBlack"] = {codepoint = 0xEEF2, description = "Di (black note)"},
        ["mensuralProlationCombiningThreeDots"] = {codepoint = 0xE922, description = "Combining three dots horizontal"},
        ["noteGFlatBlack"] = {codepoint = 0xE1A8, description = "G flat (black note)"},
        ["mensuralGclef"] = {codepoint = 0xE900, description = "Mensural G clef"},
        ["mensuralObliqueDesc3rdBlackVoid"] = {codepoint = 0xE986, description = "Oblique form, descending 3rd, black and void"},
        ["pictXylSmithBrindle"] = {codepoint = 0xE6AB, description = "Xylophone (Smith Brindle)"},
        ["figbassFlat"] = {codepoint = 0xEA64, description = "Figured bass flat"},
        ["kahnRiff"] = {codepoint = 0xEDE0, description = "Riff"},
        ["accSagittalFlat11v19MDown"] = {codepoint = 0xE3D3, description = "Flat 11:19M-down"},
        ["luteGermanPLower"] = {codepoint = 0xEC0E, description = "1st course, 3rd fret (p)"},
        ["chantPunctumVirgaReversed"] = {codepoint = 0xE997, description = "Punctum virga, reversed"},
        ["brassHarmonMuteClosed"] = {codepoint = 0xE5E8, description = "Harmon mute, stem in"},
        ["accidentalDoubleFlatEqualTempered"] = {codepoint = 0xE2F0, description = "Double flat equal tempered semitone"},
        ["noteEBlack"] = {codepoint = 0xE1A3, description = "E (black note)"},
        ["csymAccidentalSharp"] = {codepoint = 0xED62, description = "Sharp"},
        ["chantPunctum"] = {codepoint = 0xE990, description = "Punctum"},
        ["pictBeaterMediumYarnLeft"] = {codepoint = 0xE7A9, description = "Medium yarn beater left"},
        ["note1024thDown"] = {codepoint = 0xE1E6, description = "1024th note (semihemidemisemihemidemisemiquaver) stem down"},
        ["analyticsChoralmelodie"] = {codepoint = 0xE86A, description = "Choralmelodie (Berg)"},
        ["accidentalQuarterToneSharpBusotti"] = {codepoint = 0xE472, description = "Quarter tone sharp (Bussotti)"},
        ["accidentalCombiningRaise23Limit29LimitComma"] = {codepoint = 0xE2EB, description = "Combining raise by one 23-limit comma"},
        ["noteCFlatBlack"] = {codepoint = 0xE19C, description = "C flat (black note)"},
        ["articTenutoAccentBelow"] = {codepoint = 0xE4B5, description = "Tenuto-accent below"},
        ["luteFrenchFretD"] = {codepoint = 0xEBC3, description = "Third fret (d)"},
        ["accSagittal19SchismaUp"] = {codepoint = 0xE390, description = "19 schisma up, (19s)"},
        ["pictRim2"] = {codepoint = 0xE802, description = "Rim (Ghent)"},
        ["noteBFlatHalf"] = {codepoint = 0xE182, description = "B flat (half note)"},
        ["cClefSquare"] = {codepoint = 0xE060, description = "C clef (19th century)"},
        ["organGermanDLower"] = {codepoint = 0xEE0E, description = "German organ tablature small D"},
        ["fingering0"] = {codepoint = 0xED10, description = "Fingering 0 (open string)"},
        ["noteRiWhole"] = {codepoint = 0xEEE1, description = "Ri (whole note)"},
        ["arrowWhiteDownLeft"] = {codepoint = 0xEB6D, description = "White arrow down-left (SW)"},
        ["kahnDrawStep"] = {codepoint = 0xEDB2, description = "Draw-step"},
        ["accSagittalFlat5v23SDown"] = {codepoint = 0xE381, description = "Flat 5:23S-down, 7° down [60 EDO], 7/10-tone down"},
        ["elecAudioMono"] = {codepoint = 0xEB3C, description = "Mono audio setup"},
        ["noteAFlatBlack"] = {codepoint = 0xE196, description = "A flat (black note)"},
        ["bridgeClef"] = {codepoint = 0xE078, description = "Bridge clef"},
        ["miscDoNotPhotocopy"] = {codepoint = 0xEC60, description = "Do not photocopy"},
        ["accidentalFilledReversedFlatArrowUp"] = {codepoint = 0xE292, description = "Filled reversed flat with arrow up"},
        ["figbass0"] = {codepoint = 0xEA50, description = "Figured bass 0"},
        ["arrowOpenDownRight"] = {codepoint = 0xEB73, description = "Open arrow down-right (SE)"},
        ["noteheadSlashWhiteHalf"] = {codepoint = 0xE103, description = "White slash half"},
        ["kahnKneeOutward"] = {codepoint = 0xEDAC, description = "Knee-outward"},
        ["accidentalCombiningRaise31Schisma"] = {codepoint = 0xE2ED, description = "Combining raise by one 31-limit schisma"},
        ["luteDuration32nd"] = {codepoint = 0xEBAC, description = "32nd note (demisemiquaver) duration sign"},
        ["accSagittalDoubleFlat23CUp"] = {codepoint = 0xE387, description = "Double flat 23C-up, 14° down [96 EDO], 7/8-tone down"},
        ["breathMarkSalzedo"] = {codepoint = 0xE4D5, description = "Breath mark (Salzedo)"},
        ["accSagittal5v13LargeDiesisUp"] = {codepoint = 0xE3AC, description = "5:13 large diesis up, (5:13L, ~37L, apotome less 5:13M)"},
        ["breathMarkComma"] = {codepoint = 0xE4CE, description = "Breath mark (comma)"},
        ["accSagittalFlat35LDown"] = {codepoint = 0xE32B, description = "Flat 35L-down, 5° down [50 EDO]"},
        ["fingeringILower"] = {codepoint = 0xED19, description = "Fingering i (indicio; right-hand index finger for guitar)"},
        ["brassMuteHalfClosed"] = {codepoint = 0xE5E6, description = "Half-muted (half-closed)"},
        ["organGermanTie"] = {codepoint = 0xEE1B, description = "Tie"},
        ["elecVolumeLevel60"] = {codepoint = 0xEB31, description = "Volume level 60%"},
        ["guitarString2"] = {codepoint = 0xE835, description = "String number 2"},
        ["accSagittal11v19LargeDiesisDown"] = {codepoint = 0xE3AB, description = "11:19 large diesis down"},
        ["brassFallRoughMedium"] = {codepoint = 0xE5DE, description = "Rough fall, medium"},
        ["ornamentObliqueLineAfterNote"] = {codepoint = 0xE57C, description = "Oblique straight line NW-SE"},
        ["accSagittalSharp23CDown"] = {codepoint = 0xE37A, description = "Sharp 23C-down, 6° up [96 EDO], 3/8-tone up"},
        ["accidentalThreeQuarterTonesFlatArabic"] = {codepoint = 0xED31, description = "Arabic three-quarter-tones flat"},
        ["pictGumMediumUp"] = {codepoint = 0xE7BF, description = "Medium gum beater, up"},
        ["accSagittal55CommaUp"] = {codepoint = 0xE344, description = "55 comma up, (55C, 11M less 5C), 3°up [96 EDO], 3/16-tone up"},
        ["accidentalFlatThreeArrowsDown"] = {codepoint = 0xE2D5, description = "Flat lowered by three syntonic commas"},
        ["articStaccatissimoStrokeAbove"] = {codepoint = 0xE4AA, description = "Staccatissimo stroke above"},
        ["accidentalQuarterToneFlatVanBlankenburg"] = {codepoint = 0xE488, description = "Quarter-tone flat (van Blankenburg)"},
        ["beamAccelRit6"] = {codepoint = 0xEAF9, description = "Accel./rit. beam 6"},
        ["chantPunctumCavum"] = {codepoint = 0xE998, description = "Punctum cavum"},
        ["note8thDown"] = {codepoint = 0xE1D8, description = "Eighth note (quaver) stem down"},
        ["accSagittalSharp19sDown"] = {codepoint = 0xE3BE, description = "Sharp 19s-down"},
        ["handbellsMutedMartellato"] = {codepoint = 0xE813, description = "Muted martellato"},
        ["timeSig7Turned"] = {codepoint = 0xECE7, description = "Turned time signature 7"},
        ["fermataVeryShortBelow"] = {codepoint = 0xE4C3, description = "Very short fermata below"},
        ["mensuralProlation3"] = {codepoint = 0xE912, description = "Tempus perfectum cum prolatione imperfecta diminution 1 (3/8)"},
        ["mensuralNoteheadMinimaWhite"] = {codepoint = 0xE93C, description = "Minima notehead, white"},
        ["fretboardX"] = {codepoint = 0xE859, description = "String not played (X)"},
        ["chantCustosStemDownPosHighest"] = {codepoint = 0xEA09, description = "Plainchant custos, stem down, highest position"},
        ["mensuralObliqueDesc4thBlackVoid"] = {codepoint = 0xE98A, description = "Oblique form, descending 4th, black and void"},
        ["mensuralObliqueDesc2ndWhite"] = {codepoint = 0xE983, description = "Oblique form, descending 2nd, white"},
        ["elecAudioChannelsTwo"] = {codepoint = 0xEB3F, description = "Two channels (stereo)"},
        ["barlineHeavy"] = {codepoint = 0xE034, description = "Heavy barline"},
        ["caesuraThick"] = {codepoint = 0xE4D2, description = "Thick caesura"},
        ["articStaccatoAbove"] = {codepoint = 0xE4A2, description = "Staccato above"},
        ["analyticsTheme1"] = {codepoint = 0xE868, description = "Theme 1"},
        ["noteheadClusterHalfMiddle"] = {codepoint = 0xE133, description = "Combining half note cluster, middle"},
        ["pictBeaterHammerMetalDown"] = {codepoint = 0xE7D0, description = "Metal hammer, down"},
        ["articSoftAccentTenutoStaccatoBelow"] = {codepoint = 0xED47, description = "Soft accent-tenuto-staccato below"},
        ["accidentalWyschnegradsky7TwelfthsFlat"] = {codepoint = 0xE431, description = "7/12 tone flat"},
        ["noteheadSlashedWhole2"] = {codepoint = 0xE0D4, description = "Slashed whole notehead (top left to bottom right)"},
        ["kahnToeClick"] = {codepoint = 0xEDBC, description = "Toe-click"},
        ["articAccentBelow"] = {codepoint = 0xE4A1, description = "Accent below"},
        ["accSagittalSharp7v11kUp"] = {codepoint = 0xE354, description = "Sharp 7:11k-up"},
        ["elecAudioIn"] = {codepoint = 0xEB49, description = "Audio in"},
        ["noteheadSlashedHalf2"] = {codepoint = 0xE0D2, description = "Slashed half notehead (top left to bottom right)"},
        ["handbellsMartellato"] = {codepoint = 0xE810, description = "Martellato"},
        ["handbellsBelltree"] = {codepoint = 0xE81F, description = "Belltree"},
        ["staffDivideArrowDown"] = {codepoint = 0xE00B, description = "Staff divide arrow down"},
        ["accidentalWyschnegradsky2TwelfthsSharp"] = {codepoint = 0xE421, description = "1/6 tone sharp"},
        ["functionVLower"] = {codepoint = 0xEA8E, description = "Function theory v"},
        ["figbass4Raised"] = {codepoint = 0xEA56, description = "Figured bass 4 raised by half-step"},
        ["accdnRH4RanksSoftTenor"] = {codepoint = 0xE8B9, description = "Right hand, 4 ranks, soft tenor"},
        ["kahnWing"] = {codepoint = 0xEDE9, description = "Wing"},
        ["stringsTripleChopOutward"] = {codepoint = 0xEE8B, description = "Triple chop, outward"},
        ["csymParensLeftVeryTall"] = {codepoint = 0xE879, description = "Triple-height left parenthesis"},
        ["accidentalThreeQuarterTonesFlatArrowUp"] = {codepoint = 0xE278, description = "Three-quarter-tones flat"},
        ["accSagittalSharp19sUp"] = {codepoint = 0xE3C0, description = "Sharp 19s-up"},
        ["kievanNoteQuarterStemUp"] = {codepoint = 0xEC37, description = "Kievan quarter note, stem up"},
        ["analyticsHauptstimme"] = {codepoint = 0xE860, description = "Hauptstimme"},
        ["kahnGraceTapStamp"] = {codepoint = 0xEDD3, description = "Grace-tap-stamp"},
        ["dynamicFFF"] = {codepoint = 0xE530, description = "fff"},
        ["noteTiBlack"] = {codepoint = 0xE166, description = "Ti (black note)"},
        ["mensuralObliqueDesc3rdVoid"] = {codepoint = 0xE985, description = "Oblique form, descending 3rd, void"},
        ["accidentalWyschnegradsky8TwelfthsFlat"] = {codepoint = 0xE432, description = "2/3 tone flat"},
        ["luteGermanHLower"] = {codepoint = 0xEC07, description = "3rd course, 2nd fret (h)"},
        ["accidentalSims12Up"] = {codepoint = 0xE2A3, description = "1/12 tone high"},
        ["smnHistoryDoubleSharp"] = {codepoint = 0xEC55, description = "Double sharp history sign"},
        ["accSagittalSharp5v7kDown"] = {codepoint = 0xE316, description = "Sharp 5:7k-down"},
        ["accidentalNaturalArabic"] = {codepoint = 0xED34, description = "Arabic natural"},
        ["kahnFlat"] = {codepoint = 0xEDA9, description = "Flat"},
        ["flag1024thUp"] = {codepoint = 0xE24E, description = "Combining flag 8 (1024th) above"},
        ["luteStaff6LinesNarrow"] = {codepoint = 0xEBA2, description = "Lute tablature staff, 6 courses (narrow)"},
        ["tremolo3"] = {codepoint = 0xE222, description = "Combining tremolo 3"},
        ["harpSalzedoFluidicSoundsRight"] = {codepoint = 0xE68E, description = "Fluidic sounds, right hand (Salzedo)"},
        ["accSagittal3TinasUp"] = {codepoint = 0xE3FC, description = "3 tinas up, 1 mina up, 1/(5⋅7⋅13)-schismina up, 0.42 cents up"},
        ["figbass5Raised1"] = {codepoint = 0xEA58, description = "Figured bass 5 raised by half-step"},
        ["accdnRH3RanksDoubleTremoloLower8ve"] = {codepoint = 0xE8B1, description = "Right hand, 3 ranks, lower tremolo 8' stop + 8' stop + upper tremolo 8' stop + 16' stop"},
        ["accidentalWyschnegradsky3TwelfthsSharp"] = {codepoint = 0xE422, description = "1/4 tone sharp"},
        ["handbellsPluckLift"] = {codepoint = 0xE817, description = "Pluck lift"},
        ["pictBeaterSoftTimpaniRight"] = {codepoint = 0xE78A, description = "Soft timpani stick right"},
        ["luteFrenchFretM"] = {codepoint = 0xEBCB, description = "11th fret (m)"},
        ["conductorStrongBeat"] = {codepoint = 0xE890, description = "Strong beat or cue"},
        ["fingering3Italic"] = {codepoint = 0xED83, description = "Fingering 3 italic (middle finger)"},
        ["accSagittal35MediumDiesisUp"] = {codepoint = 0xE308, description = "35 medium diesis up, (35M, ~13M, ~125M, 5C plus 7C), 2/9-tone up"},
        ["pictCrushStem"] = {codepoint = 0xE80C, description = "Combining crush for stem"},
        ["accSagittalSharp35LUp"] = {codepoint = 0xE32A, description = "Sharp 35L-up, 5° up [50 EDO]"},
        ["accidentalDoubleSharpTwoArrowsUp"] = {codepoint = 0xE2D3, description = "Double sharp raised by two syntonic commas"},
        ["figbass9"] = {codepoint = 0xEA61, description = "Figured bass 9"},
        ["luteFrenchFretF"] = {codepoint = 0xEBC5, description = "Fifth fret (f)"},
        ["accSagittalSharp5v7kUp"] = {codepoint = 0xE31C, description = "Sharp 5:7k-up"},
        ["fingering9Italic"] = {codepoint = 0xED89, description = "Fingering 9 italic"},
        ["luteFrenchAppoggiaturaBelow"] = {codepoint = 0xEBD4, description = "Appoggiatura from below"},
        ["pictBeaterCombiningDashedCircle"] = {codepoint = 0xE7EA, description = "Combining dashed circle for round beaters (plated)"},
        ["noteShapeTriangleRightWhite"] = {codepoint = 0xE1B4, description = "Triangle right white (stem down; 4-shape fa; 7-shape fa)"},
        ["accidentalTwoThirdTonesSharpFerneyhough"] = {codepoint = 0xE48C, description = "Two-third-tones sharp (Ferneyhough)"},
        ["noteheadTriangleDownWhite"] = {codepoint = 0xE0C6, description = "Triangle notehead down white"},
        ["textHeadlessBlackNoteShortStem"] = {codepoint = 0xE204, description = "Headless black note, short stem"},
        ["arrowBlackDownRight"] = {codepoint = 0xEB63, description = "Black arrow down-right (SE)"},
        ["accidentalDoubleSharpEqualTempered"] = {codepoint = 0xE2F4, description = "Double sharp equal tempered semitone"},
        ["arrowheadWhiteDownRight"] = {codepoint = 0xEB83, description = "White arrowhead down-right (SE)"},
        ["accidentalSharpOneArrowDown"] = {codepoint = 0xE2C3, description = "Sharp lowered by one syntonic comma"},
        ["accidentalCombiningRaise37Quartertone"] = {codepoint = 0xEE53, description = "Combining raise by one 37-limit quartertone"},
        ["accSagittalFlat49SDown"] = {codepoint = 0xE3CD, description = "Flat 49S-down"},
        ["accidentalSims12Down"] = {codepoint = 0xE2A0, description = "1/12 tone low"},
        ["keyboardPedalHeel3"] = {codepoint = 0xE663, description = "Pedal heel 3 (Davis)"},
        ["accidentalJohnstonEl"] = {codepoint = 0xE2B2, description = "Inverted seven (raise by 36:35)"},
        ["repeatBarUpperDot"] = {codepoint = 0xE503, description = "Repeat bar upper dot"},
        ["mensuralColorationEndSquare"] = {codepoint = 0xEA0D, description = "Coloration end, square"},
        ["kievanNote8thStemDown"] = {codepoint = 0xEC3A, description = "Kievan eighth note, stem down"},
        ["functionMUpper"] = {codepoint = 0xED00, description = "Function theory M"},
        ["arrowheadWhiteRight"] = {codepoint = 0xEB82, description = "White arrowhead right (E)"},
        ["figbassBracketLeft"] = {codepoint = 0xEA68, description = "Figured bass ["},
        ["accSagittalFlat23SUp"] = {codepoint = 0xE3B1, description = "Flat 23S-up"},
        ["mensuralWhiteFusa"] = {codepoint = 0xE961, description = "White mensural fusa"},
        ["accidentalHabaSharpThreeQuarterTonesHigher"] = {codepoint = 0xEE66, description = "Three quarter-tones higher (Alois Hába)"},
        ["fermataLongHenzeBelow"] = {codepoint = 0xE4CB, description = "Long fermata (Henze) below"},
        ["fingering6"] = {codepoint = 0xED24, description = "Fingering 6"},
        ["noteheadTriangleRightWhite"] = {codepoint = 0xE0C1, description = "Triangle notehead right white"},
        ["luteGermanBUpper"] = {codepoint = 0xEC18, description = "6th course, 2nd fret (B)"},
        ["csymHalfDiminished"] = {codepoint = 0xE871, description = "Half-diminished"},
        ["accSagittalSharp11LUp"] = {codepoint = 0xE328, description = "Sharp 11L-up, 8° up [46 EDO]"},
        ["noteheadRectangularClusterBlackTop"] = {codepoint = 0xE142, description = "Combining black rectangular cluster, top"},
        ["keyboardPedalHalf2"] = {codepoint = 0xE65B, description = "Half pedal mark 1"},
        ["figbassPlus"] = {codepoint = 0xEA6C, description = "Figured bass +"},
        ["mensuralProportion1"] = {codepoint = 0xE926, description = "Mensural proportion 1"},
        ["accdnRicochet3"] = {codepoint = 0xE8CE, description = "Ricochet (3 tones)"},
        ["dynamicCombinedSeparatorHyphen"] = {codepoint = 0xE547, description = "Hyphen separator for combined dynamics"},
        ["brassHarmonMuteStemOpen"] = {codepoint = 0xE5EB, description = "Harmon mute, stem out"},
        ["arrowheadWhiteUpLeft"] = {codepoint = 0xEB87, description = "White arrowhead up-left (NW)"},
        ["elecReplay"] = {codepoint = 0xEB24, description = "Replay"},
        ["figbass6"] = {codepoint = 0xEA5B, description = "Figured bass 6"},
        ["pictTambourine"] = {codepoint = 0xE6DB, description = "Tambourine"},
        ["accSagittalSharp23SDown"] = {codepoint = 0xE3B0, description = "Sharp 23S-down"},
        ["timeSig1Reversed"] = {codepoint = 0xECF1, description = "Reversed time signature 1"},
        ["accidentalQuarterToneFlat4"] = {codepoint = 0xE47F, description = "Quarter-tone flat"},
        ["beamAccelRit8"] = {codepoint = 0xEAFB, description = "Accel./rit. beam 8"},
        ["kahnPush"] = {codepoint = 0xEDDE, description = "Push"},
        ["brassPlop"] = {codepoint = 0xE5E0, description = "Plop"},
        ["accSagittalShaftUp"] = {codepoint = 0xE3F0, description = "Shaft up, (natural for use with only diacritics up)"},
        ["chantPunctumInclinatumAuctum"] = {codepoint = 0xE992, description = "Punctum inclinatum auctum"},
        ["fingeringMultipleNotes"] = {codepoint = 0xED23, description = "Multiple notes played by thumb or single finger"},
        ["ornamentHighRightConcaveStroke"] = {codepoint = 0xE5A2, description = "Ornament high right concave stroke"},
        ["accidentalWyschnegradsky5TwelfthsFlat"] = {codepoint = 0xE42F, description = "5/12 tone flat"},
        ["accSagittal7CommaUp"] = {codepoint = 0xE304, description = "7 comma up, (7C), 1° up [43 EDO], 2° up [72 EDO], 1/6-tone up"},
        ["accidentalLowerOneSeptimalComma"] = {codepoint = 0xE2DE, description = "Lower by one septimal comma"},
        ["analyticsTheme"] = {codepoint = 0xE864, description = "Theme"},
        ["accSagittalFractionalTinaUp"] = {codepoint = 0xE40A, description = "Fractional tina up, 77/(5⋅37)-schismina up, 0.08 cents up"},
        ["accSagittal5v11SmallDiesisUp"] = {codepoint = 0xE348, description = "5:11 small diesis up, (5:11S, ~7:13S, ~11:17S, 5:7k plus 7:11C)"},
        ["mensuralBlackBrevis"] = {codepoint = 0xE952, description = "Black mensural brevis"},
        ["noteMeWhole"] = {codepoint = 0xEEE3, description = "Me (whole note)"},
        ["kahnLeap"] = {codepoint = 0xEDA3, description = "Leap"},
        ["harpSalzedoDampAbove"] = {codepoint = 0xE69A, description = "Damp above (Salzedo)"},
        ["accidentalSims6Down"] = {codepoint = 0xE2A1, description = "1/6 tone low"},
        ["fingeringSeparatorMiddleDot"] = {codepoint = 0xED2C, description = "Fingering middle dot separator"},
        ["accdnLH3Ranks8Square"] = {codepoint = 0xE8C1, description = "Left hand, 3 ranks, 8' stop (square)"},
        ["kahnGraceTapHop"] = {codepoint = 0xEDD0, description = "Grace-tap-hop"},
        ["elecMIDIOut"] = {codepoint = 0xEB35, description = "MIDI out"},
        ["elecAudioChannelsEight"] = {codepoint = 0xEB46, description = "Eight channels (7.1 surround)"},
        ["gClef8vbParens"] = {codepoint = 0xE057, description = "G clef, optionally ottava bassa"},
        ["ornamentMiddleVerticalStroke"] = {codepoint = 0xE59F, description = "Ornament middle vertical stroke"},
        ["articUnstressBelow"] = {codepoint = 0xE4B9, description = "Unstress below"},
        ["wiggleRandom3"] = {codepoint = 0xEAF2, description = "Quasi-random squiggle 3"},
        ["arrowOpenRight"] = {codepoint = 0xEB72, description = "Open arrow right (E)"},
        ["mensuralWhiteBrevis"] = {codepoint = 0xE95E, description = "White mensural brevis"},
        ["kahnBrushForward"] = {codepoint = 0xEDA6, description = "Brush-forward"},
        ["accSagittalDoubleSharp7v19CDown"] = {codepoint = 0xE3E4, description = "Double sharp 7:19C-down"},
        ["guitarClosePedal"] = {codepoint = 0xE83F, description = "Closed wah/volume pedal"},
        ["accdnRicochet6"] = {codepoint = 0xE8D1, description = "Ricochet (6 tones)"},
        ["harpSalzedoPlayUpperEnd"] = {codepoint = 0xE68A, description = "Play at upper end of strings (Salzedo)"},
        ["kahnHeelChange"] = {codepoint = 0xEDC9, description = "Heel-change"},
        ["accSagittalGrave"] = {codepoint = 0xE3F3, description = "Grave, 5 schisma down, 2 cents down"},
        ["dynamicPiano"] = {codepoint = 0xE520, description = "Piano"},
        ["csymMajorSeventh"] = {codepoint = 0xE873, description = "Major seventh"},
        ["accidentalWyschnegradsky11TwelfthsSharp"] = {codepoint = 0xE42A, description = "11/12 tone sharp"},
        ["accSagittal19SchismaDown"] = {codepoint = 0xE391, description = "19 schisma down"},
        ["accdnRH3RanksOrgan"] = {codepoint = 0xE8A9, description = "Right hand, 3 ranks, 4' stop + 16' stop (organ)"},
        ["harpSalzedoOboicFlux"] = {codepoint = 0xE685, description = "Oboic flux (Salzedo)"},
        ["accSagittalSharp55CUp"] = {codepoint = 0xE358, description = "Sharp 55C-up, 11° up [96 EDO], 11/16-tone up"},
        ["noteFiBlack"] = {codepoint = 0xEEF6, description = "Fi (black note)"},
        ["accidentalCombiningLower31Schisma"] = {codepoint = 0xE2EC, description = "Combining lower by one 31-limit schisma"},
        ["figbass8"] = {codepoint = 0xEA60, description = "Figured bass 8"},
        ["harpPedalLowered"] = {codepoint = 0xE682, description = "Harp pedal lowered (sharp)"},
        ["harpPedalRaised"] = {codepoint = 0xE680, description = "Harp pedal raised (flat)"},
        ["accSagittalDoubleFlat5v7kUp"] = {codepoint = 0xE333, description = "Double flat 5:7k-up"},
        ["guitarString6"] = {codepoint = 0xE839, description = "String number 6"},
        ["accidentalHabaFlatQuarterToneHigher"] = {codepoint = 0xEE65, description = "Quarter-tone higher (Alois Hába)"},
        ["handbellsTableSingleBell"] = {codepoint = 0xE820, description = "Table single handbell"},
        ["accidentalSharpThreeArrowsUp"] = {codepoint = 0xE2DC, description = "Sharp raised by three syntonic commas"},
        ["handbellsMalletBellOnTable"] = {codepoint = 0xE815, description = "Mallet, bell on table"},
        ["gClef"] = {codepoint = 0xE050, description = "G clef"},
        ["accSagittalFlat49LDown"] = {codepoint = 0xE3D9, description = "Flat 49L-down"},
        ["accSagittalSharp5v11SUp"] = {codepoint = 0xE35C, description = "Sharp 5:11S-up"},
        ["accSagittalUnused2"] = {codepoint = 0xE31B, description = "Unused"},
        ["noteheadCowellFifthNoteSeriesHalf"] = {codepoint = 0xEEA5, description = "2/5 note (fifth note series, Cowell)"},
        ["accSagittalFlat11v49CDown"] = {codepoint = 0xE3C7, description = "Flat 11:49C-down"},
        ["chantSemicirculusBelow"] = {codepoint = 0xE9D5, description = "Semicirculus below"},
        ["organGermanALower"] = {codepoint = 0xEE15, description = "German organ tablature small A"},
        ["gClefChange"] = {codepoint = 0xE07A, description = "G clef change"},
        ["fClefArrowUp"] = {codepoint = 0xE067, description = "F clef, arrow up"},
        ["figbass7"] = {codepoint = 0xEA5D, description = "Figured bass 7"},
        ["kahnPull"] = {codepoint = 0xEDE3, description = "Pull"},
        ["graceNoteAppoggiaturaStemUp"] = {codepoint = 0xE562, description = "Grace note stem up"},
        ["pictBellPlate"] = {codepoint = 0xE713, description = "Bell plate"},
        ["accidentalFiveQuarterTonesFlatArrowDown"] = {codepoint = 0xE279, description = "Five-quarter-tones flat"},
        ["noteQuarterUp"] = {codepoint = 0xE1D5, description = "Quarter note (crotchet) stem up"},
        ["gClef8va"] = {codepoint = 0xE053, description = "G clef ottava alta"},
        ["accSagittal5v49MediumDiesisUp"] = {codepoint = 0xE3A6, description = "5:49 medium diesis up, (5:49M, half apotome)"},
        ["accdnCombRH4RanksEmpty"] = {codepoint = 0xE8C7, description = "Combining right hand, 4 ranks, empty"},
        ["fretboardFilledCircle"] = {codepoint = 0xE858, description = "Fingered fret (filled circle)"},
        ["functionThree"] = {codepoint = 0xEA73, description = "Function theory 3"},
        ["mensuralRestSemibrevis"] = {codepoint = 0xE9F4, description = "Semibrevis rest"},
        ["kodalyHandFa"] = {codepoint = 0xEC43, description = "Fa hand sign"},
        ["noteDoubleWholeSquare"] = {codepoint = 0xE1D1, description = "Double whole note (square)"},
        ["figbass2"] = {codepoint = 0xEA52, description = "Figured bass 2"},
        ["beamAccelRit13"] = {codepoint = 0xEB00, description = "Accel./rit. beam 13"},
        ["bracketBottom"] = {codepoint = 0xE004, description = "Bracket bottom"},
        ["accSagittalDoubleSharp17kDown"] = {codepoint = 0xE3EC, description = "Double sharp 17k-down"},
        ["timeSig9"] = {codepoint = 0xE089, description = "Time signature 9"},
        ["wiggleVibratoLargeSlow"] = {codepoint = 0xEAE6, description = "Vibrato large, slow"},
        ["accidentalParensRight"] = {codepoint = 0xE26B, description = "Accidental parenthesis, right"},
        ["cClef"] = {codepoint = 0xE05C, description = "C clef"},
        ["fClef"] = {codepoint = 0xE062, description = "F clef"},
        ["kievanAccidentalSharp"] = {codepoint = 0xEC3D, description = "Kievan sharp"},
        ["noteMeHalf"] = {codepoint = 0xEEEC, description = "Me (half note)"},
        ["fretboard3StringNut"] = {codepoint = 0xE851, description = "3-string fretboard at nut"},
        ["accSagittalDoubleSharp19CDown"] = {codepoint = 0xE3E6, description = "Double sharp 19C-down"},
        ["fClef8vb"] = {codepoint = 0xE064, description = "F clef ottava bassa"},
        ["accidentalTwoThirdTonesFlatFerneyhough"] = {codepoint = 0xE48D, description = "Two-third-tones flat (Ferneyhough)"},
        ["kievanNoteWholeFinal"] = {codepoint = 0xEC34, description = "Kievan final whole note"},
        ["accidentalCombiningRaise29LimitComma"] = {codepoint = 0xEE51, description = "Combining raise by one 29-limit comma"},
        ["kahnClap"] = {codepoint = 0xEDB8, description = "Clap"},
        ["kahnDoubleSnap"] = {codepoint = 0xEDBA, description = "Double-snap"},
        ["flag256thUp"] = {codepoint = 0xE24A, description = "Combining flag 6 (256th) above"},
        ["accidentalQuarterToneFlatStein"] = {codepoint = 0xE280, description = "Reversed flat (quarter-tone flat) (Stein)"},
        ["pictBeaterDoubleBassDrumDown"] = {codepoint = 0xE7A1, description = "Double bass drum stick down"},
        ["flag16thDown"] = {codepoint = 0xE243, description = "Combining flag 2 (16th) below"},
        ["fermataShortHenzeBelow"] = {codepoint = 0xE4CD, description = "Short fermata (Henze) below"},
        ["accSagittalDoubleSharp23SDown"] = {codepoint = 0xE3E0, description = "Double sharp 23S-down"},
        ["scaleDegree3"] = {codepoint = 0xEF02, description = "Scale degree 3"},
        ["fingeringSubstitutionBelow"] = {codepoint = 0xED21, description = "Finger substitution below"},
        ["accSagittalFlat7v11kUp"] = {codepoint = 0xE353, description = "Flat 7:11k-up"},
        ["chantOriscusAscending"] = {codepoint = 0xE99C, description = "Oriscus ascending"},
        ["accSagittalDoubleSharp17CDown"] = {codepoint = 0xE364, description = "Double sharp 17C-down"},
        ["analyticsHauptrhythmus"] = {codepoint = 0xE86B, description = "Hauptrhythmus (Berg)"},
        ["fingering2"] = {codepoint = 0xED12, description = "Fingering 2 (index finger)"},
        ["pictBeaterSoftXylophoneRight"] = {codepoint = 0xE772, description = "Soft xylophone stick right"},
        ["luteItalianFret5"] = {codepoint = 0xEBE5, description = "Fifth fret (5)"},
        ["beamAccelRit11"] = {codepoint = 0xEAFE, description = "Accel./rit. beam 11"},
        ["conductorBeat4Simple"] = {codepoint = 0xE896, description = "Beat 4, simple time"},
        ["fingering8"] = {codepoint = 0xED26, description = "Fingering 8"},
        ["kahnJumpApart"] = {codepoint = 0xEDA5, description = "Jump-apart"},
        ["noteShapeMoonLeftBlack"] = {codepoint = 0xE1C7, description = "Moon left black (Funk 7-shape do)"},
        ["kahnBallDig"] = {codepoint = 0xEDCD, description = "Ball-dig"},
        ["fingeringSeparatorMiddleDotWhite"] = {codepoint = 0xED2D, description = "Fingering white middle dot separator"},
        ["accidentalFilledReversedFlatAndFlatArrowDown"] = {codepoint = 0xE298, description = "Filled reversed flat and flat with arrow down"},
        ["coda"] = {codepoint = 0xE048, description = "Coda"},
        ["flag1024thDown"] = {codepoint = 0xE24F, description = "Combining flag 8 (1024th) below"},
        ["keyboardPlayWithLHEnd"] = {codepoint = 0xE671, description = "Play with left hand (end)"},
        ["noteheadHalfWithX"] = {codepoint = 0xE0B6, description = "Half notehead with X"},
        ["accSagittalSharp7CDown"] = {codepoint = 0xE312, description = "Sharp 7C-down, 2° up [43 EDO], 4° up [72 EDO], 1/3-tone up"},
        ["flag256thDown"] = {codepoint = 0xE24B, description = "Combining flag 6 (256th) below"},
        ["fingeringCLower"] = {codepoint = 0xED1C, description = "Fingering c (right-hand little finger for guitar)"},
        ["accSagittalDoubleSharp"] = {codepoint = 0xE334, description = "Double sharp, (2 apotomes up)[almost all EDOs], whole-tone up"},
        ["accSagittal2TinasUp"] = {codepoint = 0xE3FA, description = "2 tinas up, 1/(7³⋅17)-schismina up, 0.30 cents up"},
        ["accidentalDoubleSharpArabic"] = {codepoint = 0xED38, description = "Arabic double sharp"},
        ["luteStaff6LinesWide"] = {codepoint = 0xEBA1, description = "Lute tablature staff, 6 courses (wide)"},
        ["noteShapeTriangleLeftBlack"] = {codepoint = 0xE1B7, description = "Triangle left black (stem up; 4-shape fa; 7-shape fa)"},
        ["fretboard6String"] = {codepoint = 0xE856, description = "6-string fretboard"},
        ["accSagittalFlat5v11SUp"] = {codepoint = 0xE34B, description = "Flat 5:11S-up"},
        ["keyboardBebung4DotsAbove"] = {codepoint = 0xE66C, description = "Clavichord bebung, 4 finger movements (above)"},
        ["articAccentStaccatoAbove"] = {codepoint = 0xE4B0, description = "Accent-staccato above"},
        ["functionAngleRight"] = {codepoint = 0xEA94, description = "Function theory angle bracket right"},
        ["organGermanELower"] = {codepoint = 0xEE10, description = "German organ tablature small E"},
        ["functionDUpper"] = {codepoint = 0xEA7F, description = "Function theory major dominant"},
        ["accidentalCombiningRaise17Schisma"] = {codepoint = 0xE2E7, description = "Combining raise by one 17-limit schisma"},
        ["functionLLower"] = {codepoint = 0xEA9F, description = "Function theory l"},
        ["functionLUpper"] = {codepoint = 0xEA9E, description = "Function theory L"},
        ["functionMLower"] = {codepoint = 0xED01, description = "Function theory m"},
        ["accSagittalFlat143CDown"] = {codepoint = 0xE3C5, description = "Flat 143C-down"},
        ["functionPlus"] = {codepoint = 0xEA98, description = "Function theory prefix plus"},
        ["harpSalzedoTamTamSounds"] = {codepoint = 0xE689, description = "Tam-tam sounds (Salzedo)"},
        ["accidentalWyschnegradsky1TwelfthsSharp"] = {codepoint = 0xE420, description = "1/12 tone sharp"},
        ["noteFHalf"] = {codepoint = 0xE18F, description = "F (half note)"},
        ["fingeringELower"] = {codepoint = 0xED1E, description = "Fingering e (right-hand little finger for guitar)"},
        ["accSagittalFlat19sDown"] = {codepoint = 0xE3C1, description = "Flat 19s-down"},
        ["luteFrenchMordentLower"] = {codepoint = 0xEBD2, description = "Mordent with lower auxiliary"},
        ["organGermanCisUpper"] = {codepoint = 0xEE01, description = "German organ tablature great Cis"},
        ["pictGumSoftDown"] = {codepoint = 0xE7BC, description = "Soft gum beater, down"},
        ["csymParensLeftTall"] = {codepoint = 0xE875, description = "Double-height left parenthesis"},
        ["mensuralNoteheadSemibrevisBlackVoidTurned"] = {codepoint = 0xE93B, description = "Semibrevis notehead, black and void (turned)"},
        ["gClef15ma"] = {codepoint = 0xE054, description = "G clef quindicesima alta"},
        ["accidentalSharpThreeArrowsDown"] = {codepoint = 0xE2D7, description = "Sharp lowered by three syntonic commas"},
        ["gClef8vbCClef"] = {codepoint = 0xE056, description = "G clef ottava bassa with C clef"},
        ["gClef8vbOld"] = {codepoint = 0xE055, description = "G clef ottava bassa (old style)"},
        ["ornamentTurnInverted"] = {codepoint = 0xE568, description = "Inverted turn"},
        ["guitarRightHandTapping"] = {codepoint = 0xE841, description = "Right-hand tapping"},
        ["accSagittal7v11KleismaDown"] = {codepoint = 0xE341, description = "7:11 kleisma down"},
        ["keyboardPlayWithRHEnd"] = {codepoint = 0xE66F, description = "Play with right hand (end)"},
        ["graceNoteAcciaccaturaStemUp"] = {codepoint = 0xE560, description = "Slashed grace note stem up"},
        ["chantOriscusLiquescens"] = {codepoint = 0xE99E, description = "Oriscus liquescens"},
        ["graceNoteSlashStemDown"] = {codepoint = 0xE565, description = "Slash for stem down grace note"},
        ["dynamicPPPP"] = {codepoint = 0xE529, description = "pppp"},
        ["keyboardPedalUp"] = {codepoint = 0xE655, description = "Pedal up mark"},
        ["gClefArrowUp"] = {codepoint = 0xE05A, description = "G clef, arrow up"},
        ["noteRiBlack"] = {codepoint = 0xEEF3, description = "Ri (black note)"},
        ["guitarShake"] = {codepoint = 0xE832, description = "Guitar shake"},
        ["noteAHalf"] = {codepoint = 0xE180, description = "A (half note)"},
        ["cClefArrowUp"] = {codepoint = 0xE05E, description = "C clef, arrow up"},
        ["guitarString12"] = {codepoint = 0xE84C, description = "String number 12"},
        ["luteGermanGLower"] = {codepoint = 0xEC06, description = "4th course, 2nd fret (g)"},
        ["mensuralFclef"] = {codepoint = 0xE903, description = "Mensural F clef"},
        ["guitarString5"] = {codepoint = 0xE838, description = "String number 5"},
        ["accidentalQuarterToneFlatArabic"] = {codepoint = 0xED33, description = "Arabic quarter-tone flat"},
        ["guitarWideVibratoStroke"] = {codepoint = 0xEAB3, description = "Wide vibrato wiggle segment"},
        ["accSagittal49MediumDiesisUp"] = {codepoint = 0xE3A4, description = "49 medium diesis up, (49M, ~31M, 7C plus 7C)"},
        ["accidentalRaiseOneSeptimalComma"] = {codepoint = 0xE2DF, description = "Raise by one septimal comma"},
        ["luteFrenchFretA"] = {codepoint = 0xEBC0, description = "Open string (a)"},
        ["kahnRightCatch"] = {codepoint = 0xEDC0, description = "Right-catch"},
        ["dynamicPPPPPP"] = {codepoint = 0xE527, description = "pppppp"},
        ["harpMetalRod"] = {codepoint = 0xE68F, description = "Metal rod pictogram"},
        ["harpPedalCentered"] = {codepoint = 0xE681, description = "Harp pedal centered (natural)"},
        ["kievanNoteHalfStaffSpace"] = {codepoint = 0xEC36, description = "Kievan half note (in staff space)"},
        ["noteheadSlashedDoubleWhole1"] = {codepoint = 0xE0D5, description = "Slashed double whole notehead (bottom left to top right)"},
        ["ornamentRightVerticalStroke"] = {codepoint = 0xE5A4, description = "Ornament right vertical stroke"},
        ["schaefferFClefToGClef"] = {codepoint = 0xE072, description = "Schäffer F clef to G clef change"},
        ["functionRepetition1"] = {codepoint = 0xEA95, description = "Function theory repetition 1"},
        ["noteheadCowellFifteenthNoteSeriesHalf"] = {codepoint = 0xEEB4, description = "4/15 note (fifteenth note series, Cowell)"},
        ["accidentalUpsAndDownsUp"] = {codepoint = 0xEE60, description = "Accidental up"},
        ["noteheadPlusHalf"] = {codepoint = 0xE0AE, description = "Plus notehead half"},
        ["accSagittalSharp11v19LUp"] = {codepoint = 0xE3DA, description = "Sharp 11:19L-up"},
        ["organGermanHUpper"] = {codepoint = 0xEE0B, description = "German organ tablature great H"},
        ["harpStringNoiseStem"] = {codepoint = 0xE694, description = "Combining string noise for stem"},
        ["arrowOpenUpRight"] = {codepoint = 0xEB71, description = "Open arrow up-right (NE)"},
        ["arrowheadWhiteDown"] = {codepoint = 0xEB84, description = "White arrowhead down (S)"},
        ["indianDrumClef"] = {codepoint = 0xED70, description = "Indian drum clef"},
        ["accidentalQuarterToneSharpWiggle"] = {codepoint = 0xE475, description = "Quarter tone sharp with wiggly tail"},
        ["caesura"] = {codepoint = 0xE4D1, description = "Caesura"},
        ["organGermanBuxheimerBrevis2"] = {codepoint = 0xEE25, description = "Brevis (Binary) Buxheimer Orgelbuch"},
        ["luteGermanIUpper"] = {codepoint = 0xEC1F, description = "6th course, 9th fret (I)"},
        ["kahnDoubleWing"] = {codepoint = 0xEDEB, description = "Double-wing"},
        ["fingeringRightBracketItalic"] = {codepoint = 0xED8D, description = "Fingering right bracket italic"},
        ["kievanNote8thStemUp"] = {codepoint = 0xEC39, description = "Kievan eighth note, stem up"},
        ["mensuralObliqueDesc4thVoid"] = {codepoint = 0xE989, description = "Oblique form, descending 4th, void"},
        ["dynamicZ"] = {codepoint = 0xE525, description = "Z"},
        ["kahnHeelDrop"] = {codepoint = 0xEDB6, description = "Heel-drop"},
        ["noteheadDiamondClusterWhiteTop"] = {codepoint = 0xE13C, description = "Combining white diamond cluster, top"},
        ["kahnHop"] = {codepoint = 0xEDA2, description = "Hop"},
        ["pictGumSoftLeft"] = {codepoint = 0xE7BE, description = "Soft gum beater, left"},
        ["kahnLeapFlatFoot"] = {codepoint = 0xEDD2, description = "Leap-flat-foot"},
        ["noteFaBlack"] = {codepoint = 0xE163, description = "Fa (black note)"},
        ["kahnLeapHeelClick"] = {codepoint = 0xEDD4, description = "Leap-heel-click"},
        ["octaveBassa"] = {codepoint = 0xE51F, description = "Bassa"},
        ["windHalfClosedHole1"] = {codepoint = 0xE5F6, description = "Half-closed hole"},
        ["elecAudioChannelsSix"] = {codepoint = 0xEB44, description = "Six channels (5.1 surround)"},
        ["kahnOverTheTop"] = {codepoint = 0xEDEC, description = "Over-the-top"},
        ["dynamicCrescendoHairpin"] = {codepoint = 0xE53E, description = "Crescendo"},
        ["noteShapeSquareWhite"] = {codepoint = 0xE1B2, description = "Square white (4-shape la; Aikin 7-shape la)"},
        ["accidental4CommaFlat"] = {codepoint = 0xE457, description = "4-comma flat"},
        ["csymBracketRightTall"] = {codepoint = 0xE878, description = "Double-height right bracket"},
        ["kahnSlap"] = {codepoint = 0xEDD9, description = "Slap"},
        ["kahnSlideStep"] = {codepoint = 0xEDB4, description = "Slide-step"},
        ["keyboardPedalHookEnd"] = {codepoint = 0xE673, description = "Pedal hook end"},
        ["luteItalianTremolo"] = {codepoint = 0xEBF2, description = "Single-finger tremolo or mordent"},
        ["kahnStepStamp"] = {codepoint = 0xEDC7, description = "Step-stamp"},
        ["accidentalQuarterToneSharp4"] = {codepoint = 0xE47E, description = "Quarter-tone sharp"},
        ["guitarVibratoBarDip"] = {codepoint = 0xE831, description = "Guitar vibrato bar dip"},
        ["kahnStompBrush"] = {codepoint = 0xEDDB, description = "Stomp-brush"},
        ["kahnToeTap"] = {codepoint = 0xEDCC, description = "Toe-tap"},
        ["accSagittal49LargeDiesisDown"] = {codepoint = 0xE3A9, description = "49 large diesis down"},
        ["keyboardPedalD"] = {codepoint = 0xE653, description = "Pedal d"},
        ["noteCSharpWhole"] = {codepoint = 0xE170, description = "C sharp (whole note)"},
        ["accidentalCombiningRaise19Schisma"] = {codepoint = 0xE2E9, description = "Combining raise by one 19-limit schisma"},
        ["accidentalBakiyeSharp"] = {codepoint = 0xE445, description = "Bakiye (sharp)"},
        ["keyboardPedalHeel2"] = {codepoint = 0xE662, description = "Pedal heel 2"},
        ["luteDurationHalf"] = {codepoint = 0xEBA8, description = "Half note (minim) duration sign"},
        ["elecCamera"] = {codepoint = 0xEB1B, description = "Camera"},
        ["keyboardPedalHeelToToe"] = {codepoint = 0xE674, description = "Pedal heel to toe"},
        ["figbass1"] = {codepoint = 0xEA51, description = "Figured bass 1"},
        ["accSagittal5v11SmallDiesisDown"] = {codepoint = 0xE349, description = "5:11 small diesis down"},
        ["kievanCClef"] = {codepoint = 0xEC30, description = "Kievan C clef (tse-fa-ut)"},
        ["functionPUpper"] = {codepoint = 0xEA87, description = "Function theory P"},
        ["staff2Lines"] = {codepoint = 0xE011, description = "2-line staff"},
        ["accSagittalSharp55CDown"] = {codepoint = 0xE34E, description = "Sharp 55C-down, 5° up [96 EDO], 5/16-tone up"},
        ["ornamentPrecompDoubleCadenceLowerPrefix"] = {codepoint = 0xE5C0, description = "Double cadence with lower prefix"},
        ["kodalyHandLa"] = {codepoint = 0xEC45, description = "La hand sign"},
        ["lyricsTextRepeat"] = {codepoint = 0xE555, description = "Text repeats"},
        ["accidentalQuarterToneSharpNaturalArrowUp"] = {codepoint = 0xE272, description = "Quarter-tone sharp"},
        ["leftRepeatSmall"] = {codepoint = 0xE04C, description = "Left repeat sign within bar"},
        ["legerLineNarrow"] = {codepoint = 0xE024, description = "Leger line (narrow)"},
        ["luteBarlineFinal"] = {codepoint = 0xEBA5, description = "Lute tablature final barline"},
        ["beamAccelRit10"] = {codepoint = 0xEAFD, description = "Accel./rit. beam 10"},
        ["6stringTabClef"] = {codepoint = 0xE06D, description = "6-string tab clef"},
        ["harpSalzedoMetallicSoundsOneString"] = {codepoint = 0xE69B, description = "Metallic sounds, one string (Salzedo)"},
        ["guitarString13"] = {codepoint = 0xE84D, description = "String number 13"},
        ["kahnRightFoot"] = {codepoint = 0xEDEF, description = "Right-foot"},
        ["noteEFlatBlack"] = {codepoint = 0xE1A2, description = "E flat (black note)"},
        ["figbassTripleFlat"] = {codepoint = 0xECC1, description = "Figured bass triple flat"},
        ["elecShuffle"] = {codepoint = 0xEB25, description = "Shuffle"},
        ["beamAccelRit14"] = {codepoint = 0xEB01, description = "Accel./rit. beam 14"},
        ["elecVolumeFaderThumb"] = {codepoint = 0xEB2D, description = "Combining volume fader thumb"},
        ["chantPunctumInclinatumDeminutum"] = {codepoint = 0xE993, description = "Punctum inclinatum deminutum"},
        ["luteFrenchFretB"] = {codepoint = 0xEBC1, description = "First fret (b)"},
        ["accidentalEnharmonicEquals"] = {codepoint = 0xE2FB, description = "Enharmonically reinterpret accidental equals"},
        ["pictDrumStick"] = {codepoint = 0xE7E8, description = "Drum stick"},
        ["accidentalOneAndAHalfSharpsArrowDown"] = {codepoint = 0xE29C, description = "One and a half sharps with arrow down"},
        ["luteFrenchFretK"] = {codepoint = 0xEBC9, description = "Ninth fret (k)"},
        ["accidentalWyschnegradsky6TwelfthsSharp"] = {codepoint = 0xE425, description = "1/2 tone sharp"},
        ["noteheadRectangularClusterWhiteTop"] = {codepoint = 0xE145, description = "Combining white rectangular cluster, top"},
        ["dynamicFortePiano"] = {codepoint = 0xE534, description = "Forte-piano"},
        ["noteLaWhole"] = {codepoint = 0xE155, description = "La (whole note)"},
        ["mensuralObliqueAsc3rdVoid"] = {codepoint = 0xE975, description = "Oblique form, ascending 3rd, void"},
        ["kahnShuffle"] = {codepoint = 0xEDE5, description = "Shuffle"},
        ["scaleDegree7"] = {codepoint = 0xEF06, description = "Scale degree 7"},
        ["conductorBeat3Simple"] = {codepoint = 0xE895, description = "Beat 3, simple time"},
        ["luteGermanCLower"] = {codepoint = 0xEC02, description = "3rd course, 1st fret (c)"},
        ["noteheadTriangleUpBlack"] = {codepoint = 0xE0BE, description = "Triangle notehead up black"},
        ["timeSig5Reversed"] = {codepoint = 0xECF5, description = "Reversed time signature 5"},
        ["luteGermanDUpper"] = {codepoint = 0xEC1A, description = "6th course, 4th fret (D)"},
        ["accSagittal5TinasUp"] = {codepoint = 0xE400, description = "5 tinas up, 7⁴/25-schismina up, 0.72 cents up"},
        ["luteGermanGUpper"] = {codepoint = 0xEC1D, description = "6th course, 7th fret (G)"},
        ["accidentalDoubleFlatOneArrowUp"] = {codepoint = 0xE2C5, description = "Double flat raised by one syntonic comma"},
        ["luteGermanNLower"] = {codepoint = 0xEC0C, description = "3rd course, 3rd fret (n)"},
        ["timeSig1"] = {codepoint = 0xE081, description = "Time signature 1"},
        ["dynamicMezzo"] = {codepoint = 0xE521, description = "Mezzo"},
        ["luteGermanZLower"] = {codepoint = 0xEC16, description = "3rd course, 5th fret (z)"},
        ["luteItalianClefFFaUt"] = {codepoint = 0xEBF0, description = "F fa ut clef"},
        ["noteHSharpHalf"] = {codepoint = 0xE195, description = "H sharp (half note)"},
        ["noteheadRoundWhiteDoubleSlashed"] = {codepoint = 0xE11D, description = "Round white notehead, double slashed"},
        ["fingering5Italic"] = {codepoint = 0xED85, description = "Fingering 5 italic (little finger)"},
        ["noteShapeKeystoneBlack"] = {codepoint = 0xE1C1, description = "Inverted keystone black (Walker 7-shape do)"},
        ["luteItalianTimeTriple"] = {codepoint = 0xEBEF, description = "Triple time indication"},
        ["accSagittalUnused1"] = {codepoint = 0xE31A, description = "Unused"},
        ["brassFallLipMedium"] = {codepoint = 0xE5D8, description = "Lip fall, medium"},
        ["mensuralSignumUp"] = {codepoint = 0xEA00, description = "Signum congruentiae up"},
        ["accSagittalFlat5v7kUp"] = {codepoint = 0xE317, description = "Flat 5:7k-up"},
        ["noteheadRoundBlackDoubleSlashed"] = {codepoint = 0xE11C, description = "Round black notehead, double slashed"},
        ["lyricsElisionWide"] = {codepoint = 0xE552, description = "Wide elision"},
        ["luteDuration16th"] = {codepoint = 0xEBAB, description = "16th note (semiquaver) duration sign"},
        ["dynamicHairpinParenthesisLeft"] = {codepoint = 0xE542, description = "Left parenthesis (for hairpins)"},
        ["tremoloDivisiDots4"] = {codepoint = 0xE230, description = "Divide measured tremolo by 4"},
        ["accidentalSharpEqualTempered"] = {codepoint = 0xE2F3, description = "Sharp equal tempered semitone"},
        ["wiggleTrillFastest"] = {codepoint = 0xEAA0, description = "Trill wiggle segment, fastest"},
        ["luteItalianFret4"] = {codepoint = 0xEBE4, description = "Fourth fret (4)"},
        ["mensuralCombStemDownFlagFusa"] = {codepoint = 0xE94C, description = "Combining stem with fusa flag down"},
        ["figbassCombiningLowering"] = {codepoint = 0xEA6E, description = "Combining lower"},
        ["mensuralCombStemDownFlagSemiminima"] = {codepoint = 0xE94A, description = "Combining stem with semiminima flag down"},
        ["mensuralCombStemUpFlagFlared"] = {codepoint = 0xE945, description = "Combining stem with flared flag up"},
        ["mensuralGclefPetrucci"] = {codepoint = 0xE901, description = "Petrucci G clef"},
        ["mensuralModusPerfectumVert"] = {codepoint = 0xE92C, description = "Modus perfectum, vertical"},
        ["stringsUpBowAwayFromBody"] = {codepoint = 0xEE83, description = "Up bow, away from body"},
        ["mensuralProportion6"] = {codepoint = 0xEE91, description = "Mensural proportion 6"},
        ["mensuralNoteheadMaximaWhite"] = {codepoint = 0xE933, description = "Maxima notehead, white"},
        ["kahnBackChug"] = {codepoint = 0xEDE2, description = "Back-chug"},
        ["accdnRicochetStem3"] = {codepoint = 0xE8D3, description = "Combining ricochet for stem (3 tones)"},
        ["noteEmptyBlack"] = {codepoint = 0xE1AF, description = "Empty black note"},
        ["mensuralObliqueAsc3rdWhite"] = {codepoint = 0xE977, description = "Oblique form, ascending 3rd, white"},
        ["kodalyHandTi"] = {codepoint = 0xEC46, description = "Ti hand sign"},
        ["graceNoteSlashStemUp"] = {codepoint = 0xE564, description = "Slash for stem up grace note"},
        ["kahnLeftCross"] = {codepoint = 0xEDBD, description = "Left-cross"},
        ["arrowWhiteDown"] = {codepoint = 0xEB6C, description = "White arrow down (S)"},
        ["articAccentAbove"] = {codepoint = 0xE4A0, description = "Accent above"},
        ["mensuralCclef"] = {codepoint = 0xE905, description = "Mensural C clef"},
        ["conductorLeftBeat"] = {codepoint = 0xE891, description = "Left-hand beat or cue"},
        ["accSagittal49SmallDiesisUp"] = {codepoint = 0xE39C, description = "49 small diesis up, (49S, ~31S)"},
        ["beamAccelRit15"] = {codepoint = 0xEB02, description = "Accel./rit. beam 15 (narrowest)"},
        ["kahnFleaTap"] = {codepoint = 0xEDB1, description = "Flea-tap"},
        ["keyboardPlayWithLH"] = {codepoint = 0xE670, description = "Play with left hand"},
        ["mensuralProlation8"] = {codepoint = 0xE917, description = "Tempus imperfectum cum prolatione imperfecta diminution 2 (6/16)"},
        ["fingeringALower"] = {codepoint = 0xED1B, description = "Fingering a (anular; right-hand ring finger for guitar)"},
        ["guitarString3"] = {codepoint = 0xE836, description = "String number 3"},
        ["accSagittal143CommaDown"] = {codepoint = 0xE395, description = "143 comma down"},
        ["accSagittalSharp49SUp"] = {codepoint = 0xE3CC, description = "Sharp 49S-up"},
        ["repeatBarLowerDot"] = {codepoint = 0xE505, description = "Repeat bar lower dot"},
        ["mensuralProlationCombiningDot"] = {codepoint = 0xE920, description = "Combining dot"},
        ["mensuralProlationCombiningDotVoid"] = {codepoint = 0xE924, description = "Combining void dot"},
        ["dynamicSforzatoFF"] = {codepoint = 0xE53B, description = "Sforzatissimo"},
        ["ornamentPrecompCadenceWithTurn"] = {codepoint = 0xE5BF, description = "Cadence with turn"},
        ["mensuralProportion7"] = {codepoint = 0xEE92, description = "Mensural proportion 7"},
        ["mensuralProportionProportioQuadrupla"] = {codepoint = 0xE91F, description = "Proportio quadrupla"},
        ["mensuralProportionProportioTripla"] = {codepoint = 0xE91E, description = "Proportio tripla"},
        ["noteFWhole"] = {codepoint = 0xE178, description = "F (whole note)"},
        ["keyboardPedalPed"] = {codepoint = 0xE650, description = "Pedal mark"},
        ["accidentalFlatRepeatedSpaceStockhausen"] = {codepoint = 0xED5B, description = "Repeated flat, note in space (Stockhausen)"},
        ["mensuralRestSemiminima"] = {codepoint = 0xE9F6, description = "Semiminima rest"},
        ["flag32ndDown"] = {codepoint = 0xE245, description = "Combining flag 3 (32nd) below"},
        ["mensuralTempusImperfectumHoriz"] = {codepoint = 0xE92F, description = "Tempus imperfectum, horizontal"},
        ["arrowheadBlackUpLeft"] = {codepoint = 0xEB7F, description = "Black arrowhead up-left (NW)"},
        ["metAugmentationDot"] = {codepoint = 0xECB7, description = "Augmentation dot"},
        ["kahnHeelTap"] = {codepoint = 0xEDCB, description = "Heel-tap"},
        ["noteheadPlusBlack"] = {codepoint = 0xE0AF, description = "Plus notehead black"},
        ["luteItalianTempoSlow"] = {codepoint = 0xEBED, description = "Slow tempo indication (de Mudarra)"},
        ["accdnRH4RanksMaster"] = {codepoint = 0xE8B7, description = "Right hand, 4 ranks, master"},
        ["brassFallSmoothShort"] = {codepoint = 0xE5DA, description = "Smooth fall, short"},
        ["daseianSuperiores1"] = {codepoint = 0xEA38, description = "Daseian superiores 1"},
        ["rest8th"] = {codepoint = 0xE4E6, description = "Eighth (quaver) rest"},
        ["elecRewind"] = {codepoint = 0xEB20, description = "Rewind"},
        ["metNote64thUp"] = {codepoint = 0xECAD, description = "64th note (hemidemisemiquaver) stem up"},
        ["elecMIDIController40"] = {codepoint = 0xEB38, description = "MIDI controller 40%"},
        ["mensuralProportionMinor"] = {codepoint = 0xE92A, description = "Mensural proportion minor"},
        ["accidentalWyschnegradsky2TwelfthsFlat"] = {codepoint = 0xE42C, description = "1/6 tone flat"},
        ["noteShapeDiamondDoubleWhole"] = {codepoint = 0xECD4, description = "Diamond double whole (4-shape mi; 7-shape mi)"},
        ["medRenNatural"] = {codepoint = 0xE9E2, description = "Natural"},
        ["conductorUnconducted"] = {codepoint = 0xE89A, description = "Unconducted/free passages"},
        ["cClefArrowDown"] = {codepoint = 0xE05F, description = "C clef, arrow down"},
        ["note16thUp"] = {codepoint = 0xE1D9, description = "16th note (semiquaver) stem up"},
        ["note8thUp"] = {codepoint = 0xE1D7, description = "Eighth note (quaver) stem up"},
        ["accidental2CommaFlat"] = {codepoint = 0xE455, description = "2-comma flat"},
        ["handbellsMartellatoLift"] = {codepoint = 0xE811, description = "Martellato lift"},
        ["flag128thDown"] = {codepoint = 0xE249, description = "Combining flag 5 (128th) below"},
        ["noteASharpWhole"] = {codepoint = 0xE16A, description = "A sharp (whole note)"},
        ["noteAWhole"] = {codepoint = 0xE169, description = "A (whole note)"},
        ["articSoftAccentTenutoBelow"] = {codepoint = 0xED45, description = "Soft accent-tenuto below"},
        ["noteBSharpHalf"] = {codepoint = 0xE184, description = "B sharp (half note)"},
        ["organGermanCisLower"] = {codepoint = 0xEE0D, description = "German organ tablature small Cis"},
        ["pictBeaterWoodTimpaniRight"] = {codepoint = 0xE796, description = "Wood timpani stick right"},
        ["noteheadTriangleDownDoubleWhole"] = {codepoint = 0xE0C3, description = "Triangle notehead down double whole"},
        ["barlineReverseFinal"] = {codepoint = 0xE033, description = "Reverse final barline"},
        ["textAugmentationDot"] = {codepoint = 0xE1FC, description = "Augmentation dot"},
        ["accSagittalFlat5v11SDown"] = {codepoint = 0xE35D, description = "Flat 5:11S-down"},
        ["accSagittalSharp19CUp"] = {codepoint = 0xE3C8, description = "Sharp 19C-up"},
        ["noteCFlatHalf"] = {codepoint = 0xE185, description = "C flat (half note)"},
        ["arrowheadWhiteUp"] = {codepoint = 0xEB80, description = "White arrowhead up (N)"},
        ["noteheadCircledDoubleWhole"] = {codepoint = 0xE0E7, description = "Circled double whole notehead"},
        ["noteDHalf"] = {codepoint = 0xE189, description = "D (half note)"},
        ["noteDoHalf"] = {codepoint = 0xE158, description = "Do (half note)"},
        ["accSagittalShaftDown"] = {codepoint = 0xE3F1, description = "Shaft down, (natural for use with only diacritics down)"},
        ["arrowWhiteLeft"] = {codepoint = 0xEB6E, description = "White arrow left (W)"},
        ["noteEFlatWhole"] = {codepoint = 0xE174, description = "E flat (whole note)"},
        ["noteEHalf"] = {codepoint = 0xE18C, description = "E (half note)"},
        ["elecUSB"] = {codepoint = 0xEB16, description = "USB connection"},
        ["mensuralNoteheadSemibrevisBlack"] = {codepoint = 0xE938, description = "Semibrevis notehead, black"},
        ["rest1024th"] = {codepoint = 0xE4ED, description = "1024th rest"},
        ["noteheadClusterDoubleWhole3rd"] = {codepoint = 0xE128, description = "Double whole note cluster, 3rd"},
        ["noteFFlatHalf"] = {codepoint = 0xE18E, description = "F flat (half note)"},
        ["luteGermanDLower"] = {codepoint = 0xEC03, description = "2nd course, 1st fret (d)"},
        ["elecAudioStereo"] = {codepoint = 0xEB3D, description = "Stereo audio setup"},
        ["staffPosLower1"] = {codepoint = 0xEB98, description = "Lower 1 staff position"},
        ["accSagittal35LargeDiesisUp"] = {codepoint = 0xE30E, description = "35 large diesis up, (35L, ~13L, ~125L, sharp less 35M), 2°50 up"},
        ["wiggleVibratoLargestSlowest"] = {codepoint = 0xEAEF, description = "Vibrato largest, slowest"},
        ["noteGFlatHalf"] = {codepoint = 0xE191, description = "G flat (half note)"},
        ["mensuralProportionProportioDupla1"] = {codepoint = 0xE91C, description = "Proportio dupla 1"},
        ["pictBoardClapper"] = {codepoint = 0xE6F7, description = "Board clapper"},
        ["luteItalianFret1"] = {codepoint = 0xEBE1, description = "First fret (1)"},
        ["accdnRH3RanksBandoneon"] = {codepoint = 0xE8AB, description = "Right hand, 3 ranks, 8' stop + 16' stop (bandoneón)"},
        ["accidentalFlatEqualTempered"] = {codepoint = 0xE2F1, description = "Flat equal tempered semitone"},
        ["mensuralRestBrevis"] = {codepoint = 0xE9F3, description = "Brevis rest"},
        ["doubleTongueBelow"] = {codepoint = 0xE5F1, description = "Double-tongue below"},
        ["scaleDegree8"] = {codepoint = 0xEF07, description = "Scale degree 8"},
        ["noteMeBlack"] = {codepoint = 0xEEF5, description = "Me (black note)"},
        ["noteMiHalf"] = {codepoint = 0xE15A, description = "Mi (half note)"},
        ["keyboardPedalParensRight"] = {codepoint = 0xE677, description = "Right parenthesis for pedal marking"},
        ["accSagittalSharp49SDown"] = {codepoint = 0xE3B2, description = "Sharp 49S-down"},
        ["pictMaraca"] = {codepoint = 0xE741, description = "Maraca"},
        ["accidentalNaturalSharp"] = {codepoint = 0xE268, description = "Natural sharp"},
        ["handbellsGyro"] = {codepoint = 0xE81D, description = "Gyro"},
        ["noteSeBlack"] = {codepoint = 0xEEF7, description = "Se (black note)"},
        ["fingeringRightParenthesisItalic"] = {codepoint = 0xED8B, description = "Fingering right parenthesis italic"},
        ["arpeggiatoDown"] = {codepoint = 0xE635, description = "Arpeggiato down"},
        ["fingeringPLower"] = {codepoint = 0xED17, description = "Fingering p (pulgar; right-hand thumb for guitar)"},
        ["accidentalReversedFlatArrowUp"] = {codepoint = 0xE290, description = "Reversed flat with arrow up"},
        ["noteShapeMoonBlack"] = {codepoint = 0xE1BD, description = "Moon black (Aikin 7-shape re)"},
        ["figbassNatural"] = {codepoint = 0xEA65, description = "Figured bass natural"},
        ["timeSigCut3"] = {codepoint = 0xEC86, description = "Cut triple time (9/8)"},
        ["kahnLeftFoot"] = {codepoint = 0xEDEE, description = "Left-foot"},
        ["articSoftAccentStaccatoAbove"] = {codepoint = 0xED42, description = "Soft accent-staccato above"},
        ["accidentalUpsAndDownsDown"] = {codepoint = 0xEE61, description = "Accidental down"},
        ["guitarString10"] = {codepoint = 0xE84A, description = "String number 10"},
        ["noteShapeTriangleRoundBlack"] = {codepoint = 0xE1BF, description = "Triangle-round black (Aikin 7-shape ti)"},
        ["arrowheadBlackRight"] = {codepoint = 0xEB7A, description = "Black arrowhead right (E)"},
        ["articStaccatoBelow"] = {codepoint = 0xE4A3, description = "Staccato below"},
        ["noteheadCircleXWhole"] = {codepoint = 0xE0B1, description = "Circle X whole"},
        ["noteheadCircledBlackLarge"] = {codepoint = 0xE0E8, description = "Black notehead in large circle"},
        ["harpSalzedoIsolatedSounds"] = {codepoint = 0xE69C, description = "Isolated sounds (Salzedo)"},
        ["chantPodatusUpper"] = {codepoint = 0xE9B1, description = "Podatus, upper"},
        ["articStressAbove"] = {codepoint = 0xE4B6, description = "Stress above"},
        ["chantCustosStemDownPosMiddle"] = {codepoint = 0xEA07, description = "Plainchant custos, stem down, middle position"},
        ["noteheadDiamondDoubleWhole"] = {codepoint = 0xE0D7, description = "Diamond double whole notehead"},
        ["noteheadCowellEleventhSeriesBlack"] = {codepoint = 0xEEAF, description = "2/11 note (eleventh note series, Cowell)"},
        ["noteheadCowellFifteenthNoteSeriesWhole"] = {codepoint = 0xEEB3, description = "8/15 note (fifteenth note series, Cowell)"},
        ["accidentalThreeQuarterTonesSharpStein"] = {codepoint = 0xE283, description = "One and a half sharps (three-quarter-tones sharp) (Stein)"},
        ["noteheadCowellSeventhNoteSeriesBlack"] = {codepoint = 0xEEA9, description = "1/7 note (seventh note series, Cowell)"},
        ["accidentalSharpTwoArrowsDown"] = {codepoint = 0xE2CD, description = "Sharp lowered by two syntonic commas"},
        ["accSagittal11MediumDiesisUp"] = {codepoint = 0xE30A, description = "11 medium diesis up, (11M), 1°[17 31] 2°46 up, 1/4-tone up"},
        ["mensuralNoteheadSemibrevisVoid"] = {codepoint = 0xE939, description = "Semibrevis notehead, void"},
        ["luteGermanLLower"] = {codepoint = 0xEC0A, description = "5th course, 3rd fret (l)"},
        ["noteShapeQuarterMoonDoubleWhole"] = {codepoint = 0xECD9, description = "Quarter moon double whole (Walker 7-shape re)"},
        ["metNote8thUp"] = {codepoint = 0xECA7, description = "Eighth note (quaver) stem up"},
        ["noteheadClusterWhole2nd"] = {codepoint = 0xE125, description = "Whole note cluster, 2nd"},
        ["noteheadDiamondHalfWide"] = {codepoint = 0xE0DA, description = "Diamond half notehead (wide)"},
        ["accSagittalDoubleFlat5v19CUp"] = {codepoint = 0xE385, description = "Double flat 5:19C-up, 19/20-tone down"},
        ["noteheadRoundWhiteSlashed"] = {codepoint = 0xE119, description = "Round white notehead, slashed"},
        ["noteheadSlashVerticalEndsMuted"] = {codepoint = 0xE107, description = "Muted slash with vertical ends"},
        ["noteheadDiamondOpen"] = {codepoint = 0xE0FC, description = "Open diamond notehead"},
        ["medRenPlicaCMN"] = {codepoint = 0xEA23, description = "Plica"},
        ["accidentalRaiseOneUndecimalQuartertone"] = {codepoint = 0xE2E3, description = "Raise by one undecimal quartertone"},
        ["beamAccelRit2"] = { codepoint = 0xEAF5, description = "Accel./rit. beam 2" },

        ["pictTomTomChinesePeinkofer"] = { codepoint = 0xF4AD, description = "Chinese tom-tom (Peinkofer/Tannigel)" },
        ["chordOmit5"] = { codepoint = 0xF891, description = "Chord omit 5" },
        ["dynamicCrescendoHairpinLong"] = { codepoint = 0xF750, description = "Dynamic crescendo hairpin long" },
        ["chordm7alt"] = { codepoint = 0xF894, description = "Chord M7 (alternate)" },
        ["stringsUpBowLegacy"] = { codepoint = 0xF633, description = "Strings up bow (legacy)" },
        ["accidentalFlatJohnstonDown"] = { codepoint = 0xF5DF, description = "Flat-down arrow (Johnston)" },
        ["noteheadVoidWithXLV5"] = { codepoint = 0xF7A6, description = "Notehead void with x l v5" },
        ["accidentalSharpJohnstonDownEl"] = { codepoint = 0xF5E7, description = "Sharp-down arrow-inverted seven (Johnston)" },
        ["chord13#9"] = { codepoint = 0xF878, description = "Chord 13(#9)" },
        ["fClefFrench"] = { codepoint = 0xF406, description = "F clef (French, 18th century)" },
        ["note16thDownWide"] = { codepoint = 0xF60C, description = "Note 16th down wide" },
        ["noteheadDoubleWholeWide"] = { codepoint = 0xF600, description = "Notehead double whole wide" },
        ["noteheadPlusBlackLVLegacy"] = { codepoint = 0xF8ED, description = "Notehead plus black l v (legacy)" },
        ["chordDM7"] = { codepoint = 0xF88B, description = "Chord d(M7) (diminished)" },
        ["chordMin"] = { codepoint = 0xF8B0, description = "Chord min" },
        ["textEnclosureSegmentArrowJogDown"] = { codepoint = 0xF81D, description = "Text enclosure segment arrow jog down" },
        ["gClefFlat7Below"] = { codepoint = 0xF55C, description = "G Clef (flat 7 below)" },
        ["accidentalFlatJohnstonUp"] = { codepoint = 0xF5DE, description = "Flat-up arrow (Johnston)" },
        ["chordD7#9"] = { codepoint = 0xF889, description = "Chord d7(#9) (diminished)" },
        ["chord#9b13"] = { codepoint = 0xF89C, description = "Chord #9/b13" },
        ["miscCodaMonk"] = { codepoint = 0xF7C2, description = "Coda guitar monk" },
        ["chord7#11b9"] = { codepoint = 0xF871, description = "Chord 7 (#11/b9)" },
        ["pictMaracaSmithBrindle"] = { codepoint = 0xF43C, description = "Maraca (Smith Brindle)" },
        ["noteheadCircledXLargeLV1"] = { codepoint = 0xF79E, description = "Notehead circled x large l v1" },
        ["chordD7b9"] = { codepoint = 0xF888, description = "Chord d7(b9) (diminished)" },
        ["conductorBeat2SimpleLegacy1"] = { codepoint = 0xF7BB, description = "Conductor beat 2 simple (legacy 1)" },
        ["flag8thDownAlt"] = { codepoint = 0xF704, description = "Flag 8th down alt" },
        ["pictCastanetsSmithBrindle"] = { codepoint = 0xF439, description = "Castanets (Smith Brindle)" },
        ["arrowDownMedium"] = { codepoint = 0xF77A, description = "Arrow down medium" },
        ["textEnclosureSegmentCUrvedArrowShort"] = { codepoint = 0xF819, description = "Text enclosure segment c urved arrow short" },
        ["noteheadXBlackLegacy"] = { codepoint = 0xF611, description = "Notehead x black (legacy)" },
        ["pictBongosPeinkofer"] = { codepoint = 0xF4B0, description = "Bongos (Peinkofer/Tannigel)" },
        ["chordMi13#11"] = { codepoint = 0xF8BB, description = "Chord mi13(#11)" },
        ["chordMa13#11"] = { codepoint = 0xF8AA, description = "Chord ma13(#11)" },
        ["arpeggioArrowDownMedium"] = { codepoint = 0xF774, description = "Arpeggio arrow down medium" },
        ["noteheadTriangleLeftWhiteLVLegacy"] = { codepoint = 0xF8F5, description = "Notehead triangle left white l v (legacy)" },
        ["gClef7Below"] = { codepoint = 0xF547, description = "G Clef (7 below)" },
        ["enclosureParenUnderlineLeft"] = { codepoint = 0xF72F, description = "Enclosure paren underline left" },
        ["gClefFlat8Above"] = { codepoint = 0xF55D, description = "G Clef (flat 8 above)" },
        ["gClef3Below"] = { codepoint = 0xF53F, description = "G Clef (3 below)" },
        ["chordMa69"] = { codepoint = 0xF8CA, description = "Chord ma6/9" },
        ["accidentalDoubleSharpParenthesesSmall"] = { codepoint = 0xF715, description = "Double sharp (parentheses small)" },
        ["chordM9#11"] = { codepoint = 0xF842, description = "Chord M9(#11)" },
        ["gClef12Below"] = { codepoint = 0xF536, description = "G Clef (12 below)" },
        ["chord-11M7"] = { codepoint = 0xF862, description = "Chord -11(M7)" },
        ["noteheadHalfDouble"] = { codepoint = 0xF781, description = "Notehead half double" },
        ["pictCowBellBerio"] = { codepoint = 0xF43B, description = "Cow bell (Berio)" },
        ["enclosureRehersalU"] = { codepoint = 0xF835, description = "Enclosure rehersal u" },
        ["chordD7"] = { codepoint = 0xF887, description = "Chord d7 (diminished)" },
        ["tremolo4Legacy"] = { codepoint = 0xF683, description = "Tremolo 4 (legacy)" },
        ["noteheadHalfLVLegacy"] = { codepoint = 0xF8D8, description = "Notehead half l v (legacy)" },
        ["chordMi69"] = { codepoint = 0xF8B3, description = "Chord mi6/9" },
        ["chordM69#11"] = { codepoint = 0xF843, description = "Chord m6/9(#11)" },
        ["ornamentTrillFlatAbove"] = { codepoint = 0xF5B2, description = "Trill (flat above)" },
        ["noteheadHalfLV4"] = { codepoint = 0xF78F, description = "Notehead half l v4" },
        ["chord13"] = { codepoint = 0xF8D6, description = "Chord 13" },
        ["accidentalSharpJohnstonUpEl"] = { codepoint = 0xF5E6, description = "Sharp-up arrow-inverted seven (Johnston)" },
        ["chord9"] = { codepoint = 0xF8D4, description = "Chord 9" },
        ["noteheadVoidWithXLV6"] = { codepoint = 0xF7A7, description = "Notehead void with x l v6" },
        ["articMarcatoStaccatoAboveLegacy"] = { codepoint = 0xF62D, description = "Marcato-staccato above (legacy)" },
        ["enclosureRehersalN"] = { codepoint = 0xF82E, description = "Enclosure rehersal n" },
        ["gClefFlat6Below"] = { codepoint = 0xF55A, description = "G Clef (flat 6 below)" },
        ["noteheadDoubleWholeLongWings"] = { codepoint = 0xF689, description = "Notehead double whole long wings" },
        ["flag1024thUpStraight"] = { codepoint = 0xF424, description = "Combining flag 8 (1024th) above (straight)" },
        ["chord+9"] = { codepoint = 0xF87E, description = "Chord +9" },
        ["noteheadHalfLV2"] = { codepoint = 0xF78D, description = "Notehead half l v2" },
        ["arrowUpLong"] = { codepoint = 0xF778, description = "Arrow up long" },
        ["noteheadHalfLV3"] = { codepoint = 0xF78E, description = "Notehead half l v3" },
        ["chordM13"] = { codepoint = 0xF83F, description = "Chord m13" },
        ["chordAdd2"] = { codepoint = 0xF8C4, description = "Chord add2" },
        ["chord7#11#9"] = { codepoint = 0xF872, description = "Chord 7(#11/#9)" },
        ["enclosureRehersalZ"] = { codepoint = 0xF83A, description = "Enclosure rehersal z" },
        ["noteheadSquareBlackLVLegacy"] = { codepoint = 0xF8E0, description = "Notehead square black l v (legacy)" },
        ["enclosureRehersalQ"] = { codepoint = 0xF831, description = "Enclosure rehersal q" },
        ["noteheadwholeDouble"] = { codepoint = 0xF780, description = "Noteheadwhole double" },
        ["laissezVibrer"] = { codepoint = 0xF765, description = "Laissez vibrer" },
        ["articTenutoStaccatoBelowLegacy"] = { codepoint = 0xF636, description = "Tenuto-staccato below (legacy)" },
        ["flag128thUpStraight"] = { codepoint = 0xF41B, description = "Combining flag 5 (128th) above (straight)" },
        ["miscEyeglassesAlt2"] = { codepoint = 0xF686, description = "Eyeglasses 2.0" },
        ["enclosureBracketWavyRightLong"] = { codepoint = 0xF740, description = "Enclosure bracket wavy right long" },
        ["accidentalDoubleFlatSmall"] = { codepoint = 0xF714, description = "Double flat (small)" },
        ["enclosureRehersalB"] = { codepoint = 0xF822, description = "Enclosure rehersal b" },
        ["chordH-d7"] = { codepoint = 0xF88D, description = "Chord half-diminished7" },
        ["chord+7#9"] = { codepoint = 0xF87C, description = "Chord +7(#9)" },
        ["analyticsModulationCombiningBracketRight"] = { codepoint = 0xF7E5, description = "Analytics modulation combining bracket (right)" },
        ["analyticsArrowSegmentRight"] = { codepoint = 0xF7ED, description = "Analytics arrow (right)" },
        ["chord#9b5"] = { codepoint = 0xF89A, description = "Chord #9/b5" },
        ["chord-11b9b5"] = { codepoint = 0xF85F, description = "Chord -11(b9/b5)" },
        ["noteheadBlackLV8"] = { codepoint = 0xF79C, description = "Notehead black l v8" },
        ["noteheadSquareBlackLegacy"] = { codepoint = 0xF615, description = "Notehead square black (legacy)" },
        ["pictVibMotorOffPeinkofer"] = { codepoint = 0xF4A6, description = "Metallophone (vibraphone motor off) (Peinkofer/Tannigel)" },
        ["textEnclosureSegmentExtension"] = { codepoint = 0xF812, description = "Text enclosure segment extension" },
        ["chord7Sus"] = { codepoint = 0xF84D, description = "Chord 7sus" },
        ["enclosureRehersalF"] = { codepoint = 0xF826, description = "Enclosure rehersal f" },
        ["chordM7#11"] = { codepoint = 0xF841, description = "Chord M7/#11" },
        ["gClefNatural7Above"] = { codepoint = 0xF569, description = "G Clef (natural 7 above)" },
        ["chord7b9b13"] = { codepoint = 0xF869, description = "Chord 7(b9/b13)" },
        ["noteheadSlashVerticalEndsLegacy"] = { codepoint = 0xF628, description = "Notehead slash vertical ends (legacy)" },
        ["noteheadCircledBlackLargeLVLegacy"] = { codepoint = 0xF8EB, description = "Notehead circled black large l v (legacy)" },
        ["gClef2Below"] = { codepoint = 0xF53D, description = "G Clef (2 below)" },
        ["noteheadWholeLV6"] = { codepoint = 0xF788, description = "Notehead whole l v6" },
        ["chordMi9"] = { codepoint = 0xF8B5, description = "Chord mi9" },
        ["pictBassDrumPeinkofer"] = { codepoint = 0xF4AF, description = "Bass drum (Peinkofer/Tannigel)" },
        ["chord13#11"] = { codepoint = 0xF87A, description = "Chord 13(#11)" },
        ["chordM13#11"] = { codepoint = 0xF845, description = "Chord m13(#11)" },
        ["chord-13"] = { codepoint = 0xF859, description = "Chord -13" },
        ["noteheadDiamondWholeOldLVLegacy"] = { codepoint = 0xF8F8, description = "Notehead diamond whole old l v (legacy)" },
        ["chord2"] = { codepoint = 0xF8CD, description = "Chord 2" },
        ["accidentalSharpJohnstonUp"] = { codepoint = 0xF5DB, description = "Sharp-up arrow (Johnston)" },
        ["repeat1BarLegacy"] = { codepoint = 0xF674, description = "Repeat 1 bar (legacy)" },
        ["chord7#9b5"] = { codepoint = 0xF86F, description = "Chord 7(#9/b5)" },
        ["noteheadSlashWhiteWholeLegacy"] = { codepoint = 0xF7AA, description = "Notehead slash white whole (legacy)" },
        ["note16thUpWide"] = { codepoint = 0xF60B, description = "Note 16th up wide" },
        ["accidentalJohnstonSevenUp"] = { codepoint = 0xF5E2, description = "Seven-up arrow (Johnston)" },
        ["restHBarAngled"] = { codepoint = 0xF766, description = "Rest h bar angled" },
        ["tremolo3Alt2"] = { codepoint = 0xF7B7, description = "Tremolo 3 alt 2" },
        ["enclosureParenOverLeft2Long"] = { codepoint = 0xF744, description = "Enclosure paren over left 2 long" },
        ["chordSus4"] = { codepoint = 0xF84B, description = "Chord sus4" },
        ["noteheadBlackLV3"] = { codepoint = 0xF797, description = "Notehead black l v3" },
        ["accidentalNaturalParens"] = { codepoint = 0xF5D6, description = "Natural (parentheses)" },
        ["gClef3Above"] = { codepoint = 0xF53E, description = "G Clef (3 above)" },
        ["brassFallRoughShortSlightDecline"] = { codepoint = 0xF762, description = "Brass fall rough short slight decline" },
        ["textEnclosureCurvedArrow"] = { codepoint = 0xF814, description = "Text enclosure curved arrow" },
        ["analyticsLongExtension"] = { codepoint = 0xF7E3, description = "Analytics long extension" },
        ["chordOmit3"] = { codepoint = 0xF892, description = "Chord omit 3" },
        ["accidentalDoubleSharpSmall"] = { codepoint = 0xF710, description = "Double sharp (small)" },
        ["analyticsArrowRightSegment"] = { codepoint = 0xF7E9, description = "Analytics arrow segment (right)" },
        ["chordNo3rd"] = { codepoint = 0xF8C8, description = "Chord no 3rd" },
        ["noteheadTriangleLeftWhiteLegacy"] = { codepoint = 0xF618, description = "Notehead triangle left white (legacy)" },
        ["enclosureParenUnderlineExtensionLong"] = { codepoint = 0xF739, description = "Enclosure paren underline extension long" },
        ["noteQuarterDownSmall"] = { codepoint = 0xF707, description = "Note quarter down small" },
        ["chord+M9"] = { codepoint = 0xF880, description = "Chord +(M9)" },
        ["chord-9M7#11"] = { codepoint = 0xF863, description = "Chord -9(M7/#11)" },
        ["noteQuarterUpWide"] = { codepoint = 0xF607, description = "Note quarter up wide" },
        ["gClefSharp5Below"] = { codepoint = 0xF56F, description = "G Clef (sharp 5 below)" },
        ["noteheadCircleX3LVLegacy"] = { codepoint = 0xF8DC, description = "Notehead circle x3 l v (legacy)" },
        ["noteheadXLV2"] = { codepoint = 0xF7AD, description = "Notehead x l v2" },
        ["noteheadCircledXLargeLV4"] = { codepoint = 0xF7A1, description = "Notehead circled x large l v4" },
        ["gClefNatural10Below"] = { codepoint = 0xF561, description = "G Clef (natural 10 below)" },
        ["pictMarPeinkofer"] = { codepoint = 0xF4AB, description = "Marimba (Peinkofer/Tannigel)" },
        ["accidentalFlatParenthesesSmall"] = { codepoint = 0xF718, description = "Flat (parentheses small)" },
        ["chord1"] = { codepoint = 0xF8CC, description = "Chord 1" },
        ["gClef8Above"] = { codepoint = 0xF548, description = "G Clef (8 above)" },
        ["accidentalTripleFlatJoinedStems"] = { codepoint = 0xF4A2, description = "Triple flat (joined stems)" },
        ["chord7Sus4"] = { codepoint = 0xF84F, description = "Chord 7sus4" },
        ["noteheadBlackWide"] = { codepoint = 0xF604, description = "Notehead black wide" },
        ["enclosureRehersalA"] = { codepoint = 0xF821, description = "Enclosure rehersal a" },
        ["ornamentTrillSharpAbove"] = { codepoint = 0xF5B4, description = "Trill (sharp above)" },
        ["noteheadHalfLV7"] = { codepoint = 0xF792, description = "Notehead half l v7" },
        ["accidentalSharpJohnstonDown"] = { codepoint = 0xF5DC, description = "Sharp-down arrow (Johnston)" },
        ["noteheadDoubleWholeAlt2"] = { codepoint = 0xF43F, description = "Notehead double whole alt 2" },
        ["pictXylBassPeinkofer"] = { codepoint = 0xF4A3, description = "Bass xylophone (Peinkofer/Tannigel)" },
        ["flag256thUpStraight"] = { codepoint = 0xF41E, description = "Combining flag 6 (256th) above (straight)" },
        ["noteQuarterDownWide"] = { codepoint = 0xF608, description = "Note quarter down wide" },
        ["gClef14Below"] = { codepoint = 0xF538, description = "G Clef (14 below)" },
        ["flag8thUpStraight"] = { codepoint = 0xF40F, description = "Combining flag 1 (8th) above (straight)" },
        ["arrowUpShort"] = { codepoint = 0xF776, description = "Arrow up short" },
        ["chordMa7"] = { codepoint = 0xF8A4, description = "Chord ma7" },
        ["enclosureRehersalG"] = { codepoint = 0xF827, description = "Enclosure rehersal g" },
        ["noteheadDiamondBlackLVLegacy"] = { codepoint = 0xF8E3, description = "Notehead diamond black l v (legacy)" },
        ["chordMi6"] = { codepoint = 0xF8B2, description = "Chord mi6" },
        ["enclosureRehersalT"] = { codepoint = 0xF834, description = "Enclosure rehersal t" },
        ["chord7Sus4b9"] = { codepoint = 0xF850, description = "Chord 7sus4(b9)" },
        ["handbellsGyroAlt"] = { codepoint = 0xF688, description = "Handbells gyro alt" },
        ["gClefNatural3Above"] = { codepoint = 0xF565, description = "G Clef (natural 3 above)" },
        ["chordDimM7"] = { codepoint = 0xF88A, description = "Chord dim(M7)" },
        ["gClefNatural6Below"] = { codepoint = 0xF568, description = "G Clef (natural 6 below)" },
        ["dynamicDiminuendoHairpinLong"] = { codepoint = 0xF751, description = "Dynamic diminuendo hairpin long" },
        ["textEnclosureSegmentJogUp"] = { codepoint = 0xF811, description = "Text enclosure segment jog up" },
        ["accidentalDoubleFlatJoinedStems"] = { codepoint = 0xF4A1, description = "Double flat (joined stems)" },
        ["6stringTabClefSerif"] = { codepoint = 0xF40B, description = "6-string tab clef (serif)" },
        ["flag32ndDownStraight"] = { codepoint = 0xF417, description = "Combining flag 3 (32nd) below (straight)" },
        ["4stringTabClefSerif"] = { codepoint = 0xF40D, description = "4-string tab clef (serif)" },
        ["gClefNatural17Below"] = { codepoint = 0xF563, description = "G Clef (natural 17 below)" },
        ["noteheadWholeLV7"] = { codepoint = 0xF789, description = "Notehead whole l v7" },
        ["ornamentTurnSharpAboveFlatBelow"] = { codepoint = 0xF5BB, description = "Turn (sharp above, flat below)" },
        ["enclosureParenUnderlineLeftLongAlt"] = { codepoint = 0xF738, description = "Enclosure paren underline left long alt" },
        ["noteheadTriangleDownBlackLVLegacy"] = { codepoint = 0xF8E9, description = "Notehead triangle down black l v (legacy)" },
        ["analyticsHauptrhythmusR"] = { codepoint = 0xF4B9, description = "Hauptrhythmus R (Berg)" },
        ["enclosureRehersalR"] = { codepoint = 0xF832, description = "Enclosure rehersal r" },
        ["analyticsModulationCombiningBracketLeft"] = { codepoint = 0xF7E0, description = "Analytics modulation combining bracket (left)" },
        ["articTenutoAccentAboveLegacy"] = { codepoint = 0xF630, description = "Tenuto-accent above (legacy)" },
        ["chord-11"] = { codepoint = 0xF858, description = "Chord -11" },
        ["noteheadXLV6"] = { codepoint = 0xF7B1, description = "Notehead x l v6" },
        ["chord7#9"] = { codepoint = 0xF868, description = "Chord 7(#9)" },
        ["noteQuarterUpSmall"] = { codepoint = 0xF706, description = "Note quarter up small" },
        ["textBlackNoteMiddleTripletNote"] = { codepoint = 0xF7CB, description = "Text black note middle triplet note" },
        ["timeSig5Large"] = { codepoint = 0xF445, description = "Time signature 5 (outside staff)" },
        ["legacyX"] = { codepoint = 0xF820, description = "x (legacy)" },
        ["noteheadTriangleRightWhiteLegacy"] = { codepoint = 0xF619, description = "Notehead triangle right white (legacy)" },
        ["noteheadBlackDouble"] = { codepoint = 0xF782, description = "Notehead black double" },
        ["enclosureRehersalI"] = { codepoint = 0xF829, description = "Enclosure rehersal i" },
        ["noteheadCircledXLargeLV3"] = { codepoint = 0xF7A0, description = "Notehead circled x large l v3" },
        ["chordSus2"] = { codepoint = 0xF852, description = "Chord sus2" },
        ["noteheadParenthesisAlt"] = { codepoint = 0xF74C, description = "Notehead parenthesis alt" },
        ["noteheadPlusBlackLegacy"] = { codepoint = 0xF627, description = "Notehead plus black (legacy)" },
        ["flag64thDownStraight"] = { codepoint = 0xF41A, description = "Combining flag 4 (64th) below (straight)" },
        ["accidentalSharpParenthesesSmall"] = { codepoint = 0xF716, description = "Sharp (parentheses small)" },
        ["chord#11b9"] = { codepoint = 0xF89E, description = "Chord #11/b9" },
        ["noteheadBlackLV2"] = { codepoint = 0xF796, description = "Notehead black l v2" },
        ["noteheadXLV3"] = { codepoint = 0xF7AE, description = "Notehead x l v3" },
        ["note8thDownWide"] = { codepoint = 0xF60A, description = "Note 8th down wide" },
        ["gClef13Below"] = { codepoint = 0xF537, description = "G Clef (13 below)" },
        ["enclosureRehersalY"] = { codepoint = 0xF839, description = "Enclosure rehersal y" },
        ["brassFallRoughVeryShortFastDecline"] = { codepoint = 0xF760, description = "Brass fall rough very short fast decline" },
        ["chordM7#5"] = { codepoint = 0xF847, description = "Chord M7(#5)" },
        ["chord-69#11"] = { codepoint = 0xF864, description = "Chord -6/9(#11)" },
        ["articAccentAboveLegacy"] = { codepoint = 0xF632, description = "Accent above (legacy)" },
        ["chordMa9#11"] = { codepoint = 0xF8A8, description = "Chord ma9(#11)" },
        ["chord+M7"] = { codepoint = 0xF87F, description = "Chord +(M7)" },
        ["enclosureParenUnderlineRightShort"] = { codepoint = 0xF737, description = "Enclosure paren underline right short" },
        ["noteheadCircleX1LVLegacy"] = { codepoint = 0xF8DA, description = "Notehead circle x1 l v (legacy)" },
        ["noteheadTriangleUpRightWhiteLegacy"] = { codepoint = 0xF61A, description = "Notehead triangle up right white (legacy)" },
        ["gClefFlat13Below"] = { codepoint = 0xF54E, description = "G Clef (flat 13 below)" },
        ["arrowDownLong"] = { codepoint = 0xF77B, description = "Arrow down long" },
        ["noteheadBlackLV7"] = { codepoint = 0xF79B, description = "Notehead black l v7" },
        ["gClef2Above"] = { codepoint = 0xF53C, description = "G Clef (2 above)" },
        ["accidentalFlatJohnstonElDown"] = { codepoint = 0xF5EB, description = "Flat-inverted seven-down arrow (Johnston)" },
        ["braceSmall"] = { codepoint = 0xF400, description = "Brace (small)" },
        ["chord-7"] = { codepoint = 0xF856, description = "Chord -7" },
        ["gClefNatural13Below"] = { codepoint = 0xF562, description = "G Clef (natural 13 below)" },
        ["noteheadCircledHalfLargeLVLegacy"] = { codepoint = 0xF8F7, description = "Notehead circled half large l v (legacy)" },
        ["pluckedSnapPizzicatoBelowGerman"] = { codepoint = 0xF432, description = "Snap pizzicato below (German)" },
        ["flag8thUpAlt3"] = { codepoint = 0xF702, description = "Flag 8th up alt 3" },
        ["chord9Sus"] = { codepoint = 0xF84E, description = "Chord 9sus" },
        ["flag512thDownStraight"] = { codepoint = 0xF423, description = "Combining flag 7 (512th) below (straight)" },
        ["pictGuiroPeinkofer"] = { codepoint = 0xF4B5, description = "Guiro (Peinkofer/Tannigel)" },
        ["timeSig6Large"] = { codepoint = 0xF446, description = "Time signature 6 (outside staff)" },
        ["noteheadTriangleUpWhiteLVLegacy"] = { codepoint = 0xF8EF, description = "Notehead triangle up white l v (legacy)" },
        ["chord+7b9"] = { codepoint = 0xF866, description = "Chord +7(b9)" },
        ["textEnclosureCurvedArrowWHook"] = { codepoint = 0xF815, description = "Text enclosure curved arrow w hook" },
        ["analyticsModulationCombiningBracketCenter2"] = { codepoint = 0xF7E4, description = "Analytics modulation combining bracket (center)" },
        ["repeat2BarLegacy"] = { codepoint = 0xF675, description = "Repeat 2 bar (legacy)" },
        ["gClef6Above"] = { codepoint = 0xF544, description = "G Clef (6 above)" },
        ["noteheadBlackLV5"] = { codepoint = 0xF799, description = "Notehead black l v5" },
        ["handbellsEcho1Alt"] = { codepoint = 0xF687, description = "Handbells echo 1 alt" },
        ["gClefFlat9Above"] = { codepoint = 0xF55E, description = "G Clef (flat 9 above)" },
        ["chord-9b5"] = { codepoint = 0xF85B, description = "Chord -9(b5)" },
        ["gClefFlat15Below"] = { codepoint = 0xF550, description = "G Clef (flat 15 below)" },
        ["enclosureBracketLeftLong"] = { codepoint = 0xF729, description = "Enclosure bracket left long" },
        ["arpeggioArrowDownLong"] = { codepoint = 0xF775, description = "Arpeggio arrow down long" },
        ["enclosureBracketExtension"] = { codepoint = 0xF721, description = "Enclosure bracket extension" },
        ["chord0"] = { codepoint = 0xF8CB, description = "Chord 0" },
        ["chord-Add2"] = { codepoint = 0xF865, description = "Chord -(add2)" },
        ["textBlackNoteFracSingle16th"] = { codepoint = 0xF7D6, description = "Text black note frac single 16th" },
        ["brassLiftSlight"] = { codepoint = 0xF767, description = "Brass lift slight" },
        ["fClefAlt1"] = { codepoint = 0xF7D8, description = "F clef alt 1" },
        ["chord+7"] = { codepoint = 0xF87D, description = "Chord +7" },
        ["noteheadTriangleRightBlackLVLegacy"] = { codepoint = 0xF8E8, description = "Notehead triangle right black l v (legacy)" },
        ["enclosureRehersalK"] = { codepoint = 0xF82B, description = "Enclosure rehersal k" },
        ["analyticsBackwardArrowRightSegmentTall"] = { codepoint = 0xF7EB, description = "Analytics tall arrow segment (left)" },
        ["brassFallSmoothVeryLong"] = { codepoint = 0xF758, description = "Brass fall smooth very long" },
        ["noteheadVoidWithXLV3"] = { codepoint = 0xF7A4, description = "Notehead void with x l v3" },
        ["pictTomTomPeinkofer"] = { codepoint = 0xF4B2, description = "Tom-tom (Peinkofer/Tannigel)" },
        ["gClefFlat3Above"] = { codepoint = 0xF555, description = "G Clef (flat 3 above)" },
        ["noteheadWhiteParenthesisLVLegacy"] = { codepoint = 0xF8F6, description = "Notehead white parenthesis l v (legacy)" },
        ["chordMi11b9b5"] = { codepoint = 0xF8BD, description = "Chord mi11(b9/b5)" },
        ["enclosureParenOverRight2Alt"] = { codepoint = 0xF743, description = "Enclosure paren over right 2 alt" },
        ["noteheadDiamondBlackLVLegacyAlt"] = { codepoint = 0xF8EC, description = "Notehead diamond black l v (legacy alt)" },
        ["chordMi"] = { codepoint = 0xF8B1, description = "Chord mi (minor)" },
        ["noteheadDiamondHalfWideLVLegacy"] = { codepoint = 0xF8F0, description = "Notehead diamond half wide l v (legacy)" },
        ["chordMiM7"] = { codepoint = 0xF8BE, description = "Chord mi(M7)" },
        ["noteheadTriangleLeftBlackLVLegacy"] = { codepoint = 0xF8E7, description = "Notehead triangle left black l v (legacy)" },
        ["noteheadTriangleUpWhiteLegacy"] = { codepoint = 0xF616, description = "Notehead triangle up white (legacy)" },
        ["flag64thUpStraight"] = { codepoint = 0xF418, description = "Combining flag 4 (64th) above (straight)" },
        ["enclosureParenOverRight"] = { codepoint = 0xF725, description = "Enclosure paren over right" },
        ["gClefNatural3Below"] = { codepoint = 0xF566, description = "G Clef (natural 3 below)" },
        ["chordb9b13"] = { codepoint = 0xF89B, description = "Chord b9/b13" },
        ["analyticsModulationCombiningBracketRightLong"] = { codepoint = 0xF7E1, description = "Analytics modulation long combining bracket (right)" },
        ["chord4"] = { codepoint = 0xF8CF, description = "Chord 4" },
        ["gClefFlat14Below"] = { codepoint = 0xF54F, description = "G Clef (flat 14 below)" },
        ["brassLiftSmoothVeryLong"] = { codepoint = 0xF757, description = "Brass lift smooth very long" },
        ["chordM9b5"] = { codepoint = 0xF848, description = "Chord M9(b5)" },
        ["chordMa9"] = { codepoint = 0xF8A5, description = "Chord ma9" },
        ["chord7#11#9Alt"] = { codepoint = 0xF882, description = "Chord 7(#11/#9) (alternate)" },
        ["braceLarge"] = { codepoint = 0xF401, description = "Brace (large)" },
        ["chordMa9b5"] = { codepoint = 0xF8AD, description = "Chord ma9(b5)" },
        ["noteheadWholeLV2"] = { codepoint = 0xF784, description = "Notehead whole l v2" },
        ["chordDim7"] = { codepoint = 0xF885, description = "Chord dim7" },
        ["noteheadCircledXLargeLegacy"] = { codepoint = 0xF612, description = "Notehead circled x large (legacy)" },
        ["ventiduesimaBassaMbLegacy"] = { codepoint = 0xF67F, description = "Ventiduesima bassa mb (legacy)" },
        ["noteheadHalfLV6"] = { codepoint = 0xF791, description = "Notehead half l v6" },
        ["gClefFlat1Below"] = { codepoint = 0xF552, description = "G Clef (flat 1 below)" },
        ["noteheadTriangleUpRightWhiteLVLegacy"] = { codepoint = 0xF8F1, description = "Notehead triangle up right white l v (legacy)" },
        ["analyticsArrowShort"] = { codepoint = 0xF7EE, description = "Analytics short arrow (right)" },
        ["pictXylPeinkofer"] = { codepoint = 0xF4A9, description = "Xylophone (Peinkofer/Tannigel)" },
        ["gClefAlt4"] = { codepoint = 0xF7DB, description = "G clef alt 4" },
        ["chord-9"] = { codepoint = 0xF857, description = "Chord -9" },
        ["chordMaj"] = { codepoint = 0xF8A1, description = "Chord maj" },
        ["chordM7#11Alt"] = { codepoint = 0xF8A0, description = "Chord M7/#11 (alternate)" },
        ["noteheadBlackLV1"] = { codepoint = 0xF795, description = "Notehead black l v1" },
        ["brassFallRoughVeryShortSlightDecilne"] = { codepoint = 0xF75A, description = "Brass fall rough very short slight decilne" },
        ["enclosureClosedLong"] = { codepoint = 0xF74B, description = "Enclosure closed long" },
        ["chord7b9"] = { codepoint = 0xF867, description = "Chord 7(b9)" },
        ["chordMiAdd2"] = { codepoint = 0xF8C3, description = "Chord mi(add2)" },
        ["chordMa6"] = { codepoint = 0xF8A3, description = "Chord ma6" },
        ["brassFallRoughShortMedDecline"] = { codepoint = 0xF764, description = "Brass fall rough short med decline" },
        ["pictGuiroSevsay"] = { codepoint = 0xF4B4, description = "Guiro (Sevsay)" },
        ["metSwing"] = { codepoint = 0xF74F, description = "Met swing" },
        ["chordM7"] = { codepoint = 0xF83D, description = "Chord M7" },
        ["chord13b5"] = { codepoint = 0xF876, description = "Chord 13(b5)" },
        ["brassVeryLiftShort"] = { codepoint = 0xF75F, description = "Brass lift very short" },
        ["braceLarger"] = { codepoint = 0xF402, description = "Brace (larger)" },
        ["tremolo3Alt1"] = { codepoint = 0xF7B6, description = "Tremolo 3 alt 1" },
        ["ornamentTrillSharpAboveLegacy"] = { codepoint = 0xF68E, description = "Trill sharp above (legacy)" },
        ["gClefFlat7Above"] = { codepoint = 0xF55B, description = "G Clef (flat 7 above)" },
        ["textEnclosureSegmentExtensionLong"] = { codepoint = 0xF818, description = "Text enclosure segment extension long" },
        ["enclosureBracketRight"] = { codepoint = 0xF722, description = "Enclosure bracket right" },
        ["chord-9M7"] = { codepoint = 0xF861, description = "Chord -9(M7)" },
        ["noteheadWholeLV4"] = { codepoint = 0xF786, description = "Notehead whole l v4" },
        ["brassLiftShortSlightIncline"] = { codepoint = 0xF761, description = "Brass lift short slight incline" },
        ["enclosureBracketWavyLeftLong"] = { codepoint = 0xF73E, description = "Enclosure bracket wavy left long" },
        ["accidentalNaturalParenthesesSmall"] = { codepoint = 0xF717, description = "Natural (parentheses small)" },
        ["chordMajorTriadb5"] = { codepoint = 0xF88F, description = "Chord major triad (b5)" },
        ["6stringTabClefTall"] = { codepoint = 0xF40A, description = "6-string tab clef (tall)" },
        ["noteheadHalfWide"] = { codepoint = 0xF603, description = "Notehead half wide" },
        ["noteheadBlackLV6"] = { codepoint = 0xF79A, description = "Notehead black l v6" },
        ["4stringTabClefTall"] = { codepoint = 0xF40C, description = "4-string tab clef (tall)" },
        ["noteheadDoubleWholeAltWide"] = { codepoint = 0xF601, description = "Notehead double whole alt wide" },
        ["accidentalJohnstonSevenFlatDown"] = { codepoint = 0xF5ED, description = "Seven-flat-down arrow (Johnston)" },
        ["chord-13#11"] = { codepoint = 0xF85D, description = "Chord -13(#11)" },
        ["gClef16Below"] = { codepoint = 0xF53A, description = "G Clef (16 below)" },
        ["stringsChangeBowDirectionLiga"] = { codepoint = 0xF431, description = "Change bow direction, indeterminate (Pricope)" },
        ["chordSus"] = { codepoint = 0xF84A, description = "Chord sus" },
        ["miscLegacy1"] = { codepoint = 0xF7C1, description = "Misc (legacy 1)" },
        ["noteheadVoidWithXLV2"] = { codepoint = 0xF7A3, description = "Notehead void with x l v2" },
        ["enclosureParenOverLeft"] = { codepoint = 0xF723, description = "Enclosure paren over left" },
        ["analyticsBackwardArrowLeftSegment"] = { codepoint = 0xF7E7, description = "Analytics arrow (left)" },
        ["ventiduesimaLegacy"] = { codepoint = 0xF67D, description = "Ventiduesima (legacy)" },
        ["ventiduesimaAltaLegacy"] = { codepoint = 0xF67E, description = "Ventiduesima alta (legacy)" },
        ["unpitchedPercussionClef1Alt"] = { codepoint = 0xF409, description = "Unpitched percussion clef 1 (thick-thin)" },
        ["noteheadWholeLV5"] = { codepoint = 0xF787, description = "Notehead whole l v5" },
        ["gClefNatural6Above"] = { codepoint = 0xF567, description = "G Clef (natural 6 above)" },
        ["ottavaAltaLegacy"] = { codepoint = 0xF677, description = "Ottava alta (legacy)" },
        ["chord7b5"] = { codepoint = 0xF86B, description = "Chord 7(b5)" },
        ["tripleTongueAboveNoSlur"] = { codepoint = 0xF42F, description = "Triple-tongue above (no slur)" },
        ["flag128thDownStraight"] = { codepoint = 0xF41D, description = "Combining flag 5 (128th) below (straight)" },
        ["gClefNatural9Below"] = { codepoint = 0xF56B, description = "G Clef (natural 9 below)" },
        ["chordM9"] = { codepoint = 0xF83E, description = "Chord M9" },
        ["tremolo3Alt4"] = { codepoint = 0xF7B9, description = "Tremolo 3 alt 4" },
        ["braceFlat"] = { codepoint = 0xF403, description = "Brace (flat)" },
        ["timeSigCommonLarge"] = { codepoint = 0xF44A, description = "Common time (outside staff)" },
        ["tremolo3Alt3"] = { codepoint = 0xF7B8, description = "Tremolo 3 alt 3" },
        ["noteheadRoundWhiteLegacy"] = { codepoint = 0xF629, description = "Notehead round white (legacy)" },
        ["noteheadXLV4"] = { codepoint = 0xF7AF, description = "Notehead x l v4" },
        ["tremolo2Alt"] = { codepoint = 0xF681, description = "Tremolo 2 alt" },
        ["tremolo1Alt"] = { codepoint = 0xF680, description = "Tremolo 1 alt" },
        ["timeSigPlusLarge"] = { codepoint = 0xF44C, description = "Time signature + (outside staff)" },
        ["articTenutoAccentBelowLegacy"] = { codepoint = 0xF631, description = "Tenuto-accent below (legacy)" },
        ["chordMa"] = { codepoint = 0xF8A2, description = "Chord ma (major)" },
        ["timeSig9Large"] = { codepoint = 0xF449, description = "Time signature 9 (outside staff)" },
        ["timeSig8Large"] = { codepoint = 0xF448, description = "Time signature 8 (outside staff)" },
        ["timeSig7Large"] = { codepoint = 0xF447, description = "Time signature 7 (outside staff)" },
        ["timeSig4Large"] = { codepoint = 0xF444, description = "Time signature 4 (outside staff)" },
        ["chordb5"] = { codepoint = 0xF895, description = "Chord b5" },
        ["timeSig2Large"] = { codepoint = 0xF442, description = "Time signature 2 (outside staff)" },
        ["timeSig1Large"] = { codepoint = 0xF441, description = "Time signature 1 (outside staff)" },
        ["noteheadWholeLV9"] = { codepoint = 0xF78B, description = "Notehead whole l v9" },
        ["chordSus4b9"] = { codepoint = 0xF84C, description = "Chord sus4(b9)" },
        ["noteheadTriangleBlackLVLegacy"] = { codepoint = 0xF8E1, description = "Notehead triangle black l v (legacy)" },
        ["textEnclosureSegmentLeftHook"] = { codepoint = 0xF816, description = "Text enclosure segment left hook" },
        ["analyticsBackwardArrowRightSegment"] = { codepoint = 0xF7E8, description = "Analytics arrow segment (left)" },
        ["textEnclosureSegmentJogDown"] = { codepoint = 0xF810, description = "Text enclosure segment jog down" },
        ["noteheadMoonBlackLVLegacy"] = { codepoint = 0xF8E2, description = "Notehead moon black l v (legacy)" },
        ["textEnclosureSegmentCurvedArrowLong"] = { codepoint = 0xF81A, description = "Text enclosure segment curved arrow long" },
        ["enclosureRehersalV"] = { codepoint = 0xF836, description = "Enclosure rehersal v" },
        ["enclosureParenOverLeft2"] = { codepoint = 0xF72C, description = "Enclosure paren over left 2" },
        ["noteheadCircleX2LVLegacy"] = { codepoint = 0xF8DB, description = "Notehead circle x2 l v (legacy)" },
        ["textEnclosureSegmentArrowJogOver"] = { codepoint = 0xF81C, description = "Text enclosure segment arrow jog over" },
        ["textEnclosureSegmentArrowDown"] = { codepoint = 0xF81E, description = "Text enclosure segment arrow down" },
        ["textEnclosureSegmentArrow"] = { codepoint = 0xF813, description = "Text enclosure segment arrow" },
        ["chord#11"] = { codepoint = 0xF898, description = "Chord #11" },
        ["keyboardPedalSostNoDot"] = { codepoint = 0xF435, description = "Sostenuto pedal mark (no dot)" },
        ["noteheadMoonWhiteLegacy"] = { codepoint = 0xF61B, description = "Notehead moon white (legacy)" },
        ["doubleTongueBelowNoSlur"] = { codepoint = 0xF42E, description = "Double-tongue below (no slur)" },
        ["chordMi9M7"] = { codepoint = 0xF8BF, description = "Chord mi9(M7)" },
        ["chordMi11M7"] = { codepoint = 0xF8C0, description = "Chord mi11(M7)" },
        ["accidentalJohnstonSevenSharpDown"] = { codepoint = 0xF5E9, description = "Seven-sharp-down arrow (Johnston)" },
        ["chordH-d"] = { codepoint = 0xF88C, description = "Chord half-diminished" },
        ["gClefAlt2"] = { codepoint = 0xF7D9, description = "G clef alt 2" },
        ["pictCongaPeinkofer"] = { codepoint = 0xF4B1, description = "Conga (Peinkofer/Tannigel)" },
        ["textBlackNoteRightFacing16thBeam"] = { codepoint = 0xF7CA, description = "Text black note right facing 16th beam" },
        ["textBlackNoteFrac8thLongBeam"] = { codepoint = 0xF7D3, description = "Text black note frac 8th long beam" },
        ["textBlackNoteFrac32ndLongBeam"] = { codepoint = 0xF7D5, description = "Text black note frac 32nd long beam" },
        ["gClef11Below"] = { codepoint = 0xF535, description = "G Clef (11 below)" },
        ["restWholeLegacy"] = { codepoint = 0xF670, description = "Rest whole (legacy)" },
        ["chordMi11b5"] = { codepoint = 0xF8BA, description = "Chord mi11(b5)" },
        ["stringsDownBowLegacy"] = { codepoint = 0xF634, description = "Strings down bow (legacy)" },
        ["stringsChangeBowDirectionImposed"] = { codepoint = 0xF43E, description = "Change bow direction, indeterminate (Plötz)" },
        ["chord8"] = { codepoint = 0xF8D3, description = "Chord 8" },
        ["textBlackNoteFrac16thLongBeam"] = { codepoint = 0xF7D4, description = "Text black note frac 16th long beam" },
        ["restQuarterAlt1"] = { codepoint = 0xF7DC, description = "Rest quarter alt 1" },
        ["repeatRightLeftThick"] = { codepoint = 0xF45C, description = "Right and left repeat sign (thick-thick)" },
        ["quindicesimaLegacy2"] = { codepoint = 0xF67B, description = "Quindicesima (legacy 2)" },
        ["quindicesimaLegacy"] = { codepoint = 0xF67A, description = "Quindicesima (legacy)" },
        ["noteheadHalfParens"] = { codepoint = 0xF5D2, description = "Half notehead (parentheses)" },
        ["enclosureParenUnderlineLeftAlt2"] = { codepoint = 0xF747, description = "Enclosure paren underline left alt 2" },
        ["quindicesimaBassaMbLegacy"] = { codepoint = 0xF67C, description = "Quindicesima bassa mb (legacy)" },
        ["pluckedSnapPizzicatoAboveGerman"] = { codepoint = 0xF433, description = "Snap pizzicato above (German)" },
        ["gClefFlat9Below"] = { codepoint = 0xF55F, description = "G Clef (flat 9 below)" },
        ["mensuralProportion4Old"] = { codepoint = 0xF43D, description = "Mensural proportion 4 (old)" },
        ["pictXylTenorPeinkofer"] = { codepoint = 0xF4A4, description = "Tenor xylophone (Peinkofer/Tannigel)" },
        ["pictVibPeinkofer"] = { codepoint = 0xF4A5, description = "Vibraphone (Peinkofer/Tannigel)" },
        ["ornamentTurnNaturalAbove"] = { codepoint = 0xF5B8, description = "Turn (natural above)" },
        ["pictTubaphonePeinkofer"] = { codepoint = 0xF4A8, description = "Tubaphone (Peinkofer/Tannigel)" },
        ["pictTimpaniPeinkofer"] = { codepoint = 0xF4AE, description = "Timpani (Peinkofer/Tannigel)" },
        ["pictTimbalesPeinkofer"] = { codepoint = 0xF4B3, description = "Timbales (Peinkofer/Tannigel)" },
        ["chord#5"] = { codepoint = 0xF896, description = "Chord #5" },
        ["noteheadBlackParenthesisLVLegacy"] = { codepoint = 0xF8EA, description = "Notehead black parenthesis l v (legacy)" },
        ["enclosureUnderlineExtension"] = { codepoint = 0xF730, description = "Enclosure underline extension" },
        ["conductorBeat2SimpleLegacy2"] = { codepoint = 0xF7BC, description = "Conductor beat 2 simple (legacy 2)" },
        ["chorus1st"] = { codepoint = 0xF7C4, description = "Chorus 1st" },
        ["enclosureRehersalC"] = { codepoint = 0xF823, description = "Enclosure rehersal c" },
        ["chord69"] = { codepoint = 0xF83B, description = "Chord 6/9" },
        ["chordDim"] = { codepoint = 0xF884, description = "Chord dim" },
        ["pictMusicalSawPeinkofer"] = { codepoint = 0xF4B7, description = "Musical saw (Peinkofer/Tannigel)" },
        ["chordAug"] = { codepoint = 0xF881, description = "Chord aug" },
        ["chordM9#5"] = { codepoint = 0xF849, description = "Chord M9(#5)" },
        ["pictHalfOpen2Legacy"] = { codepoint = 0xF62A, description = "Pict half open 2 (legacy)" },
        ["accidentalDoubleFlatParenthesesSmall"] = { codepoint = 0xF719, description = "Double flat (parentheses small)" },
        ["pictGlspPeinkofer"] = { codepoint = 0xF4AA, description = "Glockenspiel (Peinkofer/Tannigel)" },
        ["note8thUpWide"] = { codepoint = 0xF609, description = "Note 8th up wide" },
        ["gClefFlat2Above"] = { codepoint = 0xF553, description = "G Clef (flat 2 above)" },
        ["pictFlexatonePeinkofer"] = { codepoint = 0xF4B6, description = "Flexatone (Peinkofer/Tannigel)" },
        ["noteheadDoubleWholeAltLongWings"] = { codepoint = 0xF68A, description = "Notehead double whole alt long wings" },
        ["ottavaLegacy"] = { codepoint = 0xF676, description = "Ottava (legacy)" },
        ["ornamentTurnSharpAbove"] = { codepoint = 0xF5BA, description = "Turn (sharp above)" },
        ["accidentalJohnstonDownEl"] = { codepoint = 0xF5E5, description = "Down arrow-inverted seven (Johnston)" },
        ["noteHalfDownWide"] = { codepoint = 0xF606, description = "Note half down wide" },
        ["noteheadDiamondWhiteLegacy"] = { codepoint = 0xF625, description = "Notehead diamond white (legacy)" },
        ["ottavaBassaVbLegacy"] = { codepoint = 0xF678, description = "Ottava bassa vb (legacy)" },
        ["ottavaBassaBaLegacy"] = { codepoint = 0xF679, description = "Ottava bassa ba (legacy)" },
        ["noteheadSquareWhiteLegacy2"] = { codepoint = 0xF614, description = "Notehead square white (legacy 2)" },
        ["enclosureParenUnderlineLeftLong"] = { codepoint = 0xF732, description = "Enclosure paren underline left long" },
        ["ornamentTurnSharpBelow"] = { codepoint = 0xF5BC, description = "Turn (sharp below)" },
        ["gClef6Below"] = { codepoint = 0xF545, description = "G Clef (6 below)" },
        ["ornamentTurnFlatBelow"] = { codepoint = 0xF5B7, description = "Turn (flat below)" },
        ["ornamentTurnFlatAboveSharpBelow"] = { codepoint = 0xF5B6, description = "Turn (flat above, sharp below)" },
        ["chordMi9M7#11"] = { codepoint = 0xF8C1, description = "Chord mi9(M7/#11)" },
        ["ornamentTurnFlatAbove"] = { codepoint = 0xF5B5, description = "Turn (flat above)" },
        ["chord11"] = { codepoint = 0xF8D5, description = "Chord 11" },
        ["ornamentTrillNaturalAbove"] = { codepoint = 0xF5B3, description = "Trill (Natural above)" },
        ["chordAdd9"] = { codepoint = 0xF8C6, description = "Chord add9" },
        ["gClefFlat6Above"] = { codepoint = 0xF559, description = "G Clef (flat 6 above)" },
        ["ornamentTrillFlatAboveLegacy"] = { codepoint = 0xF68C, description = "Trill flat above (legacy)" },
        ["accidentalFlatJohnstonUpEl"] = { codepoint = 0xF5EA, description = "Flat-up arrow-inverted seven (Johnston)" },
        ["noteheadXLV8"] = { codepoint = 0xF7B3, description = "Notehead x l v8" },
        ["noteheadXLV7"] = { codepoint = 0xF7B2, description = "Notehead x l v7" },
        ["noteheadSquareWhiteLegacy3"] = { codepoint = 0xF624, description = "Notehead square white (legacy 3)" },
        ["flag16thDownAlt"] = { codepoint = 0xF705, description = "Flag 16th down alt" },
        ["noteheadXLV5"] = { codepoint = 0xF7B0, description = "Notehead x l v5" },
        ["noteheadXLV1"] = { codepoint = 0xF7AC, description = "Notehead x l v1" },
        ["miscCodaLogo"] = { codepoint = 0xF7C3, description = "Coda logo" },
        ["enclosureBracketLeft"] = { codepoint = 0xF720, description = "Enclosure bracket left" },
        ["noteheadSquareBlackLVLegacyAlt"] = { codepoint = 0xF8E5, description = "Notehead square black l v (legacy alt)" },
        ["noteheadXBlack2LVLegacy"] = { codepoint = 0xF8DE, description = "Notehead x black2 l v (legacy)" },
        ["noteheadXBlack1LVLegacy"] = { codepoint = 0xF8DD, description = "Notehead x black1 l v (legacy)" },
        ["noteheadWholeWide"] = { codepoint = 0xF602, description = "Notehead whole wide" },
        ["noteheadWholeParens"] = { codepoint = 0xF5D3, description = "Whole notehead (parentheses)" },
        ["noteheadWholeLVJazz"] = { codepoint = 0xF8D7, description = "Notehead whole l v jazz" },
        ["noteheadWholeLV8"] = { codepoint = 0xF78A, description = "Notehead whole l v8" },
        ["noteheadTriangleDownWhiteLegacy"] = { codepoint = 0xF617, description = "Notehead triangle down white (legacy)" },
        ["noteheadWholeLV3"] = { codepoint = 0xF785, description = "Notehead whole l v3" },
        ["noteheadWholeLV1"] = { codepoint = 0xF783, description = "Notehead whole l v1" },
        ["gClef10Below"] = { codepoint = 0xF534, description = "G Clef (10 below)" },
        ["noteheadVoidWithXLV8"] = { codepoint = 0xF7A9, description = "Notehead void with x l v8" },
        ["breathMarkCommaLegacy"] = { codepoint = 0xF635, description = "Breath mark comma (legacy)" },
        ["noteheadRoundWhiteLVLegacy"] = { codepoint = 0xF8FB, description = "Notehead round white l v (legacy)" },
        ["noteheadVoidWithXLV4"] = { codepoint = 0xF7A5, description = "Notehead void with x l v4" },
        ["miscEyeglassesAlt1"] = { codepoint = 0xF685, description = "Eyeglasses 1.0" },
        ["chord7#11"] = { codepoint = 0xF86C, description = "Chord 7(#11)" },
        ["accidentalJohnstonSevenSharpUp"] = { codepoint = 0xF5E8, description = "Seven-sharp-up arrow (Johnston)" },
        ["noteheadTriangleUpRightBlackLVLegacy"] = { codepoint = 0xF8E4, description = "Notehead triangle up right black l v (legacy)" },
        ["noteheadHalfLV1"] = { codepoint = 0xF78C, description = "Notehead half l v1" },
        ["gClefNat2Below"] = { codepoint = 0xF560, description = "G Clef (natural 2 below)" },
        ["noteheadTriangleRoundDownWhiteLegacy"] = { codepoint = 0xF61C, description = "Notehead triangle round down white (legacy)" },
        ["noteheadTriangleRoundDownWhiteLVLegacy"] = { codepoint = 0xF8F2, description = "Notehead triangle round down white l v (legacy)" },
        ["noteheadTriangleRoundDownBlackLVLegacy"] = { codepoint = 0xF8E6, description = "Notehead triangle round down black l v (legacy)" },
        ["gClef9Above"] = { codepoint = 0xF54A, description = "G Clef (9 above)" },
        ["noteheadTriangleRightWhiteLVLegacy"] = { codepoint = 0xF8F3, description = "Notehead triangle right white l v (legacy)" },
        ["noteheadTriangleDownWhiteLVLegacy"] = { codepoint = 0xF8FA, description = "Notehead triangle down white l v (legacy)" },
        ["enclosureRehersalH"] = { codepoint = 0xF828, description = "Enclosure rehersal h" },
        ["arpeggioVerticalSegment"] = { codepoint = 0xF700, description = "Arpeggio vertical segment " },
        ["textTripletBracketFull"] = { codepoint = 0xF7D2, description = "Text triplet bracket full" },
        ["dynamicSforzandoLegacy"] = { codepoint = 0xF610, description = "Dynamic sforzando (legacy)" },
        ["gClef17Below"] = { codepoint = 0xF53B, description = "G Clef (17 below)" },
        ["chordb9b5"] = { codepoint = 0xF899, description = "Chord b9/b5" },
        ["arrowUpMedium"] = { codepoint = 0xF777, description = "Arrow up medium" },
        ["noteheadDoubleWholeParens"] = { codepoint = 0xF5D4, description = "Double whole notehead (parentheses)" },
        ["fretboard6StringLegacy"] = { codepoint = 0xF8FE, description = "Fretboard 6 string (legacy)" },
        ["noteheadDiamondWhiteWideLegacy"] = { codepoint = 0xF626, description = "Notehead diamond white wide (legacy)" },
        ["chord#9b9"] = { codepoint = 0xF89D, description = "Chord #9/b9" },
        ["flag8thDownStraight"] = { codepoint = 0xF411, description = "Combining flag 1 (8th) below (straight)" },
        ["arpeggioArrowUpShort"] = { codepoint = 0xF770, description = "Arpeggio arrow up short" },
        ["chordb9"] = { codepoint = 0xF893, description = "Chord b9" },
        ["flag8thUpAlt2"] = { codepoint = 0xF701, description = "Flag 8th up alt 2" },
        ["chord9#5"] = { codepoint = 0xF875, description = "Chord 9(#5)" },
        ["accidentalSharpJohnstonEl"] = { codepoint = 0xF5DA, description = "Sharp-inverted seven (Johnston)" },
        ["noteheadDoubleWholeAlt"] = { codepoint = 0xF40E, description = "Double whole note (breve), single vertical strokes" },
        ["tremolo3Alt"] = { codepoint = 0xF682, description = "Tremolo 3 alt" },
        ["flag8thDownAlt2"] = { codepoint = 0xF769, description = "Flag 8th down alt 2" },
        ["miscLegacy3"] = { codepoint = 0xF7CE, description = "Misc (legacy 3)" },
        ["noteheadVoidWithXLV7"] = { codepoint = 0xF7A8, description = "Notehead void with x l v7" },
        ["accdnPushAlt"] = { codepoint = 0xF45B, description = "Push (Draugsvoll & Højsgaard)" },
        ["noteheadMoonWhiteLVLegacy"] = { codepoint = 0xF8EE, description = "Notehead moon white l v (legacy)" },
        ["gClef9Below"] = { codepoint = 0xF54B, description = "G Clef (9 below)" },
        ["noteheadHalfLV9"] = { codepoint = 0xF794, description = "Notehead half l v9" },
        ["articAccentStaccatoBelowLegacy"] = { codepoint = 0xF62C, description = "Accent-staccato below (legacy)" },
        ["chord-69"] = { codepoint = 0xF855, description = "Chord -6/9" },
        ["noteheadCircledXLargeLV2"] = { codepoint = 0xF79F, description = "Notehead circled x large l v2" },
        ["accidentalJohnstonUpEl"] = { codepoint = 0xF5E4, description = "Up arrow-inverted seven (Johnston)" },
        ["noteheadHalfLV8"] = { codepoint = 0xF793, description = "Notehead half l v8" },
        ["enclosureRehersalJ"] = { codepoint = 0xF82A, description = "Enclosure rehersal j" },
        ["accidentalFlatParens"] = { codepoint = 0xF5D5, description = "Flat (parentheses)" },
        ["chord7Sus4b9Add3"] = { codepoint = 0xF851, description = "Chord 7sus4(b9)(add3)" },
        ["chordMi7"] = { codepoint = 0xF8B4, description = "Chord mi7" },
        ["noteheadBlackParens"] = { codepoint = 0xF5D1, description = "Closed notehead (parentheses)" },
        ["textEnclosureExtensionShort"] = { codepoint = 0xF817, description = "Text enclosure extension short" },
        ["noteheadBlackLV4"] = { codepoint = 0xF798, description = "Notehead black l v4" },
        ["noteHalfUpWide"] = { codepoint = 0xF605, description = "Note half up wide" },
        ["arpeggioArrowUpLong"] = { codepoint = 0xF772, description = "Arpeggio arrow up long" },
        ["enclosureParenUnderlineExtension"] = { codepoint = 0xF736, description = "Enclosure paren underline extension" },
        ["gClefNatural2Above"] = { codepoint = 0xF564, description = "G Clef (natural 2 above)" },
        ["accidentalSharpParens"] = { codepoint = 0xF5D7, description = "Sharp (parentheses)" },
        ["chordMa69#11"] = { codepoint = 0xF8A9, description = "Chord ma6/9(#11)" },
        ["chordM6"] = { codepoint = 0xF83C, description = "Chord m6" },
        ["chordM69"] = { codepoint = 0xF840, description = "Chord m6/9" },
        ["accidentalFlatSmall"] = { codepoint = 0xF713, description = "Flat (for small staves)" },
        ["chordMajorTriad"] = { codepoint = 0xF88E, description = "Chord major triad" },
        ["chord7#9#5"] = { codepoint = 0xF87B, description = "Chord 7(#9/#5)" },
        ["chord6"] = { codepoint = 0xF8D1, description = "Chord 6" },
        ["enclosureBracketExtensionShort"] = { codepoint = 0xF727, description = "Enclosure bracket extension short" },
        ["chordMi7b5"] = { codepoint = 0xF8B8, description = "Chord mi7(b5)" },
        ["guitarGolpeFlamenco"] = { codepoint = 0xF4B8, description = "Golpe (tapping the pick guard) (Vounelakos)" },
        ["chordMi69#11"] = { codepoint = 0xF8C2, description = "Chord mi6/9(#11)" },
        ["fClef19thCentury"] = { codepoint = 0xF407, description = "F clef (19th century)" },
        ["gClefFlat5Above"] = { codepoint = 0xF558, description = "G Clef (flat 5 above)" },
        ["articAccentStaccatoAboveLegacy"] = { codepoint = 0xF62B, description = "Accent-staccato above (legacy)" },
        ["flag256thDownStraight"] = { codepoint = 0xF420, description = "Combining flag 6 (256th) below (straight)" },
        ["pictLithophonePeinkofer"] = { codepoint = 0xF4A7, description = "Lithophone (Peinkofer/Tannigel)" },
        ["gClefFlat2Below"] = { codepoint = 0xF554, description = "G Clef (flat 2 below)" },
        ["chord7Alt"] = { codepoint = 0xF890, description = "Chord 7alt" },
        ["chord7#5"] = { codepoint = 0xF86D, description = "Chord 7(#5)" },
        ["chord5"] = { codepoint = 0xF8D0, description = "Chord 5" },
        ["chord69#11"] = { codepoint = 0xF844, description = "Chord 6/9(#11)" },
        ["chord7#9b9"] = { codepoint = 0xF870, description = "Chord 7(#9/b9)" },
        ["pictSleighBellSmithBrindle"] = { codepoint = 0xF43A, description = "Sleigh bell (Smith Brindle)" },
        ["cClefFrench"] = { codepoint = 0xF408, description = "C clef (French, 18th century)" },
        ["textEnclosureSegmentArrowJogUp"] = { codepoint = 0xF81B, description = "Text enclosure segment arrow jog up" },
        ["accidentalDoubleFlatParens"] = { codepoint = 0xF5D9, description = "Double flat (parentheses)" },
        ["chord#9"] = { codepoint = 0xF897, description = "Chord #9" },
        ["chord13b9"] = { codepoint = 0xF877, description = "Chord 13(b9)" },
        ["arrowDownShort"] = { codepoint = 0xF779, description = "Arrow down short" },
        ["chord7#9b13"] = { codepoint = 0xF86A, description = "Chord 7(#9/b13)" },
        ["analyticsArrowRightSegmentTall"] = { codepoint = 0xF7EC, description = "Analytics tall arrow segment (right)" },
        ["chordMa7#11"] = { codepoint = 0xF8A7, description = "Chord ma7(#11)" },
        ["accidentalJohnstonSevenFlatUp"] = { codepoint = 0xF5EC, description = "Seven-flat-up arrow (Johnston)" },
        ["chord-11b5"] = { codepoint = 0xF85C, description = "Chord -11(b5)" },
        ["flag16thUpStraight"] = { codepoint = 0xF412, description = "Combining flag 2 (16th) above (straight)" },
        ["accidentalSharpSmall"] = { codepoint = 0xF711, description = "Sharp (for small staves)" },
        ["flag16thDownStraight"] = { codepoint = 0xF414, description = "Combining flag 2 (16th) below (straight)" },
        ["tremolo5Legacy"] = { codepoint = 0xF684, description = "Tremolo 5 (legacy)" },
        ["chord9#11"] = { codepoint = 0xF874, description = "Chord 9(#11)" },
        ["noteheadSquareWhiteAltLVLegacy"] = { codepoint = 0xF8F4, description = "Notehead square white alt l v (legacy)" },
        ["chordMa9#5"] = { codepoint = 0xF8AE, description = "Chord ma9(#5)" },
        ["noteheadBlackLV9"] = { codepoint = 0xF79D, description = "Notehead black l v9" },
        ["arpeggioArrowUpMedium"] = { codepoint = 0xF771, description = "Arpeggio arrow up medium" },
        ["gClef0Below"] = { codepoint = 0xF533, description = "G Clef (0 below)" },
        ["keyboardPedalPedNoDot"] = { codepoint = 0xF434, description = "Pedal mark (no dot)" },
        ["gClefAlt3"] = { codepoint = 0xF7DA, description = "G clef alt 3" },
        ["enclosureRehersalL"] = { codepoint = 0xF82C, description = "Enclosure rehersal l" },
        ["enclosureBracketLeftShort"] = { codepoint = 0xF728, description = "Enclosure bracket left short" },
        ["accidentalDoubleSharpParens"] = { codepoint = 0xF5D8, description = "Double sharp (parentheses)" },
        ["enclosureRehersalW"] = { codepoint = 0xF837, description = "Enclosure rehersal w" },
        ["chordAdd3"] = { codepoint = 0xF8C5, description = "Chord add3" },
        ["enclosureRehersalM"] = { codepoint = 0xF82D, description = "Enclosure rehersal m" },
        ["chordD"] = { codepoint = 0xF886, description = "Chord d (diminished)" },
        ["timeSigCutCommonLarge"] = { codepoint = 0xF44B, description = "Cut time (outside staff)" },
        ["gClefSharp4Above"] = { codepoint = 0xF56E, description = "G Clef (sharp 4 above)" },
        ["brassLiftVeryShortMedIncline"] = { codepoint = 0xF75B, description = "Brass lift very short med incline" },
        ["chordLydian"] = { codepoint = 0xF853, description = "Chord lydian" },
        ["enclosureParenOverRight2"] = { codepoint = 0xF72E, description = "Enclosure paren over right 2" },
        ["enclosureBracketExtensionLong"] = { codepoint = 0xF73C, description = "Enclosure bracket extension long" },
        ["chordMa13"] = { codepoint = 0xF8A6, description = "Chord ma13" },
        ["gClef8Below"] = { codepoint = 0xF549, description = "G Clef (8 below)" },
        ["segnoJapanese"] = { codepoint = 0xF404, description = "Segno (Japanese style, rotated)" },
        ["enclosureParenOverExtensionLong"] = { codepoint = 0xF726, description = "Enclosure paren over extension long" },
        ["noteheadSquareWhiteLVLegacy"] = { codepoint = 0xF8F9, description = "Notehead square white l v (legacy)" },
        ["timeSig0Large"] = { codepoint = 0xF440, description = "Time signature 0 (outside staff)" },
        ["chorus2nd"] = { codepoint = 0xF7C5, description = "Chorus 2nd" },
        ["enclosureParenUnderlineExtensionAlt"] = { codepoint = 0xF748, description = "Enclosure paren underline extension alt" },
        ["analyticsBackwardArrowShort"] = { codepoint = 0xF7E6, description = "Analytics short arrow (left)" },
        ["enclosureParenOverExtension2"] = { codepoint = 0xF742, description = "Enclosure paren over extension 2" },
        ["chordM7b5"] = { codepoint = 0xF846, description = "Chord M7(b5)" },
        ["articMarcatoStaccatoBelowLegacy"] = { codepoint = 0xF62E, description = "Marcato-staccato below (legacy)" },
        ["chorus3rd"] = { codepoint = 0xF7C6, description = "Chorus 3rd" },
        ["chordAdd11"] = { codepoint = 0xF8C7, description = "Chord add11" },
        ["chorus4th"] = { codepoint = 0xF7C7, description = "Chorus 4th" },
        ["dynamicDiminuendoHairpinVeryLong"] = { codepoint = 0xF753, description = "Dynamic diminuendo hairpin very long" },
        ["pictTambourineStockhausen"] = { codepoint = 0xF438, description = "Tambourine (Stockhausen)" },
        ["chord7b9#5"] = { codepoint = 0xF883, description = "Chord 7(b9/#5)" },
        ["codaJapanese"] = { codepoint = 0xF405, description = "Coda (Japanese style, serif)" },
        ["conductorBeat3SimpleLegacy"] = { codepoint = 0xF7BD, description = "Conductor beat 3 simple (legacy)" },
        ["doubleTongueAboveNoSlur"] = { codepoint = 0xF42D, description = "Double-tongue above (no slur)" },
        ["dynamicCrescendoHairpinVeryLong"] = { codepoint = 0xF752, description = "Dynamic crescendo hairpin very long" },
        ["chordMa7#5"] = { codepoint = 0xF8AC, description = "Chord ma7(#5)" },
        ["noteheadSquareWhiteLegacy"] = { codepoint = 0xF613, description = "Notehead square white (legacy)" },
        ["gClefFlat11Below"] = { codepoint = 0xF54D, description = "G Clef (flat 11 below)" },
        ["chordMa7b5"] = { codepoint = 0xF8AB, description = "Chord ma7(b5)" },
        ["accidentalJohnstonSevenSharp"] = { codepoint = 0xF5E0, description = "Seven-sharp (Johnston)" },
        ["chordNo5"] = { codepoint = 0xF8C9, description = "Chord no 5th" },
        ["enclosureParenOverLeft2Alt"] = { codepoint = 0xF741, description = "Enclosure paren over left 2 alt" },
        ["noteheadVoidWithXLV1"] = { codepoint = 0xF7A2, description = "Notehead void with x l v1" },
        ["brassFallSlight"] = { codepoint = 0xF768, description = "Brass fall slight" },
        ["enclosureBracketLongExtension"] = { codepoint = 0xF72A, description = "Enclosure bracket long extension" },
        ["enclosureBracketRightLong"] = { codepoint = 0xF72B, description = "Enclosure bracket right long" },
        ["brassLiftShortMedIncline"] = { codepoint = 0xF763, description = "Brass lift short med incline" },
        ["accidentalJohnstonSevenDown"] = { codepoint = 0xF5E3, description = "Seven-down arrow (Johnston)" },
        ["analyticsArrowExtension"] = { codepoint = 0xF7EA, description = "Analytics short extension" },
        ["chordMi13"] = { codepoint = 0xF8B7, description = "Chord mi13" },
        ["fine"] = { codepoint = 0xF7C8, description = "Fine" },
        ["fClef5Below"] = { codepoint = 0xF532, description = "F clef (5 below)" },
        ["gClef5Below"] = { codepoint = 0xF543, description = "G Clef (5 below)" },
        ["enclosureBracketWavyRight"] = { codepoint = 0xF73D, description = "Enclosure bracket wavy right" },
        ["enclosureParenOverExtensionLongAlt"] = { codepoint = 0xF72D, description = "Enclosure paren over extension long alt" },
        ["analyticsModulationCombiningBracketRightShort"] = { codepoint = 0xF7E2, description = "Analytics modulation short combining bracket (right)" },
        ["enclosureClosed"] = { codepoint = 0xF74A, description = "Enclosure closed" },
        ["textEnclosureFine"] = { codepoint = 0xF81F, description = "Text enclosure fine" },
        ["enclosureParenUnderlineRight"] = { codepoint = 0xF731, description = "Enclosure paren underline right" },
        ["enclosureParenUnderlineRightLong"] = { codepoint = 0xF734, description = "Enclosure paren underline right long" },
        ["enclosureParenUnderlineRightShortLong"] = { codepoint = 0xF73A, description = "Enclosure paren underline right short long" },
        ["brassLiftVeryShortSlightIncline"] = { codepoint = 0xF759, description = "Brass lift very short slight incline" },
        ["chord#11#9"] = { codepoint = 0xF89F, description = "Chord #11/#9" },
        ["chordMi7b9b5"] = { codepoint = 0xF8BC, description = "Chord mi7(b9/b5)" },
        ["enclosureRehersalO"] = { codepoint = 0xF82F, description = "Enclosure rehersal o" },
        ["noteheadSlashDiamondWhiteLVLegacy"] = { codepoint = 0xF8FC, description = "Notehead slash diamond white l v (legacy)" },
        ["chord13b9b5"] = { codepoint = 0xF879, description = "Chord 13(b9/b5)" },
        ["chord-7b5"] = { codepoint = 0xF85A, description = "Chord -7(b5)" },
        ["enclosureRehersalX"] = { codepoint = 0xF838, description = "Enclosure rehersal x" },
        ["enclosureUnderlineLong"] = { codepoint = 0xF733, description = "Enclosure underline long" },
        ["enclosureRehersalD"] = { codepoint = 0xF824, description = "Enclosure rehersal d" },
        ["gClef7Above"] = { codepoint = 0xF546, description = "G Clef (7 above)" },
        ["accidentalNaturalSmall"] = { codepoint = 0xF712, description = "Natural (for small staves)" },
        ["ornamentTrillNaturalAboveLegacy"] = { codepoint = 0xF68D, description = "Trill natural above (legacy)" },
        ["enclosureParenOverRight2Long"] = { codepoint = 0xF746, description = "Enclosure paren over right 2 long" },
        ["chordMi11"] = { codepoint = 0xF8B6, description = "Chord mi11" },
        ["flag16thUpAlt"] = { codepoint = 0xF703, description = "Flag 16th up alt" },
        ["enclosureRehersalE"] = { codepoint = 0xF825, description = "Enclosure rehersal e" },
        ["flag1024thDownStraight"] = { codepoint = 0xF426, description = "Combining flag 8 (1024th) below (straight)" },
        ["gClefSmall"] = { codepoint = 0xF472, description = "G clef (small staff)" },
        ["fClefSmall"] = { codepoint = 0xF474, description = "F clef (small staff)" },
        ["timeSig3Large"] = { codepoint = 0xF443, description = "Time signature 3 (outside staff)" },
        ["flag512thUpStraight"] = { codepoint = 0xF421, description = "Combining flag 7 (512th) above (straight)" },
        ["chord-7b9b5"] = { codepoint = 0xF85E, description = "Chord -7(b9/b5)" },
        ["chordMi9b5"] = { codepoint = 0xF8B9, description = "Chord mi9(b5)" },
        ["chord3"] = { codepoint = 0xF8CE, description = "Chord 3" },
        ["noteheadSlashHorizontalEndsLegacy"] = { codepoint = 0xF673, description = "Notehead slash horizontal ends (legacy)" },
        ["gClef15Below"] = { codepoint = 0xF539, description = "G Clef (15 below)" },
        ["gClef4Above"] = { codepoint = 0xF540, description = "G Clef (4 above)" },
        ["gClef4Below"] = { codepoint = 0xF541, description = "G Clef (4 below)" },
        ["gClef5Above"] = { codepoint = 0xF542, description = "G Clef (5 above)" },
        ["chord9b5"] = { codepoint = 0xF873, description = "Chord 9(b5)" },
        ["enclosureParenOverExtension"] = { codepoint = 0xF724, description = "Enclosure paren over extension" },
        ["ornamentTurnNaturalBelow"] = { codepoint = 0xF5B9, description = "Turn (natural below)" },
        ["enclosureRehersalS"] = { codepoint = 0xF833, description = "Enclosure rehersal s" },
        ["chord-M7"] = { codepoint = 0xF860, description = "Chord -(M7)" },
        ["arpeggioArrowDownShort"] = { codepoint = 0xF773, description = "Arpeggio arrow down short" },
        ["pictLotusFlutePeinkofer"] = { codepoint = 0xF4AC, description = "Lotus flute (Peinkofer/Tannigel)" },
        ["gClefFlat16Below"] = { codepoint = 0xF551, description = "G Clef (flat 16 below)" },
        ["chord7"] = { codepoint = 0xF8D2, description = "Chord 7" },
        ["gClefFlat3Below"] = { codepoint = 0xF556, description = "G Clef (flat 3 below)" },
        ["gClefSharp12Below"] = { codepoint = 0xF56C, description = "G Clef (sharp 12 below)" },
        ["gClefFlat4Below"] = { codepoint = 0xF557, description = "G Clef (flat 4 below)" },
        ["gClefSharp1Above"] = { codepoint = 0xF56D, description = "G Clef (sharp 1 above)" },
        ["enclosureRehersalP"] = { codepoint = 0xF830, description = "Enclosure rehersal p" },
        ["gClefAlt"] = { codepoint = 0xF7D7, description = "G clef alt" },
        ["tripleTongueBelowNoSlur"] = { codepoint = 0xF430, description = "Triple-tongue below (no slur)" },
        ["gClefNatural9Above"] = { codepoint = 0xF56A, description = "G Clef (natural 9 above)" },
        ["enclosureParenUnderlineRightShortAlt2"] = { codepoint = 0xF749, description = "Enclosure paren underline right short alt 2" },
        ["tremolo3Alt5"] = { codepoint = 0xF7BA, description = "Tremolo 3 alt 5" },
        ["brassShakeLong"] = { codepoint = 0xF756, description = "Brass shake long" },
        ["harpMetalRodAlt"] = { codepoint = 0xF436, description = "Metal rod pictogram (alternative)" },
        ["articTenutoStaccatoAboveLegacy"] = { codepoint = 0xF62F, description = "Tenuto-staccato above (legacy)" },
        ["accidentalFlatJohnstonEl"] = { codepoint = 0xF5DD, description = "Flat-inverted seven (Johnston)" },
        ["enclosureParenUnderlineLeftAlt"] = { codepoint = 0xF735, description = "Enclosure paren underline left alt" },
        ["cClefSmall"] = { codepoint = 0xF473, description = "C clef (small staff)" },
        ["noteheadXBlack3LVLegacy"] = { codepoint = 0xF8DF, description = "Notehead x black3 l v (legacy)" },
        ["miscLegacy2"] = { codepoint = 0xF7CD, description = "Misc (legacy 2)" },
        ["note64thUpAlt"] = { codepoint = 0xF7CC, description = "Note 64th up alt" },
        ["gClefFlat10Below"] = { codepoint = 0xF54C, description = "G Clef (flat 10 below)" },
        ["flag32ndUpStraight"] = { codepoint = 0xF415, description = "Combining flag 3 (32nd) above (straight)" },
        ["brassFallRoughVeryShortMedDecline"] = { codepoint = 0xF75C, description = "Brass fall rough very short med decline" },
        ["noteheadHalfLV5"] = { codepoint = 0xF790, description = "Notehead half l v5" },
        ["harpTuningKeyAlt"] = { codepoint = 0xF437, description = "Tuning key pictogram (alternative)" },
        ["noteheadBlackLVLegacy"] = { codepoint = 0xF8D9, description = "Notehead black l v (legacy)" },
        ["enclosureParenOverExtension2Long"] = { codepoint = 0xF745, description = "Enclosure paren over extension 2 long" },
        ["accidentalJohnstonSevenFlat"] = { codepoint = 0xF5E1, description = "Seven-flat (Johnston)" },
        ["enclosureBracketWavyLeft"] = { codepoint = 0xF73B, description = "Enclosure bracket wavy left" },
        ["chord7b9b5"] = { codepoint = 0xF86E, description = "Chord7(b9/b5)" },
        ["chord-6"] = { codepoint = 0xF854, description = "Chord -6" },
    }
    local by_codepoint = {
        [0xE4A9] = "articStaccatissimoWedgeBelow",
        [0xE226] = "tremoloFingered2",
        [0xEEB2] = "noteheadCowellThirteenthNoteSeriesBlack",
        [0xE852] = "fretboard4String",
        [0xEEA6] = "noteheadCowellFifthNoteSeriesBlack",
        [0xE9D8] = "chantEpisema",
        [0xEC33] = "kievanNoteWhole",
        [0xE818] = "handbellsSwingUp",
        [0xEEB1] = "noteheadCowellThirteenthNoteSeriesHalf",
        [0xE3BF] = "accSagittalFlat19sUp",
        [0xE7A5] = "pictBeaterSoftYarnLeft",
        [0xED29] = "fingeringRightParenthesis",
        [0xE150] = "noteDoWhole",
        [0xE1B3] = "noteShapeSquareBlack",
        [0xE5E9] = "brassHarmonMuteStemHalfLeft",
        [0xEA02] = "mensuralCustosUp",
        [0xE8F2] = "chantStaffNarrow",
        [0xE9C5] = "chantStrophicusLiquescens5th",
        [0xE7EB] = "pictBeaterBox",
        [0xE213] = "stemPendereckiTremolo",
        [0xEB7B] = "arrowheadBlackDownRight",
        [0xED80] = "fingering0Italic",
        [0xEB79] = "arrowheadBlackUpRight",
        [0xE15F] = "noteSiHalf",
        [0xEC08] = "luteGermanILower",
        [0xE6C5] = "pictGlassTubeChimes",
        [0xED66] = "csymAccidentalTripleFlat",
        [0xE481] = "accidentalSharpReversed",
        [0xE274] = "accidentalThreeQuarterTonesSharpArrowUp",
        [0xE722] = "pictHiHat",
        [0xE80E] = "pictScrapeAroundRimClockwise",
        [0xE3FF] = "accSagittal4TinasDown",
        [0xE60A] = "windMouthpiecePop",
        [0xE8D4] = "accdnRicochetStem4",
        [0xE198] = "noteASharpBlack",
        [0xE7D2] = "pictBeaterSnareSticksDown",
        [0xE8A5] = "accdnRH3RanksOboe",
        [0xE4E4] = "restHalf",
        [0xE8E5] = "controlEndSlur",
        [0xE7CE] = "pictBeaterHammerPlasticDown",
        [0xE561] = "graceNoteAcciaccaturaStemDown",
        [0xEB75] = "arrowOpenDownLeft",
        [0xEC93] = "octaveBaselineB",
        [0xE792] = "pictBeaterHardTimpaniRight",
        [0xE94B] = "mensuralCombStemUpFlagFusa",
        [0xED8E] = "fingeringQLower",
        [0xE37C] = "accSagittalSharp23CUp",
        [0xE539] = "dynamicSforzato",
        [0xE9D6] = "chantAccentusAbove",
        [0xE18A] = "noteDSharpHalf",
        [0xE397] = "accSagittal11v49CommaDown",
        [0xE6A6] = "pictMar",
        [0xEA89] = "functionSUpper",
        [0xE404] = "accSagittal7TinasUp",
        [0xE489] = "accidentalThreeQuarterTonesFlatCouper",
        [0xEA28] = "medRenQuilismaCMN",
        [0xE264] = "accidentalDoubleFlat",
        [0xEDCE] = "kahnSlam",
        [0xE960] = "mensuralWhiteSemiminima",
        [0xEC31] = "kievanEndingSymbol",
        [0xE52D] = "dynamicMF",
        [0xE2D2] = "accidentalSharpTwoArrowsUp",
        [0xEAA8] = "wiggleTrillSlowest",
        [0xE074] = "gClefTurned",
        [0xE8D0] = "accdnRicochet5",
        [0xE077] = "fClefTurned",
        [0xE19B] = "noteBSharpBlack",
        [0xE5E3] = "brassBend",
        [0xE606] = "windReedPositionIn",
        [0xE3B4] = "accSagittalSharp7v19CDown",
        [0xE162] = "noteMiBlack",
        [0xED5E] = "accidentalSharpRepeatedLineStockhausen",
        [0xE1BB] = "noteShapeTriangleUpBlack",
        [0xE4C6] = "fermataLongAbove",
        [0xE6F9] = "pictCastanetsWithHandle",
        [0xE12D] = "noteheadClusterDoubleWholeMiddle",
        [0xE083] = "timeSig3",
        [0xE7F4] = "pictOnRim",
        [0xE3EE] = "accSagittalDoubleSharp19sDown",
        [0xE48E] = "accidentalOneQuarterToneSharpFerneyhough",
        [0xE95D] = "mensuralWhiteLonga",
        [0xEADD] = "wiggleVibratoMediumFaster",
        [0xE1FA] = "textCont16thBeamLongStem",
        [0xE833] = "guitarString0",
        [0xE81B] = "handbellsEcho1",
        [0xE646] = "vocalsSussurando",
        [0xE590] = "ornamentTopLeftConcaveStroke",
        [0xE1E7] = "augmentationDot",
        [0xE5A3] = "ornamentHighRightConvexStroke",
        [0xE0A7] = "noteheadXWhole",
        [0xE42E] = "accidentalWyschnegradsky4TwelfthsFlat",
        [0xEAF4] = "beamAccelRit1",
        [0xE068] = "fClefArrowDown",
        [0xEE55] = "accidentalCombiningRaise41Comma",
        [0xEEA0] = "noteheadNancarrowSine",
        [0xED28] = "fingeringLeftParenthesis",
        [0xEB81] = "arrowheadWhiteUpRight",
        [0xE3A5] = "accSagittal49MediumDiesisDown",
        [0xEB65] = "arrowBlackDownLeft",
        [0xE1AB] = "noteHBlack",
        [0xED40] = "articSoftAccentAbove",
        [0xEE33] = "organGerman3Semifusae",
        [0xE626] = "stringsChangeBowDirection",
        [0xE2F6] = "accidentalQuarterSharpEqualTempered",
        [0xECB5] = "metNote1024thUp",
        [0xE8F7] = "chantVirgula",
        [0xE110] = "noteheadRoundBlackLarge",
        [0xE514] = "quindicesima",
        [0xE1DF] = "note128thUp",
        [0xE3B3] = "accSagittalFlat49SUp",
        [0xE19D] = "noteCBlack",
        [0xE4C8] = "fermataVeryLongAbove",
        [0xE0F8] = "noteheadHeavyX",
        [0xE8B3] = "accdnRH3RanksFullFactory",
        [0xE405] = "accSagittal7TinasDown",
        [0xEE2D] = "organGerman2Semiminimae",
        [0xE686] = "harpSalzedoThunderEffect",
        [0xE8D6] = "accdnRicochetStem6",
        [0xE866] = "analyticsThemeRetrogradeInversion",
        [0xE6F8] = "pictCastanets",
        [0xE8E0] = "controlBeginBeam",
        [0xE0FB] = "noteheadHalfFilled",
        [0xE7DA] = "pictBeaterBrassMalletsDown",
        [0xED52] = "accidentalFlatRaisedStockhausen",
        [0xE01C] = "staff1LineNarrow",
        [0xE3C2] = "accSagittalSharp17kUp",
        [0xE9F7] = "mensuralRestFusa",
        [0xEAF0] = "wiggleRandom1",
        [0xEAE1] = "wiggleVibratoMediumSlowest",
        [0xE923] = "mensuralProlationCombiningThreeDotsTri",
        [0xE5DF] = "brassFallRoughLong",
        [0xED11] = "fingering1",
        [0xEB17] = "elecVideoCamera",
        [0xE3A2] = "accSagittal11v19MediumDiesisUp",
        [0xE927] = "mensuralProportion2",
        [0xECAB] = "metNote32ndUp",
        [0xEE71] = "swissRudimentsNoteheadHalfFlam",
        [0xE136] = "noteheadClusterQuarterMiddle",
        [0xE4C4] = "fermataShortAbove",
        [0xEB1A] = "elecLoudspeaker",
        [0xEEA3] = "noteheadCowellThirdNoteSeriesBlack",
        [0xE6AD] = "pictVibSmithBrindle",
        [0xEA0E] = "mensuralColorationStartRound",
        [0xE5DD] = "brassFallRoughShort",
        [0xEC3E] = "kievanAccidentalFlat",
        [0xE470] = "accidentalXenakisOneThirdToneSharp",
        [0xE8E2] = "controlBeginTie",
        [0xE105] = "noteheadSlashVerticalEndsSmall",
        [0xE29A] = "accidentalHalfSharpArrowDown",
        [0xEA90] = "functionBracketRight",
        [0xE95A] = "mensuralBlackDragma",
        [0xE4BD] = "articMarcatoTenutoBelow",
        [0xE5DC] = "brassFallSmoothLong",
        [0xE2E5] = "accidentalRaiseOneTridecimalQuartertone",
        [0xE614] = "stringsHarmonic",
        [0xEADC] = "wiggleVibratoMediumFasterStill",
        [0xEDF0] = "kahnLeftTurn",
        [0xED55] = "accidentalNaturalLoweredStockhausen",
        [0xE8A0] = "accdnRH3RanksPiccolo",
        [0xE1E1] = "note256thUp",
        [0xEF08] = "scaleDegree9",
        [0xE37D] = "accSagittalFlat23CDown",
        [0xEAF3] = "wiggleRandom4",
        [0xE3BD] = "accSagittalFlat17kUp",
        [0xECB2] = "metNote256thDown",
        [0xE09C] = "timeSigX",
        [0xE307] = "accSagittal25SmallDiesisDown",
        [0xE98C] = "mensuralObliqueDesc5thBlack",
        [0xE284] = "accidentalNarrowReversedFlat",
        [0xE429] = "accidentalWyschnegradsky10TwelfthsSharp",
        [0xE3B5] = "accSagittalFlat7v19CUp",
        [0xE647] = "vocalNasalVoice",
        [0xE0CB] = "noteheadMoonBlack",
        [0xEA08] = "chantCustosStemDownPosHigh",
        [0xE551] = "lyricsElision",
        [0xE511] = "ottavaAlta",
        [0xEB8A] = "arrowheadOpenRight",
        [0xE16B] = "noteBFlatWhole",
        [0xE0D1] = "noteheadSlashedHalf1",
        [0xE65A] = "keyboardPedalS",
        [0xE035] = "barlineHeavyHeavy",
        [0xE573] = "ornamentRightFacingHook",
        [0xE374] = "accSagittal5v23SmallDiesisUp",
        [0xE83C] = "guitarString9",
        [0xE99D] = "chantOriscusDescending",
        [0xE794] = "pictBeaterWoodTimpaniUp",
        [0xE937] = "mensuralNoteheadLongaWhite",
        [0xEE63] = "accidentalUpsAndDownsLess",
        [0xE668] = "keyboardBebung2DotsAbove",
        [0xE3A0] = "accSagittal5v13MediumDiesisUp",
        [0xE600] = "windLessTightEmbouchure",
        [0xEA63] = "figbassDoubleFlat",
        [0xE5EE] = "brassLiftSmoothLong",
        [0xEEEB] = "noteRaHalf",
        [0xE05D] = "cClef8vb",
        [0xEA3A] = "daseianSuperiores3",
        [0xE4CC] = "fermataShortHenzeAbove",
        [0xE052] = "gClef8vb",
        [0xEC62] = "miscEyeglasses",
        [0xE8B4] = "accdnRH4RanksSoprano",
        [0xEB45] = "elecAudioChannelsSeven",
        [0xE266] = "accidentalTripleFlat",
        [0xE8F1] = "chantStaffWide",
        [0xE63C] = "arpeggiato",
        [0xE865] = "analyticsThemeRetrograde",
        [0xE92B] = "mensuralProportionMajor",
        [0xED35] = "accidentalQuarterToneSharpArabic",
        [0xE281] = "accidentalThreeQuarterTonesFlatZimmermann",
        [0xE617] = "stringsMuteOff",
        [0xE83A] = "guitarString7",
        [0xEB18] = "elecMonitor",
        [0xE5D1] = "brassLiftShort",
        [0xE3C6] = "accSagittalSharp11v49CUp",
        [0xEA8C] = "functionTLower",
        [0xE403] = "accSagittal6TinasDown",
        [0xEE3C] = "organGerman6Minimae",
        [0xEDB7] = "kahnToeDrop",
        [0xE234] = "doubleLateralRollStevens",
        [0xE424] = "accidentalWyschnegradsky5TwelfthsSharp",
        [0xE1D0] = "noteDoubleWhole",
        [0xE199] = "noteBFlatBlack",
        [0xE93A] = "mensuralNoteheadSemibrevisBlackVoid",
        [0xE785] = "pictBeaterHardGlockenspielDown",
        [0xEBD5] = "luteFrenchAppoggiaturaAbove",
        [0xE4C5] = "fermataShortBelow",
        [0xEB1C] = "elecPlay",
        [0xEA41] = "daseianResidua2",
        [0xE164] = "noteSoBlack",
        [0xE3D6] = "accSagittalSharp5v49MUp",
        [0xEA74] = "functionFour",
        [0xEBE2] = "luteItalianFret2",
        [0xE08E] = "timeSigFractionalSlash",
        [0xEAA6] = "wiggleTrillSlower",
        [0xE887] = "tuplet7",
        [0xE207] = "textHeadlessBlackNoteFrac8thLongStem",
        [0xE8F4] = "chantDivisioMaior",
        [0xE3B9] = "accSagittalFlat11v49CUp",
        [0xE8C5] = "accdnLH3RanksTuttiSquare",
        [0xE5D7] = "brassFallLipShort",
        [0xEA0A] = "mensuralCustosCheckmark",
        [0xE393] = "accSagittal17KleismaDown",
        [0xE4B3] = "articTenutoStaccatoBelow",
        [0xED46] = "articSoftAccentTenutoStaccatoAbove",
        [0xE812] = "handbellsHandMartellato",
        [0xEBB0] = "luteFingeringRHThird",
        [0xE1BA] = "noteShapeTriangleUpWhite",
        [0xE753] = "pictSiren",
        [0xE5E1] = "brassFlip",
        [0xEDD1] = "kahnGraceTapChange",
        [0xED1A] = "fingeringMLower",
        [0xE2B4] = "accidentalJohnstonUp",
        [0xE579] = "ornamentShortObliqueLineBeforeNote",
        [0xE528] = "dynamicPPPPP",
        [0xE3DB] = "accSagittalFlat11v19LDown",
        [0xE57B] = "ornamentObliqueLineBeforeNote",
        [0xE367] = "accSagittalDoubleFlat7v11kUp",
        [0xE4A5] = "articTenutoBelow",
        [0xE5A1] = "ornamentTopRightConvexStroke",
        [0xE295] = "accidentalReversedFlatAndFlatArrowDown",
        [0xE814] = "handbellsMalletBellSuspended",
        [0xE40B] = "accSagittalFractionalTinaDown",
        [0xE2D8] = "accidentalDoubleSharpThreeArrowsDown",
        [0xEE62] = "accidentalUpsAndDownsMore",
        [0xEE38] = "organGerman5Minimae",
        [0xE3A3] = "accSagittal11v19MediumDiesisDown",
        [0xE949] = "mensuralCombStemUpFlagSemiminima",
        [0xE3D1] = "accSagittalFlat5v13MDown",
        [0xE427] = "accidentalWyschnegradsky8TwelfthsSharp",
        [0xE6F5] = "pictFootballRatchet",
        [0xE4C2] = "fermataVeryShortAbove",
        [0xE09D] = "timeSigOpenPenderecki",
        [0xE22A] = "buzzRoll",
        [0xE3DF] = "accSagittalUnused4",
        [0xE516] = "quindicesimaBassa",
        [0xED2E] = "fingeringSeparatorSlash",
        [0xE12E] = "noteheadClusterDoubleWholeBottom",
        [0xE006] = "reversedBracketBottom",
        [0xE1C2] = "noteShapeQuarterMoonWhite",
        [0xE285] = "accidentalNarrowReversedFlatAndFlat",
        [0xE9F8] = "mensuralRestSemifusa",
        [0xE526] = "dynamicNiente",
        [0xEAFA] = "beamAccelRit7",
        [0xE9A1] = "chantPunctumDeminutum",
        [0xE1A0] = "noteDBlack",
        [0xE65C] = "keyboardPedalHalf3",
        [0xE478] = "accidentalQuarterToneFlatPenderecki",
        [0xE1B9] = "noteShapeDiamondBlack",
        [0xE3A7] = "accSagittal5v49MediumDiesisDown",
        [0xEC63] = "metricModulationArrowLeft",
        [0xE861] = "analyticsNebenstimme",
        [0xE407] = "accSagittal8TinasDown",
        [0xEDA7] = "kahnBrushBackward",
        [0xE3EB] = "accSagittalDoubleFlat143CUp",
        [0xE0F6] = "noteheadParenthesisRight",
        [0xE553] = "lyricsHyphenBaseline",
        [0xE265] = "accidentalTripleSharp",
        [0xE1A7] = "noteFSharpBlack",
        [0xEBF1] = "luteItalianClefCSolFaUt",
        [0xE849] = "guitarBarreHalf",
        [0xE17F] = "noteAFlatHalf",
        [0xE246] = "flag64thUp",
        [0xE77C] = "pictBeaterWoodXylophoneUp",
        [0xE0DB] = "noteheadDiamondBlack",
        [0xED51] = "accidentalLoweredStockhausen",
        [0xE978] = "mensuralObliqueAsc4thBlack",
        [0xE151] = "noteReWhole",
        [0xE4D3] = "caesuraShort",
        [0xE7A8] = "pictBeaterMediumYarnRight",
        [0xEAC3] = "wiggleCircularConstantFlippedLarge",
        [0xEBF3] = "luteItalianHoldNote",
        [0xEB4B] = "elecVideoIn",
        [0xE1E5] = "note1024thUp",
        [0xECA2] = "metNoteWhole",
        [0xE8C6] = "accdnCombRH3RanksEmpty",
        [0xE0E6] = "noteheadCircledWhole",
        [0xEDE8] = "kahnRipple",
        [0xE2CC] = "accidentalNaturalTwoArrowsDown",
        [0xE97E] = "mensuralObliqueAsc5thBlackVoid",
        [0xE52F] = "dynamicFF",
        [0xE394] = "accSagittal143CommaUp",
        [0xEBA0] = "luteStaff6Lines",
        [0xE2C0] = "accidentalDoubleFlatOneArrowDown",
        [0xEE67] = "accidentalHabaQuarterToneLower",
        [0xEDB0] = "kahnFleaHop",
        [0xE981] = "mensuralObliqueDesc2ndVoid",
        [0xE15C] = "noteSoHalf",
        [0xE17B] = "noteGWhole",
        [0xE51A] = "octaveParensLeft",
        [0xE664] = "keyboardPedalToe1",
        [0xE660] = "keyboardRightPedalPictogram",
        [0xE16E] = "noteCFlatWhole",
        [0xE406] = "accSagittal8TinasUp",
        [0xE262] = "accidentalSharp",
        [0xE19A] = "noteBBlack",
        [0xE310] = "accSagittalSharp25SDown",
        [0xED41] = "articSoftAccentBelow",
        [0xE5B7] = "ornamentPrecompTurnTrillBach",
        [0xE1FE] = "textTupletBracketStartShortStem",
        [0xEEE8] = "noteTeWhole",
        [0xE202] = "textTuplet3LongStem",
        [0xE3A1] = "accSagittal5v13MediumDiesisDown",
        [0xE6E2] = "pictGobletDrum",
        [0xE380] = "accSagittalSharp5v23SUp",
        [0xE959] = "mensuralBlackSemibrevisCaudata",
        [0xEA70] = "functionZero",
        [0xEEED] = "noteFiHalf",
        [0xE5E5] = "brassMuteClosed",
        [0xEAA7] = "wiggleTrillSlowerStill",
        [0xE4B8] = "articUnstressAbove",
        [0xE620] = "stringsJeteAbove",
        [0xEA99] = "functionFUpper",
        [0xE3FE] = "accSagittal4TinasUp",
        [0xE015] = "staff6Lines",
        [0xE21F] = "stemHarpStringNoise",
        [0xEEF1] = "noteTeHalf",
        [0xE39B] = "accSagittal7v19CommaDown",
        [0xE306] = "accSagittal25SmallDiesisUp",
        [0xE041] = "repeatRight",
        [0xE8CB] = "accdnPush",
        [0xE5EC] = "brassLiftSmoothShort",
        [0xE450] = "accidental1CommaSharp",
        [0xE023] = "legerLineWide",
        [0xE173] = "noteDSharpWhole",
        [0xEB1E] = "elecPause",
        [0xE30B] = "accSagittal11MediumDiesisDown",
        [0xE1AD] = "noteEmptyWhole",
        [0xE843] = "guitarFadeIn",
        [0xEDAA] = "kahnHeel",
        [0xEDDF] = "kahnZink",
        [0xE42D] = "accidentalWyschnegradsky3TwelfthsFlat",
        [0xE176] = "noteESharpWhole",
        [0xEADE] = "wiggleVibratoMediumFast",
        [0xEA0C] = "mensuralColorationStartSquare",
        [0xE544] = "dynamicHairpinBracketLeft",
        [0xE32F] = "accSagittalDoubleFlat7CUp",
        [0xE30D] = "accSagittal11LargeDiesisDown",
        [0xE932] = "mensuralNoteheadMaximaBlackVoid",
        [0xE276] = "accidentalFiveQuarterTonesSharpArrowUp",
        [0xE56A] = "ornamentTurnUp",
        [0xE114] = "noteheadRoundWhite",
        [0xEA3D] = "daseianExcellentes2",
        [0xE1C9] = "noteShapeArrowheadLeftBlack",
        [0xEA37] = "daseianFinales4",
        [0xE460] = "accidentalKoron",
        [0xE9BB] = "chantLigaturaDesc4th",
        [0xE2DB] = "accidentalNaturalThreeArrowsUp",
        [0xEDDD] = "kahnChug",
        [0xEB29] = "elecMicrophoneUnmute",
        [0xE126] = "noteheadClusterHalf2nd",
        [0xE87B] = "csymAlteredBassSlash",
        [0xE485] = "accidentalDoubleFlatTurned",
        [0xE79F] = "pictBeaterMetalBassDrumDown",
        [0xE7B9] = "pictWoundSoftRight",
        [0xE219] = "stemVibratoPulse",
        [0xEB14] = "elecTape",
        [0xEC54] = "smnHistorySharp",
        [0xEC12] = "luteGermanTLower",
        [0xE972] = "mensuralObliqueAsc2ndBlackVoid",
        [0xE4B4] = "articTenutoAccentAbove",
        [0xE032] = "barlineFinal",
        [0xE001] = "reversedBrace",
        [0xE78F] = "pictBeaterMediumTimpaniLeft",
        [0xE21A] = "stemMultiphonicsBlack",
        [0xE500] = "repeat1Bar",
        [0xE355] = "accSagittalFlat7v11kDown",
        [0xEE3D] = "organGerman6Semiminimae",
        [0xE2F9] = "accidentalEnharmonicTilde",
        [0xE3BA] = "accSagittalSharp143CDown",
        [0xE8BE] = "accdnLH2RanksMasterRound",
        [0xE487] = "accidentalThreeQuarterTonesFlatTartini",
        [0xE984] = "mensuralObliqueDesc3rdBlack",
        [0xE314] = "accSagittalSharp5CDown",
        [0xE291] = "accidentalReversedFlatArrowDown",
        [0xE18D] = "noteESharpHalf",
        [0xEABE] = "wiggleGlissandoGroup2",
        [0xED8F] = "fingeringSLower",
        [0xE0CC] = "noteheadTriangleRoundDownWhite",
        [0xEB78] = "arrowheadBlackUp",
        [0xEB89] = "arrowheadOpenUpRight",
        [0xE0BB] = "noteheadTriangleUpWhole",
        [0xE7A0] = "pictBeaterDoubleBassDrumUp",
        [0xE8B5] = "accdnRH4RanksAlto",
        [0xE26C] = "accidentalBracketLeft",
        [0xE666] = "keyboardPedalHeelToe",
        [0xEB93] = "staffPosRaise4",
        [0xED37] = "accidentalThreeQuarterTonesSharpArabic",
        [0xE3CB] = "accSagittalFlat7v19CDown",
        [0xEF04] = "scaleDegree5",
        [0xE359] = "accSagittalFlat55CDown",
        [0xE6D9] = "pictTomTomJapanese",
        [0xEBA4] = "luteBarlineEndRepeat",
        [0xE160] = "noteDoBlack",
        [0xE2CE] = "accidentalDoubleSharpTwoArrowsDown",
        [0xE1D4] = "noteHalfDown",
        [0xEC10] = "luteGermanRLower",
        [0xECD2] = "noteShapeTriangleRightDoubleWhole",
        [0xE919] = "mensuralProlation10",
        [0xE2E1] = "accidentalRaiseTwoSeptimalCommas",
        [0xEA9D] = "functionKLower",
        [0xE34D] = "accSagittalFlat7v11CUp",
        [0xEE54] = "accidentalCombiningLower41Comma",
        [0xEE85] = "stringsUpBowBeyondBridge",
        [0xE5D9] = "brassFallLipLong",
        [0xE533] = "dynamicFFFFFF",
        [0xEA78] = "functionEight",
        [0xE372] = "accSagittal5v19CommaUp",
        [0xE7C2] = "pictGumMediumLeft",
        [0xE435] = "accidentalWyschnegradsky11TwelfthsFlat",
        [0xE0FA] = "noteheadWholeFilled",
        [0xE77F] = "pictBeaterWoodXylophoneLeft",
        [0xE7C9] = "pictBeaterMetalRight",
        [0xEEF4] = "noteRaBlack",
        [0xEEF8] = "noteLiBlack",
        [0xE1DB] = "note32ndUp",
        [0xE118] = "noteheadRoundBlackSlashed",
        [0xE8E7] = "controlEndPhrase",
        [0xEB8F] = "arrowheadOpenUpLeft",
        [0xE327] = "accSagittalFlat11MDown",
        [0xE183] = "noteBHalf",
        [0xE81A] = "handbellsSwing",
        [0xED25] = "fingering7",
        [0xE61E] = "stringsOverpressurePossibileUpBow",
        [0xEE86] = "stringsScrapeParallelInward",
        [0xEC58] = "smnNatural",
        [0xE950] = "mensuralBlackMaxima",
        [0xE1C3] = "noteShapeQuarterMoonBlack",
        [0xE26D] = "accidentalBracketRight",
        [0xE8C4] = "accdnLH3Ranks2Plus8Square",
        [0xE1CA] = "noteShapeTriangleRoundLeftWhite",
        [0xEB8E] = "arrowheadOpenLeft",
        [0xE2C4] = "accidentalDoubleSharpOneArrowDown",
        [0xE0E5] = "noteheadCircledHalf",
        [0xED87] = "fingering7Italic",
        [0xEDB9] = "kahnSnap",
        [0xE13B] = "noteheadDiamondClusterBlack3rd",
        [0xE240] = "flag8thUp",
        [0xE844] = "guitarFadeOut",
        [0xE870] = "csymDiminished",
        [0xE9F2] = "mensuralRestLongaImperfecta",
        [0xEAD8] = "wiggleVibratoSmallSlow",
        [0xEB23] = "elecLoop",
        [0xEAFC] = "beamAccelRit9",
        [0xE863] = "analyticsEndStimme",
        [0xE8D2] = "accdnRicochetStem2",
        [0xEA83] = "functionGUpper",
        [0xEC05] = "luteGermanFLower",
        [0xE168] = "noteAFlatWhole",
        [0xE018] = "staff3LinesWide",
        [0xEE08] = "organGermanGisUpper",
        [0xEEAB] = "noteheadCowellNinthNoteSeriesHalf",
        [0xE746] = "pictSistrum",
        [0xE061] = "cClefCombining",
        [0xED20] = "fingeringSubstitutionAbove",
        [0xE104] = "noteheadSlashDiamondWhite",
        [0xE12B] = "noteheadClusterQuarter3rd",
        [0xEAAB] = "wiggleArpeggiatoUpSwash",
        [0xE6F3] = "pictGuiro",
        [0xE588] = "ornamentPinceCouperin",
        [0xE9B6] = "chantEntryLineAsc4th",
        [0xE260] = "accidentalFlat",
        [0xE1F9] = "textCont16thBeamShortStem",
        [0xE101] = "noteheadSlashHorizontalEnds",
        [0xE910] = "mensuralProlation1",
        [0xE7EE] = "pictBeaterBrassMalletsLeft",
        [0xE596] = "ornamentLeftShakeT",
        [0xE757] = "pictDuckCall",
        [0xE652] = "keyboardPedalE",
        [0xE7F1] = "pictScrapeCenterToEdge",
        [0xEEE0] = "noteDiWhole",
        [0xE13D] = "noteheadDiamondClusterWhiteMiddle",
        [0xED5C] = "accidentalFlatRepeatedLineStockhausen",
        [0xE5EF] = "brassValveTrill",
        [0xE882] = "tuplet2",
        [0xEEEE] = "noteSeHalf",
        [0xE0D6] = "noteheadSlashedDoubleWhole2",
        [0xE6A3] = "pictXylBass",
        [0xED86] = "fingering6Italic",
        [0xEAB2] = "guitarVibratoStroke",
        [0xEBA3] = "luteBarlineStartRepeat",
        [0xEDAB] = "kahnToe",
        [0xEB6A] = "arrowWhiteRight",
        [0xE275] = "accidentalQuarterToneSharpArrowDown",
        [0xE57D] = "ornamentDoubleObliqueLinesBeforeNote",
        [0xEBCC] = "luteFrenchFretN",
        [0xE0B3] = "noteheadCircleX",
        [0xEAD0] = "wiggleVibratoSmallestFast",
        [0xE301] = "accSagittal5v7KleismaDown",
        [0xE81C] = "handbellsEcho2",
        [0xE6C0] = "pictTubularBells",
        [0xE885] = "tuplet5",
        [0xEA8B] = "functionTUpper",
        [0xE08D] = "timeSigPlusSmall",
        [0xE3E8] = "accSagittalDoubleSharp11v49CDown",
        [0xEA88] = "functionPLower",
        [0xE361] = "accSagittalDoubleFlat7v11CUp",
        [0xED03] = "functionRLower",
        [0xEF00] = "scaleDegree1",
        [0xE5C5] = "ornamentPrecompMordentRelease",
        [0xE99F] = "chantStrophicus",
        [0xE691] = "harpTuningKeyHandle",
        [0xE3BC] = "accSagittalSharp17kDown",
        [0xED14] = "fingering4",
        [0xE537] = "dynamicSforzandoPiano",
        [0xE8BA] = "accdnRH4RanksBassAlto",
        [0xE5B0] = "ornamentPrecompSlide",
        [0xEEB0] = "noteheadCowellThirteenthNoteSeriesWhole",
        [0xEDE4] = "kahnZank",
        [0xE9A0] = "chantStrophicusAuctus",
        [0xEC1B] = "luteGermanEUpper",
        [0xE988] = "mensuralObliqueDesc4thBlack",
        [0xE444] = "accidentalKomaSharp",
        [0xEBF5] = "luteItalianReleaseFinger",
        [0xE7D1] = "pictBeaterSnareSticksUp",
        [0xED02] = "functionNUpperSuperscript",
        [0xE305] = "accSagittal7CommaDown",
        [0xECC2] = "figbassTripleSharp",
        [0xE847] = "guitarStrumDown",
        [0xE87C] = "csymDiagonalArrangementSlash",
        [0xEBEA] = "luteItalianTempoFast",
        [0xE022] = "legerLine",
        [0xE251] = "flagInternalDown",
        [0xE982] = "mensuralObliqueDesc2ndBlackVoid",
        [0xE351] = "accSagittalFlat17CUp",
        [0xE6B0] = "pictCelesta",
        [0xEA82] = "functionSlashedDD",
        [0xE66D] = "keyboardBebung4DotsBelow",
        [0xE2E2] = "accidentalLowerOneUndecimalQuartertone",
        [0xE726] = "pictChineseCymbal",
        [0xE699] = "harpSalzedoDampBelow",
        [0xEDE7] = "kahnRiffle",
        [0xE386] = "accSagittalDoubleSharp23CDown",
        [0xE79B] = "pictBeaterMediumBassDrumDown",
        [0xECE9] = "timeSig9Turned",
        [0xE881] = "tuplet1",
        [0xE87A] = "csymParensRightVeryTall",
        [0xEE36] = "organGerman4Fusae",
        [0xE049] = "codaSquare",
        [0xE1A1] = "noteDSharpBlack",
        [0xE973] = "mensuralObliqueAsc2ndWhite",
        [0xE522] = "dynamicForte",
        [0xE000] = "brace",
        [0xECD8] = "noteShapeKeystoneDoubleWhole",
        [0xE97B] = "mensuralObliqueAsc4thWhite",
        [0xEB70] = "arrowOpenUp",
        [0xE0B8] = "noteheadSquareWhite",
        [0xE729] = "pictEdgeOfCymbal",
        [0xEE3B] = "organGerman5Semifusae",
        [0xE0ED] = "noteheadLargeArrowUpDoubleWhole",
        [0xEC15] = "luteGermanYLower",
        [0xEA06] = "chantCustosStemUpPosMiddle",
        [0xE483] = "accidentalDoubleFlatReversed",
        [0xE300] = "accSagittal5v7KleismaUp",
        [0xE106] = "noteheadSlashX",
        [0xE0BC] = "noteheadTriangleUpHalf",
        [0xE7CD] = "pictBeaterHammerPlasticUp",
        [0xE3EF] = "accSagittalDoubleFlat19sUp",
        [0xE345] = "accSagittal55CommaDown",
        [0xE84B] = "guitarString11",
        [0xE781] = "pictBeaterSoftGlockenspielDown",
        [0xE877] = "csymBracketLeftTall",
        [0xEE07] = "organGermanGUpper",
        [0xEB28] = "elecMicrophoneMute",
        [0xE0AD] = "noteheadPlusWhole",
        [0xE0CA] = "noteheadMoonWhite",
        [0xE065] = "fClef8va",
        [0xE021] = "staff6LinesNarrow",
        [0xEB68] = "arrowWhiteUp",
        [0xEBE9] = "luteItalianFret9",
        [0xE3F9] = "accSagittal1TinaDown",
        [0xEA62] = "figbass9Raised",
        [0xE0C5] = "noteheadTriangleDownHalf",
        [0xEE73] = "swissRudimentsNoteheadHalfDouble",
        [0xE124] = "noteheadClusterDoubleWhole2nd",
        [0xE91A] = "mensuralProlation11",
        [0xE165] = "noteLaBlack",
        [0xE2D1] = "accidentalNaturalTwoArrowsUp",
        [0xE4C1] = "fermataBelow",
        [0xE093] = "timeSigParensRightSmall",
        [0xE979] = "mensuralObliqueAsc4thVoid",
        [0xE2C1] = "accidentalFlatOneArrowDown",
        [0xEE50] = "accidentalCombiningLower29LimitComma",
        [0xE9E4] = "medRenFlatWithDot",
        [0xE970] = "mensuralObliqueAsc2ndBlack",
        [0xEBEB] = "luteItalianTempoSomewhatFast",
        [0xE2C9] = "accidentalDoubleSharpOneArrowUp",
        [0xE569] = "ornamentTurnSlash",
        [0xEAF1] = "wiggleRandom2",
        [0xE100] = "noteheadSlashVerticalEnds",
        [0xE946] = "mensuralCombStemDownFlagFlared",
        [0xE9C0] = "chantConnectingLineAsc5th",
        [0xE261] = "accidentalNatural",
        [0xE0B9] = "noteheadSquareBlack",
        [0xE269] = "accidentalSharpSharp",
        [0xEA55] = "figbass4",
        [0xE53C] = "dynamicRinforzando1",
        [0xE684] = "harpSalzedoSlideWithSuppleness",
        [0xE5FA] = "windTrillKey",
        [0xE3D2] = "accSagittalSharp11v19MUp",
        [0xE7B4] = "pictWoundHardDown",
        [0xE4BA] = "articLaissezVibrerAbove",
        [0xE2B3] = "accidentalJohnstonSeven",
        [0xEA7C] = "functionGreaterThan",
        [0xE471] = "accidentalXenakisTwoThirdTonesSharp",
        [0xEE00] = "organGermanCUpper",
        [0xE303] = "accSagittal5CommaDown",
        [0xE277] = "accidentalThreeQuarterTonesSharpArrowDown",
        [0xE93E] = "mensuralCombStemUp",
        [0xE357] = "accSagittalFlat17CDown",
        [0xE5D6] = "brassDoitLong",
        [0xE4B1] = "articAccentStaccatoBelow",
        [0xE7D9] = "pictBeaterBrassMalletsUp",
        [0xEB4D] = "elecDataIn",
        [0xEA21] = "ornamentOriscus",
        [0xEB4F] = "elecDownload",
        [0xE1F4] = "textBlackNoteFrac16thShortStem",
        [0xED63] = "csymAccidentalDoubleSharp",
        [0xE532] = "dynamicFFFFF",
        [0xEAB4] = "wiggleWavyNarrow",
        [0xE8B0] = "accdnRH3RanksTremoloUpper8ve",
        [0xEAF6] = "beamAccelRit3",
        [0xEA6D] = "figbassCombiningRaising",
        [0xE0EB] = "noteheadCircledDoubleWholeLarge",
        [0xE944] = "mensuralCombStemDownFlagLeft",
        [0xE654] = "keyboardPedalDot",
        [0xE5C1] = "ornamentPrecompCadenceUpperPrefix",
        [0xE75A] = "pictLotusFlute",
        [0xEEEA] = "noteRiHalf",
        [0xE974] = "mensuralObliqueAsc3rdBlack",
        [0xE27A] = "accidentalArrowUp",
        [0xE97D] = "mensuralObliqueAsc5thVoid",
        [0xE81E] = "handbellsDamp3",
        [0xEB19] = "elecProjector",
        [0xE5F2] = "tripleTongueAbove",
        [0xE161] = "noteReBlack",
        [0xEBE3] = "luteItalianFret3",
        [0xE147] = "noteheadRectangularClusterWhiteBottom",
        [0xE461] = "accidentalSori",
        [0xEA31] = "daseianGraves2",
        [0xE17E] = "noteHSharpWhole",
        [0xEDBB] = "kahnHeelClick",
        [0xE092] = "timeSigParensLeftSmall",
        [0xE19E] = "noteCSharpBlack",
        [0xE335] = "accSagittalDoubleFlat",
        [0xEBEC] = "luteItalianTempoNeitherFastNorSlow",
        [0xE010] = "staff1Line",
        [0xE658] = "keyboardPedalHyphen",
        [0xED59] = "accidentalOneQuarterToneFlatStockhausen",
        [0xED8C] = "fingeringLeftBracketItalic",
        [0xEBA9] = "luteDurationQuarter",
        [0xE4AD] = "articMarcatoBelow",
        [0xE446] = "accidentalKucukMucennebSharp",
        [0xE0E4] = "noteheadCircledBlack",
        [0xEB1F] = "elecFastForward",
        [0xE447] = "accidentalBuyukMucennebSharp",
        [0xEDC4] = "kahnHeelStep",
        [0xE934] = "mensuralNoteheadLongaBlack",
        [0xE35B] = "accSagittalFlat7v11CDown",
        [0xE423] = "accidentalWyschnegradsky4TwelfthsSharp",
        [0xE9B0] = "chantPodatusLower",
        [0xEE58] = "accidentalCombiningLower47Quartertone",
        [0xE1D3] = "noteHalfUp",
        [0xEEA4] = "noteheadCowellFifthNoteSeriesWhole",
        [0xE700] = "pictTriangle",
        [0xE5F7] = "windHalfClosedHole2",
        [0xE375] = "accSagittal5v23SmallDiesisDown",
        [0xE61B] = "stringsOverpressureDownBow",
        [0xE3D5] = "accSagittalFlat49MDown",
        [0xE07E] = "clef15",
        [0xECDB] = "noteShapeMoonLeftDoubleWhole",
        [0xE4A6] = "articStaccatissimoAbove",
        [0xE7C0] = "pictGumMediumDown",
        [0xEC98] = "octaveSuperscriptV",
        [0xE129] = "noteheadClusterWhole3rd",
        [0xED60] = "csymAccidentalFlat",
        [0xE538] = "dynamicSforzandoPianissimo",
        [0xE6D1] = "pictSnareDrum",
        [0xE1F6] = "textBlackNoteFrac32ndLongStem",
        [0xE837] = "guitarString4",
        [0xE8B8] = "accdnRH4RanksSoftBass",
        [0xEBAF] = "luteFingeringRHSecond",
        [0xEE2B] = "organGermanSemifusa",
        [0xE869] = "analyticsInversion1",
        [0xE13F] = "noteheadDiamondClusterBlackTop",
        [0xEA54] = "figbass3",
        [0xE948] = "mensuralCombStemDownFlagExtended",
        [0xEE84] = "stringsDownBowBeyondBridge",
        [0xE30F] = "accSagittal35LargeDiesisDown",
        [0xE325] = "accSagittalFlat35MDown",
        [0xE615] = "stringsHalfHarmonic",
        [0xE721] = "pictSuspendedCymbal",
        [0xE227] = "tremoloFingered3",
        [0xE1DA] = "note16thDown",
        [0xEAD7] = "wiggleVibratoSmallFast",
        [0xED61] = "csymAccidentalNatural",
        [0xEACB] = "wiggleCircularEnd",
        [0xE930] = "mensuralNoteheadMaximaBlack",
        [0xE7DE] = "pictBeaterBow",
        [0xEC64] = "metricModulationArrowRight",
        [0xEB88] = "arrowheadOpenUp",
        [0xE32D] = "accSagittalDoubleFlat25SUp",
        [0xE293] = "accidentalFilledReversedFlatArrowDown",
        [0xE7E0] = "pictBeaterMetalHammer",
        [0xEC56] = "smnHistoryFlat",
        [0xE9E3] = "medRenSharpCroix",
        [0xE181] = "noteASharpHalf",
        [0xE633] = "pluckedLeftHandPizzicato",
        [0xE08A] = "timeSigCommon",
        [0xE373] = "accSagittal5v19CommaDown",
        [0xE1E3] = "note512thUp",
        [0xE4F2] = "restQuarterOld",
        [0xE309] = "accSagittal35MediumDiesisDown",
        [0xE37E] = "accSagittalSharp5v19CUp",
        [0xE9BC] = "chantLigaturaDesc5th",
        [0xE612] = "stringsUpBow",
        [0xE34F] = "accSagittalFlat55CUp",
        [0xE78E] = "pictBeaterMediumTimpaniRight",
        [0xEA85] = "functionNUpper",
        [0xE656] = "keyboardPedalHalf",
        [0xE807] = "pictLeftHandCircle",
        [0xE955] = "mensuralBlackSemiminima",
        [0xE141] = "noteheadDiamondClusterBlackBottom",
        [0xE8CA] = "accdnCombDot",
        [0xEBC4] = "luteFrenchFretE",
        [0xE47B] = "accidentalWilsonPlus",
        [0xE85A] = "fretboardO",
        [0xEE27] = "organGermanSemibrevis",
        [0xEBA7] = "luteDurationWhole",
        [0xE480] = "accidentalQuarterToneFlatFilledReversed",
        [0xE661] = "keyboardPedalHeel1",
        [0xEB9C] = "staffPosLower5",
        [0xE1DD] = "note64thUp",
        [0xE454] = "accidental1CommaFlat",
        [0xED82] = "fingering2Italic",
        [0xE845] = "guitarVolumeSwell",
        [0xE65D] = "keyboardPedalUpSpecial",
        [0xE771] = "pictBeaterSoftXylophoneDown",
        [0xE002] = "bracket",
        [0xE098] = "timeSigFractionHalf",
        [0xEF05] = "scaleDegree6",
        [0xEBE7] = "luteItalianFret7",
        [0xEEB5] = "noteheadCowellFifteenthNoteSeriesBlack",
        [0xEDAD] = "kahnKneeInward",
        [0xE037] = "barlineDotted",
        [0xE5B3] = "ornamentPrecompAppoggTrillSuffix",
        [0xEC0D] = "luteGermanOLower",
        [0xEE87] = "stringsScrapeParallelOutward",
        [0xEA80] = "functionDLower",
        [0xE270] = "accidentalQuarterToneFlatArrowUp",
        [0xE715] = "pictHandbell",
        [0xE571] = "ornamentRightFacingHalfCircle",
        [0xE156] = "noteTiWhole",
        [0xEB50] = "elecUpload",
        [0xE07B] = "cClefChange",
        [0xE020] = "staff5LinesNarrow",
        [0xE2F5] = "accidentalQuarterFlatEqualTempered",
        [0xE07C] = "fClefChange",
        [0xE0A3] = "noteheadHalf",
        [0xEBC8] = "luteFrenchFretI",
        [0xEB2B] = "elecEject",
        [0xEDE1] = "kahnBackRiff",
        [0xE0C4] = "noteheadTriangleDownWhole",
        [0xE3F4] = "accSagittal1MinaUp",
        [0xE3CA] = "accSagittalSharp7v19CUp",
        [0xE872] = "csymAugmented",
        [0xE12A] = "noteheadClusterHalf3rd",
        [0xE433] = "accidentalWyschnegradsky9TwelfthsFlat",
        [0xE5E7] = "brassMuteOpen",
        [0xE92D] = "mensuralModusImperfectumVert",
        [0xEBE8] = "luteItalianFret8",
        [0xE4E5] = "restQuarter",
        [0xE482] = "accidentalNaturalReversed",
        [0xE53F] = "dynamicDiminuendoHairpin",
        [0xE005] = "reversedBracketTop",
        [0xEAC7] = "wiggleCircularLarger",
        [0xEABA] = "wiggleSawtoothNarrow",
        [0xE5C7] = "ornamentPrecompInvertedMordentUpperPrefix",
        [0xE7E9] = "pictBeaterCombiningParentheses",
        [0xE0F3] = "noteheadLargeArrowDownHalf",
        [0xEE1F] = "organGermanSemibrevisRest",
        [0xEEF9] = "noteLeBlack",
        [0xE816] = "handbellsMalletLft",
        [0xE4F4] = "restWholeLegerLine",
        [0xE030] = "barlineSingle",
        [0xEB76] = "arrowOpenLeft",
        [0xEA81] = "functionDD",
        [0xEC11] = "luteGermanSLower",
        [0xEE1C] = "organGermanAugmentationDot",
        [0xE953] = "mensuralBlackSemibrevis",
        [0xE4AC] = "articMarcatoAbove",
        [0xE35F] = "accSagittalDoubleFlat5v11SUp",
        [0xE711] = "pictCowBell",
        [0xEC38] = "kievanNoteQuarterStemDown",
        [0xEC41] = "kodalyHandRe",
        [0xE66A] = "keyboardBebung3DotsAbove",
        [0xE371] = "accSagittal23CommaDown",
        [0xECD0] = "noteShapeRoundDoubleWhole",
        [0xEC52] = "smnFlat",
        [0xE1BC] = "noteShapeMoonWhite",
        [0xECB6] = "metNote1024thDown",
        [0xE456] = "accidental3CommaFlat",
        [0xE1AA] = "noteGSharpBlack",
        [0xEC35] = "kievanNoteHalfStaffLine",
        [0xE63B] = "pluckedDampOnStem",
        [0xE2C8] = "accidentalSharpOneArrowUp",
        [0xEEA8] = "noteheadCowellSeventhNoteSeriesHalf",
        [0xE271] = "accidentalThreeQuarterTonesFlatArrowDown",
        [0xE980] = "mensuralObliqueDesc2ndBlack",
        [0xE730] = "pictTamTam",
        [0xE47D] = "accidentalLargeDoubleSharp",
        [0xE99B] = "chantQuilisma",
        [0xE4BB] = "articLaissezVibrerBelow",
        [0xE5C8] = "ornamentPrecompTrillLowerSuffix",
        [0xE5FC] = "windSharpEmbouchure",
        [0xE0B0] = "noteheadCircleXDoubleWhole",
        [0xEA9B] = "functionILower",
        [0xEE94] = "mensuralProportion9",
        [0xEB92] = "staffPosRaise3",
        [0xE32E] = "accSagittalDoubleSharp7CDown",
        [0xEC14] = "luteGermanXLower",
        [0xE0F5] = "noteheadParenthesisLeft",
        [0xE0A4] = "noteheadBlack",
        [0xEA9A] = "functionIUpper",
        [0xEA36] = "daseianFinales3",
        [0xE5A8] = "ornamentBottomRightConvexStroke",
        [0xEDCF] = "kahnFlam",
        [0xE06F] = "schaefferClef",
        [0xE9E5] = "medRenNaturalWithCross",
        [0xED13] = "fingering3",
        [0xEB30] = "elecVolumeLevel40",
        [0xE0A2] = "noteheadWhole",
        [0xEBCF] = "luteFrench9thCourse",
        [0xE8AF] = "accdnRH3RanksTremoloLower8ve",
        [0xECA4] = "metNoteHalfDown",
        [0xE5D3] = "brassLiftLong",
        [0xEDD8] = "kahnBackFlap",
        [0xE98E] = "mensuralObliqueDesc5thBlackVoid",
        [0xE2E8] = "accidentalCombiningLower19Schisma",
        [0xEEA2] = "noteheadCowellThirdNoteSeriesHalf",
        [0xED15] = "fingering5",
        [0xE0C7] = "noteheadTriangleDownBlack",
        [0xED18] = "fingeringTLower",
        [0xE583] = "ornamentVerticalLine",
        [0xEE70] = "swissRudimentsNoteheadBlackFlam",
        [0xECD3] = "noteShapeTriangleLeftDoubleWhole",
        [0xE0C0] = "noteheadTriangleLeftBlack",
        [0xE763] = "pictLionsRoar",
        [0xE34C] = "accSagittalSharp7v11CDown",
        [0xE5DB] = "brassFallSmoothMedium",
        [0xE426] = "accidentalWyschnegradsky7TwelfthsSharp",
        [0xED5D] = "accidentalSharpRepeatedSpaceStockhausen",
        [0xE808] = "pictSwishStem",
        [0xE6E0] = "pictSlitDrum",
        [0xE212] = "stemSwished",
        [0xECB0] = "metNote128thDown",
        [0xEA3E] = "daseianExcellentes3",
        [0xEBF4] = "luteItalianHoldFinger",
        [0xE925] = "mensuralProlationCombiningStroke",
        [0xE764] = "pictGlassHarp",
        [0xE2CF] = "accidentalDoubleFlatTwoArrowsUp",
        [0xE22E] = "tremoloDivisiDots2",
        [0xE608] = "windMultiphonicsWhiteStem",
        [0xE4E2] = "restDoubleWhole",
        [0xE343] = "accSagittal17CommaDown",
        [0xE159] = "noteReHalf",
        [0xE120] = "noteheadClusterSquareWhite",
        [0xEB37] = "elecMIDIController20",
        [0xE146] = "noteheadRectangularClusterWhiteMiddle",
        [0xECAF] = "metNote128thUp",
        [0xE35E] = "accSagittalDoubleSharp5v11SDown",
        [0xE536] = "dynamicSforzando1",
        [0xEAE7] = "wiggleVibratoLargeSlower",
        [0xEBE0] = "luteItalianFret0",
        [0xE123] = "noteheadClusterRoundBlack",
        [0xE046] = "daCapo",
        [0xE83D] = "guitarOpenPedal",
        [0xEB10] = "elecMicrophone",
        [0xE9C3] = "chantStrophicusLiquescens3rd",
        [0xEBD1] = "luteFrenchMordentUpper",
        [0xE0E1] = "noteheadDiamondHalfOld",
        [0xE1B5] = "noteShapeTriangleRightBlack",
        [0xE8E1] = "controlEndBeam",
        [0xE205] = "textHeadlessBlackNoteLongStem",
        [0xE39E] = "accSagittal23SmallDiesisUp",
        [0xE187] = "noteCSharpHalf",
        [0xE1AC] = "noteHSharpBlack",
        [0xEA7D] = "functionSSUpper",
        [0xEBAE] = "luteFingeringRHFirst",
        [0xE624] = "stringsThumbPosition",
        [0xE321] = "accSagittalFlat7CDown",
        [0xE80A] = "pictTurnLeftStem",
        [0xECDC] = "noteShapeArrowheadLeftDoubleWhole",
        [0xE504] = "repeatBarSlash",
        [0xE897] = "conductorBeat2Compound",
        [0xE6FA] = "pictQuijada",
        [0xE2B5] = "accidentalJohnstonDown",
        [0xEA0B] = "mensuralCustosTurn",
        [0xE6DA] = "pictTomTomIndoAmerican",
        [0xE073] = "gClefReversed",
        [0xE076] = "fClefReversed",
        [0xE98D] = "mensuralObliqueDesc5thVoid",
        [0xE951] = "mensuralBlackLonga",
        [0xEE82] = "stringsDownBowAwayFromBody",
        [0xECB4] = "metNote512thDown",
        [0xE311] = "accSagittalFlat25SUp",
        [0xEACD] = "wiggleVibratoSmallestFastest",
        [0xE8AD] = "accdnRH3RanksMaster",
        [0xE9D1] = "chantIctusBelow",
        [0xE003] = "bracketTop",
        [0xEA3C] = "daseianExcellentes1",
        [0xE322] = "accSagittalSharp25SUp",
        [0xEA72] = "functionTwo",
        [0xE59A] = "ornamentBottomLeftConcaveStroke",
        [0xEA7A] = "functionLessThan",
        [0xE075] = "cClefReversed",
        [0xED88] = "fingering8Italic",
        [0xEC1C] = "luteGermanFUpper",
        [0xE7F8] = "pictOpen",
        [0xEB8C] = "arrowheadOpenDown",
        [0xEA96] = "functionRepetition2",
        [0xE676] = "keyboardPedalParensLeft",
        [0xE586] = "glissandoDown",
        [0xEA69] = "figbassBracketRight",
        [0xE66E] = "keyboardPlayWithRH",
        [0xE0D0] = "noteheadSlashedBlack2",
        [0xE7E6] = "pictBeaterFingernails",
        [0xE12C] = "noteheadClusterDoubleWholeTop",
        [0xE3C4] = "accSagittalSharp143CUp",
        [0xE1C5] = "noteShapeIsoscelesTriangleBlack",
        [0xEB3A] = "elecMIDIController80",
        [0xE3E3] = "accSagittalDoubleFlat49SUp",
        [0xE144] = "noteheadRectangularClusterBlackBottom",
        [0xE913] = "mensuralProlation4",
        [0xE914] = "mensuralProlation5",
        [0xE931] = "mensuralNoteheadMaximaVoid",
        [0xEEA7] = "noteheadCowellSeventhNoteSeriesWhole",
        [0xE4E9] = "rest64th",
        [0xE3ED] = "accSagittalDoubleFlat17kUp",
        [0xE2E4] = "accidentalLowerOneTridecimalQuartertone",
        [0xE857] = "fretboard6StringNut",
        [0xECC0] = "figbass7Diminished",
        [0xE319] = "accSagittalFlat",
        [0xE3FD] = "accSagittal3TinasDown",
        [0xEC1E] = "luteGermanHUpper",
        [0xE0AA] = "noteheadXOrnate",
        [0xE830] = "guitarVibratoBarScoop",
        [0xE167] = "noteSiBlack",
        [0xE5F0] = "doubleTongueAbove",
        [0xECA5] = "metNoteQuarterUp",
        [0xE244] = "flag32ndUp",
        [0xE634] = "arpeggiatoUp",
        [0xE1C8] = "noteShapeArrowheadLeftWhite",
        [0xE819] = "handbellsSwingDown",
        [0xECE3] = "timeSig3Turned",
        [0xEDBE] = "kahnRightCross",
        [0xE5D4] = "brassDoitShort",
        [0xE152] = "noteMiWhole",
        [0xE0B2] = "noteheadCircleXHalf",
        [0xEE90] = "mensuralProportion5",
        [0xE92E] = "mensuralTempusPerfectumHoriz",
        [0xEBEE] = "luteItalianTempoVerySlow",
        [0xEA8A] = "functionSLower",
        [0xE382] = "accSagittalDoubleSharp5v23SDown",
        [0xED16] = "fingeringTUpper",
        [0xECD7] = "noteShapeTriangleRoundDoubleWhole",
        [0xEE1A] = "organGermanOctaveDown",
        [0xE8C2] = "accdnLH3Ranks2Square",
        [0xE356] = "accSagittalSharp17CUp",
        [0xEAC2] = "wiggleCircularConstantLarge",
        [0xE332] = "accSagittalDoubleSharp5v7kDown",
        [0xE6DF] = "pictLogDrum",
        [0xE5FE] = "windLessRelaxedEmbouchure",
        [0xEA7E] = "functionSSLower",
        [0xEC20] = "luteGermanKUpper",
        [0xEA8F] = "functionBracketLeft",
        [0xE4C0] = "fermataAbove",
        [0xE68B] = "harpSalzedoTimpanicSounds",
        [0xE915] = "mensuralProlation6",
        [0xE4E7] = "rest16th",
        [0xED84] = "fingering4Italic",
        [0xEA5C] = "figbass6Raised",
        [0xEE28] = "organGermanMinima",
        [0xEBD3] = "luteFrenchMordentInverted",
        [0xEBCD] = "luteFrench7thCourse",
        [0xE0C8] = "noteheadTriangleUpRightWhite",
        [0xE7D8] = "pictBeaterWireBrushesDown",
        [0xEDDA] = "kahnBackRip",
        [0xE894] = "conductorBeat2Simple",
        [0xE201] = "textTupletBracketStartLongStem",
        [0xE0A6] = "noteheadXDoubleWhole",
        [0xEE34] = "organGerman4Minimae",
        [0xEC21] = "luteGermanLUpper",
        [0xE1AE] = "noteEmptyHalf",
        [0xE53A] = "dynamicSforzatoPiano",
        [0xE13E] = "noteheadDiamondClusterWhiteBottom",
        [0xE4CA] = "fermataLongHenzeAbove",
        [0xEE0F] = "organGermanDisLower",
        [0xE323] = "accSagittalFlat25SDown",
        [0xE111] = "noteheadRoundWhiteLarge",
        [0xE324] = "accSagittalSharp35MUp",
        [0xE9D2] = "chantCirculusAbove",
        [0xE899] = "conductorBeat4Compound",
        [0xEB3E] = "elecAudioChannelsOne",
        [0xE296] = "accidentalFilledReversedFlatAndFlat",
        [0xEDD6] = "kahnRip",
        [0xE342] = "accSagittal17CommaUp",
        [0xEEAC] = "noteheadCowellNinthNoteSeriesBlack",
        [0xE5B1] = "ornamentPrecompDescendingSlide",
        [0xE2CA] = "accidentalDoubleFlatTwoArrowsDown",
        [0xE2B6] = "accidentalJohnston13",
        [0xE1F8] = "textCont8thBeamLongStem",
        [0xE37F] = "accSagittalFlat5v19CDown",
        [0xE15B] = "noteFaHalf",
        [0xE651] = "keyboardPedalP",
        [0xE9E0] = "medRenFlatSoftB",
        [0xEA91] = "functionParensLeft",
        [0xE31E] = "accSagittalSharp5CUp",
        [0xE3E7] = "accSagittalDoubleFlat19CUp",
        [0xEBCA] = "luteFrenchFretL",
        [0xE66B] = "keyboardBebung3DotsBelow",
        [0xE9E1] = "medRenFlatHardB",
        [0xEB64] = "arrowBlackDown",
        [0xE8C9] = "accdnCombLH3RanksEmptySquare",
        [0xEB26] = "elecMute",
        [0xE3F8] = "accSagittal1TinaUp",
        [0xE4F1] = "restHBarRight",
        [0xE452] = "accidental3CommaSharp",
        [0xE928] = "mensuralProportion3",
        [0xE302] = "accSagittal5CommaUp",
        [0xE639] = "pluckedDampAll",
        [0xE773] = "pictBeaterSoftXylophoneLeft",
        [0xE3BB] = "accSagittalFlat143CUp",
        [0xE442] = "accidentalBakiyeFlat",
        [0xE6D3] = "pictSnareDrumMilitary",
        [0xE892] = "conductorRightBeat",
        [0xE2C6] = "accidentalFlatOneArrowUp",
        [0xE889] = "tuplet9",
        [0xE2F8] = "accidentalCombiningRaise53LimitComma",
        [0xE57F] = "ornamentObliqueLineHorizBeforeNote",
        [0xE15E] = "noteTiHalf",
        [0xE4C7] = "fermataLongBelow",
        [0xEC44] = "kodalyHandSo",
        [0xE98B] = "mensuralObliqueDesc4thWhite",
        [0xEDD7] = "kahnFlapStep",
        [0xEB12] = "elecHeadset",
        [0xEBC7] = "luteFrenchFretH",
        [0xE7CC] = "pictBeaterHammerWoodDown",
        [0xE47C] = "accidentalWilsonMinus",
        [0xE1B6] = "noteShapeTriangleLeftWhite",
        [0xE26A] = "accidentalParensLeft",
        [0xE350] = "accSagittalSharp17CDown",
        [0xEB62] = "arrowBlackRight",
        [0xE3DC] = "accSagittalSharp5v13LUp",
        [0xEBC6] = "luteFrenchFretG",
        [0xE1BE] = "noteShapeTriangleRoundWhite",
        [0xE331] = "accSagittalDoubleFlat5CUp",
        [0xEA2A] = "medRenOriscusCMN",
        [0xE197] = "noteABlack",
        [0xE942] = "mensuralCombStemDownFlagRight",
        [0xE862] = "analyticsStartStimme",
        [0xEB43] = "elecAudioChannelsFive",
        [0xE0F7] = "noteheadCircleSlash",
        [0xEAB5] = "wiggleWavy",
        [0xE91B] = "mensuralProportionTempusPerfectum",
        [0xE019] = "staff4LinesWide",
        [0xE2A5] = "accidentalSims4Up",
        [0xEB69] = "arrowWhiteUpRight",
        [0xE04A] = "segnoSerpent1",
        [0xEA3F] = "daseianExcellentes4",
        [0xE04B] = "segnoSerpent2",
        [0xE115] = "noteheadRoundWhiteWithDot",
        [0xE0F9] = "noteheadHeavyXHat",
        [0xE846] = "guitarStrumUp",
        [0xEAA3] = "wiggleTrillFast",
        [0xEE39] = "organGerman5Semiminimae",
        [0xE3AA] = "accSagittal11v19LargeDiesisUp",
        [0xECA0] = "metNoteDoubleWhole",
        [0xE3A8] = "accSagittal49LargeDiesisUp",
        [0xE190] = "noteFSharpHalf",
        [0xE434] = "accidentalWyschnegradsky10TwelfthsFlat",
        [0xE90A] = "mensuralCclefPetrucciPosHigh",
        [0xEA53] = "figbass2Raised",
        [0xE4CF] = "breathMarkTick",
        [0xEB4C] = "elecVideoOut",
        [0xE762] = "pictSandpaperBlocks",
        [0xEAF8] = "beamAccelRit5",
        [0xE267] = "accidentalNaturalFlat",
        [0xEAAE] = "wiggleArpeggiatoDownArrow",
        [0xE8AE] = "accdnRH3RanksTwoChoirs",
        [0xE1E2] = "note256thDown",
        [0xE3DE] = "accSagittalUnused3",
        [0xE672] = "keyboardPedalHookStart",
        [0xE65F] = "keyboardMiddlePedalPictogram",
        [0xE5F8] = "windHalfClosedHole3",
        [0xEDED] = "kahnOverTheTopTap",
        [0xECE2] = "timeSig2Turned",
        [0xEAE8] = "wiggleVibratoLargeSlowest",
        [0xE35A] = "accSagittalSharp7v11CUp",
        [0xE9BD] = "chantConnectingLineAsc2nd",
        [0xEE23] = "organGermanSemifusaRest",
        [0xE766] = "pictMusicalSaw",
        [0xE8B6] = "accdnRH4RanksTenor",
        [0xEB3B] = "elecMIDIController100",
        [0xEE2C] = "organGerman2Minimae",
        [0xE365] = "accSagittalDoubleFlat17CUp",
        [0xEA03] = "mensuralCustosDown",
        [0xE994] = "chantAuctumAsc",
        [0xE52B] = "dynamicPP",
        [0xE7ED] = "pictBeaterBrassMalletsRight",
        [0xEAB6] = "wiggleWavyWide",
        [0xE273] = "accidentalQuarterToneFlatNaturalArrowDown",
        [0xE6FB] = "pictBambooScraper",
        [0xEA9C] = "functionKUpper",
        [0xEB2F] = "elecVolumeLevel20",
        [0xE6DD] = "pictBongos",
        [0xE7A7] = "pictBeaterMediumYarnDown",
        [0xE220] = "tremolo1",
        [0xE659] = "keyboardPedalSost",
        [0xE732] = "pictGong",
        [0xE0F4] = "noteheadLargeArrowDownBlack",
        [0xE3D8] = "accSagittalSharp49LUp",
        [0xE2D9] = "accidentalDoubleFlatThreeArrowsUp",
        [0xEA40] = "daseianResidua1",
        [0xED81] = "fingering1Italic",
        [0xE474] = "accidentalThreeQuarterTonesSharpBusotti",
        [0xE687] = "harpSalzedoWhistlingSounds",
        [0xE7C1] = "pictGumMediumRight",
        [0xEEE2] = "noteRaWhole",
        [0xE9C4] = "chantStrophicusLiquescens4th",
        [0xEA29] = "medRenStrophicusCMN",
        [0xE440] = "accidentalBuyukMucennebFlat",
        [0xE6E1] = "pictBrakeDrum",
        [0xE665] = "keyboardPedalToe2",
        [0xE07D] = "clef8",
        [0xE976] = "mensuralObliqueAsc3rdBlackVoid",
        [0xE24D] = "flag512thDown",
        [0xE2B1] = "accidentalJohnstonMinus",
        [0xE3E9] = "accSagittalDoubleFlat11v49CUp",
        [0xE854] = "fretboard5String",
        [0xEDC5] = "kahnToeStep",
        [0xE340] = "accSagittal7v11KleismaUp",
        [0xE693] = "harpTuningKeyGlissando",
        [0xE8CC] = "accdnPull",
        [0xE9B5] = "chantEntryLineAsc3rd",
        [0xEA6B] = "figbassParensRight",
        [0xEA22] = "medRenLiquescenceCMN",
        [0xE2B7] = "accidentalJohnston31",
        [0xE642] = "vocalMouthOpen",
        [0xE5F4] = "windClosedHole",
        [0xE079] = "accdnDiatonicClef",
        [0xE378] = "accSagittalSharp5v19CDown",
        [0xEA77] = "functionSeven",
        [0xE941] = "mensuralCombStemUpFlagRight",
        [0xE00A] = "splitBarDivider",
        [0xE102] = "noteheadSlashWhiteWhole",
        [0xEEE7] = "noteLeWhole",
        [0xE999] = "chantPunctumLinea",
        [0xE193] = "noteGSharpHalf",
        [0xE7BA] = "pictWoundSoftLeft",
        [0xED44] = "articSoftAccentTenutoAbove",
        [0xE48A] = "accidentalOneThirdToneSharpFerneyhough",
        [0xEDAF] = "kahnTrench",
        [0xECE1] = "timeSig1Turned",
        [0xEC95] = "octaveBaselineM",
        [0xE7A6] = "pictBeaterMediumYarnUp",
        [0xE9D7] = "chantAccentusBelow",
        [0xE09B] = "timeSigFractionTwoThirds",
        [0xE0F1] = "noteheadLargeArrowDownDoubleWhole",
        [0xEB32] = "elecVolumeLevel80",
        [0xE384] = "accSagittalDoubleSharp5v19CDown",
        [0xE63A] = "pluckedPlectrum",
        [0xE131] = "noteheadClusterWholeBottom",
        [0xE370] = "accSagittal23CommaUp",
        [0xE1DC] = "note32ndDown",
        [0xEB2C] = "elecVolumeFader",
        [0xE4EF] = "restHBarLeft",
        [0xEC94] = "octaveSuperscriptB",
        [0xEA59] = "figbass5Raised2",
        [0xEDC3] = "kahnStamp",
        [0xE4EA] = "rest128th",
        [0xEA04] = "chantCustosStemUpPosLowest",
        [0xE2E0] = "accidentalLowerTwoSeptimalCommas",
        [0xE848] = "guitarBarreFull",
        [0xE8AC] = "accdnRH3RanksAccordion",
        [0xE39F] = "accSagittal23SmallDiesisDown",
        [0xEAC6] = "wiggleCircularLargerStill",
        [0xEAE3] = "wiggleVibratoLargeFasterStill",
        [0xE616] = "stringsMuteOn",
        [0xE7DF] = "pictBeaterMallet",
        [0xE834] = "guitarString1",
        [0xE0DF] = "noteheadDiamondDoubleWholeOld",
        [0xECAA] = "metNote16thDown",
        [0xE139] = "noteheadDiamondClusterBlack2nd",
        [0xE0F2] = "noteheadLargeArrowDownWhole",
        [0xE362] = "accSagittalDoubleSharp55CDown",
        [0xE12F] = "noteheadClusterWholeTop",
        [0xE9B4] = "chantEntryLineAsc2nd",
        [0xE622] = "stringsFouette",
        [0xE78B] = "pictBeaterSoftTimpaniLeft",
        [0xE780] = "pictBeaterSoftGlockenspielUp",
        [0xEA01] = "mensuralSignumDown",
        [0xE589] = "ornamentTremblementCouperin",
        [0xE477] = "accidentalTavenerFlat",
        [0xE9F1] = "mensuralRestLongaPerfecta",
        [0xE908] = "mensuralCclefPetrucciPosLow",
        [0xE880] = "tuplet0",
        [0xE315] = "accSagittalFlat5CUp",
        [0xE5FF] = "windTightEmbouchure",
        [0xE0A9] = "noteheadXBlack",
        [0xEC23] = "luteGermanNUpper",
        [0xE211] = "stemSprechgesang",
        [0xE603] = "windStrongAirPressure",
        [0xEB66] = "arrowBlackLeft",
        [0xE632] = "pluckedBuzzPizzicato",
        [0xE6AC] = "pictMarSmithBrindle",
        [0xEB21] = "elecSkipForwards",
        [0xE044] = "repeatDot",
        [0xE1FB] = "textCont32ndBeamLongStem",
        [0xE6DE] = "pictConga",
        [0xE5FD] = "windRelaxedEmbouchure",
        [0xE605] = "windReedPositionOut",
        [0xED57] = "accidentalSharpLoweredStockhausen",
        [0xE066] = "fClef15ma",
        [0xE097] = "timeSigFractionQuarter",
        [0xE604] = "windReedPositionNormal",
        [0xE5F9] = "windOpenHole",
        [0xE609] = "windMultiphonicsBlackWhiteStem",
        [0xE607] = "windMultiphonicsBlackStem",
        [0xEDC1] = "kahnLeftToeStrike",
        [0xE5FB] = "windFlatEmbouchure",
        [0xE4EB] = "rest256th",
        [0xE80B] = "pictTurnRightLeftStem",
        [0xEAB1] = "wiggleVibratoWide",
        [0xE2DA] = "accidentalFlatThreeArrowsUp",
        [0xE8F8] = "chantCaesura",
        [0xE95B] = "mensuralBlackSemibrevisOblique",
        [0xEAD3] = "wiggleVibratoSmallestSlowest",
        [0xEAD2] = "wiggleVibratoSmallestSlower",
        [0xEAD1] = "wiggleVibratoSmallestSlow",
        [0xE9D4] = "chantSemicirculusAbove",
        [0xEACE] = "wiggleVibratoSmallestFasterStill",
        [0xEACF] = "wiggleVibratoSmallestFaster",
        [0xEB27] = "elecUnmute",
        [0xE113] = "noteheadRoundBlack",
        [0xED32] = "accidentalFlatArabic",
        [0xE016] = "staff1LineWide",
        [0xE695] = "harpSalzedoAeolianAscending",
        [0xEA3B] = "daseianSuperiores4",
        [0xEAD9] = "wiggleVibratoSmallSlower",
        [0xE710] = "pictSleighBell",
        [0xE563] = "graceNoteAppoggiaturaStemDown",
        [0xE5A5] = "ornamentLowRightConcaveStroke",
        [0xE52A] = "dynamicPPP",
        [0xEAD5] = "wiggleVibratoSmallFasterStill",
        [0xEAD6] = "wiggleVibratoSmallFaster",
        [0xEADF] = "wiggleVibratoMediumSlow",
        [0xEADB] = "wiggleVibratoMediumFastest",
        [0xEA57] = "figbass5",
        [0xE876] = "csymParensRightTall",
        [0xE513] = "ottavaBassaBa",
        [0xE8A1] = "accdnRH3RanksClarinet",
        [0xE0A5] = "noteheadNull",
        [0xE3B8] = "accSagittalSharp11v49CDown",
        [0xED43] = "articSoftAccentStaccatoBelow",
        [0xE153] = "noteFaWhole",
        [0xE4A4] = "articTenutoAbove",
        [0xE909] = "mensuralCclefPetrucciPosMiddle",
        [0xE2DD] = "accidentalDoubleSharpThreeArrowsUp",
        [0xEAED] = "wiggleVibratoLargestSlow",
        [0xEAE9] = "wiggleVibratoLargestFastest",
        [0xEAEA] = "wiggleVibratoLargestFasterStill",
        [0xEA39] = "daseianSuperiores2",
        [0xE7FA] = "pictDamp2",
        [0xE5BA] = "ornamentPrecompSlideTrillSuffixMuffat",
        [0xED53] = "accidentalFlatLoweredStockhausen",
        [0xE6A2] = "pictXylTenor",
        [0xEAEC] = "wiggleVibratoLargestFast",
        [0xE545] = "dynamicHairpinBracketRight",
        [0xE68D] = "harpSalzedoFluidicSoundsLeft",
        [0xE995] = "chantAuctumDesc",
        [0xECF4] = "timeSig4Reversed",
        [0xEAE2] = "wiggleVibratoLargeFastest",
        [0xED50] = "accidentalRaisedStockhausen",
        [0xEAE4] = "wiggleVibratoLargeFaster",
        [0xE299] = "accidentalHalfSharpArrowUp",
        [0xE546] = "dynamicCombinedSeparatorColon",
        [0xEE2A] = "organGermanFusa",
        [0xE0EC] = "noteheadCircledXLarge",
        [0xEC04] = "luteGermanELower",
        [0xE2EE] = "accidentalCombiningOpenCurlyBrace",
        [0xEAE5] = "wiggleVibratoLargeFast",
        [0xEB33] = "elecVolumeLevel100",
        [0xE112] = "noteheadRoundWhiteWithDotLarge",
        [0xEAB0] = "wiggleVibrato",
        [0xEAE0] = "wiggleVIbratoMediumSlower",
        [0xEDC8] = "kahnStampStamp",
        [0xE4A7] = "articStaccatissimoBelow",
        [0xE07F] = "clefChangeCombining",
        [0xE8AA] = "accdnRH3RanksHarmonium",
        [0xEBA6] = "luteDurationDoubleWhole",
        [0xE9BE] = "chantConnectingLineAsc3rd",
        [0xE177] = "noteFFlatWhole",
        [0xE22C] = "unmeasuredTremolo",
        [0xE83E] = "guitarHalfOpenPedal",
        [0xE473] = "accidentalSharpOneHorizontalStroke",
        [0xE911] = "mensuralProlation2",
        [0xE8BC] = "accdnLH2Ranks16Round",
        [0xECDD] = "noteShapeTriangleRoundLeftDoubleWhole",
        [0xE724] = "pictSizzleCymbal",
        [0xEAA5] = "wiggleTrillSlow",
        [0xEA93] = "functionAngleLeft",
        [0xEAA1] = "wiggleTrillFasterStill",
        [0xE52E] = "dynamicPF",
        [0xEAA2] = "wiggleTrillFaster",
        [0xEAA4] = "wiggleTrill",
        [0xEAB9] = "wiggleSquareWaveWide",
        [0xEAB7] = "wiggleSquareWaveNarrow",
        [0xE8A7] = "accdnRH3RanksImitationMusette",
        [0xEAB8] = "wiggleSquareWave",
        [0xEABC] = "wiggleSawtoothWide",
        [0xEABB] = "wiggleSawtooth",
        [0xE2C7] = "accidentalNaturalOneArrowUp",
        [0xEABF] = "wiggleGlissandoGroup3",
        [0xEB03] = "beamAccelRitFinal",
        [0xEBCE] = "luteFrench8thCourse",
        [0xEE22] = "organGermanFusaRest",
        [0xEA32] = "daseianGraves3",
        [0xEAAF] = "wiggleGlissando",
        [0xE172] = "noteDWhole",
        [0xE723] = "pictHiHatOnStand",
        [0xEAC4] = "wiggleCircularStart",
        [0xEA35] = "daseianFinales2",
        [0xE743] = "pictCabasa",
        [0xEAC5] = "wiggleCircularLargest",
        [0xE3AD] = "accSagittal5v13LargeDiesisDown",
        [0xE140] = "noteheadDiamondClusterBlackMiddle",
        [0xEA7B] = "functionMinus",
        [0xE200] = "textTupletBracketEndShortStem",
        [0xE71A] = "pictBellTree",
        [0xED54] = "accidentalNaturalRaisedStockhausen",
        [0xEAC1] = "wiggleCircularConstantFlipped",
        [0xEAC0] = "wiggleCircularConstant",
        [0xE8F0] = "chantStaff",
        [0xE5ED] = "brassLiftSmoothMedium",
        [0xE7AC] = "pictBeaterHardYarnRight",
        [0xE2EF] = "accidentalCombiningCloseCurlyBrace",
        [0xEEAD] = "noteheadCowellEleventhNoteSeriesWhole",
        [0xEAC9] = "wiggleCircular",
        [0xE4A8] = "articStaccatissimoWedgeAbove",
        [0xEA75] = "functionFive",
        [0xEAAD] = "wiggleArpeggiatoUpArrow",
        [0xE37B] = "accSagittalFlat23CUp",
        [0xEAA9] = "wiggleArpeggiatoUp",
        [0xE0E3] = "noteheadDiamondHalfFilled",
        [0xE376] = "accSagittalSharp5v23SDown",
        [0xE3D0] = "accSagittalSharp5v13MUp",
        [0xEBD0] = "luteFrench10thCourse",
        [0xEAAC] = "wiggleArpeggiatoDownSwash",
        [0xEAAA] = "wiggleArpeggiatoDown",
        [0xE64A] = "vocalTongueFingerClickStockhausen",
        [0xE2B0] = "accidentalJohnstonPlus",
        [0xE34A] = "accSagittalSharp5v11SDown",
        [0xE648] = "vocalTongueClickStockhausen",
        [0xE5C6] = "ornamentPrecompMordentUpperPrefix",
        [0xE19F] = "noteDFlatBlack",
        [0xE645] = "vocalSprechgesang",
        [0xE2F2] = "accidentalNaturalEqualTempered",
        [0xE6A9] = "pictEmptyTrap",
        [0xE643] = "vocalMouthWideOpen",
        [0xE320] = "accSagittalSharp7CUp",
        [0xE48B] = "accidentalOneThirdToneFlatFerneyhough",
        [0xECD5] = "noteShapeTriangleUpDoubleWhole",
        [0xE0CE] = "noteheadParenthesis",
        [0xE683] = "harpPedalDivider",
        [0xE644] = "vocalMouthPursed",
        [0xE640] = "vocalMouthClosed",
        [0xE64B] = "vocalHalbGesungen",
        [0xE649] = "vocalFingerClickStockhausen",
        [0xE51E] = "ventiduesimaBassaMb",
        [0xE68C] = "harpSalzedoMuffleTotally",
        [0xE519] = "ventiduesimaBassa",
        [0xE518] = "ventiduesimaAlta",
        [0xE517] = "ventiduesima",
        [0xE1A6] = "noteFBlack",
        [0xE06A] = "unpitchedPercussionClef2",
        [0xE069] = "unpitchedPercussionClef1",
        [0xE22D] = "unmeasuredTremoloSimple",
        [0xE88A] = "tupletColon",
        [0xE821] = "handbellsTablePairBells",
        [0xE754] = "pictWindMachine",
        [0xE886] = "tuplet6",
        [0xE884] = "tuplet4",
        [0xE0CF] = "noteheadSlashedBlack1",
        [0xE0E2] = "noteheadDiamondBlackOld",
        [0xE1C4] = "noteShapeIsoscelesTriangleWhite",
        [0xE883] = "tuplet3",
        [0xE313] = "accSagittalFlat7CUp",
        [0xECA1] = "metNoteDoubleWholeSquare",
        [0xE5F3] = "tripleTongueBelow",
        [0xE0A1] = "noteheadDoubleWholeSquare",
        [0xE229] = "tremoloFingered5",
        [0xE0EA] = "noteheadCircledWholeLarge",
        [0xE727] = "pictFingerCymbals",
        [0xE225] = "tremoloFingered1",
        [0xE3E1] = "accSagittalDoubleFlat23SUp",
        [0xE4AB] = "articStaccatissimoStrokeBelow",
        [0xE675] = "keyboardPedalToeToHeel",
        [0xE0C9] = "noteheadTriangleUpRightBlack",
        [0xEA66] = "figbassSharp",
        [0xE208] = "textHeadlessBlackNoteFrac16thShortStem",
        [0xE93D] = "mensuralNoteheadSemiminimaWhite",
        [0xE086] = "timeSig6",
        [0xE10A] = "noteheadSlashWhiteDoubleWhole",
        [0xE8CF] = "accdnRicochet4",
        [0xE116] = "noteheadRoundBlackSlashedLarge",
        [0xE396] = "accSagittal11v49CommaUp",
        [0xE22F] = "tremoloDivisiDots3",
        [0xE224] = "tremolo5",
        [0xE223] = "tremolo4",
        [0xE1F1] = "textBlackNoteLongStem",
        [0xEC50] = "smnSharp",
        [0xE247] = "flag64thDown",
        [0xE221] = "tremolo2",
        [0xEE05] = "organGermanFUpper",
        [0xEB74] = "arrowOpenDown",
        [0xEB13] = "elecDisc",
        [0xE6A5] = "pictXylTenorTrough",
        [0xEC84] = "timeSigSlash",
        [0xE08C] = "timeSigPlus",
        [0xE095] = "timeSigParensRight",
        [0xE094] = "timeSigParensLeft",
        [0xEA10] = "mensuralAlterationSign",
        [0xE5E2] = "brassSmear",
        [0xEA30] = "daseianGraves1",
        [0xE091] = "timeSigMultiply",
        [0xEE93] = "mensuralProportion8",
        [0xE090] = "timeSigMinus",
        [0xE099] = "timeSigFractionThreeQuarters",
        [0xE3DD] = "accSagittalFlat5v13LDown",
        [0xE9F0] = "mensuralRestMaxima",
        [0xE6DC] = "pictTimbales",
        [0xE08F] = "timeSigEquals",
        [0xE6F4] = "pictRatchet",
        [0xE9B2] = "chantDeminutumUpper",
        [0xECFB] = "timeSigCutCommonReversed",
        [0xE08B] = "timeSigCutCommon",
        [0xE1C6] = "noteShapeMoonLeftWhite",
        [0xE855] = "fretboard5StringNut",
        [0xE577] = "ornamentUpCurve",
        [0xEA0F] = "mensuralColorationEndRound",
        [0xEB15] = "elecMixingConsole",
        [0xECEA] = "timeSigCommonTurned",
        [0xECFA] = "timeSigCommonReversed",
        [0xEB86] = "arrowheadWhiteLeft",
        [0xE096] = "timeSigComma",
        [0xE09E] = "timeSigCombNumerator",
        [0xE09F] = "timeSigCombDenominator",
        [0xEC83] = "timeSigBracketRightSmall",
        [0xEC81] = "timeSigBracketRight",
        [0xE800] = "pictCenter3",
        [0xEC80] = "timeSigBracketLeft",
        [0xEBF6] = "luteItalianVibrato",
        [0xECF9] = "timeSig9Reversed",
        [0xE795] = "pictBeaterWoodTimpaniDown",
        [0xE451] = "accidental2CommaSharp",
        [0xECE8] = "timeSig8Turned",
        [0xE57E] = "ornamentDoubleObliqueLinesAfterNote",
        [0xECF8] = "timeSig8Reversed",
        [0xEC0F] = "luteGermanQLower",
        [0xEA05] = "chantCustosStemUpPosLow",
        [0xE51B] = "octaveParensRight",
        [0xE916] = "mensuralProlation7",
        [0xEEE9] = "noteDiHalf",
        [0xE669] = "keyboardBebung2DotsBelow",
        [0xE039] = "barlineTick",
        [0xE6AE] = "pictCrotales",
        [0xE8B2] = "accdnRH3RanksDoubleTremoloUpper8ve",
        [0xEC32] = "kievanNoteReciting",
        [0xEE69] = "accidentalHabaFlatThreeQuarterTonesLower",
        [0xEE24] = "organGermanBuxheimerBrevis3",
        [0xEC3B] = "kievanNoteBeam",
        [0xE902] = "chantFclef",
        [0xEDE6] = "kahnScuffle",
        [0xE5C2] = "ornamentPrecompCadenceUpperPrefixTurn",
        [0xE087] = "timeSig7",
        [0xE138] = "noteheadDiamondClusterWhite2nd",
        [0xE1B0] = "noteShapeRoundWhite",
        [0xE943] = "mensuralCombStemUpFlagLeft",
        [0xECE6] = "timeSig6Turned",
        [0xE65E] = "keyboardLeftPedalPictogram",
        [0xEEE6] = "noteLiWhole",
        [0xED56] = "accidentalSharpRaisedStockhausen",
        [0xE7C4] = "pictGumHardDown",
        [0xECF6] = "timeSig6Reversed",
        [0xECE5] = "timeSig5Turned",
        [0xEAEE] = "wiggleVIbratoLargestSlower",
        [0xEB11] = "elecHeadphones",
        [0xE085] = "timeSig5",
        [0xECE4] = "timeSig4Turned",
        [0xEC22] = "luteGermanMUpper",
        [0xE084] = "timeSig4",
        [0xE5D2] = "brassLiftMedium",
        [0xECF3] = "timeSig3Reversed",
        [0xECF2] = "timeSig2Reversed",
        [0xEBAD] = "luteFingeringRHThumb",
        [0xE082] = "timeSig2",
        [0xE4AE] = "articMarcatoStaccatoAbove",
        [0xEDF1] = "kahnRightTurn",
        [0xEDAE] = "kahnScrape",
        [0xE088] = "timeSig8",
        [0xE402] = "accSagittal6TinasUp",
        [0xECF0] = "timeSig0Reversed",
        [0xE058] = "gClefLigatedNumberBelow",
        [0xE697] = "harpSalzedoDampLowStrings",
        [0xE080] = "timeSig0",
        [0xEA6F] = "figbass6Raised2",
        [0xE203] = "textTupletBracketEndLongStem",
        [0xE1FF] = "textTuplet3ShortStem",
        [0xE8F3] = "chantDivisioMinima",
        [0xE1FD] = "textTie",
        [0xE42B] = "accidentalWyschnegradsky1TwelfthsFlat",
        [0xE206] = "textHeadlessBlackNoteFrac8thShortStem",
        [0xE4E3] = "restWhole",
        [0xE8A4] = "accdnRH3RanksBassoon",
        [0xE20A] = "textHeadlessBlackNoteFrac32ndLongStem",
        [0xE231] = "tremoloDivisiDots6",
        [0xE209] = "textHeadlessBlackNoteFrac16thLongStem",
        [0xEE0A] = "organGermanBUpper",
        [0xE1F0] = "textBlackNoteShortStem",
        [0xE1F2] = "textBlackNoteFrac8thShortStem",
        [0xE4E1] = "restLonga",
        [0xE01B] = "staff6LinesWide",
        [0xE531] = "dynamicFFFF",
        [0xE734] = "pictSlideBrushOnGong",
        [0xE4B2] = "articTenutoStaccatoAbove",
        [0xE171] = "noteDFlatWhole",
        [0xE008] = "systemDividerLong",
        [0xE566] = "ornamentTrill",
        [0xE009] = "systemDividerExtraLong",
        [0xE716] = "pictCencerro",
        [0xE867] = "analyticsThemeInversion",
        [0xE629] = "stringsBowBehindBridgeThreeStrings",
        [0xEE72] = "swissRudimentsNoteheadBlackDouble",
        [0xE623] = "stringsVibratoPulse",
        [0xE613] = "stringsUpBowTurned",
        [0xE2EA] = "accidentalCombiningLower23Limit29LimitComma",
        [0xE7D6] = "pictBeaterTriangleDown",
        [0xEE89] = "stringsScrapeCircularCounterclockwise",
        [0xE935] = "mensuralNoteheadLongaVoid",
        [0xE3E5] = "accSagittalDoubleFlat7v19CUp",
        [0xED36] = "accidentalSharpArabic",
        [0xE971] = "mensuralObliqueAsc2ndVoid",
        [0xEA5E] = "figbass7Raised1",
        [0xEE57] = "accidentalCombiningRaise43Comma",
        [0xE4D7] = "caesuraSingleStroke",
        [0xE3D7] = "accSagittalFlat5v49MDown",
        [0xE3D4] = "accSagittalSharp49MUp",
        [0xEE8A] = "stringsTripleChopInward",
        [0xEB1D] = "elecStop",
        [0xE947] = "mensuralCombStemUpFlagExtended",
        [0xE157] = "noteSiWhole",
        [0xE5E4] = "brassJazzTurn",
        [0xEDEA] = "kahnWingChange",
        [0xEE88] = "stringsScrapeCircularClockwise",
        [0xED27] = "fingering9",
        [0xE61C] = "stringsOverpressureUpBow",
        [0xE4D4] = "caesuraCurved",
        [0xE61D] = "stringsOverpressurePossibileDownBow",
        [0xE61F] = "stringsOverpressureNoDirection",
        [0xE797] = "pictBeaterWoodTimpaniLeft",
        [0xE3C3] = "accSagittalFlat17kDown",
        [0xE602] = "windWeakAirPressure",
        [0xEA25] = "medRenPunctumCMN",
        [0xE611] = "stringsDownBowTurned",
        [0xED64] = "csymAccidentalDoubleFlat",
        [0xEE80] = "stringsDownBowTowardsBody",
        [0xE610] = "stringsDownBow",
        [0xE61A] = "stringsBowOnTailpiece",
        [0xE8CD] = "accdnRicochet2",
        [0xE7FE] = "pictCenter1",
        [0xE0C2] = "noteheadTriangleRightBlack",
        [0xE667] = "keyboardPluckInside",
        [0xE628] = "stringsBowBehindBridgeTwoStrings",
        [0xE16F] = "noteCWhole",
        [0xE627] = "stringsBowBehindBridgeOneString",
        [0xE929] = "mensuralProportion4",
        [0xE18B] = "noteEFlatHalf",
        [0xE154] = "noteSoWhole",
        [0xE62A] = "stringsBowBehindBridgeFourStrings",
        [0xEE59] = "accidentalCombiningRaise47Quartertone",
        [0xEE18] = "organGermanOctaveUp",
        [0xE232] = "stockhausenTremolo",
        [0xE21D] = "stemSussurando",
        [0xED8A] = "fingeringLeftParenthesisItalic",
        [0xE214] = "stemSulPonticello",
        [0xE132] = "noteheadClusterHalfTop",
        [0xE330] = "accSagittalDoubleSharp5CDown",
        [0xE21E] = "stemRimShot",
        [0xE21B] = "stemMultiphonicsWhite",
        [0xEEEF] = "noteLiHalf",
        [0xED65] = "csymAccidentalTripleSharp",
        [0xE21C] = "stemMultiphonicsBlackWhite",
        [0xE218] = "stemDamp",
        [0xE217] = "stemBuzzRoll",
        [0xE216] = "stemBowOnTailpiece",
        [0xE215] = "stemBowOnBridge",
        [0xE77A] = "pictBeaterHardXylophoneRight",
        [0xE122] = "noteheadClusterRoundWhite",
        [0xEE12] = "organGermanFisLower",
        [0xE842] = "guitarGolpe",
        [0xEB97] = "staffPosRaise8",
        [0xE479] = "accidentalCommaSlashUp",
        [0xEB96] = "staffPosRaise7",
        [0xE987] = "mensuralObliqueDesc3rdWhite",
        [0xE7DB] = "pictBeaterSoftXylophone",
        [0xEB94] = "staffPosRaise5",
        [0xEB91] = "staffPosRaise2",
        [0xE127] = "noteheadClusterQuarter2nd",
        [0xEB90] = "staffPosRaise1",
        [0xEDA4] = "kahnJumpTogether",
        [0xEB9F] = "staffPosLower8",
        [0xEB9E] = "staffPosLower7",
        [0xEB9D] = "staffPosLower6",
        [0xEB9B] = "staffPosLower4",
        [0xE11B] = "noteheadSquareBlackWhite",
        [0xE5D5] = "brassDoitMedium",
        [0xE7A3] = "pictBeaterSoftYarnDown",
        [0xEB9A] = "staffPosLower3",
        [0xEB99] = "staffPosLower2",
        [0xE9D0] = "chantIctusAbove",
        [0xE00D] = "staffDivideArrowUpDown",
        [0xE248] = "flag128thUp",
        [0xE7F0] = "pictStickShot",
        [0xE00C] = "staffDivideArrowUp",
        [0xE3E2] = "accSagittalDoubleSharp49SDown",
        [0xE134] = "noteheadClusterHalfBottom",
        [0xE631] = "pluckedSnapPizzicatoAbove",
        [0xED30] = "accidentalDoubleFlatArabic",
        [0xE1F5] = "textBlackNoteFrac16thLongStem",
        [0xE01A] = "staff5LinesWide",
        [0xE6D4] = "pictBassDrum",
        [0xE8C3] = "accdnLH3RanksDouble8Square",
        [0xEE0C] = "organGermanCLower",
        [0xE893] = "conductorWeakBeat",
        [0xE013] = "staff4Lines",
        [0xE01E] = "staff3LinesNarrow",
        [0xE383] = "accSagittalDoubleFlat5v23SUp",
        [0xE012] = "staff3Lines",
        [0xEDC2] = "kahnRightToeStrike",
        [0xE48F] = "accidentalOneQuarterToneFlatFerneyhough",
        [0xE017] = "staff2LinesWide",
        [0xE2F7] = "accidentalCombiningLower53LimitComma",
        [0xE01D] = "staff2LinesNarrow",
        [0xE641] = "vocalMouthSlightlyOpen",
        [0xEB8B] = "arrowheadOpenDownRight",
        [0xEADA] = "wiggleVibratoSmallSlowest",
        [0xE47A] = "accidentalCommaSlashDown",
        [0xEC5A] = "smnSharpWhiteDown",
        [0xED22] = "fingeringSubstitutionDash",
        [0xE7F3] = "pictScrapeAroundRim",
        [0xEC00] = "luteGermanALower",
        [0xEB39] = "elecMIDIController60",
        [0xE30C] = "accSagittal11LargeDiesisUp",
        [0xEC57] = "smnHistoryDoubleFlat",
        [0xE409] = "accSagittal9TinasDown",
        [0xEC53] = "smnFlatWhite",
        [0xE9F5] = "mensuralRestMinima",
        [0xEB36] = "elecMIDIController0",
        [0xEA71] = "functionOne",
        [0xE06C] = "semipitchedPercussionClef2",
        [0xE2A2] = "accidentalSims4Down",
        [0xE4BC] = "articMarcatoTenutoAbove",
        [0xE06B] = "semipitchedPercussionClef1",
        [0xEC3C] = "kievanAugmentationDot",
        [0xE047] = "segno",
        [0xE070] = "schaefferPreviousClef",
        [0xE059] = "gClefLigatedNumberAbove",
        [0xE750] = "pictSlideWhistle",
        [0xE071] = "schaefferGClefToFClef",
        [0xE698] = "harpSalzedoDampBothHands",
        [0xECB1] = "metNote256thUp",
        [0xEA5F] = "figbass7Raised2",
        [0xEC17] = "luteGermanAUpper",
        [0xEF03] = "scaleDegree4",
        [0xE038] = "barlineShort",
        [0xEE26] = "organGermanBuxheimerSemibrevis",
        [0xEA67] = "figbassDoubleSharp",
        [0xE4F6] = "restQuarterZ",
        [0xE4E0] = "restMaxima",
        [0xE1F3] = "textBlackNoteFrac8thLongStem",
        [0xE907] = "mensuralCclefPetrucciPosLowest",
        [0xE476] = "accidentalTavenerSharp",
        [0xE8A6] = "accdnRH3RanksViolin",
        [0xE69D] = "harpSalzedoSnareDrum",
        [0xE294] = "accidentalReversedFlatAndFlatArrowUp",
        [0xEE31] = "organGerman3Semiminimae",
        [0xE0DD] = "noteheadDiamondWhite",
        [0xEB6B] = "arrowWhiteDownRight",
        [0xE3F7] = "accSagittal2MinasDown",
        [0xE690] = "harpTuningKey",
        [0xE770] = "pictBeaterSoftXylophoneUp",
        [0xEDCA] = "kahnStomp",
        [0xE657] = "keyboardPedalUpNotch",
        [0xEB7D] = "arrowheadBlackDownLeft",
        [0xE4EE] = "restHBar",
        [0xE4F3] = "restDoubleWholeLegerLine",
        [0xECB3] = "metNote512thUp",
        [0xE918] = "mensuralProlation9",
        [0xEE56] = "accidentalCombiningLower43Comma",
        [0xE4EC] = "rest512th",
        [0xE379] = "accSagittalFlat5v19CUp",
        [0xE598] = "ornamentLowLeftConcaveStroke",
        [0xEA20] = "ornamentQuilisma",
        [0xE13A] = "noteheadDiamondClusterWhite3rd",
        [0xE4E8] = "rest32nd",
        [0xE91D] = "mensuralProportionProportioDupla2",
        [0xE042] = "repeatRightLeft",
        [0xE936] = "mensuralNoteheadLongaBlackVoid",
        [0xEE02] = "organGermanDUpper",
        [0xE0AC] = "noteheadPlusDoubleWhole",
        [0xE2D4] = "accidentalDoubleFlatThreeArrowsDown",
        [0xE043] = "repeatDots",
        [0xE4B7] = "articStressBelow",
        [0xE98F] = "mensuralObliqueDesc5thWhite",
        [0xE502] = "repeat4Bars",
        [0xE501] = "repeat2Bars",
        [0xEA86] = "functionNLower",
        [0xE7FD] = "pictRimShotOnStem",
        [0xE51D] = "quindicesimaBassaMb",
        [0xE9BF] = "chantConnectingLineAsc4th",
        [0xE515] = "quindicesimaAlta",
        [0xE7E7] = "pictCoins",
        [0xE630] = "pluckedSnapPizzicatoBelow",
        [0xE637] = "pluckedFingernailFlick",
        [0xE638] = "pluckedDamp",
        [0xE6A4] = "pictXylTrough",
        [0xEAEB] = "wiggleVibratoLargestFaster",
        [0xE9C2] = "chantStrophicusLiquescens2nd",
        [0xECA8] = "metNote8thDown",
        [0xECDA] = "noteShapeIsoscelesTriangleDoubleWhole",
        [0xE6A1] = "pictXyl",
        [0xE7B7] = "pictWoundSoftUp",
        [0xE7B8] = "pictWoundSoftDown",
        [0xE7B3] = "pictWoundHardUp",
        [0xE7B5] = "pictWoundHardRight",
        [0xE7AF] = "pictBeaterSuperballDown",
        [0xE7B6] = "pictWoundHardLeft",
        [0xE408] = "accSagittal9TinasUp",
        [0xEC01] = "luteGermanBLower",
        [0xE6F0] = "pictWoodBlock",
        [0xE758] = "pictWindWhistle",
        [0xE759] = "pictMegaphone",
        [0xE888] = "tuplet8",
        [0xE9B3] = "chantDeminutumLower",
        [0xEA5A] = "figbass5Raised3",
        [0xE6C1] = "pictWindChimesGlass",
        [0xE95C] = "mensuralWhiteMaxima",
        [0xE031] = "barlineDouble",
        [0xE6F6] = "pictWhip",
        [0xE954] = "mensuralBlackMinima",
        [0xE725] = "pictVietnameseHat",
        [0xECAC] = "metNote32ndDown",
        [0xE745] = "pictVibraslap",
        [0xE32C] = "accSagittalDoubleSharp25SDown",
        [0xE6A8] = "pictVibMotorOff",
        [0xE6A7] = "pictVib",
        [0xE809] = "pictTurnRightStem",
        [0xE6B2] = "pictTubaphone",
        [0xE6D8] = "pictTomTomChinese",
        [0xE8E6] = "controlBeginPhrase",
        [0xE6D7] = "pictTomTom",
        [0xE6D0] = "pictTimpani",
        [0xE09A] = "timeSigFractionOneThird",
        [0xE352] = "accSagittalSharp7v11kDown",
        [0xE744] = "pictThundersheet",
        [0xE7E3] = "pictBeaterHand",
        [0xE6F1] = "pictTempleBlocks",
        [0xE135] = "noteheadClusterQuarterTop",
        [0xE401] = "accSagittal5TinasDown",
        [0xEB67] = "arrowBlackUpLeft",
        [0xE731] = "pictTamTamWithBeater",
        [0xE6E3] = "pictTabla",
        [0xE806] = "pictRightHandSquare",
        [0xE7B2] = "pictSuperball",
        [0xE3CE] = "accSagittalSharp23SUp",
        [0xE233] = "oneHandedRollStevens",
        [0xE6AF] = "pictSteelDrums",
        [0xE6D2] = "pictSnareDrumSnaresOff",
        [0xEAD4] = "wiggleVibratoSmallFastest",
        [0xE242] = "flag16thUp",
        [0xE6C4] = "pictShellChimes",
        [0xE718] = "pictShellBells",
        [0xE7F2] = "pictScrapeEdgeToCenter",
        [0xE486] = "accidentalThreeQuarterTonesFlatGrisey",
        [0xEC59] = "smnSharpDown",
        [0xE803] = "pictRim3",
        [0xE297] = "accidentalFilledReversedFlatAndFlatArrowUp",
        [0xE7DD] = "pictBeaterGuiroScraper",
        [0xE6FC] = "pictRecoReco",
        [0xECEB] = "timeSigCutCommonTurned",
        [0xE747] = "pictRainstick",
        [0xE541] = "dynamicNienteForHairpin",
        [0xE752] = "pictPoliceWhistle",
        [0xE760] = "pictPistolShot",
        [0xE1E0] = "note128thDown",
        [0xE7F5] = "pictOpenRimShot",
        [0xE804] = "pictNormalPosition",
        [0xE6C7] = "pictMetalTubeChimes",
        [0xE6C8] = "pictMetalPlateChimes",
        [0xEDC6] = "kahnBallChange",
        [0xE742] = "pictMaracas",
        [0xEDA8] = "kahnGraceTap",
        [0xEC61] = "miscDoNotCopy",
        [0xE60B] = "windRimOnly",
        [0xE6B1] = "pictLithophone",
        [0xE24C] = "flag512thUp",
        [0xEC13] = "luteGermanVLower",
        [0xE756] = "pictKlaxonHorn",
        [0xE4C9] = "fermataVeryLongBelow",
        [0xE719] = "pictJingleBells",
        [0xE767] = "pictJawHarp",
        [0xE0D3] = "noteheadSlashedWhole1",
        [0xECA6] = "metNoteQuarterDown",
        [0xEBC2] = "luteFrenchFretC",
        [0xE7F7] = "pictHalfOpen2",
        [0xE7F6] = "pictHalfOpen1",
        [0xE77E] = "pictBeaterWoodXylophoneRight",
        [0xE7BB] = "pictGumSoftUp",
        [0xE7BD] = "pictGumSoftRight",
        [0xE585] = "glissandoUp",
        [0xE108] = "noteheadSlashHorizontalEndsMuted",
        [0xE0DC] = "noteheadDiamondBlackWide",
        [0xE0EE] = "noteheadLargeArrowUpWhole",
        [0xEB7E] = "arrowheadBlackLeft",
        [0xE17A] = "noteGFlatWhole",
        [0xEA76] = "functionSix",
        [0xE7AE] = "pictBeaterSuperballUp",
        [0xEA97] = "functionRing",
        [0xE53D] = "dynamicRinforzando2",
        [0xE8A8] = "accdnRH3RanksAuthenticMusette",
        [0xE7C3] = "pictGumHardUp",
        [0xE7C5] = "pictGumHardRight",
        [0xEB47] = "elecLineIn",
        [0xE7C6] = "pictGumHardLeft",
        [0xE733] = "pictGongWithButton",
        [0xE6AA] = "pictGlspSmithBrindle",
        [0xE6A0] = "pictGlsp",
        [0xE6C6] = "pictGlassPlateChimes",
        [0xED5A] = "accidentalThreeQuarterTonesSharpStockhausen",
        [0xE765] = "pictGlassHarmonica",
        [0xE740] = "pictFlexatone",
        [0xE241] = "flag8thDown",
        [0xE16D] = "noteBSharpWhole",
        [0xE7FC] = "pictDamp4",
        [0xE8C8] = "accdnCombLH2RanksEmpty",
        [0xE7FB] = "pictDamp3",
        [0xE2D0] = "accidentalFlatTwoArrowsUp",
        [0xE2FA] = "accidentalEnharmonicAlmostEqualTo",
        [0xE7F9] = "pictDamp1",
        [0xE9B8] = "chantEntryLineAsc6th",
        [0xE853] = "fretboard4StringNut",
        [0xE1B8] = "noteShapeDiamondWhite",
        [0xE8D5] = "accdnRicochetStem5",
        [0xE6E4] = "pictCuica",
        [0xE329] = "accSagittalFlat11LDown",
        [0xE1A9] = "noteGBlack",
        [0xE720] = "pictCrashCymbals",
        [0xE346] = "accSagittal7v11CommaUp",
        [0xE636] = "pluckedWithFingernails",
        [0xE6F2] = "pictClaves",
        [0xE121] = "noteheadClusterSquareBlack",
        [0xE5D0] = "brassScoop",
        [0xE805] = "pictChokeCymbal",
        [0xEDDC] = "kahnScuff",
        [0xE6C2] = "pictChimes",
        [0xE748] = "pictChainRattle",
        [0xEC82] = "timeSigBracketLeftSmall",
        [0xE7FF] = "pictCenter2",
        [0xE619] = "stringsBowOnBridge",
        [0xE007] = "systemDivider",
        [0xE755] = "pictCarHorn",
        [0xE761] = "pictCannon",
        [0xE776] = "pictBeaterMediumXylophoneRight",
        [0xE597] = "ornamentLeftPlus",
        [0xEC09] = "luteGermanKLower",
        [0xEACA] = "wiggleCircularSmall",
        [0xE9BA] = "chantLigaturaDesc3rd",
        [0xE751] = "pictBirdWhistle",
        [0xE377] = "accSagittalFlat5v23SUp",
        [0xEAC8] = "wiggleCircularLarge",
        [0xECE0] = "timeSig0Turned",
        [0xE4AF] = "articMarcatoStaccatoBelow",
        [0xE9C1] = "chantConnectingLineAsc6th",
        [0xEB60] = "arrowBlackUp",
        [0xE72A] = "pictBellOfCymbal",
        [0xE523] = "dynamicRinforzando",
        [0xE714] = "pictBell",
        [0xE77D] = "pictBeaterWoodXylophoneDown",
        [0xEB85] = "arrowheadWhiteDownLeft",
        [0xE80D] = "pictDeadNoteStem",
        [0xE621] = "stringsJeteBelow",
        [0xE7D7] = "pictBeaterWireBrushesUp",
        [0xE7D5] = "pictBeaterTriangleUp",
        [0xE7EF] = "pictBeaterTrianglePlain",
        [0xEE19] = "organGerman2OctaveUp",
        [0xE7B0] = "pictBeaterSuperballRight",
        [0xE7B1] = "pictBeaterSuperballLeft",
        [0xE5C4] = "ornamentPrecompDoubleCadenceUpperPrefixTurn",
        [0xED2A] = "fingeringLeftBracket",
        [0xE7A2] = "pictBeaterSoftYarnUp",
        [0xE3C9] = "accSagittalFlat19CDown",
        [0xE1B1] = "noteShapeRoundBlack",
        [0xE79C] = "pictBeaterHardBassDrumUp",
        [0xE2D6] = "accidentalNaturalThreeArrowsDown",
        [0xE5BD] = "ornamentPrecompTrillWithMordent",
        [0xE957] = "mensuralBlackSemibrevisVoid",
        [0xE0D8] = "noteheadDiamondWhole",
        [0xEB95] = "staffPosRaise6",
        [0xE788] = "pictBeaterSoftTimpaniUp",
        [0xE2C2] = "accidentalNaturalOneArrowDown",
        [0xE789] = "pictBeaterSoftTimpaniDown",
        [0xE2A4] = "accidentalSims6Up",
        [0xE782] = "pictBeaterSoftGlockenspielRight",
        [0xED2B] = "fingeringRightBracket",
        [0xE692] = "harpTuningKeyShank",
        [0xE9D3] = "chantCirculusBelow",
        [0xE783] = "pictBeaterSoftGlockenspielLeft",
        [0xEB61] = "arrowBlackUpRight",
        [0xE798] = "pictBeaterSoftBassDrumUp",
        [0xE548] = "dynamicCombinedSeparatorSpace",
        [0xE799] = "pictBeaterSoftBassDrumDown",
        [0xE7C7] = "pictBeaterMetalUp",
        [0xE39D] = "accSagittal49SmallDiesisDown",
        [0xE7CA] = "pictBeaterMetalLeft",
        [0xE7C8] = "pictBeaterMetalDown",
        [0xE79E] = "pictBeaterMetalBassDrumUp",
        [0xE3F6] = "accSagittal2MinasUp",
        [0xEDB5] = "kahnSlideTap",
        [0xE774] = "pictBeaterMediumXylophoneUp",
        [0xE777] = "pictBeaterMediumXylophoneLeft",
        [0xEEAA] = "noteheadCowellNinthNoteSeriesWhole",
        [0xE775] = "pictBeaterMediumXylophoneDown",
        [0xEA24] = "medRenGClefCMN",
        [0xE850] = "fretboard3String",
        [0xE78C] = "pictBeaterMediumTimpaniUp",
        [0xE78D] = "pictBeaterMediumTimpaniDown",
        [0xE453] = "accidental5CommaSharp",
        [0xEEF0] = "noteLeHalf",
        [0xE79A] = "pictBeaterMediumBassDrumUp",
        [0xE7EC] = "pictBeaterMalletDown",
        [0xE7E2] = "pictBeaterKnittingNeedle",
        [0xE15D] = "noteLaHalf",
        [0xEEAE] = "noteheadCowellEleventhNoteSeriesHalf",
        [0xE7D3] = "pictBeaterJazzSticksUp",
        [0xE7D4] = "pictBeaterJazzSticksDown",
        [0xE535] = "dynamicForzando",
        [0xE192] = "noteGHalf",
        [0xE398] = "accSagittal19CommaUp",
        [0xEE06] = "organGermanFisUpper",
        [0xE7AB] = "pictBeaterHardYarnDown",
        [0xE778] = "pictBeaterHardXylophoneUp",
        [0xE31D] = "accSagittalFlat5v7kDown",
        [0xE210] = "stem",
        [0xEEE4] = "noteFiWhole",
        [0xE93F] = "mensuralCombStemDown",
        [0xE77B] = "pictBeaterHardXylophoneLeft",
        [0xE779] = "pictBeaterHardXylophoneDown",
        [0xE347] = "accSagittal7v11CommaDown",
        [0xE0BA] = "noteheadTriangleUpDoubleWhole",
        [0xE188] = "noteDFlatHalf",
        [0xE0D9] = "noteheadDiamondHalf",
        [0xE0EF] = "noteheadLargeArrowUpHalf",
        [0xE790] = "pictBeaterHardTimpaniUp",
        [0xE793] = "pictBeaterHardTimpaniLeft",
        [0xE791] = "pictBeaterHardTimpaniDown",
        [0xE109] = "noteheadSlashWhiteMuted",
        [0xE784] = "pictBeaterHardGlockenspielUp",
        [0xE786] = "pictBeaterHardGlockenspielRight",
        [0xE787] = "pictBeaterHardGlockenspielLeft",
        [0xEA26] = "medRenLiquescentAscCMN",
        [0xE1A5] = "noteFFlatBlack",
        [0xE3B6] = "accSagittalSharp19CDown",
        [0xE0A0] = "noteheadDoubleWhole",
        [0xE117] = "noteheadRoundWhiteSlashedLarge",
        [0xEDA0] = "kahnStep",
        [0xE7A4] = "pictBeaterSoftYarnRight",
        [0xE3CF] = "accSagittalFlat23SDown",
        [0xE39A] = "accSagittal7v19CommaUp",
        [0xECD1] = "noteShapeSquareDoubleWhole",
        [0xE524] = "dynamicSforzando",
        [0xE79D] = "pictBeaterHardBassDrumDown",
        [0xE6D6] = "pictTenorDrum",
        [0xE7CB] = "pictBeaterHammerWoodUp",
        [0xEB2A] = "elecPowerOnOff",
        [0xE696] = "harpSalzedoAeolianDescending",
        [0xE7CF] = "pictBeaterHammerMetalUp",
        [0xE97A] = "mensuralObliqueAsc4thBlackVoid",
        [0xE0E0] = "noteheadDiamondWholeOld",
        [0xE97C] = "mensuralObliqueAsc5thBlack",
        [0xE7E1] = "pictBeaterHammer",
        [0xE801] = "pictRim1",
        [0xE7E5] = "pictBeaterFist",
        [0xE7E4] = "pictBeaterFinger",
        [0xE8E3] = "controlEndTie",
        [0xE130] = "noteheadClusterWholeMiddle",
        [0xE7AA] = "pictBeaterHardYarnUp",
        [0xE6D5] = "pictBassDrumOnSide",
        [0xE6C3] = "pictBambooChimes",
        [0xE701] = "pictAnvil",
        [0xE5BB] = "ornamentPrecompTrillSuffixDandrieu",
        [0xE3EA] = "accSagittalDoubleSharp143CDown",
        [0xE717] = "pictAgogo",
        [0xE0E9] = "noteheadCircledHalfLarge",
        [0xE22B] = "pendereckiTremolo",
        [0xE51C] = "ottavaBassaVb",
        [0xE512] = "ottavaBassa",
        [0xEAFF] = "beamAccelRit12",
        [0xE510] = "ottava",
        [0xE17C] = "noteGSharpWhole",
        [0xE59E] = "ornamentZigZagLineWithRightEnd",
        [0xE59D] = "ornamentZigZagLineNoRightEnd",
        [0xE99A] = "chantPunctumLineaCavum",
        [0xEC85] = "timeSigCut2",
        [0xE90B] = "mensuralCclefPetrucciPosHighest",
        [0xE5B9] = "ornamentPrecompSlideTrillMuffat",
        [0xE05B] = "gClefArrowDown",
        [0xE567] = "ornamentTurn",
        [0xE601] = "windVeryTightEmbouchure",
        [0xE56E] = "ornamentTremblement",
        [0xEDB3] = "kahnDrawTap",
        [0xEB2E] = "elecVolumeLevel0",
        [0xE3FB] = "accSagittal2TinasDown",
        [0xEB40] = "elecAudioChannelsThreeFrontal",
        [0xE5A0] = "ornamentTopRightConcaveStroke",
        [0xE443] = "accidentalKomaFlat",
        [0xEB34] = "elecMIDIIn",
        [0xE591] = "ornamentTopLeftConvexStroke",
        [0xE56C] = "ornamentShortTrill",
        [0xE57A] = "ornamentShortObliqueLineAfterNote",
        [0xE584] = "ornamentShakeMuffat1",
        [0xE582] = "ornamentShake3",
        [0xE1DE] = "note64thDown",
        [0xE3B7] = "accSagittalFlat19CUp",
        [0xE587] = "ornamentSchleifer",
        [0xE3F5] = "accSagittal1MinaDown",
        [0xE996] = "chantPunctumVirga",
        [0xE540] = "dynamicMessaDiVoce",
        [0xEC19] = "luteGermanCUpper",
        [0xE5B4] = "ornamentPrecompTurnTrillDAnglebert",
        [0xEBE6] = "luteItalianFret6",
        [0xE712] = "pictAlmglocken",
        [0xE56B] = "ornamentTurnUpS",
        [0xE5B6] = "ornamentPrecompSlideTrillMarpurg",
        [0xE840] = "guitarLeftHandTapping",
        [0xE5B5] = "ornamentPrecompSlideTrillDAnglebert",
        [0xE5B8] = "ornamentPrecompSlideTrillBach",
        [0xE5BC] = "ornamentPrecompPortDeVoixMordent",
        [0xE7DC] = "pictBeaterSpoonWoodenMallet",
        [0xE5C3] = "ornamentPrecompDoubleCadenceUpperPrefix",
        [0xEC40] = "kodalyHandDo",
        [0xE31F] = "accSagittalFlat5CDown",
        [0xE5EA] = "brassHarmonMuteStemHalfRight",
        [0xE5BE] = "ornamentPrecompCadence",
        [0xEB6F] = "arrowWhiteUpLeft",
        [0xE5B2] = "ornamentPrecompAppoggTrill",
        [0xE688] = "harpSalzedoMetallicSounds",
        [0xEA6A] = "figbassParensLeft",
        [0xE570] = "ornamentPortDeVoixV",
        [0xE580] = "ornamentObliqueLineHorizAfterNote",
        [0xE441] = "accidentalKucukMucennebFlat",
        [0xE56D] = "ornamentMordent",
        [0xEA79] = "functionNine",
        [0xE2CB] = "accidentalFlatTwoArrowsDown",
        [0xECA9] = "metNote16thUp",
        [0xE5A6] = "ornamentLowRightConvexStroke",
        [0xE27B] = "accidentalArrowDown",
        [0xEEFA] = "noteTeBlack",
        [0xE599] = "ornamentLowLeftConvexStroke",
        [0xE595] = "ornamentLeftVerticalStrokeWithCross",
        [0xE594] = "ornamentLeftVerticalStroke",
        [0xE574] = "ornamentLeftFacingHook",
        [0xE572] = "ornamentLeftFacingHalfCircle",
        [0xE575] = "ornamentHookBeforeNote",
        [0xE1CB] = "noteShapeTriangleRoundLeftBlack",
        [0xE143] = "noteheadRectangularClusterBlackMiddle",
        [0xE576] = "ornamentHookAfterNote",
        [0xE9D9] = "chantAugmentum",
        [0xEA27] = "medRenLiquescentDescCMN",
        [0xE97F] = "mensuralObliqueAsc5thWhite",
        [0xE593] = "ornamentHighLeftConvexStroke",
        [0xE11A] = "noteheadSquareBlackLarge",
        [0xEE16] = "organGermanBLower",
        [0xEC0B] = "luteGermanMLower",
        [0xE592] = "ornamentHighLeftConcaveStroke",
        [0xE392] = "accSagittal17KleismaUp",
        [0xE56F] = "ornamentHaydn",
        [0xE0DE] = "noteheadDiamondWhiteWide",
        [0xE578] = "ornamentDownCurve",
        [0xE581] = "ornamentComma",
        [0xECAE] = "metNote64thDown",
        [0xE186] = "noteCHalf",
        [0xE9B7] = "chantEntryLineAsc5th",
        [0xE16C] = "noteBWhole",
        [0xE8BF] = "accdnLH2RanksMasterPlus16Round",
        [0xE940] = "mensuralCombStemDiagonal",
        [0xE2E6] = "accidentalCombiningLower17Schisma",
        [0xE29B] = "accidentalOneAndAHalfSharpsArrowUp",
        [0xE9B9] = "chantLigaturaDesc2nd",
        [0xE543] = "dynamicHairpinParenthesisRight",
        [0xE962] = "mensuralWhiteSemibrevis",
        [0xE5A7] = "ornamentBottomRightConcaveStroke",
        [0xE59C] = "ornamentBottomLeftConvexStroke",
        [0xE59B] = "ornamentBottomLeftConcaveStrokeLarge",
        [0xEE52] = "accidentalCombiningLower37Quartertone",
        [0xE8A3] = "accdnRH3RanksLowerTremolo8",
        [0xEE21] = "organGermanSemiminimaRest",
        [0xEE37] = "organGerman4Semifusae",
        [0xE83B] = "guitarString8",
        [0xEE29] = "organGermanSemiminima",
        [0xE618] = "stringsBowBehindBridge",
        [0xEE20] = "organGermanMinimaRest",
        [0xE4F0] = "restHBarMiddle",
        [0xE956] = "mensuralBlackBrevisVoid",
        [0xE484] = "accidentalFlatTurned",
        [0xECF7] = "timeSig7Reversed",
        [0xEB48] = "elecLineOut",
        [0xE318] = "accSagittalSharp",
        [0xEE14] = "organGermanGisLower",
        [0xEE13] = "organGermanGLower",
        [0xE363] = "accSagittalDoubleFlat55CUp",
        [0xEC42] = "kodalyHandMi",
        [0xEABD] = "wiggleGlissandoGroup1",
        [0xE7AD] = "pictBeaterHardYarnLeft",
        [0xE045] = "dalSegno",
        [0xEE11] = "organGermanFLower",
        [0xEE04] = "organGermanEUpper",
        [0xE1C0] = "noteShapeKeystoneWhite",
        [0xEA34] = "daseianFinales1",
        [0xE430] = "accidentalWyschnegradsky6TwelfthsFlat",
        [0xE8BD] = "accdnLH2Ranks8Plus16Round",
        [0xEE03] = "organGermanDisUpper",
        [0xE06E] = "4stringTabClef",
        [0xE3F2] = "accSagittalAcute",
        [0xE1A4] = "noteESharpBlack",
        [0xED1D] = "fingeringXLower",
        [0xE550] = "lyricsElisionNarrow",
        [0xEC51] = "smnSharpWhite",
        [0xECA3] = "metNoteHalfUp",
        [0xE014] = "staff5Lines",
        [0xEE1D] = "organGermanBuxheimerSemibrevisRest",
        [0xEF01] = "scaleDegree2",
        [0xEE1E] = "organGermanBuxheimerMinimaRest",
        [0xED58] = "accidentalOneQuarterToneSharpStockhausen",
        [0xE554] = "lyricsHyphenBaselineNonBreaking",
        [0xEE68] = "accidentalHabaSharpQuarterToneLower",
        [0xEE17] = "organGermanHLower",
        [0xED1F] = "fingeringOLower",
        [0xE1F7] = "textCont8thBeamShortStem",
        [0xEB77] = "arrowOpenUpLeft",
        [0xEE09] = "organGermanAUpper",
        [0xE326] = "accSagittalSharp11MUp",
        [0xEE3F] = "organGerman6Semifusae",
        [0xE282] = "accidentalQuarterToneSharpStein",
        [0xEE3E] = "organGerman6Fusae",
        [0xE8A2] = "accdnRH3RanksUpperTremolo8",
        [0xEEE5] = "noteSeWhole",
        [0xEE3A] = "organGerman5Fusae",
        [0xEE35] = "organGerman4Semiminimae",
        [0xEE2F] = "organGerman2Semifusae",
        [0xEE32] = "organGerman3Fusae",
        [0xEE30] = "organGerman3Minimae",
        [0xE063] = "fClef15mb",
        [0xE051] = "gClef15mb",
        [0xEE2E] = "organGerman2Fusae",
        [0xEC96] = "octaveSuperscriptM",
        [0xEB4E] = "elecDataOut",
        [0xEC92] = "octaveSuperscriptA",
        [0xEC90] = "octaveLoco",
        [0xEDBF] = "kahnLeftCatch",
        [0xEC97] = "octaveBaselineV",
        [0xE906] = "chantCclef",
        [0xEC91] = "octaveBaselineA",
        [0xE0AB] = "noteheadXOrnateEllipse",
        [0xE0A8] = "noteheadXHalf",
        [0xE5F5] = "windThreeQuartersClosedHole",
        [0xE0B5] = "noteheadWholeWithX",
        [0xE0B7] = "noteheadVoidWithX",
        [0xE0BD] = "noteheadTriangleUpWhite",
        [0xE0CD] = "noteheadTriangleRoundDownBlack",
        [0xE4D0] = "breathMarkUpbow",
        [0xEA92] = "functionParensRight",
        [0xE921] = "mensuralProlationCombiningTwoDots",
        [0xE360] = "accSagittalDoubleSharp7v11CDown",
        [0xEACC] = "wiggleVibratoStart",
        [0xE625] = "stringsThumbPositionTurned",
        [0xE904] = "mensuralFclefPetrucci",
        [0xEB41] = "elecAudioChannelsThreeSurround",
        [0xEB22] = "elecSkipBackwards",
        [0xEB8D] = "arrowheadOpenDownLeft",
        [0xE8F5] = "chantDivisioMaxima",
        [0xEEA1] = "noteheadCowellThirdNoteSeriesWhole",
        [0xEB7C] = "arrowheadBlackDown",
        [0xEB4A] = "elecAudioOut",
        [0xE8C0] = "accdnLH2RanksFullMasterRound",
        [0xE263] = "accidentalDoubleSharp",
        [0xE549] = "dynamicCombinedSeparatorSlash",
        [0xE175] = "noteEWhole",
        [0xEB42] = "elecAudioChannelsFour",
        [0xE137] = "noteheadClusterQuarterBottom",
        [0xE898] = "conductorBeat3Compound",
        [0xE228] = "tremoloFingered4",
        [0xE0BF] = "noteheadTriangleLeftWhite",
        [0xE399] = "accSagittal19CommaDown",
        [0xE52C] = "dynamicMP",
        [0xE1D2] = "noteWhole",
        [0xE04D] = "rightRepeatSmall",
        [0xE036] = "barlineDashed",
        [0xECD6] = "noteShapeMoonDoubleWhole",
        [0xE728] = "pictCymbalTongs",
        [0xEE81] = "stringsUpBowTowardsBody",
        [0xE0B4] = "noteheadDoubleWholeWithX",
        [0xEBAA] = "luteDuration8th",
        [0xE8F6] = "chantDivisioFinalis",
        [0xE95F] = "mensuralWhiteMinima",
        [0xEA33] = "daseianGraves4",
        [0xEAF7] = "beamAccelRit4",
        [0xE1D6] = "noteQuarterDown",
        [0xE991] = "chantPunctumInclinatum",
        [0xE4D6] = "curlewSign",
        [0xE250] = "flagInternalUp",
        [0xEDD5] = "kahnFlap",
        [0xE874] = "csymMinor",
        [0xE428] = "accidentalWyschnegradsky9TwelfthsSharp",
        [0xEA8D] = "functionVUpper",
        [0xEDA1] = "kahnTap",
        [0xEE64] = "accidentalHabaQuarterToneHigher",
        [0xE1E4] = "note512thDown",
        [0xE17D] = "noteHWhole",
        [0xE958] = "mensuralBlackMinimaVoid",
        [0xE040] = "repeatLeft",
        [0xEA84] = "functionGLower",
        [0xE194] = "noteHHalf",
        [0xE8E4] = "controlBeginSlur",
        [0xE01F] = "staff4LinesNarrow",
        [0xE366] = "accSagittalDoubleSharp7v11kDown",
        [0xE8BB] = "accdnLH2Ranks8Round",
        [0xE179] = "noteFSharpWhole",
        [0xE0F0] = "noteheadLargeArrowUpBlack",
        [0xE4F5] = "restHalfLegerLine",
        [0xEEF2] = "noteDiBlack",
        [0xE922] = "mensuralProlationCombiningThreeDots",
        [0xE1A8] = "noteGFlatBlack",
        [0xE900] = "mensuralGclef",
        [0xE986] = "mensuralObliqueDesc3rdBlackVoid",
        [0xE6AB] = "pictXylSmithBrindle",
        [0xEA64] = "figbassFlat",
        [0xEDE0] = "kahnRiff",
        [0xE3D3] = "accSagittalFlat11v19MDown",
        [0xEC0E] = "luteGermanPLower",
        [0xE997] = "chantPunctumVirgaReversed",
        [0xE5E8] = "brassHarmonMuteClosed",
        [0xE2F0] = "accidentalDoubleFlatEqualTempered",
        [0xE1A3] = "noteEBlack",
        [0xED62] = "csymAccidentalSharp",
        [0xE990] = "chantPunctum",
        [0xE7A9] = "pictBeaterMediumYarnLeft",
        [0xE1E6] = "note1024thDown",
        [0xE86A] = "analyticsChoralmelodie",
        [0xE472] = "accidentalQuarterToneSharpBusotti",
        [0xE2EB] = "accidentalCombiningRaise23Limit29LimitComma",
        [0xE19C] = "noteCFlatBlack",
        [0xE4B5] = "articTenutoAccentBelow",
        [0xEBC3] = "luteFrenchFretD",
        [0xE390] = "accSagittal19SchismaUp",
        [0xE802] = "pictRim2",
        [0xE182] = "noteBFlatHalf",
        [0xE060] = "cClefSquare",
        [0xEE0E] = "organGermanDLower",
        [0xED10] = "fingering0",
        [0xEEE1] = "noteRiWhole",
        [0xEB6D] = "arrowWhiteDownLeft",
        [0xEDB2] = "kahnDrawStep",
        [0xE381] = "accSagittalFlat5v23SDown",
        [0xEB3C] = "elecAudioMono",
        [0xE196] = "noteAFlatBlack",
        [0xE078] = "bridgeClef",
        [0xEC60] = "miscDoNotPhotocopy",
        [0xE292] = "accidentalFilledReversedFlatArrowUp",
        [0xEA50] = "figbass0",
        [0xEB73] = "arrowOpenDownRight",
        [0xE103] = "noteheadSlashWhiteHalf",
        [0xEDAC] = "kahnKneeOutward",
        [0xE2ED] = "accidentalCombiningRaise31Schisma",
        [0xEBAC] = "luteDuration32nd",
        [0xE387] = "accSagittalDoubleFlat23CUp",
        [0xE4D5] = "breathMarkSalzedo",
        [0xE3AC] = "accSagittal5v13LargeDiesisUp",
        [0xE4CE] = "breathMarkComma",
        [0xE32B] = "accSagittalFlat35LDown",
        [0xED19] = "fingeringILower",
        [0xE5E6] = "brassMuteHalfClosed",
        [0xEE1B] = "organGermanTie",
        [0xEB31] = "elecVolumeLevel60",
        [0xE835] = "guitarString2",
        [0xE3AB] = "accSagittal11v19LargeDiesisDown",
        [0xE5DE] = "brassFallRoughMedium",
        [0xE57C] = "ornamentObliqueLineAfterNote",
        [0xE37A] = "accSagittalSharp23CDown",
        [0xED31] = "accidentalThreeQuarterTonesFlatArabic",
        [0xE7BF] = "pictGumMediumUp",
        [0xE344] = "accSagittal55CommaUp",
        [0xE2D5] = "accidentalFlatThreeArrowsDown",
        [0xE4AA] = "articStaccatissimoStrokeAbove",
        [0xE488] = "accidentalQuarterToneFlatVanBlankenburg",
        [0xEAF9] = "beamAccelRit6",
        [0xE998] = "chantPunctumCavum",
        [0xE1D8] = "note8thDown",
        [0xE3BE] = "accSagittalSharp19sDown",
        [0xE813] = "handbellsMutedMartellato",
        [0xECE7] = "timeSig7Turned",
        [0xE4C3] = "fermataVeryShortBelow",
        [0xE912] = "mensuralProlation3",
        [0xE93C] = "mensuralNoteheadMinimaWhite",
        [0xE859] = "fretboardX",
        [0xEA09] = "chantCustosStemDownPosHighest",
        [0xE98A] = "mensuralObliqueDesc4thBlackVoid",
        [0xE983] = "mensuralObliqueDesc2ndWhite",
        [0xEB3F] = "elecAudioChannelsTwo",
        [0xE034] = "barlineHeavy",
        [0xE4D2] = "caesuraThick",
        [0xE4A2] = "articStaccatoAbove",
        [0xE868] = "analyticsTheme1",
        [0xE133] = "noteheadClusterHalfMiddle",
        [0xE7D0] = "pictBeaterHammerMetalDown",
        [0xED47] = "articSoftAccentTenutoStaccatoBelow",
        [0xE431] = "accidentalWyschnegradsky7TwelfthsFlat",
        [0xE0D4] = "noteheadSlashedWhole2",
        [0xEDBC] = "kahnToeClick",
        [0xE4A1] = "articAccentBelow",
        [0xE354] = "accSagittalSharp7v11kUp",
        [0xEB49] = "elecAudioIn",
        [0xE0D2] = "noteheadSlashedHalf2",
        [0xE810] = "handbellsMartellato",
        [0xE81F] = "handbellsBelltree",
        [0xE00B] = "staffDivideArrowDown",
        [0xE421] = "accidentalWyschnegradsky2TwelfthsSharp",
        [0xEA8E] = "functionVLower",
        [0xEA56] = "figbass4Raised",
        [0xE8B9] = "accdnRH4RanksSoftTenor",
        [0xEDE9] = "kahnWing",
        [0xEE8B] = "stringsTripleChopOutward",
        [0xE879] = "csymParensLeftVeryTall",
        [0xE278] = "accidentalThreeQuarterTonesFlatArrowUp",
        [0xE3C0] = "accSagittalSharp19sUp",
        [0xEC37] = "kievanNoteQuarterStemUp",
        [0xE860] = "analyticsHauptstimme",
        [0xEDD3] = "kahnGraceTapStamp",
        [0xE530] = "dynamicFFF",
        [0xE166] = "noteTiBlack",
        [0xE985] = "mensuralObliqueDesc3rdVoid",
        [0xE432] = "accidentalWyschnegradsky8TwelfthsFlat",
        [0xEC07] = "luteGermanHLower",
        [0xE2A3] = "accidentalSims12Up",
        [0xEC55] = "smnHistoryDoubleSharp",
        [0xE316] = "accSagittalSharp5v7kDown",
        [0xED34] = "accidentalNaturalArabic",
        [0xEDA9] = "kahnFlat",
        [0xE24E] = "flag1024thUp",
        [0xEBA2] = "luteStaff6LinesNarrow",
        [0xE222] = "tremolo3",
        [0xE68E] = "harpSalzedoFluidicSoundsRight",
        [0xE3FC] = "accSagittal3TinasUp",
        [0xEA58] = "figbass5Raised1",
        [0xE8B1] = "accdnRH3RanksDoubleTremoloLower8ve",
        [0xE422] = "accidentalWyschnegradsky3TwelfthsSharp",
        [0xE817] = "handbellsPluckLift",
        [0xE78A] = "pictBeaterSoftTimpaniRight",
        [0xEBCB] = "luteFrenchFretM",
        [0xE890] = "conductorStrongBeat",
        [0xED83] = "fingering3Italic",
        [0xE308] = "accSagittal35MediumDiesisUp",
        [0xE80C] = "pictCrushStem",
        [0xE32A] = "accSagittalSharp35LUp",
        [0xE2D3] = "accidentalDoubleSharpTwoArrowsUp",
        [0xEA61] = "figbass9",
        [0xEBC5] = "luteFrenchFretF",
        [0xE31C] = "accSagittalSharp5v7kUp",
        [0xED89] = "fingering9Italic",
        [0xEBD4] = "luteFrenchAppoggiaturaBelow",
        [0xE7EA] = "pictBeaterCombiningDashedCircle",
        [0xE1B4] = "noteShapeTriangleRightWhite",
        [0xE48C] = "accidentalTwoThirdTonesSharpFerneyhough",
        [0xE0C6] = "noteheadTriangleDownWhite",
        [0xE204] = "textHeadlessBlackNoteShortStem",
        [0xEB63] = "arrowBlackDownRight",
        [0xE2F4] = "accidentalDoubleSharpEqualTempered",
        [0xEB83] = "arrowheadWhiteDownRight",
        [0xE2C3] = "accidentalSharpOneArrowDown",
        [0xEE53] = "accidentalCombiningRaise37Quartertone",
        [0xE3CD] = "accSagittalFlat49SDown",
        [0xE2A0] = "accidentalSims12Down",
        [0xE663] = "keyboardPedalHeel3",
        [0xE2B2] = "accidentalJohnstonEl",
        [0xE503] = "repeatBarUpperDot",
        [0xEA0D] = "mensuralColorationEndSquare",
        [0xEC3A] = "kievanNote8thStemDown",
        [0xED00] = "functionMUpper",
        [0xEB82] = "arrowheadWhiteRight",
        [0xEA68] = "figbassBracketLeft",
        [0xE3B1] = "accSagittalFlat23SUp",
        [0xE961] = "mensuralWhiteFusa",
        [0xEE66] = "accidentalHabaSharpThreeQuarterTonesHigher",
        [0xE4CB] = "fermataLongHenzeBelow",
        [0xED24] = "fingering6",
        [0xE0C1] = "noteheadTriangleRightWhite",
        [0xEC18] = "luteGermanBUpper",
        [0xE871] = "csymHalfDiminished",
        [0xE328] = "accSagittalSharp11LUp",
        [0xE142] = "noteheadRectangularClusterBlackTop",
        [0xE65B] = "keyboardPedalHalf2",
        [0xEA6C] = "figbassPlus",
        [0xE926] = "mensuralProportion1",
        [0xE8CE] = "accdnRicochet3",
        [0xE547] = "dynamicCombinedSeparatorHyphen",
        [0xE5EB] = "brassHarmonMuteStemOpen",
        [0xEB87] = "arrowheadWhiteUpLeft",
        [0xEB24] = "elecReplay",
        [0xEA5B] = "figbass6",
        [0xE6DB] = "pictTambourine",
        [0xE3B0] = "accSagittalSharp23SDown",
        [0xECF1] = "timeSig1Reversed",
        [0xE47F] = "accidentalQuarterToneFlat4",
        [0xEAFB] = "beamAccelRit8",
        [0xEDDE] = "kahnPush",
        [0xE5E0] = "brassPlop",
        [0xE3F0] = "accSagittalShaftUp",
        [0xE992] = "chantPunctumInclinatumAuctum",
        [0xED23] = "fingeringMultipleNotes",
        [0xE5A2] = "ornamentHighRightConcaveStroke",
        [0xE42F] = "accidentalWyschnegradsky5TwelfthsFlat",
        [0xE304] = "accSagittal7CommaUp",
        [0xE2DE] = "accidentalLowerOneSeptimalComma",
        [0xE864] = "analyticsTheme",
        [0xE40A] = "accSagittalFractionalTinaUp",
        [0xE348] = "accSagittal5v11SmallDiesisUp",
        [0xE952] = "mensuralBlackBrevis",
        [0xEEE3] = "noteMeWhole",
        [0xEDA3] = "kahnLeap",
        [0xE69A] = "harpSalzedoDampAbove",
        [0xE2A1] = "accidentalSims6Down",
        [0xED2C] = "fingeringSeparatorMiddleDot",
        [0xE8C1] = "accdnLH3Ranks8Square",
        [0xEDD0] = "kahnGraceTapHop",
        [0xEB35] = "elecMIDIOut",
        [0xEB46] = "elecAudioChannelsEight",
        [0xE057] = "gClef8vbParens",
        [0xE59F] = "ornamentMiddleVerticalStroke",
        [0xE4B9] = "articUnstressBelow",
        [0xEAF2] = "wiggleRandom3",
        [0xEB72] = "arrowOpenRight",
        [0xE95E] = "mensuralWhiteBrevis",
        [0xEDA6] = "kahnBrushForward",
        [0xE3E4] = "accSagittalDoubleSharp7v19CDown",
        [0xE83F] = "guitarClosePedal",
        [0xE8D1] = "accdnRicochet6",
        [0xE68A] = "harpSalzedoPlayUpperEnd",
        [0xEDC9] = "kahnHeelChange",
        [0xE3F3] = "accSagittalGrave",
        [0xE520] = "dynamicPiano",
        [0xE873] = "csymMajorSeventh",
        [0xE42A] = "accidentalWyschnegradsky11TwelfthsSharp",
        [0xE391] = "accSagittal19SchismaDown",
        [0xE8A9] = "accdnRH3RanksOrgan",
        [0xE685] = "harpSalzedoOboicFlux",
        [0xE358] = "accSagittalSharp55CUp",
        [0xEEF6] = "noteFiBlack",
        [0xE2EC] = "accidentalCombiningLower31Schisma",
        [0xEA60] = "figbass8",
        [0xE682] = "harpPedalLowered",
        [0xE680] = "harpPedalRaised",
        [0xE333] = "accSagittalDoubleFlat5v7kUp",
        [0xE839] = "guitarString6",
        [0xEE65] = "accidentalHabaFlatQuarterToneHigher",
        [0xE820] = "handbellsTableSingleBell",
        [0xE2DC] = "accidentalSharpThreeArrowsUp",
        [0xE815] = "handbellsMalletBellOnTable",
        [0xE050] = "gClef",
        [0xE3D9] = "accSagittalFlat49LDown",
        [0xE35C] = "accSagittalSharp5v11SUp",
        [0xE31B] = "accSagittalUnused2",
        [0xEEA5] = "noteheadCowellFifthNoteSeriesHalf",
        [0xE3C7] = "accSagittalFlat11v49CDown",
        [0xE9D5] = "chantSemicirculusBelow",
        [0xEE15] = "organGermanALower",
        [0xE07A] = "gClefChange",
        [0xE067] = "fClefArrowUp",
        [0xEA5D] = "figbass7",
        [0xEDE3] = "kahnPull",
        [0xE562] = "graceNoteAppoggiaturaStemUp",
        [0xE713] = "pictBellPlate",
        [0xE279] = "accidentalFiveQuarterTonesFlatArrowDown",
        [0xE1D5] = "noteQuarterUp",
        [0xE053] = "gClef8va",
        [0xE3A6] = "accSagittal5v49MediumDiesisUp",
        [0xE8C7] = "accdnCombRH4RanksEmpty",
        [0xE858] = "fretboardFilledCircle",
        [0xEA73] = "functionThree",
        [0xE9F4] = "mensuralRestSemibrevis",
        [0xEC43] = "kodalyHandFa",
        [0xE1D1] = "noteDoubleWholeSquare",
        [0xEA52] = "figbass2",
        [0xEB00] = "beamAccelRit13",
        [0xE004] = "bracketBottom",
        [0xE3EC] = "accSagittalDoubleSharp17kDown",
        [0xE089] = "timeSig9",
        [0xEAE6] = "wiggleVibratoLargeSlow",
        [0xE26B] = "accidentalParensRight",
        [0xE05C] = "cClef",
        [0xE062] = "fClef",
        [0xEC3D] = "kievanAccidentalSharp",
        [0xEEEC] = "noteMeHalf",
        [0xE851] = "fretboard3StringNut",
        [0xE3E6] = "accSagittalDoubleSharp19CDown",
        [0xE064] = "fClef8vb",
        [0xE48D] = "accidentalTwoThirdTonesFlatFerneyhough",
        [0xEC34] = "kievanNoteWholeFinal",
        [0xEE51] = "accidentalCombiningRaise29LimitComma",
        [0xEDB8] = "kahnClap",
        [0xEDBA] = "kahnDoubleSnap",
        [0xE24A] = "flag256thUp",
        [0xE280] = "accidentalQuarterToneFlatStein",
        [0xE7A1] = "pictBeaterDoubleBassDrumDown",
        [0xE243] = "flag16thDown",
        [0xE4CD] = "fermataShortHenzeBelow",
        [0xE3E0] = "accSagittalDoubleSharp23SDown",
        [0xEF02] = "scaleDegree3",
        [0xED21] = "fingeringSubstitutionBelow",
        [0xE353] = "accSagittalFlat7v11kUp",
        [0xE99C] = "chantOriscusAscending",
        [0xE364] = "accSagittalDoubleSharp17CDown",
        [0xE86B] = "analyticsHauptrhythmus",
        [0xED12] = "fingering2",
        [0xE772] = "pictBeaterSoftXylophoneRight",
        [0xEBE5] = "luteItalianFret5",
        [0xEAFE] = "beamAccelRit11",
        [0xE896] = "conductorBeat4Simple",
        [0xED26] = "fingering8",
        [0xEDA5] = "kahnJumpApart",
        [0xE1C7] = "noteShapeMoonLeftBlack",
        [0xEDCD] = "kahnBallDig",
        [0xED2D] = "fingeringSeparatorMiddleDotWhite",
        [0xE298] = "accidentalFilledReversedFlatAndFlatArrowDown",
        [0xE048] = "coda",
        [0xE24F] = "flag1024thDown",
        [0xE671] = "keyboardPlayWithLHEnd",
        [0xE0B6] = "noteheadHalfWithX",
        [0xE312] = "accSagittalSharp7CDown",
        [0xE24B] = "flag256thDown",
        [0xED1C] = "fingeringCLower",
        [0xE334] = "accSagittalDoubleSharp",
        [0xE3FA] = "accSagittal2TinasUp",
        [0xED38] = "accidentalDoubleSharpArabic",
        [0xEBA1] = "luteStaff6LinesWide",
        [0xE1B7] = "noteShapeTriangleLeftBlack",
        [0xE856] = "fretboard6String",
        [0xE34B] = "accSagittalFlat5v11SUp",
        [0xE66C] = "keyboardBebung4DotsAbove",
        [0xE4B0] = "articAccentStaccatoAbove",
        [0xEA94] = "functionAngleRight",
        [0xEE10] = "organGermanELower",
        [0xEA7F] = "functionDUpper",
        [0xE2E7] = "accidentalCombiningRaise17Schisma",
        [0xEA9F] = "functionLLower",
        [0xEA9E] = "functionLUpper",
        [0xED01] = "functionMLower",
        [0xE3C5] = "accSagittalFlat143CDown",
        [0xEA98] = "functionPlus",
        [0xE689] = "harpSalzedoTamTamSounds",
        [0xE420] = "accidentalWyschnegradsky1TwelfthsSharp",
        [0xE18F] = "noteFHalf",
        [0xED1E] = "fingeringELower",
        [0xE3C1] = "accSagittalFlat19sDown",
        [0xEBD2] = "luteFrenchMordentLower",
        [0xEE01] = "organGermanCisUpper",
        [0xE7BC] = "pictGumSoftDown",
        [0xE875] = "csymParensLeftTall",
        [0xE93B] = "mensuralNoteheadSemibrevisBlackVoidTurned",
        [0xE054] = "gClef15ma",
        [0xE2D7] = "accidentalSharpThreeArrowsDown",
        [0xE056] = "gClef8vbCClef",
        [0xE055] = "gClef8vbOld",
        [0xE568] = "ornamentTurnInverted",
        [0xE841] = "guitarRightHandTapping",
        [0xE341] = "accSagittal7v11KleismaDown",
        [0xE66F] = "keyboardPlayWithRHEnd",
        [0xE560] = "graceNoteAcciaccaturaStemUp",
        [0xE99E] = "chantOriscusLiquescens",
        [0xE565] = "graceNoteSlashStemDown",
        [0xE529] = "dynamicPPPP",
        [0xE655] = "keyboardPedalUp",
        [0xE05A] = "gClefArrowUp",
        [0xEEF3] = "noteRiBlack",
        [0xE832] = "guitarShake",
        [0xE180] = "noteAHalf",
        [0xE05E] = "cClefArrowUp",
        [0xE84C] = "guitarString12",
        [0xEC06] = "luteGermanGLower",
        [0xE903] = "mensuralFclef",
        [0xE838] = "guitarString5",
        [0xED33] = "accidentalQuarterToneFlatArabic",
        [0xEAB3] = "guitarWideVibratoStroke",
        [0xE3A4] = "accSagittal49MediumDiesisUp",
        [0xE2DF] = "accidentalRaiseOneSeptimalComma",
        [0xEBC0] = "luteFrenchFretA",
        [0xEDC0] = "kahnRightCatch",
        [0xE527] = "dynamicPPPPPP",
        [0xE68F] = "harpMetalRod",
        [0xE681] = "harpPedalCentered",
        [0xEC36] = "kievanNoteHalfStaffSpace",
        [0xE0D5] = "noteheadSlashedDoubleWhole1",
        [0xE5A4] = "ornamentRightVerticalStroke",
        [0xE072] = "schaefferFClefToGClef",
        [0xEA95] = "functionRepetition1",
        [0xEEB4] = "noteheadCowellFifteenthNoteSeriesHalf",
        [0xEE60] = "accidentalUpsAndDownsUp",
        [0xE0AE] = "noteheadPlusHalf",
        [0xE3DA] = "accSagittalSharp11v19LUp",
        [0xEE0B] = "organGermanHUpper",
        [0xE694] = "harpStringNoiseStem",
        [0xEB71] = "arrowOpenUpRight",
        [0xEB84] = "arrowheadWhiteDown",
        [0xED70] = "indianDrumClef",
        [0xE475] = "accidentalQuarterToneSharpWiggle",
        [0xE4D1] = "caesura",
        [0xEE25] = "organGermanBuxheimerBrevis2",
        [0xEC1F] = "luteGermanIUpper",
        [0xEDEB] = "kahnDoubleWing",
        [0xED8D] = "fingeringRightBracketItalic",
        [0xEC39] = "kievanNote8thStemUp",
        [0xE989] = "mensuralObliqueDesc4thVoid",
        [0xE525] = "dynamicZ",
        [0xEDB6] = "kahnHeelDrop",
        [0xE13C] = "noteheadDiamondClusterWhiteTop",
        [0xEDA2] = "kahnHop",
        [0xE7BE] = "pictGumSoftLeft",
        [0xEDD2] = "kahnLeapFlatFoot",
        [0xE163] = "noteFaBlack",
        [0xEDD4] = "kahnLeapHeelClick",
        [0xE51F] = "octaveBassa",
        [0xE5F6] = "windHalfClosedHole1",
        [0xEB44] = "elecAudioChannelsSix",
        [0xEDEC] = "kahnOverTheTop",
        [0xE53E] = "dynamicCrescendoHairpin",
        [0xE1B2] = "noteShapeSquareWhite",
        [0xE457] = "accidental4CommaFlat",
        [0xE878] = "csymBracketRightTall",
        [0xEDD9] = "kahnSlap",
        [0xEDB4] = "kahnSlideStep",
        [0xE673] = "keyboardPedalHookEnd",
        [0xEBF2] = "luteItalianTremolo",
        [0xEDC7] = "kahnStepStamp",
        [0xE47E] = "accidentalQuarterToneSharp4",
        [0xE831] = "guitarVibratoBarDip",
        [0xEDDB] = "kahnStompBrush",
        [0xEDCC] = "kahnToeTap",
        [0xE3A9] = "accSagittal49LargeDiesisDown",
        [0xE653] = "keyboardPedalD",
        [0xE170] = "noteCSharpWhole",
        [0xE2E9] = "accidentalCombiningRaise19Schisma",
        [0xE445] = "accidentalBakiyeSharp",
        [0xE662] = "keyboardPedalHeel2",
        [0xEBA8] = "luteDurationHalf",
        [0xEB1B] = "elecCamera",
        [0xE674] = "keyboardPedalHeelToToe",
        [0xEA51] = "figbass1",
        [0xE349] = "accSagittal5v11SmallDiesisDown",
        [0xEC30] = "kievanCClef",
        [0xEA87] = "functionPUpper",
        [0xE011] = "staff2Lines",
        [0xE34E] = "accSagittalSharp55CDown",
        [0xE5C0] = "ornamentPrecompDoubleCadenceLowerPrefix",
        [0xEC45] = "kodalyHandLa",
        [0xE555] = "lyricsTextRepeat",
        [0xE272] = "accidentalQuarterToneSharpNaturalArrowUp",
        [0xE04C] = "leftRepeatSmall",
        [0xE024] = "legerLineNarrow",
        [0xEBA5] = "luteBarlineFinal",
        [0xEAFD] = "beamAccelRit10",
        [0xE06D] = "6stringTabClef",
        [0xE69B] = "harpSalzedoMetallicSoundsOneString",
        [0xE84D] = "guitarString13",
        [0xEDEF] = "kahnRightFoot",
        [0xE1A2] = "noteEFlatBlack",
        [0xECC1] = "figbassTripleFlat",
        [0xEB25] = "elecShuffle",
        [0xEB01] = "beamAccelRit14",
        [0xEB2D] = "elecVolumeFaderThumb",
        [0xE993] = "chantPunctumInclinatumDeminutum",
        [0xEBC1] = "luteFrenchFretB",
        [0xE2FB] = "accidentalEnharmonicEquals",
        [0xE7E8] = "pictDrumStick",
        [0xE29C] = "accidentalOneAndAHalfSharpsArrowDown",
        [0xEBC9] = "luteFrenchFretK",
        [0xE425] = "accidentalWyschnegradsky6TwelfthsSharp",
        [0xE145] = "noteheadRectangularClusterWhiteTop",
        [0xE534] = "dynamicFortePiano",
        [0xE155] = "noteLaWhole",
        [0xE975] = "mensuralObliqueAsc3rdVoid",
        [0xEDE5] = "kahnShuffle",
        [0xEF06] = "scaleDegree7",
        [0xE895] = "conductorBeat3Simple",
        [0xEC02] = "luteGermanCLower",
        [0xE0BE] = "noteheadTriangleUpBlack",
        [0xECF5] = "timeSig5Reversed",
        [0xEC1A] = "luteGermanDUpper",
        [0xE400] = "accSagittal5TinasUp",
        [0xEC1D] = "luteGermanGUpper",
        [0xE2C5] = "accidentalDoubleFlatOneArrowUp",
        [0xEC0C] = "luteGermanNLower",
        [0xE081] = "timeSig1",
        [0xE521] = "dynamicMezzo",
        [0xEC16] = "luteGermanZLower",
        [0xEBF0] = "luteItalianClefFFaUt",
        [0xE195] = "noteHSharpHalf",
        [0xE11D] = "noteheadRoundWhiteDoubleSlashed",
        [0xED85] = "fingering5Italic",
        [0xE1C1] = "noteShapeKeystoneBlack",
        [0xEBEF] = "luteItalianTimeTriple",
        [0xE31A] = "accSagittalUnused1",
        [0xE5D8] = "brassFallLipMedium",
        [0xEA00] = "mensuralSignumUp",
        [0xE317] = "accSagittalFlat5v7kUp",
        [0xE11C] = "noteheadRoundBlackDoubleSlashed",
        [0xE552] = "lyricsElisionWide",
        [0xEBAB] = "luteDuration16th",
        [0xE542] = "dynamicHairpinParenthesisLeft",
        [0xE230] = "tremoloDivisiDots4",
        [0xE2F3] = "accidentalSharpEqualTempered",
        [0xEAA0] = "wiggleTrillFastest",
        [0xEBE4] = "luteItalianFret4",
        [0xE94C] = "mensuralCombStemDownFlagFusa",
        [0xEA6E] = "figbassCombiningLowering",
        [0xE94A] = "mensuralCombStemDownFlagSemiminima",
        [0xE945] = "mensuralCombStemUpFlagFlared",
        [0xE901] = "mensuralGclefPetrucci",
        [0xE92C] = "mensuralModusPerfectumVert",
        [0xEE83] = "stringsUpBowAwayFromBody",
        [0xEE91] = "mensuralProportion6",
        [0xE933] = "mensuralNoteheadMaximaWhite",
        [0xEDE2] = "kahnBackChug",
        [0xE8D3] = "accdnRicochetStem3",
        [0xE1AF] = "noteEmptyBlack",
        [0xE977] = "mensuralObliqueAsc3rdWhite",
        [0xEC46] = "kodalyHandTi",
        [0xE564] = "graceNoteSlashStemUp",
        [0xEDBD] = "kahnLeftCross",
        [0xEB6C] = "arrowWhiteDown",
        [0xE4A0] = "articAccentAbove",
        [0xE905] = "mensuralCclef",
        [0xE891] = "conductorLeftBeat",
        [0xE39C] = "accSagittal49SmallDiesisUp",
        [0xEB02] = "beamAccelRit15",
        [0xEDB1] = "kahnFleaTap",
        [0xE670] = "keyboardPlayWithLH",
        [0xE917] = "mensuralProlation8",
        [0xED1B] = "fingeringALower",
        [0xE836] = "guitarString3",
        [0xE395] = "accSagittal143CommaDown",
        [0xE3CC] = "accSagittalSharp49SUp",
        [0xE505] = "repeatBarLowerDot",
        [0xE920] = "mensuralProlationCombiningDot",
        [0xE924] = "mensuralProlationCombiningDotVoid",
        [0xE53B] = "dynamicSforzatoFF",
        [0xE5BF] = "ornamentPrecompCadenceWithTurn",
        [0xEE92] = "mensuralProportion7",
        [0xE91F] = "mensuralProportionProportioQuadrupla",
        [0xE91E] = "mensuralProportionProportioTripla",
        [0xE178] = "noteFWhole",
        [0xE650] = "keyboardPedalPed",
        [0xED5B] = "accidentalFlatRepeatedSpaceStockhausen",
        [0xE9F6] = "mensuralRestSemiminima",
        [0xE245] = "flag32ndDown",
        [0xE92F] = "mensuralTempusImperfectumHoriz",
        [0xEB7F] = "arrowheadBlackUpLeft",
        [0xECB7] = "metAugmentationDot",
        [0xEDCB] = "kahnHeelTap",
        [0xE0AF] = "noteheadPlusBlack",
        [0xEBED] = "luteItalianTempoSlow",
        [0xE8B7] = "accdnRH4RanksMaster",
        [0xE5DA] = "brassFallSmoothShort",
        [0xEA38] = "daseianSuperiores1",
        [0xE4E6] = "rest8th",
        [0xEB20] = "elecRewind",
        [0xECAD] = "metNote64thUp",
        [0xEB38] = "elecMIDIController40",
        [0xE92A] = "mensuralProportionMinor",
        [0xE42C] = "accidentalWyschnegradsky2TwelfthsFlat",
        [0xECD4] = "noteShapeDiamondDoubleWhole",
        [0xE9E2] = "medRenNatural",
        [0xE89A] = "conductorUnconducted",
        [0xE05F] = "cClefArrowDown",
        [0xE1D9] = "note16thUp",
        [0xE1D7] = "note8thUp",
        [0xE455] = "accidental2CommaFlat",
        [0xE811] = "handbellsMartellatoLift",
        [0xE249] = "flag128thDown",
        [0xE16A] = "noteASharpWhole",
        [0xE169] = "noteAWhole",
        [0xED45] = "articSoftAccentTenutoBelow",
        [0xE184] = "noteBSharpHalf",
        [0xEE0D] = "organGermanCisLower",
        [0xE796] = "pictBeaterWoodTimpaniRight",
        [0xE0C3] = "noteheadTriangleDownDoubleWhole",
        [0xE033] = "barlineReverseFinal",
        [0xE1FC] = "textAugmentationDot",
        [0xE35D] = "accSagittalFlat5v11SDown",
        [0xE3C8] = "accSagittalSharp19CUp",
        [0xE185] = "noteCFlatHalf",
        [0xEB80] = "arrowheadWhiteUp",
        [0xE0E7] = "noteheadCircledDoubleWhole",
        [0xE189] = "noteDHalf",
        [0xE158] = "noteDoHalf",
        [0xE3F1] = "accSagittalShaftDown",
        [0xEB6E] = "arrowWhiteLeft",
        [0xE174] = "noteEFlatWhole",
        [0xE18C] = "noteEHalf",
        [0xEB16] = "elecUSB",
        [0xE938] = "mensuralNoteheadSemibrevisBlack",
        [0xE4ED] = "rest1024th",
        [0xE128] = "noteheadClusterDoubleWhole3rd",
        [0xE18E] = "noteFFlatHalf",
        [0xEC03] = "luteGermanDLower",
        [0xEB3D] = "elecAudioStereo",
        [0xEB98] = "staffPosLower1",
        [0xE30E] = "accSagittal35LargeDiesisUp",
        [0xEAEF] = "wiggleVibratoLargestSlowest",
        [0xE191] = "noteGFlatHalf",
        [0xE91C] = "mensuralProportionProportioDupla1",
        [0xE6F7] = "pictBoardClapper",
        [0xEBE1] = "luteItalianFret1",
        [0xE8AB] = "accdnRH3RanksBandoneon",
        [0xE2F1] = "accidentalFlatEqualTempered",
        [0xE9F3] = "mensuralRestBrevis",
        [0xE5F1] = "doubleTongueBelow",
        [0xEF07] = "scaleDegree8",
        [0xEEF5] = "noteMeBlack",
        [0xE15A] = "noteMiHalf",
        [0xE677] = "keyboardPedalParensRight",
        [0xE3B2] = "accSagittalSharp49SDown",
        [0xE741] = "pictMaraca",
        [0xE268] = "accidentalNaturalSharp",
        [0xE81D] = "handbellsGyro",
        [0xEEF7] = "noteSeBlack",
        [0xED8B] = "fingeringRightParenthesisItalic",
        [0xE635] = "arpeggiatoDown",
        [0xED17] = "fingeringPLower",
        [0xE290] = "accidentalReversedFlatArrowUp",
        [0xE1BD] = "noteShapeMoonBlack",
        [0xEA65] = "figbassNatural",
        [0xEC86] = "timeSigCut3",
        [0xEDEE] = "kahnLeftFoot",
        [0xED42] = "articSoftAccentStaccatoAbove",
        [0xEE61] = "accidentalUpsAndDownsDown",
        [0xE84A] = "guitarString10",
        [0xE1BF] = "noteShapeTriangleRoundBlack",
        [0xEB7A] = "arrowheadBlackRight",
        [0xE4A3] = "articStaccatoBelow",
        [0xE0B1] = "noteheadCircleXWhole",
        [0xE0E8] = "noteheadCircledBlackLarge",
        [0xE69C] = "harpSalzedoIsolatedSounds",
        [0xE9B1] = "chantPodatusUpper",
        [0xE4B6] = "articStressAbove",
        [0xEA07] = "chantCustosStemDownPosMiddle",
        [0xE0D7] = "noteheadDiamondDoubleWhole",
        [0xEEAF] = "noteheadCowellEleventhSeriesBlack",
        [0xEEB3] = "noteheadCowellFifteenthNoteSeriesWhole",
        [0xE283] = "accidentalThreeQuarterTonesSharpStein",
        [0xEEA9] = "noteheadCowellSeventhNoteSeriesBlack",
        [0xE2CD] = "accidentalSharpTwoArrowsDown",
        [0xE30A] = "accSagittal11MediumDiesisUp",
        [0xE939] = "mensuralNoteheadSemibrevisVoid",
        [0xEC0A] = "luteGermanLLower",
        [0xECD9] = "noteShapeQuarterMoonDoubleWhole",
        [0xECA7] = "metNote8thUp",
        [0xE125] = "noteheadClusterWhole2nd",
        [0xE0DA] = "noteheadDiamondHalfWide",
        [0xE385] = "accSagittalDoubleFlat5v19CUp",
        [0xE119] = "noteheadRoundWhiteSlashed",
        [0xE107] = "noteheadSlashVerticalEndsMuted",
        [0xE0FC] = "noteheadDiamondOpen",
        [0xEA23] = "medRenPlicaCMN",
        [0xE2E3] = "accidentalRaiseOneUndecimalQuartertone",
        [0xEAF5] = "beamAccelRit2",

        [0xF4AD] = "pictTomTomChinesePeinkofer",
        [0xF891] = "chordOmit5",
        [0xF750] = "dynamicCrescendoHairpinLong",
        [0xF894] = "chordm7alt",
        [0xF633] = "stringsUpBowLegacy",
        [0xF5DF] = "accidentalFlatJohnstonDown",
        [0xF7A6] = "noteheadVoidWithXLV5",
        [0xF5E7] = "accidentalSharpJohnstonDownEl",
        [0xF878] = "chord13#9",
        [0xF406] = "fClefFrench",
        [0xF60C] = "note16thDownWide",
        [0xF600] = "noteheadDoubleWholeWide",
        [0xF8ED] = "noteheadPlusBlackLVLegacy",
        [0xF88B] = "chordDM7",
        [0xF8B0] = "chordMin",
        [0xF81D] = "textEnclosureSegmentArrowJogDown",
        [0xF55C] = "gClefFlat7Below",
        [0xF5DE] = "accidentalFlatJohnstonUp",
        [0xF889] = "chordD7#9",
        [0xF89C] = "chord#9b13",
        [0xF7C2] = "miscCodaMonk",
        [0xF871] = "chord7#11b9",
        [0xF43C] = "pictMaracaSmithBrindle",
        [0xF79E] = "noteheadCircledXLargeLV1",
        [0xF888] = "chordD7b9",
        [0xF7BB] = "conductorBeat2SimpleLegacy1",
        [0xF704] = "flag8thDownAlt",
        [0xF439] = "pictCastanetsSmithBrindle",
        [0xF77A] = "arrowDownMedium",
        [0xF819] = "textEnclosureSegmentCUrvedArrowShort",
        [0xF611] = "noteheadXBlackLegacy",
        [0xF4B0] = "pictBongosPeinkofer",
        [0xF8BB] = "chordMi13#11",
        [0xF8AA] = "chordMa13#11",
        [0xF774] = "arpeggioArrowDownMedium",
        [0xF8F5] = "noteheadTriangleLeftWhiteLVLegacy",
        [0xF547] = "gClef7Below",
        [0xF72F] = "enclosureParenUnderlineLeft",
        [0xF55D] = "gClefFlat8Above",
        [0xF53F] = "gClef3Below",
        [0xF8CA] = "chordMa69",
        [0xF715] = "accidentalDoubleSharpParenthesesSmall",
        [0xF842] = "chordM9#11",
        [0xF536] = "gClef12Below",
        [0xF862] = "chord-11M7",
        [0xF781] = "noteheadHalfDouble",
        [0xF43B] = "pictCowBellBerio",
        [0xF835] = "enclosureRehersalU",
        [0xF887] = "chordD7",
        [0xF683] = "tremolo4Legacy",
        [0xF8D8] = "noteheadHalfLVLegacy",
        [0xF8B3] = "chordMi69",
        [0xF843] = "chordM69#11",
        [0xF5B2] = "ornamentTrillFlatAbove",
        [0xF78F] = "noteheadHalfLV4",
        [0xF8D6] = "chord13",
        [0xF5E6] = "accidentalSharpJohnstonUpEl",
        [0xF8D4] = "chord9",
        [0xF7A7] = "noteheadVoidWithXLV6",
        [0xF62D] = "articMarcatoStaccatoAboveLegacy",
        [0xF82E] = "enclosureRehersalN",
        [0xF55A] = "gClefFlat6Below",
        [0xF689] = "noteheadDoubleWholeLongWings",
        [0xF424] = "flag1024thUpStraight",
        [0xF87E] = "chord+9",
        [0xF78D] = "noteheadHalfLV2",
        [0xF778] = "arrowUpLong",
        [0xF78E] = "noteheadHalfLV3",
        [0xF83F] = "chordM13",
        [0xF8C4] = "chordAdd2",
        [0xF872] = "chord7#11#9",
        [0xF83A] = "enclosureRehersalZ",
        [0xF8E0] = "noteheadSquareBlackLVLegacy",
        [0xF831] = "enclosureRehersalQ",
        [0xF780] = "noteheadwholeDouble",
        [0xF765] = "laissezVibrer",
        [0xF636] = "articTenutoStaccatoBelowLegacy",
        [0xF41B] = "flag128thUpStraight",
        [0xF686] = "miscEyeglassesAlt2",
        [0xF740] = "enclosureBracketWavyRightLong",
        [0xF714] = "accidentalDoubleFlatSmall",
        [0xF822] = "enclosureRehersalB",
        [0xF88D] = "chordH-d7",
        [0xF87C] = "chord+7#9",
        [0xF7E5] = "analyticsModulationCombiningBracketRight",
        [0xF7ED] = "analyticsArrowSegmentRight",
        [0xF89A] = "chord#9b5",
        [0xF85F] = "chord-11b9b5",
        [0xF79C] = "noteheadBlackLV8",
        [0xF615] = "noteheadSquareBlackLegacy",
        [0xF4A6] = "pictVibMotorOffPeinkofer",
        [0xF812] = "textEnclosureSegmentExtension",
        [0xF84D] = "chord7Sus",
        [0xF826] = "enclosureRehersalF",
        [0xF841] = "chordM7#11",
        [0xF569] = "gClefNatural7Above",
        [0xF869] = "chord7b9b13",
        [0xF628] = "noteheadSlashVerticalEndsLegacy",
        [0xF8EB] = "noteheadCircledBlackLargeLVLegacy",
        [0xF53D] = "gClef2Below",
        [0xF788] = "noteheadWholeLV6",
        [0xF8B5] = "chordMi9",
        [0xF4AF] = "pictBassDrumPeinkofer",
        [0xF87A] = "chord13#11",
        [0xF845] = "chordM13#11",
        [0xF859] = "chord-13",
        [0xF8F8] = "noteheadDiamondWholeOldLVLegacy",
        [0xF8CD] = "chord2",
        [0xF5DB] = "accidentalSharpJohnstonUp",
        [0xF674] = "repeat1BarLegacy",
        [0xF86F] = "chord7#9b5",
        [0xF7AA] = "noteheadSlashWhiteWholeLegacy",
        [0xF60B] = "note16thUpWide",
        [0xF5E2] = "accidentalJohnstonSevenUp",
        [0xF766] = "restHBarAngled",
        [0xF7B7] = "tremolo3Alt2",
        [0xF744] = "enclosureParenOverLeft2Long",
        [0xF84B] = "chordSus4",
        [0xF797] = "noteheadBlackLV3",
        [0xF5D6] = "accidentalNaturalParens",
        [0xF53E] = "gClef3Above",
        [0xF762] = "brassFallRoughShortSlightDecline",
        [0xF814] = "textEnclosureCurvedArrow",
        [0xF7E3] = "analyticsLongExtension",
        [0xF892] = "chordOmit3",
        [0xF710] = "accidentalDoubleSharpSmall",
        [0xF7E9] = "analyticsArrowRightSegment",
        [0xF8C8] = "chordNo3rd",
        [0xF618] = "noteheadTriangleLeftWhiteLegacy",
        [0xF739] = "enclosureParenUnderlineExtensionLong",
        [0xF707] = "noteQuarterDownSmall",
        [0xF880] = "chord+M9",
        [0xF863] = "chord-9M7#11",
        [0xF607] = "noteQuarterUpWide",
        [0xF56F] = "gClefSharp5Below",
        [0xF8DC] = "noteheadCircleX3LVLegacy",
        [0xF7AD] = "noteheadXLV2",
        [0xF7A1] = "noteheadCircledXLargeLV4",
        [0xF561] = "gClefNatural10Below",
        [0xF4AB] = "pictMarPeinkofer",
        [0xF718] = "accidentalFlatParenthesesSmall",
        [0xF8CC] = "chord1",
        [0xF548] = "gClef8Above",
        [0xF4A2] = "accidentalTripleFlatJoinedStems",
        [0xF84F] = "chord7Sus4",
        [0xF604] = "noteheadBlackWide",
        [0xF821] = "enclosureRehersalA",
        [0xF5B4] = "ornamentTrillSharpAbove",
        [0xF792] = "noteheadHalfLV7",
        [0xF5DC] = "accidentalSharpJohnstonDown",
        [0xF43F] = "noteheadDoubleWholeAlt2",
        [0xF4A3] = "pictXylBassPeinkofer",
        [0xF41E] = "flag256thUpStraight",
        [0xF608] = "noteQuarterDownWide",
        [0xF538] = "gClef14Below",
        [0xF40F] = "flag8thUpStraight",
        [0xF776] = "arrowUpShort",
        [0xF8A4] = "chordMa7",
        [0xF827] = "enclosureRehersalG",
        [0xF8E3] = "noteheadDiamondBlackLVLegacy",
        [0xF8B2] = "chordMi6",
        [0xF834] = "enclosureRehersalT",
        [0xF850] = "chord7Sus4b9",
        [0xF688] = "handbellsGyroAlt",
        [0xF565] = "gClefNatural3Above",
        [0xF88A] = "chordDimM7",
        [0xF568] = "gClefNatural6Below",
        [0xF751] = "dynamicDiminuendoHairpinLong",
        [0xF811] = "textEnclosureSegmentJogUp",
        [0xF4A1] = "accidentalDoubleFlatJoinedStems",
        [0xF40B] = "6stringTabClefSerif",
        [0xF417] = "flag32ndDownStraight",
        [0xF40D] = "4stringTabClefSerif",
        [0xF563] = "gClefNatural17Below",
        [0xF789] = "noteheadWholeLV7",
        [0xF5BB] = "ornamentTurnSharpAboveFlatBelow",
        [0xF738] = "enclosureParenUnderlineLeftLongAlt",
        [0xF8E9] = "noteheadTriangleDownBlackLVLegacy",
        [0xF4B9] = "analyticsHauptrhythmusR",
        [0xF832] = "enclosureRehersalR",
        [0xF7E0] = "analyticsModulationCombiningBracketLeft",
        [0xF630] = "articTenutoAccentAboveLegacy",
        [0xF858] = "chord-11",
        [0xF7B1] = "noteheadXLV6",
        [0xF868] = "chord7#9",
        [0xF706] = "noteQuarterUpSmall",
        [0xF7CB] = "textBlackNoteMiddleTripletNote",
        [0xF445] = "timeSig5Large",
        [0xF820] = "legacyX",
        [0xF619] = "noteheadTriangleRightWhiteLegacy",
        [0xF782] = "noteheadBlackDouble",
        [0xF829] = "enclosureRehersalI",
        [0xF7A0] = "noteheadCircledXLargeLV3",
        [0xF852] = "chordSus2",
        [0xF74C] = "noteheadParenthesisAlt",
        [0xF627] = "noteheadPlusBlackLegacy",
        [0xF41A] = "flag64thDownStraight",
        [0xF716] = "accidentalSharpParenthesesSmall",
        [0xF89E] = "chord#11b9",
        [0xF796] = "noteheadBlackLV2",
        [0xF7AE] = "noteheadXLV3",
        [0xF60A] = "note8thDownWide",
        [0xF537] = "gClef13Below",
        [0xF839] = "enclosureRehersalY",
        [0xF760] = "brassFallRoughVeryShortFastDecline",
        [0xF847] = "chordM7#5",
        [0xF864] = "chord-69#11",
        [0xF632] = "articAccentAboveLegacy",
        [0xF8A8] = "chordMa9#11",
        [0xF87F] = "chord+M7",
        [0xF737] = "enclosureParenUnderlineRightShort",
        [0xF8DA] = "noteheadCircleX1LVLegacy",
        [0xF61A] = "noteheadTriangleUpRightWhiteLegacy",
        [0xF54E] = "gClefFlat13Below",
        [0xF77B] = "arrowDownLong",
        [0xF79B] = "noteheadBlackLV7",
        [0xF53C] = "gClef2Above",
        [0xF5EB] = "accidentalFlatJohnstonElDown",
        [0xF400] = "braceSmall",
        [0xF856] = "chord-7",
        [0xF562] = "gClefNatural13Below",
        [0xF8F7] = "noteheadCircledHalfLargeLVLegacy",
        [0xF432] = "pluckedSnapPizzicatoBelowGerman",
        [0xF702] = "flag8thUpAlt3",
        [0xF84E] = "chord9Sus",
        [0xF423] = "flag512thDownStraight",
        [0xF4B5] = "pictGuiroPeinkofer",
        [0xF446] = "timeSig6Large",
        [0xF8EF] = "noteheadTriangleUpWhiteLVLegacy",
        [0xF866] = "chord+7b9",
        [0xF815] = "textEnclosureCurvedArrowWHook",
        [0xF7E4] = "analyticsModulationCombiningBracketCenter2",
        [0xF675] = "repeat2BarLegacy",
        [0xF544] = "gClef6Above",
        [0xF799] = "noteheadBlackLV5",
        [0xF687] = "handbellsEcho1Alt",
        [0xF55E] = "gClefFlat9Above",
        [0xF85B] = "chord-9b5",
        [0xF550] = "gClefFlat15Below",
        [0xF729] = "enclosureBracketLeftLong",
        [0xF775] = "arpeggioArrowDownLong",
        [0xF721] = "enclosureBracketExtension",
        [0xF8CB] = "chord0",
        [0xF865] = "chord-Add2",
        [0xF7D6] = "textBlackNoteFracSingle16th",
        [0xF767] = "brassLiftSlight",
        [0xF7D8] = "fClefAlt1",
        [0xF87D] = "chord+7",
        [0xF8E8] = "noteheadTriangleRightBlackLVLegacy",
        [0xF82B] = "enclosureRehersalK",
        [0xF7EB] = "analyticsBackwardArrowRightSegmentTall",
        [0xF758] = "brassFallSmoothVeryLong",
        [0xF7A4] = "noteheadVoidWithXLV3",
        [0xF4B2] = "pictTomTomPeinkofer",
        [0xF555] = "gClefFlat3Above",
        [0xF8F6] = "noteheadWhiteParenthesisLVLegacy",
        [0xF8BD] = "chordMi11b9b5",
        [0xF743] = "enclosureParenOverRight2Alt",
        [0xF8EC] = "noteheadDiamondBlackLVLegacyAlt",
        [0xF8B1] = "chordMi",
        [0xF8F0] = "noteheadDiamondHalfWideLVLegacy",
        [0xF8BE] = "chordMiM7",
        [0xF8E7] = "noteheadTriangleLeftBlackLVLegacy",
        [0xF616] = "noteheadTriangleUpWhiteLegacy",
        [0xF418] = "flag64thUpStraight",
        [0xF725] = "enclosureParenOverRight",
        [0xF566] = "gClefNatural3Below",
        [0xF89B] = "chordb9b13",
        [0xF7E1] = "analyticsModulationCombiningBracketRightLong",
        [0xF8CF] = "chord4",
        [0xF54F] = "gClefFlat14Below",
        [0xF757] = "brassLiftSmoothVeryLong",
        [0xF848] = "chordM9b5",
        [0xF8A5] = "chordMa9",
        [0xF882] = "chord7#11#9Alt",
        [0xF401] = "braceLarge",
        [0xF8AD] = "chordMa9b5",
        [0xF784] = "noteheadWholeLV2",
        [0xF885] = "chordDim7",
        [0xF612] = "noteheadCircledXLargeLegacy",
        [0xF67F] = "ventiduesimaBassaMbLegacy",
        [0xF791] = "noteheadHalfLV6",
        [0xF552] = "gClefFlat1Below",
        [0xF8F1] = "noteheadTriangleUpRightWhiteLVLegacy",
        [0xF7EE] = "analyticsArrowShort",
        [0xF4A9] = "pictXylPeinkofer",
        [0xF7DB] = "gClefAlt4",
        [0xF857] = "chord-9",
        [0xF8A1] = "chordMaj",
        [0xF8A0] = "chordM7#11Alt",
        [0xF795] = "noteheadBlackLV1",
        [0xF75A] = "brassFallRoughVeryShortSlightDecilne",
        [0xF74B] = "enclosureClosedLong",
        [0xF867] = "chord7b9",
        [0xF8C3] = "chordMiAdd2",
        [0xF8A3] = "chordMa6",
        [0xF764] = "brassFallRoughShortMedDecline",
        [0xF4B4] = "pictGuiroSevsay",
        [0xF74F] = "metSwing",
        [0xF83D] = "chordM7",
        [0xF876] = "chord13b5",
        [0xF75F] = "brassVeryLiftShort",
        [0xF402] = "braceLarger",
        [0xF7B6] = "tremolo3Alt1",
        [0xF68E] = "ornamentTrillSharpAboveLegacy",
        [0xF55B] = "gClefFlat7Above",
        [0xF818] = "textEnclosureSegmentExtensionLong",
        [0xF722] = "enclosureBracketRight",
        [0xF861] = "chord-9M7",
        [0xF786] = "noteheadWholeLV4",
        [0xF761] = "brassLiftShortSlightIncline",
        [0xF73E] = "enclosureBracketWavyLeftLong",
        [0xF717] = "accidentalNaturalParenthesesSmall",
        [0xF88F] = "chordMajorTriadb5",
        [0xF40A] = "6stringTabClefTall",
        [0xF603] = "noteheadHalfWide",
        [0xF79A] = "noteheadBlackLV6",
        [0xF40C] = "4stringTabClefTall",
        [0xF601] = "noteheadDoubleWholeAltWide",
        [0xF5ED] = "accidentalJohnstonSevenFlatDown",
        [0xF85D] = "chord-13#11",
        [0xF53A] = "gClef16Below",
        [0xF431] = "stringsChangeBowDirectionLiga",
        [0xF84A] = "chordSus",
        [0xF7C1] = "miscLegacy1",
        [0xF7A3] = "noteheadVoidWithXLV2",
        [0xF723] = "enclosureParenOverLeft",
        [0xF7E7] = "analyticsBackwardArrowLeftSegment",
        [0xF67D] = "ventiduesimaLegacy",
        [0xF67E] = "ventiduesimaAltaLegacy",
        [0xF409] = "unpitchedPercussionClef1Alt",
        [0xF787] = "noteheadWholeLV5",
        [0xF567] = "gClefNatural6Above",
        [0xF677] = "ottavaAltaLegacy",
        [0xF86B] = "chord7b5",
        [0xF42F] = "tripleTongueAboveNoSlur",
        [0xF41D] = "flag128thDownStraight",
        [0xF56B] = "gClefNatural9Below",
        [0xF83E] = "chordM9",
        [0xF7B9] = "tremolo3Alt4",
        [0xF403] = "braceFlat",
        [0xF44A] = "timeSigCommonLarge",
        [0xF7B8] = "tremolo3Alt3",
        [0xF629] = "noteheadRoundWhiteLegacy",
        [0xF7AF] = "noteheadXLV4",
        [0xF681] = "tremolo2Alt",
        [0xF680] = "tremolo1Alt",
        [0xF44C] = "timeSigPlusLarge",
        [0xF631] = "articTenutoAccentBelowLegacy",
        [0xF8A2] = "chordMa",
        [0xF449] = "timeSig9Large",
        [0xF448] = "timeSig8Large",
        [0xF447] = "timeSig7Large",
        [0xF444] = "timeSig4Large",
        [0xF895] = "chordb5",
        [0xF442] = "timeSig2Large",
        [0xF441] = "timeSig1Large",
        [0xF78B] = "noteheadWholeLV9",
        [0xF84C] = "chordSus4b9",
        [0xF8E1] = "noteheadTriangleBlackLVLegacy",
        [0xF816] = "textEnclosureSegmentLeftHook",
        [0xF7E8] = "analyticsBackwardArrowRightSegment",
        [0xF810] = "textEnclosureSegmentJogDown",
        [0xF8E2] = "noteheadMoonBlackLVLegacy",
        [0xF81A] = "textEnclosureSegmentCurvedArrowLong",
        [0xF836] = "enclosureRehersalV",
        [0xF72C] = "enclosureParenOverLeft2",
        [0xF8DB] = "noteheadCircleX2LVLegacy",
        [0xF81C] = "textEnclosureSegmentArrowJogOver",
        [0xF81E] = "textEnclosureSegmentArrowDown",
        [0xF813] = "textEnclosureSegmentArrow",
        [0xF898] = "chord#11",
        [0xF435] = "keyboardPedalSostNoDot",
        [0xF61B] = "noteheadMoonWhiteLegacy",
        [0xF42E] = "doubleTongueBelowNoSlur",
        [0xF8BF] = "chordMi9M7",
        [0xF8C0] = "chordMi11M7",
        [0xF5E9] = "accidentalJohnstonSevenSharpDown",
        [0xF88C] = "chordH-d",
        [0xF7D9] = "gClefAlt2",
        [0xF4B1] = "pictCongaPeinkofer",
        [0xF7CA] = "textBlackNoteRightFacing16thBeam",
        [0xF7D3] = "textBlackNoteFrac8thLongBeam",
        [0xF7D5] = "textBlackNoteFrac32ndLongBeam",
        [0xF535] = "gClef11Below",
        [0xF670] = "restWholeLegacy",
        [0xF8BA] = "chordMi11b5",
        [0xF634] = "stringsDownBowLegacy",
        [0xF43E] = "stringsChangeBowDirectionImposed",
        [0xF8D3] = "chord8",
        [0xF7D4] = "textBlackNoteFrac16thLongBeam",
        [0xF7DC] = "restQuarterAlt1",
        [0xF45C] = "repeatRightLeftThick",
        [0xF67B] = "quindicesimaLegacy2",
        [0xF67A] = "quindicesimaLegacy",
        [0xF5D2] = "noteheadHalfParens",
        [0xF747] = "enclosureParenUnderlineLeftAlt2",
        [0xF67C] = "quindicesimaBassaMbLegacy",
        [0xF433] = "pluckedSnapPizzicatoAboveGerman",
        [0xF55F] = "gClefFlat9Below",
        [0xF43D] = "mensuralProportion4Old",
        [0xF4A4] = "pictXylTenorPeinkofer",
        [0xF4A5] = "pictVibPeinkofer",
        [0xF5B8] = "ornamentTurnNaturalAbove",
        [0xF4A8] = "pictTubaphonePeinkofer",
        [0xF4AE] = "pictTimpaniPeinkofer",
        [0xF4B3] = "pictTimbalesPeinkofer",
        [0xF896] = "chord#5",
        [0xF8EA] = "noteheadBlackParenthesisLVLegacy",
        [0xF730] = "enclosureUnderlineExtension",
        [0xF7BC] = "conductorBeat2SimpleLegacy2",
        [0xF7C4] = "chorus1st",
        [0xF823] = "enclosureRehersalC",
        [0xF83B] = "chord69",
        [0xF884] = "chordDim",
        [0xF4B7] = "pictMusicalSawPeinkofer",
        [0xF881] = "chordAug",
        [0xF849] = "chordM9#5",
        [0xF62A] = "pictHalfOpen2Legacy",
        [0xF719] = "accidentalDoubleFlatParenthesesSmall",
        [0xF4AA] = "pictGlspPeinkofer",
        [0xF609] = "note8thUpWide",
        [0xF553] = "gClefFlat2Above",
        [0xF4B6] = "pictFlexatonePeinkofer",
        [0xF68A] = "noteheadDoubleWholeAltLongWings",
        [0xF676] = "ottavaLegacy",
        [0xF5BA] = "ornamentTurnSharpAbove",
        [0xF5E5] = "accidentalJohnstonDownEl",
        [0xF606] = "noteHalfDownWide",
        [0xF625] = "noteheadDiamondWhiteLegacy",
        [0xF678] = "ottavaBassaVbLegacy",
        [0xF679] = "ottavaBassaBaLegacy",
        [0xF614] = "noteheadSquareWhiteLegacy2",
        [0xF732] = "enclosureParenUnderlineLeftLong",
        [0xF5BC] = "ornamentTurnSharpBelow",
        [0xF545] = "gClef6Below",
        [0xF5B7] = "ornamentTurnFlatBelow",
        [0xF5B6] = "ornamentTurnFlatAboveSharpBelow",
        [0xF8C1] = "chordMi9M7#11",
        [0xF5B5] = "ornamentTurnFlatAbove",
        [0xF8D5] = "chord11",
        [0xF5B3] = "ornamentTrillNaturalAbove",
        [0xF8C6] = "chordAdd9",
        [0xF559] = "gClefFlat6Above",
        [0xF68C] = "ornamentTrillFlatAboveLegacy",
        [0xF5EA] = "accidentalFlatJohnstonUpEl",
        [0xF7B3] = "noteheadXLV8",
        [0xF7B2] = "noteheadXLV7",
        [0xF624] = "noteheadSquareWhiteLegacy3",
        [0xF705] = "flag16thDownAlt",
        [0xF7B0] = "noteheadXLV5",
        [0xF7AC] = "noteheadXLV1",
        [0xF7C3] = "miscCodaLogo",
        [0xF720] = "enclosureBracketLeft",
        [0xF8E5] = "noteheadSquareBlackLVLegacyAlt",
        [0xF8DE] = "noteheadXBlack2LVLegacy",
        [0xF8DD] = "noteheadXBlack1LVLegacy",
        [0xF602] = "noteheadWholeWide",
        [0xF5D3] = "noteheadWholeParens",
        [0xF8D7] = "noteheadWholeLVJazz",
        [0xF78A] = "noteheadWholeLV8",
        [0xF617] = "noteheadTriangleDownWhiteLegacy",
        [0xF785] = "noteheadWholeLV3",
        [0xF783] = "noteheadWholeLV1",
        [0xF534] = "gClef10Below",
        [0xF7A9] = "noteheadVoidWithXLV8",
        [0xF635] = "breathMarkCommaLegacy",
        [0xF8FB] = "noteheadRoundWhiteLVLegacy",
        [0xF7A5] = "noteheadVoidWithXLV4",
        [0xF685] = "miscEyeglassesAlt1",
        [0xF86C] = "chord7#11",
        [0xF5E8] = "accidentalJohnstonSevenSharpUp",
        [0xF8E4] = "noteheadTriangleUpRightBlackLVLegacy",
        [0xF78C] = "noteheadHalfLV1",
        [0xF560] = "gClefNat2Below",
        [0xF61C] = "noteheadTriangleRoundDownWhiteLegacy",
        [0xF8F2] = "noteheadTriangleRoundDownWhiteLVLegacy",
        [0xF8E6] = "noteheadTriangleRoundDownBlackLVLegacy",
        [0xF54A] = "gClef9Above",
        [0xF8F3] = "noteheadTriangleRightWhiteLVLegacy",
        [0xF8FA] = "noteheadTriangleDownWhiteLVLegacy",
        [0xF828] = "enclosureRehersalH",
        [0xF700] = "arpeggioVerticalSegment",
        [0xF7D2] = "textTripletBracketFull",
        [0xF610] = "dynamicSforzandoLegacy",
        [0xF53B] = "gClef17Below",
        [0xF899] = "chordb9b5",
        [0xF777] = "arrowUpMedium",
        [0xF5D4] = "noteheadDoubleWholeParens",
        [0xF8FE] = "fretboard6StringLegacy",
        [0xF626] = "noteheadDiamondWhiteWideLegacy",
        [0xF89D] = "chord#9b9",
        [0xF411] = "flag8thDownStraight",
        [0xF770] = "arpeggioArrowUpShort",
        [0xF893] = "chordb9",
        [0xF701] = "flag8thUpAlt2",
        [0xF875] = "chord9#5",
        [0xF5DA] = "accidentalSharpJohnstonEl",
        [0xF40E] = "noteheadDoubleWholeAlt",
        [0xF682] = "tremolo3Alt",
        [0xF769] = "flag8thDownAlt2",
        [0xF7CE] = "miscLegacy3",
        [0xF7A8] = "noteheadVoidWithXLV7",
        [0xF45B] = "accdnPushAlt",
        [0xF8EE] = "noteheadMoonWhiteLVLegacy",
        [0xF54B] = "gClef9Below",
        [0xF794] = "noteheadHalfLV9",
        [0xF62C] = "articAccentStaccatoBelowLegacy",
        [0xF855] = "chord-69",
        [0xF79F] = "noteheadCircledXLargeLV2",
        [0xF5E4] = "accidentalJohnstonUpEl",
        [0xF793] = "noteheadHalfLV8",
        [0xF82A] = "enclosureRehersalJ",
        [0xF5D5] = "accidentalFlatParens",
        [0xF851] = "chord7Sus4b9Add3",
        [0xF8B4] = "chordMi7",
        [0xF5D1] = "noteheadBlackParens",
        [0xF817] = "textEnclosureExtensionShort",
        [0xF798] = "noteheadBlackLV4",
        [0xF605] = "noteHalfUpWide",
        [0xF772] = "arpeggioArrowUpLong",
        [0xF736] = "enclosureParenUnderlineExtension",
        [0xF564] = "gClefNatural2Above",
        [0xF5D7] = "accidentalSharpParens",
        [0xF8A9] = "chordMa69#11",
        [0xF83C] = "chordM6",
        [0xF840] = "chordM69",
        [0xF713] = "accidentalFlatSmall",
        [0xF88E] = "chordMajorTriad",
        [0xF87B] = "chord7#9#5",
        [0xF8D1] = "chord6",
        [0xF727] = "enclosureBracketExtensionShort",
        [0xF8B8] = "chordMi7b5",
        [0xF4B8] = "guitarGolpeFlamenco",
        [0xF8C2] = "chordMi69#11",
        [0xF407] = "fClef19thCentury",
        [0xF558] = "gClefFlat5Above",
        [0xF62B] = "articAccentStaccatoAboveLegacy",
        [0xF420] = "flag256thDownStraight",
        [0xF4A7] = "pictLithophonePeinkofer",
        [0xF554] = "gClefFlat2Below",
        [0xF890] = "chord7Alt",
        [0xF86D] = "chord7#5",
        [0xF8D0] = "chord5",
        [0xF844] = "chord69#11",
        [0xF870] = "chord7#9b9",
        [0xF43A] = "pictSleighBellSmithBrindle",
        [0xF408] = "cClefFrench",
        [0xF81B] = "textEnclosureSegmentArrowJogUp",
        [0xF5D9] = "accidentalDoubleFlatParens",
        [0xF897] = "chord#9",
        [0xF877] = "chord13b9",
        [0xF779] = "arrowDownShort",
        [0xF86A] = "chord7#9b13",
        [0xF7EC] = "analyticsArrowRightSegmentTall",
        [0xF8A7] = "chordMa7#11",
        [0xF5EC] = "accidentalJohnstonSevenFlatUp",
        [0xF85C] = "chord-11b5",
        [0xF412] = "flag16thUpStraight",
        [0xF711] = "accidentalSharpSmall",
        [0xF414] = "flag16thDownStraight",
        [0xF684] = "tremolo5Legacy",
        [0xF874] = "chord9#11",
        [0xF8F4] = "noteheadSquareWhiteAltLVLegacy",
        [0xF8AE] = "chordMa9#5",
        [0xF79D] = "noteheadBlackLV9",
        [0xF771] = "arpeggioArrowUpMedium",
        [0xF533] = "gClef0Below",
        [0xF434] = "keyboardPedalPedNoDot",
        [0xF7DA] = "gClefAlt3",
        [0xF82C] = "enclosureRehersalL",
        [0xF728] = "enclosureBracketLeftShort",
        [0xF5D8] = "accidentalDoubleSharpParens",
        [0xF837] = "enclosureRehersalW",
        [0xF8C5] = "chordAdd3",
        [0xF82D] = "enclosureRehersalM",
        [0xF886] = "chordD",
        [0xF44B] = "timeSigCutCommonLarge",
        [0xF56E] = "gClefSharp4Above",
        [0xF75B] = "brassLiftVeryShortMedIncline",
        [0xF853] = "chordLydian",
        [0xF72E] = "enclosureParenOverRight2",
        [0xF73C] = "enclosureBracketExtensionLong",
        [0xF8A6] = "chordMa13",
        [0xF549] = "gClef8Below",
        [0xF404] = "segnoJapanese",
        [0xF726] = "enclosureParenOverExtensionLong",
        [0xF8F9] = "noteheadSquareWhiteLVLegacy",
        [0xF440] = "timeSig0Large",
        [0xF7C5] = "chorus2nd",
        [0xF748] = "enclosureParenUnderlineExtensionAlt",
        [0xF7E6] = "analyticsBackwardArrowShort",
        [0xF742] = "enclosureParenOverExtension2",
        [0xF846] = "chordM7b5",
        [0xF62E] = "articMarcatoStaccatoBelowLegacy",
        [0xF7C6] = "chorus3rd",
        [0xF8C7] = "chordAdd11",
        [0xF7C7] = "chorus4th",
        [0xF753] = "dynamicDiminuendoHairpinVeryLong",
        [0xF438] = "pictTambourineStockhausen",
        [0xF883] = "chord7b9#5",
        [0xF405] = "codaJapanese",
        [0xF7BD] = "conductorBeat3SimpleLegacy",
        [0xF42D] = "doubleTongueAboveNoSlur",
        [0xF752] = "dynamicCrescendoHairpinVeryLong",
        [0xF8AC] = "chordMa7#5",
        [0xF613] = "noteheadSquareWhiteLegacy",
        [0xF54D] = "gClefFlat11Below",
        [0xF8AB] = "chordMa7b5",
        [0xF5E0] = "accidentalJohnstonSevenSharp",
        [0xF8C9] = "chordNo5",
        [0xF741] = "enclosureParenOverLeft2Alt",
        [0xF7A2] = "noteheadVoidWithXLV1",
        [0xF768] = "brassFallSlight",
        [0xF72A] = "enclosureBracketLongExtension",
        [0xF72B] = "enclosureBracketRightLong",
        [0xF763] = "brassLiftShortMedIncline",
        [0xF5E3] = "accidentalJohnstonSevenDown",
        [0xF7EA] = "analyticsArrowExtension",
        [0xF8B7] = "chordMi13",
        [0xF7C8] = "fine",
        [0xF532] = "fClef5Below",
        [0xF543] = "gClef5Below",
        [0xF73D] = "enclosureBracketWavyRight",
        [0xF72D] = "enclosureParenOverExtensionLongAlt",
        [0xF7E2] = "analyticsModulationCombiningBracketRightShort",
        [0xF74A] = "enclosureClosed",
        [0xF81F] = "textEnclosureFine",
        [0xF731] = "enclosureParenUnderlineRight",
        [0xF734] = "enclosureParenUnderlineRightLong",
        [0xF73A] = "enclosureParenUnderlineRightShortLong",
        [0xF759] = "brassLiftVeryShortSlightIncline",
        [0xF89F] = "chord#11#9",
        [0xF8BC] = "chordMi7b9b5",
        [0xF82F] = "enclosureRehersalO",
        [0xF8FC] = "noteheadSlashDiamondWhiteLVLegacy",
        [0xF879] = "chord13b9b5",
        [0xF85A] = "chord-7b5",
        [0xF838] = "enclosureRehersalX",
        [0xF733] = "enclosureUnderlineLong",
        [0xF824] = "enclosureRehersalD",
        [0xF546] = "gClef7Above",
        [0xF712] = "accidentalNaturalSmall",
        [0xF68D] = "ornamentTrillNaturalAboveLegacy",
        [0xF746] = "enclosureParenOverRight2Long",
        [0xF8B6] = "chordMi11",
        [0xF703] = "flag16thUpAlt",
        [0xF825] = "enclosureRehersalE",
        [0xF426] = "flag1024thDownStraight",
        [0xF472] = "gClefSmall",
        [0xF474] = "fClefSmall",
        [0xF443] = "timeSig3Large",
        [0xF421] = "flag512thUpStraight",
        [0xF85E] = "chord-7b9b5",
        [0xF8B9] = "chordMi9b5",
        [0xF8CE] = "chord3",
        [0xF673] = "noteheadSlashHorizontalEndsLegacy",
        [0xF539] = "gClef15Below",
        [0xF540] = "gClef4Above",
        [0xF541] = "gClef4Below",
        [0xF542] = "gClef5Above",
        [0xF873] = "chord9b5",
        [0xF724] = "enclosureParenOverExtension",
        [0xF5B9] = "ornamentTurnNaturalBelow",
        [0xF833] = "enclosureRehersalS",
        [0xF860] = "chord-M7",
        [0xF773] = "arpeggioArrowDownShort",
        [0xF4AC] = "pictLotusFlutePeinkofer",
        [0xF551] = "gClefFlat16Below",
        [0xF8D2] = "chord7",
        [0xF556] = "gClefFlat3Below",
        [0xF56C] = "gClefSharp12Below",
        [0xF557] = "gClefFlat4Below",
        [0xF56D] = "gClefSharp1Above",
        [0xF830] = "enclosureRehersalP",
        [0xF7D7] = "gClefAlt",
        [0xF430] = "tripleTongueBelowNoSlur",
        [0xF56A] = "gClefNatural9Above",
        [0xF749] = "enclosureParenUnderlineRightShortAlt2",
        [0xF7BA] = "tremolo3Alt5",
        [0xF756] = "brassShakeLong",
        [0xF436] = "harpMetalRodAlt",
        [0xF62F] = "articTenutoStaccatoAboveLegacy",
        [0xF5DD] = "accidentalFlatJohnstonEl",
        [0xF735] = "enclosureParenUnderlineLeftAlt",
        [0xF473] = "cClefSmall",
        [0xF8DF] = "noteheadXBlack3LVLegacy",
        [0xF7CD] = "miscLegacy2",
        [0xF7CC] = "note64thUpAlt",
        [0xF54C] = "gClefFlat10Below",
        [0xF415] = "flag32ndUpStraight",
        [0xF75C] = "brassFallRoughVeryShortMedDecline",
        [0xF790] = "noteheadHalfLV5",
        [0xF437] = "harpTuningKeyAlt",
        [0xF8D9] = "noteheadBlackLVLegacy",
        [0xF745] = "enclosureParenOverExtension2Long",
        [0xF5E1] = "accidentalJohnstonSevenFlat",
        [0xF73B] = "enclosureBracketWavyLeft",
        [0xF86E] = "chord7b9b5",
        [0xF854] = "chord-6",
    }

    function smufl_glyphs.get_glyph_info(codepoint_or_name, font_info_or_name)
        local name
        if type(codepoint_or_name) == "number" then
            name = by_codepoint[codepoint_or_name]
        elseif type(codepoint_or_name) == "string" then
            name = codepoint_or_name
        end
        local info = name and glyphs[name]
        if not info and font_info_or_name then
            local optional_glyphs = library.get_smufl_metadata_table(font_info_or_name, "optionalGlyphs")
            if optional_glyphs then
                if type(codepoint_or_name) == "number" then
                    for k, v in pairs(optional_glyphs) do
                        if v.codepoint then
                            local codepoint = utils.parse_codepoint(v.codepoint)
                            if codepoint == codepoint_or_name then
                                name = k
                                info = { codepoint = codepoint, description = "", optional = true }
                                break
                            end
                        end
                    end
                elseif type(codepoint_or_name) == "string" then
                    name = codepoint_or_name
                    local optinfo = optional_glyphs[name]
                    if optinfo and optinfo.codepoint then
                        local codepoint = utils.parse_codepoint(optinfo.codepoint)
                        info = codepoint and {codepoint = codepoint, description = "", optional = true}
                    end
                end
            end
        end
        return name, info and utils.copy_table(info) or nil
    end

    function smufl_glyphs.iterate_glyphs()
        local k, v
        return function()
            k, v = next(glyphs, k)
            if k then
                return k, utils.copy_table(v)
            end
        end
    end
    return smufl_glyphs
end
function plugindef()
    finaleplugin.RequireDocument = true -- manipulating font information requires a document
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.3"
    finaleplugin.Date = "June 22, 2025"
    finaleplugin.MinJWLuaVersion = 0.75
    finaleplugin.Notes = [[
        A utility for mapping legacy music font glyphs to SMuFL glyphs. It emits a json
        file in the same format as those provided in the Finale installation for MakeMusic's
        legacy fonts.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 A utility for mapping legacy music font glyphs to SMuFL glyphs. It emits a json file in the same format as those provided in the Finale installation for MakeMusic\u8217's legacy fonts.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/font_map_legacy.hash"
    return "Map Legacy Fonts to SMuFL...", "Map Legacy Fonts to SMuFL", "Map legacy font glyphs to SMuFL glyphs"
end
local utils = require("library.utils")
local client = require("library.client")
local library = require("library.general_library")
local mixin = require("library.mixin")
local smufl_glyphs = require("library.smufl_glyphs")
local cjson = require("cjson")
context = {
    smufl_list = library.get_smufl_font_list(),
    current_font = finale.FCFontInfo("Maestro", 24),
    current_mapping = {},
    entries_by_glyph = {},
    popup_entries = {},
    current_directory = finenv.RunningLuaFolderPath()
}
local enable_disable
local get_popup_entry
local function reset_mapping_state()
    context.current_mapping = {}
    context.entries_by_glyph = {}
    context.popup_entries = {}
end
local function parse_legacy_codepoint_string(str)
    if type(str) == "number" then
        return str
    end
    if type(str) ~= "string" then
        return nil
    end
    str = utils.trim(str)
    if str:match("^0[xX]%x+$") then
        return tonumber(str, 16)
    end
    return tonumber(str)
end
local function legacy_codepoint_to_string(legacy_codepoint, original)
    if type(original) == "string" and #original > 0 then
        return original
    end
    return tostring(legacy_codepoint)
end
local function register_entry_glyph(entry)
    if not entry or type(entry.glyph) ~= "string" then
        return
    end
    local glyph_name = entry.glyph
    if entry._registered_glyph == glyph_name then
        return
    end
    if entry._registered_glyph then
        local old_list = context.entries_by_glyph[entry._registered_glyph]
        if old_list then
            for index, candidate in ipairs(old_list) do
                if candidate == entry then
                    table.remove(old_list, index)
                    break
                end
            end
            if #old_list == 0 then
                context.entries_by_glyph[entry._registered_glyph] = nil
            end
        end
    end
    context.entries_by_glyph[glyph_name] = context.entries_by_glyph[glyph_name] or {}
    local glyph_list = context.entries_by_glyph[glyph_name]
    local exists = false
    for _, candidate in ipairs(glyph_list) do
        if candidate == entry then
            exists = true
            break
        end
    end
    if not exists then
        table.insert(glyph_list, entry)
    end
    entry._registered_glyph = glyph_name
end
local function ensure_entry_registration(entry)
    if not entry or type(entry.glyph) ~= "string" then
        return
    end
    if not entry.legacyCodepoints or #entry.legacyCodepoints == 0 then
        return
    end
    entry.legacyStrings = entry.legacyStrings or {}
    register_entry_glyph(entry)
    for index, legacy_cp in ipairs(entry.legacyCodepoints) do
        entry.legacyStrings[index] = entry.legacyStrings[index] or legacy_codepoint_to_string(legacy_cp)
        context.current_mapping[legacy_cp] = context.current_mapping[legacy_cp] or {}
        local mapping_list = context.current_mapping[legacy_cp]
        local exists = false
        for _, candidate in ipairs(mapping_list) do
            if candidate == entry then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(mapping_list, entry)
        end
    end
end
local function unregister_entry_if_empty(entry)
    if not entry or not entry.legacyCodepoints or #entry.legacyCodepoints > 0 then
        return
    end
    if not entry._registered_glyph then
        return
    end
    local glyph_list = context.entries_by_glyph[entry._registered_glyph]
    if not glyph_list then
        return
    end
    for index, candidate in ipairs(glyph_list) do
        if candidate == entry then
            table.remove(glyph_list, index)
            break
        end
    end
    if #glyph_list == 0 then
        context.entries_by_glyph[entry._registered_glyph] = nil
    end
    entry._registered_glyph = nil
end
local function remove_legacy_codepoint_from_entry(entry, legacy_codepoint)
    if not entry or not entry.legacyCodepoints then
        return
    end
    for i, value in ipairs(entry.legacyCodepoints) do
        if value == legacy_codepoint then
            table.remove(entry.legacyCodepoints, i)
            if entry.legacyStrings then
                table.remove(entry.legacyStrings, i)
            end
            break
        end
    end
    local mapping_list = context.current_mapping[legacy_codepoint]
    if mapping_list then
        for i, candidate in ipairs(mapping_list) do
            if candidate == entry then
                table.remove(mapping_list, i)
                break
            end
        end
        if #mapping_list == 0 then
            context.current_mapping[legacy_codepoint] = nil
        end
    end
    unregister_entry_if_empty(entry)
end
local function set_entry_smufl_info(entry, smufl_point, font)
    if not entry then
        return
    end
    local glyph_name, info = smufl_glyphs.get_glyph_info(smufl_point, font)
    entry.codepoint = smufl_point
    if info then
        entry.glyph = glyph_name
    else
        entry.glyph = utils.format_codepoint(smufl_point)
    end
    if font and smufl_point >= 0xF400 and smufl_point <= 0xF8FF then
        entry.smuflFontName = font.Name
    else
        entry.smuflFontName = nil
    end
    register_entry_glyph(entry)
end
local function normalize_entry_legacy_arrays(entry)
    if not entry or not entry.legacyCodepoints then
        return
    end
    local zipped = {}
    for index, cp in ipairs(entry.legacyCodepoints) do
        if cp then
            local str
            if entry.legacyStrings and entry.legacyStrings[index] then
                str = entry.legacyStrings[index]
            else
                str = legacy_codepoint_to_string(cp)
            end
            table.insert(zipped, {codepoint = cp, value = str})
        end
    end
    table.sort(zipped, function(a, b)
        if a.codepoint == b.codepoint then
            return (a.value or "") < (b.value or "")
        end
        return (a.codepoint or 0) < (b.codepoint or 0)
    end)
    entry.legacyCodepoints = {}
    entry.legacyStrings = {}
    for index, item in ipairs(zipped) do
        entry.legacyCodepoints[index] = item.codepoint
        entry.legacyStrings[index] = item.value
    end
end
local function format_mapping(mapping)
    if not mapping then
        return ""
    end
    local codepoint_desc = "[" .. utils.format_codepoint(mapping.codepoint or 0) .. "]"
    if mapping.glyph then
        codepoint_desc = "'" .. mapping.glyph .. "' " .. codepoint_desc
    end
    if mapping.smuflFontName then
        codepoint_desc = codepoint_desc .. "(" .. mapping.smuflFontName ..")"
    end
    return codepoint_desc
end
local function change_font(dialog, font_info)
    if font_info.IsSMuFLFont then
        dialog:CreateChildUI():AlertError("Unable to map SMuFL font " .. font_info:CreateDescription(), "SMuFL Font")
        return
    end
    context.current_font = font_info
    reset_mapping_state()
    local control = dialog:GetControl("legacy_box")
    control:SetText("")
    control:SetFont(context.current_font)
    dialog:GetControl("show_font"):SetText(font_info:CreateDescription())
    dialog:GetControl("mappings"):Clear()
    enable_disable(dialog)
end
local function get_codepoint(control)
    local fcstr = finale.FCString()
    control:GetText(fcstr)
    if control:CreateFontInfo():IsMacSymbolFont() then
        fcstr:EncodeToMacRoman()
    end
    return fcstr.Length > 0 and fcstr:GetCodePointAt(0) or 0
end
local function set_codepoint(control, codepoint)
    local fcstr = finale.FCString(utf8.char(codepoint))
    if control:CreateFontInfo():IsMacSymbolFont() then
        fcstr:EncodeFromMacRoman()
    end
    control:SetText(fcstr)
end
get_popup_entry = function(popup)
    if not popup then
        return nil
    end
    local index = popup:GetSelectedItem()
    if index == nil or index < 0 then
        return nil
    end
    return context.popup_entries[index + 1]
end
enable_disable = function(dialog)
    local delable = #(dialog:GetControl("legacy_box"):GetText()) > 0
    local addable = delable and #(dialog:GetControl("smufl_box"):GetText()) > 0
    if delable then
        local popup = dialog:GetControl("mappings")
        delable = popup:GetCount() > 0 and get_popup_entry(popup) ~= nil
    end
    dialog:GetControl("add_mapping"):SetEnable(addable)
    dialog:GetControl("delete_mapping"):SetEnable(delable)
end
local function on_smufl_popup(popup)
    local dialog = popup:GetParent()
    local smufl_box = dialog:GetControl("smufl_box")
    local fcstr = finale.FCString()
    popup:GetItemText(popup:GetSelectedItem(), fcstr)
    smufl_box:SetFont(finale.FCFontInfo(fcstr.LuaString, 24))
end
local function on_popup(popup)
    local selection = get_popup_entry(popup)
    local legacy_codepoint = selection and selection.legacy_codepoint or 0
    local current_mapping = selection and selection.entry
    local smufl_codepoint = current_mapping and current_mapping.codepoint or 0
    local dialog = popup:GetParent()
    if current_mapping and current_mapping.smuflFontName then
        local smufl_list = dialog:GetControl("smufl_list")
        for index = 0, smufl_list:GetCount() - 1 do
            local str = finale.FCString()
            smufl_list:GetItemText(index, str)
            if str.LuaString == current_mapping.smuflFontName then
                smufl_list:SetSelectedItem(index)
                on_smufl_popup(smufl_list)
            end
        end
    end
    set_codepoint(dialog:GetControl("legacy_box"), legacy_codepoint)
    set_codepoint(dialog:GetControl("smufl_box"), smufl_codepoint)
end
local function update_popup(popup, target_codepoint, target_entry)
    context.popup_entries = {}
    for legacy_codepoint, entry_list in pairs(context.current_mapping) do
        if type(entry_list) == "table" then
            for legacy_index, entry in ipairs(entry_list) do
                table.insert(context.popup_entries, {
                    legacy_codepoint = legacy_codepoint,
                    entry = entry,
                    legacy_index = legacy_index
                })
            end
        end
    end
    table.sort(context.popup_entries, function(a, b)
        if a.legacy_codepoint == b.legacy_codepoint then
            local glyph_a = (a.entry and a.entry.glyph) or ""
            local glyph_b = (b.entry and b.entry.glyph) or ""
            if glyph_a == glyph_b then
                local codepoint_a = (a.entry and a.entry.codepoint) or 0
                local codepoint_b = (b.entry and b.entry.codepoint) or 0
                return codepoint_a < codepoint_b
            end
            return glyph_a < glyph_b
        end
        return a.legacy_codepoint < b.legacy_codepoint
    end)
    popup:Clear()
    local current_index
    for index, info in ipairs(context.popup_entries) do
        local label = tostring(info.legacy_codepoint) .. " maps to " .. format_mapping(info.entry)
        popup:AddString(label)
        if target_entry and info.entry == target_entry and info.legacy_codepoint == target_codepoint then
            current_index = index - 1
        elseif not current_index and target_codepoint and info.legacy_codepoint == target_codepoint then
            current_index = index - 1
        end
    end
    if not current_index and popup:GetCount() > 0 then
        current_index = 0
    end
    if current_index then
        popup:SetSelectedItem(current_index)
        on_popup(popup)
    end
    enable_disable(popup:GetParent())
end
local function on_select_font(control)
    local font_info = finale.FCFontInfo(context.current_font.Name, context.current_font.Size)
    local font_dialog = finale.FCFontDialog(control:GetParent():CreateChildUI(), font_info)
    font_dialog.UseSizes = true
    font_dialog.UseStyles = false
    if font_dialog:Execute() then
        font_info = font_dialog.FontInfo
        if font_info.FontID ~= context.current_font.FontID then
            change_font(control:GetParent(), font_dialog.FontInfo)
        end
    end
end
local function on_select_file(control)
    local dialog = control:GetParent()
    local open_dialog = mixin.FCMFileOpenDialog(dialog:CreateChildUI())
        :SetWindowTitle(finale.FCString("Select existing JSON file"))
        :SetInitFolder(finale.FCString(context.current_directory))
        :AddFilter(finale.FCString("*.json"), finale.FCString("Legacy Font Mapping"))
    if not open_dialog:Execute() then
        return
    end
    local selected_file = finale.FCString()
    open_dialog:GetFileName(selected_file)
    local path, name = utils.split_file_path(selected_file.LuaString)
    if not finenv.UI():IsFontAvailable(finale.FCString(name)) then
        dialog:CreateChildUI():AlertError("Font " .. name .. " is not available on the system.", "Missing Font")
        return
    end
    local font_info = finale.FCFontInfo(name, context.current_font.Size)
    if font_info.IsSMuFLFont then
        dialog:CreateChildUI():AlertError("Font " .. name .. " is a SMuFL font.", "SMuFL Font")
        return
    end
    local file = io.open(client.encode_with_client_codepage(selected_file.LuaString))
    if file then
        local json_contents = file:read("*a")
        file:close()
        local json = cjson.decode(json_contents)
        if type(json) ~= "table" then
            dialog:CreateChildUI():AlertError("Selected file is not a valid mapping.", "Invalid File")
            return
        end
        context.current_directory = path
        change_font(dialog, font_info)
        local smufl_box = dialog:GetControl("smufl_box")
        for glyph, value in pairs(json) do
            if type(glyph) == "string" and type(value) == "table" then
                local entries = value
                if not entries[1] and (entries.codepoint or entries.legacyCodepoint) then
                    entries = {entries}
                end
                for _, entry_data in ipairs(entries) do
                    if type(entry_data) == "table" then
                        local entry = {
                            glyph = glyph,
                            codepoint = utils.parse_codepoint(entry_data.codepoint or ""),
                            description = entry_data.description or "",
                            nameIsMakeMusic = entry_data.nameIsMakeMusic,
                            smuflFontName = entry_data.smuflFontName,
                            xOffset = entry_data.xOffset,
                            yOffset = entry_data.yOffset,
                            alternate = entry_data.alternate,
                            notes = entry_data.notes,
                            legacyCodepoints = {},
                            legacyStrings = {}
                        }
                        if entry.codepoint == 0xFFFD then
                            local _, info = smufl_glyphs.get_glyph_info(glyph, smufl_box:CreateFontInfo())
                            if info then
                                entry.codepoint = info.codepoint
                            end
                        end
                        if type(entry_data.legacyCodepoints) == "table" then
                            for _, legacy_str in ipairs(entry_data.legacyCodepoints) do
                                local cp_value = parse_legacy_codepoint_string(legacy_str)
                                if cp_value then
                                    table.insert(entry.legacyCodepoints, cp_value)
                                    table.insert(entry.legacyStrings, legacy_codepoint_to_string(cp_value, legacy_str))
                                end
                            end
                        elseif entry_data.legacyCodepoint ~= nil then
                            local legacy_str = tostring(entry_data.legacyCodepoint)
                            local cp_value = parse_legacy_codepoint_string(entry_data.legacyCodepoint)
                            if cp_value then
                                table.insert(entry.legacyCodepoints, cp_value)
                                table.insert(entry.legacyStrings, legacy_codepoint_to_string(cp_value, legacy_str))
                            end
                        end
                        normalize_entry_legacy_arrays(entry)
                        if entry.codepoint and #entry.legacyCodepoints > 0 then
                            ensure_entry_registration(entry)
                        end
                    end
                end
            end
        end
        update_popup(dialog:GetControl("mappings"))
    end
end
local function on_edit_box(control)
    local fcstr = finale.FCString()
    control:GetText(fcstr)
    if fcstr.Length > 0 then
        local cp, x = fcstr:GetCodePointAt(fcstr.Length - 1)
        if x > 0 then
            fcstr.LuaString = utf8.char(cp)
            control:SetText(fcstr)
        end
    end
    enable_disable(control:GetParent())
end
local function on_symbol_select(box)
    local dialog = box:GetParent()
    local last_point = get_codepoint(box)
    local new_point = dialog:CreateChildUI():DisplaySymbolDialog(box:CreateFontInfo(), last_point)
    if new_point ~= 0 then
        set_codepoint(box, new_point)
    end
    enable_disable(dialog)
end
local function on_add_mapping(control)
    local dialog = control:GetParent()
    local popup = dialog:GetControl("mappings")
    local legacy_point = get_codepoint(dialog:GetControl("legacy_box"))
    if legacy_point == 0 then return end
    local smufl_point = get_codepoint(dialog:GetControl("smufl_box"))
    if smufl_point == 0 then return end
    local font = dialog:GetControl("smufl_box"):CreateFontInfo()
    local selection = get_popup_entry(popup)
    local editing_entry = selection and selection.legacy_codepoint == legacy_point and selection.entry
    if editing_entry then
        set_entry_smufl_info(editing_entry, smufl_point, font)
        update_popup(popup, legacy_point, editing_entry)
        return
    end
    local existing_entries = context.current_mapping[legacy_point]
    if existing_entries and #existing_entries > 0 then
        local message
        if #existing_entries == 1 then
            message = "Symbol " .. legacy_point .. " is already mapped to " .. format_mapping(existing_entries[1]) .. ". Add another mapping?"
        else
            message = "Symbol " .. legacy_point .. " already has " .. #existing_entries .. " mappings. Add another mapping?"
        end
        if finale.YESRETURN ~= dialog:CreateChildUI():AlertYesNo(message, "Already Mapped") then
            return
        end
    end
    local glyph, info = smufl_glyphs.get_glyph_info(smufl_point, font)
    local new_entry = {
        codepoint = smufl_point,
        glyph = info and glyph or utils.format_codepoint(smufl_point),
        description = "",
        nameIsMakeMusic = nil,
        smuflFontName = nil,
        xOffset = nil,
        yOffset = nil,
        alternate = nil,
        notes = nil,
        legacyCodepoints = { legacy_point },
        legacyStrings = { legacy_codepoint_to_string(legacy_point) }
    }
    if font and smufl_point >= 0xF400 and smufl_point <= 0xF8FF then
        new_entry.smuflFontName = font.Name
    end
    ensure_entry_registration(new_entry)
    update_popup(popup, legacy_point, new_entry)
end
local function on_delete_mapping(control)
    local dialog = control:GetParent()
    local popup = dialog:GetControl("mappings")
    if popup:GetCount() > 0 then
        local selection = get_popup_entry(popup)
        if selection and selection.entry and selection.legacy_codepoint then
            remove_legacy_codepoint_from_entry(selection.entry, selection.legacy_codepoint)
            update_popup(popup)
        end
    end
end
local function emit_json(entries_by_glyph)
    local function quote(str)
        return '"' .. tostring(str):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    end
    local function format_legacy_array(entry)
        local strings = {}
        if entry.legacyCodepoints then
            for index, legacy_cp in ipairs(entry.legacyCodepoints) do
                local str = entry.legacyStrings and entry.legacyStrings[index] or legacy_codepoint_to_string(legacy_cp)
                table.insert(strings, str)
            end
        end
        if #strings == 0 then
            return '            "legacyCodepoints": []'
        end
        local parts = {}
        for _, str in ipairs(strings) do
            table.insert(parts, '                ' .. quote(str))
        end
        return '            "legacyCodepoints": [\n' .. table.concat(parts, ",\n") .. '\n            ]'
    end
    local function emit_entry(entry)
        local parts = { format_legacy_array(entry) }
        table.insert(parts, '            "codepoint": ' .. quote(utils.format_codepoint(entry.codepoint)))
        table.insert(parts, '            "description": ' .. quote(entry.description or ""))
        if type(entry.nameIsMakeMusic) == "boolean" then
            table.insert(parts, '            "nameIsMakeMusic": ' .. tostring(entry.nameIsMakeMusic))
        end
        if entry.smuflFontName then
            table.insert(parts, '            "smuflFontName": ' .. quote(entry.smuflFontName))
        end
        if entry.xOffset then
            table.insert(parts, '            "xOffset": ' .. quote(tostring(entry.xOffset)))
        end
        if entry.yOffset then
            table.insert(parts, '            "yOffset": ' .. quote(tostring(entry.yOffset)))
        end
        if type(entry.alternate) == "boolean" then
            table.insert(parts, '            "alternate": ' .. tostring(entry.alternate))
        end
        if entry.notes and #entry.notes > 0 then
            table.insert(parts, '            "notes": ' .. quote(entry.notes))
        end
        return "        {\n" .. table.concat(parts, ",\n") .. "\n        }"
    end
    local lines = { "{" }
    local first_glyph = true
    for glyph, entry_list in pairsbykeys(entries_by_glyph) do
        if type(glyph) == "string" and type(entry_list) == "table" and #entry_list > 0 then
            local sortable = {}
            for _, entry in ipairs(entry_list) do
                if entry.legacyCodepoints and #entry.legacyCodepoints > 0 then
                    table.insert(sortable, entry)
                end
            end
            if #sortable > 0 then
                table.sort(sortable, function(a, b)
                    local a_codepoint = a.legacyCodepoints and a.legacyCodepoints[1] or 0
                    local b_codepoint = b.legacyCodepoints and b.legacyCodepoints[1] or 0
                    if a_codepoint == b_codepoint then
                        return (a.codepoint or 0) < (b.codepoint or 0)
                    end
                    return a_codepoint < b_codepoint
                end)
                if not first_glyph then
                    lines[#lines] = lines[#lines] .. ","
                end
                table.insert(lines, "    " .. quote(glyph) .. ": [")
                for index, entry in ipairs(sortable) do
                    local entry_text = emit_entry(entry)
                    if index < #sortable then
                        entry_text = entry_text .. ","
                    end
                    table.insert(lines, entry_text)
                end
                table.insert(lines, "    ]")
                first_glyph = false
            end
        end
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end
local function on_save(control)
    local dialog = control:GetParent()
    local function has_mappings()
        for _, entry_list in pairs(context.entries_by_glyph) do
            if type(entry_list) == "table" then
                for _, entry in ipairs(entry_list) do
                    if entry.legacyCodepoints and #entry.legacyCodepoints > 0 then
                        return true
                    end
                end
            end
        end
        return false
    end
    if not has_mappings() then
        dialog:CreateChildUI():AlertInfo("Nothing has been mapped.", "No Mapping")
        return
    end
    local save_dialog = finale.FCFileSaveAsDialog(dialog:CreateChildUI())
    save_dialog:SetWindowTitle(finale.FCString("Save mapping as"))
    save_dialog:AddFilter(finale.FCString("*.json"), finale.FCString("Legacy Font Mapping"))
    save_dialog:SetInitFolder(finale.FCString(context.current_directory))
    save_dialog:SetFileName(finale.FCString(context.current_font.Name .. ".json"))
    save_dialog:AssureFileExtension("json")
    if not save_dialog:Execute() then
        return
    end
    local path_fstr = finale.FCString()
    save_dialog:GetFileName(path_fstr)
    for _, entry_list in pairs(context.entries_by_glyph) do
        if type(entry_list) == "table" then
            for _, entry in ipairs(entry_list) do
                if entry.legacyCodepoints and #entry.legacyCodepoints > 0 then
                    if type(entry.glyph) ~= "string" or entry.glyph == "" then
                        dialog:CreateChildUI():AlertError("A mapping is missing a glyph name.", "Missing Glyph Name")
                        return
                    end
                    if not entry.codepoint then
                        dialog:CreateChildUI():AlertError("A mapping is missing a SMuFL codepoint.", "Missing Codepoint")
                        return
                    end
                end
            end
        end
    end
    local result = emit_json(context.entries_by_glyph)
    local file = io.open(client.encode_with_client_codepage(path_fstr.LuaString), "w")
    if not file then
        dialog:CreateChildUI():AlertError("Unable to write to file " .. path_fstr.LuaString .. ".", "File Error")
        return
    end
    file:write(result)
    file:close()
end
function font_map_legacy()
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle("Map Legacy Fonts to SMuFL")
    local editor_width = 60
    local editor_height = 80
    local smufl_y_diff = 20

    local button_height = 20
    local y_increment = 10
    local current_y = 0

    dialog:CreateButton(0, current_y, "font_sel")
        :SetText("Font...")
        :DoAutoResizeWidth(0)
        :AddHandleCommand(on_select_font)
    dialog:CreateButton(0, current_y, "file_sel")
        :SetText("File...")
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dialog:GetControl("font_sel"), 10)
        :AddHandleCommand(on_select_file)
    local smufl_popup = dialog:CreatePopup(0, current_y, "smufl_list")
        :AssureNoHorizontalOverlap(dialog:GetControl("file_sel"), 10)
        :StretchToAlignWithRight()
        :AddHandleCommand(on_smufl_popup)
    local start_index = 0
    for name, _ in pairsbykeys(context.smufl_list) do
        smufl_popup:AddString(name)
        if name == "Finale Maestro" then
            start_index = smufl_popup:GetCount() - 1
        end
    end
    if smufl_popup:GetCount() <= 0 then
        finenv.UI():AlertError("No SMuFL fonts found on system.", "SMuFL Required")
        return
    end
    smufl_popup:SetSelectedItem(start_index)
    current_y = current_y + 1.5 * button_height

    dialog:CreateStatic(0, current_y, "show_font")
        :DoAutoResizeWidth()
        :SetText(context.current_font:CreateDescription())
    current_y = current_y + button_height

    dialog:CreateEdit(0, current_y, "legacy_box")
        :SetHeight(editor_height)
        :SetWidth(editor_width)
        :SetFont(context.current_font)
        :AddHandleCommand(on_edit_box)
    dialog:CreateButton(0, current_y + editor_height + y_increment, "legacy_sel")
        :SetText("Symbol...")
        :SetWidth(editor_width)
        :AddHandleCommand(function(control)
            on_symbol_select(control:GetParent():GetControl("legacy_box"))
        end)
    dialog:CreateButton(0, current_y + editor_height / 2 - button_height, "add_mapping")
        :SetText("Add/Update Mapping")
        :SetWidth(140)
        :SetEnable(false)
        :AssureNoHorizontalOverlap(dialog:GetControl("legacy_box"), editor_width / 2)
        :AddHandleCommand(on_add_mapping)
    dialog:CreateButton(0, current_y + editor_height / 2 + y_increment, "delete_mapping")
        :SetText("Delete Mapping")
        :SetWidth(140)
        :SetEnable(false)
        :AssureNoHorizontalOverlap(dialog:GetControl("legacy_box"), editor_width / 2)
        :AddHandleCommand(on_delete_mapping)
    dialog:CreateEdit(0, current_y - smufl_y_diff, "smufl_box")
        :SetHeight(editor_height + smufl_y_diff)
        :SetWidth(editor_width)
        :SetFont(finale.FCFontInfo("Finale Maestro", 24))
        :AssureNoHorizontalOverlap(dialog:GetControl("add_mapping"), editor_width/2)
        :AddHandleCommand(on_edit_box)
    dialog:CreateButton(0, current_y + editor_height + y_increment, "smufl_sel")
        :SetText("Symbol...")
        :SetWidth(editor_width)
        :HorizontallyAlignLeftWith(dialog:GetControl("smufl_box"))
        :AddHandleCommand(function(control)
            on_symbol_select(control:GetParent():GetControl("smufl_box"))
        end)
    current_y = current_y + editor_height + 2 * y_increment + button_height
    dialog:CreatePopup(0, current_y, "mappings")
        :StretchToAlignWithRight()
        :AddHandleCommand(on_popup)
    current_y = current_y + button_height + y_increment

    dialog:CreateButton(0, current_y, "save")
        :SetText("Save...")
        :DoAutoResizeWidth(0)
        :AddHandleCommand(on_save)
    dialog:CreateCloseButton(0, current_y, "close")
        :SetText("Close")
        :DoAutoResizeWidth(0)
        :HorizontallyAlignRightWithFurthest()

    dialog:RegisterInitWindow(function(self)
        on_smufl_popup(self:GetControl("smufl_list"))
    end)

    dialog:ExecuteModal()
end
font_map_legacy()

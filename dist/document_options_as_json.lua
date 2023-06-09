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
        private[self].Left = self:GetLeft__()
        private[self].Top = self:GetTop__()
        private[self].Height = self:GetHeight__()
        private[self].Width = self:GetWidth__()
    end

    function methods:RestoreState()
        self:SetEnable__(private[self].Enable)
        self:SetVisible__(private[self].Visible)
        self:SetLeft__(private[self].Left)
        self:SetTop__(private[self].Top)
        self:SetHeight__(private[self].Height)
        self:SetWidth__(private[self].Width)

        temp_str.LuaString = private[self].Text
        self:SetText__(temp_str)
    end


    methods.AddHandleCommand, methods.RemoveHandleCommand = mixin_helper.create_standard_control_event("HandleCommand")
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
    local trigger_check_change
    local each_last_check_change

    function methods:SetCheck(checked)
        mixin_helper.assert_argument_type(2, checked, "number")
        self:SetCheck__(checked)
        trigger_check_change(self)
    end



    methods.AddHandleCheckChange, methods.RemoveHandleCheckChange, trigger_check_change, each_last_check_change = mixin_helper.create_custom_control_change_event(


        {
            name = "last_check",
            get = "GetCheck__",
            initial = 0,
        }
    )
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
    local library = require("library.general_library")
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

    function methods:AddStrings(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString", "FCStrings")
            if type(v) == "userdata" and v:ClassName() == "FCStrings" then
                for str in each(v) do
                    mixin.FCMCtrlListBox.AddString(self, str)
                end
            else
                mixin.FCMCtrlListBox.AddString(self, v)
            end
        end
    end

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
    local library = require("library.general_library")
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

    function methods:AddStrings(...)
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
    local using_timer_fix = false
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
    local utils = require("library.utils")
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

    function methods:SetMeasurementEfix(value, measurementunit)
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
            if not self:RegisterHandleControlEvent_(control, function(ctrl)
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
    local class = {Methods = {}}
    local methods = class.Methods
    local private = setmetatable({}, {__mode = "k"})
    local function create_control(self, func, num_args, ...)
        local control = self["Create" .. func .. "__"](self, ...)
        private[self].Controls[control:GetControlID()] = control
        control:RegisterParent(self)
        local control_name = select(num_args + 1, ...)
        if control_name then
            control_name = type(control_name) == "userdata" and control_name.LuaString or control_name
            if private[self].NamedControls[control_name] then
                error("A control is already registered with the name '" .. control_name .. "'", 2)
            end
            private[self].NamedControls[control_name] = control
        end
        return control
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
        [2] = {"Button", "Checkbox", "CloseButton", "DataList", "Edit",
            "ListBox", "Popup", "Slider", "Static", "Switcher", "Tree", "UpDown",
        },
        [3] = {"HorizontalLine", "VerticalLine",},
    }) do
        for _, control_type in pairs(ctrl_types) do
            if not finale.FCCustomWindow.__class["Create" .. control_type] then
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
    local library = require("library.general_library")
    local class = {Methods = {}}
    local methods = class.Methods
    local temp_str = finale.FCString()

    function methods:AddCopy(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        mixin_helper.boolean_to_error(self, "AddCopy", mixin_helper.to_fcstring(str, temp_str))
    end

    function methods:AddCopies(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin_helper.assert_argument_type(i + 1, v, "FCStrings", "FCString", "string", "number")
            if mixin_helper.is_instance_of(v, "FCStrings") then
                for str in each(v) do
                    self:AddCopy__(str)
                end
            else
                mixin.FCStrings.AddCopy(self, v)
            end
        end
    end

    function methods:Find(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        return self:Find_(mixin_helper.to_fcstring(str, temp_str))
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

    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 59 then
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

                local num_steps = tonumber(tostring(value / step_def.value))
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
package.preload["mixin.FCXCustomLuaWindow"] = package.preload["mixin.FCXCustomLuaWindow"] or function()



    local mixin = require("library.mixin")
    local utils = require("library.utils")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local class = {Parent = "FCMCustomLuaWindow", Methods = {}}
    local methods = class.Methods
    local trigger_measurement_unit_change
    local each_last_measurement_unit_change

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
package.preload["library.mixin_helper"] = package.preload["library.mixin_helper"] or function()




    require("library.lua_compatibility")
    local utils = require("library.utils")
    local mixin = require("library.mixin")
    local library = require("library.general_library")
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
            if (object_type < 2 and class_names[0][parent])
                or (object_type > 0 and class_names[1][parent])
            then
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
    local function assert_func(condition, message, level)
        if type(condition) == 'function' then
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
            mixin_helper.assert(
                (window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow",
                "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
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
                for k, v in pairs(current) do
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
            window:AddInitWindow(
                function()

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
            mixin_helper.assert(
                (window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow",
                "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
            mixin_helper.force_assert(
                not event.callback_exists(self, callback), "The callback has already been added as a handler.")
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
                window:QueueHandleCustom(
                    function()
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
            mixin_helper.force_assert(
                not event.callback_exists(self, callback), "The callback has already been added as a handler.")
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
            window:QueueHandleCustom(
                function()
                    queued[window] = nil
                    event.dispatcher(window)
                end)
            queued[window] = true
        end
        local function trigger_func(window, immediate)
            if type(window) == "boolean" and window then
                for win in event.target_iterator() do
                    if immediate then
                        event.dispatcher(window)
                    else
                        trigger_helper(window)
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
        fcstr.LuaString = tostring(value)
        return fcstr
    end

    function mixin_helper.boolean_to_error(object, method, ...)
        if not object[method .. "__"](object, ...) then
            error("'" .. object.MixinClass .. "." .. method .. "' has encountered an error.", 3)
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
                if attr == "StaticMethods" or (lookup[attr] and lookup[attr][nane]) then
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
        return function ()
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
package.preload["lunajson.decoder"] = package.preload["lunajson.decoder"] or function()
    local setmetatable, tonumber, tostring =
          setmetatable, tonumber, tostring
    local floor, inf =
          math.floor, math.huge
    local mininteger, tointeger =
          math.mininteger or nil, math.tointeger or nil
    local byte, char, find, gsub, match, sub =
          string.byte, string.char, string.find, string.gsub, string.match, string.sub
    local function _decode_error(pos, errmsg)
    	error("parse error at " .. pos .. ": " .. errmsg, 2)
    end
    local f_str_ctrl_pat
    if _VERSION == "Lua 5.1" then
    	
    	f_str_ctrl_pat = '[^\32-\255]'
    else
    	f_str_ctrl_pat = '[\0-\31]'
    end
    local _ENV = nil
    local function newdecoder()
    	local json, pos, nullv, arraylen, rec_depth
    	
    	
    	local dispatcher, f
    	
    	local function decode_error(errmsg)
    		return _decode_error(pos, errmsg)
    	end
    	
    	local function f_err()
    		decode_error('invalid value')
    	end
    	
    	
    	local function f_nul()
    		if sub(json, pos, pos+2) == 'ull' then
    			pos = pos+3
    			return nullv
    		end
    		decode_error('invalid value')
    	end
    	
    	local function f_fls()
    		if sub(json, pos, pos+3) == 'alse' then
    			pos = pos+4
    			return false
    		end
    		decode_error('invalid value')
    	end
    	
    	local function f_tru()
    		if sub(json, pos, pos+2) == 'rue' then
    			pos = pos+3
    			return true
    		end
    		decode_error('invalid value')
    	end
    	
    	
    	local radixmark = match(tostring(0.5), '[^0-9]')
    	local fixedtonumber = tonumber
    	if radixmark ~= '.' then
    		if find(radixmark, '%W') then
    			radixmark = '%' .. radixmark
    		end
    		fixedtonumber = function(s)
    			return tonumber(gsub(s, '.', radixmark))
    		end
    	end
    	local function number_error()
    		return decode_error('invalid number')
    	end
    	
    	local function f_zro(mns)
    		local num, c = match(json, '^(%.?[0-9]*)([-+.A-Za-z]?)', pos)
    		if num == '' then
    			if c == '' then
    				if mns then
    					return -0.0
    				end
    				return 0
    			end
    			if c == 'e' or c == 'E' then
    				num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    				if c == '' then
    					pos = pos + #num
    					if mns then
    						return -0.0
    					end
    					return 0.0
    				end
    			end
    			number_error()
    		end
    		if byte(num) ~= 0x2E or byte(num, -1) == 0x2E then
    			number_error()
    		end
    		if c ~= '' then
    			if c == 'e' or c == 'E' then
    				num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    			end
    			if c ~= '' then
    				number_error()
    			end
    		end
    		pos = pos + #num
    		c = fixedtonumber(num)
    		if mns then
    			c = -c
    		end
    		return c
    	end
    	
    	local function f_num(mns)
    		pos = pos-1
    		local num, c = match(json, '^([0-9]+%.?[0-9]*)([-+.A-Za-z]?)', pos)
    		if byte(num, -1) == 0x2E then
    			number_error()
    		end
    		if c ~= '' then
    			if c ~= 'e' and c ~= 'E' then
    				number_error()
    			end
    			num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    			if not num or c ~= '' then
    				number_error()
    			end
    		end
    		pos = pos + #num
    		c = fixedtonumber(num)
    		if mns then
    			c = -c
    			if c == mininteger and not find(num, '[^0-9]') then
    				c = mininteger
    			end
    		end
    		return c
    	end
    	
    	local function f_mns()
    		local c = byte(json, pos)
    		if c then
    			pos = pos+1
    			if c > 0x30 then
    				if c < 0x3A then
    					return f_num(true)
    				end
    			else
    				if c > 0x2F then
    					return f_zro(true)
    				end
    			end
    		end
    		decode_error('invalid number')
    	end
    	
    	local f_str_hextbl = {
    		0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7,
    		0x8, 0x9, inf, inf, inf, inf, inf, inf,
    		inf, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF,
    		__index = function()
    			return inf
    		end
    	}
    	setmetatable(f_str_hextbl, f_str_hextbl)
    	local f_str_escapetbl = {
    		['"']  = '"',
    		['\\'] = '\\',
    		['/']  = '/',
    		['b']  = '\b',
    		['f']  = '\f',
    		['n']  = '\n',
    		['r']  = '\r',
    		['t']  = '\t',
    		__index = function()
    			decode_error("invalid escape sequence")
    		end
    	}
    	setmetatable(f_str_escapetbl, f_str_escapetbl)
    	local function surrogate_first_error()
    		return decode_error("1st surrogate pair byte not continued by 2nd")
    	end
    	local f_str_surrogate_prev = 0
    	local function f_str_subst(ch, ucode)
    		if ch == 'u' then
    			local c1, c2, c3, c4, rest = byte(ucode, 1, 5)
    			ucode = f_str_hextbl[c1-47] * 0x1000 +
    			        f_str_hextbl[c2-47] * 0x100 +
    			        f_str_hextbl[c3-47] * 0x10 +
    			        f_str_hextbl[c4-47]
    			if ucode ~= inf then
    				if ucode < 0x80 then
    					if rest then
    						return char(ucode, rest)
    					end
    					return char(ucode)
    				elseif ucode < 0x800 then
    					c1 = floor(ucode / 0x40)
    					c2 = ucode - c1 * 0x40
    					c1 = c1 + 0xC0
    					c2 = c2 + 0x80
    					if rest then
    						return char(c1, c2, rest)
    					end
    					return char(c1, c2)
    				elseif ucode < 0xD800 or 0xE000 <= ucode then
    					c1 = floor(ucode / 0x1000)
    					ucode = ucode - c1 * 0x1000
    					c2 = floor(ucode / 0x40)
    					c3 = ucode - c2 * 0x40
    					c1 = c1 + 0xE0
    					c2 = c2 + 0x80
    					c3 = c3 + 0x80
    					if rest then
    						return char(c1, c2, c3, rest)
    					end
    					return char(c1, c2, c3)
    				elseif 0xD800 <= ucode and ucode < 0xDC00 then
    					if f_str_surrogate_prev == 0 then
    						f_str_surrogate_prev = ucode
    						if not rest then
    							return ''
    						end
    						surrogate_first_error()
    					end
    					f_str_surrogate_prev = 0
    					surrogate_first_error()
    				else
    					if f_str_surrogate_prev ~= 0 then
    						ucode = 0x10000 +
    						        (f_str_surrogate_prev - 0xD800) * 0x400 +
    						        (ucode - 0xDC00)
    						f_str_surrogate_prev = 0
    						c1 = floor(ucode / 0x40000)
    						ucode = ucode - c1 * 0x40000
    						c2 = floor(ucode / 0x1000)
    						ucode = ucode - c2 * 0x1000
    						c3 = floor(ucode / 0x40)
    						c4 = ucode - c3 * 0x40
    						c1 = c1 + 0xF0
    						c2 = c2 + 0x80
    						c3 = c3 + 0x80
    						c4 = c4 + 0x80
    						if rest then
    							return char(c1, c2, c3, c4, rest)
    						end
    						return char(c1, c2, c3, c4)
    					end
    					decode_error("2nd surrogate pair byte appeared without 1st")
    				end
    			end
    			decode_error("invalid unicode codepoint literal")
    		end
    		if f_str_surrogate_prev ~= 0 then
    			f_str_surrogate_prev = 0
    			surrogate_first_error()
    		end
    		return f_str_escapetbl[ch] .. ucode
    	end
    	
    	local f_str_keycache = setmetatable({}, {__mode="v"})
    	local function f_str(iskey)
    		local newpos = pos
    		local tmppos, c1, c2
    		repeat
    			newpos = find(json, '"', newpos, true)
    			if not newpos then
    				decode_error("unterminated string")
    			end
    			tmppos = newpos-1
    			newpos = newpos+1
    			c1, c2 = byte(json, tmppos-1, tmppos)
    			if c2 == 0x5C and c1 == 0x5C then
    				repeat
    					tmppos = tmppos-2
    					c1, c2 = byte(json, tmppos-1, tmppos)
    				until c2 ~= 0x5C or c1 ~= 0x5C
    				tmppos = newpos-2
    			end
    		until c2 ~= 0x5C
    		local str = sub(json, pos, tmppos)
    		pos = newpos
    		if iskey then
    			tmppos = f_str_keycache[str]
    			if tmppos then
    				return tmppos
    			end
    			tmppos = str
    		end
    		if find(str, f_str_ctrl_pat) then
    			decode_error("unescaped control string")
    		end
    		if find(str, '\\', 1, true) then
    			
    			
    			
    			
    			
    			str = gsub(str, '\\(.)([^\\]?[^\\]?[^\\]?[^\\]?[^\\]?)', f_str_subst)
    			if f_str_surrogate_prev ~= 0 then
    				f_str_surrogate_prev = 0
    				decode_error("1st surrogate pair byte not continued by 2nd")
    			end
    		end
    		if iskey then
    			f_str_keycache[tmppos] = str
    		end
    		return str
    	end
    	
    	
    	local function f_ary()
    		rec_depth = rec_depth + 1
    		if rec_depth > 1000 then
    			decode_error('too deeply nested json (> 1000)')
    		end
    		local ary = {}
    		pos = match(json, '^[ \n\r\t]*()', pos)
    		local i = 0
    		if byte(json, pos) == 0x5D then
    			pos = pos+1
    		else
    			local newpos = pos
    			repeat
    				i = i+1
    				f = dispatcher[byte(json,newpos)]
    				pos = newpos+1
    				ary[i] = f()
    				newpos = match(json, '^[ \n\r\t]*,[ \n\r\t]*()', pos)
    			until not newpos
    			newpos = match(json, '^[ \n\r\t]*%]()', pos)
    			if not newpos then
    				decode_error("no closing bracket of an array")
    			end
    			pos = newpos
    		end
    		if arraylen then
    			ary[0] = i
    		end
    		rec_depth = rec_depth - 1
    		return ary
    	end
    	
    	local function f_obj()
    		rec_depth = rec_depth + 1
    		if rec_depth > 1000 then
    			decode_error('too deeply nested json (> 1000)')
    		end
    		local obj = {}
    		pos = match(json, '^[ \n\r\t]*()', pos)
    		if byte(json, pos) == 0x7D then
    			pos = pos+1
    		else
    			local newpos = pos
    			repeat
    				if byte(json, newpos) ~= 0x22 then
    					decode_error("not key")
    				end
    				pos = newpos+1
    				local key = f_str(true)
    				
    				
    				
    				f = f_err
    				local c1, c2, c3 = byte(json, pos, pos+3)
    				if c1 == 0x3A then
    					if c2 ~= 0x20 then
    						f = dispatcher[c2]
    						newpos = pos+2
    					else
    						f = dispatcher[c3]
    						newpos = pos+3
    					end
    				end
    				if f == f_err then
    					newpos = match(json, '^[ \n\r\t]*:[ \n\r\t]*()', pos)
    					if not newpos then
    						decode_error("no colon after a key")
    					end
    					f = dispatcher[byte(json, newpos)]
    					newpos = newpos+1
    				end
    				pos = newpos
    				obj[key] = f()
    				newpos = match(json, '^[ \n\r\t]*,[ \n\r\t]*()', pos)
    			until not newpos
    			newpos = match(json, '^[ \n\r\t]*}()', pos)
    			if not newpos then
    				decode_error("no closing bracket of an object")
    			end
    			pos = newpos
    		end
    		rec_depth = rec_depth - 1
    		return obj
    	end
    	
    	dispatcher = { [0] =
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_str, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_mns, f_err, f_err,
    		f_zro, f_num, f_num, f_num, f_num, f_num, f_num, f_num,
    		f_num, f_num, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_ary, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_fls, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_nul, f_err,
    		f_err, f_err, f_err, f_err, f_tru, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_obj, f_err, f_err, f_err, f_err,
    		__index = function()
    			decode_error("unexpected termination")
    		end
    	}
    	setmetatable(dispatcher, dispatcher)
    	
    	local function decode(json_, pos_, nullv_, arraylen_)
    		json, pos, nullv, arraylen = json_, pos_, nullv_, arraylen_
    		rec_depth = 0
    		pos = match(json, '^[ \n\r\t]*()', pos)
    		f = dispatcher[byte(json, pos)]
    		pos = pos+1
    		local v = f()
    		if pos_ then
    			return v, pos
    		else
    			f, pos = find(json, '^[ \n\r\t]*', pos)
    			if pos ~= #json then
    				decode_error('json ended')
    			end
    			return v
    		end
    	end
    	return decode
    end
    return newdecoder
end
package.preload["lunajson.encoder"] = package.preload["lunajson.encoder"] or function()
    local error = error
    local byte, find, format, gsub, match = string.byte, string.find, string.format,  string.gsub, string.match
    local concat = table.concat
    local tostring = tostring
    local pairs, type = pairs, type
    local setmetatable = setmetatable
    local huge, tiny = 1/0, -1/0
    local f_string_esc_pat
    if _VERSION == "Lua 5.1" then
    	
    	f_string_esc_pat = '[^ -!#-[%]^-\255]'
    else
    	f_string_esc_pat = '[\0-\31"\\]'
    end
    local _ENV = nil
    local function newencoder()
    	local v, nullv
    	local i, builder, visited
    	local function f_tostring(v)
    		builder[i] = tostring(v)
    		i = i+1
    	end
    	local radixmark = match(tostring(0.5), '[^0-9]')
    	local delimmark = match(tostring(12345.12345), '[^0-9' .. radixmark .. ']')
    	if radixmark == '.' then
    		radixmark = nil
    	end
    	local radixordelim
    	if radixmark or delimmark then
    		radixordelim = true
    		if radixmark and find(radixmark, '%W') then
    			radixmark = '%' .. radixmark
    		end
    		if delimmark and find(delimmark, '%W') then
    			delimmark = '%' .. delimmark
    		end
    	end
    	local f_number = function(n)
    		if tiny < n and n < huge then
    			local s = format("%.17g", n)
    			if radixordelim then
    				if delimmark then
    					s = gsub(s, delimmark, '')
    				end
    				if radixmark then
    					s = gsub(s, radixmark, '.')
    				end
    			end
    			builder[i] = s
    			i = i+1
    			return
    		end
    		error('invalid number')
    	end
    	local doencode
    	local f_string_subst = {
    		['"'] = '\\"',
    		['\\'] = '\\\\',
    		['\b'] = '\\b',
    		['\f'] = '\\f',
    		['\n'] = '\\n',
    		['\r'] = '\\r',
    		['\t'] = '\\t',
    		__index = function(_, c)
    			return format('\\u00%02X', byte(c))
    		end
    	}
    	setmetatable(f_string_subst, f_string_subst)
    	local function f_string(s)
    		builder[i] = '"'
    		if find(s, f_string_esc_pat) then
    			s = gsub(s, f_string_esc_pat, f_string_subst)
    		end
    		builder[i+1] = s
    		builder[i+2] = '"'
    		i = i+3
    	end
    	local function f_table(o)
    		if visited[o] then
    			error("loop detected")
    		end
    		visited[o] = true
    		local tmp = o[0]
    		if type(tmp) == 'number' then
    			builder[i] = '['
    			i = i+1
    			for j = 1, tmp do
    				doencode(o[j])
    				builder[i] = ','
    				i = i+1
    			end
    			if tmp > 0 then
    				i = i-1
    			end
    			builder[i] = ']'
    		else
    			tmp = o[1]
    			if tmp ~= nil then
    				builder[i] = '['
    				i = i+1
    				local j = 2
    				repeat
    					doencode(tmp)
    					tmp = o[j]
    					if tmp == nil then
    						break
    					end
    					j = j+1
    					builder[i] = ','
    					i = i+1
    				until false
    				builder[i] = ']'
    			else
    				builder[i] = '{'
    				i = i+1
    				local tmp = i
    				for k, v in pairs(o) do
    					if type(k) ~= 'string' then
    						error("non-string key")
    					end
    					f_string(k)
    					builder[i] = ':'
    					i = i+1
    					doencode(v)
    					builder[i] = ','
    					i = i+1
    				end
    				if i > tmp then
    					i = i-1
    				end
    				builder[i] = '}'
    			end
    		end
    		i = i+1
    		visited[o] = nil
    	end
    	local dispatcher = {
    		boolean = f_tostring,
    		number = f_number,
    		string = f_string,
    		table = f_table,
    		__index = function()
    			error("invalid type value")
    		end
    	}
    	setmetatable(dispatcher, dispatcher)
    	function doencode(v)
    		if v == nullv then
    			builder[i] = 'null'
    			i = i+1
    			return
    		end
    		return dispatcher[type(v)](v)
    	end
    	local function encode(v_, nullv_)
    		v, nullv = v_, nullv_
    		i, builder, visited = 1, {}, {}
    		doencode(v)
    		return concat(builder)
    	end
    	return encode
    end
    return newencoder
end
package.preload["lunajson.sax"] = package.preload["lunajson.sax"] or function()
    local setmetatable, tonumber, tostring =
          setmetatable, tonumber, tostring
    local floor, inf =
          math.floor, math.huge
    local mininteger, tointeger =
          math.mininteger or nil, math.tointeger or nil
    local byte, char, find, gsub, match, sub =
          string.byte, string.char, string.find, string.gsub, string.match, string.sub
    local function _parse_error(pos, errmsg)
    	error("parse error at " .. pos .. ": " .. errmsg, 2)
    end
    local f_str_ctrl_pat
    if _VERSION == "Lua 5.1" then
    	
    	f_str_ctrl_pat = '[^\32-\255]'
    else
    	f_str_ctrl_pat = '[\0-\31]'
    end
    local type, unpack = type, table.unpack or unpack
    local open = io.open
    local _ENV = nil
    local function nop() end
    local function newparser(src, saxtbl)
    	local json, jsonnxt, rec_depth
    	local jsonlen, pos, acc = 0, 1, 0
    	
    	
    	local dispatcher, f
    	
    	if type(src) == 'string' then
    		json = src
    		jsonlen = #json
    		jsonnxt = function()
    			json = ''
    			jsonlen = 0
    			jsonnxt = nop
    		end
    	else
    		jsonnxt = function()
    			acc = acc + jsonlen
    			pos = 1
    			repeat
    				json = src()
    				if not json then
    					json = ''
    					jsonlen = 0
    					jsonnxt = nop
    					return
    				end
    				jsonlen = #json
    			until jsonlen > 0
    		end
    		jsonnxt()
    	end
    	local sax_startobject = saxtbl.startobject or nop
    	local sax_key = saxtbl.key or nop
    	local sax_endobject = saxtbl.endobject or nop
    	local sax_startarray = saxtbl.startarray or nop
    	local sax_endarray = saxtbl.endarray or nop
    	local sax_string = saxtbl.string or nop
    	local sax_number = saxtbl.number or nop
    	local sax_boolean = saxtbl.boolean or nop
    	local sax_null = saxtbl.null or nop
    	
    	local function tryc()
    		local c = byte(json, pos)
    		if not c then
    			jsonnxt()
    			c = byte(json, pos)
    		end
    		return c
    	end
    	local function parse_error(errmsg)
    		return _parse_error(acc + pos, errmsg)
    	end
    	local function tellc()
    		return tryc() or parse_error("unexpected termination")
    	end
    	local function spaces()
    		while true do
    			pos = match(json, '^[ \n\r\t]*()', pos)
    			if pos <= jsonlen then
    				return
    			end
    			if jsonlen == 0 then
    				parse_error("unexpected termination")
    			end
    			jsonnxt()
    		end
    	end
    	
    	local function f_err()
    		parse_error('invalid value')
    	end
    	
    	
    	local function generic_constant(target, targetlen, ret, sax_f)
    		for i = 1, targetlen do
    			local c = tellc()
    			if byte(target, i) ~= c then
    				parse_error("invalid char")
    			end
    			pos = pos+1
    		end
    		return sax_f(ret)
    	end
    	
    	local function f_nul()
    		if sub(json, pos, pos+2) == 'ull' then
    			pos = pos+3
    			return sax_null(nil)
    		end
    		return generic_constant('ull', 3, nil, sax_null)
    	end
    	
    	local function f_fls()
    		if sub(json, pos, pos+3) == 'alse' then
    			pos = pos+4
    			return sax_boolean(false)
    		end
    		return generic_constant('alse', 4, false, sax_boolean)
    	end
    	
    	local function f_tru()
    		if sub(json, pos, pos+2) == 'rue' then
    			pos = pos+3
    			return sax_boolean(true)
    		end
    		return generic_constant('rue', 3, true, sax_boolean)
    	end
    	
    	
    	local radixmark = match(tostring(0.5), '[^0-9]')
    	local fixedtonumber = tonumber
    	if radixmark ~= '.' then
    		if find(radixmark, '%W') then
    			radixmark = '%' .. radixmark
    		end
    		fixedtonumber = function(s)
    			return tonumber(gsub(s, '.', radixmark))
    		end
    	end
    	local function number_error()
    		return parse_error('invalid number')
    	end
    	
    	local function generic_number(mns)
    		local buf = {}
    		local i = 1
    		local is_int = true
    		local c = byte(json, pos)
    		pos = pos+1
    		local function nxt()
    			buf[i] = c
    			i = i+1
    			c = tryc()
    			pos = pos+1
    		end
    		if c == 0x30 then
    			nxt()
    			if c and 0x30 <= c and c < 0x3A then
    				number_error()
    			end
    		else
    			repeat nxt() until not (c and 0x30 <= c and c < 0x3A)
    		end
    		if c == 0x2E then
    			is_int = false
    			nxt()
    			if not (c and 0x30 <= c and c < 0x3A) then
    				number_error()
    			end
    			repeat nxt() until not (c and 0x30 <= c and c < 0x3A)
    		end
    		if c == 0x45 or c == 0x65 then
    			is_int = false
    			nxt()
    			if c == 0x2B or c == 0x2D then
    				nxt()
    			end
    			if not (c and 0x30 <= c and c < 0x3A) then
    				number_error()
    			end
    			repeat nxt() until not (c and 0x30 <= c and c < 0x3A)
    		end
    		if c and (0x41 <= c and c <= 0x5B or
    		          0x61 <= c and c <= 0x7B or
    		          c == 0x2B or c == 0x2D or c == 0x2E) then
    			number_error()
    		end
    		pos = pos-1
    		local num = char(unpack(buf))
    		num = fixedtonumber(num)
    		if mns then
    			num = -num
    			if num == mininteger and is_int then
    				num = mininteger
    			end
    		end
    		return sax_number(num)
    	end
    	
    	local function f_zro(mns)
    		local num, c = match(json, '^(%.?[0-9]*)([-+.A-Za-z]?)', pos)
    		if num == '' then
    			if pos > jsonlen then
    				pos = pos - 1
    				return generic_number(mns)
    			end
    			if c == '' then
    				if mns then
    					return sax_number(-0.0)
    				end
    				return sax_number(0)
    			end
    			if c == 'e' or c == 'E' then
    				num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    				if c == '' then
    					pos = pos + #num
    					if pos > jsonlen then
    						pos = pos - #num - 1
    						return generic_number(mns)
    					end
    					if mns then
    						return sax_number(-0.0)
    					end
    					return sax_number(0.0)
    				end
    			end
    			pos = pos-1
    			return generic_number(mns)
    		end
    		if byte(num) ~= 0x2E or byte(num, -1) == 0x2E then
    			pos = pos-1
    			return generic_number(mns)
    		end
    		if c ~= '' then
    			if c == 'e' or c == 'E' then
    				num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    			end
    			if c ~= '' then
    				pos = pos-1
    				return generic_number(mns)
    			end
    		end
    		pos = pos + #num
    		if pos > jsonlen then
    			pos = pos - #num - 1
    			return generic_number(mns)
    		end
    		c = fixedtonumber(num)
    		if mns then
    			c = -c
    		end
    		return sax_number(c)
    	end
    	
    	local function f_num(mns)
    		pos = pos-1
    		local num, c = match(json, '^([0-9]+%.?[0-9]*)([-+.A-Za-z]?)', pos)
    		if byte(num, -1) == 0x2E then
    			return generic_number(mns)
    		end
    		if c ~= '' then
    			if c ~= 'e' and c ~= 'E' then
    				return generic_number(mns)
    			end
    			num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    			if not num or c ~= '' then
    				return generic_number(mns)
    			end
    		end
    		pos = pos + #num
    		if pos > jsonlen then
    			pos = pos - #num
    			return generic_number(mns)
    		end
    		c = fixedtonumber(num)
    		if mns then
    			c = -c
    			if c == mininteger and not find(num, '[^0-9]') then
    				c = mininteger
    			end
    		end
    		return sax_number(c)
    	end
    	
    	local function f_mns()
    		local c = byte(json, pos) or tellc()
    		if c then
    			pos = pos+1
    			if c > 0x30 then
    				if c < 0x3A then
    					return f_num(true)
    				end
    			else
    				if c > 0x2F then
    					return f_zro(true)
    				end
    			end
    		end
    		parse_error("invalid number")
    	end
    	
    	local f_str_hextbl = {
    		0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7,
    		0x8, 0x9, inf, inf, inf, inf, inf, inf,
    		inf, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF,
    		__index = function()
    			return inf
    		end
    	}
    	setmetatable(f_str_hextbl, f_str_hextbl)
    	local f_str_escapetbl = {
    		['"']  = '"',
    		['\\'] = '\\',
    		['/']  = '/',
    		['b']  = '\b',
    		['f']  = '\f',
    		['n']  = '\n',
    		['r']  = '\r',
    		['t']  = '\t',
    		__index = function()
    			parse_error("invalid escape sequence")
    		end
    	}
    	setmetatable(f_str_escapetbl, f_str_escapetbl)
    	local function surrogate_first_error()
    		return parse_error("1st surrogate pair byte not continued by 2nd")
    	end
    	local f_str_surrogate_prev = 0
    	local function f_str_subst(ch, ucode)
    		if ch == 'u' then
    			local c1, c2, c3, c4, rest = byte(ucode, 1, 5)
    			ucode = f_str_hextbl[c1-47] * 0x1000 +
    			        f_str_hextbl[c2-47] * 0x100 +
    			        f_str_hextbl[c3-47] * 0x10 +
    			        f_str_hextbl[c4-47]
    			if ucode ~= inf then
    				if ucode < 0x80 then
    					if rest then
    						return char(ucode, rest)
    					end
    					return char(ucode)
    				elseif ucode < 0x800 then
    					c1 = floor(ucode / 0x40)
    					c2 = ucode - c1 * 0x40
    					c1 = c1 + 0xC0
    					c2 = c2 + 0x80
    					if rest then
    						return char(c1, c2, rest)
    					end
    					return char(c1, c2)
    				elseif ucode < 0xD800 or 0xE000 <= ucode then
    					c1 = floor(ucode / 0x1000)
    					ucode = ucode - c1 * 0x1000
    					c2 = floor(ucode / 0x40)
    					c3 = ucode - c2 * 0x40
    					c1 = c1 + 0xE0
    					c2 = c2 + 0x80
    					c3 = c3 + 0x80
    					if rest then
    						return char(c1, c2, c3, rest)
    					end
    					return char(c1, c2, c3)
    				elseif 0xD800 <= ucode and ucode < 0xDC00 then
    					if f_str_surrogate_prev == 0 then
    						f_str_surrogate_prev = ucode
    						if not rest then
    							return ''
    						end
    						surrogate_first_error()
    					end
    					f_str_surrogate_prev = 0
    					surrogate_first_error()
    				else
    					if f_str_surrogate_prev ~= 0 then
    						ucode = 0x10000 +
    						        (f_str_surrogate_prev - 0xD800) * 0x400 +
    						        (ucode - 0xDC00)
    						f_str_surrogate_prev = 0
    						c1 = floor(ucode / 0x40000)
    						ucode = ucode - c1 * 0x40000
    						c2 = floor(ucode / 0x1000)
    						ucode = ucode - c2 * 0x1000
    						c3 = floor(ucode / 0x40)
    						c4 = ucode - c3 * 0x40
    						c1 = c1 + 0xF0
    						c2 = c2 + 0x80
    						c3 = c3 + 0x80
    						c4 = c4 + 0x80
    						if rest then
    							return char(c1, c2, c3, c4, rest)
    						end
    						return char(c1, c2, c3, c4)
    					end
    					parse_error("2nd surrogate pair byte appeared without 1st")
    				end
    			end
    			parse_error("invalid unicode codepoint literal")
    		end
    		if f_str_surrogate_prev ~= 0 then
    			f_str_surrogate_prev = 0
    			surrogate_first_error()
    		end
    		return f_str_escapetbl[ch] .. ucode
    	end
    	local function f_str(iskey)
    		local pos2 = pos
    		local newpos
    		local str = ''
    		local bs
    		while true do
    			while true do
    				newpos = find(json, '[\\"]', pos2)
    				if newpos then
    					break
    				end
    				str = str .. sub(json, pos, jsonlen)
    				if pos2 == jsonlen+2 then
    					pos2 = 2
    				else
    					pos2 = 1
    				end
    				jsonnxt()
    				if jsonlen == 0 then
    					parse_error("unterminated string")
    				end
    			end
    			if byte(json, newpos) == 0x22 then
    				break
    			end
    			pos2 = newpos+2
    			bs = true
    		end
    		str = str .. sub(json, pos, newpos-1)
    		pos = newpos+1
    		if find(str, f_str_ctrl_pat) then
    			parse_error("unescaped control string")
    		end
    		if bs then
    			
    			
    			
    			
    			
    			str = gsub(str, '\\(.)([^\\]?[^\\]?[^\\]?[^\\]?[^\\]?)', f_str_subst)
    			if f_str_surrogate_prev ~= 0 then
    				f_str_surrogate_prev = 0
    				parse_error("1st surrogate pair byte not continued by 2nd")
    			end
    		end
    		if iskey then
    			return sax_key(str)
    		end
    		return sax_string(str)
    	end
    	
    	
    	local function f_ary()
    		rec_depth = rec_depth + 1
    		if rec_depth > 1000 then
    			parse_error('too deeply nested json (> 1000)')
    		end
    		sax_startarray()
    		spaces()
    		if byte(json, pos) == 0x5D then
    			pos = pos+1
    		else
    			local newpos
    			while true do
    				f = dispatcher[byte(json, pos)]
    				pos = pos+1
    				f()
    				newpos = match(json, '^[ \n\r\t]*,[ \n\r\t]*()', pos)
    				if newpos then
    					pos = newpos
    				else
    					newpos = match(json, '^[ \n\r\t]*%]()', pos)
    					if newpos then
    						pos = newpos
    						break
    					end
    					spaces()
    					local c = byte(json, pos)
    					pos = pos+1
    					if c == 0x2C then
    						spaces()
    					elseif c == 0x5D then
    						break
    					else
    						parse_error("no closing bracket of an array")
    					end
    				end
    				if pos > jsonlen then
    					spaces()
    				end
    			end
    		end
    		rec_depth = rec_depth - 1
    		return sax_endarray()
    	end
    	
    	local function f_obj()
    		rec_depth = rec_depth + 1
    		if rec_depth > 1000 then
    			parse_error('too deeply nested json (> 1000)')
    		end
    		sax_startobject()
    		spaces()
    		if byte(json, pos) == 0x7D then
    			pos = pos+1
    		else
    			local newpos
    			while true do
    				if byte(json, pos) ~= 0x22 then
    					parse_error("not key")
    				end
    				pos = pos+1
    				f_str(true)
    				newpos = match(json, '^[ \n\r\t]*:[ \n\r\t]*()', pos)
    				if newpos then
    					pos = newpos
    				else
    					spaces()
    					if byte(json, pos) ~= 0x3A then
    						parse_error("no colon after a key")
    					end
    					pos = pos+1
    					spaces()
    				end
    				if pos > jsonlen then
    					spaces()
    				end
    				f = dispatcher[byte(json, pos)]
    				pos = pos+1
    				f()
    				newpos = match(json, '^[ \n\r\t]*,[ \n\r\t]*()', pos)
    				if newpos then
    					pos = newpos
    				else
    					newpos = match(json, '^[ \n\r\t]*}()', pos)
    					if newpos then
    						pos = newpos
    						break
    					end
    					spaces()
    					local c = byte(json, pos)
    					pos = pos+1
    					if c == 0x2C then
    						spaces()
    					elseif c == 0x7D then
    						break
    					else
    						parse_error("no closing bracket of an object")
    					end
    				end
    				if pos > jsonlen then
    					spaces()
    				end
    			end
    		end
    		rec_depth = rec_depth - 1
    		return sax_endobject()
    	end
    	
    	dispatcher = { [0] =
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_str, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_mns, f_err, f_err,
    		f_zro, f_num, f_num, f_num, f_num, f_num, f_num, f_num,
    		f_num, f_num, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_ary, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_fls, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_nul, f_err,
    		f_err, f_err, f_err, f_err, f_tru, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_obj, f_err, f_err, f_err, f_err,
    	}
    	
    	local function run()
    		rec_depth = 0
    		spaces()
    		f = dispatcher[byte(json, pos)]
    		pos = pos+1
    		f()
    	end
    	local function read(n)
    		if n < 0 then
    			error("the argument must be non-negative")
    		end
    		local pos2 = (pos-1) + n
    		local str = sub(json, pos, pos2)
    		while pos2 > jsonlen and jsonlen ~= 0 do
    			jsonnxt()
    			pos2 = pos2 - (jsonlen - (pos-1))
    			str = str .. sub(json, pos, pos2)
    		end
    		if jsonlen ~= 0 then
    			pos = pos2+1
    		end
    		return str
    	end
    	local function tellpos()
    		return acc + pos
    	end
    	return {
    		run = run,
    		tryc = tryc,
    		read = read,
    		tellpos = tellpos,
    	}
    end
    local function newfileparser(fn, saxtbl)
    	local fp = open(fn)
    	local function gen()
    		local s
    		if fp then
    			s = fp:read(8192)
    			if not s then
    				fp:close()
    				fp = nil
    			end
    		end
    		return s
    	end
    	return newparser(gen, saxtbl)
    end
    return {
    	newparser = newparser,
    	newfileparser = newfileparser
    }
end
package.preload["lunajson.lunajson"] = package.preload["lunajson.lunajson"] or function()
    local newdecoder = require('lunajson.decoder')
    local newencoder = require('lunajson.encoder')
    local sax = require('lunajson.sax')


    return {
    	decode = newdecoder(),
    	encode = newencoder(),
    	newparser = sax.newparser,
    	newfileparser = sax.newfileparser,
    }
end
package.preload["library.utils"] = package.preload["library.utils"] or function()

    local utils = {}




    function utils.copy_table(t)
        if type(t) == "table" then
            local new = {}
            for k, v in pairs(t) do
                new[utils.copy_table(k)] = utils.copy_table(v)
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

    function utils.iterate_keys(t)
        local a, b, c = pairs(t)
        return function()
            c = a(b, c)
            return c
        end
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

    function utils.require_embedded(library_name)
        return require(library_name)
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
            return "This script uses " .. to_human_string(feature) .. "which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
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
    }

    function client.supports(feature)
        if features[feature].test == nil then
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
    return client
end
package.preload["library.general_library"] = package.preload["library.general_library"] or function()

    local library = {}
    local utils = require("library.utils")
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
        local success = false
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
        local osutils = finenv.EmbeddedLuaOSUtils and utils.require_embedded("luaosutils")
        local font_names = {}
        local add_to_table = function(for_user)
            local smufl_directory = calc_smufl_directory(for_user)
            local get_dirs = function()
                local options = finenv.UI():IsOnWindows() and "/b /ad" or "-1"
                if osutils then
                    return osutils.process.list_dir(smufl_directory, options)
                end

                local cmd = finenv.UI():IsOnWindows() and "dir " or "ls "
                local handle = io.popen(cmd .. options .. " \"" .. smufl_directory .. "\"")
                local retval = handle:read("*a")
                handle:close()
                return retval
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

    function library.get_smufl_metadata_file(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        local try_prefix = function(prefix, font_info)
            local file_path = prefix .. font_info.Name .. "/" .. font_info.Name .. ".json"
            return io.open(file_path, "r")
        end
        local user_file = try_prefix(calc_smufl_directory(true), font_info)
        if user_file then
            return user_file
        end
        return try_prefix(calc_smufl_directory(false), font_info)
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

    function library.simple_input(title, text)
        local return_value = finale.FCString()
        return_value.LuaString = ""
        local str = finale.FCString()
        local min_width = 160

        function format_ctrl(ctrl, h, w, st)
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
            str.LuaString = st
            ctrl:SetText(str)
        end

        title_width = string.len(title) * 6 + 54
        if title_width > min_width then
            min_width = title_width
        end
        text_width = string.len(text) * 6
        if text_width > min_width then
            min_width = text_width
        end

        str.LuaString = title
        local dialog = finale.FCCustomLuaWindow()
        dialog:SetTitle(str)
        local descr = dialog:CreateStatic(0, 0)
        format_ctrl(descr, 16, min_width, text)
        local input = dialog:CreateEdit(0, 20)
        format_ctrl(input, 20, min_width, "")
        dialog:CreateOkButton()
        dialog:CreateCancelButton()

        function callback(ctrl)
        end

        dialog:RegisterHandleCommand(callback)

        if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
            return_value.LuaString = input:GetText(return_value)

            return return_value.LuaString

        end
    end

    function library.is_finale_object(object)

        return object and type(object) == "userdata" and object.ClassName and object.GetClassID and true or false
    end

    function library.get_parent_class(classname)
        local class = finale[classname]
        if type(class) ~= "table" then return nil end
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
            for k, _ in pairs(class.__parent) do
                return tostring(k)
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

    function library.calc_script_name(include_extension)
        local fc_string = finale.FCString()
        if finenv.RunningLuaFilePath then

            fc_string.LuaString = finenv.RunningLuaFilePath()
        else


            fc_string:SetRunningLuaFilePath()
        end
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
package.preload["library.note_entry"] = package.preload["library.note_entry"] or function()

    local note_entry = {}

    function note_entry.get_music_region(entry)
        local exp_region = finale.FCMusicRegion()
        exp_region:SetCurrentSelection()
        exp_region.StartStaff = entry.Staff
        exp_region.EndStaff = entry.Staff
        exp_region.StartMeasure = entry.Measure
        exp_region.EndMeasure = entry.Measure
        exp_region.StartMeasurePos = entry.MeasurePos
        exp_region.EndMeasurePos = entry.MeasurePos
        return exp_region
    end


    local use_or_get_passed_in_entry_metrics = function(entry, entry_metrics)
        if entry_metrics then
            return entry_metrics, false
        end
        entry_metrics = finale.FCEntryMetrics()
        if entry_metrics:Load(entry) then
            return entry_metrics, true
        end
        return nil, false
    end

    function note_entry.get_evpu_notehead_height(entry)
        local highest_note = entry:CalcHighestNote(nil)
        local lowest_note = entry:CalcLowestNote(nil)
        local evpu_height = (2 + highest_note:CalcStaffPosition() - lowest_note:CalcStaffPosition()) * 12
        return evpu_height
    end

    function note_entry.get_top_note_position(entry, entry_metrics)
        local retval = -math.huge
        local loaded_here = false
        entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
        if nil == entry_metrics then
            return retval
        end
        if not entry:CalcStemUp() then
            retval = entry_metrics.TopPosition
        else
            local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
            if nil ~= cell_metrics then
                local evpu_height = note_entry.get_evpu_notehead_height(entry)
                local scaled_height = math.floor(((cell_metrics.StaffScaling * evpu_height) / 10000) + 0.5)
                retval = entry_metrics.BottomPosition + scaled_height
                cell_metrics:FreeMetrics()
            end
        end
        if loaded_here then
            entry_metrics:FreeMetrics()
        end
        return retval
    end

    function note_entry.get_bottom_note_position(entry, entry_metrics)
        local retval = math.huge
        local loaded_here = false
        entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
        if nil == entry_metrics then
            return retval
        end
        if entry:CalcStemUp() then
            retval = entry_metrics.BottomPosition
        else
            local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
            if nil ~= cell_metrics then
                local evpu_height = note_entry.get_evpu_notehead_height(entry)
                local scaled_height = math.floor(((cell_metrics.StaffScaling * evpu_height) / 10000) + 0.5)
                retval = entry_metrics.TopPosition - scaled_height
                cell_metrics:FreeMetrics()
            end
        end
        if loaded_here then
            entry_metrics:FreeMetrics()
        end
        return retval
    end

    function note_entry.calc_widths(entry)
        local left_width = 0
        local right_width = 0
        for note in each(entry) do
            local note_width = note:CalcNoteheadWidth()
            if note_width > 0 then
                if note:CalcRightsidePlacement() then
                    if note_width > right_width then
                        right_width = note_width
                    end
                else
                    if note_width > left_width then
                        left_width = note_width
                    end
                end
            end
        end
        return left_width, right_width
    end




    function note_entry.calc_left_of_all_noteheads(entry)
        if entry:CalcStemUp() then
            return 0
        end
        local left, right = note_entry.calc_widths(entry)
        return -left
    end

    function note_entry.calc_left_of_primary_notehead(entry)
        return 0
    end

    function note_entry.calc_center_of_all_noteheads(entry)
        local left, right = note_entry.calc_widths(entry)
        local width_centered = (left + right) / 2
        if not entry:CalcStemUp() then
            width_centered = width_centered - left
        end
        return width_centered
    end

    function note_entry.calc_center_of_primary_notehead(entry)
        local left, right = note_entry.calc_widths(entry)
        if entry:CalcStemUp() then
            return left / 2
        end
        return right / 2
    end

    function note_entry.calc_stem_offset(entry)
        if not entry:CalcStemUp() then
            return 0
        end
        local left, right = note_entry.calc_widths(entry)
        return left
    end

    function note_entry.calc_right_of_all_noteheads(entry)
        local left, right = note_entry.calc_widths(entry)
        if entry:CalcStemUp() then
            return left + right
        end
        return right
    end

    function note_entry.calc_note_at_index(entry, note_index)
        local x = 0
        for note in each(entry) do
            if x == note_index then
                return note
            end
            x = x + 1
        end
        return nil
    end

    function note_entry.stem_sign(entry)
        if entry:CalcStemUp() then
            return 1
        end
        return -1
    end

    function note_entry.duplicate_note(note)
        local new_note = note.Entry:AddNewNote()
        if nil ~= new_note then
            new_note.Displacement = note.Displacement
            new_note.RaiseLower = note.RaiseLower
            new_note.Tie = note.Tie
            new_note.TieBackwards = note.TieBackwards
        end
        return new_note
    end

    function note_entry.delete_note(note)
        local entry = note.Entry
        if nil == entry then
            return false
        end

        finale.FCAccidentalMod():EraseAt(note)
        finale.FCCrossStaffMod():EraseAt(note)
        finale.FCDotMod():EraseAt(note)
        finale.FCNoteheadMod():EraseAt(note)
        finale.FCPercussionNoteMod():EraseAt(note)
        finale.FCTablatureNoteMod():EraseAt(note)
        finale.FCPerformanceMod():EraseAt(note)
        if finale.FCTieMod then
            finale.FCTieMod(finale.TIEMODTYPE_TIESTART):EraseAt(note)
            finale.FCTieMod(finale.TIEMODTYPE_TIEEND):EraseAt(note)
        end
        return entry:DeleteNote(note)
    end

    function note_entry.make_rest(entry)
        local articulations = entry:CreateArticulations()
        for articulation in each(articulations) do
            articulation:DeleteData()
        end
        if entry:IsNote() then
            while entry.Count > 0 do
                note_entry.delete_note(entry:GetItemAt(0))
            end
        end
        entry:MakeRest()
        return true
    end

    function note_entry.calc_pitch_string(note)
        local pitch_string = finale.FCString()
        local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
        local key_signature = cell:GetKeySignature()
        note:GetString(pitch_string, key_signature, false, false)
        return pitch_string
    end

    function note_entry.calc_spans_number_of_octaves(entry)
        local top_note = entry:CalcHighestNote(nil)
        local bottom_note = entry:CalcLowestNote(nil)
        local displacement_diff = top_note.Displacement - bottom_note.Displacement
        local num_octaves = math.ceil(displacement_diff / 7)
        return num_octaves
    end

    function note_entry.add_augmentation_dot(entry)

        entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
    end

    function note_entry.remove_augmentation_dot(entry)
        if entry.Duration <= 0 then
            return false
        end
        local lowest_order_bit = 1
        if bit32.band(entry.Duration, lowest_order_bit) == 0 then

            lowest_order_bit = bit32.bxor(bit32.band(entry.Duration, entry.Duration - 1), entry.Duration)
        end

        local new_value = bit32.band(entry.Duration, bit32.bnot(lowest_order_bit))
        if new_value ~= 0 then
            entry.Duration = new_value
            return true
        end
        return false
    end

    function note_entry.get_next_same_v(entry)
        local next_entry = entry:Next()
        if entry.Voice2 then
            if (nil ~= next_entry) and next_entry.Voice2 then
                return next_entry
            end
            return nil
        end
        if entry.Voice2Launch then
            while (nil ~= next_entry) and next_entry.Voice2 do
                next_entry = next_entry:Next()
            end
        end
        return next_entry
    end

    function note_entry.hide_stem(entry)
        local stem = finale.FCCustomStemMod()
        stem:SetNoteEntry(entry)
        stem:UseUpStemData(entry:CalcStemUp())
        if stem:LoadFirst() then
            stem.ShapeID = 0
            stem:Save()
        else
            stem.ShapeID = 0
            stem:SaveNew()
        end
    end

    function note_entry.rest_offset(entry, offset)
        if entry:IsNote() then
            return false
        end
        local rest_prop = "OtherRestPosition"
        if entry.Duration >= finale.BREVE then
            rest_prop = "DoubleWholeRestPosition"
        elseif entry.Duration >= finale.WHOLE_NOTE then
            rest_prop = "WholeRestPosition"
        elseif entry.Duration >= finale.HALF_NOTE then
            rest_prop = "HalfRestPosition"
        end
        entry:MakeMovableRest()
        local rest = entry:GetItemAt(0)
        local curr_staffpos = rest:CalcStaffPosition()
        local staff_spec = finale.FCCurrentStaffSpec()
        staff_spec:LoadForEntry(entry)
        local total_offset = staff_spec[rest_prop] + offset - curr_staffpos
        entry:SetRestDisplacement(entry:GetRestDisplacement() + total_offset)
        return true
    end
    return note_entry
end
package.preload["library.enigma_string"] = package.preload["library.enigma_string"] or function()

    local enigma_string = {}
    local starts_with_font_command = function(string)
        local text_cmds = {"^font", "^Font", "^fontMus", "^fontTxt", "^fontNum", "^size", "^nfx"}
        for i, text_cmd in ipairs(text_cmds) do
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

    function enigma_string.remove_inserts(fcstring, replace_with_generic)


        local text_cmds = {
            "^arranger", "^composer", "^copyright", "^date", "^description", "^fdate", "^filename", "^lyricist", "^page",
            "^partname", "^perftime", "^subtitle", "^time", "^title", "^totpages",
        }
        local lua_string = fcstring.LuaString
        for i, text_cmd in ipairs(text_cmds) do
            local starts_at = string.find(lua_string, text_cmd, 1, true)
            while nil ~= starts_at do
                local replace_with = ""
                if replace_with_generic then
                    replace_with = string.sub(text_cmd, 2)
                end
                local after_text_at = starts_at + string.len(text_cmd)
                local next_at = string.find(lua_string, ")", after_text_at, true)
                if nil ~= next_at then
                    next_at = next_at + 1
                else
                    next_at = starts_at
                end
                lua_string = string.sub(lua_string, 1, starts_at - 1) .. replace_with .. string.sub(lua_string, next_at)
                starts_at = string.find(lua_string, text_cmd, 1, true)
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
package.preload["library.expression"] = package.preload["library.expression"] or function()

    local expression = {}
    local library = require("library.general_library")
    local note_entry = require("library.note_entry")
    local enigma_string = require("library.enigma_string")

    function expression.get_music_region(exp_assign)
        if not exp_assign:IsSingleStaffAssigned() then
            return nil
        end
        local exp_region = finale.FCMusicRegion()
        exp_region:SetCurrentSelection()
        exp_region.StartStaff = exp_assign.Staff
        exp_region.EndStaff = exp_assign.Staff
        exp_region.StartMeasure = exp_assign.Measure
        exp_region.EndMeasure = exp_assign.Measure
        exp_region.StartMeasurePos = exp_assign.MeasurePos
        exp_region.EndMeasurePos = exp_assign.MeasurePos
        return exp_region
    end

    function expression.get_associated_entry(exp_assign)
        local exp_region = expression.get_music_region(exp_assign)
        if nil == exp_region then
            return nil
        end
        for entry in eachentry(exp_region) do
            if (0 == exp_assign.LayerAssignment) or (entry.LayerNumber == exp_assign.LayerAssignment) then
                if not entry:GetGraceNote() then
                    return entry
                end
            end
        end
        return nil
    end

    function expression.calc_handle_offset_for_smart_shape(exp_assign)
        local manual_horizontal = exp_assign.HorizontalPos
        local def_horizontal = 0
        local alignment_offset = 0
        local exp_def = exp_assign:CreateTextExpressionDef()
        if nil ~= exp_def then
            def_horizontal = exp_def.HorizontalOffset
        end
        local exp_entry = expression.get_associated_entry(exp_assign)
        local ent_position = exp_entry and exp_entry.ManualPosition or 0
        if (nil ~= exp_entry) and (nil ~= exp_def) then
            if finale.ALIGNHORIZ_LEFTOFALLNOTEHEAD == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_left_of_all_noteheads(exp_entry)
            elseif finale.ALIGNHORIZ_LEFTOFPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_left_of_primary_notehead(exp_entry)
            elseif finale.ALIGNHORIZ_STEM == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_stem_offset(exp_entry)
            elseif finale.ALIGNHORIZ_CENTERPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_center_of_primary_notehead(exp_entry)
            elseif finale.ALIGNHORIZ_CENTERALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_center_of_all_noteheads(exp_entry)
            elseif finale.ALIGNHORIZ_RIGHTALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_right_of_all_noteheads(exp_entry)
            end
        end
        return (manual_horizontal + def_horizontal + ent_position + alignment_offset)
    end

    function expression.calc_text_width(expression_def, expand_tags)
        expand_tags = expand_tags or false
        local fcstring = expression_def:CreateTextString()
        if expand_tags then
            enigma_string.expand_value_tag(fcstring, expression_def:GetPlaybackTempoValue())
        end
        local retval = enigma_string.calc_text_advance_width(fcstring)
        return retval
    end

    function expression.is_for_current_part(exp_assign, current_part)
        current_part = current_part or library.get_current_part()
        if current_part:IsScore() and exp_assign.ScoreAssignment then
            return true
        elseif current_part:IsPart() and exp_assign.PartAssignment then
            return true
        end
        return false
    end

    function expression.is_dynamic(exp)
        if not exp:IsShape() and exp.Visible and exp.StaffGroupID == 0 then
            local cat_id = exp:CreateTextExpressionDef().CategoryID
            if cat_id == finale.DEFAULTCATID_DYNAMICS then
                return true
            end
            local cd = finale.FCCategoryDef()
            cd:Load(cat_id)
            if cd.Type == finale.DEFAULTCATID_DYNAMICS then
                return true
            end
            local exp_name = cd:CreateName().LuaString
            if string.find(exp_name, "Dynamic") or string.find(exp_name, "dynamic") then
                return true
            end
        end
        return false
    end

    function expression.resync_expressions_for_category(category_id)
        for expression_def in loadall(finale.FCTextExpressionDefs()) do
            if expression_def.CategoryID == category_id then
                expression.resync_to_category(expression_def)
            end
        end
    end

    function expression.resync_to_category(expression_def)
        local cat = finale.FCCategoryDef()
        cat:Load(expression_def.CategoryID)

        if expression_def.UseCategoryFont then
            local str = expression_def:CreateTextString()
            if str then
                str:ReplaceCategoryFonts(cat, finale.CATEGORYMODE_TEXT, false)
                str:ReplaceCategoryFonts(cat, finale.CATEGORYMODE_MUSIC, false)
                str:ReplaceCategoryFonts(cat, finale.CATEGORYMODE_NUMBER, false)
                expression_def:SaveTextString(str)
            end
        end
        if expression_def.UseCategoryPos then
            local pos_props = {
                "HorizontalJustification",
                "HorizontalAlignmentPoint",
                "HorizontalOffset",
                "VerticalAlignmentPoint",
                "VerticalBaselineOffset",
                "VerticalEntryOffset"
            }
            for _, prop in pairs(pos_props) do
                expression_def[prop] = cat[prop]
            end
            expression_def:Save()
        end
    end
    return expression
end
function plugindef()
    finaleplugin.RequireScore = false
    finaleplugin.RequireSelection = false
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "2.1.2"
    finaleplugin.Date = "2023-03-25"
    finaleplugin.CategoryTags = "Report"
    finaleplugin.Id = "9c05a4c4-9508-4608-bb1b-2819cba96101"
    finaleplugin.AdditionalMenuOptions = [[
        Import Document Options from JSON...
    ]]
    finaleplugin.AdditionalPrefixes = [[
        action = "import"
    ]]
    finaleplugin.RevisionNotes = [[
        v2.1.2      Resync expression definitions
        v2.1.1      Add music spacing allotments (requires RGPLua v0.66)
        v2.0.1      Add ability to import
        v1.2.1      Add Grid/Guide snap-tos; better organization of SmartShapes
        v1.1.2      First public release
    ]]
    finaleplugin.Notes = [[
        While other plugins exist that let you copy document options directly from one document to another,
        this script saves the options from the current document in an organized human-readable form, as a
        JSON file. You can then use a diff program to compare the JSON files generated from
        two Finale documents, or you can keep track of how the settings in a document have changed
        over time. The script will also let you import settings from a full or partial JSON file.
        Please see https://url.sherber.com/finalelua/options-as-json for more information.

        The focus is on document-specific settings, rather than program-wide ones, and in particular on
        the ones that affect the look of a document. Most of these come from the Document Options dialog
        in Finale, although some come from the Category Designer, the Page Format dialog, and the
        SmartShape menu.
        All physical measurements are given in EVPUs, except for a couple of values that Finale always
        displays as spaces. (1 EVPU is 1/288 of an inch, 1/24 of a space, or 1/4 of a point.) So if your
        measurement units are set to EVPUs, the values given here should match what you see in Finale.
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/document_options_as_json.hash"
    return "Save Document Options as JSON...", "", "Saves all current document options to a JSON file"
end
action = action or "export"
local debug = {
    raw_categories = false,
    raw_units = false
}
local mixin = require('library.mixin')
local json = require("lunajson.lunajson")
local expr = require("library.expression")
local fcstr = function(str)
    return mixin.FCMString():SetLuaString(str)
end
function simplify_finale_version(ver)
    if type(ver) == "number" then
        return ver < 10000 and ver or (ver - 10000)
    else
        return nil
    end
end
function get_file_options_tag()
    local temp_table = {}
    if debug.raw_categories then table.insert(temp_table, "raw prefs") end
    if debug.raw_units then table.insert(temp_table, "raw units") end
    local result = table.concat(temp_table, ", ")
    if #result > 0 then result = " - " .. result end
    return result
end
function get_path_and_file(document)
    local file_name = mixin.FCMString()
    local path_name = mixin.FCMString()
    local file_path = mixin.FCMString()
    document:GetPath(file_path)
    file_path:SplitToPathAndFile(path_name, file_name)
    return path_name, file_name
end
function do_file_open_dialog(document)
    local text_extension = ".json"
    local filter_text = "JSON files"
    local path_name, file_name = get_path_and_file(document)
    local open_dialog = mixin.FCMFileOpenDialog(finenv.UI())
            :SetWindowTitle(fcstr("Open JSON Settings"))
            :SetInitFolder(path_name)
            :AddFilter(fcstr("*" .. text_extension), fcstr(filter_text))
    if not open_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    open_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end
function confirm_file_import(meta)

    if meta == nil then return true end
    local col_1_width = 85
    local width_factor = 6
    local row_height = 17
    local max_string_length = 0
    local dialog = mixin.FCMCustomWindow()
        :SetTitle("Confirm Import")
    local t = {
        { "Import these settings?" },
        {},
        { "Music File", meta.File or meta.MusicFile},
        { "Date", meta.Date },
        { "Finale Version", simplify_finale_version(meta.FinaleVersion) },
        { "Description", meta.Description }
    }
    for row, labels in ipairs(t) do
        for col, label in ipairs(labels) do
            max_string_length = math.max(max_string_length, string.len(label or ""))
            dialog:CreateStatic((col - 1) * col_1_width, (row - 1) * row_height)
                :SetText(label)
        end
    end
    for ctrl in each(dialog) do
        ctrl:SetWidth(max_string_length * width_factor)
    end

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return dialog:ExecuteModal(nil) == finale.EXECMODAL_OK
end
function do_save_as_dialog(document)
    local text_extension = ".json"
    local filter_text = "JSON files"
    local path_name, file_name = get_path_and_file(document)
    local full_file_name = file_name.LuaString
    local extension = mixin.FCMString()
                            :SetLuaString(file_name.LuaString)
                            :ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("." .. extension.LuaString))
    end
    file_name:AppendLuaString(" settings")
            :AppendLuaString(get_file_options_tag())
            :AppendLuaString(text_extension)
    local save_dialog = mixin.FCMFileSaveAsDialog(finenv.UI())
            :SetWindowTitle(fcstr("Save As"))
            :AddFilter(fcstr("*" .. text_extension), fcstr(filter_text))
            :SetInitFolder(path_name)
            :SetFileName(file_name)
    if not save_dialog:Execute() then
        return nil
    end
    save_dialog:AssureFileExtension(text_extension)
    local selected_file_name = finale.FCString()
    save_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end
function get_description()
    local dialog = mixin.FCMCustomWindow():SetTitle("Save As")
    dialog:CreateStatic(0, 0):SetText("Settings Description"):SetWidth(120)
    dialog:CreateEdit(0, 17, "input"):SetWidth(360)
    dialog:CreateOkButton()
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        return dialog:GetControl("input"):GetText()
    else
        return ""
    end
end

function getter_name(...) return "Get" .. table.concat{...} end
function setter_name(...) return "Set" .. table.concat{...} end
function delete_from_table(prefs_table, exclusions)
    if not prefs_table or not exclusions then return end
    for _, e in pairs(exclusions) do prefs_table[e] = nil end
end
function add_props_to_table(prefs_table, prefs_obj, tag, exclusions)
    if tag then
        prefs_table[tag] = {}
        prefs_table = prefs_table[tag]
    end
    for k, v in pairs(dumpproperties(prefs_obj)) do
        prefs_table[k] = v
    end
    delete_from_table(prefs_table, exclusions)
end
function set_props_from_table(prefs_table, prefs_obj, exclusions)
    prefs_table = prefs_table or {}
    delete_from_table(prefs_table, exclusions)
    for k, v in pairs(prefs_table) do
        if type(v) ~= "table" then
            local setter = prefs_obj[setter_name(k)]
            if setter then setter(prefs_obj, v) end
        end
    end
end
function handle_page_format_prefs(prefs_obj, prefs_table, load)
    local SCORE, PARTS = "Score", "Parts"
    if load then
        prefs_obj:LoadScore()
        add_props_to_table(prefs_table, prefs_obj, SCORE)
        prefs_obj:LoadParts()
        add_props_to_table(prefs_table, prefs_obj, PARTS)
    else
        prefs_obj:LoadScore()
        set_props_from_table(prefs_table[SCORE], prefs_obj)
        prefs_obj:Save()
        prefs_obj:LoadParts()
        set_props_from_table(prefs_table[PARTS], prefs_obj)
        prefs_obj:Save()
    end
end
function handle_name_position_prefs(prefs_obj, prefs_table, load)
    local FULL, ABBREVIATED = "Full", "Abbreviated"
    if load then
        prefs_obj:LoadFull()
        add_props_to_table(prefs_table, prefs_obj, FULL)
        prefs_obj:LoadAbbreviated()
        add_props_to_table(prefs_table, prefs_obj, ABBREVIATED)
    else
        prefs_obj:LoadFull()
        set_props_from_table(prefs_table[FULL], prefs_obj)
        prefs_obj:Save()
        prefs_obj:LoadAbbreviated()
        set_props_from_table(prefs_table[ABBREVIATED], prefs_obj)
        prefs_obj:Save()
    end
end
function handle_layer_prefs(prefs_obj, prefs_table, load)
    for i = 0, 3 do
        prefs_obj:Load(i)
        local layer_name = "Layer" .. i + 1
        if load then
            add_props_to_table(prefs_table, prefs_obj, layer_name)
        else
            set_props_from_table(prefs_table[layer_name], prefs_obj)
            prefs_obj:Save()
        end
    end
end
local FONT_EXCLUSIONS = { "EnigmaStyles", "IsSMuFLFont", "Size" }
function handle_font_prefs(prefs_obj, prefs_table, load)
    local font_pref_types = {
        [finale.FONTPREF_MUSIC]              = 'Music',
        [finale.FONTPREF_KEYSIG]             = 'KeySignatures',
        [finale.FONTPREF_CLEF]               = 'Clefs',
        [finale.FONTPREF_TIMESIG]            = 'TimeSignatureScore',
        [finale.FONTPREF_CHORDSYMBOL]        = 'ChordSymbols',
        [finale.FONTPREF_CHORDALTERATION]    = 'ChordAlterations',
        [finale.FONTPREF_ENDING]             = 'EndingRepeats',
        [finale.FONTPREF_TUPLET]             = 'Tuplets',
        [finale.FONTPREF_TEXTBLOCK]          = 'TextBlocks',
        [finale.FONTPREF_LYRICSVERSE]        = 'LyricVerses',
        [finale.FONTPREF_LYRICSCHORUS]       = 'LyricChoruses',
        [finale.FONTPREF_LYRICSSECTION]      = 'LyricSections',
        [finale.FONTPREF_MULTIMEASUREREST]   = 'MultimeasureRests',
        [finale.FONTPREF_CHORDSUFFIX]        = 'ChordSuffixes',
        [finale.FONTPREF_EXPRESSION]         = 'Expressions',
        [finale.FONTPREF_REPEAT]             = 'TextRepeats',
        [finale.FONTPREF_CHORDFRETBOARD]     = 'ChordFretboards',
        [finale.FONTPREF_FLAG]               = 'Flags',
        [finale.FONTPREF_ACCIDENTAL]         = 'Accidentals',
        [finale.FONTPREF_ALTERNATESLASH]     = 'AlternateNotation',
        [finale.FONTPREF_ALTERNATENUMBER]    = 'AlternateNotationNumbers',
        [finale.FONTPREF_REST]               = 'Rests',
        [finale.FONTPREF_REPEATDOT]          = 'RepeatDots',
        [finale.FONTPREF_NOTEHEAD]           = 'Noteheads',
        [finale.FONTPREF_AUGMENTATIONDOT]    = 'AugmentationDots',
        [finale.FONTPREF_TIMESIGPLUS]        = 'TimeSignaturePlusScore',
        [finale.FONTPREF_ARTICULATION]       = 'Articulations',
        [finale.FONTPREF_DEFTABLATURE]       = 'Tablature',
        [finale.FONTPREF_PERCUSSION]         = 'PercussionNoteheads',
        [finale.FONTPREF_8VA]                = 'SmartShape8va',
        [finale.FONTPREF_MEASURENUMBER]      = 'MeasureNumbers',
        [finale.FONTPREF_STAFFNAME]          = 'StaffNames',
        [finale.FONTPREF_ABRVSTAFFNAME]      = 'StaffNamesAbbreviated',
        [finale.FONTPREF_GROUPNAME]          = 'GroupNames',
        [finale.FONTPREF_8VB]                = 'SmartShape8vb',
        [finale.FONTPREF_15MA]               = 'SmartShape15ma',
        [finale.FONTPREF_15MB]               = 'SmartShape15mb',
        [finale.FONTPREF_TR]                 = 'SmartShapeTrill',
        [finale.FONTPREF_WIGGLE]             = 'SmartShapeWiggle',
        [finale.FONTPREF_ABRVGROUPNAME]      = 'GroupNamesAbbreviated',
        [finale.FONTPREF_GUITARBENDFULL]     = 'GuitarBendFull',
        [finale.FONTPREF_GUITARBENDNUMBER]   = 'GuitarBendNumber',
        [finale.FONTPREF_GUITARBENDFRACTION] = 'GuitarBendFraction',
        [finale.FONTPREF_TIMESIG_PARTS]      = 'TimeSignatureParts',
        [finale.FONTPREF_TIMESIGPLUS_PARTS]  = 'TimeSignaturePlusParts',
    }
    for pref_type, tag in pairs(font_pref_types) do
        if load then
            prefs_obj:LoadFontPrefs(pref_type)
            add_props_to_table(prefs_table, prefs_obj, tag, FONT_EXCLUSIONS)
        else
            set_props_from_table(prefs_table[tag], prefs_obj, FONT_EXCLUSIONS)
            prefs_obj:SaveFontPrefs(pref_type)
        end
    end
end
function handle_tie_placement_prefs(prefs_obj, prefs_table, load)
    local tie_placement_types = {
        [finale.TIEPLACE_OVERINNER]      = "Over/Inner",
        [finale.TIEPLACE_UNDERINNER]     = "Under/Inner",
        [finale.TIEPLACE_OVEROUTERNOTE]  = "Over/Outer/Note",
        [finale.TIEPLACE_UNDEROUTERNOTE] = "Under/Outer/Note",
        [finale.TIEPLACE_OVEROUTERSTEM]  = "Over/Outer/Stem",
        [finale.TIEPLACE_UNDEROUTERSTEM] = "Under/Outer/Stem"
    }
    local prop_names = {
        "HorizontalStart",
        "VerticalStart",
        "HorizontalEnd",
        "VerticalEnd"
    }
    for placement_type, tag in pairs(tie_placement_types) do
        prefs_obj:Load(placement_type)
        if load then
            local t = {}
            for _, name in pairs(prop_names) do
                t[name] = prefs_obj[getter_name(name)](prefs_obj, placement_type)
            end
            prefs_table[tag] = t
        else
            local t = prefs_table[tag]
            for _, name in pairs(prop_names) do
                prefs_obj[setter_name(name)](prefs_obj, placement_type, t[name])
            end
            prefs_obj:Save()
        end
    end
end
function handle_tie_contour_prefs(prefs_obj, prefs_table, load)
    local tie_contour_types = {
        [finale.TCONTOURIDX_SHORT]   = "Short",
        [finale.TCONTOURIDX_MEDIUM]  = "Medium",
        [finale.TCONTOURIDX_LONG]    = "Long",
        [finale.TCONTOURIDX_TIEENDS] = "TieEnds"
    }
    local prop_names = {
        "Span",
        "LeftRelativeInset",
        "LeftRawRelativeInset",
        "LeftHeight",
        "LeftFixedInset",
        "RightRelativeInset",
        "RightRawRelativeInset",
        "RightHeight",
        "RightFixedInset",
    }

    for contour_type, tag in pairs(tie_contour_types) do
        prefs_obj:Load(contour_type)
        if load then
            local t = {}
            for _, name in pairs(prop_names) do
                t[name] = prefs_obj[getter_name(name)](prefs_obj, contour_type)
            end
            prefs_table[tag] = t
        else
            local t = prefs_table[tag]
            for _, name in pairs(prop_names) do
                prefs_obj[setter_name(name)](prefs_obj, contour_type, t[name])
            end
            prefs_obj:Save()
        end
    end
end
function handle_base_prefs(prefs_obj, prefs_table, load, exclusions)
    exclusions = exclusions or {}
    prefs_obj:Load(1)
    if load then
        add_props_to_table(prefs_table, prefs_obj, nil, exclusions)
    else
        set_props_from_table(prefs_table, prefs_obj, exclusions)
        prefs_obj:Save()
    end
end
function handle_tie_prefs(prefs_obj, prefs_table, load)
    handle_base_prefs(prefs_obj, prefs_table, load)
    local TIE_CONTOURS, TIE_PLACEMENT = "TieContours", "TiePlacement"
    if load then
        local function load_sub_prefs(sub_prefs, handler, tag)
            local t = {}
            handler(sub_prefs, t, true)
            prefs_table[tag] = t
        end
        load_sub_prefs(prefs_obj:CreateTieContourPrefs(), handle_tie_contour_prefs, TIE_CONTOURS)
        load_sub_prefs(prefs_obj:CreateTiePlacementPrefs(), handle_tie_placement_prefs, TIE_PLACEMENT)
    else
        handle_tie_contour_prefs(prefs_obj:CreateTieContourPrefs(), prefs_table[TIE_CONTOURS], false)
        handle_tie_placement_prefs(prefs_obj:CreateTiePlacementPrefs(), prefs_table[TIE_PLACEMENT], false)
    end
end
function handle_category_prefs(prefs_obj, prefs_table, load)
    local font = finale.FCFontInfo()
    local font_types = { "Text", "Music", "Number" }
    local FONTS, FONT_INFO, TYPE = "Fonts", "FontInfo", "Type"
    local EXCLUSIONS = { "ID" }
    local function get_cat_tag(cat) return cat:CreateName().LuaString:gsub(" ", "") end
    local function humanize(tag) return string.gsub(tag, "(%l)(%u)", "%1 %2") end
    prefs_obj:LoadAll()
    if load then
        for raw_cat in each(prefs_obj) do
            if raw_cat:IsDefaultMiscellaneous() then
                goto cat_continue
            end
            local raw_cat_tag = get_cat_tag(raw_cat)
            add_props_to_table(prefs_table, raw_cat, raw_cat_tag, EXCLUSIONS)
            local font_table = {}
            prefs_table[raw_cat_tag][FONTS] = font_table
            for _, font_type in pairs(font_types) do
                if raw_cat[getter_name(font_type, FONT_INFO)](raw_cat, font) then
                    add_props_to_table(font_table, font, font_type, FONT_EXCLUSIONS)
                end
            end
            ::cat_continue::
        end
    else
        local function populate_raw_cat(cat_values, raw_cat)
            set_props_from_table(cat_values, raw_cat, EXCLUSIONS)
            for _, font_type in pairs(font_types) do
                if raw_cat[getter_name(font_type, FONT_INFO)](raw_cat, font) then
                    set_props_from_table(cat_values[FONTS][font_type], font, FONT_EXCLUSIONS)
                    raw_cat[setter_name(font_type, FONT_INFO)](raw_cat, font)
                end
            end
        end
        for cat_tag, cat_values in pairs(prefs_table) do
            local this_cat = nil
            for raw_cat in each(prefs_obj) do
                if get_cat_tag(raw_cat) == cat_tag then
                    this_cat = raw_cat
                    break
                end
            end
            if this_cat then
                populate_raw_cat(cat_values, this_cat)
                this_cat:Save()
            else
                local new_cat = finale.FCCategoryDef()
                local cat_type = cat_values[TYPE]
                new_cat:Load(cat_type)
                new_cat:SetName(mixin.FCMString():SetLuaString(humanize(cat_tag)))
                populate_raw_cat(cat_values, new_cat)
                new_cat:SaveNewWithType(cat_type)
            end
        end
    end
end
function handle_smart_shape_prefs(prefs_obj, prefs_table, load)
    handle_base_prefs(prefs_obj, prefs_table, load)
    local contour_prefs = prefs_obj:CreateSlurContourPrefs()
    local span_types = { 'Short', 'Medium', 'Long', 'ExtraLong' }
    local prop_names = { 'Span', 'Inset', 'Height' }
    local SLUR_CONTOURS = "SlurContours"
    if load then
        local contour_table = {}
        prefs_table[SLUR_CONTOURS] = contour_table

        for _, type in pairs(span_types) do
            local t = {}
            for _, name in pairs(prop_names) do
                t[name] = contour_prefs[getter_name(type, name)](contour_prefs)
            end
            contour_table[type] = t
        end
    else
        for _, type in pairs(span_types) do
            for _, name in pairs(prop_names) do
                local contour_table = prefs_table[SLUR_CONTOURS]
                if contour_table and contour_table[type] and contour_table[type][name] then
                    contour_prefs[setter_name(type, name)](contour_prefs, contour_table[type][name])
                end
            end
        end
        contour_prefs:Save()
    end
end
function handle_grid_prefs(prefs_obj, prefs_table, load)
    local snap_items = {
        [finale.SNAPITEM_BRACKETS ] = "Brackets",
        [finale.SNAPITEM_CHORDS ] = "Chords",
        [finale.SNAPITEM_EXPRESSIONS ] = "Expressions",
        [finale.SNAPITEM_FRETBOARDS ] = "Fretboards",
        [finale.SNAPITEM_GRAPHICSMOVE ] = "GraphicsMove",
        [finale.SNAPITEM_GRAPHICSSIZING ] = "GraphicsSizing",
        [finale.SNAPITEM_MEASURENUMBERS ] = "MeasureNumbers",
        [finale.SNAPITEM_REPEATS ] = "Repeats",
        [finale.SNAPITEM_SPECIALTOOLS ] = "SpecialTools",
        [finale.SNAPITEM_STAFFNAMES ] = "StaffNames",
        [finale.SNAPITEM_STAVES ] = "Staves",
        [finale.SNAPITEM_TEXTBLOCKMOVE ] = "TextBlockMove",
        [finale.SNAPITEM_TEXTBLOCKSIZING ] = "TextBlockSizing",
    }
    local SNAP_TO_GRID, SNAP_TO_GUIDE = "SnapToGrid", "SnapToGuide"
    handle_base_prefs(prefs_obj, prefs_table, load, { "HorizontalGuideCount", "VerticalGuideCount" })
    if load then
        prefs_table[SNAP_TO_GRID] = {}
        prefs_table[SNAP_TO_GUIDE] = {}
        for item, name in pairs(snap_items) do
            prefs_table[SNAP_TO_GRID][name] = prefs_obj:GetGridSnapToItem(item)
            prefs_table[SNAP_TO_GUIDE][name] = prefs_obj:GetGuideSnapToItem(item)
        end
    else
        for item, name in pairs(snap_items) do
            prefs_obj:SetGridSnapToItem(item, prefs_table[SNAP_TO_GRID][name])
            prefs_obj:SetGuideSnapToItem(item, prefs_table[SNAP_TO_GUIDE][name])
        end
        prefs_obj:Save()
    end
end
function handle_music_spacing_prefs(prefs_obj, prefs_table, load)
    handle_base_prefs(prefs_obj, prefs_table, load, { "ScalingValue" })
end
function handle_allotment_prefs(prefs_obj, prefs_table, load)
    if load then
        for a in loadall(prefs_obj) do
            table.insert(prefs_table, { Duration = a.ItemNo, Width = a.Width })
        end
    else

        for a in loadall(prefs_obj) do
            a:DeleteData()
        end
        for _, a in ipairs(prefs_table) do
            local new_allotment = finale.FCAllotment()
            new_allotment.Width = a.Width
            new_allotment:SaveAs(a.Duration)
        end
    end
end
local raw_pref_definitions = {
    { prefs = finale.FCAllotments, handler = handle_allotment_prefs },
    { prefs = finale.FCCategoryDefs, handler = handle_category_prefs },
    { prefs = finale.FCChordPrefs },
    { prefs = finale.FCDistancePrefs },
    { prefs = finale.FCFontInfo, handler = handle_font_prefs },
    { prefs = finale.FCGridsGuidesPrefs, handler = handle_grid_prefs },
    { prefs = finale.FCGroupNamePositionPrefs, handler = handle_name_position_prefs },
    { prefs = finale.FCLayerPrefs, handler = handle_layer_prefs },
    { prefs = finale.FCLyricsPrefs },
    { prefs = finale.FCMiscDocPrefs },
    { prefs = finale.FCMultiMeasureRestPrefs },
    { prefs = finale.FCMusicCharacterPrefs },
    { prefs = finale.FCMusicSpacingPrefs, handler = handle_music_spacing_prefs },
    { prefs = finale.FCPageFormatPrefs, handler = handle_page_format_prefs },
    { prefs = finale.FCPianoBracePrefs },
    { prefs = finale.FCRepeatPrefs },
    { prefs = finale.FCSizePrefs },
    { prefs = finale.FCSmartShapePrefs, handler = handle_smart_shape_prefs },
    { prefs = finale.FCStaffNamePositionPrefs, handler = handle_name_position_prefs },
    { prefs = finale.FCTiePrefs, handler = handle_tie_prefs },
    { prefs = finale.FCTupletPrefs },
}
local function instantiate_prefs()
    for _, obj in pairs(raw_pref_definitions) do
        if type(obj.prefs) == "table" then
            local ok, prefs = pcall(function() return obj.prefs() end)
            obj.prefs = ok and prefs or nil
        end
    end
end
function load_all_raw_prefs()
    instantiate_prefs()
    local result = {}

    for _, obj in pairs(raw_pref_definitions) do
        if obj.prefs then
            local tag = obj.prefs:ClassName()
            if obj.handler == nil then
                obj.prefs:Load(1)
                add_props_to_table(result, obj.prefs, tag)
            else
                result[tag] = {}
                obj.handler(obj.prefs, result[tag], true)
            end
            if not debug.raw_units then
                normalize_units_for_raw_section(result[tag], tag)
            end
        end
    end
    return result
end
function save_all_raw_prefs(prefs_table)
    instantiate_prefs()
    for _, obj in pairs(raw_pref_definitions) do
        if obj.prefs then
            local tag = obj.prefs:ClassName()
            denormalize_units_for_raw_section(prefs_table[tag], tag)
            if obj.handler == nil then
                obj.prefs:Load(1)
                set_props_from_table(prefs_table[tag], obj.prefs)
                obj.prefs:Save()
            else
                obj.handler(obj.prefs, prefs_table[tag], false)
            end
        end
    end
    for cat in loadall(finale.FCCategoryDefs()) do
        expr.resync_expressions_for_category(cat.ID)
    end
end
local transform_definitions = {
    Accidentals = {
        FCDistancePrefs  = { "^Accidental" },
        FCMusicSpacingPrefs = { "AccidentalsGutter" },
        FCMusicCharacterPrefs = {
            "SymbolNatural", "SymbolFlat", "SymbolSharp", "SymbolDoubleFlat",
            "SymbolDoubleSharp", "SymbolPar."
        },
    },
    AlternateNotation = {
        FCDistancePrefs = { "^Alternate" },
        FCMusicCharacterPrefs = {
            "VerticalTwoMeasureRepeatOffset", ".Slash",
            "SymbolOneBarRepeat", "SymbolTwoBarRepeat",
        },
    },
    AugmentationDots = {
        FCMiscDocPrefs = { "AdjustDotForMultiVoices" },
        FCMusicCharacterPrefs = { "SymbolAugmentationDot" },
        FCDistancePrefs = { "^AugmentationDot" }
    },
    Barlines = {
        FCDistancePrefs = { "^Barline" },
        FCSizePrefs = { "Barline." },
        FCMiscDocPrefs = { ".Barline" }
    },
    Beams = {
        FCDistancePrefs = { "Beam." },
        FCSizePrefs = { "Beam." },
        FCMiscDocPrefs = { "Beam.", "IncludeRestsInFour", "AllowFloatingRests" }
    },
    Chords = {
        FCChordPrefs = { "." },
        FCMusicCharacterPrefs = { "Chord." },
        FCMiscDocPrefs = { "Chord.", "Fretboard." }
    },
    Clefs = {
        FCMiscDocPrefs = { "ClefResize", ".Clef" },
        FCDistancePrefs = { "^Clef" }
    },
    Flags = {
        FCMusicCharacterPrefs = { ".Flag", "VerticalSecondaryGroupAdjust" }
    },
    Fonts = {
        FCFontInfo = {
            "^Lyric", "^Text", "^Time", ".Names", "Noteheads$", "^Chord",
            "^Alternate", "Dots$", "EndingRepeats",  "MeasureNumbers",
            "Tablature",  "Accidentals",  "Flags", "Rests", "Clefs",
            "KeySignatures", "MultimeasureRests",
            "Tuplets", "Articulations", "Expressions"
        }
    },
    GraceNotes = {
        FCSizePrefs = { "Grace." },
        FCDistancePrefs = { "GraceNoteSpacing" },
        FCMiscDocPrefs = { "Grace." },
    },
    GridsAndGuides = {
        FCGridsGuidesPrefs = { "." }
    },
    KeySignatures = {
        FCDistancePrefs = { "^Key" },
        FCMusicCharacterPrefs = { "^SymbolKey" },
        FCMiscDocPrefs = { "^Key", "CourtesyKeySigAtSystemEnd" }
    },
    Layers = {
        FCLayerPrefs = { "." },
        FCMiscDocPrefs = { "ConsolidateRestsAcrossLayers" }
    },
    LinesAndCurves = {
        FCSizePrefs = { "^Ledger", "EnclosureThickness", "StaffLineThickness", "ShapeSlurTipWidth" },
        FCMiscDocPrefs = { "CurveResolution" }
    },
    Lyrics = {
        FCLyricsPrefs = { "." }
    },
    MultimeasureRests = {
        FCMultiMeasureRestPrefs = { "." }
    },
    MusicSpacing = {
        FCMusicSpacingPrefs = { "!Gutter$" },
        FCMiscDocPrefs = { "ScaleManualNotePositioning" },
        ["FCAllotments>Allotments"] = { "." }
    },
    NotesAndRests = {
        FCMiscDocPrefs = { "UseNoteShapes", "CrossStaffNotesInOriginal" },
        FCDistancePrefs = { "^Space" },
        FCMusicCharacterPrefs = { "^Symbol.*Rest$", "^Symbol.*Notehead$", "^Vertical.*Rest$"}
    },
    PianoBracesAndBrackets = {
        FCPianoBracePrefs = { "." },
        FCDistancePrefs = { "GroupBracketDefaultDistance" }
    },
    Repeats = {
        FCRepeatPrefs = { "." },
        FCMusicCharacterPrefs = { "RepeatDot$" }
    },
    Stems = {
        FCSizePrefs = { "Stem." },
        FCDistancePrefs = { "StemVerticalNoteheadOffset" },
        FCMiscDocPrefs = { "UseStemConnections", "DisplayReverseStemming" }
    },
    Text = {
        FCMiscDocPrefs = { "DateFormat", "SecondsInTimeStamp", "TextTabCharacters" },
    },
    Ties = {
        FCTiePrefs = { "." }
    },
    TimeSignatures = {
        FCMiscDocPrefs = { ".TimeSig", "TimeSigCompositeDecimals" },
        FCMusicCharacterPrefs = { ".TimeSig" },
        FCDistancePrefs = { "^TimeSig" },
    },
    Tuplets = {
        FCTupletPrefs = { "." }
    },
    Categories = {
        FCCategoryDefs = { "." }
    },
    PageFormat = {
        FCPageFormatPrefs = { "." }
    },
    SmartShapes = {
        FCSmartShapePrefs = { "^Symbol", "^Hairpin", "^Line", "HookLength", "OctavesAsText", "ID$" },
        FCMusicCharacterPrefs = { ".Octave", "SymbolTrill", "SymbolWiggle" },
        ["FCFontInfo>Fonts"] = { "^SmartShape" },
        ["FCSmartShapePrefs>SmartSlur"] = { "Slur." },
        ["FCSmartShapePrefs>GuitarBend"] = { "GuitarBend[^D]" },
        ["FCFontInfo>GuitarBend>Fonts"] = { "^Guitar" }
    },
    NamePositions = {
        ["FCGroupNamePositionPrefs>GroupNames"] = { "." },
        ["FCStaffNamePositionPrefs>StaffNames"] = { "." },
    },
    DefaultMusicFont = {
        ["FCFontInfo/Music"] = { "." }
    }
}
function is_pattern(s) return string.find(s, "[^%a%d]") end
function matches_negatable_pattern(s, pattern)
    local negate = pattern:sub(1, 1) == '!'
    if negate then pattern = pattern:sub(2) end
    local found = string.find(s, pattern)
    return (found ~= nil) ~= negate
end
function transform_to_friendly(all_raw_prefs)
    local function copy_items(source_table, dest_table, all_defs)
        local target
        local function copy_matching(pattern, category)
            local source = source_table[category];
            if string.find(category, "/") then
                local main, sub = string.match(category, "([%a%d]+)/([%a%d]+)")
                source = source_table[main][sub]
            end
            if not source then return end
            for k, v in pairs(source) do
                if matches_negatable_pattern(k, pattern) then target[k] = v end
            end
        end
        for category, locators in pairs(all_defs) do
            target = dest_table
            if string.find(category, ">") then
                for dest_menu in string.gmatch(category, ">(%a+)") do
                    if target[dest_menu] == nil then target[dest_menu] = {} end
                    target = target[dest_menu]
                end
                category = string.match(category, "^%a+")
            end

            for _, locator in pairs(locators) do
                if is_pattern(locator) then
                    copy_matching(locator, category)
                else
                    target[locator] = source_table[category][locator]
                end
            end
        end
    end
    local result = {}
    for transformed_category, all_defs in pairs(transform_definitions) do
        result[transformed_category] = {}
        copy_items(all_raw_prefs, result[transformed_category], all_defs)
    end
    return result
end
function transform_to_raw(prefs_to_import)
    local function copy_matching(import_items, raw_items, pattern)
        if not import_items then return end
        if raw_items[1] and import_items[1] then

            while #raw_items > 0 do
                table.remove(raw_items)
            end
            for k, v in ipairs(import_items) do
                raw_items[k] = v
            end
        else
            for k, _ in pairs(raw_items) do
                if matches_negatable_pattern(k, pattern) then
                    if type(raw_items[k]) == "table" then
                        copy_matching(import_items[k], raw_items[k], ".")
                    elseif import_items[k] ~= nil then
                        raw_items[k] = import_items[k]
                    end
                end
            end
        end
    end
    local function copy_section(import_items, raw_items, locators)
        if raw_items then
            for _, locator in pairs(locators) do
                if not is_pattern(locator) then
                    locator = "^" .. locator .. "$"
                end
                copy_matching(import_items, raw_items, locator)
            end
        end
    end
    local raw_prefs = load_all_raw_prefs()
    for import_cat, import_values in pairs(prefs_to_import) do
        local transform_defs = transform_definitions[import_cat]
        if transform_defs then
            for raw_cat, locators in pairs(transform_defs) do
                local source = import_values
                local dest = raw_prefs[raw_cat]
                if string.find(raw_cat, ">") then
                    local first = true
                    for segment in string.gmatch(raw_cat, "[%a%d]+") do
                        if first then
                            dest = raw_prefs[segment]
                            first = false
                        else
                            source = source and source[segment]
                        end
                    end
                elseif string.find(raw_cat, "/") then
                    for segment in string.gmatch(raw_cat, "[%a%d]+") do
                        dest = raw_prefs[segment] or dest[segment]
                    end
                end
                copy_section(source, dest, locators)
            end
        end
    end

    local cat_defs_to_import = prefs_to_import["Categories"]
    if cat_defs_to_import then
        local raw_cat_defs = raw_prefs["FCCategoryDefs"]
        for k, v in pairs(cat_defs_to_import) do
            if not raw_cat_defs[k] then raw_cat_defs[k] = v end
        end
    end
    return raw_prefs
end
local norm_func_selectors = {
    FCDistancePrefs = {
        BarlineDoubleSpace = "d64",
        BarlineFinalSpace = "d64",
        StemVerticalNoteheadOffset = "d64"
    },
    FCGridsGuidesPrefs = {
        GravityZoneSize = "d64",
        GridDistance = "d64"
    },
    FCLyricsPrefs = {
        WordExtLineThickness = "d64"
    },
    FCMiscDocPrefs = {
        FretboardsResizeFraction = "d10000"
    },
    FCMusicCharacterPrefs = {
        DefaultStemLift = "d64",
        ["[HV].+Flag[UD]"] = "d64",
    },
    FCPageFormatPrefs = {
        SystemStaffHeight = "d16"
    },
    FCPianoBracePrefs = {
        ["."] = "d10000"
    },
    FCRepeatPrefs = {
        ["Thickness$"] = "d64",
        SpaceBetweenLines = "d64",
    },
    FCSizePrefs = {
        ["Thickness$"] = "d64",
        ShapeSlurTipWidth = "d10000",
    },
    FCSmartShapePrefs = {
        EngraverSlurMaxAngle = "d100",
        EngraverSlurMaxLift = "d64",
        EngraverSlurMaxStretchFixed = "d64",
        EngraverSlurMaxStretchPercent = "d100",
        EngraverSlurSymmetryPercent = "d100",
        HairpinLineWidth = "d64",
        ["^LineWidth$"] = "d64",
        SlurTipWidth = "d10000",
        Inset = "d20.48",
    },
    FCTiePrefs = {
        TipWidth = "d10000",
        ["tRelativeInset"] = "m100"
    },
    FCTupletPrefs = {
        BracketThickness = "d64",
        MaxSlope = "d10"
    }
}
function modify_units_for_selected(t, pattern, op)
    local operation, operand = string.match(op, "(.)(.+)")
    for key, value in pairs(t) do
        if type(value) == "table" then
            modify_units_for_selected(value, pattern, op)
        elseif string.find(key, pattern) then
            local new_value = operation == "m" and (value * operand) or (value / operand)
            t[key] = new_value
        end
    end
end
function modify_units_for_raw_section(section_table, tag, invert)
    local selectors = norm_func_selectors[tag]
    if selectors then
        for pattern, op in pairs(selectors) do
            if invert then
                op = (op:sub(1, 1) == "m" and "d" or "m") .. op:sub(2)
            end
            modify_units_for_selected(section_table, pattern, op)
        end
    end
end
function normalize_units_for_raw_section(section_table, tag)
    modify_units_for_raw_section(section_table, tag, false)
end
function denormalize_units_for_raw_section(section_table, tag)
    modify_units_for_raw_section(section_table, tag, true)
end
function get_as_ordered_json(t, indent_level, in_array)
    local function get_last_key(this_table)
        local result
        for k, _ in pairsbykeys(this_table) do result = k end
        return result
    end
    local function quote_and_escape(s)
        s = string.gsub(s, "\\", "\\\\")
        s = string.gsub(s, '"', '\\"')
        return string.format('"%s"', s)
    end
    local function has_entries(this_table)
        for _ in pairs(this_table) do return true end
        return false
    end

    indent_level = indent_level or 0
    local result = {}
    table.insert(result, (in_array and '[' or '{') .. '\n')
    indent_level = indent_level + 1
    local indent = string.rep(" ", indent_level * 2)
    local last_key = get_last_key(t)
    for key, val in pairsbykeys(t) do
        local maybe_comma_plus_newline = key ~= last_key and ',\n' or '\n'
        local maybe_element_name = in_array and '' or quote_and_escape(key) .. ': '
        if type(val) == "table" and has_entries(val) then
            local val_is_array = val[1] ~= nil
            local new_line = table.concat({
                indent,
                maybe_element_name,
                get_as_ordered_json(val, indent_level, val_is_array),
                indent,
                val_is_array and ']' or '}',
                maybe_comma_plus_newline
            })
            table.insert(result, new_line)
        elseif type(val) == "string" or type(val) == "number" or type(val) == "boolean" then
            local new_line = table.concat({
                indent,
                maybe_element_name,
                type(val) == "string" and quote_and_escape(val) or tostring(val),
                maybe_comma_plus_newline
            })
            table.insert(result, new_line)
        end
    end
    if indent_level == 1 then
        table.insert(result, "}")
    end
    return table.concat(result)
end
function insert_header(prefs_table, document, description)
    local file_path = finale.FCString()
    document:GetPath(file_path)
    local key = "@Meta"
    prefs_table[key] = {
        MusicFile = file_path.LuaString,
        Date =  os.date(),
        FinaleVersion = simplify_finale_version(finenv.FinaleVersion),
        PluginVersion = finaleplugin.Version,
        Description = description
    }
    if debug.raw_categories then
        prefs_table[key].Transformed = false
    end
    if not debug.raw_units then
        prefs_table[key].DefaultUnit = "ev"
    end
end
function get_current_document()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    return documents:FindCurrent()
end
function open_file(file_path, mode)
    local file = io.open(file_path, mode)
    if not file then
        finenv.UI():AlertError("Unable to open " .. file_path .. ". Please check folder permissions.", "")
    else
        return file
    end
end
function options_import_from_json()
    local file_to_open = do_file_open_dialog(get_current_document())
    if file_to_open then
        local file = open_file(file_to_open, "r")
        if file then
            local prefs_json = file:read("*a")
            file:close()

            local prefs_to_import
            local ok, err_msg = pcall(function() prefs_to_import = json.decode(prefs_json) end)
            if not ok then
                err_msg = err_msg or "Unknown error"
                err_msg = err_msg:gsub("^.-%d:", "")
                finenv.UI():AlertError(err_msg, "JSON Error")
                return
            end

            if confirm_file_import(prefs_to_import["@Meta"]) then
                local raw_prefs = transform_to_raw(prefs_to_import)
                save_all_raw_prefs(raw_prefs)
                finenv.UI():AlertInfo("Done.", "Import Settings")
            end
        end
    end
end
function options_save_as_json()
    local document = get_current_document()
    local file_to_write = do_save_as_dialog(document)
    if file_to_write then
        local file = open_file(file_to_write, "w")
        if file then
            local raw_prefs = load_all_raw_prefs()
            local prefs_to_save = debug.raw_categories and raw_prefs or transform_to_friendly(raw_prefs)
            insert_header(prefs_to_save, document, get_description())
            file:write(get_as_ordered_json(prefs_to_save))
            file:close()
        end
    end
end
if action == "export" then
    options_save_as_json()
elseif action == "import" then
    options_import_from_json()
end

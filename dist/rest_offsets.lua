__imports = __imports or {}
__import_results = __import_results or {}
function require(item)
    if not __imports[item] then
        error("module '" .. item .. "' not found")
    end
    if __import_results[item] == nil then
        __import_results[item] = __imports[item]()
        if __import_results[item] == nil then
            __import_results[item] = true
        end
    end
    return __import_results[item]
end
__imports["mixin.FCMControl"] = __imports["mixin.FCMControl"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")

    local parent = setmetatable({}, {__mode = "kv"})
    local private = setmetatable({}, {__mode = "k"})
    local props = {}
    local temp_str = finale.FCString()

    function props:Init()
        private[self] = private[self] or {}
    end

    function props:GetParent()
        return parent[self]
    end

    function props:RegisterParent(window)
        mixin.assert_argument(window, {"FCMCustomWindow", "FCMCustomLuaWindow"}, 2)
        if parent[self] then
            error("This method is for internal use only.", 2)
        end
        parent[self] = window
    end












    for method, valid_types in pairs({
        Enable = {"boolean", "nil"},
        Visible = {"boolean", "nil"},
        Left = "number",
        Top = "number",
        Height = "number",
        Width = "number",
    }) do
        props["Get" .. method] = function(self)
            if mixin.FCMControl.UseStoredState(self) then
                return private[self][method]
            end
            return self["Get" .. method .. "_"](self)
        end
        props["Set" .. method] = function(self, value)
            mixin.assert_argument(value, valid_types, 2)
            if mixin.FCMControl.UseStoredState(self) then
                private[self][method] = value
            else

                if (method == "Enable" or method == "Visible") and finenv.UI():IsOnMac() and finenv.MajorVersion == 0 and finenv.MinorVersion < 63 then
                    self:GetText_(temp_str)
                    self:SetText_(temp_str)
                end
                self["Set" .. method .. "_"](self, value)
            end
        end
    end

    function props:GetText(str)
        mixin.assert_argument(str, {"nil", "FCString"}, 2)
        if not str then
            str = temp_str
        end
        if mixin.FCMControl.UseStoredState(self) then
            str.LuaString = private[self].Text
        else
            self:GetText_(str)
        end
        return str.LuaString
    end

    function props:SetText(str)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        if type(str) ~= "userdata" then
            temp_str.LuaString = tostring(str)
            str = temp_str
        end
        if mixin.FCMControl.UseStoredState(self) then
            private[self].Text = str.LuaString
        else
            self:SetText_(str)
        end
    end

    function props:UseStoredState()
        local parent = self:GetParent()
        return mixin.is_instance_of(parent, "FCMCustomLuaWindow") and parent:GetRestoreControlState() and not parent:WindowExists() and parent:HasBeenShown()
    end

    function props:StoreState()
        self:GetText_(temp_str)
        private[self].Text = temp_str.LuaString
        private[self].Enable = self:GetEnable_()
        private[self].Visible = self:GetVisible_()
        private[self].Left = self:GetLeft_()
        private[self].Top = self:GetTop_()
        private[self].Height = self:GetHeight_()
        private[self].Width = self:GetWidth_()
    end

    function props:RestoreState()
        self:SetEnable_(private[self].Enable)
        self:SetVisible_(private[self].Visible)
        self:SetLeft_(private[self].Left)
        self:SetTop_(private[self].Top)
        self:SetHeight_(private[self].Height)
        self:SetWidth_(private[self].Width)

        temp_str.LuaString = private[self].Text
        self:SetText_(temp_str)
    end


    props.AddHandleCommand, props.RemoveHandleCommand = mixin_helper.create_standard_control_event("HandleCommand")
    return props
end
__imports["mixin.FCMCtrlButton"] = __imports["mixin.FCMCtrlButton"] or function()



    local mixin_helper = require("library.mixin_helper")
    local props = {}
    mixin_helper.disable_methods(props, "AddHandleCheckChange", "RemoveHandleCheckChange")
    return props
end
__imports["mixin.FCMCtrlCheckbox"] = __imports["mixin.FCMCtrlCheckbox"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local props = {}
    local trigger_check_change
    local each_last_check_change

    function props:SetCheck(checked)
        mixin.assert_argument(checked, "number", 2)
        self:SetCheck_(checked)
        trigger_check_change(self)
    end



    props.AddHandleCheckChange, props.RemoveHandleCheckChange, trigger_check_change, each_last_check_change =
        mixin_helper.create_custom_control_change_event(


            {name = "last_check", get = "GetCheck_", initial = 0})
    return props
end
__imports["mixin.FCMCtrlDataList"] = __imports["mixin.FCMCtrlDataList"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local props = {}
    local temp_str = finale.FCString()

    function props:AddColumn(title, columnwidth)
        mixin.assert_argument(title, {"string", "number", "FCString"}, 2)
        mixin.assert_argument(columnwidth, "number", 3)
        if type(title) ~= "userdata" then
            temp_str.LuaString = tostring(title)
            title = temp_str
        end
        self:AddColumn_(title, columnwidth)
    end

    function props:SetColumnTitle(columnindex, title)
        mixin.assert_argument(columnindex, "number", 2)
        mixin.assert_argument(title, {"string", "number", "FCString"}, 3)
        if type(title) ~= "userdata" then
            temp_str.LuaString = tostring(title)
            title = temp_str
        end
        self:SetColumnTitle_(columnindex, title)
    end


    props.AddHandleCheck, props.RemoveHandleCheck = mixin_helper.create_standard_control_event("HandleDataListCheck")


    props.AddHandleSelect, props.RemoveHandleSelect = mixin_helper.create_standard_control_event("HandleDataListSelect")
    return props
end
__imports["mixin.FCMCtrlEdit"] = __imports["mixin.FCMCtrlEdit"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local props = {}
    local trigger_change
    local each_last_change
    local temp_str = mixin.FCMString()

    function props:SetText(str)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        mixin.FCMControl.SetText(self, str)
        trigger_change(self)
    end




    for method, valid_types in pairs({
        Integer = "number",
        Float = "number",
    }) do
        props["Get" .. method] = function(self)

            mixin.FCMControl.GetText(self, temp_str)
            return temp_str["Get" .. method](temp_str, 0)
        end
        props["Set" .. method] = function(self, value)
            mixin.assert_argument(value, valid_types, 2)
            temp_str["Set" .. method](temp_str, value)
            mixin.FCMControl.SetText(self, temp_str)
            trigger_change(self)
        end
    end






    for method, valid_types in pairs({
        Measurement = "number",
        MeasurementEfix = "number",
        MeasurementInteger = "number",
    }) do
        props["Get" .. method] = function(self, measurementunit)
            mixin.assert_argument(measurementunit, "number", 2)
            mixin.FCMControl.GetText(self, temp_str)
            return temp_str["Get" .. method](temp_str, measurementunit)
        end
        props["Set" .. method] = function(self, value, measurementunit)
            mixin.assert_argument(value, valid_types, 2)
            mixin.assert_argument(measurementunit, "number", 3)
            temp_str["Set" .. method](temp_str, value, measurementunit)
            mixin.FCMControl.SetText(self, temp_str)
            trigger_change(self)
        end
    end

    function props:GetRangeInteger(minimum, maximum)
        mixin.assert_argument(minimum, "number", 2)
        mixin.assert_argument(maximum, "number", 3)
        return utils.clamp(mixin.FCMCtrlEdit.GetInteger(self), math.floor(minimum), math.floor(maximum))
    end

    function props:GetRangeMeasurement(measurementunit, minimum, maximum)
        mixin.assert_argument(measurementunit, "number", 2)
        mixin.assert_argument(minimum, "number", 3)
        mixin.assert_argument(maximum, "number", 4)
        return utils.clamp(mixin.FCMCtrlEdit.GetMeasurement(self, measurementunit), minimum, maximum)
    end

    function props:GetRangeMeasurementEfix(measurementunit, minimum, maximum)
        mixin.assert_argument(measurementunit, "number", 2)
        mixin.assert_argument(minimum, "number", 3)
        mixin.assert_argument(maximum, "number", 4)
        return utils.clamp(mixin.FCMCtrlEdit.GetMeasurementEfix(self, measurementunit), minimum, maximum)
    end

    function props:GetRangeMeasurementInteger(measurementunit, minimum, maximum)
        mixin.assert_argument(measurementunit, "number", 2)
        mixin.assert_argument(minimum, "number", 3)
        mixin.assert_argument(maximum, "number", 4)
        return utils.clamp(mixin.FCMCtrlEdit.GetMeasurementInteger(self, measurementunit), math.floor(minimum), math.floor(maximum))
    end



    props.AddHandleChange, props.RemoveHandleChange, trigger_change, each_last_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_value",
            get = mixin.FCMControl.GetText,
            initial = ""
        }
    )
    return props
end
__imports["mixin.FCMCtrlListBox"] = __imports["mixin.FCMCtrlListBox"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local library = require("library.general_library")
    local utils = require("library.utils")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}
    local trigger_selection_change
    local each_last_selection_change
    local temp_str = finale.FCString()

    function props:Init()
        private[self] = private[self] or {}
    end

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

    function props:SetSelectedItem(index)
        mixin.assert_argument(index, "number", 2)
        self:SetSelectedItem_(index)
        trigger_selection_change(self)
    end

    function props:SetSelectedLast()
        trigger_selection_change(self)
        return self:SetSelectedLast_()
    end

    function props:AddString(str)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        if type(str) ~= "userdata" then
            temp_str.LuaString = tostring(str)
            str = temp_str
        end
        self:AddString_(str)

        table.insert(private[self], str.LuaString)
    end

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

    function props:SetStrings(...)

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

    function props:SetItemText(index, str)
        mixin.assert_argument(index, "number", 2)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 3)
        if not private[self][index + 1] then
            error("No item at index " .. tostring(index), 2)
        end
        private[self][index + 1] = type(str) == "userdata" and str.LuaString or tostring(str)

        if self:GetParent():WindowExists_() and self.SetItemText_ then
            temp_str.LuaString = private[self][index + 1]
            self:SetItemText_(index, temp_str)

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
                v.last_item = v.last_item + 1
            end
        end
    end

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

        if curr_item == index then
            trigger_selection_change(self)
        end
    end



    props.AddHandleSelectionChange, props.RemoveHandleSelectionChange, trigger_selection_change, each_last_selection_change =
        mixin_helper.create_custom_control_change_event(
            {name = "last_item", get = "GetSelectedItem_", initial = -1}, {
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
            })
    return props
end
__imports["mixin.FCMCtrlPopup"] = __imports["mixin.FCMCtrlPopup"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local library = require("library.general_library")
    local utils = require("library.utils")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}
    local trigger_selection_change
    local each_last_selection_change
    local temp_str = finale.FCString()

    function props:Init()
        private[self] = private[self] or {}
    end

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

    function props:SetSelectedItem(index)
        mixin.assert_argument(index, "number", 2)
        self:SetSelectedItem_(index)
        trigger_selection_change(self)
    end

    function props:SetSelectedLast()
        if self:GetCount() ~= 0 then
            self:SetSelectedItem(self:GetCount() - 1)
        end
    end

    function props:IsItemSelected()
        return self:GetSelectedItem_() >= 0
    end

    function props:ItemExists(index)
        mixin.assert_argument(index, "number", 2)
        return index <= self:GetCount_() - 1
    end

    function props:AddString(str)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        if type(str) ~= "userdata" then
            temp_str.LuaString = tostring(str)
            str = temp_str
        end
        self:AddString_(str)

        table.insert(private[self], str.LuaString)
    end

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

    function props:SetStrings(...)

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

    function props:SetItemText(index, str)
        mixin.assert_argument(index, "number", 2)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 3)
        if not private[self][index + 1] then
            error("No item at index " .. tostring(index), 2)
        end
        str = type(str) == "userdata" and str.LuaString or tostring(str)

        if private[self][index + 1] == str then
            return
        end
        private[self][index + 1] = type(str) == "userdata" and str.LuaString or tostring(str)
        local strs = finale.FCStrings()
        for _, v in ipairs(private[self]) do
            temp_str.LuaString = v
            strs:AddCopy(temp_str)
        end
        local curr_item = self:GetSelectedItem_()
        self:SetStrings_(strs)
        self:SetSelectedItem_(curr_item)
    end

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

    function props:InsertString(index, str)
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
                v.last_item = v.last_item + 1
            end
        end
    end

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

        if curr_item == index then
            trigger_selection_change(self)
        end
    end



    props.AddHandleSelectionChange, props.RemoveHandleSelectionChange, trigger_selection_change, each_last_selection_change =
        mixin_helper.create_custom_control_change_event(
            {name = "last_item", get = "GetSelectedItem_", initial = -1}, {
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
            })
    return props
end
__imports["mixin.FCMCtrlSlider"] = __imports["mixin.FCMCtrlSlider"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local windows = setmetatable({}, {__mode = "k"})
    local props = {}
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

    function props:RegisterParent(window)
        mixin.FCMControl.RegisterParent(self, window)
        if not windows[window] then

            window:AddHandleCommand(bootstrap_command)
            if window.SetTimer_ then

                window:AddHandleTimer(window:SetNextTimer(1000), bootstrap_timer_first)
            end
            windows[window] = true
        end
    end

    function props:SetThumbPosition(position)
        mixin.assert_argument(position, "number", 2)
        self:SetThumbPosition_(position)
        trigger_thumb_position_change(self)
    end

    function props:SetMinValue(minvalue)
        mixin.assert_argument(minvalue, "number", 2)
        self:SetMinValue_(minvalue)
        trigger_thumb_position_change(self)
    end

    function props:SetMaxValue(maxvalue)
        mixin.assert_argument(maxvalue, "number", 2)
        self:SetMaxValue_(maxvalue)
        trigger_thumb_position_change(self)
    end



    props.AddHandleThumbPositionChange, props.RemoveHandleThumbPositionChange, trigger_thumb_position_change, each_last_thumb_position_change =
        mixin_helper.create_custom_control_change_event(
            {name = "last_position", get = "GetThumbPosition_", initial = -1})
    return props
end
__imports["mixin.FCMCtrlStatic"] = __imports["mixin.FCMCtrlStatic"] or function()



    local mixin = require("library.mixin")
    local utils = require("library.utils")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}
    local temp_str = finale.FCString()

    function props:Init()
        private[self] = private[self] or {}
    end

    function props:SetTextColor(red, green, blue)
        mixin.assert_argument(red, "number", 2)
        mixin.assert_argument(green, "number", 3)
        mixin.assert_argument(blue, "number", 4)
        private[self].TextColor = {red, green, blue}
        if not mixin.FCMControl.UseStoredState(self) then
            self:SetTextColor_(red, green, blue)


            mixin.FCMControl.SetText(self, mixin.FCMControl.GetText(self))
        end
    end

    function props:RestoreState()
        mixin.FCMControl.RestoreState(self)
        if private[self].TextColor then
            mixin.FCMCtrlStatic.SetTextColor(self, private[self].TextColor[1], private[self].TextColor[2], private[self].TextColor[3])
        end
    end
    return props
end
__imports["mixin.FCMCtrlSwitcher"] = __imports["mixin.FCMCtrlSwitcher"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local library = require("library.general_library")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}
    local trigger_page_change
    local each_last_page_change
    local temp_str = finale.FCString()

    function props:Init()
        private[self] = private[self] or {Index = {}}
    end

    function props:AddPage(title)
        mixin.assert_argument(title, {"string", "number", "FCString"}, 2)
        if type(title) ~= "userdata" then
            temp_str.LuaString = tostring(title)
            title = temp_str
        end
        self:AddPage_(title)
        table.insert(private[self].Index, title.LuaString)
    end

    function props:AddPages(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin.assert_argument(v, {"string", "number", "FCString"}, i + 1)
            mixin.FCMCtrlSwitcher.AddPage(self, v)
        end
    end

    function props:AttachControlByTitle(control, title)

        mixin.assert_argument(title, {"string", "number", "FCString"}, 3)
        title = type(title) == "userdata" and title.LuaString or tostring(title)
        local index = -1
        for k, v in ipairs(private[self].Index) do
            if v == title then
                index = k - 1
            end
        end
        mixin.force_assert(index ~= -1, "No page titled '" .. title .. "'")
        return self:AttachControl_(control, index)
    end

    function props:SetSelectedPage(index)
        mixin.assert_argument(index, "number", 2)
        self:SetSelectedPage_(index)
        trigger_page_change(self)
    end

    function props:SetSelectedPageByTitle(title)
        mixin.assert_argument(title, {"string", "number", "FCString"}, 2)
        title = type(title) == "userdata" and title.LuaString or tostring(title)
        for k, v in ipairs(private[self].Index) do
            if v == title then
                mixin.FCMCtrlSwitcher.SetSelectedPage(self, k - 1)
                return
            end
        end
        error("No page titled '" .. title .. "'", 2)
    end

    function props:GetSelectedPageTitle(title)
        mixin.assert_argument(title, {"nil", "FCString"}, 2)
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

    function props:GetPageTitle(index, str)
        mixin.assert_argument(index, "number", 2)
        mixin.assert_argument(str, {"nil", "FCString"}, 2)
        local text = private[self].Index[index + 1]
        mixin.force_assert(text, "No page at index " .. tostring(index))
        if str then
            str.LuaString = text
        end
        return text
    end



    props.AddHandlePageChange, props.RemoveHandlePageChange, trigger_page_change, each_last_page_change =
        mixin_helper.create_custom_control_change_event(
            {name = "last_page", get = "GetSelectedPage_", initial = -1}, {
                name = "last_page_title",
                get = function(ctrl)
                    return mixin.FCMCtrlSwitcher.GetSelectedPageTitle(ctrl)
                end,
                initial = "",
            }
        )
    return props
end
__imports["mixin.FCMCtrlTree"] = __imports["mixin.FCMCtrlTree"] or function()



    local mixin = require("library.mixin")
    local props = {}
    local temp_str = finale.FCString()

    function props:AddNode(parentnode, iscontainer, text)
        mixin.assert_argument(parentnode, {"nil", "FCTreeNode"}, 2)
        mixin.assert_argument(iscontainer, "boolean", 3)
        mixin.assert_argument(text, {"string", "number", "FCString"}, 4)
        if not text.ClassName then
            temp_str.LuaString = tostring(text)
            text = temp_str
        end
        return self:AddNode_(parentnode, iscontainer, text)
    end
    return props
end
__imports["mixin.FCMCtrlUpDown"] = __imports["mixin.FCMCtrlUpDown"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}

    function props:Init()
        private[self] = private[self] or {}
    end

    function props:GetConnectedEdit()
        return private[self].ConnectedEdit
    end

    function props:ConnectIntegerEdit(control, minvalue, maxvalue)
        mixin.assert_argument(control, "FCMCtrlEdit", 2)
        mixin.assert_argument(minvalue, "number", 3)
        mixin.assert_argument(maxvalue, "number", 4)
        local ret = self:ConnectIntegerEdit_(control, minvalue, maxvalue)
        if ret then
            private[self].ConnectedEdit = control
        end
        return ret
    end

    function props:ConnectMeasurementEdit(control, minvalue, maxvalue)
        mixin.assert_argument(control, "FCMCtrlEdit", 2)
        mixin.assert_argument(minvalue, "number", 3)
        mixin.assert_argument(maxvalue, "number", 4)
        local ret = self:ConnectMeasurementEdit_(control, minvalue, maxvalue)
        if ret then
            private[self].ConnectedEdit = control
        end
        return ret
    end


    props.AddHandlePress, props.RemoveHandlePress = mixin_helper.create_standard_control_event("HandleUpDownPressed")
    return props
end
__imports["mixin.FCMCustomLuaWindow"] = __imports["mixin.FCMCustomLuaWindow"] or function()



    local mixin = require("library.mixin")
    local utils = require("library.utils")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}
    local control_handlers = {"HandleCommand", "HandleDataListCheck", "HandleDataListSelect", "HandleUpDownPressed"}
    local other_handlers = {"HandleCancelButtonPressed", "HandleOkButtonPressed", "InitWindow", "CloseWindow"}
    local function flush_custom_queue(self)
        local queue = private[self].HandleCustomQueue
        private[self].HandleCustomQueue = {}
        for _, cb in ipairs(queue) do
            cb()
        end
    end
    local function restore_position(window)
        if private[window].HasBeenShown and private[window].AutoRestorePosition and window.StorePosition then
            window:StorePosition(false)
            window:SetRestorePositionOnlyData_(private[window].StoredX, private[window].StoredY)
            window:RestorePosition()
        end
    end

    function props:Init()
        private[self] = private[self] or {
            HandleCustomQueue = {},
            HasBeenShown = false,
            EnableDebugClose = false,
            RestoreControlState = false,
            AutoRestorePosition = false,
            StoredX = nil,
            StoredY = nil,
        }

        for _, f in ipairs(control_handlers) do
            private[self][f] = {Added = {}}

            local is_running = false
            if self["Register" .. f .. "_"] then
                self["Register" .. f .. "_"](
                    self, function(control, ...)
                        if is_running then
                            return
                        end
                        is_running = true
                        local handlers = private[self][f]

                        flush_custom_queue(self)

                        local temp = self:FindControl(control:GetControlID())
                        if not temp then
                            error("Control with ID #" .. tostring(control:GetControlID()) .. " not found in '" .. f .. "'")
                        end
                        control = temp

                        if handlers.Registered then
                            handlers.Registered(control, ...)
                        end

                        for _, cb in ipairs(handlers.Added) do
                            cb(control, ...)
                        end

                        while #private[self].HandleCustomQueue > 0 do
                            flush_custom_queue(self)
                        end
                        is_running = false
                    end)
            end
        end

        for _, f in ipairs(other_handlers) do
            private[self][f] = {Added = {}}
            if self["Register" .. f .. "_"] then
                local function cb()
                    local handlers = private[self][f]
                    if handlers.Registered then
                        handlers.Registered(self)
                    end
                    for _, v in ipairs(handlers.Added) do
                        v(self)
                    end
                end
                if f == "InitWindow" then
                    self["Register" .. f .. "_"](self, function()
                        if private[self].HasBeenShown and private[self].RestoreControlState then
                            for control in each(self) do
                                control:RestoreState()
                            end
                        end
                        cb()
                    end)
                elseif f == "CloseWindow" then
                    self["Register" .. f .. "_"](self, function()
                        if private[self].EnableDebugClose and finenv.RetainLuaState ~= nil then
                            if finenv.DebugEnabled and (self:QueryLastCommandModifierKeys(finale.CMDMODKEY_ALT) or self:QueryLastCommandModifierKeys(finale.CMDMODKEY_SHIFT)) then
                                finenv.RetainLuaState = false
                            end
                        end

                        local is_error, error_msg = pcall(cb)
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
                        if is_error then
                            error(error_msg, 0)
                        end
                    end)
                else
                    self["Register" .. f .. "_"](self, cb)
                end
            end
        end
    end




    for _, f in ipairs(control_handlers) do
        props["Register" .. f] = function(self, callback)
            mixin.assert_argument(callback, "function", 2)
            private[self][f].Registered = callback
            return true
        end
    end








    for _, f in ipairs(other_handlers) do
        props["Register" .. f] = function(self, callback)
            mixin.assert_argument(callback, "function", 2)
            private[self][f].Registered = callback
            return true
        end
    end




    for _, f in ipairs(control_handlers) do
        props["Add" .. f] = function(self, callback)
            mixin.assert_argument(callback, "function", 2)
            table.insert(private[self][f].Added, callback)
        end
    end




    for _, f in ipairs(other_handlers) do
        props["Add" .. f] = function(self, callback)
            mixin.assert_argument(callback, "function", 2)
            table.insert(private[self][f].Added, callback)
        end
    end




    for _, f in ipairs(control_handlers) do
        props["Remove" .. f] = function(self, callback)
            mixin.assert_argument(callback, "function", 2)
            utils.table_remove_first(private[self][f].Added, callback)
        end
    end




    for _, f in ipairs(other_handlers) do
        props["Remove" .. f] = function(self, callback)
            mixin.assert_argument(callback, "function", 2)
            utils.table_remove_first(private[self][f].Added, callback)
        end
    end

    function props:QueueHandleCustom(callback)
        mixin.assert_argument(callback, "function", 2)
        table.insert(private[self].HandleCustomQueue, callback)
    end
    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then

        function props:RegisterHandleControlEvent(control, callback)
            mixin.assert_argument(callback, "function", 3)
            return self:RegisterHandleControlEvent_(
                       control, function(ctrl)
                    callback(self.FindControl(ctrl:GetControlID()))
                end)
        end
    end

    function props:HasBeenShown()
        return private[self].HasBeenShown
    end
    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 60 then

        function props:SetAutoRestorePosition(enabled)
            mixin.assert_argument(enabled, "boolean", 2)
            private[self].AutoRestorePosition = enabled
        end

        function props:GetAutoRestorePosition()
            return private[self].AutoRestorePosition
        end

        function props:SetRestorePositionData(x, y, width, height)
            mixin.assert_argument(x, "number", 2)
            mixin.assert_argument(y, "number", 3)
            mixin.assert_argument(width, "number", 4)
            mixin.assert_argument(height, "number", 5)
            self:SetRestorePositionOnlyData_(x, y, width, height)
            if private[self].HasBeenShown and not self:WindowExists() then
                private[self].StoredX = x
                private[self].StoredY = y
            end
        end

        function props:SetRestorePositionOnlyData(x, y)
            mixin.assert_argument(x, "number", 2)
            mixin.assert_argument(y, "number", 3)
            self:SetRestorePositionOnlyData_(x, y)
            if private[self].HasBeenShown and not self:WindowExists() then
                private[self].StoredX = x
                private[self].StoredY = y
            end
        end
    end

    function props:SetEnableDebugClose(enabled)
        mixin.assert_argument(enabled, "boolean", 2)
        private[self].EnableDebugClose = enabled and true or false
    end

    function props:GetEnableDebugClose(enabled)
        return private[self].EnableDebugClose
    end

    function props:SetRestoreControlState(enabled)
        mixin.assert_argument(enabled, "boolean", 2)
        private[self].RestoreControlState = enabled and true or false
    end

    function props:GetRestoreControlState()
        return private[self].RestoreControlState
    end

    function props:ExecuteModal(parent)
        restore_position(self)
        return mixin.FCMCustomWindow.ExecuteModal(self, parent)
    end

    function props:ShowModeless()
        restore_position(self)
        return self:ShowModeless_()
    end
    return props
end
__imports["mixin.FCMCustomWindow"] = __imports["mixin.FCMCustomWindow"] or function()



    local mixin = require("library.mixin")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}

    function props:Init()
        private[self] = private[self] or {
            Controls = {},
            NamedControls = {},
        }
    end




    for _, f in ipairs({"CancelButton", "OkButton"}) do
        props["Create" .. f] = function(self, control_name)
            mixin.assert_argument(control_name, {"string", "nil", "FCString"}, 2)
            local control = self["Create" .. f .. "_"](self)
            private[self].Controls[control:GetControlID()] = control
            control:RegisterParent(self)
            if control_name then
                control_name = type(control_name) == "userdata" and control_name.LuaString or control_name
                if private[self].NamedControls[control_name] then
                    error("A control is already registered with the name '" .. control_name .. "'", 2)
                end
                private[self].NamedControls[control_name] = control
            end
            return control
        end
    end











    for _, f in ipairs(
                    {
            "Button", "Checkbox", "DataList", "Edit", "ListBox", "Popup", "Slider", "Static", "Switcher", "Tree", "UpDown",
        }) do
        props["Create" .. f] = function(self, x, y, control_name)
            mixin.assert_argument(x, "number", 2)
            mixin.assert_argument(y, "number", 3)
            mixin.assert_argument(control_name, {"string", "nil", "FCString"}, 4)
            local control = self["Create" .. f .. "_"](self, x, y)
            private[self].Controls[control:GetControlID()] = control
            control:RegisterParent(self)
            if control_name then
                control_name = type(control_name) == "userdata" and control_name.LuaString or control_name
                if private[self].NamedControls[control_name] then
                    error("A control is already registered with the name '" .. control_name .. "'", 2)
                end
                private[self].NamedControls[control_name] = control
            end
            return control
        end
    end


    for _, f in ipairs({"HorizontalLine", "VerticalLine"}) do
        props["Create" .. f] = function(self, x, y, length, control_name)
            mixin.assert_argument(x, "number", 2)
            mixin.assert_argument(y, "number", 3)
            mixin.assert_argument(length, "number", 4)
            mixin.assert_argument(control_name, {"string", "nil", "FCString"}, 5)
            local control = self["Create" .. f .. "_"](self, x, y, length)
            private[self].Controls[control:GetControlID()] = control
            control:RegisterParent(self)
            if control_name then
                control_name = type(control_name) == "userdata" and control_name.LuaString or control_name
                if private[self].NamedControls[control_name] then
                    error("A control is already registered with the name '" .. control_name .. "'", 2)
                end
                private[self].NamedControls[control_name] = control
            end
            return control
        end
    end

    function props:FindControl(control_id)
        mixin.assert_argument(control_id, "number", 2)
        return private[self].Controls[control_id]
    end

    function props:GetControl(control_name)
        mixin.assert_argument(control_name, {"string", "FCString"}, 2)
        return private[self].NamedControls[control_name]
    end

    function props:Each(class_filter)
        local i = -1
        local v
        local iterator = function()
            repeat
                i = i + 1
                v = mixin.FCMCustomWindow.GetItemAt(self, i)
            until not v or not class_filter or mixin.is_instance_of(v, class_filter)
            return v
        end
        return iterator
    end

    function props:GetItemAt(index)
        local item = self:GetItemAt_(index)
        return item and private[self].Controls[item:GetControlID()] or item
    end

    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then
        function props.CreateCloseButton(self, x, y, control_name)
            mixin.assert_argument(x, "number", 2)
            mixin.assert_argument(y, "number", 3)
            mixin.assert_argument(control_name, {"string", "nil", "FCString"}, 4)
            local control = self:CreateCloseButton_(x, y)
            private[self].Controls[control:GetControlID()] = control
            control:RegisterParent(self)
            if control_name then
                control_name = type(control_name) == "userdata" and control_name.LuaString or control_name
                if private[self].NamedControls[control_name] then
                    error("A control is already registered with the name '" .. control_name .. "'", 2)
                end
                private[self].NamedControls[control_name] = control
            end
            return control
        end
    end

    function props:GetParent()
        return private[self].Parent
    end

    function props:ExecuteModal(parent)
        private[self].Parent = parent
        local ret = self:ExecuteModal_(parent)
        private[self].Parent = nil
        return ret
    end
    return props
end
__imports["mixin.FCMNoteEntry"] = __imports["mixin.FCMNoteEntry"] or function()



    local mixin = require("library.mixin")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}

    function props:Init()
        private[self] = private[self] or {}
    end

    function props:RegisterParent(parent)
        mixin.assert_argument(parent, 'FCNoteEntryCell', 2)
        if not private[self].Parent then
            private[self].Parent = parent
        end
    end

    function props:GetParent()
        return private[self].Parent
    end
    return props
end
__imports["mixin.FCMNoteEntryCell"] = __imports["mixin.FCMNoteEntryCell"] or function()



    local mixin = require("library.mixin")
    local props = {}

    function props:GetItemAt(index)
        mixin.assert_argument(index, "number", 2)
        local item = self:GetItemAt_(index)
        if item then
            item:RegisterParent(self)
        end
        return item
    end
    return props
end
__imports["mixin.FCMPage"] = __imports["mixin.FCMPage"] or function()



    local mixin = require("library.mixin")
    local page_size = require("library.page_size")
    local props = {}

    function props:GetSize()
        return page_size.get_page_size(self)
    end

    function props:SetSize(size)
        mixin.assert_argument(size, "string", 2)
        mixin.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")
        page_size.set_page_size(self, size)
    end

    function props:IsBlank()
        return self:GetFirstSystem() == -1
    end
    return props
end
__imports["mixin.FCMString"] = __imports["mixin.FCMString"] or function()



    local mixin = require("library.mixin")
    local utils = require("library.utils")
    local props = {}

    function props:GetMeasurementInteger(measurementunit)
        mixin.assert_argument(measurementunit, "number", 2)
        return utils.round(self:GetMeasurement_(measurementunit))
    end

    function props:SetMeasurementInteger(value, measurementunit)
        mixin.assert_argument(value, "number", 2)
        mixin.assert_argument(measurementunit, "number", 3)
        self:SetMeasurement_(utils.round(value), measurementunit)
    end
    return props
end
__imports["library.client"] = __imports["library.client"] or function()

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
__imports["library.general_library"] = __imports["library.general_library"] or function()

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
        local font_names = {}
        local add_to_table = function(for_user)
            local smufl_directory = calc_smufl_directory(for_user)
            local get_dirs = function()
                if finenv.UI():IsOnWindows() then
                    return io.popen("dir \"" .. smufl_directory .. "\" /b /ad")
                else
                    return io.popen("ls \"" .. smufl_directory .. "\"")
                end
            end
            local is_font_available = function(dir)
                local fc_dir = finale.FCString()
                fc_dir.LuaString = dir
                return finenv.UI():IsFontAvailable(fc_dir)
            end
            for dir in get_dirs():lines() do
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
        add_to_table(true)
        add_to_table(false)
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
__imports["mixin.FCMStrings"] = __imports["mixin.FCMStrings"] or function()



    local mixin = require("library.mixin")
    local library = require("library.general_library")
    local props = {}
    local temp_str = finale.FCString()

    function props:AddCopy(str)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        if type(str) ~= "userdata" then
            temp_str.LuaString = tostring(str)
            str = temp_str
        end
        return self:AddCopy_(str)
    end

    function props:AddCopies(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin.assert_argument(v, {"FCStrings", "FCString", "string", "number"}, i + 1)
            if type(v) == "userdata" and v:ClassName() == "FCStrings" then
                for str in each(v) do
                    v:AddCopy_(str)
                end
            else
                mixin.FCStrings.AddCopy(self, v)
            end
        end
        return true
    end

    function props:CopyFrom(...)
        local num_args = select("#", ...)
        local first = select(1, ...)
        mixin.assert_argument(first, {"FCStrings", "FCString", "string", "number"}, 2)
        if library.is_finale_object(first) and first:ClassName() == "FCStrings" then
            self:CopyFrom_(first)
        else
            self:ClearAll_()
            mixin.FCMStrings.AddCopy(self, first)
        end
        for i = 2, num_args do
            local v = select(i, ...)
            mixin.assert_argument(v, {"FCStrings", "FCString", "string", "number"}, i + 1)
            if type(v) == "userdata" then
                if v:ClassName() == "FCString" then
                    self:AddCopy_(v)
                elseif v:ClassName() == "FCStrings" then
                    for str in each(v) do
                        v:AddCopy_(str)
                    end
                end
            else
                temp_str.LuaString = tostring(v)
                self:AddCopy_(temp_str)
            end
        end
        return true
    end

    function props:Find(str)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        if type(str) ~= "userdata" then
            temp_str.LuaString = tostring(str)
            str = temp_str
        end
        return self:Find_(str)
    end

    function props:FindNocase(str)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        if type(str) ~= "userdata" then
            temp_str.LuaString = tostring(str)
            str = temp_str
        end
        return self:FindNocase_(str)
    end

    function props:LoadFolderFiles(folderstring)
        mixin.assert_argument(folderstring, {"string", "FCString"}, 2)
        if type(folderstring) ~= "userdata" then
            temp_str.LuaString = tostring(folderstring)
            folderstring = temp_str
        end
        return self:LoadFolderFiles_(folderstring)
    end

    function props:LoadSubfolders(folderstring)
        mixin.assert_argument(folderstring, {"string", "FCString"}, 2)
        if type(folderstring) ~= "userdata" then
            temp_str.LuaString = tostring(folderstring)
            folderstring = temp_str
        end
        return self:LoadSubfolders_(folderstring)
    end

    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 59 then
        function props:InsertStringAt(str, index)
            mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
            mixin.assert_argument(index, "number", 3)
            if type(str) ~= "userdata" then
                temp_str.LuaString = tostring(str)
                str = temp_str
            end
            self:InsertStringAt_(str, index)
        end
    end
    return props
end
__imports["mixin.FCMTreeNode"] = __imports["mixin.FCMTreeNode"] or function()



    local mixin = require("library.mixin")
    local props = {}
    local temp_str = finale.FCString()

    function props:GetText(str)
        mixin.assert_argument(str, {"nil", "FCString"}, 2)
        if not str then
            str = temp_str
        end
        self:GetText_(str)
        return str.LuaString
    end

    function props:SetText(str)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        if type(str) ~= "userdata" then
            temp_str.LuaString = tostring(str)
            str = temp_str
        end
        self:SetText_(str)
    end
    return props
end
__imports["mixin.FCMUI"] = __imports["mixin.FCMUI"] or function()



    local mixin = require("library.mixin")
    local props = {}
    local temp_str = finale.FCString()

    function props:GetDecimalSeparator(str)
        mixin.assert_argument(str, {"nil", "FCString"}, 2)
        if not str then
            str = temp_str
        end
        self:GetDecimalSeparator_(str)
        return str.LuaString
    end
    return props
end
__imports["mixin.FCXCtrlMeasurementEdit"] = __imports["mixin.FCXCtrlMeasurementEdit"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local private = setmetatable({}, {__mode = "k"})
    local props = {MixinParent = "FCMCtrlEdit"}
    local trigger_change
    local each_last_change

    function props:Init()
        local parent = self:GetParent()
        mixin.assert(mixin.is_instance_of(parent, "FCXCustomLuaWindow"), "FCXCtrlMeasurementEdit must have a parent window that is an instance of FCXCustomLuaWindow")
        private[self] = private[self] or {
            Type = "MeasurementInteger",
            LastMeasurementUnit = parent:GetMeasurementUnit(),
        }
    end



    for method, valid_types in pairs({
        Text = {"string", "number", "FCString"},
        Integer = "number",
        Float = "number",
    }) do
        props["Set" .. method] = function(self, value)
            mixin.assert_argument(value, valid_types, 2)
            mixin.FCMCtrlEdit["Set" .. method](self, value)
            trigger_change(self)
        end
    end









    for method, valid_types in pairs({
        Measurement = "number",
        MeasurementInteger = "number",
        MeasurementEfix = "number",
    }) do
        props["Get" .. method] = function(self)
            return mixin.FCMCtrlEdit["Get" .. method](self, private[self].LastMeasurementUnit)
        end
        props["GetRange" .. method] = function(self, minimum, maximum)
            mixin.assert_argument(minimum, "number", 2)
            mixin.assert_argument(maximum, "number", 3)
            return mixin.FCMCtrlEdit["GetRange" .. method](self, private[self].LastMeasurementUnit, minimum, maximum)
        end
        props["Set" .. method] = function (self, value)
            mixin.assert_argument(value, valid_types, 2)
            mixin.FCMCtrlEdit["Set" .. method](self, value, private[self].LastMeasurementUnit)
            trigger_change(self)
        end
        props["IsType" .. method] = function(self)
            return private[self].Type == method
        end
    end

    function props:GetType()
        return private[self].Type
    end




    function props:SetTypeMeasurement()
        if private[self].Type == "Measurement" then
            return
        end
        if private[self].Type == "MeasurementEfix" then
            for v in each_last_change(self) do
                v.last_value = v.last_value / 64
            end
        end
        private[self].Type = "Measurement"
    end

    function props:SetTypeMeasurementInteger()
        if private[self].Type == "MeasurementInteger" then
            return
        end
        if private[self].Type == "Measurement" then
            for v in each_last_change(self) do
                v.last_value = utils.round(v.last_value)
            end
        elseif private[self].Type == "MeasurementEfix" then
            for v in each_last_change(self) do
                v.last_value = utils.round(v.last_value / 64)
            end
        end
        private[self].Type = "MeasurementInteger"
    end

    function props:SetTypeMeasurementEfix()
        if private[self].Type == "MeasurementEfix" then
            return
        end
        for v in each_last_change(self) do
            v.last_value = v.last_value * 64
        end
        private[self].Type = "MeasurementEfix"
    end

    function props:UpdateMeasurementUnit()
        local new_unit = self:GetParent():GetMeasurementUnit()
        if private[self].LastMeasurementUnit ~= new_unit then
            local val = self["Get" .. private[self].Type](self)
            private[self].LastMeasurementUnit = new_unit
            self["Set" .. private[self].Type](self, val)
        end
    end



    props.AddHandleChange, props.RemoveHandleChange, trigger_change, each_last_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_value",
            get = function(ctrl)
                return mixin.FCXCtrlMeasurementEdit["Get" .. private[ctrl].Type](ctrl)
            end,
            initial = 0,
        }
    )
    return props
end
__imports["mixin.FCXCtrlMeasurementUnitPopup"] = __imports["mixin.FCXCtrlMeasurementUnitPopup"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local props = {MixinParent = "FCMCtrlPopup"}
    local unit_order = {
        finale.MEASUREMENTUNIT_EVPUS, finale.MEASUREMENTUNIT_INCHES, finale.MEASUREMENTUNIT_CENTIMETERS,
        finale.MEASUREMENTUNIT_POINTS, finale.MEASUREMENTUNIT_PICAS, finale.MEASUREMENTUNIT_SPACES,
    }
    local reverse_unit_order = {}
    for k, v in ipairs(unit_order) do
        reverse_unit_order[v] = k
    end

    mixin_helper.disable_methods(
        props, "Clear", "AddString", "AddStrings", "SetStrings", "GetSelectedItem", "SetSelectedItem", "SetSelectedLast",
        "ItemExists", "InsertString", "DeleteItem", "GetItemText", "SetItemText", "AddHandleSelectionChange",
        "RemoveHandleSelectionChange")

    function props:Init()
        mixin.assert(
            mixin.is_instance_of(self:GetParent(), "FCXCustomLuaWindow"),
            "FCXCtrlMeasurementUnitPopup must have a parent window that is an instance of FCXCustomLuaWindow")
        for _, v in ipairs(unit_order) do
            mixin.FCMCtrlPopup.AddString(self, measurement.get_unit_name(v))
        end
        self:UpdateMeasurementUnit()
        mixin.FCMCtrlPopup.AddHandleSelectionChange(
            self, function(control)
                control:GetParent():SetMeasurementUnit(unit_order[control:GetSelectedItem_() + 1])
            end)
    end

    function props:UpdateMeasurementUnit()
        local unit = self:GetParent():GetMeasurementUnit()
        if unit == unit_order[self:GetSelectedItem_() + 1] then
            return
        end
        mixin.FCMCtrlPopup.SetSelectedItem(self, reverse_unit_order[unit] - 1)
    end
    return props
end
__imports["library.page_size"] = __imports["library.page_size"] or function()



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
__imports["mixin.FCXCtrlPageSizePopup"] = __imports["mixin.FCXCtrlPageSizePopup"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local page_size = require("library.page_size")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}
    local trigger_page_size_change
    local each_last_page_size_change
    local temp_str = finale.FCString()

    mixin_helper.disable_methods(
        props, "Clear", "AddString", "AddStrings", "SetStrings", "GetSelectedItem", "SetSelectedItem", "SetSelectedLast",
        "ItemExists", "InsertString", "DeleteItem", "GetItemText", "SetItemText", "AddHandleSelectionChange",
        "RemoveHandleSelectionChange")
    local function repopulate(control)
        local unit = mixin.is_instance_of(control:GetParent(), "FCXCustomLuaWindow") and
                         control:GetParent():GetMeasurementUnit() or measurement.get_real_default_unit()
        if private[control].LastUnit == unit then
            return
        end
        local suffix = measurement.get_unit_abbreviation(unit)
        local selection = control:GetSelectedItem_()

        mixin.FCMCtrlPopup.Clear()
        for size, dimensions in page_size.pairs() do
            local str = size .. " ("
            temp_str:SetMeasurement(dimensions.width, unit)
            str = str .. temp_str.LuaString .. suffix .. " x "
            temp_str:SetMeasurement(dimensions.height, unit)
            str = str .. temp_str.LuaString .. suffix .. ")"
            mixin.FCMCtrlPopup.AddString(str)
        end
        control:SetSelectedItem_(selection)
        private[control].LastUnit = unit
    end

    function props:Init()
        private[self] = private[self] or {}
        repopulate(self)
    end

    function props:GetSelectedPageSize()
        local str = mixin.FCMCtrlPopup.GetSelectedString()
        if not str then
            return nil
        end
        return str:match("(.+) %(")
    end

    function props:SetSelectedPageSize(size)
        mixin.assert_argument(size, {"string", "FCString"}, 2)
        size = type(size) == "userdata" and size.LuaString or tostring(size)
        mixin.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")
        local index = 0
        for s in page_size.pairs() do
            if size == s then
                if index ~= self:_GetSelectedItem() then
                    mixin.FCMCtrlPopup.SetSelectedItem(index)
                    trigger_page_size_change(self)
                end
                return
            end
            index = index + 1
        end
    end

    function props:UpdateMeasurementUnit()
        repopulate(self)
    end



    props.AddHandlePageSizeChange, props.RemoveHandlePageSizeChange, trigger_page_size_change, each_last_page_size_change =
        mixin_helper.create_custom_control_change_event(
            {
                name = "last_page_size",
                get = function(ctrl)
                    return mixin.FCXCtrlPageSizePopup.GetSelectedPageSize(ctrl)
                end,
                initial = false,
            })
    return props
end
__imports["mixin.FCXCtrlStatic"] = __imports["mixin.FCXCtrlStatic"] or function()



    local mixin = require("library.mixin")
    local measurement = require("library.measurement")
    local utils = require("library.utils")
    local private = setmetatable({}, {__mode = "k"})
    local props = {MixinParent = "FCMCtrlStatic"}
    local temp_str = finale.FCString()
    local function get_suffix(unit, suffix_type)
        if suffix_type == 1 then
            return measurement.get_unit_suffix(unit)
        elseif suffix_type == 2 then
            return measurement.get_unit_abbreviation(unit)
        elseif suffix_type == 3 then
            return " " .. string.lower(measurement.get_unit_name(unit))
        end
    end

    function props:Init()
        mixin.assert(mixin.is_instance_of(self:GetParent(), "FCXCustomLuaWindow"), "FCXCtrlStatic must have a parent window that is an instance of FCXCustomLuaWindow")
        private[self] = private[self] or {
            ShowMeasurementSuffix = true,
            MeasurementSuffixType = 2,
        }
    end

    function props:SetText(str)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        mixin.FCMCtrlStatic.SetText(self, str)
        private[self].Measurement = nil
        private[self].MeasurementType = nil
    end

    function props:SetMeasurement(value)
        mixin.assert_argument(value, "number", 2)
        local unit = self:GetParent():GetMeasurementUnit()
        temp_str:SetMeasurement(value, unit)
        temp_str:AppendLuaString(private[self].ShowMeasurementSuffix and get_suffix(unit, private[self].MeasurementSuffixType) or "")
        mixin.FCMCtrlStatic.SetText(self, temp_str)
        private[self].Measurement = value
        private[self].MeasurementType = "Measurement"
    end

    function props:SetMeasurementInteger(value)
        mixin.assert_argument(value, "number", 2)
        value = utils.round(value)
        local unit = self:GetParent():GetMeasurementUnit()
        temp_str:SetMeasurement(value, unit)
        temp_str:AppendLuaString(private[self].ShowMeasurementSuffix and get_suffix(unit, private[self].MeasurementSuffixType) or "")
        mixin.FCMCtrlStatic.SetText(self, temp_str)
        private[self].Measurement = value
        private[self].MeasurementType = "MeasurementInteger"
    end

    function props:SetMeasurementEfix(value)
        mixin.assert_argument(value, "number", 2)
        local evpu = value / 64
        local unit = self:GetParent():GetMeasurementUnit()
        temp_str:SetMeasurement(evpu, unit)
        temp_str:AppendLuaString(private[self].ShowMeasurementSuffix and get_suffix(unit, private[self].MeasurementSuffixType) or "")
        mixin.FCMCtrlStatic.SetText(self, temp_str)
        private[self].Measurement = value
        private[self].MeasurementType = "MeasurementEfix"
    end

    function props:SetShowMeasurementSuffix(enabled)
        mixin.assert_argument(enabled, "boolean", 2)
        private[self].ShowMeasurementSuffix = enabled and true or false
        mixin.FCXCtrlStatic.UpdateMeasurementUnit(self)
    end

    function props:SetMeasurementSuffixShort()
        private[self].MeasurementSuffixType = 1
        mixin.FCXCtrlStatic.UpdateMeasurementUnit(self)
    end

    function props:SetMeasurementSuffixAbbreviated()
        private[self].MeasurementSuffixType = 2
        mixin.FCXCtrlStatic.UpdateMeasurementUnit(self)
    end

    function props:SetMeasurementSuffixFull()
        private[self].MeasurementSuffixType = 3
        mixin.FCXCtrlStatic.UpdateMeasurementUnit(self)
    end

    function props:UpdateMeasurementUnit()
        if private[self].Measurement then
            mixin.FCXCtrlStatic["Set" .. private[self].MeasurementType](self, private[self].Measurement)
        end
    end
    return props
end
__imports["mixin.FCXCtrlUpDown"] = __imports["mixin.FCXCtrlUpDown"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local private = setmetatable({}, {__mode = "k"})
    local props = {MixinParent = "FCMCtrlUpDown"}
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

    function props:Init()
        mixin.assert(
            mixin.is_instance_of(self:GetParent(), "FCXCustomLuaWindow"),
            "FCXCtrlUpDown must have a parent window that is an instance of FCXCustomLuaWindow")
        private[self] = private[self] or {IntegerStepSize = 1, MeasurementSteps = {}, AlignWhenMoving = true}
        self:AddHandlePress(
            function(self, delta)
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
                    step_def = private[self].MeasurementSteps[unit] or (edit_type == 4 and default_efix_steps[unit]) or
                                   default_measurement_steps[unit]
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

    function props:GetConnectedEdit()
        return private[self].ConnectedEdit
    end

    function props:ConnectIntegerEdit(control, minimum, maximum)
        mixin.assert_argument(control, "FCMCtrlEdit", 2)
        mixin.assert_argument(minimum, "number", 3)
        mixin.assert_argument(maximum, "number", 4)
        mixin.assert(
            not mixin.is_instance_of(control, "FCXCtrlMeasurementEdit"),
            "A measurement edit cannot be connected as an integer edit.")
        private[self].ConnectedEdit = control
        private[self].ConnectedEditType = "Integer"
        private[self].Minimum = minimum
        private[self].Maximum = maximum
    end

    function props:ConnectMeasurementEdit(control, minimum, maximum)
        mixin.assert_argument(control, "FCXCtrlMeasurementEdit", 2)
        mixin.assert_argument(minimum, "number", 3)
        mixin.assert_argument(maximum, "number", 4)
        private[self].ConnectedEdit = control
        private[self].ConnectedEditType = "Measurement"
        private[self].Minimum = minimum
        private[self].Maximum = maximum
    end

    function props:SetIntegerStepSize(value)
        mixin.assert_argument(value, "number", 2)
        private[self].IntegerStepSize = value
    end

    function props:SetEVPUsStepSize(value)
        mixin.assert_argument(value, "number", 2)
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_EVPUS] = {value = value, is_evpus = true}
    end

    function props:SetInchesStepSize(value, is_evpus)
        mixin.assert_argument(value, "number", 2)
        mixin.assert_argument(is_evpus, {"boolean", "nil"}, 3)
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_INCHES] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function props:SetCentimetersStepSize(value, is_evpus)
        mixin.assert_argument(value, "number", 2)
        mixin.assert_argument(is_evpus, {"boolean", "nil"}, 3)
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_CENTIMETERS] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function props:SetPointsStepSize(value, is_evpus)
        mixin.assert_argument(value, "number", 2)
        mixin.assert_argument(is_evpus, {"boolean", "nil"}, 3)
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_POINTS] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function props:SetPicasStepSize(value, is_evpus)
        mixin.assert_argument(value, {"number", "string"}, 2)
        if not is_evpus then
            temp_str:SetText(tostring(value))
            value = temp_str:GetMeasurement(finale.MEASUREMENTUNIT_PICAS)
        end
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_PICAS] = {value = value, is_evpus = true}
    end

    function props:SetSpacesStepSize(value, is_evpus)
        mixin.assert_argument(value, "number", 2)
        mixin.assert_argument(is_evpus, {"boolean", "nil"}, 3)
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_SPACES] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function props:SetAlignWhenMoving(on)
        mixin.assert_argument(on, "boolean", 2)
        private[self].AlignWhenMoving = on
    end

    function props:GetValue()
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

    function props:SetValue(value)
        mixin.assert_argument(value, "number", 2)
        mixin.assert(private[self].ConnectedEdit, "Unable to set value: no connected edit.")

        value = value < private[self].Minimum and private[self].Minimum or value
        value = value > private[self].Maximum and private[self].Maximum or value
        local edit = private[self].ConnectedEdit
        if private[self].ConnectedEditType == "Measurement" then
            edit["Set" .. edit:GetType()](edit, value)
        else
            edit:SetInteger(value)
        end
    end

    function props:GetMinimum()
        return private[self].Minimum
    end

    function props:GetMaximum()
        return private[self].Maximum
    end

    function props:SetRange(minimum, maximum)
        mixin.assert_argument(minimum, "number", 2)
        mixin.assert_argument(maximum, "number", 3)
        private[self].Minimum = minimum
        private[self].Maximum = maximum
    end
    return props
end
__imports["library.utils"] = __imports["library.utils"] or function()

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

    function utils.round(num)
        return math.floor(num + 0.5)
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
    return utils
end
__imports["library.mixin_helper"] = __imports["library.mixin_helper"] or function()


     local utils = require("library.utils")
    local mixin = require("library.mixin")
    local mixin_helper = {}
    local disabled_method = function()
        error("Attempt to call disabled method 'tryfunczzz'", 2)
    end

    function mixin_helper.disable_methods(props, ...)
        for i = 1, select("#", ...) do
            props[select(i, ...)] = disabled_method
        end
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
            mixin.assert_argument(callback, "function", 3)
            local window = control:GetParent()
            mixin.assert(window, "Cannot add handler to control with no parent window.")
            mixin.assert(
                (window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow",
                "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
            init_window(window)
            callbacks[control] = callbacks[control] or {}
            table.insert(callbacks[control], callback)
        end
        local function remove_func(control, callback)
            mixin.assert_argument(callback, "function", 3)
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
            mixin.assert_argument(callback, "function", 2)
            local window = self:GetParent()
            mixin.assert(window, "Cannot add handler to self with no parent window.")
            mixin.assert(
                (window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow",
                "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
            mixin.force_assert(
                not event.callback_exists(self, callback), "The callback has already been added as a handler.")
            init_window(window)
            event.add(self, callback, not window:WindowExists_())
        end
        local function remove_func(self, callback)
            mixin.assert_argument(callback, "function", 2)
            event.remove(self, callback)
        end
        local function trigger_helper(control)
            if not event.has_callbacks(control) or queued[control] then
                return
            end
            local window = control:GetParent()
            if window:WindowExists_() then
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
            mixin.assert_argument(self, "FCMCustomLuaWindow", 1)
            mixin.assert_argument(callback, "function", 2)
            mixin.force_assert(
                not event.callback_exists(self, callback), "The callback has already been added as a handler.")
            event.add(self, callback)
        end
        local function remove_func(self, callback)
            mixin.assert_argument(callback, "function", 2)
            event.remove(self, callback)
        end
        local function trigger_helper(window)
            if not event.has_callbacks(window) or queued[window] or not window:WindowExists_() then
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
    return mixin_helper
end
__imports["library.measurement"] = __imports["library.measurement"] or function()

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
__imports["mixin.FCXCustomLuaWindow"] = __imports["mixin.FCXCustomLuaWindow"] or function()



    local mixin = require("library.mixin")
    local utils = require("library.utils")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local private = setmetatable({}, {__mode = "k"})
    local props = {MixinParent = "FCMCustomLuaWindow"}
    local trigger_measurement_unit_change
    local each_last_measurement_unit_change

    function props:Init()
        private[self] = private[self] or {
            MeasurementUnit = measurement.get_real_default_unit(),
            UseParentMeasurementUnit = true,
            HandleTimer = {},
            RunModelessDefaultAction = nil,
        }
        if self.SetAutoRestorePosition then
            self:SetAutoRestorePosition(true)
        end
        self:SetRestoreControlState(true)
        self:SetEnableDebugClose(true)

        if self.RegisterHandleTimer_ then
            self:RegisterHandleTimer_(function(timerid)

                if private[self].HandleTimer.Registered then

                    private[self].HandleTimer.Registered(self, timerid)
                end

                if private[self].HandleTimer[timerid] then
                    for _, cb in ipairs(private[self].HandleTimer[timerid]) do

                        cb(self, timerid)
                    end
                end
            end)
        end
    end

    function props:GetMeasurementUnit()
        return private[self].MeasurementUnit
    end

    function props:SetMeasurementUnit(unit)
        mixin.assert_argument(unit, "number", 2)
        if unit == private[self].MeasurementUnit then
            return
        end
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end
        mixin.force_assert(measurement.is_valid_unit(unit), "Measurement unit is not valid.")
        private[self].MeasurementUnit = unit

        for ctrl in each(self) do
            local func = ctrl.UpdateMeasurementUnit
            if func then
                func(ctrl)
            end
        end
        trigger_measurement_unit_change(self)
    end

    function props:GetMeasurementUnitName()
        return measurement.get_unit_name(private[self].MeasurementUnit)
    end

    function props:UseParentMeasurementUnit(on)
        mixin.assert_argument(on, "boolean", 2)
        private[self].UseParentMeasurementUnit = on
    end

    function props:CreateMeasurementEdit(x, y, control_name)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)
        mixin.assert_argument(control_name, {"string", "nil"}, 4)
        local edit = mixin.FCMCustomWindow.CreateEdit(self, x, y, control_name)
        return mixin.subclass(edit, "FCXCtrlMeasurementEdit")
    end

    function props:CreateMeasurementUnitPopup(x, y, control_name)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)
        mixin.assert_argument(control_name, {"string", "nil"}, 4)
        local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
        return mixin.subclass(popup, "FCXCtrlMeasurementUnitPopup")
    end

    function props:CreatePageSizePopup(x, y, control_name)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)
        mixin.assert_argument(control_name, {"string", "nil"}, 4)
        local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
        return mixin.subclass(popup, "FCXCtrlPageSizePopup")
    end

    function props:CreateStatic(x, y, control_name)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)
        mixin.assert_argument(control_name, {"string", "nil"}, 4)
        local popup = mixin.FCMCustomWindow.CreateStatic(self, x, y, control_name)
        return mixin.subclass(popup, "FCXCtrlStatic")
    end

    function props:CreateUpDown(x, y, control_name)
        mixin.assert_argument(x, "number", 2)
        mixin.assert_argument(y, "number", 3)
        mixin.assert_argument(control_name, {"string", "nil"}, 4)
        local updown = mixin.FCMCustomWindow.CreateUpDown(self, x, y, control_name)
        return mixin.subclass(updown, "FCXCtrlUpDown")
    end
    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then

        function props:SetTimer(timerid, msinterval)
            mixin.assert_argument(timerid, "number", 2)
            mixin.assert_argument(msinterval, "number", 3)
            self:SetTimer_(timerid, msinterval)
            private[self].HandleTimer[timerid] = private[self].HandleTimer[timerid] or {}
        end

        function props:GetNextTimerID()
            while private[self].HandleTimer[private[self].NextTimerID] do
                private[self].NextTimerID = private[self].NextTimerID + 1
            end
            return private[self].NextTimerID
        end

        function props:SetNextTimer(msinterval)
            mixin.assert_argument(msinterval, "number", 2)
            local timerid = self:GetNextTimerID()
            self:SetTimer(timerid, msinterval)
            return timerid
        end


        function props:RegisterHandleTimer(callback)
            mixin.assert_argument(callback, "function", 2)
            private[self].HandleTimer.Registered = callback
            return true
        end

        function props:AddHandleTimer(timerid, callback)
            mixin.assert_argument(timerid, "number", 2)
            mixin.assert_argument(callback, "function", 3)
            private[self].HandleTimer[timerid] = private[self].HandleTimer[timerid] or {}
            table.insert(private[self].HandleTimer[timerid], callback)
        end

        function props:RemoveHandleTimer(timerid, callback)
            mixin.assert_argument(timerid, "number", 2)
            mixin.assert_argument(callback, "function", 3)
            if not private[self].HandleTimer[timerid] then
                return
            end
            utils.table_remove_first(private[self].HandleTimer[timerid], callback)
        end
    end

    function props:RegisterHandleOkButtonPressed(callback)
        mixin.assert_argument(callback, "function", 2)
        private[self].RunModelessDefaultAction = callback
        mixin.FCMCustomLuaWindow.RegisterHandleOkButtonPressed(self, callback)
    end

    function props:ExecuteModal(parent)
        if mixin.is_instance_of(parent, "FCXCustomLuaWindow") and private[self].UseParentMeasurementUnit then
            self:SetMeasurementUnit(parent:GetMeasurementUnit())
        end
        return mixin.FCMCustomLuaWindow.ExecuteModal(self, parent)
    end

    function props:ShowModeless()
        finenv.RegisterModelessDialog(self)
        return mixin.FCMCustomLuaWindow.ShowModeless(self)
    end

    function props:RunModeless(no_selection_required, default_action_override)
        local modifier_keys_on_invoke = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
        local default_action = default_action_override == nil and private[self].RunModelessDefaultAction or default_action_override
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
            if not no_selection_required and finenv.Region():IsEmpty() then
                finenv.UI():AlertInfo("Please select a music region before running this script.", "Selection Required")
                return
            end
            self:ExecuteModal(nil)
        end
    end



    props.AddHandleMeasurementUnitChange, props.RemoveHandleMeasurementUnitChange, trigger_measurement_unit_change, each_last_measurement_unit_change =
        mixin_helper.create_custom_window_change_event(
            {
                name = "last_unit",
                get = function(win)
                    return mixin.FCXCustomLuaWindow.GetMeasurementUnit(win)
                end,
                initial = measurement.get_real_default_unit(),
            })
    return props
end
__imports["mixin.__FCMUserWindow"] = __imports["mixin.__FCMUserWindow"] or function()



    local mixin = require("library.mixin")
    local props = {}
    local temp_str = finale.FCString()

    function props:GetTitle(title)
        mixin.assert_argument(title, {"nil", "FCString"}, 2)
        if not title then
            title = temp_str
        end
        self:GetTitle_(title)
        return title.LuaString
    end

    function props:SetTitle(title)
        mixin.assert_argument(title, {"string", "number", "FCString"}, 2)
        if type(title) ~= "userdata" then
            temp_str.LuaString = tostring(title)
            title = temp_str
        end
        self:SetTitle_(title)
    end
    return props
end
__imports["library.mixin"] = __imports["library.mixin"] or function()





    local utils = require("library.utils")
    local library = require("library.general_library")


    local mixin_public = {}

    local mixin_private = {}

    local mixin_classes = {}

    local mixin_props = setmetatable({}, {__mode = "k"})


    local mixin = setmetatable({}, {
        __newindex = function(t, k, v) end,
        __index = function(t, k)
            if mixin_public[k] then return mixin_public[k] end

            mixin_private.load_mixin_class(k)
            if not mixin_classes[k] then return nil end


            mixin_public[k] = setmetatable({}, {
                __newindex = function(tt, kk, vv) end,
                __index = function(tt, kk)
                    local val = utils.copy_table(mixin_classes[k].props[kk])
                    if type(val) == "function" then
                        val = mixin_private.create_fluid_proxy(val, kk)
                    end
                    return val
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




    local reserved_props = {
        IsMixinReady = 0,
        MixinClass = 0,
        MixinParent = 1,
        MixinBase = 0,
        Init = 1,
    }

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




    function mixin_private.get_class_name(object)

        local suffix = object.MixinClass and "_" or ""
        local class_name = object["ClassName" .. suffix](object)

        if class_name == "__FCCollection" and object["ExecuteModal" ..suffix] then
            return object["RegisterHandleCommand" .. suffix] and "FCCustomLuaWindow" or "FCCustomWindow"
        elseif class_name == "FCControl" then
            if object["GetCheck" .. suffix] then
                return "FCCtrlCheckbox"
            elseif object["GetThumbPosition" .. suffix] then
                return "FCCtrlSlider"
            elseif object["AddPage" .. suffix] then
                return "FCCtrlSwitcher"
            else
                return "FCCtrlButton"
            end
        elseif class_name == "FCCtrlButton" and object["GetThumbPosition" .. suffix] then
            return "FCCtrlSlider"
        end

        return class_name
    end



    function mixin_private.get_parent_class(classname)
        local class = finale[classname]
        if type(class) ~= "table" then return nil end
        if not finenv.IsRGPLua then
            classt = class.__class
            if classt and classname ~= "__FCBase" then
                classtp = classt.__parent
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


    function mixin_private.try_load_module(name)
        local success, result = pcall(function(c) return require(c) end, name)


        if not success and not result:match("module '[^']-' not found") then
            error(result, 0)
        end

        return success, result
    end


    function mixin_private.load_mixin_class(class_name)
        if mixin_classes[class_name] then return end

        local is_fcm = mixin_private.is_fcm_class_name(class_name)
        local is_fcx = mixin_private.is_fcx_class_name(class_name)


        local success, result = mixin_private.try_load_module("personal_mixin." .. class_name)

        if not success then
            success, result = mixin_private.try_load_module("mixin." .. class_name)
        end

        if not success then

            if is_fcm and finale[mixin_private.fcm_to_fc_class_name(class_name)] then
                result = {}
            else
                return
            end
        end


        if type(result) ~= "table" then
            error("Mixin '" .. class_name .. "' is not a table.", 0)
        end

        local class = {props = result}


        for k, _ in pairs(class.props) do
            if type(k) == "string" and k:sub(-1) == "_" then
                error("Mixin methods and properties cannot end in an underscore (" .. class_name .. "." .. k .. ")", 0)
            end
        end


        for k, v in pairs(reserved_props) do
            if v == 0 and type(class.props[k]) ~= "nil" then
                error("Mixin '" .. class_name .. "' contains reserved property '" .. k .. "'", 0)
            end
        end


        if class.props.Init and type(class.props.Init) ~= "function" then
            error("Mixin '" .. class_name .. "' method 'Init' must be a function.", 0)
        end


        if is_fcm then
            class.props.MixinParent = mixin_private.get_parent_class(mixin_private.fcm_to_fc_class_name(class_name))

            if class.props.MixinParent then
                class.props.MixinParent = mixin_private.fc_to_fcm_class_name(class.props.MixinParent)

                mixin_private.load_mixin_class(class.props.MixinParent)


                class.init = mixin_classes[class.props.MixinParent].init and utils.copy_table(mixin_classes[class.props.MixinParent].init) or {}

                if class.props.Init then
                    table.insert(class.init, class.props.Init)
                end



                for k, v in pairs(mixin_classes[class.props.MixinParent].props) do
                    if type(class.props[k]) == "nil" then
                        class.props[k] = utils.copy_table(v)
                    end
                end
            end


        else

            if not class.props.MixinParent then
                error("Mixin '" .. class_name .. "' does not have a 'MixinParent' property defined.", 0)
            end

            mixin_private.load_mixin_class(class.props.MixinParent)


            if not mixin_classes[class.props.MixinParent] then
                error("Unable to load mixin '" .. class.props.MixinParent .. "' as parent of '" .. class_name .. "'", 0)
            end


            class.props.MixinBase = mixin_private.is_fcm_class_name(class.props.MixinParent) and class.props.MixinParent or mixin_classes[class.props.MixinParent].props.MixinBase
        end


        class.props.MixinClass = class_name

        mixin_classes[class_name] = class
    end




    local pcall_line = debug.getinfo(1, "l").currentline + 2
    local function catch_and_rethrow(tryfunczzz, levels, ...)
        return mixin_private.pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))
    end


    local mixin_file_name = debug.getinfo(1, "S").source
    mixin_file_name = mixin_file_name:sub(1, 1) == "@" and mixin_file_name:sub(2) or nil


    function mixin_private.pcall_wrapper(levels, success, result, ...)
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
                and mixin_file_name
                and (file_is_truncated and mixin_file_name:sub(-1 * file:len()) == file or file == mixin_file_name)
                and tonumber(line) == pcall_line
            then
                local d = debug.getinfo(levels, "n")


                msg = msg:gsub("'tryfunczzz'", "'" .. (d.name or "") .. "'")


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



    local function proxy(t, ...)
        local n = select("#", ...)

        if n == 0 then
            return t
        end


        for i = 1, n do
            mixin_private.enable_mixin(select(i, ...))
        end
        return ...
    end


    function mixin_private.create_fluid_proxy(func, func_name)
        return function(t, ...)
            return proxy(t, catch_and_rethrow(func, 2, t, ...))
        end
    end


    function mixin_private.enable_mixin(object, fcm_class_name)
        if not library.is_finale_object(object) or mixin_props[object] then return object end

        mixin_private.apply_mixin_foundation(object)
        fcm_class_name = fcm_class_name or mixin_private.fc_to_fcm_class_name(mixin_private.get_class_name(object))
        mixin_props[object] = {}

        mixin_private.load_mixin_class(fcm_class_name)

        if mixin_classes[fcm_class_name].init then
            for _, v in pairs(mixin_classes[fcm_class_name].init) do
                v(object)
            end
        end

        return object
    end



    function mixin_private.apply_mixin_foundation(object)
        if not object or not library.is_finale_object(object) or object.IsMixinReady then return end


        local meta = getmetatable(object)


        local original_index = meta.__index
        local original_newindex = meta.__newindex

        local fcm_class_name = mixin_private.fc_to_fcm_class_name(mixin_private.get_class_name(object))

        meta.__index = function(t, k)


            if k == "IsMixinReady" then return true end


            if not mixin_props[t] then return original_index(t, k) end

            local prop


            if type(k) == "string" and k:sub(-1) == "_" then

                prop = original_index(t, k:sub(1, -2))


            elseif type(mixin_props[t][k]) ~= "nil" then
                prop = mixin_props[t][k]


            elseif type(mixin_classes[fcm_class_name].props[k]) ~= "nil" then
                prop = mixin_classes[fcm_class_name].props[k]


                if type(prop) == "table" then
                    mixin_props[t][k] = utils.copy_table(prop)
                    prop = mixin[t][k]
                end


            else
                prop = original_index(t, k)
            end

            if type(prop) == "function" then
                return mixin_private.create_fluid_proxy(prop, k)
            else
                return prop
            end
        end



        meta.__newindex = function(t, k, v)

            if not mixin_props[t] then return catch_and_rethrow(original_newindex, 2, t, k, v) end


            if type(k) == "string" and k:sub(-1) == "_" then
                error("Mixin methods and properties cannot end in an underscore.", 2)
            end


            if reserved_props[k] then
                error("Cannot set reserved property '" .. k .. "'", 2)
            end

            local type_v_original = type(original_index(t, k))


            if type_v_original == "nil" then
                local type_v_mixin = type(mixin_props[t][k])
                local type_v = type(v)



                if type_v_mixin ~= "nil" then
                    if type_v == "function" and type_v_mixin ~= "function" then
                        error("A mixin method cannot be overridden with a property.", 2)
                    elseif type_v_mixin == "function" and type_v ~= "function" then
                        error("A mixin property cannot be overridden with a method.", 2)
                    end
                end

                mixin_props[t][k] = v


            elseif type_v_original == "function" then
                if type(v) ~= "function" then
                    error("A mixin method cannot be overridden with a property.", 2)
                end

                mixin_props[t][k] = v


            else
                catch_and_rethrow(original_newindex, 2, t, k, v)
            end
        end
    end


    function mixin_private.subclass(object, class_name)
        if not library.is_finale_object(object) then
            error("Object is not a finale object.", 2)
        end

        if not catch_and_rethrow(mixin_private.subclass_helper, 2, object, class_name) then
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


        if mixin_private.is_fcm_class_name(mixin_classes[class_name].props.MixinParent) and mixin_classes[class_name].props.MixinParent ~= object.MixinClass then
            return false
        end


        if mixin_classes[class_name].props.MixinParent ~= object.MixinClass then
            if not catch_and_rethrow(mixin_private.subclass_helper, 2, object, mixin_classes[class_name].props.MixinParent) then
                return false
            end
        end


        local props = mixin_props[object]
        for k, v in pairs(mixin_classes[class_name].props) do
            props[k] = utils.copy_table(v)
        end


        if mixin_classes[class_name].props.Init then
            catch_and_rethrow(object.Init, 2, object)
        end

        return true
    end


    function mixin_private.create_fcm(class_name, ...)
        mixin_private.load_mixin_class(class_name)
        if not mixin_classes[class_name] then return nil end

        return mixin_private.enable_mixin(catch_and_rethrow(finale[mixin_private.fcm_to_fc_class_name(class_name)], 2, ...))
    end


    function mixin_private.create_fcx(class_name, ...)
        mixin_private.load_mixin_class(class_name)
        if not mixin_classes[class_name] then return nil end

        local object = mixin_private.create_fcm(mixin_classes[class_name].props.MixinBase, ...)

        if not object then return nil end

        if not catch_and_rethrow(mixin_private.subclass_helper, 2, object, class_name, false) then
            return nil
        end

        return object
    end


    mixin_public.subclass = mixin_private.subclass


    function mixin_public.is_instance_of(object, class_name)
        if not library.is_finale_object(object) then
            return false
        end




        local object_type = (mixin_private.is_fcx_class_name(object.MixinClass) and 2) or (mixin_private.is_fcm_class_name(object.MixinClass) and 1) or 0
        local class_type = (mixin_private.is_fcx_class_name(class_name) and 2) or (mixin_private.is_fcm_class_name(class_name) and 1) or 0


        if (object_type == 0 and class_type == 1) or (object_type == 0 and class_type == 2) or (object_type == 1 and class_type == 2) or (object_type == 2 and class_type == 0) then
            return false
        end

        local parent = object_type == 0 and mixin_private.get_class_name(object) or object.MixinClass


        if object_type == 2 then
            repeat
                if parent == class_name then
                    return true
                end


                parent = mixin_classes[parent].props.MixinParent
            until mixin_private.is_fcm_class_name(parent)
        end


        if object_type > 0 then
            parent = mixin_private.fcm_to_fc_class_name(parent)
        end

        if class_type > 0 then
            class_name = mixin_private.fcm_to_fc_class_name(class_name)
        end


        repeat
            if parent == class_name then
                return true
            end

            parent = mixin_private.get_parent_class(parent)
        until not parent


        return false
    end


    function mixin_public.assert_argument(value, expected_type, argument_number)
        local t, tt

        if library.is_finale_object(value) then
            t = value.MixinClass
            tt = mixin_private.is_fcx_class_name(t) and value.MixinBase or mixin_private.get_class_name(value)
        else
            t = type(value)
        end

        if type(expected_type) == "table" then
            for _, v in ipairs(expected_type) do
                if t == v or tt == v then
                    return
                end
            end

            expected_type = table.concat(expected_type, " or ")
        else
            if t == expected_type or tt == expected_type then
                return
            end
        end

        error("bad argument #" .. tostring(argument_number) .. " to 'tryfunczzz' (" .. expected_type .. " expected, got " .. (t or tt) .. ")", 3)
    end


    mixin_public.force_assert_argument = mixin_public.assert_argument


    function mixin_public.assert(condition, message, no_level)
        if not condition then
            error(message, no_level and 0 or 3)
        end
    end


    mixin_public.force_assert = mixin_public.assert


    if finenv.IsRGPLua and not finenv.DebugEnabled then
        mixin_public.assert_argument = function() end
        mixin_public.assert = mixin_public.assert_argument
    end


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
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Version = "v1.40"
    finaleplugin.Date = "2022/09/05"
    finaleplugin.Notes = [[
        Several situations including cross-staff notation (rests should be centred between the staves)
        require adjusting the vertical position (offset) of rests.
        This script duplicates the action of Finale's inbuilt "Move rests..." plug-in but needs no mouse activity.
        It is also an easy way to reset rest offsets to zero in every layer, the default setting.
        Newly created rests are "floating" and will avoid entries in other layers (if present)
        using the setting for "Adjust Floating Rests by..." in `Document Options...` -> `Layers`.
        This script stops them "floating", instead "fixing" them to a specific offset from the middle staff line.
        To return them to "floating", select the "Zero = Floating Rest" checkbox and set the offset to zero.
    ]]
   return "Rest Offsets", "Rest Offsets", "Rest vertical offsets"
end
local mixin = require("library.mixin")
config = config or {}
function is_error()
    local msg = ""
    if math.abs(config.offset) > 20 then
        msg = "Offset level must be reasonable,\nsay -20 to 20\n(not " .. config.offset .. ")"
    elseif config.layer < 0 or config.layer > 4 then
        msg = "Layer number must be an\ninteger between zero and 4\n(not " .. config.layer .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertNeutral("script: " .. plugindef(), msg)
        return true
    end
    return false
end
function make_dialog()
    local horizontal = 110
    local y_level = {15, 45, 75}
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0
    local answer = {}
    local dialog = mixin.FCXCustomLuaWindow():SetTitle( plugindef() )
    local texts = {
        { "Vertical offset:", config.offset or 0, y_level[1] },
        { "Layer# 1-4 (0 = all):", config.layer or 0, y_level[2]  },
    }
    for i, v in ipairs(texts) do
        dialog:CreateStatic(0, v[3]):SetText(v[1]):SetWidth(horizontal)
        answer[i] = dialog:CreateEdit(horizontal, v[3] - mac_offset):SetInteger(v[2]):SetWidth(50)
    end
    local checked = config.zero_floating and 1 or 0
    answer[3] = dialog:CreateCheckbox(0, texts[2][3] + 30):SetText("Zero = Floating Rest"):SetWidth(horizontal * 2):SetCheck(checked)
    texts = {
        {  "4", 5, "= top staff line", 0 },
        {  "0", 5, "= middle staff line", 15 },
        { "-4", 0, "= bottom staff line", 30 },
        { "", 0, "(for 5-line staff)", 45 },
    }
    for _, v in ipairs(texts) do
        dialog:CreateStatic(horizontal + 60 + v[2], v[4]):SetText(v[1])
        dialog:CreateStatic(horizontal + 75, v[4]):SetText(v[3]):SetWidth(horizontal)
    end
    dialog:CreateButton(128, y_level[3]):SetText("?"):SetWidth(20):AddHandleCommand(function(self)
        local msg = "Newly created rests are \"floating\" and will avoid entries in other layers (if present) "
        .. "using the setting for \"Adjust Floating Rests by...\" in \"Document Options...\" -> \"Layers\". \n\n"
        .. "This script stops rests \"floating\", instead \"fixing\" them to a specific offset from the middle staff line. "
        .. "To return them to \"floating\", select the \"Zero = Floating Rest\" option and set the offset to zero."
        finenv.UI():AlertNeutral(msg, "Rest Offsets Info")
    end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        config.offset = answer[1]:GetInteger()
        config.layer = answer[2]:GetInteger()
        config.zero_floating = (answer[3]:GetCheck() == 1)
        dialog:StorePosition()
        config.pos_x = dialog.StoredX
        config.pos_y = dialog.StoredY
    end)
    return dialog
end
function make_the_change()
    if finenv.RetainLuaState ~= nil then
        finenv.RetainLuaState = true
    end
    for entry in eachentrysaved(finenv.Region(), config.layer) do
        if entry:IsRest() then
            if config.offset == 0 and config.zero_floating then
                entry:SetFloatingRest(true)
            else
                local rest_prop = "OtherRestPosition"
                local duration = entry.Duration
                if duration >= finale.BREVE then
                    rest_prop = "DoubleWholeRestPosition"
                elseif duration >= finale.WHOLE_NOTE then
                    rest_prop = "WholeRestPosition"
                elseif duration >= finale.HALF_NOTE then
                    rest_prop = "HalfRestPosition"
                end
                local staff_spec = finale.FCCurrentStaffSpec()
                staff_spec:LoadForEntry(entry)
                local total_offset = staff_spec[rest_prop] + config.offset
                entry:MakeMovableRest()
                local rest = entry:GetItemAt(0)
                local curr_staffpos = rest:CalcStaffPosition()
                entry:SetRestDisplacement(entry:GetRestDisplacement() + total_offset - curr_staffpos)
            end
        end
    end
end
function change_rest_offset()
    local dialog = make_dialog()
    if config.pos_x and config.pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
        dialog:RestorePosition()
    end
    if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK or is_error() then
        return
    end
    make_the_change()
end
change_rest_offset()

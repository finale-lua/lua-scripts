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
        local path = ""
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

            local osutils = finenv.EmbeddedLuaOSUtils and utils.require_embedded("luaosutils")
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
package.preload["library.layer"] = package.preload["library.layer"] or function()

    local layer = {}

    function layer.copy(region, source_layer, destination_layer, clone_articulations)
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        source_layer = source_layer - 1
        destination_layer = destination_layer - 1
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local noteentry_source_layer = finale.FCNoteEntryLayer(source_layer, staffNum, start, stop)
            noteentry_source_layer:SetUseVisibleLayer(false)
            noteentry_source_layer:Load()
            local noteentry_destination_layer = noteentry_source_layer:CreateCloneEntries(
                destination_layer, staffNum, start)
            noteentry_destination_layer:Save()
            noteentry_destination_layer:CloneTuplets(noteentry_source_layer)

            if clone_articulations and noteentry_source_layer.Count == noteentry_destination_layer.Count then
                for index = 0, noteentry_destination_layer.Count - 1 do
                    local source_entry = noteentry_source_layer:GetItemAt(index)
                    local destination_entry = noteentry_destination_layer:GetItemAt(index)
                    local source_artics = source_entry:CreateArticulations()
                    for articulation in each (source_artics) do
                        articulation:SetNoteEntry(destination_entry)
                        articulation:SaveNew()
                    end
                end
            end
            noteentry_destination_layer:Save()
        end
    end

    function layer.clear(region, layer_to_clear)
        layer_to_clear = layer_to_clear - 1
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local  noteentry_layer = finale.FCNoteEntryLayer(layer_to_clear, staffNum, start, stop)
            noteentry_layer:SetUseVisibleLayer(false)
            noteentry_layer:Load()
            noteentry_layer:ClearAllEntries()
        end
    end

    function layer.swap(region, swap_a, swap_b)

        swap_a = swap_a - 1
        swap_b = swap_b - 1
        for measure, staff_number in eachcell(region) do
            local cell_frame_hold = finale.FCCellFrameHold()
            cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
            local loaded = cell_frame_hold:Load()
            local cell_clef_changes = loaded and cell_frame_hold.IsClefList and cell_frame_hold:CreateCellClefChanges() or nil
            local  noteentry_layer_one = finale.FCNoteEntryLayer(swap_a, staff_number, measure, measure)
            noteentry_layer_one:SetUseVisibleLayer(false)
            noteentry_layer_one:Load()
            noteentry_layer_one.LayerIndex = swap_b

            local  noteentry_layer_two = finale.FCNoteEntryLayer(swap_b, staff_number, measure, measure)
            noteentry_layer_two:SetUseVisibleLayer(false)
            noteentry_layer_two:Load()
            noteentry_layer_two.LayerIndex = swap_a
            noteentry_layer_one:Save()
            noteentry_layer_two:Save()
            if loaded then
                local new_cell_frame_hold = finale.FCCellFrameHold()
                new_cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
                if new_cell_frame_hold:Load() then
                    if cell_frame_hold.IsClefList then
                        if new_cell_frame_hold.SetCellClefChanges then
                            new_cell_frame_hold:SetCellClefChanges(cell_clef_changes)
                        end

                    else
                        new_cell_frame_hold.ClefIndex = cell_frame_hold.ClefIndex
                    end
                    new_cell_frame_hold:Save()
                end
            end
        end
    end

    function layer.max_layers()
        return finale.FCLayerPrefs.GetMaxLayers and finale.FCLayerPrefs.GetMaxLayers() or 4
    end
    return layer
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
package.preload["library.tie"] = package.preload["library.tie"] or function()

    local tie = {}
    local note_entry = require('library.note_entry')

    local equal_note = function(entry, target_note, for_tied_to, tie_must_exist)
        local found_note = entry:FindPitch(target_note)
        if not found_note or not tie_must_exist then
            return found_note
        end
        if for_tied_to then
            if found_note.TieBackwards then
                return found_note
            end
        else
            if found_note.Tie then
                return found_note
            end
        end
        return nil
    end

    function tie.calc_tied_to(note, tie_must_exist)
        if not note then
            return nil
        end
        local next_entry = note.Entry
        if next_entry then
            if next_entry.Voice2Launch then
                next_entry = note_entry.get_next_same_v(next_entry)
            else
                next_entry = next_entry:Next()
            end
            if next_entry and not next_entry.GraceNote then
                local tied_to_note = equal_note(next_entry, note, true, tie_must_exist)
                if tied_to_note then
                    return tied_to_note
                end
                if next_entry.Voice2Launch then
                    local next_v2_entry = next_entry:Next()
                    tied_to_note = equal_note(next_v2_entry, note, true, tie_must_exist)
                    if tied_to_note then
                        return tied_to_note
                    end
                end
            end
        end
        return nil
    end

    function tie.calc_tied_from(note, tie_must_exist)
        if not note then
            return nil
        end
        local entry = note.Entry
        while true do
            entry = entry:Previous()
            if not entry then
                break
            end
            tied_from_note = equal_note(entry, note, false, tie_must_exist)
            if tied_from_note then
                return tied_from_note
            end
        end
    end

    function tie.calc_tie_span(note, for_tied_to, tie_must_exist)
        local start_measnum = (for_tied_to and note.Entry.Measure > 1) and note.Entry.Measure - 1 or note.Entry.Measure
        local end_measnum = for_tied_to and note.Entry.Measure or note.Entry.Measure + 1
        local note_entry_layer = finale.FCNoteEntryLayer(note.Entry.LayerNumber - 1, note.Entry.Staff, start_measnum, end_measnum)
        note_entry_layer:Load()
        local same_entry
        for entry in each(note_entry_layer) do
            if entry.EntryNumber == note.Entry.EntryNumber then
                same_entry = entry
                break
            end
        end
        if not same_entry then
            return note_entry_layer
        end
        local note_entry_layer_note = same_entry:GetItemAt(note.NoteIndex)
        local start_note = for_tied_to and tie.calc_tied_from(note_entry_layer_note, tie_must_exist) or note_entry_layer_note
        local end_note = for_tied_to and note_entry_layer_note or tie.calc_tied_to(note_entry_layer_note, tie_must_exist)
        return note_entry_layer, start_note, end_note
    end

    function tie.calc_default_direction(note, for_tieend, tie_prefs)
        if for_tieend then
            if not note.TieBackwards then
                return 0
            end
        else
            if not note.Tie then
                return 0
            end
        end
        if not tie_prefs then
            tie_prefs = finale.FCTiePrefs()
            tie_prefs:Load(0)
        end
        local stemdir = note.Entry:CalcStemUp() and 1 or -1
        if note.Entry.Count > 1 then




            if note.NoteIndex == 0 then
                return finale.TIEMODDIR_UNDER
            end
            if note.NoteIndex == note.Entry.Count - 1 then
                return finale.TIEMODDIR_OVER
            end
            local inner_default = 0
            if tie_prefs.ChordDirectionType ~= finale.TIECHORDDIR_STEMREVERSAL then
                if note.NoteIndex < math.floor(note.Entry.Count / 2) then
                    inner_default = finale.TIEMODDIR_UNDER
                end
                if note.NoteIndex >= math.floor((note.Entry.Count + 1) / 2) then
                    inner_default = finale.TIEMODDIR_OVER
                end
                if tie_prefs.ChordDirectionType == finale.TIECHORDDIR_OUTSIDEINSIDE then
                    inner_default = (stemdir > 0) and finale.TIEMODDIR_UNDER or finale.TIEMODDIR_OVER
                end
            end
            if inner_default == 0 or tie_prefs.ChordDirectionType == finale.TIECHORDDIR_STEMREVERSAL then
                local staff_position = note:CalcStaffPosition()
                local curr_staff = finale.FCCurrentStaffSpec()
                curr_staff:LoadForEntry(note.Entry)
                inner_default = staff_position < curr_staff.StemReversalPosition and finale.TIEMODDIR_UNDER or finale.TIEMODDIR_OVER
            end
            if inner_default ~= 0 then
                if tie_prefs.ChordDirectionOpposingSeconds then
                    if inner_default == finale.TIEMODDIR_OVER and not note:IsUpper2nd() and note:IsLower2nd() then
                        return finale.TIEMODDIR_UNDER
                    end
                    if inner_default == finale.TIEMODDIR_UNDER and note:IsUpper2nd() and not note:IsLower2nd() then
                        return finale.TIEMODDIR_OVER
                    end
                end
                return inner_default
            end
        else
            local adjacent_stemdir = 0
            local note_entry_layer, start_note, end_note = tie.calc_tie_span(note, for_tieend, true)
            if for_tieend then




                if end_note then
                    local start_entry = end_note.Entry:Previous()
                    if start_entry then
                        adjacent_stemdir = start_entry:CalcStemUp() and 1 or -1
                    end
                end
            else
                if end_note then
                    adjacent_stemdir = end_note.Entry:CalcStemUp() and 1 or -1
                end
                if adjacent_stemdir == 0 and start_note then






                    local next_entry = start_note.Entry:Next()
                    if next_entry and not next_entry:IsRest() then
                        adjacent_stemdir = next_entry:CalcStemUp() and 1 or -1
                        if not next_entry.FreezeStem and next_entry.Voice2Launch and adjacent_stemdir == stemdir then
                            next_entry = next_entry:Next()
                            if next_entry then
                                adjacent_stemdir = next_entry:CalcStemUp() and 1 or -1
                            end
                        end
                    end
                end
                if adjacent_stemdir ~= 0 and adjacent_stemdir ~= stemdir then
                    if tie_prefs.MixedStemDirectionType == finale.TIEMIXEDSTEM_OVER then
                        return finale.TIEMODDIR_OVER
                    elseif tie_prefs.MixedStemDirectionType == finale.TIEMIXEDSTEM_UNDER then
                        return finale.TIEMODDIR_UNDER
                    end
                end
            end
        end
        return (stemdir > 0) and finale.TIEMODDIR_UNDER or finale.TIEMODDIR_OVER
    end
    local calc_layer_is_visible = function(staff, layer_number)
        local altnotation_layer = staff.AltNotationLayer
        if layer_number ~= altnotation_layer then
            return staff.AltShowOtherNotes
        end
        local hider_altnotation_types = {
            finale.ALTSTAFF_BLANKNOTATION, finale.ALTSTAFF_SLASHBEATS, finale.ALTSTAFF_ONEBARREPEAT, finale.ALTSTAFF_TWOBARREPEAT, finale.ALTSTAFF_BLANKNOTATIONRESTS,
        }
        local altnotation_type = staff.AltNotationStyle
        for _, v in pairs(hider_altnotation_types) do
            if v == altnotation_type then
                return false
            end
        end
        return true
    end
    local calc_other_layers_visible = function(entry)
        local staff = finale.FCCurrentStaffSpec()
        staff:LoadForEntry(entry)
        for layer = 1, finale.FCLayerPrefs.GetMaxLayers() do
            if layer ~= entry.LayerNumber and calc_layer_is_visible(staff, layer) then
                local layer_prefs = finale.FCLayerPrefs()
                if layer_prefs:Load(layer - 1) and not layer_prefs.HideWhenInactive then
                    local layer_entries = finale.FCNoteEntryLayer(layer - 1, entry.Staff, entry.Measure, entry.Measure)
                    if layer_entries:Load() then
                        for layer_entry in each(layer_entries) do
                            if layer_entry.Visible then
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end
    local layer_stem_direction = function(layer_prefs, entry)
        if layer_prefs.UseFreezeStemsTies then
            if layer_prefs.UseRestOffsetInMultiple then
                if not entry:CalcMultiLayeredCell() then
                    return 0
                end
                if layer_prefs.IgnoreHiddenNotes and not calc_other_layers_visible(entry) then
                    return 0
                end
            end
            return layer_prefs.FreezeStemsUp and 1 or -1
        end
        return 0
    end
    local layer_tie_direction = function(entry)
        local layer_prefs = finale.FCLayerPrefs()
        if not layer_prefs:Load(entry.LayerNumber - 1) then
            return 0
        end
        local layer_stemdir = layer_stem_direction(layer_prefs, entry)
        if layer_stemdir ~= 0 and layer_prefs.FreezeTiesSameDirection then
            return layer_stemdir > 0 and finale.TIEMODDIR_OVER or finale.TIEMODDIR_UNDER
        end
        return 0
    end

    function tie.calc_direction(note, tie_mod, tie_prefs)


        if tie_mod.TieDirection ~= finale.TIEMODDIR_AUTOMATIC then
            return tie_mod.TieDirection
        end
        if note.Entry.SplitStem then
            return note.UpstemSplit and finale.TIEMODDIR_OVER or finale.TIEMODDIR_UNDER
        end
        local layer_tiedir = layer_tie_direction(note.Entry)
        if layer_tiedir ~= 0 then
            return layer_tiedir
        end
        if note.Entry.Voice2Launch or note.Entry.Voice2 then
            return note.Entry:CalcStemUp() and finale.TIEMODDIR_OVER or finale.TIEMODDIR_UNDER
        end
        if note.Entry.FlipTie then
            return note.Entry:CalcStemUp() and finale.TIEMODDIR_OVER or finale.TIEMODDIR_UNDER
        end
        return tie.calc_default_direction(note, not tie_mod:IsStartTie(), tie_prefs)
    end
    local calc_is_end_of_system = function(note, for_pageview)
        if not note.Entry:Next() then
            local region = finale.FCMusicRegion()
            region:SetFullDocument()
            if note.Entry.Measure == region.EndMeasure then
                return true
            end
        end
        if for_pageview then
            local note_entry_layer, start_note, end_note = tie.calc_tie_span(note, false, true)
            if start_note and end_note then
                local systems = finale.FCStaffSystems()
                systems:LoadAll()
                local start_system = systems:FindMeasureNumber(start_note.Entry.Measure)
                local end_system = systems:FindMeasureNumber(end_note.Entry.Measure)
                return start_system.ItemNo ~= end_system.ItemNo
            end
        end
        return false
    end
    local has_nonaligned_2nd = function(entry)
        for note in each(entry) do
            if note:IsNonAligned2nd() then
                return true
            end
        end
        return false
    end

    function tie.calc_connection_code(note, placement, direction, for_endpoint, for_tieend, for_pageview, tie_prefs)




        if not tie_prefs then
            tie_prefs = finale.FCTiePrefs()
            tie_prefs:Load(0)
        end
        if not for_endpoint and for_tieend then
            return finale.TIEMODCNCT_SYSTEMSTART
        end
        if for_endpoint and not for_tieend and calc_is_end_of_system(note, for_pageview) then
            return finale.TIEMODCNCT_SYSTEMEND
        end
        if placement == finale.TIEPLACE_OVERINNER or placement == finale.TIEPLACE_UNDERINNER then
            local stemdir = note.Entry:CalcStemUp() and 1 or -1
            if for_endpoint then
                if tie_prefs.BeforeSingleAccidental and note.Entry.Count == 1 and note:CalcAccidental() then
                    return finale.TIEMODCNCT_ACCILEFT_NOTECENTER
                end
                if has_nonaligned_2nd(note.Entry) then
                    if (stemdir > 0 and direction ~= finale.TIEMODDIR_UNDER and note:IsNonAligned2nd()) or (stemdir < 0 and not note:IsNonAligned2nd()) then
                        return finale.TIEMODCNCT_NOTELEFT_NOTECENTER
                    end
                end
                return finale.TIEMODCNCT_ENTRYLEFT_NOTECENTER
            else
                local num_dots = note.Entry:CalcDots()
                if (tie_prefs.AfterSingleDot and num_dots == 1) or (tie_prefs.AfterMultipleDots and num_dots > 1) then
                    return finale.TIEMODCNCT_DOTRIGHT_NOTECENTER
                end
                if has_nonaligned_2nd(note.Entry) then
                    if (stemdir > 0 and not note:IsNonAligned2nd()) or (stemdir < 0 and direction ~= finale.TIEMODDIR_OVER and note:IsNonAligned2nd()) then
                        return finale.TIEMODCNCT_NOTERIGHT_NOTECENTER
                    end
                end
                return finale.TIEMODCNCT_ENTRYRIGHT_NOTECENTER
            end
        elseif placement == finale.TIEPLACE_OVEROUTERNOTE then
            return finale.TIEMODCNCT_NOTECENTER_NOTETOP
        elseif placement == finale.TIEPLACE_UNDEROUTERNOTE then
            return finale.TIEMODCNCT_NOTECENTER_NOTEBOTTOM
        elseif placement == finale.TIEPLACE_OVEROUTERSTEM then
            return for_endpoint and finale.TIEMODCNCT_NOTELEFT_NOTETOP or finale.TIEMODCNCT_NOTERIGHT_NOTETOP
        elseif placement == finale.TIEPLACE_UNDEROUTERSTEM then
            return for_endpoint and finale.TIEMODCNCT_NOTELEFT_NOTEBOTTOM or finale.TIEMODCNCT_NOTERIGHT_NOTEBOTTOM
        end
        return finale.TIEMODCNCT_NONE
    end
    local calc_placement_for_endpoint = function(note, tie_mod, tie_prefs, direction, stemdir, for_endpoint, end_note_slot, end_num_notes, end_upstem2nd, end_downstem2nd)
        local note_slot = end_note_slot and end_note_slot or note.NoteIndex
        local num_notes = end_num_notes and end_num_notes or note.Entry.Count
        local upstem2nd = end_upstem2nd ~= nil and end_upstem2nd or note.Upstem2nd
        local downstem2nd = end_downstem2nd ~= nil and end_downstem2nd or note.Downstem2nd
        if (note_slot == 0 and direction == finale.TIEMODDIR_UNDER) or (note_slot == num_notes - 1 and direction == finale.TIEMODDIR_OVER) then
            local use_outer = false
            local manual_override = false
            if tie_mod.OuterPlacement ~= finale.TIEMODSEL_DEFAULT then
                manual_override = true
                if tie_mod.OuterPlacement == finale.TIEMODSEL_ON then
                    use_outer = true
                end
            end
            if not manual_override and tie_prefs.UseOuterPlacement then
                use_outer = true
            end
            if use_outer then
                if note.Entry.Duration < finale.WHOLE_NOTE then
                    if for_endpoint then


                        if stemdir < 0 and direction == finale.TIEMODDIR_UNDER and not downstem2nd then
                            return finale.TIEPLACE_UNDEROUTERSTEM
                        end
                        if stemdir > 0 and direction == finale.TIEMODDIR_OVER and upstem2nd then
                            return finale.TIEPLACE_OVEROUTERSTEM
                        end
                    else

                        if stemdir > 0 and direction == finale.TIEMODDIR_OVER and not upstem2nd then
                            return finale.TIEPLACE_OVEROUTERSTEM
                        end
                        if stemdir < 0 and direction == finale.TIEMODDIR_UNDER and downstem2nd then
                            return finale.TIEPLACE_UNDEROUTERSTEM
                        end
                    end
                end
                return direction == finale.TIEMODDIR_UNDER and finale.TIEPLACE_UNDEROUTERNOTE or finale.TIEPLACE_OVEROUTERNOTE
            end
        end
        return direction == finale.TIEMODDIR_UNDER and finale.TIEPLACE_UNDERINNER or finale.TIEPLACE_OVERINNER
    end

    function tie.calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)
        if not tie_prefs then
            tie_prefs = finale.FCTiePrefs()
            tie_prefs:Load(0)
        end
        direction = direction and direction ~= finale.TIEMODDIR_AUTOMATIC and direction or tie.calc_direction(note, tie_mod, tie_prefs)
        local stemdir = note.Entry:CalcStemUp() and 1 or -1
        local start_placement, end_placement
        if not tie_mod:IsStartTie() then
            start_placement = calc_placement_for_endpoint(note, tie_mod, tie_prefs, direction, stemdir, false)
            end_placement = calc_placement_for_endpoint(note, tie_mod, tie_prefs, direction, stemdir, true)
        else
            start_placement = calc_placement_for_endpoint(note, tie_mod, tie_prefs, direction, stemdir, false)
            end_placement = start_placement
            local note_entry_layer, start_note, end_note = tie.calc_tie_span(note, false, true)
            if end_note then
                local next_stemdir = end_note.Entry:CalcStemUp() and 1 or -1
                end_placement = calc_placement_for_endpoint(end_note, tie_mod, tie_prefs, direction, next_stemdir, true)
            else







                local next_entry = start_note.Entry:Next()
                if next_entry then
                    if not next_entry:IsRest() and next_entry.Count > 0 then
                        if direction == finale.TIEMODDIR_UNDER then
                            local next_note = next_entry:GetItemAt(0)
                            if next_note.Displacment < note.Displacement then
                                end_placement = finale.TIEPLACE_UNDERINNER
                            else
                                local next_stemdir = next_entry:CalcStemUp() and 1 or -1
                                end_placement = calc_placement_for_endpoint(next_note, tie_mod, tie_prefs, direction, next_stemdir, true)
                            end
                        else
                            local next_note = next_entry:GetItemAt(next_entry.Count - 1)
                            if next_note.Displacment > note.Displacement then
                                end_placement = finale.TIEPLACE_OVERINNER
                            else





                                local upstem2nd = next_note.Upstem2nd
                                if next_entry:CalcStemUp() then
                                    for check_note in each(next_entry) do
                                        if check_note.Upstem2nd then
                                            upstem2nd = true
                                        end
                                    end
                                    local next_stemdir = direction == finale.TIEMODDIR_UNDER and -1 or 1
                                    end_placement = calc_placement_for_endpoint(
                                                        next_note, tie_mod, tie_prefs, direction, next_stemdir, true, next_note.NoteIndex, next_entry.Count, upstem2nd,
                                                        next_note.Downstem2nd)
                                end
                            end
                        end
                    else
                        local next_stemdir = direction == finale.TIEMODDIR_UNDER and -1 or 1
                        end_placement = calc_placement_for_endpoint(note, tie_mod, tie_prefs, direction, next_stemdir, true, note.NoteIndex, note.Entry.Count, false, false)
                    end
                else
                    if calc_is_end_of_system(note, for_pageview) then
                        end_placement = direction == finale.TIEMODDIR_UNDER and finale.TIEPLACE_UNDEROUTERSTEM or finale.TIEPLACE_OVEROUTERSTEM
                    else
                        end_placement = direction == finale.TIEMODDIR_UNDER and finale.TIEPLACE_UNDERINNER or finale.TIEPLACE_OVERINNER
                    end
                end
            end
        end

        if start_placement == finale.TIEPLACE_OVERINNER or start_placement == finale.TIEPLACE_UNDERINNER then
            end_placement = start_placement
        elseif end_placement == finale.TIEPLACE_OVERINNER or end_placement == finale.TIEPLACE_UNDERINNER then
            start_placement = end_placement
        end
        return start_placement, end_placement
    end
    local calc_prefs_offset_for_endpoint = function(note, tie_prefs, tie_placement_prefs, placement, for_endpoint, for_tieend, for_pageview)
        local tie_
        if for_endpoint then
            if calc_is_end_of_system(note, for_pageview) then
                return tie_prefs.SystemRightHorizontalOffset, tie_placement_prefs:GetVerticalEnd(placement)
            end
            return tie_placement_prefs:GetHorizontalEnd(placement), tie_placement_prefs:GetVerticalEnd(placement)
        end
        if for_tieend then
            return tie_prefs.SystemLeftHorizontalOffset, tie_placement_prefs:GetVerticalStart(placement)
        end
        return tie_placement_prefs:GetHorizontalStart(placement), tie_placement_prefs:GetVerticalStart(placement)
    end
    local activate_endpoint = function(note, tie_mod, placement, direction, for_endpoint, for_pageview, tie_prefs, tie_placement_prefs)
        local active_check_func = for_endpoint and tie_mod.IsEndPointActive or tie_mod.IsStartPointActive
        if active_check_func(tie_mod) then
            return false
        end
        local for_tieend = not tie_mod:IsStartTie()
        local connect = tie.calc_connection_code(note, placement, direction, for_endpoint, for_tieend, for_pageview, tie_prefs)
        local xoffset, yoffset = calc_prefs_offset_for_endpoint(note, tie_prefs, tie_placement_prefs, placement, for_endpoint, for_tieend, for_pageview)
        local activation_func = for_endpoint and tie_mod.ActivateEndPoint or tie_mod.ActivateStartPoint
        activation_func(tie_mod, direction == finale.TIEMODDIR_OVER, connect, xoffset, yoffset)
        return true
    end

    function tie.activate_endpoints(note, tie_mod, for_pageview, tie_prefs)
        if not tie_prefs then
            tie_prefs = finale.FCTiePrefs()
            tie_prefs:Load(0)
        end
        local tie_placement_prefs = tie_prefs:CreateTiePlacementPrefs()
        local direction = tie.calc_direction(note, tie_mod, tie_prefs)
        local lplacement, rplacement = tie.calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)
        local lactivated = activate_endpoint(note, tie_mod, lplacement, direction, false, for_pageview, tie_prefs, tie_placement_prefs)
        local ractivated = activate_endpoint(note, tie_mod, rplacement, direction, true, for_pageview, tie_prefs, tie_placement_prefs)
        if lactivated and ractivated then
            tie_mod:LocalizeFromPreferences()
        end
        return lactivated or ractivated
    end
    local calc_tie_length = function(note, tie_mod, for_pageview, direction, tie_prefs, tie_placement_prefs)
        local cell_metrics_start = finale.FCCellMetrics()
        local entry_metrics_start = finale.FCEntryMetrics()
        cell_metrics_start:LoadAtEntry(note.Entry)
        entry_metrics_start:Load(note.Entry)
        local cell_metrics_end = finale.FCCellMetrics()
        local entry_metrics_end = finale.FCEntryMetrics()
        local note_entry_layer, start_note, end_note = tie.calc_tie_span(note, false, true)
        if tie_mod:IsStartTie() then
            if end_note then
                cell_metrics_end:LoadAtEntry(end_note.Entry)
                entry_metrics_end:Load(end_note.Entry)
            end
        end
        local lplacement, rplacement = tie.calc_placement(note, tie_mod, for_pageview, direction, tie_prefs)
        local horz_start = 0
        local horz_end = 0
        local incr_start = 0
        local incr_end = 0

        local OUTER_NOTE_OFFSET_PCTG = 7.0 / 16.0
        local INNER_INCREMENT = 6
        local staff_scaling = cell_metrics_start.StaffScaling / 10000.0
        local horz_stretch = for_pageview and 1 or cell_metrics_start.HorizontalStretch / 10000.0
        if tie_mod:IsStartTie() then
            horz_start = entry_metrics_start:GetNoteLeftPosition(note.NoteIndex) / horz_stretch
            if lplacement == finale.TIEPLACE_OVERINNER or lplacement == finale.TIEPLACE_OVEROUTERSTEM or lplacement == finale.TIEPLACE_UNDERINNER then
                horz_start = horz_start + entry_metrics_start:GetNoteWidth(note.NoteIndex)
                incr_start = INNER_INCREMENT
            else
                horz_start = horz_start + (entry_metrics_start:GetNoteWidth(note.NoteIndex) * OUTER_NOTE_OFFSET_PCTG)
            end
        else
            horz_start = (cell_metrics_start.MusicStartPos * staff_scaling) / horz_stretch
        end
        if tie_mod:IsStartTie() and (not end_note or cell_metrics_start.StaffSystem ~= cell_metrics_end.StaffSystem) then
            local next_cell_metrics = finale.FCCellMetrics()
            local next_metrics_loaded = next_cell_metrics:LoadAtCell(finale.FCCell(note.Entry.Measure + 1, note.Entry.Staff))
            if not next_metrics_loaded or cell_metrics_start.StaffSystem ~= cell_metrics_end.StaffSystem then



                horz_end = (cell_metrics_start.MusicStartPos + cell_metrics_start.Width) * staff_scaling
                incr_end = cell_metrics_start.RightBarlineWidth
            else
                horz_end = next_cell_metrics.MusicStartPos * staff_scaling
            end
            horz_end = horz_end / horz_stretch
        else
            local entry_metrics = tie_mod:IsStartTie() and entry_metrics_end or entry_metrics_start
            local note_index = start_note.NoteIndex
            if end_note then


                note_index = tie_mod:IsStartTie() and end_note.NoteIndex or note_index
            end
            horz_end = entry_metrics:GetNoteLeftPosition(note_index) / horz_stretch
            if rplacement == finale.TIEPLACE_OVERINNER or rplacement == finale.TIEPLACE_UNDERINNER or rplacement == finale.TIEPLACE_UNDEROUTERSTEM then
                incr_end = -INNER_INCREMENT
            else
                horz_end = horz_end + (entry_metrics_start:GetNoteWidth(note.NoteIndex) * (1.0 - OUTER_NOTE_OFFSET_PCTG))
            end
        end
        local start_offset = tie_mod.StartHorizontalPos
        if not tie_mod:IsStartPointActive() then
            start_offset = calc_prefs_offset_for_endpoint(note, tie_prefs, tie_placement_prefs, lplacement, false, not tie_mod:IsStartTie(), for_pageview)
        end
        local end_offset = tie_mod.EndHorizontalPos
        if not tie_mod:IsEndPointActive() then
            end_offset = calc_prefs_offset_for_endpoint(note, tie_prefs, tie_placement_prefs, lplacement, true, not tie_mod:IsStartTie(), for_pageview)
        end
        local tie_length = horz_end - horz_start

        tie_length = tie_length / staff_scaling
        tie_length = tie_length + ((end_offset + incr_end) - (start_offset + incr_start))
        return math.floor(tie_length + 0.5)
    end

    function tie.calc_contour_index(note, tie_mod, for_pageview, direction, tie_prefs)
        if not tie_prefs then
            tie_prefs = finale.FCTiePrefs()
            tie_prefs:Load(0)
        end
        direction = direction and direction ~= finale.TIEMODDIR_AUTOMATIC and direction or tie.calc_direction(note, tie_mod, tie_prefs)
        local tie_placement_prefs = tie_prefs:CreateTiePlacementPrefs()
        if tie_prefs.UseTieEndStyle then
            return finale.TCONTOURIDX_TIEENDS
        end
        local tie_length = calc_tie_length(note, tie_mod, for_pageview, direction, tie_prefs, tie_placement_prefs)
        local tie_contour_prefs = tie_prefs:CreateTieContourPrefs()
        if tie_length >= tie_contour_prefs:GetSpan(finale.TCONTOURIDX_LONG) then
            return finale.TCONTOURIDX_LONG
        elseif tie_length <= tie_contour_prefs:GetSpan(finale.TCONTOURIDX_SHORT) then
            return finale.TCONTOURIDX_SHORT
        end
        return finale.TCONTOURIDX_MEDIUM, tie_length
    end
    local calc_inset_and_height = function(tie_prefs, tie_contour_prefs, length, contour_index, get_fixed_func, get_relative_func, get_height_func)



        local height = get_height_func(tie_contour_prefs, contour_index)
        local inset = tie_prefs.FixedInsetStyle and get_fixed_func(tie_contour_prefs, contour_index) or get_relative_func(tie_contour_prefs, contour_index)
        if tie_prefs.UseInterpolation and contour_index == finale.TCONTOURIDX_MEDIUM then
            local interpolation_length, interpolation_percent, interpolation_height_diff, interpolation_inset_diff
            if length < tie_contour_prefs:GetSpan(finale.TCONTOURIDX_MEDIUM) then
                interpolation_length = tie_contour_prefs:GetSpan(finale.TCONTOURIDX_MEDIUM) - tie_contour_prefs:GetSpan(finale.TCONTOURIDX_SHORT)
                interpolation_percent = (interpolation_length - tie_contour_prefs:GetSpan(finale.TCONTOURIDX_MEDIUM) + length) / interpolation_length
                interpolation_height_diff = get_height_func(tie_contour_prefs, finale.TCONTOURIDX_MEDIUM) - get_height_func(tie_contour_prefs, finale.TCONTOURIDX_SHORT)
                interpolation_inset_diff = get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_MEDIUM) - get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_SHORT)
                height = get_height_func(tie_contour_prefs, finale.TCONTOURIDX_SHORT)
                if not tie_prefs.FixedInsetStyle then
                    inset = get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_SHORT)
                end
            else
                interpolation_length = tie_contour_prefs:GetSpan(finale.TCONTOURIDX_LONG) - tie_contour_prefs:GetSpan(finale.TCONTOURIDX_MEDIUM)
                interpolation_percent = (interpolation_length - tie_contour_prefs:GetSpan(finale.TCONTOURIDX_LONG) + length) / interpolation_length
                interpolation_height_diff = get_height_func(tie_contour_prefs, finale.TCONTOURIDX_LONG) - get_height_func(tie_contour_prefs, finale.TCONTOURIDX_MEDIUM)
                interpolation_inset_diff = get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_LONG) - get_relative_func(tie_contour_prefs, finale.TCONTOURIDX_MEDIUM)
            end
            height = math.floor(0.5 + height + interpolation_height_diff * interpolation_percent)
            if not tie_prefs.FixedInsetStyle then
                inset = math.floor(0.5 + inset + interpolation_inset_diff * interpolation_percent)
            end
        end
        return inset, height
    end

    function tie.activate_contour(note, tie_mod, for_pageview, tie_prefs)
        if tie_mod:IsContourActive() then
            return false
        end
        if not tie_prefs then
            tie_prefs = finale.FCTiePrefs()
            tie_prefs:Load(0)
        end
        local direction = tie.calc_direction(note, tie_mod, tie_prefs)
        local tie_contour_index, length = tie.calc_contour_index(note, tie_mod, for_pageview, direction, tie_prefs)
        local tie_contour_prefs = tie_prefs:CreateTieContourPrefs()
        local left_inset, left_height = calc_inset_and_height(
                                            tie_prefs, tie_contour_prefs, length, tie_contour_index, tie_contour_prefs.GetLeftFixedInset, tie_contour_prefs.GetLeftRawRelativeInset,
                                            tie_contour_prefs.GetLeftHeight)
        local right_inset, right_height = calc_inset_and_height(
                                              tie_prefs, tie_contour_prefs, length, tie_contour_index, tie_contour_prefs.GetRightFixedInset, tie_contour_prefs.GetRightRawRelativeInset,
                                              tie_contour_prefs.GetRightHeight)
        tie_mod:ActivateContour(left_inset, left_height, right_inset, right_height, tie_prefs.FixedInsetStyle)
        return true
    end
    return tie
end
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.61"
    finaleplugin.Date = "2023/05/23"
    finaleplugin.CategoryTags = "Measure, Time Signature, Meter"
    finaleplugin.MinJWLuaVersion = 0.64
    finaleplugin.AdditionalMenuOptions = [[
        Measure Span Join
        Measure Span Divide
    ]]
    finaleplugin.AdditionalUndoText = [[
        Measure Span Join
        Measure Span Divide
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Join pairs of measures together by consolidating their time signatures
        Divide single measures into two by altering the time signature
    ]]
    finaleplugin.AdditionalPrefixes = [[
        span_action = "join"
        span_action = "divide"
    ]]
    finaleplugin.ScriptGroupName = "Measure Span"
    finaleplugin.ScriptGroupDescription = "Divide single measures or join measure pairs by changing time signatures"
    finaleplugin.Notes = [[This script changes the "span" of every measure in the currently selected music by
manipulating its time signature, either dividing it into two or combining it with the
following measure. Many measures with different time signatures can be modified at once.
== JOIN ==
Combine each pair of measures in the selection into one by combining their time signatures.
If they have the same time signature either double the numerator ([3/4][3/4] -> [6/4]) or
halve the denominator ([3/4][3/4] -> [3/2]). If the time signatures aren't equal, choose to either
COMPOSITE them ([2/4][3/8] -> [2/4 + 3/8]) or CONSOLIDATE them ([2/4][3/8] -> [7/8]).
(Consolidation loses current beam groupings). You can choose that a consolidated "display"
time signature is created automatically when compositing meters. "JOIN" only works on an even number of measures.
== DIVIDE ==
Divide every selected measure into two, changing the time signature by either halving the
numerator ([6/4] -> [3/4][3/4]) or doubling the denominator ([6/4] -> [6/8][6/8]).
If the measure has an odd number of beats, choose whether to put more beats in the first
measure (5->3+2) or the second (5->2+3). Measures containing composite meters will be divided
after the first composite group, or if there is only one group, after its first element.
== IN ALL CASES ==
Incomplete measures will be filled with rests before Join/Divide. Measures containing too many
notes will be trimmed to their "real" duration. Time signatures "for display only" will be removed.
Measures are either deleted or shifted in every operation so smart shapes spanning the area
need to be "restored". Selecting a SPAN of "5" will look for smart shapes to restore from 5
measures before until 5 after the selected region. (This takes noticeably longer than a SPAN of "2").
== OPTIONS ==
To configure script settings select the "Measure Span Options..." menu item, or else hold down
the SHIFT or ALT (option) key when invoking "Join" or "Divide".
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/measure_span.hash"
    return "Measure Span Options...", "Measure Span Options", "Change the default behaviour of the Measure Span script"
end
span_action = span_action or "options"
local config = {
    halve_numerator =   true,
    odd_more_first  =   true,
    double_join     =   true,
    composite_join  =   true,
    note_spacing    =   true,
    repaginate      =   false,
    display_meter   =   true,
    shape_extend    =   3,
    window_pos_x    =   false,
    window_pos_y    =   false,
}
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local tie = require("library.tie")
local script_name = "measure_span"
configuration.get_user_settings(script_name, config, true)
function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end
function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end
function note_spacing(rgn)
    if config.note_spacing then
        rgn:SetFullMeasureStack()
        rgn:SetInDocument()
        finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
    end
end
function user_options()
    local x_grid = { 15, 70, 190, 210, 305, 110 }
    local i_width = 142
    local y = 0
    local dlg = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
        local function yd(diff)
            diff = diff or 15
            y = y + diff
        end
        local function cstat(cx, cy, ctext, cwide, chigh)
            cx = (type(cx) == "string") and tonumber(cx) or x_grid[cx]
            local stat = dlg:CreateStatic(cx, cy):SetText(ctext)
            if cwide then stat:SetWidth(cwide) end
            if chigh then stat:SetHeight(chigh) end
            return stat
        end
        local function ccheck(cx, cy, cname, cwide, check, ctext, chigh)
            cx = x_grid[cx]
            local chk = dlg:CreateCheckbox(cx, cy, cname):SetWidth(cwide):SetText(ctext):SetCheck(check)
            if chigh then chk:SetHeight(chigh) end
        end
        local function chl(cx, cy, cwide)
            dlg:CreateHorizontalLine(cx, cy, cwide)
        end
    local shadow = cstat("1", y + 1, "DIVIDE EACH MEASURE INTO TWO:", x_grid[4])
    if shadow.SetTextColor then shadow:SetTextColor(180, 180, 180) end
    cstat("0", y, "DIVIDE EACH MEASURE INTO TWO:", x_grid[4])
    yd(20)
    cstat(1, y, "Halve the numerator:", x_grid[3])
    ccheck(3, y, "1", i_width, (config.halve_numerator and 1 or 0), " [6/4] -> [3/4][3/4]")
    yd()
    cstat(2, y, "OR")
    yd()
    cstat(1, y, "Double the denominator:", x_grid[3])
    ccheck(3, y, "2", i_width, (config.halve_numerator and 0 or 1), " [6/4] -> [6/8][6/8]")
    yd(25)
    chl(1, y, x_grid[5])
    yd(10)
    cstat(1, y, "If halving a numerator with an ODD number of beats:", x_grid[5])
    yd(17)
    cstat(1, y, "More beats in first measure:", x_grid[4] + 20)
    ccheck(3, y, "3", i_width, (config.odd_more_first and 1 or 0), " 3 -> 2 + 1 etc.")
    yd()
    cstat(2, y, "OR")
    yd()
    cstat(1, y, "More beats in second measure:", x_grid[4] + 20)
    ccheck(3, y, "4", i_width, (config.odd_more_first and 0 or 1), " 3 -> 1 + 2 etc.")
    yd(27)
    chl(0, y, x_grid[3] + i_width)
    chl(0, y + 2, x_grid[3] + i_width)
    chl(0, y + 3, x_grid[3] + i_width)
    yd(13)
    shadow = cstat("1", y + 1, "JOIN PAIRS OF MEASURES:", x_grid[3])
    if shadow.SetTextColor then shadow:SetTextColor(180, 180, 180) end
    cstat("0", y, "JOIN PAIRS OF MEASURES:", x_grid[3])
    yd(20)
    cstat(1, y, "If both measures have the same time signature ...", x_grid[5])
    yd(17)
    cstat(1, y, "Double the numerator:", x_grid[3])
    ccheck(3, y, "5", i_width, (config.double_join and 1 or 0), " [3/8][3/8] -> [6/8]")
    yd()
    cstat(2, y, "OR")
    yd()
    cstat(1, y, "Halve the denominator:", x_grid[3])
    ccheck(3, y, "6", i_width, (config.double_join and 0 or 1), " [3/8][3/8] -> [3/4]")
    yd(25)
    chl(1, y, x_grid[5])
    yd(5)
    cstat(1, y, "otherwise ...", x_grid[2])
    yd(17)
    cstat(1, y, "Consolidate time signatures:", x_grid[4])
    ccheck(3, y, "8", i_width, (config.composite_join and 0 or 1),
        " [2/4][3/8] -> [7/8]\n (lose beaming groups)", 30)
    yd(17)
    cstat(2, y, "OR")
    yd(17)
    cstat(1, y, "Composite time signatures:", x_grid[3])
    ccheck(3, y, "7", i_width, (config.composite_join and 1 or 0),
        " [2/4][3/8] -> [2/4+3/8]\n (keep beaming groups)", 30)
    yd(35)
    ccheck(1, y, "display", x_grid[5] + 10, (config.display_meter and 1 or 0),
        " Create \"display\" time signature when compositing\n [2/4][3/8] -> [2/4+3/8] displaying \"7/8\" )", 30)
    yd(36)
    chl(0, y, x_grid[3] + i_width)
    chl(0, y + 2, x_grid[3] + i_width)
    chl(0, y + 3, x_grid[3] + i_width)
    yd(12)
    cstat("0", y, "Preserve smart shapes within\n(Larger spans take longer)", x_grid[3], 30)
    local popup = dlg:CreatePopup(x_grid[3] - 25, y - 1, "extend"):SetWidth(35):SetSelectedItem(config.shape_extend - 2)
    for i = 2, 5 do
        popup:AddString(i)
    end
    cstat("205", y, "measure span")
    yd(38)
    cstat("0", y, "ON COMPLETION:", i_width)
    ccheck(6, y, "spacing", i_width, (config.note_spacing and 1 or 0), "Respace notes")
    dlg:CreateButton(x_grid[5], y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() finenv.UI():AlertInfo(finaleplugin.Notes:gsub(" \n", " "), "Measure Span Info") end)
    yd(18)
    ccheck(6, y, "repaginate", i_width, (config.repaginate and 1 or 0), "Repaginate entire score")

    local function radio_change(id, check)
        local matching_id = (id % 2 == 0) and (id - 1) or (id + 1)
        dlg:GetControl(tostring(matching_id)):SetCheck((check + 1) % 2)
    end
    for id = 1, 8 do
        dlg:GetControl(tostring(id)):AddHandleCommand(function(self) radio_change(id, self:GetCheck()) end)
    end
    dlg:CreateOkButton():SetText("Save")
    dlg:CreateCancelButton()
    dialog_set_position(dlg)
    dlg:RegisterHandleOkButtonPressed(function(self)
        for k, v in pairs(
            { halve_numerator = "1", odd_more_first = "3", double_join = "5", composite_join = "7",
              display_meter = "display", note_spacing = "spacing", repaginate = "repaginate" }
            ) do
            config[k] = (self:GetControl(v):GetCheck() == 1)
        end
        config.shape_extend = (self:GetControl("extend"):GetSelectedItem() + 2)
        dialog_save_position(self)
    end)
    return (dlg:ExecuteModal(nil) == finale.EXECMODAL_OK)
end
function repaginate()
    local gen_prefs = finale.FCGeneralPrefs()
    gen_prefs:LoadFirst()
    local saved = {}
    local replace_values = {
        RecalcMeasures = true,
        RespaceMeasureLayout = false,
        RetainFrozenMeasures = true
    }
    for k, v in pairs(replace_values) do
        saved[k] = gen_prefs[k]
        gen_prefs[k] = v
    end
    gen_prefs:Save()
    local all_pages = finale.FCPages()
    all_pages:LoadAll()
    for page in each(all_pages) do
        page:UpdateLayout(false)
        page:Save()
    end
    for k, _ in pairs(replace_values) do
        gen_prefs[k] = saved[k]
    end
    gen_prefs:Save()
end
function region_contains_notes(region, layer_num)
    for entry in eachentry(region, layer_num) do
        if entry.Count > 0 then return true end
    end
    return false
end
function insert_blank_measure_after(measure_num)
    local props_copy = {"PositioningNotesMode", "Barline", "SpaceAfter", "SpaceBefore", "UseTimeSigForDisplay"}
    local props_set = {"BreakMMRest", "HideCautionary", "BreakWordExtension"}
    local measure = { finale.FCMeasure(), finale.FCMeasure() }
    measure[1]:Load(measure_num)
    measure[1].UseTimeSigForDisplay = false
    finale.FCMeasures.Insert(measure_num + 1, 1)
    measure[2]:Load(measure_num + 1)
    for _, v in ipairs(props_copy) do
        measure[2][v] = measure[1][v]
    end
    measure[1].Barline = finale.BARLINE_NORMAL
    measure[1].SpaceAfter = 0
    for _, v in ipairs(props_set) do
        if measure[1][v] then
            measure[1][v] = false
            measure[2][v] = true
        end
    end
    measure[1]:Save()
    measure[2]:Save()
    return 1
end
function pad_or_truncate_cells(measure_rgn, measure_num, measure_duration)
    measure_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num)
    for slot = measure_rgn.StartSlot, measure_rgn.EndSlot do
        local staff = measure_rgn:CalcStaffNumber(slot)
        local cell_rgn = mixin.FCMMusicRegion()
        cell_rgn:SetRegion(measure_rgn):SetStartStaff(staff):SetEndStaff(staff)
        if region_contains_notes(cell_rgn, 0) then
            for layer_num = 1, layer.max_layers() do
                local entry_layer = finale.FCNoteEntryLayer(layer_num - 1, staff, measure_num, measure_num)
                entry_layer:Load()
                if entry_layer.Count > 0 then
                    local layer_duration = entry_layer:CalcFrameDuration(measure_num)
                    if layer_duration > measure_duration then

                        for entry in eachentrysaved(cell_rgn, layer_num) do
                            if entry.MeasurePos >= measure_duration then
                                entry.Duration = 0
                            elseif (entry.MeasurePos + entry.ActualDuration) > measure_duration then
                                entry.Duration = measure_duration - entry.MeasurePos

                            end
                        end
                    elseif layer_duration < measure_duration then
                        local last_note = entry_layer:GetItemAt(entry_layer.Count - 1)
                        local newentry = entry_layer:InsertEntriesAfter(last_note, 1, false)
                        if newentry ~= nil then
                            newentry:MakeRest()
                            newentry.Duration = measure_duration - layer_duration
                            newentry.Legality = true
                            newentry.Visible = true
                            entry_layer:Save()
                        end
                    end
                end
            end
        end
    end
end
function clear_composite(time_sig, top, bottom)
    if time_sig.CompositeTop and top > 0 then
        time_sig:RemoveCompositeTop(top)
    end
    if time_sig.CompositeBottom and bottom > 0 then
        time_sig:RemoveCompositeBottom(bottom)
    end
end
function extract_composite_to_array(time_sig)
    local comp_array = {}
    if time_sig.CompositeTop then
        comp_array.top = { comp = time_sig:CreateCompositeTop(), count = 0, groups = { } }
        comp_array.bottom = { count = 0, groups = { } }
        comp_array.top.count = comp_array.top.comp:GetGroupCount()
        if time_sig.CompositeBottom then
            comp_array.bottom.comp = time_sig:CreateCompositeBottom()
            comp_array.bottom.count = comp_array.bottom.comp:GetGroupCount()
        end
        for group = 0, (comp_array.top.count - 1) do
            comp_array.top.groups[group + 1] = {}
            for i = 0, (comp_array.top.comp:GetGroupElementCount(group) - 1) do
                table.insert(comp_array.top.groups[group + 1], comp_array.top.comp:GetGroupElementBeats(group, i))
            end
            if comp_array.bottom.count > 0 then
                table.insert(comp_array.bottom.groups, comp_array.bottom.comp:GetGroupElementBeatDuration(group, 0))
            end
        end
    end
    return comp_array
end
function flatten_comp_numerators(comp)
    local small_denom = finale.BREVE
    for group = 1, #comp.bottom.groups do
        local dur = comp.bottom.groups[group]
        if dur % 3 == 0 then dur = dur / 3 end
        if dur < small_denom then
            small_denom = dur
        end
    end
    local total_top = 0
    for group = 1, #comp.top.groups do
        for el = 1, #comp.top.groups[group] do
            total_top = total_top + (comp.top.groups[group][el] * comp.bottom.groups[group] / small_denom)
        end
    end
    return total_top, small_denom
end
function make_display_meter(fc_measure, comp)
    if config.display_meter then
        fc_measure.UseTimeSigForDisplay = true
        local display_sig = fc_measure:GetTimeSignatureForDisplay()
        if display_sig then
            display_sig.Beats, display_sig.BeatDuration = flatten_comp_numerators(comp)
        end
    end
end
function new_composite_top(time_sig, group_array, first, last, from_element)
    if last == 0 then last = #group_array end
    local comp_top = finale.FCCompositeTimeSigTop()
    for g = first, last do
        local group = comp_top:AddGroup(#group_array[g] - from_element + 1)
        for i = from_element, #group_array[g] do
            comp_top:SetGroupElementBeats(group, i - from_element, group_array[g][i])
        end
    end
    comp_top:SaveAll()
    time_sig:RemoveCompositeTop(1)
    time_sig:SaveNewCompositeTop(comp_top)
end
function new_composite_bottom(time_sig, group_array, first, last)
    if last == 0 then last = #group_array end
    local comp_bottom = finale.FCCompositeTimeSigBottom()
    for g = first, last do
        local group = comp_bottom:AddGroup(1)
        comp_bottom:SetGroupElementBeatDuration(group, 0, group_array[g])
    end
    comp_bottom:SaveAll()
    time_sig:RemoveCompositeBottom(finale.QUARTER_NOTE)
    time_sig:SaveNewCompositeBottom(comp_bottom)
end
function extend_smart_shape_ends(rgn, measure_num, measure_duration)
    local extend_rgn = mixin.FCMMusicRegion()
    local measures = finale.FCMeasures()
    measures:LoadAll()
    local extend_count = measure_num + config.shape_extend
    if extend_count > measures.Count then extend_count = measures.Count end
    extend_rgn:SetRegion(rgn)
        :SetStartMeasure(measure_num - config.shape_extend)
        :SetEndMeasure(extend_count)
        :SetFullMeasureStack()
    local marks = finale.FCSmartShapeMeasureMarks()
    marks:LoadAllForRegion(extend_rgn, true)
    for mark in each(marks) do
        local shape = mark:CreateSmartShape()
        local segment = { shape:GetTerminateSegmentLeft(), shape:GetTerminateSegmentRight() }
        local m = { segment[1].Measure, segment[2].Measure }
        if not shape.EntryBased and m[1] <= measure_num then
            if m[2] > measure_num then
                segment[2].Measure = m[2] + 1
            end
            for i = 1, 2 do
                if m[i] == measure_num and segment[i].MeasurePos >= measure_duration then
                    segment[i].Measure = m[i] + 1
                    segment[i].MeasurePos = segment[i].MeasurePos - measure_duration
                end
            end
            shape:Save()
        end
    end
end
function divide_measures(selection)
    local extra_measures = 0
    for measure_num = selection.EndMeasure, selection.StartMeasure, -1 do
        insert_blank_measure_after(measure_num)
        local measure = { mixin.FCMMeasure(), mixin.FCMMeasure() }
        measure[1]:Load(measure_num)
        measure[2]:Load(measure_num + 1)
        local time_sig = { measure[1]:GetTimeSignature(), measure[2]:GetTimeSignature() }
        local top = { time_sig[1].Beats, time_sig[1].Beats }
        local bottom = time_sig[1].BeatDuration
        local pair_rgn = mixin.FCMMusicRegion()
        pair_rgn:SetRegion(selection):SetFullMeasureStack()
        pad_or_truncate_cells(pair_rgn, measure_num, measure[1]:GetDuration())
        if time_sig[1].CompositeTop then

            local comp_array = extract_composite_to_array(time_sig[1])
            if comp_array.top.count == 1 then
                clear_composite(time_sig[1], comp_array.top.groups[1][1], comp_array.bottom.groups[1])
                if #comp_array.top.groups[1] == 2 then
                    clear_composite(time_sig[2], comp_array.top.groups[1][2], comp_array.bottom.groups[1])
                else
                    new_composite_top(time_sig[2], comp_array.top.groups, 1, 1, 2)
                end
            else

                if #comp_array.top.groups[1] == 1 then
                    clear_composite(time_sig[1], comp_array.top.groups[1][1], comp_array.bottom.groups[1])
                else
                    new_composite_top(time_sig[1], comp_array.top.groups, 1, 1, 1)
                    time_sig[1]:RemoveCompositeBottom(comp_array.bottom.groups[1])
                end

                if comp_array.top.count == 2 and #comp_array.top.groups[2] == 1 then
                    clear_composite(time_sig[2], comp_array.top.groups[2][1], comp_array.bottom.groups[2])
                else
                    new_composite_top(time_sig[2], comp_array.top.groups, 2, 0, 1)
                    new_composite_bottom(time_sig[2], comp_array.bottom.groups, 2, 0)
                end
            end
        else

            if config.halve_numerator then
                if top[1] == 1 then
                    if bottom % 3 == 0 then
                        bottom = bottom / 3
                        top[1] = config.odd_more_first and 2 or 1
                        top[2] = 3 - top[1]
                    else
                        top[2] = 1
                        bottom = bottom / 2
                    end
                else
                    top[1] = top[1] / 2
                    if (time_sig[1].Beats % 2) ~= 0 then
                        top[1] = math.floor(top[1])
                        if config.odd_more_first then
                            top[1] = top[1] + 1
                        end
                    end
                    top[2] = time_sig[1].Beats - top[1]
                end
            else
                bottom = bottom / 2
            end
            time_sig[1]:SetBeats(top[1]):SetBeatDuration(bottom)
            time_sig[2]:SetBeats(top[2]):SetBeatDuration(bottom)
        end
        measure[1]:Save()
        measure[2]:Save()
        extend_smart_shape_ends(pair_rgn, measure_num, measure[1]:GetDuration())
        pair_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num + 1)
        pair_rgn:RebarMusic(finale.REBARSTOP_REGIONEND, true, false)
        note_spacing(pair_rgn)
        extra_measures = extra_measures + 1
    end
    selection.EndMeasure = selection.EndMeasure + extra_measures
end
function entry_from_enum(measure, staff_num, entry_num)
    local cell = finale.FCNoteEntryCell(measure, staff_num)
    cell:Load()
    return cell:FindEntryNumber(entry_num)
end
function shift_smart_shapes(rgn, measure_num, pos_offset)
    local slurs = {}
    local measures = finale.FCMeasures()
    measures:LoadAll()
    local extend_count = measure_num + config.shape_extend + 1
    if extend_count > measures.Count then extend_count = measures.Count end
    local shift_rgn = mixin.FCMMusicRegion()
    shift_rgn:SetRegion(rgn)
        :SetStartMeasure(measure_num - config.shape_extend)
        :SetEndMeasure(extend_count)
        :SetFullMeasureStack()
    local marks = finale.FCSmartShapeMeasureMarks()
    marks:LoadAllForRegion(shift_rgn, true)
    for mark in each(marks) do
        local shape = mark:CreateSmartShape()
        local segment = { L = shape:GetTerminateSegmentLeft(), R = shape:GetTerminateSegmentRight() }
        local m = { L = segment.L.Measure, R = segment.R.Measure }
        if shape.Visible and m.L < (measure_num + 2) and m.L ~= m.R and m.R > measure_num then
            if not shape.EntryBased then
                if m.L > measure_num then
                    segment.L.Measure = m.L - 1
                    if m.L == measure_num + 1 then
                        segment.L.MeasurePos = segment.L.MeasurePos + pos_offset
                    end
                end
                if m.R > measure_num then
                    segment.R.Measure = m.R - 1
                    if m.R == measure_num + 1 then
                        segment.R.MeasurePos = segment.R.MeasurePos + pos_offset
                    end
                end
                shape:Save()

            elseif m.L == (measure_num + 1) or m.R == (measure_num + 1) then
                local entry = {
                    L = entry_from_enum(m.L, segment.L.Staff, segment.L.EntryNumber),
                    R = entry_from_enum(m.R, segment.R.Staff, segment.R.EntryNumber)
                }
                local slur =  {
                    L = { staff = segment.L.Staff, m = m.L, shape = shape },
                    R = { staff = segment.R.Staff, m = m.R - 1 },
                }
                if m.L <= measure_num then
                    slur.L.entry = entry.L
                else
                    slur.L.m = m.L - 1
                    slur.L.pos = (entry.L and entry.L.MeasurePos or 0) + pos_offset
                end
                if m.R > measure_num + 1 then
                    slur.R.entry = entry.R
                else
                    slur.R.pos = (entry.R and entry.R.MeasurePos or 0) + pos_offset
                end
                table.insert(slurs, slur)
            end
        end
    end
    local saved_expressions = {}
    shift_rgn:SetStartMeasure(measure_num + 1):SetEndMeasure(measure_num + 1)
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(shift_rgn)
    for exp in eachbackwards(expressions) do
        if exp.StaffGroupID == 0 then
            table.insert(saved_expressions, exp)
            exp:DeleteData()
        end
    end
    return slurs, saved_expressions
end
function make_entry_smartshape(start_entry, end_entry, shape)
    local seg = { L = shape:GetTerminateSegmentLeft(), R = shape:GetTerminateSegmentRight() }
    local new_shape = mixin.FCMSmartShape()
    local new_seg = { L = new_shape:GetTerminateSegmentLeft(), R = new_shape:GetTerminateSegmentRight() }
    new_shape:SetEntryAttachedFlags(true)
    for _, v in ipairs(
            {"ShapeType", "PresetShape", "LineID", "EngraverSlur",
             "MakeHorizontal", "MaintainAngle", "AvoidAccidentals"} ) do
        new_shape[v] = shape[v]
    end
    new_seg.L:SetEntry(start_entry)
    new_seg.R:SetEntry(end_entry)
    if not shape:IsSlur() then
        new_seg.L:SetCustomOffset(false)
        new_seg.R:SetCustomOffset(true)
    end
    for _, v in ipairs( {"Staff", "Measure", "NoteID", "EndpointOffsetX", "EndpointOffsetY" } ) do
        new_seg.L[v] = seg.L[v]
        new_seg.R[v] = seg.R[v]
    end
    local cpa = { old = shape:GetCtrlPointAdjust(), new = new_shape:GetCtrlPointAdjust() }
    if cpa.old.CustomShaped then
        cpa.new.CustomShaped = true
        for _, v in ipairs( { "ControlPoint1OffsetX", "ControlPoint1OffsetY",
                "ControlPoint2OffsetX", "ControlPoint2OffsetY" } ) do
            cpa.new[v] = cpa.old[v]
        end
    end
    new_shape:SaveNewEverything(start_entry, end_entry)
end
function restore_slurs(measure_num, pos_offset, slurs, expressions)
    if #slurs > 0 then
        for _, slur in ipairs(slurs) do
            for _, id in ipairs({"L", "R"}) do
                if not slur[id].entry and slur[id].pos ~= nil then
                    local cell = finale.FCNoteEntryCell(slur[id].m, slur[id].staff)
                    cell:Load()
                    slur[id].entry = cell:FindClosestPos(slur[id].pos)
                end
            end
            if slur.L.entry ~= nil and slur.R.entry ~= nil then
                make_entry_smartshape(slur.L.entry, slur.R.entry, slur.L.shape)
            end
        end
    end
    if #expressions > 0 then
        for _, exp in ipairs(expressions) do
            exp.MeasurePos = exp.MeasurePos + pos_offset
            exp:SaveNewToCell(finale.FCCell(measure_num, exp.Staff))
        end
    end
end
function save_tie_ends(region, measure)
    local ties = {}
    for slot = region.StartSlot, region.EndSlot do
        local staff = region:CalcStaffNumber(slot)
        ties[staff] = {}
        for layer_num = 1, layer.max_layers() do
            local entry_layer = finale.FCNoteEntryLayer(layer_num - 1, staff, measure, measure)
            entry_layer:Load()
            ties[staff][layer_num] = {}
            if entry_layer.Count > 0 then
                local last_entry = entry_layer:GetItemAt(entry_layer.Count - 1)
                local pos = last_entry.MeasurePos
                ties[staff][layer_num][pos] = {}
                for note in each(last_entry) do
                    if note.Tie then
                        table.insert(ties[staff][layer_num][pos], note.NoteID )
                    end
                end
            end
        end
    end
    return ties
end
function restore_tie_ends(region, measure, ties)
    for slot = region.StartSlot, region.EndSlot do
        local staff = region:CalcStaffNumber(slot)
        if ties[staff] then
            for layer_num = 1, layer.max_layers() do
                if ties[staff][layer_num] then
                    local entry_layer = finale.FCNoteEntryLayer(layer_num - 1, staff, measure, measure)
                    entry_layer:Load()
                    for entry in each(entry_layer) do
                        if ties[staff][layer_num][entry.MeasurePos] ~= nil then
                            for _, v in ipairs(ties[staff][layer_num][entry.MeasurePos]) do
                                local note = entry:FindNoteID(v)
                                local tied_to_note = tie.calc_tied_to(note)
                                if tied_to_note then
                                    note.Tie = true
                                    tied_to_note.TieBackwards = true
                                end
                            end
                        end
                    end
                    entry_layer:Save()
                end
            end
        end
    end
end
function join_measures(selection)
    if (selection.EndMeasure - selection.StartMeasure) % 2 ~= 1 then
        local msg = "Please select an EVEN number of measures for the \"Measure Span Join\" action"
        finenv.UI():AlertError(msg, "User Error")
        return
    end

    local measures_removed = 0
    for measure_num = selection.EndMeasure - 1, selection.StartMeasure, -2 do
        local measure = { finale.FCMeasure(), finale.FCMeasure() }
        measure[1]:Load(measure_num)
        measure[2]:Load(measure_num + 1)
        measure[1].UseTimeSigForDisplay = false
        measure[1].Barline = measure[2].Barline
        local time_sig = { measure[1]:GetTimeSignature(), measure[2]:GetTimeSignature()}
        local top = { time_sig[1].Beats, time_sig[2].Beats }
        local bottom = { time_sig[1].BeatDuration, time_sig[2].BeatDuration }
        local measure_dur = { measure[1]:GetDuration(), measure[2]:GetDuration() }

        local paste_rgn = mixin.FCMMusicRegion()
        paste_rgn:SetRegion(selection):SetFullMeasureStack()
        local saved_tie_ends = save_tie_ends(paste_rgn, measure_num)
        local saved_slurs, saved_expressions = shift_smart_shapes(paste_rgn, measure_num, measure_dur[1])
        pad_or_truncate_cells(paste_rgn, measure_num + 1, measure_dur[2])
        paste_rgn:SetStartMeasure(measure_num + 1):SetEndMeasure(measure_num + 1):CopyMusic()
        pad_or_truncate_cells(paste_rgn, measure_num, measure_dur[1])
        local comp_array = {}
        if time_sig[1].CompositeTop or time_sig[2].CompositeTop then

            for cnt = 1, 2 do
                comp_array[cnt] = {}
                if time_sig[cnt].CompositeTop then
                    comp_array[cnt] = extract_composite_to_array(time_sig[cnt])
                    if not time_sig[cnt].CompositeBottom then
                        comp_array[cnt].bottom = { groups = { bottom[cnt] } }
                    end
                else
                    comp_array[cnt].top = { groups = { { top[cnt] } } }
                    comp_array[cnt].bottom = { groups = { bottom[cnt] } }
                end
            end
            for i = 1, #comp_array[2].top.groups do
                table.insert(comp_array[1].top.groups, comp_array[2].top.groups[i])
                table.insert(comp_array[1].bottom.groups, comp_array[2].bottom.groups[i])
            end
            if not config.composite_join then
                local beats, dur = flatten_comp_numerators(comp_array[1])
                clear_composite(time_sig[1], beats, dur)
                time_sig[1].Beats = beats
                time_sig[1].BeatDuration = dur
            else
                new_composite_top(time_sig[1], comp_array[1].top.groups, 1, 0, 1)
                new_composite_bottom(time_sig[1], comp_array[1].bottom.groups, 1, 0)
                make_display_meter(measure[1], comp_array[1])
            end
        else

            if top[1] == top[2] and bottom[1] == bottom[2] then
                if config.double_join then
                    top[1] = top[1] * 2
                else
                    bottom[1] = bottom[1] * 2
                end
                time_sig[1].Beats = top[1]
                time_sig[1].BeatDuration = bottom[1]
            else
                comp_array = {
                    top = { groups = { { top[1] }, { top[2] } } },
                    bottom = { groups = { bottom[1], bottom[2] } }
                }
                if not config.composite_join then
                    time_sig[1].Beats, time_sig[1].BeatDuration = flatten_comp_numerators(comp_array)
                else
                    new_composite_bottom(time_sig[1], comp_array.bottom.groups, 1, 0)
                    new_composite_top(time_sig[1], comp_array.top.groups, 1, 0, 1)
                    make_display_meter(measure[1], comp_array)
                end
            end
        end
        measure[1]:Save()
        paste_rgn:SetStartMeasurePos(measure_dur[1]):SetEndMeasurePosRight()
        paste_rgn:PasteMusic()
        paste_rgn:ReleaseMusic()
        measure[1]:Save()
        restore_tie_ends(paste_rgn, measure_num, saved_tie_ends)
        restore_slurs(measure_num, measure_dur[1], saved_slurs, saved_expressions)
        paste_rgn:SetStartMeasurePos(0)
            :RebarMusic(finale.REBARSTOP_REGIONEND, true, false)

        paste_rgn:SetStartMeasure(measure_num + 1):SetEndMeasure(measure_num + 1):CutDeleteMusic()
        paste_rgn:ReleaseMusic()
        paste_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num)
        note_spacing(paste_rgn)
        measures_removed = measures_removed + 1
    end
    selection.EndMeasure = selection.EndMeasure - measures_removed
end
function measure_span()
    local mod_down = finenv.QueryInvokedModifierKeys and
        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
         or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
        )
    if mod_down or (span_action == "options") then
        local ok = user_options()
        if not ok or (span_action == "options") then return end
    end
    local selection = mixin.FCMMusicRegion()
    selection:SetRegion(finenv.Region()):SetStartMeasurePosLeft():SetEndMeasurePosRight()
    if span_action == "divide" then
        divide_measures(selection)
    elseif span_action == "join" then
        join_measures(selection)
    else
        return
    end
    selection:SetInDocument()
    if config.repaginate then repaginate() end
end
measure_span()

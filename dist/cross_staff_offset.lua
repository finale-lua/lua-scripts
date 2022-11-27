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
__imports["library.configuration"] = __imports["library.configuration"] or function()



    local configuration = {}
    local script_settings_dir = "script_settings"
    local comment_marker = "
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
    local strip_leading_trailing_whitespace = function(str)
        return str:match("^%s*(.-)%s*$")
    end
    local parse_table = function(val_string)
        local ret_table = {}
        for element in val_string:gmatch("[^,%s]+") do
            local parsed_element = parse_parameter(element)
            table.insert(ret_table, parsed_element)
        end
        return ret_table
    end
    parse_parameter = function(val_string)
        if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "\"(.+)\"", "%1")
        elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then
            return string.gsub(val_string, "'(.+)'", "%1")
        elseif "{" == val_string:sub(1, 1) and "}" == val_string:sub(#val_string, #val_string) then
            return parse_table(string.gsub(val_string, "{(.+)}", "%1"))
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
                local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at - 1))
                local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at + 1))
                file_parameters[name] = parse_parameter(val_string)
            end
        end
        for param_name, _ in pairs(parameter_list) do
            local param_val = file_parameters[param_name]
            if nil ~= param_val then
                parameter_list[param_name] = param_val
            end
        end
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
            os.execute('mkdir "' .. folder_path ..'"')
            file = io.open(file_path, "w")
        end
        if not file then
            return false
        end
        file:write("
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
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.HandlesUndo = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Version = "v1.33"
    finaleplugin.Date = "2022/08/05"
	finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        When creating cross-staff notes using the option-downarrow shortcut, the stems of
        'crossed' notes are reversed (on the wrong side of the notehead) and appear too far
        to the right (if shifting downwards) by the width of one notehead, typically 24EVPU.
        This script allows setting a horizontal offset for cross-staff notes in the
        selected region, with a different offset for non-crossed notes,
        and specify which layer to act on, 1-4 or "all layers" (0).
        This also offers a simple way to reset the horizontal offset of all selected notes to zero.
        For crossing to the staff below use (-24,0) or (-12,12).
        For crossing to the staff above use (24,0) or (12,-12).
        If you want to repeat your last settings without a confirmation dialog,
        just hold down the `shift` or `alt` (option) key when selecting the script's menu item.
    ]]
   return "CrossStaff Offset...", "CrossStaff Offset", "Offset horizontal position of cross-staff note entries"
end
local config = {
    cross_staff_offset  = 0,
    non_cross_offset = 0,
    layer = 0,
    pos_x = false,
    pos_y = false,
}
local configuration = require("library.configuration")
function is_error()
    local msg = ""
    if math.abs(config.cross_staff_offset) > 999 or math.abs(config.non_cross_offset) > 999 then
        msg = "Choose realistic offset\nvalues (say from -999 to 999)\n(not "
        .. config.cross_staff_offset .. " / " .. config.non_cross_offset .. ")"
    elseif config.layer < 0 or config.layer > 4 then
        msg = "Layer number must be an\ninteger between zero and 4\n(not " .. config.layer .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertNeutral("script: " .. plugindef(), msg)
        return true
    end
    return false
end
function create_user_dialog()
    local info_vertical = 75
    local edit_horiz = 120
    local edit_width = 75
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0
    local answer = {}
    local dialog_options = {
        { "Cross-staff offset:", "cross_staff_offset", 0 },
        { "Non-crossed offset:", "non_cross_offset", 25 },
        { "Layer 1-4 (0 = all):", "layer", 50 }
    }
    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
        function make_static(msg, horiz, vert, width, sepia)
            local static = dialog:CreateStatic(horiz, vert)
            str.LuaString = msg
            static:SetText(str)
            static:SetWidth(width)
            if sepia then
                static:SetTextColor(153, 51, 0)
            end
        end
    for i, v in ipairs(dialog_options) do
        make_static(v[1], 0, v[3], edit_horiz, false)
        answer[i] = dialog:CreateEdit(edit_horiz, v[3] - mac_offset)
        answer[i]:SetInteger(config[v[2]])
        answer[i]:SetWidth(edit_width)
        if i < 3 then
            make_static("EVPUs", edit_horiz + edit_width + 5, v[3], 75, false)
        end
    end
    make_static("cross to staff below = [ -24, 0 ] or [ -12, 12 ]", 0, info_vertical, 290, true)
    make_static("cross to staff above = [ 24, 0 ] or [ 12, -12 ]", 0, info_vertical + 18, 290, true)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function()
        config.cross_staff_offset = answer[1]:GetInteger()
        config.non_cross_offset = answer[2]:GetInteger()
        config.layer = answer[3]:GetInteger()
    end)
    dialog:RegisterCloseWindow(function()
        dialog:StorePosition()
        config.pos_x = dialog.StoredX
        config.pos_y = dialog.StoredY
    end)
    return dialog
end
function cross_staff_offset()
    configuration.get_user_settings("cross_staff_offset", config, true)

    local mod_down = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    if not mod_down then
        local dialog = create_user_dialog()
        if config.pos_x and config.pos_y then
            dialog:StorePosition()
            dialog:SetRestorePositionOnlyData(config.pos_x, config.pos_y)
            dialog:RestorePosition()
        end
        if dialog:ExecuteModal(nil) ~= finale.EXECMODAL_OK then
            return
        end
        if is_error() then
            return
        end
        configuration.save_user_settings("cross_staff_offset", config)
    end

    for entry in eachentrysaved(finenv.Region(), config.layer) do
        if entry:IsNote() then
            entry.ManualPosition = entry.CrossStaff and config.cross_staff_offset or config.non_cross_offset
        end
    end
end
cross_staff_offset()

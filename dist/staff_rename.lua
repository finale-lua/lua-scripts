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
function plugindef()


    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "2.0"
    finaleplugin.Date = "8/13/2022"
    finaleplugin.MinJWLuaVersion = 0.63
    finaleplugin.Notes = [[
USING THE 'STAFF RENAME' SCRIPT
This script creates a dialog containing the full and abbreviated names of all selected instruments, including multi-staff instruments such as organ or piano. This allows for quick renaming of staves, with far less mouse clicking than trying to rename them from the Score Manager.
If there is no selection, all staves will be loaded.
There are buttons for each instrument that will copy the full name into the abbreviated name field.
There is a popup at the bottom of the list that will automatically set all transposing instruments to show either the instrument and then the transposition (e.g. "Clarinet in Bb"), or the transposition and then the instrument (e.g. "Bb Clarinet").
Speaking of the Bb Clarinet... Accidentals are displayed with square brackets, so the dialog will show "B[b] Clarinet". This is then converted into symbols using the appropriate Enigma tags. All other font info is retained.
]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/staff_rename.hash"
    return "Rename Staves", "Rename Staves", "Renames selected staves"
end
local utils = require("library.utils")
local configuration = require("library.configuration")
function staff_rename()
    local script_name = "rename_staves"
    local config = {use_doc_fonts = 1}
    configuration.get_user_settings(script_name, config, true)
    local staff_count = 0
    local multi_inst = finale.FCMultiStaffInstruments()
    multi_inst:LoadAll()
    local multi_inst_grp = {}
    local multi_fullnames = {}
    local multi_full_fonts = {}
    local multi_abbnames = {}
    local multi_abb_fonts = {}
    local multi_added = {}
    local omit_staves = {}
    local multi_staff = {}
    local multi_staves = {}
    local fullnames = {}
    local abbnames = {}
    local full_fonts = {}
    local abb_fonts = {}
    local staves = {}
    local autonumber_bool = {}
    local autonumber_style = {}

    local fullname_font_info = finale.FCFontInfo()
    fullname_font_info:LoadFontPrefs(finale.FONTPREF_STAFFNAME)
    local abrev_font_info = finale.FCFontInfo()
    abrev_font_info:LoadFontPrefs(finale.FONTPREF_ABRVSTAFFNAME)
    local fullgroup_font_info = finale.FCFontInfo()
    fullgroup_font_info:LoadFontPrefs(finale.FONTPREF_GROUPNAME)
    local abbrevgroup_font_info = finale.FCFontInfo()
    abbrevgroup_font_info:LoadFontPrefs(finale.FONTPREF_ABRVGROUPNAME)

    local static_staff = {}
    local edit_fullname = {}
    local edit_abbname = {}
    local copy_button = {}
    local autonumber_check = {}
    local autonumber_popup = {}

    local form_0_names = {"Clarinet in B[b]", "Clarinet in A", "Clarinet in E[b]","Horn in F", "Trumpet in B[b]", "Trumpet in C", "Horn in E[b]", "Piccolo Trumpet in A", "Trumpet in D", "Cornet in E[b]", "Pennywhistle in D", "Pennywhistle in G", "Tin Whistle in B[b]", "Melody Sax in C"}
    local form_1_names = {"B[b] Clarinet", "A Clarinet", "E[b] Clarinet", "F Horn", "B[b] Trumpet", "C Trumpet", "E[b] Horn", "A Piccolo Trumpet", "D Trumpet", "E[b] Cornet", "D Pennywhistle", "G Pennywhistle", "B[b] Tin Whistle", "C Melody Sax"}
    function enigma_to_accidental(str)
        str.LuaString = string.gsub(str.LuaString, "%^flat%(%)", "[b]")
        str.LuaString = string.gsub(str.LuaString, "%^natural%(%)", "[n]")
        str.LuaString = string.gsub(str.LuaString, "%^sharp%(%)", "[#]")
        str:TrimEnigmaTags()
        return str
    end
    function accidental_to_enigma(s)
        s.LuaString = string.gsub(s.LuaString, "%[b%]", "^flat()")
        s.LuaString = string.gsub(s.LuaString, "%[n%]", "^natural()")
        s.LuaString = string.gsub(s.LuaString, "%[%#%]", "^sharp()")
        return s
    end
    for inst in each(multi_inst) do
        table.insert(multi_inst_grp, inst.GroupID)
        local grp = finale.FCGroup()
        grp:Load(0, inst.GroupID)
        local str = grp:CreateFullNameString()
        local font = str:CreateLastFontInfo()
        enigma_to_accidental(str)
        table.insert(multi_fullnames, str.LuaString)
        local font_enigma = finale.FCString()
        font_enigma = font:CreateEnigmaString(nil)
        table.insert(multi_full_fonts, font_enigma.LuaString)

        str = grp:CreateAbbreviatedNameString()
        font = str:CreateLastFontInfo()
        font_enigma = font:CreateEnigmaString(nil)
        enigma_to_accidental(str)
        table.insert(multi_abbnames, str.LuaString)
        table.insert(multi_abb_fonts, font_enigma.LuaString)
        table.insert(multi_added, false)
        table.insert(omit_staves, inst:GetFirstStaff())
        table.insert(omit_staves, inst:GetSecondStaff())
        if inst:GetThirdStaff() ~= 0 then
            table.insert(omit_staves, inst:GetThirdStaff())
        end
        table.insert(multi_staff, inst:GetFirstStaff())
        table.insert(multi_staff, inst:GetSecondStaff())
        table.insert(multi_staff, inst:GetThirdStaff())
        table.insert(multi_staves, multi_staff)
        multi_staff = {}
    end
    local sysstaves = finale.FCSystemStaves()
    local region = finale.FCMusicRegion()
    region = finenv.Region()
    if region:IsEmpty() then
        region:SetFullDocument()
    end
    sysstaves:LoadAllForRegion(region)
    for sysstaff in each(sysstaves) do

        for i,j in pairs(multi_staves) do
            for k,l in pairs(multi_staves[i]) do
                if multi_staves[i][k] == sysstaff.Staff and multi_staves[i][k] ~= 0 then
                    local staff = finale.FCStaff()
                    staff:Load(sysstaff.Staff)
                    if multi_added[i] == false then
                        table.insert(fullnames, multi_fullnames[i])
                        staff_count = staff_count + 1
                        table.insert(abbnames, multi_abbnames[i])
                        table.insert(full_fonts, multi_full_fonts[i])
                        table.insert(abb_fonts, multi_abb_fonts[i])
                        table.insert(staves, sysstaff.Staff)
                        table.insert(autonumber_bool, staff.UseAutoNumberingStyle)
                        table.insert(autonumber_style, staff.AutoNumberingStyle)
                        multi_added[i] = true
                        goto done
                    elseif multi_added == true then
                        goto done
                    end
                end
            end
        end
        for i, j in pairs(omit_staves) do
            if omit_staves[i] == sysstaff.Staff then
                goto done
            end
        end

        local staff = finale.FCStaff()
        staff:Load(sysstaff.Staff)
        local str = staff:CreateFullNameString()
        local font = str:CreateLastFontInfo()
        enigma_to_accidental(str)
        table.insert(fullnames, str.LuaString)
        staff_count = staff_count + 1
        local font_enigma = finale.FCString()
        font_enigma = font:CreateEnigmaString(nil)
        table.insert(full_fonts, font_enigma.LuaString)
        str = staff:CreateAbbreviatedNameString()
        font = str:CreateLastFontInfo()
        enigma_to_accidental(str)
        table.insert(abbnames, str.LuaString)
        font_enigma = font:CreateEnigmaString(nil)
        table.insert(abb_fonts, font_enigma.LuaString)
        table.insert(staves, sysstaff.Staff)
        table.insert(autonumber_bool, staff.UseAutoNumberingStyle)
        table.insert(autonumber_style, staff.AutoNumberingStyle)
        ::done::
    end
    function dialog(title)
        local row_h = 20
        local row_count = 1
        local col_w = 140
        local col_gap = 20
        local str = finale.FCString()
        str.LuaString = title
        local dialog = finale.FCCustomLuaWindow()
        dialog:SetTitle(str)

        local row = {}
        for i = 1, (staff_count + 5) do
            row[i] = (i -1) * row_h
        end

        local col = {}
        for i = 1, 5 do
            col[i] = (i - 1) * col_w
            col[i] = col[i] + 40
        end

        function add_ctrl(dialog, ctrl_type, text, x, y, h, w, min, max)
            str.LuaString = tostring(text)
            local ctrl = ""
            if ctrl_type == "button" then
                ctrl = dialog:CreateButton(x, y + 2)
            elseif ctrl_type == "popup" then
                ctrl = dialog:CreatePopup(tonumber(x) or 0, tonumber(y) or 0)
            elseif ctrl_type == "checkbox" then
                ctrl = dialog:CreateCheckbox(x, y)
            elseif ctrl_type == "edit" then
                ctrl = dialog:CreateEdit(x, y)
            elseif ctrl_type == "horizontalline" then
                ctrl = dialog:CreateHorizontalLine(x, y, w)
            elseif ctrl_type == "static" then
                ctrl = dialog:CreateStatic(x, y + 4)
            elseif ctrl_type == "verticalline" then
                ctrl = dialog:CreateVerticalLine(x, y, h)
            end
            if ctrl_type == "edit" then
                ctrl:SetHeight(h - 2)
                ctrl:SetWidth(w - col_gap)
            elseif ctrl_type == "horizontalline" then
                ctrl:SetWidth(w)
            else
                ctrl:SetHeight(h)
                ctrl:SetWidth(w)
            end
            ctrl:SetText(str)
            return ctrl
        end
        local autonumber_style_list = {"Instrument 1, 2, 3", "Instrument I, II, II", "1st, 2nd, 3rd Instrument",
            "Instrument A, B, C", "1., 2., 3. Instrument"}
        local auto_x_width = 40
        local staff_num_static = add_ctrl(dialog, "static", "Staff", 0, row[1], row_h, col_w, 0, 0)
        local staff_name_full_static = add_ctrl(dialog, "static", "Full Name", col[1], row[1], row_h, col_w, 0, 0)
        local staff_name_abb_static = add_ctrl(dialog, "static", "Abbr. Name", col[2], row[1], row_h, col_w, 0, 0)
        local copy_all = add_ctrl(dialog, "button", "→", col[2] - col_gap + 2, row[1], row_h-4, 16, 0, 0)
        local master_autonumber_static = add_ctrl(dialog, "static", "Auto #", col[3] , row[1], row_h, auto_x_width, 0, 0)
        local master_autonumber_check = add_ctrl(dialog, "checkbox", "Auto #", col[3] + auto_x_width, row[1], row_h, 13, 0, 0)
        master_autonumber_check:SetCheck(1)
        local master_autonumber_popup = add_ctrl(dialog, "popup", "", col[3] + 60, row[1], row_h, col_w - col_gap, 0, 0)
        for i, k in pairs(autonumber_style_list) do
            str.LuaString = autonumber_style_list[i]
            master_autonumber_popup:AddString(str)
        end
        add_ctrl(dialog, "horizontalline", "", 0, row[2] + 8, 0, col_w * 3.5 + 20, 0, 0)
        str.LuaString = "*Custom*"
        master_autonumber_popup:AddString(str)

        for i, j in pairs(staves) do
            static_staff[i] = add_ctrl(dialog, "static", staves[i], 10, row[i + 2], row_h, col_w, 0, 0)
            edit_fullname[i] = add_ctrl(dialog, "edit", fullnames[i], col[1], row[i + 2], row_h, col_w, 0, 0)
            edit_abbname[i] = add_ctrl(dialog, "edit", abbnames[i], col[2], row[i + 2], row_h, col_w, 0, 0)
            copy_button[i] = add_ctrl(dialog, "button", "→", col[2] - col_gap + 2, row[i + 2], row_h-4, 16, 0, 0)
            autonumber_check[i] = add_ctrl(dialog, "checkbox", "", col[3] + auto_x_width, row[i+2], row_h, 13, 0, 0)
            autonumber_popup[i] = add_ctrl(dialog, "popup", "", col[3] + 60, row[i+2], row_h, col_w - 20, 0, 0)
            for key, val in pairs(autonumber_style_list) do
                str.LuaString = autonumber_style_list[key]
                autonumber_popup[i]:AddString(str)
            end
            if autonumber_bool[i] then
                autonumber_check[i]:SetCheck(1)
                autonumber_popup[i]:SetEnable(true)
            else
                autonumber_check[i]:SetCheck(0)
                autonumber_popup[i]:SetEnable(false)
                master_autonumber_check:SetCheck(0)
                master_autonumber_popup:SetEnable(false)
            end
            autonumber_popup[i]:SetSelectedItem(autonumber_style[i])
            row_count = row_count + 1
        end

        add_ctrl(dialog, "horizontalline", "", 0, row[row_count + 2] + 8, 0, col_w * 3.5 + 20, 0, 0)

        local form_select = add_ctrl(dialog, "popup", "", col[1], row[row_count + 3], row_h, col_w - col_gap, 0, 0)
        local forms = {"Instrument in Trn.","Trn. Instrument"}
        for i,j in pairs(forms) do
            str.LuaString = forms[i]
            form_select:AddString(str)
        end
        local doc_fonts_check = add_ctrl(dialog, "checkbox", "Use Document Fonts", col[2], row[row_count + 3], row_h, col_w, 0, 0)
        doc_fonts_check:SetCheck(config.use_doc_fonts)
        local hardcode_autonumber_btn = add_ctrl(dialog, "button", "Hardcode Autonumbers", col[3] + auto_x_width, row[row_count + 3], row_h, col_w, 0, 0)

        dialog:CreateOkButton()
        dialog:CreateCancelButton()

        function hardcode_autonumbers()
            local staff_name = {}
            local inst_nums = {}
            local inst_num = 1
            for i,k in pairs(staves) do
                edit_fullname[i]:GetText(str)
                local is_present = false
                for j, l in pairs(staff_name) do
                    if staff_name[j] == str.LuaString then
                        is_present = true
                    end
                end
                if not is_present then
                    table.insert(staff_name, str.LuaString)
                    table.insert(inst_nums, 1)
                end
            end
            for i,k in pairs(staves) do
                local str_two = finale.FCString()
                local is_match = false
                edit_fullname[i]:GetText(str)
                edit_abbname[i]:GetText(str_two)
                for j, l in pairs(staff_name) do
                    if (staff_name[j] == str.LuaString) and (autonumber_check[i]:GetCheck() == 1) then
                        is_match = true
                        inst_num = inst_nums[j]
                        inst_nums[j] = inst_nums[j] + 1
                    end
                end
                if is_match and (autonumber_check[i]:GetCheck() == 1) then
                    if autonumber_popup[i]:GetSelectedItem() == 0 then
                        str.LuaString = str.LuaString.." "..inst_num
                        str_two.LuaString = str_two.LuaString.." "..inst_num
                    elseif autonumber_popup[i]:GetSelectedItem() == 1 then
                        str.LuaString = str.LuaString.." "..utils.calc_roman_numeral(inst_num)
                        str_two.LuaString = str_two.LuaString.." "..utils.calc_roman_numeral(inst_num)
                    elseif autonumber_popup[i]:GetSelectedItem() == 2 then
                        str.LuaString = utils.calc_ordinal(inst_num).." "..str.LuaString
                        str_two.LuaString = utils.calc_ordinal(inst_num).." "..str_two.LuaString
                    elseif autonumber_popup[i]:GetSelectedItem() == 3 then
                        str.LuaString = str.LuaString.." "..utils.calc_alphabet(inst_num)
                        str_two.LuaString = str_two.LuaString.." "..utils.calc_alphabet(inst_num)
                    elseif autonumber_popup[i]:GetSelectedItem() == 4 then
                        str.LuaString = inst_num..". "..str.LuaString
                        str_two.LuaString = inst_num..". "..str_two.LuaString
                    end
                end
                edit_fullname[i]:SetText(str)
                edit_abbname[i]:SetText(str_two)
                autonumber_check[i]:SetCheck(0)
                autonumber_popup[i]:SetEnable(false)
                is_match = false
            end
        end

        function callback(ctrl)
            if ctrl:GetControlID() == form_select:GetControlID() then
                local form = form_select:GetSelectedItem()
                local search = {}
                local replace = {}
                if form == 0 then
                    search = form_1_names
                    replace = form_0_names
                elseif form == 1 then
                    search = form_0_names
                    replace = form_1_names
                end
                for a,b in pairs(search) do
                    search[a] = string.gsub(search[a], "%[", "%%[")
                    search[a] = string.gsub(search[a], "%]", "%%]")
                    replace[a] = string.gsub(replace[a], "%%", "")
                end
                for i,j in pairs(fullnames) do
                    edit_fullname[i]:GetText(str)
                    for k,l in pairs(search) do
                        str.LuaString = string.gsub(str.LuaString, search[k], replace[k])
                    end
                    edit_fullname[i]:SetText(str)

                    edit_abbname[i]:GetText(str)
                    for k,l in pairs(search) do
                        str.LuaString = string.gsub(str.LuaString, search[k], replace[k])
                    end
                    edit_abbname[i]:SetText(str)
                end
            end
            for i, j in pairs(edit_fullname) do
                if ctrl:GetControlID() == copy_button[i]:GetControlID() then
                    edit_fullname[i]:GetText(str)
                    edit_abbname[i]:SetText(str)
                elseif ctrl:GetControlID() == autonumber_check[i]:GetControlID() then
                    if autonumber_check[i]:GetCheck() == 1 then
                        autonumber_bool[i] = true
                        autonumber_popup[i]:SetEnable(true)
                    else
                        autonumber_bool[i] = false
                        autonumber_popup[i]:SetEnable(false)
                        master_autonumber_check:SetCheck(0)
                    end
                elseif ctrl:GetControlID() == autonumber_popup[i]:GetControlID() then
                    autonumber_style[i] = autonumber_popup[i]:GetSelectedItem()
                    master_autonumber_popup:SetSelectedItem(5)
                end
            end
            if ctrl:GetControlID() == copy_all:GetControlID() then
                for i,j in pairs(edit_fullname) do
                    edit_fullname[i]:GetText(str)
                    edit_abbname[i]:SetText(str)
                end
            elseif ctrl:GetControlID() == master_autonumber_check:GetControlID() then
                if master_autonumber_check:GetCheck() == 1 then
                    master_autonumber_popup:SetEnable(true)
                    for i, k in pairs(edit_fullname) do
                        autonumber_check[i]:SetCheck(1)
                        autonumber_popup[i]:SetEnable(true)
                    end
                else
                    master_autonumber_popup:SetEnable(false)
                    for i, k in pairs(edit_fullname) do
                        autonumber_check[i]:SetCheck(0)
                        autonumber_popup[i]:SetEnable(false)
                    end
                end
            elseif ctrl:GetControlID() == master_autonumber_popup:GetControlID() then
                if master_autonumber_popup:GetSelectedItem() < 5 then
                    for i, k in pairs(edit_fullname) do
                        autonumber_popup[i]:SetSelectedItem(master_autonumber_popup:GetSelectedItem())
                    end
                end
            elseif ctrl:GetControlID() == hardcode_autonumber_btn:GetControlID() then
                hardcode_autonumbers()
            end
        end
        dialog:RegisterHandleCommand(callback)
        if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
            config.use_doc_fonts = doc_fonts_check:GetCheck()
            configuration.save_user_settings(script_name, config)
            local str = finale.FCString()
            local font_str = finale.FCString()
            for i, j in pairs(staves) do
                for k, l in pairs(multi_staves) do
                    for m, n in pairs(multi_staves[k]) do
                        if staves[i] == multi_staves[k][m] then
                            local grp = finale.FCGroup()
                            grp:Load(0, multi_inst_grp[k])
                            edit_fullname[i]:GetText(str)
                            accidental_to_enigma(str)
                            if config.use_doc_fonts == 1 then
                                font_str = fullgroup_font_info:CreateEnigmaString(nil)
                                str.LuaString = font_str.LuaString..str.LuaString
                            else
                                str.LuaString = full_fonts[i]..str.LuaString
                            end
                            grp:SaveNewFullNameBlock(str)
                            edit_abbname[i]:GetText(str)
                            accidental_to_enigma(str)
                            if config.use_doc_fonts == 1 then
                                font_str = abbrevgroup_font_info:CreateEnigmaString(nil)
                                str.LuaString = font_str.LuaString..str.LuaString
                            else
                                str.LuaString = abb_fonts[i]..str.LuaString
                            end
                            grp:SaveNewAbbreviatedNameBlock(str)
                            grp:Save()
                        end
                    end
                end
                local staff = finale.FCStaff()
                staff:Load(staves[i])
                if autonumber_check[i]:GetCheck() == 1 then
                    staff.UseAutoNumberingStyle = true
                else
                    staff.UseAutoNumberingStyle = false
                end
                staff.AutoNumberingStyle = autonumber_popup[i]:GetSelectedItem()
                staff:Save()
                for k, l in pairs(omit_staves) do
                    if staves[i] == omit_staves[k] then
                        goto done_with_staff
                    end
                end
                edit_fullname[i]:GetText(str)
                accidental_to_enigma(str)
                if config.use_doc_fonts == 1 then
                    font_str = fullname_font_info:CreateEnigmaString(nil)
                    str.LuaString = font_str.LuaString..str.LuaString
                else
                    str.LuaString = full_fonts[i]..str.LuaString
                end
                staff:SaveNewFullNameString(str)
                edit_abbname[i]:GetText(str)
                accidental_to_enigma(str)
                if config.use_doc_fonts == 1 then
                    font_str = abrev_font_info:CreateEnigmaString(nil)
                    str.LuaString = font_str.LuaString..str.LuaString
                else
                    str.LuaString = abb_fonts[i]..str.LuaString
                end
                staff:SaveNewAbbreviatedNameString(str)
                staff:Save()
                ::done_with_staff::
            end
        end
    end
    dialog("Rename Staves")
end
staff_rename()

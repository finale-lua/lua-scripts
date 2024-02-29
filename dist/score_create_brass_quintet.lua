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
        local osutils = finenv.EmbeddedLuaOSUtils and require("luaosutils")
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
                if not handle then return "" end
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
    return score
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
function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "July 12, 2022"
    finaleplugin.CategoryTags = "Score"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        This script sets up a score for brass quintet:

        - Trumpet in C 1
        - Trumpet in C 2
        - Horn in F
        - Trombone
        - Tuba

        To use it, first open your default document or document styles. Then, run the script.
        All existing staffs will be deleted. And in their place, the brass quintet will be created.

        This script uses the standard ensemble creation configuration options.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script sets up a score for brass quintet:\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Trumpet in C 1\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Trumpet in C 2\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Horn in F\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Trombone\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab Tuba\sa180\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 To use it, first open your default document or document styles. Then, run the script. All existing staffs will be deleted. And in their place, the brass quintet will be created.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script uses the standard ensemble creation configuration options.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/score_create_brass_quintet.hash"
    return "Create brass quintet score", "Create brass quintet score", "Creates the score setup correctly for brass quintet"
end
local score = require("library.score")
local configuration = require("library.configuration")
local config = score.create_default_config()
config.systems_per_page = 2
config.large_measure_number_space = "12s"
configuration.get_parameters("score_create_brass_quintet_score.config.txt", config)
local function score_create_brass_quintet_score()
    score.reset_and_clear_score()
    local staves = {}
    staves.trumpet_1 = score.create_staff("Trumpet in C 1", "Tpt. 1", finale.FFUUID_TRUMPETC, "treble")
    staves.trumpet_2 = score.create_staff("Trumpet in C 2", "Tpt. 2", finale.FFUUID_TRUMPETC, "treble")



    staves.horn = score.create_staff("Horn in F", "Hn.", finale.FFUUID_HORNF, "alto")
    staves.trombone = score.create_staff("Trombone", "Tbn.", finale.FFUUID_TROMBONE, "bass")
    staves.tuba = score.create_staff("Tuba", "Tba.", finale.FFUUID_TUBA, "bass")
    score.create_group_primary(staves.trumpet_1, staves.tuba)
    score.create_group_secondary(staves.trumpet_1, staves.trumpet_2)
    score.set_staff_transposition(staves.horn, "F", 4, "treble")
    score.apply_config(config, {force_staves_show_time_signatures = {staves.trumpet_2}})
end
score_create_brass_quintet_score()

local __imports = {}
local __import_results = {}

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

__imports["library.client"] = function()
    --[[
    $module Client

    Get information about the current client. For the purposes of Finale Lua, the client is
    the Finale application that's running on someones machine. Therefore, the client has
    details about the user's setup, such as their Finale version, plugin version, and
    operating system.

    One of the main uses of using client details is to check its capabilities. As such,
    the bulk of this library is helper functions to determine what the client supports.
    ]] --
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

    --[[
    % get_raw_finale_version
    Returns a raw Finale version from major, minor, and (optional) build parameters. For 32-bit Finale
    this is the internal major Finale version, not the year.

    @ major (number) Major Finale version
    @ minor (number) Minor Finale version
    @ [build] (number) zero if omitted

    : (number)
    ]]
    function client.get_raw_finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

    --[[
    % get_lua_plugin_version
    Returns a number constructed from `finenv.MajorVersion` and `finenv.MinorVersion`. The reason not
    to use `finenv.StringVersion` is that `StringVersion` can contain letters if it is a pre-release
    version.

    : (number)
    ]]
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

    --[[
    % supports

    Checks the client supports a given feature. Returns true if the client
    supports the feature, false otherwise.

    To assert the client must support a feature, use `client.assert_supports`.

    For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

    @ feature (string) The feature the client should support.
    : (boolean)
    ]]
    function client.supports(feature)
        if features[feature].test == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

    --[[
    % assert_supports

    Asserts that the client supports a given feature. If the client doesn't
    support the feature, this function will throw an friendly error then
    exit the program.

    To simply check if a client supports a feature, use `client.supports`.

    For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

    @ feature (string) The feature the client should support.
    : (boolean)
    ]]
    function client.assert_supports(feature)
        local error_level = finenv.DebugEnabled and 2 or 0
        if not client.supports(feature) then
            if features[feature].error then
                error(features[feature].error, error_level)
            end
            -- Generic error message
            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end

    return client

end

__imports["library.general_library"] = function()
    --[[
    $module Library
    ]] --
    local library = {}

    local client = require("library.client")

    --[[
    % group_overlaps_region

    Returns true if the input staff group overlaps with the input music region, otherwise false.

    @ staff_group (FCGroup)
    @ region (FCMusicRegion)
    : (boolean)
    ]]
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

    --[[
    % group_is_contained_in_region

    Returns true if the entire input staff group is contained within the input music region.
    If the start or end staff are not visible in the region, it returns false.

    @ staff_group (FCGroup)
    @ region (FCMusicRegion)
    : (boolean)
    ]]
    function library.group_is_contained_in_region(staff_group, region)
        if not region:IsStaffIncluded(staff_group.StartStaff) then
            return false
        end
        if not region:IsStaffIncluded(staff_group.EndStaff) then
            return false
        end
        return true
    end

    --[[
    % staff_group_is_multistaff_instrument

    Returns true if the entire input staff group is a multistaff instrument.

    @ staff_group (FCGroup)
    : (boolean)
    ]]
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

    --[[
    % get_selected_region_or_whole_doc

    Returns a region that contains the selected region if there is a selection or the whole document if there isn't.
    SIDE-EFFECT WARNING: If there is no selected region, this function also changes finenv.Region() to the whole document.

    : (FCMusicRegion)
    ]]
    function library.get_selected_region_or_whole_doc()
        local sel_region = finenv.Region()
        if sel_region:IsEmpty() then
            sel_region:SetFullDocument()
        end
        return sel_region
    end

    --[[
    % get_first_cell_on_or_after_page

    Returns the first FCCell at the top of the input page. If the page is blank, it returns the first cell after the input page.

    @ page_num (number)
    : (FCCell)
    ]]
    function library.get_first_cell_on_or_after_page(page_num)
        local curr_page_num = page_num
        local curr_page = finale.FCPage()
        local got1 = false
        -- skip over any blank pages
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
        -- if we got here there were nothing but blank pages left at the end
        local end_region = finale.FCMusicRegion()
        end_region:SetFullDocument()
        return finale.FCCell(end_region.EndMeasure, end_region.EndStaff)
    end

    --[[
    % get_top_left_visible_cell

    Returns the topmost, leftmost visible FCCell on the screen, or the closest possible estimate of it.

    : (FCCell)
    ]]
    function library.get_top_left_visible_cell()
        if not finenv.UI():IsPageView() then
            local all_region = finale.FCMusicRegion()
            all_region:SetFullDocument()
            return finale.FCCell(finenv.UI():GetCurrentMeasure(), all_region.StartStaff)
        end
        return library.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())
    end

    --[[
    % get_top_left_selected_or_visible_cell

    If there is a selection, returns the topmost, leftmost cell in the selected region.
    Otherwise returns the best estimate for the topmost, leftmost currently visible cell.

    : (FCCell)
    ]]
    function library.get_top_left_selected_or_visible_cell()
        local sel_region = finenv.Region()
        if not sel_region:IsEmpty() then
            return finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
        end
        return library.get_top_left_visible_cell()
    end

    --[[
    % is_default_measure_number_visible_on_cell

    Returns true if measure numbers for the input region are visible on the input cell for the staff system.

    @ meas_num_region (FCMeasureNumberRegion)
    @ cell (FCCell)
    @ staff_system (FCStaffSystem)
    @ current_is_part (boolean) true if the current view is a linked part, otherwise false
    : (boolean)
    ]]
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

    --[[
    % calc_parts_boolean_for_measure_number_region

    Returns the correct boolean value to use when requesting information about a measure number region.

    @ meas_num_region (FCMeasureNumberRegion)
    @ [for_part] (boolean) true if requesting values for a linked part, otherwise false. If omitted, this value is calculated.
    : (boolean) the value to pass to FCMeasureNumberRegion methods with a parts boolean
    ]]
    function library.calc_parts_boolean_for_measure_number_region(meas_num_region, for_part)
        if meas_num_region.UseScoreInfoForParts then
            return false
        end
        if nil == for_part then
            return finenv.UI():IsPartView()
        end
        return for_part
    end

    --[[
    % is_default_number_visible_and_left_aligned

    Returns true if measure number for the input cell is visible and left-aligned.

    @ meas_num_region (FCMeasureNumberRegion)
    @ cell (FCCell)
    @ system (FCStaffSystem)
    @ current_is_part (boolean) true if the current view is a linked part, otherwise false
    @ is_for_multimeasure_rest (boolean) true if the current cell starts a multimeasure rest
    : (boolean)
    ]]
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

    --[[
    % update_layout

    Updates the page layout.

    @ [from_page] (number) page to update from, defaults to 1
    @ [unfreeze_measures] (boolean) defaults to false
    ]]
    function library.update_layout(from_page, unfreeze_measures)
        from_page = from_page or 1
        unfreeze_measures = unfreeze_measures or false
        local page = finale.FCPage()
        if page:Load(from_page) then
            page:UpdateLayout(unfreeze_measures)
        end
    end

    --[[
    % get_current_part

    Returns the currently selected part or score.

    : (FCPart)
    ]]
    function library.get_current_part()
        local part = finale.FCPart(finale.PARTID_CURRENT)
        part:Load(part.ID)
        return part
    end

    --[[
    % get_score

    Returns an `FCPart` instance that represents the score.

    : (FCPart)
    ]]
    function library.get_score()
        local part = finale.FCPart(finale.PARTID_SCORE)
        part:Load(part.ID)
        return part
    end

    --[[
    % get_page_format_prefs

    Returns the default page format prefs for score or parts based on which is currently selected.

    : (FCPageFormatPrefs)
    ]]
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

    --[[
    % get_smufl_font_list

    Returns table of installed SMuFL font names by searching the directory that contains
    the .json files for each font. The table is in the format:

    ```lua
    <font-name> = "user" | "system"
    ```

    : (table) an table with SMuFL font names as keys and values "user" or "system"
    ]]

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

    --[[
    % get_smufl_metadata_file

    @ [font_info] (FCFontInfo) if non-nil, the font to search for; if nil, search for the Default Music Font
    : (file handle|nil)
    ]]
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

    --[[
    % is_font_smufl_font

    @ [font_info] (FCFontInfo) if non-nil, the font to check; if nil, check the Default Music Font
    : (boolean)
    ]]
    function library.is_font_smufl_font(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end

        if client.supports("smufl") then
            if nil ~= font_info.IsSMuFLFont then -- if this version of the lua interpreter has the IsSMuFLFont property (i.e., RGP Lua 0.59+)
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

    --[[
    % simple_input

    Creates a simple dialog box with a single 'edit' field for entering values into a script, similar to the old UserValueInput command. Will automatically resize the width to accomodate longer strings.

    @ [title] (string) the title of the input dialog box
    @ [text] (string) descriptive text above the edit field
    : string
    ]]
    function library.simple_input(title, text)
        local return_value = finale.FCString()
        return_value.LuaString = ""
        local str = finale.FCString()
        local min_width = 160
        --
        function format_ctrl(ctrl, h, w, st)
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
            str.LuaString = st
            ctrl:SetText(str)
        end -- function format_ctrl
        --
        title_width = string.len(title) * 6 + 54
        if title_width > min_width then
            min_width = title_width
        end
        text_width = string.len(text) * 6
        if text_width > min_width then
            min_width = text_width
        end
        --
        str.LuaString = title
        local dialog = finale.FCCustomLuaWindow()
        dialog:SetTitle(str)
        local descr = dialog:CreateStatic(0, 0)
        format_ctrl(descr, 16, min_width, text)
        local input = dialog:CreateEdit(0, 20)
        format_ctrl(input, 20, min_width, "") -- edit "" for defualt value
        dialog:CreateOkButton()
        dialog:CreateCancelButton()
        --
        function callback(ctrl)
        end -- callback
        --
        dialog:RegisterHandleCommand(callback)
        --
        if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
            return_value.LuaString = input:GetText(return_value)
            -- print(return_value.LuaString)
            return return_value.LuaString
            -- OK button was pressed
        end
    end -- function simple_input

    --[[
    % is_finale_object

    Attempts to determine if an object is a Finale object through ducktyping

    @ object (__FCBase)
    : (bool)
    ]]
    function library.is_finale_object(object)
        -- All finale objects implement __FCBase, so just check for the existence of __FCBase methods
        return object and type(object) == "userdata" and object.ClassName and object.GetClassID and true or false
    end

    --[[
    % system_indent_set_to_prefs

    Sets the system to match the indentation in the page preferences currently in effect. (For score or part.)
    The page preferences may be provided optionally to avoid loading them for each call.

    @ system (FCStaffSystem)
    @ [page_format_prefs] (FCPageFormatPrefs) page format preferences to use, if supplied.
    : (boolean) `true` if the system was successfully updated.
    ]]
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

    --[[
    % calc_script_name

    Returns the running script name, with or without extension.

    @ [include_extension] (boolean) Whether to include the file extension in the return value: `false` if omitted
    : (string) The name of the current running script.
    ]]
    function library.calc_script_name(include_extension)
        local fc_string = finale.FCString()
        if finenv.RunningLuaFilePath then
            -- Use finenv.RunningLuaFilePath() if available because it doesn't ever get overwritten when retaining state.
            fc_string.LuaString = finenv.RunningLuaFilePath()
        else
            -- This code path is only taken by JW Lua (and very early versions of RGP Lua).
            -- SetRunningLuaFilePath is not reliable when retaining state, so later versions use finenv.RunningLuaFilePath.
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

    --[[
    % get_default_music_font_name

    Fetches the default music font from document options and processes the name into a usable format.

    : (string) The name of the defalt music font.
    ]]
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

__imports["library.measurement"] = function()
    --[[
    $module measurement
    ]] --
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

    --[[
    % convert_to_EVPUs

    Converts the specified string into EVPUs. Like text boxes in Finale, this supports
    the usage of units at the end of the string. The following are a few examples:

    - `12s` => 288 (12 spaces is 288 EVPUs)
    - `8.5i` => 2448 (8.5 inches is 2448 EVPUs)
    - `10cm` => 1133 (10 centimeters is 1133 EVPUs)
    - `10mm` => 113 (10 millimeters is 113 EVPUs)
    - `1pt` => 4 (1 point is 4 EVPUs)
    - `2.5p` => 120 (2.5 picas is 120 EVPUs)

    Read the [Finale User Manual](https://usermanuals.finalemusic.com/FinaleMac/Content/Finale/def-equivalents.htm#overriding-global-measurement-units)
    for more details about measurement units in Finale.

    @ text (string) the string to convert
    : (number) the converted number of EVPUs
    ]]
    function measurement.convert_to_EVPUs(text)
        local str = finale.FCString()
        str.LuaString = text
        return str:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)
    end

    --[[
    % get_unit_name

    Returns the name of a measurement unit.

    @ unit (number) A finale MEASUREMENTUNIT constant.
    : (string)
    ]]
    function measurement.get_unit_name(unit)
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end

        return unit_names[unit]
    end

    --[[
    % get_unit_suffix

    Returns the measurement unit's suffix. Suffixes can be used to force the text value (eg in `FCString` or `FCCtrlEdit`) to be treated as being from a particular measurement unit
    Note that although this method returns a "p" for Picas, the fractional part goes after the "p" (eg `1p6`), so in practice it may be that no suffix is needed.

    @ unit (number) A finale MEASUREMENTUNIT constant.
    : (string)
    ]]
    function measurement.get_unit_suffix(unit)
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end

        return unit_suffixes[unit]
    end

    --[[
    % get_unit_abbreviation

    Returns measurement unit abbreviations that are more human-readable than Finale's internal suffixes.
    Abbreviations are also compatible with the internal ones because Finale discards everything after the first letter that isn't part of the suffix.

    For example:
    ```lua
    local str_internal = finale.FCString()
    str.LuaString = "2i"

    local str_display = finale.FCString()
    str.LuaString = "2in"

    print(str_internal:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT) == str_display:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)) -- true
    ```

    @ unit (number) A finale MEASUREMENTUNIT constant.
    : (string)
    ]]
    function measurement.get_unit_abbreviation(unit)
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end

        return unit_abbreviations[unit]
    end

    --[[
    % is_valid_unit

    Checks if a number is equal to one of the finale MEASUREMENTUNIT constants.

    @ unit (number) The unit to check.
    : (boolean) `true` if valid, `false` if not.
    ]]
    function measurement.is_valid_unit(unit)
        return unit_names[unit] and true or false
    end

    --[[
    % get_real_default_unit

    Resolves `finale.MEASUREMENTUNIT_DEFAULT` to the value of one of the other `MEASUREMENTUNIT` constants.

    : (number)
    ]]
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

__imports["library.score"] = function()
    --[[
    $module Score
    ]] --
    local library = require("library.general_library")
    local configuration = require("library.configuration")
    local measurement = require("library.measurement")

    local config = {use_uppercase_staff_names = false, hide_default_whole_rests = false}

    configuration.get_parameters("score.config.txt", config)

    local score = {}

    local CLEF_MAP = {treble = 0, alto = 1, tenor = 2, bass = 3, percussion = 12}
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
    local KEY_MAP = {} -- defined verbosely to be able to use "#" in key names
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
    KEY_MAP.bb = 2 -- Bb, just lowercase
    KEY_MAP.eb = 3 -- Eb, just lowercase
    KEY_MAP.ab = 4 -- Ab, just lowercase
    KEY_MAP.db = 5 -- Db, just lowercase
    KEY_MAP.gb = 6 -- Gb, just lowercase
    KEY_MAP.cb = 7 -- Cb, just lowercase
    KEY_MAP.fb = 8 -- Fb, just lowercase

    --[[
    % create_default_config

    Many of the "create ensemble" plugins use the same configuration. This function
    creates that configuration object.

    : (table) the configuration object
    ]]
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
            max_measures_per_system = 0, -- 0 means "as many as possible"
            large_measure_number_space = "14s",
        }
        configuration.get_parameters("score_create_new_score_defaults.config.txt", default_config)
        return default_config
    end

    --[[
    % delete_all_staves

    Deletes all staves in the current document.
    ]]
    function score.delete_all_staves()
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            staff:DeleteData()
        end
        staves:SaveAll()
    end

    --[[
    % reset_and_clear_score

    Resets and clears the score to begin creating a new ensemble
    ]]
    function score.reset_and_clear_score()
        score.delete_all_staves()
    end

    --[[
    % set_show_staff_time_signature

    Sets whether or not to show the time signature on the staff.

    @ staff_id (number) the staff_id for the staff
    @ [show_time_signature] (boolean) whether or not to show the time signature, true if not specified

    : (number) the staff_id for the staff
    ]]
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

    --[[
    % set_show_all_staves_time_signature

    Sets whether or not to show the time signature on the staff.

    @ [show_time_signature] (boolean) whether or not to show the time signature, true if not specified
    ]]
    function score.set_show_all_staves_time_signature(show_time_signature)
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            score.set_show_staff_time_signature(staff:GetItemNo(), show_time_signature)
        end
    end

    --[[
    % set_staff_transposition

    Sets the transposition for a staff. Used for instruments that are not concert pitch (e.g., Bb Clarinet or F Horn)

    @ staff_id (number) the staff_id for the staff
    @ key (string) the key signature ("C", "F", "Bb", "C#" etc.)
    @ interval (number) the interval number of steps to transpose the notes by
    @ [clef] (string) the clef to set, "treble", "alto", "tenor", or "bass"

    : (number) the staff_id for the staff
    ]]
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

    --[[
    % set_staff_allow_hiding

    Sets whether the staff is allowed to hide when it is empty.

    @ staff_id (number) the staff_id for the staff
    @ [allow_hiding] (boolean) whether or not to allow the staff to hide, true if not specified

    : (number) the staff_id for the staff
    ]]
    function score.set_staff_allow_hiding(staff_id, allow_hiding)
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        staff.AllowHiding = allow_hiding or true
        staff:Save()
        return staff_id
    end

    --[[
    % set_staff_keyless

    Sets whether or not the staff is keyless.

    @ staff_id (number) the staff_id for the staff
    @ [is_keyless] (boolean) whether the staff is keyless, true if not specified

    : (number) the staff_id for the staff
    ]]
    function score.set_staff_keyless(staff_id, is_keyless)
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        staff.NoKeySigShowAccidentals = is_keyless or true
        staff:Save()
        return staff_id
    end

    --[[
    % set_staff_keyless

    Sets whether or not all staves are keyless.

    @ [is_keyless] (boolean) whether the staff is keyless, true if not specified
    ]]
    function score.set_all_staves_keyless(is_keyless)
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            score.set_staff_keyless(staff:GetItemNo(), is_keyless)
        end
    end

    --[[
    % set_staff_show_default_whole_rests

    Sets whether to show default whole rests on a particular staff.

    @ staff_id (number) the staff_id for the staff
    @ [show_whole_rests] (boolean) whether to show default whole rests, true if not specified

    : (number) the staff_id for the staff
    ]]
    function score.set_staff_show_default_whole_rests(staff_id, show_whole_rests)
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        staff:SetDisplayEmptyRests(show_whole_rests)
        staff:Save()
        return staff_id
    end

    --[[
    % set_all_staves_show_default_whole_rests

    Sets whether or not all staves show default whole rests.

    @ [show_whole_rests] (boolean) whether to show default whole rests, true if not specified
    ]]
    function score.set_all_staves_show_default_whole_rests(show_whole_rests)
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            score.set_staff_show_default_whole_rests(staff:GetItemNo(), show_whole_rests)
        end
    end

    --[[
    % add_space_above_staff

    This is the equivalent of "Add Vertical Space" in the Setup Wizard. It adds space above the staff as well as adds the staff to Staff List 1, which allows it to show tempo markings.

    @ staff_id (number) the staff_id for the staff

    : (number) the staff_id for the staff
    ]]
    function score.add_space_above_staff(staff_id)
        local lists = finale.FCStaffLists()
        lists:SetMode(finale.SLMODE_CATEGORY_SCORE)
        lists:LoadAll()
        local list = lists:GetItemAt(0)
        list:AddStaff(staff_id)
        list:Save()

        -- could be faster
        local system_staves = finale.FCSystemStaves()
        system_staves:LoadAllForItem(1)
        for system_staff in each(system_staves) do
            if system_staff.Staff == staff_id then
                system_staff.Distance = system_staff.Distance + measurement.convert_to_EVPUs(tostring("6s"))
            end
            system_staff:Save()
        end
    end

    --[[
    % set_staff_full_name

    Sets the full name for the staff.

    If two instruments are on the same staff, this will also add the related numbers. For instance, if horn one and 2 are on the same staff, this will show Horn 1/2. `double` sets the first number. In this example, `double` should be `1` to show Horn 1/2. If the staff is for horn three and four, `double` should be `3`.

    @ staff (FCStaff) the staff
    @ full_name (string) the full name to set
    @ [double] (number) the number of the first instrument if two instruments share the staff
    ]]
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

    --[[
    % set_staff_short_name

    Sets the abbreviated name for the staff.

    If two instruments are on the same staff, this will also add the related numbers. For instance, if horn one and 2 are on the same staff, this will show Horn 1/2. `double` sets the first number. In this example, `double` should be `1` to show Horn 1/2. If the staff is for horn three and four, `double` should be `3`.

    @ staff (FCStaff) the staff
    @ short_name (string) the abbreviated name to set
    @ [double] (number) the number of the first instrument if two instruments share the staff
    ]]
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

    --[[
    % create_staff

    Creates a staff at the end of the score.

    @ full_name (string) the abbreviated name
    @ short_name (string) the abbreviated name
    @ type (string) the `__FCStaffBase` type (e.g., finale.FFUUID_TRUMPETC)
    @ clef (string) the clef for the staff (e.g., "treble", "bass", "tenor")
    @ [double] (number) the number of the first instrument if two instruments share the staff

    : (number) the staff_id for the new staff
    ]]
    function score.create_staff(full_name, short_name, type, clef, double)
        local staff_id = finale.FCStaves.Append()
        if staff_id then
            -- Load the created staff
            local staff = finale.FCStaff()
            staff:Load(staff_id)

            staff.InstrumentUUID = type
            staff:SetDefaultClef(CLEF_MAP[clef])

            if config.hide_default_whole_rests then
                staff:SetDisplayEmptyRests(false)
            end

            score.set_staff_full_name(staff, full_name, double)
            score.set_staff_short_name(staff, short_name, double)

            -- Save and return
            staff:Save()
            return staff:GetItemNo()
        end
        return -1
    end

    --[[
    % create_staff_spaced

    Creates a staff at the end of the score with a space above it. This is equivalent to using `score.create_staff` then `score.add_space_above_staff`.

    @ full_name (string) the abbreviated name
    @ short_name (string) the abbreviated name
    @ type (string) the `__FCStaffBase` type (e.g., finale.FFUUID_TRUMPETC)
    @ clef (string) the clef for the staff (e.g., "treble", "bass", "tenor")
    @ [double] (number) the number of the first instrument if two instruments share the staff

    : (number) the staff_id for the new staff
    ]]
    function score.create_staff_spaced(full_name, short_name, type, clef)
        local staff_id = score.create_staff(full_name, short_name, type, clef)
        score.add_space_above_staff(staff_id)
        return staff_id
    end

    --[[
    % create_staff_percussion

    Creates a percussion staff at the end of the score.

    @ full_name (string) the abbreviated name
    @ short_name (string) the abbreviated name

    : (number) the staff_id for the new staff
    ]]
    function score.create_staff_percussion(full_name, short_name)
        local staff_id = score.create_staff(full_name, short_name, finale.FFUUID_PERCUSSIONGENERAL, "percussion")
        local staff = finale.FCStaff()
        staff:Load(staff_id)
        staff:SetNotationStyle(finale.STAFFNOTATION_PERCUSSION)
        staff:SavePercussionLayout(1, 0)
        return staff_id
    end

    --[[
    % create_group

    Creates a percussion staff at the end of the score.

    @ start_staff (number) the staff_id for the first staff
    @ end_staff (number) the staff_id for the last staff
    @ brace_name (string) the name for the brace (e.g., "none", "plain", "piano")
    @ has_barline (boolean) whether or not barlines should continue through all staves in the group
    @ level (number) the indentation level for the group bracket
    @ [full_name] (string) the full name for the group
    @ [short_name] (string) the abbreviated name for the group
    ]]
    function score.create_group(start_staff, end_staff, brace_name, has_barline, level, full_name, short_name)
        local sg_cmper = {}
        local sg = finale.FCGroup()
        local staff_groups = finale.FCGroups()
        staff_groups:LoadAll()
        for sg in each(staff_groups) do
            table.insert(sg_cmper, sg:GetItemID())
        end
        table.sort(sg_cmper)
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

        -- names
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

    --[[
    % create_group_primary

    Creates a primary group with the "curved_chorus" bracket.

    @ start_staff (number) the staff_id for the first staff
    @ end_staff (number) the staff_id for the last staff
    @ [full_name] (string) the full name for the group
    @ [short_name] (string) the abbreviated name for the group
    ]]
    function score.create_group_primary(start_staff, end_staff, full_name, short_name)
        score.create_group(start_staff, end_staff, "curved_chorus", true, 1, full_name, short_name)
    end

    --[[
    % create_group_secondary

    Creates a primary group with the "desk" bracket.

    @ start_staff (number) the staff_id for the first staff
    @ end_staff (number) the staff_id for the last staff
    @ [full_name] (string) the full name for the group
    @ [short_name] (string) the abbreviated name for the group
    ]]
    function score.create_group_secondary(start_staff, end_staff, full_name, short_name)
        score.create_group(start_staff, end_staff, "desk", false, 2, full_name, short_name)
    end

    --[[
    % calc_system_scalings

    _EXPERIMENTAL_

    Calculates the system scaling to fit the desired number of systems on each page.

    Currently produces the incorrect values. Should not be used in any production-ready
    scripts.

    @ systems_per_page (number) the number of systems that should fit on each page

    : (number, number) the desired scaling factors—first_page_scaling, global_scaling
    ]]
    function score.calc_system_scalings(systems_per_page)
        local score_page_format_prefs = finale.FCPageFormatPrefs()
        score_page_format_prefs:LoadScore()
        local page_height = score_page_format_prefs:GetPageHeight()
        local margin_top = score_page_format_prefs:GetLeftPageTopMargin()
        local margin_bottom = score_page_format_prefs:GetLeftPageBottomMargin()
        local available_height = page_height - margin_top - margin_bottom

        local staff_systems = finale.FCStaffSystems()
        staff_systems:LoadAll()
        -- use first staff and not second in case second is not defined
        local system = staff_systems:GetItemAt(0)
        local first_system_height = system:CalcHeight(false)
        -- update margins to use second system height
        local system_height = first_system_height
        system_height = system_height - score_page_format_prefs:GetFirstSystemTop()
        system_height = system_height + score_page_format_prefs:GetSystemTop()
        -- apply staff scaling
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

    --[[
    % set_global_system_scaling

    Sets the system scaling for every system in the score.

    @ scaling (number) the scaling factor
    ]]
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

    --[[
    % set_global_system_scaling

    Sets the system scaling for a specific system in the score.

    @ system_number (number) the system number to set the scaling for
    @ scaling (number) the scaling factor
    ]]
    function score.set_single_system_scaling(system_number, scaling)
        local staff_systems = finale.FCStaffSystems()
        staff_systems:LoadAll()
        local system = staff_systems:GetItemAt(system_number)
        if system then
            system:SetResize(scaling)
            system:Save()
        end
    end

    --[[
    % set_large_time_signatures_settings

    Updates the document settings for large time signatures.
    ]]
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

    --[[
    % use_large_time_signatures

    Sets the system scaling for a specific system in the score.

    @ uses_large_time_signatures (boolean) the system number to set the scaling for
    @ staves_with_time_signatures (table) a table where all values are the staff_id for every staff with a time signature
    ]]
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

    --[[
    % use_large_measure_numbers

    Adds large measure numbers below every measure in the score.

    @ distance (string) the distance between the bottom staff and the measure numbers (e.g., "12s" for 12 spaces)
    ]]
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

            -- Sets the position in accordance to the system scaling
            local position = -1 * measurement.convert_to_EVPUs(distance)
            m:SetMultipleVerticalPosition(position, false)
            m:Save()

            font_size = font:GetSize()
        end

        -- extend bottom system margin to cover measure numbers if needed
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

    --[[
    % set_max_measures_per_system

    Sets the maximum number of measures per system.

    @ max_measures_per_system (number) maximum number of measures per system
    ]]
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

    --[[
    % set_score_page_size

    Sets the score page size.

    @ width (string) the page height (e.g., "8.5i" for 8.5 inches)
    @ height (string) the page width (e.g., "11i" for 11 inches)
    ]]
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

    --[[
    % set_all_parts_page_size

    Sets the page size for all parts.

    @ width (string) the page height (e.g., "8.5i" for 8.5 inches)
    @ height (string) the page width (e.g., "11i" for 11 inches)
    ]]
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

    --[[
    % apply_config

    When creating an ensemble, this function is used to apply the configuration.

    The inputted config file must have a all the fields in the default config file
    (created with `score.create_default_config`).

    The options field must contain the following items:

    - `force_staves_show_time_signatures` (table) a table where all values are the staff_id for every staff with a time signature
    used if `uses_large_time_signatures` is true

    @ config (table) the config file
    @ options (table) ensemble-specific options
    ]]
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

    return score

end

__imports["library.configuration"] = function()
    --  Author: Robert Patterson
    --  Date: March 5, 2021
    --[[
    $module Configuration

    This library implements a UTF-8 text file scheme for configuration and user settings as follows:

    - Comments start with `--`
    - Leading, trailing, and extra whitespace is ignored
    - Each parameter is named and delimited as follows:

    ```
    <parameter-name> = <parameter-value>
    ```

    Parameter values may be:

    - Strings delimited with either single- or double-quotes
    - Tables delimited with `{}` that may contain strings, booleans, or numbers
    - Booleans (`true` or `false`)
    - Numbers

    Currently the following are not supported:

    - Tables embedded within tables
    - Tables containing strings that contain commas

    A sample configuration file might be:

    ```lua
    -- Configuration File for "Hairpin and Dynamic Adjustments" script
    --
    left_dynamic_cushion 		= 12		--evpus
    right_dynamic_cushion		= -6		--evpus
    ```

    ## Configuration Files

    Configuration files provide a way for power users to modify script behavior without
    having to modify the script itself. Some users track their changes to their configuration files,
    so scripts should not create or modify them programmatically.

    - The user creates each configuration file in a subfolder called `script_settings` within
    the folder of the calling script.
    - Each script that has a configuration file defines its own configuration file name.
    - It is entirely appropriate over time for scripts to transition from configuration files to user settings,
    but this requires implementing a user interface to modify the user settings from within the script.
    (See below.)

    ## User Settings Files

    User settings are written by the scripts themselves and reside in the user's preferences folder
    in an appropriately-named location for the operating system. (The naming convention is a detail that the
    configuration library handles for the caller.) If the user settings are to be changed from their defaults,
    the script itself should provide a means to change them. This could be a (preferably optional) dialog box
    or any other mechanism the script author chooses.

    User settings are saved in the user's preferences folder (on Mac) or AppData folder (on Windows).

    ## Merge Process

    Files are _merged_ into the passed-in list of default values. They do not _replace_ the list. Each calling script contains
    a table of all the configurable parameters or settings it recognizes along with default values. An example:

    `sample.lua:`

    ```lua
    parameters = {
       x = 1,
       y = 2,
       z = 3
    }

    configuration.get_parameters(parameters, "script.config.txt")

    for k, v in pairs(parameters) do
       print(k, v)
    end
    ```

    Suppose the `script.config.text` file is as follows:

    ```
    y = 4
    q = 6
    ```

    The returned parameters list is:


    ```lua
    parameters = {
       x = 1,       -- remains the default value passed in
       y = 4,       -- replaced value from the config file
       z = 3        -- remains the default value passed in
    }
    ```

    The `q` parameter in the config file is ignored because the input paramater list
    had no `q` parameter.

    This approach allows total flexibility for the script add to or modify its list of parameters
    without having to worry about older configuration files or user settings affecting it.
    ]]

    local configuration = {}

    local script_settings_dir = "script_settings" -- the parent of this directory is the running lua path
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

    local strip_leading_trailing_whitespace = function(str)
        return str:match("^%s*(.-)%s*$") -- lua pattern magic taken from the Internet
    end

    local parse_table = function(val_string)
        local ret_table = {}
        for element in val_string:gmatch("[^,%s]+") do -- lua pattern magic taken from the Internet
            local parsed_element = parse_parameter(element)
            table.insert(ret_table, parsed_element)
        end
        return ret_table
    end

    parse_parameter = function(val_string)
        if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then -- double-quote string
            return string.gsub(val_string, "\"(.+)\"", "%1") -- lua pattern magic: "(.+)" matches all characters between two double-quote marks (no escape chars)
        elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then -- single-quote string
            return string.gsub(val_string, "'(.+)'", "%1") -- lua pattern magic: '(.+)' matches all characters between two single-quote marks (no escape chars)
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
            local comment_at = string.find(line, comment_marker, 1, true) -- true means find raw string rather than lua pattern
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

    --[[
    % get_parameters

    Searches for a file with the input filename in the `script_settings` directory and replaces the default values in `parameter_list`
    with any that are found in the config file.

    @ file_name (string) the file name of the config file (which will be prepended with the `script_settings` directory)
    @ parameter_list (table) a table with the parameter name as key and the default value as value
    : (boolean) true if the file exists
    ]]
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

    -- Calculates a filepath in the user's preferences folder using recommended naming conventions
    --
    local calc_preferences_filepath = function(script_name)
        local str = finale.FCString()
        str:SetUserOptionsPath()
        local folder_name = str.LuaString
        if not finenv.IsRGPLua and finenv.UI():IsOnMac() then
            -- works around bug in SetUserOptionsPath() in JW Lua
            folder_name = os.getenv("HOME") .. folder_name:sub(2) -- strip '~' and replace with actual folder
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

    --[[
    % save_user_settings

    Saves the user's preferences for a script from the values provided in `parameter_list`.

    @ script_name (string) the name of the script (without an extension)
    @ parameter_list (table) a table with the parameter name as key and the default value as value
    : (boolean) true on success
    ]]
    function configuration.save_user_settings(script_name, parameter_list)
        local file_path, folder_path = calc_preferences_filepath(script_name)
        local file = io.open(file_path, "w")
        if not file and finenv.UI():IsOnWindows() then -- file not found
            os.execute('mkdir "' .. folder_path ..'"') -- so try to make a folder (windows only, since the folder is guaranteed to exist on mac)
            file = io.open(file_path, "w") -- try the file again
        end
        if not file then -- still couldn't find file
            return false -- so give up
        end
        file:write("-- User settings for " .. script_name .. ".lua\n\n")
        for k,v in pairs(parameter_list) do -- only number, boolean, or string values
            if type(v) == "string" then
                v = "\"" .. v .."\""
            else
                v = tostring(v)
            end
            file:write(k, " = ", v, "\n")
        end
        file:close()
        return true -- success
    end

    --[[
    % get_user_settings

    Find the user's settings for a script in the preferences directory and replaces the default values in `parameter_list`
    with any that are found in the preferences file. The actual name and path of the preferences file is OS dependent, so
    the input string should just be the script name (without an extension).

    @ script_name (string) the name of the script (without an extension)
    @ parameter_list (table) a table with the parameter name as key and the default value as value
    @ [create_automatically] (boolean) if true, create the file automatically (default is `true`)
    : (boolean) `true` if the file already existed, `false` if it did not or if it was created automatically
    ]]
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
    finaleplugin.Date = "March 26, 2022"
    finaleplugin.CategoryTags = "Score"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        This script sets up a score for string orchestra:

        - Violin 1
        - Violin 2
        - Viola
        - Cello
        - Bass

        To use it, first open your default document or document styles. Then, run the script.
        All existing staffs will be deleted. And in their place, the string orchestra will be created.

        This script uses the standard ensemble creation configuration options.
    ]]
    return "Create string orchestra score", "Create string orchestra score",
           "Creates the score setup correctly for string orchestra"
end

local score = require("library.score")
local configuration = require("library.configuration")

local config = score.create_default_config()
config.systems_per_page = 2
config.large_measure_number_space = "12s"
configuration.get_parameters("score_create_string_orchestra_score.config.txt", config)

local function score_create_string_orchestra_score()
    score.reset_and_clear_score()

    local staves = {}
    staves.violin_1 = score.create_staff("Violin I", "Vln. I", finale.FFUUID_VIOLINSECTION, "treble")
    staves.violin_2 = score.create_staff("Violin II", "Vln. II", finale.FFUUID_VIOLINSECTION, "treble")
    staves.viola = score.create_staff("Viola", "Vla.", finale.FFUUID_VIOLASECTION, "alto")
    staves.cello = score.create_staff("Cello", "Vc.", finale.FFUUID_CELLOSECTION, "bass")
    staves.bass = score.create_staff("Double Bass", "D.B.", finale.FFUUID_DOUBLEBASSSECTION, "bass")

    score.set_staff_transposition(staves.bass, "C", 7)

    score.create_group_primary(staves.violin_1, staves.bass)
    score.create_group_secondary(staves.violin_1, staves.violin_2)

    score.apply_config(config, {force_staves_show_time_signatures = {staves.violin_2}})
end

score_create_string_orchestra_score()

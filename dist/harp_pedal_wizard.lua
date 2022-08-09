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
  -- This function and the 'finaleplugin' namespace
  -- are both reserved for the plug-in definition.
  finaleplugin.RequireSelection = false
  finaleplugin.Author = "Jacob Winkler"
  finaleplugin.Copyright = "2022"
  finaleplugin.Version = "2.0"
  finaleplugin.Date = "2022-07-17"
  finaleplugin.MinJWLuaVersion = 0.63 -- https://robertgpatterson.com/-fininfo/-rgplua/rgplua.html
  return "Harp Pedal Wizard", "Harp Pedal Wizard", "Creates Harp Diagrams and Pedal Changes"
end

local library = require("library.general_library")
local configuration = require("library.configuration")

--------------------------------------
-- borrowed JetStream functions - will replace later with repo equivalents!
function get_used_font_name(standard_name)
  local font_name = standard_name
  if string.find(os.tmpname(), "/") then
    font_name = standard_name
  elseif string.find(os.tmpname(), "\\") then
    font_name = string.gsub(standard_name, "%s", "")
  end
  return font_name
end

function get_def_mus_font()
  local fontinfo = finale.FCFontInfo()
  if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
    return get_used_font_name(fontinfo:GetName())
  end
end
--------------------------------------
function harp_pedal_wizard()
  local script_name = "harp_pedal_wizard"
  local config = {root = 2, accidental = 1, scale = 0, scale_check = 1, chord = 0, chord_check = 0, diagram_check = 1, names_check = 0, partial_check = 0, stack = 1, pedal_lanes = 1, last_notes = "D, C, B, E, F, G, A"}
  local partial = false
  local changes = false
  local stack = true
  local pedal_lanes = true
  local direct = false
  local override = false
  local context =
  {
    window_pos_x = window_pos_x or nil,
    window_pos_y = window_pos_y or nil
  }

  local SMuFL = library.is_font_smufl_font(nil)
  harpstrings = {}
  diagram_string = finale.FCString()
  description = finale.FCString()
  local changes_str = finale.FCString()
  changes_str.LuaString = ""
  local default_music_font = get_def_mus_font()
  local diagram_font = "^fontTxt("..default_music_font..")"
  --
  local flat_char = utf8.char(0xe680) -- SMuFL: Harp pedal raised (flat)
  local nat_char = utf8.char(0xe681) -- SMuFL: Harp pedal centered (natural)
  local sharp_char = utf8.char(0xe682) -- SMuFL: Harp pedal lowered (sharp)
  local divider_char = utf8.char(0xe683) -- SMuFL: Harp pedal divider
  local desc_prefix = finale.FCString()
  desc_prefix.LuaString = ""
  local ui = finenv.UI()
  local direct_notes = {0, 0, 0, 0, 0, 0, 0}
  configuration.get_user_settings(script_name, config, create_automatically)

  function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
    end
    return result;
  end

  function trim(s)
    return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
  end

  function process_return(harpnotes)
    local error = false
    direct_notes = {0, 0, 0, 0, 0, 0, 0}
    --
    local harp_tbl = split(harpnotes, ",")
    local count = 0 

    for i,k in pairs(harp_tbl) do
      harp_tbl[i] = trim(harp_tbl[i])
      if string.len(harp_tbl[i]) > 2 then
        error = true
--                goto error            
      end
      harp_tbl[i] = string.lower(harp_tbl[i])
      local first = harp_tbl[i]:sub(1,1)
      local second = harp_tbl[i]:sub(2,2)
      if second == "f" then second = "b" end
      if second == "s" then second = "#" end
      if second == "n" then second = "" end
      local first_upper = string.upper(first)
      harp_tbl[i] = first_upper..second
      if string.len(harp_tbl[i]) == 2 then
        if string.sub(harp_tbl[i], -1) == "b" 
        or string.sub(harp_tbl[i], -1) == "#" 
        or string.sub(harp_tbl[i], -1) == "n" then
          -- then nothing!!!
        else
          error = true
          --goto error     
        end
      end -- if length is 2...
      ---- Assign to strings...
      if harp_tbl[i]:sub(1,1) == "A" then 
        harpstrings[7] = harp_tbl[i]
        direct_notes[7] = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "B" then 
        harpstrings[3] = harp_tbl[i]
        direct_notes[3] = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "C" then
        harpstrings[2] = harp_tbl[i]
        direct_notes[2] = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "D" then
        harpstrings[1] = harp_tbl[i]
        direct_notes[1] = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "E" then
        harpstrings[4] = harp_tbl[i]
        direct_notes[4] = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "F" then
        harpstrings[5] = harp_tbl[i]
        direct_notes[5] = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "G" then
        harpstrings[6] = harp_tbl[i]
        direct_notes[6] = harp_tbl[i]
      else
--                error = true
--                goto error1               
      end -- End string assignments
      count = i        
    end -- for i,j
  end

  function changes_update()
    changes_str.LuaString = ""
    if not harpstrings[1] then
      harpstrings = {"D", "C", "B", "E", "F", "G", "A"}
    end
    local new_pedals = {0, 0, 0, 0, 0, 0, 0}
    local compare_notes = split(config.last_notes, ",")
    for i, k in pairs(compare_notes) do
      compare_notes[i] = trim(compare_notes[i])
    end
    local changes_temp
    for i = 1, 7, 1 do
      if harpstrings[i] == compare_notes[i] then
        new_pedals[i] = 0
      else
        new_pedals[i] = harpstrings[i]
        if changes_str.LuaString == "" then
          changes_str.LuaString = "New: "
        end
        changes_str.LuaString = changes_str.LuaString..harpstrings[i]..", "
        changes_temp = true
      end
    end
    if not changes_temp then 
      changes_str.LuaString = ""
    else
      local length = string.len(changes_str.LuaString) - 2
      changes_str.LuaString = string.sub(changes_str.LuaString, 1, length)
    end
    changes_static:SetText(changes_str)
  end

  function harp_diagram(harpnotes, use_diagram, scaleinfo, partial)
    if use_diagram then
      desc_prefix.LuaString = "Hp. Diagram: "
    else
      desc_prefix.LuaString = "Hp. Pedals: "
    end
    if partial then scaleinfo = nil end
    local region = finenv.Region()
    local harp_error = false
    local use_tech = false
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadScrollView()
    local sysstaff = finale.FCSystemStaff()
    local left_strings = finale.FCString()
    left_strings.LuaString = ""
    local new_pedals = {0, 0, 0, 0, 0, 0, 0}
    description.LuaString = desc_prefix.LuaString
    diagram_string.LuaString = ""

    if not SMuFL then
      diagram_font = "^fontTxt(Engraver Text H)"
      flat_char = "o"
      nat_char = "O"
      sharp_char = "p"
      divider_char = "P"
    end
---------------------------------
-- Initialize harpstring variables to 0
    A = "A"
    B = "B"
    C = "C"
    D = "D"
    E = "E"
    F = "F"
    G = "G"

-----------------------------
    local compare_notes = split(config.last_notes, ",")
    for i, k in pairs(compare_notes) do
      compare_notes[i] = trim(compare_notes[i])
    end
    --
    local harp_tbl = split(harpnotes, ",")
    local count = 0 

    for i,k in pairs(harp_tbl) do
      harp_tbl[i] = trim(harp_tbl[i])
      if string.len(harp_tbl[i]) > 2 then
        harp_error = true
        goto error1            
      end
      harp_tbl[i] = string.lower(harp_tbl[i])
      local first = harp_tbl[i]:sub(1,1)
      local second = harp_tbl[i]:sub(2,2)
      if second == "f" then second = "b" end
      if second == "s" then second = "#" end
      if second == "n" then second = "" end
      local first_upper = string.upper(first)
      harp_tbl[i] = first_upper..second
      if string.len(harp_tbl[i]) == 2 then
        if string.sub(harp_tbl[i], -1) == "b" 
        or string.sub(harp_tbl[i], -1) == "#" 
        or string.sub(harp_tbl[i], -1) == "n" then
          -- then nothing!!!
        else
          harp_error = true
          goto error1     
        end
      end -- if length is 2...

      ---- Assign to strings...
      if harp_tbl[i]:sub(1,1) == "A" then 
        A = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "B" then 
        B = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "C" then
        C = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "D" then
        D = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "E" then
        E = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "F" then
        F = harp_tbl[i]
      elseif harp_tbl[i]:sub(1,1) == "G" then
        G = harp_tbl[i]
      else
        harp_error = true
        goto error1               
      end -- End string assignments
      count = i        
    end -- for i,j
--
    harpstrings = {D, C, B, E, F, G, A}
    pedals_update()

    if count > 7 then
      harp_error = true
      goto error1
    end

    if partial then
      for i = 1, 7, 1 do
        if harpstrings[i] == compare_notes[i] then
          new_pedals[i] = 0
        else
          new_pedals[i] = harpstrings[i]
          changes = true
        end
      end
    else
      new_pedals = harpstrings
    end

    if not changes and partial then
      if direct then
        local yesno = ui:AlertYesNo("There are no pedal changes required.\rAdd anyway?", nil)
        if yesno == 3 then
          override = true
        elseif yesno == 2 then
          new_pedals = direct_notes
          changes = true
        end
      end
    end

    changes_update()
    for i = 1, 7, 1 do
      if use_diagram then
        description.LuaString = description.LuaString..harpstrings[i]
        if string.len(harpstrings[i]) == 1 then
          diagram_string.LuaString = diagram_string.LuaString..nat_char
        elseif string.len(harpstrings[i]) == 2 then
          if string.sub(harpstrings[i], -1) == "b" then
            diagram_string.LuaString = diagram_string.LuaString..flat_char
          elseif string.sub(harpstrings[i], -1) == "#" then
            diagram_string.LuaString = diagram_string.LuaString..sharp_char
          elseif string.sub(harpstrings[i], -1) == "n" then
            diagram_string.LuaString = diagram_string.LuaString..nat_char
          end
        end
        if i == 3 then
          diagram_string.LuaString = diagram_string.LuaString..divider_char
          description.LuaString = description.LuaString.." | "
        elseif i < 7 then
          description.LuaString = description.LuaString.." "
        end
      elseif not use_diagram then -- Settings for 'Note names'
        if i < 3 then
          if new_pedals[i] ~= 0 then
            description.LuaString = description.LuaString..harpstrings[i].." "
            left_strings.LuaString = left_strings.LuaString..harpstrings[i]
            if string.len(harpstrings[i]) == 1 then
              left_strings.LuaString = left_strings.LuaString.."n"
            end
            left_strings.LuaString = left_strings.LuaString.." "
          end
        elseif i == 3 then
          if new_pedals[i] ~= 0 then
            description.LuaString = description.LuaString..harpstrings[i].." "
            left_strings.LuaString = left_strings.LuaString..harpstrings[i]
            if string.len(harpstrings[i]) == 1 then
              left_strings.LuaString = left_strings.LuaString.."n"
            end
          end
          if new_pedals[i + 1] ~= 0 then
            description.LuaString = description.LuaString.."| "
          end
        elseif i > 3 and i ~= 7 then
          if new_pedals[i] ~= 0 then
            description.LuaString = description.LuaString..harpstrings[i].." "
            diagram_string.LuaString = diagram_string.LuaString..harpstrings[i]
            if string.len(harpstrings[i]) == 1 then
              diagram_string.LuaString = diagram_string.LuaString.."n"
            end
            diagram_string.LuaString = diagram_string.LuaString.." "
          end    
        elseif i == 7 then
          if new_pedals[i] ~= 0 then
            description.LuaString = description.LuaString..harpstrings[i]
            diagram_string.LuaString = diagram_string.LuaString..harpstrings[i]  
            if string.len(harpstrings[i]) == 1 then
              diagram_string.LuaString = diagram_string.LuaString.."n"
            end
          end
        end
      end -- if use_diagram...
    end -- i 1 to 7
--
    if not use_diagram then 
      if not stack then
        if diagram_string.LuaString ~= "" then
          left_strings.LuaString = left_strings.LuaString.." "
        end
        diagram_string.LuaString = left_strings.LuaString..diagram_string.LuaString
      elseif stack and (diagram_string.LuaString ~= ""and not config.pedal_lanes)
      or stack and not partial
      or pedal_lanes and partial then
        diagram_string.LuaString = diagram_string.LuaString.."\r"..left_strings.LuaString
      elseif (partial and diagram_string.LuaString == "" and not pedal_lanes) then
        diagram_string.LuaString = left_strings.LuaString
      end
      diagram_string.LuaString = string.gsub(diagram_string.LuaString, "n", "^natural()")
      diagram_string.LuaString = string.gsub(diagram_string.LuaString, "b", "^flat()")
      diagram_string.LuaString = string.gsub(diagram_string.LuaString, "#", "^sharp()")
      diagram_string.LuaString = string.gsub(diagram_string.LuaString, " %\13", "\r")
    end
    if scaleinfo then description.LuaString = description.LuaString.." ("..scaleinfo..")" end
    ::error1::
    if harp_error then
      local result = ui:AlertYesNo("There seems to be a problem with your harp diagram. \n Would you like to try again?", NULL)
      if result == 2 then 
        config.last_notes = "D, C, B, E, F, G, A" -- reset the last notes in case there is a problem with them
      end
    end -- error
    if diag_asn then
      ui:AlertInfo("There is already a harp diagram assigned to this region.", NULL)
    end
  end

  function pedals_add(use_diagram, partial)
    local undo_str = ""
    if use_diagram then
      undo_str = "Create harp diagram"
    else
      undo_str = "Create harp pedals"
    end
    finenv.StartNewUndoBlock(undo_str, false)
    local categorydefs = finale.FCCategoryDefs()
    local misc_cat = finale.FCCategoryDef()
    categorydefs:LoadAll()
    local diagrams = 0
    local region = finenv.Region()
    local start = region.StartMeasure
    local font = finale.FCFontInfo()
    local textexpressiondefs = finale.FCTextExpressionDefs()
    textexpressiondefs:LoadAll()
    local add_expression = finale.FCExpression()
    local diag_ted = 0
    local diag_asn = false
    local expressions = finale.FCExpressions()
    local measure_num = region.StartMeasure
    local measure_pos = region.StartMeasurePos
    local staff_num = region.EndStaff 
    local and_cell = finale.FCCell(measure_num, staff_num)
    --
    ---- deal with categories

    for cat in eachbackwards(categorydefs) do
      if cat:CreateName().LuaString == "Technique Text" and diagrams == 0 then
        diagrams = cat.ID
        diagrams_cat = cat
        use_tech = true
        if use_diagram then
          print("No Harp Diagrams category found. Using Technique Text,",diagrams)
        else
          print("No Harp Pedals category found. Using Technique Text,",diagrams)
        end
      elseif string.lower(cat:CreateName().LuaString) == "harp diagrams" and use_diagram == true then
        print("Found Harp Diagrams category")
        diagrams = cat.ID
        diagrams_cat = cat
      elseif string.lower(cat:CreateName().LuaString) == "harp pedals" and use_diagram == false then
        print("Found Harp Pedals category")
        diagrams = cat.ID
        diagrams_cat = cat
      end -- if cat...
    end -- for cat
-----
    -- find an existing diagram 
    --
    textexpressiondefs:LoadAll()
    for ted in each(textexpressiondefs) do
      if ted.CategoryID == diagrams and ted:CreateDescription().LuaString == description.LuaString then
        print ("Diagram found at",ted.ItemNo)
        diag_ted = ted.ItemNo
      end -- if ted.CategoryID
    end -- for ted...
    --
    -- if there is no existing diagram...', create one
    if diag_ted == 0 then
      local ex_ted = finale.FCTextExpressionDef()
      local ted_text = finale.FCString()
      if use_diagram then
        local text_font = diagram_font
        ted_text.LuaString = text_font..diagram_string.LuaString
      else 
        ted_text.LuaString = diagram_string.LuaString
      end -- if use_diagram
      ex_ted:AssignToCategory(diagrams_cat)
      ex_ted:SetDescription(description)
      ex_ted:SaveNewTextBlock(ted_text)
      if use_tech then -- If using the Techniques category, override positioning
        ex_ted:SetUseCategoryPos(false)
        --ex_ted.HorizontalJustification = 1 -- Justify Center
        --ex_ted.HorizontalAlignmentPoint = 5 -- Center on Music
        --ex_ted.HorizontalOffset = nudge
        ex_ted.VerticalAlignmentPoint = 9 -- align to 
        ex_ted.VerticalBaselineOffset = 12
        ex_ted.VerticalEntryOffset = -36
      end
      ex_ted:SaveNew()
      diag_ted = ex_ted.ItemNo
    end -- if diag_ted == 0

-- Test to see if diagram is there already...
    expressions:LoadAllForRegion(region)
    for e in each(expressions) do
      local ted = e:CreateTextExpressionDef()
      local ted_desc = ted:CreateDescription()
      if ted_desc:ContainsLuaString(desc_prefix.LuaString) then
        diag_asn = true
        goto error1
      end 
      end -- for e in expressions... ]]

-- add the harp diagram

      add_expression:SetStaff(staff_num)
      add_expression:SetMeasurePos(measure_pos)
      add_expression:SetID(diag_ted)
      add_expression:SaveNewToCell(and_cell)

-------
      ::error1::
      finenv.EndUndoBlock(true)
      if harp_error then
        print("There seems to be a problem with your harp diagram.")
        local result = ui:AlertYesNo("There seems to be a problem with your harp diagram. \n Would you like to try again?", NULL)
--                if result == 2 then harp_dialog() end
      end -- error
      if diag_asn then
        ui:AlertInfo("There is already a harp diagram assigned to this region.", NULL)
      end
    end -- function add_pedals

    -------
    function harp_scale(root, scale, use_diagram, use_chord, partial)
      local scale_error = false
      local enharmonic = finale.FCString()
      local scaleinfo = root.." "..scale
      if use_chord then scaleinfo = root..scale end
      -------------------
      ---- Set up tables for all strings, as both numbers (C = 0) and letters. 
      local C_num = {11, 0, 1}
      local C_ltr = {"Cb", "C", "C#"}
      --
      local D_num = {1, 2, 3}
      local D_ltr = {"Db", "D", "D#"}
      --    
      local E_num = {3, 4, 5}
      local E_ltr = {"Eb", "E", "E#"}
      --
      local F_num = {4, 5, 6}
      local F_ltr = {"Fb", "F", "F#"}
      --
      local G_num = {6, 7, 8}
      local G_ltr = {"Gb", "G", "G#"}
      --
      local A_num = {8, 9, 10}
      local A_ltr = {"Ab", "A", "A#"}
      --
      local B_num = {10, 11, 0}
      local B_ltr = {"Bb", "B", "B#"}
      ---- And also master lists of all notes and numbers
      local all_ltr = {"Cb", "C", "C#", "Db", "D", "D#", "Eb", "E", "E#", "Fb", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B", "B#"}
      local enh_ltr = {"B", "B#", "Db", "C#", "D", "Eb", "D#", "Fb", "F", "E", "E#", "Gb", "F#", "G", "Ab", "G#", "A", "Bb", "A#", "Cb", "C"}
      local all_num = {11, 0, 1, 1, 2, 3, 3, 4, 5, 4, 5, 6, 6, 7, 8, 8, 9, 10, 10, 11, 0}
      for i,j in pairs(all_ltr) do
        if all_ltr[i] == root then enharmonic.LuaString = enh_ltr[i] end
      end

-- 1) Find root offset
      local root_off = 0
      for a, b in pairs(all_ltr) do
        if all_ltr[a] == root then
          root_off = all_num[a]
        end -- if
      end -- for a, b...
----
-- 2) Find scale and transpose it
      scale = string.lower(scale)
      local scale_new = {}
      -----------------------
      if scale == "major" or scale == "ionian" then scale_new = {0, 2, 4, 5, 7, 9, 11} end
      if scale == "dorian" then scale_new = {0, 2, 3, 5, 7, 9, 10}  end
      if scale == "phrygian" then scale_new = {0, 1, 3, 5, 7, 8, 10} end
      if scale == "lydian" then scale_new = {0, 2, 4, 6, 7, 9, 11} end
      if scale == "mixolydian" then scale_new = {0, 2, 4, 5, 7, 9, 10}  end
      if scale == "natural minor" or scale == "aeolian" then scale_new = {0, 2, 3, 5, 7, 8, 10} end
      if scale == "harmonic minor" then scale_new = {0, 2, 3, 5, 7, 8, 11} end
      if scale == "hungarian minor" then scale_new = {0, 2, 3, 6, 7, 8, 11} end
----- 'Exotic' scales, with something other than 7 scale degrees. Will be treated as chords.
      if scale == "whole tone" then scale_new = {0, 4, 2, 6, 8, 10} end
      if scale == "major pentatonic" then scale_new = {0, 4, 7, 2, 9} end
      if scale == "minor pentatonic" then scale_new = {0, 3, 7, 5, 10} end
----- Chords - Listed in order of matching priority. 
      if scale == "dom7" then scale_new = {0, 4, 7, 10, 2, 9, 5} end
      if scale == "maj7" then scale_new = {11, 0, 4, 7, 9, 2, 5} end
      if scale == "min7" then scale_new = {0, 3, 7, 10, 2, 5, 9} end
      if scale == "m7b5" then scale_new = {0, 3, 6, 10, 2, 5, 8} end
      if scale == "dim7" then scale_new = {0, 3, 6, 9, 2, 5, 8} end
      if scale == "aug" then scale_new = {0, 4, 8, 2, 10, 6} end
      --

      --print("New scale (scale_new) numbers are:")
      for a, b in pairs(scale_new) do
        scale_new[a] = math.fmod (scale_new[a] + root_off , 12)
        --print(scale_new[a])
      end 
--------------------------
-- 3) build out scale using letternames
      local scale_ltrs = root  -- This is where we will build scale (as string of letter-names)
      local root_string = string.sub(root, 1, 1) -- the base string, A-G
      local last = root_string -- the last string added to the list
      local scale_deg = 2 -- will advance through scale. Root was already added, so we will start at 2...
----
      if scale == "whole tone" or scale == "major pentatonic" or scale == "minor pentatonic" then
        use_chord = true
      end -- temporary change for exotic scales!

      if not use_chord then
        for i = 1, 2, 1 do --- run through this twice...
          if last == "A"  and scale_deg <= 7 then
            local is_found = false
            for j = 1, 3, 1 do
              if B_num[j] == scale_new[scale_deg] then
                scale_ltrs = scale_ltrs..", "..B_ltr[j]
                is_found = true
              end
            end -- for j
            if not is_found then
              scale_error = true
              goto scale_error
            end
            scale_deg = scale_deg + 1
            last = "B"
          end
          if last == "B"  and scale_deg <= 7 then
            local is_found = false
            for j = 1, 3, 1 do
              if C_num[j] == scale_new[scale_deg] then
                scale_ltrs = scale_ltrs..", "..C_ltr[j]
                is_found = true
              end
            end -- for j
            if not is_found then
              scale_error = true
              goto scale_error
            end
            scale_deg = scale_deg + 1
            last = "C"
          end
          if last == "C" and scale_deg <= 7  then
            local is_found = false
            for j = 1, 3, 1 do
              if D_num[j] == scale_new[scale_deg] then
                scale_ltrs = scale_ltrs..", "..D_ltr[j]
                is_found = true
              end
            end -- for j
            if not is_found then
              scale_error = true
              goto scale_error
            end
            scale_deg = scale_deg + 1
            last = "D"
          end
          if last == "D"  and scale_deg <= 7 then
            local is_found = false
            for j = 1, 3, 1 do
              if E_num[j] == scale_new[scale_deg] then
                scale_ltrs = scale_ltrs..", "..E_ltr[j]
                is_found = true
              end
            end -- for j
            if not is_found then
              scale_error = true
              goto scale_error
            end
            scale_deg = scale_deg + 1
            last = "E"
          end
          if last == "E" and scale_deg <= 7 then
            local is_found = false
            for j = 1, 3, 1 do
              if F_num[j] == scale_new[scale_deg] then
                scale_ltrs = scale_ltrs..", "..F_ltr[j]
                is_found = true
              end 
            end -- for j
            if not is_found then
              scale_error = true
              goto scale_error
            end
            scale_deg = scale_deg + 1
            last = "F"
          end
          if last == "F"  and scale_deg <= 7 then
            local is_found = false
            for j = 1, 3, 1 do
              if G_num[j] == scale_new[scale_deg] then
                scale_ltrs = scale_ltrs..", "..G_ltr[j]
                is_found = true
              end
            end -- for j
            if not is_found then
              scale_error = true
              goto scale_error
            end
            scale_deg = scale_deg + 1
            last = "G"
          end
          if last == "G"  and scale_deg <= 7 then
            local is_found = false
            for j = 1, 3, 1 do
              if A_num[j] == scale_new[scale_deg] then
                scale_ltrs = scale_ltrs..", "..A_ltr[j]
                is_found = true
              end
            end -- for j
            if not is_found then
              scale_error = true
              goto scale_error
            end
            scale_deg = scale_deg + 1
            last = "A"
          end
        end -- for i...
      elseif use_chord then
        local ind_string_ltrs = {A_ltr, B_ltr, C_ltr, D_ltr, E_ltr, F_ltr, G_ltr}
        local ind_string_nums = {A_num, B_num, C_num, D_num, E_num, F_num, G_num}
        for i, j in pairs(ind_string_ltrs) do
          if ind_string_ltrs[i][2] ~= root_string then
            local match = false
            local count = 0
            repeat
              for k, l in pairs(scale_new) do
                for m,n in pairs(ind_string_nums[i]) do
                  if ind_string_nums[i][m] == scale_new[k] then
                    scale_ltrs = scale_ltrs..", "..ind_string_ltrs[i][m]
                    match = true
                    goto continue
                  end
                end
              end -- for k, l...
              count = count + 1
              if count == 25 then
                print("Something clearly went wrong...")
                match = true
              end
              ::continue::
            until ( match == true )
          end -- if ind_string_ltrs[i][2]...
        end -- for i, j...
      end -- if use_chord...

      if scale == "whole tone" or scale == "major pentatonic" or scale == "minor pentatonic" then
        use_chord = false
      end -- temporary change for exotic scales!

      harp_diagram(scale_ltrs, use_diagram, scaleinfo, partial)
---
      ::scale_error::
      if scale_error then
        local str = finale.FCString()
        str.LuaString = "That scale won't work, sorry. \n Try again using "..enharmonic.LuaString.." "..scale.."?"
        local result = ui:AlertYesNo(str.LuaString, NULL)
        if result == 2 then
          sel_acc:SetSelectedItem(1)
          for i, k in pairs(roots) do
            if string.sub(enharmonic.LuaString, 1, 1) == roots[i] then
              sel_root:SetSelectedItem(i-1)
            end
          end
          if string.len(enharmonic.LuaString) == 2 then
            if string.sub(enharmonic.LuaString, -1) == "b" then
              sel_acc:SetSelectedItem(0)
            elseif string.sub(enharmonic.LuaString, -1) == "#" then
              sel_acc:SetSelectedItem(2)
            end
          end
        end
      end -- error

    end -- function harp_scale()
-------

    function harp_dialog()
      local str = finale.FCString()
      local use_diagram = true
      local use_chord = false

      if config.chord_check == 0  or config.chord_check == "0" then use_chord = false 
      elseif config.chord_check == 1 or config.chord_check == "1" then use_chord = true end
      if config.diagram_check == 0  or config.diagram_check == "0" then use_diagram = true 
      elseif config.diagram_check == 1 or config.diagram_check == "1"  then use_diagram = false end

      local row_y = 0 -- The various controls will use this to consistently place themselves vertically
--
      function format_ctrl(ctrl, h, w, st)
        ctrl:SetHeight(h)
        ctrl:SetWidth(w)
        str.LuaString = st
        ctrl:SetText(str)
      end -- function format_ctrl
--
      local dialog = finale.FCCustomLuaWindow()
      if context.window_pos_x ~= nil and context.window_pos_y ~= nil then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(context.window_pos_x, context.window_pos_y)
        dialog:RestorePosition()
      end
      str.LuaString = "Harp Pedal Wizard"
      dialog:SetTitle(str)
-----
      local scale_static = dialog:CreateStatic(0, row_y)
      format_ctrl(scale_static, 120, 320, 
[[Choose a root and accidental, then either a scale
or a chord from the drop down lists.]])
----
        row_y = row_y + 52

        roots = {"A", "B", "C", "D", "E", "F", "G"}
        local root_label = dialog:CreateStatic(8,row_y-14)
        format_ctrl(root_label, 15, 30, "Root")
        sel_root = dialog:CreatePopup(8, row_y)
        format_ctrl(sel_root, 20, 36, "Root")
        for i,j in pairs(roots) do
          str.LuaString = roots[i]
          sel_root:AddString(str)
        end
        sel_root:SetSelectedItem(config.root)
        local accidentals = {"b", "♮", "#"} -- unicode symbols... natural at least displays as 'n' on Windows
--      local accidentals = {"♭", "♮", "♯"} -- unicode symbols
        sel_acc = dialog:CreatePopup(42, row_y)
        format_ctrl(sel_acc, 20, 32, "Accidental")
        for i,j in pairs(accidentals) do
          str.LuaString = accidentals[i]
          sel_acc:AddString(str)
        end   
        sel_acc:SetSelectedItem(config.accidental)

        -- Setup Scales
        str.LuaString = " Scale"  
        local scale_check = dialog:CreateCheckbox(86, row_y-14)
        format_ctrl(scale_check, 16, 70, str.LuaString)

        scale_check:SetCheck(config.scale_check)

        local scales = {"Major", "Natural Minor", "Harmonic Minor", "Ionian",
          "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Hungarian Minor", 
          "Whole tone", "Major Pentatonic", "Minor Pentatonic"}
        local sel_scale = dialog:CreatePopup(86, row_y)
        format_ctrl(sel_scale, 20, 120, "Scale")
        local standard_scales_count = 0
        for i,j in pairs(scales) do
          str.LuaString = scales[i]
          sel_scale:AddString(str)
          standard_scales_count = i
        end
        sel_scale:SetSelectedItem(config.scale)
        if scale_check:GetCheck() == 0 then
          sel_scale:SetEnable(false)
        end

        --- Setup Chords
        str.LuaString = " Chord"  
        local chord_check = dialog:CreateCheckbox(220, row_y-14)
        format_ctrl(chord_check, 16, 70, str.LuaString)
        chord_check:SetCheck(config.chord_check)

        local chords = {"dom7", "maj7", "min7", "m7b5", "dim7", "aug"}
        local sel_chord = dialog:CreatePopup(220, row_y)
        format_ctrl(sel_chord, 20, 100, "Chord")
        for i,j in pairs(chords) do
          str.LuaString = chords[i]
          sel_chord:AddString(str)
        end
        sel_chord:SetSelectedItem(config.chord)
        if chord_check:GetCheck() == 0 then 
          sel_chord:SetEnable(false) 
        end
        if scale_check:GetCheck() == 0 and chord_check:GetCheck() == 0 then
          sel_root:SetEnable(false)
          sel_acc:SetEnable(false)
        end
        --
        row_y = row_y + 32
        local horz_line1 = dialog:CreateHorizontalLine(0, row_y - 6, 320)
        -- Setup diagram or Note Names 
        str.LuaString = "Style:"
        local style_label = dialog:CreateStatic(0, row_y-1)
        format_ctrl(style_label, 20, 70, str.LuaString)
        --
        local diagram_checkbox = dialog:CreateCheckbox(40, row_y)
        str.LuaString = " Diagram"
        format_ctrl(diagram_checkbox, 16, 70, str.LuaString)
        diagram_checkbox:SetCheck(config.diagram_check) 
        --
        local names_checkbox = dialog:CreateCheckbox(132, row_y)
        str.LuaString = " Note Names"
        format_ctrl(names_checkbox, 16, 90, str.LuaString)
        names_checkbox:SetCheck(config.names_check)
        --
        local partial_checkbox = dialog:CreateCheckbox(224, row_y)
        str.LuaString = " Partial"
        format_ctrl(partial_checkbox, 16, 70, str.LuaString)
        partial_checkbox:SetCheck(config.partial_check)
        --
        row_y = row_y + 18
        local stack_checkbox = dialog:CreateCheckbox(132, row_y)
        str.LuaString = " Stack"
        format_ctrl(stack_checkbox, 16, 70, str.LuaString)
        stack_checkbox:SetCheck(config.stack)    
        --
        local lanes_checkbox = dialog:CreateCheckbox(224, row_y)
        str.LuaString = " Preserve Lanes"
        format_ctrl(lanes_checkbox, 16, 100, str.LuaString)
        lanes_checkbox:SetCheck(config.pedal_lanes)
        --
        row_y = row_y + 26
        local horz_line3 = dialog:CreateHorizontalLine(0, row_y-8, 320)
        --
        str.LuaString = "D"
        local blank = finale.FCString()
        blank.LuaString = ""
        local col_x = 0
        local col_width = 20
        local col = 0
        local row_h = 20
        local flat_y = row_y + row_h
        local nat_y = flat_y + row_h
        local sharp_y = nat_y + row_h
        -- On MacOS in Dark Mode, the horizontal/vertical lines representing the natural position and center line of the harp are too faint.
        -- Therefore, on the Mac I have opted to create these lines using vertical pipe and hyphen characters.
        if ui:IsOnMac() then
          local pedals_h_line = {}
          str.LuaString = "-"
          for i = 1, 7, 1 do
            local line_off
            if i < 4 then
              line_off = 11
            else
              line_off = -0
            end
            pedals_h_line[i] = dialog:CreateStatic(col_x + ((i-1) * col_width + line_off), nat_y)
            format_ctrl(pedals_h_line[i], 20, 10, str.LuaString)
          end
        else
          local pedals_h_line1 = dialog:CreateHorizontalLine(col_x, nat_y + 6, col_width * 7)
        end
        --
        local d_stg_static = dialog:CreateStatic(col_x + (col * col_width), row_y-1)
        format_ctrl(d_stg_static, 20, 20, str.LuaString)
        local d_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width), flat_y)
        format_ctrl(d_stg_flat, 16, 13, str.LuaString)
        d_stg_flat:SetText(blank)
        local d_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width), nat_y)
        format_ctrl(d_stg_nat, 16, 13, str.LuaString)
        d_stg_nat:SetText(blank)
        local d_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width), sharp_y)
        format_ctrl(d_stg_sharp, 16, 13, str.LuaString)
        d_stg_sharp:SetText(blank)
        col = col + 1
        --
        str.LuaString = "C"
        local c_stg_static = dialog:CreateStatic(col_x + (col * col_width), row_y-1)
        format_ctrl(c_stg_static, 20, 20, str.LuaString)
        local c_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width), flat_y)
        format_ctrl(c_stg_flat, 16, 13, str.LuaString)
        c_stg_flat:SetText(blank)
        local c_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width), nat_y)
        format_ctrl(c_stg_nat, 16, 13, str.LuaString)
        c_stg_nat:SetText(blank)
        local c_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width), sharp_y)
        format_ctrl(c_stg_sharp, 16, 13, str.LuaString)
        c_stg_sharp:SetText(blank)
        col = col + 1
        --
        str.LuaString = "B"
        local b_stg_static = dialog:CreateStatic(col_x + (col * col_width), row_y-1)
        format_ctrl(b_stg_static, 20, 20, str.LuaString)
        local b_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width), flat_y)
        format_ctrl(b_stg_flat, 16, 13, str.LuaString)
        b_stg_flat:SetText(blank)
        local b_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width), nat_y)
        format_ctrl(b_stg_nat, 16, 13, str.LuaString)
        b_stg_nat:SetText(blank)
        local b_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width), sharp_y)
        format_ctrl(b_stg_sharp, 16, 13, str.LuaString)
        b_stg_sharp:SetText(blank)
        col = col + 1
        --
        if ui:IsOnMac() then
          str.LuaString = "|"
          local pedals_v_line = {}
          for i = 1, 5, 1 do
            pedals_v_line[i] = dialog:CreateStatic(col_x + (col * col_width) - 4, flat_y+(10*(i-1)))
            format_ctrl(pedals_v_line[i], 20, 10, str.LuaString)
          end
        else
          local pedals_v_line1 = dialog:CreateVerticalLine(col_x + (col * col_width) - 1, flat_y, row_h * 3)
        end

        col = col + 1
        --
        local nudge_rt_ped = 12
        str.LuaString = "E"
        local e_stg_static = dialog:CreateStatic(col_x + (col * col_width) - nudge_rt_ped, row_y-1)
        format_ctrl(e_stg_static, 20, 20, str.LuaString)
        local e_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, flat_y)
        format_ctrl(e_stg_flat, 16, 13, str.LuaString)
        e_stg_flat:SetText(blank)
        local e_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, nat_y)
        format_ctrl(e_stg_nat, 16, 13, str.LuaString)
        e_stg_nat:SetText(blank)
        local e_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, sharp_y)
        format_ctrl(e_stg_sharp, 16, 13, str.LuaString)
        e_stg_sharp:SetText(blank)
        col = col + 1
        --                    
        str.LuaString = "F"
        local f_stg_static = dialog:CreateStatic(col_x + (col * col_width) - nudge_rt_ped, row_y-1)
        format_ctrl(f_stg_static, 20, 20, str.LuaString)
        local f_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, flat_y)
        format_ctrl(f_stg_flat, 16, 13, str.LuaString)
        f_stg_flat:SetText(blank)
        local f_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, nat_y)
        format_ctrl(f_stg_nat, 16, 13, str.LuaString)
        f_stg_nat:SetText(blank)
        local f_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, sharp_y)
        format_ctrl(f_stg_sharp, 16, 13, str.LuaString)
        f_stg_sharp:SetText(blank)
        col = col + 1
        --  
        str.LuaString = "G"
        local g_stg_static = dialog:CreateStatic(col_x + (col * col_width) - nudge_rt_ped, row_y-1)
        format_ctrl(g_stg_static, 20, 20, str.LuaString)
        local g_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, flat_y)
        format_ctrl(g_stg_flat, 16, 13, str.LuaString)
        g_stg_flat:SetText(blank)
        local g_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, nat_y)
        format_ctrl(g_stg_nat, 16, 13, str.LuaString)
        g_stg_nat:SetText(blank)
        local g_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, sharp_y)
        format_ctrl(g_stg_sharp, 16, 13, str.LuaString)
        g_stg_sharp:SetText(blank)
        col = col + 1
        --  
        str.LuaString = "A"
        local a_stg_static = dialog:CreateStatic(col_x + (col * col_width) - nudge_rt_ped, row_y-1)
        format_ctrl(a_stg_static, 20, 20, str.LuaString)
        local a_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, flat_y)
        format_ctrl(a_stg_flat, 16, 13, str.LuaString)
        a_stg_flat:SetText(blank)
        local a_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, nat_y)
        format_ctrl(a_stg_nat, 16, 13, str.LuaString)
        a_stg_nat:SetText(blank)
        local a_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, sharp_y)
        format_ctrl(a_stg_sharp, 16, 13, str.LuaString)
        a_stg_sharp:SetText(blank)
        col = col + 1
        --
        local tracker_v_line = dialog:CreateVerticalLine(col_x + (col * col_width) - 8, row_y, row_h * 4)
        col = col + 1
        --
        local last_static = dialog:CreateStatic(col_x + (col * col_width) - 19, row_y)
        str.LuaString = "Last:"
        format_ctrl(last_static, 20, 30, str.LuaString)
--                    last_static:SetVisible(false)
        --
        local lastnotes_static = dialog:CreateStatic(col_x + (col * col_width) + 11, row_y)
        format_ctrl(lastnotes_static, 20, 150, config.last_notes)
--                    lastnotes_static:SetVisible(false)        
--
        changes_static = dialog:CreateStatic(col_x + (col * col_width) - 19, row_y + 18)
        format_ctrl(changes_static, 20, 166, changes_str.LuaString)
        --
        local names_x = col_x + (col * col_width) - 19
        --
        row_y = nat_y - 6
        local notes_label = dialog:CreateStatic(names_x ,row_y+2)
        format_ctrl(notes_label, 14, 160, "Enter Pedals (e.g. C, D#, Fb):")
        local harp_notes = dialog:CreateEdit(names_x + 1, row_y + row_h)
        harp_notes:SetWidth(150)                    

        --
        local ok_btn = dialog:CreateOkButton()
        str.LuaString = "Go"
        ok_btn:SetText(str)
        local close_btn = dialog:CreateCancelButton()
        str.LuaString = "Close"
        close_btn:SetText(str)

        function pedals_update()
          str.LuaString = harpstrings[1]
          d_stg_static:SetText(str)
          if harpstrings[1] == "Db" then
            d_stg_flat:SetCheck(1)
            d_stg_nat:SetCheck(0)
            d_stg_sharp:SetCheck(0)
          elseif harpstrings[1] == "D" then
            d_stg_flat:SetCheck(0)
            d_stg_nat:SetCheck(1)
            d_stg_sharp:SetCheck(0)
          elseif harpstrings[1] == "D#" then
            d_stg_flat:SetCheck(0)
            d_stg_nat:SetCheck(0)
            d_stg_sharp:SetCheck(1)
          end
          str.LuaString = harpstrings[2]
          c_stg_static:SetText(str)
          if harpstrings[2] == "Cb" then
            c_stg_flat:SetCheck(1)
            c_stg_nat:SetCheck(0)
            c_stg_sharp:SetCheck(0)
          elseif harpstrings[2] == "C" then
            c_stg_flat:SetCheck(0)
            c_stg_nat:SetCheck(1)
            c_stg_sharp:SetCheck(0)
          elseif harpstrings[2] == "C#" then
            c_stg_flat:SetCheck(0)
            c_stg_nat:SetCheck(0)
            c_stg_sharp:SetCheck(1)
          end
          str.LuaString = harpstrings[3]
          b_stg_static:SetText(str)                        
          if harpstrings[3] == "Bb" then
            b_stg_flat:SetCheck(1)
            b_stg_nat:SetCheck(0)
            b_stg_sharp:SetCheck(0)
          elseif harpstrings[3] == "B" then
            b_stg_flat:SetCheck(0)
            b_stg_nat:SetCheck(1)
            b_stg_sharp:SetCheck(0)
          elseif harpstrings[3] == "B#" then
            b_stg_flat:SetCheck(0)
            b_stg_nat:SetCheck(0)
            b_stg_sharp:SetCheck(1)
          end   
          str.LuaString = harpstrings[4]
          e_stg_static:SetText(str)                        
          if harpstrings[4] == "Eb" then
            e_stg_flat:SetCheck(1)
            e_stg_nat:SetCheck(0)
            e_stg_sharp:SetCheck(0)
          elseif harpstrings[4] == "E" then
            e_stg_flat:SetCheck(0)
            e_stg_nat:SetCheck(1)
            e_stg_sharp:SetCheck(0)
          elseif harpstrings[4] == "E#" then
            e_stg_flat:SetCheck(0)
            e_stg_nat:SetCheck(0)
            e_stg_sharp:SetCheck(1)
          end                     
          str.LuaString = harpstrings[5]
          f_stg_static:SetText(str)                        
          if harpstrings[5] == "Fb" then
            f_stg_flat:SetCheck(1)
            f_stg_nat:SetCheck(0)
            f_stg_sharp:SetCheck(0)
          elseif harpstrings[5] == "F" then
            f_stg_flat:SetCheck(0)
            f_stg_nat:SetCheck(1)
            f_stg_sharp:SetCheck(0)
          elseif harpstrings[5] == "F#" then
            f_stg_flat:SetCheck(0)
            f_stg_nat:SetCheck(0)
            f_stg_sharp:SetCheck(1)
          end    
          str.LuaString = harpstrings[6]
          g_stg_static:SetText(str)                        
          if harpstrings[6] == "Gb" then
            g_stg_flat:SetCheck(1)
            g_stg_nat:SetCheck(0)
            g_stg_sharp:SetCheck(0)
          elseif harpstrings[6] == "G" then
            g_stg_flat:SetCheck(0)
            g_stg_nat:SetCheck(1)
            g_stg_sharp:SetCheck(0)
          elseif harpstrings[6] == "G#" then
            g_stg_flat:SetCheck(0)
            g_stg_nat:SetCheck(0)
            g_stg_sharp:SetCheck(1)
          end       
          str.LuaString = harpstrings[7]
          a_stg_static:SetText(str)                        
          if harpstrings[7] == "Ab" then
            a_stg_flat:SetCheck(1)
            a_stg_nat:SetCheck(0)
            a_stg_sharp:SetCheck(0)
          elseif harpstrings[7] == "A" then
            a_stg_flat:SetCheck(0)
            a_stg_nat:SetCheck(1)
            a_stg_sharp:SetCheck(0)
          elseif harpstrings[7] == "A#" then
            a_stg_flat:SetCheck(0)
            a_stg_nat:SetCheck(0)
            a_stg_sharp:SetCheck(1)
          end
          if names_checkbox:GetCheck() == 1 then
            stack_checkbox:SetEnable(true)
            lanes_checkbox:SetEnable(true)
          else
            stack_checkbox:SetEnable(false)
            lanes_checkbox:SetEnable(false)
          end
          changes_update()
        end

        function pedal_buttons()
          scale_check:SetCheck(0)
          chord_check:SetCheck(0)
          sel_root:SetEnable(false)
          sel_acc:SetEnable(false)
          sel_scale:SetEnable(false)
          sel_chord:SetEnable(false)
          pedals_update()
        end

        function config_update()
          config.root = sel_root:GetSelectedItem()
          config.accidental = sel_acc:GetSelectedItem()
          config.scale = sel_scale:GetSelectedItem()
          config.scale_check = scale_check:GetCheck()
          config.chord = sel_chord:GetSelectedItem()
          config.chord_check = chord_check:GetCheck()
          config.diagram_check = diagram_checkbox:GetCheck()
          config.names_check = names_checkbox:GetCheck()
          config.partial_check = partial_checkbox:GetCheck()
          config.stack = stack_checkbox:GetCheck()
          config.pedal_lanes = lanes_checkbox:GetCheck()
        end

        function update_variables()
          if diagram_checkbox:GetCheck() == 1 then use_diagram = true 
          elseif diagram_checkbox:GetCheck() == 0 then use_diagram = false end
          if names_checkbox:GetCheck() == 1 then
            if stack_checkbox:GetCheck() == 1 then 
              stack = true
            else
              stack = false
            end
            if lanes_checkbox:GetCheck() == 1  then
              stack = true
              pedal_lanes = true
            else
              pedal_lanes = false
            end
          end
        end

        function callback(ctrl)
          if ctrl:GetControlID() == sel_scale:GetControlID() or ctrl:GetControlID() == sel_chord:GetControlID() then
            scale_update()
          elseif ctrl:GetControlID() == sel_root:GetControlID() or ctrl:GetControlID() == sel_acc:GetControlID() then
            scale_update()
          end 
          if ctrl:GetControlID() == scale_check:GetControlID() and scale_check:GetCheck() == 1 then
            chord_check:SetCheck(0)
            sel_scale:SetEnable(true)
            sel_chord:SetEnable(false)
            sel_root:SetEnable(true)
            sel_acc:SetEnable(true)                        
            scale_update()
          elseif ctrl:GetControlID() == scale_check:GetControlID() and scale_check:GetCheck() == 0 then
            sel_chord:SetEnable(false)
            sel_scale:SetEnable(false)
            sel_root:SetEnable(false)
            sel_acc:SetEnable(false)        
          end
          if ctrl:GetControlID() == chord_check:GetControlID() and chord_check:GetCheck() == 1 then
            scale_check:SetCheck(0)
            sel_chord:SetEnable(true)
            sel_scale:SetEnable(false)
            sel_root:SetEnable(true)
            sel_acc:SetEnable(true)
            scale_update()
          elseif ctrl:GetControlID() == chord_check:GetControlID() and chord_check:GetCheck() == 0 then
            sel_chord:SetEnable(false)
            sel_scale:SetEnable(false)
            sel_root:SetEnable(false)
            sel_acc:SetEnable(false)
          end
          --
          if ctrl:GetControlID() == diagram_checkbox:GetControlID() and diagram_checkbox:GetCheck() == 0 then 
            names_checkbox:SetCheck(1)
            stack_checkbox:SetEnable(true)
            lanes_checkbox:SetEnable(true)                        
          elseif ctrl:GetControlID() == diagram_checkbox:GetControlID() and diagram_checkbox:GetCheck() == 1 then 
            names_checkbox:SetCheck(0) 
            partial_checkbox:SetCheck(0)
            stack_checkbox:SetEnable(false)
            lanes_checkbox:SetEnable(false)
          end 
          --
          if ctrl:GetControlID() == names_checkbox:GetControlID() and names_checkbox:GetCheck() == 0 then 
            diagram_checkbox:SetCheck(1)
            partial_checkbox:SetCheck(0)
            stack_checkbox:SetEnable(false)
            lanes_checkbox:SetEnable(false)                        
          elseif ctrl:GetControlID() == names_checkbox:GetControlID() and names_checkbox:GetCheck() == 1 then 
            diagram_checkbox:SetCheck(0) 
            stack_checkbox:SetEnable(true)
            lanes_checkbox:SetEnable(true)
          end 
          --
          if ctrl:GetControlID() == partial_checkbox:GetControlID() then
            if partial_checkbox:GetCheck() == 1 then
              partial = true
              diagram_checkbox:SetCheck(0)
              names_checkbox:SetCheck(1)
              stack_checkbox:SetEnable(true)
              lanes_checkbox:SetEnable(true)                            
            end
          end
          --
          if ctrl:GetControlID() == stack_checkbox:GetControlID() and stack_checkbox:GetCheck() == 1 then
            stack = true
          elseif ctrl:GetControlID() == stack_checkbox:GetControlID() and stack_checkbox:GetCheck() == 0 then

            stack = false
            lanes_checkbox:SetCheck(0)
            pedal_lanes = false
          end
          --
          if ctrl:GetControlID() == lanes_checkbox:GetControlID() and lanes_checkbox:GetCheck() == 1 then
            stack = true
            stack_checkbox:SetCheck(1)
            pedal_lanes = true
          elseif ctrl:GetControlID() == lanes_checkbox:GetControlID() and lanes_checkbox:GetCheck() == 0 then
            pedal_lanes = false
          end                
          --
          -----------------
          --Pedal buttons--
          -----------------
          if ctrl:GetControlID() == d_stg_flat:GetControlID() and d_stg_flat:GetCheck() == 1 then
            harpstrings[1] = "Db"
            pedal_buttons()
          elseif ctrl:GetControlID() == d_stg_nat:GetControlID() and d_stg_nat:GetCheck() == 1 then
            harpstrings[1] = "D"
            pedal_buttons()
          elseif ctrl:GetControlID() == d_stg_sharp:GetControlID() and d_stg_sharp:GetCheck() == 1 then
            harpstrings[1] = "D#"
            pedal_buttons()
          elseif ctrl:GetControlID() == c_stg_flat:GetControlID() and c_stg_flat:GetCheck() == 1 then
            harpstrings[2] = "Cb"
            pedal_buttons()
          elseif ctrl:GetControlID() == c_stg_nat:GetControlID() and c_stg_nat:GetCheck() == 1 then
            harpstrings[2] = "C"
            pedal_buttons()
          elseif ctrl:GetControlID() == c_stg_sharp:GetControlID() and c_stg_sharp:GetCheck() == 1 then
            harpstrings[2] = "C#"
            pedal_buttons()   
          elseif ctrl:GetControlID() == b_stg_flat:GetControlID() and b_stg_flat:GetCheck() == 1 then
            harpstrings[3] = "Bb"
            pedal_buttons()   
          elseif ctrl:GetControlID() == b_stg_nat:GetControlID() and b_stg_nat:GetCheck() == 1 then
            harpstrings[3] = "B"
            pedal_buttons()    
          elseif ctrl:GetControlID() == b_stg_sharp:GetControlID() and b_stg_sharp:GetCheck() == 1 then
            harpstrings[3] = "B#"
            pedal_buttons()   
          elseif ctrl:GetControlID() == e_stg_flat:GetControlID() and e_stg_flat:GetCheck() == 1 then
            harpstrings[4] = "Eb"
            pedal_buttons()   
          elseif ctrl:GetControlID() == e_stg_nat:GetControlID() and e_stg_nat:GetCheck() == 1 then
            harpstrings[4] = "E"
            pedal_buttons()    
          elseif ctrl:GetControlID() == e_stg_sharp:GetControlID() and e_stg_sharp:GetCheck() == 1 then
            harpstrings[4] = "E#"
            pedal_buttons()   
          elseif ctrl:GetControlID() == f_stg_flat:GetControlID() and f_stg_flat:GetCheck() == 1 then
            harpstrings[5] = "Fb"
            pedal_buttons()   
          elseif ctrl:GetControlID() == f_stg_nat:GetControlID() and f_stg_nat:GetCheck() == 1 then
            harpstrings[5] = "F"
            pedal_buttons()    
          elseif ctrl:GetControlID() == f_stg_sharp:GetControlID() and f_stg_sharp:GetCheck() == 1 then
            harpstrings[5] = "F#"
            pedal_buttons()   
          elseif ctrl:GetControlID() == g_stg_flat:GetControlID() and g_stg_flat:GetCheck() == 1 then
            harpstrings[6] = "Gb"
            pedal_buttons()   
          elseif ctrl:GetControlID() == g_stg_nat:GetControlID() and g_stg_nat:GetCheck() == 1 then
            harpstrings[6] = "G"
            pedal_buttons()    
          elseif ctrl:GetControlID() == g_stg_sharp:GetControlID() and g_stg_sharp:GetCheck() == 1 then
            harpstrings[6] = "G#"
            pedal_buttons()  
          elseif ctrl:GetControlID() == a_stg_flat:GetControlID() and a_stg_flat:GetCheck() == 1 then
            harpstrings[7] = "Ab"
            pedal_buttons()   
          elseif ctrl:GetControlID() == a_stg_nat:GetControlID() and a_stg_nat:GetCheck() == 1 then
            harpstrings[7] = "A"
            pedal_buttons()    
          elseif ctrl:GetControlID() == a_stg_sharp:GetControlID() and a_stg_sharp:GetCheck() == 1 then
            harpstrings[7] = "A#"
            pedal_buttons()                              
          end
          --
          pedals_update()
          update_variables()
          config_update()
          configuration.save_user_settings(script_name, config)
        end -- callback

        function callback_ok(ctrl)
          apply()
        end

        function callback_update(ctrl)
          scale_update()
          pedals_update()
        end

        function root_calc()
          local root_calc = finale.FCString()
          root_calc.LuaString = roots[sel_root:GetSelectedItem()+1]..accidentals[sel_acc:GetSelectedItem()+1]
          root_calc.LuaString = string.gsub(root_calc.LuaString, "♮", "")
          root_calc.LuaString = string.gsub(root_calc.LuaString, "♭", "b") 
          root_calc.LuaString = string.gsub(root_calc.LuaString, "♯", "#")
          return root_calc
        end

        function scale_update()
          --local config = harp_config_load()

          local use_chord = false
          if chord_check:GetCheck() == 1 then use_chord = true end
          local return_string = finale.FCString()
          local root = root_calc()

          if diagram_checkbox:GetCheck() == 1 then use_diagram = true 
          elseif diagram_checkbox:GetCheck() == 0 then use_diagram = false end

          return_string.LuaString = harp_notes:GetText(return_string)
--                    local notes, desc = finale.FCString()
          if return_string.LuaString ~= "" then
--                        harp_diagram(return_string.LuaString, diag)
          end
          if scale_check:GetCheck() == 1 then
            harp_scale(root.LuaString, scales[sel_scale:GetSelectedItem() + 1], use_diagram, use_chord)
          elseif chord_check:GetCheck() == 1 then
            harp_scale(root.LuaString, chords[sel_chord:GetSelectedItem() + 1], use_diagram, use_chord)
          end

          pedals_update()
          configuration.save_user_settings(script_name, config)
--                    ui:RedrawDocument()
--                    finenv.Region():Redraw()
        end

        function strings_read()
          str.LuaString = ""
          for i = 1, 6, 1 do
            str.LuaString = str.LuaString..harpstrings[i]..", "
          end
          str.LuaString = str.LuaString..harpstrings[7]
        end

        function on_close()
          dialog:StorePosition()
          context.window_pos_x = dialog.StoredX
          context.window_pos_y = dialog.StoredY
        end

        function apply()
          update_variables()
          local return_string = finale.FCString()
          return_string.LuaString = harp_notes:GetText(return_string)
          strings_read()
          if partial_checkbox:GetCheck() == 1 then partial = true
          elseif partial_checkbox:GetCheck() == 0 then partial = false end
          if diagram_checkbox:GetCheck() == 1 then use_diagram = true
          else use_diagram = false end
          local root = root_calc()
          local scaleinfo = ""
          if return_string.LuaString ~= "" then
            direct = true
            process_return(return_string.LuaString)
            strings_read()
          else
            if scale_check:GetCheck() == 1 then 
              scaleinfo = root.LuaString.." "..scales[sel_scale:GetSelectedItem() + 1]
            elseif chord_check:GetCheck() == 1 then 
              scaleinfo = root.LuaString..chords[sel_chord:GetSelectedItem() + 1]
            end
          end

          harp_diagram(str.LuaString, use_diagram, scaleinfo, partial)

          if partial and not changes then
            if not override then
              ui:AlertInfo("There are no pedal changes required. Try entering notes directly in the 'Enter Notes' field, or update your 'last used' pedals somewhere else and try again.", nil)
            end
            goto apply_error
          end
          pedals_add(use_diagram, partial)
          ::apply_error::
          str.LuaString = ""
          harp_notes:SetText(str)
          changes_static:SetText(str)
          str.LuaString = harpstrings[1]..", "..harpstrings[2]..", "..harpstrings[3]..", "..harpstrings[4]..", "..harpstrings[5]..", "..harpstrings[6]..", "..harpstrings[7]
          config.last_notes = str.LuaString
          configuration.save_user_settings(script_name, config)
          finenv.Region():Redraw()
          direct = false
          override = false
          changes = false
          direct_notes = {0, 0, 0, 0, 0, 0, 0}
        end -- apply()

        dialog:RegisterHandleCommand(callback)
        dialog:RegisterHandleOkButtonPressed(callback_ok)
        dialog:RegisterHandleDataListSelect(callback_update)
        if dialog.RegisterCloseWindow then
          dialog:RegisterCloseWindow(on_close)
        end
        -- initialize pedals
        partial = false 
        harp_diagram(config.last_notes, use_diagram, scaleinfo, partial)
        update_variables()

        if partial_checkbox:GetCheck() == 1 then partial = true end
        pedals_update()

        dialog.OkButtonCanClose = false
        finenv.RegisterModelessDialog(dialog) -- must register, or ShowModeless does nothing
        dialog:ShowModeless()
        if nil ~= finenv.RetainLuaState then -- if finenv.RetainLuaState then --same?
          finenv.RetainLuaState = true
        end

--                if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
--                end -- if dialog:Execute...

      end -- 
      harp_dialog()
    end -- harp

    harp_pedal_wizard()
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

__imports["library.clef"] = function()
    --[[
    $module Clef

    A library of general clef utility functions.
    ]] --
    local clef = {}

    local client = require("library.client")

    --[[
    % get_cell_clef

    Gets the clef for any cell.

    @ measure (number) The measure number for the cell
    @ staff_number (number) The staff number for the cell
    : (number) The clef for the cell
    ]]
    function clef.get_cell_clef(measure, staff_number)
        local cell_clef = -1
        local cell = finale.FCCell(measure, staff_number)
        local cell_frame_hold = finale.FCCellFrameHold()

        cell_frame_hold:ConnectCell(cell)
        if cell_frame_hold:Load() then
            if cell_frame_hold.IsClefList then
                cell_clef = cell_frame_hold:CreateFirstCellClefChange().ClefIndex
            else
                cell_clef = cell_frame_hold.ClefIndex
            end
        end
        return cell_clef
    end

    --[[
    % get_default_clef

    Gets the default clef for any staff for a specific region.

    @ first_measure (number) The first measure of the region
    @ last_measure (number) The last measure of the region
    @ staff_number (number) The staff number for the cell
    : (number) The default clef for the staff
    ]]
    function clef.get_default_clef(first_measure, last_measure, staff_number)
        local staff = finale.FCStaff()
        local cell_clef = clef.get_cell_clef(first_measure - 1, staff_number)
        if cell_clef < 0 then -- failed, so check clef AFTER insertion
            cell_clef = clef.get_cell_clef(last_measure + 1, staff_number)
            if cell_clef < 0 then -- resort to destination staff default clef
                cell_clef = staff:Load(staff_number) and staff.DefaultClef or 0 -- default treble
            end
        end
        return cell_clef
    end

    --[[
    % restore_default_clef

    Restores the default clef for any staff for a specific region.

    @ first_measure (number) The first measure of the region
    @ last_measure (number) The last measure of the region
    @ staff_number (number) The staff number for the cell
    ]]
    function clef.restore_default_clef(first_measure, last_measure, staff_number)
        client.assert_supports("clef_change")

        local default_clef = clef.get_default_clef(first_measure, last_measure, staff_number)

        for measure = first_measure, last_measure do
            local cell = finale.FCCell(measure, staff_number)
            local cell_frame_hold = finale.FCCellFrameHold()
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
                cell_frame_hold:MakeCellSingleClef(nil) -- RGPLua v0.60
                cell_frame_hold:SetClefIndex(default_clef)
                cell_frame_hold:Save()
            end
        end
    end

    return clef

end

__imports["library.layer"] = function()
    --[[
    $module Layer
    ]] --
    local layer = {}
    
    --[[
    % copy
    
    Duplicates the notes from the source layer to the destination. The source layer remains untouched.
    
    @ region (FCMusicRegion) the region to be copied
    @ source_layer (number) the number (1-4) of the layer to duplicate
    @ destination_layer (number) the number (1-4) of the layer to be copied to
    ]]
    function layer.copy(region, source_layer, destination_layer)
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        source_layer = source_layer - 1
        destination_layer = destination_layer - 1
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local noteentry_source_layer = finale.FCNoteEntryLayer(source_layer, staffNum, start, stop)
            noteentry_source_layer:Load()
            local noteentry_destination_layer = noteentry_source_layer:CreateCloneEntries(
                                                    destination_layer, staffNum, start)
            noteentry_destination_layer:Save()
            noteentry_destination_layer:CloneTuplets(noteentry_source_layer)
            noteentry_destination_layer:Save()
        end
    end -- function layer_copy
    
    --[[
    % clear
    
    Clears all entries from a given layer.
    
    @ region (FCMusicRegion) the region to be cleared
    @ layer_to_clear (number) the number (1-4) of the layer to clear
    ]]
    function layer.clear(region, layer_to_clear)
        layer_to_clear = layer_to_clear - 1 -- Turn 1 based layer to 0 based layer
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local noteentrylayer = finale.FCNoteEntryLayer(layer_to_clear, staffNum, start, stop)
            noteentrylayer:Load()
            noteentrylayer:ClearAllEntries()
        end
    end
    
    --[[
    % swap
    
    Swaps the entries from two different layers (e.g. 1-->2 and 2-->1).
    
    @ region (FCMusicRegion) the region to be swapped
    @ swap_a (number) the number (1-4) of the first layer to be swapped
    @ swap_b (number) the number (1-4) of the second layer to be swapped
    ]]
    function layer.swap(region, swap_a, swap_b)
        -- Set layers for 0 based
        swap_a = swap_a - 1
        swap_b = swap_b - 1
        for measure, staff_number in eachcell(region) do
            local cell_frame_hold = finale.FCCellFrameHold()    
            cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
            local loaded = cell_frame_hold:Load()
            local cell_clef_changes = loaded and cell_frame_hold.IsClefList and cell_frame_hold:CreateCellClefChanges() or nil
            local noteentrylayer_1 = finale.FCNoteEntryLayer(swap_a, staff_number, measure, measure)
            noteentrylayer_1:Load()
            noteentrylayer_1.LayerIndex = swap_b
            --
            local noteentrylayer_2 = finale.FCNoteEntryLayer(swap_b, staff_number, measure, measure)
            noteentrylayer_2:Load()
            noteentrylayer_2.LayerIndex = swap_a
            noteentrylayer_1:Save()
            noteentrylayer_2:Save()
            if loaded then
                local new_cell_frame_hold = finale.FCCellFrameHold()
                new_cell_frame_hold:ConnectCell(finale.FCCell(measure, staff_number))
                if new_cell_frame_hold:Load() then
                    if cell_frame_hold.IsClefList then
                        if new_cell_frame_hold.SetCellClefChanges then
                            new_cell_frame_hold:SetCellClefChanges(cell_clef_changes)
                        end
                        -- No remedy here in JW Lua. The clef list can be changed by a layer swap.
                    else
                        new_cell_frame_hold.ClefIndex = cell_frame_hold.ClefIndex
                    end
                    new_cell_frame_hold:Save()
                end
            end
        end
    end
    
    return layer

end

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.64"
    finaleplugin.Date = "2022/07/11"
    finaleplugin.Notes = [[
        This script is keyboard-centred requiring minimal mouse action. 
        It takes music in Layer 1 from one staff in the selected region and creates a "Cue" version on another chosen staff. 
        The cue copy is reduced in size and muted, and can duplicate chosen markings from the original. 
        It is shifted to the chosen layer with a (real) whole-note rest placed in layer 1.

        Your choices are saved after each script run in your user preferences folder. 
        If using RGPLua (v0.58+) the script automatically creates a new expression category 
        called "Cue Names" if it does not exist. 
        If using JWLua, before running the script you must create an Expression Category 
        called "Cue Names" containing at least one text expression.
    ]]
    return "Cue Notes Create…", "Cue Notes Create", "Copy as cue notes to another staff"
end

local config = { -- retained and over-written by the user's "settings" file
    copy_articulations  =   false,
    copy_expressions    =   false,
    copy_smartshapes    =   false,
    copy_slurs          =   true,
    copy_clef           =   false,
    mute_cuenotes       =   true,
    cuenote_percent     =   70,    -- (75% too big, 66% too small)
    cuenote_layer       =   3,
    freeze_up_down      =   0,      -- "0" for no freezing, "1" for up, "2" for down
    -- if creating a new "Cue Names" category ...
    cue_category_name   =   "Cue Names",
    cue_font_smaller    =   1, -- how many points smaller than the standard technique expression
}
local configuration = require("library.configuration")
local clef = require("library.clef")
local layer = require("library.layer")

configuration.get_user_settings("cue_notes_create", config, true)

function show_error(error_code)
    local errors = {
        only_one_staff = "Please select just one staff\n as the source for the new cue",
        empty_region = "Please select a region\nwith some notes in it!",
        first_make_expression_category = "You must first create a new Text Expression Category called \""..config.cue_category_name.."\" containing at least one entry",
    }
    finenv.UI():AlertNeutral("script: " .. plugindef(), errors[error_code])
    return -1
end

function should_overwrite_existing_music()
    local alert = finenv.UI():AlertOkCancel("script: " .. plugindef(), "Overwrite existing music?")
    local should_overwrite = (alert == 0)
    return should_overwrite
end

function region_is_empty(region)
    for entry in eachentry(region) do
        if entry.Count > 0 then
            return false
        end
    end
    return true
end

function new_cue_name(source_staff)
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    str.LuaString = "New cue name:"
    dialog:CreateStatic(0, 20):SetText(str)
    
	local the_name = dialog:CreateEdit(0, 40)
	the_name:SetWidth(200)
	-- copy default name from the source Staff Name
	local staff = finale.FCStaff()
	staff:Load(source_staff)
	the_name:SetText( staff:CreateDisplayFullNameString() )
	
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    the_name:GetText(str)
    return ok, str.LuaString
end

function choose_name_index(name_list)
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
    str.LuaString = "Select cue name:"
    dialog:CreateStatic(0, 20):SetText(str)

	local staff_list = dialog:CreateListBox(0, 40)
	staff_list:SetWidth(200)
	-- item "0" in the list is "*** new name ***"
    str.LuaString = "*** new name ***"
	staff_list:AddString(str)

    -- add all names in the extant list
    for i,v in ipairs(name_list) do
        str.LuaString = v[1]  -- copy the name, not the ItemNo
		staff_list:AddString(str)
	end
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, staff_list:GetSelectedItem()
    -- NOTE: returns the chosen INDEX number (0-based)
end

function create_new_expression(exp_name, category_number)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(category_number)
    local tfi = cat_def:CreateTextFontInfo()
    local str = finale.FCString()
    str.LuaString = "^fontTxt"
        .. tfi:CreateEnigmaString(finale.FCString()).LuaString
        .. exp_name
    local ted = finale.FCTextExpressionDef()
    ted:SaveNewTextBlock(str)
    ted:AssignToCategory(cat_def)
    ted:SetUseCategoryPos(true)
    ted:SetUseCategoryFont(true)
    ted:SaveNew()
    return ted:GetItemNo() -- *** RETURNS the new expression's ITEM NUMBER
end

function choose_destination_staff(source_staff)
	local staff_list = {}    -- compile all staves in the score
    local rgn = finenv.Region()
    -- compile staff list by slot number
    local original_slot = rgn.StartSlot
    rgn:SetFullMeasureStack()   -- scan the whole stack
    local staff = finale.FCStaff()
    for slot = rgn.StartSlot, rgn.EndSlot do
        local staff_number = rgn:CalcStaffNumber(slot)
        if staff_number ~= source_staff then
            staff:Load(staff_number) -- staff at this slot
            table.insert(staff_list, { staff_number, staff:CreateDisplayFullNameString().LuaString } )
        end
    end
    rgn.StartSlot = original_slot -- restore original single staff
    rgn.EndSlot = original_slot

    -- draw up the dialog box
    local horiz_grid = { 210, 310, 360 }
    local vert_step = 20
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra horizontal offset for Mac edit boxes
    local user_checks = { -- boolean config values - copy choices from CONFIG file
        "copy_articulations",   "copy_expressions",   "copy_smartshapes",
        "copy_slurs",           "copy_clef",          "mute_cuenotes",
        -- integer config values - copy choices from CONFIG file
        "cuenote_percent",      "cuenote_layer",       "freeze_up_down"
    }
    local boolean_count = 6 -- higher than this number are integer config values, not checkboxes
    local user_selections = {}  -- an array of controls corresponding to user choices

    local str = finale.FCString()
    local dialog = finale.FCCustomLuaWindow()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
    local static = dialog:CreateStatic(0, 0)
    str.LuaString = "Select destination staff:"
    static:SetText(str)
	static:SetWidth(200)
	
	local list_box = dialog:CreateListBox(0, vert_step)
    list_box.UseCheckboxes = true
	list_box:SetWidth(200)
    for i,v in ipairs(staff_list) do -- list all staff names
        str.LuaString = v[2]
		list_box:AddString(str)
	end
    -- add user options
    str.LuaString = "Cue Options:"
    dialog:CreateStatic(horiz_grid[1], 0):SetText(str)

    for i,v in ipairs(user_checks) do -- run through config parameters
        str.LuaString = string.gsub(v, '_', ' ')
        if i <= boolean_count then -- boolean checkbox
            user_selections[i] = dialog:CreateCheckbox(horiz_grid[1], i * vert_step)
            user_selections[i]:SetText(str)
            user_selections[i]:SetWidth(120)
            local checked = config[v] and 1 or 0
            user_selections[i]:SetCheck(checked)
        elseif i < #user_checks then    -- integer value (#user_checks = stem_direction_popup)
            str.LuaString = str.LuaString .. ":"
            dialog:CreateStatic(horiz_grid[1], i * vert_step):SetText(str)
            user_selections[i] = dialog:CreateEdit(horiz_grid[2], (i * vert_step) - mac_offset)
            user_selections[i]:SetInteger(config[v])
            user_selections[i]:SetWidth(50)
        end
    end
    -- popup for stem direction
    local stem_direction_popup = dialog:CreatePopup(horiz_grid[1], (#user_checks * vert_step) + 5)
    str.LuaString = "Stems: normal"
    stem_direction_popup:AddString(str)  -- config.freeze_up_down == 0
    str.LuaString = "Stems: freeze up"
    stem_direction_popup:AddString(str)  -- config.freeze_up_down == 1
    str.LuaString = "Stems: freeze down"
    stem_direction_popup:AddString(str)  -- config.freeze_up_down == 2
    stem_direction_popup:SetWidth(160)
    stem_direction_popup:SetSelectedItem(config.freeze_up_down) -- 0-based index

    -- "CLEAR ALL" button to clear copy choices
    local clear_button = dialog:CreateButton(horiz_grid[3], vert_step * 2)
    str.LuaString = "Clear All"
    clear_button:SetWidth(80)
    clear_button:SetText(str)
    dialog:RegisterHandleControlEvent ( clear_button,
        function()
            for i = 1, boolean_count do
                user_selections[i]:SetCheck(0)
            end
            list_box:SetKeyboardFocus()
        end
    )

    -- "SET ALL" button to set all copy choices
    local set_button = dialog:CreateButton(horiz_grid[3], vert_step * 4)
    str.LuaString = "Set All"
    set_button:SetWidth(80)
    set_button:SetText(str)
    dialog:RegisterHandleControlEvent ( set_button,
        function()
            for i = 1, boolean_count do
                user_selections[i]:SetCheck(1)
            end
            list_box:SetKeyboardFocus()
        end
    )
    -- run the dialog
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    local selected_item = list_box:GetSelectedItem() -- retrieve user staff selection (index base 0)
    local chosen_staff_number = staff_list[selected_item + 1][1]

    -- save User Pref changes
    for i,v in ipairs(user_checks) do -- run through config parameters
        if i <= boolean_count then
            config[v] = (user_selections[i]:GetCheck() == 1) -- "true" for value 1, checked
        elseif i < #user_checks then    -- integer value (#user_checks = stem_direction_popup)
            local answer = user_selections[i]:GetInteger()
            if i == #user_selections and (answer < 2 or answer > 4) then -- legitimate layer number choice?
                answer = 4 -- make sure layer number is in range
            end
            config[v] = answer
        end
    end
    config.freeze_up_down = stem_direction_popup:GetSelectedItem() -- 0-based index
    return ok, chosen_staff_number
end

function fix_text_expressions(region)
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    for expression in eachbackwards(expressions) do
        if expression.StaffGroupID == 0 then -- staff-attached expressions only
            if config.copy_expressions then -- keep them and switch to cuenote layer
                expression.LayerAssignment = config.cuenote_layer
                expression.ScaleWithEntry = true -- and scale to smaller noteheads
                expression:Save()
            else
                expression:DeleteData() -- otherwise delete them
            end
        end
    end
end

function copy_to_destination(source_region, destination_staff)
    local destination_region = finale.FCMusicRegion()
    destination_region:SetRegion(source_region)
    destination_region:CopyMusic() -- copy the original
    destination_region.StartStaff = destination_staff
    destination_region.EndStaff = destination_staff

    if not region_is_empty(destination_region) and (not should_overwrite_existing_music()) then
        destination_region:ReleaseMusic() -- clear memory
        return false -- and go home
    end
    -- otherwise carry on ...
    destination_region:PasteMusic()   -- paste the copy
    destination_region:ReleaseMusic() -- and release memory
    for layer_number = 2, 4 do     -- clear out LAYERS 2-4
        layer.clear(destination_region, layer_number)
    end

    -- mute / set to % size / delete articulations / freeze stems
    for entry in eachentrysaved(destination_region) do
        if entry:IsNote() and config.mute_cuenotes then
            entry.Playback = false
        end
        entry:SetNoteDetailFlag(true)
        local entry_mod = finale.FCEntryAlterMod()
        entry_mod:SetNoteEntry(entry)
        entry_mod:SetResize(config.cuenote_percent)
        entry_mod:Save()
        
        if not config.copy_articulations and entry:GetArticulationFlag() then
            for articulation in each(entry:CreateArticulations()) do
                articulation:DeleteData()
            end
            entry:SetArticulationFlag(false)
        end
        if config.freeze_up_down > 0 then -- frozen stems requested
            entry.FreezeStem = true
            entry.StemUp = (config.freeze_up_down == 1) -- "true" -> upstem, "false" -> downstem
        end
    end
    -- swap layer 1 with cuenote_layer & fix clef
    layer.swap(destination_region, 1, config.cuenote_layer)
    if not config.copy_clef then
        clef.restore_default_clef(destination_region.StartMeasure, destination_region.EndMeasure, destination_staff)
    end

    -- delete or amend text expressions
    fix_text_expressions(destination_region)
    -- check smart shapes
    if not config.copy_smartshapes or not config.copy_slurs then
        local marks = finale.FCSmartShapeMeasureMarks()
        marks:LoadAllForRegion(destination_region, true)
        for one_mark in each(marks) do
            local shape = one_mark:CreateSmartShape()
            if (shape:IsSlur() and not config.copy_slurs) or (not shape:IsSlur() and not config.copy_smartshapes) then
                shape:DeleteData()
            end
        end
    end

    -- create whole-note rest in layer 1 in each measure
    for measure = destination_region.StartMeasure, destination_region.EndMeasure do
        local notecell = finale.FCNoteEntryCell(measure, destination_staff)
        notecell:Load()
        local whole_note = notecell:AppendEntriesInLayer(1, 1) --   Append to layer 1, add 1 entry
        if whole_note then
            whole_note.Duration = finale.WHOLE_NOTE
            whole_note.Legality = true
            whole_note:MakeRest()
            notecell:Save()
        end
    end
    return true
end

function new_expression_category(new_name)
    local ok = false
    local category_id = 0
    if not finenv.IsRGPLua then  -- SaveNewWithType only works on RGPLua 0.58+
        return ok, category_id   -- and crashes on JWLua
    end
    local new_category = finale.FCCategoryDef()
    new_category:Load(finale.DEFAULTCATID_TECHNIQUETEXT)
    local str = finale.FCString()
    str.LuaString = new_name
    new_category:SetName(str)
    new_category:SetVerticalAlignmentPoint(finale.ALIGNVERT_STAFF_REFERENCE_LINE)
    new_category:SetVerticalBaselineOffset(30)
    new_category:SetHorizontalAlignmentPoint(finale.ALIGNHORIZ_CLICKPOS)
    new_category:SetHorizontalOffset(-18)
    -- make font slightly smaller than standard TECHNIQUE expression
    local tfi = new_category:CreateTextFontInfo()
    tfi.Size = tfi.Size - config.cue_font_smaller
    new_category:SetTextFontInfo(tfi)
    
    ok = new_category:SaveNewWithType(finale.DEFAULTCATID_TECHNIQUETEXT)
    if ok then
        category_id = new_category:GetID()
    end
    return ok, category_id
end

function assign_expression_to_staff(staff_number, measure_number, measure_position, expression_id)
    local new_expression = finale.FCExpression()
    new_expression:SetStaff(staff_number)
    new_expression:SetVisible(true)
    new_expression:SetMeasurePos(measure_position)
    new_expression:SetScaleWithEntry(false)    -- could possibly be true!  
    new_expression:SetPartAssignment(true)
    new_expression:SetScoreAssignment(true)
    new_expression:SetID(expression_id)
    new_expression:SaveNewToCell( finale.FCCell(measure_number, staff_number) )
end

function create_cue_notes()
	local cue_names = { }	-- compile NAME/ItemNo of all pre-existing CUE_NAME expressions
    local source_region = finenv.Region()
    local start_staff = source_region.StartStaff
    -- declare all other local variables
    local ok, cd, expression_defs, cat_ID, expression_ID, name_index, destination_staff, new_expression

    if source_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    elseif region_is_empty(source_region) then
        return show_error("empty_region")
    end
    
    cd = finale.FCCategoryDef()
    expression_defs = finale.FCTextExpressionDefs()
	expression_defs:LoadAll()

	-- collate extant cue names
	for text_def in each(expression_defs) do
		cd:Load(text_def.CategoryID)
		if string.find(cd:CreateName().LuaString, config.cue_category_name) then
			cat_ID = text_def.CategoryID
			local str = text_def:CreateTextString()
			str:TrimEnigmaTags()
			-- save expresion NAME and ItemNo
			table.insert(cue_names, {str.LuaString, text_def.ItemNo} )
	    end
	end
	-- test for pre-existing names
	if #cue_names == 0 then
	    -- create a new Text Expression Category
	    ok, cat_ID = new_expression_category(config.cue_category_name)
	    if not ok then -- creation failed
            return show_error("first_make_expression_category")
        end
	end
	-- choose cue name
	ok, name_index = choose_name_index(cue_names)
    if not ok then
        return
    end
	if name_index == 0 then	-- USER wants to provide a new cue name
		ok, new_expression = new_cue_name(start_staff)
		if not ok or new_expression == "" then
            return
        end
		expression_ID = create_new_expression(new_expression, cat_ID)
	else          -- otherwise get the ItemNo of chosen pre-existing expression
	    expression_ID = cue_names[name_index][2] --([name_index][1] is the item name)
    end
    -- choose destination staff
	ok, destination_staff = choose_destination_staff(start_staff)
	if not ok then
        return
    end
    -- save revised config file
    configuration.save_user_settings("cue_notes_create", config)
    -- make the cue copy
	if not copy_to_destination(source_region, destination_staff) then
        return
    end
	-- name the cue
	assign_expression_to_staff(destination_staff, source_region.StartMeasure, 0, expression_ID)
    -- reset visible selection to original staff
    source_region:SetInDocument()
end

create_cue_notes() -- go and do it already

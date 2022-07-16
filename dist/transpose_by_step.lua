local __imports = {}

function require(item)
    return __imports[item]()
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

__imports["library.transposition"] = function()
    --[[
    $module Transposition

    A collection of helpful JW Lua transposition scripts.

    This library allows configuration of custom key signatures by means
    of a configuration file called "custom_key_sig.config.txt" in the
    "script_settings" subdirectory. However, RGP Lua (starting with version 0.58)
    can read the correct custom key signature information directly from
    Finale. Therefore, when you run this script with RGP Lua 0.58+, the configuration file
    is ignored.
    ]] --
    -- Structure
    -- 1. Helper functions
    -- 2. Diatonic Transposition
    -- 3. Enharmonic Transposition
    -- 3. Chromatic Transposition
    --
    local transposition = {}

    local configuration = require("library.configuration")

    local standard_key_number_of_steps = 12
    local standard_key_major_diatonic_steps = {0, 2, 4, 5, 7, 9, 11}
    local standard_key_minor_diatonic_steps = {0, 2, 3, 5, 7, 8, 10}

    local max_allowed_abs_alteration = 7 -- Finale cannot represent an alteration outside +/- 7

    -- first number is plus_fifths
    -- second number is minus_octaves
    local diatonic_interval_adjustments = {{0, 0}, {2, -1}, {4, -2}, {-1, 1}, {1, 0}, {3, -1}, {5, -2}, {0, 1}}

    local custom_key_sig_config = {
        number_of_steps = standard_key_number_of_steps,
        diatonic_steps = standard_key_major_diatonic_steps,
    }

    configuration.get_parameters("custom_key_sig.config.txt", custom_key_sig_config)

    --
    -- HELPER functions
    --

    local sign = function(n)
        if n < 0 then
            return -1
        end
        return 1
    end

    -- this is necessary because the % operator in lua appears always to return a positive value,
    -- unlike the % operator in c++
    local signed_modulus = function(n, d)
        return sign(n) * (math.abs(n) % d)
    end

    local get_key = function(note)
        local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
        return cell:GetKeySignature()
    end

    -- These local functions that take FCKeySignature (key) as their first argument should
    -- perhaps move to a key_signature library someday.

    -- return number of steps, diatonic steps map, and number of steps in fifth
    local get_key_info = function(key)
        local number_of_steps = standard_key_number_of_steps
        local diatonic_steps = standard_key_major_diatonic_steps
        if finenv.IsRGPLua and key.CalcTotalChromaticSteps then -- if this version of RGP Lua supports custom key sigs
            number_of_steps = key:CalcTotalChromaticSteps()
            diatonic_steps = key:CalcDiatonicStepsMap()
        else
            if not key:IsPredefined() then
                number_of_steps = custom_key_sig_config.number_of_steps
                diatonic_steps = custom_key_sig_config.diatonic_steps
            elseif key:IsMinor() then
                diatonic_steps = standard_key_minor_diatonic_steps
            end
        end
        -- 0.5849625 is log(3/2)/log(2), which is how to calculate the 5th per Ere Lievonen.
        -- For basically any practical key sig this calculation comes out to the 5th scale degree,
        -- which is 7 chromatic steps for standard keys
        local fifth_steps = math.floor((number_of_steps * 0.5849625) + 0.5)
        return number_of_steps, diatonic_steps, fifth_steps
    end

    local calc_scale_degree = function(interval, number_of_diatonic_steps_in_key)
        local interval_normalized = signed_modulus(interval, number_of_diatonic_steps_in_key)
        if interval_normalized < 0 then
            interval_normalized = interval_normalized + number_of_diatonic_steps_in_key
        end
        return interval_normalized
    end

    local calc_steps_between_scale_degrees = function(key, first_disp, second_disp)
        local number_of_steps_in_key, diatonic_steps = get_key_info(key)
        local first_scale_degree = calc_scale_degree(first_disp, #diatonic_steps)
        local second_scale_degree = calc_scale_degree(second_disp, #diatonic_steps)
        local number_of_steps = sign(second_disp - first_disp) *
                                    (diatonic_steps[second_scale_degree + 1] - diatonic_steps[first_scale_degree + 1])
        if number_of_steps < 0 then
            number_of_steps = number_of_steps + number_of_steps_in_key
        end
        return number_of_steps
    end

    local calc_steps_in_alteration = function(key, interval, alteration)
        local number_of_steps_in_key, _, fifth_steps = get_key_info(key)
        local plus_fifths = sign(interval) * alteration * 7 -- number of fifths to add for alteration
        local minus_octaves = sign(interval) * alteration * -4 -- number of octaves to subtract for alteration
        local new_alteration = sign(interval) * ((plus_fifths * fifth_steps) + (minus_octaves * number_of_steps_in_key)) -- new alteration for chromatic interval
        return new_alteration
    end

    local calc_steps_in_normalized_interval = function(key, interval_normalized)
        local number_of_steps_in_key, _, fifth_steps = get_key_info(key)
        local plus_fifths = diatonic_interval_adjustments[math.abs(interval_normalized) + 1][1] -- number of fifths to add for interval
        local minus_octaves = diatonic_interval_adjustments[math.abs(interval_normalized) + 1][2] -- number of octaves to subtract for alteration
        local number_of_steps_in_interval = sign(interval_normalized) *
                                                ((plus_fifths * fifth_steps) + (minus_octaves * number_of_steps_in_key))
        return number_of_steps_in_interval
    end

    local simplify_spelling = function(note, min_abs_alteration)
        while math.abs(note.RaiseLower) > min_abs_alteration do
            local curr_sign = sign(note.RaiseLower)
            local curr_abs_disp = math.abs(note.RaiseLower)
            local direction = curr_sign
            local success = transposition.enharmonic_transpose(note, direction, true) -- true: ignore errors (success is always true)
            if not success then
                return false
            end
            if math.abs(note.RaiseLower) >= curr_abs_disp then
                return transposition.enharmonic_transpose(note, -1 * direction)
            end
            if curr_sign ~= sign(note.RaiseLower) then
                break
            end
        end
        return true
    end

    --
    -- DIATONIC transposition (affect only Displacement)
    --

    --[[
    % diatonic_transpose

    Transpose the note diatonically by the given interval displacement.

    @ note (FCNote) input and modified output
    @ interval (number) 0 = unison, 1 = up a diatonic second, -2 = down a diatonic third, etc.
    ]]
    function transposition.diatonic_transpose(note, interval)
        note.Displacement = note.Displacement + interval
    end

    --[[
    % change_octave

    Transpose the note by the given number of octaves.

    @ note (FCNote) input and modified output
    @ number_of_octaves (number) 0 = no change, 1 = up an octave, -2 = down 2 octaves, etc.
    ]]
    function transposition.change_octave(note, number_of_octaves)
        transposition.diatonic_transpose(note, 7 * number_of_octaves)
    end

    --
    -- ENHARMONIC transposition
    --

    --[[
    % enharmonic_transpose

    Transpose the note enharmonically in the given direction. In some microtone systems this yields a different result than transposing by a diminished 2nd.
    Failure occurs if the note's `RaiseLower` value exceeds an absolute value of 7. This is a hard-coded limit in Finale.

    @ note (FCNote) input and modified output
    @ direction (number) positive = up, negative = down (normally 1 or -1, but any positive or negative numbers work)
    @ [ignore_error] (boolean) default false. If true, always return success. External callers should omit this parameter.
    : (boolean) success or failure
    ]]
    function transposition.enharmonic_transpose(note, direction, ignore_error)
        ignore_error = ignore_error or false
        local curr_disp = note.Displacement
        local curr_alt = note.RaiseLower
        local key = get_key(note)
        local key_step_enharmonic = calc_steps_between_scale_degrees(
                                        key, note.Displacement, note.Displacement + sign(direction))
        transposition.diatonic_transpose(note, sign(direction))
        note.RaiseLower = note.RaiseLower - sign(direction) * key_step_enharmonic
        if ignore_error then
            return true
        end
        if math.abs(note.RaiseLower) > max_allowed_abs_alteration then
            note.Displacement = curr_disp
            note.RaiseLower = curr_alt
            return false
        end
        return true
    end

    --
    -- CHROMATIC transposition (affect Displacement and RaiseLower)
    --

    --[[
    % chromatic_transpose

    Transposes a note chromatically by the input chromatic interval. Supports custom key signatures
    and microtone systems by means of a `custom_key_sig.config.txt` file. In Finale, chromatic intervals
    are defined by a diatonic displacement (0 = unison, 1 = second, 2 = third, etc.) and a chromatic alteration.
    Major and perfect intervals have a chromatic alteration of 0. So for example, `{2, -1}` is up a minor third, `{3, 0}`
    is up a perfect fourth, `{5, 1}` is up an augmented sixth, etc. Reversing the signs of both values in the pair
    allows for downwards transposition.

    @ note (FCNote) the note to transpose
    @ interval (number) the diatonic displacement (negative for transposing down)
    @ alteration (number) the chromatic alteration that defines the chromatic interval (reverse sign for transposing down)
    @ [simplify] (boolean) if present and true causes the spelling of the transposed note to be simplified
    : (boolean) success or failure (see `enharmonic_transpose` for what causes failure)
    --]]
    function transposition.chromatic_transpose(note, interval, alteration, simplify)
        simplify = simplify or false
        local curr_disp = note.Displacement
        local curr_alt = note.RaiseLower

        local key = get_key(note)
        local number_of_steps, diatonic_steps, fifth_steps = get_key_info(key)
        local interval_normalized = signed_modulus(interval, #diatonic_steps)
        local steps_in_alteration = calc_steps_in_alteration(key, interval, alteration)
        local steps_in_interval = calc_steps_in_normalized_interval(key, interval_normalized)
        local steps_in_diatonic_interval = calc_steps_between_scale_degrees(
                                               key, note.Displacement, note.Displacement + interval_normalized)
        local effective_alteration = steps_in_alteration + steps_in_interval - sign(interval) * steps_in_diatonic_interval
        transposition.diatonic_transpose(note, interval)
        note.RaiseLower = note.RaiseLower + effective_alteration

        local min_abs_alteration = max_allowed_abs_alteration
        if simplify then
            min_abs_alteration = 0
        end
        local success = simplify_spelling(note, min_abs_alteration)
        if not success then -- if Finale can't represent the transposition, revert it to original value
            note.Displacement = curr_disp
            note.RaiseLower = curr_alt
        end
        return success
    end

    --[[
    % stepwise_transpose

    Transposes the note by the input number of steps and simplifies the spelling.
    For predefined key signatures, each step is a half-step.
    For microtone systems defined with custom key signatures and matching options in the `custom_key_sig.config.txt` file,
    each step is the smallest division of the octave defined by the custom key signature.

    @ note (FCNote) input and modified output
    @ number_of_steps (number) positive = up, negative = down
    : (boolean) success or failure (see `enharmonic_transpose` for what causes failure)
    ]]
    function transposition.stepwise_transpose(note, number_of_steps)
        local curr_disp = note.Displacement
        local curr_alt = note.RaiseLower
        note.RaiseLower = note.RaiseLower + number_of_steps
        local success = simplify_spelling(note, 0)
        if not success then -- if Finale can't represent the transposition, revert it to original value
            note.Displacement = curr_disp
            note.RaiseLower = curr_alt
        end
        return success
    end

    --[[
    % chromatic_major_third_down

    Transpose the note down by a major third.

    @ note (FCNote) input and modified output
    ]]
    function transposition.chromatic_major_third_down(note)
        transposition.chromatic_transpose(note, -2, -0)
    end

    --[[
    % chromatic_perfect_fourth_up

    Transpose the note up by a perfect fourth.

    @ note (FCNote) input and modified output
    ]]
    function transposition.chromatic_perfect_fourth_up(note)
        transposition.chromatic_transpose(note, 3, 0)
    end

    --[[
    % chromatic_perfect_fifth_down

    Transpose the note down by a perfect fifth.

    @ note (FCNote) input and modified output
    ]]
    function transposition.chromatic_perfect_fifth_down(note)
        transposition.chromatic_transpose(note, -4, -0)
    end

    return transposition

end

__imports["library.general_library"] = function()
    --[[
    $module Library
    ]] --
    local library = {}

    --[[
    % finale_version

    Returns a raw Finale version from major, minor, and (optional) build parameters. For 32-bit Finale
    this is the internal major Finale version, not the year.

    @ major (number) Major Finale version
    @ minor (number) Minor Finale version
    @ [build] (number) zero if omitted
    : (number)
    ]]
    function library.finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

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
    % is_default_number_visible_and_left_aligned

    Returns true if measure number for the input cell is visible and left-aligned.

    @ meas_num_region (FCMeasureNumberRegion)
    @ cell (FCCell)
    @ system (FCStaffSystem)
    @ current_is_part (boolean) true if the current view is a linked part, otherwise false
    @ is_for_multimeasure_rest (boolean) true if the current cell starts a multimeasure rest
    : (boolean)
    ]]
    function library.is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part,
                                                                is_for_multimeasure_rest)
        if meas_num_region.UseScoreInfoForParts then
            current_is_part = false
        end
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
        local do_getenv = function (win_var, mac_var)
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
                    return io.popen('dir "'..smufl_directory..'" /b /ad')
                else
                    return io.popen('ls "'..smufl_directory..'"')
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

        if finenv.RawFinaleVersion >= library.finale_version(27, 1) then
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


    return library

end

__imports["library.utils"] = function()
    --[[
    $module Utility Functions

    A library of general Lua utility functions.
    ]] --
    local utils = {}

    --[[
    % copy_table

    If a table is passed, returns a copy, otherwise returns the passed value.

    @ t (mixed)
    : (mixed)
    ]]
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

    --[[
    % table_remove_first

    Removes the first occurrence of a value from an array table.

    @ t (table)
    @ value (mixed)
    ]]
    function utils.table_remove_first(t, value)
        for k = 1, #t do
            if t[k] == value then
                table.remove(t, k)
                return
            end
        end
    end

    --[[
    % iterate_keys

    Returns an unordered iterator for the keys in a table.

    @ t (table)
    : (function)
    ]]
    function utils.iterate_keys(t)
        local a, b, c = pairs(t)

        return function()
            c = a(b, c)
            return c
        end
    end

    --[[
    % round

    Rounds a number to the nearest whole integer.

    @ num (number)
    : (number)
    ]]
    function utils.round(num)
        return math.floor(num + 0.5)
    end

    return utils

end

__imports["library.mixin"] = function()
    --  Author: Edward Koltun
    --  Date: November 3, 2021
    
    --[[
    $module Fluid Mixins
    
    The Fluid Mixins library does the following:
    - Modifies Finale objects to allow methods to be overridden and new methods or properties to be added. In other words, the modified Finale objects function more like regular Lua tables.
    - Mixins can be used to address bugs, to introduce time-savers, or to provide custom functionality.
    - Introduces a new namespace for accessing the mixin-enabled Finale objects.
    - Also introduces two types of formally defined mixin: `FCM` and `FCX` classes
    - As an added convenience, all methods that return zero values have a fluid interface enabled (aka method chaining)
    
    
    ## finalemix Namespace
    To utilise the new namespace, simply include the library, which also gives access to he helper functions:
    ```lua
    local finalemix = require("library.mixin")
    ```
    
    All defined mixins can be accessed through the `finalemix` namespace in the same way as the `finale` namespace. All constructors have the same signature as their `FC` originals.
    
    ```lua
    local fcstr = finale.FCString()
    
    -- Base mixin-enabled FCString object
    local fcmstr = finalemix.FCMString()
    
    -- Customised mixin that extends FCMString
    local fcxstr = finalemix.FCXString()
    
    -- Customised mixin that extends FCXString. Still has the same constructor signature as FCString
    local fcxcstr = finalemix.FCXMyCustomString()
    ```
    For more information about naming conventions and the different types of mixins, see the 'FCM Mixins' and 'FCX Mixins' sections.
    
    
    Static copies of `FCM` and `FCX` methods and properties can also be accessed through the namespace like so:
    ```lua
    local func = finalemix.FCXMyMixin.MyMethod
    ```
    Note that static access includes inherited methods and properties.
    
    
    ## Rules of the Game
    - New methods can be added or existing methods can be overridden.
    - New properties can be added but existing properties retain their original behaviour (ie if they are writable or read-only, and what types they can be)
    - The original method can always be accessed by appending a trailing underscore to the method name
    - In keeping with the above, method and property names cannot end in an underscore. Setting a method or property ending with an underscore will result in an error.
    - Returned `FC` objects from all mixin methods are automatically upgraded to a mixin-enabled `FCM` object.
    - All methods that return no values (returning `nil` counts as returning a value) will instead return `self`, enabling a fluid interface
    
    There are also some additional global mixin properties and methods that have special meaning:
    | Name | Description | FCM Accessible | FCM Definable | FCX Accessible | FCX Definable |
    | :--- | :---------- | :------------- | :------------ | :------------- | :------------ |
    | string `MixinClass` | The class name (FCM or FCX) of the mixin. | Yes | No | Yes | No |
    | string|nil `MixinParent` | The name of the mixin parent | Yes | No | Yes | Yes (required) |
    | string|nil `MixinBase` | The class name of the FCM base of an FCX class | No | No | Yes | No |
    | function `Init(self`) | An initialising function. This is not a constructor as it will be called after the object has been constructed. | Yes | Yes (optional) | Yes | Yes (optional) |
    
    
    ## FCM Mixins
    
    `FCM` classes are the base mixin-enabled Finale objects. These are modified Finale classes which, by default (that is, without any additional modifications), retain full backward compatibility with their original counterparts.
    
    The name of an `FCM` class corresponds to its underlying 'FC' class, with the addition of an 'M' after the 'FC'.
    For example, the following will create a mixin-enabled `FCCustomLuaWindow` object:
    ```lua
    local finalemix = require("library.mixin")
    
    local dialog = finalemix.FCMCustomLuaWindow()
    ```
    
    In addition to creating a mixin-enabled finale object, `FCM` objects also automatically load any `FCM` mixins that apply to the class or its parents. These may contain additional methods or overrides for existing methods (eg allowing a method that expects an `FCString` object to accept a regular Lua string as an alternative). The usual principles of inheritance apply (children override parents, etc).
    
    To see if any additional methods are available, or which methods have been modified, look for a file named after the class (eg `FCMCtrlStatic.lua`) in the `mixin` directory. Also check for parent classes, as `FCM` mixins are inherited and can be set at any level in the class hierarchy.
    
    
    ## Defining an FCM Mixin
    The following is an example of how to define an `FCM` mixin for `FCMControl`.
    `src/mixin/FCMControl.lua`
    ```lua
    -- Include the mixin namespace and helper functions
    local library = require("library.general_library")
    local finalemix = require("library.mixin")
    
    local props = {
    
        -- An optional initialising method
        Init = function(self)
            print("Initialising...")
        end,
    
        -- This method is an override for the SetText method 
        -- It allows the method to accept a regular Lua string, which means that plugin authors don't need to worry anout creating an FCString objectq
        SetText = function(self, str)
            finalemix.assert_argument(str, {"string", "number", "FCString"}, 2)
    
            -- Check if the argument is a finale object. If not, turn it into an FCString
            if not library.is_finale_object(str)
                local tmp = str
    
                -- Use a mixin object so that we can take advantage of the fluid interface
                str = finalemix.FCMString():SetLuaString(tostring(str))
            end
    
            -- Use a trailing underscore to reference the original method from FCControl
            self:SetText_(str)
    
            -- By maintaining the original method's behaviour and not returning anything, the fluid interface can be applied.
        end
    }
    
    return props
    ```
    Since the underlying class `FCControl` has a number of child classes, the `FCMControl` mixin will also be inherited by all child classes, unless overridden.
    
    
    An example of utilizing the above mixin:
    ```lua
    local finalemix = require("library.mixin")
    
    local dialog = finalemix.FCMCustomLuaWindow()
    
    -- Fluid interface means that self is returned from SetText instead of nothing
    local label = dialog:CreateStatic(10, 10):SetText("Hello World")
    
    dialog:ExecuteModal(nil)
    ```
    
    
    
    ## FCX Mixins
    `FCX` mixins are extensions of `FCM` mixins. They are intended for defining extended functionality with no requirement for backwards compatability with the underlying `FC` object.
    
    While `FCM` class names are directly tied to their underlying `FC` object, their is no such requirement for an `FCX` mixin. As long as it the class name is prefixed with `FCX` and is immediately followed with another uppercase letter, they can be named anything. If an `FCX` mixin is not defined, the namespace will return `nil`.
    
    When constructing an `FCX` mixin (eg `local dialog = finalemix.FCXMyDialog()`, the library first creates the underlying `FCM` object and then adds each parent (if any) `FCX` mixin until arriving at the requested class.
    
    
    Here is an example `FCX` mixin definition:
    
    `src/mixin/FCXMyStaticCounter.lua`
    ```lua
    -- Include the mixin namespace and helper functions
    local finalemix = require("library.mixin")
    
    -- Since mixins can't have private properties, we can store them in a table
    local private = {}
    setmetatable(private, {__mode = "k"}) -- Use weak keys so that properties are automatically garbage collected along with the objects they are tied to
    
    local props = {
    
        -- All FCX mixins must declare their parent. It can be an FCM class or another FCX class
        MixinParent = "FCMCtrlStatic",
    
        -- Initialiser
        Init = function(self)
            -- Set up private storage for the counter value
            if not private[self] then
                private[self] = 0
                finalemix.FCMControl.SetText(self, tostring(private[self]))
            end
        end,
    
        -- This custom control doesn't allow manual setting of text, so we override it with an empty function
        SetText = function()
        end,
    
        -- Incrementing counter method
        Increment = function(self)
            private[self] = private[self] + 1
    
            -- We need the SetText method, but we've already overridden it! Fortunately we can take a static copy from the finalemix namespace
            finalemix.FCMControl.SetText(self, tostring(private[self]))
        end
    }
    
    return props
    ```
    
    `src/mixin/FCXMyCustomDialog.lua`
    ```lua
    -- Include the mixin namespace and helper functions
    local finalemix = require("library.mixin")
    
    local props = {
        MixinParent = "FCMCustomLuaWindow",
    
        CreateStaticCounter = function(self, x, y)
            -- Create an FCMCtrlStatic and then use the subclass function to apply the FCX mixin
            return finalemix.subclass(self:CreateStatic(x, y), "FCXMyStaticCounter")
        end
    }
    
    return props
    ```
    
    
    Example usage:
    ```lua
    local finalemix = require("library.mixin")
    
    local dialog = finalemix.FCXMyCustomDialog()
    
    local counter = dialog:CreateStaticCounter(10, 10)
    
    counter:Increment():Increment()
    
    -- Counter should display 2
    dialog:ExecuteModal(nil)
    ```
    ]]
    
    local utils = require("library.utils")
    local library = require("library.general_library")
    
    local mixin, mixin_props, mixin_classes = {}, {}, {}
    
    -- Weak table for mixin properties / methods
    setmetatable(mixin_props, {__mode = "k"})
    
    -- Reserved properties (cannot be set on an object)
    -- 0 = cannot be set in the mixin definition
    -- 1 = can be set in the mixin definition
    local reserved_props = {
        IsMixinReady = 0,
        MixinClass = 0,
        MixinParent = 1,
        MixinBase = 0,
        Init = 1,
    }
    
    
    local function is_fcm_class_name(class_name)
        return type(class_name) == "string" and (class_name:match("^FCM%u") or class_name:match("^__FCM%u")) and true or false
    end
    
    local function is_fcx_class_name(class_name)
        return type(class_name) == "string" and class_name:match("^FCX%u") and true or false
    end
    
    local function fcm_to_fc_class_name(class_name)
        return string.gsub(class_name, "FCM", "FC", 1)
    end
    
    local function fc_to_fcm_class_name(class_name)
        return string.gsub(class_name, "FC", "FCM", 1)
    end
    
    -- Gets the real class name of a Finale object
    -- Some classes have incorrect class names, so this function attempts to resolve them with ducktyping
    -- Does not check if the object is a Finale object
    local function get_class_name(object)
        -- If we're dealing with mixin objects, methods may have been added, so we need the originals
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
    
    -- Returns the name of the parent class
    -- This function should only be called for classnames that start with "FC" or "__FC"
    local function get_parent_class(classname)
        local class = finale[classname]
        if type(class) ~= "table" then return nil end
        if not finenv.IsRGPLua then -- old jw lua
            classt = class.__class
            if classt and classname ~= "__FCBase" then
                classtp = classt.__parent -- this line crashes Finale (in jw lua 0.54) if "__parent" doesn't exist, so we excluded "__FCBase" above, the only class without a parent
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
                return tostring(k)  -- in RGP Lua the v is just a dummy value, and the key is the classname of the parent
            end
        end
        return nil
    end
    
    local function try_load_module(name)
        local success, result = pcall(function(c) return require(c) end, name)
    
        -- If the reason it failed to load was anything other than module not found, display the error
        if not success and not result:match("module '[^']-' not found") then
            error(result, 0)
        end
    
        return success, result
    end
    
    function mixin.load_mixin_class(class_name)
        if mixin_classes[class_name] then return end
    
        local is_fcm = is_fcm_class_name(class_name)
        local is_fcx = is_fcx_class_name(class_name)
    
        local success, result = try_load_module("mixin." .. class_name)
    
        if not success then
            success, result = try_load_module("personal_mixin." .. class_name)
        end
    
        if not success then
            -- FCM classes are optional, so if it's valid and not found, start with a blank slate
            if is_fcm and finale[fcm_to_fc_class_name(class_name)] then
                result = {}
            else
                return
            end
        end
    
        -- Mixins must be a table
        if type(result) ~= "table" then
            error("Mixin '" .. class_name .. "' is not a table.", 0)
        end
    
        local class = {props = result}
    
        -- Check for trailing underscores
        for k, _ in pairs(class.props) do
            if type(k) == "string" and k:sub(-1) == "_" then
                error("Mixin methods and properties cannot end in an underscore (" .. class_name .. "." .. k .. ")", 0)
            end
        end
    
        -- Check for reserved properties
        for k, v in pairs(reserved_props) do
            if v == 0 and type(class.props[k]) ~= "nil" then
                error("Mixin '" .. class_name .. "' contains reserved property '" .. k .. "'", 0)
            end
        end
    
        -- Ensure that Init is a function
        if class.props.Init and type(class.props.Init) ~= "function" then
            error("Mixin '" .. class_name .. "' method 'Init' must be a function.", 0)
        end
    
        -- FCM specific
        if is_fcm then
            class.props.MixinParent = get_parent_class(fcm_to_fc_class_name(class_name))
    
            if class.props.MixinParent then
                class.props.MixinParent = fc_to_fcm_class_name(class.props.MixinParent)
    
                mixin.load_mixin_class(class.props.MixinParent)
    
                -- Collect init functions
                class.init = mixin_classes[class.props.MixinParent].init and utils.copy_table(mixin_classes[class.props.MixinParent].init) or {}
    
                if class.props.Init then
                    table.insert(class.init, class.props.Init)
                end
    
                -- Collect parent methods/properties if not overridden
                -- This prevents having to traverse the whole tree every time a method or property is accessed
                for k, v in pairs(mixin_classes[class.props.MixinParent].props) do
                    if type(class.props[k]) == "nil" then
                        class.props[k] = utils.copy_table(v)
                    end
                end
            end
    
        -- FCX specific
        else
            -- FCX classes must specify a parent
            if not class.props.MixinParent then
                error("Mixin '" .. class_name .. "' does not have a 'MixinParent' property defined.", 0)
            end
    
            mixin.load_mixin_class(class.props.MixinParent)
    
            -- Check if FCX parent is missing
            if not mixin_classes[class.props.MixinParent] then
                error("Unable to load mixin '" .. class.props.MixinParent .. "' as parent of '" .. class_name .. "'", 0)
            end
    
            -- Get the base FCM class (all FCX classes must eventually arrive at an FCM parent)
            class.props.MixinBase = is_fcm_class_name(class.props.MixinParent) and class.props.MixinParent or mixin_classes[class.props.MixinParent].props.MixinBase
        end
    
        -- Add class info to properties
        class.props.MixinClass = class_name
    
        mixin_classes[class_name] = class
    end
    
    -- Catches an error and throws it at the specified level (relative to where this function was called)
    -- First argument is called tryfunczzz for uniqueness
    local pcall_line = debug.getinfo(1, "l").currentline + 2 -- This MUST refer to the pcall 2 lines below
    local function catch_and_rethrow(tryfunczzz, levels, ...)
        return mixin.pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))
    end
    
    function mixin.pcall_wrapper(levels, success, result, ...)
        if not success then
            file, line, msg = result:match("([a-zA-Z]-:?[^:]+):([0-9]+): (.+)")
            msg = msg or result
    
            -- Conditions for rethrowing at a higher level:
            -- Ignore errors thrown with no level info (ie. level = 0), as we can't make any assumptions
            -- Both the file and line number indicate that it was thrown at this level
            if file and line and file:sub(-9) == "mixin.lua" and tonumber(line) == pcall_line then
                local d = debug.getinfo(levels, "n")
    
                -- Replace the method name with the correct one, for bad argument errors etc
                msg = msg:gsub("'tryfunczzz'", "'" .. (d.name or "") .. "'")
    
                -- Shift argument numbers down by one for colon function calls
                if d.namewhat == "method" then
                    local arg = msg:match("^bad argument #(%d+)")
    
                    if arg then
                        msg = msg:gsub("#" .. arg, "#" .. tostring(tonumber(arg) - 1), 1)
                    end
                end
    
                error(msg, levels + 1)
    
            -- Otherwise, it's either an internal function error or we couldn't be certain that it isn't
            -- So, rethrow with original file and line number to be 'safe'
            else
                error(result, 0)
            end
        end
    
        return ...
    end
    
    local function proxy(t, ...)
        local n = select("#", ...)
        -- If no return values, then apply the fluid interface
        if n == 0 then
            return t
        end
    
        -- Apply mixin foundation to all returned finale objects
        for i = 1, n do
            mixin.enable_mixin(select(i, ...))
        end
        return ...
    end
    
    -- Returns a function that handles the fluid interface
    function mixin.create_fluid_proxy(func, func_name)
        return function(t, ...)
            return proxy(t, catch_and_rethrow(func, 2, t, ...))
        end
    end
    
    -- Takes an FC object and enables the mixin
    function mixin.enable_mixin(object, fcm_class_name)
        if not library.is_finale_object(object) or mixin_props[object] then return object end
    
        mixin.apply_mixin_foundation(object)
        fcm_class_name = fcm_class_name or fc_to_fcm_class_name(get_class_name(object))
        mixin_props[object] = {}
    
        mixin.load_mixin_class(fcm_class_name)
    
        if mixin_classes[fcm_class_name].init then
            for _, v in pairs(mixin_classes[fcm_class_name].init) do
                v(object)
            end
        end
    
        return object
    end
    
    -- Modifies an FC class to allow adding mixins to any instance of that class.
    -- Needs an instance in order to gain access to the metatable
    function mixin.apply_mixin_foundation(object)
        if not object or not library.is_finale_object(object) or object.IsMixinReady then return end
    
        -- Metatables are shared across all instances, so this only needs to be done once per class
        local meta = getmetatable(object)
    
        -- We need to retain a reference to the originals for later
        local original_index = meta.__index 
        local original_newindex = meta.__newindex
    
        local fcm_class_name = fc_to_fcm_class_name(get_class_name(object))
    
        meta.__index = function(t, k)
            -- Return a flag that this class has been modified
            -- Adding a property to the metatable would be preferable, but that would entail going down the rabbit hole of modifying metatables of metatables
            if k == "IsMixinReady" then return true end
    
            -- If the object doesn't have an associated mixin (ie from finale namespace), let's pretend that nothing has changed and return early
            if not mixin_props[t] then return original_index(t, k) end
    
            local prop
    
            -- If there's a trailing underscore in the key, then return the original property, whether it exists or not
            if type(k) == "string" and k:sub(-1) == "_" then
                -- Strip trailing underscore
                prop = original_index(t, k:sub(1, -2))
    
            -- Check if it's a custom or FCX property/method
            elseif type(mixin_props[t][k]) ~= "nil" then
                prop = mixin_props[t][k]
            
            -- Check if it's an FCM property/method
            elseif type(mixin_classes[fcm_class_name].props[k]) ~= "nil" then
                prop = mixin_classes[fcm_class_name].props[k]
    
                -- If it's a table, copy it to allow instance-level editing
                if type(prop) == "table" then
                    mixin_props[t][k] = utils.copy_table(prop)
                    prop = mixin[t][k]
                end
    
            -- Otherwise, use the underlying object
            else
                prop = original_index(t, k)
            end
    
            if type(prop) == "function" then
                return mixin.create_fluid_proxy(prop, k)
            else
                return prop
            end
        end
    
        -- This will cause certain things (eg misspelling a property) to fail silently as the misspelled property will be stored on the mixin instead of triggering an error
        -- Using methods instead of properties will avoid this
        meta.__newindex = function(t, k, v)
            -- Return early if this is not mixin-enabled
            if not mixin_props[t] then return catch_and_rethrow(original_newindex, 2, t, k, v) end
    
            -- Trailing underscores are reserved for accessing original methods
            if type(k) == "string" and k:sub(-1) == "_" then
                error("Mixin methods and properties cannot end in an underscore.", 2)
            end
    
            -- Setting a reserved property is not allowed
            if reserved_props[k] then
                error("Cannot set reserved property '" .. k .. "'", 2)
            end
    
            local type_v_original = type(original_index(t, k))
    
            -- If it's a method, or a property that doesn't exist on the original object, store it
            if type_v_original == "nil" then
                local type_v_mixin = type(mixin_props[t][k])
                local type_v = type(v)
    
                -- Technically, a property could still be erased by setting it to nil and then replacing it with a method afterwards
                -- But handling that case would mean either storing a list of all properties ever created, or preventing properties from being set to nil.
                if type_v_mixin ~= "nil" then
                    if type_v == "function" and type_v_mixin ~= "function" then
                        error("A mixin method cannot be overridden with a property.", 2)
                    elseif type_v_mixin == "function" and type_v ~= "function" then
                        error("A mixin property cannot be overridden with a method.", 2)
                    end
                end
    
                mixin_props[t][k] = v
    
            -- If it's a method, we can override it but only with another method
            elseif type_v_original == "function" then
                if type(v) ~= "function" then
                    error("A mixin method cannot be overridden with a property.", 2)
                end
    
                mixin_props[t][k] = v
    
            -- Otherwise, try and store it on the original property. If it's read-only, it will fail and we show the error
            else
                catch_and_rethrow(original_newindex, 2, t, k, v)
            end
        end
    end
    
    --[[
    % subclass
    
    Takes a mixin-enabled finale object and migrates it to an `FCX` subclass. Any conflicting property or method names will be overwritten.
    
    If the object is not mixin-enabled or the current `MixinClass` is not a parent of `class_name`, then an error will be thrown.
    If the current `MixinClass` is the same as `class_name`, this function will do nothing.
    
    @ object (__FCMBase)
    @ class_name (string) FCX class name.
    : (__FCMBase|nil) The object that was passed with mixin applied.
    ]]
    function mixin.subclass(object, class_name)
        if not library.is_finale_object(object) then
            error("Object is not a finale object.", 2)
        end
    
        if not catch_and_rethrow(mixin.subclass_helper, 2, object, class_name) then
            error(class_name .. " is not a subclass of " .. object.MixinClass, 2)
        end
    
        return object
    end
    
    -- Returns true on success, false if class_name is not a subclass of the object, and throws errors for everything else
    -- Returns false because we only want the originally requested class name for the error message, which is then handled by mixin.subclass
    function mixin.subclass_helper(object, class_name, suppress_errors)
        if not object.MixinClass then
            if suppress_errors then
                return false
            end
    
            error("Object is not mixin-enabled.", 2)
        end
    
        if not is_fcx_class_name(class_name) then
            if suppress_errors then
                return false
            end
    
            error("Mixins can only be subclassed with an FCX class.", 2)
        end
    
        if object.MixinClass == class_name then return true end
    
        mixin.load_mixin_class(class_name)
    
        if not mixin_classes[class_name] then
            if suppress_errors then
                return false
            end
    
            error("Mixin '" .. class_name .. "' not found.", 2)
        end
    
        -- If we've reached the top of the FCX inheritance tree and the class names don't match, then class_name is not a subclass
        if is_fcm_class_name(mixin_classes[class_name].props.MixinParent) and mixin_classes[class_name].props.MixinParent ~= object.MixinClass then
            return false
        end
    
        -- If loading the parent of class_name fails, then it's not a subclass of the object
        if mixin_classes[class_name].props.MixinParent ~= object.MixinClass then
            if not catch_and_rethrow(mixin.subclass_helper, 2, object, mixin_classes[class_name].props.MixinParent) then
                return false
            end
        end
    
        -- Copy the methods and properties over
        local props = mixin_props[object]
        for k, v in pairs(mixin_classes[class_name].props) do
            props[k] = utils.copy_table(v)
        end
    
        -- Run initialiser, if there is one
        if mixin_classes[class_name].props.Init then
            catch_and_rethrow(object.Init, 2, object)
        end
    
        return true
    end
    
    -- Silently returns nil on failure
    function mixin.create_fcm(class_name, ...)
        mixin.load_mixin_class(class_name)
        if not mixin_classes[class_name] then return nil end
    
        return mixin.enable_mixin(catch_and_rethrow(finale[fcm_to_fc_class_name(class_name)], 2, ...))
    end
    
    -- Silently returns nil on failure
    function mixin.create_fcx(class_name, ...)
        mixin.load_mixin_class(class_name)
        if not mixin_classes[class_name] then return nil end
    
        local object = mixin.create_fcm(mixin_classes[class_name].props.MixinBase, ...)
    
        if not object then return nil end
    
        if not catch_and_rethrow(mixin.subclass_helper, 2, object, class_name, false) then
            return nil
        end
    
        return object
    end
    
    
    local mixin_public = {subclass = mixin.subclass}
    
    --[[
    % is_instance_of
    
    Checks if an object is an instance of a class.
    Conditions:
    - Parent cannot be instance of child.
    - `FC` object cannot be an instance of an `FCM` or `FCX` class
    - `FCM` object cannot be an instance of an `FCX` class
    - `FCX` object cannot be an instance of an `FC` class
    
    @ object (__FCBase) Any finale object, including mixin enabled objects.
    @ class_name (string) An `FC`, `FCM`, or `FCX` class name. Can be the name of a parent class.
    : (boolean)
    ]]
    function mixin_public.is_instance_of(object, class_name)
        if not library.is_finale_object(object) then
            return false
        end
    
        -- 0 = FC
        -- 1 = FCM
        -- 2 = FCX
        local object_type = (is_fcx_class_name(object.MixinClass) and 2) or (is_fcm_class_name(object.MixinClass) and 1) or 0
        local class_type = (is_fcx_class_name(class_name) and 2) or (is_fcm_class_name(class_name) and 1) or 0
    
        -- See doc block for explanation of conditions
        if (object_type == 0 and class_type == 1) or (object_type == 0 and class_type == 2) or (object_type == 1 and class_type == 2) or (object_type == 2 and class_type == 0) then
            return false
        end
    
        local parent = object_type == 0 and get_class_name(object) or object.MixinClass
    
        -- Traverse FCX hierarchy until we get to an FCM base
        if object_type == 2 then
            repeat
                if parent == class_name then
                    return true
                end
    
                -- We can assume that since we have an object, all parent classes have been loaded
                parent = mixin_classes[parent].props.MixinParent
            until is_fcm_class_name(parent)
        end
    
        -- Since FCM classes follow the same hierarchy as FC classes, convert to FC
        if object_type > 0 then
            parent = fcm_to_fc_class_name(parent)
        end
    
        if class_type > 0 then
            class_name = fcm_to_fc_class_name(class_name)
        end
    
        -- Traverse FC hierarchy
        repeat
            if parent == class_name then
                return true
            end
    
            parent = get_parent_class(parent)
        until not parent
    
        -- Nothing found
        return false
    end
    
    --[[
    % assert_argument
    
    Asserts that an argument to a mixin method is the expected type(s). This should only be used within mixin methods as the function name will be inserted automatically.
    
    NOTE: For performance reasons, this function will only assert if in debug mode (ie `finenv.DebugEnabled == true`). If assertions are always required, use `force_assert_argument` instead.
    
    If not a valid type, will throw a bad argument error at the level above where this function is called.
    Types can be Lua types (eg `string`, `number`, `bool`, etc), finale class (eg `FCString`, `FCMeasure`, etc), or mixin class (eg `FCMString`, `FCMMeasure`, etc)
    Parent classes cannot be specified as this function does not examine the class hierarchy.
    
    Note that mixin classes may satisfy the condition for the underlying `FC` class.
    For example, if the expected type is `FCString`, an `FCMString` object will pass the test, but an `FCXString` object will not.
    If the expected type is `FCMString`, an `FCXString` object will pass the test but an `FCString` object will not.
    
    @ value (mixed) The value to test.
    @ expected_type (string|table) If there are multiple valid types, pass a table of strings.
    @ argument_number (number) The REAL argument number for the error message (self counts as #1).
    ]]
    function mixin_public.assert_argument(value, expected_type, argument_number)
        local t, tt
    
        if library.is_finale_object(value) then
            t = value.MixinClass
            tt = is_fcx_class_name(t) and value.MixinBase or get_class_name(value)
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
    
    --[[
    % force_assert_argument
    
    The same as `assert_argument` except this function always asserts, regardless of whether debug mode is enabled.
    
    @ value (mixed) The value to test.
    @ expected_type (string|table) If there are multiple valid types, pass a table of strings.
    @ argument_number (number) The REAL argument number for the error message (self counts as #1).
    ]]
    mixin_public.force_assert_argument = mixin_public.assert_argument
    
    --[[
    % assert
    
    Asserts a condition in a mixin method. If the condition is false, an error is thrown one level above where this function is called.
    Only asserts when in debug mode. If assertion is required on all executions, use `force_assert` instead
    
    @ condition (any) Can be any value or expression.
    @ message (string) The error message.
    @ [no_level] (boolean) If true, error will be thrown with no level (ie level 0)
    ]]
    function mixin_public.assert(condition, message, no_level)
        if not condition then
            error(message, no_level and 0 or 3)
        end
    end
    
    --[[
    % force_assert
    
    The same as `assert` except this function always asserts, regardless of whether debug mode is enabled.
    
    @ condition (any) Can be any value or expression.
    @ message (string) The error message.
    @ [no_level] (boolean) If true, error will be thrown with no level (ie level 0)
    ]]
    mixin_public.force_assert = mixin_public.assert
    
    
    -- Replace assert functions with dummy function when not in debug mode
    if finenv.IsRGPLua and not finenv.DebugEnabled then
        mixin_public.assert_argument = function() end
        mixin_public.assert = mixin_public.assert_argument
    end
    
    --[[
    % UI
    
    Returns a mixin enabled UI object from `finenv.UI`
    
    : (FCMUI)
    ]]
    function mixin_public.UI()
        return mixin.enable_mixin(finenv.UI(), "FCMUI")
    end
    
    -- Create a new namespace for mixins
    return setmetatable({}, {
        __newindex = function(t, k, v) end,
        __index = function(t, k)
            if mixin_public[k] then return mixin_public[k] end
    
            mixin.load_mixin_class(k)
            if not mixin_classes[k] then return nil end
    
            -- Cache the class tables
            mixin_public[k] = setmetatable({}, {
                __newindex = function(tt, kk, vv) end,
                __index = function(tt, kk)
                    local val = utils.copy_table(mixin_classes[k].props[kk])
                    if type(val) == "function" then
                        val = mixin.create_fluid_proxy(val, kk)
                    end
                    return val
                end,
                __call = function(_, ...)
                    if is_fcm_class_name(k) then
                        return mixin.create_fcm(k, ...)
                    else
                        return mixin.create_fcx(k, ...)
                    end
                end
            })
    
            return mixin_public[k]
        end
    })

end

function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true -- not recognized by JW Lua or RGP Lua v0.55
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "January 20, 2022"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.Notes = [[
        This script allows you to specify a number of chromatic steps by which to transpose and the script
        simplifies the spelling. Chromatic steps are half-steps in a standard 12-tone scale, but they are smaller
        if you are using a microtone sytem defined in a custom key signature.

        Normally the script opens a modeless window. However, if you invoke the plugin with a shift, option, or
        alt key pressed, it skips opening a window and uses the last settings you entered into the window.
        (This works with RGP Lua version 0.60 and higher.)
        
        If you are using custom key signatures with JW Lua or an early version of RGP Lua, you must create
        a custom_key_sig.config.txt file in a folder called `script_settings` within the same folder as the script.
        It should contains the following two lines that define the custom key signature you are using. Unfortunately,
        the JW Lua and early versions of RGP Lua do not allow scripts to read this information from the Finale document.
        
        (This example is for 31-EDO.)
        
        ```
        number_of_steps = 31
        diatonic_steps = {0, 5, 10, 13, 18, 23, 28}
        ```
        
        Later versions of RGP Lua (0.58 or higher) ignore this configuration file (if it exists) and read the correct
        information from the Finale document.
    ]]
    return "Transpose By Steps...", "Transpose By Steps", "Transpose by the number of steps given, simplifying spelling as needed."
end

if not finenv.IsRGPLua then
    local path = finale.FCString()
    path:SetRunningLuaFolderPath()
    package.path = package.path .. ";" .. path.LuaString .. "?.lua"
end

local transposition = require("library.transposition")
local mixin = require("library.mixin")

function do_transpose_by_step(global_number_of_steps_edit)
    if finenv.Region():IsEmpty() then
        return
    end
    local undostr = "Transpose By Steps " .. tostring(finenv.Region().StartMeasure)
    if finenv.Region().StartMeasure ~= finenv.Region().EndMeasure then
        undostr = undostr .. " - " .. tostring(finenv.Region().EndMeasure)
    end
    local success = true
    finenv.StartNewUndoBlock(undostr, false) -- this works on both JW Lua and RGP Lua
    for entry in eachentrysaved(finenv.Region()) do
        for note in each(entry) do
            if not transposition.stepwise_transpose(note, global_number_of_steps_edit) then
                success = false
            end
        end
    end
    if finenv.EndUndoBlock then -- EndUndoBlock only exists on RGP Lua 0.56 and higher
        finenv.EndUndoBlock(true)
        finenv.Region():Redraw()
    else
        finenv.StartNewUndoBlock(undostr, true) -- JW Lua automatically terminates the final undo block we start here
    end
    if not success then
        finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.", "Transposition Error")
    end
    return success
end

function create_dialog_box()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Transpose By Steps")
    local current_y = 0
    local x_increment = 105
    -- number of steps
    dialog:CreateStatic(0, current_y + 2):SetText("Number Of Steps:")
    local edit_x = x_increment + (finenv.UI():IsOnMac() and 4 or 0)
    dialog:CreateEdit(edit_x, current_y, "num_steps"):SetText("")
    -- ok/cancel
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(function(self)
            do_transpose_by_step(self:GetControl("num_steps"):GetInteger())
        end
    )
    return dialog
end

function transpose_by_step()
    global_dialog = global_dialog or create_dialog_box()
    global_dialog:RunModeless()
end

transpose_by_step()

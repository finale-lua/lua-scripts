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

            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end
    return client
end

__imports["library.configuration"] = function()



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







    local transposition = {}
    local client = require("library.client")
    local configuration = require("library.configuration")
    local standard_key_number_of_steps = 12
    local standard_key_major_diatonic_steps = {0, 2, 4, 5, 7, 9, 11}
    local standard_key_minor_diatonic_steps = {0, 2, 3, 5, 7, 8, 10}
    local max_allowed_abs_alteration = 7


    local diatonic_interval_adjustments = {{0, 0}, {2, -1}, {4, -2}, {-1, 1}, {1, 0}, {3, -1}, {5, -2}, {0, 1}}
    local custom_key_sig_config = {number_of_steps = standard_key_number_of_steps, diatonic_steps = standard_key_major_diatonic_steps}
    configuration.get_parameters("custom_key_sig.config.txt", custom_key_sig_config)



    local sign = function(n)
        if n < 0 then
            return -1
        end
        return 1
    end


    local signed_modulus = function(n, d)
        return sign(n) * (math.abs(n) % d)
    end
    local get_key = function(note)
        local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
        return cell:GetKeySignature()
    end



    local get_key_info = function(key)
        local number_of_steps = standard_key_number_of_steps
        local diatonic_steps = standard_key_major_diatonic_steps
        if client.supports("FCKeySignature::CalcTotalChromaticSteps") then
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
        local number_of_steps = sign(second_disp - first_disp) * (diatonic_steps[second_scale_degree + 1] - diatonic_steps[first_scale_degree + 1])
        if number_of_steps < 0 then
            number_of_steps = number_of_steps + number_of_steps_in_key
        end
        return number_of_steps
    end
    local calc_steps_in_alteration = function(key, interval, alteration)
        local number_of_steps_in_key, _, fifth_steps = get_key_info(key)
        local plus_fifths = sign(interval) * alteration * 7
        local minus_octaves = sign(interval) * alteration * -4
        local new_alteration = sign(interval) * ((plus_fifths * fifth_steps) + (minus_octaves * number_of_steps_in_key))
        return new_alteration
    end
    local calc_steps_in_normalized_interval = function(key, interval_normalized)
        local number_of_steps_in_key, _, fifth_steps = get_key_info(key)
        local plus_fifths = diatonic_interval_adjustments[math.abs(interval_normalized) + 1][1]
        local minus_octaves = diatonic_interval_adjustments[math.abs(interval_normalized) + 1][2]
        local number_of_steps_in_interval = sign(interval_normalized) * ((plus_fifths * fifth_steps) + (minus_octaves * number_of_steps_in_key))
        return number_of_steps_in_interval
    end
    local simplify_spelling = function(note, min_abs_alteration)
        while math.abs(note.RaiseLower) > min_abs_alteration do
            local curr_sign = sign(note.RaiseLower)
            local curr_abs_disp = math.abs(note.RaiseLower)
            local direction = curr_sign
            local success = transposition.enharmonic_transpose(note, direction, true)
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




    function transposition.diatonic_transpose(note, interval)
        note.Displacement = note.Displacement + interval
    end

    function transposition.change_octave(note, number_of_octaves)
        transposition.diatonic_transpose(note, 7 * number_of_octaves)
    end




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
        local key_step_enharmonic = calc_steps_between_scale_degrees(key, note.Displacement, note.Displacement + sign(direction))
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

    function transposition.chromatic_transpose(note, interval, alteration, simplify)
        simplify = simplify or false
        local curr_disp = note.Displacement
        local curr_alt = note.RaiseLower
        local key = get_key(note)
        local number_of_steps, diatonic_steps, fifth_steps = get_key_info(key)
        local interval_normalized = signed_modulus(interval, #diatonic_steps)
        local steps_in_alteration = calc_steps_in_alteration(key, interval, alteration)
        local steps_in_interval = calc_steps_in_normalized_interval(key, interval_normalized)
        local steps_in_diatonic_interval = calc_steps_between_scale_degrees(key, note.Displacement, note.Displacement + interval_normalized)
        local effective_alteration = steps_in_alteration + steps_in_interval - sign(interval) * steps_in_diatonic_interval
        transposition.diatonic_transpose(note, interval)
        note.RaiseLower = note.RaiseLower + effective_alteration
        local min_abs_alteration = max_allowed_abs_alteration
        if simplify then
            min_abs_alteration = 0
        end
        local success = simplify_spelling(note, min_abs_alteration)
        if not success then
            note.Displacement = curr_disp
            note.RaiseLower = curr_alt
        end
        return success
    end

    function transposition.stepwise_transpose(note, number_of_steps)
        local curr_disp = note.Displacement
        local curr_alt = note.RaiseLower
        note.RaiseLower = note.RaiseLower + number_of_steps
        local success = simplify_spelling(note, 0)
        if not success then
            note.Displacement = curr_disp
            note.RaiseLower = curr_alt
        end
        return success
    end

    function transposition.chromatic_major_third_down(note)
        transposition.chromatic_transpose(note, -2, -0)
    end

    function transposition.chromatic_perfect_fourth_up(note)
        transposition.chromatic_transpose(note, 3, 0)
    end

    function transposition.chromatic_perfect_fifth_down(note)
        transposition.chromatic_transpose(note, -4, -0)
    end
    return transposition
end

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "August 22, 2021"
    finaleplugin.CategoryTags = "Accidental"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    return "Simplify accidentals", "Simplify accidentals", "Removes all double sharps and flats by respelling them"
end
local transposition = require("library.transposition")
function accidentals_simplify()
    for entry in eachentrysaved(finenv.Region()) do
        if not entry:IsNote() then
            goto continue_entry_loop
        end
        local measure_number = entry.Measure
        local staff_number = entry.Staff
        local cell = finale.FCCell(measure_number, staff_number)
        local key_signature = cell:GetKeySignature()
        for note in each(entry) do
            if note.RaiseLower == 0 then
                goto continue_note_loop
            end





            local fs_note_string = finale.FCString()
            note:GetString(fs_note_string, key_signature, false, false)
            local note_string = fs_note_string:GetLuaString()

            if string.match(note_string, "bb") or string.match(note_string, "##") then
                transposition.enharmonic_transpose(note, note.RaiseLower)
                transposition.chromatic_transpose(note, 0, 0, true)
            end
            ::continue_note_loop::
        end
        ::continue_entry_loop::
    end
end
accidentals_simplify()

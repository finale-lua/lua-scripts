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
            os.execute('mkdir "' .. folder_path ..'"')
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
package.preload["library.transposition"] = package.preload["library.transposition"] or function()







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

    function transposition.enharmonic_transpose_default(note, ignore_error)
        if note.RaiseLower ~= 0 then
            return transposition.enharmonic_transpose(note, sign(note.RaiseLower), ignore_error)
        end
        local original_displacement = note.Displacement
        local original_raiselower = note.RaiseLower
        if not transposition.enharmonic_transpose(note, 1, ignore_error) then
            return false
        end



        if math.abs(note.RaiseLower) ~= 2 then
            return true
        end
        local up_displacement = note.Displacement
        local up_raiselower = note.RaiseLower
        note.Displacement = original_displacement
        note.RaiseLower = original_raiselower
        if not transposition.enharmonic_transpose(note, -1, ignore_error) then
            return false
        end
        if math.abs(note.RaiseLower) < math.abs(up_raiselower) then
            return true
        end
        note.Displacement = up_displacement
        note.RaiseLower = up_raiselower
        return true
    end




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
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 25, 2021"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.Notes = [[
        In normal 12-note music, enharmonically transposing is the same as transposing by a diminished 2nd.
        However, in some microtone systems (specifically 19-EDO and 31-EDO), enharmonic transposition produces a different result
        than chromatic transposition. As an example, C is equivalent to Dbb in 12-tone systems. But in 31-EDO, C is five microsteps
        lower than D whereas Dbb is four microsteps lower than D. Transposing C up a diminished 2nd gives Dbb in either system, but
        in 31-EDO, Dbb is not the same pitch as C.

        If you are using custom key signatures with JW Lua or an early version of RGP Lua, you must create
        a `custom_key_sig.config.txt` file in a folder called `script_settings` within the same folder as the script.
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
    return "Enharmonic Transpose Up", "Enharmonic Transpose Up",
           "Transpose up enharmonically all notes in selected regions."
end
local transposition = require("library.transposition")
function transpose_enharmonic_up()
    local success = true
    for entry in eachentrysaved(finenv.Region()) do
        for note in each(entry) do
            if not transposition.enharmonic_transpose(note, 1) then
                success = false
            end
        end
    end
    if not success then
        finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.", "Transposition Error")
    end
end
transpose_enharmonic_up()

function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "2.0"
    finaleplugin.Date = "2022-07-06"
    return "Harp Pedal Wizard", "Harp Pedal Wizard", "Creates Harp Diagrams and Pedal Changes"
end

  if finenv.IsRGPLua == false then
    local ui = finenv.FCUI
    ui:AlertInfo("This script requires RGP Lua to function.", NULL)
    local str = finale.FCString()
    str.LuaString = "https://robertgpatterson.com/-fininfo/-rgplua/rgplua.html"
    ui:DisplayWebURL(str)
  end

local library = require("library.general_library")
--local configuration = require("library.configuration")
  
local config_filename = "com.harp_pedal_wizard.text"

-- finalelua library functions - copied from library\configuration.lua
local strip_leading_trailing_whitespace = function (str)
    return str:match("^%s*(.-)%s*$") -- lua pattern magic taken from the Internet
end

local parse_parameter -- forward function declaration


local parse_table = function(val_string)
    local ret_table = {}
    for element in val_string:gmatch('[^,%s]+') do  -- lua pattern magic taken from the Internet
        local parsed_element = parse_parameter(element)
        table.insert(ret_table, parsed_element)
    end
    return ret_table
end

parse_parameter = function(val_string)
    if '"' == val_string:sub(1,1) and '"' == val_string:sub(#val_string,#val_string) then -- double-quote string
        return string.gsub(val_string, '"(.+)"', "%1") -- lua pattern magic: "(.+)" matches all characters between two double-quote marks (no escape chars)
    elseif "'" == val_string:sub(1,1) and "'" == val_string:sub(#val_string,#val_string) then -- single-quote string
        return string.gsub(val_string, "'(.+)'", "%1") -- lua pattern magic: '(.+)' matches all characters between two single-quote marks (no escape chars)
    elseif "{" == val_string:sub(1,1) and "}" == val_string:sub(#val_string,#val_string) then
        return parse_table(string.gsub(val_string, "{(.+)}", "%1"))
    elseif "true" == val_string then
        return true
    elseif "false" == val_string then
        return false
    end
--    return tonumber(val_string)
    return val_string
end

local get_parameters_from_file = function(file_name) -- modified
    local parameters = {}
    for line in io.lines(file_name) do
        local comment_marker = "--"
        local parameter_delimiter = "="
        local comment_at = string.find(line, comment_marker, 1, true) -- true means find raw string rather than lua pattern
        if nil ~= comment_at then
            line = string.sub(line, 1, comment_at-1)
        end
        local delimiter_at = string.find(line, parameter_delimiter, 1, true)
        if nil ~= delimiter_at then
            local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at-1))
            local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at+1))
            parameters[name] = parse_parameter(val_string)
        end
    end
    return parameters
end

-- Modified from library
function get_parameters(file_name, parameter_list)
    local file_parameters = get_parameters_from_file(file_name)
    if nil ~= file_parameters then
        for param_name, def_val in pairs(file_parameters) do
            local param_val = file_parameters[param_name]
            if nil ~= param_val then
                parameter_list[param_name] = param_val
            end
        end
    end
    return parameter_list
end

--------------------------------------
function path_set(filename)
    local path = finale.FCString()
    local path_delimiter = finale.FCString()
    local ui = finenv.UI()
    path:SetUserOptionsPath()
    if ui:IsOnMac() then
        path_delimiter.LuaString = "/"
    elseif ui:IsOnWindows() then
        path_delimiter.LuaString = "\\"
        --path_delimiter.LuaString = "/" -- apparently Windows can use either! Go figure!
    end
    path.LuaString = path.LuaString..path_delimiter.LuaString..filename
    return path
end

function harp_config_load()
    local path = path_set(config_filename)
    local config_settings = {}
    local init_settings = {root = 2, accidental = 1, scale = 0, scale_check = 1, chord = 0, chord_check = 0, diagram_check = 1, names_check = 0, partial_check = 0, stack = 1, pedal_lanes = 1, last_notes = "D, C, B, E, F, G, A"}
    -- This next might not be needed... But doesn't hurt so leaving it in for now...
    local init_count = 0
    for i,k in pairs(init_settings) do
        init_count = init_count + 1
    end
    --
    local file_r = io.open(path.LuaString, "r")

    if file_r == nil then
        config_settings = init_settings
        harp_config_save(config_settings)
        file_r = io.open(path.LuaString, "r")
    end

    config_settings = get_parameters(path.LuaString, config_settings)

    for key, val in pairs(init_settings) do
        if config_settings[key] == nil then
            config_settings[key] = val
        end
    end
    return config_settings
end -- harp_config_load()

function harp_config_save(config_settings)
    local path = path_set(config_filename)
    local file_w = io.open(path.LuaString, "w")
    for key, val in pairs(config_settings) do
        file_w:write(key.." = "..val.."\n")
    end
    file_w:close()
end -- harp_config_save()

function getUsedFontName(standard_name)
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
        return getUsedFontName(fontinfo:GetName())
    end
end

---
function harp()
    finenv.RetainLuaState = true
    local default_music_font = get_def_mus_font() 
    local partial = false
    local changes = false
    local stack = true
    local pedal_lanes = true
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
    local diagram_font = "^fontTxt("..default_music_font..")"
    --
    local flat_char = ""
    local nat_char = ""
    local sharp_char = ""
    local cross_char = ""
    local desc_prefix = finale.FCString()
    desc_prefix.LuaString = ""
    local ui = finenv.UI()

    local config = harp_config_load()

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
            elseif harp_tbl[i]:sub(1,1) == "B" then 
                harpstrings[3] = harp_tbl[i]
            elseif harp_tbl[i]:sub(1,1) == "C" then
                harpstrings[2] = harp_tbl[i]
            elseif harp_tbl[i]:sub(1,1) == "D" then
                harpstrings[1] = harp_tbl[i]
            elseif harp_tbl[i]:sub(1,1) == "E" then
                harpstrings[4] = harp_tbl[i]
            elseif harp_tbl[i]:sub(1,1) == "F" then
                harpstrings[5] = harp_tbl[i]
            elseif harp_tbl[i]:sub(1,1) == "G" then
                harpstrings[6] = harp_tbl[i]
            else
--                error = true
                --goto error1               
            end -- End string assignments
            count = i        
        end -- for i,j
    end

    function changes_update()
        changes_str.LuaString = ""
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
        if changes_temp == false then 
            changes_str.LuaString = ""
        else
            local length = string.len(changes_str.LuaString) - 2
            changes_str.LuaString = string.sub(changes_str.LuaString, 1, length)
        end
        changes_static:SetText(changes_str)
    end

    function harp_diagram(harpnotes, diag, scaleinfo, partial)
        if diag then
            desc_prefix.LuaString = "Hp. Diagram: "
        else
            desc_prefix.LuaString = "Hp. Pedals: "
        end
        if partial == true then scaleinfo = nil end
        local region = finenv.Region()
        local error = false
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
            cross_char = "P"
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
                error = true
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
                    error = true
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
                error = true
                goto error1               
            end -- End string assignments
            count = i        
        end -- for i,j
--
        harpstrings = {D, C, B, E, F, G, A}
        pedals_update()

        if count > 7 then
            error = true
            goto error1
        end

        if partial == true then
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
        changes_update()
        for i = 1, 7, 1 do
            if diag == true then
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
                    diagram_string.LuaString = diagram_string.LuaString..cross_char
                    description.LuaString = description.LuaString.." | "
                elseif i < 7 then
                    description.LuaString = description.LuaString.." "
                end
            elseif diag == false then -- Settings for 'Note names'
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
            end -- if diag...
        end -- i 1 to 7
--
        if diag == false then 
            if (stack == false) then
                if diagram_string.LuaString ~= "" then
                    left_strings.LuaString = left_strings.LuaString.." "
                end
                diagram_string.LuaString = left_strings.LuaString..diagram_string.LuaString
            elseif (stack == true and (config.pedal_lanes == false and diagram_string.LuaString ~= "")) 
            or (stack == true and partial == false)
            or (pedal_lanes and partial) then
                diagram_string.LuaString = diagram_string.LuaString.."\r"..left_strings.LuaString
            elseif (pedal_lanes == false and partial and diagram_string.LuaString == "") then
                diagram_string.LuaString = left_strings.LuaString
            end

            diagram_string.LuaString = string.gsub(diagram_string.LuaString, "n", "^natural()")
            diagram_string.LuaString = string.gsub(diagram_string.LuaString, "b", "^flat()")
            diagram_string.LuaString = string.gsub(diagram_string.LuaString, "#", "^sharp()")
            diagram_string.LuaString = string.gsub(diagram_string.LuaString, " %\13", "\r")
        end
        if scaleinfo ~= nil then description.LuaString = description.LuaString.." ("..scaleinfo..")" end
        print(description.LuaString)
        ::error1::
        if error == true then
            print("There seems to be a problem with your harp diagram.")
            local result = ui:AlertYesNo("There seems to be a problem with your harp diagram. \n Would you like to try again?", NULL)
            if result == 2 then harp_dialog() end
        end -- error
        if (diag_asn == true) then
            ui:AlertInfo("There is already a harp diagram assigned to this region.", NULL)
        end
    end

    function pedals_add(diag, partial)
        local undo_str = ""
        if diag then
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
                if diag == true then
                    print("No Harp Diagrams category found. Using Technique Text,",diagrams)
                else
                    print("No Harp Pedals category found. Using Technique Text,",diagrams)
                end
            elseif string.lower(cat:CreateName().LuaString) == "harp diagrams" and diag == true then
                print("Found Harp Diagrams category")
                diagrams = cat.ID
                diagrams_cat = cat
            elseif string.lower(cat:CreateName().LuaString) == "harp pedals" and diag == false then
                print("Found Harp Pedals category")
                diagrams = cat.ID
                diagrams_cat = cat
            end -- if cat...
        end -- for cat
-----
        -- find an existing diagram 
        --
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
--        local text_font = "^fontTxt"..font:CreateEnigmaString(finale.FCString()).LuaString

            if diag == true then
                local text_font = diagram_font
                ted_text.LuaString = text_font..diagram_string.LuaString
            else 
                ted_text.LuaString = diagram_string.LuaString
            end -- if diag == true
            ex_ted:AssignToCategory(diagrams_cat)
            ex_ted:SetDescription(description)
            ex_ted:SaveNewTextBlock(ted_text)
            if use_tech == true then -- If using the Techniques category, override positioning
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
            finenv.EndUndoBlock(true)
-------
            ::error1::
            if error == true then
                print("There seems to be a problem with your harp diagram.")
                local result = ui:AlertYesNo("There seems to be a problem with your harp diagram. \n Would you like to try again?", NULL)
                if result == 2 then harp_dialog() end
            end -- error
            if diag_asn == true then
                ui:AlertInfo("There is already a harp diagram assigned to this region.", NULL)
            end
        end -- function add_pedals

        -------
        function harp_scale(root, scale, diag, chd, partial)
            print("Harp Scale function called")
            local error = false
            local enharmonic = finale.FCString()
            local scaleinfo = root.." "..scale
            if chd == true then scaleinfo = root..scale end
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
                chd = true
            end -- temporary change for exotic scales!

            if chd == false then
                for i = 1, 2, 1 do --- run through this twice...
                    if last == "A"  and scale_deg <= 7 then
                        local found = false
                        for j = 1, 3, 1 do
                            if B_num[j] == scale_new[scale_deg] then
                                scale_ltrs = scale_ltrs..", "..B_ltr[j]
                                found = true
                            end
                        end -- for j
                        if found == false then
                            error = true
                            goto error
                        end
                        scale_deg = scale_deg + 1
                        last = "B"
                    end
                    if last == "B"  and scale_deg <= 7 then
                        local found = false
                        for j = 1, 3, 1 do
                            if C_num[j] == scale_new[scale_deg] then
                                scale_ltrs = scale_ltrs..", "..C_ltr[j]
                                found = true
                            end
                        end -- for j
                        if found == false then
                            error = true
                            goto error
                        end
                        scale_deg = scale_deg + 1
                        last = "C"
                    end
                    if last == "C" and scale_deg <= 7  then
                        local found = false
                        for j = 1, 3, 1 do
                            if D_num[j] == scale_new[scale_deg] then
                                scale_ltrs = scale_ltrs..", "..D_ltr[j]
                                found = true
                            end
                        end -- for j
                        if found == false then
                            error = true
                            goto error
                        end
                        scale_deg = scale_deg + 1
                        last = "D"
                    end
                    if last == "D"  and scale_deg <= 7 then
                        local found = false
                        for j = 1, 3, 1 do
                            if E_num[j] == scale_new[scale_deg] then
                                scale_ltrs = scale_ltrs..", "..E_ltr[j]
                                found = true
                            end
                        end -- for j
                        if found == false then
                            error = true
                            goto error
                        end
                        scale_deg = scale_deg + 1
                        last = "E"
                    end
                    if last == "E" and scale_deg <= 7 then
                        local found = false
                        for j = 1, 3, 1 do
                            if F_num[j] == scale_new[scale_deg] then
                                scale_ltrs = scale_ltrs..", "..F_ltr[j]
                                found = true
                            end 
                        end -- for j
                        if found == false then
                            error = true
                            goto error
                        end
                        scale_deg = scale_deg + 1
                        last = "F"
                    end
                    if last == "F"  and scale_deg <= 7 then
                        local found = false
                        for j = 1, 3, 1 do
                            if G_num[j] == scale_new[scale_deg] then
                                scale_ltrs = scale_ltrs..", "..G_ltr[j]
                                found = true
                            end
                        end -- for j
                        if found == false then
                            error = true
                            goto error
                        end
                        scale_deg = scale_deg + 1
                        last = "G"
                    end
                    if last == "G"  and scale_deg <= 7 then
                        local found = false
                        for j = 1, 3, 1 do
                            if A_num[j] == scale_new[scale_deg] then
                                scale_ltrs = scale_ltrs..", "..A_ltr[j]
                                found = true
                            end
                        end -- for j
                        if found == false then
                            error = true
                            goto error
                        end
                        scale_deg = scale_deg + 1
                        last = "A"
                    end
                end -- for i...
            elseif chd == true then
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
            end -- if chd...

            if scale == "whole tone" or scale == "major pentatonic" or scale == "minor pentatonic" then
                chd = false
            end -- temporary change for exotic scales!

            harp_diagram(scale_ltrs, diag, scaleinfo, partial)
---
            ::error::
            if error == true then
                print("That scale won't work.")
                local str = finale.FCString()
                str.LuaString = "That scale won't work, sorry. \n Try again using "..enharmonic.LuaString.." "..scale.."?"
                local result = ui:AlertYesNo(str.LuaString, NULL)
                if result == 2 then harp_scale(enharmonic.LuaString, scale, diag, chd) end
            end -- error

        end -- function harp_scale()
-------

        function harp_dialog()

            local path = path_set("com.harp_diagram.txt")
            local str = finale.FCString()
            local diag = true
            local chd = false
            local file_r = io.open(path.LuaString, "r")

            if config.chord_check == 0  or config.chord_check == "0" then chd = false 
            elseif config.chord_check == 1 or config.chord_check == "1" then chd = true end
            if config.diagram_check == 0  or config.diagram_check == "0" then diag = true 
            elseif config.diagram_check == 1 or config.diagram_check == "1"  then diag = false end

            local row_y = 0 -- The various controls will use this to consistently place themselves vertically
--
            function format_ctrl( ctrl, h, w, st)
                ctrl:SetHeight(h)
                ctrl:SetWidth(w)
                str.LuaString = st
                ctrl:SetText(str)
            end -- function format_ctrl
--
            local dialog = finale.FCCustomLuaWindow()
            if nil ~= context.window_pos_x and nil ~= context.window_pos_y then
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

                local roots = {"A", "B", "C", "D", "E", "F", "G"}
                local root_label = dialog:CreateStatic(8,row_y-14)
                format_ctrl(root_label, 15, 30, "Root")
                local sel_root = dialog:CreatePopup(8, row_y)
                format_ctrl(sel_root, 20, 36, "Root")
                for i,j in pairs(roots) do
                    str.LuaString = roots[i]
                    sel_root:AddString(str)
                end
                sel_root:SetSelectedItem(config.root)
                local accidentals = {"b", "♮", "#"} -- unicode symbols... natural at least displays as 'n' on Windows
--      local accidentals = {"♭", "♮", "♯"} -- unicode symbols
                local sel_acc = dialog:CreatePopup(42, row_y)
                format_ctrl(sel_acc, 20, 32, "Accidental")
                for i,j in pairs(accidentals) do
                    str.LuaString = accidentals[i]
                    sel_acc:AddString(str)
                end   
                sel_acc:SetSelectedItem(config.accidental)

                -- Setup Scales
                str.LuaString = ""  
                local scale_check = dialog:CreateCheckbox(86, row_y-14)
                scale_check:SetText(str)
                scale_check:SetCheck(config.scale_check)

                local scale_label = dialog:CreateStatic(100,row_y-14)
                format_ctrl(scale_label, 15, 48, "Scale")
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
                str.LuaString = ""  
                local chord_check = dialog:CreateCheckbox(220, row_y-14)
                chord_check:SetText(str)
                chord_check:SetCheck(config.chord_check)
                local chord_label = dialog:CreateStatic(234, row_y-14)
                format_ctrl(chord_label, 15, 48, "Chord")
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
                format_ctrl(style_label, 20, 40, str.LuaString)
                --
                local diagram_checkbox = dialog:CreateCheckbox(40, row_y)
                str.LuaString = " Diagram"
                diagram_checkbox:SetText(str)
                diagram_checkbox:SetCheck(config.diagram_check) 
                --
                local names_checkbox = dialog:CreateCheckbox(132, row_y)
                str.LuaString = " Note Names"
                names_checkbox:SetText(str)
                names_checkbox:SetCheck(config.names_check)
                --
                local partial_checkbox = dialog:CreateCheckbox(224, row_y)
                str.LuaString = " Partial"
                partial_checkbox:SetText(str)
                partial_checkbox:SetCheck(config.partial_check)
                --
                row_y = row_y + 18
                local stack_checkbox = dialog:CreateCheckbox(132, row_y)
                str.LuaString = " Stack"
                stack_checkbox:SetText(str)
                stack_checkbox:SetCheck(config.stack)    
                --
                local lanes_checkbox = dialog:CreateCheckbox(224, row_y)
                str.LuaString = " Preserve Lanes"
                lanes_checkbox:SetText(str)
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
                local pedals_h_line1 = dialog:CreateHorizontalLine(col_x, nat_y + 6, col_width * 7)
                local pedals_h_line2 = dialog:CreateHorizontalLine(col_x, nat_y + 6, col_width * 7)
                local pedals_h_line3 = dialog:CreateHorizontalLine(col_x, nat_y + 6, col_width * 7)
--                    pedals_h_line:SetHeight(4)
                --
                local d_stg_static = dialog:CreateStatic(col_x + (col * col_width), row_y-1)
                format_ctrl(d_stg_static, 20, 20, str.LuaString)
                local d_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width), flat_y)
                d_stg_flat:SetText(blank)
                local d_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width), nat_y)
                d_stg_nat:SetText(blank)
                local d_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width), sharp_y)
                d_stg_sharp:SetText(blank)
                col = col + 1
                --
                str.LuaString = "C"
                local c_stg_static = dialog:CreateStatic(col_x + (col * col_width), row_y-1)
                format_ctrl(c_stg_static, 20, 20, str.LuaString)
                local c_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width), flat_y)
                c_stg_flat:SetText(blank)
                local c_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width), nat_y)
                c_stg_nat:SetText(blank)
                local c_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width), sharp_y)
                c_stg_sharp:SetText(blank)
                col = col + 1
                --
                str.LuaString = "B"
                local b_stg_static = dialog:CreateStatic(col_x + (col * col_width), row_y-1)
                format_ctrl(b_stg_static, 20, 20, str.LuaString)
                local b_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width), flat_y)
                b_stg_flat:SetText(blank)
                local b_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width), nat_y)
                b_stg_nat:SetText(blank)
                local b_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width), sharp_y)
                b_stg_sharp:SetText(blank)
                col = col + 1
                --
                local pedals_v_line1 = dialog:CreateVerticalLine(col_x + (col * col_width), flat_y, row_h * 3)
                local pedals_v_line2 = dialog:CreateVerticalLine(col_x + (col * col_width), flat_y, row_h * 3)
                local pedals_v_line3 = dialog:CreateVerticalLine(col_x + (col * col_width), flat_y, row_h * 3)
                col = col + 1
                --
                local nudge_rt_ped = 12
                str.LuaString = "E"
                local e_stg_static = dialog:CreateStatic(col_x + (col * col_width) - nudge_rt_ped, row_y-1)
                format_ctrl(e_stg_static, 20, 20, str.LuaString)
                local e_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, flat_y)
                e_stg_flat:SetText(blank)
                local e_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, nat_y)
                e_stg_nat:SetText(blank)
                local e_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, sharp_y)
                e_stg_sharp:SetText(blank)
                col = col + 1
                --                    
                str.LuaString = "F"
                local f_stg_static = dialog:CreateStatic(col_x + (col * col_width) - nudge_rt_ped, row_y-1)
                format_ctrl(f_stg_static, 20, 20, str.LuaString)
                local f_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, flat_y)
                f_stg_flat:SetText(blank)
                local f_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, nat_y)
                f_stg_nat:SetText(blank)
                local f_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, sharp_y)
                f_stg_sharp:SetText(blank)
                col = col + 1
                --  
                str.LuaString = "G"
                local g_stg_static = dialog:CreateStatic(col_x + (col * col_width) - nudge_rt_ped, row_y-1)
                format_ctrl(g_stg_static, 20, 20, str.LuaString)
                local g_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, flat_y)
                g_stg_flat:SetText(blank)
                local g_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, nat_y)
                g_stg_nat:SetText(blank)
                local g_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, sharp_y)
                g_stg_sharp:SetText(blank)
                col = col + 1
                --  
                str.LuaString = "A"
                local a_stg_static = dialog:CreateStatic(col_x + (col * col_width) - nudge_rt_ped, row_y-1)
                format_ctrl(a_stg_static, 20, 20, str.LuaString)
                local a_stg_flat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, flat_y)
                a_stg_flat:SetText(blank)
                local a_stg_nat = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, nat_y)
                a_stg_nat:SetText(blank)
                local a_stg_sharp = dialog:CreateCheckbox(col_x + (col * col_width) - nudge_rt_ped, sharp_y)
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
                    if diagram_checkbox:GetCheck() == 1 then diag = true 
                    elseif diagram_checkbox:GetCheck() == 0 then diag = false end
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
                    harp_config_save(config)
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
                    local config = harp_config_load()

                    local chd = false
                    if chord_check:GetCheck() == 1 then chd = true end
                    local return_string = finale.FCString()
                    local root = root_calc()

                    if diagram_checkbox:GetCheck() == 1 then diag = true 
                    elseif diagram_checkbox:GetCheck() == 0 then diag = false end

                    return_string.LuaString = harp_notes:GetText(return_string)
--                    local notes, desc = finale.FCString()
                    if return_string.LuaString ~= "" then
--                        harp_diagram(return_string.LuaString, diag)
                    end
                    if scale_check:GetCheck() == 1 then
                        harp_scale(root.LuaString, scales[sel_scale:GetSelectedItem() + 1], diag, chd)
                    elseif chord_check:GetCheck() == 1 then
                        harp_scale(root.LuaString, chords[sel_chord:GetSelectedItem() + 1], diag, chd)
                    end

                    pedals_update()
                    harp_config_save(config)
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
                    if diagram_checkbox:GetCheck() == 1 then diag = true
                    else diag = false end
                    local root = root_calc()
                    local scaleinfo = ""
                    if return_string.LuaString ~= "" then
--                        harp_diagram(return_string.LuaString, diag, nil, partial)
                        process_return(return_string.LuaString)
                        strings_read()
                    else
                        if scale_check:GetCheck() == 1 then 
                            scaleinfo = root.LuaString.." "..scales[sel_scale:GetSelectedItem() + 1]
                        elseif chord_check:GetCheck() == 1 then 
                            scaleinfo = root.LuaString..chords[sel_chord:GetSelectedItem() + 1]
                        end
                    end

                    harp_diagram(str.LuaString, diag, scaleinfo, partial)
                    if (changes == false) and (partial == true) then
                        goto error
                    end
                    pedals_add(diag, partial)
                    str.LuaString = ""
                    harp_notes:SetText(str)
                    changes_static:SetText(str)
                    for i = 1, 6, 1 do
                        str.LuaString = str.LuaString..harpstrings[i]..", "
                    end
                    str.LuaString = str.LuaString..harpstrings[7]
                    config.last_notes = str.LuaString
                    harp_config_save(config)
--                    ui:RedrawDocument()
                    finenv.Region():Redraw()
                    ::error::
                    if (changes == false) and (partial == true) then
                        ui:AlertInfo("There are no pedal changes required.", NULL)
                    end
                end -- apply()

                dialog:RegisterHandleCommand(callback)
                dialog:RegisterHandleOkButtonPressed(callback_ok)
                dialog:RegisterHandleDataListSelect(callback_update)
                if dialog.RegisterCloseWindow then
                    dialog:RegisterCloseWindow(on_close)
                end
                -- initialize pedals
                partial = false 
                harp_diagram(config.last_notes, diag, scaleinfo, partial)
                update_variables()

                if partial_checkbox:GetCheck() == 1 then partial = true end
                pedals_update()

                dialog.OkButtonCanClose = false
                finenv.RegisterModelessDialog(dialog) -- must register, or ShowModeless does nothing
                dialog:ShowModeless()

--                if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
--                end -- if dialog:Execute...

            end -- get_harp
            harp_dialog()
        end -- harp

        harp()
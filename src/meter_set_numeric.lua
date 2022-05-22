function plugindef()
	finaleplugin.RequireSelection = true
    finaleplugin.MinJWLuaVersion = 0.60
    finaleplugin.Author = "Carl Vine"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.55"
    finaleplugin.Date = "2022/05/21"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Notes = [[
This script requires RGPLua 0.60 or later and does not work under JWLua.
(see: https://robertgpatterson.com/-fininfo/-rgplua/rgplua.html)

This script is keyboard focussed with minimal mouse action allowing rapid entry of complex time signatures with a few keystrokes. It supports composite numerators allowing meters like (3+2+3/16) in conjunction with further composites (e.g. (3+2+3/16)+(1/4)+(5+4/8)). Alternate "display" time signatures can be equally complex. At startup the script shows the time signature of the first selected measure. Click the "Clear All" button to revert to a simple 4/4 with no other options. (or, ideally, use a keyboard macro app like Keyboard Maestro to click the button in response to a keystroke!)

All measures in the currently selected region will be assigned the new time signature. If one measure is selected only it will be affected. (Unlike the default Finale behaviour of "change every measure until next meter change").

"Bottom" numbers (denominators) are the usual "note" numbers - 2, 4, 8, 16, 32 or 64. "Top" numbers (numerators) must be integers, optionally joined by '+' signs. Multiples of 3 will automatically convert to compound signatures so, for instance, (9/16) will convert to three groups of dotted 8ths. To suppress automatic compounding, instead of the bottom 'note' number enter its EDU equivalent (quarter note = 1024; eighth note = 512 etc) but be careful since Finale can get confused if the number is inappropriate.

Empty and zero "Top" numbers are ignored. If the "Secondary" Top is zero, "Tertiary" values are ignored. Finale's Time Signature tool will also accept "Top" numbers with decimals but I haven't allowed for that in this script. This script requires RGPLua 0.60 or later.
]]
	return "Meter Set Numeric", "Meter Set Numeric", "Set the Meter Numerically"
end

function user_chooses_meter(meters, region)
    local horiz = { 0, 70, 130, 210, 290, 300 } -- dialog items grid
    local vert = { 0, 20, 40, 60, 82, 115, 135, 155, 175 }
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local left_shift =  19 -- horizontal shift left for the longer "SECONDARY" name
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0
    local user_entry = {} -- compile a bunch of edit fields
    local message = "m. " .. start -- measure selection information
    if stop ~= start then  -- multiple measures
        message = "m" .. message .. "-" .. stop
    end

    local dialog = finale.FCCustomLuaWindow()    
    local str = finale.FCString()
    str.LuaString = plugindef() -- get script name
    dialog:SetTitle(str)
    dialog:CreateHorizontalLine(horiz[1], vert[6] - 9, horiz[5] + 80)

    local texts = { -- words, horiz, vert position
        { "TIME SIGNATURE:", horiz[1], vert[1] },
        { "TOP", horiz[3], vert[1] },               { "BOTTOM", horiz[4], vert[1] },
        { "PRIMARY", horiz[2], vert[2] },           { "Selection:", horiz[6], vert[2]+ 5 },
        { "SECONDARY", horiz[2] - left_shift, vert[3] }, { message, horiz[6], vert[3] }, -- "mm. START-STOP"
        { "TERTIARY", horiz[2] - 3, vert[4] },
        { "('TOP' entries can include integers joined by '+')", horiz[2] - 30, vert[5] },
        { "DISPLAY SIGNATURE:", horiz[1], vert[6] },  { "(set to \"0\" for none)", horiz[3], vert[6] },
        { "PRIMARY", horiz[2], vert[7] },
        { "SECONDARY", horiz[2] - left_shift, vert[8] },
        { "TERTIARY", horiz[2] - 3, vert[9] },
    }
    for i,v in ipairs(texts) do -- write static text items
        local static = dialog:CreateStatic(v[2], v[3])
        str.LuaString = v[1]
        static:SetText(str)
        static:SetWidth( (#v[1] * 6) + 20 ) -- wide enough for item text (circa 6 pix per char plus a bit)
    end

    for i, v in ipairs(meters) do -- create all meter numeric entry boxes
        local vert_step = math.floor((i - 1) / 2) + 2
        if i > 6 then
            vert_step = vert_step + 2  -- middle two lines are instructions
        end
        local top_bottom = 4 - (i % 2) -- 'TOP' or 'BOTTOM' position x-value
        user_entry[i] = dialog:CreateEdit(horiz[top_bottom], vert[vert_step] - mac_offset)
        user_entry[i]:SetWidth(70)
        str.LuaString = v
        if i % 2 == 1 then  -- string for TOP meter number
            user_entry[i]:SetText(str) -- string for TOP (split into tables later)
        else    -- plain integer for BOTTOM meter number
            user_entry[i]:SetInteger(v) -- integer for BOTTOM
        end
    end

    -- "CLEAR ALL" button to reset meter defaults
    local clear_button = dialog:CreateButton(horiz[5], vert[1] - 2)
    str.LuaString = "Clear All"
    clear_button:SetWidth(80)
    clear_button:SetText(str)

    dialog:RegisterHandleControlEvent ( clear_button,
        function(control)
            local str = finale.FCString()
            str.LuaString = "4" 
            user_entry[1]:SetText(str)
            user_entry[2]:SetInteger(4)
            str.LuaString = "0" 
            for i = 3, 11, 2 do -- clear all other edit boxes
                user_entry[i]:SetText(str)
                user_entry[i + 1]:SetInteger(0)
            end
            user_entry[1]:SetFocus()
        end
    )
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = dialog:ExecuteModal(nil)  -- run the dialog

    for i = 1, #meters do  -- collate user input
        if i % 2 == 1 then    -- string for TOP
            user_entry[i]:GetText(str)
            meters[i] = str.LuaString
        else              -- integer for BOTTOM
            meters[i] = user_entry[i]:GetInteger()
        end
    end
    return ok
end

function encode_existing_meter(time_sig, meters, index_offset)
    -- convert existing meter to our { meters } filing method
    if time_sig.CompositeTop then
        local comp_top = time_sig:CreateCompositeTop()
        local group_count = comp_top:GetGroupCount()
        if group_count > 3 then 
            group_count = 3 -- three composites max
        end
        for i = 0, group_count - 1 do -- add elements of each group
            local top_string = ""  -- empty string to index_offset
            for element_count = 0, comp_top:GetGroupElementCount(i) - 1 do
                if element_count > 0 then -- plus sign after first number
                    top_string = top_string .. "+" 
                end
                top_string = top_string .. comp_top:GetGroupElementBeats(i, element_count)
            end
            meters[(i * 2) + index_offset] = top_string -- save the string result
        end
    else    -- non-composite TOP, simple number string
        meters[index_offset] = "" .. time_sig.Beats
    end

    if time_sig.CompositeBottom then
        local comp_bottom = time_sig:CreateCompositeBottom()
        local group_count = comp_bottom:GetGroupCount()
        if group_count > 3 then
            group_count = 3 -- 3 composites max
        end
        for i = 0, group_count - 1 do
            -- assume one element for each composite bottom
            local beat_duration = comp_bottom:GetGroupElementBeatDuration(i, 0)
            local bottom_offset = (i * 2) + index_offset -- offset for individual composites
            if beat_duration % 3 == 0 and not string.find(meters[bottom_offset], "+") then 
                meters[bottom_offset] = "" .. ( meters[bottom_offset] * 3 ) -- create compound meter
                beat_duration = beat_duration / 3
            end
            meters[bottom_offset + 1] = math.floor(4096 / beat_duration) -- round to integer in case
        end
    else    -- non-composite BOTTOM
        local beat_duration = time_sig.BeatDuration
        if beat_duration % 3 == 0 and not string.find(meters[index_offset], "+") then
            meters[index_offset] = "" .. ( meters[index_offset] * 3 ) -- create compound meter
            beat_duration = beat_duration / 3
        end
        meters[index_offset + 1] = math.floor(4096 / beat_duration) -- round to integer in case
    end
end

function copy_meters_from_score(meters, measure_number)
    local measure = finale.FCMeasure()
    measure:Load(measure_number)
    encode_existing_meter(measure:GetTimeSignature(), meters, 1)  -- encode primary meter - offset to meters[1]
    if measure.UseTimeSigForDisplay then    -- encode DISPLAY meter - offset to meters[7]
        encode_existing_meter(measure.TimeSignatureForDisplay, meters, 7)
    end
end

function is_positive_integer(x)
    if x == nil or x < 0 or x ~= math.floor(x) then 
        return "All numbers must be positive integers"
    end
    return ""
end

function is_power_of_2(test_number)
    local result = is_positive_integer(test_number)
    if result ~= "" then
        return result
    end
    local power_2_test = math.log(test_number) / math.log(2) -- power of 2???
    if power_2_test ~= math.floor(power_2_test) then
        result = "BOTTOM numbers must be 2,4,8,16 or 32\n(not \"" .. test_number .. "\")"
    end
    return result
end

function convert_meter_pairs_to_numbers(top_index, meters)
    local result = "" -- generic answer string ("" for no error)

    -- 'TOP' indexed meter is a string of numbers, possibly joined by "+" signs
    -- convert to a table of simple integers
    if meters[top_index] == "0" or meters[top_index] == "" then
        meters[top_index] = { 0 } -- zero array for numerators
        if top_index == 1 then
            return "Primary time signature can not be zero"
        else
            return "" -- nil result ... BOTTOM is irrelevant
        end
    end
    if string.find(meters[top_index], "[+ -/]") then -- TOP number string contains "+" or other divider
        -- COMPLEX string numerator: split into integers
        local string_copy = meters[top_index] -- copy the string
        meters[top_index] = {} -- start over with empty table of integers
        for split_number in string.gmatch(string_copy, "[0-9]+") do -- split numbers
        	local as_number = tonumber(split_number)
        	result = is_positive_integer(as_number)    -- positive integer result?
            if result ~= "" then -- error
                return result
            end
            table.insert(meters[top_index], as_number)    -- else add integer to table
        end
    else -- simple integer, re-store as single-element table
        local as_number = tonumber(meters[top_index])
        result = is_positive_integer(as_number)    -- positive integer resultor?
        if result ~= "" then -- error
            return result
        end
        meters[top_index] = { as_number }    -- save single integer table
    end
    
    -- 'BOTTOM' numeric DENOMINATOR (top_index + 1)
    -- must be simple integer, power of 2 ... convert NOTE NUMBER to EDU value, with compounding
    local bottom_index = top_index + 1
    local denominator = meters[bottom_index]
    if denominator == 0 then  -- no meter here!
        return ""
    end
    if denominator > 65 then -- assume it's EDU, not a NOTE VALUE (bigger than 64th note)
        result = is_positive_integer(denominator) -- positive integer resultor?
        if result ~= "" then    -- error
            return result
        end
    else -- a NOTE VALUE number (8th note = '8' etc)
        result = is_power_of_2(denominator) -- is it a power of 2?
        if result ~= "" then -- error
            return result
        end
        meters[bottom_index] = 4096 / denominator  -- else convert to EDUs

        -- check for COMPOUND meter
        if #meters[top_index] == 1 then -- single number, simple numerator
            local numerator = meters[top_index][1]
            -- convert to COMPOUND if NOT a display meter (top_index>=7)
            if top_index < 7 and numerator % 3 == 0 and meters[bottom_index] < 1024 then -- (8th notes or smaller)
                meters[top_index][1] = numerator / 3
                meters[bottom_index] = meters[bottom_index] * 3   -- convert to COMPOUND
            end
        end
    end
    return ""   -- no errors
end

function new_composite_top(tableA, tableB, tableC)
    -- each table contains one or more integers to be meter numerators
    local composite_top = finale.FCCompositeTimeSigTop()
    local group = composite_top:AddGroup(#tableA)
    for i = 1, #tableA do
        composite_top:SetGroupElementBeats(group, i - 1, tableA[i])
    end

    if tableB[1] ~= 0 then    -- non-nul secondary
        group = composite_top:AddGroup(#tableB)
        for i = 1, #tableB do
            composite_top:SetGroupElementBeats(group, i - 1, tableB[i])
        end
        -- only add tableC if tableB is non-zero
        if tableC[1] ~= 0 then    -- non-nul tertiary
            group = composite_top:AddGroup(#tableC)
            for i = 1, #tableC do
                composite_top:SetGroupElementBeats(group, i - 1, tableC[i])
            end
        end
    end
    composite_top:SaveAll()
    return composite_top
end

function new_composite_bottom(numA, numB, numC)
    -- each number is an EDU value for meter denominator
    local composite_bottom = finale.FCCompositeTimeSigBottom()
    local new_group = composite_bottom:AddGroup(1)
    composite_bottom:SetGroupElementBeatDuration(new_group, 0, numA)
    
    if numB > 0 then
        new_group = composite_bottom:AddGroup(1)
        composite_bottom:SetGroupElementBeatDuration(new_group, 0, numB)
        -- only consider numC if numB is non-zero
        if numC > 0 then
            new_group = composite_bottom:AddGroup(1)
            composite_bottom:SetGroupElementBeatDuration(new_group, 0, numC)
        end
    end
    composite_bottom:SaveAll()
    return composite_bottom
end

function fix_new_top(composite_top, time_sig, numerator)
    if composite_top ~= nil then    -- COMPOSITE top
        time_sig:SaveNewCompositeTop(composite_top)
    else
        if time_sig:GetCompositeTop() then
            time_sig:RemoveCompositeTop(numerator)
        else
            time_sig.Beats = numerator  -- simple time sig
        end
    end
end

function fix_new_bottom(composite_bottom, time_sig, denominator)
    if composite_bottom ~= nil then    -- COMPOSITE bottom
        time_sig:SaveNewCompositeBottom(composite_bottom)
    else
        if time_sig:GetCompositeBottom() then
            time_sig:RemoveCompositeBottom(denominator)
        else
            time_sig.BeatDuration = denominator
        end
    end
end

function create_new_meter()
    local region = finenv.Region()
    -- preset "all zero" basic meters - 6 sets of top/bottom pairs
    --  "real" meter   1   +      2   +   3  | display meter 1    +     2    +   3   
    local meters = { "4", 4,   "0", 0,   "0", 0,           "0", 0,   "0", 0,   "0", 0,  }
    local result = "" -- holder for error messages
        
    copy_meters_from_score(meters, region.StartMeasure) -- examine and encode original meter from start of selection
    local ok = user_chooses_meter(meters, region) -- user choices stored in meters { }
	if ok ~= finale.EXECMODAL_OK then
        return -- user cancelled
    end

    for index_pairs = 1, 11, 2 do -- check 6 top/bottom pairs
        result = convert_meter_pairs_to_numbers(index_pairs, meters)
        if result ~= "" then 
            finenv.UI():AlertNeutral(plugindef(), result)
            return
        end
    end
    --  -----------
    -- NOTE that "meters" array now equals
    -- TOPS (1,3,5 / 7,9,11) = arrays of integers, BOTTOMS (2,4,6 / 8,10,12) = simple integers
    --  -----------
    -- new COMPOSITE METERS TABLE to hold FOUR combined composite Time Signatures: 
    -- "REAL" = 1 (top) / 2 (bottom) | "DISPLAY" = 3 (top) / 4 (bottom)
    local composites = { nil, nil, nil, nil }
    for i = 0, 1 do  -- PRIMARY meters then DISPLAY meters
        local step = i * 6 -- 6 steps between "real" and "display" meter numbers
        if #meters[step + 1] > 1 or meters[step + 3][1] ~= 0 then -- composite TOP
            composites[(i * 2) + 1] = new_composite_top(meters[step + 1], meters[step + 3], meters[step + 5])
        end
        -- composite BOTTOM?
        if composites[(i * 2) + 1] ~= nil and meters[step + 3][1] ~= 0 then
            composites[(i * 2) + 2] = new_composite_bottom(meters[step + 2], meters[step + 4], meters[step + 6])
        end
    end

    --  -----------
    region.StartMeasurePos = 0    -- set to whole stack (in case it is safer)
    region:SetEndMeasurePosRight()
    region:SetFullMeasureStack()
    local measures = finale.FCMeasures()
    measures:LoadRegion(region)
 
    for measure in each(measures) do
        local time_sig = measure:GetTimeSignature()
        fix_new_top(composites[1], time_sig, meters[1][1])
        fix_new_bottom(composites[2], time_sig, meters[2])
        time_sig:Save()

        if meters[7][1] ~= 0 then -- new, unique Display meter
            measure.UseTimeSigForDisplay = true
            local display_sig = measure.TimeSignatureForDisplay
            if display_sig then
                fix_new_top(composites[3], display_sig, meters[7][1])
                fix_new_bottom(composites[4], display_sig, meters[8])
                display_sig:Save()
            end
        else   -- suppress display time_sig
            measure.UseTimeSigForDisplay = false
        end
        measure:Save()
    end
end

create_new_meter()

function plugindef()
	finaleplugin.RequireSelection = true
    finaleplugin.MinJWLuaVersion = 0.60
    finaleplugin.Author = "Carl Vine"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.57"
    finaleplugin.Date = "2022/05/22"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Notes = [[
This script requires RGPLua 0.60 or later and does not work under JWLua.
(see: https://robertgpatterson.com/-fininfo/-rgplua/rgplua.html)
This script is keyboard focussed with minimal mouse action allowing rapid entry of complex time signatures with a few keystrokes. It supports composite numerators allowing meters like (3+2+3/16) in conjunction with further composites (e.g. (3+2+3/16)+(1/4)+(5+4/8)). Alternate "display" time signatures can be equally complex. At startup the script shows the time signature of the first selected measure. Click the "Clear All" button to revert to a simple 4/4 with no other options. (or, ideally, use a keyboard macro app like Keyboard Maestro to click the button in response to a keystroke!)
All measures in the currently selected region will be assigned the new time signature. If one measure is selected only it will be affected. (Unlike the default Finale behaviour of "change every measure until next meter change").
"Bottom" numbers (denominators) are the usual "note" numbers - 2, 4, 8, 16, 32 or 64. "Top" numbers (numerators) must be integers, optionally joined by '+' signs. Multiples of 3 will automatically convert to compound signatures so, for instance, (9/16) will convert to three groups of dotted 8ths. To suppress automatic compounding, instead of the bottom 'note' number enter its EDU equivalent (quarter note = 1024; eighth note = 512 etc) but be careful since Finale can get confused if the number is inappropriate.
Empty and zero "Top" numbers are ignored. If the "Secondary" Top is zero, "Tertiary" values are ignored. Finale's Time Signature tool will also accept "Top" numbers with decimals but I haven't allowed for that in this script.
]]
	return "Meter Set Numeric", "Meter Set Numeric", "Set the Meter Numerically"
end
function user_chooses_meter(meters, region)
    local horiz = { 0, 70, 130, 210, 290, 300 }
    local vert = { 0, 20, 40, 60, 82, 115, 135, 155, 175 }
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local left_shift =  19
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0
    local user_entry = {}
    local message = "m. " .. start
    if stop ~= start then
        message = "m" .. message .. "-" .. stop
    end
    local dialog = finale.FCCustomLuaWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
    dialog:CreateHorizontalLine(horiz[1], vert[6] - 9, horiz[5] + 80)
    local texts = {
        { "TIME SIGNATURE:", horiz[1], vert[1] },
        { "TOP", horiz[3], vert[1] },               { "BOTTOM", horiz[4], vert[1] },
        { "PRIMARY", horiz[2], vert[2] },           { "Selection:", horiz[6], vert[2]+ 5 },
        { "SECONDARY", horiz[2] - left_shift, vert[3] }, { message, horiz[6], vert[3] },
        { "TERTIARY", horiz[2] - 3, vert[4] },
        { "('TOP' entries can include integers joined by '+')", horiz[2] - 30, vert[5] },
        { "DISPLAY SIGNATURE:", horiz[1], vert[6] },  { "(set to \"0\" for none)", horiz[3], vert[6] },
        { "PRIMARY", horiz[2], vert[7] },
        { "SECONDARY", horiz[2] - left_shift, vert[8] },
        { "TERTIARY", horiz[2] - 3, vert[9] },
    }
    for i,v in ipairs(texts) do
        local static = dialog:CreateStatic(v[2], v[3])
        str.LuaString = v[1]
        static:SetText(str)
        static:SetWidth( (#v[1] * 6) + 20 )
    end
    for i, v in ipairs(meters) do
        local vert_step = math.floor((i - 1) / 2) + 2
        if i > 6 then
            vert_step = vert_step + 2
        end
        local top_bottom = 4 - (i % 2)
        user_entry[i] = dialog:CreateEdit(horiz[top_bottom], vert[vert_step] - mac_offset)
        user_entry[i]:SetWidth(70)
        str.LuaString = v
        if i % 2 == 1 then
            user_entry[i]:SetText(str)
        else
            user_entry[i]:SetInteger(v)
        end
    end

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
            for i = 3, 11, 2 do
                user_entry[i]:SetText(str)
                user_entry[i + 1]:SetInteger(0)
            end
            user_entry[1]:SetFocus()
        end
    )
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = dialog:ExecuteModal(nil)
    for i = 1, #meters do
        if i % 2 == 1 then
            user_entry[i]:GetText(str)
            meters[i] = str.LuaString
        else
            meters[i] = user_entry[i]:GetInteger()
        end
    end
    return ok
end
function encode_existing_meter(time_sig, meters, index_offset)

    if time_sig.CompositeTop then
        local comp_top = time_sig:CreateCompositeTop()
        local group_count = comp_top:GetGroupCount()
        if group_count > 3 then
            group_count = 3
        end
        for i = 0, group_count - 1 do
            local top_string = ""
            for element_count = 0, comp_top:GetGroupElementCount(i) - 1 do
                if element_count > 0 then
                    top_string = top_string .. "+"
                end
                top_string = top_string .. comp_top:GetGroupElementBeats(i, element_count)
            end
            meters[(i * 2) + index_offset] = top_string
        end
    else
        meters[index_offset] = "" .. time_sig.Beats
    end
    if time_sig.CompositeBottom then
        local comp_bottom = time_sig:CreateCompositeBottom()
        local group_count = comp_bottom:GetGroupCount()
        if group_count > 3 then
            group_count = 3
        end
        for i = 0, group_count - 1 do

            local beat_duration = comp_bottom:GetGroupElementBeatDuration(i, 0)
            local bottom_offset = (i * 2) + index_offset
            if beat_duration % 3 == 0 and not string.find(meters[bottom_offset], "+") then
                meters[bottom_offset] = "" .. ( meters[bottom_offset] * 3 )
                beat_duration = beat_duration / 3
            end
            meters[bottom_offset + 1] = math.floor(4096 / beat_duration)
        end
    else
        local beat_duration = time_sig.BeatDuration
        if beat_duration % 3 == 0 and not string.find(meters[index_offset], "+") then
            meters[index_offset] = "" .. ( meters[index_offset] * 3 )
            beat_duration = beat_duration / 3
        end
        meters[index_offset + 1] = math.floor(4096 / beat_duration)
    end
end
function copy_meters_from_score(meters, measure_number)
    local measure = finale.FCMeasure()
    measure:Load(measure_number)
    encode_existing_meter(measure:GetTimeSignature(), meters, 1)
    if measure.UseTimeSigForDisplay then
        encode_existing_meter(measure.TimeSignatureForDisplay, meters, 7)
    end
end
function is_positive_integer(x)
    return x ~= nil and x > 0 and x % 1 == 0
end
function is_power_of_two(num)
    local current = 1
    while current < num do
        current = current * 2
    end
    return current == num
end
function convert_meter_pairs_to_numbers(top_index, meters)


    if meters[top_index] == "0" or meters[top_index] == "" then
        meters[top_index] = { 0 }
        if top_index == 1 then
            return "Primary time signature can not be zero"
        else
            return ""
        end
    end
    if string.find(meters[top_index], "[+ -/]") then

        local string_copy = meters[top_index]
        meters[top_index] = {}
        for split_number in string.gmatch(string_copy, "[0-9]+") do
        	local as_number = tonumber(split_number)
            if not is_positive_integer(as_number) then
                return "All numbers must be positive integers\n(not " .. as_number .. ")"
            end
            table.insert(meters[top_index], as_number)
        end
    else
        local as_number = tonumber(meters[top_index])
        if not is_positive_integer(as_number) then
            return "All numbers must be positive integers\n(not " .. as_number .. ")"
        end
        meters[top_index] = { as_number }
    end



    local bottom_index = top_index + 1
    local denominator = meters[bottom_index]
    if denominator == 0 then
        return ""
    end
    if not is_positive_integer(denominator) then
        return "All numbers must be positive integers\n(not " .. denominator .. ")"
    end
    if denominator <= 64 then
        if not is_power_of_two(denominator) then
            return "Denominators must be powers of 2\n(not " .. denominator .. ")"
        end
        denominator = 4096 / denominator

        if #meters[top_index] == 1 then
            local numerator = meters[top_index][1]

            if top_index < 7 and numerator % 3 == 0 and denominator < 1024 then
                meters[top_index][1] = numerator / 3
                denominator = denominator * 3
            end
        end
        meters[bottom_index] = denominator
    end
    return ""
end
function new_composite_top(numerator_valuesA, numerator_valuesB, numerator_valuesC)

    local composite_top = finale.FCCompositeTimeSigTop()
    local group = composite_top:AddGroup(#numerator_valuesA)
    for i = 1, #numerator_valuesA do
        composite_top:SetGroupElementBeats(group, i - 1, numerator_valuesA[i])
    end
    if numerator_valuesB[1] ~= 0 then
        group = composite_top:AddGroup(#numerator_valuesB)
        for i = 1, #numerator_valuesB do
            composite_top:SetGroupElementBeats(group, i - 1, numerator_valuesB[i])
        end

        if numerator_valuesC[1] ~= 0 then
            group = composite_top:AddGroup(#numerator_valuesC)
            for i = 1, #numerator_valuesC do
                composite_top:SetGroupElementBeats(group, i - 1, numerator_valuesC[i])
            end
        end
    end
    composite_top:SaveAll()
    return composite_top
end
function new_composite_bottom(denominatorA, denominatorB, denominatorC)

    local composite_bottom = finale.FCCompositeTimeSigBottom()
    local new_group = composite_bottom:AddGroup(1)
    composite_bottom:SetGroupElementBeatDuration(new_group, 0, denominatorA)

    if denominatorB > 0 then
        new_group = composite_bottom:AddGroup(1)
        composite_bottom:SetGroupElementBeatDuration(new_group, 0, denominatorB)

        if denominatorC > 0 then
            new_group = composite_bottom:AddGroup(1)
            composite_bottom:SetGroupElementBeatDuration(new_group, 0, denominatorC)
        end
    end
    composite_bottom:SaveAll()
    return composite_bottom
end
function fix_new_top(composite_top, time_sig, numerator)
    if composite_top ~= nil then
        time_sig:SaveNewCompositeTop(composite_top)
    else
        if time_sig:GetCompositeTop() then
            time_sig:RemoveCompositeTop(numerator)
        else
            time_sig.Beats = numerator
        end
    end
end
function fix_new_bottom(composite_bottom, time_sig, denominator)
    if composite_bottom ~= nil then
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


    local meters = { "4", 4,   "0", 0,   "0", 0,           "0", 0,   "0", 0,   "0", 0,  }
    local result = ""

    copy_meters_from_score(meters, region.StartMeasure)
    local ok = user_chooses_meter(meters, region)
	if ok ~= finale.EXECMODAL_OK then
        return
    end
    for index_pairs = 1, 11, 2 do
        result = convert_meter_pairs_to_numbers(index_pairs, meters)
        if result ~= "" then
            finenv.UI():AlertNeutral(plugindef(), result)
            return
        end
    end






    local composites = { nil, nil, nil, nil }
    for i = 0, 1 do
        local step = i * 6
        if #meters[step + 1] > 1 or meters[step + 3][1] ~= 0 then
            composites[(i * 2) + 1] = new_composite_top(meters[step + 1], meters[step + 3], meters[step + 5])
        end

        if composites[(i * 2) + 1] ~= nil and meters[step + 3][1] ~= 0 then
            composites[(i * 2) + 2] = new_composite_bottom(meters[step + 2], meters[step + 4], meters[step + 6])
        end
    end

    region.StartMeasurePos = 0
    region:SetEndMeasurePosRight()
    region:SetFullMeasureStack()
    local measures = finale.FCMeasures()
    measures:LoadRegion(region)

    for measure in each(measures) do
        local time_sig = measure:GetTimeSignature()
        fix_new_top(composites[1], time_sig, meters[1][1])
        fix_new_bottom(composites[2], time_sig, meters[2])
        if meters[7][1] ~= 0 then
            measure.UseTimeSigForDisplay = true
            local display_sig = measure.TimeSignatureForDisplay
            if display_sig then
                fix_new_top(composites[3], display_sig, meters[7][1])
                fix_new_bottom(composites[4], display_sig, meters[8])
            end
        else
            measure.UseTimeSigForDisplay = false
        end
        measure:Save()
    end
end
create_new_meter()

function plugindef()
	finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/?cv=lua"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.68"
    finaleplugin.Date = "2023/06/12"
    finaleplugin.MinJWLuaVersion = 0.60
    finaleplugin.Notes = [["Meter Set Numeric" provides rapid entry of simple or complex 
time signatures with a few keystrokes. 
It supports composite numerators like [3+2+3/16] and can join 
with further composites (e.g. [3+2+3/16]+[1/4]+[5+4/8]). 
"Display only" time signatures can be equally complex and set without using a mouse. 
At startup the time signature of the first selected measure is shown. 
Click the "Clear All" button to revert to a simple 4/4 with no other options.

All measures in the current selection will be assigned the new time signature. 
If just one measure is selected only it will be changed.

"Bottom" numbers (denominators) are the usual "note" numbers: 2, 4, 8, 16, 32, 64. 
"Top" numbers (numerators) are integers, optionally joined by '+' signs for composite meters. 
Multiples of 3 automatically convert to compound signatures so [9/16] will 
convert to three groups of dotted 8ths. 
To prevent automatic compounding, instead of the bottom 'note' number enter its EDU value 
(quarter note = 1024; eighth note = 512 etc).

Empty and zero "Top" numbers will be ignored. 
If "Secondary" numbers are zero then "Tertiary" values are ignored. 
    ]]
	return "Meter Set Numeric", "Meter Set Numeric", "Set the Meter Numerically"
end

--[[
    This version uses a new (intelligible!) data structure for composite Time Signatures:
    local meter = {
        main = { 
            top = { {element_1a, element_1b, element_1c}, {element_2a, etc. ...}, {... element_3c} }, 
            bottom = {group_1, group_2, group_3}
        },
        display =  {
            top = { {element_1a, element_1b, element_1c}, etc. ... }, 
            bottom = {group_1, group_2, group_3}
        },
    }
]]

local mixin = require("library.mixin")
local configuration = require("library.configuration")
local config = {
    note_spacing = true,
    window_pos_x = false,
    window_pos_y = false,
}
local script_name = "meter_set_numeric"
configuration.get_user_settings(script_name, config, true)

function blank_meter()
    return { -- empty composite meter record
        main = { top = {}, bottom = {} },
        display =  { top = {}, bottom = {} }
    }
end

function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

function user_chooses_meter(meter, rgn)
    local x = { 0, 70, 130, 210, 280, 290 } -- horizontal grid
    local label = {"PRIMARY", "(+ SECONDARY)", "(+ TERTIARY)"}
    local label_off = { 0, -37, -21 } -- horizontal offset for these names (ranged right)
    local y_middle = 118 -- window vertical mid-point
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local message = "m. " .. rgn.StartMeasure -- measure selection information
    if rgn.StartMeasure ~= rgn.EndMeasure then  -- multiple measures
        message = "m" .. message .. "-" .. rgn.EndMeasure
    end
    local y = 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    -- STATIC TEXT ELEMENTS
    local function cstat(nx, ny, nwide, ntext)
        local dx = (type(nx) == "number") and x[nx] or tonumber(nx)
        return dialog:CreateStatic(dx, ny):SetWidth(nwide):SetText(ntext)
    end
    local function join(values) -- join integers from the meter.top array with '+' signs
        if not values or #values == 0 then return "0" end
        return table.concat(values, "+")
    end
    local shadow = cstat("1", y + 1, x[3], "TIME SIGNATURE")
    if shadow.SetTextColor then shadow:SetTextColor(153, 153, 153) end
    cstat(1, y, x[3], "TIME SIGNATURE")
    cstat(3, y, x[3], "TOP")
    cstat(4, y, x[3], "BOTTOM")
    cstat(6, 25, 80, "Selection:")
    cstat(6, 40, 80, message)
    y = y_middle
    cstat(x[2] - 30, y - 30, 330, "'TOP' entries can include integers joined by '+' signs")
    dialog:CreateHorizontalLine(x[1], y - 9, x[5] + 50)
    dialog:CreateHorizontalLine(x[1], y - 8, x[5] + 50)
    shadow = cstat("1", y + 1, x[3], "DISPLAY SIGNATURE")
    if shadow.SetTextColor then shadow:SetTextColor(153, 153, 153) end
    cstat(1, y, x[3], "DISPLAY SIGNATURE")
    cstat(3, y, 150, "(set to '0' for none)")
    dialog:CreateButton(x[5] + 60, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() finenv.UI():AlertInfo(finaleplugin.Notes:gsub(" \n", " "), "INFO: Meter Set Numeric") end)

    -- USER EDIT BOXES
    y = 0
    local box = {} -- user's edit-box entry responses
    for jump = 0, 6, 6 do
        local t_sig = (jump == 0) and meter.main or meter.display
        for group = 1, 3 do
            y = y + 20
            local id = group + jump
            box[id] = dialog:CreateEdit(x[3], y - offset, tostring(id))
                :SetText(join(t_sig.top[group])):SetWidth(65)
            box[id + 3] = dialog:CreateEdit(x[4], y - offset, tostring(id + 3))
                :SetInteger(t_sig.bottom[group] or 0):SetWidth(65)
            cstat(x[2] + label_off[group], y, 95, label[group])
        end
        y = y_middle
    end
    dialog:CreateCheckbox(x[3], y_middle + 85, "spacing"):SetText("Respace notes on completion")
        :SetCheck(config.note_spacing and 1 or 0):SetWidth(170)
    local clear_button = dialog:CreateButton(x[5], 0):SetWidth(80):SetText("Clear All")
    clear_button:AddHandleCommand(function()
            box[1]:SetText("4")
            box[4]:SetInteger(4)
            for _, i in ipairs({2, 3, 7, 8, 9}) do -- "clear" the other edit boxes
                box[i]:SetText("0")
                box[i + 3]:SetInteger(0)
            end
            box[1]:SetKeyboardFocus()
        end
    )
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local choices = {} -- convert edit box values to 12-element table
    dialog:RegisterInitWindow(function() box[1]:SetKeyboardFocus() end)
    -- "TOP" values are strings, "BOTTOMS" are integers
    dialog:RegisterHandleOkButtonPressed(function(self)
        for count = 0, 6, 6 do -- "main" then "display" t_sig values
            for group = 1, 3 do
                local id = count + group
                choices[id] = self:GetControl(tostring(id)):GetText() or "0"
                choices[id + 3] = math.abs(self:GetControl(tostring(id + 3)):GetInteger()) or 0
            end
        end
        config.note_spacing = (self:GetControl("spacing"):GetCheck() == 1)
        dialog_save_position(self) -- save window position and config choices
    end)
    dialog_set_position(dialog)
    local ok = dialog:ExecuteModal(nil)  -- run the dialog
    return ok, choices
end

function encode_current_meter(time_sig, sub_meter)
    local function numerators_treble(top_table)
        for j = 1, #top_table do
            top_table[j] = top_table[j] * 3
        end
    end

    if time_sig.CompositeTop then
        local comp_top = time_sig:CreateCompositeTop()
        local group_count = comp_top:GetGroupCount()
        if group_count > 3 then group_count = 3 end -- 3 groups max
        for i = 1, group_count do -- add each group
            sub_meter.top[i] = {}
            for element = 1, comp_top:GetGroupElementCount(i - 1) do
                sub_meter.top[i][element] = comp_top:GetGroupElementBeats(i - 1, element - 1)
            end
        end
    else    -- NON-Composite Top
        sub_meter.top[1] = { time_sig.Beats }
    end

    if time_sig.CompositeBottom then
        local comp_bottom = time_sig:CreateCompositeBottom()
        local group_count = comp_bottom:GetGroupCount()
        if group_count > 3 then group_count = 3 end -- 3 groups max
        for i = 1, group_count do
            local beat_duration = comp_bottom:GetGroupElementBeatDuration(i - 1, 0)
            if beat_duration % 3 == 0 then
                beat_duration = beat_duration / 3
                numerators_treble(sub_meter.top[i])
            end
            sub_meter.bottom[i] = math.floor(4096 / beat_duration) -- round to integer in case
        end
    else    -- NON-Composite Bottom
        local beat_duration = time_sig.BeatDuration
        if beat_duration % 3 == 0 then
            beat_duration = beat_duration / 3
            numerators_treble(sub_meter.top[1])
        end
        sub_meter.bottom[1] = math.floor(4096 / beat_duration)
    end
end

function copy_meter_from_score(measure_number)
    local measure = finale.FCMeasure()
    measure:Load(measure_number)
    local meter = blank_meter()
    encode_current_meter(measure:GetTimeSignature(), meter.main)
    if measure.UseTimeSigForDisplay then
        encode_current_meter(measure.TimeSignatureForDisplay, meter.display)
    end
    return meter
end

function is_power_of_two(num)
    local current = 1
    while current < num do
        current = current * 2
    end
    return current == num
end

function convert_choices_to_meter(choices, meter)
    if choices[1] == "0" or choices[4] == 0 then
        return "Primary time signature cannot be zero"
    end
    for jump = 0, 6, 6 do -- 'main' meter then 'display' meter
        local data = (jump == 0) and meter.main or meter.display
        for count = 1, 3 do
            -- 'TOP' NUMBERS
            local c_count = count + jump
            local value = choices[c_count]
            if value == "0" or choices[c_count + 3] == 0 then
                break -- no valid meter values
            end
            if string.find(value, "^%d") then -- string contains non-numeric characters
                data.top[count] = {}
                for split in string.gmatch(value, "%d+") do
                    table.insert(data.top[count], tonumber(split))
                end
            else
                data.top[count] = { tonumber(choices[c_count]) } -- single integer value
            end
            -- 'BOTTOM' NUMBERS
            local bottom = choices[c_count + 3]
            if bottom <= 64 and bottom > 0 then -- must be a NOTE VALUE (64th note or smaller) not EDU
                if not is_power_of_two(bottom) then
                    return "DENOMINATORS must be powers of 2\n(not " .. bottom .. ")"
                end
                bottom = 4096 / bottom  -- convert to EDU

                if #data.top[count] == 1 then -- not composite so check for compound
                    local n = data.top[count][1]
                    if n % 3 == 0 and jump == 0 and n > 3 then
                        data.top[count][1] = n / 3 -- COMPOUND METER: so numerator divide by 3
                        bottom = bottom * 3   -- and denominator multiply by 3
                    end
                end
            end
            data.bottom[count] = bottom
        end
    end
    return "" -- no error
end

function new_composite_top(sub_meter)
    local composite_top = finale.FCCompositeTimeSigTop()
    for count = 1, 3 do
        if not sub_meter[count] or sub_meter[count][1] == 0 then break end
        local group = composite_top:AddGroup(#sub_meter[count])
        for i = 1, #sub_meter[count] do
            composite_top:SetGroupElementBeats(group, i - 1, sub_meter[count][i])
        end
    end
    composite_top:SaveAll()
    return composite_top
end

function new_composite_bottom(sub_meter)
    local composite_bottom = finale.FCCompositeTimeSigBottom()
    for count = 1, 3 do
        if not sub_meter[count] or sub_meter[count] == 0 then break end
        local group = composite_bottom:AddGroup(1)
        composite_bottom:SetGroupElementBeatDuration(group, 0, sub_meter[count])
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
    local region = mixin.FCMMusicRegion()
    region:SetRegion(finenv.Region()):SetStartMeasurePosLeft():SetEndMeasurePosRight()

    local meter = copy_meter_from_score(region.StartMeasure)
    local ok, choices = user_chooses_meter(meter, region) -- save user choices as 12-element table
	if ok ~= finale.EXECMODAL_OK then return end -- user cancelled

    meter = blank_meter() -- start over with an empty meter
    local msg = convert_choices_to_meter(choices, meter)
    if msg ~= "" then finenv.UI():AlertInfo(msg, plugindef()) return end -- entry error

    local composites = {
        main = { top = nil, bottom = nil},
        display = { top = nil, bottom = nil}
    }
    for _, kind in ipairs({"main", "display"}) do
        if meter[kind].top[1] and (#meter[kind].top > 1 or #meter[kind].top[1] > 1) then
            composites[kind].top = new_composite_top(meter[kind].top)
            if #meter[kind].bottom > 1 then
                composites[kind].bottom = new_composite_bottom(meter[kind].bottom)
            end
        end
    end

    local measures = finale.FCMeasures()
    measures:LoadRegion(region)
    for measure in each(measures) do
        local time_sig = measure:GetTimeSignature()
        fix_new_top(composites.main.top, time_sig, meter.main.top[1][1])
        fix_new_bottom(composites.main.bottom, time_sig, meter.main.bottom[1])

        if #meter.display.top > 0 then -- new DISPLAY meter
            measure.UseTimeSigForDisplay = true
            local display_sig = measure.TimeSignatureForDisplay
            if display_sig then
                fix_new_top(composites.display.top, display_sig, meter.display.top[1][1])
                fix_new_bottom(composites.display.bottom, display_sig, meter.display.bottom[1])
            end
        else
            measure.UseTimeSigForDisplay = false -- suppress display time_sig
        end
        measure:Save()
    end
    if config.note_spacing then
        local space_rgn = mixin.FCMMusicRegion()
        space_rgn:SetRegion(region):SetFullMeasureStack()
        space_rgn:SetInDocument()
        finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
        region:SetInDocument()
    end
end

create_new_meter()

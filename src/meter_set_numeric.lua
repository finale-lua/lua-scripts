function plugindef()
	finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.84"
    finaleplugin.Date = "2024/04/16"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[ 
        This script allows rapid creation of simple or complex 
        time signatures with a few keystrokes. 
        It supports composite numerators like [3+2+3/16] and joins easily 
        with extra composites (e.g. [3+2+3/16]+[1/4]+[5+4/8]). 
        __Display Only__ time signatures can be equally complex and set without mouse action.  

        At startup the time signature of the first selected measure is shown. 
        To revert to a simple 4/4 with no other options click the _Clear All_ button or type __x__. 
        To read these script notes click the __?__ button or type __q__. 
        To respace notes on completion click the _Respace_ button or type __r__.

        All measures in the current selection will be assigned the new time signature. 
        Use this feature to quickly copy the initial meter across the selection. 
        If just one measure is selected only it will be changed.

        __Bottom__ numbers (denominators) are the usual "note" numbers: 2, 4, 8, 16, 32, or 64. 
        __Top__ numbers (numerators) are integers, optionally joined by __+__ signs for composite meters. 
        Numerators that are multiples of 3 automatically convert to compound signatures 
        so [9/16] will register as three groups of dotted 8ths. 
        To prevent automatic compounding, instead of the bottom "note" number enter its 
        EDU value (quarter note = 1024; eighth note = 512; sixteenth = 256 etc).

        Empty and zero __Top__ numbers will be ignored. 
        __Tertiary__ values will be ignored if __Secondary__ numbers are blank or zero.
    ]]
	return "Meter Set Numeric...", "Meter Set Numeric", "Set the Meter Numerically"
end

--[[
    Data structure for composite Time Signatures:
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
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false -- set to true if utils.show_notes_dialog is used

local function refocus() -- utils.show_notes_dialog has been used?
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

local config = {
    note_spacing = true,
    window_pos_x = false,
    window_pos_y = false,
}
configuration.get_user_settings(script_name, config, true)

local function blank_meter()
    return { -- empty composite meter record
        main    = { top = {}, bottom = {} },
        display = { top = {}, bottom = {} }
    }
end

local function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function encode_current_meter(time_sig, sub_meter)
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

local function copy_meter_from_score(measure_number)
    local measure = finale.FCMeasure()
    measure:Load(measure_number)
    local meter = blank_meter()
    encode_current_meter(measure:GetTimeSignature(), meter.main)
    if measure.UseTimeSigForDisplay then
        encode_current_meter(measure.TimeSignatureForDisplay, meter.display)
    end
    return meter
end

local function is_power_of_two(num)
    local current = 1
    while current < num do
        current = current * 2
    end
    return current == num
end

local function convert_choices_to_meter(choices, meter)
    if choices[1] == "0" or choices[1] == "" or choices[4] == 0 then
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

local function user_chooses_meter(rgn)
    local x = { 0, 70, 130, 210, 280, 290 } -- horizontal grid
    local label = { -- data type descriptors and (range right) horizontal offset
        { "PRIMARY", 0}, -- name, horiz (left) offset
        { "(+ SECONDARY)", -37 },
        { "(+ TERTIARY)", -21 }
    }
    local y_middle = 118 -- window vertical mid-point
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local name = plugindef():gsub("%.%.%.", "") -- remove trailing dots
    local box, save_text = {}, {} -- user's edit-box entry responses
    local message = "m. " .. rgn.StartMeasure -- measure selection information
    if rgn.StartMeasure ~= rgn.EndMeasure then  -- multiple measures
        message = "m" .. message .. "-" .. rgn.EndMeasure
    end
    local respace_check -- pre-declare the "respace" checkbox

    local y = 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 500, 350)
            refocus_document = true
        end
        local function cstat(nx, ny, nwide, ntext, id)
            local dx = (type(nx) == "number") and x[nx] or tonumber(nx)
            return dialog:CreateStatic(dx, ny, id):SetWidth(nwide):SetText(ntext)
        end
        local function join(values) -- join integers from the meter.top array with '+' signs
            if not values or #values == 0 then return "0" end
            return table.concat(values, "+")
        end
        local function clear_entries()
            for j = 0, 6, 6 do
                for i = 1, 3 do
                    local n = (j == 0 and i == 1) and 4 or 0
                    box[j + i]:SetText(n)
                    box[j + i + 3]:SetInteger(n)
                    save_text[j + i] = n
                    save_text[j + i + 3] = n
                end
            end
            box[1]:SetKeyboardFocus()
        end
        local function key_check(id)
            local s = box[id]:GetText():lower()
            if s:find("[^0-9+]") then
                if s:find("x") then
                    clear_entries()
                else
                    if s:find("[?q]") then
                        show_info()
                    elseif s:find("r") then
                        local n = respace_check:GetCheck()
                        respace_check:SetCheck((n + 1) % 2)
                    end
                    box[id]:SetText(save_text[id])
                end
            elseif s ~= "" then
                save_text[id] = s -- save newly entered text
            end
        end
    cstat(1, y + 1, x[3], "TIME SIGNATURE", "main")
    cstat(3, y, x[3], "TOP")
    cstat(4, y, x[3], "BOTTOM")
    cstat(6, 25, 80, "Selection:")
    cstat(6, 40, 80, message)
    dialog:CreateButton(x[5], y):SetWidth(80):SetText("Clear All (x)")
        :AddHandleCommand(function() clear_entries() end)
    y = y_middle
    cstat(x[2] - 30, y - 30, 330, "'TOP' entries can include integers joined by '+' signs")
    dialog:CreateHorizontalLine(x[1], y - 9, x[5] + 50)
    dialog:CreateHorizontalLine(x[1], y - 8, x[5] + 50)
    cstat(1, y + 1, x[3], "DISPLAY SIGNATURE", "second")
    cstat(3, y, 150, "(set to '0' for none)")

    -- COMPOSITE TIME SIG BOXES
    local meter = copy_meter_from_score(rgn.StartMeasure)
    y = 0
    for jump = 0, 6, 6 do
        local t_sig = (jump == 0) and meter.main or meter.display
        for group = 1, 3 do
            y = y + 20
            local id = group + jump
            box[id] = dialog:CreateEdit(x[3], y - offset) -- numerator
                :SetText(join(t_sig.top[group])):SetWidth(65)
                :AddHandleCommand(function() key_check(id) end)
            save_text[id] = box[id]:GetText()
            box[id + 3] = dialog:CreateEdit(x[4], y - offset) -- matching denominator
                :SetInteger(t_sig.bottom[group] or 0):SetWidth(65)
                :AddHandleCommand(function() key_check(id + 3) end)
            cstat(x[2] + label[group][2], y, 56 - label[group][2], label[group][1])
            save_text[id + 3] = box[id + 3]:GetText()
        end
        y = y_middle
    end
    y = y + 60
    dialog:CreateButton(x[5] + 60, y, "q"):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    y = y + 25
    respace_check = dialog:CreateCheckbox(x[3], y):SetText("Respace notes on completion (r)")
        :SetCheck(config.note_spacing and 1 or 0):SetWidth(185)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local choices = {} -- convert edit box values to 12-element table
    dialog:RegisterInitWindow(function(self)
        box[1]:SetKeyboardFocus()
        local q = self:GetControl("q")
        local bold = q:CreateFontInfo():SetBold(true)
        q:SetFont(bold)
        self:GetControl("main"):SetFont(bold)
        self:GetControl("second"):SetFont(bold)
    end)
    local user_error = false
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        for count = 0, 6, 6 do -- "main" then "display" time_sig values
            for group = 1, 3 do
                local id = count + group
                choices[id] = box[id]:GetText() or "0"
                if choices[id] == "" then choices[id] = "0" end
                choices[id + 3] = box[id + 3]:GetInteger() or 0
            end
        end
        config.note_spacing = (respace_check:GetCheck() == 1)
        meter = blank_meter() -- start over with an empty meter
        local msg = convert_choices_to_meter(choices, meter)
        if msg ~= "" then -- entry error
            user_error = true
            finenv.UI():AlertInfo(msg, plugindef())
        end
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, user_error, meter
end

local function new_composite_top(sub_meter)
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

local function new_composite_bottom(sub_meter)
    local composite_bottom = finale.FCCompositeTimeSigBottom()
    for count = 1, 3 do
        if not sub_meter[count] or sub_meter[count] == 0 then break end
        local group = composite_bottom:AddGroup(1)
        composite_bottom:SetGroupElementBeatDuration(group, 0, sub_meter[count])
    end
    composite_bottom:SaveAll()
    return composite_bottom
end

local function fix_new_top(composite_top, time_sig, numerator)
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

local function fix_new_bottom(composite_bottom, time_sig, denominator)
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

local function create_new_meter()
    local region = mixin.FCMMusicRegion()
    region:SetRegion(finenv.Region()):SetStartMeasurePosLeft():SetEndMeasurePosRight()

    local ok, error, meter = true, true, {}
    while (ok and error) do -- re-entrant until no error
        ok, error, meter = user_chooses_meter(region)
    end
    if not ok then refocus() return end -- user cancelled
    local composites = {
        main =    { top = nil, bottom = nil},
        display = { top = nil, bottom = nil}
    }
    for _, kind in ipairs{"main", "display"} do
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
    refocus()
end

create_new_meter()

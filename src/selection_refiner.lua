function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.41"
    finaleplugin.Date = "2023/08/14"
    finaleplugin.CategoryTags = "Measures, Region, Selection"
    finaleplugin.MinJWLuaVersion = 0.67
    finaleplugin.Notes = [[
        The selected score area can be refined in Finale by measure and 
        either beat or EDU at "Edit" → "Select Region...". 
        This script offers a more organic option for precise positioning with 
        slider controls to change the beat and EDU position in each measure, 
        continuously updating the score highlighting as the selection changes.

        == BEAT BOUNDARIES ==

        The duration of a Finale quarter note is 1024 EDUs, 
        but to select all of of the first beat in a 4/4 measure the 
        selection must be from 0 to 1023 EDU, otherwise it will 
        include notes starting ON the second beat. 
        This "minus one" adjustment is applied to all END positions 
        relative to the beat, as happens when entering beat numbers 
        on the inbuilt "Select Region" option.

        Note that when one slider collides with the other in the same 
        measure, it will be pushed out of the way creating a "null" selection 
        (start = end). This doesn't break anything but creates a 
        selection containing no notes. 
    ]]
    return "Selection Refiner...", "Selection Refiner", "Refine the selected music area with visual feedback"
end

local config = { window_pos_x = false, window_pos_y = false }
local mixin = require("library.mixin")
local library = require("library.general_library")
local configuration = require("library.configuration")
local script_name = "selection_refiner"

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

function power_of_2(duration)
    local test_rest = finale.NOTE_128TH / 2 -- smallest duration = 256th note
    local power = 1
    while test_rest < duration and power < 10 do
        test_rest = test_rest * 2
        power = power + 1
    end
    return power -- 256th note = 1 ... breve = 10
end

function score_limits()
    local all_rgn = mixin.FCMMusicRegion()
    all_rgn:SetRegion(finenv.Region()):SetFullMeasureStack()
    local max_slot = all_rgn.EndSlot
    local m = finale.FCMeasures()
    m:LoadAll()
    local max_measure = m.Count
    return max_measure, max_slot
end

function compile_rest_strings(power)
    power = math.min(math.max(power, 1), 10) -- maximum exponent of 2 as "beat" rhythm
    -- non-SMuFL font characters first
    local rests = { "…", "Â", "Ù", "®", "≈", "‰", "Œ", "Ó", "∑", "„" } -- 256th to breve
    local array = { dot = "k", space = " ", gap = "  ", vert = 18 }
    if library.is_font_smufl_font() then -- SMuFL
        rests = {
            "\u{E4EB}", "\u{E4EA}", "\u{E4E9}", "\u{E4E8}", "\u{E4E7}",
            "\u{E4E6}", "\u{E4E5}", "\u{E4E4}", "\u{E4E3}", "\u{E4E2}"
        }
        array = { dot = "\u{E044}", space = "\u{E548}", gap = "\u{E548}\u{E548}", vert = 0 }
    end
    local p = power - 3           -- (divide beat duration by 8)
    array.div = { -- rest characters for each beat division
        rests[p], -- smallest
        rests[p + 1],
        rests[p + 1] .. array.space .. array.dot,
        rests[p + 2], -- "compound" rest values stop here
        rests[p + 2] .. array.space .. rests[p],
        rests[p + 2] .. array.space .. array.dot,
        rests[p + 2] .. array.space .. array.dot .. array.space .. array. dot
    }
    array.div[8] = rests[power]
    array.beat = rests[power] -- abbreviation
    return array
end

function get_measure_details(region, is_start_sector)
    local measure = finale.FCMeasure()
    measure:Load(is_start_sector and region.StartMeasure or region.EndMeasure)
    local time_sig = measure:GetTimeSignature()
    local md = { -- "Measure Details"
        dur = measure:GetDuration(),
        beats = time_sig.Beats,
        compound = false,
        beatdur = time_sig.BeatDuration,
        composite = time_sig.CompositeTop
    }
    if is_start_sector then
        md.measure = region.StartMeasure
        md.pos = region.StartMeasurePos
        md.slot = region.StartSlot
    else
        md.measure = region.EndMeasure
        md.pos = region.EndMeasurePos
        md.slot = region.EndSlot
    end
    md.pos = math.min(md.pos, md.dur) -- position <= measure duration
    if time_sig.CompositeBottom then -- use beat of first COMPOSITE group
        md.beatdur = time_sig:CreateCompositeBottom():GetGroupElementBeatDuration(0, 0)
    end
    if md.beatdur % 3 == 0 then
        md.compound = true -- compound meter
        md.mark = md.beatdur / 3 -- compound first-division marker 1/3rd of beat
        md.steps = 12 -- divisions per beat
    else
        md.mark = md.beatdur / 2 -- first-division marker = half of beat
        md.steps = 8 -- divisions per beat
    end
    local power = power_of_2(md.mark * 2) -- 2 ^ power exponent to index notehead durations
    md.div_dur = md.beatdur / md.steps -- duration of each division
    md.divisions = md.beats * md.steps -- total number of divisions
    if md.composite then
        md.divisions = md.dur / md.div_dur -- recalc across whole measure
        while md.divisions < 32 and md.div_dur >= 32 do
            -- get largest slider positions ("divisions") <= 64
            md.beats = md.beats * 2
            md.beatdur = md.beatdur / 2
            power = power - 1
            md.div_dur = md.div_dur / 2
            md.divisions = md.divisions * 2
        end
    end
    md.rests = compile_rest_strings(power)
    return md
end

function get_staff_name(region, slot)
    local staff_number = region:CalcStaffNumber(slot)
    local staff = finale.FCStaff()
    staff:Load(staff_number)
    return staff:CreateDisplayFullNameString()
end

function convert_position_to_rest(index, md, backwards)
    if backwards then index = md.divisions - index end
    local beat = md.rests.beat
    if md.compound then beat = beat .. md.rests.space .. md.rests.dot end

    local rest_string = ""
    for _ = 1, math.floor(index / md.steps) do
        rest_string = rest_string .. beat .. md.rests.gap
    end
    index = index % md.steps
    if md.compound then -- compound meter, beats divided by three then 4
        for _ = 1, math.floor(index / 4) do
            if backwards then
                rest_string = md.rests.div[4] .. md.rests.space .. rest_string
            else
                rest_string = rest_string .. md.rests.div[4] .. md.rests.space
            end
        end
        index = index % 4
    end
    if index > 0 then -- add remaining rest element
        if backwards then
            rest_string = md.rests.div[index] .. md.rests.space .. rest_string
        else
            rest_string = rest_string .. md.rests.div[index]
        end
    end
    return rest_string
end

function user_chooses(rgn)
    local y, rest_wide, x_wide =  40, 130, 236
    local x_offset = finenv.UI():IsOnMac() and 0 or 3
        local function yd(diff)
            y = diff and y + diff or y + 16
        end
    -- indicator and control arrays for "start" and "end":
    local measure, sliders, offset, rest, buttons, index, staff = {}, {}, {}, {}, {}, {}, {}
    local max_measure, max_slot = score_limits()

    -- MD :: MEASURE DETAILS
    local md = { get_measure_details(rgn, true), get_measure_details(rgn, false) } -- { start, end }
    index[1] = math.floor(md[1].pos * md[1].divisions / md[1].dur) -- convert POS to thumb index
    index[2] = math.floor(md[2].pos * md[2].divisions / md[2].dur)

    -- start dialog
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, y):SetText("START of Selection:"):SetWidth(x_wide)

    -- "rest" static texts go first because excess MUSIC font height overlaps other buttons
    local sys_finfo = finale.FCFontInfo()
    sys_finfo:LoadFontPrefs(finale.FONTPREF_MUSIC)
    rest[1] = dialog:CreateStatic(x_wide + 65, md[1].rests.vert):SetWidth(rest_wide):SetHeight(80)
        :SetFont(sys_finfo):SetText(convert_position_to_rest(index[1], md[1], false))
    rest[2] = dialog:CreateStatic(x_wide + 65, 83 + md[2].rests.vert):SetWidth(rest_wide):SetHeight(80)
        :SetFont(sys_finfo):SetText(convert_position_to_rest(index[2], md[2], false))

    -- "start" components
    measure[1] = dialog:CreateStatic(x_wide - 80, y):SetWidth(rest_wide)
        :SetText("m. " .. md[1].measure)
    staff[1] = dialog:CreateStatic(x_wide - 20, y):SetWidth(rest_wide)
        :SetText(get_staff_name(rgn, md[1].slot))
    dialog:CreateButton(x_wide + rest_wide + 30, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function()
            finenv.UI():AlertInfo(finaleplugin.Notes:gsub(" %s+", " "), "About " .. plugindef())
        end)
    yd()
    sliders[1] = dialog:CreateSlider(0, y):SetMinValue(0):SetMaxValue(md[1].divisions)
        :SetThumbPosition(index[1]):SetWidth(x_wide)
    offset[1] = dialog:CreateEdit(x_wide + 7, y - x_offset):SetInteger(md[1].pos):SetWidth(50)
    local button_x = (x_wide + rest_wide + 14) / 4
    local button_mid = button_x * 2 + 24
        local function make_buttons(i)
            buttons[i] = {
                up    = dialog:CreateButton(0, y):SetText("Staff ↑")
                    :SetWidth(button_x):SetEnable(md[i].slot > 1),
                down  = dialog:CreateButton(button_x + 12, y):SetText("Staff ↓")
                    :SetWidth(button_x):SetEnable(md[i].slot < max_slot),
                left  = dialog:CreateButton(button_mid, y):SetText("← Measure")
                    :SetWidth(button_x):SetEnable(md[i].measure > 1),
                right = dialog:CreateButton(button_mid + button_x + 12, y):SetText("Measure →")
                    :SetWidth(button_x):SetEnable(md[i].measure < max_measure)
            }
        end
    yd(29) -- (total y-offset here is 85)
    make_buttons(1)
    yd(32)
    dialog:CreateHorizontalLine(0, y, button_x * 4)
    yd(10)
    -- "end" components
    dialog:CreateStatic(0, y):SetText("END of Selection:"):SetWidth(x_wide)
    measure[2] = dialog:CreateStatic(x_wide - 80, y):SetWidth(60)
        :SetText("m. " .. md[2].measure)
    staff[2] = dialog:CreateStatic(x_wide - 20, y):SetWidth(rest_wide)
        :SetText(get_staff_name(rgn, md[2].slot))
    yd()
    sliders[2] = dialog:CreateSlider(0, y):SetMinValue(0):SetMaxValue(md[2].divisions)
        :SetThumbPosition(index[2]):SetWidth(x_wide)
    offset[2] = dialog:CreateEdit(x_wide + 7, y - x_offset):SetWidth(50):SetInteger(md[2].pos)
    yd(29)
    make_buttons(2)

        -- local functions
        local function set_measure_pos(side)
            if side == 1 then rgn.StartMeasurePos = md[side].pos
            else rgn.EndMeasurePos = md[side].pos
            end
        end
        local function set_rest_and_offset(side, thumb)
            rest[side]:SetText(convert_position_to_rest(thumb, md[side], false))
            local edu = thumb * md[side].div_dur
            if side == 2 and edu > 0 and edu < md[2].dur and edu > offset[1]:GetInteger() then
                edu = edu - 1
            end
            md[side].pos = edu
            set_measure_pos(side)
            offset[side]:SetInteger(edu)
        end
        local function set_indicators(side)
            local thumb = math.floor(md[side].pos * md[side].divisions / md[side].dur)
            sliders[side]:SetMaxValue(md[side].divisions):SetThumbPosition(thumb)
            rest[side]:SetText(convert_position_to_rest(thumb, md[side], false))
            offset[side]:SetInteger(md[side].pos)
            measure[side]:SetText("m. " .. md[side].measure)
        end
        local function swap_pos()
            local save_pos = md[1].pos
            md[1].pos = md[2].pos
            md[2].pos = save_pos
            set_measure_pos(1)
            set_measure_pos(2)
        end
        local function clamp_measure_pos(side)
            md[side] = get_measure_details(rgn, (side == 1))
            if md[side].pos > md[side].dur then
                md[side].pos = md[side].dur
                set_measure_pos(side)
            end
            set_indicators(side)
        end
        local function measure_button_visibility(clamp_side)
            for side = 1, 2 do
                buttons[side].left:SetEnable(md[side].measure > 1)
                buttons[side].right:SetEnable(md[side].measure < max_measure)
            end
            clamp_measure_pos(clamp_side)
            rgn:SetInDocument()
            rgn:Redraw()
        end
        local function staff_button_visibility()
            for side = 1, 2 do
                buttons[side].up:SetEnable(md[side].slot > 1)
                buttons[side].down:SetEnable(md[side].slot < max_slot)
                staff[side]:SetText(get_staff_name(rgn, md[side].slot))
            end
            rgn:SetInDocument()
            rgn:Redraw()
        end
    dialog:CreateOkButton()
    dialog:CreateCancelButton()

    -- ACTION HANDLERS for selector buttons, duplicated on START [1] and END [2] sides
    for side = 1, 2 do
        local other_side = (side % 2) + 1
        -- MEASURE POSITION SLIDERS
        sliders[side]:AddHandleCommand(function()
            local thumb = sliders[side]:GetThumbPosition()
            set_rest_and_offset(side, thumb)
            if (rgn.StartMeasure == rgn.EndMeasure) then -- start and end in same measure
                local other_thumb = sliders[other_side]:GetThumbPosition()
                if side == 1 then
                    if thumb > other_thumb or md[1].pos > md[2].pos then
                        if thumb <= md[2].divisions then other_thumb = thumb end
                        set_rest_and_offset(2, other_thumb)
                        sliders[2]:SetThumbPosition(other_thumb)
                    end
                else -- side 2
                    if thumb < other_thumb or md[2].pos < md[1].pos then
                        if thumb > 0 then other_thumb = thumb end
                        set_rest_and_offset(1, other_thumb)
                        sliders[1]:SetThumbPosition(other_thumb)
                    end
                end
            end
            rgn:SetInDocument()
            rgn:Redraw()
        end)
        -- STAFF UP
        buttons[side].up:AddHandleCommand(function()
            if md[side].slot > 1 then
                md[side].slot = md[side].slot - 1
                if side == 1 then
                    rgn.StartSlot = md[1].slot
                else -- side 2
                    rgn.EndSlot = md[2].slot
                    if md[1].slot > md[2].slot  then
                        md[1].slot = md[2].slot
                        rgn.StartSlot = md[2].slot
                    end
                end
                staff_button_visibility()
            end
        end)
        -- STAFF DOWN
        buttons[side].down:AddHandleCommand(function()
            if md[side].slot < max_slot then
                md[side].slot = md[side].slot + 1
                if side == 1 then
                    rgn.StartSlot = md[1].slot
                    if md[2].slot < md[1].slot  then
                        md[2].slot = md[1].slot
                        rgn.EndSlot = md[1].slot
                    end
                else
                    rgn.EndSlot = md[2].slot
                end
                staff_button_visibility()
            end
        end)
        -- MEASURE LEFT
        buttons[side].left:AddHandleCommand(function()
            if md[side].measure > 1 then
                md[side].measure = md[side].measure - 1
                md[side].pos = offset[side]:GetInteger()
                md[other_side].pos = offset[other_side]:GetInteger()
                if side == 1 then
                    rgn.StartMeasure = md[1].measure
                else -- side 2
                    rgn.EndMeasure = md[2].measure
                    if md[2].measure < md[1].measure then -- also shift the start to the left
                        md[1].measure = md[2].measure
                        rgn.StartMeasure = md[1].measure
                        clamp_measure_pos(1)
                    end
                    if md[1].measure == md[2].measure and md[2].pos < md[1].pos then
                        swap_pos()
                        set_indicators(1)
                    end
                end
                measure_button_visibility(side)
            end
        end)
        -- MEASURE RIGHT
        buttons[side].right:AddHandleCommand(function()
            if md[side].measure < max_measure then
                md[side].measure = md[side].measure + 1
                md[side].pos = offset[side]:GetInteger()
                md[other_side].pos = offset[other_side]:GetInteger()
                if side == 1 then
                    rgn.StartMeasure = md[1].measure
                    if md[1].measure > md[2].measure then -- also shift the end to the right
                        md[2].measure = md[1].measure
                        rgn.EndMeasure = md[2].measure
                        clamp_measure_pos(2)
                    end
                    if md[1].measure == md[2].measure and md[1].pos > md[2].pos then
                        swap_pos()
                        set_indicators(2)
                    end
                else -- side 2
                    rgn.EndMeasure = md[2].measure
                end
                measure_button_visibility(side)
            end
        end)
        -- TEXT OFFSET ADJUSTMENTS
        offset[side]:AddHandleCommand(function()
            local n = offset[side]:GetInteger()
            n = math.min(math.max(n, 0), md[side].dur) -- 0 <= n <= measure_duration
            offset[side]:SetInteger(n)
            md[side].pos = n
            set_indicators(side)
            set_measure_pos(side)
            rgn:SetInDocument()
            rgn:Redraw()
        end)
    end
    dialog_set_position(dialog)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function refine_selection()
    configuration.get_user_settings(script_name, config)
    local rgn = mixin.FCMMusicRegion()
    rgn:SetRegion(finenv.Region())
    if not user_chooses(rgn) then -- cancelled, so restore original selection
        rgn:SetRegion(finenv.Region())
    end
    rgn:SetInDocument() -- otherwise set new selection
end

refine_selection()

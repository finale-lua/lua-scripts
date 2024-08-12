function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.95b"
    finaleplugin.Date = "2024/07/29"
    finaleplugin.CategoryTags = "Measure, Time Signature, Meter"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.AdditionalMenuOptions = [[
        Measure Span Join
        Measure Span Divide
    ]]
    finaleplugin.AdditionalUndoText = [[
        Measure Span Join
        Measure Span Divide
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Join pairs of measures together by consolidating their time signatures
        Divide single measures into two by altering the time signature
    ]]
    finaleplugin.AdditionalPrefixes = [[
        span_action = "join"
        span_action = "divide"
    ]]
    finaleplugin.ScriptGroupName = "Measure Span"
    finaleplugin.ScriptGroupDescription = "Divide single measures or join measure pairs by changing time signatures"
    finaleplugin.Notes = [[
        Select any number of measures and this script changes their "span" by 
        manipulating the time signatures, either dividing each one into two or combining 
        pairs of measures together. 
        
        __Join__  
        Combine each pair of measures in the selection by combining their time signatures. 
        If they have the same time signature either double the numerator ([3/4][3/4] → [6/4]) or 
        halve the denominator ([3/4][3/4] → [3/2]). If the time signatures are different, choose to either 
        _Composite_ them ([2/4][3/8] → [2/4 + 3/8]) or _Consolidate_ them ([2/4][3/8] → [7/8]). 
        (Consolidation loses current beam groupings). You can choose that a consolidated "display" 
        time signature is created automatically when compositing meters. 
        _Join_ only works on an even number of measures. 
        
        __Divide__  
        Divide every selected measure into two, changing the time signature by either halving the 
        numerator ([6/4] → [3/4][3/4]) or doubling the denominator ([6/4] → [6/8][6/8]). 
        If the measure has an odd number of beats, choose whether to put more beats in the first 
        measure (5→3+2) or the second (5→2+3). Measures containing composite meters will be divided 
        after the first composite group, or if there is only one group, after its first element. 
        
        __In All Cases__  
        Incomplete measures will be filled with rests before __Join__ or __Divide__. Measures containing 
        too many notes will be trimmed to the "real" duration of the time signature. 
        __Display only__ time signatures  are erased. 
        Measures are either deleted or shifted in every operation so smart shapes 
        spanning the selected music need to be "restored". 
        Selecting a __Span__ of __5__ will look for smart shapes to restore from 5 
        measures before until 5 after the selected region. 
        (This takes noticeably longer than a __Span__ of __2__). 
        
        __Options__  
        To configure script settings select the _Measure Span Options..._ menu 
        or hold down [Shift] when using __Join__ or __Divide__.
    ]]
    return "Measure Span Options...",
        "Measure Span Options",
        "Change the default behaviour of the Measure Span script"
end

span_action = span_action or "options"

local config = {
    halve_numerator =   true, -- halve the numerator on DIVIDE otherwise double the denominator
    odd_more_first  =   true, -- if dividing odd beats, more beats in FIRST measure (otherwise in the second)
    double_join     =   true, -- double the numerator on JOIN (otherwise halve the denominator)
    composite_join  =   true, -- JOIN measure by COMPOSITING two unequal time signatures (otherwise CONSOLIDATE them)
    note_spacing    =   true, -- implement note spacing after each operation
    repaginate      =   false, -- repaginate after each operation
    rebeam          =   false, -- whether to rebeam on completion
    display_meter   =   true, -- create a composite "display" time signature with composite joins
    shape_extend    =   4,    -- how many measures either side of the selection to span for smart shapes
    window_pos_x    =   false, -- saved dialog window position
    window_pos_y    =   false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false -- set to true if utils.show_notes_dialog is used

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

local function user_options()
    local x_grid = { 15, 70, 193, 210, 305, 110 }
    local i_width = 138
    local y = 0

    local dlg = mixin.FCXCustomLuaWindow():SetTitle(finaleplugin.ScriptGroupName)
        local function yd(diff)
            diff = diff or 15 -- average horizontal line shift
            y = y + diff
        end
        local function cstat(cx, cy, ctext, cwide, chigh, cname)
            cx = (type(cx) == "string") and tonumber(cx) or x_grid[cx]
            local stat = dlg:CreateStatic(cx, cy, cname):SetText(ctext)
            if cwide then stat:SetWidth(cwide) end
            if chigh then stat:SetHeight(chigh) end
        end
        local function ccheck(cx, cy, cname, cwide, check, ctext, chigh)
            cx = (type(cx) == "string") and tonumber(cx) or x_grid[cx]
            local chk = dlg:CreateCheckbox(cx, cy, cname):SetWidth(cwide)
                :SetText(ctext):SetCheck(check)
            if chigh then chk:SetHeight(chigh) end
        end
        local function chl(cx, cy, cwide)
            dlg:CreateHorizontalLine(cx, cy, cwide)
        end

    cstat("0", y + 1, "DIVIDE", 50, nil, "div1")
    cstat("43", y + 1, "Every Measure Into Two:", x_grid[3], nil, nil)
    yd(20)
    cstat(1, y, "Halve the Numerator:", x_grid[3])
    ccheck(3, y, "1", i_width, (config.halve_numerator and 1 or 0), " [6/4] → [3/4][3/4]")
    yd()
    cstat(2, y, "OR")
    yd()
    cstat(1, y, "Double the Denominator:", x_grid[3])
    ccheck(3, y, "2", i_width, (config.halve_numerator and 0 or 1), " [6/4] → [6/8][6/8]")
    yd(25)
    chl(1, y, x_grid[5])
    yd(10)
    cstat(1, y, "If Halving a Numerator With an Odd Number of Beats:", x_grid[5])
    yd(17)
    cstat(1, y, "More Beats in First Measure:", x_grid[4] + 20)
    ccheck(3, y, "3", i_width, (config.odd_more_first and 1 or 0), " 3 → 2 + 1 etc.")
    yd()
    cstat(2, y, "OR")
    yd()
    cstat(1, y, "More Beats in Second Measure:", x_grid[4] + 20)
    ccheck(3, y, "4", i_width, (config.odd_more_first and 0 or 1), " 3 → 1 + 2 etc.")
    yd(27)
    chl(0, y, x_grid[3] + i_width)
    chl(0, y + 2, x_grid[3] + i_width)
    chl(0, y + 3, x_grid[3] + i_width)
    yd(13)
    cstat("0", y + 1, "JOIN", 35, nil, "div2")
    cstat("33", y + 1, "Each Pair of Measures:", x_grid[3])
    yd(20)
    cstat(1, y, "If Both Measures Have the Same Time Signature:", x_grid[5])
    yd(17)
    cstat("30", y, "Halve the Denominator:", x_grid[3])
    ccheck(3, y, "6", i_width, (config.double_join and 0 or 1), " [6/8][6/8] → [6/4]")
    yd()
    cstat("85", y, "OR")
    yd()
    cstat("30", y, "Double the Numerator:", x_grid[3])
    ccheck(3, y, "5", i_width, (config.double_join and 1 or 0), " [6/8][6/8] → [12/8]")
    yd(25)
    chl(1, y, x_grid[5])
    yd(5)
    cstat(1, y, "Else if They Have Different Time Signatures:", x_grid[5])
    yd(17)
    cstat("30", y, "Consolidate Time Signatures:", x_grid[4])
    ccheck(3, y, "8", i_width, (config.composite_join and 0 or 1),
        " [2/4][3/8] → [7/8]\n (Lose Beam Groups)", 30)
    yd(17)
    cstat("85", y, "OR")
    yd(17)
    cstat("30", y, "Composite Time Signatures:", x_grid[3])
    ccheck(3, y, "7", i_width, (config.composite_join and 1 or 0),
        " [2/4][3/8] → [2/4+3/8]\n (Keep Beam Groups)", 30)
    yd(35)
    ccheck("30", y, "display_meter", x_grid[5] + 10, (config.display_meter and 1 or 0),
        " Create \"Display\" Time Signature When Compositing\n "
        .. "   ([2/4][3/8] → [2/4+3/8] Displaying \"7/8\")", 32
    )
    yd(36)
    chl(0, y, x_grid[3] + i_width)
    chl(0, y + 2, x_grid[3] + i_width)
    chl(0, y + 3, x_grid[3] + i_width)
    yd(12)
    cstat("0", y, "Preserve Smart Shapes Within\n(Larger Spans Take Longer)", x_grid[3], 32)
    local popup = dlg:CreatePopup(x_grid[3] - 27, y - 1, "shape_extend")
        :SetWidth(40):SetSelectedItem(config.shape_extend - 2)
    for i = 2, 10 do
        popup:AddString(i)
    end
    cstat("204", y, "- Measure Span")
    yd(38)
    cstat("0", y, "ON COMPLETION:", i_width, nil, "div3")
    ccheck(6, y, "note_spacing", i_width, (config.note_spacing and 1 or 0), "Respace Notes")
    dlg:CreateButton(x_grid[5], y, "q"):SetText("?"):SetWidth(20)
        :AddHandleCommand(function()
            utils.show_notes_dialog(dlg, "About " .. finaleplugin.ScriptGroupName)
            refocus_document = true
        end)
    yd(18)
    ccheck(6, y, "rebeam", i_width + 20, (config.rebeam and 1 or 0), "Rebeam Note Groups")
    yd(18)
    ccheck(6, y, "repaginate", i_width + 20, (config.repaginate and 1 or 0), "Repaginate Entire Score")

    -- radio button action
    local function radio_change(id, check) -- for checkboxes "1" to "8"
        local toggle = (id % 2 == 0) and (id - 1) or (id + 1)
        dlg:GetControl(tostring(toggle)):SetCheck((check + 1) % 2) -- "ON" <-> "OFF"
        if id > 6 then
            local state = check == ((id == 7) and 1 or 0)
            dlg:GetControl("display_meter"):SetEnable(state)
        end
    end
    for id = 1, 8 do -- add to HandleCommand to 8 buttons
        dlg:GetControl(tostring(id))
            :AddHandleCommand(function(self) radio_change(id, self:GetCheck()) end)
    end
    dlg:CreateOkButton():SetText("Save")
    dlg:CreateCancelButton()
    dialog_set_position(dlg)
    dlg:RegisterHandleOkButtonPressed(function(self)
        for k, v in pairs{
                halve_numerator = "1", odd_more_first = "3",
                double_join =     "5", composite_join = "7"
            } do
            config[k] = (self:GetControl(v):GetCheck() == 1)
        end
        for _, v in ipairs{"display_meter", "note_spacing", "repaginate", "rebeam"} do
            config[v] = (self:GetControl(v):GetCheck() == 1)
        end
        config.shape_extend = (self:GetControl("shape_extend"):GetSelectedItem() + 2)
    end)
    dlg:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dlg:RegisterInitWindow(function(self)
        local bold = self:GetControl("div1"):CreateFontInfo():SetBold(true)
        for _, v in ipairs{"div1", "div2", "div3", "q"} do
            dlg:GetControl(v):SetFont(bold)
        end
        self:GetControl("display_meter"):SetEnable(config.composite_join)
    end)
    return (dlg:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function repaginate()
    local gen_prefs = finale.FCGeneralPrefs()
    gen_prefs:LoadFirst()
    local saved = {}
    local replace_values = {
        RecalcMeasures = true,
        RespaceMeasureLayout = false,
        RetainFrozenMeasures = true
    }
    for k, v in pairs(replace_values) do
        saved[k] = gen_prefs[k] -- save old values
        gen_prefs[k] = v -- replace with values for repagination
    end
    gen_prefs:Save()

    local all_pages = finale.FCPages()
    all_pages:LoadAll()
    for page in each(all_pages) do
        page:UpdateLayout(false)
        page:Save()
    end
    for k, _ in pairs(replace_values) do
        gen_prefs[k] = saved[k] -- restore old values
    end
    gen_prefs:Save()
end

function copy_measure_values(measure_1, measure_2)
    for _, v in ipairs{ "PositioningNotesMode", "Barline",
        "SpaceAfter", "SpaceBefore", "UseTimeSigForDisplay" } do
            measure_2[v] = measure_1[v]
    end
    measure_1.Barline = finale.BARLINE_NORMAL
    measure_1.SpaceAfter = 0
    measure_1:Save()
    measure_2:Save()
end

local function pad_or_truncate_cells(region, measure_num, measure_duration, check_measure)
    local cell_rgn = mixin.FCMMusicRegion()
    cell_rgn:SetRegion(region)
        :SetStartMeasure(measure_num):SetEndMeasure(measure_num) -- one measure wide
    for staff in eachstaff(region) do
        cell_rgn:SetStartStaff(staff):SetEndStaff(staff)
        for layer_num = 1, layer.max_layers() do
            local check_required = false
            if check_measure > 0 then
                local check_layer = finale.FCNoteEntryLayer(layer_num - 1, staff, measure_num, check_measure)
                check_layer:Load()
                if check_layer.Count > 0 then check_required = true end
            end
            local entry_layer = finale.FCNoteEntryLayer(layer_num - 1, staff, measure_num, measure_num)
            entry_layer:Load()
            if entry_layer.Count > 0 or check_required then -- layer contains (or needs) some notes
                local layer_duration = entry_layer:CalcFrameDuration(measure_num)
                if layer_duration > measure_duration then -- TRUNCATE
                    -- crop entry lengths
                    for entry in eachentrysaved(cell_rgn, layer_num) do
                        if entry.MeasurePos >= measure_duration then -- entry starts beyond the barline
                            entry.Duration = 0 -- so delete it
                        elseif (entry.MeasurePos + entry.ActualDuration) > measure_duration then
                            entry.Duration = measure_duration - entry.MeasurePos -- shorten the entry to fit
                            -- NOTE: spurious result if last valid note is within a tuplet
                        end
                    end
                elseif layer_duration < measure_duration then -- insert rest PADDING
                    local last_note = entry_layer:GetItemAt(entry_layer.Count - 1)
                    local newentry = entry_layer:InsertEntriesAfter(last_note, 1, false)
                    if newentry ~= nil then
                        newentry:MakeRest()
                        newentry.Duration = measure_duration - layer_duration
                        newentry.Legality = true
                        newentry.Visible = true
                        entry_layer:Save()
                    end
                end
            end
        end
    end
end

--[[ STRUCTURE OF COMPOSITE TIME SIGNATURE TABLES:
    composite_array = {
        top = {
            comp = FCCompositeTimeSigTop,
            groups = { 
                { element_1, element_2, element_3... }, -- group_1
                { element_1, element_2, element_3... }, -- group_2
                { etc... }, -- etc.
            },
            count = number_of_groups,
        }
        bottom = {
            comp = FCCompositeTimeSigBotom,
            groups = { bottom_1, bottom_2, bottom_3, ... },
            count = number_of_groups
        }
    }
]]

local function clear_composite(time_sig, top, bottom)
    if time_sig.CompositeTop and top > 0 then
        time_sig:RemoveCompositeTop(top)
    end
    if time_sig.CompositeBottom and bottom > 0 then
        time_sig:RemoveCompositeBottom(bottom)
    end
end

local function extract_composite_to_array(time_sig)
    local comp_array = {}
    if time_sig.CompositeTop then
        comp_array.top = { comp = time_sig:CreateCompositeTop(), count = 0, groups = { } }
        comp_array.bottom = { count = 0, groups = { } }
        comp_array.top.count = comp_array.top.comp:GetGroupCount()
        if time_sig.CompositeBottom then
            comp_array.bottom.comp = time_sig:CreateCompositeBottom()
            comp_array.bottom.count = comp_array.bottom.comp:GetGroupCount()
        end
        for group = 0, (comp_array.top.count - 1) do
            comp_array.top.groups[group + 1] = {}
            for i = 0, (comp_array.top.comp:GetGroupElementCount(group) - 1) do
                table.insert(comp_array.top.groups[group + 1], comp_array.top.comp:GetGroupElementBeats(group, i))
            end
            if comp_array.bottom.count > 0 then
                table.insert(comp_array.bottom.groups, comp_array.bottom.comp:GetGroupElementBeatDuration(group, 0))
            end
        end
    end
    return comp_array
end

local function flatten_comp_numerators(comp)
    local small_denom = finale.BREVE -- find smallest denominator in the composite
    for group = 1, #comp.bottom.groups do
        local dur = comp.bottom.groups[group]
        if dur % 3 == 0 then dur = dur / 3 end -- remove compound multiplier
        if dur < small_denom then
            small_denom = dur
        end
    end
    local total_top = 0 -- add numerators over the smallest denominator
    for group = 1, #comp.top.groups do
        for el = 1, #comp.top.groups[group] do
            total_top = total_top + (comp.top.groups[group][el] * comp.bottom.groups[group] / small_denom)
        end
    end
    return total_top, small_denom
end

local function make_display_meter(fc_measure, comp)
    if config.display_meter then -- only if requested
        fc_measure.UseTimeSigForDisplay = true
        local display_sig = fc_measure:GetTimeSignatureForDisplay()
        if display_sig then
            display_sig.Beats, display_sig.BeatDuration = flatten_comp_numerators(comp)
        end
    end
end

local function new_composite_top(time_sig, group_array, first, last, from_element)
    if last == 0 then last = #group_array end
    local comp_top = finale.FCCompositeTimeSigTop()
    for g = first, last do
        local group = comp_top:AddGroup(#group_array[g] - from_element + 1)
        for i = from_element, #group_array[g] do
            comp_top:SetGroupElementBeats(group, i - from_element, group_array[g][i])
        end
    end
    comp_top:SaveAll()
    time_sig:RemoveCompositeTop(1)
    time_sig:SaveNewCompositeTop(comp_top)
end

local function new_composite_bottom(time_sig, group_array, first, last)
    if last == 0 then last = #group_array end
    local comp_bottom = finale.FCCompositeTimeSigBottom()
    for g = first, last do
        local group = comp_bottom:AddGroup(1)
        comp_bottom:SetGroupElementBeatDuration(group, 0, group_array[g])
    end
    comp_bottom:SaveAll()
    time_sig:RemoveCompositeBottom(finale.QUARTER_NOTE)
    time_sig:SaveNewCompositeBottom(comp_bottom)
end

local function measure_extend_count(measure_num)
    local measures = finale.FCMeasures()
    measures:LoadAll()
    return math.max(measures.Count, (measure_num + config.shape_extend))
end

local function shift_divided_measure_shapes(rgn, measure_num, new_duration)
    local extend_rgn = mixin.FCMMusicRegion()
    extend_rgn:SetRegion(rgn)
        :SetStartMeasure(measure_num - config.shape_extend)
        :SetEndMeasure(measure_extend_count(measure_num))
    for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), extend_rgn) do
        local shape = mark:CreateSmartShape()
        if shape and not shape.EntryBased then
            local seg = { L = shape:GetTerminateSegmentLeft(), R = shape:GetTerminateSegmentRight() }
            local m = { L = seg.L.Measure, R = seg.R.Measure }
            if m.L <= measure_num then -- only affect shapes that straddle the inserted measure
                local save_new = false
                if m.R > measure_num then
                    seg.R.Measure = m.R + 1 -- crosses measure boundary
                    save_new = true
                end
                for _, i in ipairs{"L", "R"} do
                    if m[i] == measure_num and seg[i].MeasurePos >= new_duration then
                        seg[i].Measure = m[i] + 1
                        seg[i].MeasurePos = seg[i].MeasurePos - new_duration
                        save_new = true
                    end
                end
                if save_new then
                    local save_id = shape.ItemNo
                    shape:SaveNewEverything(nil, nil)
                    shape:Load(save_id) -- delete the original non-"fixed" version
                    shape:DeleteData()
                end
            end
        end
    end
end

local function shift_divided_measure_expressions(measure_num, old_width, dur_1, dur_2)
    local exps = finale.FCExpressions()
    exps:LoadAllForItem(measure_num)
    for exp in eachbackwards(exps) do
        if exp.StaffGroupID > 0 then -- has staff list
            local save_new = false
            if exp.MeasurePos > 0 then -- attached to beat
                if exp.MeasurePos >= dur_1 then
                    exp.MeasurePos = exp.MeasurePos - dur_1
                    save_new = true
                end
            elseif exp.HorizontalPos > 0 then -- attached to start of measure
                -- GUESSTIMATE of horizontal division between the split measures
                local divider = (old_width * dur_1 / (dur_1 + dur_2)) * 1.1
                if exp.HorizontalPos > divider then
                    exp.HorizontalPos = exp.HorizontalPos - math.floor(divider)
                    save_new = true
                end
            end
            if save_new then
                local save_cmper, save_inci = exp.ItemCmper, exp.ItemInci
                exp:SaveNewToCell(finale.FCCell(measure_num + 1, exp.Staff))
                local old_exp = finale.FCExpression()
                old_exp:Load(save_cmper, save_inci)
                if old_exp then old_exp:DeleteData() end
            end
        end
    end
end

local function divide_measures(selection)
    local pair_rgn = mixin.FCMMusicRegion()
    pair_rgn:SetRegion(selection):SetFullMeasureStack()

    for measure_num = selection.EndMeasure, selection.StartMeasure, -1 do
        pair_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num):SetFullMeasureStack()
        local measure = { mixin.FCMMeasure(), mixin.FCMMeasure() }
        measure[1]:Load(measure_num)
        measure[1].UseTimeSigForDisplay = false -- no longer relevant
        local old_width = measure[1]:GetWidth()
        finale.FCMeasures.Insert(measure_num + 1, 1, false)
        measure[2]:Load(measure_num + 1)
        copy_measure_values(measure[1], measure[2])

        local time_sig = { measure[1]:GetTimeSignature(), measure[2]:GetTimeSignature() }
        local top = { time_sig[1].Beats, time_sig[1].Beats }
        local bottom = time_sig[1].BeatDuration
        pad_or_truncate_cells(pair_rgn, measure_num, measure[1]:GetDuration(), 0)

        if time_sig[1].CompositeTop then
            -- COMPOSITE METER
            local comp_array = extract_composite_to_array(time_sig[1])
            if comp_array.top.count == 1 then -- a single composite group - just divide into two
                clear_composite(time_sig[1], comp_array.top.groups[1][1], comp_array.bottom.groups[1])
                if #comp_array.top.groups[1] == 2 then
                    clear_composite(time_sig[2], comp_array.top.groups[1][2], comp_array.bottom.groups[1])
                else -- more than 2 TOP elements, so keep second composite meter
                    new_composite_top(time_sig[2], comp_array.top.groups, 1, 1, 2)
                end
            else            -- COMPOSITE has two or more groups
                --= GROUP 1 =--
                if #comp_array.top.groups[1] == 1 then -- group contains one element?
                    clear_composite(time_sig[1], comp_array.top.groups[1][1], comp_array.bottom.groups[1])
                else
                    new_composite_top(time_sig[1], comp_array.top.groups, 1, 1, 1)
                    time_sig[1]:RemoveCompositeBottom(comp_array.bottom.groups[1])
                end
                --= GROUPS 2+ =--
                if comp_array.top.count == 2 and #comp_array.top.groups[2] == 1 then -- second group has one element
                    clear_composite(time_sig[2], comp_array.top.groups[2][1], comp_array.bottom.groups[2])
                else -- copy groups 2+ to top and bottom
                    new_composite_top(time_sig[2], comp_array.top.groups, 2, 0, 1)
                    new_composite_bottom(time_sig[2], comp_array.bottom.groups, 2, 0)
                end
            end
        else  -- NON-COMPOSITE METER
            if config.halve_numerator then -- HALVE the numerator
                if top[1] == 1 then
                    if bottom % 3 == 0 then
                        bottom = bottom / 3 -- revert to non-compound meter
                        top[1] = config.odd_more_first and 2 or 1
                        top[2] = 3 - top[1]
                    else
                        top[2] = 1 -- no other option but to DOUBLE the denominator
                        bottom = bottom / 2
                    end
                else
                    top[1] = top[1] / 2
                    if (time_sig[1].Beats % 2) ~= 0 then -- ODD number of beats
                        top[1] = math.floor(top[1])
                        if config.odd_more_first then top[1] = top[1] + 1 end
                    end
                    top[2] = time_sig[1].Beats - top[1]
                end
            else -- "DOUBLE" the denominator
                bottom = bottom / 2
            end
            time_sig[1]:SetBeats(top[1]):SetBeatDuration(bottom)
            time_sig[2]:SetBeats(top[2]):SetBeatDuration(bottom)
        end
        measure[1]:Save()
        measure[2]:Save()
        local dur_1 = measure[1]:GetDuration()
        shift_divided_measure_shapes(pair_rgn, measure_num, dur_1)
        pair_rgn:SetEndMeasure(measure_num + 1):RebarMusic(finale.REBARSTOP_REGIONEND, config.rebeam, false)
        shift_divided_measure_expressions(measure_num, old_width, dur_1, measure[2]:GetDuration())
    end
end

local function compress_smart_shape_ends(rgn, measure_num, measure_duration)
    local extend_rgn = mixin.FCMMusicRegion()
    extend_rgn:SetRegion(rgn)
        :SetStartMeasure(measure_num - config.shape_extend)
        :SetEndMeasure(measure_extend_count(measure_num + 2))
    for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), extend_rgn) do
        local shape = mark:CreateSmartShape()
        if shape and not shape.EntryBased then
            local seg_L, seg_R = shape:GetTerminateSegmentLeft(), shape:GetTerminateSegmentRight()
            local m_L,   m_R   = seg_L.Measure, seg_R.Measure
            if m_L == measure_num + 1 then
                seg_L.Measure = m_L - 1
                seg_L.MeasurePos = seg_L.MeasurePos + measure_duration
            end
            if m_R == measure_num + 1 then
                seg_R.Measure = m_R - 1
                seg_R.MeasurePos = seg_R.MeasurePos + measure_duration
            end
            shape:Save()
        end
    end
end

local function save_shapes_for_joining(rgn, measure_num)
    local shapes = {}
    local extend_rgn = mixin.FCMMusicRegion()
    extend_rgn:SetRegion(rgn)
        :SetStartMeasure(measure_num - config.shape_extend)
        :SetEndMeasure(measure_extend_count(measure_num + 2))

    for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), extend_rgn) do
        local shape = mark:CreateSmartShape()
        if shape and not shape.EntryBased then
            local seg_L, seg_R = shape:GetTerminateSegmentLeft(), shape:GetTerminateSegmentRight()
            local m_L,   m_R   = seg_L.Measure, seg_R.Measure
            if m_L <= measure_num + 2 and m_R > measure_num then
                table.insert(shapes, { shape.ItemNo, m_L, m_R, seg_L.MeasurePos, seg_R.MeasurePos })
            end
        end
    end
    return shapes
end

local function restore_joined_shapes(shapes, measure_num, dur)
    local shape = finale.FCSmartShape()
    for _, v in ipairs(shapes) do
        shape:Load(v[1])
        local seg_L = shape:GetTerminateSegmentLeft()
        if v[2] == measure_num + 1 then seg_L.MeasurePos = v[4] + dur end
        if v[2] >= measure_num + 1 then seg_L.Measure = v[2] - 1
        else seg_L.Measure = v[2]
        end
        shape:GetTerminateSegmentRight().Measure = v[3] - 1
        shape:SaveNewEverything(nil, nil)
        shape:Load(v[1]) -- delete the original non-"fixed" shape
        shape:DeleteData()
    end
end

local function shift_joined_expressions(measure_num, m_offset, m_width)
    local exps = finale.FCExpressions()
    exps:LoadAllForItem(measure_num + 1) -- the "joining" second measure
    for exp in eachbackwards(exps) do
        if exp.StaffGroupID > 0 and exp.MeasurePos == 0 then -- measure-attached
            exp.HorizontalPos = exp.HorizontalPos + m_width
        else -- note-attached or beat-attached
            exp.MeasurePos = exp.MeasurePos + m_offset
        end
        exp:SaveNewToCell(finale.FCCell(measure_num, exp.Staff))
    end
end

local function join_measures(selection)
    if (selection.EndMeasure - selection.StartMeasure) % 2 ~= 1 then
        local msg = "Please select an EVEN number\nof measures for the\n\"Measure Span Join\" action"
        finenv.UI():AlertError(msg, "User Error")
        return false
    end
    local join_rgn = mixin.FCMMusicRegion()
    join_rgn:SetRegion(selection)

    -- run through pairs of measures backwards
    for measure_num = selection.EndMeasure - 1, selection.StartMeasure, -2 do
        join_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num + 1)
        local measure = { mixin.FCMMeasure(), mixin.FCMMeasure() }
        measure[1]:Load(measure_num)
        measure[2]:Load(measure_num + 1)
        measure[1].UseTimeSigForDisplay = false -- no longer relevant
        measure[1].Barline = measure[2].Barline -- before [2] is deleted

        local time_sig = { measure[1]:GetTimeSignature(), measure[2]:GetTimeSignature()}
        local top = { time_sig[1].Beats, time_sig[2].Beats }
        local bottom = { time_sig[1].BeatDuration, time_sig[2].BeatDuration }
        local measure_dur = { measure[1]:GetDuration(), measure[2]:GetDuration() }
        local saved_shapes = save_shapes_for_joining(join_rgn, measure_num)
        pad_or_truncate_cells(join_rgn, measure_num + 1, measure_dur[2], 0)
        pad_or_truncate_cells(join_rgn, measure_num, measure_dur[1], measure_num + 1)

        local comp_array = {}
        if time_sig[1].CompositeTop or time_sig[2].CompositeTop then
            -- at least ONE composite
            for cnt = 1, 2 do
                comp_array[cnt] = {}
                if time_sig[cnt].CompositeTop then
                    comp_array[cnt] = extract_composite_to_array(time_sig[cnt])
                    if not time_sig[cnt].CompositeBottom then
                        comp_array[cnt].bottom = { groups = { bottom[cnt] } }
                    end
                else -- create dummy composite
                    comp_array[cnt].top = { groups = { { top[cnt] } } }
                    comp_array[cnt].bottom = { groups = { bottom[cnt] } }
                end
            end

            for i = 1, #comp_array[2].top.groups do -- COMBINE both sets into comp_array[1]
                table.insert(comp_array[1].top.groups, comp_array[2].top.groups[i])
                table.insert(comp_array[1].bottom.groups, comp_array[2].bottom.groups[i])
            end
            if not config.composite_join then -- CONSOLIDATE the meters
                local beats, dur = flatten_comp_numerators(comp_array[1])
                    clear_composite(time_sig[1], beats, dur)
                    time_sig[1]:SetBeats(beats):SetBeatDuration(dur)
            else
                new_composite_top(time_sig[1], comp_array[1].top.groups, 1, 0, 1)
                new_composite_bottom(time_sig[1], comp_array[1].bottom.groups, 1, 0)
                make_display_meter(measure[1], comp_array[1]) -- conditional on config
            end
        else
            -- NO COMPOSITES in this measure pair
            if top[1] == top[2] and bottom[1] == bottom[2] then -- identical meters
                if config.double_join then
                    top[1] = top[1] * 2 -- double numerator
                else
                    bottom[1] = bottom[1] * 2 -- "halve" denominator
                end
                time_sig[1]:SetBeats(top[1]):SetBeatDuration(bottom[1])
            else
                comp_array = {
                    top = { groups = { { top[1] }, { top[2] } } },
                    bottom = { groups = { bottom[1], bottom[2] } }
                }
                if not config.composite_join then -- CONSOLIDATE the meters
                        time_sig[1].Beats, time_sig[1].BeatDuration = flatten_comp_numerators(comp_array)
                else -- fabricate COMPOSITE
                    new_composite_bottom(time_sig[1], comp_array.bottom.groups, 1, 0)
                    new_composite_top(time_sig[1], comp_array.top.groups, 1, 0, 1)
                    make_display_meter(measure[1], comp_array) -- (conditional on config)
                end
            end
        end
        measure[1]:Save()
        measure[2]:Save()
        shift_joined_expressions(measure_num, measure_dur[1], measure[1].Width)
        join_rgn:SetEndMeasure(measure_num + 1):RebarMusic(finale.REBARSTOP_REGIONEND, config.rebeam, false)
        compress_smart_shape_ends(join_rgn, measure_num, measure_dur[1])
        -- delete old measure 2
        join_rgn:SetStartMeasure(measure_num + 1):CutDeleteMusic()
        join_rgn:ReleaseMusic()
        join_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num)
        restore_joined_shapes(saved_shapes, measure_num, measure_dur[1])
    end
    return true
end

local function refocus() -- has utils.show_notes_dialog been invoked?
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

local function measure_span()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_down = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))
    if mod_down or (span_action == "options") then
        local ok = user_options()
        if not ok or (span_action == "options") then refocus() return end -- user cancelled
    end
    local selection = mixin.FCMMusicRegion()
    selection:SetRegion(finenv.Region())
        :SetStartMeasurePosLeft():SetEndMeasurePosRight()
        :SetFullMeasureStack()
    if selection:IsEmpty() then
        finenv.UI():AlertError(
            "Please select some music before running this script",
            finaleplugin.ScriptGroupName .. "Error"
        )
        refocus()
        return
    end

    local end_m = selection.EndMeasure
    if span_action == "divide" then
        divide_measures(selection) -- adds extra measures
        end_m = end_m + (end_m - selection.StartMeasure + 1)
    elseif span_action == "join" then
        if join_measures(selection) then -- removes joined measures
            end_m = end_m - ((end_m - selection.StartMeasure + 1) / 2)
        end
    end
    selection.EndMeasure = end_m
    if config.note_spacing then
        selection:SetInDocument()
        finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
    end
    if config.repaginate then repaginate() end
    -- restore original selection with new end measure
    selection:SetRegion(finenv.Region()):SetEndMeasure(end_m):SetInDocument()
    refocus()
end

measure_span()

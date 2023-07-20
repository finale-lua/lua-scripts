function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.61"
    finaleplugin.Date = "2023/05/23"
    finaleplugin.CategoryTags = "Measure, Time Signature, Meter"
    finaleplugin.MinJWLuaVersion = 0.64
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
    finaleplugin.Notes = [[This script changes the "span" of every measure in the currently selected music by 
manipulating its time signature, either dividing it into two or combining it with the 
following measure. Many measures with different time signatures can be modified at once.

== JOIN ==

Combine each pair of measures in the selection into one by combining their time signatures. 
If they have the same time signature either double the numerator ([3/4][3/4] -> [6/4]) or 
halve the denominator ([3/4][3/4] -> [3/2]). If the time signatures aren't equal, choose to either 
COMPOSITE them ([2/4][3/8] -> [2/4 + 3/8]) or CONSOLIDATE them ([2/4][3/8] -> [7/8]). 
(Consolidation loses current beam groupings). You can choose that a consolidated "display" 
time signature is created automatically when compositing meters. "JOIN" only works on an even number of measures.

== DIVIDE ==

Divide every selected measure into two, changing the time signature by either halving the 
numerator ([6/4] -> [3/4][3/4]) or doubling the denominator ([6/4] -> [6/8][6/8]). 
If the measure has an odd number of beats, choose whether to put more beats in the first 
measure (5->3+2) or the second (5->2+3). Measures containing composite meters will be divided 
after the first composite group, or if there is only one group, after its first element.

== IN ALL CASES ==

Incomplete measures will be filled with rests before Join/Divide. Measures containing too many 
notes will be trimmed to their "real" duration. Time signatures "for display only" will be removed. 
Measures are either deleted or shifted in every operation so smart shapes spanning the area 
need to be "restored". Selecting a SPAN of "5" will look for smart shapes to restore from 5 
measures before until 5 after the selected region. (This takes noticeably longer than a SPAN of "2").

== OPTIONS ==

To configure script settings select the "Measure Span Options..." menu item, or else hold down 
the SHIFT or ALT (option) key when invoking "Join" or "Divide".
    ]]
    return "Measure Span Options...", "Measure Span Options", "Change the default behaviour of the Measure Span script"
end

span_action = span_action or "options"
local config = {
    halve_numerator =   true, -- halve the numerator on DIVIDE otherwise double the denominator
    odd_more_first  =   true, -- if dividing odd beats, more beats in FIRST measure (otherwise in the second)
    double_join     =   true, -- double the numerator on JOIN (otherwise halve the denominator)
    composite_join  =   true, -- JOIN measure by COMPOSITING two unequal time signatures (otherwise CONSOLIDATE them)
    note_spacing    =   true, -- implement note spacing after each operation
    repaginate      =   false, -- repaginate after each operation
    display_meter   =   true, -- create a composite "display" time signature with composite joins
    shape_extend    =   3,    -- how many measures either side of the selection to span for smart shapes
    window_pos_x    =   false, -- saved dialog window position
    window_pos_y    =   false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local tie = require("library.tie")
local script_name = "measure_span"
configuration.get_user_settings(script_name, config, true)

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

function note_spacing(rgn)
    if config.note_spacing then
        rgn:SetFullMeasureStack()
        rgn:SetInDocument()
        finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
    end
end

function user_options()
    local x_grid = { 15, 70, 190, 210, 305, 110 }
    local i_width = 142
    local y = 0

    local dlg = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
        local function yd(diff)
            diff = diff or 15 -- average horizontal line shift
            y = y + diff
        end
        local function cstat(cx, cy, ctext, cwide, chigh)
            cx = (type(cx) == "string") and tonumber(cx) or x_grid[cx]
            local stat = dlg:CreateStatic(cx, cy):SetText(ctext)
            if cwide then stat:SetWidth(cwide) end
            if chigh then stat:SetHeight(chigh) end
            return stat
        end
        local function ccheck(cx, cy, cname, cwide, check, ctext, chigh)
            cx = x_grid[cx]
            local chk = dlg:CreateCheckbox(cx, cy, cname):SetWidth(cwide):SetText(ctext):SetCheck(check)
            if chigh then chk:SetHeight(chigh) end
        end
        local function chl(cx, cy, cwide)
            dlg:CreateHorizontalLine(cx, cy, cwide)
        end

    local shadow = cstat("1", y + 1, "DIVIDE EACH MEASURE INTO TWO:", x_grid[4])
    if shadow.SetTextColor then shadow:SetTextColor(180, 180, 180) end
    cstat("0", y, "DIVIDE EACH MEASURE INTO TWO:", x_grid[4])
    yd(20)
    cstat(1, y, "Halve the numerator:", x_grid[3])
    ccheck(3, y, "1", i_width, (config.halve_numerator and 1 or 0), " [6/4] -> [3/4][3/4]")
    yd()
    cstat(2, y, "OR")
    yd()
    cstat(1, y, "Double the denominator:", x_grid[3])
    ccheck(3, y, "2", i_width, (config.halve_numerator and 0 or 1), " [6/4] -> [6/8][6/8]")
    yd(25)
    chl(1, y, x_grid[5])
    yd(10)
    cstat(1, y, "If halving a numerator with an ODD number of beats:", x_grid[5])
    yd(17)
    cstat(1, y, "More beats in first measure:", x_grid[4] + 20)
    ccheck(3, y, "3", i_width, (config.odd_more_first and 1 or 0), " 3 -> 2 + 1 etc.")
    yd()
    cstat(2, y, "OR")
    yd()
    cstat(1, y, "More beats in second measure:", x_grid[4] + 20)
    ccheck(3, y, "4", i_width, (config.odd_more_first and 0 or 1), " 3 -> 1 + 2 etc.")
    yd(27)
    chl(0, y, x_grid[3] + i_width)
    chl(0, y + 2, x_grid[3] + i_width)
    chl(0, y + 3, x_grid[3] + i_width)
    yd(13)
    shadow = cstat("1", y + 1, "JOIN PAIRS OF MEASURES:", x_grid[3])
    if shadow.SetTextColor then shadow:SetTextColor(180, 180, 180) end
    cstat("0", y, "JOIN PAIRS OF MEASURES:", x_grid[3])
    yd(20)
    cstat(1, y, "If both measures have the same time signature ...", x_grid[5])
    yd(17)
    cstat(1, y, "Double the numerator:", x_grid[3])
    ccheck(3, y, "5", i_width, (config.double_join and 1 or 0), " [3/8][3/8] -> [6/8]")
    yd()
    cstat(2, y, "OR")
    yd()
    cstat(1, y, "Halve the denominator:", x_grid[3])
    ccheck(3, y, "6", i_width, (config.double_join and 0 or 1), " [3/8][3/8] -> [3/4]")
    yd(25)
    chl(1, y, x_grid[5])
    yd(5)
    cstat(1, y, "otherwise ...", x_grid[2])
    yd(17)
    cstat(1, y, "Consolidate time signatures:", x_grid[4])
    ccheck(3, y, "8", i_width, (config.composite_join and 0 or 1),
        " [2/4][3/8] -> [7/8]\n (lose beaming groups)", 30)
    yd(17)
    cstat(2, y, "OR")
    yd(17)
    cstat(1, y, "Composite time signatures:", x_grid[3])
    ccheck(3, y, "7", i_width, (config.composite_join and 1 or 0),
        " [2/4][3/8] -> [2/4+3/8]\n (keep beaming groups)", 30)
    yd(35)
    ccheck(1, y, "display", x_grid[5] + 10, (config.display_meter and 1 or 0),
        " Create \"display\" time signature when compositing\n [2/4][3/8] -> [2/4+3/8] displaying \"7/8\" )", 30)
    yd(36)
    chl(0, y, x_grid[3] + i_width)
    chl(0, y + 2, x_grid[3] + i_width)
    chl(0, y + 3, x_grid[3] + i_width)
    yd(12)
    cstat("0", y, "Preserve smart shapes within\n(Larger spans take longer)", x_grid[3], 30)
    local popup = dlg:CreatePopup(x_grid[3] - 25, y - 1, "extend"):SetWidth(35):SetSelectedItem(config.shape_extend - 2)
    for i = 2, 5 do
        popup:AddString(i)
    end
    cstat("205", y, "measure span")
    yd(38)
    cstat("0", y, "ON COMPLETION:", i_width)
    ccheck(6, y, "spacing", i_width, (config.note_spacing and 1 or 0), "Respace notes")
    dlg:CreateButton(x_grid[5], y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() finenv.UI():AlertInfo(finaleplugin.Notes:gsub(" \n", " "), "Measure Span Info") end)
    yd(18)
    ccheck(6, y, "repaginate", i_width, (config.repaginate and 1 or 0), "Repaginate entire score")

    -- radio button action
    local function radio_change(id, check) -- for checkboxes "1" to "8"
        local matching_id = (id % 2 == 0) and (id - 1) or (id + 1)
        dlg:GetControl(tostring(matching_id)):SetCheck((check + 1) % 2) -- "ON" <-> "OFF"
    end
    for id = 1, 8 do -- add to 8 buttons
        dlg:GetControl(tostring(id)):AddHandleCommand(function(self) radio_change(id, self:GetCheck()) end)
    end
    dlg:CreateOkButton():SetText("Save")
    dlg:CreateCancelButton()
    dialog_set_position(dlg)
    dlg:RegisterHandleOkButtonPressed(function(self)
        for k, v in pairs(
            { halve_numerator = "1", odd_more_first = "3", double_join = "5", composite_join = "7",
              display_meter = "display", note_spacing = "spacing", repaginate = "repaginate" }
            ) do
            config[k] = (self:GetControl(v):GetCheck() == 1)
        end
        config.shape_extend = (self:GetControl("extend"):GetSelectedItem() + 2)
        dialog_save_position(self) -- save window position and config choices
    end)
    return (dlg:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function repaginate()
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

function region_contains_notes(region, layer_num)
    for entry in eachentry(region, layer_num) do
        if entry.Count > 0 then return true end
    end
    return false
end

function insert_blank_measure_after(measure_num) -- required for Span Divide operation
    local props_copy = {"PositioningNotesMode", "Barline", "SpaceAfter", "SpaceBefore", "UseTimeSigForDisplay"}
    local props_set = {"BreakMMRest", "HideCautionary", "BreakWordExtension"}
    local measure = { finale.FCMeasure(), finale.FCMeasure() }

    measure[1]:Load(measure_num)
    measure[1].UseTimeSigForDisplay = false
    finale.FCMeasures.Insert(measure_num + 1, 1)
    measure[2]:Load(measure_num + 1)
    for _, v in ipairs(props_copy) do -- copy main measure values
        measure[2][v] = measure[1][v]
    end
    measure[1].Barline = finale.BARLINE_NORMAL
    measure[1].SpaceAfter = 0
    for _, v in ipairs(props_set) do  -- move "section" properties to second measure
        if measure[1][v] then
            measure[1][v] = false
            measure[2][v] = true
        end
    end
    measure[1]:Save()
    measure[2]:Save()
    return 1 -- added one measure
end

function pad_or_truncate_cells(measure_rgn, measure_num, measure_duration)
    measure_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num) -- one bar width

    for slot = measure_rgn.StartSlot, measure_rgn.EndSlot do
        local staff = measure_rgn:CalcStaffNumber(slot)
        local cell_rgn = mixin.FCMMusicRegion()
        cell_rgn:SetRegion(measure_rgn):SetStartStaff(staff):SetEndStaff(staff)

        if region_contains_notes(cell_rgn, 0) then
            for layer_num = 1, layer.max_layers() do
                local entry_layer = finale.FCNoteEntryLayer(layer_num - 1, staff, measure_num, measure_num)
                entry_layer:Load()
                if entry_layer.Count > 0 then -- layer contains some notes
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
end

--[[ STRUCTURE OF COMPOSITE TIME SIGNATURE TABLES:
    composite_array = {
        top = {
            comp = FCCompositeTimeSigTop,
            groups = { 
                { element_1, element_2, element_3... }, -- group1
                { element_1, element_2, element_3... }, -- group2
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

function clear_composite(time_sig, top, bottom)
    if time_sig.CompositeTop and top > 0 then
        time_sig:RemoveCompositeTop(top)
    end
    if time_sig.CompositeBottom and bottom > 0 then
        time_sig:RemoveCompositeBottom(bottom)
    end
end

function extract_composite_to_array(time_sig)
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

function flatten_comp_numerators(comp)
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

function make_display_meter(fc_measure, comp)
    if config.display_meter then -- only if requested
        fc_measure.UseTimeSigForDisplay = true
        local display_sig = fc_measure:GetTimeSignatureForDisplay()
        if display_sig then
            display_sig.Beats, display_sig.BeatDuration = flatten_comp_numerators(comp)
        end
    end
end

function new_composite_top(time_sig, group_array, first, last, from_element)
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

function new_composite_bottom(time_sig, group_array, first, last)
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

function extend_smart_shape_ends(rgn, measure_num, measure_duration) -- called by divide_measures()
    local extend_rgn = mixin.FCMMusicRegion()
    local measures = finale.FCMeasures()
    measures:LoadAll() -- find highest measure number
    local extend_count = measure_num + config.shape_extend
    if extend_count > measures.Count then extend_count = measures.Count end

    extend_rgn:SetRegion(rgn)
        :SetStartMeasure(measure_num - config.shape_extend)
        :SetEndMeasure(extend_count)
        :SetFullMeasureStack()
    local marks = finale.FCSmartShapeMeasureMarks()
    marks:LoadAllForRegion(extend_rgn, true)
    for mark in each(marks) do
        local shape = mark:CreateSmartShape()
        local segment = { shape:GetTerminateSegmentLeft(), shape:GetTerminateSegmentRight() }
        local m = { segment[1].Measure, segment[2].Measure }

        if not shape.EntryBased and m[1] <= measure_num then
            if m[2] > measure_num then
                segment[2].Measure = m[2] + 1 -- crosses new measure boundary
            end
            for i = 1, 2 do
                if m[i] == measure_num and segment[i].MeasurePos >= measure_duration then
                    segment[i].Measure = m[i] + 1 -- crosses boundary
                    segment[i].MeasurePos = segment[i].MeasurePos - measure_duration
                end
            end
            shape:Save()
        end
    end
end

function divide_measures(selection)
    local extra_measures = 0 -- run backwards through selection
    for measure_num = selection.EndMeasure, selection.StartMeasure, -1 do
        insert_blank_measure_after(measure_num)

        local measure = { mixin.FCMMeasure(), mixin.FCMMeasure() }
        measure[1]:Load(measure_num)
        measure[2]:Load(measure_num + 1)
        local time_sig = { measure[1]:GetTimeSignature(), measure[2]:GetTimeSignature() }
        local top = { time_sig[1].Beats, time_sig[1].Beats }
        local bottom = time_sig[1].BeatDuration

        local pair_rgn = mixin.FCMMusicRegion()
        pair_rgn:SetRegion(selection):SetFullMeasureStack()
        pad_or_truncate_cells(pair_rgn, measure_num, measure[1]:GetDuration())

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
                if #comp_array.top.groups[1] == 1 then -- does group one contain one element?
                    clear_composite(time_sig[1], comp_array.top.groups[1][1], comp_array.bottom.groups[1])
                else
                    new_composite_top(time_sig[1], comp_array.top.groups, 1, 1, 1)
                    time_sig[1]:RemoveCompositeBottom(comp_array.bottom.groups[1])
                end
                --= GROUPS 2+ =--
                if comp_array.top.count == 2 and #comp_array.top.groups[2] == 1 then -- second group has one element?
                    clear_composite(time_sig[2], comp_array.top.groups[2][1], comp_array.bottom.groups[2])
                else -- copy groups 2+ to top and bottom
                    new_composite_top(time_sig[2], comp_array.top.groups, 2, 0, 1)
                    new_composite_bottom(time_sig[2], comp_array.bottom.groups, 2, 0)
                end
            end
        else
            -- NON-COMPOSITE METER
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
                        if config.odd_more_first then
                            top[1] = top[1] + 1
                        end
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
        extend_smart_shape_ends(pair_rgn, measure_num, measure[1]:GetDuration())
        pair_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num + 1) -- rebar BOTH measures
        pair_rgn:RebarMusic(finale.REBARSTOP_REGIONEND, true, false)
        note_spacing(pair_rgn) -- (conditional on config)
        extra_measures = extra_measures + 1
    end
    selection.EndMeasure = selection.EndMeasure + extra_measures
end

function entry_from_enum(measure, staff_num, entry_num)
    local cell = finale.FCNoteEntryCell(measure, staff_num)
    cell:Load()
    return cell:FindEntryNumber(entry_num)
end

function shift_smart_shapes(rgn, measure_num, pos_offset)
    local slurs = {}
    local measures = finale.FCMeasures()
    measures:LoadAll() -- find highest measure number
    local extend_count = measure_num + config.shape_extend + 1
    if extend_count > measures.Count then extend_count = measures.Count end

    local shift_rgn = mixin.FCMMusicRegion()
    shift_rgn:SetRegion(rgn)
        :SetStartMeasure(measure_num - config.shape_extend)
        :SetEndMeasure(extend_count)
        :SetFullMeasureStack()
    local marks = finale.FCSmartShapeMeasureMarks()
    marks:LoadAllForRegion(shift_rgn, true)
    for mark in each(marks) do
        local shape = mark:CreateSmartShape()
        local segment = { L = shape:GetTerminateSegmentLeft(), R = shape:GetTerminateSegmentRight() }
        local m = { L = segment.L.Measure, R = segment.R.Measure }

        if shape.Visible and m.L < (measure_num + 2) and m.L ~= m.R and m.R > measure_num then
            if not shape.EntryBased then -- MEASURE ATTACHED (and crosses deleted measure 2)
                if m.L > measure_num then
                    segment.L.Measure = m.L - 1
                    if m.L == measure_num + 1 then
                        segment.L.MeasurePos = segment.L.MeasurePos + pos_offset
                    end
                end
                if m.R > measure_num then
                    segment.R.Measure = m.R - 1
                    if m.R == measure_num + 1 then
                        segment.R.MeasurePos = segment.R.MeasurePos + pos_offset
                    end
                end
                shape:Save()
            -- otherwise ENTRY-ATTACHED shape (which starts or ends in second measure)
            elseif m.L == (measure_num + 1) or m.R == (measure_num + 1) then
                local entry = {
                    L = entry_from_enum(m.L, segment.L.Staff, segment.L.EntryNumber),
                    R = entry_from_enum(m.R, segment.R.Staff, segment.R.EntryNumber)
                }
                local slur =  {
                    L = { staff = segment.L.Staff, m = m.L, shape = shape },
                    R = { staff = segment.R.Staff, m = m.R - 1 },
                }
                if m.L <= measure_num then
                    slur.L.entry = entry.L -- entry stays put
                else
                    slur.L.m = m.L - 1 -- move to previous measure
                    slur.L.pos = (entry.L and entry.L.MeasurePos or 0) + pos_offset -- by position
                end
                if m.R > measure_num + 1 then -- entry stays put
                    slur.R.entry = entry.R
                else -- move to previous measure by position
                    slur.R.pos = (entry.R and entry.R.MeasurePos or 0) + pos_offset
                end
                table.insert(slurs, slur)
            end
        end
    end
    local saved_expressions = {} -- save note-attached expressions from "joined" (2nd) bar
    shift_rgn:SetStartMeasure(measure_num + 1):SetEndMeasure(measure_num + 1)
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(shift_rgn)
    for exp in eachbackwards(expressions) do
        if exp.StaffGroupID == 0 then
            table.insert(saved_expressions, exp)
            exp:DeleteData()
        end
    end
    return slurs, saved_expressions
end

function make_entry_smartshape(start_entry, end_entry, shape)
    local seg = { L = shape:GetTerminateSegmentLeft(), R = shape:GetTerminateSegmentRight() }
    local new_shape = mixin.FCMSmartShape()
    local new_seg = { L = new_shape:GetTerminateSegmentLeft(), R = new_shape:GetTerminateSegmentRight() }
    new_shape:SetEntryAttachedFlags(true)

    for _, v in ipairs(
            {"ShapeType", "PresetShape", "LineID", "EngraverSlur",
             "MakeHorizontal", "MaintainAngle", "AvoidAccidentals"} ) do
        new_shape[v] = shape[v]
    end
    new_seg.L:SetEntry(start_entry)
    new_seg.R:SetEntry(end_entry)
    if not shape:IsSlur() then
        new_seg.L:SetCustomOffset(false) -- LH
        new_seg.R:SetCustomOffset(true)  -- RH
    end
    for _, v in ipairs( {"Staff", "Measure", "NoteID", "EndpointOffsetX", "EndpointOffsetY" } ) do
        new_seg.L[v] = seg.L[v]
        new_seg.R[v] = seg.R[v]
    end

    local cpa = { old = shape:GetCtrlPointAdjust(), new = new_shape:GetCtrlPointAdjust() }
    if cpa.old.CustomShaped then
        cpa.new.CustomShaped = true
        for _, v in ipairs( { "ControlPoint1OffsetX", "ControlPoint1OffsetY",
                "ControlPoint2OffsetX", "ControlPoint2OffsetY" } ) do
            cpa.new[v] = cpa.old[v]
        end
    end
    new_shape:SaveNewEverything(start_entry, end_entry)
end

function restore_slurs(measure_num, pos_offset, slurs, expressions)
    if #slurs > 0 then
        for _, slur in ipairs(slurs) do
            for _, id in ipairs({"L", "R"}) do
                if not slur[id].entry and slur[id].pos ~= nil then
                    local cell = finale.FCNoteEntryCell(slur[id].m, slur[id].staff)
                    cell:Load()
                    slur[id].entry = cell:FindClosestPos(slur[id].pos)
                end
            end
            if slur.L.entry ~= nil and slur.R.entry ~= nil then
                make_entry_smartshape(slur.L.entry, slur.R.entry, slur.L.shape)
            end
        end
    end
    if #expressions > 0 then -- restore expressions from "joined" (2nd) measure
        for _, exp in ipairs(expressions) do
            exp.MeasurePos = exp.MeasurePos + pos_offset
            exp:SaveNewToCell(finale.FCCell(measure_num, exp.Staff))
        end
    end
end

function save_tie_ends(region, measure)
    local ties = {}
    for slot = region.StartSlot, region.EndSlot do -- assumes FullMeasureStack
        local staff = region:CalcStaffNumber(slot)
        ties[staff] = {}
        for layer_num = 1, layer.max_layers() do
            local entry_layer = finale.FCNoteEntryLayer(layer_num - 1, staff, measure, measure)
            entry_layer:Load()
            ties[staff][layer_num] = {}
            if entry_layer.Count > 0 then -- layer contains some notes
                local last_entry = entry_layer:GetItemAt(entry_layer.Count - 1)
                local pos = last_entry.MeasurePos
                ties[staff][layer_num][pos] = {}
                for note in each(last_entry) do
                    if note.Tie then
                        table.insert(ties[staff][layer_num][pos], note.NoteID )
                    end
                end
            end
        end
    end
    return ties
end

function restore_tie_ends(region, measure, ties)
    for slot = region.StartSlot, region.EndSlot do
        local staff = region:CalcStaffNumber(slot)
        if ties[staff] then
            for layer_num = 1, layer.max_layers() do
                if ties[staff][layer_num] then
                    local entry_layer = finale.FCNoteEntryLayer(layer_num - 1, staff, measure, measure)
                    entry_layer:Load()
                    for entry in each(entry_layer) do
                        if ties[staff][layer_num][entry.MeasurePos] ~= nil then
                            for _, v in ipairs(ties[staff][layer_num][entry.MeasurePos]) do
                                local note = entry:FindNoteID(v)
                                local tied_to_note = tie.calc_tied_to(note)
                                if tied_to_note then
                                    note.Tie = true
                                    tied_to_note.TieBackwards = true
                                end
                            end
                        end
                    end
                    entry_layer:Save()
                end
            end
        end
    end
end

function join_measures(selection)
    if (selection.EndMeasure - selection.StartMeasure) % 2 ~= 1 then
        local msg = "Please select an EVEN number of measures for the \"Measure Span Join\" action"
        finenv.UI():AlertError(msg, "User Error")
        return
    end
    -- run through selection backwards by measure pairs
    local measures_removed = 0
    for measure_num = selection.EndMeasure - 1, selection.StartMeasure, -2 do
        local measure = { finale.FCMeasure(), finale.FCMeasure() }
        measure[1]:Load(measure_num)
        measure[2]:Load(measure_num + 1)
        measure[1].UseTimeSigForDisplay = false -- no longer relevant
        measure[1].Barline = measure[2].Barline -- before [2] is erased

        local time_sig = { measure[1]:GetTimeSignature(), measure[2]:GetTimeSignature()}
        local top = { time_sig[1].Beats, time_sig[2].Beats }
        local bottom = { time_sig[1].BeatDuration, time_sig[2].BeatDuration }
        local measure_dur = { measure[1]:GetDuration(), measure[2]:GetDuration() }

        -- paste all of measure[2] onto end of measure[1]
        local paste_rgn = mixin.FCMMusicRegion()
        paste_rgn:SetRegion(selection):SetFullMeasureStack()
        local saved_tie_ends = save_tie_ends(paste_rgn, measure_num)
        local saved_slurs, saved_expressions = shift_smart_shapes(paste_rgn, measure_num, measure_dur[1])
        pad_or_truncate_cells(paste_rgn, measure_num + 1, measure_dur[2])
        paste_rgn:SetStartMeasure(measure_num + 1):SetEndMeasure(measure_num + 1):CopyMusic()
        pad_or_truncate_cells(paste_rgn, measure_num, measure_dur[1])

        local comp_array = {}
        if time_sig[1].CompositeTop or time_sig[2].CompositeTop then
            -- at least ONE composite in this pair
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
                time_sig[1].Beats = beats
                time_sig[1].BeatDuration = dur
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
                time_sig[1].Beats = top[1]
                time_sig[1].BeatDuration = bottom[1]
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
        paste_rgn:SetStartMeasurePos(measure_dur[1]):SetEndMeasurePosRight()
        paste_rgn:PasteMusic()
        paste_rgn:ReleaseMusic()
        measure[1]:Save()
        restore_tie_ends(paste_rgn, measure_num, saved_tie_ends)
        restore_slurs(measure_num, measure_dur[1], saved_slurs, saved_expressions)

        paste_rgn:SetStartMeasurePos(0)
            :RebarMusic(finale.REBARSTOP_REGIONEND, true, false)
        -- delete the copied (second) measure
        paste_rgn:SetStartMeasure(measure_num + 1):SetEndMeasure(measure_num + 1):CutDeleteMusic()
        paste_rgn:ReleaseMusic()
        paste_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num)
        note_spacing(paste_rgn)
        measures_removed = measures_removed + 1
    end
    selection.EndMeasure = selection.EndMeasure - measures_removed
end

function measure_span()
    local mod_down = finenv.QueryInvokedModifierKeys and
        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
         or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
        )
    if mod_down or (span_action == "options") then
        local ok = user_options()
        if not ok or (span_action == "options") then return end
    end

    local selection = mixin.FCMMusicRegion()
    selection:SetRegion(finenv.Region()):SetStartMeasurePosLeft():SetEndMeasurePosRight()
    if span_action == "divide" then
        divide_measures(selection)
    elseif span_action == "join" then
        join_measures(selection)
    else
        return -- unknown request
    end
    selection:SetInDocument()
    if config.repaginate then repaginate() end
end

measure_span()

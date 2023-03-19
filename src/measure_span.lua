function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.17"
    finaleplugin.Date = "2023/03/19"
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
        This script changes the "span" of every measure in the selection by either dividing it into two 
        or combining it with the following measure. The options are arranged so that many measures with 
        different time signatures can be modified at once.

        *JOIN:*  
        Combine each pair of measures in the selection into one by consolidating their time signatures. 
        If both measures have the same time signature, choose to either double the numerator ([3/4][3/4] -> [6/4]) 
        or halve the denominator ([3/4][3/4] -> [3/2]). 
        If the time signatures aren't equal, choose to either COMPOSITE them ([2/4][3/8] -> [2/4 + 3/8]) 
        or CONSOLIDATE them ([2/4][3/8] -> [7/8]). 
        "JOIN" will only work on an EVEN number of measures.  

        *DIVIDE:*  
        Divide every selected measure into two, changing the time signature by either 
        halving the numerator ([6/4] -> [3/4][3/4]) or doubling the denominator ([6/4] -> [6/8][6/8]). 
        If the measure has an odd number of beats, choose whether to put more beats in the first measure (5->3+2) or the second (5->2+3). 

        *IN ALL CASES:*  
        Any measure in the selection containing a composite meter (e.g. [3+4/8]) will not be modified. 
        Time signatures "for display only" will be removed, as will notes at the end of any measure beyond its "real" duration. 

        *OPTIONS:*  
        To configure the option settings either select the "Measure Span Options..." menu item, 
        or hold down the `shift` or `alt` (option) key when invoking "Join" or "Divide".
    ]]
    return "Measure Span Options...", "Measure Span Options", "Change the default behaviour of the Measure Span script"
end

-- TEXT DATA for the "?" INFO button in the configuration dialog
local info = "This script changes the \"span\" of every measure in the selection by either dividing it into two "
.. "or combining it with the following measure. The options are arranged so that many measures with "
.. "different time signatures can be modified at once.\n\n"
.. "MEASURE SPAN JOIN: Combine each pair of measures in the selection into one by consolidating their time signatures. "
.. "If both measures have the same time signature, choose to either double the numerator ([3/4][3/4] -> [6/4]) "
.. "or halve the denominator ([3/4][3/4] -> [3/2]). If the time signatures aren't equal, choose to either "
.. "COMPOSITE them ([2/4][3/8] -> [2/4 + 3/8]) or CONSOLIDATE them ([2/4][3/8] -> [7/8]). "
.. "\"JOIN\" will only work on an EVEN number of measures. \n\n"
.. "MEASURE SPAN DIVIDE: \nDivide every selected measure into two, changing the time signature by either "
.. "HALVING its numerator ([6/4] -> [3/4][3/4]) or DOUBLING its denominator ([6/4] -> [6/8][6/8]). "
.. "If the measure has an odd number of beats, choose whether to put more beats in the first measure (5->3+2) or the second (5->2+3).\n\n"
.. "IN ALL CASES: \nAny measure in the selection containing a composite meter (e.g. [3+4/8]) will not be modified. "
.. "Time signatures \"for display only\" will be removed, as will notes at the end of any measure beyond its \"real\" duration.\n\n"
.. "MEASURE SPAN OPTIONS: \nTo configure the option settings either select the \"Measure Span Options...\" menu item, "
.. "or hold down the `shift` or `alt` (option) key when invoking \"Join\" or \"Divide\". \n\n"

span_action = span_action or "options"

local config = {
    halve_numerator =   true, -- otherwise double the denominator on DIVIDE
    odd_more_first  =   true, -- otherwise more beats in SECOND bar if odd beats
    double_join     =   true, -- double the numerator on JOIN (otherwise halve the denominator)
    composite_join  =   true, -- JOIN measure by COMPOSITING two unequal time signatures (otherwise CONSOLIDATE them)
    note_spacing    =   true,
    repaginate      =   false,
    window_pos_x    =   false,
    window_pos_y    =   false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local script_name = "meter_span"
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

function user_options()
    local x_grid = { 15, 70, 190, 210, 305 }
    local i_width = 140
    local y = 0
    local function yd(delta)
        if delta then y = y + delta
        else y = y + 15
        end
    end

    local dlg = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dlg:CreateStatic(0, y):SetText("DIVIDE EACH MEASURE INTO TWO:"):SetWidth(x_grid[4])
    dlg:CreateStatic(1, y + 1):SetText("DIVIDE EACH MEASURE INTO TWO:"):SetWidth(x_grid[4])
    yd(20)
    dlg:CreateStatic(x_grid[1], y):SetText("Halve the numerator:"):SetWidth(x_grid[3])
    dlg:CreateCheckbox(x_grid[3], y, "1"):SetCheck(config.halve_numerator and 1 or 0):SetText(" [6/4] -> [3/4][3/4]"):SetWidth(i_width)
    yd()
    dlg:CreateStatic(x_grid[2], y):SetText("OR")
    yd()
    dlg:CreateStatic(x_grid[1], y):SetText("Double the denominator:"):SetWidth(x_grid[3])
    dlg:CreateCheckbox(x_grid[3], y, "2"):SetCheck(config.halve_numerator and 0 or 1):SetText(" [6/4] -> [6/8][6/8]"):SetWidth(i_width)
    yd(25)
    dlg:CreateHorizontalLine(x_grid[1], y, x_grid[3] + i_width)
    yd(10)
    dlg:CreateStatic(x_grid[1], y):SetText("If halving a numerator with an ODD number of beats:"):SetWidth(x_grid[5])
    yd(17)
    dlg:CreateStatic(x_grid[1], y):SetText("More beats in first measure:"):SetWidth(x_grid[4] + 20)
    dlg:CreateCheckbox(x_grid[3], y, "3"):SetCheck(config.odd_more_first and 1 or 0):SetText(" 3 -> 2 + 1 etc."):SetWidth(i_width)
    yd()
    dlg:CreateStatic(x_grid[2], y):SetText("OR")
    yd()
    dlg:CreateStatic(x_grid[1], y):SetText("More beats in second measure:"):SetWidth(x_grid[4] + 20)
    dlg:CreateCheckbox(x_grid[3], y, "4"):SetCheck(config.odd_more_first and 0 or 1):SetText(" 3 -> 1 + 2 etc."):SetWidth(i_width)
    yd(30)
    dlg:CreateHorizontalLine(0, y, x_grid[4] + i_width)
    dlg:CreateHorizontalLine(0, y - 1, x_grid[4] + i_width)
    dlg:CreateHorizontalLine(0, y - 3, x_grid[4] + i_width)
    yd(10)
    dlg:CreateStatic(0, y):SetText("JOIN PAIRS OF MEASURES:"):SetWidth(x_grid[3])
    dlg:CreateStatic(1, y + 1):SetText("JOIN PAIRS OF MEASURES:"):SetWidth(x_grid[3])
    yd(20)
    dlg:CreateStatic(x_grid[1], y):SetText("If both measures have the same time signature ..."):SetWidth(x_grid[5])
    yd(17)
    dlg:CreateStatic(x_grid[1], y):SetText("Double the numerator:"):SetWidth(x_grid[3])
    dlg:CreateCheckbox(x_grid[3], y, "5"):SetCheck(config.double_join and 1 or 0):SetText(" [3/4][3/4] -> [6/4]"):SetWidth(i_width)
    yd()
    dlg:CreateStatic(x_grid[2], y):SetText("OR")
    yd()
    dlg:CreateStatic(x_grid[1], y):SetText("Halve the denominator:"):SetWidth(x_grid[3])
    dlg:CreateCheckbox(x_grid[3], y, "6"):SetCheck(config.double_join and 0 or 1):SetText(" [6/8][6/8] -> [6/4]"):SetWidth(i_width)
    yd(25)
    dlg:CreateHorizontalLine(x_grid[1], y, x_grid[3] + i_width)
    yd(5)
    dlg:CreateStatic(x_grid[1], y):SetText("otherwise ..."):SetWidth(x_grid[2])
    yd(17)
    dlg:CreateStatic(x_grid[1], y):SetText("Composite time signature:"):SetWidth(x_grid[3])
    dlg:CreateCheckbox(x_grid[3], y, "7"):SetCheck(config.composite_join and 1 or 0):SetText(" [2/4][3/8] -> [2/4+3/8]"):SetWidth(i_width)
    yd()
    dlg:CreateStatic(x_grid[2], y):SetText("OR")
    yd()
    dlg:CreateStatic(x_grid[1], y):SetText("Consolidate time signatures:"):SetWidth(x_grid[3])
    dlg:CreateCheckbox(x_grid[3], y, "8"):SetCheck(config.composite_join and 0 or 1):SetText(" [2/4][3/8] -> [7/8]"):SetWidth(i_width)
    yd(25)
    dlg:CreateHorizontalLine(0, y, x_grid[4] + i_width)
    dlg:CreateHorizontalLine(0, y - 1, x_grid[4] + i_width)
    dlg:CreateHorizontalLine(0, y - 3, x_grid[4] + i_width)
    yd(8)
    dlg:CreateCheckbox(0, y, "note_spacing")
        :SetText("Respace notes on completion"):SetCheck(config.note_spacing and 1 or 0):SetWidth(x_grid[5])
    dlg:CreateButton(x_grid[5] - 10, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() finenv.UI():AlertInfo(info, "Measure Span Info") end)
    yd(22)
    dlg:CreateCheckbox(0, y, "repaginate")
        :SetText("Repaginate entire score on completion"):SetCheck(config.repaginate and 1 or 0):SetWidth(x_grid[5])

    -- create radio button action
    local function radio_change(id, check) -- for controls "1" to "4"
        local matching_id = (id % 2 == 0) and (id - 1) or (id + 1)
        dlg:GetControl(tostring(matching_id)):SetCheck((check + 1) % 2)
    end
    for id = 1, 8 do
        dlg:GetControl(tostring(id)):AddHandleCommand(function(self) radio_change(id, self:GetCheck()) end)
    end

    dlg:CreateOkButton()
    dlg:CreateCancelButton()
    dialog_set_position(dlg)

    dlg:RegisterHandleOkButtonPressed(function(self)
        config.halve_numerator = (self:GetControl("1"):GetCheck() == 1)
        config.odd_more_first = (self:GetControl("3"):GetCheck() == 1)
        config.double_join = (self:GetControl("5"):GetCheck() == 1)
        config.composite_join = (self:GetControl("7"):GetCheck() == 1)
        config.note_spacing = (self:GetControl("note_spacing"):GetCheck() == 1)
        config.repaginate = (self:GetControl("repaginate"):GetCheck() == 1)
        dialog_save_position(self) -- save window position and config choices
    end)
    return (dlg:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function eliminate_display_meter(fc_measure)
    if fc_measure.UseTimeSigForDisplay then
        local display_sig = fc_measure.TimeSignatureForDisplay
        if display_sig then display_sig:DeleteData() end
        fc_measure.UseTimeSigForDisplay = false
        fc_measure:Save()
    end
end

function insert_blank_measure_after(measure_num)
    local props_copy = {"PositioningNotesMode", "Barline", "SpaceAfter"}
    local props_set = {"BreakMMRest", "HideCautionary", "IncludeInNumbering", "BreakWordExtension"}
    local measure_1, measure_2 = finale.FCMeasure(), finale.FCMeasure()
    measure_1:Load(measure_num)
    local time_sig = measure_1:GetTimeSignature()
    if time_sig.CompositeTop or time_sig.CompositeBottom then -- ignore measures with composite time_sig
        return 0
    end
    eliminate_display_meter(measure_1)
    finale.FCMeasures.Insert(measure_num + 1, 1)
    measure_2:Load(measure_num + 1)
    for _, v in ipairs(props_copy) do -- copy main measure values
        measure_2[v] = measure_1[v]
    end
    measure_1.Barline = finale.BARLINE_NORMAL
    measure_1.SpaceAfter = 0
    for _, v in ipairs(props_set) do  -- move "section" properties to second measure
        if measure_1[v] then
            measure_1[v] = false
            measure_2[v] = true
        end
    end
    measure_1:Save()
    measure_2:Save()
    return 1 -- added one measure
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

function insert_rest(entry_layer, after_note, duration)
    local newentry = entry_layer:InsertEntriesAfter(after_note, 1, false)
    if newentry ~= nil then
        newentry:MakeRest()
        newentry.Duration = duration
        newentry.Legality = true
        newentry.Visible = true
        entry_layer:Save()
    end
end

function crop_entry_lengths(region, entry_layer, measure_duration)
    for entry in eachentrysaved(region, entry_layer) do
        if entry.MeasurePos >= measure_duration then -- entry starts beyond the barline
            entry.Duration = 0 -- so delete it
        elseif (entry.MeasurePos + entry.ActualDuration) > measure_duration then
            entry.Duration = measure_duration - entry.MeasurePos -- shorten the entry to fit
            -- NOTE: spurious result if last valid note is within a tuplet
        end
    end
end

function pad_or_truncate_cells(measure_rgn, measure_duration)
    local measure_num = measure_rgn.StartMeasure -- should be just one measure wide
    for slot = measure_rgn.StartSlot, measure_rgn.EndSlot do
        local staff = measure_rgn:CalcStaffNumber(slot)
        local cell_rgn = finale.FCMusicRegion()
        cell_rgn:SetRegion(measure_rgn)
        cell_rgn.StartStaff = staff
        cell_rgn.EndStaff = staff
        if region_contains_notes(cell_rgn, 0) then
            for layer_num = 1, layer.max_layers() do
                local entry_layer = finale.FCNoteEntryLayer(layer_num - 1, staff, measure_num, measure_num)
                entry_layer:Load()
                if entry_layer.Count > 0 then
                    local layer_duration = entry_layer:CalcFrameDuration(measure_num)
                    if layer_duration > measure_duration then
                        crop_entry_lengths(cell_rgn, layer_num, measure_duration)
                    elseif layer_duration < measure_duration then
                        local last_note = entry_layer:GetItemAt(entry_layer.Count - 1)
                        insert_rest(entry_layer, last_note, (measure_duration - layer_duration) )
                    end
                end
            end
        end
    end
end

function spread_measure_pair(measure_num, selection)
    local measure_1, measure_2 = mixin.FCMMeasure(), mixin.FCMMeasure()
    measure_1:Load(measure_num)
    measure_2:Load(measure_num + 1)

    local time_sig_1 = measure_1:GetTimeSignature()
    local time_sig_2 = measure_2:GetTimeSignature()
    local top_1 = time_sig_1.Beats
    local top_2 = top_1
    local bottom = time_sig_1.BeatDuration
    if config.halve_numerator then -- HALVE the numerator
        top_1 = top_1 / 2
        if (time_sig_1.Beats % 2) ~= 0 then -- ODD number of beats
            top_1 = math.floor(top_1)
            if config.odd_more_first then
                top_1 = top_1 + 1
            end
        end
        top_2 = time_sig_1.Beats - top_1
    else -- "DOUBLE" the denominator
        bottom = bottom / 2
    end

    local pair_rgn = mixin.FCMMusicRegion()
    pair_rgn:SetRegion(selection):SetStartMeasure(measure_num):SetEndMeasure(measure_num):SetFullMeasureStack()
    pad_or_truncate_cells(pair_rgn, measure_1:GetDuration())

    time_sig_1:SetBeats(top_1):SetBeatDuration(bottom)
    measure_1:Save()
    time_sig_2:SetBeats(top_2):SetBeatDuration(bottom)
    measure_2:Save()
    pair_rgn.EndMeasure = measure_num + 1 -- rebar BOTH measures
    pair_rgn:RebarMusic(finale.REBARSTOP_REGIONEND, true, false)
end

function expand_compound_values(top, bottom)
    if bottom % 3 == 0 then
        bottom = bottom / 3
        top = top * 3
    end
    return top, bottom
end

function join_measures(selection)
    if (selection.EndMeasure - selection.StartMeasure) % 2 ~= 1 then
        finenv.UI():AlertInfo("Please select an EVEN number of measures for the \"Measure Span Join\" action", "User Error")
        return
    end
    -- run through selection backwards by pairs of measures
    local measures_removed = 0
    for measure_num = selection.EndMeasure - 1, selection.StartMeasure, -2 do
        local measure_1, measure_2 = finale.FCMeasure(), finale.FCMeasure()
        measure_1:Load(measure_num)
        measure_2:Load(measure_num + 1)

        local time_sig_1 = measure_1:GetTimeSignature()
        local time_sig_2 = measure_2:GetTimeSignature()
        local top_1 = time_sig_1.Beats
        local top_2 = time_sig_2.Beats
        local bottom_1 = time_sig_1.BeatDuration
        local bottom_2 = time_sig_2.BeatDuration
        local measure_1_dur = measure_1:GetDuration()
        local measure_2_dur = measure_2:GetDuration()

        -- won't deal with composite meters
        if not time_sig_1.CompositeTop and not time_sig_1.CompositeBottom
            and not time_sig_2.CompositeTop and not time_sig_2.CompositeBottom then

            eliminate_display_meter(measure_1)
            if top_1 == top_2 and bottom_1 == bottom_2 then
                if config.double_join then
                    top_1 = top_1 * 2 -- double numerator
                else
                    bottom_1 = bottom_1 * 2 -- halve denominator
                end
            else
                if not config.composite_join then -- CONSOLIDATE the meters
                    top_1, bottom_1 = expand_compound_values(top_1, bottom_1)
                    top_2, bottom_2 = expand_compound_values(top_2, bottom_2)
                    if bottom_1 == bottom_2 then
                        top_1 = top_1 + top_2
                    elseif bottom_1 < bottom_2 then
                        top_1 = top_1 + (top_2 * bottom_2 / bottom_1)
                    else -- bottom_1 > bottom_2
                        top_1 = top_2 +(top_1 * bottom_1 / bottom_2)
                        bottom_1 = bottom_2
                    end
                end
            end

            local paste_rgn = mixin.FCMMusicRegion()
            paste_rgn:SetRegion(selection):SetFullMeasureStack()
            paste_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num)
            pad_or_truncate_cells(paste_rgn, measure_1_dur)
            paste_rgn:SetStartMeasure(measure_num + 1):SetEndMeasure(measure_num + 1)
            pad_or_truncate_cells(paste_rgn, measure_2_dur)

            paste_rgn:CopyMusic()
            paste_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num)

            if config.composite_join then -- create COMPOSITE meter
                local comp_top = finale.FCCompositeTimeSigTop()
                local comp_bot = finale.FCCompositeTimeSigBottom()
                local group_bot = comp_bot:AddGroup(1)
                comp_bot:SetGroupElementBeatDuration(group_bot, 0, bottom_1)

                if bottom_1 == bottom_2 then -- only one composite group
                    local group_top = comp_top:AddGroup(2)
                    comp_top:SetGroupElementBeats(group_top, 0, top_1)
                    comp_top:SetGroupElementBeats(group_top, 1, top_2)
                else -- TWO composite meter groups
                    local group_top = comp_top:AddGroup(1)
                    comp_top:SetGroupElementBeats(group_top, 0, top_1)
                    group_top = comp_top:AddGroup(1)
                    comp_top:SetGroupElementBeats(group_top, 0, top_2)
                    group_bot = comp_bot:AddGroup(1)
                    comp_bot:SetGroupElementBeatDuration(group_bot, 0, bottom_2)
                end
                comp_top:SaveAll()
                comp_bot:SaveAll()
                time_sig_1:SaveNewCompositeTop(comp_top)
                time_sig_1:SaveNewCompositeBottom(comp_bot)
            else
                time_sig_1.Beats = top_1
                time_sig_1.BeatDuration = bottom_1
            end
            measure_1:Save()
            paste_rgn:SetStartMeasurePos(measure_1_dur):SetEndMeasurePosRight():PasteMusic()
            paste_rgn:ReleaseMusic()
            measure_1:Save()
            paste_rgn:SetStartMeasurePos(0):RebarMusic(finale.REBARSTOP_REGIONEND, true, false)
            -- delete the copied (second) measure
            paste_rgn:SetStartMeasure(measure_num + 1):SetEndMeasure(measure_num + 1):CutDeleteMusic()
            paste_rgn:ReleaseMusic()
            paste_rgn:SetStartMeasure(measure_num):SetEndMeasure(measure_num)
        end
        measures_removed = measures_removed + 1
    end
    selection.EndMeasure = selection.EndMeasure - measures_removed
end

function divide_measures(selection)
    local extra_measures = 0
    for measure_number = selection.EndMeasure, selection.StartMeasure, -1 do
        local add = insert_blank_measure_after(measure_number)
        if add > 0 then -- valid new measure added
            spread_measure_pair(measure_number, selection)
            extra_measures = extra_measures + add
        end
    end
    selection.EndMeasure = selection.EndMeasure + extra_measures
end

function measure_span()
    local mod_down = finenv.QueryInvokedModifierKeys and
        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)
         or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
        )
    if mod_down or (span_action == "options") then
        local ok = user_options()
        if not ok or span_action == "options" then return end -- USER cancelled, or doesn't want further action
    end

    local selection = mixin.FCMMusicRegion()
    selection:SetRegion(finenv.Region())
    if span_action == "join" then
        join_measures(selection)
    elseif span_action == "divide" then
        divide_measures(selection)
    else
        return -- unidentified request
    end

    if config.note_spacing then
        local space_rgn = mixin.FCMMusicRegion()
        space_rgn:SetRegion(selection):SetFullMeasureStack()
        space_rgn:SetInDocument()
        finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
    end
    selection:SetInDocument()
    if config.repaginate then
        repaginate()
    end
end

measure_span()

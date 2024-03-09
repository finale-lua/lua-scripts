function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.11"
    finaleplugin.Date = "2024/03/09"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        This script works through every measure of the selection minimising the 
        number of rests on each layer. Whole measures containing rests but 
        no notes are cleared out so they will display the default whole-measure rest. 
        Measures containing notes and rests are dissected down to individual 
        beats and sub-beats to combine small rests into larger rhythmic values. 
        It doesn't change note beaming and doesn't "re-bar" the music, 
        but makes limited rhythmic corrections where rests span beat 
        and sub-beat boundaries, so each boundary is "revealed". 

        It doesn't touch rests within tuplets or measures using 
        composite time signatures (say __2+3/8__). 
        Note that in compound meters (say __12/8__), rests at the start of each 
        beat will be limited to one third of the beat duration. 
        (A quarter note rest at the start of a 3/8 beat will be replaced by 
        two 8th notes). This may be unwanted. 
    ]]
    return "Rest Minimiser", "Rest Minimiser",
        "Delete any rests in the selection that serve no musical function"
end

local layer = require("library.layer")
local mixin = require("library.mixin")

local function clear_whole_cell(cell, layer_num)
    -- cell already identified as containing entries
    local layer_cell = finale.FCNoteEntryLayer(layer_num - 1,
        cell.Staff, cell.Measure, cell.Measure)
    layer_cell:Load()
    for entry in each(layer_cell) do
        if entry:IsNote() then
            return false -- layer measure untouched
        end
    end
    -- found no notes so ...
    layer_cell:ClearAllEntries() -- delete the rests
    return true -- cell layer cleared
end

local function insert_rest_after(rgn, layer_num, rest_entry, duration)
    local layer_cell = mixin.FCMNoteEntryLayer(layer_num - 1, rgn.StartStaff,
        rgn.StartMeasure, rgn.StartMeasure)
    layer_cell:Load()
    local entry = layer_cell:FindEntryNumber(rest_entry)
    local new_rest = layer_cell:InsertEntriesAfter(entry, 1, false)
    if new_rest then
        new_rest:MakeRest():SetLegality(true):SetVisible(true):SetDuration(duration)
        layer_cell:Save()
    end
end

local function measure_duration(measure_number)
    local m = finale.FCMeasure()
    return m:Load(measure_number) and m:GetDuration() or 0
end

local function remove_rests(rgn, beat_width, layer_num)
    local only_rests, no_tuplets = true, true
    for entry in eachentry(rgn, layer_num) do
        if entry:IsNote() then only_rests = false end
        if entry.TupletStartFlag then
            no_tuplets = false
            break -- don't erase rests when tuplets are around
        end
    end
    if only_rests and no_tuplets then
        local first, rests_replaced = true, 0
        local first_pos, first_rest_num
        for entry in eachentrysaved(rgn, layer_num) do
            if first then -- first rest: change duration to beat-width
                first = false
                first_pos = entry.MeasurePos
                rests_replaced = entry.ActualDuration
                first_rest_num = entry.EntryNumber
                entry.Duration = beat_width
            else
                rests_replaced = rests_replaced + entry.ActualDuration
                entry.Duration = 0 -- delete rests 2+
            end
        end
        local extra_rest = rests_replaced - beat_width
        if extra_rest > 0 and -- end of rest group is within measure boundary
            (first_pos + rests_replaced) <= measure_duration(rgn.StartMeasure)
            then -- need to add a follow-on rest
            insert_rest_after(rgn, layer_num, first_rest_num, extra_rest)
        end
    end
    return (only_rests or not no_tuplets) -- this sub-beat is handled
end

local function shift_rgn(rgn, shift)
    rgn.StartMeasurePos = rgn.StartMeasurePos + shift
    rgn.EndMeasurePos = rgn.EndMeasurePos + shift
end

local function minimise_rests()
    local region = finenv.Region()
    local level_div = {} -- number of divisions on each sub-group "level"

    local function check_beat_region(cell, start_pos, beat_wide, level, layer_num)
        local rgn = mixin.FCMMusicRegion() -- instantiate if needed
        rgn:SetStartMeasure(cell.Measure):SetEndMeasure(cell.Measure)
            :SetStartStaff(cell.Staff):SetStartMeasurePos(start_pos)
            :SetEndStaff(cell.Staff):SetEndMeasurePos(start_pos + beat_wide - 1)
        for _ = 1, level_div[level] do -- number of divisions on this level
            if level < #level_div and not remove_rests(rgn, beat_wide, layer_num) then
                -- rests not removed so examine sub-beats
                local new_beat = beat_wide / level_div[level + 1]
                -- recursion to next lower (smaller) sub-group
                check_beat_region(cell, start_pos, new_beat, level + 1, layer_num)
            end
            shift_rgn(rgn, beat_wide) -- shift to next sub-beat
            start_pos = start_pos + beat_wide -- update new sub-beat position
        end
    end

    for cell in each(region:CreateCells()) do
        for layer_num = 1, layer.max_layers() do
            if cell:CalcEntryDuration(layer_num) > 0 then
                -- cell contains entries in this layer
                local time_sig = cell:GetTimeSignature()
                if  not time_sig.CompositeTop and
                    not clear_whole_cell(cell, layer_num)
                    then
                    -- examine by beat group
                    local num_beats = time_sig.Beats
                    local beat_wide = time_sig:CalcLargestBeatDuration()
                    if num_beats % 2 == 0 then -- first examine "double" beat group
                        beat_wide = beat_wide * 2
                        level_div = { num_beats / 2, 2} -- "double" then "whole" beats
                    else
                        level_div = { num_beats } -- "whole" beats only
                    end
                    local n = time_sig:IsCompound() and 3 or 2 -- primary sub-beats
                    table.insert(level_div, n)
                    -- allow another 4 levels of half-beat value-divisions
                    for _ = 1, 4 do table.insert(level_div, 2) end
                    -- examine levels recursively starting at pos 0, level 1
                    check_beat_region(cell, 0, beat_wide, 1, layer_num)
                end
            end
        end
    end
end

minimise_rests()

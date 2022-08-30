--[[
$module Clef

A library of general clef utility functions.
]] --
local clef = {}

local client = require("library.client")

local clef_map = {
    treble = 0,
    alto = 1,
    tenor = 2,
    bass = 3,
    perc_old = 4,
    treble_8ba = 5,
    treble_8vb = 5,
    tenor_voice = 5,
    bass_8ba = 6,
    bass_8vb = 6,
    baritone = 7,
    baritone_f = 7,
    french_violin_clef = 8,
    baritone_c = 9,
    mezzo_soprano = 10,
    soprano = 11,
    percussion = 12,
    perc_new = 12,
    treble_8va = 13,
    bass_8va = 14,
    blank = 15,
    tab_sans = 16,
    tab_serif = 17
}


--[[
% get_cell_clef

Gets the clef for any cell.

@ measure (number) The measure number for the cell
@ staff_number (number) The staff number for the cell
: (number) The clef for the cell
]]
function clef.get_cell_clef(measure, staff_number)
    local cell_clef = -1
    local cell = finale.FCCell(measure, staff_number)
    local cell_frame_hold = finale.FCCellFrameHold()

    cell_frame_hold:ConnectCell(cell)
    if cell_frame_hold:Load() then
        if cell_frame_hold.IsClefList then
            cell_clef = cell_frame_hold:CreateFirstCellClefChange().ClefIndex
        else
            cell_clef = cell_frame_hold.ClefIndex
        end
    end
    return cell_clef
end

--[[
% get_default_clef

Gets the default clef for any staff for a specific region.

@ first_measure (number) The first measure of the region
@ last_measure (number) The last measure of the region
@ staff_number (number) The staff number for the cell
: (number) The default clef for the staff
]]
function clef.get_default_clef(first_measure, last_measure, staff_number)
    local staff = finale.FCStaff()
    local cell_clef = clef.get_cell_clef(first_measure - 1, staff_number)
    if cell_clef < 0 then -- failed, so check clef AFTER insertion
        cell_clef = clef.get_cell_clef(last_measure + 1, staff_number)
        if cell_clef < 0 then -- resort to destination staff default clef
            cell_clef = staff:Load(staff_number) and staff.DefaultClef or 0 -- default treble
        end
    end
    return cell_clef
end

--[[
% restore_default_clef

Restores the default clef for any staff for a specific region.

@ first_measure (number) The first measure of the region
@ last_measure (number) The last measure of the region
@ staff_number (number) The staff number for the cell
]]
function clef.restore_default_clef(first_measure, last_measure, staff_number)
    client.assert_supports("clef_change")

    local default_clef = clef.get_default_clef(first_measure, last_measure, staff_number)

    for measure = first_measure, last_measure do
        local cell = finale.FCCell(measure, staff_number)
        local cell_frame_hold = finale.FCCellFrameHold()
        cell_frame_hold:ConnectCell(cell)
        if cell_frame_hold:Load() then
            cell_frame_hold:MakeCellSingleClef(nil) -- RGPLua v0.60
            cell_frame_hold:SetClefIndex(default_clef)
            cell_frame_hold:Save()
        end
    end
end

--[[
% clef_change

Inserts a clef change in the selected region.

@ clef (string) The clef to change to.
@ region FCMusicRegion The region to change.
]]
function clef.clef_change(clef, region)
    local clef_index = clef_map[clef]
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        if region:IsStaffIncluded(staff:GetItemNo()) then
            local cell_frame_hold = finale.FCCellFrameHold()

            for cell_measure, cell_staff in eachcell(region) do
                local cell = finale.FCCell(cell_measure, cell_staff)
                cell_frame_hold:ConnectCell(cell)
                if cell_frame_hold:Load() then -- Loads... but only if it can, preventing crashes.
                end
                if not region:IsFullMeasureIncluded(cell_measure) then
                    local mid_measure_clefs = cell_frame_hold:CreateCellClefChanges()
                    local new_mid_measure_clefs = finale.FCCellClefChanges()
                    local mid_measure_clef = finale.FCCellClefChange()
                    if not mid_measure_clefs then
                        mid_measure_clefs = finale.FCCellClefChanges()
                        mid_measure_clef:SetClefIndex(cell_frame_hold.ClefIndex)
                        mid_measure_clef:SetMeasurePos(0)
                        mid_measure_clef:Save()
                        mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                        mid_measure_clefs:SaveAllAsNew()
                    end
                    if cell_frame_hold.Measure == region:GetStartMeasure() then
                        mid_measure_clef:SetClefIndex(clef_index)
                        mid_measure_clef:SetMeasurePos(region:GetStartMeasurePos())
                        mid_measure_clef:Save()
                    end
                    if mid_measure_clefs then
                        mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                        mid_measure_clefs:SaveAllAsNew()
                    end

                    local last_clef = cell_frame_hold.ClefIndex
                    local last_clef_added = false

                    for mid_clef in each(mid_measure_clefs) do
                        if region.StartMeasure ~= region.EndMeasure then
                            if (cell_frame_hold.Measure == region.StartMeasure) then
                                if mid_clef.MeasurePos <= region.StartMeasurePos then
                                    new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                    new_mid_measure_clefs:SaveAllAsNew()
                                end
                            end
                            if (cell_frame_hold.Measure == region.EndMeasure) then
                                if mid_clef.MeasurePos <= region.EndMeasurePos then
                                    last_clef = mid_clef.ClefIndex
                                    cell_frame_hold:SetClefIndex(clef_index)
                                    cell_frame_hold:Save()
                                    if mid_clef.MeasurePos == 0 then
                                        mid_clef:SetClefIndex(clef_index)
                                        new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                        new_mid_measure_clefs:SaveAllAsNew()
                                    end
                                else
                                    if not last_clef_added then
                                        mid_measure_clef:SetClefIndex(clef_index)
                                        mid_measure_clef:SetMeasurePos(0)
                                        mid_measure_clef:Save()
                                        new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                                        mid_measure_clef:SetClefIndex(last_clef)
                                        mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                                        mid_measure_clef:Save()
                                        new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                                        new_mid_measure_clefs:SaveAllAsNew()
                                        last_clef_added = true
                                    end
                                    new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                    new_mid_measure_clefs:SaveAllAsNew()
                                end
                            end
                        elseif region.StartMeasure == region.EndMeasure then
                            if mid_clef.MeasurePos <= region.StartMeasurePos then
                                if mid_clef.MeasurePos ~= region.StartMeasurePos then
                                    last_clef = mid_clef.ClefIndex
                                end
                                new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                new_mid_measure_clefs:SaveAllAsNew()
                            elseif mid_clef.MeasurePos <= region.EndMeasurePos then
                                last_clef = mid_clef.ClefIndex
                            else
                                if not last_clef_added then
                                    mid_measure_clef:SetClefIndex(last_clef)
                                    mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                                    mid_measure_clef:Save()
                                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                                    new_mid_measure_clefs:SaveAllAsNew()
                                    last_clef_added = true
                                end
                                new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                                new_mid_measure_clefs:SaveAllAsNew()
                            end
                        end
                    end
                    if not last_clef_added then
                        mid_measure_clef:SetClefIndex(last_clef)
                        mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                        mid_measure_clef:Save()
                        new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                        new_mid_measure_clefs:SaveAllAsNew()
                        last_clef_added = true
                    end
                    -- Removes duplicate clefs:
                    for i = new_mid_measure_clefs.Count - 1, 1, -1 do
                        local later_clef_change = new_mid_measure_clefs:GetItemAt(i)
                        local earlier_clef_change = new_mid_measure_clefs:GetItemAt(i - 1)
                        if earlier_clef_change.ClefIndex == later_clef_change.ClefIndex then
                            new_mid_measure_clefs:ClearItemAt(i)
                            new_mid_measure_clefs:SaveAll()
                        end
                    end
                    --
                    cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                    cell_frame_hold:Save()
                else
                    cell_frame_hold:MakeCellSingleClef(nil) -- RGPLua v0.60
                    cell_frame_hold:SetClefIndex(clef_index)
                    cell_frame_hold:Save()
                end
                if not cell_frame_hold:Load() then
                    cell_frame_hold:SaveNew()
                end

            end
        end
    end
end

return clef

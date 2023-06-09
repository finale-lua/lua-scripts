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
% set_measure_clef

Sets the clefs of of a range measures.

@ first_measure (number) The first measure of the region
@ last_measure (number) The last measure of the region
@ staff_number (number) The staff number for the cell
@ clef_index (number) The clef to set
]]
function clef.set_measure_clef(first_measure, last_measure, staff_number, clef_index)
    client.assert_supports("clef_change")

    for measure = first_measure, last_measure do
        local cell = finale.FCCell(measure, staff_number)
        local cell_frame_hold = finale.FCCellFrameHold()
        local clef_change = cell_frame_hold:CreateFirstCellClefChange()
        clef_change:SetClefIndex(clef_index)
        cell_frame_hold:ConnectCell(cell)
        if cell_frame_hold:Load() then
            cell_frame_hold:MakeCellSingleClef(clef_change) -- RGPLua v0.60
            cell_frame_hold:SetClefIndex(clef_index)
            cell_frame_hold:Save()
        else
            cell_frame_hold:MakeCellSingleClef(clef_change) -- RGPLua v0.60
            cell_frame_hold:SetClefIndex(clef_index)
            cell_frame_hold:SaveNew()
        end
    end
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

    clef.set_measure_clef(first_measure, last_measure, staff_number, default_clef)

    --[[The following section of code has been replaced by the new library function above,
    which should theoretically also be a little more robust than this.
    
    I am leaving this intact, though, in case it needs to be restored for some reason.
    - Jake, Sept 9 2022

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
    ]]
end

--[[
% process_clefs

Processes a table of clef changes and returns them in order, without duplicates.

@ mid_clefs (FCCellClefChanges)
:(FCCellClefChanges) 
]]
function clef.process_clefs(mid_clefs)
    local clefs = {}
    local new_mid_clefs = finale.FCCellClefChanges()
    for mid_clef in each(mid_clefs) do
        table.insert(clefs, mid_clef)
    end
    table.sort(clefs, function (k1, k2) return k1.MeasurePos < k2.MeasurePos end)

    for k, mid_clef in ipairs(clefs) do
        new_mid_clefs:InsertCellClefChange(mid_clef)
        new_mid_clefs:SaveAllAsNew()
    end

    -- Removes duplicate clefs:
    for i = new_mid_clefs.Count - 1, 1, -1 do
        local later_clef_change = new_mid_clefs:GetItemAt(i)
        local earlier_clef_change = new_mid_clefs:GetItemAt(i - 1)
        if later_clef_change.MeasurePos < 0 then
            new_mid_clefs:ClearItemAt(i)
            new_mid_clefs:SaveAll()
            goto continue
        end
        if earlier_clef_change.ClefIndex == later_clef_change.ClefIndex then
            new_mid_clefs:ClearItemAt(i)
            new_mid_clefs:SaveAll()
        end
        ::continue::
    end

    return new_mid_clefs
end

--[[
% clef_change

Inserts a clef change in the selected region.

@ clef (string) The clef to change to.
@ region FCMusicRegion The region to change.
]]
function clef.clef_change(clef_type, region)
    local clef_index = clef_map[clef_type]
    local cell_frame_hold = finale.FCCellFrameHold()
    local last_clef
    local last_staff = -1

    for cell_measure, cell_staff in eachcell(region) do
        local cell = finale.FCCell(region.EndMeasure, cell_staff)
        if cell_staff ~= last_staff then
            last_clef = cell:CalcClefIndexAt(region.EndMeasurePos)
            last_staff = cell_staff
        end
        cell = finale.FCCell(cell_measure, cell_staff)
        cell_frame_hold:ConnectCell(cell)
        if cell_frame_hold:Load() then -- Loads... but only if it can, preventing crashes.
        end

        if  region:IsFullMeasureIncluded(cell_measure) then
            clef.set_measure_clef(cell_measure, cell_measure, cell_staff, clef_index)
            if not region:IsLastEndMeasure() then
                cell = finale.FCCell(cell_measure + 1, cell_staff)
                cell_frame_hold:ConnectCell(cell)
                if cell_frame_hold:Load() then
                    cell_frame_hold:SetClefIndex(last_clef)
                    cell_frame_hold:Save()
                else
                    cell_frame_hold:SetClefIndex(last_clef)
                    cell_frame_hold:SaveNew()
                end
            end


        else -- Process partial measures
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

            if cell_frame_hold.Measure == region.StartMeasure and region.StartMeasure ~= region.EndMeasure then
                -- first copy the clef changes before the region
                for mid_clef in each(mid_measure_clefs) do
                    if mid_clef.MeasurePos < region.StartMeasurePos then
                        new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                        new_mid_measure_clefs:SaveAllAsNew()
                    end
                end
                -- then insert the target clef change
                mid_measure_clef:SetClefIndex(clef_index)
                mid_measure_clef:SetMeasurePos(region.StartMeasurePos)
                mid_measure_clef:Save()
                new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                new_mid_measure_clefs:SaveAllAsNew()
            end

            if cell_frame_hold.Measure == region.EndMeasure and region.StartMeasure ~= region.EndMeasure then
--                local last_clef = cell:CalcClefIndexAt(region.EndMeasurePos)

                for mid_clef in each(mid_measure_clefs) do
                    if mid_clef.MeasurePos == 0 then
                        mid_clef:SetClefIndex(clef_index)
                        mid_clef:Save()
                        new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                        new_mid_measure_clefs:SaveAllAsNew()
                    elseif mid_clef.MeasurePos > region.EndMeasurePos then
                        new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                        new_mid_measure_clefs:SaveAllAsNew()
                    end
                end

                -- then insert the last clef change
                mid_measure_clef:SetClefIndex(last_clef)
                mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                mid_measure_clef:Save()
                new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                new_mid_measure_clefs:SaveAllAsNew()
            end

            if cell_frame_hold.Measure == region.StartMeasure and region.StartMeasure == region.EndMeasure then
                local last_clef = cell:CalcClefIndexAt(region.EndMeasurePos)

                for mid_clef in each(mid_measure_clefs) do
                    if mid_clef.MeasurePos == 0 then
                        if region.StartMeasurePos == 0 then
                            mid_clef:SetClefIndex(clef_index)
                            mid_clef:Save()
                        end
                        new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                        new_mid_measure_clefs:SaveAllAsNew()
                    elseif mid_clef.MeasurePos < region.StartMeasurePos or 
                    mid_clef.MeasurePos > region.EndMeasurePos then
                        new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                        new_mid_measure_clefs:SaveAllAsNew()
                    end
                end
                -- insert region clef change
                mid_measure_clef:SetClefIndex(clef_index)
                mid_measure_clef:SetMeasurePos(region.StartMeasurePos)
                mid_measure_clef:Save()
                new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                new_mid_measure_clefs:SaveAllAsNew()
                -- insert last clef chenge
                mid_measure_clef:SetClefIndex(last_clef)
                mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                mid_measure_clef:Save()
                new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                new_mid_measure_clefs:SaveAllAsNew()
            end
            --
            new_mid_measure_clefs = clef.process_clefs(new_mid_measure_clefs)
            --
            if cell_frame_hold:Load() then
                cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                cell_frame_hold:Save()    
            else
                cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                cell_frame_hold:SaveNew()         
            end
        end
    end
end

return clef
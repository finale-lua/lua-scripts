-- A library of helpful JW Lua scripts
-- Simply import this file to another Lua script to use any of these scripts
local library = {}

function library.add_augmentation_dot(entry)
    entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
end

function library.get_next_same_v(entry)
    local next_entry = entry:Next()
    if entry.Voice2 then
        if (nil ~= next_entry) and next_entry.Voice2 then
            return next_entry
        end
        return nil
    end
    if entry.Voice2Launch then
        while (nil ~= next_entry) and next_entry.Voice2 do
            next_entry = next_entry:Next()
        end
    end
    return next_entry
end

function library.group_overlaps_region(staff_group, region)
    if region:IsFullDocumentSpan() then
        return true
    end
    local staff_exists = false
    local sys_staves = finale.FCSystemStaves()
    sys_staves:LoadAllForRegion(region)
    for sys_staff in each(sys_staves) do
        if staff_group:ContainsStaff(sys_staff:GetStaff()) then
            staff_exists = true
            break
        end
    end
    if not staff_exists then
        return false
    end
    if (staff_group.StartMeasure > region.EndMeasure) or (staff_group.EndMeasure < region.StartMeasure) then
        return false
    end
    return true
end

-- this function requires the entire group to be contained
-- if the start or end staff are not visible in the region,
-- it returns false

function library.group_is_contained_in_region(staff_group, region)
    if not region:IsStaffIncluded(staff_group.StartStaff) then
        return false
    end
    if not region:IsStaffIncluded(staff_group.EndStaff) then
        return false
    end
    return true
end

function library.staff_group_is_multistaff_instrument(staff_group)
    local multistaff_instruments = finale.FCMultiStaffInstruments()
    multistaff_instruments:LoadAll()
    for inst in each(multistaff_instruments) do
        if inst:ContainsStaff(staff_group.StartStaff) and (inst.GroupID == staff_group:GetItemID()) then
            return true
        end
    end
    return false
end

function library.get_selected_region_or_whole_doc()
    local sel_region = finenv.Region()
    if sel_region:IsEmpty() then
        sel_region:SetFullDocument()
    end
    return sel_region
end

return library

function plugindef()
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "6/28/2022"
    finaleplugin.AdditionalMenuOptions = [[
        Lock Systems (Score)
        Lock Systems (Parts)
    ]]
    finaleplugin.AdditionalUndoText = [[
        Lock Systems (Score)
        Lock Systems (Parts)
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Lock All Systems (Score)
        Lock All Systems (Parts)
    ]]
    finaleplugin.AdditionalPrefixes = [[
        lock = "Score"
        lock = "Parts"
    ]]
    return "Lock Systems (All)", "Lock Systems (All)", "Lock All Systems (Score & Parts)"
end

lock = lock or "All"

function systems_lock()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    for sys in each(systems) do
        local start = sys:GetFirstMeasure()
        local next_sys = sys:GetNextSysMeasure()
        local freeze = sys:CreateFreezeSystem(true)
        if freeze then
            freeze:SetNextSysMeasure(next_sys)
            freeze:Save()
        end
        sys:Save()
    end
end

function parts_switch(lock_score, lock_parts)
    local part_current = finale.FCPart(1)
    part_current:SetCurrent()
    local parts = finale.FCParts()
    parts:LoadAll()
    for part in each(parts) do
        if part:IsScore() and lock_score then
            part:SwitchTo()
            systems_lock()
        end
        if part:IsPart() and lock_parts then
            part:SwitchTo()
            systems_lock()
        end
    end
    part_current:SwitchTo()
end

function formatting_systems_lock(lock)
    lock = lock or "All"

    local lock_score = true
    local lock_parts = true

    if lock == "Score" then
        lock_parts = false
    elseif lock == "Parts" then
        lock_score = false
    end

    parts_switch(lock_score, lock_parts)
end

formatting_systems_lock(lock)

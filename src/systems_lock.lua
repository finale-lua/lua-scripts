function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "6/28/2022"
    finaleplugin.AdditionalMenuOptions = [[
        Systems: Lock Score
        Systems: Lock Parts
    ]]
    finaleplugin.AdditionalUndoText = [[
        Systems: Lock Score
        Systems: Lock Parts
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Lock All Systems (Score)
        Lock All Systems (Parts)
    ]]
    finaleplugin.AdditionalPrefixes = [[
        lock = "Score"
        lock = "Parts"
    ]]
    return "Systems: Lock All", "Systems: Lock All", "Lock All Systems (Score & Parts)"
end

    lock = lock or "All"

function formatting_systems_lock(lock)
    lock = lock or "All"

    local lock_score = true
    local lock_parts = true

    if lock == "Score" then
        lock_parts = false
    elseif lock == "Parts" then
        lock_score = false
    end

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

    function parts_switch()
        local part_current = finale.FCPart(1)
        part_current:SetCurrent()
        local parts = finale.FCParts()
        parts:LoadAll()
        for part in each(parts) do
            if part:IsScore() and lock_score == true then
                part:SwitchTo()
                systems_lock()
            end
            if part:IsPart() and lock_parts == true then
                part:SwitchTo()
                systems_lock()
            end
        end
        part_current:SwitchTo()
    end
    parts_switch()
end

formatting_systems_lock(lock)
function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "CJ Garcia"
    finaleplugin.Copyright = "© 2020 CJ Garcia Music"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "6/5/2020"
    finaleplugin.CategoryTags = "UI"
    return "Switch To Selected Part", "Switch To Selected Part", "Switches to the first part of the top staff in a selected region in a score. Switches back to the score if viewing a part."
end

local music_region = finenv.Region()

top_staff = music_region:GetStartStaff()
local parts = finale.FCParts()
parts:LoadAll()
local current_part = parts:GetCurrent()
if current_part:IsScore() then
    local part_ID = nil
    for part in each(parts) do
        if part:IsStaffIncluded(top_staff) then
            part_ID = part:GetID()
        end
    end
    if part_ID ~= nil then
        local part = finale.FCPart(part_ID)
        part:SwitchTo()
    else
        finenv.UI():AlertInfo("Hmm, this part doesn't seem to be generated.\nTry generating parts and try again", "No Part Detected")
    end
else
    local score_ID = parts:GetScore()
    local part = finale.FCPart(score_ID:GetID())
    part:SwitchTo()
end

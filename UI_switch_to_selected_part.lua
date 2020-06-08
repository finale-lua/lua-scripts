function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "CJ Garcia"
    finaleplugin.Copyright = "© 2020 CJ Garcia Music"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "6/5/2020"
    finaleplugin.CategoryTags = "UI"
    return "Switch To Selected Part", "Switch To Selected Part", "Switches to the first part of the top staff in a selected region in a score. Switches back to the score if viewing a part."
end

local music_region = finenv.Region()
local ui = finenv.UI()

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
        part:ViewInDocument()
        --Finale does not always calculate the selected region correctly for the part, leading to an invalid selection state, so fix it when switching to parts
        music_region:SetInstrumentList(0)
        music_region:SetStartStaff(top_staff)
        music_region:SetEndStaff(top_staff)
        music_region:SetInDocument()
        --scroll the selected region into view, because Finale sometimes loses track of it
        ui:MoveToMeasure (music_region:GetStartMeasure(), music_region:GetStartStaff())
    else
        finenv.UI():AlertInfo("Hmm, this part doesn't seem to be generated.\nTry generating parts and try again", "No Part Detected")
    end
else
    local score_ID = parts:GetScore()
    local part = finale.FCPart(score_ID:GetID())
    --Finale manages to keep the selected region displayed when switching back to score, so nothing needs to be done here
    part:ViewInDocument()
   --scroll the selected region into view, because Finale sometimes loses track of it
    ui:MoveToMeasure (music_region:GetStartMeasure(), music_region:GetStartStaff())
end

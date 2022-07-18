function plugindef()
    finaleplugin.NoStore = true
    finaleplugin.Author = "CJ Garcia"
    finaleplugin.Copyright = "© 2020 CJ Garcia Music"
    finaleplugin.Version = "1.2"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "UI"
    return "Switch To Selected Part", "Switch To Selected Part",
           "Switches to the first part of the top staff in a selected region in a score. Switches back to the score if viewing a part."
end

local library = require("library.general_library")

function ui_switch_to_selected_part()

    local music_region = finenv.Region()
    local selection_exists = not music_region:IsEmpty()
    local ui = finenv.UI()

    local top_cell = library.get_top_left_selected_or_visible_cell()
    local parts = finale.FCParts()
    parts:LoadAll()
    local current_part = parts:GetCurrent()
    if current_part:IsScore() then
        local part_ID = nil
        parts:SortByOrderID()
        for part in each(parts) do
            if (not part:IsScore()) and part:IsStaffIncluded(top_cell.Staff) then
                part_ID = part:GetID()
                break
            end
        end
        if part_ID ~= nil then
            local part = finale.FCPart(part_ID)
            part:ViewInDocument()
            -- Finale does not always calculate the selected region correctly for the part, leading to an invalid selection state, so fix it when switching to parts
            if selection_exists then
                music_region:SetInstrumentList(0)
                music_region:SetStartStaff(top_cell.Staff)
                music_region:SetEndStaff(top_cell.Staff)
                music_region:SetInDocument()
            end
            -- scroll the selected region into view, because Finale sometimes loses track of it
            ui:MoveToMeasure(top_cell.Measure, music_region.StartStaff)
        else
            finenv.UI():AlertInfo("Hmm, this part doesn't seem to be generated.\nTry generating parts and try again", "No Part Detected")
        end
    else
        local score_ID = parts:GetScore()
        local part = finale.FCPart(score_ID:GetID())
        -- Finale manages to keep the selected region displayed when switching back to score, so nothing needs to be done here
        part:ViewInDocument()
        -- scroll the selected region into view, because Finale sometimes loses track of it
        ui:MoveToMeasure(top_cell.Measure, top_cell.Staff)
    end

end

ui_switch_to_selected_part()

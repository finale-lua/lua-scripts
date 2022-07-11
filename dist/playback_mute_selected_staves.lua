function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "March 26, 2022"
    finaleplugin.CategoryTags = "Playback"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        Select the staves you want muted, then run this script.
    ]]
    return "Mute selected staves", "Mute selected staves", "Mutes selected staves"
end

function playback_mute_selected_staves()
    local full_doc_region = finale.FCMusicRegion()
    full_doc_region:SetFullDocument()

    local region = finenv.Region()

    for slot = full_doc_region.StartSlot, full_doc_region.EndSlot do
        local staff_number = region:CalcStaffNumber(slot)
        local staff = finale.FCStaff()
        staff:Load(staff_number)
        local playback_data = staff:CreateInstrumentPlaybackData()
        for layer = 1, 4 do
            local layer_definition = playback_data:GetNoteLayerData(layer)
            layer_definition.Play = not region:IsStaffIncluded(staff_number)
        end
        playback_data:Save()
    end
end

playback_mute_selected_staves()

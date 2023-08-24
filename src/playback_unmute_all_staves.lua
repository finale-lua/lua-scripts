function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.2"
    finaleplugin.Date = "March 16, 2023"
    finaleplugin.CategoryTags = "Playback"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        Run this script and all staves will be unmuted.
    ]]
    return "Unmute all staves", "Unmute all staves", "Unmutes all staves"
end

local max_layers = finale.FCLayerPrefs.GetMaxLayers and finale.FCLayerPrefs.GetMaxLayers() or 4

function playback_unmute_all_staves()
    local full_doc_region = finale.FCMusicRegion()
    full_doc_region:SetFullDocument()
    local region = finenv.Region()
    for slot = full_doc_region.StartSlot, full_doc_region.EndSlot do
        local staff_number = region:CalcStaffNumber(slot)
        local staff = finale.FCStaff()
        staff:Load(staff_number)
        local playback_data = staff:CreateInstrumentPlaybackData()
        for layer = 1, max_layers do
            local layer_definition = playback_data:GetNoteLayerData(layer)
            layer_definition.Play = true
        end
        playback_data:Save()
    end
end

playback_unmute_all_staves()

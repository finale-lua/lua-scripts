function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.4"
    finaleplugin.Date = "June 12, 2024"
    finaleplugin.CategoryTags = "Playback"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        Run this script and all staves will be unmuted and all solos will be cleared.
    ]]
    return "Unmute all staves", "Unmute all staves", "Unmutes all staves"
end

local layer = require("library.layer")

function set_layer_playback_data(layer_playback_data)
    layer_playback_data.Play = true
    layer_playback_data.Solo = false
end

function playback_unmute_all_staves()
    local full_doc_region = finale.FCMusicRegion()
    full_doc_region:SetFullDocument()
    local region = finenv.Region()
    for slot = full_doc_region.StartSlot, full_doc_region.EndSlot do
        local staff_number = region:CalcStaffNumber(slot)
        local staff = finale.FCStaff()
        staff:Load(staff_number)
        local playback_data = staff:CreateInstrumentPlaybackData()
        for this_layer = 1, layer.max_layers() do
            set_layer_playback_data(playback_data:GetNoteLayerData(this_layer))
        end
        set_layer_playback_data(playback_data:GetChordLayerData())
        set_layer_playback_data(playback_data:GetMidiExpressionLayerData())
        playback_data:Save()
    end
end

playback_unmute_all_staves()

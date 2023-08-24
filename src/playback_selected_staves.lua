function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "2.0"
    finaleplugin.Date = "August23, 2023"
    finaleplugin.CategoryTags = "Playback"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.ScriptGroupName = "Playback selected staves"
    finaleplugin.ScriptGroupDescription =
    "Set up playback to the selected staves and measures, using either Solo or Mute"
    finaleplugin.AdditionalMenuOptions = [[
        DBG Mute selected staves
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Sets up playback to the selected region by muting selected staves.
    ]]
    finaleplugin.AdditionalPrefixes = [[
        mute_staves = true
    ]]
    finaleplugin.Notes = [[
        Select the staves you want soloed or muted, then run this script. If nothing is selected, all solos and mutes
        are cleared.

        You can optionally set a configuration to start playback at the beginning of the selected region.
        (If nothing selected, it reverts playback to a selected default start measure.)
        To set the options, create a plain text file called
        playback_selected_region.config.txt in a folder called `script_settings` within the same
        folder as the script. It can contain any or all of the following configuration parameters.
        (The default values are shown.)

        ```
        set_playback_start = false                  -- if true, modify the start measure to match the selection or first measure if none
        revert_playback_start = 0                   -- revert to start measure playback when no selection exists
                                                    -- (1 == leftmost and 2 == current counter)
        ```
    ]]
    return "DBG Solo selected staves", "Solo selected staves", "Sets up playback to the selected region."
end

local max_layers = finale.FCLayerPrefs.GetMaxLayers and finale.FCLayerPrefs.GetMaxLayers() or 4

function playback_selected_staves()
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
            layer_definition.Play = not region:IsStaffIncluded(staff_number) or not mute_staves
            layer_definition.Solo = region:IsStaffIncluded(staff_number) and not mute_staves
        end
        playback_data:Save()
    end
end

playback_selected_staves()

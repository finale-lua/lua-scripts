function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "2.0"
    finaleplugin.Date = "August 23, 2023"
    finaleplugin.CategoryTags = "Playback"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.ScriptGroupName = "Playback selected staves"
    finaleplugin.ScriptGroupDescription = [[
        Set up playback to the selected staves and measures, using either Solo or Mute
        and (optionally) modifying the playback start/end measures.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Mute selected staves
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Mute selected staves
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

        You can optionally use a configuration to start playback at the beginning of the selected region.
        (If nothing is selected, it reverts playback to a selected default start option.)
        To set the options, create a plain text file called
        playback_selected_region.config.txt in a folder called `script_settings` within the same
        folder as the script. It can contain any or all of the following configuration parameters.
        (The default values are shown.)

        ```
        set_playback_start = false                  -- if true, modify the playback start measure to match the selection or first measure if none
        revert_playback_start = 0                   -- revert to start measure playback when no selection exists (1 == leftmost, 2 == current counter)
        include_chord_playback = true               -- if true, modify chord playback as well
        include_expression_playback = true          -- if true, modify MIDI expression playback as well
        include_end_measure = false                 -- if true, stop playback at the end measure of the region
        ```
    ]]
    return "Solo selected staves", "Solo selected staves", "Sets up playback to the selected region."
end

local configuration = require("library.configuration")
local layer = require("library.layer")

local config = {
    set_playback_start = false,
    revert_playback_start = finale.PLAYBACKSTART_MEASURE,
    include_chord_playback = true,
    include_expression_playback = true,
    include_end_measure = false
}
configuration.get_parameters("playback_selected_region.config.txt", config)

function set_layer_playback_data(layer_playback_data, region, staff_number)
    layer_playback_data.Play = not region:IsStaffIncluded(staff_number) or not mute_staves
    layer_playback_data.Solo = region:IsStaffIncluded(staff_number) and not mute_staves
end

function playback_selected_staves()
    local full_doc_region = finale.FCMusicRegion()
    full_doc_region:SetFullDocument()

    local region = finenv.Region()

    for slot = full_doc_region.StartSlot, full_doc_region.EndSlot do
        local staff_number = region:CalcStaffNumber(slot)
        local staff = finale.FCStaff()
        staff:Load(staff_number)
        local playback_data = staff:CreateInstrumentPlaybackData()
        for layer = 1, layer.max_layers() do
            set_layer_playback_data(playback_data:GetNoteLayerData(layer), region, staff_number)
        end
        if config.include_chord_playback then
            set_layer_playback_data(playback_data:GetChordLayerData(), region, staff_number)
        end
        if config.include_expression_playback then
            set_layer_playback_data(playback_data:GetMidiExpressionLayerData(), region, staff_number)
        end
        playback_data:Save()
    end

    if config.set_playback_start then
        local playback_prefs = finale.FCPlaybackPrefs()
        if playback_prefs:Load(1) then
            if region:IsEmpty() then
                playback_prefs.StartMode = config.revert_playback_start
                playback_prefs.StartMeasure = 1
                playback_prefs.StopMeasure = 0x7ffe -- this selects the radio button for "End of Piece"
            else
                playback_prefs.StartMode = finale.PLAYBACKSTART_MEASURE
                playback_prefs.StartMeasure = region.StartMeasure
                if config.include_end_measure then
                    playback_prefs.StopMeasure = region.EndMeasure
                end
            end
            playback_prefs:Save()
        end
    end
end

playback_selected_staves()

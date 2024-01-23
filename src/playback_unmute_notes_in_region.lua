function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Version = "1.0.2"
    return "Playback - Unmute Notes", "Playback - Unmute Notes", "Unmutes all the notes in the selected region"
end

function playback_entries_mute(layers_input) -- argument optional
    layers_input = layers_input or {1, 2, 3, 4}
    local layer_playback = {[1] = true, [2] = true, [3] = true, [4] = true}

    for _, v in ipairs(layers_input) do
        layer_playback[v] = false
    end

    for entry in eachentrysaved(finenv.Region()) do
        entry.Playback = layer_playback[entry.LayerNumber]
    end
end

playback_entries_mute({})

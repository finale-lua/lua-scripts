function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "March 26, 2022"
    finaleplugin.CategoryTags = "Playback"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.Notes = [[
        Swaps layers 1 and 2 for the selected region.
    ]]
    return "Layer: Swap 1 & 2", "Layer: Swap 1 & 2", "Swaps layers 1 and 2"
end

local layers = require("library.layer")

function layers_swap_1_2()
    layers.swap(finenv.Region(), 1, 2)
end

layers_swap_1_2()

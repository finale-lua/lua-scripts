function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Version = "v1.04"
    finaleplugin.Date = "2022/05/30"
    finaleplugin.AdditionalMenuOptions = [[ Layer Unmute ]]
    finaleplugin.AdditionalUndoText = [[    Layer Unmute ]]
    finaleplugin.AdditionalPrefixes = [[    unmute_layer = true ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
		Mute the nominated layer, or all layers. 
		RGPLua (0.62 and above) creates a companion menu item, Layer UNMUTE.
	]]
    return "Layer Mute", "Layer Mute", "Mute selected layer(s) with complementary UMMUTE menu"
end

-- default to "mute" layer for "normal" operation
unmute_layer = unmute_layer or false

function choose_layer_to_affect()
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    local vertical = 10
    local horiz_offset = 120
    local edit_width = 50
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra horizontal offset for Mac edit box

    str.LuaString = unmute_layer and "Layer Unmute" or "Layer Mute"
    dialog:SetTitle(str)
    str.LuaString = "Layer# 1-4 (0 = all):"
    local static = dialog:CreateStatic(0, vertical)
    static:SetText(str)
    static:SetWidth(horiz_offset)
    
    local answer = dialog:CreateEdit(horiz_offset, vertical - mac_offset)
    answer:SetInteger(0)  -- set default layer ALL
    answer:SetWidth(edit_width)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return dialog:ExecuteModal(nil), answer:GetInteger()
end

function change_state()
    local ok, layer_number = choose_layer_to_affect()
    if ok ~= finale.EXECMODAL_OK then -- user cancelled
        return -- go home
    end
    if layer_number < 0 or layer_number > 4 then
        finenv.UI():AlertNeutral(
            "(script: " .. plugindef() .. ")",
            "Layer number must be\nbetween 0 and 4\n(not " .. layer_number ..")"
        )
        return -- go home
    end
    for entry in eachentrysaved(finenv.Region(), layer_number) do
        entry.Playback = unmute_layer
    end

end

change_state()

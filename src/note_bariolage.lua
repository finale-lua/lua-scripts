function plugindef()
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "8/1/2022"
    finaleplugin.Notes = [[
        USING THE 'BARIOLAGE' SCRIPT

        This script creates bariolage-style notation where layers 1 and 2 interlock. It works well for material that has even-numbered beam groups like 4x 16th notes or 6x 16th notes (in compound meters). 32nd notes also work. Odd numbers of notes produce undesirable results.

        To use, create a suitable musical passage in layer 1, then run the script. The script does the following:
        - Duplicates layer 1 to layer 2.
        - Mutes playback of layer 2.
        - Iterates through the notes in layer 1. For even-numbered notes (i.e. the 2nd and 4th 16ths in a group of 4) it replaces the stem with a blank shape, effectively hiding it.
        - Any note in layer 1 that is the last note of a beamed group is hidden.
        - Iterates through the notes in layer 2 and changes the stems of the odd-numbered notes.
        - Any note in layer 2 that is the beginning of a beamed group is hidden.

        This script works best when Layer 1 is set to be upstem in multi-layer settings and Layer 2 is set to be downstem.
    ]]
    return "Bariolage", "Bariolage",
           "Bariolage: Creates alternating layer pattern from layer 1. Doesn't play nicely with odd numbered groups!"
end

local layer = require("library.layer")
local note_entry = require("library.note_entry")
---
function bariolage()
    local region = finenv.Region()
    layer.copy(region, 1, 2)
    local odd_layer_ct = 1
    local even_layer_ct = 1
    local odd_layer = 1
    local even_layer = 2
    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() then
            if odd_layer_ct == 1 and even_layer_ct == 1 then
                local next = note_entry.get_next_same_v(entry)
                if next and next:IsNote() and entry.Measure == next.Measure then
                    if entry:CalcHighestStaffPosition() < next:CalcHighestStaffPosition() then
                        odd_layer = 2
                        even_layer = 1
                    end
                end
            end
            if entry.LayerNumber == odd_layer then
                if entry:CalcBeamedGroupEnd() then
                    entry.Visible = false
                end
                if odd_layer_ct % 2 == 0 then
                    note_entry.hide_stem(entry)
                end
                odd_layer_ct = odd_layer_ct + 1
            elseif entry.LayerNumber == even_layer then
                if entry:GetBeamBeat() then
                    entry.Visible = false
                end
                if even_layer_ct % 2 == 1 then
                    note_entry.hide_stem(entry)
                end
                entry:SetPlayback(false)
                even_layer_ct = even_layer_ct + 1
            end
        end
    end
end -- function bariolage

bariolage()

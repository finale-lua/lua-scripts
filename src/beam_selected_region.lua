function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.Notes = [[
        This script beams together any notes or rests in the selected region that can
        be beamed together and breaks beams that cross into or out of the selected
        region at the boundaries of the selected region. The beam options in Finale’s
        Document Settings determine whether rests can be included at the start or end of a beam.
        If you select multiple staves vertically, you can create the same beaming pattern
        across all the staves with a single invocation of the script.

        It does *not* create beams over barlines.

        This script could be particularly useful if you assign it a keystroke using a keyboard macro utility.
    ]]
    return "Beam Selected Region", "Beam Selected Region", "Beam Selected Region"
end

local note_entry = require("library.note_entry")

function beam_selected_region()

    local first_in_beam = true
    local first_in_beam_v2 = false
    local curr_staff = 0
    local curr_layer = -1

    for entry in eachentrysaved(finenv.Region()) do
        if (curr_staff ~= entry:GetStaff()) or (curr_layer ~= entry:GetLayerNumber()) then
            first_in_beam = true
            first_in_beam_v2 = true
            curr_staff = entry:GetStaff()
            curr_layer = entry:GetLayerNumber()
        end
        local isV2 = entry:GetVoice2()
        if not isV2 then
            first_in_beam_v2 = true
        end
        if entry:GetDuration() < 1024 then -- less than quarter note duration
            if (not isV2 and first_in_beam) or (isV2 and first_in_beam_v2) then
                entry:SetBeamBeat(true)
                if not isV2 then
                    first_in_beam = false
                else
                    first_in_beam_v2 = false
                end
            else
                entry:SetBeamBeat(false)
            end
            local next_entry = note_entry.get_next_same_v(entry)
            if (nil ~= next_entry) and (next_entry:GetDuration() < 1024) and
                not finenv.Region():IsEntryPosWithin(next_entry) then
                next_entry:SetBeamBeat(true)
            end
        end
    end
end

beam_selected_region()

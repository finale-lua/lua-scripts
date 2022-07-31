--[[
$module SmartShape
]]
local smartshape = {}


--[[
% smartshape_entrybased

Creates an entry based SmartShape based on two input notes. If a type is not specified, creates a slur.

@ start_note (FCNoteEntry) Starting note for SmartShape.
@ end_note (FCNoteEntry) Ending note for SmartShape.
@ type (SMARTSHAPE_TYPES or string)
]]
function smartshape.add_entry_based_smartshape(start_note, end_note, shape_type)
    local smartshape = finale.FCSmartShape()
    smartshape:SetEntryAttachedFlags(true)
    -- Folks: Let me know if this is just too much... or not enough...
    local types = {"slurauto" = finale.SMARTSHAPE_SLURAUTO, "slur_auto" = finale.SMARTSHAPE_SLURAUTO, "autoslur" = finale.SMARTSHAPE_SLURAUTO, "auto_slur" = finale.SMARTSHAPE_SLURAUTO, 
"slur" = finale.SMARTSHAPE_SLURAUTO, "slurdown" = finale.SMARTSHAPE_SLURDOWN, "slur_down" = finale.SMARTSHAPE_SLURDOWN, "slurup" = finale.SMARTSHAPE_SLURUP, "slur_up" = finale.SMARTSHAPE_SLURUP,"dashed" = finale.SMARTSHAPE_DASHEDSLURAUTO, "dashedslur" = finale.SMARTSHAPE_DASHEDSLURAUTO, "dashed_slur" = finale.SMARTSHAPE_DASHEDSLURAUTO,"dashedslurdown" = finale.SMARTSHAPE_DASHEDSLURDOWN, "dashedslurup" = finale.SMARTSHAPE_DASHEDSLURDOWN, "dashedcurve" = finale.SMARTSHAPE_DASHCURVEAUTO, "dashed_curve" = finale.SMARTSHAPE_DASHCURVEAUTO,"curve" = finale.SMARTSHAPE_DASHCURVEAUTO,"dashedcurvedown", finale.SMARTSHAPE_DASHCURVEDOWN, "dashedcurveup"finale.SMARTSHAPE_DASHCURVEUP, "tabslide" = finale.SMARTSHAPE_TABSLIDE, "tab" = finale.SMARTSHAPE_TABSLIDE, "slide" = finale.SMARTSHAPE_TABSLIDE, "glissando" = finale.SMARTSHAPE_GLISSANDO, "gliss" = finale.SMARTSHAPE_GLISSANDO, "bendhat" = finale.SMARTSHAPE_BEND_HAT, "bend_hat" = finale.SMARTSHAPE_BEND_HAT,"hat" = finale.SMARTSHAPE_BEND_HAT, "bend" = finale.SMARTSHAPE_BEND_HAT, "bendcurve" = finale.SMARTSHAPE_BEND_CURVE, "bend_curve" = finale.SMARTSHAPE_BEND_CURVE}
    --
    if not shape_type then
        shape_type = "slur"
    end
    --
    shape_type = string.lower(shape_type)
    local shape = types[shape_type]
    smartshape:SetShapeType(shape)
    smartshape.PresetShape = true
    if smartshape:IsAutoSlur() then
        smartshape:SetSlurFlags(true)
        smartshape:SetEngraverSlur(finale.SS_AUTOSTATE)
    end
    --
    local leftseg = smartshape:GetTerminateSegmentLeft()
    local rightseg = smartshape:GetTerminateSegmentRight()
    --
    leftseg:SetEntry(start_note)
    leftseg:SetStaff(start_note.Staff)
    leftseg:SetMeasure(start_note.Measure)
--
    rightseg:SetEntry(end_note)
    rightseg:SetStaff(end_note.Staff)
    rightseg:SetMeasure(end_note.Measure)

    if (shape == finale.SMARTSHAPE_TABSLIDE) or (shape == finale.SMARTSHAPE_GLISSANDO) then
        if shape == finale.SMARTSHAPE_GLISSANDO then
            smartshape.LineID = 1
        elseif shape == finale.SMARTSHAPE_TABSLIDE then
            smartshape.LineID = 2
        end
--    smartshape:SetAvoidAccidentals(finale.SS_ONSTATE) -- Actually appears to do nothing :/
        leftseg.NoteID = 1 -- If there is more than 1 note in the entry, shape will be attached to the first one entered
        rightseg.NoteID = 1
        rightseg:SetCustomOffset(true)
        local accidentals = 0
        local start_note_staff_pos = 0
        local end_note_staff_pos = 0
        local offset_y_add = 4
        local offset_x_add = 12
        for note in each(start_note) do
            if note.NoteID == 1 then
                start_note_staff_pos = note:CalcStaffPosition()
            end
        end
        -- Since the lines don't automatically avoid accidentals...
        for note in each(end_note) do
            if note:CalcAccidental() then
                accidentals = accidentals + 1
            end
            if note.NoteID == 1 then
                end_note_staff_pos = note:CalcStaffPosition()
            end
        end
        local staff_pos_difference = start_note_staff_pos - end_note_staff_pos
        if accidentals > 0 then 
            offset_x_add = offset_x_add + 28
        end
        rightseg:SetEndpointOffsetX(rightseg.EndpointOffsetX - offset_x_add)
        rightseg:SetEndpointOffsetY(rightseg.EndpointOffsetY + offset_y_add + (staff_pos_difference/2))
    end
    smartshape:SaveNewEverything(start_note, end_note)
end
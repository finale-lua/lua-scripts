function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.56"
    finaleplugin.Date = "2022/08/22"
    finaleplugin.MinJWLuaVersion = 0.62
	finaleplugin.AdditionalMenuOptions = [[
        Delete Dynamics
        Delete Expressions (Not Dynamics)
        Delete Expressions (Measure-Attached)
        Delete Articulations
        Delete Hairpins
        Delete Slurs
        Delete Custom Lines
        Delete Glissandos
        Delete Smart Shapes (Beat Aligned)
        Delete All Smart Shapes
        Delete MIDI Note Data
        Delete MIDI Continuous Data
     ]]
     finaleplugin.AdditionalUndoText = [[
        Delete Dynamics
        Delete Expressions (Not Dynamics)
        Delete Expressions (Measure-Attached)
        Delete Articulations
        Delete Hairpins
        Delete Slurs
        Delete Custom Lines
        Delete Glissandos
        Delete Smart Shapes (Beat Aligned)
        Delete All Smart Shapes
        Delete MIDI Note Data
        Delete MIDI Continuous Data
	]]
     finaleplugin.AdditionalDescriptions = [[
        Delete dynamics from the selected region
        Delete expressions (not dynamics) from the selected region
        Delete measure-assigned expressions from the selected region
        Delete articulations from the selected region
        Delete hairpins from the selected region
        Delete slurs from the selected region
        Delete custom lines from the selected region
        Delete glissandos from the selected region
        Delete smart shapes (beat aligned) from the selected region
        Delete all smart shapes from the selected region
        Delete MIDI note data (velocity, start/stop times) from the selected region
        Delete MIDI continuous data (controllers, pressure, pitch-bend) from the selected region
    ]]
    finaleplugin.AdditionalPrefixes = [[
        delete_type = "expression_dynamic"
        delete_type = "expression_not_dynamic"
        delete_type = "measure_attached"
        delete_type = "articulation"
        delete_type = "shape_hairpin"
        delete_type = "shape_slur"
        delete_type = "shape_custom"
        delete_type = "shape_glissando"
        delete_type = "shape_beat_aligned"
        delete_type = "shape_all"
        delete_type = "midi_note"
        delete_type = "midi_continuous"
	]]
    finaleplugin.ScriptGroupName = "Delete selective"
    finaleplugin.ScriptGroupDescription = "Selectively delete thirteen different types of data from the currently selected music region"
	finaleplugin.Notes = [[
        Deletes nominated items from the selected region. 
        Individual menu items are created to independently delete items of type:  
        All Expressions / Dynamics / Expressions (Not Dynamics) / Expressions (Measure-Attached) /  
        Articulations / Hairpins / Slurs / Custom Lines / Glissandos / Smart Shapes (Beat Aligned) /  
        All Smart Shapes / Midi Note Data / Midi Continuous Data
    ]]
    return "Delete All Expressions", "Delete All Expressions", "Delete all expressions from the selected region"
end

delete_type = delete_type or "expression_all"

function delete_selected()
    if string.find(delete_type, "shape") then -- SMART SHAPE
        local marks = finale.FCSmartShapeMeasureMarks()
        marks:LoadAllForRegion(finenv.Region(), true)
        for mark in each(marks) do
            local shape = mark:CreateSmartShape()
            if (delete_type == "shape_all")
                or (delete_type == "shape_hairpin" and shape:IsHairpin())
                or (delete_type == "shape_slur" and shape:IsSlur())
                or (delete_type == "shape_custom" and shape:IsCustomLine())
                or (delete_type == "shape_glissando" and shape:IsGlissando())
                or (delete_type == "shape_beat_aligned" and not shape:IsEntryBased())
            then
                shape:DeleteData()
            end
        end
    elseif string.find(delete_type, "express") then -- EXPRESSION type
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(finenv.Region())
        for exp in eachbackwards(expressions) do
            local def_id = exp:CreateTextExpressionDef().CategoryID -- test for DYNAMICS
            if not exp:IsShape() and exp.StaffGroupID == 0 and
              (    (delete_type == "expression_all")
                or (delete_type == "expression_not_dynamic" and def_id ~= finale.DEFAULTCATID_DYNAMICS)
                or (delete_type == "expression_dynamic" and def_id == finale.DEFAULTCATID_DYNAMICS)
              )
            then
                exp:DeleteData()
            end
        end
    elseif delete_type == "midi_continuous" then -- MIDI CONTINUOUS type
        local midi_ex = finale.FCMidiExpressions()
        midi_ex:LoadAllForRegion(finenv.Region())
        for exp in eachbackwards(midi_ex) do
            exp:DeleteData()
        end
    elseif delete_type == "midi_note" then -- MIDI NOTE DATA type
        for entry in eachentrysaved(finenv.Region()) do
            if entry.PerformanceDataFlag then
                local perf_mods = entry:CreatePerformanceMods()
                if perf_mods.Count > 0 then
                    for mod in eachbackwards(perf_mods) do
                        mod:DeleteData()
                    end
                end
                entry.PerformanceDataFlag = false
            end
        end
    elseif delete_type == "measure_attached" then -- MEASURE-ATTACHED EXPRESSIONS type
        local measures = finale.FCMeasures()
        measures:LoadRegion(finenv.Region())
        for measure in each(measures) do
            for exp in eachbackwards(measure:CreateExpressions()) do
                if exp.StaffGroupID > 0 then
                    exp:DeleteData()
                end
            end
            local expression = finale.FCExpression()
            if not expression:Load(measure.ItemNo, 0) then
                measure.ExpressionFlag = false -- no expressions left
                measure:Save()
            end
        end
    elseif delete_type == "articulation" then -- ARTICULATION type
        for entry in eachentrysaved(finenv.Region()) do
            if entry:GetArticulationFlag() then
                for articulation in eachbackwards(entry:CreateArticulations()) do
                    articulation:DeleteData()
                end
                entry:SetArticulationFlag(false)
            end
        end
    end
end

delete_selected()

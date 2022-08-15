function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.51"
    finaleplugin.Date = "2022/06/24"
	finaleplugin.AdditionalMenuOptions = [[
        Delete dynamics
        Delete expressions (not dynamics)
        Delete expressions (measure-attached)
        Delete articulations
        Delete hairpins
        Delete slurs
        Delete custom lines
        Delete glissandos
        Delete smart shapes (beat aligned)
        Delete all smart shapes
     ]]
     finaleplugin.AdditionalUndoText = [[
        Delete dynamics
        Delete expressions (not dynamics)
        Delete expressions (measure-attached)
        Delete articulations
        Delete hairpins
        Delete slurs
        Delete custom lines
        Delete glissandos
        Delete smart shapes (beat aligned)
        Delete all smart shapes
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
	]]
	finaleplugin.Notes = [[
        Deletes nominated items from the selected region,
        defaulting to a primary menu item: "Delete all expressions".
        Under RGPLua (0.62+) nine additional menu items are created
        to independently delete other items of these types:
        dynamics / expressions (not dynamics) / expressions (measure-attached) / articulations /
        hairpins / slurs / custom lines / glissandos / smart shapes (beat aligned) / all smart shapes
    ]]
    return "Delete all expressions", "Delete all expressions", "Delete all expressions from the selected region"
end
delete_type = delete_type or "expression_all"
function delete_selected()
    if string.find(delete_type, "shape") then
        local marks = finale.FCSmartShapeMeasureMarks()
        marks:LoadAllForRegion(finenv.Region(), true)
        for mark in each(marks) do
            local shape = mark:CreateSmartShape()
            if     (delete_type == "shape_hairpin" and shape:IsHairpin())
                or (delete_type == "shape_slur" and shape:IsSlur())
                or (delete_type == "shape_custom" and shape:IsCustomLine())
                or (delete_type == "shape_glissando" and shape:IsGlissando())
                or (delete_type == "shape_beat_aligned" and not shape:IsEntryBased())
                or (delete_type == "shape_all")
            then
                shape:DeleteData()
            end
        end
    elseif string.find(delete_type, "express") then
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(finenv.Region())
        for exp in eachbackwards(expressions) do
            local def_id = exp:CreateTextExpressionDef().CategoryID
            if not exp:IsShape() and exp.StaffGroupID == 0 and
              (    (delete_type == "expression_all")
                or (delete_type == "expression_not_dynamic" and def_id ~= finale.DEFAULTCATID_DYNAMICS)
                or (delete_type == "expression_dynamic" and def_id == finale.DEFAULTCATID_DYNAMICS)
              )
            then
                exp:DeleteData()
            end
        end
    elseif delete_type == "measure_attached" then
        local measures = finale.FCMeasures()
        measures:LoadRegion(finenv.Region())
        local try = finale.FCExpression()
        for measure in each(measures) do
            for exp in eachbackwards(measure:CreateExpressions()) do
                if exp.StaffGroupID > 0 then
                    exp:DeleteData()
                end
            end
            if not try:Load(measure.ItemNo, 0) then
                measure.ExpressionFlag = false
                measure:Save()
            end
        end
    elseif delete_type == "articulation" then
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

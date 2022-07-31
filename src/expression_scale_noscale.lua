function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Jacob Winkler"
--    finaleplugin.AuthorURL = "http://"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.0"
    finaleplugin.Date = "2022/07/30"
    finaleplugin.AdditionalMenuOptions = [[
    Expressions: Scaling ON
    ]]
    finaleplugin.AdditionalUndoText = [[
    Expressions: Scaling ON
    ]]
    finaleplugin.AdditionalDescriptions = [[
    Turns on expression scaling in the selected region.
    ]]
    finaleplugin.AdditionalPrefixes = [[
    scale_bool = true
    ]]
--    finaleplugin.MinJWLuaVersion = 0.63
--    finaleplugin.ScriptGroupName = ""
    finaleplugin.Notes = [[
    This plug-in will set or clear the option to scale with entries in the selected region. It will not work on expressions that are assigned to staff lists, such as tempo marks and tempo alterations.
    ]]
    return "Expressions: Scaling OFF", "Expressions: Scaling OFF", "Turns off expression scaling in the selected region."
end

scale_bool = scale_bool or false

function expressions_scale(scale_bool)
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(finenv.Region())

    for exp in each(expressions) do
        exp:SetScaleWithEntry(scale_bool)
        exp:Save()
    end
end

expressions_scale(scale_bool)
function plugindef()
	finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.53"
    finaleplugin.Date = "2022/05/23"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Notes = [[
    The default setting for new TEMPO expressions is that their playback effect starts at their alignment point in the measure. This can create erratic 'elapsed time' results (metatool '3' with the Selection Tool) if the expression isn't positioned at the exact start of the measure. To avoid this select the Tempo expression, control-click to EDIT EXPRESSION ASSIGNMENT then set playback to start from BEGINNING OF MEASURE. Which is six precise mouse clicks. Or else just run this script over the measures concerned.
]]
    return "Tempo From Beginning", "Tempo From Beginning", "Set tempo markings to start playback at the BEGINNING of each measure"
end
function set_tempo_to_beginning()
    local measures = finale.FCMeasures()
    measures:LoadRegion(finenv.Region())

    for measure in each(measures) do
        for expression in each(measure:CreateExpressions()) do
            local exp_def = expression:CreateTextExpressionDef()
            if exp_def.CategoryID == finale.DEFAULTCATID_TEMPOMARKS
                or exp_def.CategoryID == finale.DEFAULTCATID_TEMPOALTERATIONS
                or exp_def.PlaybackType == finale.EXPPLAYTYPE_TEMPO
                    then
                expression.PlaybackStart = finale.EXPRPLAYSTART_BEGINNINGOFMEASURE
                expression:Save()
            end
        end
    end
end
set_tempo_to_beginning()

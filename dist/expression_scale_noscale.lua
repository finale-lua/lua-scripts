function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Jacob Winkler"

    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.0"
    finaleplugin.Date = "2022/07/30"
    finaleplugin.ScriptGroupName = "Expressions: Scaling"
    finaleplugin.ScriptGroupDescription = [[
    Sets the scaling parameter of any expressions in a selection to on or off. 
    
    By default, if you resize a note or rest, any attached expressions will get scaled by the same amount. By turning scaling to 'off' you can override this behavior and always keep the expression at the defined size.
    
    Note that these scripts do not work on expressions assigned to a staff list, such as those found in the Tempo Marks or Tempo Alterations categories.
    ]]
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


    finaleplugin.Notes = [[
    This plug-in will set or clear the option to scale with entries in the selected region. It will not work on expressions that are assigned to staff lists, such as tempo marks and tempo alterations.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \f0\fs20
        \f1\fs20
        {\pard \ql \f0 \sa180 \li0 \fi0 This plug-in will set or clear the option to scale with entries in the selected region. It will not work on expressions that are assigned to staff lists, such as tempo marks and tempo alterations.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/expression_scale_noscale.hash"
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
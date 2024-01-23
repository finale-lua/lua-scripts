function plugindef()
   -- This function and the 'finaleplugin' namespace
   -- are both reserved for the plug-in definition.
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "March 8, 2021"
    finaleplugin.CategoryTags = "Multimeasure Rest"
    return "Widen Multimeasure Rests to Tempo Mark", "Widen Multimeasure Rests to Tempo Mark", "Widens any multimeasure rest with a tempo mark to be wide enough for the mark."
end

local library = require("library.general_library")
local configuration = require("library.configuration")
local expression = require("library.expression")

local config = {
    additional_padding = 0         -- amount to add to (or subtract from) mmrest length, beyond the width of the tempo mark (evpus)
}

configuration.get_parameters("mmrest_widen_to_tempo_mark.config.txt", config)

-- NOTE: Due to a limitation somewhere in either Finale or the PDK Framework, it is not possible to
--          use CalcMetricPos for expressions assigned to top or bottom staff. Therefore,
--          this function produces best results when the expression is assigned to the individual staves
--          in the parts, rather than just Top Staff or Bottom Staff. However, it works
--          decently well without the get_expression_offset calculation for Top Staff and Bottom Staff
--          assignments, hence the effort in this code to go either way.

function get_expression_offset(exp, cell)
    local mm = finale.FCCellMetrics()
    if not mm:LoadAtCell(cell) then
        return 0
    end
    local point = finale.FCPoint(0, 0)
    if not exp:CalcMetricPos(point) then
        return 0
    end
    local retval = point.X - mm.MusicStartPos
    mm:FreeMetrics()
    return retval
end

function mmrest_widen_to_tempo_mark()
    local measures = finale.FCMeasures()
    local sel_region = library.get_selected_region_or_whole_doc()
    measures:LoadRegion(sel_region)
    for meas in each(measures) do
        local mmrest = finale.FCMultiMeasureRest()
        if mmrest:Load(meas.ItemNo) then
            local expression_assignments = finale.FCExpressions()
            expression_assignments:LoadAllForItem(meas.ItemNo)
            local new_width_top_bot = mmrest.Width
            local got_top_bot = false
            local new_width_staff = mmrest.Width
            local got_staff = false
            for expression_assignment in each(expression_assignments) do
                if not expression_assignment:IsShape() then
                    local expression_def = finale.FCTextExpressionDef()
                    if expression_def:Load(expression_assignment.ID) then
                        if finale.DEFAULTCATID_TEMPOMARKS == expression_def.CategoryID then
                            local this_width = expression.calc_text_width(expression_def, true) + config.additional_padding -- true: expand tags (currently only supports ^value())
                            if expression_assignment.Staff <= 0 then
                                if this_width > new_width_top_bot then
                                    new_width_top_bot = this_width
                                    got_top_bot = true
                                end
                            else
                                local cell = finale.FCCell(meas.ItemNo, expression_assignment.Staff)
                                this_width = this_width + get_expression_offset(expression_assignment, cell)
                                if this_width > new_width_staff then
                                    got_staff = true
                                    new_width_staff = this_width
                                end
                            end
                        end
                    end
                end
            end
            if got_staff then
                mmrest.Width = new_width_staff
                mmrest:Save()
            elseif got_top_bot then
                mmrest.Width = new_width_top_bot
                mmrest:Save()
            end
        end
    end
    library.update_layout()
end

mmrest_widen_to_tempo_mark()

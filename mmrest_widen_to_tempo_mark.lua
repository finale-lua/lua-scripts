function plugindef()
   -- This function and the 'finaleplugin' namespace
   -- are both reserved for the plug-in definition.
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 8, 2021"
    finaleplugin.CategoryTags = "Multimeasure Rest"
    return "Widen Multimeasure Rests to Tempo Mark", "Widen Multimeasure Rests to Tempo Mark", "Widens any multimeasure rest with a tempo mark to be wide enough for the mark."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library.general_library")
local configuration = require("library.configuration")

local config = {
    additional_padding = 48         -- amount to add to mmrest length, beyond the width of the tempo mark (evpus)
}

configuration.get_parameters("mmrest_widen_to_tempo_mark.config.txt", config)

function get_expression_offset(exp, cell)
    local mm = finale.FCCellMetrics()
    if not mm:LoadAtCell(cell) then
        finenv.UI():AlertInfo("met failed, m: " .. tostring(cell.Measure) .. " s: " .. tostring(cell.Staff) , "get_expression_offset")
        return 0
    end
    local point = finale.FCPoint(0, 0)
    if not exp:CalcMetricPos(point) then
        finenv.UI():AlertInfo("calc failed but got muspos: " .. tostring(mm.MusicStartPos), "get_expression_offset")
        return 0
    end
    local retval = mm.MusicStartPos - point.X   -- ToDo: mm.MusicStartPos may need to be scaled. we'll see.
    finenv.UI():AlertInfo("muspos: " .. tostring(mm.MusicStartPos) .. " x: " .. tostring(point.X) .. " diff: " .. tostring(retval), "get_expression_offset")
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
            local new_width = mmrest.Width
            local got1 = false
            for expression_assignment in each(expression_assignments) do
                if not expression_assignment:IsShape() then
                    local expression_def = finale.FCTextExpressionDef()
                    if expression_def:Load(expression_assignment.ID) then
                        if finale.DEFAULTCATID_TEMPOMARKS == expression_def.CategoryID then
                            local text_met = finale.FCTextMetrics()
                            local fcstring = expression_def:CreateTextString()
                            local font_info = fcstring:CreateLastFontInfo()
                            fcstring:TrimEnigmaTags()
                            text_met:LoadString(fcstring, font_info, 100)
                            local cell = finale.FCCell(meas.ItemNo, sel_region.StartStaff)
                            local this_width = text_met:GetAdvanceWidthEVPUs() + config.additional_padding + get_expression_offset(expression_assignment, cell)
                            if this_width > new_width then
                                got1 = true
                                new_width = this_width
                            end
                        end
                    end
                end
            end
            if got1 then
                mmrest.Width = new_width
                mmrest:Save()
            end
        end
    end
    library.update_layout()
end

mmrest_widen_to_tempo_mark()

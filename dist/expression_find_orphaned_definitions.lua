function plugindef()
   -- This function and the 'finaleplugin' namespace
   -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 27, 2020"
    finaleplugin.CategoryTags = "Expression"
    finaleplugin.Notes = [[
        The Expression Selection Dialog expects expression definitions to be stored sequentially and stops looking for definitions
        once the next value is not found. However, Finale can leave orphaned expression definitions with higher values. These
        are inaccessible unless you add in dummy expressions to fill in the gaps. This script builds a report of any such
        expression definitions.
    ]]
    return "Expression Find Orphans", "Expression Find Orphans",
           "Reports any orphaned expression definitions not visible in the Expression Selection Dialog."
end


local new_line_string = "\n"

-- :LoadAll() suffers from the same problem that the Expression Selection Dialog does. It stops looking once it hits a gap.
-- So search all possible values. (It turns out attempting to load non-existent values is not a noticable performance hit.)

local max_value_to_search = 32767

local get_report_string_for_orphans = function(orphaned_exps, is_for_shape)
    local type_string = "Text Expression"
    if is_for_shape then
        type_string = "Shape Expression"
    end
    local report_string = ""
    local is_first = true
    for k, v in pairs(orphaned_exps) do
        local exp_def = nil
        if is_for_shape then
            exp_def = finale.FCShapeExpressionDef()
        else
            exp_def = finale.FCTextExpressionDef()
        end
        if exp_def:Load(v) then
            if not is_first then
                report_string = report_string .. new_line_string
            end
            is_first = false
            report_string = report_string .. type_string .. " " .. exp_def.ItemNo
            if not is_for_shape then
                local text_block = finale.FCTextBlock()
                if text_block:Load(exp_def.TextID) then
                    local raw_text = text_block:CreateRawTextString()
                    if nil ~= raw_text then
                        raw_text:TrimEnigmaFontTags()
                        report_string = report_string .. " " .. raw_text.LuaString
                    end
                end
            end
        end
    end
    return report_string
end

local expression_find_orphans_for_type = function(is_for_shape)
    local exp_def = nil
    if is_for_shape then
        exp_def = finale.FCShapeExpressionDef()
    else
        exp_def = finale.FCTextExpressionDef()
    end
    local count = 0
    local max_valid = 0
    local max_found = 0
    local orphaned_exps = { }
    for try_id = 1, max_value_to_search do
        if exp_def:Load(try_id) then
            max_found = exp_def.ItemNo
            count = count + 1
            if count ~= exp_def.ItemNo then
                table.insert(orphaned_exps, exp_def.ItemNo)
            else
                max_valid = count
            end
        end
    end
    return orphaned_exps, max_valid, max_found
end

function expression_find_orphaned_definitions()
    local orphaned_text_exps, text_max_valid, text_max_found = expression_find_orphans_for_type(false)
    local orphaned_shape_exps, shape_max_valid, shape_max_found = expression_find_orphans_for_type(true)
    local got_orphan = false
    local report_string = ""
    if #orphaned_text_exps > 0 then
        got_orphan = true
        report_string = report_string .. get_report_string_for_orphans(orphaned_text_exps, false)
    end
    if #orphaned_shape_exps > 0 then
        if got_orphan then -- if we found text exps as well
            report_string = report_string .. new_line_string .. new_line_string
        else
            got_orphan = true
        end
        report_string = report_string .. get_report_string_for_orphans(orphaned_shape_exps, true)
    end
    if got_orphan then
        report_string = report_string .. new_line_string .. new_line_string .. "Max Valid Text = " .. text_max_valid .. ". Max Valid Shape = " .. shape_max_valid .. "."
        finenv.UI():AlertInfo(report_string, "Found Orphaned Expressions:")
    else
        finenv.UI():AlertInfo("", "No Orphaned Expressions Found")
    end
end

expression_find_orphaned_definitions()

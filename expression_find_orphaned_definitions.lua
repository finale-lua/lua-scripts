function plugindef()
   -- This function and the 'finaleplugin' namespace
   -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 27, 2020"
    finaleplugin.CategoryTags = "Expression"
    return "Expression Find Orphans", "Expression Find Orphans",
           "Reports any orphaned expression definitions not visible in the Expression Selection Dialog."
end

-- The Expression Selection Dialog expects expression definitions to be stored sequentially and stops looking for definitions
-- once the next value is not found. However, Finale can leave orphaned expression definitions with higher values. These
-- are inaccessible unless you add in dummy expressions to fill in the gaps.

local new_line_string = "\n"

-- :LoadAll() suffers from the same problem that the Expression Selection Dialog does. It stops looking once it hits a gap.
-- So search all possible values. (It turns out attempting to load non-existent values is not a noticable performance hit.)

local max_value_to_search = 32767

local get_report_string_for_orphans = function(orphaned_exps, is_for_shape)
    local type_string = "   Text Expression"
    if is_for_shape then
        type_string = "   Shape Expression"
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

local expression_insert_dummy_exps_for_type = function(max_valid, max_found, is_for_shape)
    for item_no = max_valid+1, max_found do
        if is_for_shape then
            exp_def = finale.FCShapeExpressionDef()
        else
            exp_def = finale.FCTextExpressionDef()
        end
        if not exp_def:Load(item_no) then
            local desc = exp_def:CreateDescription()
            desc.LuaString = "Dummy expression added to reconnect orphaned expression"
            --exp_def:SetDescription(desc)
            if is_for_shape then
                -- not sure what to do here; try leaving it with no shape
            else
                local text = finale.FCString()
                text.LuaString = "Dummy expression"
                exp_def:SaveNewTextBlock(text)
            end
            if not exp_def:DeepSaveAs(item_no) then
                finenv.UI():AlertInfo("SaveAs " .. item_no .. " failed", "DEBUG")
                return false
            end
        end
    end
    return true
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
        report_string = report_string .. new_line_string .. new_line_string .. "Max Valid Text = " .. text_max_valid .. " Max Valid Shape = " .. shape_max_valid
        finenv.UI():AlertInfo(report_string, "Found Orphaned Expressions:")
        if finale.YESRETURN == finenv.UI():AlertYesNo("Dummy expressions will be inserted into the gaps so that the Expression Selection Dialog sees all the orphaned expressions.", "Reconnect Them?") then
            finenv.StartNewUndoBlock("Reconnect Orphaned Expressions", false)
            if #orphaned_text_exps > 0 then
                local text_result = expression_insert_dummy_exps_for_type(text_max_valid, text_max_found, false)
                if not text_result then
                    finenv.UI():AlertError("Unable To Reconnect Orphaned Text Expressions", "Text Expressions")
                    finenv.StartNewUndoBlock("Reconnect Orphaned Expressions", false)
                    return
                end
            end
            if #orphaned_shape_exps > 0 then
                local shape_result = expression_insert_dummy_exps_for_type(shape_max_valid, shape_max_found, true)
                if not shape_result then
                    finenv.UI():AlertError("Unable To Reconnect Orphaned Shape Expressions", "Shape Expressions")
                    finenv.StartNewUndoBlock("Reconnect Orphaned Expressions", false)
                    return
                end
            end
        end
    else
        finenv.UI():AlertInfo("", "No Orphaned Expressions Found")
    end
end

expression_find_orphaned_definitions()

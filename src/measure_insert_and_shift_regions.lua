function plugindef()
    finaleplugin.RequireScore = true
    finaleplugin.RequireSelection = true
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "2024-05-07"
    finaleplugin.Id = "1fef3a2d-42c3-4ab1-a75a-6f245c6b5ec2" 
    finaleplugin.MinJWLuaVersion = 0.71
    finaleplugin.RevisionNotes = [[
        v1.0.1      First release
    ]]
    finaleplugin.Notes = [[
        This script will insert or delete one or more measures; it will then adjust the start
        and end measures of the current and subsequent measure number regions. 

        It can also optionally:

        - Adjust the start numbers of subsequent numeric regions
        - Adjust the numeric prefixes of subsequent regions

        For example, given three measure regions `1-5, 5A-5B, 6-10`, if two measures are
        inserted into the first region and both optional adjustments are enabled, the regions
        will then look like `1-7, 7A-7B, 8-12`.

        The script will stop adjusting start numbers and numeric prefixes
        if it encounters a region with a numeric start number of 1 (indicating a new movement).

        **Note:** At the moment, the script will only delete measures which sit within a 
        single measure region.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Delete Measures and Shift Regions...
    ]]
    finaleplugin.AdditionalUndoText = [[
        Delete Measures and Shift Regions
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Deletes one or more measures and adjusts measure number regions
    ]]
    finaleplugin.AdditionalPrefixes = [[
        mode = "Delete"
    ]]    

    return "Insert Measures and Shift Regions...", "Insert Measures and Shift Regions", 
        "Inserts one or more measures and adjusts measure number regions"
end


local INSERT <const> = "Insert"
local DELETE <const> = "Delete"
mode = mode or INSERT


local mixin <const> = require("library.mixin")
local configuration <const> = require("library.configuration")
local library <const> = require("library.general_library")
local utils <const> = require("library.utils")

local config <const> = {
    adjust_start_number = 1,
    adjust_prefix = 1,    
    number_of_measures = 0,
}

local script_name <const> = library.calc_script_name()
configuration.get_user_settings(script_name, config)

local function confirm_options()
    config.number_of_measures = finenv.Region():CalcMeasureSpan()

    local dialog <const> = mixin.FCMCustomLuaWindow()
        :SetTitle(mode .. " Measures and Shift Regions")

    local max_length = 0
    local function add_checkbox(text, name)
        max_length = math.max(max_length, #text)
        return dialog:CreateCheckbox(0, dialog.Count * 17 - 8, name)
            :DoAutoResizeWidth()
            :SetText(text)
            :SetCheck(config[name])
            :AddHandleCheckChange(function(ctrl)
                config[name] = ctrl:GetCheck()
            end)
    end

    dialog:CreateStatic(0, 0)
        :SetText('Number of Measures')
    dialog:CreateEdit(108, 0)
        :SetWidth(35)
        :SetHeight(17)
        :SetInteger(config.number_of_measures)
        :AddHandleChange(function(ctrl, last_value)
            local value <const> = ctrl:GetText()
            if not value:match("^%d+$") then
                ctrl:SetText(last_value)
            else
                config.number_of_measures = ctrl:GetInteger()
            end
        end)

    local xment <const> = mode:sub(1, 2) .. "crement"
    add_checkbox(xment .. " numeric start numbers for following regions", "adjust_start_number")
        :AddHandleCheckChange(function(source)
            local target = dialog:GetControl("adjust_prefix")
            target:SetEnable(source:GetCheck() == 1)
            if not target:GetEnable() then target:SetCheck(0) end
        end)
    add_checkbox(xment .. " numeric prefixes for following regions", "adjust_prefix")
        :SetEnable(config.adjust_start_number == 1)

    dialog:CreateButton(0, dialog.Count * 17 + 6)
        :SetText("?")
        :DoAutoResizeWidth(0)
        :AddHandleCommand(function() utils.show_notes_dialog(dialog) end)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local result <const> = dialog:ExecuteModal() == finale.EXECMODAL_OK
    if result then
        configuration.save_user_settings(script_name, config)
    end
    return result
end

local function document_measure_count()
    local region <const> = finale.FCMusicRegion()
    region:SetFullDocument()
    return region:CalcMeasureSpan()
end

local function get_end_measure(start_measure, count)
    return start_measure + count - 1
end

local function measures_span_regions(start_measure, count)
    for r in loadall(finale.FCMeasureNumberRegions()) do
        if r:IsMeasureIncluded(start_measure) ~= r:IsMeasureIncluded(get_end_measure(start_measure, count)) then
            return true
        end
    end
    return false
end

local function measure_regions_in_document_order()
    local all_regions <const> = finale.FCMeasureNumberRegions()
    all_regions:LoadAll()
    local result <const> = coll2table(all_regions)
    table.sort(result, function(a, b) return a.StartMeasure < b.StartMeasure end)
    return result
end

local function matches_region(measure_region, start, count)
    return measure_region.StartMeasure == start 
        and measure_region.EndMeasure == get_end_measure(start, count)
end

local function insert_or_delete()
    local pos <const> = finenv.Region().StartMeasure
    local measure_count <const> = config.number_of_measures
    local shift_op

    if mode == INSERT then
        if document_measure_count() + measure_count > 32768 then
            finenv.UI():AlertError("Can't insert that many measures in this document.", "Error")
            return
        end
        finale.FCMeasures.Insert(pos, measure_count, true)
        shift_op = function(n) return n + measure_count end
    else
        if measures_span_regions(pos, measure_count) then
            finenv.UI():AlertError("Can't delete measures that span multiple regions.", "Error")
            return
        end
        finale.FCMeasures.Delete(pos, measure_count)
        shift_op = function(n) return n - measure_count end
    end

    local stop_adjusting_start_numbers = false
    local region_to_delete
    for _, r in ipairs(measure_regions_in_document_order()) do
        if mode == DELETE and matches_region(r, pos, measure_count) then
            -- can't delete directly, because it will mess up the iteration
            region_to_delete = r
            goto continue
        end

        if r.StartMeasure > pos then
            r.StartMeasure = shift_op(r.StartMeasure)
            
            local is_new_movement <const> = r.NumberingStyle == finale.NUMBERING_DIGITS and r.StartNumber == 1
            stop_adjusting_start_numbers = stop_adjusting_start_numbers or is_new_movement

            if config.adjust_start_number == 1  and not stop_adjusting_start_numbers then
                if r.NumberingStyle == finale.NUMBERING_DIGITS then
                    r.StartNumber = shift_op(r.StartNumber)
                elseif config.adjust_prefix == 1 then
                    local str <const> = finale.FCString()
                    r:GetPrefix(str)
                    local prefix <const> = str.LuaString
                    if tonumber(prefix) then
                        str.LuaString = shift_op(prefix)
                        r:SetPrefix(str)
                    end
                end
            end
        end
        if r.EndMeasure >= pos then
            r.EndMeasure = shift_op(r.EndMeasure)
        end
        r:Save()

        ::continue::
    end

    if region_to_delete then
        region_to_delete:DeleteData()
    end
end




if confirm_options() then
    insert_or_delete()
end
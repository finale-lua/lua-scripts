function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "CJ Garcia"
    finaleplugin.Copyright = "2024 MuseCraft Studio"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "7/20/2024"
    finaleplugin.MinJWLuaVersion = 0.66
    finaleplugin.RevisionNotes = [[
        May 27, 2024: Script work began with idea from Burt Goldstein
        May 28, 2024: Version 1.0
        July 20, 2024: Carl Vine edits integrated
        ]]
    finaleplugin.CategoryTags = "Articulation, Expression"
    return "Articulation and Expression Swap...", "Articulation and Expression Swap",
        "Replaces the selected articulation with the selected expression (or vice versa) for the full document if a region is not selected."
end

local config = {
    art_id = 0,
    exp_id = 0,
    show_result = true,
}
local configuration = require("library.configuration")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local name = plugindef():gsub("%.%.%.", "")
configuration.get_user_settings(script_name, config, true)

local function assign_expression(exp_id, entry)
    local exp = finale.FCExpression()
    exp:SetStaff(entry.Staff)
    exp:SetVisible(true)
    exp:SetMeasurePos(entry:GetMeasurePos())
    exp:SetScaleWithEntry(true)
    exp:SetLayerAssignment(entry.LayerNumber)
    exp:SetID(exp_id)
    exp:SaveNewToCell(finale.FCCell(entry.Measure, entry.Staff))
end

local function show_the_results(type, count, id)
    if config.show_result then
        if count ~= 0 then
            local msg = count > 1 and " occurances of " or " occurance of "
            msg = msg .. type .. " ID " .. id
            finenv.UI():AlertInfo("Replaced " .. count .. msg, name .. ": Success")
        else
            finenv.UI():AlertInfo("No occurances of " .. type .. " ID " .. id .. " were found",
                name .. ": Not found")
        end
    end
end

local function run(art_id, exp_id, selected_item)
    local msg = {}
    if art_id == nil or art_id < 1 then
        table.insert(msg, "The Articulation ID must be a digit > 0")
    end
    if exp_id == nil or exp_id < 1 then
        table.insert(msg, "The Expression ID must be a digit > 0")
    end
    if #msg > 0 then
        table.insert(msg, "Exiting process.")
        finenv.UI():AlertInfo(table.concat(msg, "\n\n"), name .. ": Entry Error")
        return
    end

    local function match_item(fc_defs, id)
        fc_defs:LoadAll()
        for a in each(fc_defs) do
            if a:GetItemNo() == id then return true end
        end
        return false
    end
    local has_art = match_item(finale.FCArticulationDefs(), art_id)
    local has_exp = match_item(finale.FCTextExpressionDefs(), exp_id)
    msg = {}
    if not has_art then
        table.insert(msg, "Articulation ID " .. art_id .. " could not be found.")
    end
    if not has_exp then
        table.insert(msg, "Expression ID " .. exp_id .. " could not be found.")
    end
    if #msg > 0 then
        table.insert(msg, "Exiting process.")
        finenv.UI():AlertInfo(table.concat(msg, "\n\n"), name .. ": Items not found")
        return
    end

    local music_region = finenv.Region()
    if music_region:IsEmpty() then
        music_region = finale.FCMusicRegion()
        music_region:SetFullDocument()
    end

    local count = 0
    if selected_item == 0 then
        -- replace articulation with expression
        for noteentry in eachentrysaved(music_region) do
            local arts = noteentry:CreateArticulations()
            for a in eachbackwards(arts) do
                if a:GetID() == art_id then
                    count = count + 1
                    a:DeleteData()
                    assign_expression(exp_id, noteentry)
                end
            end
        end
        show_the_results("articulation", count, art_id)
    else
        -- replace expression with articulation
        for noteentry in eachentrysaved(music_region) do
            local pin_point = finale.FCMusicRegion()
            pin_point:SetStartStaff(noteentry:GetStaff())
            pin_point:SetEndStaff(noteentry:GetStaff())
            pin_point:SetStartMeasure(noteentry:GetMeasure())
            pin_point:SetEndMeasure(noteentry:GetMeasure())
            pin_point:SetStartMeasurePos(noteentry:GetMeasurePos())
            pin_point:SetEndMeasurePos(noteentry:GetMeasurePos())

            local expressions = finale.FCExpressions()
            expressions:LoadAllForRegion(pin_point)
            for exp in eachbackwards(expressions) do
                local ted = exp:CreateTextExpressionDef()
                if ted:GetItemNo() == exp_id then
                    count = count + 1
                    exp:DeleteData()
                    local art = finale.FCArticulation()
                    art:SetNoteEntry(noteentry)
                    art:SetID(art_id)
                    art:SaveNew()
                end
            end
        end
        show_the_results("expression", count, exp_id)
    end
end

local fs = finale.FCString
local dialog = finale.FCCustomLuaWindow()
dialog:SetTitle(fs(name))

local art_button = dialog:CreateButton(0, 45)
art_button:SetText(fs("Select..."))
local exp_button = dialog:CreateButton(150, 45)
exp_button:SetText(fs("Select..."))

local art_text = dialog:CreateStatic(0, 0)
art_text:SetText(fs("Articulation ID"))
local art_box = dialog:CreateEdit(0, 16)
art_box:SetInteger(config.art_id)

local exp_text = dialog:CreateStatic(150, 0)
exp_text:SetText(fs("Expression ID"))
local exp_box = dialog:CreateEdit(150, 16)
exp_box:SetInteger(config.exp_id)

local radio_group = dialog:CreateRadioButtonGroup(0, 70, 2)
local strs = finale.FCStrings()
strs:CopyFromStringTable{
    "Find Articulation, Replace With Expression",
    "Find Expression, Replace With Articulation"
}
radio_group:SetText(strs)
radio_group:SetWidth(240)
local show_result = dialog:CreateCheckbox(0, 105)
show_result:SetWidth(150)
show_result:SetText(fs("Show Results"))
show_result:SetCheck(config.show_result and 1 or 0)

dialog:CreateOkButton()
dialog:CreateCancelButton()

local function get_user_selection(controller)
    if controller:GetControlID() == art_button:GetControlID() then
        art_box:SetInteger(finenv.UI():DisplayArticulationDialog(art_box:GetInteger()))
    elseif controller:GetControlID() == exp_button:GetControlID() then
        exp_box:SetInteger(finenv.UI():DisplayExpressionDialog(exp_box:GetInteger(), false))
    end
end

dialog:RegisterHandleCommand(get_user_selection)

if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
    config.art_id = art_box:GetInteger()
    config.exp_id = exp_box:GetInteger()
    config.show_result = (show_result:GetCheck() == 1)
    configuration.save_user_settings(script_name, config)
    run(config.art_id, config.exp_id, radio_group:GetSelectedItem())
end

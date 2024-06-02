function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "CJ Garcia"
    finaleplugin.Copyright = "2024 MuseCraft Studio"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "5/27/2024"
    finaleplugin.RevisionNotes = [[
        May 27, 2024: Script work began with idea from Burt Goldstein
        May 28, 2024: Version 1.0
        ]]
    finaleplugin.CategoryTags = "Articulation, Expression"
    return "Articulation and Expression Swap", "Articulation and Expression Swap",
        "Replaces the selected articulation with the selected expression (or vice versa) for the full document if a region is not selected."
end

SelectedItem = nil

local function assignExpression(exp_id, entry)
    local exp = finale.FCExpression()
    exp:SetStaff(entry.Staff)
    exp:SetVisible(true)
    exp:SetMeasurePos(entry:GetMeasurePos())
    exp:SetScaleWithEntry(true)
    exp:SetLayerAssignment(entry.LayerNumber)
    exp:SetID(exp_id)

    local note_cell = finale.FCCell(entry.Measure, entry.Staff)
    exp:SaveNewToCell(note_cell)
end

local function run(art_id, exp_id)
    if (art_id == nil) and (exp_id ~= nil) then
        finenv.UI():AlertInfo("Articulation ID must be a number. Exiting process", "Articulation entry error")
        return
    elseif (art_id ~= nil) and (exp_id == nil) then
        finenv.UI():AlertInfo("Expression ID must be a number. Exiting process", "Expression entry error")
        return
    elseif (art_id == nil) and (exp_id == nil) then
        finenv.UI():AlertInfo("The articulation ID and expression ID must both be a number. Exiting process",
            "Entry error")
        return
    end

    local art_defs = finale.FCArticulationDefs()
    art_defs:LoadAll()
    local has_art = false
    for art in each(art_defs) do
        if art:GetItemNo() == art_id then
            has_art = true
            break
        end
    end

    local exp_defs = finale.FCTextExpressionDefs()
    exp_defs:LoadAll()
    local has_exp = false
    for ted in each(exp_defs) do
        if ted:GetItemNo() == exp_id then
            has_exp = true
            break
        end
    end

    if (has_art ~= true) and (has_exp == true) then
        finenv.UI():AlertInfo("The articulation with ID " .. art_id .. " could not be found. Exiting process",
            "Unable to find articulation")
        return
    elseif (has_art == true) and (has_exp ~= true) then
        finenv.UI():AlertInfo("The expression with ID " .. exp_id .. " could not be found. Exiting process",
            "Unable to find expression")
        return
    elseif (has_art ~= true) and (has_exp ~= true) then
        finenv.UI():AlertInfo(
            "Neither the articulation with ID " ..
            art_id .. " nor the expression with ID " .. exp_id .. " could not be found. Exiting process",
            "Unable to find items")
        return
    end

    local music_region = finenv.Region()
    if music_region:IsEmpty() == true then
        music_region = finale.FCMusicRegion()
        music_region:SetFullDocument()
    end

    local count = 0

    if SelectedItem == 0 then
        -- replace articulation with expression
        for noteentry in eachentrysaved(music_region) do
            local arts = noteentry:CreateArticulations()
            for a in eachbackwards(arts) do
                if a:GetID() == art_id then
                    count = count + 1
                    a:DeleteData()
                    assignExpression(exp_id, noteentry)
                end
            end
        end
        if count ~= 0 then
            if count > 1 then
                finenv.UI():AlertInfo("Replaced " .. count .. " occurances of articulation with the ID of " .. art_id,
                    "Success")
            else
                finenv.UI():AlertInfo("Replaced " .. count .. " occurance of articulation with the ID of " .. art_id,
                    "Success")
            end
        else
            finenv.UI():AlertInfo("No occurances of articulation with the ID of " .. art_id .. " was found.",
                "Nothing found")
        end
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
        if count ~= 0 then
            if count > 1 then
                finenv.UI():AlertInfo("Replaced " .. count .. " occurances of expression with the ID of " .. exp_id,
                    "Success")
            else
                finenv.UI():AlertInfo("Replaced " .. count .. " occurance of expression with the ID of " .. exp_id,
                    "Success")
            end
        else
            finenv.UI():AlertInfo("No occurances of expression with the ID of " .. exp_id .. " was found.",
                "Nothing found")
        end
    end
end

local str = finale.FCString()
str.LuaString = "Articulation Replacement"
local dialog = finale.FCCustomLuaWindow()
dialog:SetTitle(str)

local art_button = dialog:CreateButton(0, 45)
str.LuaString = "Select..."
art_button:SetText(str)

local exp_button = dialog:CreateButton(150, 45)
str.LuaString = "Select..."
exp_button:SetText(str)

local art_text = dialog:CreateStatic(0, 0)
str.LuaString = "Articulation ID"
art_text:SetText(str)
local art_box = dialog:CreateEdit(0, 16)
local art_str = finale.FCString()
art_str.LuaString = ""

local exp_text = dialog:CreateStatic(150, 0)
str.LuaString = "Expression ID"
exp_text:SetText(str)
local exp_box = dialog:CreateEdit(150, 16)
local exp_str = finale.FCString()
exp_str.LuaString = ""

local radio_group = dialog:CreateRadioButtonGroup(0, 100, 2)
local strs = finale.FCStrings()
strs:AddCopy(finale.FCString("Find articulation, replace with expression."))
strs:AddCopy(finale.FCString("Find expression, replace with articulation."))
radio_group:SetText(strs)
radio_group:SetWidth(225)

dialog:CreateOkButton()

dialog:CreateCancelButton()

local function getUserSelection(controller)
    if controller:GetControlID() == art_button:GetControlID() then
        local art_select = finenv.UI():DisplayArticulationDialog(0)
        art_box:SetText(finale.FCString(tostring(art_select)))
    elseif controller:GetControlID() == exp_button:GetControlID() then
        local art_select = finenv.UI():DisplayExpressionDialog(0, false)
        exp_box:SetText(finale.FCString(tostring(art_select)))
    end
end

dialog:RegisterHandleCommand(getUserSelection)

if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
    art_box:GetText(art_str)
    exp_box:GetText(exp_str)
    SelectedItem = radio_group:GetSelectedItem()
    run(tonumber(art_str.LuaString), tonumber(exp_str.LuaString))
end

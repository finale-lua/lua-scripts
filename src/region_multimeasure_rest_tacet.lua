function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "The JWs: Jacob Winkler & Jari Williamsson"
    finaleplugin.Version = "3.0"
    finaleplugin.Date = "12/27/2023"
    finaleplugin.CategoryTags = "Layout, Measure, Rest"
    finaleplugin.Notes = [[
   This script takes a region and creates a multimeasure rest with the text 'TACET'
   above as an expression. The font settings for the expression are taken from the 'Tempo' category.
   If the region includes the last measure of the file but NOT the first measure, it will instead
   create an expression that says 'tacet al fine'.

   If you are using RGP Lua 0.6 or above, you can override the default text settings by including
   appropriate values for `tacet_text` and/or `al_fine_text` in the optional field in the RGP Lua
   configuration dialog. The default values are:

   ```
   tacet_text = "TACET"
   al_fine_text = "tacet al fine"
   ```
   ]]
    return "TACET", "Create Tacet", "Creates a mm-rest and TACET expression"
end
-- USER VARIABLES--
tacet_text = tacet_text or "TACET" -- The text of TACET expressions created by the script
local tacet_description = "TACET for Multimeasure Rests"
al_fine_text = al_fine_text or "tacet al fine"
local al_fine_description = "'tacet al fine' for Multimeasure Rests"
local nudge_horizontal = -24 -- The amount to nudge_horizontal the expression, in EVPUs. -24 EVPUs = left 1 space
local ui = finenv.UI()
-------------------------------
function tacet_mm(region)
    local al_fine_check = false

    if region.StartMeasure > 1  and region:IsLastEndMeasure() then
        al_fine_check = true
    end
    -- Load the multimeasure rest prefs
    local mm_rest_prefs = finale.FCMultiMeasureRestPrefs()
    mm_rest_prefs:Load(1)

    -- Will not continue if auto-update of mm rests is ON
    if mm_rest_prefs.AutoUpdate then
        local mm_update = ui:AlertYesNo("Automatic Update is ON in the multimeasure preferences. Would you like to turn it OFF and proceed?", "Unable to create tacet:")
        if mm_update == 3 then
            return
        elseif mm_update == 2 then
            mm_rest_prefs.AutoUpdate = false
            mm_rest_prefs:Save()
        end -- if
    end --  if

    -- Delete all old mm rests from the region
    -- (In this case, it's safe to delete from the start, since no relocation of data records takes place.)

    local mm_rests = finale.FCMultiMeasureRests()
    mm_rests:LoadAll()
    for mm in each (mm_rests) do
        if region:IsMeasureIncluded(mm.StartMeasure) or region:IsMeasureIncluded(mm.EndMeasure) then
            mm:DeleteData()
        end -- if
    end -- for

    local mm = finale.FCMultiMeasureRest()
    mm.StartMeasure = region.StartMeasure
    mm.EndMeasure = region.EndMeasure
    -- Copy from the default MM rest definition
    mm.NumberHorizontalAdjust = mm_rest_prefs.NumberHorizontalAdjust
    mm.NumberVerticalAdjust = mm_rest_prefs.NumberVerticalAdjust
    mm.ShapeEndAdjust = mm_rest_prefs.ShapeEndAdjust
    mm.ShapeID = mm_rest_prefs.ShapeID
    mm.ShapeStartAdjust = mm_rest_prefs.ShapeStartAdjust
    mm.StartNumberingAt = 20000 -- A really high value here to hide the number
    mm.SymbolSpace = mm_rest_prefs.SymbolSpace
    mm.UseSymbols = mm_rest_prefs.UseSymbols
    mm.UseSymbolsLessThan = mm_rest_prefs.UseSymbolsLessThan
    mm.Width = mm_rest_prefs.Width
    mm:Save()
    finale.FCStaffSystems.UpdateFullLayout()
--
    tacet_expr(al_fine_check)
end -- end function tacet_mm()

function tacet_expr(al_fine_check)
    local region = finenv.Region()
    --local category_definitions = finale.FCcategory_definitions()
    local misc_cat = finale.FCCategoryDef()
    misc_cat:Load(0)
    local tempo_cat = finale.DEFAULTCATID_TEMPOMARKS
    local tacet_cat = finale.FCCategoryDef()
    local category_definition = finale.FCCategoryDef()
    local category_definitions = finale.FCCategoryDefs()
    
    category_definitions:LoadAll()
    local tacet_cat_num = 0
    local cat_name_string = finale.FCString()
    for cat in eachbackwards(category_definitions) do
        cat_name_string.LuaString = string.lower(cat:CreateName().LuaString)
        if  cat_name_string.LuaString == "tacet" then
            tacet_cat_num = cat.ID
            tacet_cat = cat
        end -- if
    end -- for cat

    local text_expression_definitions = finale.FCTextExpressionDefs()
    text_expression_definitions:LoadAll()
    local tacet_ted = 0
-- find an existing TACET (with the right parameters!)
    local ted_descr = finale.FCString()
    local ted_text = finale.FCString()
    if al_fine_check == true then
        ted_descr.LuaString = al_fine_description
    else
        ted_descr.LuaString = tacet_description
    end
    print(ted_descr.LuaString)


    for ted in each(text_expression_definitions) do
        if ted:CreateDescription().LuaString == ted_descr.LuaString then
            print ("Tacet found at",ted.ItemNo)
            tacet_ted = ted.ItemNo
        end -- if ted:CreateDescription...
    end -- for ted...
    -- if there is no existing TACET, create one
    if tacet_ted == 0 then
        local ex_ted = finale.FCTextExpressionDef()
        local font, text_font
        if tacet_cat_num == 0 then -- If there is no 'tacet' category
            ex_ted:AssignToCategory(misc_cat)
            category_definition:Load(tempo_cat)
            font = category_definition:CreateTextFontInfo()
            text_font = "^fontTxt"..font:CreateEnigmaString(finale.FCString()).LuaString
            ex_ted.HorizontalJustification = 1
            ex_ted.HorizontalAlignmentPoint = 5 -- center over/under music
            ex_ted.HorizontalOffset = nudge_horizontal
            ex_ted.VerticalAlignmentPoint = 3 -- align to staff reference line
            ex_ted.VerticalBaselineOffset = 18
        else
            ex_ted:AssignToCategory(tacet_cat)
            category_definition:Load(tacet_cat_num)
            font = category_definition:CreateTextFontInfo()
            text_font = "^fontTxt"..font:CreateEnigmaString(finale.FCString()).LuaString
        end

        if al_fine_check == true then
            ted_text.LuaString = text_font..al_fine_text
        else
            ted_text.LuaString = text_font..tacet_text
        end
        ex_ted:SetDescription(ted_descr)
        ex_ted:SaveNewTextBlock(ted_text)

        ex_ted:SaveNew()
        tacet_ted = ex_ted.ItemNo
        print ("New TACET created at",tacet_ted)
    end -- if tacet_ted == 0

-- Test to see if mark is there already...
    local tacet_assigned = false
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    --local tacet_assigned = expressions:FindItemNo(tacet_ted, 1)
    for e in each(expressions) do
        local create_def = e:CreateTextExpressionDef()
        if create_def.ItemNo == tacet_ted then
            tacet_assigned = true
            print ("tacet_assigned = ",tacet_assigned)
        end
    end -- for e in expressions...
-- add the TACET mark
    if tacet_assigned == false then
        local system_staves = finale.FCSystemStaves()
        system_staves:LoadScrollView()
        local first_staff = 1
        for sys in each(system_staves) do
            if first_staff == 1 then
                region:SetStartStaff(sys.Staff)
                first_staff = 0
            end -- end "if first_staff == 1"
        end -- end "for sys..."
--
        local measure_num = region.StartMeasure
        local measure_pos = region.StartMeasurePos
        local add_expression = finale.FCExpression()
        local staff_num = region.StartStaff
        add_expression:SetStaff(staff_num)
        add_expression:SetMeasurePos(measure_pos)
        add_expression:SetID(tacet_ted)
        local and_cell = finale.FCCell(measure_num, staff_num)
        add_expression:SaveNewToCell(and_cell)
    end -- if tacet_assigned...
end -- end function tacet_expr()

----
local function process_tacets()

    local region = finenv.Region()
    local parts = finale.FCParts()
    parts:LoadAll()
    local current_part = parts:GetCurrent()

    -- Check for selection...
    if region.StartMeasure == 0 and current_part:IsPart() then
        local process_all = ui:AlertYesNo("There is no active selection. Would you like to process the current part?", "No Selection:")
        if process_all == 3 then
            goto bypass
        elseif process_all == 2 then
            region:SetFullDocument()
            tacet_mm(region)
            goto bypass
        end -- if...
    end -- if StartMeasure == 0

    if current_part:IsScore() then
        local process_score = ui:AlertYesNo("Would you like to process the whole score?", "Score:")
        if process_score == 3 then
            goto bypass
        elseif process_score == 2 then
            region:SetFullDocument()
        end
    end

    for part in each(parts) do
        print("Part number "..part.ItemNo)
        if part:IsPart() then
            part:SwitchTo()
            local count = 0
            local staves = finale.FCSystemStaves()
            staves:LoadScrollView()
            local part_region = finale.FCMusicRegion()
            part_region.StartMeasure = region.StartMeasure
            part_region.StartMeasurePos = region.StartMeasurePos            
            part_region.EndMeasure = region.EndMeasure
            part_region.EndMeasurePos = region.EndMeasurePos
            part_region.StartStaff = staves:GetStartStaff()
            part_region.EndStaff = staves:GetEndStaff()

            for _ in eachentry(part_region) do
                count = count + 1
                if count > 0 then 
                    goto skip_part
                end
            end
--            end
            if count < 1 then
                tacet_mm(part_region)
            end
        end
        ::skip_part::
    end


    current_part:SwitchTo()

    ::bypass::
end

process_tacets()

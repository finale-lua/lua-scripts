function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.69"
    finaleplugin.Date = "2023/01/25"
    finaleplugin.Notes = [[
        This script is keyboard-centred requiring minimal mouse action. 
        It takes music from a nominated layer in the chosen staff and creates a "Cue" version on another staff. 
        The cue copy is reduced in size and muted, and can duplicate nominated markings from the original. 
        It is shifted to the chosen layer with a whole-note rest placed in the original layer.

        Your choices are saved in your preferences folder after each script execution. 
        This script requires an expression category called "Cue Names". 
        Under RGPLua (v0.58+) the category is created automatically if necessary. 
        Under JWLua, before running the script you must create an Expression Category called 
        "Cue Names" containing at least one text expression.
        ]]
    return "Cue Notes Create...", "Cue Notes Create", "Copy as cue notes to another staff"
end

local config = { -- retained and over-written by the user's "settings" file
    copy_articulations  =   false,
    copy_expressions    =   false,
    copy_smartshapes    =   false,
    copy_slurs          =   true,
    copy_clef           =   false,
    copy_lyrics         =   false,
    mute_cuenotes       =   true,
    cuenote_percent     =   70,    -- (75% too big, 66% too small)
    source_layer        =   1,     -- layer the cue comes from
    cuenote_layer       =   3,     -- layer the cue ends up
    rest_layer          =   1,     -- layer for default wholenote rest
    freeze_up_down      =   0,     -- "0" for no freezing, "1" for up, "2" for down
    -- if creating a new "Cue Names" category ...
    cue_category_name   =   "Cue Names",
    cue_font_smaller    =   1, -- how many points smaller than the standard technique expression
}

local configuration = require("library.configuration")
local clef = require("library.clef")
local layer = require("library.layer")

configuration.get_user_settings("cue_notes_create", config, true)

function show_error(error_code)
    local errors = {
        only_one_staff = "Please select just one staff\n as the source for the new cue",
        empty_region = "Please select a region\nwith some notes in it!",
        no_notes_in_source_layer = "The music selected contains\nno notes in layer " .. config.source_layer,
        first_make_expression_category = "You must first create a new Text Expression Category called \""..config.cue_category_name.."\" containing at least one entry",
    }
    local msg = errors[error_code] or "Unknown error condition"
    finenv.UI():AlertNeutral("script: " .. plugindef(), msg)
    return -1
end

function dont_overwrite_existing_music()
    local alert = finenv.UI():AlertOkCancel("script: " .. plugindef(), "Overwrite existing music?")
    return (alert ~= finale.OKRETURN)
end

function region_contains_notes(region, layer_number)
    for entry in eachentry(region, layer_number) do
        if entry.Count > 0 then
            return true
        end
    end
    return false
end

function new_cue_name(source_staff)
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    str.LuaString = "New cue name:"
    dialog:CreateStatic(0, 20):SetText(str)

    local the_name = dialog:CreateEdit(0, 40)
    the_name:SetWidth(200)
    -- copy default name from the source Staff Name
    local staff = finale.FCStaff()
    staff:Load(source_staff)
    the_name:SetText(staff:CreateDisplayFullNameString())

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    the_name:GetText(str)
    return ok, str.LuaString
end

function choose_name_index(name_list)
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
    str.LuaString = "Select cue name:"
    dialog:CreateStatic(0, 20):SetText(str)

    local staff_list = dialog:CreateListBox(0, 40)
    staff_list:SetWidth(200)
    -- item "0" in the list is "*** new name ***"
    str.LuaString = "*** new name ***"
    staff_list:AddString(str)

    -- add all names in the extant list
    for _, v in ipairs(name_list) do
        str.LuaString = v[1]  -- add the name, not the ItemNo
        staff_list:AddString(str)
    end
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, staff_list:GetSelectedItem()
    -- NOTE: returns the chosen INDEX number (0-based)
end

function create_new_expression(exp_name, category_number)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(category_number)
    local tfi = cat_def:CreateTextFontInfo()
    local str = finale.FCString()
    str.LuaString = "^fontTxt"
        .. tfi:CreateEnigmaString(finale.FCString()).LuaString
        .. exp_name
    local ted = finale.FCTextExpressionDef()
    ted:SaveNewTextBlock(str)
    ted:AssignToCategory(cat_def)
    ted:SetUseCategoryPos(true)
    ted:SetUseCategoryFont(true)
    ted:SaveNew()
    return ted:GetItemNo() -- *** RETURNS the new expression's ITEM NUMBER
end

function choose_destination_staff(source_staff)
    local staff_list = {}    -- compile all staves in the score
    local rgn = finenv.Region()
    -- compile staff list by slot number
    local original_slot = rgn.StartSlot
    rgn:SetFullMeasureStack()   -- scan the whole stack
    local staff = finale.FCStaff()
    for slot = rgn.StartSlot, rgn.EndSlot do
        local staff_number = rgn:CalcStaffNumber(slot)
        if staff_number ~= source_staff then
            staff:Load(staff_number) -- staff at this slot
            table.insert(staff_list, { staff_number, staff:CreateDisplayFullNameString().LuaString } )
        end
    end
    rgn.StartSlot = original_slot -- restore original single staff
    rgn.EndSlot = original_slot

    -- draw up the dialog box
    local x_grid = { 210, 310, 360 }
    local y_step = 20
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- + vertical offset for Mac edit boxes
    local user_checks = {
        "copy_articulations",  "copy_expressions",  "copy_smartshapes",
        "copy_slurs",          "copy_clef",         "copy_lyrics",
        "mute_cuenotes",       "cuenote_percent",   "source_layer",   "cuenote_layer",
        -- note that [config.freeze_up_down] is a special case
    }
    local integer_options = { -- numeric, not boolean options
        cuenote_percent = true,
        source_layer = true,
        cuenote_layer = true
    }
    local user_selections = {}  -- an array of controls corresponding to user choices

    local str = finale.FCString()
    local dialog = finale.FCCustomLuaWindow()
    str.LuaString = plugindef()
    dialog:SetTitle(str)
    local static = dialog:CreateStatic(0, 0)
    str.LuaString = "Select destination staff:"
    static:SetText(str)
    static:SetWidth(200)

    local list_box = dialog:CreateListBox(0, y_step)
    list_box.UseCheckboxes = true
    list_box:SetWidth(200)
    for _, v in ipairs(staff_list) do -- list all staff names
        str.LuaString = v[2]
        list_box:AddString(str)
    end
    -- add user options
    str.LuaString = "Cue Options:"
    dialog:CreateStatic(x_grid[1], 0):SetText(str)

    for i, v in ipairs(user_checks) do -- run through config parameter list
        str.LuaString = string.gsub(v, '_', ' ')
        local y = y_step * i
        if integer_options[v] then
            str.LuaString = str.LuaString .. ":"
            dialog:CreateStatic(x_grid[1], y):SetText(str)
            user_selections[v] = dialog:CreateEdit(x_grid[2], y - mac_offset)
            user_selections[v]:SetInteger(config[v])
            user_selections[v]:SetWidth(50)
        else
            user_selections[v] = dialog:CreateCheckbox(x_grid[1], y)
            user_selections[v]:SetText(str)
            user_selections[v]:SetWidth(120)
            local checked = config[v] and 1 or 0
            user_selections[v]:SetCheck(checked)
        end
    end
    -- popup for stem direction -> config.freeze_up_down
    local stem_direction_popup = dialog:CreatePopup(x_grid[1], ((#user_checks + 1) * y_step + 5))
    str.LuaString = "Stems: normal"
    stem_direction_popup:AddString(str)  -- config.freeze_up_down == 0 (normal)
    str.LuaString = "Stems: freeze up"
    stem_direction_popup:AddString(str)  -- config.freeze_up_down == 1 (up)
    str.LuaString = "Stems: freeze down"
    stem_direction_popup:AddString(str)  -- config.freeze_up_down == 2 (down)
    stem_direction_popup:SetWidth(160)
    stem_direction_popup:SetSelectedItem(config.freeze_up_down) -- 0-based index

    -- "CLEAR ALL" button to CLEAR all booleans
    local clear_button = dialog:CreateButton(x_grid[3], y_step * 2)
    str.LuaString = "Clear All"
    clear_button:SetWidth(80)
    clear_button:SetText(str)
    dialog:RegisterHandleControlEvent ( clear_button,
        function()
            for _, v in ipairs(user_checks) do
                if not integer_options[v] then
                    user_selections[v]:SetCheck(0)
                end
            end
            list_box:SetKeyboardFocus()
        end
    )

    -- "SET ALL" button to SET all booleans
    local set_button = dialog:CreateButton(x_grid[3], y_step * 4)
    str.LuaString = "Set All"
    set_button:SetWidth(80)
    set_button:SetText(str)
    dialog:RegisterHandleControlEvent ( set_button,
        function()
            for _, v in ipairs(user_checks) do
                if not integer_options[v] then
                    user_selections[v]:SetCheck(1)
                end
            end
            list_box:SetKeyboardFocus()
        end
    )

    -- run the dialog
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    local selected_item = list_box:GetSelectedItem() -- retrieve user staff selection (index base 0)
    local chosen_staff_number = staff_list[selected_item + 1][1]

    if ok then -- save changed User Prefs
        for i, v in ipairs(user_checks) do -- run through config parameters
            if integer_options[v] then
                config[v] = user_selections[v]:GetInteger()
                if string.find(v, "layer") and (config[v] < 1 or config[v] > layer.max_layers()) then -- legitimate layer choice?
                    config[v] = (v == "source_layer") and 1 or layer.max_layers() -- make sure layer number is in range
                end
            else
                config[v] = (user_selections[v]:GetCheck() == 1) -- "true" for value 1, boolean checked
            end
        end
        if config.source_layer ~= config.cuenote_layer then
            config.rest_layer = config.source_layer
        else -- make sure the whole-bar rest is in a different layer from the cuenotes
            config.rest_layer = (config.source_layer % layer.max_layers()) + 1
        end
        config.freeze_up_down = stem_direction_popup:GetSelectedItem() -- 0-based index
    end
    return ok, chosen_staff_number
end

function fix_text_expressions(region)
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    for expression in eachbackwards(expressions) do
        if expression.StaffGroupID == 0 then -- note-attached expressions only
            if config.copy_expressions then -- keep them and switch to cuenote layer
                expression.LayerAssignment = config.cuenote_layer
                expression.ScaleWithEntry = true -- and scale to smaller noteheads
                expression:Save()
            else
                expression:DeleteData() -- otherwise delete them
            end
        end
    end
end

function copy_to_destination(source_region, destination_staff)
    local destination_region = finale.FCMusicRegion()
    destination_region:SetRegion(source_region)
    destination_region:CopyMusic() -- copy the original
    destination_region.StartStaff = destination_staff
    destination_region.EndStaff = destination_staff

    if region_contains_notes(destination_region, 0) and dont_overwrite_existing_music() then
        destination_region:ReleaseMusic() -- clear memory
        return false -- and go home
    end
    if not region_contains_notes(source_region, config.source_layer) then
        destination_region:ReleaseMusic() -- clear memory
        show_error("no_notes_in_source_layer")
        return false -- and go home
    end
    -- otherwise carry on ...
    destination_region:PasteMusic()   -- paste the copy
    destination_region:ReleaseMusic() -- and release memory
    for layer_number = 1, 4 do     -- clear out non-source layers
        if layer_number ~= config.source_layer then
            layer.clear(destination_region, layer_number)
        end
    end

    -- mute / set to % size / delete articulations? / freeze stems? / delete lyrics?
    for entry in eachentrysaved(destination_region) do
        if entry:IsNote() and config.mute_cuenotes then
            entry.Playback = false
        end
        entry:SetNoteDetailFlag(true)
        local entry_mod = finale.FCEntryAlterMod()
        entry_mod:SetNoteEntry(entry)
        entry_mod:SetResize(config.cuenote_percent)
        entry_mod:Save()

        if entry.ArticulationFlag and not config.copy_articulations then
            for articulation in each(entry:CreateArticulations()) do
                articulation:DeleteData()
            end
            entry.ArticulationFlag = false
        end
        if entry.LyricFlag and not config.copy_lyrics then -- delete lyrics from copy
            local lyrics = { finale.FCChorusSyllable(), finale.FCSectionSyllable(), finale.FCVerseSyllable() }
            for _, v in ipairs(lyrics) do
                v:SetNoteEntry(entry)
                while v:LoadFirst() do
                    v:DeleteData()
                end
            end
        end
        if config.freeze_up_down > 0 then -- frozen stems requested
            entry.FreezeStem = true
            entry.StemUp = (config.freeze_up_down == 1) -- "true" -> upstem, "false" -> downstem
        else
            entry.FreezeStem = false
        end
    end
    -- swap layer 1 with cuenote_layer & fix clef
    layer.swap(destination_region, config.source_layer, config.cuenote_layer)
    if not config.copy_clef then
        clef.restore_default_clef(destination_region.StartMeasure, destination_region.EndMeasure, destination_staff)
    end

    -- delete or amend text expressions
    fix_text_expressions(destination_region)
    -- check smart shapes
    if not config.copy_smartshapes or not config.copy_slurs then
        local marks = finale.FCSmartShapeMeasureMarks()
        marks:LoadAllForRegion(destination_region, true)
        for m in each(marks) do
            local shape = m:CreateSmartShape()
            if (shape:IsSlur() and not config.copy_slurs) or (not shape:IsSlur() and not config.copy_smartshapes) then
                shape:DeleteData()
            end
        end
    end

    -- create whole-note rest in rest_layer in each measure
    for measure = destination_region.StartMeasure, destination_region.EndMeasure do
        local notecell = finale.FCNoteEntryCell(measure, destination_staff)
        notecell:Load()
        local whole_note = notecell:AppendEntriesInLayer(config.rest_layer, 1) --   Append to layer 1, add 1 entry
        if whole_note then
            whole_note.Duration = finale.WHOLE_NOTE
            whole_note.Legality = true
            whole_note:MakeRest()
            notecell:Save()
        end
    end
    return true
end

function new_expression_category(new_name)
    local ok = false
    local category_id = 0
    if not finenv.IsRGPLua then  -- SaveNewWithType only works on RGPLua 0.58+
        return ok, category_id   -- and crashes on JWLua
    end
    local new_category = finale.FCCategoryDef()
    new_category:Load(finale.DEFAULTCATID_TECHNIQUETEXT)
    local str = finale.FCString()
    str.LuaString = new_name
    new_category:SetName(str)
    new_category:SetVerticalAlignmentPoint(finale.ALIGNVERT_STAFF_REFERENCE_LINE)
    new_category:SetVerticalBaselineOffset(30)
    new_category:SetHorizontalAlignmentPoint(finale.ALIGNHORIZ_CLICKPOS)
    new_category:SetHorizontalOffset(-18)
    -- make font slightly smaller than standard TECHNIQUE expression
    local tfi = new_category:CreateTextFontInfo()
    tfi.Size = tfi.Size - config.cue_font_smaller
    new_category:SetTextFontInfo(tfi)

    ok = new_category:SaveNewWithType(finale.DEFAULTCATID_TECHNIQUETEXT)
    if ok then
        category_id = new_category:GetID()
    end
    return ok, category_id
end

function assign_expression_to_staff(staff_number, measure_number, measure_position, expression_id)
    local new_expression = finale.FCExpression()
    new_expression:SetStaff(staff_number)
    new_expression:SetVisible(true)
    new_expression:SetMeasurePos(measure_position)
    new_expression:SetScaleWithEntry(false) -- could also (possibly) be true!  
    new_expression:SetPartAssignment(true)
    new_expression:SetScoreAssignment(true)
    new_expression:SetID(expression_id)
    new_expression:SaveNewToCell( finale.FCCell(measure_number, staff_number) )
end

function create_cue_notes()
    local cue_names = { }	-- compile NAME/ItemNo of all pre-existing CUE_NAME expressions
    local source_region = finenv.Region()
    local start_staff = source_region.StartStaff
    -- declare all other local variables
    local ok, cd, expression_defs, cat_ID, expression_ID, name_index, destination_staff, new_expression

    if source_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    elseif not region_contains_notes(source_region, 0) then
        return show_error("empty_region")
    end

    cd = finale.FCCategoryDef()
    expression_defs = finale.FCTextExpressionDefs()
    expression_defs:LoadAll()

    -- collate extant cue names
    for text_def in each(expression_defs) do
        cat_ID = text_def.CategoryID
        cd:Load(cat_ID)
        if string.find(cd:CreateName().LuaString, config.cue_category_name) then
            local str = text_def:CreateTextString()
            str:TrimEnigmaTags()
            -- save expresion NAME and ItemNo
            table.insert(cue_names, {str.LuaString, text_def.ItemNo} )
        end
    end
    -- test for pre-existing names
    if #cue_names == 0 then
        -- create a new Text Expression Category
        ok, cat_ID = new_expression_category(config.cue_category_name)
        if not ok then -- creation failed
            return show_error("first_make_expression_category")
        end
    end
    -- choose cue name
    ok, name_index = choose_name_index(cue_names)
    if not ok then return end

    if name_index == 0 then	-- USER wants to provide a new cue name
        ok, new_expression = new_cue_name(start_staff)
        if not ok or new_expression == "" then return end
        expression_ID = create_new_expression(new_expression, cat_ID)
    else  -- otherwise get the ItemNo of chosen pre-existing expression
        expression_ID = cue_names[name_index][2] --([name_index][1] is the item name)
    end
    -- choose destination staff
    ok, destination_staff = choose_destination_staff(start_staff)
    if not ok then return end

    -- save revised config file
    configuration.save_user_settings("cue_notes_create", config)
    -- make the cue copy
    if not copy_to_destination(source_region, destination_staff) then
        return
    end
    -- name the cue
    assign_expression_to_staff(destination_staff, source_region.StartMeasure, 0, expression_ID)
    -- reset visible selection to original staff
    source_region:SetInDocument()
end

create_cue_notes() -- go and do it already

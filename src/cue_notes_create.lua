function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.88"
    finaleplugin.Date = "2023/02/24"
    finaleplugin.Notes = [[
        This script is keyboard-centred requiring minimal mouse action. 
        It takes music from a nominated layer in the selected staff and 
        creates a "Cue" version on one or more other staves. 
        The cue copy is reduced in size and muted, and can duplicate nominated markings from the original. 
        It is shifted to the chosen layer with a whole-note rest placed in the original layer.

        Your preferences are preserved between each script run. 
        This script requires an expression category called "Cue Names". 
        Under RGPLua (v0.58+) a new category is created automatically if needed. 
        To use with JWLua you must first create an Expression Category called "Cue Names". 

        An extra menu item, "Cue Notes Flip Frozen", will look for notes in the chosen 
        "cue note" layer and flip the direction of their stems if they have been "frozen" up or down.  
        ]]
    finaleplugin.AdditionalMenuOptions = [[
        Cue Notes Flip Frozen
    ]]
    finaleplugin.AdditionalUndoText = [[
        Cue Notes Flip Frozen
    ]]
    finaleplugin.AdditionalPrefixes = [[
        action = "flip"
    ]]
    return "Cue Notes Create...", "Cue Notes Create", "Copy as cue notes to another staff"
end

action = action or nil

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
    freeze_up_down      =   0,     -- "0" for no stem freezing, "1" for up, "2" for down, "3" for away from middle
    -- if creating a new "Cue Names" category ...
    cue_category_name   =   "Cue Names",
    cue_font_smaller    =   1, -- how many points smaller than the standard technique expression
    window_pos_x        =   false,
    window_pos_y        =   false,
}

local freeze = {
    none = 0,
    up = 1,
    down = 2,
    away_from_middle = 3
}

local configuration = require("library.configuration")
local clef = require("library.clef")
local layer = require("library.layer")
local mixin = require("library.mixin")

local script_name = "cue_notes_create"
configuration.get_user_settings(script_name, config, true)

function show_error(error_code)
    local errors = {
        only_one_staff = "Please select just one staff\n as the source for the new cue",
        empty_region = "Please select a region\nwith some notes in it!",
        no_notes_in_source_layer = "The music selected contains\nno notes in layer " .. config.source_layer,
        first_make_expression_category = "You must first create a new Text Expression Category called \""..config.cue_category_name.."\" containing at least one entry",
        no_cue_notes = "The region selected contains \nno cue notes in layer " .. config.cuenote_layer
    }
    local msg = errors[error_code] or "Unknown error condition"
    finenv.UI():AlertInfo("script: " .. plugindef(), msg)
    return -1
end

function dont_overwrite_existing_music(staff_number)
    local staff = finale.FCStaff()
    staff:Load(staff_number) -- staff number of this slot
    local msg = "Overwrite existing music on staff: " .. staff:CreateDisplayFullNameString().LuaString .. "?"
    local alert = finenv.UI():AlertOkCancel("script: " .. plugindef(), msg)
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

function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

function new_cue_name(source_staff)
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 20):SetText("New cue name:"):SetWidth(100)

    local staff = finale.FCStaff() -- copy the source Staff Name
    staff:Load(source_staff)
    local the_name = dialog:CreateEdit(0, 40):SetWidth(200):SetText(staff:CreateDisplayFullNameString())
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self) dialog_save_position(self) end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, the_name:GetText()
end

function choose_name_index(name_list)
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 20):SetText("Select cue name:"):SetWidth(100)
    -- menu item [0] is "*** new name ***"
    local staff_list = dialog:CreateListBox(0, 40):SetWidth(200):AddString("*** new name ***")
    for _, v in ipairs(name_list) do -- add all names in the extant list
        staff_list:AddString(v[1])
    end
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self) dialog_save_position(self) end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, staff_list:GetSelectedItem() -- returns the chosen (0-based) INDEX number
end

function create_new_expression(exp_name, category_number)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(category_number)
    local tfi = cat_def:CreateTextFontInfo()
    local str = finale.FCString()
    str.LuaString = "^fontTxt"
        .. tfi:CreateEnigmaString(finale.FCString()).LuaString
        .. exp_name

    local ted = mixin.FCMTextExpressionDef()
    ted:SaveNewTextBlock(str)
        :AssignToCategory(cat_def)
        :SetUseCategoryPos(true)
        :SetUseCategoryFont(true)
        :SaveNew()
    return ted:GetItemNo() -- *** RETURNS the new expression's ITEM NUMBER
end

function choose_destination_staff(source_staff)
    local staff_list = {} -- save number and name of all (other) staves in the score
    local rgn = finale.FCMusicRegion()
    rgn:SetCurrentSelection()
    rgn:SetFullMeasureStack() -- scan the whole stack
    local staff = finale.FCStaff()
    for slot = rgn.StartSlot, rgn.EndSlot do
        local staff_number = rgn:CalcStaffNumber(slot)
        if staff_number ~= source_staff then
            staff:Load(staff_number) -- staff number of this slot
            table.insert(staff_list, { staff_number, staff:CreateDisplayFullNameString().LuaString } )
        end
    end
    local checks = {
        "copy_articulations", "copy_expressions", "copy_smartshapes",
        "copy_slurs", "copy_clef", "copy_lyrics", "mute_cuenotes"
    }
    local integers = { "cuenote_percent", "source_layer", "cuenote_layer" }

    -- make the dialog
    local x_grid = { 210, 310, 370 }
    local y_step = 19
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- + vertical offset for Mac edit boxes

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 20):SetText("Select cue name:"):SetWidth(100)
    local max_rows = #checks + #integers + 2
    local num_rows = (#staff_list > (max_rows + 2)) and max_rows or (#staff_list + 2)
    local data_list = dialog:CreateDataList(0, 0)
        :SetUseCheckboxes(true)
        :SetHeight(num_rows * y_step)
        :AddColumn("Destination Staff(s):", 120)
    if finenv.UI():IsOnMac() then
        data_list:UseAlternatingBackgroundRowColors()
    end
    for _, v in ipairs(staff_list) do -- list all staff names
        local row = data_list:CreateRow()
        row:GetItemAt(0).LuaString = v[2]
    end

    local y = y_step
    dialog:CreateStatic(x_grid[1], 0):SetText("Cue Options:"):SetWidth(150)
    for _, v in ipairs(checks) do -- run through config parameter list
        dialog:CreateCheckbox(x_grid[1], y, v):SetText(string.gsub(v, "_", " ")):SetWidth(120):SetCheck(config[v] and 1 or 0)
        y = y + y_step
    end
    for _, v in ipairs(integers) do -- run through config parameter list
        dialog:CreateStatic(x_grid[1], y):SetText(string.gsub(v, "_", " ") .. ":"):SetWidth(150)
        dialog:CreateEdit(x_grid[2], y - mac_offset, v):SetWidth(50):SetInteger(config[v])
        y = y + y_step
    end

    local stem_popup = dialog:CreatePopup(x_grid[1], y + 5):SetWidth(160)
        :AddString("Stems: normal")  -- == 0 (normal)
        :AddString("Stems: freeze up")  -- == 1 (up)
        :AddString("Stems: freeze down")  -- == 2 (down)
        :AddString("Stems: away from middle")  -- == 3 (away from middle)
        :SetSelectedItem(config.freeze_up_down) -- 0-based index configure value

    local function set_check_state(state)
        for _, v in ipairs(checks) do
            dialog:GetControl(v):SetCheck(state)
        end
        data_list:SetKeyboardFocus()
    end
    local function set_list_state(state)
        for i, v in ipairs(staff_list) do
            local list_row = data_list:GetItemAt(i - 1)
            if state > -1 then -- "No Staves" = 0 / "All Staves" = 1
                list_row.Check = (state == 1)
            else
                rgn.StartStaff = v[1] -- is this staff number empty?
                rgn.EndStaff = v[1]
                local check_state = not region_contains_notes(rgn, 0)
                list_row.Check = check_state
                if check_state then
                    data_list:SelectLine(i - 1) -- update menu list visually
                end
            end
        end
    end

    -- buttons to PRESET checkboxes/data_list items
    local buttons = {}
    for i, name in ipairs( {"Set All", "Clear All", "All Staves", "No Staves", "Empty Staves"} ) do
        buttons[name] = dialog:CreateButton(x_grid[3], y_step * 2 * (i - 1)):SetWidth(80):SetText(name)
        if i > 2 then
            buttons[name]:AddHandleCommand(function() set_list_state(4 - i) end)
        else
            buttons[name]:AddHandleCommand(function() set_check_state(2 - i) end)
        end
    end

    -- run the dialog
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    local chosen_staves = {} -- save user choice of destination staves

    dialog:RegisterHandleOkButtonPressed(function(self)
        local selection = data_list:GetSelectedLine() + 1
        if selection > 0 then -- user selected a line (not necessairly the line's checkbox)
            table.insert(chosen_staves, staff_list[selection][1])
        end
        for i, v in ipairs(staff_list) do -- check every staff for ticked boxes
            local list_row = data_list:GetItemAt(i - 1)
            if list_row.Check and i ~= selection then
                table.insert(chosen_staves, v[1])
            end
        end
        -- udpate config values
        local max = layer.max_layers()
        for _, v in ipairs(checks) do
            config[v] = (self:GetControl(v):GetCheck() == 1)
        end
        for _, v in ipairs(integers) do
            config[v] = self:GetControl(v):GetInteger()
            if string.find(v, "layer") and (config[v] < 1 or config[v] > max) then -- legitimate layer choice?
                config[v] = (v == "source_layer") and 1 or max -- make sure layer number is in range
            end
        end
        if config.source_layer ~= config.cuenote_layer then
            config.rest_layer = config.source_layer
        else -- make sure the whole-bar rest is in a different layer from the cuenotes
            config.rest_layer = (config.source_layer % max) + 1
        end
        config.freeze_up_down = stem_popup:GetSelectedItem() -- 0-based index
        dialog_save_position(self)
    end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, chosen_staves
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

function get_away_from_middle_is_up(region)
    if config.freeze_up_down ~= freeze.away_from_middle then return false end
    local total_displacement = 0
    for entry in eachentry(region) do
        if entry:IsNote() then
            for note in each(entry) do
                total_displacement = total_displacement + (note:CalcStaffPosition() + 4)
            end
        end
    end
    return total_displacement >= 0
end

function freeze_tuplets_and_ties(entry, up)
    if entry:IsNote() and entry:IsTied() then
        for note in each(entry) do
            if note.Tie then
                local tie_mod = finale.FCTieMod(finale.TIEMODTYPE_TIESTART)
                tie_mod.TieDirection = up
                    and finale.TIEMODDIR_OVER
                    or finale.TIEMODDIR_UNDER
                tie_mod:SaveAt(note)
            end
        end
    end

    if entry.TupletStartFlag then
        for tuplet in each(entry:CreateTuplets()) do
            tuplet.PlacementMode = finale.TUPLETPLACEMENT_STEMSIDE
            tuplet:Save()
        end
    end
end

function freeze_slurs(region, up)
    local marks = finale.FCSmartShapeMeasureMarks()
    marks:LoadAllForRegion(region, true)
    for m in each(marks) do
        local shape = m:CreateSmartShape()
        if shape:IsSolidSlur() then
            shape:SetShapeType(up
                and finale.SMARTSHAPE_SLURUP
                or finale.SMARTSHAPE_SLURDOWN
            )
            shape:Save()
        elseif shape:IsDashedSlur() then
            shape:SetShapeType(up 
                and finale.SMARTSHAPE_DASHEDSLURUP
                or finale.SMARTSHAPE_DASHEDSLURDOWN
            )
            shape:Save()
        end
    end
end

function copy_to_destination(source_region, destination_staff)
    local destination_region = finale.FCMusicRegion()
    destination_region:SetRegion(source_region)
    destination_region:CopyMusic() -- copy the original
    destination_region.StartStaff = destination_staff
    destination_region.EndStaff = destination_staff

    if region_contains_notes(destination_region, 0) and dont_overwrite_existing_music(destination_staff) then
        destination_region:ReleaseMusic() -- clear memory
        return -- and go home
    elseif not region_contains_notes(source_region, config.source_layer) then
        destination_region:ReleaseMusic() -- clear memory
        show_error("no_notes_in_source_layer")
        return false -- and go home
    end
    -- otherwise carry on ...
    destination_region:PasteMusic()   -- paste the copy
    destination_region:ReleaseMusic() -- and release memory
    for layer_number = 1, layer.max_layers() do     -- clear out non-source layers
        if layer_number ~= config.source_layer then
            layer.clear(destination_region, layer_number)
        end
    end

    -- swap source_layer with cuenote_layer & fix clef
    layer.swap(destination_region, config.source_layer, config.cuenote_layer)
    if not config.copy_clef then
        clef.restore_default_clef(destination_region.StartMeasure, destination_region.EndMeasure, destination_staff)
    end

    local away_from_middle_is_up = get_away_from_middle_is_up(destination_region)

    -- mute / set to % size / delete articulations? / freeze stems? / delete lyrics?
    for entry in eachentrysaved(destination_region) do
        if entry:IsNote() and config.mute_cuenotes then
            entry.Playback = false
        end
        entry:SetNoteDetailFlag(true)
        mixin.FCMEntryAlterMod()
            :SetNoteEntry(entry)
            :SetResize(config.cuenote_percent)
            :Save()
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
        if config.freeze_up_down > freeze.none then -- frozen stems requested
            entry.FreezeStem = true
            local freeze_stem_up = {
                true,
                false,
                away_from_middle_is_up
            }
            entry.StemUp = freeze_stem_up[config.freeze_up_down]
        else
            entry.FreezeStem = false
        end
        -- freeze ties and tuplets for "away from middle" stems
        if config.freeze_up_down == freeze.away_from_middle then
            freeze_tuplets_and_ties(entry, away_from_middle_is_up)
        end
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
    if config.copy_slurs and config.freeze_up_down == freeze.away_from_middle then
        freeze_slurs(destination_region, away_from_middle_is_up)
    end

    -- create whole-note rest in rest_layer in each measure
    for measure = destination_region.StartMeasure, destination_region.EndMeasure do
        local notecell = finale.FCNoteEntryCell(measure, destination_staff)
        notecell:Load()
        local whole_note = notecell:AppendEntriesInLayer(config.rest_layer, 1) --   Append to rest_layer, add 1 entry
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
    local category_id = 0
    if not finenv.IsRGPLua then  -- SaveNewWithType only works on RGPLua 0.58+
        return false, category_id   -- and crashes on JWLua
    end

    local new_category = mixin.FCMCategoryDef()
    new_category:Load(finale.DEFAULTCATID_TECHNIQUETEXT)
    local str = finale.FCString()
    str.LuaString = new_name
    new_category:SetName(str)
        :SetVerticalAlignmentPoint(finale.ALIGNVERT_STAFF_REFERENCE_LINE)
        :SetVerticalBaselineOffset(30)
        :SetHorizontalAlignmentPoint(finale.ALIGNHORIZ_CLICKPOS)
        :SetHorizontalOffset(-18)
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

function create_cue_notes()
    local cue_names = { } -- compile NAME/ItemNo of all pre-existing CUE_NAME expressions
    local source_region = finenv.Region()
    local start_staff = source_region.StartStaff
    -- declare other local variables
    local ok, expression_ID, name_index, new_expression, destination_staves

    if source_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    elseif not region_contains_notes(source_region, 0) then
        return show_error("empty_region")
    end

    local cat_ID = -1 -- assume the CUE_NAMES category doesn't exist
    local cat_defs = finale.FCCategoryDefs()
    cat_defs:LoadAll()
    for cat in each(cat_defs) do
        if cat:CreateName().LuaString == config.cue_category_name then
            cat_ID = cat.ID
            break
        end
    end

    local expression_defs = finale.FCTextExpressionDefs()
    expression_defs:LoadAll()
    if cat_ID > -1 then -- expression category already exists
        for text_def in each(expression_defs) do -- collate existing cue names
            if text_def.CategoryID == cat_ID then
                local str = text_def:CreateTextString()
                str:TrimEnigmaTags()
                table.insert(cue_names, { str.LuaString, text_def.ItemNo } ) -- save expresion NAME and ItemNo
            end
        end
        table.sort(cue_names, function(a, b) return string.lower(a[1]) < string.lower(b[1]) end)
    end

    -- test for pre-existing names
    if cat_ID < 0 then -- create a new Text Expression Category
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
        expression_ID = cue_names[name_index][2] --([name_index][1] is the expression's name)
    end

    -- choose destination staff
    ok, destination_staves = choose_destination_staff(start_staff)
    if not ok then return end

    -- make the cue copy
    for _, one_staff in ipairs(destination_staves) do
        if copy_to_destination(source_region, one_staff) then
            mixin.FCMExpression() -- "name" the cue
                :SetStaff(one_staff)
                :SetVisible(true)
                :SetMeasurePos(0)
                :SetScaleWithEntry(false) -- could also (possibly) be true!  
                :SetPartAssignment(true)
                :SetScoreAssignment(true)
                :SetID(expression_ID)
                :SaveNewToCell(finale.FCCell(source_region.StartMeasure, one_staff))
        end
    end
    source_region:SetInDocument()
end

function flip_cue_notes()
    local region = finenv.Region()
    if not region_contains_notes(region, config.cuenote_layer) then
        show_error("no_cue_notes")
        return
    end

    for staff = region.StartStaff, region.EndStaff do
        local freeze_up = nil
        local staff_region = mixin.FCMMusicRegion()
            :SetRegion(region)
            :SetStartStaff(staff)
            :SetEndStaff(staff)
        for entry in eachentrysaved(staff_region, config.cuenote_layer) do
            if entry:IsNote() and not entry.FreezeStem then goto next_staff end
            entry.StemUp = not entry.StemUp
            if freeze_up == nil then freeze_up = entry.StemUp end
            freeze_tuplets_and_ties(entry, freeze_up)
        end
        freeze_slurs(staff_region, freeze_up)
        ::next_staff::
    end
end

if action == "flip" then
    flip_cue_notes()
else
    create_cue_notes()
end

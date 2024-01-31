function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine with additional coding by Aaron Sherber"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.92i"
    finaleplugin.Date = "2023/12/25"
    finaleplugin.AdditionalMenuOptions = [[
        Cue Notes Flip Frozen
    ]]
    finaleplugin.AdditionalUndoText = [[
        Cue Notes Flip Frozen
    ]]
    finaleplugin.AdditionalPrefixes = [[
        action = "flip"
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        This script is designed to take music from one staff and create 
        "cue note" copies in the same measure on one or more empty staves. 
        The copy is smaller and muted, and can include chosen markings from the original. 
        It is copied to the chosen layer with a whole-note rest placed in the original layer.

        Preferences are preserved between each run. 
        This script uses an expression category called "Cue Names" which 
        will be created if needed. 

        An extra menu, "Cue Notes Flip Frozen", will look for notes in the 
        previously selected "cue note" layer and flip the direction of their 
        stems if they have been "frozen" up or down.
    ]]
    return "Cue Notes Create...", "Cue Notes Create", "Copy as cue notes to another staff"
end

action = action or ""

local info_notes = [[
This script is designed to take music from one staff and create
"cue note" copies in the same measure on one or more empty staves.
The copy is smaller and muted, and can include chosen markings from the original.
It is copied to the chosen layer with a whole-note rest placed in the original layer.
**
Preferences are preserved between each run.
This script uses an expression category called "Cue Names" which
will be created if needed.
**
An extra menu, "Cue Notes Flip Frozen", will look for notes in the
previously selected "cue note" layer and flip the direction of their
stems if they have been "frozen" up or down.
**
== Command Keys ==
*In the "Destination Staff" window,
hit the tab key to move the cursor into a numeric
field and these key commands are available:
*q @t show these script notes
*w @t flip [copy articulations]
*e @t flip [copy expressions]
*r @t flip [copy smartshapes]
*t @t flip [copy slurs]
*y @t flip [copy clef]
*u @t flip [copy lyrics]
*i @t flip [copy chords]
*o @t flip [mute cuenotes]
*– – –
*a @t all options checked
*s @t no options checked
*d @t select all staves
*f @t select no staves
*g @t select empty staves
*– – –
*z @t next stem direction
*x @t previous stem direction
]]
info_notes = info_notes:gsub("\n%s*", " "):gsub("*", "\n"):gsub("@t", "\t")

local config = { -- retained and over-written by the user's "settings" file
    copy_articulations  =   false,
    copy_expressions    =   false,
    copy_smartshapes    =   false,
    copy_slurs          =   true,
    copy_clef           =   false,
    copy_lyrics         =   false,
    copy_chords         =   false,
    mute_cuenotes       =   true,
    cuenote_percent     =   70,    -- (75% too big, 66% too small)
    source_layer        =   1,     -- layer the cue comes from
    cuenote_layer       =   3,     -- layer the cue ends up
    rest_layer          =   1,     -- layer for default wholenote rest
    freeze_up_down      =   0,     -- "0" for no stem freezing, "1" for up, "2" for down, "3" for away from middle
    cuename_item        =   0,     -- ItemNo of the last selected cue_name expression
    -- if creating a new "Cue Names" category ...
    cue_category_name   =   "Cue Names",
    cue_font_smaller    =   1, -- how many points smaller than the standard technique expression
    window_pos_x        =   false,
    window_pos_y        =   false,
    abbreviate          =   false
}
local option = {
    check = {   "copy_articulations", "copy_expressions", "copy_smartshapes",
                "copy_slurs", "copy_clef", "copy_lyrics", "copy_chords", "mute_cuenotes" },
    integer = { "cuenote_percent", "source_layer", "cuenote_layer" },
    stem = {  "normal", "freeze up", "freeze down", "away from middle" },
    button = { "Set All", "Clear All", "All Staves", "No Staves", "Empty Staves" }
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
        only_one_staff = "Please select just one staff \nas the source for the new cue",
        empty_region = "Please select a region \nwith some notes in it!",
        no_notes_in_source_layer = "The selected music contains\nno notes in layer " .. config.source_layer,
        first_make_expression_category = "You must first create a new Text Expression Category called \""..config.cue_category_name.."\" containing at least one entry",
        no_cue_notes = "The selected music contains \nno cue notes in layer " .. config.cuenote_layer,
        unknown = "Unknown error condition"
    }
    local msg = errors[error_code] or errors.unknown
    finenv.UI():AlertInfo(msg, "User Error")
    return -1
end

function dont_overwrite_existing_music(staff_number)
    local staff = finale.FCStaff()
    staff:Load(staff_number) -- staff number of this slot
    local msg = "Overwrite existing music on staff: " .. staff:CreateDisplayFullNameString().LuaString .. "?"
    local alert = finenv.UI():AlertOkCancel(msg, nil)
    return (alert ~= finale.OKRETURN)
end

function region_is_empty(region, layer_number)
    for entry in eachentry(region, layer_number) do
        if entry.Count > 0 then return false end
    end
    return true
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

local function info_dialog()
    finenv.UI():AlertInfo(info_notes, "About " .. plugindef())
end

local function make_info_button(dialog, x, y)
    dialog:CreateButton(x, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() info_dialog() end)
end

function new_cue_name(source_staff)
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("New cue name:"):SetWidth(100)
    make_info_button(dialog, 180, 0)

    local staff = finale.FCStaff() -- copy the source Staff Name
    staff:Load(source_staff)
    local name = {
        full = staff:CreateDisplayFullNameString(),
        abbrev = staff:CreateDisplayAbbreviatedNameString()
    }
    local the_name = dialog:CreateEdit(0, 22):SetWidth(200)
        :SetText(config.abbreviate and name.abbrev or name.full)
    local abbrev_checkbox = dialog:CreateCheckbox(0, 47):SetText("Abbreviate staff name")
        :SetWidth(150):SetCheck(config.abbreviate and 1 or 0)
        :AddHandleCommand(function(self)
            the_name:SetText(self:GetCheck() == 1 and name.abbrev or name.full)
        end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        config.abbreviate = (abbrev_checkbox:GetCheck() == 1)
    end)
    dialog:RegisterInitWindow(function() the_name:SetFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK), the_name:GetText()
end

function choose_name_index(name_list)
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Select cue name:"):SetWidth(100)
    -- menu item [0] is "*** new name ***"
    local staff_list = dialog:CreateListBox(0, 22):SetWidth(200):AddString("*** new name ***")
    for i, v in ipairs(name_list) do -- add all names in the extant list
        staff_list:AddString(v[1])
        if v[2] == config.cuename_item then staff_list:SetSelectedItem(i) end
    end
    make_info_button(dialog, 180, 0)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        local idx = staff_list:GetSelectedItem()
        if idx ~= 0 then -- existing cuename chosen
            config.cuename_item = name_list[idx][2]
        end
    end)
    dialog:RegisterInitWindow(function() staff_list:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK), staff_list:GetSelectedItem()
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
    config.cuename_item = ted:GetItemNo() -- save new item number
end

function choose_destination_staff(source_staff)
    local staff_list = {} -- save number and name of other staves in the score
    local rgn = finale.FCMusicRegion()
    local max = layer.max_layers()
    rgn:SetCurrentSelection()
    rgn:SetFullMeasureStack() -- scan the whole stack
    local staff = finale.FCStaff()
    for staff_number in eachstaff(rgn) do
        if staff_number ~= source_staff then
            staff:Load(staff_number)
            local full_name = staff:CreateDisplayFullNameString().LuaString
            table.insert(staff_list, { staff_number, full_name } )
        end
    end
    local answer, saved, buttons = {}, {}, {}

    -- make the dialog
    local x_grid = { 210, 310, 370 }
    local y_step = 19
    local y_offset = finenv.UI():IsOnMac() and 3 or 0 -- + vertical offset for Mac edit boxes

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 20):SetText("Select cue name:"):SetWidth(100)
    local max_rows = #option.check + #option.integer + 2
    local num_rows = (#staff_list > (max_rows + 2)) and max_rows or (#staff_list + 2)
    local data_list = dialog:CreateDataList(0, 0):SetUseCheckboxes(true)
        :SetHeight(num_rows * y_step):AddColumn("Destination Staff(s):", 120)
    if finenv.UI():IsOnMac() then
        data_list:UseAlternatingBackgroundRowColors()
    end
    for _, v in ipairs(staff_list) do -- list all staff names
        local row = data_list:CreateRow()
        row:GetItemAt(0).LuaString = v[2]
    end

        local function set_check_state(state)
            for _, v in ipairs(option.check) do
                answer[v]:SetCheck(state)
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
                    list_row.Check = region_is_empty(rgn, 0)
                    if list_row.Check then
                        data_list:SelectLine(i - 1) -- update menu list visually
                    end
                end
            end
        end
        local function flip_check(idx)
            local ctl = answer[option.check[idx]]
            ctl:SetCheck((ctl:GetCheck() + 1) % 2)
        end
        local function flip_direction(add)
            local item = answer.stem_direction:GetSelectedItem() + add
            item = (item < 0) and 3 or (item % 4)
            answer.stem_direction:SetSelectedItem(item)
        end
        local function key_check(name)
            local ctl = answer[name]
            local s = ctl:GetText():lower()
            if  (   s:find("[^0-9]") or
                    (name:find("layer") and s:find("[^1-" .. max .. "]"))
                ) then
                if     s:find("[q?]") then info_dialog()
                elseif s:find("w") then flip_check(1)
                elseif s:find("e") then flip_check(2)
                elseif s:find("r") then flip_check(3)
                elseif s:find("t") then flip_check(4)
                elseif s:find("y") then flip_check(5)
                elseif s:find("u") then flip_check(6)
                elseif s:find("i") then flip_check(7)
                elseif s:find("o") then flip_check(8)
                elseif s:find("a") then set_check_state(1) -- check all
                elseif s:find("s") then set_check_state(0) -- check none
                elseif s:find("d") then set_list_state(1) -- all staves
                elseif s:find("f") then set_list_state(0) -- no staves
                elseif s:find("g") then set_list_state(-1) -- empty staves
                elseif s:find("z") then flip_direction(1) -- up/down stem
                elseif s:find("x") then flip_direction(-1)
                end
                ctl:SetText(saved[name]):SetKeyboardFocus()
            elseif s ~= "" then
                if name:find("layer") then s = s:sub(-1) -- 1-digit layer numbers
                else s = s:sub(1, 3) -- 3-digit percentage
                end
                ctl:SetText(s)
                saved[name] = s
            end
        end

    local y = y_step
    dialog:CreateStatic(x_grid[1], 0):SetText("Cue Options:"):SetWidth(150)
    for _, v in ipairs(option.check) do -- run through config boolean list
        answer[v] = dialog:CreateCheckbox(x_grid[1], y):SetText(v:gsub("_", " "))
        :SetWidth(120):SetCheck(config[v] and 1 or 0)
        y = y + y_step
    end
    for i, v in ipairs(option.integer) do -- run through config integer list
        dialog:CreateStatic(x_grid[1], y):SetText(v:gsub("_", " ") .. ":"):SetWidth(150)
        answer[v] = dialog:CreateEdit(x_grid[2], y - y_offset):SetInteger(config[v])
            :AddHandleCommand(function() key_check(v) end)
        answer[v]:SetWidth(i == 1 and 40 or 20) -- layer numbers thinner
        saved[v] = config[v]
        y = y + y_step
    end

    answer.stem_direction = dialog:CreatePopup(x_grid[1], y + 5):SetWidth(160)
    for _, v in ipairs(option.stem) do
        answer.stem_direction:AddString("Stems: " .. v)
    end
    answer.stem_direction:SetSelectedItem(config.freeze_up_down) -- 0-based index configure value

    -- buttons to PRESET checkboxes/data_list items
    for i, name in ipairs(option.button) do
        buttons[name] = dialog:CreateButton(x_grid[3], y_step * 2 * (i - 1)):SetWidth(80):SetText(name)
        if i < 3 then
            buttons[name]:AddHandleCommand(function() set_check_state(2 - i) end)
        else
            buttons[name]:AddHandleCommand(function() set_list_state(4 - i) end)
        end
    end
    make_info_button(dialog, x_grid[3] + 60, y_step * 11 + 3)

    -- run the dialog
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    local chosen_staves = {} -- save user choice of destination staves

    dialog:RegisterHandleOkButtonPressed(function()
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
        -- save config values
        for _, v in ipairs(option.check) do
            config[v] = (answer[v]:GetCheck() == 1)
        end
        for _, v in ipairs(option.integer) do
            config[v] = answer[v]:GetInteger()
        end
        if config.source_layer ~= config.cuenote_layer then
            config.rest_layer = config.source_layer
        else -- make sure the whole-bar rest is in a different layer from the cuenotes
            config.rest_layer = (config.source_layer % max) + 1
        end
        config.freeze_up_down = answer.stem_direction:GetSelectedItem() -- 0-based index
    end)
    dialog:RegisterInitWindow(function() data_list:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK), chosen_staves
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
                tie_mod.TieDirection = up and finale.TIEMODDIR_OVER or finale.TIEMODDIR_UNDER
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
            shape:SetShapeType(up and finale.SMARTSHAPE_SLURUP or finale.SMARTSHAPE_SLURDOWN)
            shape:Save()
        elseif shape:IsDashedSlur() then
            shape:SetShapeType(up and finale.SMARTSHAPE_DASHEDSLURUP or finale.SMARTSHAPE_DASHEDSLURDOWN)
            shape:Save()
        end
    end
end

function copy_to_destination(source_region, destination_staff)
    local destination_region = mixin.FCMMusicRegion()
    destination_region:SetRegion(source_region):CopyMusic() -- copy the original
    destination_region:SetStartStaff(destination_staff):SetEndStaff(destination_staff)

    if not region_is_empty(destination_region, 0)
        and dont_overwrite_existing_music(destination_staff) then
            destination_region:ReleaseMusic() -- clear memory
            return false -- and go home
    elseif region_is_empty(source_region, config.source_layer) then
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
        for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), destination_region) do
            local shape = mark:CreateSmartShape()
            if  (shape:IsSlur() and not config.copy_slurs) or
                (not shape:IsSlur() and not config.copy_smartshapes) then
                shape:DeleteData()
            end
        end
    end
    if config.copy_slurs and config.freeze_up_down == freeze.away_from_middle then
        freeze_slurs(destination_region, away_from_middle_is_up)
    end
    -- delete chord symbols?
    if not config.copy_chords then
        for chord in loadallforregion(finale.FCChords(), destination_region) do
            if chord then chord:DeleteData() end
        end
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
    local ok = new_category:SaveNewWithType(finale.DEFAULTCATID_TECHNIQUETEXT)
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
    local ok, name_index, new_expression, destination_staves

    if source_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    elseif region_is_empty(source_region, 0) then
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
    ok, name_index = choose_name_index(cue_names) -- saved in config.cuename_item
    if not ok then return end
    if name_index == 0 then	-- USER wants to provide a new cue name
        ok, new_expression = new_cue_name(start_staff)
        if not ok or new_expression == "" then return end
        create_new_expression(new_expression, cat_ID) -- ID saved in config.cuename_item
    end
    -- choose destination staff
    ok, destination_staves = choose_destination_staff(start_staff)
    if not ok then return end
    if region_is_empty(source_region, config.source_layer) then
        return show_error("no_notes_in_source_layer")
    end
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
                :SetID(config.cuename_item)
                :SaveNewToCell(finale.FCCell(source_region.StartMeasure, one_staff))
        end
    end
    source_region:SetInDocument()
end

function flip_cue_notes()
    local region = finenv.Region()
    if region_is_empty(region, config.cuenote_layer) then
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

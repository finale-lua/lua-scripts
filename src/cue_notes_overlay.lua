function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.11"
    finaleplugin.Date = "2023/12/09"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        This script takes music from a nominated layer in the selected staff 
        and creates a "Cue" version on one or more other staves. 
        It is specifically intended to create cue notes above or below 
        existing "played" material in the destination. 
        If the nominated "cue" layer already contains music 
        the cue will copy to the first empty layer. 
        If the destination measure is completely empty a whole-measure 
        rest will be created as a reminder that the cue isn't played.

        Cue notes are often shown in a different octave to 
        accommodate the clef and transposition of the destination. 
        Use "cue octave offset" setting for this. 
        Cues can interact visually with "played" "material in countless ways 
        so settings probably need to change between scenarios.

        The cue copy is reduced in size and muted, and can optionally duplicate 
        articulations, expressions, lyrics and smart shapes. 
        "Note-based" smart shapes are copied, typically slurs and 
        glissandos, because they actually "attach" to the cued notes. 
        This script stores cue names in a text expression category called 
        "Cue Names" which will be created automatically if needed. 
        Once created you can adjust its text and position parameters 
        like any other expression category.  

        Rests in the cue will be offset by the value you have set 
        for layer 1 at Document → Document Options → Layers. 
        They will automatically offset in the same direction as the 
        nominated cue stem direction.
    ]]
    return "Cue Notes Overlay...", "Cue Notes Overlay", "Copy as cue notes to another staff"
end

local info_notes = [[
This script takes music from a nominated layer in the selected staff
and creates a "Cue" version on one or more other staves.
It is specifically intended to create cue notes above or below
existing "played" material in the destination.
If the nominated "cue" layer already contains music
the cue will copy to the first empty layer.
If the destination measure is completely empty a whole-measure
rest will be created as a reminder that the cue isn't played.
**
Cue notes are often shown in a different octave to
accommodate the clef and transposition of the destination.
Use "cue octave offset" setting for this.
Cues can interact visually with "played" "material in countless ways
so settings probably need to change between scenarios.
**
The cue copy is reduced in size and muted, and can optionally duplicate
articulations, expressions, lyrics and smart shapes.
"Note-based" smart shapes are copied, typically slurs and
glissandos, because they actually "attach" to the cued notes.
This script stores cue names in a text expression category called
"Cue Names" which will be created automatically if needed.
Once created you can adjust its text and position parameters
like any other expression category.
**
Rests in the cue will be offset by the value you have set
for layer 1 at Document → Document Options → Layers.
They will automatically offset in the same direction as the
nominated cue stem direction.
**
== Command Keys ==
*In the "Destination Staff" window,
hit the tab key to move the cursor into a numeric
field and these key commands are available:
*• q @t show these script notes
*• w @t flip [copy articulations]
*• e @t flip [copy expressions]
*• r @t flip [copy smartshapes]
*• t @t flip [copy lyrics]
*• y @t flip [mute cuenotes]
*– – –
*• a @t all options checked
*• s @t no options checked
*• d @t select all staves
*• f @t select no staves
*• g @t select empty staves
*– – –
*• z (-) octave -1
*• x (+) octave +1
*• c @t flip stem direction
*• v @t flip [destination stems opposite]
]]

info_notes = info_notes:gsub("\n%s*", " "):gsub("*", "\n"):gsub("@t", "\t")

local config = { -- retained and over-written by the user's "settings" file
    copy_articulations  =   false,
    copy_expressions    =   false,
    copy_smartshapes    =   true,
    copy_lyrics         =   false,
    mute_cuenotes       =   true,
    cuenote_percent     =   70,    -- (75% too big, 66% too small)
    source_layer        =   1,     -- layer the cue comes from
    cuenote_layer       =   3,     -- layer the cue ends up
    stem_direction      =   0,     -- "0" up, "1" down
    stems_oppose        =   false, -- destination stem direction opposite to cue stem
    octave_offset       =   0,     -- octave displacement (-5 to +5) of copied cue version
    abbreviate          =   true, -- abbreviate staff names when creating new titles
    cuename_item        =   0,    -- ItemNo of the last selected cue_name expression
    -- not user accessible:
    shift_expression_down = -24 * 9, -- when cue_name is below staff
    shift_expression_left = -24, -- EVPUs; cue names generally need to be LEFT of music start
    -- if creating a new "Cue Names" category ...
    cue_category_name   =   "Cue Names",
    cue_font_smaller    =   1, -- how many points smaller than the standard technique expression
    window_pos_x        =   false,
    window_pos_y        =   false,
}
local options = {
    check = { -- ordered user input checkboxes
        "copy_articulations", "copy_expressions", "copy_smartshapes", "copy_lyrics", "mute_cuenotes" },
    integer = { "cuenote_percent", "source_layer", "cuenote_layer" }, -- integer edit boxes
    button = { "Set All", "Clear All", "All Staves", "No Staves", "Empty Staves" }
}
local configuration = require("library.configuration")
local layer = require("library.layer")
local mixin = require("library.mixin")
local note_entry = require("library.note_entry")
local transposition = require("library.transposition")
local script_name = "cue_notes_overlay"

local function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function show_error(error_code)
    local errors = {
        only_one_staff = "Please select just one staff \nas the source for the cue",
        empty_region = "Please select a region with \nnotes in it as the source of the cue",
        no_notes_in_source_layer = "The selected music contains\nno notes in \"source layer\" "
            .. config.source_layer,
        make_expression_category = "You must first create a new Text Expression Category called \""
            .. config.cue_category_name .. "\" containing at least one entry",
    }
    local msg = errors[error_code] or "Unknown error condition"
    finenv.UI():AlertInfo(msg, plugindef() .. " Error")
    return -1
end

local function overwrite_existing_music(staff_number, layer_number)
    local staff = finale.FCStaff()
    staff:Load(staff_number) -- staff number of this slot
    local msg = "Are you sure you want to overwrite existing music on layer [" .. layer_number
        .. "] of staff: \"" .. staff:CreateDisplayFullNameString().LuaString .. "\"?"
    local alert = finenv.UI():AlertOkCancel(msg, nil)
    return (alert == finale.OKRETURN)
end

local function region_is_empty(region, layer_number)
    for entry in eachentry(region, layer_number) do
        if entry.Count > 0 then return false end
    end
    return true
end

local function info_dialog()
    finenv.UI():AlertInfo(info_notes, "About " .. plugindef())
end

local function make_info_button(dialog, x, y)
    dialog:CreateButton(x, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() info_dialog() end)
end

local function new_cue_name(source_staff)
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("New cue name:"):SetWidth(100)
    make_info_button(dialog, 180, 0)

    local staff = finale.FCStaff() -- copy the source Staff Name
    staff:Load(source_staff)
    local abbrev_name = staff:CreateDisplayAbbreviatedNameString()
    local full_name = staff:CreateDisplayFullNameString()
    local the_name = dialog:CreateEdit(0, 22):SetWidth(200)
        :SetText(config.abbreviate and abbrev_name or full_name)
    local abbrev_checkbox = dialog:CreateCheckbox(0, 47):SetText('Abbreviate staff name')
        :SetWidth(150):SetCheck(config.abbreviate and 1 or 0)
        :AddHandleCommand(function(self)
            the_name:SetText(self:GetCheck() == 1 and abbrev_name or full_name):SetFocus()
        end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.abbreviate = (abbrev_checkbox:GetCheck() == 1)
    end)
    dialog:RegisterInitWindow(function() the_name:SetFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK), the_name:GetText()
end

local function choose_name_index(name_list)
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

local function create_new_expression(exp_name, category_number)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(category_number)
    local text_font_info = cat_def:CreateTextFontInfo()
    local str = finale.FCString()
    str.LuaString = "^fontTxt"
        .. text_font_info:CreateEnigmaString(finale.FCString()).LuaString
        .. exp_name
    local ted = mixin.FCMTextExpressionDef()
    ted:SaveNewTextBlock(str)
        :AssignToCategory(cat_def)
        :SetUseCategoryPos(true)
        :SetUseCategoryFont(true)
        :SaveNew()
    config.cuename_item = ted:GetItemNo() -- save new item number
end

local function choose_destination_staff(source_staff)
    local rgn = finale.FCMusicRegion()
    rgn:SetCurrentSelection()
    rgn:SetFullMeasureStack() -- scan the whole stack

    -- assemble selected staves
    local staff_list = {} -- staff number; name
    local staff = finale.FCStaff()
    for staff_number in eachstaff(rgn) do
        if staff_number ~= source_staff then
            staff:Load(staff_number)
            local full_name = staff:CreateDisplayFullNameString().LuaString
            table.insert(staff_list, { staff_number, full_name } )
        end
    end
    local max = layer.max_layers()
    local answer, save_layer = {}, {}

    -- make the dialog
    local x_grid = { 210, 310, 370 }
    local y_step = 19
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 20):SetText("Select cue name:"):SetWidth(100)
    local max_rows = #options.check + #options.integer + 2
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
            for _, v in ipairs(options.check) do
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
                    local check_state = region_is_empty(rgn, 0)
                    list_row.Check = check_state
                    if check_state then
                        data_list:SelectLine(i - 1) -- update menu list visually
                    end
                end
            end
        end
        local function octave_change(dir)
            local item = answer.octave_offset:GetSelectedItem()
            if (dir < 0 and item > 0) or (dir > 0 and item < 10) then
                item = item + dir
            end
            answer.octave_offset:SetSelectedItem(item)
        end
        local function flip_check(name)
            local ctl = answer[name]
            ctl:SetCheck((ctl:GetCheck() + 1) % 2)
        end
        local function flip_direction()
            local n = answer.stem_direction:GetSelectedItem()
            answer.stem_direction:SetSelectedItem((n + 1) % 2)
        end
        local function key_check(name)
            local ctl = answer[name]
            local s = ctl:GetText():lower()
            if  (   ( name:find("layer") and s:find("[^1-" .. max .. "]")
                      or s:find("[^0-9]")
                    )
                ) then
                if     s:find("[q?]") then info_dialog()
                elseif s:find("w") then flip_check("copy_articulations")
                elseif s:find("e") then flip_check("copy_expressions")
                elseif s:find("r") then flip_check("copy_smartshapes")
                elseif s:find("t") then flip_check("copy_lyrics")
                elseif s:find("y") then flip_check("mute_cuenotes")
                elseif s:find("a") then set_check_state(1) -- check all
                elseif s:find("s") then set_check_state(0) -- check none
                elseif s:find("d") then set_list_state(1) -- all staves
                elseif s:find("f") then set_list_state(0) -- no staves
                elseif s:find("g") then set_list_state(-1) -- empty staves
                elseif s:find("[-z_]") then octave_change(-1) -- octave -1
                elseif s:find("[+x=]") then octave_change(1) -- octave +1
                elseif s:find("c") then flip_direction() -- up/down stem
                elseif s:find("v") then flip_check("stems_oppose")
                end
                ctl:SetText(save_layer[name]):SetKeyboardFocus()
            elseif s ~= "" then
                if name:find("layer") then s = s:sub(-1) -- 1-digit layer numbers
                else s = s:sub(1,3) -- 3-digit percentage
                end
                ctl:SetText(s)
                save_layer[name] = s
            end
        end
    local y = y_step
    dialog:CreateStatic(x_grid[1], 0):SetText("Cue Options:"):SetWidth(150)
    for _, v in ipairs(options.check) do -- run through check options
        answer[v] = dialog:CreateCheckbox(x_grid[1], y):SetText(string.gsub(v, "_", " "))
            :SetWidth(120):SetCheck(config[v] and 1 or 0)
        y = y + y_step
    end

    local y_offset = finenv.UI():IsOnMac() and 3 or 0
    for i, v in ipairs(options.integer) do -- run through integer options
        dialog:CreateStatic(x_grid[1], y):SetText(v:gsub("_", " ") .. ":"):SetWidth(150)
        answer[v] = dialog:CreateEdit(x_grid[2], y - y_offset):SetInteger(config[v])
            :AddHandleCommand(function() key_check(v) end)
        answer[v]:SetWidth(i == 1 and 40 or 20) -- layer numbers thinner
        save_layer[v] = tostring(config[v])
        y = y + y_step
    end

    answer.stem_direction = dialog:CreatePopup(x_grid[1], y + 2):SetWidth(150)
        :AddString("Cue Stems Up")  -- == 0
        :AddString("Cue Stems Down")  -- == 1
        :SetSelectedItem(config.stem_direction)
    y = y + y_step + 5
    answer.stems_oppose = dialog:CreateCheckbox(x_grid[1], y)
        :SetText("destination stems opposite direction"):SetWidth(220)
        :SetCheck(config.stems_oppose and 1 or 0)

    -- buttons to PRESET checkboxes/data_list items
    local buttons = {}
    dialog:CreateStatic(x_grid[3] + 15, 3):SetText("OPTIONS:"):SetWidth(80)
    for i, name in ipairs(options.button) do
        local diff = (i < 3) and (y_step * i ) or (y_step * (i + 1))
        buttons[name] = dialog:CreateButton(x_grid[3], diff)
            :SetWidth(80):SetText(name)
        if i > 2 then
            buttons[name]:AddHandleCommand(function() set_list_state(4 - i) end)
        else
            buttons[name]:AddHandleCommand(function() set_check_state(2 - i) end)
        end
    end
    dialog:CreateStatic(x_grid[3] + 15, y_step * 3 + 3):SetText("SELECT:"):SetWidth(80)
    dialog:CreateStatic(x_grid[3], (y_step * 7) + 9):SetText("cue octave offset:"):SetWidth(100)
    answer.octave_offset = dialog:CreatePopup(x_grid[3] + 25, (y_step * 8) + 6):SetWidth(40)
    for i = -5, 5 do
        local pole = (i > 0) and "+" or ""
        answer.octave_offset:AddString(pole .. i)
    end
    answer.octave_offset:SetSelectedItem(config.octave_offset + 5)
    make_info_button(dialog, x_grid[3] + 60, y_step * 10 + 3)

    -- run the dialog
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    local chosen_staves = {} -- return the user's chosen destination staves

    dialog:RegisterHandleOkButtonPressed(function(self)
        local selection = data_list:GetSelectedLine() + 1
        if selection > 0 then -- user selected a line (not necessarily the line's checkbox)
            table.insert(chosen_staves, staff_list[selection][1])
        end
        for i, v in ipairs(staff_list) do -- check every staff for ticked boxes
            local list_row = data_list:GetItemAt(i - 1)
            if list_row.Check and i ~= selection then
                table.insert(chosen_staves, v[1])
            end
        end
        -- return config values
        for _, v in ipairs(options.check) do
            config[v] = (answer[v]:GetCheck() == 1)
        end
        for _, v in ipairs(options.integer) do
            config[v] = answer[v]:GetInteger()
        end
        config.stem_direction = answer.stem_direction:GetSelectedItem() -- 0-based
        config.octave_offset  = answer.octave_offset:GetSelectedItem() - 5 -- octave offset value
        config.stems_oppose = (answer.stems_oppose:GetCheck() == 1)
    end)
    dialog:RegisterInitWindow(function() data_list:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK), chosen_staves
end

local function get_layer_rest_offset(layer_num)
    local layer_prefs = finale.FCLayerPrefs()
    layer_prefs:Load(layer_num - 1)
    local rest_offset = math.abs(layer_prefs:GetRestOffset()) -- ignore polarity
    rest_offset = math.max(rest_offset, 4) -- not less than 4
    if config.stem_direction == 1 then rest_offset = -rest_offset end -- downstem
    return rest_offset
end

local function get_empty_cue_layer(rgn)
    if region_is_empty(rgn, config.cuenote_layer) then
        return config.cuenote_layer
    end
    for i = 1, 4 do
        if i ~= config.cuenote_layer and region_is_empty(rgn, i) then
            return  i -- got an empty layer
        end
    end
    -- no empty layers available
    if overwrite_existing_music(rgn.StartStaff, config.cuenote_layer) then
        return config.cuenote_layer
    end
    return -1
end

local function add_measure_rests(dest_region, cue_layer)
    local rest_layer = (cue_layer == 1) and 2 or 1
    local rgn = mixin.FCMMusicRegion()
    rgn:SetRegion(dest_region)
    for meas = rgn.StartMeasure, rgn.EndMeasure do -- check one measure at a time
        rgn:SetStartMeasure(meas):SetEndMeasure(meas)
        if region_is_empty(rgn, 0) then -- create a whole-measure rest
            local notecell = finale.FCNoteEntryCell(meas, rgn.StartStaff)
            notecell:Load()
            local whole_note = notecell:AppendEntriesInLayer(rest_layer, 1)
            if whole_note then
                whole_note.Duration = finale.WHOLE_NOTE
                whole_note.Legality = true
                whole_note:MakeRest()
                notecell:Save()
            end
        end
    end
end

local function notelayer_copy(rgn, dest_staff)
    local start = rgn.StartMeasure
    local stop = rgn.EndMeasure
    local shape_starts, shape_ends = {}, {}
    local rest_offset = get_layer_rest_offset(1) -- User's rest offset (layer 1)
    local dest_region = mixin.FCMMusicRegion()
    dest_region:SetRegion(rgn):SetStartStaff(dest_staff):SetEndStaff(dest_staff)

    local cue_layer = get_empty_cue_layer(dest_region)
    if cue_layer < 0 then return false end -- couldn't find one
    add_measure_rests(dest_region, cue_layer) -- if needed

    -- CLONE THE SOURCE LAYER
    local src_nel = finale.FCNoteEntryLayer(config.source_layer - 1, rgn.StartStaff, start, stop)
    src_nel:SetUseVisibleLayer(false)
    src_nel:Load()
    local dest_nel = src_nel:CreateCloneEntries(cue_layer - 1, dest_staff, start)
    dest_nel:Save()
    dest_nel:CloneTuplets(src_nel)
    dest_nel:Save()

    -- modify destination layer ENTRY BY ENTRY
    for index = 0, dest_nel.Count - 1 do
        local src_entry = src_nel:GetItemAt(index)
        local dest_entry = dest_nel:GetItemAt(index)

        if dest_entry:IsNote() then -- NOTE-LEVEL CHANGES
            if config.mute_cuenotes then -- MUTING
                dest_entry.Playback = false
            end
            dest_entry.FreezeStem = true -- STEM DIRECTION
            dest_entry.StemUp = (config.stem_direction == 0) -- ("up")
            if config.octave_offset ~= 0 then -- change octave
                for note in each(dest_entry) do
                    transposition.change_octave(note, config.octave_offset)
                end
            end
            if config.copy_articulations then -- ARTICULATIONS
                for articulation in eachbackwards(src_entry:CreateArticulations()) do
                    articulation:SetNoteEntry(dest_entry)
                    articulation:SaveNew()
                end
            end
            if src_entry.SecondaryBeamFlag then -- SECONDARY BEAM BREAKS
                local bbm = mixin.FCMSecondaryBeamBreakMod()
                bbm:SetNoteEntry(src_entry):LoadFirst()
                bbm:SetNoteEntry(dest_entry):SaveNew()
            end
            if config.copy_smartshapes then -- SMARTSHAPES
                for mark in loadall(finale.FCSmartShapeEntryMarks(src_entry)) do
                    local shape = mark:CreateSmartShape()
                    if mark:CalcLeftMark() then shape_starts[shape.ItemNo] = index end
                    if mark:CalcRightMark() then shape_ends[shape.ItemNo] = index end
                end
            end
        else -- is REST CHANGES -> offset
            note_entry.rest_offset(dest_entry, rest_offset)
        end
        
        dest_entry:SetNoteDetailFlag(true) -- CUENOTE SIZE
        mixin.FCMEntryAlterMod()
            :SetNoteEntry(dest_entry)
            :SetResize(config.cuenote_percent)
            :Save()

        if src_entry.LyricFlag and config.copy_lyrics then -- LYRICS
            for _, v in ipairs({ "FCMChorusSyllable", "FCMSectionSyllable", "FCMVerseSyllable" }) do
                local lyric = mixin[v]()
                lyric:SetNoteEntry(src_entry):LoadFirst()
                lyric:SetNoteEntry(dest_entry):SaveNew()
            end
        end
    end
    dest_nel:Save()

    if config.copy_smartshapes then -- REPLICATE SLURS  
        for itemno, index in pairs(shape_starts) do
            if shape_ends[itemno] then
                local shape = mixin.FCMSmartShape()
                shape:Load(itemno)
                local e_left = dest_nel:GetItemAt(index)
                local e_right = dest_nel:GetItemAt(shape_ends[itemno])
                shape:GetTerminateSegmentLeft():SetEntry(e_left):SetStaff(dest_staff)
                shape:GetTerminateSegmentRight():SetEntry(e_right):SetStaff(dest_staff)
                shape:SaveNewEverything(e_left, e_right)
            end
        end
    end
    if config.copy_expressions then -- DUPLICATE EXPRESSIONS
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(rgn)
        for exp in eachbackwards(expressions) do
            if exp.StaffGroupID == 0 then -- note-attached expressions only
                exp.LayerAssignment = config.cuenote_layer
                exp.ScaleWithEntry = true -- scale to smaller noteheads
                exp:SaveNewToCell(finale.FCCell(exp.Measure, dest_staff))
            end
        end
    end
    -- OPPOSE ORIGINAL (played) ENTRY STEMS
    if config.stems_oppose then
        for entry in eachentrysaved(dest_region) do
            if entry.LayerNumber ~= cue_layer then
                if entry:IsNote() then -- stems opposite direction
                    entry.FreezeStem = true
                    entry.StemUp = (config.stem_direction == 1) -- opposite
                else -- rests shifted opposite direction
                    note_entry.rest_offset(entry, -rest_offset)
                end
            end
        end
    end
    return true
end

local function new_expression_category(new_name)
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

local function create_cue_notes()
    configuration.get_user_settings(script_name, config, true)
    local cue_names = { } -- compile NAME/ItemNo of all pre-existing CUE_NAME expressions
    local source_region = mixin.FCMMusicRegion()
    source_region:SetRegion(finenv.Region()):SetStartMeasurePosLeft():SetEndMeasurePosRight()
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
            return show_error("make_expression_category")
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
        if notelayer_copy(source_region, one_staff) then
            local cue_name = mixin.FCMExpression() -- "name" the cue
            cue_name:SetStaff(one_staff)
                :SetVisible(true)
                :SetMeasurePos(0)
                :SetScaleWithEntry(false)
                :SetPartAssignment(true)
                :SetScoreAssignment(true)
                :SetID(config.cuename_item)
                :SetHorizontalPos(config.shift_expression_left)
                :SaveNewToCell(finale.FCCell(source_region.StartMeasure, one_staff))
            if config.stem_direction == 1 then -- downstem
                cue_name.VerticalPos = config.shift_expression_down
                cue_name:Save()
            end
        end
    end
    source_region:SetInDocument()
end

create_cue_notes()

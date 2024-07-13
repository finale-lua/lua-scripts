function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.32"
    finaleplugin.Date = "2024/07/12"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        This script takes music from a nominated layer in the selected staff 
        and creates a __Cue__ version on one or more other staves. 
        It is intended to create cue notes above or below existing 
        "played" material in the destination. 
        If the destination measure is empty a whole-measure rest 
        will be created as a reminder that the cue isn't played. 

        Use __Cue Octave Offset__ to change the register of a cue to 
        suit the clef and transposition of the destination. 
        Cues can interact visually with "played" material in countless ways 
        so settings probably need to change between scenarios. 

        The cue copy is reduced in size and muted, and can optionally duplicate 
        articulations, expressions, lyrics and smart shapes. 
        __Note-based__ smart shapes are copied, typically slurs and glissandos, 
        because they actually "attach" to the cued notes. 

        This script stores cue names in a text expression category called 
        __Cue Names__ which will be created automatically if needed. 
        Once created you can adjust its text and position parameters 
        like any other expression category. 

        Rests in the cue will be offset by the value you have set 
        for layer 1 at _Document_ &rarr; _Document Options_ &rarr; _Layers_. 
        They will automatically be offset in the same direction as 
        the nominated cue stem direction.

        > __Command Keys__  
        > In the __Destination Staff__ window, highlight one of the 
        > numeric fields and these key commands become available: 

        > - __q__: show script info 
        > - __w__: toggle [copy articulations] 
        > - __e__: toggle [copy expressions] 
        > - __r__: toggle [copy smartshapes] 
        > - __t__: toggle [copy lyrics] 
        > - __y__: toggle [mute cuenotes]  
        > - __a__: check all options 
        > - __s__: check no options 
        > - __d__: select all staves 
        > - __f__: select no staves 
        > - __g__: select empty staves  
        > - __z (-)__: octave -1 
        > - __x (+)__: octave +1 
        > - __c__: toggle stem direction 
        > - __v__: toggle [destination stems opposite] 
    ]]
    return "Cue Notes Overlay...",
        "Cue Notes Overlay",
        "Copy as cue notes to another staff"
end

local config = { -- retained and over-written by the user's "settings" file
    copy_articulations  =   false,
    copy_expressions    =   false,
    copy_smartshapes    =   true,
    copy_lyrics         =   false,
    mute_cuenotes       =   true,
    cuenote_percent     =   70,   -- (75% too big, 66% too small)
    source_layer        =   1,    -- layer the cue comes from
    cuenote_layer       =   4,    -- layer the cue ends up
    stem_direction      =   0,    -- "0" up, "1" down
    stems_oppose        =   true, -- destination stem direction opposite to cue stem
    octave_offset       =   0,    -- octave displacement (-5 to +5) of copied cue version
    abbreviate          =   true, -- abbreviate staff names when creating new titles
    cuename_item        =   0,    -- ItemNo of the last selected cue_name expression
    overwrite_layer     =   4,    -- overriden by user
    -- not user accessible:
    shift_exp_up        =    24,     -- cue_name above staff
    shift_exp_down      =   -24 * 9, -- cue_name below staff
    shift_exp_left      =   -24, -- EVPUs; cue names generally need to be LEFT of music start
    -- if creating a new "Cue Names" category ...
    cue_category_name   =   "Cue Names",
    cue_font_smaller    =   1, -- how many points smaller than the standard technique expression
    window_pos_x        =   false,
    window_pos_y        =   false,
}
local hotkey = { -- customise
    show_info          = "q",
    copy_articulations = "w",
    copy_expressions   = "e",
    copy_smartshapes   = "r",
    copy_lyrics        = "t",
    mute_cuenotes      = "y",
    --
    set_all        = "a",
    clear_all      = "s",
    all_staves     = "d",
    no_staves      = "f",
    empty_staves   = "g",
    --
    octave_dn1     = "z",
    octave_dn2     = "-",
    octave_up1     = "x",
    octave_up2     = "+",
    stem_direction = "c",
    stems_oppose   = "v",
}
local options = {
    check =   { "copy_articulations", "copy_expressions", "copy_smartshapes", "copy_lyrics", "mute_cuenotes" },
    integer = { "cuenote_percent", "source_layer", "cuenote_layer" }, -- integer edit boxes
    button =  { "Set All", "Clear All", "All Staves", "No Staves", "Empty Staves" }
}
local configuration = require("library.configuration")
local layer = require("library.layer")
local mixin = require("library.mixin")
local note_entry = require("library.note_entry")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local title = plugindef():gsub("%.%.%.", "")
local refocus_document = false -- set to true if utils.show_notes_dialog is used

local function refocus()
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

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
    finenv.UI():AlertInfo(msg, title .. " Error")
end

local function region_is_empty(region, layer_number)
    for entry in eachentry(region, layer_number) do
        if entry.Count > 0 then return false end
    end
    return true
end

local function info_dialog(dialog)
    utils.show_notes_dialog(dialog, "About " .. title)
    refocus_document = true
end

local function make_info_button(dialog, x, y)
    dialog:CreateButton(x, y, "q"):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() info_dialog(dialog) end)
end

local function get_staff_name(staff_num)
    local staff = finale.FCStaff() -- copy the source Staff Name
    staff:Load(staff_num)
    return {
        full   = staff:CreateDisplayFullNameString().LuaString,
        abbrev = staff:CreateDisplayAbbreviatedNameString().LuaString
    }
end

local function new_cue_name(source_staff)
    local name = get_staff_name(source_staff)
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(title)
    dialog:CreateStatic(0, 0):SetText("Cue Staff: " .. name.full):SetWidth(200)
    dialog:CreateStatic(0, 17):SetText("New cue name:"):SetWidth(100)
    make_info_button(dialog, 180, 17)
    local name_edit = dialog:CreateEdit(0, 40):SetWidth(200)
        :SetText(config.abbreviate and name.abbrev or name.full)
    dialog:CreateCheckbox(0, 62, "abbreviate"):SetText("Abbreviate staff name")
        :SetWidth(150):SetCheck(config.abbreviate and 1 or 0)
        :AddHandleCommand(function(self)
            name_edit:SetText(self:GetCheck() == 1 and name.abbrev or name.full)
        end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        config.abbreviate = (dialog:GetControl("abbreviate"):GetCheck() == 1)
    end)
    dialog:RegisterInitWindow(function() name_edit:SetFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK), name_edit:GetText()
end

local function choose_name_index(name_list, source_staff)
    local name = get_staff_name(source_staff)
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(title)
    dialog:CreateStatic(0, 0):SetText("Cue Staff: " .. name.full):SetWidth(200)
    dialog:CreateStatic(0, 17):SetText("Select cue name:"):SetWidth(100)
    make_info_button(dialog, 180, 17)
    local staff_list = dialog:CreateListBox(0, 40):SetWidth(200)
        :AddString("*** new cue name ***") -- menu item [0] is "*** new name ***"
    for i, v in ipairs(name_list) do -- add all names in the extant list
        staff_list:AddString(v[1])
        if v[2] == config.cuename_item then staff_list:SetSelectedItem(i) end
    end
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
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK), staff_list:GetSelectedItem()
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
    local source_name
    local staff_list = {} -- staff number; name
    for staff_number in eachstaff(rgn) do
        local name = get_staff_name(staff_number)
        if staff_number == source_staff then
            source_name = name.full
        else
            table.insert(staff_list, { staff_number, name.full })
        end
    end
    local max = layer.max_layers()
    local answer, saved = {}, {}

    -- make the dialog
    local x_grid = { 210, 310, 370 }
    local y_step = 19
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(title)
    dialog:CreateStatic(0, 0):SetText("Cue Staff:"):SetWidth(57)
    answer.staff_name = dialog:CreateStatic(55, 0):SetText(source_name):SetWidth(200)
    local y = y_step
    dialog:CreateStatic(0, y):SetText("Select Destination Staff(s):"):SetWidth(150)
    local max_rows = #options.check + #options.integer + 1
    local num_rows = (#staff_list > (max_rows + 2)) and max_rows or (#staff_list + 2)
    y = y + y_step
    local data_list = dialog:CreateDataList(0, y)
        :SetWidth(x_grid[1] - 10)
        :SetUseCheckboxes(true)
        :SetHeight(num_rows * y_step)
        :AddColumn("", x_grid[1] - 10)
        :SetShowHeader(false)
        :SetExpandLastColumn(true)
        :SetAllowsMultipleSelection(true)
        :UseAlternatingBackgroundRowColors(true)
    for _, v in ipairs(staff_list) do -- add all staff names to list
        data_list:CreateRow():GetItemAt(0).LuaString = v[2]
    end
        -- local functions
        local function set_check_state(state)
            for _, v in ipairs(options.check) do
                answer[v]:SetCheck(state)
            end
        end
        local function set_list_state(state)
            data_list:UnselectAll() -- start blank
            for i, v in ipairs(staff_list) do
                local list_row = data_list:GetItemAt(i - 1)
                if state == -1 then -- is this staff empty?
                    rgn.StartStaff = v[1]
                    rgn.EndStaff = v[1]
                    list_row.Check = region_is_empty(rgn, 0)
                else -- "No Staves" = 0 / "All Staves" = 1
                    list_row.Check = (state == 1)
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
                if     s:find(hotkey.show_info)     then info_dialog()
                elseif s:find(hotkey.mute_cuenotes) then flip_check("mute_cuenotes")
                elseif s:find(hotkey.set_all)       then set_check_state(1)
                elseif s:find(hotkey.clear_all)     then set_check_state(0)
                elseif s:find(hotkey.all_staves)    then set_list_state(1)
                elseif s:find(hotkey.no_staves)     then set_list_state(0)
                elseif s:find(hotkey.empty_staves)  then set_list_state(-1) -- empty staves
                elseif s:find(hotkey.octave_dn1) or s:find(hotkey.octave_dn2) then octave_change(1)
                elseif s:find(hotkey.octave_up1) or s:find(hotkey.octave_up2) then octave_change(-1)
                elseif s:find(hotkey.stem_direction) then flip_direction() -- up/down stem
                elseif s:find(hotkey.stems_oppose)   then flip_check("stems_oppose")
                else
                    for _, v in ipairs(options.check) do
                        if s:find(hotkey[v]) then flip_check(v) break end
                    end
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
    y = y_step
    dialog:CreateStatic(x_grid[1], 0):SetText("Cue Options:"):SetWidth(150)
    for _, v in ipairs(options.check) do -- run through check options
        answer[v] = dialog:CreateCheckbox(x_grid[1], y):SetText(v:gsub("_", " "))
            :SetWidth(120):SetCheck(config[v] and 1 or 0)
        y = y + y_step
    end

    local y_offset = finenv.UI():IsOnMac() and 3 or 0
    for i, v in ipairs(options.integer) do -- run through integer options
        dialog:CreateStatic(x_grid[1], y):SetText(v:gsub("_", " ") .. ":"):SetWidth(150)
        answer[v] = dialog:CreateEdit(x_grid[2], y - y_offset):SetInteger(config[v])
            :SetWidth(i == 1 and 40 or 20) -- layer numbers thinner
            :AddHandleCommand(function() key_check(v) end)
        saved[v] = tostring(config[v])
        y = y + y_step
    end
    answer.stem_direction = dialog:CreatePopup(x_grid[1], y + 2):SetWidth(150)
        :AddStrings("Cue Stems Up", "Cue Stems Down")  -- == 0 ... 1
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
        if i < 3 then
            buttons[name]:AddHandleCommand(function() set_check_state(2 - i) end)
        else
            buttons[name]:AddHandleCommand(function() set_list_state(4 - i) end)
        end
    end
    dialog:CreateStatic(x_grid[3] + 15, y_step * 3 + 3):SetText("SELECT:"):SetWidth(80)
    dialog:CreateStatic(x_grid[3], y_step * 7 + 9):SetText("cue octave offset:"):SetWidth(100)
    answer.octave_offset = dialog:CreatePopup(x_grid[3] + 25, (y_step * 8) + 6):SetWidth(40)
    for i = 5, -5, -1 do
        local pole = (i > 0) and "+" or ""
        answer.octave_offset:AddString(pole .. i)
    end
    answer.octave_offset:SetSelectedItem(5 - config.octave_offset)
    make_info_button(dialog, x_grid[3] + 60, y_step * 10 + 3)
    -- flip select state on double-click!
    dialog:RegisterHandleListDoubleClick(function()
        set_list_state(data_list:GetItemAt(0).Check and 0 or 1)
    end)
    -- run the dialog
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    local chosen_staves = {} -- return the user's chosen destination staves
    dialog:RegisterHandleOkButtonPressed(function()
        for i, v in ipairs(staff_list) do -- check every staff for selection
            local list_row = data_list:GetItemAt(i - 1)
            if data_list:IsLineSelected(i - 1) or list_row.Check then
                table.insert(chosen_staves, v[1])
            end
        end
        for _, v in ipairs(options.check) do -- save config values
            config[v] = (answer[v]:GetCheck() == 1)
        end
        for _, v in ipairs(options.integer) do
            config[v] = answer[v]:GetInteger()
        end
        config.stem_direction = answer.stem_direction:GetSelectedItem() -- 0-based
        config.octave_offset  = 5 - answer.octave_offset:GetSelectedItem() -- octave offset value
        config.stems_oppose = (answer.stems_oppose:GetCheck() == 1)
    end)
    dialog:RegisterInitWindow(function(self)
            data_list:SetKeyboardFocus()
            local bold = answer.staff_name:CreateFontInfo():SetBold(true)
            answer.staff_name:SetFont(bold)
            self:GetControl("q"):SetFont(bold)
        end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK), chosen_staves
end

local function choose_overwrite_layer(staff_name, empty_layers)
    local msg = "The chosen cuenote layer (" .. config.cuenote_layer
        .. ") on staff \"" .. staff_name .. "\" already contains music."
    local wide = 200

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(title)
    dialog:CreateStatic(0, 0):SetText(msg):SetWidth(wide):SetHeight(52)
    make_info_button(dialog, wide - 20, 52)
    dialog:CreateStatic(0, 55):SetText("Please confirm:"):SetWidth(100)
    local list = dialog:CreateListBox(0, 75):SetWidth(wide):SetHeight(70)
    for i = 1, layer.max_layers() do
        if i == config.cuenote_layer then
            list:AddString("overwrite CUENOTE layer " .. i)
        else
            msg = empty_layers[i] and "use empty layer " or "overwrite layer "
            list:AddString(msg .. i)
        end
        if i == config.overwrite_layer then list:SetSelectedItem(i - 1) end
    end
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        config.overwrite_layer = list:GetSelectedItem() + 1
    end)
    dialog:RegisterInitWindow(function() list:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    local answer = -1 -- assume cancellation
    if (dialog:ExecuteModal() == finale.EXECMODAL_OK) then -- reasoned choice
        answer = list:GetSelectedItem() + 1
    end
    return answer
end

local function get_layer_rest_offset(layer_num)
    local layer_prefs = finale.FCLayerPrefs()
    layer_prefs:Load(layer_num - 1)
    local rest_offset = math.abs(layer_prefs:GetRestOffset()) -- ignore polarity
    rest_offset = math.max(rest_offset, 4) -- not less than 4
    if config.stem_direction == 1 then rest_offset = -rest_offset end -- downstem
    return rest_offset
end

local function check_empty_cue_layer(rgn)
    if region_is_empty(rgn, config.cuenote_layer) then
        return config.cuenote_layer -- user's layer choice is CONFIRMED
    end
    local staff = finale.FCStaff()
    staff:Load(rgn.StartStaff) -- staff number of this slot
    local staff_name = staff:CreateDisplayFullNameString().LuaString
    local empty_layers = {} -- collate empty layers
    for i = 1, layer.max_layers() do -- any empty layers?
        empty_layers[i] = region_is_empty(rgn, i)
    end
    return choose_overwrite_layer(staff_name, empty_layers)
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
    -- cue_layer may or may not be config.cuenote_layer
    local cue_layer = check_empty_cue_layer(dest_region)
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
                    note.Displacement = note.Displacement + (config.octave_offset * 7)
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
            for _, v in ipairs{"FCMChorusSyllable", "FCMSectionSyllable", "FCMVerseSyllable"} do
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
    return ok, (ok and new_category:GetID() or 0)
end

local function find_first_non_rest(staff, measure)
    local nel = finale.FCNoteEntryLayer(config.source_layer - 1, staff, measure, measure)
    nel:Load()
    for i = 0, (nel.Count - 1) do
        local e = nel:GetItemAt(i)
        if e ~= nil and e:IsNote() then
            return e.MeasurePos
        end
    end
    return 0
end

local function create_cue_notes()
    configuration.get_user_settings(script_name, config, true)
    local cue_names = { } -- compile NAME/ItemNo of all pre-existing CUE_NAME expressions
    local source_region = mixin.FCMMusicRegion()
    source_region:SetRegion(finenv.Region()):SetStartMeasurePosLeft():SetEndMeasurePosRight()
    local start_staff = source_region.StartStaff

    -- declare other local variables
    local ok, name_index, new_expression, destination_staves
    if source_region:CalcStaffSpan() > 1 then show_error("only_one_staff") return end
    if region_is_empty(source_region, 0) then show_error("empty_region") return end

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
                table.insert(cue_names, {str.LuaString, text_def.ItemNo} ) -- save expresion NAME and ItemNo
            end
        end
        table.sort(cue_names, function(a, b) return string.lower(a[1]) < string.lower(b[1]) end)
    end

    -- test for pre-existing names
    if cat_ID < 0 then -- create a new Text Expression Category
        ok, cat_ID = new_expression_category(config.cue_category_name)
        if not ok then -- creation failed
            show_error("make_expression_category")
            refocus()
            return
        end
    end
    -- choose cue name
    ok, name_index = choose_name_index(cue_names, start_staff) -- saved in config.cuename_item
    if not ok then refocus() return end
    if name_index == 0 then	-- USER wants to provide a new cue name
        ok, new_expression = new_cue_name(start_staff)
        if not ok or new_expression == "" then refocus() return end
        create_new_expression(new_expression, cat_ID) -- ID saved in config.cuename_item
    end
    -- choose destination staff
    ok, destination_staves = choose_destination_staff(start_staff)
    if not ok then refocus() return end
    if region_is_empty(source_region, config.source_layer) then
        show_error("no_notes_in_source_layer")
        refocus()
        return
    end
    -- make the cue copy
    local vert_shift = (config.stem_direction == 1) and config.shift_exp_down or config.shift_exp_up
    local measure_pos = find_first_non_rest(start_staff, source_region.StartMeasure)
    for _, one_staff in ipairs(destination_staves) do
        if notelayer_copy(source_region, one_staff) then
            local cue_name = mixin.FCMExpression() -- "name" the cue
            cue_name:SetStaff(one_staff)
                :SetVisible(true)
                :SetMeasurePos(measure_pos)
                :SetLayerAssignment(config.cuenote_layer)
                :SetScaleWithEntry(false)
                :SetPartAssignment(true)
                :SetScoreAssignment(true)
                :SetID(config.cuename_item)
                :SetHorizontalPos(config.shift_exp_left)
                :SetVerticalPos(vert_shift)
                :SaveNewToCell(finale.FCCell(source_region.StartMeasure, one_staff))
        end
    end
    refocus()
    source_region:SetInDocument()
end

create_cue_notes()

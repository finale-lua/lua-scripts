function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.89"
    finaleplugin.Date = "2023/12/29"
    finaleplugin.MinJWLuaVersion = 0.68
	finaleplugin.Notes = [[ 
        This script presents an alphabetical list of 24 individual types 
        of data to delete, each line beginning with a configurable "hotkey". 
        Call the script, type the hotkey and hit [Enter] or [Return]. 
        Half of the datatypes can be filtered by layer.

        DELETE INDEPENDENTLY:  
        Articulations• | Articulations on Rests• | Chords | Cross Staff Entries•  
        Custom Lines | Dynamics• | Expressions (Not Dynamics)•  
        Expressions (All)• | Expressions (Measure-Attached) | Glissandos  
        Hairpins | Lyrics• | MIDI Continuous Data | MIDI Note Data•  
        Note Position Offsets• | Notehead Modifications• | Secondary Beam Breaks•  
        Slurs | Smart Shapes (Note Attached) • | Smart Shapes (Beat Attached)  
        Smart Shapes (All) | Staff Styles | Tuplets• | User Selected...  
        (• = filter by layer)

        To delete the same data as last time without a confirmation dialog 
        hold down [shift] when starting the script. 
        The layer number is "clamped" to a single character so to change 
        layer just type a new number - 'delete' key not needed.
    ]]
    return "Deletion Chooser...", "Deletion Chooser", "Choose specific items to delete by keystroke"
end

local info_notes = [[ 
This script presents an alphabetical list of 24 individual types
of data to delete, each line beginning with a configurable "hotkey".
Call the script, type the hotkey and hit [Enter] or [Return].
Half of the datatypes can be filtered by layer.
**
DELETE INDEPENDENTLY:
*Articulations • | Articulations on Rests • | Chords | Cross Staff Entries •
*Custom Lines | Dynamics • | Expressions (Not Dynamics) •
*Expressions (All) • | Expressions (Measure-Attached) | Glissandos
*Hairpins | Lyrics • | MIDI Continuous Data | MIDI Note Data •
*Note Position Offsets• | Notehead Modifications• | Secondary Beam Breaks•
*Slurs | Smart Shapes (Note Attached) • | Smart Shapes (Beat Attached)
*Smart Shapes (All) | Staff Styles | Tuplets• | User Selected...
*(• = filter by layer)
**
To delete the same data as last time without a confirmation dialog,
hold down [shift] when starting the script.
The layer number is "clamped" to a single character so to change
layer just type a new number - 'delete' key not needed.
]]
info_notes = info_notes:gsub("\n%s*", " "):gsub("*", "\n")

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local expression = require("library.expression")
local layer = require("library.layer")
local script_name = "deletion_chooser"
-- Mac / Windows menu command value ...
local clear_selected_items_menu = finenv.UI():IsOnMac() and 1296385394 or 16010

local dialog_options = { -- key, text description (ordered)
    { "entry_articulation", "Articulations •" },
    { "rest_articulation", "Articulations on Rests •" },
    { "chords", "Chords" },
    { "cross_staff", "Cross Staff Entries •" },
    { "shape_IsCustomLine", "Custom Lines" },
    { "expression_dynamic", "Dynamics •" },
    { "expression_not_dynamic", "Expressions (Not Dynamics) •" },
    { "expression_all", "Expressions (All Note-Attached) •" },
    { "measure_attached", "Expressions (Measure-Attached)" },
    { "shape_IsGlissando", "Glissandos" },
    { "shape_IsHairpin", "Hairpins" },
    { "entry_lyrics", "Lyrics •" },
    { "midi_continuous", "MIDI Continuous Data" },
    { "midi_entry", "MIDI Note Data •" },
    { "entry_position", "Note Position Offsets •" },
    { "notehead_mods", "Notehead Modifications •" },
    { "secondary_beam_breaks", "Secondary Beam Breaks •" }, 
    { "shape_IsSlur", "Slurs" },
    { "shape_IsEntryBased", "Smart Shapes (Note Attached) •" },
    { "shape_GetBeatAttached", "Smart Shapes (Beat Attached)" },
    { "shape_all", "Smart Shapes (All)" },
    { "staff_styles", "Staff Styles (Current Score/Part)" },
    { "entry_tuplets", "Tuplets •" },
    { "user_selected", "User Selected Items ..."}
}

local config = { -- keystroke assignments, layer number and window position
    entry_articulation = "A",
    rest_articulation = "R",
    chords = "W",
    cross_staff = "X",
    shape_IsCustomLine = "C",
    expression_dynamic = "D",
    expression_not_dynamic = "E",
    expression_all = "F",
    measure_attached = "M",
    shape_IsGlissando = "G",
    shape_IsHairpin = "H",
    entry_lyrics = "L",
    midi_continuous = "O",
    midi_entry = "I",
    entry_position = "N",
    notehead_mods = "J",
    secondary_beam_breaks = "K",
    shape_IsSlur = "S",
    shape_IsEntryBased = "P",
    shape_GetBeatAttached = "B",
    shape_all = "V",
    staff_styles = "Y",
    entry_tuplets = "T",
    user_selected = "Z",
    last_selected = 0, -- last selected menu item number (0-based)
    window_pos_x = false,
    window_pos_y = false,
    ignore_duplicates = 0,
    layer_num = 0,
}

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

function shape_check_layer(shape, layer_num)
    if layer_num == 0 then return true end -- no layer check
    local left_seg = shape:GetTerminateSegmentLeft()
    local cell = finale.FCNoteEntryCell(left_seg.Measure, left_seg.Staff)
    cell:Load()
    -- assume both ends of the shape are on the same layer!
    local entry = cell:FindEntryNumber(left_seg.EntryNumber)
    return (entry.LayerNumber == layer_num)
end

local function delete_selected(delete_type)
    local rgn = finenv.Region()
    local layer_num = tonumber(config.layer_num)

    if delete_type == "user_selected" then -- access Finale menu: Edit -> "Clear Selected Items"
        if not finenv.UI():ExecuteOSMenuCommand(clear_selected_items_menu) then
            finenv.UI():AlertError("RGP Lua couldn't identify the Finale menu item "
                .. "\"Edit\" -> \"Clear Selected Items...\"", "Error")
        end
    --
    elseif delete_type:find("shape") then -- SMART SHAPE of some description
        -- both beat-attached and note-attached with RGPLua 0.68+
        for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), rgn) do
            local shape = mark:CreateSmartShape()
            local test = delete_type:sub(7, -1) -- extract shape "function" from type key value
            if shape and (delete_type == "shape_all" or shape[test](shape)) then
                if not delete_type:find("Entry") or shape_check_layer(shape, layer_num) then
                    shape:DeleteData()
                end
            end
        end
    --
    elseif delete_type:find("express") then -- EXPRESSION of some kind
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(rgn)
        for exp in eachbackwards(expressions) do
            if layer_num == 0 or exp.LayerAssignment == 0 or layer_num == exp.LayerAssignment then
                if exp.StaffGroupID == 0 and -- ??? not exp:IsShape() and 
                (      (delete_type == "expression_all")
                    or (delete_type == "expression_not_dynamic" and not expression.is_dynamic(exp))
                    or (delete_type == "expression_dynamic" and expression.is_dynamic(exp))
                )
                then
                    exp:DeleteData()
                end
            end
        end
    --
    elseif delete_type == "midi_continuous" then -- MIDI CONTINUOUS data
        local midi_ex = finale.FCMidiExpressions()
        midi_ex:LoadAllForRegion(rgn)
        for exp in eachbackwards(midi_ex) do
            exp:DeleteData()
        end
    --
    elseif delete_type == "chords" then -- CHORDS
        local chords = finale.FCChords()
        chords:LoadAllForRegion(rgn)
        for chord in eachbackwards(chords) do
            if chord then chord:DeleteData() end
        end
    --
    elseif delete_type == "measure_attached" then -- MEASURE-ATTACHED EXPRESSIONS type
        local measures = finale.FCMeasures()
        measures:LoadRegion(rgn)
        for measure in each(measures) do
            for exp in eachbackwards(measure:CreateExpressions()) do
                if exp.StaffGroupID > 0 then
                    exp:DeleteData()
                end
            end
            local m_exp = finale.FCExpression()
            if not m_exp:Load(measure.ItemNo, 0) then
                measure.ExpressionFlag = false -- no expressions left
                measure:Save()
            end
        end
    --
    elseif delete_type == "staff_styles" then -- STAFF STYLES
        for staff_number in eachstaff(rgn) do
            local style_assign = finale.FCStaffStyleAssigns()
            style_assign:LoadAllForItem(staff_number)
            for style in eachbackwards(style_assign) do
                local ss = { L = style.StartMeasure, R = style.EndMeasure }
                local rr = { L = rgn.StartMeasure, R = rgn.EndMeasure }
                if (ss.L <= rr.R and ss.R >= rr.L) then -- this style is in range
                    if (ss.L >= rr.L) and (ss.R <= rr.R) then
                        style:DeleteData() -- selection encloses style
                    else
                        if ss.L >= rr.L then -- (ss.R > rr.R) so move LH to right of selection
                            style.StartMeasure = rr.R + 1
                            style:Save()
                        else -- ss.L < rr.L: style starts before selection
                            style.EndMeasure = rr.L - 1
                            style:Save() -- move LH side to before selection
                            if ss.R > rr.R then -- continues to right of selection
                                local style_copy = mixin.FCMStaffStyleAssign()
                                style_copy:SetStyleID(style.StyleID) -- copy it
                                    :SetStartMeasure(rr.R + 1) -- move past selection
                                    :SetEndMeasure(ss.R)
                                    :SaveNew(staff_number)
                            end
                        end
                    end
                end
            end
        end
    --
    else -- ENTRY-attached datatypes remain: step through selected region
        for entry in eachentrysaved(rgn, layer_num) do
            --
            if delete_type:find("artic") and entry.ArticulationFlag then -- ARTICULATION
                if delete_type == "entry_articulation" or (entry:IsRest() and delete_type == "rest_articulation") then
                    for articulation in eachbackwards(entry:CreateArticulations()) do
                        articulation:DeleteData()
                    end
                    entry:SetArticulationFlag(false)
                end
            --
            elseif delete_type == "notehead_mods" and entry:IsNote() then -- NOTE-HEAD MODS
                local mods = entry:CreateNoteheadMods()
                if mods.Count > 0 then
                    for mod in eachbackwards(mods) do
                        mod:DeleteData()
                    end
                end
            --
            elseif delete_type == "midi_entry" and entry.PerformanceDataFlag then -- NOTE-BASED MIDI
                local perf_mods = entry:CreatePerformanceMods()
                if perf_mods.Count > 0 then
                    for mod in eachbackwards(perf_mods) do
                        mod:DeleteData()
                    end
                end
                entry.PerformanceDataFlag = false
            --
            elseif delete_type == "entry_lyrics" and entry.LyricFlag then -- LYRICS
                for _, v in ipairs({ "FCChorusSyllable", "FCSectionSyllable", "FCVerseSyllable" }) do
                    local lyric = finale[v]()
                    lyric:SetNoteEntry(entry)
                    while lyric:LoadFirst() do
                        lyric:DeleteData()
                    end
                end
            --
            elseif delete_type == "entry_tuplets" and entry.TupletStartFlag then -- TUPLETS
                local tuplets = entry:CreateTuplets()
                for tuplet in eachbackwards(tuplets) do
                    tuplet:DeleteData()
                end
                tuplets:ClearAll()
                entry.TupletStartFlag = false
            --
            elseif delete_type == "entry_position" then -- NOTE POSITION OFFSETS
                entry.ManualPosition = 0
            --
            elseif delete_type == "secondary_beam_breaks" then -- SECONDARY BEAM BREAKS
                local sbbm = finale.FCSecondaryBeamBreakMod()
                sbbm:SetNoteEntry(entry)
                while sbbm:LoadFirst() do
                    sbbm:DeleteData()
                end
            --
            elseif delete_type == "cross_staff" then -- CROSS-STAFF
                entry.FreezeBeam = false
                entry.FreezeStem = false
                entry.ManualPosition = 0
                entry.ReverseUpStem = false
                entry.ReverseDownStem = false
                if entry:IsRest() then
                    entry.FloatingRest = true
                else
                    for _, type in ipairs( {"FCCrossStaffMods", "FCPrimaryBeamMods"} ) do
                        local mods = finale[type](entry)
                        mods:LoadAll()
                        for m in eachbackwards(mods) do
                            m:DeleteData()
                        end
                    end
                end
                entry.CrossStaff = false
            end
        end
    end
end

local function reassign_keys(selected)
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Reassign Hotkeys")
    local is_duplicate, errors = false, {}
    local y = 0
    for _, v in ipairs(dialog_options) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v[1]):SetText(config[v[1]]):SetWidth(20)
            :AddHandleCommand(function(self)
                local str = self:GetText():upper():sub(-1)
                self:SetText(str):SetKeyboardFocus()
            end)
        dialog:CreateStatic(25, y):SetText(v[2]):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore_duplicates or 0)
    dialog:CreateOkButton():SetText("Save")
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self) self:GetControl(selected):SetKeyboardFocus() end)
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for i, v in ipairs(dialog_options) do
            local key = self:GetControl(v[1]):GetText()
            if key == "" then key = "?" end -- not null
            config[v[1]] = key -- save for another possible run-through
            config.ignore_duplicates = ignore:GetCheck()
            if config.ignore_duplicates == 0 then -- DON'T IGNORE duplicates
                if assigned[key] then -- previously assigned
                    is_duplicate = true
                    if not errors[key] then errors[key] = { assigned[key] } end
                    table.insert(errors[key], i)
                else
                    assigned[key] = i -- flag key assigned
                end
            end
        end
        if is_duplicate then -- list reassignment duplications
            local msg = ""
            for k, v in pairs(errors) do
                msg = msg .. "Key \"" .. k .. "\" is assigned to: "
                for i, w in ipairs(v) do
                    if i > 1 then msg = msg .. " and " end
                    msg = msg .. "\"" .. dialog_options[w][2] .. "\""
                end
                msg = msg .. "\n\n"
            end
            finenv.UI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

local function user_chooses()
    local y_step = 17
    local box_wide = 236
    local box_high = (#dialog_options * y_step) + 5
    local x_off = box_wide / 4
    local y = box_high + 27
    local max = layer.max_layers()
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local function show_info() finenv.UI():AlertInfo(info_notes, "About " .. plugindef()) end

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Delete data of type:"):SetWidth(box_wide)

    local key_list = dialog:CreateListBox(0, 20):SetWidth(box_wide):SetHeight(box_high)
        local function fill_key_list()
            local join = finenv.UI():IsOnMac() and "\t" or ":  "
            key_list:Clear()
            for _, v in ipairs(dialog_options) do
                key_list:AddString(config[v[1]] .. join .. v[2])
            end
            key_list:SetSelectedItem(config.last_selected or 0)
        end
        local function change_keys()
            local ok, is_duplicate = true, true
            local selected = dialog_options[key_list:GetSelectedItem() + 1][1]
            while ok and is_duplicate do -- wait for valid choice in reassign_keystrokes()
                ok, is_duplicate = reassign_keys(selected)
            end
            if ok then fill_key_list() end
        end

    fill_key_list()
    dialog:CreateStatic(0, y):SetWidth(x_off * 3):SetText("For data types marked [•]:")
    y = y + y_step
    dialog:CreateStatic(0, y):SetWidth(x_off + 36):SetText("Active Layer 1-" .. max)
    local save_layer = config.layer_num or "0"
    local layer_num = dialog:CreateEdit(x_off + 37, y - offset):SetWidth(20):SetText(save_layer)
        :AddHandleCommand(function(self)
            local val = self:GetText():lower()
            if val:find("[^0-" .. max .. "]") then
                if val:find("[?q]") then show_info()
                elseif val:find("r") then change_keys()
                end
                self:SetText(save_layer):SetKeyboardFocus()
            elseif val ~= "" then
                val = val:sub(-1)
                self:SetText(val)
                save_layer = val
            end
        end)

    dialog:CreateStatic(x_off + 60, y):SetWidth(x_off):SetText("(0 = all)")
    y = y + y_step + 2
    dialog:CreateButton(0, y):SetText("Reassign Hotkeys"):SetWidth(x_off * 2)
        :AddHandleCommand(function() change_keys() end)
    dialog:CreateButton(box_wide - 20, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dialog:CreateOkButton():SetText("Select")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
            config.last_selected = key_list:GetSelectedItem() -- save list choice
            config.layer_num = layer_num:GetInteger()
        end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dialog:RegisterInitWindow(function() key_list:SetKeyboardFocus() end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function select_delete_type()
    configuration.get_user_settings(script_name, config, true)
    local qimk = finenv.QueryInvokedModifierKeys
    local mod_key = qimk and (qimk(finale.CMDMODKEY_ALT) or qimk(finale.CMDMODKEY_SHIFT))

    if mod_key or user_chooses() then
        local delete_type = dialog_options[config.last_selected + 1][1]
        delete_selected(delete_type)
    end
    finenv.UI():ActivateDocumentWindow()
end

select_delete_type()

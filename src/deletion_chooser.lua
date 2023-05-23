function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.72"
    finaleplugin.Date = "2023/05/24"
    finaleplugin.MinJWLuaVersion = 0.62
	finaleplugin.Notes = [[
        This script evolved from "delete_selective.lua" which produces 
        a heap of menu items to choose between type of deletion. 
        This re-working uses a single menu item to produce an ordered list 
        of deletion types, each line beginning with a configurable "key" code. 
        Call the script, type the key code and hit [Enter] or [Return].  

        Delete independently:  
        ```
        Articulations | Articulations (on Rests) | Custom Lines | Dynamics  
        Cross Staff Entries | Expressions (Not Dynamics) | Expressions (All)  
        Expressions (Measure-Attached) | Glissandos | Hairpins | Lyrics  
        Note Position Offsets | MIDI Continuous Data | MIDI Note Data  
        Slurs | Smart Shapes (Beat Aligned) | Smart Shapes (All)  
        Staff Styles (Current Score/Part) | Tuplets | User Selected Items
        ```
    ]]
    return "Deletion Chooser...", "Deletion Chooser", "Choose specific items to delete by keystroke"
end

local dialog_options = { -- key, text description (ordered)
    { "entry_articulation", "Articulations" },
    { "rest_articulation", "Articulations on Rests" },
    { "cross_staff", "Cross Staff Entries" },
    { "shape_custom", "Custom Lines" },
    { "expression_dynamic", "Dynamics" },
    { "expression_not_dynamic", "Expressions (Not Dynamics)" },
    { "expression_all", "Expressions (All Note-Attached)" },
    { "measure_attached", "Expressions (Measure-Attached)" },
    { "shape_glissando", "Glissandos" },
    { "shape_hairpin", "Hairpins" },
    { "entry_lyrics", "Lyrics" },
    { "continuous_midi", "MIDI Continuous Data" },
    { "entry_midi", "MIDI Note Data" },
    { "entry_position", "Note Position Offsets" },
    { "shape_slur", "Slurs" },
    { "shape_all", "Smart Shapes (All)" },
    { "shape_beat_aligned", "Smart Shapes (Beat Aligned)" },
    { "staff_styles", "Staff Styles (Current Score/Part)" },
    { "entry_tuplets", "Tuplets" },
    { "user_selects", "User Selected Items ..."}
}

local config = { -- keystroke assignments and window position
    entry_articulation = "A",
    rest_articulation = "R",
    cross_staff = "X",
    shape_custom = "C",
    expression_dynamic = "D",
    expression_not_dynamic = "F",
    expression_all = "E",
    measure_attached = "M",
    shape_glissando = "G",
    shape_hairpin = "H",
    entry_lyrics = "L",
    continuous_midi = "P",
    entry_midi = "I",
    entry_position = "N",
    shape_slur = "S",
    shape_beat_aligned = "B",
    shape_all = "V",
    staff_styles = "Y",
    entry_tuplets = "T",
    user_selects = "Z",
    last_selected = 0, -- last selected menu item number (0-based)
    window_pos_x = false,
    window_pos_y = false,
    ignore = 0,
}
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local expression = require("library.expression")
local script_name = "deletion_chooser"
configuration.get_user_settings(script_name, config, true)
-- Mac / Windows menu command value ...
local clear_selected_items_menu = (finenv.UI():IsOnMac()) and 1296385394 or 16010

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

function delete_selected(delete_type)
    local rgn = finenv.Region()

    if delete_type == "user_selects" then -- access Finale menu: Edit -> "Clear Selected Items"
        if not finenv.UI():ExecuteOSMenuCommand(clear_selected_items_menu) then
            finenv.UI():AlertError("RGP Lua couldn't identify the Finale menu item "
                .. "\"Edit\" -> \"Clear Selected Items...\"", "Error")
        end
    --
    elseif string.find(delete_type, "shape") then -- SMART SHAPE of some description
        local marks = finale.FCSmartShapeMeasureMarks()
        marks:LoadAllForRegion(rgn, true)
        for mark in each(marks) do
            local shape = mark:CreateSmartShape()
            if (delete_type == "shape_all")
                or (delete_type == "shape_hairpin" and shape:IsHairpin())
                or (delete_type == "shape_slur" and shape:IsSlur())
                or (delete_type == "shape_custom" and shape:IsCustomLine())
                or (delete_type == "shape_glissando" and shape:IsGlissando())
                or (delete_type == "shape_beat_aligned" and not shape:IsEntryBased())
            then
                shape:DeleteData()
            end
        end
    --
    elseif string.find(delete_type, "express") then -- EXPRESSION of some type
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(rgn)
        for exp in eachbackwards(expressions) do
            if not exp:IsShape() and exp.StaffGroupID == 0 and
                (    (delete_type == "expression_all")
                or (delete_type == "expression_not_dynamic" and not expression.is_dynamic(exp))
                or (delete_type == "expression_dynamic" and expression.is_dynamic(exp))
                )
            then
                exp:DeleteData()
            end
        end
    --
    elseif delete_type == "continuous_midi" then -- MIDI CONTINUOUS data
        local midi_ex = finale.FCMidiExpressions()
        midi_ex:LoadAllForRegion(rgn)
        for exp in eachbackwards(midi_ex) do
            exp:DeleteData()
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
        for slot = rgn.StartSlot, rgn.EndSlot do
            local ssa = finale.FCStaffStyleAssigns()
            ssa:LoadAllForItem(rgn:CalcStaffNumber(slot))
            for style in eachbackwards(ssa) do
                if rgn:IsMeasureIncluded(style.StartMeasure) and rgn:IsMeasureIncluded(style.EndMeasure) then
                    style:DeleteData()
                end
            end
        end
    --
    else -- ENTRY-attached data deletions remain: step through selected region
        for entry in eachentrysaved(rgn) do
            --
            if string.find(delete_type, "artic") and entry.ArticulationFlag then -- ARTICULATION
                if delete_type == "entry_articulation" or (entry:IsRest() and delete_type == "rest_articulation") then
                    for articulation in eachbackwards(entry:CreateArticulations()) do
                        articulation:DeleteData()
                    end
                    entry:SetArticulationFlag(false)
                end
            --
            elseif delete_type == "entry_midi" and entry.PerformanceDataFlag then -- NOTE-BASED MIDI
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
            elseif delete_type == "cross_staff" then -- CROSS-STAFF
                entry.FreezeBeam = false
                entry.FreezeStem = false
                entry.ManualPosition = 0
                if entry.ReverseStem then entry.ReverseStem = false end -- check spelling in RGPLua 0.68
                if entry:IsRest() then entry.FloatingRest = true end

                for _, type in ipairs( {"FCCrossStaffMods", "FCPrimaryBeamMods"} ) do
                    local mods = finale[type](entry)
                    mods:LoadAll()
                    for i = mods.Count, 1, -1 do
                        mods:GetItemAt(i - 1):DeleteData()
                    end
                end
                entry.CrossStaff = false
            end
        end
    end
end

function reassign_keys()
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Reassign Keys")
    local is_duplicate, errors = false, {}
    local y = 0
    for _, v in ipairs(dialog_options) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v[1]):SetText(config[v[1]]):SetWidth(20)
        dialog:CreateStatic(25, y):SetText(v[2]):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore or 0)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for i, v in ipairs(dialog_options) do
            local key = self:GetControl(v[1]):GetText()
            key = string.upper(string.sub(key, 1, 1)) -- 1st letter, upper case
            if key == "" then key = "?" end -- make sure it's not null
            config[v[1]] = key -- save for another possible run-through
            config.ignore = ignore:GetCheck()

            if ignore:GetCheck() == 0 then -- DON'T ignore duplicates
                if assigned[key] then -- previously assigned
                    is_duplicate = true
                    if not errors[key] then errors[key] = { assigned[key] } end
                    table.insert(errors[key], i)
                else
                    assigned[key] = i -- flag key assigned
                end
            end
        end
    end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    if ok then
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
    end
    return ok, is_duplicate
end

function user_chooses()
    local y_step = 17
    local box_wide = 216
    local box_high = (#dialog_options * y_step) + 5
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 0):SetText("Delete data of type:"):SetWidth(box_wide)

    local key_list = dialog:CreateListBox(0, 20):SetWidth(box_wide):SetHeight(box_high)
    local function fill_key_list()
        key_list:Clear()
        for _, v in ipairs(dialog_options) do -- add all options with keycodes
            key_list:AddString(config[v[1]] .. ": " .. v[2])
        end
        key_list:SetSelectedItem(config.last_selected or 0)
    end
    fill_key_list()
    local y_off = box_wide / 4
    local reassign = dialog:CreateButton(y_off, box_high + 30)
        :SetText("Reassign Keys"):SetWidth(y_off * 2) -- half box width
    reassign:AddHandleCommand(function()
        local ok, is_duplicate = true, true
        while ok and is_duplicate do -- wait for valid choices in reassign_keys()
            ok, is_duplicate = reassign_keys()
        end
        if ok then -- no error ... new key assignments in config
            configuration.save_user_settings(script_name, config)
            fill_key_list()
        end
    end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
            config.last_selected = key_list:GetSelectedItem() -- save list choice
        end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function select_delete_type()
    if not user_chooses() then return end
    local delete_type = dialog_options[config.last_selected + 1][1]
    delete_selected(delete_type)
end

select_delete_type()

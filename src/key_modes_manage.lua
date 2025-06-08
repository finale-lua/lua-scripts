function plugindef()
    finaleplugin.MinJWLuaVersion = 0.72
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1.1"
    finaleplugin.Date = "June 8, 2025"
    finaleplugin.CategoryTags = "Key Signatures"
    finaleplugin.Notes = [[
This script provides a simplified interface for managing the most common types
of custom key modes (called "Nonstandard Key Signatures" in Finale.) Limitations include
        
- Key modes must have 7 diatonic steps per octave
- Linear key signatures must use the standard accidental order and size (for their EDO value)
- Linear tonal centers must follow the standard circle of fifths for their respective key signatures

The dialog has the following main components:

- **List of Keymodes [Delete] [Delete All]**: Shows any currently existing custom key modes in the document, with buttons to delete the current or all of them.
- **MIDI Note for Middle C**: The MIDI note that plays back for the note written one ledger line below the treble clef.
- **Base Tonal Center**: For linear modes, the note that is the tonal center when there is no key signature. For nonlinear modes, the note that is the tonal center.
- **Linear/Nonlinear**: Linear modes can be transposed into the full array of key signatures. Nonlinear modes only ever have the specified key signature.
- **Accidental Font**: The font that is used for accidentals.
- **Accidental Symbols**: Opens a dialog that allows you to specify strings for up to 7 flat steps and 7 sharp steps plus a natural symbol. These strings can have more than one symbol. If no accidentals have been set up, the dialog is populated with the default characters specified in the document settings.

---

- **Diatonic Step Map**: Specifies the number of divisions of the octave between each white note on the keyboard. Before any custom key modes are created in the document, this is initialized with the common practice 12-EDO values. Note that the diatonic step map _always_ starts with C, irrespective of which note is the base tonal center.
- **EDO Presets Pulldown**: This pulldown provides a shortcut for populating the diatonic step map for commonly used EDO values.

---

- **[Linear Key Modes] Accidental Step Amount (Chromatic Halfstep Size)**: This the step amount for each accidental in the key signature as you step into more sharps or more flats in the key signature. To get common practice key signatures, set it to the number of divisions of the octave in a chromatic half-step. (The **EDO Presets Pulldown** sets this value automatically for linear key modes.)
- **[Nonlinear Key Modes] Accidental Order [note][amount]**: The seven pairs of edit fields allow you to specify the accidentals in the nonlinear key signature in any arbitrary order with any mix of sharps of flats. The first amount value of 0 or blank terminates the key signature.
- **Accidental Octaves**: Opens a grid of values by clef types. Each value specifies the octave in which the accidental in that slot appears for that clef. Linear key modes using common practice key signatures generally do not need to specify anything here. Nonlinear key modes almost certainly _will_ need to specify these values.
- **Revert**: Reverts the accidental octaves to their default values.
            ]]
    return "Nonstandard Key Signatures...", "Nonstandard Key Signatures",
           "Manages Nonstandard Key Signatures. Allows view, modify, create, and delete."
end

-- luacheck: ignore 11./global_dialog

local utils = require("library.utils")
local mixin = require("library.mixin")

local win_edit_offset = 3
local mac_edit_offset = 3
local edit_offset = utils.win_mac(win_edit_offset, mac_edit_offset)
local button_offset = utils.win_mac(win_edit_offset + 1, 0)

context = context or
{
    global_timer_id = 1,
    current_doc = 0,
    current_keymodes = finale.FCCustomKeyModeDefs(),
    current_selection = -1,
    current_type_selection = -1,
    current_font = finale.FCFontInfo,
    current_symbol_list = 0,
    current_acci_octaves = {},
    current_preset = -1
}

linear_mode_types =
{
    "Ionian",
    "Dorian",
    "Phrygian",
    "Lydian",
    "Mixolydian",
    "Aeolian",
    "Locrian"
}

note_names =
{
    "C",
    "D",
    "E",
    "F",
    "G",
    "A",
    "B"
}

clef_names =
{
    "Treble",
    "Alto",
    "Tenor",
    "Bass",
    "Percussion",
    "Treble 8vb",
    "Bass 8vb",
    "Baritone",
    "Violin",
    "Baritone C",
    "Mezzo",
    "Soprano",
    "Alt. Perc.",
    "Treble 8va",
    "Bass 8va",
    "Blank",
    "TAB 1",
    "TAB 2"
}

note_number_by_names = (function()
    local retval = {}
    for k, v in ipairs(note_names) do
        retval[v] = k
    end
    return retval
end)()

alteration_names =
{
    [-2] = "bb",
    [-1] = "b",
    [0] = "",
    [1] = "#",
    [2] = "x"
}

presets =
{
    {name = "12-EDO", diatonic_whole = 2, diatonic_half = 1},
    {name = "19-EDO", diatonic_whole = 3, diatonic_half = 2},
    {name = "24-EDO", diatonic_whole = 4, diatonic_half = 2},
    {name = "31-EDO", diatonic_whole = 5, diatonic_half = 3},
    {name = "48-EDO", diatonic_whole = 8, diatonic_half = 4},
    {name = "62-EDO", diatonic_whole = 10, diatonic_half = 6},
    {name = "96-EDO", diatonic_whole = 16, diatonic_half = 8},
}

-- presets_map maps from the total steps to a preset
presets_map = (function()
    local retval = {}
    retval[0] = 1 -- for when no key mode exists or is selected
    for k, v in ipairs(presets) do
        local steps = 5*v.diatonic_whole + 2*v.diatonic_half
        retval[steps] = k
    end
    return retval
end)()

local hide_on_linear = {}
local hide_on_nonlinear = {}
local suppress_popup = false

local function calc_key_mode_desc(key_mode)
    -- Use FCKeySignature because it populates defaults if needed.
    local key = key_mode:CreateKeySignature()
    local diatonic_steps = #key:CalcDiatonicStepsMap()
    local chromatic_steps = key:CalcTotalChromaticSteps()
    if chromatic_steps == 0 then chromatic_steps = 12 end
    local tonal_center = key_mode.BaseTonalCenter
    local retval = "["
    if key_mode:IsLinear() then
        retval = retval .. "Linear "
    elseif key_mode:IsNonLinear() then
        retval = retval .. "Nonlinear "
    end
    retval = retval .. (key_mode.ItemNo & ~0xc000) .. "]"
    if key:IsMajor() then
        return retval .. " Predefined Major"
    elseif key:IsMinor() then
        return retval " Predefined Minor"
    end
    if chromatic_steps ~= 12 then
        retval = retval .. " " .. chromatic_steps .. "-EDO"
    end
    if diatonic_steps ~= 7 then
        retval = retval .. " (" .. diatonic_steps .. " Steps)"
    elseif key_mode:IsLinear() and (chromatic_steps == 12 or tonal_center ~= 0) then
        retval = retval .. " " .. linear_mode_types[(tonal_center % 7) + 1]
    elseif key_mode:IsNonLinear() then
        local notes = " " .. note_names[(tonal_center % 7) + 1] .. ":"
        local acci_amounts = key_mode.AccidentalAmounts
        local acci_order = key_mode.AccidentalOrder
        for x = 1, 7 do
            if acci_amounts[x] == 0 then
                break
            end
            if not acci_order[x] then
                break
            end
            notes = notes .. " " .. note_names[(acci_order[x] % 7) + 1]
            if chromatic_steps == 12 and acci_amounts[x] then
                notes = notes .. tostring(alteration_names[acci_amounts[x]])
            else
                notes = notes .. tostring(acci_amounts[x])
            end
        end
        retval = retval .. notes
    end
    return retval
end

local function on_type_popup(control)
    local get_value = control:GetSelectedItem()
    local dialog = control:GetParent()
    if get_value ~= context.current_type_selection then
        for _, v in ipairs(hide_on_linear) do
            dialog:GetControl(v):SetVisible(get_value == 1)
        end
        for _, v in ipairs(hide_on_nonlinear) do
            dialog:GetControl(v):SetVisible(get_value == 0)
        end
        context.current_type_selection = get_value
    end
end

local function on_presets_popup(control)
    local selected_item = control:GetSelectedItem()
    if selected_item == context.current_preset or selected_item <= 0 then
        return
    end
    local preset = presets[selected_item]
    for x = 1, 7 do
        if x ~= 3 and x ~= 7 then
            global_dialog:GetControl("ds_" .. x):SetInteger(preset.diatonic_whole)
        else
            global_dialog:GetControl("ds_" .. x):SetInteger(preset.diatonic_half)
        end
    end
    if context.current_type_selection == 0 then
        global_dialog:GetControl("chromatic_halfstep_size"):SetInteger(preset.diatonic_whole - preset.diatonic_half)
    end
    context.current_preset = selected_item
end

local function display_def(dialog, def)
    assert(def:IsLinear() or def:IsNonLinear(), "key mode " .. def.ItemNo .. "is invalid")
    local type_popup = dialog:GetControl("keymode_type")
    type_popup:SetSelectedItem(def:IsLinear() and 0 or 1)
    on_type_popup(type_popup)
    -- populate info
    dialog:GetControl("middle_note"):SetInteger(def.MiddleKeyNumber)
    dialog:GetControl("tonal_center"):SetText(note_names[def.BaseTonalCenter + 1])
    context.current_font = def:CreateAccidentalFontInfo() or finale.FCFontInfo()
    dialog:GetControl("show_font"):SetText(context.current_font:CreateDescription())
    context.current_symbol_list = def.SymbolListID
    -- populate key map
    local key_map = def.DiatonicStepsMap
    key_map = key_map and #key_map > 0 and key_map or {0, 2, 4, 5, 7, 9, 11}
    local num_steps = def.TotalChromaticSteps
    context.current_preset = presets_map[num_steps] or 0
    dialog:GetControl("presets"):SetSelectedItem(context.current_preset)
    num_steps = num_steps > 0 and num_steps or 12
    for x = 1, math.min(#key_map, #note_names) do
        local count = x < #key_map and key_map[x + 1] - key_map[x] or num_steps - key_map[x]
        dialog:GetControl("ds_" .. x):SetInteger(count)
    end
    -- populate accidental order and amounts
    local acci_amounts = def.AccidentalAmounts
    dialog:GetControl("chromatic_halfstep_size"):SetInteger(math.abs(acci_amounts[1] or 1))
    local acci_order = def.AccidentalOrder
    local termination = false
    for x = 1, 7 do
        local acci_note = acci_order[x] or 0
        local acci_amount = acci_amounts[x] or 0
        if not termination and acci_amount == 0 then
            termination = true
        end
        local note_text = termination and "" or note_names[acci_note + 1]
        local amount_text = termination and "" or tostring(acci_amount)
        dialog:GetControl("acci_order_" .. x):SetText(note_text)
        dialog:GetControl("acci_amount_" .. x):SetText(amount_text)
    end
    -- accidental octaves by clef
    context.current_acci_octaves = def.ClefAccidentalPlacements
end

local function select_keymode(dialog)
    local popup = dialog:GetControl("keymodes")
    local curr_selection = popup:GetSelectedItem()
    local selection_exists = curr_selection >= 2
    if curr_selection == 0 then
        display_def(dialog, finale.FCCustomKeyModeDef())
    elseif curr_selection == 1 then
        popup:SetSelectedItem(context.current_selection)
        return
    else
        local keymode = context.current_keymodes:GetItemAt(curr_selection - 2)
        assert(keymode, "keymode not found for popup item " .. curr_selection)
        display_def(dialog, keymode)
    end
    dialog:GetControl("keymode_type"):SetEnable(not selection_exists)
    dialog:GetControl("delete"):SetEnable(selection_exists)
    dialog:GetControl("delete_all"):SetEnable(context.current_keymodes.Count > 0)
    context.current_selection = curr_selection
end

local function on_document_change(dialog, select_itemno)
    context.current_doc = finale.FCDocument().ID
    suppress_popup = true
    local popup = dialog:GetControl("keymodes")
        :Clear()
        :AddString("< New >")
        :SetSelectedItem(0)
    context.current_keymodes:LoadAll()
    local x = 0
    local select_item
    for def in each(context.current_keymodes) do
        if x == 0 then
            popup:AddString("-")
        end
        popup:AddString(calc_key_mode_desc(def))
        if select_itemno and def.ItemNo == select_itemno then
            select_item = popup:GetCount() - 1
        end
        x = x + 1
    end
    suppress_popup = false
    if select_item and select_item < popup:GetCount() then
        popup:SetSelectedItem(select_item)
    elseif context.current_keymodes.Count > 0 then
        local sel_region = finale.FCMusicRegion()
        sel_region:SetCurrentSelection()
        if sel_region:IsEmpty() then
            sel_region:SetFullDocument()
        end
        local cell = finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
        local key_index = context.current_keymodes:FindIndexForKeySignature(cell:GetKeySignature())
        if key_index >= 0 then
            popup:SetSelectedItem(key_index + 2)
        end
    end
    select_keymode(dialog)
end

local function on_popup(control)
    if not suppress_popup then
        suppress_popup = true
        local curr_selection = control:GetSelectedItem()
        if curr_selection ~= context.current_selection then
            select_keymode(control:GetParent())
        end
    end
    suppress_popup = false
end

local function on_timer(dialog, timer)
    assert(timer == context.global_timer_id, "timer " .. timer .. " is not for this window")
    local current_doc = finale.FCDocument().ID
    if current_doc ~= context.current_doc then
        on_document_change(dialog)
    end
end

local function on_init_window(dialog)
    dialog.OkButtonCanClose = true
    context.current_selection = -1
    context.current_type_selection = -1
    context.current_preset = -1
    context.current_doc = 0
    on_timer(dialog, context.global_timer_id)
    global_dialog:SetTimer(context.global_timer_id, 100) -- last step
end

local function on_close_window(_dialog)
    global_dialog:StopTimer(context.global_timer_id) -- first step
end

local function on_listen_to_midi(_control)
    local result = finale.FCListenToMidiResult()
    if global_dialog:CreateChildUI():DisplayListenToMidiDialog(result) then
        if result.Status & 0x90 == 0x90 then
            global_dialog:GetControl("middle_note"):SetInteger(result.Data1)
        end
    end
end

local function on_choose_font(control)
    local dlg = control:GetParent()
    local font_dialog = finale.FCFontDialog(dlg:CreateChildUI(), context.current_font)
    font_dialog.UseSizes = false
    font_dialog.UseStyles = false
    if font_dialog:Execute() then
        dlg:GetControl("show_font"):SetText(context.current_font:CreateDescription())
        return true
    end
    return false
end

local function on_edit_symbols(_control)
    local function calc_current_font()
        local def = finale.FCCustomKeyModeDef()
        def.AccidentalFontID = context.current_font.FontID
        return def:CreateAccidentalFontInfo()
    end
    local save_font = calc_current_font()
    local editor_width = 60
    local editor_height = 80
    local curr_y = 0
    local button_height = 20
    local y_increment = 10
    local x_increment = 10
    local dlg = mixin.FCXCustomLuaWindow()
        :SetTitle("Accidental Symbols")
    -- utility functions
    local function get_symbol_fcstr(control, is_symbol)
        local fcstr = finale.FCString()
        control:GetText(fcstr)
        if is_symbol then
            fcstr:EncodeToMacRoman()
        end
        return fcstr
    end
    local function set_symbol_fcstr(control, is_symbol, fcstr)
        if is_symbol then
            fcstr:EncodeFromMacRoman()
        end
        control:SetText(fcstr)
    end
    local function control_name(x, sign)
        local acci_name
        if sign == 0 then
            acci_name = "natural"
        elseif sign > 0 then
            acci_name = "sharp"
        else
            acci_name = "flat"
        end
        return "edit_" .. acci_name .. "_" .. x
    end
    local is_symbol = context.current_font:IsMacSymbolFont()
    local curr_sel = 0
    local lists = finale.FCCustomKeyModeSymbolLists()
    local list_ids = {}
    lists:LoadAll()
    local function apply_symbol_list()
        local list
        if curr_sel >= 2 then
            local retval = finale.FCCustomKeyModeSymbolList()
            if retval:Load(list_ids[curr_sel - 1]) then
                list = retval.List
            end
        end
        if not list then
            list = finale.FCCustomKeyModeSymbolList.GetDefaultList()
        end
        for i = -7, 7 do
            set_symbol_fcstr(dlg:GetControl(control_name(math.abs(i), i < 0 and -1 or 1)), is_symbol,
                finale.FCString(list[i] or ""))
        end
    end
    local function add_symbol_controls(x, sign)
        local ctrl = dlg:CreateEdit(0, curr_y - edit_offset, control_name(x, sign))
            :SetHeight(editor_height)
            :SetWidth(editor_width)
            :SetFont(context.current_font)
        if x > 1 then
            ctrl:AssureNoHorizontalOverlap(dlg:GetControl(control_name(x - 1, sign)), x_increment)
        end
        local btn = dlg:CreateButton(0, curr_y + editor_height + 10 - button_offset, control_name(x, sign) .. "_ins")
            :SetWidth(editor_width)
            :SetText("Symbol...")
            :AddHandleCommand(function(_button)
                local fcstr = get_symbol_fcstr(ctrl, is_symbol)
                local last_point = 0
                for _, c in utf8.codes(fcstr.LuaString) do
                    last_point = c
                end
                local new_point = dlg:CreateChildUI():DisplaySymbolDialog(context.current_font, last_point)
                if new_point ~= 0 then
                    fcstr:AppendCharacter(new_point)
                    set_symbol_fcstr(ctrl, is_symbol, fcstr)
                end
            end)
        if x > 1 then
            btn:AssureNoHorizontalOverlap(dlg:GetControl(control_name(x - 1, sign)), x_increment)
        end
    end
    -- header fields
    local popup = dlg:CreatePopup(0, curr_y, "popup")
        :SetWidth(300)
        :AddStrings("< New >", "-")
        :AddHandleCommand(function(control)
            local new_sel = control:GetSelectedItem()
            if new_sel ~= curr_sel then
                if new_sel == 1 then
                    control:SetSelectedItem(curr_sel)
                    return
                end
                curr_sel = new_sel
                apply_symbol_list()
                dlg:GetControl("delete_symbol_list"):SetEnable(curr_sel >= 2)
            end
        end)
    for list in each(lists) do
        popup:AddString("[" .. list.ItemNo .. "] " .. list:CreateListString().LuaString)
        table.insert(list_ids, list.ItemNo)
        if list.ItemNo == context.current_symbol_list then
            curr_sel = popup:GetCount() - 1
        end
    end
    dlg:CreateButton(0, curr_y - button_offset, "delete_symbol_list")
        :SetText("Delete")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(popup, 10)
        :SetEnable(curr_sel >= 2)
        :AddHandleCommand(function(_button)
            if curr_sel >= 2 then
                local del_item = list_ids[curr_sel - 1]
                popup:DeleteItem(curr_sel)
                table.remove(list_ids, curr_sel - 1)
                if (curr_sel >= popup:GetCount()) then
                    curr_sel = 0
                    popup:SetSelectedItem(0)
                end
                apply_symbol_list()
                finenv.StartNewUndoBlock("Delete Accidental Symbol List", false)
                local list = finale.FCCustomKeyModeSymbolList()
                if list:Load(del_item) then
                    list:DeleteData()
                end
                for def in each(context.current_keymodes) do
                    if def.SymbolListID == del_item then
                        def.SymbolListID = 0
                        def.AccidentalFontID = 0
                        def:Save()
                    end
                end
                finenv.EndUndoBlock(true)
                if context.current_symbol_list == del_item then
                    context.current_symbol_list = 0
                end
                local itemno = 0
                if context.current_selection >= 2 then
                    itemno = context.current_keymodes:GetItemAt(context.current_selection - 2).ItemNo
                end
                on_document_change(global_dialog, itemno)
                finenv.UI():RedrawDocument()
                save_font = calc_current_font()
            end
        end)
    curr_y = curr_y + button_height + y_increment
    -- symbols info
    dlg:CreateButton(0, curr_y - button_offset, "symbol_font")
        :SetText("Accidental Font...")
        :DoAutoResizeWidth()
        :AddHandleCommand(function(control)
            local old_is_symbol = is_symbol
            if on_choose_font(control) then
                is_symbol = context.current_font:IsMacSymbolFont()
                for i = -7, 7 do
                    local ctrl = dlg:GetControl(control_name(math.abs(i), i < 0 and -1 or 1))
                    local ctrl_value = get_symbol_fcstr(ctrl, old_is_symbol)
                    dlg:GetControl(control_name(math.abs(i), i < 0 and -1 or 1)):SetFont(context.current_font)
                    set_symbol_fcstr(ctrl, is_symbol, ctrl_value)
                end
            end
        end)
    dlg:CreateStatic(0, curr_y, "show_font")
        :DoAutoResizeWidth()
        :SetText(context.current_font:CreateDescription())
        :AssureNoHorizontalOverlap(dlg:GetControl("symbol_font"), y_increment)
    curr_y = curr_y + button_height + y_increment
    -- editor boxes
    popup:SetSelectedItem(curr_sel)
    for x = 1, 7 do
        add_symbol_controls(x, -1)
    end
    curr_y = curr_y + editor_height + 4 * y_increment
    add_symbol_controls(0, 1)
    curr_y = curr_y + editor_height + 4 * y_increment
    for x = 1, 7 do
        add_symbol_controls(x, 1)
    end
    -- ok/cancel buttons
    dlg:CreateOkButton()
    dlg:CreateCancelButton()
    -- registrations
    dlg:RegisterInitWindow(function()
        apply_symbol_list()
    end)
    if dlg:ExecuteModal(global_dialog) == finale.EXECMODAL_OK then
        global_dialog:GetControl("show_font"):SetText(context.current_font:CreateDescription())
        local new_list = {}
        for i = -7, 7 do
            local ctrl = dlg:GetControl(control_name(math.abs(i), i < 0 and -1 or 1))
            local ctrl_value = get_symbol_fcstr(ctrl, is_symbol)
            new_list[i] = ctrl_value.LuaString
        end
        local list = curr_sel >= 2 and lists:GetItemAt(curr_sel - 2) or finale.FCCustomKeyModeSymbolList()
        list.List = new_list
        if curr_sel == 0 and list:CalcIsDefaultList() then
            context.current_symbol_list = 0
        else
            finenv.StartNewUndoBlock("Edit Accidental Symbol List", false)
            list:Save()
            finenv.EndUndoBlock(true)
            context.current_symbol_list = list.ItemNo
        end
    else
        context.current_font = save_font
    end
end

local function get_acci_order_and_amounts(dialog)
    local acci_order = {}
    local acci_amounts = {}
    local type_selected = dialog:GetControl("keymode_type"):GetSelectedItem()
    if type_selected == 0 then
        local acci_amount = dialog:GetControl("chromatic_halfstep_size"):GetInteger()
        if acci_amount <= 0 then
            return false, "Accidental Step Amount must be a positive value."
        end
        if acci_amount ~= 1 then
            acci_order = finale.FCCustomKeyModeDef.GetDefaultAccidentalOrder()
            for x = -7, -1 do
                acci_amounts[x] = -acci_amount
            end
            for x = 1, 7 do
                acci_amounts[x] = acci_amount
            end
        end
    else
        for x = 1, 7 do
            local acci_amount = dialog:GetControl("acci_amount_" .. x):GetInteger()
            if acci_amount == 0 then
                break
            end
            local acci_value = note_number_by_names[dialog:GetControl("acci_order_" .. x):GetText()]
            if not acci_value then
                return false, "Accidental note name is not populated in position " .. x .. "."
            end
            table.insert(acci_order, acci_value - 1)
            table.insert(acci_amounts, acci_amount)
        end
    end
    if finale.FCCustomKeyModeDef.CalcIsDefaultAccidentalAmounts(acci_amounts) and finale.FCCustomKeyModeDef.CalcIsDefaultAccidentalOrder(acci_order) then
        acci_order = {}
        acci_amounts = {}
    end
    return acci_order, acci_amounts
end

local function on_acci_octaves(_control)
    local curr_y = 0
    local row_height = 22 --utils.win_mac(22, 20)
    local first_edit_pos = 75
    local edit_pos_diff = 35
    local curr_values = context.current_acci_octaves
    if utils.table_is_empty(curr_values) then
        curr_values = finale.FCCustomKeyModeDef.GetDefaultClefAccidentalPlacements()
    end
    local acci_order, acci_amounts = get_acci_order_and_amounts(global_dialog)
    if not acci_order or utils.table_is_empty(acci_order) then
        acci_order = finale.FCCustomKeyModeDef.GetDefaultAccidentalOrder()
    end
    if not acci_amounts or utils.table_is_empty(acci_amounts) then
        acci_amounts = finale.FCCustomKeyModeDef.GetDefaultAccidentalAmounts()
    end
    local dlg = mixin.FCXCustomLuaWindow()
        :SetTitle("Accidental Octaves By Clef")
    -- instructions
    dlg:CreateStatic(0, curr_y)
        :SetText("Each value specifies an octave for the accidental, where 0 is the middle-C (C4) octave.")
        :DoAutoResizeWidth(0)
    curr_y = curr_y + row_height + 5
    -- note name headers
    dlg:CreateStatic(0, curr_y)
        :SetText("Clef")
        :DoAutoResizeWidth(0)
    local curr_x = first_edit_pos
    for i = -7, 7 do
        if acci_amounts[i] and acci_amounts[i] ~= 0 then
            local note_name = note_names[(acci_order[i] or 0) + 1] .. (acci_amounts[i] < 0 and "b" or "#")
            dlg:CreateStatic(curr_x + 3, curr_y)
                :SetText(note_name)
                :DoAutoResizeWidth(0)
            curr_x = curr_x + edit_pos_diff
        end
    end
    curr_y = curr_y + row_height
    dlg:CreateHorizontalLine(0, curr_y, 10)
        :StretchToAlignWithRight()
    curr_y = curr_y + row_height/2
    -- clef grid
    local clefs = finale.FCClefDefs()
    clefs:LoadAll()
    for clef in each(clefs) do
        if curr_values[clef.ClefIndex + 1] then
            dlg:CreateStatic(0, curr_y, "show_clef_" .. clef.ClefIndex)
                :SetWidth(first_edit_pos - 5)
                :SetText(clef_names[clef.ClefIndex + 1])
            local clef_table = curr_values[clef.ClefIndex + 1]
            curr_x = first_edit_pos
            for i = -7, 7 do
                if acci_amounts[i] and acci_amounts[i] ~= 0 then
                    dlg:CreateEdit(curr_x, curr_y - edit_offset, "acci_pos_" .. clef.ClefIndex .. "_" .. i)
                        :SetText(clef_table[i] and tostring(clef_table[i]) or "")
                        :SetWidth(25)
                    curr_x = curr_x + edit_pos_diff
                end
            end
            curr_y = curr_y + row_height
        end
    end
    dlg:CreateOkButton()
    dlg:CreateCancelButton()
    if dlg:ExecuteModal(global_dialog) == finale.EXECMODAL_OK then
        local new_values = {}
        for clef in each(clefs) do
            for i = -7, 7 do
                local ctrl = dlg:GetControl("acci_pos_" .. clef.ClefIndex .. "_" .. i)
                if ctrl then
                    if not new_values[clef.ClefIndex + 1] then
                        new_values[clef.ClefIndex + 1] = {}
                    end
                    new_values[clef.ClefIndex + 1][i] = ctrl:GetInteger()
                end
            end
        end
        if finale.FCCustomKeyModeDef.CalcIsDefaultClefAccidentalPlacements(new_values) then
            context.current_acci_octaves = {}
        else
            context.current_acci_octaves = new_values
        end
    end
end

local function on_note_name_edit(control)
    local curr_text = control:GetText()
    local last_char = curr_text:sub(-1)
    local result = ""
    if last_char >= 'a' and last_char <= 'g' then
        result = last_char:upper()
    elseif last_char >= 'A' and last_char <= 'G' then
        result = last_char
    elseif last_char and #last_char > 0 then
        -- Check which one is closer to 'A' or 'G'
        local dist_to_A = math.abs(last_char:byte() - ('A'):byte())
        local dist_to_G = math.abs(last_char:byte() - ('G'):byte())
        if dist_to_A < dist_to_G then
            result = 'A'
        else
            result = 'G'
        end
    end
    control:SetText(result)
end

local function copy_dialog_to_def(dialog, def, for_create)
    local type_selected = dialog:GetControl("keymode_type"):GetSelectedItem()
    if not for_create then
        assert(def:IsLinear() and type_selected == 0 or def:IsNonLinear() and type_selected == 1,
            "type pulldown does not match keymode item number")
    end
    -- populate info
    def.MiddleKeyNumber = dialog:GetControl("middle_note"):GetInteger()
    def.BaseTonalCenter = note_number_by_names[dialog:GetControl("tonal_center"):GetText()] - 1
    def.SymbolListID = context.current_symbol_list
    def.AccidentalFontID = def.SymbolListID > 0 and context.current_font.FontID or 0
    -- populate key map
    local accumulator = 0
    local steps_map = {}
    for x = 1, 7 do
        table.insert(steps_map, accumulator)
        local next_value = dialog:GetControl("ds_" .. x):GetInteger()
        if next_value <= 0 then
            return false, "All 7 diatonic steps must contain a positive value."
        end
        accumulator = accumulator + next_value
    end
    def.TotalChromaticSteps = accumulator
    def.DiatonicStepsMap = steps_map
    -- populate accidental order and amounts
    def.AccidentalOrder, def.AccidentalAmounts = get_acci_order_and_amounts(dialog)
    -- populate clef accidental octaves
    def.ClefAccidentalPlacements = context.current_acci_octaves
    def.HasClefAccidentalPlacements = next(context.current_acci_octaves) ~= nil
    -- success exit
    return true
end

local function on_save(_control)
    local def, success, errmsg
    local for_create = context.current_selection < 2
    if for_create then
        def = finale.FCCustomKeyModeDef()
        success, errmsg = copy_dialog_to_def(global_dialog, def, for_create)
    else
        def = context.current_keymodes:GetItemAt(context.current_selection - 2)
        assert(def, "selected FCCustomKeyModeDef not found for save")
        success, errmsg = copy_dialog_to_def(global_dialog, def, for_create)
    end
    if not success then
        global_dialog:CreateChildUI():AlertError(errmsg, "Unable to Save")
        return
    end
    if for_create then
        local new_linear = global_dialog:GetControl("keymode_type"):GetSelectedItem() == 0
        finenv.StartNewUndoBlock("Create Nonstandard Key Signature", false)
        if new_linear then
            assert(def:SaveNewLinear(), "save new linear failed")
        else
            assert(def:SaveNewNonLinear(), "save new non-linear failed")
        end
    else
        finenv.StartNewUndoBlock("Modify Nonstandard Key Signature", false)
        assert(def:Save(), "save failed")
    end
    finenv.EndUndoBlock(true)
    finenv.UI():RedrawDocument()
    on_document_change(global_dialog, def.ItemNo)
end

local function on_delete_all(_control)
    assert(context.current_keymodes.Count > 0, "no key modes to delete")
    if global_dialog:CreateChildUI():AlertYesNo("Delete all Nonstandard Key Definitions in this document?", "") == finale.YESRETURN then
        finenv.StartNewUndoBlock("Delete All Nonstandard Key Signatures", false)
        for def in eachbackwards(context.current_keymodes) do
            def:DeleteData()
        end
        finenv.EndUndoBlock(true)
        finenv.UI():RedrawDocument()
        on_document_change(global_dialog)
    end
end

local function on_delete(_control)
    assert(context.current_selection >= 2, "no key mode selected to delete")
    local popup = global_dialog:GetControl("keymodes")
    local fstr = finale.FCString()
    popup:GetItemText(context.current_selection, fstr)
    if global_dialog:CreateChildUI():AlertYesNo("Delete ".. fstr.LuaString .. "?", "") == finale.YESRETURN then
        finenv.StartNewUndoBlock("Delete " .. fstr.LuaString, false)
        local curr_def_index = context.current_selection - 2
        local def = context.current_keymodes:GetItemAt(curr_def_index)
        def:DeleteData()
        finenv.EndUndoBlock(true)
        finenv.UI():RedrawDocument()
        local next_itemno
        if curr_def_index + 1 < context.current_keymodes.Count then
            next_itemno = context.current_keymodes:GetItemAt(curr_def_index + 1).ItemNo
        end
        on_document_change(global_dialog, next_itemno)
    end
end

local function create_dialog_box()
    local padding = 5
    local y_increment = 30
    local curr_y = 0
    hide_on_linear = {}
    hide_on_nonlinear = {}
    local dlg = mixin.FCXCustomLuaWindow()
        :SetTitle(plugindef():gsub("%.%.%.", ""))
-- keymode list
    dlg:CreateButton(0, curr_y - button_offset, "help")
        :SetText("?")
        :SetWidth(20)
        :AddHandleCommand(function(_control)
            utils.show_notes_dialog(dlg, nil, 600, 400)        
        end)
    dlg:CreatePopup(0, curr_y, "keymodes")
        :SetWidth(300)
        :AssureNoHorizontalOverlap(dlg:GetControl("help"), padding)
        :AddHandleCommand(on_popup)
    dlg:CreateButton(0, curr_y - button_offset, "delete")
        :SetText("Delete")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("keymodes"), 2 * padding)
        :AddHandleCommand(on_delete)
    dlg:CreateButton(0, curr_y - button_offset, "delete_all")
        :SetText("Delete All")
        :DoAutoResizeWidth()
        :HorizontallyAlignRightWithFurthest()
        :AddHandleCommand(on_delete_all)
    curr_y = curr_y + y_increment
-- basic information
    dlg:CreateStatic(0, curr_y, "middle_note_label")
        :SetText("MIDI Note for Middle C")
        :DoAutoResizeWidth(0)
    dlg:CreateEdit(0, curr_y - edit_offset, "middle_note")
        :SetWidth(30)
        :AssureNoHorizontalOverlap(dlg:GetControl("middle_note_label"), padding)
    dlg:CreateButton(0, curr_y - button_offset, "listen_to_midi")
        :SetText("Listen...")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("middle_note"), padding)
        :AddHandleCommand(on_listen_to_midi)
    dlg:CreateStatic(0, curr_y, "tonal_center_label")
        :SetText("Base Tonal Center")
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dlg:GetControl("listen_to_midi"), 2 * padding)
    dlg:CreateEdit(0, curr_y - edit_offset, "tonal_center")
        :SetWidth(25)
        :AssureNoHorizontalOverlap(dlg:GetControl("tonal_center_label"), padding)
        :AddHandleCommand(on_note_name_edit)
    dlg:CreatePopup(0, curr_y, "keymode_type")
        :AddStrings("Linear", "Nonlinear")
        :DoAutoResizeWidth()
        :HorizontallyAlignRightWithFurthest()
        :SetSelectedItem(0)
        :AddHandleCommand(on_type_popup)
    curr_y = curr_y + y_increment
    -- symbols info
    dlg:CreateButton(0, curr_y - button_offset, "symbol_font")
        :SetText("Accidental Font...")
        :DoAutoResizeWidth()
        :AddHandleCommand(on_choose_font)
    dlg:CreateStatic(0, curr_y, "show_font")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("symbol_font"), padding)
    dlg:CreateButton(0, curr_y - button_offset, "symbols")
        :SetText("Accidental Symbols...")
        :DoAutoResizeWidth()
        :HorizontallyAlignRightWithFurthest()
        :AddHandleCommand(on_edit_symbols)
    curr_y = curr_y + y_increment
-- divider
    dlg:CreateHorizontalLine(0, curr_y, 10)
        :StretchToAlignWithRight()
    curr_y = curr_y + y_increment / 2
-- diatonic steps
    dlg:CreateStatic(0, curr_y, "diatonic_step_map")
        :SetText("Diatonic Step Map")
        :DoAutoResizeWidth(0)
    for k, v in ipairs(note_names) do
        local previous_control_name = k > 1 and "ds_" .. k - 1 or "diatonic_step_map"
        local static = dlg:CreateStatic(0, curr_y)
            :SetText(v)
            :DoAutoResizeWidth(0)
            :AssureNoHorizontalOverlap(dlg:GetControl(previous_control_name), padding)
        dlg:CreateEdit(0, curr_y - edit_offset, "ds_" .. k)
            :SetWidth(25)
            :AssureNoHorizontalOverlap(static, padding)
    end
    dlg:CreateStatic(0, curr_y, "final_map_letter")
        :SetText(note_names[1])
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dlg:GetControl("ds_" .. #note_names), padding)
    local presets_popup = dlg:CreatePopup(0, curr_y, "presets")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("final_map_letter"), 2*padding)
        :AddString("< Other >")
        :AddHandleCommand(on_presets_popup)
    for _, t in ipairs(presets) do
        presets_popup:AddString(t.name)
    end
    presets_popup:SetSelectedItem(0)
    curr_y = curr_y + y_increment
-- divider
    dlg:CreateHorizontalLine(0, curr_y, 10)
        :StretchToAlignWithRight()
    curr_y = curr_y + y_increment / 2
-- accidental order/amounts
    -- controls for linear mode types
    dlg:CreateStatic(0, curr_y, "chromatic_halfstep_size_label")
        :SetText("Accidental Step Amount (Chromatic Halfstep Size)")
        :DoAutoResizeWidth(0)
    dlg:CreateEdit(0, curr_y - edit_offset, "chromatic_halfstep_size")
        :SetWidth(30)
        :AssureNoHorizontalOverlap(dlg:GetControl("chromatic_halfstep_size_label"), padding)
    table.insert(hide_on_nonlinear, "chromatic_halfstep_size_label")
    table.insert(hide_on_nonlinear, "chromatic_halfstep_size")
    -- controls for non-linear mode types
    dlg:CreateStatic(0, curr_y, "accidental_order_label")
        :SetText("Accidental Order")
        :DoAutoResizeWidth(0)
    table.insert(hide_on_linear, "accidental_order_label")
    for x = 1, 7 do
        local acci_order_id = "acci_order_" .. x
        local acci_amount_id = "acci_amount_" .. x
        local prev_ctrl = x == 1 and dlg:GetControl("accidental_order_label") or dlg:GetControl("acci_divider_" .. x - 1)
        dlg:CreateEdit(0, curr_y - edit_offset, acci_order_id)
            :SetWidth(25)
            :AssureNoHorizontalOverlap(prev_ctrl, padding)
            :AddHandleCommand(on_note_name_edit)
        dlg:CreateEdit(0, curr_y - edit_offset, acci_amount_id)
            :SetWidth(25)
            :AssureNoHorizontalOverlap(dlg:GetControl(acci_order_id), padding)
        table.insert(hide_on_linear, acci_order_id)
        table.insert(hide_on_linear, acci_amount_id)
        if x < 7 then
            local acci_divider_id = "acci_divider_" .. x
            dlg:CreateVerticalLine(0, curr_y - edit_offset, 20, acci_divider_id)
                :AssureNoHorizontalOverlap(dlg:GetControl(acci_amount_id), padding)
            table.insert(hide_on_linear, acci_divider_id)
        end
    end
    curr_y = curr_y + y_increment
-- clef octaves
    dlg:CreateButton(0, curr_y - button_offset, "acci_octaves")
        :SetText("Accidental Octaves...")
        :DoAutoResizeWidth()
        :AddHandleCommand(on_acci_octaves)
    dlg:CreateButton(0, curr_y - button_offset, "clear_acci_octave")
        :SetText("Revert...")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("acci_octaves"), padding)
        :AddHandleCommand(function(_control)
            if dlg:CreateChildUI():AlertYesNo("Revert all clef accidental octave settings to their default values?", "Revert") == finale.YESRETURN then
                context.current_acci_octaves = {}
            end
        end)
-- close buttons
    dlg:CreateOkButton()
    dlg:CreateCancelButton()
 -- Registrations
    dlg:RegisterHandleOkButtonPressed(on_save)
    dlg:RegisterInitWindow(on_init_window)
    dlg:RegisterCloseWindow(on_close_window)
    dlg:RegisterHandleTimer(on_timer)
    return dlg
end

local function key_modes_manage()
    global_dialog = global_dialog or create_dialog_box()
    global_dialog:RunModeless()
end

key_modes_manage()

function plugindef()
    finaleplugin.MinJWLuaVersion = 0.72
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "March 12, 2024"
    finaleplugin.CategoryTags = "Key Signatures"
    finaleplugin.Notes = [[
        This script provides a much simpler interface for managing the most common types
        of custom key modes (called "Nonstandard Key Signatures" in Finale.) Limitations include
        - Key modes must have 7 diatonic steps per octave
        - Linear key signatures must use the standard accidental order and size (for their EDO value)
        - Linear tonal centers must follow the standard circle of fifths for their respective key signatures
    ]]
    return "Nonstandard Key Signatures...", "Nonstandard Key Signatures",
           "Manages Nonstandard Key Signatures. Allows view, modify, create, and delete."
end

-- luacheck: ignore 11./global_dialog

local utils = require("library.utils")
local mixin = require("library.mixin")

context = context or
{
    global_timer_id = 1,
    current_doc = 0,
    current_keymodes = finale.FCCustomKeyModeDefs(),
    current_selection = -1,
    current_type_selection = -1,
    current_fontname = finale.FCString(),
    current_symbol_list = 0
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
            notes = notes .. " " .. note_names[(acci_order[x] % 7) + 1]
            if not acci_order[x] then
                break
            end
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

local function calc_current_symbol_font()
    local fpref = finale.FCFontPrefs()
    assert(fpref:Load(finale.FONTPREF_KEYSIG), "failed to load default font for key signatures")
    local font = fpref:CreateFontInfo()
    if context.current_fontname.Length > 0 then
        font:SetNameString(context.current_fontname)
    end
    return font
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

local function display_def(dialog, def)
    assert(def:IsLinear() or def:IsNonLinear(), "key mode " .. def.ItemNo .. "is invalid")
    local type_popup = dialog:GetControl("keymode_type")
    type_popup:SetSelectedItem(def:IsLinear() and 0 or 1)
    on_type_popup(type_popup)
    -- populate info
    dialog:GetControl("middle_note"):SetInteger(def.MiddleKeyNumber)
    dialog:GetControl("tonal_center"):SetText(note_names[def.BaseTonalCenter + 1])
    local fpref = finale.FCFontPrefs()
    assert(fpref:Load(finale.FONTPREF_KEYSIG), "failed to load default font for key signatures")
    def:GetAccidentalFontName(context.current_fontname)
    local font = calc_current_symbol_font()
    dialog:GetControl("show_font"):SetText(font:CreateDescription())
    context.current_symbol_list = def.SymbolListID
    -- populate key map
    local key_map = def.DiatonicStepsMap
    key_map = key_map and #key_map > 0 and key_map or {0, 2, 4, 5, 7, 9, 11}
    local num_steps = def.TotalChromaticSteps
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
            print("got selected item:", x, select_item)
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
    context.current_selection = -1
    context.current_type_selection = -1
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

local function on_choose_font(_control)
    local font = calc_current_symbol_font()
    local font_dialog = finale.FCFontDialog(global_dialog:CreateChildUI(), font)
    font_dialog.UseSizes = false
    font_dialog.UseStyles = false
    if font_dialog:Execute() then
        font:GetNameString(context.current_fontname)
        global_dialog:GetControl("show_font"):SetText(font:CreateDescription())
    end
end

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

local function on_edit_symbols(_control)
    local symbol_list = (function()
        if context.current_symbol_list > 0 then
            local retval = finale.FCCustomKeyModeSymbolList()
            if retval:Load(context.current_symbol_list) then
                return retval.List
            end
        end
        return finale.FCCustomKeyModeSymbolList.GetDefaultList()
    end)()
    local editor_width = 60
    local editor_height = 80
    local dlg = mixin.FCXCustomLuaWindow()
        :SetTitle("Accidental Symbols")
    local curr_y = 0
    local y_increment = 10
    local x_increment = 10
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
    local font = calc_current_symbol_font()
    local is_symbol = font:IsMacSymbolFont()
    local function add_symbol_controls(x, sign)
        local ctrl = dlg:CreateEdit(0, curr_y, control_name(x, sign))
            :SetHeight(editor_height)
            :SetWidth(editor_width)
            :SetFont(font)
        set_symbol_fcstr(ctrl, is_symbol, finale.FCString(symbol_list[x * sign] or ""))
        if x > 1 then
            ctrl:AssureNoHorizontalOverlap(dlg:GetControl(control_name(x - 1, sign)), x_increment)
        end
        local btn = dlg:CreateButton(0, curr_y + editor_height + 10, control_name(x, sign) .. "_ins")
            :SetWidth(editor_width)
            :SetText("Symbol...")
            :AddHandleCommand(function(_button)
                local fcstr = get_symbol_fcstr(ctrl, is_symbol)
                local last_point = 0
                for _, c in utf8.codes(fcstr.LuaString) do
                    last_point = c
                end
                local new_point = dlg:CreateChildUI():DisplaySymbolDialog(font, last_point)
                if new_point ~= 0 then
                    fcstr:AppendCharacter(new_point)
                    set_symbol_fcstr(ctrl, is_symbol, fcstr)
                end
            end)
        if x > 1 then
            btn:AssureNoHorizontalOverlap(dlg:GetControl(control_name(x - 1, sign)), x_increment)
        end
    end
    for x = 1, 7 do
        add_symbol_controls(x, -1)
    end
    curr_y = curr_y + editor_height + 4*y_increment
    add_symbol_controls(0, 1)
    curr_y = curr_y + editor_height + 4*y_increment
    for x = 1, 7 do
        add_symbol_controls(x, 1)
    end
    dlg:CreateOkButton()
    dlg:CreateCancelButton()
    if dlg:ExecuteModal(global_dialog) then
        --ToDo: something
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
    def:SetAccidentalFontName(context.current_fontname)
    def.SymbolListID = context.current_symbol_list
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
    local acci_order = {}
    local acci_amounts = {}
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
    def.AccidentalOrder = acci_order
    def.AccidentalAmounts = acci_amounts
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
    local win_edit_offset = 5
    local mac_edit_offset = 3
    local edit_offset = utils.win_mac(win_edit_offset, mac_edit_offset)
    hide_on_linear = {}
    hide_on_nonlinear = {}
    local dlg = mixin.FCXCustomLuaWindow()
        :SetTitle(plugindef():gsub("%.%.%.", ""))
-- keymode list
    dlg:CreatePopup(0, curr_y, "keymodes")
        :SetWidth(300)
        :AddHandleCommand(on_popup)
    dlg:CreateButton(0, curr_y, "delete")
        :SetText("Delete")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("keymodes"), 2 * padding)
        :AddHandleCommand(on_delete)
    dlg:CreateButton(0, curr_y, "delete_all")
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
    dlg:CreateButton(0, curr_y, "listen_to_midi")
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
        dlg:CreateButton(0, curr_y, "symbol_font")
        :SetText("Accidental Font...")
        :DoAutoResizeWidth()
        :AddHandleCommand(on_choose_font)
    dlg:CreateStatic(0, curr_y, "show_font")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("symbol_font"), padding)
    dlg:CreateButton(0, curr_y, "symbols")
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
    dlg:CreateStatic(0, curr_y)
        :SetText(note_names[1])
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dlg:GetControl("ds_" .. #note_names), padding)
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
-- close button
    dlg:CreateButton(0, curr_y, "save_button")
        :SetText("Save")
        :DoAutoResizeWidth()
        :AddHandleCommand(on_save)
    dlg:CreateCloseButton(0, curr_y)
        :HorizontallyAlignRightWithFurthest()
-- Registrations
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

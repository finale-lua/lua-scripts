function plugindef()
    finaleplugin.MinJWLuaVersion = 0.72
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "March 12, 2024"
    finaleplugin.CategoryTags = "Key Signatures"
    finaleplugin.Notes = [[
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
    current_selection = 0
}

local key_mode_types =
{
    "Predefined",
    "Linear",
    "Nonlinear"
}

local linear_mode_types =
{
    "Ionian",
    "Dorian",
    "Phrygian",
    "Lydian",
    "Mixolydian",
    "Aeolian",
    "Locrian"
}

local note_names =
{
    "C",
    "D",
    "E",
    "F",
    "G",
    "A",
    "B"
}

local alteration_names =
{
    [-2] = "bb",
    [-1] = "b",
    [0] = "",
    [1] = "#",
    [2] = "x"
}

local function calc_key_mode_desc(key_mode)
    -- Use FCKeySignature because it populates defaults if needed.
    local key = key_mode:CreateKeySignature()
    local diatonic_steps = #key:CalcDiatonicStepsMap()
    local chromatic_steps = key:CalcTotalChromaticSteps()
    if chromatic_steps == 0 then chromatic_steps = 12 end
    local tonal_center = key_mode.BaseTonalCenter
    local retval = "[" .. (key_mode.ItemNo & ~0xc000) .. "]"
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
            if not acci_amounts[x] or acci_amounts[x] == 0 then
                break
            end
            if not acci_order[x] then
                break
            end
            notes = notes .. " " .. note_names[(acci_order[x] % 7) + 1] .. tostring(alteration_names[acci_amounts[x]])
        end
        retval = retval .. notes
    end
    return retval
end

local function display_def(dialog, def)
    assert(def:IsLinear() or def:IsNonLinear(), "key mode " .. def.ItemNo .. "is invalid")
    local type_popup = dialog:GetControl("keymode_type")
    type_popup:SetSelectedItem(def:IsLinear() and 0 or 1)
    -- populate info
    dialog:GetControl("middle_note"):SetInteger(def.MiddleKeyNumber)
    dialog:GetControl("tonal_center"):SetText(note_names[def.BaseTonalCenter + 1])
    -- populate key map
    local key_map = def.DiatonicStepsMap
    key_map = key_map and #key_map > 0 and key_map or {0, 2, 4, 5, 7, 9, 11}
    local num_steps = def.TotalChromaticSteps
    num_steps = num_steps > 0 and num_steps or 12
    for x = 1, math.min(#key_map, #note_names) do
        local count = x < #key_map and key_map[x+1] - key_map[x] or num_steps - key_map[x]
        dialog:GetControl("ds_" .. x):SetInteger(count)
    end
end

local function select_keymode(dialog)
    local popup = dialog:GetControl("keymodes")
    local type_popup = dialog:GetControl("keymode_type")
    local curr_selection = popup:GetSelectedItem()
    if curr_selection == 0 then
        display_def(dialog, finale.FCCustomKeyModeDef())
        type_popup:SetEnable(true)
    elseif curr_selection == 1 then
        popup:SetSelection(context.current_selection)
        return
    else
        local keymode = context.current_keymodes:GetItemAt(curr_selection - 2)
        assert(keymode, "keymode not found for popup item " .. curr_selection)
        display_def(dialog, keymode)
        type_popup:SetEnable(false)
    end
    context.current_selection = curr_selection
end

local function on_document_change(dialog)
    context.current_doc = finale.FCDocument().ID
    local popup = dialog:GetControl("keymodes")
        :Clear()
        :AddString("< New >")
    context.current_keymodes:LoadAll()
    local x = 0
    for def in each(context.current_keymodes) do
        if x == 0 then
            popup:AddString("-")
        end
        popup:AddString(calc_key_mode_desc(def))
        x = x + 1
    end
    if context.current_keymodes.Count > 0 then
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
    local curr_selection = control:GetSelectedItem()
    if curr_selection ~= context.current_selection then
        select_keymode(control:GetParent())
    end
end

local function on_timer(dialog, timer)
    assert(timer == context.global_timer_id, "timer " .. timer .. " is not for this window")
    local current_doc = finale.FCDocument().ID
    if current_doc ~= context.current_doc then
        on_document_change(dialog)
    end
end

local function on_init_window(dialog)
    on_timer(dialog, context.global_timer_id)
    global_dialog:SetTimer(context.global_timer_id, 100) -- last step
end

local function on_close_window(_dialog)
    global_dialog:StopTimer(context.global_timer_id) -- first step
end

local function listen_to_midi(_control)
    local result = finale.FCListenToMidiResult()
    if global_dialog:CreateChildUI():DisplayListenToMidiDialog(result) then
        if result.Status & 0x90 == 0x90 then
            global_dialog:GetControl("middle_note"):SetInteger(result.Data1)
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

local function create_dialog_box()
    local padding = 5
    local y_increment = 30
    local curr_y = 0
    local win_edit_offset = 5
    local mac_edit_offset = 3
    local dlg = mixin.FCXCustomLuaWindow()
        :SetTitle(plugindef():gsub("%.%.%.", ""))
    -- keymode list
    dlg:CreatePopup(0, curr_y, "keymodes")
        :SetWidth(300)
        :AddHandleCommand(on_popup)
    dlg:CreatePopup(0, curr_y, "keymode_type")
        :AddStrings("Linear", "Nonlinear")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("keymodes"), padding)
    curr_y = curr_y + y_increment
    -- basic information
    dlg:CreateStatic(0, curr_y, "middle_note_label")
        :SetText("MIDI Note for Middle C")
        :DoAutoResizeWidth(0)
    dlg:CreateEdit(0, curr_y - utils.win_mac(win_edit_offset, mac_edit_offset), "middle_note")
        :SetWidth(30)
        :AssureNoHorizontalOverlap(dlg:GetControl("middle_note_label"), padding)
    dlg:CreateButton(0, curr_y, "listen_to_midi")
        :SetText("Listen...")
        :DoAutoResizeWidth()
        :AssureNoHorizontalOverlap(dlg:GetControl("middle_note"), padding)
        :AddHandleCommand(listen_to_midi)
    dlg:CreateStatic(0, curr_y, "tonal_center_label")
        :SetText("Base Tonal Center")
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dlg:GetControl("listen_to_midi"), 2 * padding)
    dlg:CreateEdit(0, curr_y - utils.win_mac(win_edit_offset, mac_edit_offset), "tonal_center")
        :SetWidth(25)
        :AssureNoHorizontalOverlap(dlg:GetControl("tonal_center_label"), padding)
        :AddHandleCommand(on_note_name_edit)
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
        dlg:CreateEdit(0, curr_y - utils.win_mac(win_edit_offset, mac_edit_offset), "ds_" .. k)
            :SetWidth(25)
            :AssureNoHorizontalOverlap(static, padding)
    end
    dlg:CreateStatic(0, curr_y)
        :SetText(note_names[1])
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dlg:GetControl("ds_" .. #note_names), padding)
    curr_y = curr_y + y_increment
    -- close button
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

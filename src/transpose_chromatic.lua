function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true     -- not recognized by JW Lua or RGP Lua v0.55
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "January 20, 2022"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.Notes = [[
        This script transposes the selected region by a chromatic interval. It works correctly even with
        microtone scales defined by custom key signatures.

        Normally the script opens a modeless window. However, if you invoke the plugin with a shift, option, or
        alt key pressed, it skips opening a window and uses the last settings you entered into the window.
        (This works with RGP Lua version 0.60 and higher.)

        If you are using custom key signatures with JW Lua or an early version of RGP Lua, you must create
        a custom_key_sig.config.txt file in a folder called `script_settings` within the same folder as the script.
        It should contains the following two lines that define the custom key signature you are using. Unfortunately,
        the JW Lua and early versions of RGP Lua do not allow scripts to read this information from the Finale document.
        
        (This example is for 31-EDO.)
        
        ```
        number_of_steps = 31
        diatonic_steps = {0, 5, 10, 13, 18, 23, 28}
        ```
        
        Later versions of RGP Lua (0.58 or higher) ignore this configuration file (if it exists) and read the correct
        information from the Finale document.
    ]]
    return "Transpose Chromatic...", "Transpose Chromatic",
           "Chromatic transposition of selected region (supports microtone systems)."
end

if not finenv.RetainLuaState then
    -- do initial setup once per Lua state
    interval_names = {
        "Perfect Unison",
        "Augmented Unison",
        "Diminished Second",
        "Minor Second",
        "Major Second",
        "Augmented Second",
        "Diminished Third",
        "Minor Third",
        "Major Third",
        "Augmented Third",
        "Diminished Fourth",
        "Perfect Fourth",
        "Augmented Fourth",
        "Diminished Fifth",
        "Perfect Fifth",
        "Augmented Fifth",
        "Diminished Sixth",
        "Minor Sixth",
        "Major Sixth",
        "Augmented Sixth",
        "Diminished Seventh",
        "Minor Seventh",
        "Major Seventh",
        "Augmented Seventh",
        "Diminished Octave",
        "Perfect Octave"
    }

    interval_disp_alts = {
        {0,0},  {0,1},                      -- unisons
        {1,-2}, {1,-1}, {1,0}, {1,1},       -- 2nds
        {2,-2}, {2,-1}, {2,0}, {2,1},       -- 3rds
        {3,-1}, {3,0},  {3,1},              -- 4ths
        {4,-1}, {4,0},  {4,1},              -- 5ths
        {5,-2}, {5,-1}, {5,0}, {5,1},       -- 6ths
        {6,-2}, {6,-1}, {6,0}, {6,1},       -- 7ths
        {7,-1}, {7,0}                       -- octaves
    }

    context =
    {
        direction = nil,
        interval_index = nil,
        simplify = nil,
        plus_octaves = nil,
        preserve_originals = nil,
        window_pos_x = nil,
        window_pos_y = nil
    }
end

-- global vars for modeless operation
direction_choice = nil
interval_choice = nil
do_simplify = nil
plus_octaves = nil
do_preserve = nil
global_dialog = nil

local modifier_keys_on_invoke = false

if not finenv.IsRGPLua then
    local path = finale.FCString()
    path:SetRunningLuaFolderPath()
    package.path = package.path .. ";" .. path.LuaString .. "?.lua"
end

local transposition = require("library.transposition")
local note_entry = require("Library.note_entry")

function add_strings_to_control(control, strings)
    local str = finale.FCString()
    for k, v in pairs(strings) do
        str.LuaString = v
        control:AddString(str)
    end
end

function create_dialog_box()
    local str = finale.FCString()
    local dialog = finale.FCCustomLuaWindow() -- global dialog for modeless operation
    str.LuaString = "Transpose Chromatic"
    dialog:SetTitle(str)
    local current_y = 0
    local y_increment = 26
    local x_increment = 85
    -- direction
    local static = dialog:CreateStatic(0, current_y+2)
    str.LuaString = "Direction:"
    static:SetText(str)
    direction_choice = dialog:CreatePopup(x_increment, current_y)
    add_strings_to_control(direction_choice, {"Up", "Down"})
    direction_choice:SetWidth(x_increment)
    if context.direction and context.direction < 0 then
        direction_choice:SetSelectedItem(1)
    end
    current_y = current_y + y_increment
    -- interval
    static = dialog:CreateStatic(0, current_y+2)
    str.LuaString = "Interval:"
    static:SetText(str)
    interval_choice = dialog:CreatePopup(x_increment, current_y)
    add_strings_to_control(interval_choice, interval_names)
    interval_choice:SetWidth(140)
    if context.interval_index then
        interval_choice:SetSelectedItem(context.interval_index - 1)
    end
    current_y = current_y + y_increment
    -- simplify checkbox
    do_simplify = dialog:CreateCheckbox(0, current_y+2)
    str.LuaString = "Simplify Spelling"
    do_simplify:SetText(str)
    do_simplify:SetWidth(140)
    if context.simplify then
        do_simplify:SetCheck(1)
    end
    current_y = current_y + y_increment
    -- plus octaves
    static = dialog:CreateStatic(0, current_y+2)
    str.LuaString = "Plus Octaves:"
    static:SetText(str)
    local edit_x = x_increment
    if finenv.UI():IsOnMac() then
        edit_x = edit_x + 4
    end
    plus_octaves = dialog:CreateEdit(edit_x, current_y)
    if context.plus_octaves and 0 ~= context.plus_octaves then
        str.LuaString = ""
        str:AppendInteger(context.plus_octaves)
        plus_octaves:SetText(str)
    end
    current_y = current_y + y_increment
    -- preserve existing notes
    do_preserve = dialog:CreateCheckbox(0, current_y+2)
    str.LuaString = "Preserve Existing Notes"
    do_preserve:SetText(str)
    do_preserve:SetWidth(140)
    if context.preserve_originals then
        do_preserve:SetCheck(1)
    end
    current_y = current_y + y_increment
    -- OK/Cxl
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    if dialog.OkButtonCanClose then -- OkButtonCanClose will be nil before 0.56 and true (the default) after
        dialog.OkButtonCanClose = modifier_keys_on_invoke
    end
    return dialog
end

function do_transpose_chromatic(direction, interval_index, simplify, plus_octaves, preserve_originals)
    if finenv.Region():IsEmpty() then
        return
    end
    local interval = direction * interval_disp_alts[interval_index][1]
    local alteration = direction * interval_disp_alts[interval_index][2]
    plus_octaves = direction * plus_octaves
    local undostr = "Transpose Chromatic " .. tostring(finenv.Region().StartMeasure)
    if finenv.Region().StartMeasure ~= finenv.Region().EndMeasure then
        undostr = undostr .. " - " .. tostring(finenv.Region().EndMeasure)
    end
    finenv.StartNewUndoBlock(undostr, false) -- this works on both JW Lua and RGP Lua
    local success = true
    for entry in eachentrysaved(finenv.Region()) do
        local note_count = entry.Count
        local note_index = 0
        for note in each(entry) do
            if preserve_originals then
                note_index = note_index + 1
                if note_index > note_count then
                    break
                end
                local dup_note = note_entry.duplicate_note(note)
                if nil ~= dup_note then
                    note = dup_note
                end
            end
            if not transposition.chromatic_transpose(note, interval, alteration, simplify) then
                success = false
            end
            transposition.change_octave(note, plus_octaves)
        end
    end
    if finenv.EndUndoBlock then -- EndUndoBlock only exists on RGP Lua 0.56 and higher
        finenv.EndUndoBlock(true)
        finenv.Region():Redraw()
    else
        finenv.StartNewUndoBlock(undostr, true) -- JW Lua automatically terminates the final undo block we start here
    end
    if not success then
        finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.", "Transposition Error")
    end
    return success
end

function get_values_from_dialog()
    local direction = 1 -- up
    if direction_choice:GetSelectedItem() > 0 then
        direction = -1 -- down
    end
    return direction, 1+interval_choice:GetSelectedItem(), (0 ~= do_simplify:GetCheck()),
                    plus_octaves:GetInteger(), (0 ~= do_preserve:GetCheck())
end

function on_ok()
    local direction, interval_index, simplify, plus_octaves, preserve_originals = get_values_from_dialog()
    do_transpose_chromatic(direction, interval_index, simplify, plus_octaves, preserve_originals)
end

function on_close()
    if global_dialog:QueryLastCommandModifierKeys(finale.CMDMODKEY_ALT) or global_dialog:QueryLastCommandModifierKeys(finale.CMDMODKEY_SHIFT) then
        finenv.RetainLuaState = false
    else
        context.direction, context.interval_index, context.simplify, context.plus_octaves, context.preserve_originals = get_values_from_dialog()
        global_dialog:StorePosition()
        context.window_pos_x = global_dialog.StoredX
        context.window_pos_y = global_dialog.StoredY
    end
end

function transpose_chromatic()
    modifier_keys_on_invoke = finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
    if modifier_keys_on_invoke and nil ~= context.interval_index then
        do_transpose_chromatic(context.direction, context.interval_index, context.simplify, context.plus_octaves, context.preserve_originals)
        return
    end
    global_dialog = create_dialog_box()
    if nil ~= context.window_pos_x and nil ~= context.window_pos_y then
        global_dialog:StorePosition()
        global_dialog:SetRestorePositionOnlyData(context.window_pos_x, context.window_pos_y)
        global_dialog:RestorePosition()
    end
    global_dialog:RegisterHandleOkButtonPressed(on_ok)
    if global_dialog.RegisterCloseWindow then
        global_dialog:RegisterCloseWindow(on_close)
    end
    if finenv.IsRGPLua then
        if nil ~= finenv.RetainLuaState then
            finenv.RetainLuaState = true
        end
        finenv.RegisterModelessDialog(global_dialog)
        global_dialog:ShowModeless()
    else
        if finenv.Region():IsEmpty() then
            finenv.UI():AlertInfo("Please select a music region before running this script.", "Selection Required")
            return
        end
        global_dialog:ExecuteModal(nil)
    end
end

transpose_chromatic()

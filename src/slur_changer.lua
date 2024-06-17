function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.02"
    finaleplugin.Date = "2024/06/17"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        Change the characteristics of every slur in the current selection. 
        Type the matching programmable _hotkey_ and click __Apply__ [_Return_/_Enter_]. 

        Change these options on individual slurs by right-clicking with the 
        _SmartShape_ tool, or change a whole set of slurs at once with this script.

        To repeat the last action without a confirmation dialog 
        hold down _Shift_ when opening the script. 
    ]]
    return "Slur Changer...", "Slur Changer",
        "Change the characteristics of slurs in the current selection"
end

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local selection
local saved_bounds = {}

local config = {
    dummy         = "dummy", -- stop warning about table string mismatch
    last_selected = 0,     -- menu item number (0-based) selected
    modeless      = false, -- false = modal / true = modeless
    timer_id      = 1,
    window_pos_x  = nil,
    window_pos_y  = nil,
    -- other default values copied from dialog_options{} below
}
local dialog_options = { -- NAME key; HOTKEY; text description (ordered)
    { "visible_yes",               "V", "Visible" },
    { "visible_no",                "I", "Invisible" },
    { "flip",                      "X", "Flip" },
    { "SMARTSHAPE_SLURUP",         "O", "Slur: Over" },
    { "SMARTSHAPE_SLURDOWN",       "U", "Slur: Under" },
    { "SMARTSHAPE_SLURAUTO",       "A", "Slur: Auto" },
    { "SMARTSHAPE_DASHEDSLURUP",   "D", "Dashed: Over" },
    { "SMARTSHAPE_DASHEDSLURDOWN", "F", "Dashed: Under" },
    { "SMARTSHAPE_DASHEDSLURAUTO", "G", "Dashed: Auto" },
    { "SS_OFFSTATE",               "B", "Engraver: ON" },
    { "SS_ONSTATE",                "N", "Engraver: OFF" },
    { "SS_AUTOSTATE",              "M", "Engraver: AUTO" },
    { "erase",                     ";", "Erase All" },
    { "default",                   "Z", "Default Values" }
}
for _, v in ipairs(dialog_options) do config[v[1]] = v[2] end -- (map hotkeys)

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

local function get_staff_name(staff_num)
    local staff = finale.FCStaff()
    staff:Load(staff_num)
    local str = staff:CreateDisplayAbbreviatedNameString().LuaString
    if not str or str == "" then
        str = "Staff" .. staff_num
    end
    return str
end

local function track_selection()
    local bounds = { -- primary region selection boundaries
        "StartStaff", "StartMeasure", "StartMeasurePos",
        "EndStaff",   "EndMeasure",   "EndMeasurePos",
    }
    -- update selection
    local rgn = finenv.Region()
    if rgn:IsEmpty() then
        selection = "no staff, no selection" -- default
    else
        for _, property in ipairs(bounds) do
            saved_bounds[property] = rgn[property]
        end
        selection = get_staff_name(rgn.StartStaff)
        if rgn.EndStaff ~= rgn.StartStaff then
            selection = selection .. "-" .. get_staff_name(rgn.EndStaff)
        end
        selection = selection .. " m." .. rgn.StartMeasure
        if rgn.StartMeasure ~= rgn.EndMeasure then
            selection = selection .. "-" .. rgn.EndMeasure
        end
    end
end

local function reassign_keystrokes(parent, index)
    local y_step, x_wide = 17, 180
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors = false, {}
    local y = 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Slur Changer: Reassign Keys")
    for _, v in ipairs(dialog_options) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v[1]):SetText(config[v[1]]):SetWidth(20)
            :AddHandleCommand(function(self)
                local str = self:GetText():sub(-1):upper()
                self:SetText(str):SetKeyboardFocus()
            end)
        dialog:CreateStatic(25, y):SetText(v[3]):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore_duplicates or 0)
    dialog:CreateOkButton():SetText("Save")
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
        self:GetControl(dialog_options[index][1]):SetKeyboardFocus()
    end)
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for _, v in ipairs(dialog_options) do
            local key = self:GetControl(v[1]):GetText()
            if key == "" then key = "?" end -- not null
            config[v[1]] = key -- save for another possible run-through
            config.ignore_duplicates = ignore:GetCheck()
            if config.ignore_duplicates == 0 then -- DON'T IGNORE duplicates
                if assigned[key] then -- previously assigned
                    is_duplicate = true
                    if not errors[key] then errors[key] = { assigned[key] } end
                    table.insert(errors[key], v[3])
                else
                    assigned[key] = v[3] -- flag key assigned
                end
            end
        end
        if is_duplicate then -- list reassignment duplications
            local msg = ""
            for k, v in pairs(errors) do
                if msg ~= "" then msg = msg .. "\n\n" end
                msg = msg .. "Key \"" .. k .. "\" is assigned to: "
                for i, w in ipairs(v) do
                    if i > 1 then msg = msg .. " and " end
                    msg = msg .. "\"" .. w .. "\""
                end
            end
            dialog:CreateChildUI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(parent) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

local function change_the_slurs()
    local selected = dialog_options[config.last_selected + 1]
    local state = selected[1]
    local checked = {}
    finenv.StartNewUndoBlock(string.format("Slur %s %s", selected[3]:gsub(" ", ""), selection))

    for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), finenv.Region()) do
        local shape = mark:CreateSmartShape()
        if not checked[shape.ItemNo] then -- only examine shapes once
            checked[shape.ItemNo] = true
            if shape and shape:IsSlur() then
                if state == "default" then
                    shape.EngraverSlur = finale.SS_AUTOSTATE
                    shape.ShapeType = finale.SMARTSHAPE_SLURAUTO
                    shape.Visible = true
                    shape:GetCtrlPointAdjust():SetDefaultSlurShape()
                elseif state:find("visible") then shape.Visible = state:find("yes")
                elseif state == "erase" then shape:DeleteData()
                elseif state == "flip" then
                    local a = shape:IsDashedSlur() and "DASHEDSLUR" or "SLUR"
                    local b = (shape:IsOverSlur() or shape:IsAutoSlur()) and "DOWN" or "UP"
                    shape.ShapeType = finale["SMARTSHAPE_" .. a .. b]
                elseif state:find("SS_") then shape.EngraverSlur = finale[state]
                else shape.ShapeType = finale[state]
                end
                shape:Save()
            end
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
end

local function run_the_dialog()
    local y_step = 17
    local box_wide = 150
    local box_high = (#dialog_options * y_step) + 4
    local name = plugindef():gsub("%.%.%.", "")
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
    dialog:CreateStatic(0, 0):SetText("Change Slurs:"):SetWidth(box_wide)
    local key_list = dialog:CreateListBox(0, 22):SetWidth(box_wide):SetHeight(box_high)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 400, 140)
        end
        local function fill_key_list()
            local join = finenv.UI():IsOnMac() and "\t" or ": "
            key_list:Clear()
            for _, option in ipairs(dialog_options) do -- add options with keycodes
                key_list:AddString(config[option[1]] .. join .. option[3])
            end
            key_list:SetSelectedItem(config.last_selected or 0)
        end
        local function change_keys()
            local ok, is_duplicate = true, true
            while ok and is_duplicate do -- wait for good choice in reassign()
                ok, is_duplicate = reassign_keystrokes(dialog, key_list:GetSelectedItem() + 1)
            end
            if ok then fill_key_list()
            else configuration.get_user_settings(script_name, config) -- reinstall hotkeys
            end
            key_list:SetKeyboardFocus()
        end
        local function on_timer() -- track changes in selected region
            for k, v in pairs(saved_bounds) do
                if finenv.Region()[k] ~= v then -- selection changed
                    track_selection() -- update selection tracker
                    break -- all done
                end
            end
        end

    fill_key_list()
    dialog:CreateButton(box_wide - 20, 0, "q"):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    local x_off = box_wide / 6
    local y = box_high + 30
    dialog:CreateButton(x_off, y):SetText("Change Hotkeys")
        :AddHandleCommand(function() change_keys() end):SetWidth(x_off * 4)
    dialog:CreateOkButton():SetText("Apply")
    dialog:CreateCancelButton():SetText("Close")
    dialog_set_position(dialog)
    dialog:RegisterHandleTimer(on_timer)
    dialog:RegisterInitWindow(function(self)
        self:SetTimer(config.timer_id, 125)
        key_list:SetKeyboardFocus()
        local q = dialog:GetControl("q")
        q:SetFont(q:CreateFontInfo():SetBold(true))
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        config.last_selected = key_list:GetSelectedItem() -- save list choice (0-based)
        change_the_slurs()
    end)
    dialog:RegisterCloseWindow(function(self)
        self:StopTimer(config.timer_id)
        dialog_save_position(self)
    end)
    dialog:RunModeless()
end

local function change_slurs()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    track_selection() -- track current selected region
    if mod_key then change_the_slurs()
    else run_the_dialog()
    end
end

change_slurs()

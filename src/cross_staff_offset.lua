function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v1.64" -- Modeless option
    finaleplugin.Date = "2024/04/13"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        When crossing notes to adjacent staves the stems of _crossed_ notes 
        can be reversed (on the "wrong" side of the notehead) and look misaligned 
        by the width of a notehead, nominally 24 EVPUs (0.08333 inches). 
        This script shifts cross-staffed notes horizontally to correct the spacing, 
        with a matching offset for uncrossed notes, acting on one or all layers. 

        It is also a quick way to reset the horizontal position of all notes to zero. 
        To repeat your last settings without a confirmation dialog 
        hold down [Shift] when starting the script.

        > __Key Commands__: 

        > - __u__: reset default __up__ values 
        > - __d__: reset default __down__ values 
        > - __q__: display these notes 
        > - __0 - 4__: layer number (delete key not needed)  
        > - To change measurement units: 
        > - __e__: EVPU / __i__: Inches / __c__: Centimeters 
        > - __o__: Points / __a__: Picas / __s__: Spaces 
    ]]
    return "CrossStaff Offset...",
        "CrossStaff Offset",
        "Offset horizontal position of cross-staff note entries"
end

local config = {
    cross_staff_offset  = 0,
    non_cross_offset = 0,
    layer_num = 0,
    modeless = true,
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local layer = require("library.layer")
local mixin = require("library.mixin")
local measurement = require("library.measurement")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false
local name = plugindef():gsub("%.%.%.", "")
configuration.get_user_settings(script_name, config)

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
    local staff_name = staff:CreateDisplayAbbreviatedNameString().LuaString
    if not staff_name or staff_name == "" then
        staff_name = "Staff " .. staff_num
    end
    return staff_name
end

local function change_offsets()
    local rgn = finenv.Region()
    finenv.StartNewUndoBlock(
        string.format("%s %s m.%d-%d",
            name, get_staff_name(rgn.StartStaff), rgn.StartMeasure, rgn.EndMeasure
        )
    )
    for entry in eachentrysaved(rgn, config.layer_num) do
        if entry:IsNote() then
            entry.ManualPosition = entry.CrossStaff and config.cross_staff_offset or config.non_cross_offset
        end
    end
    finenv.EndUndoBlock(true)
    rgn:Redraw()
end

local function run_the_dialog()
    local x_grid = { 0, 113, 184 }
    local y, y_step = 3, 23
    local default_value = 24
    local e_width = 64
    local box, save_value = {}, {}
    local max = layer.max_layers()
    local offset = finenv.UI():IsOnMac() and 3 or 0 -- y-offset for Mac EDIT control
    local units = { -- triggered by keystroke within "[eicoas]"
        e = finale.MEASUREMENTUNIT_EVPUS,       i = finale.MEASUREMENTUNIT_INCHES,
        c = finale.MEASUREMENTUNIT_CENTIMETERS, o = finale.MEASUREMENTUNIT_POINTS,
        a = finale.MEASUREMENTUNIT_PICAS,       s = finale.MEASUREMENTUNIT_SPACES,
    }
    local dialog_options = { -- ordered table: text, config key code
        { "Cross-staff offset:", "cross_staff_offset"},
        { "Non-crossed offset:", "non_cross_offset" },
        { "Layer 1-" .. max .. " (0 = all):", "layer_num" }
    }
    local modeless, info = #dialog_options + 1, #dialog_options + 2
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
    dialog:SetMeasurementUnit(config.measurement_unit)
    local function update_saved() -- after units change
        for i = 1, #dialog_options do
            save_value[i] = box[i]:GetText()
        end
    end
    local popup = dialog:CreateMeasurementUnitPopup(x_grid[3], y):SetWidth(97)
        :AddHandleCommand(function() update_saved() end)

        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 400, 320)
            refocus_document = true
        end
        local function set_defaults(pole)
            local n = default_value * pole / 2
            box[1]:SetMeasurementInteger(n)
            box[2]:SetMeasurementInteger(-n)
            update_saved()
        end
        local function key_check(id)
            local s = box[id]:GetText():lower()
            if (s:find("p") and dialog:GetMeasurementUnit() ~= finale.MEASUREMENTUNIT_PICAS)
                or s:find("[^-.p0-9]")
                or (id == 3 and s:find("[^0-" .. max .. "]"))
                then
                if     s:find("[?q]") then show_info()
                elseif s:find("u") then set_defaults( 1) -- up
                elseif s:find("d") then set_defaults(-1) -- down
                elseif s:find("m") then -- toggle modeless
                    box[modeless]:SetCheck((box[modeless]:GetCheck() + 1) % 2)
                elseif s:find("[eicoas]") then -- change measurement unit
                    for k, v in pairs(units) do
                        if s:find(k) then
                            box[id]:SetText(save_value[id])
                            dialog:SetMeasurementUnit(v)
                            popup:UpdateMeasurementUnit()
                            update_saved()
                            break
                        end
                    end
                end
                box[id]:SetText(save_value[id])
            elseif s ~= "" then -- save new "clean" numnber
                if id == 3 then
                    s = s:sub(-1) -- 1-char layer number
                else
                    if s == "." then s = "0." -- offsets, leading zero
                    elseif s == "-." then s = "-0."
                    end
                    s = s:sub(1, 8)
                end
                box[id]:SetText(s)
                save_value[id] = s
            end
        end
        local function submission_error()
            local values = { 576, config.cross_staff_offset, config.non_cross_offset }
            if math.abs(values[2]) <= values[1] and math.abs(values[3]) <= values[1] then
                return false -- "reasonable" offset values == NO ERROR
            end
            local str = finale.FCString()
            for k, v in ipairs(values) do -- convert values to measurement_unit
                str:SetMeasurement(v, config.measurement_unit)
                values[k] = str.LuaString
            end
            local u_name = " " .. measurement.get_unit_name(config.measurement_unit)
            local msg = "Choose realistic offset values, say between -" .. values[1] .. " and "
            .. values[1] .. u_name .. ",\nnot " .. values[2] .. " to " .. values[3] .. u_name
            dialog:CreateChildUI():AlertError(msg, name .. " Error")
            return true
        end
    for i, v in ipairs(dialog_options) do
        dialog:CreateStatic(0, y):SetText(v[1]):SetWidth(x_grid[2])
        if i < 3 then
            box[i] = dialog.CreateMeasurementEdit(dialog, x_grid[2], y - offset, v[2])
                :SetWidth(e_width):SetMeasurementInteger(config[v[2]])
                :AddHandleCommand(function() key_check(i) end)
        else -- third line
            box[i] = dialog:CreateEdit(x_grid[2], y - offset, v[2]):SetText(config[v[2]])
                :SetWidth(20):AddHandleCommand(function() key_check(i) end)
            box[modeless] = dialog:CreateCheckbox(x_grid[3], y):SetWidth(80)
                :SetCheck(config.modeless and 1 or 0):SetText("Modeless")
            box[info] = dialog:CreateButton(x_grid[3] + 80, y - 2):SetText("?"):SetWidth(20)
                :AddHandleCommand(function() show_info() end)
        end
        if i == 2 then -- add UP/DOWN buttons
            dialog:CreateButton(x_grid[3], y):SetText("up (u)"):SetWidth(40)
                :AddHandleCommand(function() set_defaults(1) end)
            dialog:CreateButton(x_grid[3] + 42, y):SetText("down (d)"):SetWidth(55)
                :AddHandleCommand(function() set_defaults(-1) end)
        end
        y = y + y_step
    end
    update_saved()
    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "OK")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function()
        box[info]:SetFont(box[info]:CreateFontInfo():SetBold(true))
        box[1]:SetKeyboardFocus()
    end)
    local change_mode, user_error = false, false
    dialog:RegisterHandleOkButtonPressed(function(self)
        config.cross_staff_offset = box[1]:GetMeasurementInteger()
        config.non_cross_offset = box[2]:GetMeasurementInteger()
        config.layer_num = box[3]:GetInteger()
        config.measurement_unit = self:GetMeasurementUnit()
        if submission_error() then
            user_error = true
        else -- go ahead and change the offsets
            change_offsets()
        end
    end)
    dialog:RegisterCloseWindow(function(self)
        local mode = (box[modeless]:GetCheck() == 1)
        change_mode = (mode and not config.modeless) -- modal -> modeless?
        config.modeless = mode
        dialog_save_position(self)
    end)
    if config.modeless then   -- "modeless"
        dialog:RunModeless()
    else
        dialog:ExecuteModal() -- "modal"
        if refocus_document then finenv.UI():ActivateDocumentWindow() end
    end
    return change_mode or user_error
end

local function cross_staff_offset()
    local qim = finenv.QueryInvokedModifierKeys
    local shift_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    if shift_key  then
        change_offsets()
    else
        while run_the_dialog() do end
    end
end

cross_staff_offset()

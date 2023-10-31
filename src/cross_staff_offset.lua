function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v1.56"
    finaleplugin.Date = "2023/10/31"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[ 
        When crossing notes to adjacent staves the stems of 'crossed' notes can be reversed 
        (on the "wrong"" side of the notehead) and look too far 
        to the right (if shifting downwards) by the width of a notehead, around 24 EVPUs. 
        This script shifts cross-staffed notes horizontally, 
        with a different offset for non-crossed notes, acting on one or all layers. 
        It is also a quick way to reset the horizontal position of all notes to zero. 
        To repeat your last settings without a confirmation dialog 
        hold down the SHIFT key when starting the script.

        When crossing UP try EVPU offsets of 12 (crossed) and -12 (not crossed), or 24/0. 
        When crossing DOWN try crossed/uncrossed offsets of -12/12 EVPUs or -24/0.

        To change measurement units without using the mouse, type one of these keys: 
        "e" (EVPUs), "i" (Inches), "c" (Centimeters), 
        "o" (Points), "a" (Picas), or "s" (Spaces).         
        Use "u" and "d" to set the default values for crossing staves Up/Down. 
        To view these notes type "q". 
    ]]
    return "CrossStaff Offset...", "CrossStaff Offset",
        "Offset horizontal position of cross-staff note entries"
end

local config = {
    cross_staff_offset  = 0,
    non_cross_offset = 0,
    layer_num = 0,
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    pos_x = false,
    pos_y = false,
}

local configuration = require("library.configuration")
local layer = require("library.layer")
local mixin = require("library.mixin")
local measurement = require("library.measurement")
local script_name = "cross_staff_offset"
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

local function no_error()
    local values = { 576, config.cross_staff_offset, config.non_cross_offset }
    if math.abs(values[2]) <= values[1] and math.abs(values[3]) <= values[1] then
        return true -- "reasonable" offset values
    end
    local s = {}
    local str = finale.FCString()
    for _, v in ipairs(values) do -- convert values to current measurement_unit
        str:SetMeasurement(v, config.measurement_unit)
        table.insert(s, str.LuaString)
    end
    local name = measurement.get_unit_name(config.measurement_unit)
    local msg = "Choose realistic offset values, say from -" .. s[1] .. " to "
    .. s[1] .. " " .. name .. " ...\nnot " .. s[2] .. " / " .. s[3] .. " " .. name
    finenv.UI():AlertError(msg, "Error")
    return false
end

local function user_chooses()
    local x_grid = { 0, 113, 184 }
    local box, save_value = {}, {}
    local units = { -- triggered by keystroke within "[eicoas]"
        e = finale.MEASUREMENTUNIT_EVPUS,       i = finale.MEASUREMENTUNIT_INCHES,
        c = finale.MEASUREMENTUNIT_CENTIMETERS, o = finale.MEASUREMENTUNIT_POINTS,
        a = finale.MEASUREMENTUNIT_PICAS,       s = finale.MEASUREMENTUNIT_SPACES,
    }
    local max = layer.max_layers()
    local e_width = 64
    local y_step = 23
    local offset = finenv.UI():IsOnMac() and 3 or 0 -- y-offset for Mac EDIT control

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    local notes = finaleplugin.Notes:gsub(" %s+", " "):gsub("\n ", "\n"):sub(2)
    local function show_info() finenv.UI():AlertInfo(notes, "About " .. plugindef()) end
    local function update_saved() -- after units change
        save_value[1] = box[1]:GetText()
        save_value[2] = box[2]:GetText()
    end
    local y = 3
    dialog:SetMeasurementUnit(config.measurement_unit)
    local popup = dialog:CreateMeasurementUnitPopup(x_grid[3], y):SetWidth(97)
        :AddHandleCommand(function() update_saved() end)

        local function set_defaults(pole)
            box[1]:SetMeasurementInteger(12 * pole)
            box[2]:SetMeasurementInteger(-12 * pole)
            save_value[1] = box[1]:GetText()
            save_value[2] = box[2]:GetText()
        end
        local function key_check(id)
            local s = box[id]:GetText():lower()
            if (    s:find("p") and dialog:GetMeasurementUnit() ~= finale.MEASUREMENTUNIT_PICAS)
                    or s:find("[^-p.0-9]")
                    or (id == 3 and s:find("[-.p5-9]")
                )   then
                if s:find("q") then show_info()
                elseif s:find("u") then set_defaults(1) -- up
                elseif s:find("d") then set_defaults(-1) -- down
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
                box[id]:SetText(save_value[id]):SetKeyboardFocus()
            else -- save new "clean" numnber
                if id == 3 then s = s:sub(-1) -- layer number
                else
                    if s == "." then s = "0." -- offsets, leading zero
                    elseif s == "-." then s = "-0."
                    end
                end
                box[id]:SetText(s)
                save_value[id] = s
            end
        end
    local dialog_options = { -- ordered table: text, config key code
        { "Cross-staff offset:", "cross_staff_offset"},
        { "Non-crossed offset:", "non_cross_offset" },
        { "Layer 1-" .. max .. " (0 = all):", "layer_num" }
    }
    for i, v in ipairs(dialog_options) do
        dialog:CreateStatic(0, y):SetText(v[1]):SetWidth(x_grid[2])
        if i < 3 then
            box[i] = dialog.CreateMeasurementEdit(dialog, x_grid[2], y - offset, v[2])
                :SetWidth(e_width):SetMeasurementInteger(config[v[2]])
                :AddHandleCommand(function() key_check(i) end)
        else
            box[i] = dialog:CreateEdit(x_grid[2], y - offset, v[2]):SetText(config[v[2]])
                :SetWidth(e_width / 2):AddHandleCommand(function() key_check(i) end)
            dialog:CreateButton(x_grid[3] + 77, y):SetText("?"):SetWidth(20)
                :AddHandleCommand(function() show_info() end)
        end
        if i == 2 then
            dialog:CreateButton(x_grid[3], y):SetText("up (u)"):SetWidth(40)
                :AddHandleCommand(function() set_defaults("up") end)
            dialog:CreateButton(x_grid[3] + 42, y):SetText("down (d)"):SetWidth(55)
                :AddHandleCommand(function() set_defaults("down") end)
        end
        save_value[i] = box[i]:GetText()
        y = y + y_step
    end
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function() box[1]:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dialog:RegisterHandleOkButtonPressed(function(self)
        config["cross_staff_offset"] = box[1]:GetMeasurementInteger()
        config["non_cross_offset"] = box[2]:GetMeasurementInteger()
        config["layer_num"] = box[3]:GetInteger()
        config.measurement_unit = self:GetMeasurementUnit()
        dialog_save_position(self)
    end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function cross_staff_offset()
    local shift_key = finenv.QueryInvokedModifierKeys and finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)

    if shift_key or (user_chooses() and no_error()) then -- *** DO THE WORK ***
        for entry in eachentrysaved(finenv.Region(), config.layer_num) do
            if entry:IsNote() then
                entry.ManualPosition = entry.CrossStaff and config.cross_staff_offset or config.non_cross_offset
            end
        end
    end
end

cross_staff_offset()
